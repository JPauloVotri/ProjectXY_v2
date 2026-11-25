# Camadas

Padrão de camadas de room do projeto. Toda room usa os mesmos nomes e profundidades. O GameMaker
desenha da maior profundidade para a menor, então o menor valor fica na frente.

## Pilha

| Camada | Depth | Conteúdo |
|---|---:|---|
| `Zones` | 0 | `obj_camera_zone`, `obj_camera_zone_secret`, `obj_door_zone`; invisíveis |
| `Water` | 1000 | `obj_water`; overlay na frente de todo o mundo |
| `Effects` | 2000 | `obj_explosion_bullet`, `obj_explosion_enemy` |
| `Projectiles` | 3000 | `obj_bullet` |
| `Actors` | 4000 | player, inimigos, pickups e power-ups |
| `Terrain` | 5000 | `obj_solid`, `obj_solid_slope` |
| `Background` | 9000 | cor de fundo da room |
| `Systems` | 10000 | `obj_game` persistente e `obj_camera` criada no Room Start; sem desenho |

`Zones` fica à frente apenas para facilitar a edição; as instâncias desligam `visible` no Create.
`Systems` continua visível de propósito: o `Draw GUI Begin` da câmera precisa rodar. Os objetos
dessa camada não têm sprite. O `obj_game` é persistente e vive na `rm_room_1`; ele cria a
`obj_camera` de cada room no Room Start, porque a câmera não persiste.

## Profundidades reservadas

| Camada | Depth | Uso futuro |
|---|---:|---|
| `Foreground` | 1500 | props na frente do mundo, atrás da água |
| `Actors_Front` | 3500 | atores que precisem ficar na frente dos demais |
| `Parallax_Near` | 7000 | parallax próximo |
| `Parallax_Far` | 8000 | parallax distante |

As camadas reservadas não existem em `rm_room_1`. Ao criar uma delas em uma room nova, use o nome
e a profundidade da tabela e adicione a macro correspondente no `scr_draw`.

## Regras

- **Ordem explícita pede camada explícita.** O GameMaker não garante a ordem entre instâncias da
  mesma camada. O que precisa ficar na frente vai para outra camada ou é desenhado no mesmo Draw.
- **Nunca atribua `depth` a uma instância em camada.** A atribuição cria uma camada temporária e
  tira a instância do padrão. Crie com `instance_create_layer` e a macro `LAYER_*`.
- **Água é overlay.** `Water` fica na frente de atores, tiros e efeitos. A GUI não é tingida,
  porque o recorte da câmera acontece depois do render do mundo.
- **Zonas são invisíveis.** `obj_camera_zone` e `obj_door_zone` ligam `visible = false` no Create; a
  camada existe para posicionar e depurar as áreas.
- **Sistemas não desenham o mundo.** `obj_game` e `obj_camera` não têm sprite; a câmera só desenha
  a GUI, com a surface do mundo e o HUD. A camada fica no fundo para não disputar espaço com o
  mundo.
- **Novas rooms repetem a pilha.** O GameMaker não tem template de camadas; `rm_room_1` é a
  referência e esta tabela é a fonte de verdade.

## Macros

`scripts/scr_draw/scr_draw.gml` define uma macro para cada camada existente:

| Macro | Valor |
|---|---|
| `LAYER_ZONES` | `"Zones"` |
| `LAYER_WATER` | `"Water"` |
| `LAYER_EFFECTS` | `"Effects"` |
| `LAYER_PROJECTILES` | `"Projectiles"` |
| `LAYER_ACTORS` | `"Actors"` |
| `LAYER_TERRAIN` | `"Terrain"` |
| `LAYER_BACKGROUND` | `"Background"` |
| `LAYER_SYSTEMS` | `"Systems"` |

Use as macros em `instance_create_layer`; não escreva o nome da camada solto.

## Lâminas do crawler

`obj_crawler_blades` não tem evento Draw e nasce com `visible = false`. A instância existe só para
guardar `image_index`, `flashing` e a ligação com o pai. O `obj_crawler` desenha corpo, núcleo e
lâminas no próprio Draw, nessa ordem. Assim a ordem fica garantida pelo código, sem `depth` e sem
camada extra.
