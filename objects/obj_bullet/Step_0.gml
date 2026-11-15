wave_time += 1;
hit = false;
move();

if (hit || is_beyond_camera()) {
    instance_destroy();
}
