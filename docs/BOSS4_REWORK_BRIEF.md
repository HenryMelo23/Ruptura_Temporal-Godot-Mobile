# Boss 4 — Sapo Astronauta do Nexo: brief de rework (mecânica + animação)

Documento-fonte para as tarefas de arte (`.codex/tasks/boss4_*.md`) e para a
implementação. Toda animação nova deve seguir as regras daqui.

## 1. Regras de animação (valem para todo quadro do boss 4)

1. **Sprite = corpo; código = tudo que aponta.** Língua estendida, raios, projéteis e
   ondas NÃO são pintados no sprite. O sprite mostra só a pose do corpo e, no máximo,
   o começo do efeito colado ao corpo (ex.: brilho na mão, base da língua dentro da boca).
   O código desenha a parte direcional usando texturas próprias (ex.: segmento de língua).
2. **Quadro = fase do golpe.** Cada ataque tem fases com duração fixa:
   `preparação → ataque (ativo) → sustentação (opcional) → recuperação`.
   Cada quadro pertence a uma fase. O dano acontece exatamente no primeiro quadro da fase
   ativa. Nada de distribuir quadros por igual no tempo total.
3. **Pontos de ancoragem fixos.** Cada quadro tem posição conhecida da boca, mãos e pés.
   As tarefas de arte pedem a boca/mãos em coordenadas fixas para o código encaixar a
   língua e os efeitos sem tremer.
4. **Formato fixo.** 384×384 px, fundo transparente, olhando para a ESQUERDA, pés em
   y≈366 e centro em x≈192 (pivot do manifest: 192,366). O espelhamento para a direita é
   feito por código.
5. **Consistência de personagem.** Sempre gerar com as referências do repouso
   (`boss4_idle_00.png`) + o melhor quadro já aprovado da mesma sequência.

## 2. Locomoção

**Saltos de sapo** (sequência `hop`, 6 quadros, já gerada em `hop_raw/`):

| Fase | Quadros | Duração | Código |
|---|---|---|---|
| Preparação | 00 | 0,22 s | achata (squash), sem deslocar |
| Impulso | 01 | 0,08 s | começa a subir, poeira leve |
| Voo | 02 → 03 → 04 | 0,46 s | arco parabólico, sombra encolhe/cresce, desloca até o destino |
| Impacto | 05 | 0,14 s | amassa, poeira, tremor de câmera leve, onda curta no chão |
| Pausa | idle | 0,25–0,6 s | escolhe próximo salto ou ataque |

Saltos de 140–240 px; nos estágios 3–4 pode emendar dois saltos curtos. Nunca desliza.

## 3. Habilidades de assinatura (substituem a lista atual de 14)

| # | Habilidade | Estágio | Ideia | Por que é ameaçadora |
|---|---|---|---|---|
| 1 | **Língua-Arpão** | 1+ | mira, trava 0,35 s antes, dispara a língua até 420 px | se acertar, puxa o jogador e emenda um tapa à queima-roupa (fuga com dash); se errar, a língua gruda no chão e o sapo se puxa até o ponto (mobilidade) |
| 2 | **Salto Esmagador** | 1+ | salto alto até a posição prevista do jogador, sombra cresce | onda de impacto em anel que se expande: dá para pular a onda com dash no tempo certo ou ficar longe |
| 3 | **Tapa Orbital** (slam atual) | 1+ | golpe em leque à curta distância | pune quem fica colado; quadros atuais servem |
| 4 | **Raio do Capacete** (cometa) | 2+ | carrega no capacete, dispara um raio que varre em arco | obriga a se mover em torno do boss, não para longe |
| 5 | **Poço Gravitacional** | 3+ | cria uma singularidade que puxa; o sapo salta ao redor | combina com Língua e Salto: puxão + punição |
| 6 | **Singularidade Absoluta** (ultimate atual) | 4 | mantida | — |

Habilidades atuais fora da lista (leak, prison, clone, vampirism, fragments, collapse,
meteor, combo, fissure) saem do sorteio padrão; podem voltar como variações de estágio
depois de testar.

## 4. Língua-Arpão — especificação completa

| Fase | Tempo | Quadros (sequência `tongue_v2`) | Código |
|---|---|---|---|
| Inspirar | 0,00–0,30 | 00 garganta inchando, corpo recua | linha de mira pontilhada fina do capacete até o jogador, segue o alvo |
| Mirar | 0,30–0,55 | 01 cabeça avança, boca começa a abrir | mira **trava** (fica vermelha e para de seguir) — janela de reação 0,25 s |
| Disparo | 0,55–0,70 | 02 boca escancarada, pescoço esticado, corpo projetado | língua sai da boca (âncora fixa) até 420 px com easing, textura de segmento + ponta |
| Puxão / sustentação | 0,70–1,00 | 03 corpo inclinado para trás, puxando | se acertou: arrasta o jogador até a boca; se errou: língua gruda e o sapo é puxado |
| Recolher | 1,00–1,35 | 04 boca fechando, volta ao repouso | língua recolhe; se acertou, emenda o Tapa |

Texturas da língua (geradas como imagens separadas):
- `boss4_tongue_segment.png` — 256×48, segmento horizontal **repetível** (as bordas
  esquerda/direita encaixam), língua rosa-arroxeada úmida com brilho e veios roxos.
- `boss4_tongue_tip.png` — 96×96, ponta da língua (gota grudenta), apontando para a
  DIREITA, centro da base em (8,48).

## 5. Pendências de arte (ordem sugerida)
1. `tongue_v2` (5 quadros) + texturas da língua — tarefa `boss4_tongue_sprites.md`
2. `comet_v2` sem o raio pintado (carga no capacete) + textura do raio
3. `bigjump` (variação do hop com preparação maior) — opcional, o `hop` pode servir

## 6. Status (2026-11-03)
- Implementado: locomocao por saltos (`hop`), Lingua-Arpao (mira que trava, acerto
  puxa + tapa, dash solta, erro puxa o boss), Salto Esmagador com anel de choque
  (dash atravessa), sorteio de assinatura por estagio (`STAGE_ACTIONS`).
- Arte integrada: `boss4_hop_00..05`, `boss4_tongue_v2_00..04` (04 reduzido 0,92 nos pes),
  `boss4_tongue_segment`, `boss4_tongue_tip`. Originais do Codex em `hop_raw/` e
  `tongue_v2_raw/` (com `.gdignore`, fora do export).
- Ancoras da boca (celula 384): 00 (146,186), 01 (140,182), 02 (143,202), 03 (156,196), 04 (150,196).
- Testes: `tests/boss4_hop_tongue_smoke.gd`, `tests/boss4_hop_tongue_visual_smoke.gd`
  (capturas e GIF em `.agent_logs/boss4_rework_v2/`).
- Proximo: `comet_v2` sem o raio pintado + textura do raio; Poco Gravitacional com o
  sapo saltando em volta.


### Raio do Capacete (implementado)
- Carga 0.7s: setor de 110 graus centrado no jogador, setas no sentido da varredura, brilho no visor.
- Ativo 0.9s: raio varre o arco com smoothstep, alcance 540, meia largura 22, dano `_boss4_damage(0.06, 26)` com 0.3s de recarga por alvo, empurra no sentido da varredura; dash (0.18s) atravessa.
- Recuperacao 0.4s, recarga 6.5s. Origem do raio = `beam_origin()` (visor, espelhado pelo facing).
- Arte integrada: `boss4_comet_v2_00..04` (reduzidos 0.9 nos pes, visor medido em (138,166) -> `BEAM_VISOR_OFFSET (-28,-4)`), `boss4_beam_segment/origin/impact`; brutos em `comet_v2_raw/` com `.gdignore`. Fallback procedural mantido; usa `boss4_beam_segment/origin/impact` e `boss4_rework_comet_v2` automaticamente quando os PNGs existirem (tarefa `.codex/tasks/boss4_helmet_beam_sprites.md`).
- Testes: `tests/boss4_helmet_beam_smoke.gd`, `tests/boss4_helmet_beam_visual_smoke.gd`.


### Poco Gravitacional (implementado)
- Carga 0.8s: aviso no ponto do jogador (circulo do raio de puxao 300, setas para dentro, nucleo 56).
- Ativo 3.0s: poco nasce ao fim da carga; puxa o jogador local (60->200 px/s, mais forte perto do centro, rampa 0.35s; dash ignora); nucleo fere `_boss4_damage(0.035, 14)` a cada 0.4s.
- O sapo crava as maos (0.4s) e da 2 saltos de 95 graus em volta do poco (raio 215), cada pouso solta uma onda menor (40->175, 0.5s).
- Implosao em 2.9s (aviso de 0.5s: anel encolhendo ate o raio 150 piscando): `_boss4_damage(0.1, 42)` e empurrao para fora.
- Recuperacao 0.6s, recarga 12s. Estado no `boss4_ai_state` (`well_pos`, `orbit_hop`, `hop_from/to`) e hazard `boss4_singularity`.
- Arte integrada: `boss4_gravity_v2_00..03` (sem reescala) e `boss4_singularity_core/swirl/burst` (swirl a 1.22x do raio, alpha 0.55 para nao esconder o jogador); brutos em `gravity_v2_raw/` com `.gdignore`.
- Testes: `tests/boss4_gravity_well_smoke.gd`, `tests/boss4_gravity_well_visual_smoke.gd`.
