/// @desc Gerencia as entradas configuradas e atualiza o estado de cada uma.
/// @param {Real} _gamepad Índice do controle usado pelas entradas; -1 busca na inicialização.
/// @param {Real} _deadzone Limite mínimo de ativação dos analógicos.
function InputManager(_gamepad = -1, _deadzone = .4) constructor {
    __inputs = [];
    gamepad = _gamepad;
    deadzone = _deadzone;
    buffer = 5;

    /// @desc Adota o primeiro slot conectado, já que o índice varia por sistema.
    /// @return {Bool} `true` se encontrou um controle; caso contrário, `false`.
    refresh_gamepad = function() {
        var _count = gamepad_get_device_count();

        for (var _i = 0; _i < _count; _i++) {
            if (gamepad_is_connected(_i)) {
                gamepad = _i;
                return true;
            }
        }

        gamepad = -1;
        return false;
    }

    /// @desc Atualiza todas as entradas registradas; chamar a cada frame.
    run = function() {
        var _len = array_length(__inputs);

        for (var _i = 0; _i < _len; _i++) {
            __inputs[_i].update();
        }
    }

    /// @desc Cria e registra uma entrada vinculada a este gerenciador.
    /// @return {Struct.Input} A nova entrada.
    create_input = function() {
        var _input = new Input(self);
        array_push(__inputs, _input);
        return _input;
    }
}
