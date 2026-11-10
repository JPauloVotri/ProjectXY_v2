# Input

Sistema de entrada dividido entre `scripts/scr_input_manager` (o gerenciador) e `scripts/scr_input` (cada entrada). `objects/obj_game` é o dono único: cria o gerenciador, registra os inputs e mantém o slot do controle atualizado. Requer GML 2.3 ou superior (usa construtores e métodos de instância).

Este documento é a fonte de verdade do sistema. Os comentários `///` no código alimentam o autocomplete e a validação de tipos do Feather.

## Convenções

- **Uma entrada por ação, várias fontes por entrada.** `jump` escuta tecla e botão; a entrada responde se qualquer fonte responder.
- **Estado em um único inteiro.** `__time` positivo é frames pressionado, negativo é janela de liberação, zero é ociosa. Não há flags separadas.
- **`buffer` e `deadzone` são do gerenciador, não da entrada.** Ajustar a tolerância é uma linha em um lugar só.
- **O slot do controle é descoberto, nunca fixo.** O runner no Linux enumera cada dispositivo evdev como se fosse gamepad, então o índice varia por máquina.
- **`__` só é lido pelo próprio struct.** Quando um closure precisa da configuração, ela entra como campo público da fonte (`manager`): o `Input` lê o próprio privado uma vez e o resto conversa pelo público.
- **Nomes em snake_case.** `camelCase` fica reservado para tipos genéricos como `Vector2`.

## Referência

### Objetos

| Objeto | Papel |
|---|---|
| `obj_game` | dono do gerenciador (`input_manager`): registra os inputs, avança o estado e acompanha o controle |

`obj_game` é persistente e existe uma única vez, no `rm_room_1`. Salas futuras não devem colocá-lo de novo. O player lê `obj_game.left`, `obj_game.right` e `obj_game.jump` em tempo de execução — não cacheia no Create, porque a ordem de criação das instâncias não é garantida.

### `InputManager`

| Campo | Tipo | Papel |
|---|---|---|
| `gamepad` | `Real` | slot do controle em uso; `-1` quando não há nenhum |
| `deadzone` | `Real` | mínimo do analógico para contar como direção; padrão `.4` |
| `buffer` | `Real` | frames de tolerância de aperto e liberação; padrão `5` |

| Método | Retorna | Descrição |
|---|---|---|
| `refresh_gamepad()` | `Bool` | adota o primeiro slot conectado; `false` se não houver |
| `run()` | — | atualiza todas as entradas; chamar uma vez por frame, no Begin Step |
| `create_input()` | `Input` | cria e registra uma entrada |

### `Input`

**Fontes.** Cada uma retorna a própria entrada, então dá para encadear:

| Método | Descrição |
|---|---|
| `add_keyboard_key(_key)` | tecla |
| `add_gamepad_button(_button)` | botão do controle |
| `add_gamepad_left_stick(_direction)` | direção do analógico esquerdo |
| `add_gamepad_right_stick(_direction)` | direção do analógico direito |

**Consultas:**

| Método | Retorna | Descrição |
|---|---|---|
| `check()` | `Bool` | pressionada há pelo menos um frame |
| `check_pressed([_buffered])` | `Bool` | início do aperto; com `_buffered`, os primeiros frames |
| `check_released([_buffered])` | `Bool` | soltura; com `_buffered`, durante a janela |
| `check_stutter(_initial_delay, _interval)` | `Bool` | aperto inicial e repetições após o atraso |

**Consumo:**

| Método | Descrição |
|---|---|
| `consume_press()` | marca como já segurada além da janela, para `check_pressed(true)` não repetir |
| `consume_release()` | volta a ociosa, para `check_released(true)` não repetir |

**Interno:**

| Método | Descrição |
|---|---|
| `update()` | avalia as fontes e avança o estado; chamado pelo `run()` |

### Estado de `__time`

| Valor | Significado |
|---|---|
| `> 0` | pressionada há N frames |
| `0` | ociosa |
| `< 0` | janela de liberação; `-(buffer + 1)` no primeiro frame |

Transições a cada `update()`:

1. Alguma fonte ativa: vira `__time + 1` se já era positiva, senão `1`.
2. Nenhuma fonte e ainda positiva: vira `-(buffer + 1)`.
3. Nenhuma fonte e não positiva: sobe um por frame até `0`.

### `INPUT_AXIS`

`RIGHT`, `UP`, `LEFT`, `DOWN` — a direção pedida ao analógico. A fonte converte em eixo (`gp_axislh`/`gp_axislv`) e sinal, e compara o valor descontado da `deadzone`.

### Bindings de `obj_game`

| Ação | Teclado | Controle |
|---|---|---|
| `left` | seta esquerda, `A` | D-pad esquerdo, analógico esquerdo para a esquerda |
| `right` | seta direita, `D` | D-pad direito, analógico esquerdo para a direita |
| `jump` | espaço | botão de face de baixo |

## Desvios do original

O sistema parte do recurso de input do gm48.net (Mimpy, 2021). As diferenças abaixo são intencionais:

| Desvio | Motivo |
|---|---|
| Reaperto dentro da janela volta a `1` | No original o reaperto era engolido pelos frames restantes da liberação |
| Janela usa `-(buffer + 1)` | Com `-buffer`, `buffer = 0` deixava `check_released` verdadeiro para sempre |
| `check_stutter` retorna `false` para `_interval <= 0` | Evita divisão por zero e repetição a cada frame |
| Fontes de controle guardam `manager` | `self` dentro do closure do struct aponta para o próprio struct, então o gerenciador vai como campo da fonte |
| `consume_press` usa `max(buffer + 1, 2)` | Com `buffer = 1` o valor cairia na própria janela e o aperto repetiria |

## Armadilhas

- **Slot 0 não é o controle.** No Linux o runner enumera áudio, botão de power e teclado como gamepads, e o controle real pode cair num índice alto — nesta máquina, 38, acima do teto de 32. `refresh_gamepad()` e o evento async existem por isso; nunca fixe `gamepad = 0`.
- **O evento async dispara por instância.** O handler precisa morar num objeto único; dentro do player, dois jogadores disputariam o mesmo pad.
- **`run()` no Begin Step, leitura no Step.** Inverter a ordem faz a leitura enxergar o estado do frame anterior.
- **`consume_press()` consome mesmo quando a ação não acontece.** Chame só depois de confirmar a condição (no pulo, depois do `is_grounded()`).
- **O analógico não tem histerese.** Uma direção liga acima da `deadzone` e desliga logo abaixo, então há chacoalho exatamente no limite.
- **`buffer = 0` é válido, mas a janela de liberação dura um frame.** Bom para menu, apertado para plataforma.

## Exemplos

Registrar uma entrada com várias fontes:

```gml
jump = input_manager.create_input()
    .add_keyboard_key(vk_space)
    .add_keyboard_key(ord("Z"))
    .add_gamepad_button(gp_face1);
```

Pulo com buffer, consumindo só quando o pulo acontece:

```gml
if (obj_game.jump.check_pressed(true) && is_grounded()) {
    obj_game.jump.consume_press();
    velocity.y = -JUMP_SPEED;
}
```

Navegação de menu com repetição:

```gml
up = input_manager.create_input()
    .add_keyboard_key(vk_up)
    .add_gamepad_button(gp_padu);

// segura 20 frames, depois repete a cada 5
if (up.check_stutter(20, 5)) {
    menu_index--;
}
```

Uma segunda entrada que compartilha o mesmo gerenciador:

```gml
// as duas leem o mesmo gamepad, a mesma deadzone e o mesmo buffer
dash = input_manager.create_input()
    .add_keyboard_key(ord("X"))
    .add_gamepad_button(gp_face3);

dash.check_pressed(); // independe de jump.check_pressed()
```
