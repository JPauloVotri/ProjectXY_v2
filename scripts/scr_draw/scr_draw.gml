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
