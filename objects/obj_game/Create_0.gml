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

    // TODO: remover depois — entrada de teste do power-up de nado.
    debug_swim = input_manager.create_input()
        .add_keyboard_key(ord("T"));
#endregion
