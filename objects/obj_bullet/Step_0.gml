wave_time += 1;
hit = false;
move();

/// @type {Id.Instance.obj_enemy}
var _enemy = instance_place(x, y, obj_enemy);

if (_enemy != noone) {
    _enemy.take_damage(BULLET_DAMAGE);
    hit = true;
}

if (hit || is_beyond_camera()) {
    instance_destroy();
}
