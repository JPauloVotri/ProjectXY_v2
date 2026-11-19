input_x = obj_game.right.check() - obj_game.left.check();

if (input_x != 0) set_facing(input_x);

var _aiming = obj_game.aim.check();
var _vertical = obj_game.aim_down.check() - obj_game.aim_up.check();
var _use_facing = _aiming || input_x != 0;

if (_use_facing && _vertical != 0) aim_vertical = _vertical;

var _aim_x = (_use_facing || _vertical == 0) ? facing : 0;
var _aim_y = _aiming ? aim_vertical : _vertical;

aim_direction.set(_aim_x, _aim_y);

fire_cooldown = max(fire_cooldown - 1, 0);

// TODO: remover depois — junto com a entrada `debug_swim` do obj_game.
if (obj_game.debug_swim.check_pressed()) {
    ignores_friction = !ignores_friction;
    show_debug_message("[power_up] sem fricção " + (ignores_friction ? "ligado" : "desligado"));
}

// TODO: remover depois — junto com a entrada `debug_high_jump` do obj_game.
if (obj_game.debug_high_jump.check_pressed()) {
    high_jump = !high_jump;
    show_debug_message("[power_up] pulo alto " + (high_jump ? "ligado" : "desligado"));
}

// TODO: remover depois — junto com a entrada `debug_double_jump` do obj_game.
if (obj_game.debug_double_jump.check_pressed()) {
    double_jump = !double_jump;
    air_jump_used = false;
    show_debug_message("[power_up] pulo duplo " + (double_jump ? "ligado" : "desligado"));
}

in_water = place_meeting(x, y, obj_water);
physics_factor = (in_water && !ignores_friction) ? WATER_FACTOR : 1;

velocity.y += GRAVITY * physics_factor;

var _terminal_speed = TERMINAL_SPEED * physics_factor;

if (velocity.y > _terminal_speed) {
    velocity.y = _terminal_speed;
}

state_machine.update();

if (is_grounded()) {
    air_jump_used = false;

    if (velocity.y > 0) {
        velocity.y = 0;
    }
}

var _previous_x = x;

move();

if (state_machine.is_state("walk")) {
    walk_distance += abs(x - _previous_x);
}

try_fire();

update_appearance();
