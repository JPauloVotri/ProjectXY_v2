var _direction = keyboard_check(vk_right) - keyboard_check(vk_left);

velocity.x = _direction * MOVEMENT_SPEED;
velocity.y += GRAVITY;

if (velocity.y > TERMINAL_SPEED) {
    velocity.y = TERMINAL_SPEED;
}

if (is_grounded() && keyboard_check_pressed(vk_space)) {
    velocity.y = -JUMP_SPEED;
}

move();
