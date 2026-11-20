input_manager.run();

if (pause.check_pressed()) game_end();
if (restart.check_released()) game_restart();
