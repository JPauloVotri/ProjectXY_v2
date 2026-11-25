if (surface_exists(view_surf)) {
    draw_surface_part(view_surf, frac(x), frac(y), game_width, game_height, 0, 0);
}

/// @type {Id.Instance.obj_player}
var _player = instance_find(obj_player, 0);

if (_player != noone && _player.is_dead()) {
    draw_set_color(c_black);
    draw_rectangle(0, 0, game_width - 1, game_height - 1, false);
    _player.draw_death_overlay(x, y);

    return;
}

if (_player != noone) {
    draw_health_hud(_player);

    /// @type {Asset.GMRoom}
    var _room_asset = room;

    draw_map_debug(_room_asset, _player);
}
