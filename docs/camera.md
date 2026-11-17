# Câmera

`obj_camera` posiciona a view 0 sobre o player, adiantada pela velocidade dele, respeitando as
zonas que bloqueiam o enquadramento, e entrega a imagem com movimento sub-pixel sem quebrar o
pixel art. É a técnica de **view surface + recorte fracionado**.

## Convenções

- **O mundo renderiza em pixel inteiro.** A câmera é posicionada com `floor()`; a suavidade vem
  depois, no recorte.
- **A view é 1px maior que o jogo em cada eixo.** É essa margem que o recorte consome.
- **A fração mora em `x` e `y` da instância.** São as coordenadas da própria instância,
  reaproveitadas para guardar a posição contínua da câmera.
- **A GUI fixa a resolução do jogo.** `display_set_gui_size(320, 180)` e o GameMaker escala para
  a janela.

## Como a imagem chega à tela

1. `camera_set_view_size(view_camera[0], 321, 181)` — a view cobre um pixel a mais que a área
   útil de 320×180.
2. `view_surface_id[0] = view_surf` desvia o render do mundo para uma surface própria de 321×181,
   com a câmera em pixel inteiro.
3. No **Draw GUI Begin**, `draw_surface_part(view_surf, frac(x), frac(y), 320, 180, 0, 0)`
   recorta uma janela de 320×180 a partir da fração.
4. A GUI de 320×180 é escalada para a janela a 4× ou 6×, com filtragem desligada.

O passo 4 é o que produz a suavidade: o recorte é resolvido em espaço de 320, mas rasterizado no
espaço do window. Um `frac = 0,3` vira 1,2px de tela, e não 0. Sem a escala da GUI, o recorte
seria quantizado e a imagem andaria aos pulos de 1px.

## O enquadramento

Todo frame, o End Step chama `update_view()`:

1. Acumula a velocidade do alvo no adiantamento (`offset_x`/`offset_y`), limitado por
   `look_ahead_rate` por frame e por `look_ahead_max_*` no total.
2. Calcula o desejado: `alvo + adiantamento − metade da tela`, sem limite nenhum.
3. Aplica as zonas e limita o resultado pela room, o que pode travar um dos eixos.
4. Move a view até a posição corrigida (`__slide_to`), arredonda com `view_precision` e entrega a
   fração ao recorte.

## O adiantamento

O offset é a **integral da velocidade**, limitada por frame:

- Correndo a 1 px/frame, cresce 1 por frame.
- Caindo a 3 px/frame, a taxa corta para 1 — sem isso, o impulso do pulo (que salta de `0`
  para `-3` de uma vez) moveria a câmera 3px num frame só.
- Parado, o offset **não volta**: a câmera fica onde parou até o jogador se mover para o outro
  lado.
- Perto do teto, a taxa cai proporcionalmente ao que falta (`__offset_step`), então o
  adiantamento encosta no máximo em vez de parar de uma vez.

## O eixo livre

`__axis_step` decide cada eixo em separado. Sem zona ativa no eixo:

- **A view segue a variação do desejado, não a velocidade.** Rampa e degrau mudam a posição em y
  pelos degraus de 1px do `move()`, e a `velocity.y` fica 0 neles.
- **Sem variação no eixo, a view fica parada.** O erro acumulado espera o alvo voltar a andar
  naquele eixo.
- **O erro pendente só é fechado a favor do movimento do alvo.** Fechá-lo contra o pulo puxaria a
  câmera para o lado errado — foi o que acontecia ao cruzar para a metade direita e pular.
- O erro fecha com `__ease_step`, a até `look_ahead_rate` mais metade da variação do alvo: passo
  cheio longe do alvo, proporcional dentro de `slide_near`. É o que limita quanto a câmera acelera
  ao pagar a defasagem que a zona deixou ao soltar o eixo.

## Zonas

`obj_camera_zone` é uma área da room que **bloqueia o enquadramento** enquanto o alvo está fora
dela. A zona trava um eixo só quando o alvo está sobreposto a ela no outro:

| Alvo | Limite aplicado |
|---|---|
| acima da zona | `y = min(y, topo − 180)` |
| abaixo da zona | `y = max(y, base)` |
| à esquerda da zona | `x = min(x, esquerda − 320)` |
| à direita da zona | `x = max(x, direita)` |

Com o alvo **dentro** da zona, ou fora dela nos dois eixos, nenhum limite é aplicado.

`obj_camera_zone_secret` é filha da base e liga `secret`: além do bloqueio, a zona só é revelada
quando o alvo encosta nela pelo bbox (`place_meeting` no Step), e a revelação é permanente.

O eixo travado anda a `zone_slide_rate` por frame, com a mesma desaceleração de `slide_near` ao
chegar no limite, e assenta exatamente nele.

## Referência

| Campo | Papel |
|---|---|
| `target` | instância seguida; trocável para uma cutscene apontar para outro alvo |
| `offset_x` / `offset_y` | adiantamento acumulado, em px |
| `look_ahead_max_x` / `look_ahead_max_y` | teto do adiantamento: 24 e 8 |
| `look_ahead_rate` | quanto o offset pode mudar por frame, base do fechamento do erro: 1 |
| `zone_slide_rate` | quanto o eixo travado anda por frame: 2 |
| `slide_near` | distância em que o passo desacelera até o alvo: 16 |
| `view_precision` | precisão da posição da view: 0,01 px |
| `game_width` / `game_height` | área útil (320×180), lida da view no Create |
| `view_surf` | surface do render; criada sob demanda e liberada no Clean Up |

| Método / evento | Papel |
|---|---|
| `update_view()` | acumula o offset, aplica as zonas e posiciona a view (End Step) |
| `__offset_step` | passo do adiantamento, desacelerando no teto |
| `__axis_step` / `__ease_step` | movimento de um eixo e o passo com desaceleração |
| `__slide_to` | aplica os dois eixos, arredonda a posição e guarda o desejado |
| `__clamp_zone` / `__resolve_zones` | os limites de uma zona e a passagem por todas |
| Draw GUI Begin | recorta e desenha a surface |
| Clean Up | libera a surface |

## Armadilhas

- **O limite da sala usa `game_width`, não o tamanho da view.** Quem define o que aparece é o
  recorte de 320, não a view de 321. Limitar por `room_width - 321` faz a última coluna do mundo
  ser cortada na borda direita, porque o recorte nunca chega ao fim da view.
- **O limite da sala passa pelo mesmo deslize das zonas.** O desejado é sempre cru; quem limita é o
  alvo, em `__resolve_zones`. Com o desejado já limitado, `_follow` zerava ao encostar na borda e o
  erro pendente ficava parado: a câmera congelava antes do limite, com o alvo saindo do quadro.
- **Sem o `+1`, o recorte sai da surface.** Com `frac` próximo de 1, a janela de 320 precisaria
  de uma coluna além do que existe.
- **Rampa e degrau não geram `velocity.y`.** O movimento vertical vem do `move()`, que empilha
  degraus de 1px; medir o eixo y pela velocidade congelaria a câmera numa rampa.
- **A revelação da zona secreta é permanente.** Não há como re-bloquear uma zona já revelada.
- **A posição é arredondada a cada frame.** É o que assenta a view perto do alvo, em vez de
  deixá-la rastejando por frações de pixel.
- **A cauda da desaceleração não pode rastejar.** Perto do limite, `__ease_step` encolhe o passo a
  cada frame; entregar o resto só quando o passo ficava abaixo de `view_precision` deixava a view
  até 20 frames deslizando menos de 1px. Por isso a entrega vale quando falta menos de 1px.
- **A aplicação surface está desligada.** `application_surface_enable(false)` vale para o jogo
  inteiro: qualquer efeito futuro que dependa dela (pós-processamento, cópia de surface) precisa
  de outro caminho.
- **Todo desenho de GUI vive em 320×180.** `display_set_gui_size` fixa esse espaço; elemento de
  interface novo deve ser pensado nele.
- **`game_width` é lido no Create.** Se a view mudar depois, os dois divergem em silêncio.
