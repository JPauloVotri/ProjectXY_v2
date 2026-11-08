var _grounded = is_grounded();
var _input = obj_game.right.check() - obj_game.left.check();

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

if (obj_game.jump.check_pressed(true) && _grounded) {
    obj_game.jump.consume_press();
    velocity.y = -JUMP_SPEED;
} else if (obj_game.jump.check_released() && velocity.y < 0) {
    velocity.y *= JUMP_CUT;
}

move();
