var _event = async_load[? "event_type"];
var _pad = async_load[? "pad_index"];

if (_event == "gamepad discovered") {
    show_debug_message("[input] descoberto no slot " + string(_pad));

    if (inputs.gamepad < 0) inputs.gamepad = _pad;
} else if (_event == "gamepad lost") {
    show_debug_message("[input] perdido do slot " + string(_pad));

    if (inputs.gamepad == _pad) {
        inputs.gamepad = -1;
        inputs.refresh_gamepad();
    }
}
