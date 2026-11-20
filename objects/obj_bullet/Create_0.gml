event_inherited();

#region Aparência
    image_speed = 0;
    TRAIL_LENGTH = sprite_get_number(sprite_index);
    TRAIL_SPACING = max(sprite_get_width(sprite_index) - 2, 1);

    /// @desc Distância mínima à frente da boca, em px, para um ponto do rastro aparecer.
    TRAIL_MUZZLE_CLEARANCE = 6;

    /// @desc Amplitude da ondulação do rastro, em px.
    TRAIL_WAVE_AMPLITUDE = 1;

    /// @desc Velocidade da ondulação, em graus por frame.
    TRAIL_WAVE_SPEED = 22.5;

    /// @desc Defasagem entre os círculos do rastro, em graus.
    TRAIL_WAVE_PHASE = 180;

    wave_time = 0;

    /// @desc Posição onde o tiro nasceu; o rastro só aparece à frente dela.
    spawn_position = new Vector2(x, y);
#endregion

#region Movimento
    BULLET_SPEED = 3;
    DESPAWN_MARGIN = 64;

    travel_direction = new Vector2(1, 0);
    hit = false;

    /// @desc Aponta e acelera o tiro; chamado por quem dispara, depois da criação.
    /// @param {Struct.Vector2} _direction Direção discreta da mira.
    launch = function(_direction) {
        travel_direction.copyFrom(_direction).normalize();
        velocity.copyFrom(travel_direction).multiply(BULLET_SPEED);
    }

    /// @desc Verdadeiro quando o tiro passou a margem para fora da view.
    /// @return {Bool}
    is_beyond_camera = function() {
        var _camera = view_camera[0];
        var _left = camera_get_view_x(_camera) - DESPAWN_MARGIN;
        var _top = camera_get_view_y(_camera) - DESPAWN_MARGIN;
        var _right = _left + camera_get_view_width(_camera) + DESPAWN_MARGIN * 2;
        var _bottom = _top + camera_get_view_height(_camera) + DESPAWN_MARGIN * 2;

        return x < _left || x > _right || y < _top || y > _bottom;
    }
#endregion

#region Dano
    BULLET_DAMAGE = 1;
#endregion

#region Impacto
    /// @desc Margem, em px, do centro do primeiro passo de contato até a superfície do alvo.
    CONTACT_OFFSET = 1;

    /// @desc Ponto onde a explosão nasce: primeiro contato do Step, já na superfície.
    contact_position = new Vector2(x, y);
    contact_found = false;

    /// @desc Guarda o primeiro contato do passo atual, ignorando os seguintes.
    /// @param {Real} _x Centro do tiro no passo de contato.
    /// @param {Real} _y Centro do tiro no passo de contato.
    /// @param {Real} _offset_x Direção do encosto no eixo x: -1, 0 ou 1.
    /// @param {Real} _offset_y Direção do encosto no eixo y: -1, 0 ou 1.
    record_contact = function(_x, _y, _offset_x, _offset_y) {
        if (contact_found) return;

        contact_found = true;
        contact_position.set(
            _x + _offset_x * CONTACT_OFFSET,
            _y + _offset_y * CONTACT_OFFSET
        );
    }

    /// @desc Marca o contato com inimigo depois de um passo de 1 px efetivado.
    /// @param {Real} _offset_x Direção do passo no eixo x: -1, 0 ou 1.
    /// @param {Real} _offset_y Direção do passo no eixo y: -1, 0 ou 1.
    record_enemy_contact = function(_offset_x, _offset_y) {
        /// @type {Id.Instance.obj_enemy}
        var _enemy = instance_place(x, y, obj_enemy);

        if (_enemy != noone && _enemy.current_health > 0) {
            record_contact(x, y, _offset_x, _offset_y);
        }
    }
#endregion

#region Hooks
    /// @desc Passo em x bloqueado: marca o tiro e guarda o contato com o sólido.
    /// @param {Id.Instance} _instance Instância que bloqueou o passo.
    on_x_blocked = function(_instance) {
        hit = true;
        record_contact(x + sign(velocity.x), y, sign(velocity.x), 0);
    }

    /// @desc Passo em y bloqueado: marca o tiro e guarda o contato com o sólido.
    /// @param {Id.Instance} _instance Instância que bloqueou o passo.
    on_y_blocked = function(_instance) {
        hit = true;
        record_contact(x, y + sign(velocity.y), 0, sign(velocity.y));
    }

    /// @desc Passo em x efetivado: guarda o contato se o tiro encostou um inimigo.
    on_x_moved = function() {
        record_enemy_contact(sign(velocity.x), 0);
    }

    /// @desc Passo em y efetivado: guarda o contato se o tiro encostou um inimigo.
    on_y_moved = function() {
        record_enemy_contact(0, sign(velocity.y));
    }
#endregion
