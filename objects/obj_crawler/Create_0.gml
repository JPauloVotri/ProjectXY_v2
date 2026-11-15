event_inherited();

#region Constantes
    MOVEMENT_SPEED = .5;
    SLOPE_STEP_PENALTY = sqrt(2) - 1;
    SLOPE_MAX_PENALTY = .99;
    STICK_REACH = 2;
    STUCK_LIMIT = 30;
    PROBE_COOLDOWN = 2;
#endregion

#region Estado
    state_machine = new StateMachine();
    up = new Vector2(0, -1);
    probe_cooldown = 0;
#endregion

#region Superfície
    /// @desc Gruda na superfície encostada ou a até `STICK_REACH` px, indo 1 px ao encontro.
    /// @return {Bool} `true` se achou superfície para seguir.
    stick = function() {
        var _sides = [
            new Vector2(0, 1),
            new Vector2(-1, 0),
            new Vector2(1, 0),
            new Vector2(0, -1)
        ];

        for (var _reach = 1; _reach <= STICK_REACH; _reach++) {
            for (var i = 0; i < array_length(_sides); i++) {
                var _side = _sides[i];

                if (!place_meeting(x + _side.x * _reach, y + _side.y * _reach, obj_solid)) {
                    continue;
                }

                if (_reach > 1) {
                    x += _side.x;
                    y += _side.y;
                }

                up = _side.multiplied(-1);

                return true;
            }
        }

        return false;
    }
#endregion

#region Degraus
    /// @desc Cobra o custo de 1 px de rampa no eixo do passo, limitando o resto.
    /// @param {Real} _dx Componente x do passo: -1, 0 ou 1.
    /// @param {Real} _dy Componente y do passo: -1, 0 ou 1.
    charge_slope = function(_dx, _dy) {
        if (_dx != 0) {
            velocity_remainder.x -= sign(_dx) * SLOPE_STEP_PENALTY;
            velocity_remainder.x = clamp(velocity_remainder.x,
                -SLOPE_MAX_PENALTY, SLOPE_MAX_PENALTY);

            return;
        }

        velocity_remainder.y -= sign(_dy) * SLOPE_STEP_PENALTY;
        velocity_remainder.y = clamp(velocity_remainder.y, -SLOPE_MAX_PENALTY, SLOPE_MAX_PENALTY);
    }

    /// @desc Vence 1 px de rampa na direção do passo, afastando-se da superfície seguida e
    /// zerando o resto do eixo perpendicular a ela.
    /// @param {Real} _dx Componente x do passo: -1, 0 ou 1.
    /// @param {Real} _dy Componente y do passo: -1, 0 ou 1.
    /// @return {Bool} `true` se venceu o degrau.
    try_step_up = function(_dx, _dy) {
        if (_dx == 0 && _dy == 0) return false;
        if (place_meeting(x + _dx + up.x, y + _dy + up.y, obj_solid)) return false;
        if (!place_meeting(x - up.x, y - up.y, obj_solid)) return false;

        x += _dx + up.x;
        y += _dy + up.y;

        if (up.x != 0) {
            velocity_remainder.x = 0;
        } else {
            velocity_remainder.y = 0;
        }

        charge_slope(_dx, _dy);

        return true;
    }

    /// @desc Cola na superfície seguida 1 px adiante, cobrando o custo da rampa.
    /// @param {Real} _dx Componente x do passo: -1, 0 ou 1.
    /// @param {Real} _dy Componente y do passo: -1, 0 ou 1.
    /// @return {Bool} `true` se colou na superfície.
    try_step_down = function(_dx, _dy) {
        if (velocity.x * up.x + velocity.y * up.y > 0) return false;
        if (place_meeting(x - up.x, y - up.y, obj_solid)) return false;
        if (!place_meeting(x - 2 * up.x, y - 2 * up.y, obj_solid)) return false;
        if (!place_meeting(x - _dx - up.x, y - _dy - up.y, obj_solid)) return false;

        x -= up.x;
        y -= up.y;

        charge_slope(_dx, _dy);

        return true;
    }
#endregion

#region Rastejo
    /// @desc Conta frames parado e, ao estourar o limite, solta 1 px da superfície; sem
    /// espaço para soltar, entrega o crawler à queda.
    update_stuck = function() {
        if (x != stuck_x || y != stuck_y) {
            stuck_x = x;
            stuck_y = y;
            stuck_frames = 0;

            return;
        }

        stuck_frames++;

        if (stuck_frames < STUCK_LIMIT) return;

        stuck_frames = 0;
        probe_cooldown = PROBE_COOLDOWN;

        if (place_meeting(x + up.x, y + up.y, obj_solid)) {
            state_machine.change_state("fall");

            return;
        }

        x += up.x;
        y += up.y;
    }

    /// @desc Vira o `up` quando a superfície acaba na direção do movimento.
    probe_corner = function() {
        if (probe_cooldown > 0) {
            probe_cooldown--;

            return;
        }

        var _hug = up.multiplied(-1);
        var _move = up.rotated(surface_on_left ? -90 : 90).normalize();

        var _edge_x = _move.x != 0 ? _move.x : _hug.x;
        var _edge_y = _move.y != 0 ? _move.y : _hug.y;
        var _corner_x = _edge_x > 0 ? bbox_right + 1 : bbox_left - 1;
        var _corner_y = _edge_y > 0 ? bbox_bottom + 1 : bbox_top - 1;

        if (position_meeting(_corner_x, _corner_y, obj_solid)) return;

        var _next_up = up.rotated(surface_on_left ? -90 : 90).round();
        var _next_move = _next_up.rotated(surface_on_left ? -90 : 90).normalize();

        if (place_meeting(x + _next_move.x, y + _next_move.y, obj_solid)) return;

        up = _next_up;
        probe_cooldown = PROBE_COOLDOWN;
    }

    /// @desc Anda pela superfície no sentido definido por `surface_on_left`: `true` mantém a
    /// superfície à esquerda do movimento (chão → esquerda, teto → direita, parede à esquerda
    /// → sobe, parede à direita → desce); `false` inverte tudo. O sentido na tela depende de a
    /// superfície ser cavidade ou saliência.
    on_crawl_update = function() {
        update_stuck();

        if (!state_machine.is_state("crawl")) return;

        probe_corner();

        var _move = up.rotated(surface_on_left ? -90 : 90).normalize();

        velocity.copyFrom(_move).multiply(MOVEMENT_SPEED);
    }
#endregion

#region Queda
    /// @desc Entra em queda livre com o movimento e os restos zerados.
    on_fall_create = function() {
        velocity.set(0, 0);
        velocity_remainder.set(0, 0);
    }

    /// @desc Aplica a gravidade limitada pela velocidade terminal, sem deslocamento lateral.
    on_fall_update = function() {
        velocity.x = 0;
        velocity.y = min(velocity.y + GRAVITY, TERMINAL_SPEED);
    }

    /// @desc Gruda na superfície tocada durante a queda e volta a rastejar.
    land = function() {
        if (!stick()) return;

        velocity_remainder.set(0, 0);
        state_machine.change_state("crawl");
    }
#endregion

#region Hooks
    /// @desc Passo em x bloqueado: vence a rampa ou gira rastejando; na queda, gruda.
    /// @param {Id.Instance.obj_solid} _instance Instância que bloqueou o passo.
    on_x_blocked = function(_instance) {
        if (!state_machine.is_state("crawl")) {
            velocity.x = 0;
            velocity_remainder.x = 0;
            land();

            return;
        }

        if (try_step_up(sign(velocity.x), 0)) return;

        up.rotate(surface_on_left ? 90 : -90).round();

        velocity.x = 0;
        velocity_remainder.x = 0;
    }

    /// @desc Passo em y bloqueado: vence a rampa ou gira rastejando; na queda, gruda.
    /// @param {Id.Instance.obj_solid} _instance Instância que bloqueou o passo.
    on_y_blocked = function(_instance) {
        if (!state_machine.is_state("crawl")) {
            velocity.y = 0;
            velocity_remainder.y = 0;
            land();

            return;
        }

        if (try_step_up(0, sign(velocity.y))) return;

        up.rotate(surface_on_left ? 90 : -90).round();

        velocity.y = 0;
        velocity_remainder.y = 0;
    }

    /// @desc Passo em x efetivado: recola na superfície na descida.
    on_x_moved = function() {
        if (!state_machine.is_state("crawl")) return;

        try_step_down(sign(velocity.x), 0);
    }

    /// @desc Passo em y efetivado: recola na superfície na descida.
    on_y_moved = function() {
        if (!state_machine.is_state("crawl")) return;

        try_step_down(0, sign(velocity.y));
    }
#endregion

#region Inicialização
    state_machine
        .add_state(new State("crawl").set_update(on_crawl_update))
        .add_state(new State("fall").set_create(on_fall_create).set_update(on_fall_update));

    if (!stick()) state_machine.change_state("fall");

    stuck_x = x;
    stuck_y = y;
    stuck_frames = 0;
#endregion

#region Aparência
    /// @type {Id.Instance.obj_crawler_blades}
    blades = instance_create_layer(x, y, self.layer, obj_crawler_blades);
    blades.depth = depth - 1;
    blades.parent = self;
#endregion
