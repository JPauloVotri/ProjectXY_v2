# Vida e tanques

`obj_player` guarda a vida e os tanques; `obj_camera` desenha o HUD no Draw GUI Begin. A vida base é
99 e cada tanque soma 100 ao máximo e 100 à vida atual, sem teto. O HUD mostra o resto dentro do
tanque, de 0 a 99, e a contagem de tanques cheios sobre o total possuído.

Este documento é a fonte de verdade do sistema. Os comentários `///` no código alimentam o
autocomplete e a validação de tipos do Feather.

## Convenções

- **A vida é um número só.** `current_health` guarda o total; o resto dentro do tanque é derivado.
- **Cada 100 de vida é um tanque cheio.** `get_full_tank_count()` usa `floor(current_health / 100)`.
- **O total de tanques é dinâmico.** `tanks` cresce a cada tanque e é o denominador do HUD; não há
  limite fixo de 15.
- **A vida fica entre 0 e o máximo.** Dano tem piso em 0; cura tem teto em `max_health`.
- **Zerar a vida mata.** `take_damage` chama `die()` no 0; a sequência de morte reinicia a room com
  a vida base e nenhum tanque.

## Referência

### Campos

| Campo | Tipo | Papel |
|---|---|---|
| `BASE_MAX_HEALTH` | `Real` | vida inicial e máximo antes de tanques: 99 |
| `HEALTH_PER_TANK` | `Real` | vida somada por tanque: 100 |
| `current_health` | `Real` | vida total atual |
| `max_health` | `Real` | teto atual; começa em 99 e sobe 100 por tanque |
| `tanks` | `Real` | tanques possuídos; sem teto |

### Métodos

| Método | Retorna | Descrição |
|---|---|---|
| `take_damage(_amount)` | `Bool` | desconta vida e mata no 0; `false` quando não desceu |
| `restore_health(_amount)` | `Bool` | recupera vida até `max_health`; `false` quando não subiu |
| `grant_health_tank()` | `Bool` | soma +100 ao máximo e +100 à vida atual, até o novo máximo |
| `get_full_tank_count()` | `Real` | `clamp(floor(current_health / HEALTH_PER_TANK), 0, tanks)` |
| `die()` | — | zera a vida e entra no estado `dead`; não faz nada se já morreu |
| `is_dead()` | `Bool` | verdadeiro do instante da morte até o reinício da room |

### HUD

`draw_health_hud(_player)` em `scr_draw` desenha duas linhas em `(4, 4)` e `(4, 13)` com
`fnt_debug`, branco e alinhamento à esquerda/topo:

- `health: <resto>`: `current_health % HEALTH_PER_TANK`, de 0 a 99.
- `tanks: <cheios>/<total>`: `get_full_tank_count()` e `tanks`, ambos com dois dígitos.

A câmera chama o HUD no fim do Draw GUI Begin, depois de copiar a surface do mundo. Por ser GUI, o
HUD não é tingido pela água e não sofre o recorte da câmera. Durante a morte o HUD não é desenhado:
a tela preta o substitui.

### Cura por loot

`obj_loot_health` só entra no sorteio quando `current_health < max_health`; com a vida cheia, o
drop não cria o item. Se ele caiu com a vida baixa e o player encheu antes de encostar, a coleta
ainda consome o item. `on_collect` chama `restore_health(10)` e devolve `true` sempre. O loot
desaparece sozinho após 10 segundos se não for coletado.

### Dano por contato

`obj_hazard` é a base sem sprite dos perigos de toque: o `on_touch(_player)` padrão devolve `false` e
cada perigo sobrescreve. `obj_crawler_blades` herda dela e fere o player; `obj_enemy` define o mesmo
contrato para o corpo, com guarda de `current_health > 0`. O `Step` do player procura os dois depois
do `move()` e chama `on_touch(self)`.

O toque chama `hurt_from(_source_x, _damage, _invincible_frames)`. Se o player já está invencível,
nada acontece; senão, `take_damage(_damage)` desconta a vida com piso em 0, a direção é
`sign(x - _source_x)` (zero vira `-facing`), o resto fracionário é zerado e a velocidade vira
`(_dir * HURT_PUSH_SPEED * physics_factor, -HURT_JUMP_SPEED * physics_factor)`. O player entra no
estado `hurt`, que preserva o impulso e trava andar, pular e atirar por `HURT_LOCK_FRAMES`; ao fim,
volta para `fall`.

Se o toque zera a vida, `hurt_from` devolve `true` sem aplicar o recuo: a sequência de morte assume
no lugar do estado `hurt`.

A invencibilidade fica em `invincible_time`, decrementado no `Step`. `start_invincibility(_frames)`
usa `max` para não encurtar um recuo em andamento. As fontes atuais concedem
`TOUCH_INVINCIBLE_FRAMES = 60` e tiram `TOUCH_DAMAGE = 5`; o `Draw` pisca o player a cada
`BLINK_INTERVAL` frames e `is_invincible()` responde se um novo toque seria aceito.

| Constante | Valor | Efeito |
|---|---:|---|
| `HURT_JUMP_SPEED` | `1.2` | impulso vertical do recuo, antes de `physics_factor` |
| `HURT_PUSH_SPEED` | `.7` | impulso horizontal do recuo, em px por frame |
| `HURT_LOCK_FRAMES` | `20` | frames de controle travado no estado `hurt` |
| `BLINK_INTERVAL` | `3` | frames acesos/apagados na piscada da invencibilidade |
| `TOUCH_INVINCIBLE_FRAMES` | `60` | invencibilidade concedida por lâminas e inimigos |
| `TOUCH_DAMAGE` | `5` | vida descontada por lâminas e corpo de inimigo |

O recuo escala pela água como o pulo: `physics_factor` vale `.5` dentro dela e `1` com
`ignores_friction`. O dano não escala: são sempre os `TOUCH_DAMAGE` pontos da fonte.

### Morte

Zerar a vida chama `die()`: zera velocidade, resto, `invincible_time` e `muzzle_flash_time` e troca
para o estado `dead`. Nesse instante o `Step` do player para de rodar o jogo — só
`state_machine.update()` continua —, então o corpo fica congelado na pose em que estava e o resto do
mundo segue simulando por baixo.

A câmera desenha a morte no Draw GUI Begin: cobre a GUI de preto, chama `draw_death_overlay(x, y)` e
pula o HUD. O overlay recebe a posição da câmera e redesenha o corpo em coordenadas de tela
(`mundo - câmera`), por cima do preto.

As fases usam `state_machine.time`:

| Fase | Frames | O que aparece |
|---|---:|---|
| Preto | `DEATH_FREEZE_FRAMES` (60) | corpo normal, congelado |
| Faíscas | `DEATH_SPARK_FRAMES` (60) | corpo piscando branco/normal e faíscas |
| Explosão | 8 × `DEATH_EXPLOSION_FRAME_HOLD` (32) | explosão no lugar do corpo |

As faíscas são dados do próprio player (`death_sparks`): uma nasce a cada `DEATH_SPARK_INTERVAL`
frame, dentro de uma caixa de ±6 px do centro, com `xscale`/`yscale` em ±1, ângulo múltiplo de 90 e
`DEATH_SPARK_LIFE` frames de vida. Só espelhamento e ângulos retos, porque outra rotação tiraria a
faísca da grade de pixels.

A piscada chama `gpu_set_fog(true, c_white, 0, 0)` em `draw_body`, a cada `DEATH_FLASH_INTERVAL`
frames, começando no branco.

`on_death_end()` fecha a sequência chamando `room_restart()`; a room volta com 99 de vida e nenhum
tanque. É esse método que dará lugar à tela de game over no futuro.

### Exemplos

| `current_health` | `tanks` | HUD |
|---:|---:|---|
| 99 | 0 | `health: 99`, `tanks: 00/00` |
| 100 | 1 | `health: 0`, `tanks: 01/01` |
| 199 | 1 | `health: 99`, `tanks: 01/01` |
| 150 | 1 | `health: 50`, `tanks: 01/01` |
| 1599 | 15 | `health: 99`, `tanks: 15/15` |
| 1699 | 16 | `health: 99`, `tanks: 16/16` |

## Atalhos de teste

| Tecla | Efeito |
|---|---|
| `K` | concede um tanque |
| `L` | tira 1 HP por ativação com `check_stutter(30, 5)` |
| `H` | devolve 1 HP por ativação com `check_stutter(30, 5)` |
| `M` | chama `die()` na hora, com a vida que estiver |

Os quatro são temporários, marcados no código com `// TODO: remover depois`, e não têm
equivalente no controle.

## Armadilhas

- **O `health` do HUD não é a vida total.** Ele mostra o resto dentro do tanque; a vida total é
  `full_tanks * 100 + resto` no estado normal.
- **O denominador não é fixo.** `tanks` é o total possuído até o momento; o HUD mostra `05/15` com
  5 tanques cheios de 15, e passaria a `06/16` ao ganhar mais um.
- **Cada 100 de vida conta como um tanque cheio.** Em 100 a linha de vida volta a 0 e o tanque
  aparece como cheio; em 99 o tanque deixa de contar.
- **O HUD é GUI.** Desenhá-lo no Draw do mundo o deixaria sujeito à água e ao recorte da câmera.
- **Zerar a vida mata na hora.** `take_damage` chama `die()` no mesmo frame do acerto; não existe
  janela com 0 HP em que o player ainda aja.
- **O toque que mata não arremessa.** `hurt_from` sai depois de `take_damage` quando o player morre;
  o corpo fica parado onde encostou em vez de levar o recuo.
- **A morte é desenhada fora do mundo.** O preto e o corpo vêm do Draw GUI Begin; desenhá-los no
  mundo deixaria água, projéteis e o resto da camada por cima.
- **O dano do toque é por fonte.** `hurt_from` desconta o `TOUCH_DAMAGE` de quem tocou; não existe
  um valor global de contato. A invencibilidade decide se o toque vale, não quanto ele tira.
- **O travamento é do recuo, não da invencibilidade.** O controle volta em `HURT_LOCK_FRAMES`
  frames; a piscada dura os `TOUCH_INVINCIBLE_FRAMES` concedidos pela fonte.
- **Loot que já caiu é consumido mesmo com a vida cheia.** O filtro de drop impede criar o item
  com a vida cheia, mas `on_collect` devolve `true` e o item some se for tocado depois de a vida
  encher.
