/// @desc Desenha o próprio sprite, todo branco quando `_flashing` é verdadeiro.
/// @param {Bool} _flashing Se o desenho deve sair branco.
function draw_self_flashing(_flashing) {
    if (_flashing) {
        gpu_set_fog(true, c_white, 0, 0);
    }

    draw_self();

    gpu_set_fog(false, c_white, 0, 0);
}
