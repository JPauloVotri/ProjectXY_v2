#region Tela
    application_surface_enable(false);

    game_width = camera_get_view_width(view_camera[0]);
    game_height = camera_get_view_height(view_camera[0]);

    camera_set_view_size(view_camera[0], game_width + 1, game_height + 1);
    display_set_gui_size(game_width, game_height);
#endregion

#region Estado
    target = obj_player;

    offset_x = 0;
    offset_y = 0;

    look_ahead_max_x = 24;
    look_ahead_max_y = 8;
    look_ahead_rate = 1;

    zone_slide_rate = 2;
    slide_near = 16;
    view_precision = .01;

    desired_last_x = undefined;
    desired_last_y = undefined;

    view_surf = -1;
#endregion

#region Atualização
    /// @desc Acumula a velocidade do alvo no offset e posiciona a view.
    update_view = function() {
        if (!instance_exists(target)) return;

        var _step_x = clamp(target.velocity.x, -look_ahead_rate, look_ahead_rate);
        var _step_y = clamp(target.velocity.y, -look_ahead_rate, look_ahead_rate);

        offset_x += __offset_step(offset_x, _step_x, look_ahead_max_x);
        offset_y += __offset_step(offset_y, _step_y, look_ahead_max_y);

        var _view_x = target.x + offset_x - game_width * .5;
        var _view_y = target.y + offset_y - game_height * .5;
        var _view = __resolve_zones(_view_x, _view_y);

        __slide_to(_view.x, _view.y, _view_x, _view_y);

        camera_set_view_pos(view_camera[0], floor(x), floor(y));

        if (!surface_exists(view_surf)) {
            view_surf = surface_create(game_width + 1, game_height + 1);
            view_surface_id[0] = view_surf;
        }
    }

    /// @desc Passo do eixo: velocidade cheia longe do alvo, proporcional perto.
    /// @param {Real} _delta Distância até o alvo, com sinal.
    /// @param {Real} _rate Teto de deslocamento por frame.
    /// @param {Real} _near Distância, em px, em que a desaceleração começa.
    /// @return {Real} Deslocamento deste frame.
    __ease_step = function(_delta, _rate, _near) {
        return sign(_delta) * _rate * min(abs(_delta) / _near, 1);
    }

    /// @desc Passo do adiantamento, desacelerando ao chegar no teto do eixo.
    /// @param {Real} _offset Adiantamento atual.
    /// @param {Real} _step Velocidade do alvo já limitada por look_ahead_rate.
    /// @param {Real} _limit Teto do adiantamento no eixo.
    /// @return {Real} Deslocamento do adiantamento neste frame.
    __offset_step = function(_offset, _step, _limit) {
        var _delta = _limit * sign(_step) - _offset;

        return __ease_step(_delta, abs(_step), min(slide_near, _limit * .5));
    }

    /// @desc Passo de um eixo: correção da zona ou acompanhamento do alvo, assentando no limite.
    /// @param {Real} _pos Posição atual da view no eixo.
    /// @param {Real} _target Alvo já corrigido pela zona.
    /// @param {Real} _desired Desejado, sem as zonas.
    /// @param {Real} _last Desejado do frame anterior.
    /// @return {Real} Deslocamento do eixo neste frame.
    __axis_step = function(_pos, _target, _desired, _last) {
        if (_target != _desired) {
            var _delta = _target - _pos;

            return abs(_delta) <= 1 ? _delta : __ease_step(_delta, zone_slide_rate, slide_near);
        }

        var _follow = _desired - _last;

        if (_follow == 0) return 0;

        var _residual = _last - _pos;
        var _rate = look_ahead_rate + abs(_follow) * .5;

        if (_residual * _follow < 0) return _follow;

        return _follow + __ease_step(_residual, _rate, slide_near);
    }

    /// @desc Segue o alvo no eixo livre e corrige o eixo travado pela zona.
    /// @param {Real} _target_x Alvo já corrigido pelas zonas.
    /// @param {Real} _target_y
    /// @param {Real} _desired_x Desejado, sem as zonas.
    /// @param {Real} _desired_y
    __slide_to = function(_target_x, _target_y, _desired_x, _desired_y) {
        if (is_undefined(desired_last_x)) {
            x = _target_x;
            y = _target_y;
        } else {
            x += __axis_step(x, _target_x, _desired_x, desired_last_x);
            y += __axis_step(y, _target_y, _desired_y, desired_last_y);
        }

        desired_last_x = _desired_x;
        desired_last_y = _desired_y;

        x = clamp(round(x / view_precision) * view_precision, 0, room_width - game_width);
        y = clamp(round(y / view_precision) * view_precision, 0, room_height - game_height);
    }
#endregion

#region Zonas
    /// @desc Limita um eixo pela zona, só enquanto o alvo está sobre ela no outro.
    /// @param {Struct.Vector2} _pos Posição desejada; mutada no lugar.
    /// @param {Id.Instance.obj_camera_zone} _zone Zona consultada.
    __clamp_zone = function(_pos, _zone) {
        var _over_x = target.bbox_right > _zone.bbox_left
            && target.bbox_left < _zone.bbox_right;
        var _over_y = target.bbox_bottom > _zone.bbox_top
            && target.bbox_top < _zone.bbox_bottom;

        if (_over_x) {
            if (target.bbox_bottom <= _zone.bbox_top) {
                _pos.y = min(_pos.y, _zone.bbox_top - game_height);
            } else if (target.bbox_top >= _zone.bbox_bottom) {
                _pos.y = max(_pos.y, _zone.bbox_bottom);
            }
        }

        if (_over_y) {
            if (target.bbox_right <= _zone.bbox_left) {
                _pos.x = min(_pos.x, _zone.bbox_left - game_width);
            } else if (target.bbox_left >= _zone.bbox_right) {
                _pos.x = max(_pos.x, _zone.bbox_right);
            }
        }
    }

    /// @desc Aplica as zonas ao desejado e limita o resultado pela room.
    /// @param {Real} _x Desejado em x, ainda sem limites.
    /// @param {Real} _y Desejado em y, ainda sem limites.
    /// @return {Struct.Vector2} Posição corrigida, dentro da room.
    __resolve_zones = function(_x, _y) {
        var _pos = new Vector2(_x, _y);
        var _count = instance_number(obj_camera_zone);

        for (var _i = 0; _i < _count; _i++) {
            /// @type {Id.Instance.obj_camera_zone}
            var _zone = instance_find(obj_camera_zone, _i);

            if (_zone.secret && _zone.revealed) continue;

            __clamp_zone(_pos, _zone);
        }

        return _pos.set(
            clamp(_pos.x, 0, room_width - game_width),
            clamp(_pos.y, 0, room_height - game_height)
        );
    }
#endregion
