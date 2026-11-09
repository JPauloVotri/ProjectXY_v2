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

    view_surf = -1;
#endregion

#region Atualização
    /// @desc Acumula a velocidade do alvo no offset e posiciona a view.
    update_view = function() {
        if (!instance_exists(target)) return;

        var _step_x = clamp(target.velocity.x, -look_ahead_rate, look_ahead_rate);
        var _step_y = clamp(target.velocity.y, -look_ahead_rate, look_ahead_rate);

        offset_x = clamp(offset_x + _step_x, -look_ahead_max_x, look_ahead_max_x);
        offset_y = clamp(offset_y + _step_y, -look_ahead_max_y, look_ahead_max_y);

        x = clamp(target.x + offset_x - game_width * .5, 0, room_width - game_width);
        y = clamp(target.y + offset_y - game_height * .5, 0, room_height - game_height);

        camera_set_view_pos(view_camera[0], floor(x), floor(y));

        if (!surface_exists(view_surf)) {
            view_surf = surface_create(game_width + 1, game_height + 1);
            view_surface_id[0] = view_surf;
        }
    }
#endregion
