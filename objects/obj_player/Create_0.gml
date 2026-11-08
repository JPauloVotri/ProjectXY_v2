/// @desc Direção olhada, usada para espelhar o sprite e para consultas de lado.
enum FACING {
    LEFT = -1,
    RIGHT = 1,
}

event_inherited();

#region Constantes
    JUMP_SPEED = 3;
    JUMP_CUT = .5;
    MOVEMENT_SPEED = 1;
    AIR_SPEED = .5;
    SLOPE_STEP_PENALTY = 1;
    SLOPE_MAX_PENALTY = .99;
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

#region Estados
    input_x = 0;
    state_machine = new StateMachine();

    /// @desc Aplica a regra horizontal do chão.
    apply_ground_movement = function() {
        velocity.x = input_x * MOVEMENT_SPEED;
    }

    /// @desc Aplica a regra horizontal do ar, preservando a inércia na mesma direção.
    apply_air_control = function() {
        if (input_x == 0) {
            velocity.x = clamp(velocity.x, -AIR_SPEED, AIR_SPEED);
            return;
        }

        if (input_x == sign(velocity.x)) {
            velocity.x = input_x * max(AIR_SPEED, abs(velocity.x));
            return;
        }

        velocity.x = input_x * AIR_SPEED;
    }

    /// @desc Consome o buffer e aplica o impulso do pulo, se houver aperto.
    /// @return {Bool}
    try_jump = function() {
        if (!obj_game.jump.check_pressed(true)) return false;

        obj_game.jump.consume_press();
        velocity.y = -JUMP_SPEED;
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
        apply_air_control();

        if (obj_game.jump.check_released() && velocity.y < 0) {
            velocity.y *= JUMP_CUT;
        }

        if (velocity.y >= 0) state_machine.change_state("fall");
    }

    /// @desc Queda: controle aéreo e pouso, com pulo se o buffer estiver ativo.
    on_fall_update = function() {
        if (is_grounded()) {
            apply_ground_movement();

            if (try_jump()) return;

            state_machine.change_state(input_x == 0 ? "idle" : "walk");
            return;
        }

        apply_air_control();
    }

    state_machine
        .add_state(new State("idle").set_update(on_idle_update))
        .add_state(new State("walk").set_update(on_walk_update))
        .add_state(new State("jump").set_update(on_jump_update))
        .add_state(new State("fall").set_update(on_fall_update));
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
