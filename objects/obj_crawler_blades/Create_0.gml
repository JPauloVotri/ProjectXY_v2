#region Configuração
    /// @type {Id.Instance.obj_crawler}
    parent = noone;

    /// @desc Pixels do sprite que ficam enterrados na superfície seguida.
    SURFACE_OVERLAP = 1;

    /// @desc Diâmetro que rola: as pontas das lâminas menos a parte enterrada.
    BLADE_DIAMETER = sprite_width - SURFACE_OVERLAP;

    /// @desc Giro, em graus, que cada frame da animação representa (medido na arte).
    BLADE_FRAME_ANGLE = 9;

    /// @desc Quantas vezes a rolagem pura: 1 não escorrega, acima disso gira mais rápido.
    BLADE_ROLL_FACTOR = 1;

    /// @desc Ligado pelo crawler enquanto o acerto branqueia o desenho.
    flashing = false;

    image_speed = 0;
#endregion

#region Animação
    /// @desc Cola nas lâminas no corpo e roda a animação pela distância andada no sentido
    /// informado por ele.
    /// @param {Real} _moved Pixels andados pelo corpo desde o último frame.
    /// @param {Real} _spin Signo do giro no deslocamento: -1, 0 ou 1.
    follow = function(_moved, _spin) {
        var _degrees_per_pixel = 360 / (pi * BLADE_DIAMETER);
        var _delta = _moved * _degrees_per_pixel / BLADE_FRAME_ANGLE * _spin * BLADE_ROLL_FACTOR;

        image_index = ((image_index + _delta) % image_number + image_number) % image_number;

        x = parent.x;
        y = parent.y;
    }
#endregion
