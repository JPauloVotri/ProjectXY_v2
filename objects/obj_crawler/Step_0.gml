state_machine.update();

event_inherited();

var _step_x = x - xprevious;
var _step_y = y - yprevious;
var _spin = sign(up.y * _step_x - up.x * _step_y);
var _moved = point_distance(0, 0, _step_x, _step_y);

blades.flashing = is_flashing();
blades.follow(state_machine.is_state("crawl") ? _moved : 0, _spin);
