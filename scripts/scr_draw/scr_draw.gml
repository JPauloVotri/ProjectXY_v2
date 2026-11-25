#macro LAYER_ZONES "Zones"
#macro LAYER_WATER "Water"
#macro LAYER_EFFECTS "Effects"
#macro LAYER_PROJECTILES "Projectiles"
#macro LAYER_ACTORS "Actors"
#macro LAYER_TERRAIN "Terrain"
#macro LAYER_BACKGROUND "Background"
#macro LAYER_SYSTEMS "Systems"

/// @desc Desenha o próprio sprite, todo branco quando `_flashing` é verdadeiro.
/// @param {Bool} _flashing Se o desenho deve sair branco.
function draw_self_flashing(_flashing) {
    if (_flashing) {
        gpu_set_fog(true, c_white, 0, 0);
    }

    draw_self();

    gpu_set_fog(false, c_white, 0, 0);
}

/// @desc Desenha o HUD de vida e tanques no canto superior esquerdo da GUI.
/// @param {Id.Instance.obj_player} _player Jogador cujo estado é exibido.
function draw_health_hud(_player) {
    var _health = _player.current_health % _player.HEALTH_PER_TANK;
    var _full_tanks = _player.get_full_tank_count();
    var _full_text = (_full_tanks < 10 ? "0" : "") + string(_full_tanks);
    var _total_text = (_player.tanks < 10 ? "0" : "") + string(_player.tanks);

    draw_set_font(fnt_debug);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
    draw_text(4, 4, "health: " + string(_health));
    draw_text(4, 13, "tanks: " + _full_text + "/" + _total_text);
}

/// @desc Desenha o tile local e o global do player abaixo do HUD.
/// @param {Asset.GMRoom} _room_asset Room atual.
/// @param {Id.Instance.obj_player} _player Jogador seguido.
function draw_map_debug(_room_asset, _player) {
    var _tile = map_tile_position(_room_asset, _player.x, _player.y);

    draw_set_font(fnt_debug);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);

    if (is_undefined(_tile)) {
        draw_text(4, 22, "mapa: sem posição");

        return;
    }

    draw_text(
        4,
        22,
        "mapa: " + _tile.room_name +
        "  local " + string(_tile.local_x) + "," + string(_tile.local_y) +
        "  global " + string(_tile.global_x) + "," + string(_tile.global_y)
    );
}
