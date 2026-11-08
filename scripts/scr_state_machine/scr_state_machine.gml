/// @desc Gerencia o estado atual, o tempo decorrido nele e a troca entre estados.
function StateMachine() constructor {
    /// @type {Struct.State}
    state = undefined;
    /// @type {Struct<Struct.State>}
    __states = {};
    time = 0;

    /// @desc Troca o estado atual, destruindo o anterior e criando o novo.
    /// @param {String} _name Novo estado a ser ativado.
    static change_state = function(_name) {
        if (is_undefined(__states[$ _name])) {
            show_debug_message($"Tentando mudar para um State não existente: {_name}");
            return;
        }

        if (is_instanceof(state, State) && is_method(state.destroy)) {
            state.destroy();
        }

        state = __states[$ _name];
        time = 0;

        if (is_method(state.create)) {
            state.create();
        }
    }

    /// @desc Adiciona um estado à máquina; o primeiro vira o estado atual.
    /// @param {Struct.State} _state Estado a ser registrado na máquina.
    /// @return {Struct.StateMachine} A própria instância da máquina de estados.
    static add_state = function(_state) {
        if (!is_undefined(__states[$ _state.name])) {
            show_debug_message($"Um State com o name {_state.name} já existe " +
                "na StateMachine!");

            return self;
        }

        __states[$ _state.name] = _state;

        if (is_undefined(state)) {
            state = _state;

            if (is_method(state.create)) {
                state.create();
            }
        }

        return self;
    }

    /// @desc Atualiza o estado atual e incrementa o contador de tempo.
    static update = function() {
        if (!is_instanceof(state, State)) return;

        var _current = state;

        if (is_method(state.update)) {
            state.update();
        }

        if (state == _current) {
            time++;
        }
    }
}
