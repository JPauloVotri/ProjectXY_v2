#region Estado
    velocity = new Vector2();
    velocity_remainder = new Vector2();
#endregion

#region Hooks
    /// @desc Passo em x bloqueado: zera a velocidade e o resto horizontal.
    /// @param {Id.Instance} _instance Instância que bloqueou o passo.
    on_x_blocked = function(_instance) {
        velocity.x = 0;
        velocity_remainder.x = 0;
    }

    /// @desc Passo em y bloqueado: zera a velocidade e o resto vertical.
    /// @param {Id.Instance} _instance Instância que bloqueou o passo.
    on_y_blocked = function(_instance) {
        velocity.y = 0;
        velocity_remainder.y = 0;
    }

    /// @desc Roda depois de um passo em x efetivado.
    on_x_moved = function() {}

    /// @desc Roda depois de um passo em y efetivado.
    on_y_moved = function() {}
#endregion

#region Consultas
    /// @desc Verdadeiro quando há sólido 1px abaixo.
    /// @return {Bool}
    is_grounded = function() {
        return place_meeting(x, y + 1, obj_solid);
    }
#endregion

#region Movimento
    /// @desc Aplica a velocidade em passos de 1px por eixo, disparando os hooks.
    move = function() {
        velocity_remainder.add(velocity);
        var _amount = velocity_remainder.absolute().floor();
        _amount.x *= sign(velocity_remainder.x);
        _amount.y *= sign(velocity_remainder.y);

        if (_amount.magnitude() == 0) return;

        velocity_remainder.subtract(_amount);

        while (_amount.magnitude() > 0) {
            var _dir = _amount.normalized().round();

            if (_dir.x != 0) {
                var _collision_instance = instance_place(x + _dir.x, y, obj_solid);

                if (_collision_instance == noone) {
                    x += _dir.x;
                    on_x_moved();
                } else {
                    on_x_blocked(_collision_instance);
                }
            }

            if (_dir.y != 0) {
                var _collision_instance = instance_place(x, y + _dir.y, obj_solid);

                if (_collision_instance == noone) {
                    y += _dir.y;
                    on_y_moved();
                } else {
                    on_y_blocked(_collision_instance);
                }
            }

            _amount.subtract(_dir);
        }
    }
#endregion
