var _traveled = (x - spawn_position.x) * travel_direction.x
    + (y - spawn_position.y) * travel_direction.y;
var _start = clamp(
    floor((_traveled - TRAIL_MUZZLE_CLEARANCE) / TRAIL_SPACING),
    0,
    TRAIL_LENGTH - 1
);

for (var _i = _start; _i >= 0; _i--) {
    var _wave = 0;

    if (_i > 0) {
        var _phase = wave_time * TRAIL_WAVE_SPEED + _i * TRAIL_WAVE_PHASE;
        _wave = dsin(_phase) * TRAIL_WAVE_AMPLITUDE;
    }

    draw_sprite(
        sprite_index,
        _i,
        round(x - travel_direction.x * TRAIL_SPACING * _i - travel_direction.y * _wave),
        round(y - travel_direction.y * TRAIL_SPACING * _i + travel_direction.x * _wave)
    );
}
