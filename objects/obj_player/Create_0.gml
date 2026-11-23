/// @desc Direção olhada, usada para espelhar o sprite e para consultas de lado.
enum FACING {
    LEFT = -1,
    RIGHT = 1,
}

event_inherited();

#region Constantes
    JUMP_SPEED = 2.45;
    JUMP_CUT = .5;
    HIGH_JUMP_FACTOR = 1.37;
    DOUBLE_JUMP_FACTOR = .6;
    MOVEMENT_SPEED = 1;
    AIR_FACTOR = .5;
    SLOPE_STEP_PENALTY = 1;
    SLOPE_MAX_PENALTY = .99;
    FIRE_COOLDOWN = 20;

    /// @desc Frames em que o clarão do disparo fica visível.
    MUZZLE_FLASH_TIME = 4;

    /// @desc Vida máxima inicial, antes de qualquer tanque.
    BASE_MAX_HEALTH = 99;

    /// @desc Vida que cada tanque soma ao máximo e à vida atual.
    HEALTH_PER_TANK = 100;

    /// @desc Impulso vertical do recuo ao encostar num perigo.
    HURT_JUMP_SPEED = 1.2;

    /// @desc Impulso horizontal do recuo, em px por frame.
    HURT_PUSH_SPEED = .7;

    /// @desc Frames em que o controle fica travado depois do recuo.
    HURT_LOCK_FRAMES = 20;

    /// @desc Frames acesos e apagados alternados durante a invencibilidade.
    BLINK_INTERVAL = 3;
#endregion

#region Vida
    current_health = BASE_MAX_HEALTH;
    max_health = BASE_MAX_HEALTH;
    tanks = 0;

    /// @desc Desconta vida, sem deixar o valor abaixo de zero.
    /// @param {Real} _amount Dano a descontar.
    /// @return {Bool} `true` quando a vida desceu.
    take_damage = function(_amount) {
        if (_amount <= 0) return false;
        if (current_health <= 0) return false;

        current_health = max(current_health - _amount, 0);

        return true;
    }

    /// @desc Recupera vida, sem passar do máximo.
    /// @param {Real} _amount Vida a recuperar.
    /// @return {Bool} `true` quando a vida subiu.
    restore_health = function(_amount) {
        if (_amount <= 0) return false;
        if (current_health >= max_health) return false;

        current_health = min(current_health + _amount, max_health);

        return true;
    }

    /// @desc Soma um tanque de vida: +100 no máximo e +100 na vida atual.
    /// @return {Bool} `true` quando o tanque foi aplicado.
    grant_health_tank = function() {
        tanks++;
        max_health += HEALTH_PER_TANK;
        current_health = min(current_health + HEALTH_PER_TANK, max_health);

        return true;
    }

    /// @desc Tanques cheios derivados da vida atual: cada 100 pontos contam como um.
    /// @return {Real}
    get_full_tank_count = function() {
        return clamp(floor(current_health / HEALTH_PER_TANK), 0, tanks);
    }
#endregion

#region Dano
    /// @desc Frames restantes de invencibilidade; o Draw pisca enquanto for maior que zero.
    invincible_time = 0;

    /// @desc Verdadeiro enquanto um novo toque ainda não pode arremessar o jogador.
    /// @return {Bool}
    is_invincible = function() {
        return invincible_time > 0;
    }

    /// @desc Liga a invencibilidade pelo tempo informado, sem encurtar a que já existe.
    /// @param {Real} _frames Frames concedidos pela fonte do toque.
    start_invincibility = function(_frames) {
        invincible_time = max(invincible_time, _frames);
    }

    /// @desc Arremessa o jogador para longe da fonte, se não estiver invencível.
    /// @param {Real} _source_x X da fonte que encostou.
    /// @param {Real} _invincible_frames Frames de invencibilidade concedidos pela fonte.
    /// @return {Bool} `true` quando o recuo começou.
    bounce_from = function(_source_x, _invincible_frames) {
        if (is_invincible()) return false;

        var _dir = sign(x - _source_x);

        if (_dir == 0) _dir = -facing;

        velocity_remainder.set(0, 0);
        velocity.set(
            _dir * HURT_PUSH_SPEED * physics_factor,
            -HURT_JUMP_SPEED * physics_factor
        );
        start_invincibility(_invincible_frames);
        state_machine.change_state("hurt");

        return true;
    }
#endregion

#region Aparência
    facing = FACING.RIGHT;
    image_xscale = facing;

    /// @desc Define a direção olhada e espelha o sprite; ignora 0.
    /// @param {Enum.FACING} _dir Direção em FACING.
    set_facing = function(_dir) {
        if (_dir == 0 || _dir == facing) return;

        facing = _dir;
        image_xscale = _dir;
    }
#endregion

#region Tiro
    /// @desc Direção do próximo tiro: horizontal, diagonal para frente ou vertical.
    aim_direction = new Vector2(facing, 0);

    /// @desc Sinal vertical da diagonal lembrada: -1 para cima, 1 para baixo.
    aim_vertical = -1;

    fire_cooldown = 0;

    /// @desc Deslocamento local do centro do clarão, em px, a partir do centro do player.
    /// @param {Struct.Vector2} _direction Direção da mira, horizontal, diagonal ou vertical.
    /// @return {Struct.Vector2} X para a frente, sempre positivo; Y para baixo.
    get_muzzle_offset = function(_direction) {
        if (_direction.y == 0) return new Vector2(12, 0);
        if (_direction.x == 0) return new Vector2(0, -13);
        if (_direction.y < 0) return new Vector2(8, -7);

        return new Vector2(9, 5);
    }

    muzzle_flash_time = 0;
    muzzle_flash_offset = new Vector2(0, 0);
    muzzle_flash_frame = 0;
    muzzle_flash_yscale = 1;

    /// @desc Dispara na direção da mira, se o botão estiver apertado, a espera tiver passado e o
    /// jogador não estiver no recuo.
    /// @return {Bool} `true` se o tiro nasceu.
    try_fire = function() {
        if (fire_cooldown > 0) return false;
        if (state_machine.is_state("hurt")) return false;
        if (!obj_game.fire.check()) return false;

        var _offset = get_muzzle_offset(aim_direction);
        var _muzzle = new Vector2(x + _offset.x * facing, y + _offset.y);

        /// @type {Id.Instance.obj_bullet}
        var _bullet = instance_create_layer(_muzzle.x, _muzzle.y, LAYER_PROJECTILES, obj_bullet);

        _bullet.launch(aim_direction);
        fire_cooldown = FIRE_COOLDOWN;

        var _diagonal = aim_direction.x != 0 && aim_direction.y != 0;

        muzzle_flash_offset.set(_offset.x * facing, _offset.y);
        muzzle_flash_frame = _diagonal ? 1 : 0;
        muzzle_flash_yscale = (_diagonal && aim_direction.y > 0) ? -1 : 1;
        muzzle_flash_time = MUZZLE_FLASH_TIME;

        return true;
    }
#endregion

#region Power-ups
    ignores_friction = false;
    high_jump = false;
    double_jump = false;

    /// @desc Liga o efeito que anula a fricção de meios como a água.
    grant_frictionless = function() {
        ignores_friction = true;
    }

    /// @desc Liga o efeito que multiplica o impulso do pulo.
    grant_high_jump = function() {
        high_jump = true;
    }

    /// @desc Liga o efeito que concede um pulo extra e libera o pulo aéreo atual.
    grant_double_jump = function() {
        double_jump = true;
        air_jump_used = false;
    }
#endregion

#region Estados
    input_x = 0;
    in_water = false;
    physics_factor = 1;
    air_jump_used = false;
    state_machine = new StateMachine();

    /// @desc Aplica a regra horizontal do chão.
    apply_ground_movement = function() {
        velocity.x = input_x * MOVEMENT_SPEED * physics_factor;
    }

    /// @desc Aplica a regra horizontal do ar, preservando a inércia na mesma direção.
    apply_air_movement = function() {
        var _air_speed = MOVEMENT_SPEED * AIR_FACTOR * physics_factor;

        if (input_x == 0) {
            velocity.x = clamp(velocity.x, -_air_speed, _air_speed);
            return;
        }

        if (input_x == sign(velocity.x)) {
            velocity.x = input_x * max(_air_speed, abs(velocity.x));
            return;
        }

        velocity.x = input_x * _air_speed;
    }

    /// @desc Impulso do pulo, já com o fator do power-up de pulo alto.
    /// @return {Real}
    get_jump_speed = function() {
        return JUMP_SPEED * (high_jump ? HIGH_JUMP_FACTOR : 1);
    }

    /// @desc Consome o buffer e aplica o impulso do pulo, se houver aperto.
    /// @return {Bool}
    try_jump = function() {
        if (!obj_game.jump.check_pressed(true)) return false;

        obj_game.jump.consume_press();
        velocity.y = -get_jump_speed() * physics_factor;
        state_machine.change_state("jump");

        return true;
    }

    /// @desc Consome o buffer e aplica o pulo extra com o fator do pulo duplo, se ainda houver um.
    /// @return {Bool}
    try_air_jump = function() {
        if (!double_jump || air_jump_used) return false;

        var _terminal_speed = TERMINAL_SPEED * physics_factor;

        if (velocity.y >= _terminal_speed) return false;
        if (!obj_game.jump.check_pressed(true)) return false;

        obj_game.jump.consume_press();
        air_jump_used = true;
        velocity.y = -get_jump_speed() * DOUBLE_JUMP_FACTOR * physics_factor;
        state_machine.change_state("jump");

        return true;
    }

    /// @desc Chão parado; a regra horizontal é a mesma do walk.
    on_idle_update = function() {
        apply_ground_movement();

        if (!is_grounded()) {
            state_machine.change_state("fall");
            return;
        }

        if (try_jump()) return;

        if (input_x != 0) state_machine.change_state("walk");
    }

    /// @desc Chão em movimento.
    on_walk_update = function() {
        apply_ground_movement();

        if (!is_grounded()) {
            state_machine.change_state("fall");
            return;
        }

        if (try_jump()) return;

        if (input_x == 0) state_machine.change_state("idle");
    }

    /// @desc Subida: controle aéreo e corte ao soltar.
    on_jump_update = function() {
        apply_air_movement();

        if (obj_game.jump.check_released() && velocity.y < 0) {
            velocity.y *= JUMP_CUT;
        }

        if (velocity.y >= 0) state_machine.change_state("fall");
    }

    /// @desc Queda: controle aéreo e pouso, com pulo do chão ou aéreo se o buffer estiver ativo.
    on_fall_update = function() {
        if (is_grounded()) {
            apply_ground_movement();

            if (try_jump()) return;

            state_machine.change_state(input_x == 0 ? "idle" : "walk");
            return;
        }

        apply_air_movement();

        if (try_air_jump()) return;
    }

    /// @desc Mantém o impulso do recuo e devolve o controle quando o travamento acaba.
    on_hurt_update = function() {
        if (state_machine.time < HURT_LOCK_FRAMES) return;

        state_machine.change_state("fall");
    }

#endregion

#region Animação
    WALK_FRAME_COUNT = 8;

    /// @desc Distância percorrida, em px, para avançar um quadro da caminhada.
    WALK_FRAME_DISTANCE = 4;

    LEGS_IDLE = 0;
    LEGS_IDLE_UP = 1;
    WALK_JUMP_FRAME = 4;
    WALK_FALL_FRAME = 6;
    WALK_FALL_TERMINAL_FRAME = 3;

    TORSO_HORIZONTAL = 0;
    TORSO_DIAGONAL_UP = 1;
    TORSO_UP = 2;
    TORSO_DIAGONAL_DOWN = 3;

    /// @desc Deslocamento vertical do torso em cada quadro da caminhada, em px.
    WALK_TORSO_BOB_Y = [0, 0, 1, 0, 0, 0, 1, 0];

    /// @desc Deslocamento vertical do torso parado, em px.
    IDLE_TORSO_OFFSET_Y = 1;

    legs_sprite = spr_player_legs_idle;
    legs_frame = LEGS_IDLE;
    torso_frame = TORSO_HORIZONTAL;
    torso_offset_y = 0;
    walk_distance = 0;
    walk_frame = 0;

    /// @desc Prepara a aparência ao entrar no estado parado.
    on_idle_create = function() {
        legs_sprite = spr_player_legs_idle;
        legs_frame = (aim_direction.x == 0 && aim_direction.y < 0)
            ? LEGS_IDLE_UP : LEGS_IDLE;
        torso_offset_y = IDLE_TORSO_OFFSET_Y;
    }

    /// @desc Reinicia o ciclo de caminhada ao entrar no estado.
    on_walk_create = function() {
        legs_sprite = spr_player_legs_walk;
        legs_frame = 0;
        torso_offset_y = WALK_TORSO_BOB_Y[0];
        walk_distance = 0;
        walk_frame = 0;
    }

    /// @desc Fixa a pose de subida ao entrar no estado.
    on_jump_create = function() {
        legs_sprite = spr_player_legs_walk;
        legs_frame = WALK_JUMP_FRAME;
        torso_offset_y = WALK_TORSO_BOB_Y[WALK_JUMP_FRAME];
    }

    /// @desc Fixa a pose de queda ao entrar no estado.
    on_fall_create = function() {
        legs_sprite = spr_player_legs_walk;
        legs_frame = WALK_FALL_FRAME;
        torso_offset_y = WALK_TORSO_BOB_Y[WALK_FALL_FRAME];
    }

    /// @desc Fixa a pose de queda e o travamento ao entrar no recuo.
    on_hurt_create = function() {
        legs_sprite = spr_player_legs_walk;
        legs_frame = WALK_FALL_FRAME;
        torso_offset_y = WALK_TORSO_BOB_Y[WALK_FALL_FRAME];
    }

    /// @desc Quadro do torso correspondente à direção da mira.
    /// @return {Real}
    get_torso_frame = function() {
        if (aim_direction.y == 0) return TORSO_HORIZONTAL;
        if (aim_direction.y < 0) {
            return aim_direction.x == 0 ? TORSO_UP : TORSO_DIAGONAL_UP;
        }

        return TORSO_DIAGONAL_DOWN;
    }

    /// @desc Avança a caminhada pela distância percorrida e atualiza o torso pela mira.
    update_appearance = function() {
        if (state_machine.is_state("walk")) {
            walk_frame = floor(walk_distance / WALK_FRAME_DISTANCE) % WALK_FRAME_COUNT;
            legs_frame = walk_frame;
            torso_offset_y = WALK_TORSO_BOB_Y[walk_frame];
        } else if (state_machine.is_state("idle")) {
            legs_frame = (aim_direction.x == 0 && aim_direction.y < 0)
                ? LEGS_IDLE_UP : LEGS_IDLE;
        } else if (state_machine.is_state("fall")) {
            var _terminal_speed = TERMINAL_SPEED * physics_factor;

            legs_frame = velocity.y >= _terminal_speed
                ? WALK_FALL_TERMINAL_FRAME : WALK_FALL_FRAME;
        }

        torso_frame = get_torso_frame();
    }
#endregion

#region Registro
    state_machine
        .add_state(new State("idle").set_create(on_idle_create).set_update(on_idle_update))
        .add_state(new State("walk").set_create(on_walk_create).set_update(on_walk_update))
        .add_state(new State("jump").set_create(on_jump_create).set_update(on_jump_update))
        .add_state(new State("fall").set_create(on_fall_create).set_update(on_fall_update))
        .add_state(new State("hurt").set_create(on_hurt_create).set_update(on_hurt_update));
#endregion

#region Hooks
    /// @desc Passo em x bloqueado: tenta subir um degrau antes de parar.
    /// @param {Id.Instance} _instance Instância que bloqueou o passo.
    on_x_blocked = function(_instance) {
        if (try_step_up(sign(velocity.x))) return;

        velocity.x = 0;
        velocity_remainder.x = 0;
    }

    /// @desc Passo em x efetivado: tenta colar no chão da rampa.
    on_x_moved = function() {
        try_step_down(sign(velocity.x));
    }
#endregion

#region Degraus
    /// @desc Sobe 1px sobre degrau ou rampa, cobrando o custo da subida.
    /// @param {Real} _dir Direção do passo: -1, 0 ou 1.
    /// @return {Bool}
    try_step_up = function(_dir) {
        if (_dir == 0) return false;

        var _above = instance_place(x + _dir, y - 1, obj_solid);

        if (_above != noone) return false;
        if (!is_grounded()) return false;

        x += _dir;
        y--;
        velocity_remainder.y = 0;
        velocity_remainder.x -= _dir * SLOPE_STEP_PENALTY;
        velocity_remainder.x = clamp(velocity_remainder.x, -SLOPE_MAX_PENALTY, SLOPE_MAX_PENALTY);

        return true;
    }

    /// @desc Desce 1px para acompanhar rampa, sem sair de beiras.
    /// @param {Real} _dir Direção do passo: -1, 0 ou 1.
    /// @return {Bool}
    try_step_down = function(_dir) {
        if (velocity.y < 0) return false;

        if (instance_place(x, y + 1, obj_solid) != noone) return false;
        if (instance_place(x, y + 2, obj_solid) == noone) return false;
        if (instance_place(x - _dir, y + 1, obj_solid) == noone) return false;

        y++;
        return true;
    }
#endregion
