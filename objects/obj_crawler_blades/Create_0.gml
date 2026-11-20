#region Configuração
    /// @type {Id.Instance.obj_crawler}
    parent = noone;

    /// @desc Quadros de animação por pixel andado: a arte foi desenhada a um quadro por pixel.
    BLADE_FRAMES_PER_PIXEL = 1;

    /// @desc Ligado pelo crawler enquanto o acerto branqueia o desenho.
    flashing = false;

    image_speed = 0;

    /// @desc Desenhado pelo crawler; a instância existe só para guardar a animação.
    visible = false;
#endregion

#region Animação
    /// @desc Cola nas lâminas no corpo e roda a animação pela distância andada no sentido
    /// informado por ele.
    /// @param {Real} _moved Pixels andados pelo corpo desde o último frame.
    /// @param {Real} _spin Signo do giro no deslocamento: -1, 0 ou 1.
    follow = function(_moved, _spin) {
        var _delta = _moved * BLADE_FRAMES_PER_PIXEL * _spin;

        image_index = ((image_index + _delta) % image_number + image_number) % image_number;

        x = parent.x;
        y = parent.y;
    }
#endregion
