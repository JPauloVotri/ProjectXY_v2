# Movimento e tiro

Sistema de movimentação por colisão de passo e de tiro, dividido entre `objects/obj_actor` (base genérica), `objects/obj_player` (controle do jogador) e `objects/obj_bullet` (projétil). Posição sempre em pixel inteiro, velocidade fracionária acumulada em `velocity_remainder`, e um passo de 1px por eixo por iteração. Requer GML 2.3 ou superior (usa métodos de instância).

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
| `obj_hazard` | base sem sprite: contrato `on_touch(_player)` para perigos de toque |
| `obj_crawler_blades` | herda de `obj_hazard`; arremessa o player ao encostar |
| `obj_enemy` | base dos inimigos; o corpo arremessa o player ao encostar, com guarda de vida |
| `obj_bullet` | herda de `obj_actor`; morre no cenário pelos hooks, fere o inimigo que encontra, explode no primeiro contato e desenha o rastro de três frames a partir da boca |
| `obj_solid` | tudo que colide; `obj_solid_slope` herda dele para ser detectado |
| `obj_pickup` | base sem sprite: detecta a coleta e chama `on_collect` |
| `obj_loot_health` | herda de `obj_pickup`; só cai com a vida abaixo do máximo; recupera 10 e é consumido mesmo se a vida encher depois |
| `obj_power_up` | marcador sem sprite: todo tipo de power-up herda dele |
| `obj_power_up_frictionless` | herda do marcador; anula a fricção pelo método do jogador |
| `obj_power_up_high_jump` | herda do marcador; multiplica o impulso do pulo pelo método do jogador |
| `obj_power_up_double_jump` | herda do marcador; libera um pulo extra no ar pelo método do jogador |

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
| `GRAVITY` | `1/12` | aceleração vertical por frame |
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
| Gravidade | `1/12` | `1/24` |
| Queda máxima | `3` | `1.5` |
| Velocidade no chão | `1` | `.5` |
| Velocidade no ar | `.5` | `.25` |
| Impulso do pulo | `2.45` | `1.225` |
| Impulso do pulo alto | `3.36` | `1.68` |

Como a regra horizontal é a mesma nos dois meios, a inércia continua valendo dentro da água: entrar correndo conserva a velocidade enquanto a direção é mantida, e decai para o teto ao soltar ou inverter.

**Sem fricção.** `ignores_friction` desliga o efeito por inteiro: com ele ligado, `physics_factor` vale `1` e a água deixa de existir para a física. O nome é do efeito, não do terreno — a mesma flag vai servir para outros líquidos e para o deslize no gelo, com a condição do meio mudando e a flag não. Quem liga a flag é `grant_frictionless()`, chamado pelo pickup; o contrato está em Pickups.

Para testar existe um toggle temporário na tecla **P**, marcado no código com `// TODO: remover depois`.

### Pickups

A base `obj_pickup` não tem sprite e não é posicionada: o `Step` dela detecta a sobreposição com o player, chama `on_collect` e só destrói o item quando a resposta é `true`.

Entre a base e os tipos fica `obj_power_up`, um marcador sem sprite e sem estado que representa a categoria. Ele existe para que `instance_place`, `place_meeting` e `object_is_ancestor` perguntem "isto é um power-up?" sem listar tipos. O `Create` dele é uma linha de `event_inherited()` porque `event_inherited()` chama só o pai imediato: sem esse repasse, o `Create` da base não chegaria aos netos.

Cada power-up é um neto com sprite própria e um `Create` que sobrescreve o contrato:

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
| `grant_double_jump()` | método do player que liga `double_jump` e libera o pulo aéreo atual |

Cada efeito novo ganha um `grant_*` próprio no player, em vez de o pickup escrever a flag direto: um nome errado estoura na hora, em vez de criar uma variável nova em silêncio.

A base declara `on_collect` com `return false`, então um tipo que esqueça a sobrescrita não é consumido e continua visível no chão.

### Loot

O loot de vida não passa por `obj_power_up`: `obj_loot_health` herda direto de `obj_pickup`.
O drop também não pertence ao inimigo; `scr_loot` guarda a tabela global, escolhe o tipo e cria a
instância. O inimigo só declara `DROP_CHANCE` e chama `loot_drop(x, y, DROP_CHANCE)` na morte.

| Função | Papel |
|---|---|
| `loot_init()` | monta `global.loot_table`; chamada uma vez pelo `obj_game` |
| `loot_pick_item(_player)` | filtra os tipos úteis ao player e sorteia um por peso; devolve `noone` quando nenhum serve |
| `loot_spawn(_x, _y, _item, _index = 0)` | cria um loot específico em `LAYER_ACTORS`; o índice desloca 4 px em cruz |
| `loot_drop(_x, _y, _chance, _count = 1)` | resolve o player, rola a chance e cria até `_count` itens úteis |

`global.loot_table` é um array de `{ item, weight, is_needed }`. `is_needed(_player)` diz se o
atributo daquele tipo ainda aceita ganho; a vida usa `current_health < max_health`. Depois que a
chance do inimigo passa, só as entradas elegíveis entram no sorteio, com chance
`weight / soma dos pesos elegíveis`. Hoje há só `obj_loot_health`, com peso `1`: com a vida cheia,
nada cai; com a vida abaixo do máximo, o item pode cair.

A chance de tentar um drop é do inimigo: `obj_enemy.DROP_CHANCE` começa em `0` e o crawler usa
`.5`. Ela não garante um item: se todos os atributos estiverem cheios, `loot_pick_item` devolve
`noone`. A tabela é a mesma para todos os inimigos. `loot_drop` procura `obj_player` com
`instance_find` e devolve `0` sem player. `obj_game` chama `randomize()` e `loot_init()` no
Create.

`obj_loot_health` recupera `HEAL_AMOUNT = 10` com `restore_health` e sempre devolve `true` em
`on_collect`, então é consumido mesmo com a vida cheia. O filtro vale no momento do drop: se o
item caiu com a vida baixa e o player encheu antes de encostar, a coleta ainda gasta o item. Se
ninguém coletar, o `Alarm 0` destrói a instância após
`10 * game_get_speed(gamespeed_fps)` passos.

A sprite `spr_loot_health` tem 4 frames: `0, 1, 2, 1`. O quarto frame é uma cópia do segundo; o
loop nativo produz `0, 1, 2, 1, 0, 1...`. O ping-pong do editor de sprite é só preview e não
altera o runtime.

Para testar sem morte, chame `loot_spawn(x, y, obj_loot_health)`; ele ignora o filtro. Para testar
o filtro, use `loot_drop(x, y, 1)` com a vida cheia e depois ferida.

### Constantes (`obj_player`)

| Constante | Valor | Efeito |
|---|---|---|
| `JUMP_SPEED` | `2.45` | impulso do pulo, aplicado como `-JUMP_SPEED` |
| `JUMP_CUT` | `.5` | fração da subida mantida ao soltar o pulo |
| `HIGH_JUMP_FACTOR` | `1.37` | multiplicador do impulso enquanto `high_jump` estiver ligado |
| `DOUBLE_JUMP_FACTOR` | `.6` | fração do impulso atual aplicada ao segundo pulo |
| `MOVEMENT_SPEED` | `1` | velocidade horizontal base; no chão vale inteira |
| `AIR_FACTOR` | `.5` | fração da `MOVEMENT_SPEED` aplicada no ar |
| `SLOPE_STEP_PENALTY` | `1` | px extras cobrados por degrau vencido |
| `SLOPE_MAX_PENALTY` | `.99` | teto da penalidade acumulada na rampa |
| `FIRE_COOLDOWN` | `20` | frames entre tiros; também é a espera do disparo automático |
| `MUZZLE_FLASH_TIME` | `4` | frames em que o clarão do disparo fica visível |
| `HURT_JUMP_SPEED` | `1.2` | impulso vertical do recuo ao encostar num perigo |
| `HURT_PUSH_SPEED` | `.7` | impulso horizontal do recuo, em px por frame |
| `HURT_LOCK_FRAMES` | `20` | frames de controle travado no estado `hurt` |
| `BLINK_INTERVAL` | `3` | frames acesos/apagados na piscada da invencibilidade |

Com esses valores e o pulo alto desligado, o pulo sobe **37px** — a fórmula contínua `JUMP_SPEED² / (2 * GRAVITY)` dá 36, e o passo discreto a 60 fps rende um pouco mais. O ápice chega em 31 frames e o tempo de ar é 60.

### Estados (`obj_player`)

O `Step` coleta o input de movimento e de mira, aplica gravidade e velocidade terminal, chama `state_machine.update()`, zera `air_jump_used` e a velocidade vertical positiva quando o player está no chão, chama `move()` e procura `obj_hazard` e `obj_enemy` na posição final, chamando `on_touch(self)` em cada um. Depois acumula a distância horizontal da caminhada, tenta disparar e chama `update_appearance()`. `invincible_time` desce um por frame no começo do `Step`. A regra horizontal, o impulso do pulo, o corte e o recuo moram nos estados.

| Estado | Entra quando | Comportamento | Sai para |
|---|---|---|---|
| `idle` | `input_x == 0` no chão | regra do chão | `walk`, `fall`, `jump` |
| `walk` | `input_x != 0` no chão | regra do chão | `idle`, `fall`, `jump` |
| `jump` | impulso do pulo | controle aéreo + corte | `fall` quando `velocity.y >= 0` |
| `fall` | no ar, descendo | controle aéreo | `idle`/`walk` ao pousar, `jump` com buffer ou pulo aéreo |
| `hurt` | toque num perigo ou inimigo | preserva o impulso; sem regra horizontal, pulo ou tiro | `fall` após `HURT_LOCK_FRAMES` |

| Auxiliar | Papel |
|---|---|
| `apply_ground_movement()` | `velocity.x = input_x * MOVEMENT_SPEED * physics_factor` |
| `apply_air_movement()` | os três casos de `MOVEMENT_SPEED * AIR_FACTOR * physics_factor` |
| `try_jump()` | consome o buffer, aplica o impulso e troca para `jump`; devolve se pulou |
| `try_air_jump()` | no `fall`, consome o buffer e aplica o segundo pulo com `DOUBLE_JUMP_FACTOR`; devolve se pulou |

Cada `update` segue a ordem **comportamento → chão → pulo → transição**, que reproduz a ordem do `Step` anterior à máquina.

`idle` e `walk` aplicam a mesma regra e existem separados para a animação; cada estado fixa a pose de entrada no `create` e `update_appearance()` cuida do que muda por frame. A ramificação de pouso do `fall` aplica a regra do chão e chama `try_jump()` **antes** de trocar para `idle`/`walk`: é isso que faz o pulo sair no próprio frame do pouso, com a velocidade horizontal do chão. No `fall` no ar, `apply_air_movement()` roda antes de `try_air_jump()`; se o segundo pulo dispara, o estado volta para `jump`.

### Recuo

O player chama `on_touch(_player)` nos `obj_hazard` e `obj_enemy` que encontra depois do `move()`.
O contrato devolve `true` quando o toque teve efeito; a base `obj_hazard` devolve `false` e cada
perigo sobrescreve.

As lâminas do crawler e o corpo dos inimigos chamam
`_player.bounce_from(x, TOUCH_INVINCIBLE_FRAMES)`, com `TOUCH_INVINCIBLE_FRAMES = 60`. O
`bounce_from` recusa se `is_invincible()`, calcula `_dir = sign(x - _source_x)` (zero vira
`-facing`), zera `velocity_remainder` e aplica
`(_dir * HURT_PUSH_SPEED * physics_factor, -HURT_JUMP_SPEED * physics_factor)`. Por fim, liga
`invincible_time` com `start_invincibility(_invincible_frames)` e troca para `hurt`.

O estado `hurt` não aplica regra horizontal nem pulo: mantém o impulso e trava andar, pular e
atirar. Quando `state_machine.time` chega a `HURT_LOCK_FRAMES`, volta para `fall`. O `try_fire`
recusa durante `hurt`; mirar e virar continuam.

`invincible_time` desce no `Step`; o `Draw` pisca o player a cada `BLINK_INTERVAL` frames enquanto
ele for maior que zero. `start_invincibility(_frames)` usa `max` para não encurtar um recuo em
andamento, então uma fonte de dano contínuo pode conceder poucos frames sem derrubar a
invencibilidade longa de um recuo. O recuo escala pela água por `physics_factor`, como o pulo.
Nesta etapa ele não desconta vida; a integração com `take_damage` fica em `docs/vida.md`.

### Animação (`obj_player`)

O jogador é desenhado em duas camadas, ambas viradas para a direita e espelhadas por `image_xscale`. `spr_player` continua sendo só a máscara de colisão; o Draw do player não a desenha.

| Sprite | Quadros | Origem | Papel |
|---|---|---|---|
| `spr_player_legs_idle` | 2 | `(8, 8)` | 0 parado; 1 parado mirando reto para cima |
| `spr_player_legs_walk` | 8 | `(8, 8)` | 0–7 caminhada; 4 pulo; 6 queda; 3 queda terminal |
| `spr_player_torso` | 4 | `(8, 9)` | 0 horizontal; 1 diagonal cima; 2 reta cima; 3 diagonal baixo |

As três têm 16×16 e são desenhadas no mesmo `(x, y)`; as origens fazem o encaixe. O torso é desenhado depois das pernas.

**Caminhada por distância.** `walk_distance` acumula o `x` efetivo do `move()` e o quadro é `floor(walk_distance / WALK_FRAME_DISTANCE) % WALK_FRAME_COUNT`. Com `WALK_FRAME_DISTANCE = 4`, a animação avança um quadro a cada 4px andados. A passada desenhada mede cerca de 2px por quadro, mas 4 foi escolhido por leitura de movimento; o valor é o ajuste de cadência, e a velocidade da água e da rampa acompanha a distância real.

| Constante | Valor | Efeito |
|---|---|---|
| `WALK_FRAME_COUNT` | `8` | quadros do ciclo de caminhada |
| `WALK_FRAME_DISTANCE` | `4` | px percorridos por quadro da caminhada |
| `WALK_JUMP_FRAME` | `4` | quadro da caminhada usado no pulo |
| `WALK_FALL_FRAME` | `6` | quadro da caminhada usado na queda |
| `WALK_FALL_TERMINAL_FRAME` | `3` | quadro usado na queda em velocidade terminal |

**Torso.** `WALK_TORSO_BOB_Y` desce o torso 1px nos quadros 2 e 6; parado, `IDLE_TORSO_OFFSET_Y` também desce 1px. Pulo e queda usam o valor da tabela no quadro de entrada (4 → 0, 6 → 1); a troca para o quadro 3 no terminal muda só as pernas, sem mexer no offset do torso. O deslocamento é só de desenho: não altera a máscara, a boca nem a posição.

**Estados.** Cada estado fixa a pose de entrada no `create`: `idle` escolhe a sprite de pernas parada e o quadro conforme a mira; `walk` zera o ciclo; `jump` e `fall` fixam os quadros 4 e 6; `hurt` usa o quadro de queda. `update_appearance()` roda depois de `state_machine.update()`, avança a caminhada, troca a queda para o quadro 3 quando `velocity.y >= TERMINAL_SPEED * physics_factor` e escolhe o quadro do torso pela mira. O quadro do torso não fica no `create` porque a mira muda sem troca de estado.

### Pulo e ar

Segurar o botão sobe os 37px do pulo base. Soltar durante a subida multiplica o que resta por `JUMP_CUT`, então o ápice depende do tempo de aperto:

| Solta no frame | Altura | Tempo de ar |
|---|---|---|
| 2 (toque) | 11px | 33 |
| 5 | 16px | 38 |
| 11 | 25px | 45 |
| 16 | 30px | 50 |
| segurando | 37px | 60 |

A tabela vale com `high_jump` desligado.

Um pulo base cai por cerca de 29 frames e não alcança a velocidade terminal: o quadro 3 aparece em quedas longas. A partir do repouso, o terminal chega em cerca de 36 frames tanto no ar quanto na água, porque gravidade e teto escalam pelo mesmo fator.

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

No pulo do chão, `high_jump` multiplica o impulso antes de `physics_factor`:

```gml
velocity.y = -get_jump_speed() * physics_factor;
```

Fora da água o impulso passa de `2.45` para `3.36` e o pulo sobe **69px**, com 82 frames de ar. Dentro da água, com a física escalada (sem `ignores_friction`), passa de `1.225` para `1.68` e sobe **34px**. O `JUMP_CUT` continua valendo sobre o que resta da subida. Quem liga a flag é `grant_high_jump()`, chamado pelo pickup; o contrato está em Pickups.

Para testar existe um toggle temporário na tecla **O**, marcado no código com `// TODO: remover depois`.

### Pulo duplo

`double_jump` libera um pulo extra por saída do chão. `air_jump_used` começa falso, volta a falso sempre que o Step vê `is_grounded()` e é zerado por `grant_double_jump()`; cair de uma borda sem pular também deixa o pulo aéreo disponível.

O pulo só dispara no estado `fall` (`velocity.y >= 0`) e não dispara na velocidade terminal (`velocity.y >= TERMINAL_SPEED * physics_factor`). Apertar durante a subida não dispara na hora, mas o buffer de 5 frames pode disparar quando o `fall` começa. Ele consome o buffer, aplica `get_jump_speed() * DOUBLE_JUMP_FACTOR * physics_factor`, marca `air_jump_used` e volta para `jump`; o `JUMP_CUT` continua valendo. Pegar o pickup no ar libera o pulo na hora.

Com `DOUBLE_JUMP_FACTOR = .6`, o segundo impulso é 60% do pulo atual. A partir do ápice, o total fica em **50px** no pulo base (segundo de 13px) e **94px** com o primeiro pulo alto (segundo de 25px); na água, **25px** e **47px** (segundos de 7px e 13px).

Para testar existe um toggle temporário na tecla **I**, marcado no código com `// TODO: remover depois`.

### Facing

`facing` guarda para que lado o jogador olha. Existe só em `obj_player`, e por ser global o enum `FACING` serve a qualquer objeto que precise consultar o lado:

| Valor | Constante | Sprite |
|---|---|---|
| `1` | `FACING.RIGHT` | `image_xscale = 1` |
| `-1` | `FACING.LEFT` | `image_xscale = -1` |

| Método | Efeito |
|---|---|
| `set_facing(_dir)` | grava `facing` e aplica em `image_xscale`; ignora `0` |

A direção vem do **input**, não da velocidade: o Step chama `set_facing(_input)` sempre que `_input != 0`. Parado, ou sem direção no ar, o último lado é preservado. Apertar as duas direções ao mesmo tempo dá `_input == 0` e não vira. A mira não muda o `facing`: ela parte dele.

`set_facing` é o único ponto que traduz `facing` em `image_xscale`. O Draw usa esse valor para espelhar as duas partes; `facing` continua o mesmo, e é ele que a mira consulta para montar a direção do tiro.

### Tiro

O `Step` monta a mira no topo e chama `try_fire()` no fim, depois do `move()`; `fire_cooldown` desce um por frame. `aim_vertical` guarda a última diagonal (−1 cima, 1 baixo) e começa em `-1`.

**Mira.** `aim_direction` é sempre um dos vetores abaixo e nunca aponta para trás:

| Situação | `aim_direction` |
|---|---|
| mira segurada, sem ↑/↓ | `(facing, aim_vertical)` |
| mira segurada + ↑ ou ↓ | diagonal escolhida; atualiza `aim_vertical` |
| sem mira, andando + ↑ ou ↓ | `(facing, ±1)`; atualiza `aim_vertical` |
| sem mira, parado + ↑ | `(0, -1)` |
| sem mira, parado + ↓ | mantém `aim_direction` e `aim_vertical` anteriores |
| sem mira, sem ↑/↓ | `(facing, 0)` |
| ↑ e ↓ juntos | cancela: diagonal lembrada com a mira, horizontal sem ela |

O `x` é `facing` ou `0` — como não existe componente contra o `facing`, não há tiro para trás. Para virar, o jogador precisa andar para o outro lado.

↓ sem mira, parado e sem input horizontal não altera a mira: o tiro continua na última direção. Para mirar para baixo é preciso segurar a mira ou estar andando, e nesse caso a mira é sempre diagonal.

**Boca.** `get_muzzle_offset(_direction)` devolve o deslocamento local do centro do clarão, em px, a partir do centro do player. O X é voltado para a frente e multiplicado por `facing`; o Y é para baixo:

| Mira | Deslocamento | Quadro do clarão |
|---|---|---|
| reta para frente | `(+12, 0)` | 0 |
| reta para cima | `(0, -13)` | 0 |
| diagonal para cima | `(+8, -7)` | 1 |
| diagonal para baixo | `(+9, +5)` | 1 |

O tiro nasce no centro desse deslocamento. O clarão é desenhado pelo próprio player, depois do torso, por `MUZZLE_FLASH_TIME` frames; usa `image_xscale` para espelhar e `muzzle_flash_yscale = -1` na diagonal para baixo.

**Disparo.** `try_fire()` exige `obj_game.fire.check()` (segurar mantém o automático), `fire_cooldown == 0` e que o estado não seja `hurt`; cria o projétil na camada `Projectiles` (`LAYER_PROJECTILES`), chama `launch(aim_direction)` e grava `FIRE_COOLDOWN`. O offset e o quadro do clarão ficam gravados no disparo; a mira pode mudar sem deslocar o clarão já aceso. O primeiro tiro sai no frame do aperto.

**Projétil (`obj_bullet`).** Herda de `obj_actor`: o Create chama `event_inherited()`, `velocity` e `velocity_remainder` vêm do pai, e o Step usa o `move()` normal — a máscara 4×4 do sprite testa o cenário em passos de 1 px. Os hooks `on_x_blocked`/`on_y_blocked` marcam `hit` e guardam o passo de contato; `on_x_moved`/`on_y_moved` procuram inimigo a cada passo de 1 px. O Step destrói depois do `move()`, nunca dentro do laço.

Depois do `move()`, o Step procura `obj_enemy` na posição final: achando, chama `take_damage(BULLET_DAMAGE)` e marca `hit`. A procura roda mesmo quando o passo foi bloqueado pelo cenário — é o que permite ferir o crawler colado na parede, onde o tiro para a 1 px dela. Quem decide se o dano passa é o inimigo: vida, invencibilidade e dano mínimo moram no `obj_enemy`.

**Impacto.** `contact_position` guarda o centro do tiro no primeiro passo de 1 px que encostou outra instância, já deslocado por `CONTACT_OFFSET = 1` no eixo do passo para cair na superfície do alvo. Em sólido, o contato é o passo tentado que seria bloqueado; em inimigo, é o primeiro passo efetivado em que `instance_place` acha um inimigo com `current_health > 0`. Se o tiro já estava sobreposto sem ter se movido, o fallback usa a posição final. A explosão nasce nesse ponto; expirando pela câmera, não há explosão.

O tiro morre em `obj_solid` e em `obj_enemy`; sem alcance fixo, morre também quando o centro passa `DESPAWN_MARGIN = 64` px para fora da view de `view_camera[0]` em qualquer lado. Se a câmera se afastar dele, ele também some.

Morrendo por colisão, solta `obj_explosion_bullet` em `contact_position`, na camada `Effects` (`LAYER_EFFECTS`); expirando pela câmera, não solta nada.

| Constante | Valor | Efeito |
|---|---|---|
| `BULLET_SPEED` | `3` | px/frame ao longo da direção |
| `DESPAWN_MARGIN` | `64` | px além da view em que o tiro some |
| `BULLET_DAMAGE` | `1` | dano que o tiro desconta do inimigo |
| `CONTACT_OFFSET` | `1` | px do primeiro passo de contato até a superfície do alvo |
| `TRAIL_LENGTH` | frames do sprite (`3`) | quantidade de círculos do rastro |
| `TRAIL_SPACING` | largura do frame − 2 (`4`) | distância entre os centros; com o sprite 6×6 sobram 2 px de sobreposição |
| `TRAIL_MUZZLE_CLEARANCE` | `6` | px à frente da boca para um ponto do rastro aparecer |
| `TRAIL_WAVE_AMPLITUDE` | `1` | px de ondulação perpendicular ao trajeto |
| `TRAIL_WAVE_SPEED` | `22.5` | graus por frame; um ciclo a cada 16 frames |
| `TRAIL_WAVE_PHASE` | `180` | defasagem entre os círculos do rastro, em graus |

**Desenho.** O Draw começa no ponto mais distante que já passou `TRAIL_MUZZLE_CLEARANCE` px à frente de `spawn_position` e vai até a cabeça; assim o rastro cresce a partir da boca e não aparece entre o player e o clarão. Só a cabeça (frame 0) segue o caminho exato; os outros recebem `sin` da fase, com deslocamento perpendicular a `travel_direction` e posições arredondadas para pixel inteiro. A onda é só de desenho: não altera a posição, a colisão nem o despawn.

O `obj_bullet` não é posicionado na room; quem cria é o `try_fire()` do player.

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
- **A caminhada é por distância, não por tempo.** `walk_distance` só cresce com o `x` efetivo do `move()`; empurrar parede congela a animação e a água ou a rampa ajustam a cadência.
- **O bob do torso é só de desenho.** `torso_offset_y` entra no torso; pernas, máscara e boca não se deslocam.
- **Pulo e queda reusam quadros da caminhada.** Os índices 3, 4 e 6 precisam acompanhar a arte.
- **A pose de entrada fica no `create` do estado.** O `update` do estado novo não roda no frame da troca; o que precisa valer na hora vai no `create`, e o que muda por frame vai em `update_appearance()`.
- **O recuo não tira vida.** `bounce_from` só muda a velocidade e a invencibilidade; a vida continua intacta até o passo de dano ser ligado.
- **O travamento do recuo é mais curto que a invencibilidade.** O controle volta em `HURT_LOCK_FRAMES`; a piscada e o bloqueio de novos toques duram os frames concedidos pela fonte.
- **A inversão do sprite depende da origem.** `spr_player` usa origem `(3, 8)`, então `image_xscale = -1` mantém o bbox em `[-3, 2]` e a colisão não desloca. Trocar a origem para um canto faria a máscara espelhada mudar de lado e o personagem encostar na parede em apenas uma das direções.
- **O espaçamento da escada é o que exige o power-up.** Na água, a escada da direita sobe 24px e depois 32px, contra 18px de pulo base e 25px do duplo base; o pulo alto sozinho (34px) passa, e com o duplo chega a 47px. Mexer em `JUMP_SPEED`, em `HIGH_JUMP_FACTOR`, em `DOUBLE_JUMP_FACTOR`, em `WATER_FACTOR` ou no espaçamento das plataformas muda essa conta.
- **O segundo pulo é um só e só na descida.** `air_jump_used` zera no chão e na coleta; apertar durante a subida só fica no buffer de 5 frames. Na velocidade terminal o segundo pulo não dispara.
- **A coleta lê a posição do player depois do `move()`.** O `Step` do pickup precisa rodar depois do player, o que na room depende da ordem de criação: a instância do pickup nasce depois. Fora dessa ordem a coleta atrasa um frame — a 3 px/frame não há risco de atravessar a máscara de 6 px.
- **Nenhuma base se posiciona.** `obj_pickup` e `obj_power_up` não têm sprite: a instância da room é sempre um tipo com sprite própria, e uma instância da base estoura na checagem de colisão do `Step`.
- **A chance do inimigo e a chance do tipo são separadas.** `DROP_CHANCE` decide se o drop é
  tentado; `global.loot_table` decide se há tipo elegível e qual cai. Com todos os atributos
  cheios, a tentativa termina sem item. Mudar o peso da vida muda a distribuição de todos os
  inimigos.
- **Atributo cheio sai do sorteio, não vira peso zero.** A entrada continua na tabela; é
  `is_needed(_player)` que a remove naquela chamada. Uma entrada nova precisa declarar o próprio
  filtro.
- **O ping-pong do editor de sprite não vale no jogo.** O vai e volta do loot vem do quarto frame
  repetido, não da opção de preview.
- **O loot que já caiu é consumido mesmo com a vida cheia.** Se o item caiu com a vida baixa e o
  player encheu antes de encostar, `on_collect` devolve `true` mesmo quando `restore_health` não
  sobe nada.
- **O loot some em 10 segundos de jogo.** O `Alarm 0` conta passos; não é um contador em tempo real
  fora do passo.
- **O tiro não sai para trás.** A mira usa `facing` ou `0` no eixo x; para virar, o jogador precisa andar para o outro lado.
- **A mira reta para baixo não existe.** ↓ sem mira e parado preserva a mira anterior; com a mira segurada ou andando, ↓ dá diagonal baixo.
- **A diagonal lembrada sobrevive à soltura da mira.** `aim_vertical` só muda com ↑/↓ enquanto a mira está segurada ou o jogador anda; o tiro vertical não a altera.
- **O projétil expira pela câmera, não por tempo ou alcance.** Ele some `64px` fora da view; se a câmera se afastar, ele morre antes de sair da tela.
- **O tiro é consumido em qualquer inimigo que encosta.** O `hit` vem do contato, não do dano: inimigo invencível ou com limiar acima do `BULLET_DAMAGE` engole o projétil igual.
- **Não destrua o projétil dentro do hook.** O laço do `move()` continua depois do hook; o tiro marca `hit` e só destrói no fim do Step.
- **A onda do rastro é só desenho.** O deslocamento perpendicular não entra na posição nem na máscara do projétil.
- **O rastro só começa à frente da boca.** `spawn_position` é capturado no Create e `TRAIL_MUZZLE_CLEARANCE` corta os pontos que ainda estariam sobre o clarão; mexer no sprite ou na velocidade do tiro pede reavaliar esse valor.
- **O clarão não segue a mira.** Offset, quadro e espelhamento vertical são gravados no disparo; mudar a mira no meio do clarão não o reposiciona.
- **A explosão usa o primeiro contato do Step.** `contact_position` vem dos hooks de 1 px, não da posição final; o dano continua na posição final, mas a animação nasce na superfície.

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
