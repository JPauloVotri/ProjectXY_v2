# Movimento

Sistema de movimentação por colisão de passo, dividido entre `objects/obj_actor` (base genérica) e `objects/obj_player` (controle do jogador). Posição sempre em pixel inteiro, velocidade fracionária acumulada em `velocity_remainder`, e um passo de 1px por eixo por iteração. Requer GML 2.3 ou superior (usa métodos de instância).

Este documento é a fonte de verdade do sistema. Os comentários `///` no código alimentam o autocomplete e a validação de tipos do Feather.

## Convenções

- **Posição inteira, velocidade fracionária.** `x` e `y` nunca assumem valor quebrado; a fração vive em `velocity_remainder` e é aplicada um pixel por vez.
- **Dois hooks por eixo, momentos distintos.** `on_*_blocked` roda quando o passo é bloqueado; `on_*_moved` roda depois de um passo efetivado. Nunca os dois no mesmo passo.
- **`obj_actor` não tem sprite.** Ele é a base lógica; quem define sprite e aparência é o filho.
- **Unidades em px por frame**, a 60 fps (`option_game_speed = 60`).

## Referência

### Objetos

| Objeto | Papel |
|---|---|
| `obj_actor` | base sem sprite: guarda estado, `move()` e os hooks padrão |
| `obj_player` | herda de `obj_actor`; define as constantes e sobrescreve os hooks de x |
| `obj_solid` | tudo que colide; `obj_solid_slope` herda dele para ser detectado |
| `obj_pickup` | base sem sprite: detecta a coleta e chama `on_collect` |
| `obj_power_up` | marcador sem sprite: todo tipo de power-up herda dele |
| `obj_power_up_frictionless` | herda do marcador; anula a fricção pelo método do jogador |
| `obj_power_up_high_jump` | herda do marcador; multiplica o impulso do pulo pelo método do jogador |

### Estado

| Campo | Tipo | Papel |
|---|---|---|
| `velocity` | `Vector2` | px/frame desejados neste frame |
| `velocity_remainder` | `Vector2` | fração acumulada entre frames; é o que produz movimento subpixel |

### Hooks

| Hook | Roda quando | Recebe | Padrão em `obj_actor` |
|---|---|---|---|
| `on_x_blocked(_instance)` | passo horizontal bloqueado | instância que bloqueou | zera `velocity.x` e o resto de x |
| `on_y_blocked(_instance)` | passo vertical bloqueado | instância que bloqueou | zera `velocity.y` e o resto de y |
| `on_x_moved()` | depois de um passo em x efetivado | — | nada |
| `on_y_moved()` | depois de um passo em y efetivado | — | nada |
| `is_grounded()` | consulta | — | `place_meeting(x, y + 1, obj_solid)` |

Todos são atribuídos como métodos de instância no Create do `obj_actor`, então cada ator tem a própria cópia. Filhos sobrescrevem reatribuindo o nome depois do `event_inherited()`.

### `move()`

1. Soma `velocity` ao `velocity_remainder`.
2. Trunca cada componente para inteiro preservando o sinal (`absolute().floor()` e multiplicação por `sign`) — é o que evita andar 2px quando só há 1,6 acumulado na direção negativa.
3. Se o truncamento deu zero, retorna e deixa a fração guardada para o próximo frame.
4. Desconta o inteiro do `velocity_remainder`.
5. Enquanto sobrar deslocamento: `_dir` é a direção legalizada em −1, 0 ou 1 por eixo (`normalized().round()`); tenta 1px em x, depois 1px em y, chamando o hook correspondente em cada caso; desconta `_dir` do que falta.

### Física (`scr_physics`)

Três macros globais. Por serem macros, não há ajuste por instância nem em tempo de execução.

| Macro | Valor | Efeito |
|---|---|---|
| `GRAVITY` | `.1` | aceleração vertical por frame |
| `TERMINAL_SPEED` | `3` | teto da queda |
| `WATER_FACTOR` | `.5` | escala da física dentro da água |

### Água

A água não troca regra nenhuma: ela **escala as magnitudes** por `WATER_FACTOR`. A detecção é sobreposição de bbox, feita no `Step`:

```gml
in_water = place_meeting(x, y, obj_water);
physics_factor = (in_water && !ignores_friction) ? WATER_FACTOR : 1;
```

| Grandeza | Fora | Na água |
|---|---|---|
| Gravidade | `.1` | `.05` |
| Queda máxima | `3` | `1.5` |
| Velocidade no chão | `1` | `.5` |
| Velocidade no ar | `.5` | `.25` |
| Impulso do pulo | `3` | `1.5` |
| Impulso do pulo alto | `3.6` | `1.8` |

Como a regra horizontal é a mesma nos dois meios, a inércia continua valendo dentro da água: entrar correndo conserva a velocidade enquanto a direção é mantida, e decai para o teto ao soltar ou inverter.

**Sem fricção.** `ignores_friction` desliga o efeito por inteiro: com ele ligado, `physics_factor` vale `1` e a água deixa de existir para a física. O nome é do efeito, não do terreno — a mesma flag vai servir para outros líquidos e para o deslize no gelo, com a condição do meio mudando e a flag não. Quem liga a flag é `grant_frictionless()`, chamado pelo pickup; o contrato está em Pickups.

Para testar existe um toggle temporário na tecla **T**, marcado no código com `// TODO: remover depois`.

### Pickups

A base `obj_pickup` não tem sprite e não é posicionada: o `Step` dela detecta a sobreposição com o player, chama `on_collect` e só destrói o item quando a resposta é `true`.

Entre a base e os tipos fica `obj_power_up`, um marcador sem sprite e sem estado que representa a categoria. Ele existe para que `instance_place`, `place_meeting` e `object_is_ancestor` perguntem "isto é um power-up?" sem listar tipos. O `Create` dele é uma linha de `event_inherited()` porque `event_inherited()` chama só o pai imediato: sem esse repasse, o `Create` da base não chegaria aos netos.

Cada tipo é um neto com sprite própria e um `Create` que sobrescreve o contrato:

```gml
event_inherited();

on_collect = function(_player) {
    _player.grant_frictionless();

    return true;
}
```

| Peça | Papel |
|---|---|
| `on_collect(_player)` | contrato do tipo: `true` consome o item, `false` o deixa no chão |
| `grant_frictionless()` | método do player que liga `ignores_friction` |
| `grant_high_jump()` | método do player que liga `high_jump` |

Cada efeito novo ganha um `grant_*` próprio no player, em vez de o pickup escrever a flag direto: um nome errado estoura na hora, em vez de criar uma variável nova em silêncio.

A base declara `on_collect` com `return false`, então um tipo que esqueça a sobrescrita não é consumido e continua visível no chão.

### Constantes (`obj_player`)

| Constante | Valor | Efeito |
|---|---|---|
| `JUMP_SPEED` | `3` | impulso do pulo, aplicado como `-JUMP_SPEED` |
| `JUMP_CUT` | `.5` | fração da subida mantida ao soltar o pulo |
| `HIGH_JUMP_FACTOR` | `1.2` | multiplicador do impulso enquanto `high_jump` estiver ligado |
| `MOVEMENT_SPEED` | `1` | velocidade horizontal base; no chão vale inteira |
| `AIR_FACTOR` | `.5` | fração da `MOVEMENT_SPEED` aplicada no ar |
| `SLOPE_STEP_PENALTY` | `1` | px extras cobrados por degrau vencido |
| `SLOPE_MAX_PENALTY` | `.99` | teto da penalidade acumulada na rampa |

Com esses valores e o pulo alto desligado, o pulo sobe **46px** — a fórmula contínua `JUMP_SPEED² / (2 * GRAVITY)` dá 45, e o passo discreto a 60 fps rende um pouco mais. O ápice chega em 31 frames e o tempo de ar é 61.

### Estados (`obj_player`)

O `Step` coleta o input, aplica gravidade e velocidade terminal, chama `state_machine.update()`, zera a velocidade vertical positiva quando o player está no chão e chama `move()`. A regra horizontal, o impulso do pulo e o corte moram nos estados.

| Estado | Entra quando | Comportamento | Sai para |
|---|---|---|---|
| `idle` | `input_x == 0` no chão | regra do chão | `walk`, `fall`, `jump` |
| `walk` | `input_x != 0` no chão | regra do chão | `idle`, `fall`, `jump` |
| `jump` | impulso do pulo | controle aéreo + corte | `fall` quando `velocity.y >= 0` |
| `fall` | no ar, descendo | controle aéreo | `idle`/`walk` ao pousar, `jump` com buffer |

| Auxiliar | Papel |
|---|---|
| `apply_ground_movement()` | `velocity.x = input_x * MOVEMENT_SPEED * physics_factor` |
| `apply_air_movement()` | os três casos de `MOVEMENT_SPEED * AIR_FACTOR * physics_factor` |
| `try_jump()` | consome o buffer, aplica o impulso e troca para `jump`; devolve se pulou |

Cada `update` segue a ordem **comportamento → chão → pulo → transição**, que reproduz a ordem do `Step` anterior à máquina.

`idle` e `walk` aplicam a mesma regra hoje e existem separados para receber animação. A ramificação de pouso do `fall` aplica a regra do chão e chama `try_jump()` **antes** de trocar para `idle`/`walk`: é isso que faz o pulo sair no próprio frame do pouso, com a velocidade horizontal do chão.

### Pulo e ar

Segurar o botão sobe os 46px do pulo base. Soltar durante a subida multiplica o que resta por `JUMP_CUT`, então o ápice depende do tempo de aperto:

| Solta no frame | Altura | Tempo de ar |
|---|---|---|
| 2 (toque) | 14,2px | 33 |
| 5 | 20,5px | 38 |
| 11 | 31,0px | 46 |
| 16 | 37,7px | 51 |
| segurando | 46,5px | 61 |

A tabela vale com `high_jump` desligado.

No ar a velocidade horizontal segue três regras. O alvo delas é
`_air_speed = MOVEMENT_SPEED * AIR_FACTOR * physics_factor`, que com os valores atuais vale **0,5**
(**0,25** na água):

| Input | Efeito |
|---|---|
| mesma direção da velocidade | conserva `max(_air_speed, abs(velocity.x))` — a inércia do pulo corrido se mantém |
| direção oposta | troca na hora para `_air_speed` |
| nenhum | `clamp` em `±_air_speed`, derrubando um pulo a 1 px/frame para 0,5 |

No chão a velocidade continua sendo reescrita a cada frame com `MOVEMENT_SPEED`.

### Pulo alto

`high_jump` multiplica o impulso antes de `physics_factor`:

```gml
velocity.y = -get_jump_speed() * physics_factor;
```

Fora da água o impulso passa de `3` para `3.6` e o pulo sobe **66px**, com 74 frames de ar. Dentro da água, com a física escalada (sem `ignores_friction`), passa de `1.5` para `1.8` e sobe **33px**. O `JUMP_CUT` continua valendo sobre o que resta da subida. Quem liga a flag é `grant_high_jump()`, chamado pelo pickup; o contrato está em Pickups.

Para testar existe um toggle temporário na tecla **H**, marcado no código com `// TODO: remover depois`.

### Facing

`facing` guarda para que lado o jogador olha. Existe só em `obj_player`, e por ser global o enum `FACING` serve a qualquer objeto que precise consultar o lado:

| Valor | Constante | Sprite |
|---|---|---|
| `1` | `FACING.RIGHT` | `image_xscale = 1` |
| `-1` | `FACING.LEFT` | `image_xscale = -1` |

| Método | Efeito |
|---|---|
| `set_facing(_dir)` | grava `facing` e aplica em `image_xscale`; ignora `0` |

A direção vem do **input**, não da velocidade: o Step chama `set_facing(_input)` sempre que `_input != 0`. Parado, ou sem direção no ar, o último lado é preservado. Apertar as duas direções ao mesmo tempo dá `_input == 0` e não vira.

`set_facing` é o único ponto que traduz estado em sprite. Quando existirem sprites separadas por lado, só ele muda — `facing` continua o mesmo, e é ele que uma mecânica futura consulta para saber se o jogador está olhando para algo.

### Degraus

`try_step_up(_dir)` vence 1px de altura:

| Condição | Se falhar |
|---|---|
| `_dir != 0` | não sobe |
| `instance_place(x + _dir, y - 1, obj_solid) == noone` | não sobe |
| `is_grounded()` | não sobe |

Estando livre, aplica `x += _dir`, `y--`, zera o resto vertical e cobra a rampa:

```gml
velocity_remainder.x -= _dir * SLOPE_STEP_PENALTY;
velocity_remainder.x = clamp(velocity_remainder.x, -SLOPE_MAX_PENALTY, SLOPE_MAX_PENALTY);
```

O fator resultante é `1 / (1 + SLOPE_STEP_PENALTY)`: com o custo padrão, **metade da velocidade**.

`try_step_down(_dir)` recola ao chão depois de um passo horizontal:

| Condição | Se falhar |
|---|---|
| `velocity.y >= 0` | não desce (está subindo) |
| `instance_place(x, y + 1, obj_solid) == noone` | já tem chão, nada a fazer |
| `instance_place(x, y + 2, obj_solid) != noone` | é queda, não rampa |
| `instance_place(x - _dir, y + 1, obj_solid) != noone` | é beira, não rampa |

A última condição é o que distingue rampa de plataforma: na rampa o terreno atrás está mais alto, na beira está vazio.

## Armadilhas

- **`velocity.y` é zero no chão, mas isso não significa "está no chão".** O `Step` zera a velocidade vertical positiva enquanto `is_grounded()` for verdadeiro, então parado ela vale `0` — mas no ápice do pulo também vale `0`. Para saber se está no chão, use `is_grounded()`.
- **Passo bloqueado não dispara pós-movimento.** Se precisar reagir a uma colisão, o lugar é o `on_*_blocked`.
- **No ar a velocidade horizontal muda por regra, não por inércia livre.** Segurar a direção conserva o que veio do chão; soltar derruba para `_air_speed` e inverter troca na hora para `_air_speed`. Só no chão a velocidade é reescrita a cada frame com `MOVEMENT_SPEED`.
- **Abaixo de 1 px/frame todo movimento tem frames parados.** É quantização: a 0,5 px/frame a cadência é um passo a cada dois frames — inclusive no ar, onde `MOVEMENT_SPEED * AIR_FACTOR` vale 0,5. Não tente "suavizar" com posição fracionária; em textura com nearest sampling o sprite treme de largura.
- **Diagonal anda mais rápido em percurso.** `_dir` pode ser `(1, 1)`, o que desloca 1,41px naquele passo.
- **O step-up vence apenas 1px.** Degrau de 2px ou mais bloqueia como parede.
- **A penalidade da rampa precisa do `clamp`.** Sem ele, a penalidade chega a 1px e o `move()` a interpreta como passo válido, empurrando o ator 1px para trás quando a tecla é solta.
- **A penalidade é por degrau vencido.** Numa rampa mais suave, com menos step-ups por frame, o desconto médio cai proporcionalmente — o fator nominal só vale para 45°.
- **Hooks são métodos por instância.** Cada ator instancia as próprias funções no Create; para muitos atores com o mesmo comportamento, a alternativa seria um constructor.
- **A inversão do sprite depende da origem.** `spr_player` usa origem middle-center, então `image_xscale = -1` mantém o bbox em `[-4, 3]` e a colisão não desloca. Trocar a origem para um canto faria a máscara espelhada mudar de lado e o personagem encostar na parede em apenas uma das direções.
- **O espaçamento da escada é o que exige o power-up.** Quatro degraus de 40px, contra 23px de pulo na água e 46px fora dela — 33px e 66px com o pulo alto. É o que impede a saída do poço sem `ignores_friction`; o pulo alto sozinho ainda não alcança os 40px dentro da água, mas os dois juntos sobram. Mexer em `JUMP_SPEED`, em `HIGH_JUMP_FACTOR`, em `WATER_FACTOR` ou no espaçamento das plataformas muda essa conta.
- **A coleta lê a posição do player depois do `move()`.** O `Step` do pickup precisa rodar depois do player, o que na room depende da ordem de criação: a instância do pickup nasce depois. Fora dessa ordem a coleta atrasa um frame — a 3 px/frame não há risco de atravessar a máscara de 8 px.
- **Nenhuma base se posiciona.** `obj_pickup` e `obj_power_up` não têm sprite: a instância da room é sempre um tipo com sprite própria, e uma instância da base estoura na checagem de colisão do `Step`.

## Exemplos

Criar um ator que herda o movimento e ajusta só o que é dele:

```gml
// Create de um novo ator
event_inherited();

MOVEMENT_SPEED = 1.5;
AIR_FACTOR = .8;
```

Com esses valores o chão anda a 1,5 px/frame e o ar a 1,2 — mexer em `MOVEMENT_SPEED` move os dois juntos.

Gravidade e velocidade terminal vêm das macros de `scr_physics` e valem para todo objeto físico — não há o que sobrescrever por ator.

Reagir a um tipo específico de sólido antes de zerar a velocidade:

```gml
on_x_blocked = function(_instance) {
    if (_instance.object_index == obj_solid_slope) {
        return;
    }

    velocity.x = 0;
    velocity_remainder.x = 0;
}
```

Consultar o chão antes de qualquer decisão vertical:

```gml
if (is_grounded() && obj_game.jump.check_pressed()) {
    velocity.y = -JUMP_SPEED;
}
```

Ajustar o quanto a rampa pesa, sem mexer no código:

```gml
SLOPE_STEP_PENALTY = .33;   // 75% da velocidade
SLOPE_STEP_PENALTY = 1;     // 50%
SLOPE_STEP_PENALTY = 2;     // 33%
```
