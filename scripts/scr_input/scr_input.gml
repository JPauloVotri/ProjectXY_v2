/// @desc Direções dos analógicos do controle.
enum INPUT_AXIS {
    RIGHT,
    UP,
    LEFT,
    DOWN,
}

/// @desc Agrupa fontes de teclado e controle e acompanha o estado temporal da entrada.
/// @param {Struct.InputManager} _manager Gerenciador da entrada.
function Input(_manager) constructor {
    #region Estado
        __manager = _manager;
        __time = 0;
        __sources = [];
    #endregion

    #region Atualização
        /// @desc Avalia as fontes e avança o estado; chamado pelo gerenciador a cada frame.
        update = function() {
            var _active = false;
            var _len = array_length(__sources);

            for (var _i = 0; _i < _len; _i++) {
                if (__sources[_i].check()) {
                    _active = true;
                    break;
                }
            }

            if (_active) {
                __time = __time > 0 ? __time + 1 : 1;
                return;
            }

            if (__time > 0) {
                __time = -(__manager.buffer + 1);
                return;
            }

            __time = min(__time + 1, 0);
        }
    #endregion

    #region Fontes
        /// @desc Registra uma tecla como fonte; pressioná-la ativa a entrada.
        /// @param {Real} _key Tecla a verificar.
        /// @return {Struct.Input} Esta instância.
        add_keyboard_key = function(_key) {
            var _key_struct = {
                button: _key,
                check: function() {
                    return keyboard_check(button);
                }
            };

            array_push(__sources, _key_struct);
            return self;
        }

        /// @desc Registra um botão do controle ativo como fonte da entrada.
        /// @param {Real} _button Botão a verificar.
        /// @return {Struct.Input} Esta instância.
        add_gamepad_button = function(_button) {
            var _owner = self;
            var _key_struct = {
                creator: _owner,
                button: _button,
                check: function() {
                    if (creator.__manager.gamepad < 0) return false;

                    return gamepad_button_check(creator.__manager.gamepad, button);
                }
            };

            array_push(__sources, _key_struct);
            return self;
        }

        /// @desc Registra uma direção do analógico esquerdo, respeitando a zona morta.
        /// @param {Enum.INPUT_AXIS} _direction Direção em INPUT_AXIS.
        /// @return {Struct.Input} Esta instância.
        add_gamepad_left_stick = function(_direction) {
            var _owner = self;
            var _key_struct = {
                creator: _owner,
                axis: _direction == INPUT_AXIS.RIGHT || _direction == INPUT_AXIS.LEFT
                    ? gp_axislh
                    : gp_axislv,
                dir: _direction == INPUT_AXIS.RIGHT || _direction == INPUT_AXIS.DOWN ? 1 : -1,
                check: function() {
                    if (creator.__manager.gamepad < 0) return false;

                    return gamepad_axis_value(creator.__manager.gamepad, axis) * dir
                        >= creator.__manager.deadzone;
                }
            };

            array_push(__sources, _key_struct);
            return self;
        }

        /// @desc Registra uma direção do analógico direito, respeitando a zona morta.
        /// @param {Enum.INPUT_AXIS} _direction Direção em INPUT_AXIS.
        /// @return {Struct.Input} Esta instância.
        add_gamepad_right_stick = function(_direction) {
            var _owner = self;
            var _key_struct = {
                creator: _owner,
                axis: _direction == INPUT_AXIS.RIGHT || _direction == INPUT_AXIS.LEFT
                    ? gp_axisrh
                    : gp_axisrv,
                dir: _direction == INPUT_AXIS.RIGHT || _direction == INPUT_AXIS.DOWN ? 1 : -1,
                check: function() {
                    if (creator.__manager.gamepad < 0) return false;

                    return gamepad_axis_value(creator.__manager.gamepad, axis) * dir
                        >= creator.__manager.deadzone;
                }
            };

            array_push(__sources, _key_struct);
            return self;
        }
    #endregion

    #region Consultas
        /// @desc Verdadeiro enquanto a entrada está pressionada.
        /// @return {Bool}
        check = function() {
            return __time > 0;
        }

        /// @desc Início do pressionamento; com buffer, os primeiros frames pressionados.
        /// @param {Bool} _buffered Inclui a janela de buffer configurada.
        /// @return {Bool}
        check_pressed = function(_buffered = false) {
            if (_buffered) return __time > 0 && __time <= __manager.buffer;
            return __time == 1;
        }

        /// @desc Liberação; com buffer, mantém verdadeiro durante a janela.
        /// @param {Bool} _buffered Inclui a janela de buffer de liberação.
        /// @return {Bool}
        check_released = function(_buffered = false) {
            if (_buffered) return __time < 0;
            return __time == -(__manager.buffer + 1);
        }

        /// @desc Pressionamento inicial e repetições após o atraso e a cada intervalo.
        /// @param {Real} _initial_delay Frames até iniciar as repetições.
        /// @param {Real} _interval Frames entre repetições.
        /// @return {Bool}
        check_stutter = function(_initial_delay, _interval) {
            if (__time == 1) return true;
            if (_interval <= 0) return false;

            return __time - _initial_delay > 0 && (__time - _initial_delay) % _interval == 0;
        }
    #endregion

    #region Consumo
        /// @desc Consome o buffer de aperto, para `check_pressed(true)` não repetir.
        consume_press = function() {
            __time = max(__manager.buffer + 1, 2);
        }

        /// @desc Consome o buffer de liberação, para `check_released(true)` não repetir.
        consume_release = function() {
            __time = 0;
        }
    #endregion
}
