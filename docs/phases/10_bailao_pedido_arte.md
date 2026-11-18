# Pedido de arte — Dimensão 10: Bailão da Dona Boleta (eletrofunk)

Copiar para `.agents/codex_requests/bailao_dona_boleta.md` (pasta local e não
versionada) na hora de mandar ao Codex. Ficha: `docs/phases/10_bailao_dona_boleta.md`.

Hoje a fase roda com placeholders de `tools/baile_placeholder_sprites.py`. A arte
final só substitui os PNGs em `assets/sprites/baile/`, com o **mesmo nome, canvas e
pivô** (pés no centro inferior). Direção original: virada para a direita (o jogo espelha).

Estilo: compatível com a Geovana e com o acabamento da EX7. Contornos firmes e
leitura de silhueta. Nada de neon genérico: magenta é a identidade do baile e
âmbar/laranja é perigo.

Referências para anexar:
- `assets/sprites/cripta/s9_lobo_0.png` e `sertao/s8_cangaceiro_0.png` (escala e acabamento);
- `boss7_fenix/fenix_fly_01.png`;
- `experimental/phase_ex8_terrain_atlas.png`.

## Folhas

1. **Borboletas** (canvas 150–170 px, quadros 0..3):
   - quadros: 0/1 = dança (asas no ritmo), 2 = ataque, 3 = pose do drop (asas totalmente abertas);
   - todas usam óculos Juliet (lentes ovais escuras, aro dourado) e corrente de ouro;
   - `b10_monarca`: laranja e preto;
   - `b10_garrafeira`: borboleta-coruja com olhos nas asas; no quadro 2 segura uma garrafa;
   - `b10_sombrinha`: asa-de-vidro com guarda-chuva rosa;
   - `b10_paredinha`: mariposa-atlas com caixinha de som;
   - `b10_hype`: morpho azul de boné;
   - `b10_dancarina`: borboleta da Roda, magenta.
2. **Lagartona do Paredão:**
   - cabeça `b10_lagartona_0..3`, `_attack` (boca aberta) e `_daze` (canvas 170, lagarta verde de óculos Juliet);
   - segmentos `b10_segmento_0` (apagado), `_1` (cone aceso magenta) e `_casulo` (canvas 130).
3. **Dona Boleta** (canvas 360 × 300; âncora do microfone perto da boca):
   - visual: borboleta-imperatriz roxa e dourada, coroa, óculos Juliet espelhado, casaco de pelúcia rosa e microfone cravejado;
   - `boss10_idle_0..3` e `boss10_sing_0..3` (ciclo de 4 batidas);
   - `boss10_attack_0..1` (aponta o microfone);
   - `boss10_roda_0..1` (braços abertos, "ABRE A RODA!");
   - `boss10_daze_0..1`;
   - `boss10_remix_0..1` (sem o casaco, Estágio 2);
   - `boss10_death_0..3`.
4. **Objetos:**
   - `b10_palco` (520 × 300): tablado, dois paredões, faixa de luz e pedestal de microfone na boca do palco;
   - `b10_garrafa_whisky/gin/vodka` (48 px).
5. **Terreno:** `experimental/phase_ex10_terrain_atlas.png` (1254 × 1254, 4 × 4):
   - quadra de concreto rachada pela Ruptura: linhas pintadas gastas, poças com reflexo e tampinhas;
   - índice 5 (coluna 1, linha 1) = piso em frente ao palco, com o microfone no centro.

Música (fora do Codex): eletrofunk a **130 BPM** com virada para **150 BPM**. O
relógio do jogo é o mestre; a faixa precisa ser produzida nesse andamento.
