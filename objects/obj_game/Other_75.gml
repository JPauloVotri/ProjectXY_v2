var _event = async_load[? "event_type"];
var _pad = async_load[? "pad_index"];

if (_event == "gamepad discovered") {
    show_debug_message("[input] descoberto no slot " + string(_pad));

    if (input_manager.gamepad < 0) input_manager.gamepad = _pad;
} else if (_event == "gamepad lost") {
    show_debug_message("[input] perdido do slot " + string(_pad));

    if (input_manager.gamepad == _pad) {
        input_manager.gamepad = -1;
        input_manager.refresh_gamepad();
    }
}
