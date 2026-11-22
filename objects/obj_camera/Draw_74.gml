if (surface_exists(view_surf)) {
    draw_surface_part(view_surf, frac(x), frac(y), game_width, game_height, 0, 0);
}

/// @type {Id.Instance.obj_player}
var _player = instance_find(obj_player, 0);

if (_player != noone) {
    draw_health_hud(_player);
}
