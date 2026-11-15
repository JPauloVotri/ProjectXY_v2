# Estado

Máquina de estados dividida entre `scripts/scr_state` (o estado) e `scripts/scr_state_machine` (o controle). Um `State` é dado e callbacks; a `StateMachine` guarda o estado atual, conta os frames nele e faz a troca. Requer GML 2.3 ou superior (usa construtores e `static`).

Este documento é a fonte de verdade do sistema. Os comentários `///` no código alimentam o autocomplete e a validação de tipos do Feather.

## Convenções

- **Estado é dado, não comportamento.** `State` guarda três callbacks opcionais; quem decide quando trocar é o próprio estado, dentro do `update`.
- **Os callbacks são métodos do ator**, nunca lambdas inline. A ligação do `self` acontece na **criação** da função: uma anônima dentro de `set_update` nasceria no escopo do `State` e não enxergaria `velocity`, `input_x` nem os hooks do ator.
- **`time` conta frames no estado**, começa em `0` no `create` e o primeiro `update` vê `0`.
- **Um estado por comportamento.** Se dois estados têm a mesma regra, eles só se justificam pelo nome — útil quando a animação chegar.
- **`__states` é privado.** A API de registro é `add_state`.

## Referência

### `State`

| Campo | Tipo | Papel |
|---|---|---|
| `name` | `String` | identificador usado na troca |
| `create` | `Function` | roda ao entrar; opcional |
| `update` | `Function` | roda a cada frame no estado; opcional |
| `destroy` | `Function` | roda ao sair; opcional |

| Método | Retorna | Descrição |
|---|---|---|
| `set_create(_f)` | `State` (self) | define o callback de entrada |
| `set_update(_f)` | `State` (self) | define o callback de frame |
| `set_destroy(_f)` | `State` (self) | define o callback de saída |

Os setters são `static` — as funções são compartilhadas entre todos os estados; só os campos são por instância. Retornam a própria instância para encadear.

### `StateMachine`

| Campo | Tipo | Papel |
|---|---|---|
| `state` | `State` | estado atual; `undefined` antes do primeiro registro |
| `time` | `Real` | frames no estado atual; zerado a cada troca |

| Método | Retorna | Descrição |
|---|---|---|
| `add_state(_state)` | `StateMachine` (self) | registra; o primeiro vira o estado atual e roda o `create` |
| `change_state(_name)` | — | valida, destrói o atual, zera `time` e roda o `create` do novo |
| `update()` | — | roda o `update` do estado e incrementa `time` |
| `is_state(_name)` | `Bool` | verdadeiro quando o estado atual é o de nome informado |

### Ciclo de vida

| Momento | O que roda |
|---|---|
| primeira chamada de `add_state` | `create` do primeiro estado |
| `change_state` | `destroy` do atual, depois `create` do novo |
| `update` | `update` do estado atual, depois `time++` |

## Armadilhas

- **Lambda inline perde o `self` do ator.** `set_update(function() { velocity.x = 0; })` estoura, porque essa função nasce dentro de `State.set_update`, cujo `self` é o `State`. Declare o método no ator e passe a referência.
- **A gravidade roda antes da máquina, e isso é intencional.** No player, o impulso do pulo é absoluto (`velocity.y = -get_jump_speed()`) e precisa sobrescrever o `+GRAVITY` do frame. Inverter a ordem faz o primeiro frame do pulo valer `-get_jump_speed() + GRAVITY`.
- **Troca dentro do `update` não roda o estado novo no mesmo frame.** A máquina atualiza um estado por frame; quando o callback troca, a conta do `time` daquele frame fica com o estado novo em `0`.
- **`change_state` para o mesmo estado reinicia.** Não há atalho: o `destroy` roda e o `create` também. Útil para reiniciar, surpreendente se você esperava um no-op.
- **Nome inexistente não troca nem destrói.** Avisa por `show_debug_message` e retorna; o estado atual continua ativo.
- **Duplicata em `add_state` mantém o primeiro.** Avisa e ignora o segundo registro.

## Exemplos

Declarar e registrar:

```gml
state_machine = new StateMachine();

on_idle_update = function() {
    velocity.x = 0;
}

state_machine.add_state(new State("idle").set_update(on_idle_update));
```

Trocar de estado com `create` e `destroy`:

```gml
on_jump_create = function() {
    velocity.y = -JUMP_SPEED;
}

on_jump_destroy = function() {
    sprite_index = spr_player;
}

jump_state = new State("jump")
    .set_create(on_jump_create)
    .set_destroy(on_jump_destroy)
    .set_update(on_jump_update);
```

Usar `time` para uma janela fixa:

```gml
on_hurt_update = function() {
    if (time < 20) return;

    state_machine.change_state("idle");
}
```
