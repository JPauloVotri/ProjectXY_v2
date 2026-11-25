# Portas

`obj_door_zone` são os pontos de travessia entre rooms. Cada porta guarda um identificador dentro da
room e o par de destino (room + porta), numa relação 1:1 mantida à mão. O `obj_player` é
persistente: ao encostar numa porta armada ele marca a travessia, a room troca no fim do evento e o
player nasce no centro da porta de destino mais o offset de saída dela.

Este documento é a fonte de verdade do sistema. Os comentários `///` no código alimentam o
autocomplete e a validação de tipos do Feather.

## Convenções

- **A porta aponta para a outra ponta.** `target_room` e `target_door` dizem onde ela chega; a
  simetria é responsabilidade de quem edita a room.
- **`door_id` é único dentro da room.** O mesmo número pode existir em rooms diferentes.
- **A porta é invisível, mas colide.** `visible = false` no Create; o gatilho é `place_meeting`.
- **A porta se arma ao ver o player fora.** Sem isso, nascer dentro da área de destino dispararia a
  porta de volta no primeiro frame.
- **A chegada é o centro do bbox mais o offset.** `exit_x`/`exit_y` são em px a partir do centro,
  não do canto do sprite.
- **A saída fica fora do gatilho.** O offset precisa afastar o player da própria área da porta de
  destino; o `armed` cobre um offset curto, mas não substitui o ajuste.

## Referência

### Objeto

`obj_door_zone` é uma área invisível, sem pai, na camada `Zones`. As variáveis são Variable
Definitions, sobrescritas por instância na room:

| Variável | Tipo | Papel |
|---|---|---|
| `door_id` | Integer | identificador da porta dentro da room |
| `target_room` | Room | room da outra ponta |
| `target_door` | Integer | `door_id` da porta de chegada na room de destino |
| `exit_x` / `exit_y` | Integer | deslocamento da chegada, em px, a partir do centro da porta |

`armed` nasce falso no Create e liga no Step quando o player é visto fora da área. O Step ignora o
player morto, então a sequência de morte não é interrompida por uma travessia.

### Player

| Campo / método | Papel |
|---|---|
| `pending_room` | room marcada pela porta; `undefined` sem travessia |
| `pending_door` | porta de chegada na room marcada; `-1` sem travessia |
| `travel_to(_room_asset, _door_id)` | marca o destino e chama `room_goto` |
| `find_door(_door_id)` | porta com o id na room atual, ou `noone` |
| `apply_pending_travel()` | Room Start: posiciona na porta pendente e para o corpo |

### Ciclo

1. O Step da porta vê o player fora da área e liga `armed`.
2. Com `armed` e o player sobreposto, a porta chama `travel_to(target_room, target_door)`.
3. A room troca no fim do evento. O player persiste com vida, tanques, power-ups e aparência.
4. No Room Start, `apply_pending_travel()` acha a porta de chegada, posiciona o player no centro
   dela mais o offset e zera `velocity` e `velocity_remainder`.

Se a porta de chegada não existir, o player fica na posição antiga e o console mostra
`[porta] porta N não existe em <room>`.

### Instâncias por room

O player é persistente, mas cada room precisa de uma instância colocada dele: é o ponto de
renascimento. Na entrada por porta, a instância da room se autodestrói pela guarda
`instance_number(obj_player) > 1`; no reinício por morte, ela é a única e sobrevive.

A `obj_camera` não persiste: o Room Start do `obj_game` cria uma nova quando a room não tem. A
instância colocada do player na room 2 fica em (280, 268).

### Par atual

| Sala | Porta | `door_id` | Destino | `exit` | Chegada |
|---|---|---:|---|---|---|
| `rm_room_1` | (0, 64), 0.5×2 | 1 | `rm_room_2`, 1 | (8, 8) | (12, 88) |
| `rm_room_2` | (312, 244), 0.5×2 | 1 | `rm_room_1`, 1 | (-8, 8) | (308, 268) |

As duas portas cobrem o vão de 8×32 px: 16 px de sprite com `scaleX 0.5` e `scaleY 2`.

## Armadilhas

- **A simetria é manual.** Uma porta que aponta para a outra ponta sem ela apontar de volta deixa o
  player sem caminho de volta.
- **`bbox_center_x` não existe.** O centro sai de `(bbox_left + bbox_right) * .5` e o mesmo para y.
- **A guarda de instância depende da ordem de criação.** O player persistente entra na room antes
  das instâncias da room; a colocada vê `instance_number` 2 e se destrói.
- **O offset é do centro, não do canto.** Numa porta de 8 px de largura, `exit_x = 8` coloca o
  player fora da área; menos que isso depende do `armed`.
- **Toda room precisa de um `obj_player` colocado.** Sem ele, a morte deixa a room sem player.
- **A morte desliga a persistência.** `on_death_end` zera `persistent` para a room criar a instância
  colocada do zero, com a vida base.
- **A porta não sabe da outra room.** `target_room`/`target_door` não são validados em runtime; um
  id errado só aparece quando a room de destino já foi carregada.
