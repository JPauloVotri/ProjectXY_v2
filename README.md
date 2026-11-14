# Project XY

**Versão:** 0.1.0-alpha

Protótipo de plataforma 2D em GameMaker LTS 2026. Há uma sala só, de 960×360, com resolução
interna de 320×180 rodando a 60 fps. Não existe objetivo nem condição de vitória: o que está em
teste é o movimento, a água, a câmera e os power-ups.

## Rodar pela IDE

Abra `ProjectXY.yyp` no GameMaker LTS 2026 e aperte **F5**. O jogo abre em tela cheia.

## Rodar pelo executável

Na IDE, use `Build ▸ Create Executable` e escolha o alvo **Windows** ou **Linux** — os dois já
estão configurados no projeto. O pacote gerado não é versionado (`Build/` está no `.gitignore`),
então ele vem pronto de quem compilou.

- **Windows:** rode `projectxy.exe`.
- **Linux:** rode o binário de dentro do pacote (`.zip` ou `.AppImage`, conforme a opção
  escolhida). Se o sistema recusar por falta de permissão, dê `chmod +x` no arquivo.

## Controles

| Ação | Teclado | Controle |
|---|---|---|
| Andar para a esquerda | `←` ou `A` | D-pad esquerdo ou analógico esquerdo |
| Andar para a direita | `→` ou `D` | D-pad direito ou analógico esquerdo |
| Pular | `Espaço` | `A` no Xbox, `✕` no PlayStation |
| Reiniciar | `F5` | — |

- `A` e `✕` são o mesmo botão físico, o de face de baixo: o Xbox chama de `A` e o PlayStation
  de `✕` (Xis).
- O pulo tem altura variável: soltar o botão durante a subida corta o resto.
- O controle é detectado sozinho. No Linux ele pode ser enumerado num slot alto; se nada
  responder, conecte o controle antes de abrir o jogo e procure a mensagem
  `[input] descoberto no slot N` no console de debug.
- `F5` reinicia com a janela do jogo em foco. Com a janela da IDE em foco, a mesma tecla
  interrompe a execução — para testar o reinício, use o executável.

## O que observar

- **Andar.** No chão o passo é de 1 px por frame — lento de propósito. O sprite vira ao trocar de
  direção, e o personagem não desliza ao parar.
- **Pulo curto e longo.** Um toque sobe ~14 px; segurando o botão o pulo chega a ~46 px. Soltar no
  meio da subida corta o que falta.
- **Rampa e degrau.** A rampa de 45° anda na metade da velocidade. Degrau de 1 px é vencido; de
  2 px em diante, bloqueia como parede.
- **Água.** Queda, corrida e pulo caem pela metade, então o pulo fica em ~23 px. Dá para afundar e
  sair nadando.
- **Câmera.** Ela adianta até 24 px em x e 8 px em y na direção do movimento, para nas bordas da
  sala e é bloqueada pelas quatro zonas. O movimento é suave sem tremer o pixel art, e a imagem
  não sai do quadro nem na borda.
- **Power-ups.** Somem ao encostar e o efeito vale até reiniciar. São três: sem fricção (no fundo
  da água), pulo alto e pulo duplo.
- **Reinício.** `F5` só reinicia quando a tecla é solta, então segurar não entra em laço.

## Atalhos temporários de teste

| Tecla | Efeito |
|---|---|
| `P` | Liga e desliga o efeito sem fricção |
| `O` | Liga e desliga o pulo alto |
| `I` | Liga e desliga o pulo duplo |

Cada um imprime o estado no console de debug. São atalhos de desenvolvimento, marcados no código
para remoção, e servem só para testar um efeito isolado sem ir atrás do pickup.

## O que ainda não existe

Sem objetivo ou fim de fase, sem som, sem animação (os sprites têm um frame só), sem dano ou
morte, sem menu ou pausa, e nada persiste entre reinícios.

## Detalhes técnicos

Os subsistemas estão documentados em `docs/`: `movimento.md`, `input.md`, `estado.md`,
`camera.md` e `vector2.md`.

O sistema de input parte do recurso do [gm48.net](https://gm48.net) (Mimpy, 2021), com desvios
descritos em `docs/input.md`.
