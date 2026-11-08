input_x = obj_game.right.check() - obj_game.left.check();

if (input_x != 0) set_facing(input_x);

velocity.y += GRAVITY;

if (velocity.y > TERMINAL_SPEED) {
    velocity.y = TERMINAL_SPEED;
}

state_machine.update();
move();
