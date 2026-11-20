#region Entrada
    input_manager = new InputManager();
    input_manager.refresh_gamepad();

    left = input_manager.create_input()
        .add_keyboard_key(vk_left)
        .add_keyboard_key(ord("A"))
        .add_gamepad_button(gp_padl)
        .add_gamepad_left_stick(INPUT_AXIS.LEFT);

    right = input_manager.create_input()
        .add_keyboard_key(vk_right)
        .add_keyboard_key(ord("D"))
        .add_gamepad_button(gp_padr)
        .add_gamepad_left_stick(INPUT_AXIS.RIGHT);

    jump = input_manager.create_input()
        .add_keyboard_key(vk_space)
        .add_gamepad_button(gp_face1);

    fire = input_manager.create_input()
        .add_keyboard_key(ord("J"))
        .add_keyboard_key(ord("C"))
        .add_gamepad_button(gp_face3);

    aim = input_manager.create_input()
        .add_keyboard_key(vk_lshift)
        .add_gamepad_button(gp_shoulderr);

    aim_up = input_manager.create_input()
        .add_keyboard_key(ord("W"))
        .add_keyboard_key(vk_up)
        .add_gamepad_button(gp_padu);

    aim_down = input_manager.create_input()
        .add_keyboard_key(ord("S"))
        .add_keyboard_key(vk_down)
        .add_gamepad_button(gp_padd);

    restart = input_manager.create_input()
        .add_keyboard_key(vk_f5);

    /// @desc Pausa; enquanto não há menu, fecha o jogo.
    pause = input_manager.create_input()
        .add_keyboard_key(vk_escape)
        .add_gamepad_button(gp_start);

    // TODO: remover depois — entrada de teste do power-up de nado.
    debug_swim = input_manager.create_input()
        .add_keyboard_key(ord("P"));

    // TODO: remover depois — entrada de teste do power-up de pulo alto.
    debug_high_jump = input_manager.create_input()
        .add_keyboard_key(ord("O"));

    // TODO: remover depois — entrada de teste do power-up de pulo duplo.
    debug_double_jump = input_manager.create_input()
        .add_keyboard_key(ord("I"));
#endregion
