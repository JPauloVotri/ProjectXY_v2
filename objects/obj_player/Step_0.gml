var _grounded = is_grounded();
var _input = keyboard_check(vk_right) - keyboard_check(vk_left);

if (_grounded) {
    velocity.x = _input * MOVEMENT_SPEED;
} else if (_input == 0) {
    velocity.x = clamp(velocity.x, -AIR_SPEED, AIR_SPEED);
} else {
    var _speed = (_input == sign(velocity.x)) ? max(AIR_SPEED, abs(velocity.x)) : AIR_SPEED;

    velocity.x = _input * _speed;
}

velocity.y += GRAVITY;

if (velocity.y > TERMINAL_SPEED) {
    velocity.y = TERMINAL_SPEED;
}

if (_grounded && keyboard_check_pressed(vk_space)) {
    velocity.y = -JUMP_SPEED;
} else if (keyboard_check_released(vk_space) && velocity.y < 0) {
    velocity.y *= JUMP_CUT;
}

move();
