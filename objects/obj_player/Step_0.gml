input_x = obj_game.right.check() - obj_game.left.check();

if (input_x != 0) set_facing(input_x);

var _aiming = obj_game.aim.check();
var _vertical = obj_game.aim_down.check() - obj_game.aim_up.check();
var _use_facing = _aiming || input_x != 0;

var _ignores_down = !_use_facing && _vertical > 0;

if (!_ignores_down) {
    if (_use_facing && _vertical != 0) aim_vertical = _vertical;

    var _aim_x = (_use_facing || _vertical == 0) ? facing : 0;
    var _aim_y = _aiming ? aim_vertical : _vertical;

    aim_direction.set(_aim_x, _aim_y);
}

fire_cooldown = max(fire_cooldown - 1, 0);
muzzle_flash_time = max(muzzle_flash_time - 1, 0);

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

// TODO: remover depois — junto com a entrada `debug_health_tank` do obj_game.
if (obj_game.debug_health_tank.check_pressed()) {
    grant_health_tank();
    show_debug_message(
        "[vida] tanque ganho; vida " + string(current_health) + " (" +
        string(current_health % HEALTH_PER_TANK) + "); tanques " + string(tanks)
    );
}

// TODO: remover depois — junto com a entrada `debug_damage` do obj_game.
if (obj_game.debug_damage.check_stutter(30, 5) && take_damage(1)) {
    show_debug_message(
        "[vida] dano de teste; vida " + string(current_health) + " (" +
        string(current_health % HEALTH_PER_TANK) + "); tanques " + string(tanks)
    );
}

// TODO: remover depois — junto com a entrada `debug_heal` do obj_game.
if (obj_game.debug_heal.check_stutter(30, 5) && restore_health(1)) {
    show_debug_message(
        "[vida] cura de teste; vida " + string(current_health) + " (" +
        string(current_health % HEALTH_PER_TANK) + "); tanques " + string(tanks)
    );
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
