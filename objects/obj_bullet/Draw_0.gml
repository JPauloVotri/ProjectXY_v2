for (var _i = TRAIL_LENGTH - 1; _i >= 0; _i--) {
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
