# Henry congelado

Arte gerada com a ferramenta integrada de imagens, usando o primeiro frame de
`henry_idle_pocket_sheet_v1.png` como identidade e `img/Geo_Cool-1.png` como
referência inicial do gelo. O PNG tem transparência real, com alguns pixels
residuais de alfa 1/255 nas margens. A imagem gerada é preservada sem reamostragem.

## Mapeamento no jogo

- PNG: `henry_frozen_sheet_v1.png`, 1774 × 887.
- Frame 0: região `(242, 24, 576, 840)`, gelo inicial.
- Frame 1: região `(1012, 24, 576, 840)`, variação de reflexos/rachaduras.
- Ambos usam a pose frontal, sem espelhamento nem inclinação por movimento.
- Altura de desenho: 103,2; deslocamento vertical: +4. Isso mantém a altura
  corporal e os pés próximos ao idle de 88 px, descontando as margens de gelo.
- O temporizador de congelamento existente controla a alternância dos frames.
- A rede reutiliza `NET_ANIM_FROZEN` e o índice do frame, sem campos novos.

## Prompt final da revisão aceita

Edit the frozen Henry sheet (reference 2), correcting only character scale relative
to ice and matching reference 1 FIRST standing pose more accurately. TWO frames
horizontally, same cell size, same position of character in both frames. Reference
1 is canonical Henry; preserve his skin tone, head/body proportions, black suit,
blue tie, beard, sunglasses exactly, use his full standing hands-in-pockets pose.
Make Henry much taller inside the ice: his bald head must be only about 8 logical
pixels below the TOP of the crystal and soles only 5 pixels above bottom. The
character should occupy 90-92% of the crystal height, not 65%. Do not change his
anatomy to achieve this: shrink the ice margins around him. Crystal should hug the
silhouette with 12 pixels lateral allowance, faceted pale cyan translucent ice,
small white-blue cracks. Frame 1 frozen with clear face and suit, frame 2 same
frozen statue and same scale with tiny alternate ice glints/cracks only. Retain
sharp pixel art style and original palette visible through clear ice. Cell should
be 256x256 conceptually with Henry head y14, shoes y243; total sheet two square
cells side by side. No text, no backdrop, no checkerboard, actual transparent alpha
surrounding both crystals. No glow, no soft painting, no extra sprites. Return
game-ready PNG.
