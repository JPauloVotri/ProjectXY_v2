# Câmera

`obj_camera` posiciona a view 0 sobre o player, adiantada pela velocidade dele, e entrega a imagem com movimento sub-pixel sem quebrar o pixel art. É a técnica de **view surface + recorte fracionado**.

## Convenções

- **O mundo renderiza em pixel inteiro.** A câmera é posicionada com `floor()`; a suavidade vem depois, no recorte.
- **A view é 1px maior que o jogo em cada eixo.** É essa margem que o recorte consome.
- **A fração mora em `x` e `y` da instância.** São as coordenadas da própria instância, reaproveitadas para guardar a posição contínua da câmera.
- **A GUI fixa a resolução do jogo.** `display_set_gui_size(320, 180)` e o GameMaker escala para a janela.

## Como a imagem chega à tela

1. `camera_set_view_size(view_camera[0], 321, 181)` — a view cobre um pixel a mais que a área útil de 320×180.
2. `view_surface_id[0] = view_surf` desvia o render do mundo para uma surface própria de 321×181, com a câmera em pixel inteiro.
3. No **Draw GUI Begin**, `draw_surface_part(view_surf, frac(x), frac(y), 320, 180, 0, 0)` recorta uma janela de 320×180 a partir da fração.
4. A GUI de 320×180 é escalada para a janela a 4× ou 6×, com filtragem desligada.

O passo 4 é o que produz a suavidade: o recorte é resolvido em espaço de 320, mas rasterizado no espaço do window. Um `frac = 0,3` vira 1,2px de tela, e não 0. Sem a escala da GUI, o recorte seria quantizado e a imagem andaria aos pulos de 1px.

## Referência

| Campo | Papel |
|---|---|
| `target` | instância seguida; trocável para uma cutscene apontar para outro alvo |
| `offset_x` / `offset_y` | adiantamento acumulado, em px |
| `look_ahead_max_x` / `look_ahead_max_y` | teto do adiantamento: 24 e 8 |
| `look_ahead_rate` | quanto o offset pode mudar por frame: 1 |
| `game_width` / `game_height` | área útil (320×180), lida da view no Create |
| `view_surf` | surface do render; criada sob demanda e liberada no Clean Up |

| Método / evento | Papel |
|---|---|
| `update_view()` | acumula o offset, posiciona a view e garante a surface (End Step) |
| Draw GUI Begin | recorta e desenha a surface |
| Clean Up | libera a surface |

## O adiantamento

O offset é a **integral da velocidade**, limitada por frame:

```gml
offset_x = clamp(offset_x + clamp(target.velocity.x, -rate, rate), -max_x, max_x);
```

- Correndo a 1 px/frame, cresce 1 por frame e satura os 24 em 24 frames.
- Caindo a 3 px/frame, a taxa corta para 1 — sem isso, o impulso do pulo (que salta de `0` para `-3` de uma vez) moveria a câmera 3px num frame só.
- Parado, o offset **não volta**: a câmera fica onde parou até o jogador se mover para o outro lado.

A posição é `alvo + offset`, recalculada do zero todo frame. Não há perseguição nem lerp, então a câmera nunca "atrasa" em relação ao player — só o adiantamento cresce devagar.

## Armadilhas

- **O limite da sala usa `game_width`, não o tamanho da view.** Quem define o que aparece é o recorte de 320, não a view de 321. Limitar por `room_width - 321` faz a última coluna do mundo ser cortada na borda direita, porque o recorte nunca chega ao fim da view.
- **Sem o `+1`, o recorte sai da surface.** Com `frac` próximo de 1, a janela de 320 precisaria de uma coluna além do que existe.
- **A aplicação surface está desligada.** `application_surface_enable(false)` vale para o jogo inteiro: qualquer efeito futuro que dependa dela (pós-processamento, cópia de surface) precisa de outro caminho.
- **Todo desenho de GUI vive em 320×180.** `display_set_gui_size` fixa esse espaço; elemento de interface novo deve ser pensado nele.
- **`game_width` é lido no Create.** Se a view mudar depois, os dois divergem em silêncio.
