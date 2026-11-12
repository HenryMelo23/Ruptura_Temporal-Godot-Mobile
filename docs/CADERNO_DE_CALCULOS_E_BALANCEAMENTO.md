# Caderno de Cálculos e Balanceamento — Ruptura Temporal

**Tipo:** documento técnico interno e vivo
**Objetivo:** registrar, reproduzir e auditar os modelos matemáticos usados pelo jogo
**Versão do documento:** 1.0
**Última revisão:** 2026-11-09

## 1. Finalidade

Este caderno é a fonte central para documentar os cálculos de combate, bosses,
IA, progressão e economia de **Ruptura Temporal**. Ele deve permitir que a equipe
e, futuramente, um matemático externo consigam:

1. reproduzir cada resultado sem precisar interpretar o código inteiro;
2. identificar unidades incompatíveis, crescimento excessivo, descontinuidades,
   arredondamentos e limites incorretos;
3. separar comportamento confirmado de hipótese, intenção de design ou fórmula
   ainda não auditada;
4. comparar alterações de balanceamento ao longo das versões;
5. localizar rapidamente o código e os testes que sustentam cada fórmula.

Este documento **não substitui o código nem os testes**. Se houver divergência,
o código executado é o comportamento real, a divergência deve ser registrada e
o caderno precisa ser corrigido na mesma alteração.

## 2. Estados de auditoria

| Estado | Significado |
|---|---|
| **Confirmado** | Fórmula conferida no código e coberta por teste focado. |
| **Parcial** | Parte do contrato foi conferida, mas faltam termos, limites ou fluxo completo. |
| **A auditar** | Sistema identificado, porém a fórmula vigente ainda não foi transcrita e validada. |
| **Histórico** | Fórmula desativada, mantida apenas para explicar resultados ou migrações antigas. |

Nenhuma fórmula deve ser marcada como **Confirmado** apenas porque parece correta
em uma leitura rápida. É necessário registrar código, exemplo reproduzível e
teste correspondente.

## 3. Convenções matemáticas

- `t`: tempo total da run, em segundos, salvo quando outra unidade for indicada.
- `m`: tempo total da run em minutos, com `m = max(0, t / 60)`.
- `p`: fase ou identificador do boss.
- `n`: quantidade de jogadores considerados pelo escalonamento de grupo.
- `HP`: pontos de vida.
- Percentuais devem ser registrados como razão interna e como percentual
  legível. Exemplo: `0,25 = 25%`.
- Intervalos devem informar se incluem as extremidades: `[0, 1]`, `(0, 1]` etc.
- Toda operação `min`, `max`, `clamp`, potência, piso, teto ou arredondamento
  deve aparecer explicitamente.
- Valores exibidos podem ser arredondados, mas exemplos devem informar se o
  cálculo interno conserva ponto flutuante completo.
- Fórmulas dependentes de FPS, delta, tick de rede ou dificuldade precisam
  declarar essa dependência.
- O separador decimal deste documento é a vírgula; os trechos de código usam
  ponto, conforme a linguagem.

## 4. Índice dos modelos

| ID | Sistema | Estado | Próxima ação de auditoria |
|---|---|---|---|
| `BOSS-HP-001` | Vida inicial dos bosses por fase e tempo | **Confirmado** | Avaliar a curva contra duração real de cada luta. |
| `BOSS-PARTY-001` | Vida, pressão e ritmo por quantidade de jogadores | **Parcial** | Registrar a tabela/função completa quando a validação multiplayer for retomada. |
| `BOSS-ARMOR-001` | Armadura dos bosses | **A auditar** | Mapear fórmula, tempo, eliminações, cartas e limites. |
| `BOSS-DAMAGE-001` | Pressão e dano causado pelos bosses | **A auditar** | Separar dano base, tempo, pontuação, eliminações e limite vigente. |
| `COMBAT-DAMAGE-001` | Dano do jogador e inimigos | **A auditar** | Mapear ordem de ataque, bônus, redução, armadura e dano final. |
| `COMBAT-CRIT-001` | Chance e multiplicador crítico | **A auditar** | Registrar distribuição, limites, empilhamento e pseudoaleatoriedade, se houver. |
| `COMBAT-DOT-001` | Dano periódico, queimadura e efeitos acumuláveis | **A auditar** | Registrar tick, duração, renovação e fonte do dano. |
| `SCORE-001` | Pontuação e recompensas por inimigo | **A auditar** | Mapear valores base, minibosses, multiplicadores e compartilhamento. |
| `ECON-SHOP-001` | Preço, reroll e progressão da loja | **A auditar** | Registrar custos, crescimento, raridades e interação com pontuação. |
| `ECON-CARDS-001` | Oferta e valor matemático das cartas | **A auditar** | Registrar pesos, raridade, limite, duplicatas e retorno esperado. |
| `AI-UMBRA-001` | Inferência neural da UMBRA | **Parcial** | Auditar normalização, saída, máscara de ações e seleção final. |
| `AI-LEARNING-001` | Memória, recompensa e aprendizado dos bosses | **A auditar** | Separar inferência, memória de run, perfil persistente e treinamento. |

---

## 5. `BOSS-HP-001` — Vida inicial dos bosses

### 5.1 Estado e intenção

- **Estado:** Confirmado.
- **Intenção de design:** permitir que builds fortes continuem recompensadoras,
  mas impedir que bosses sejam eliminados antes de executar suas mecânicas.
- **Regra de justiça:** a vida cresce pelo tempo sobrevivido na run, não por
  pontuação ou quantidade de inimigos eliminados.
- **Ausência de teto:** o crescimento temporal não possui limite máximo.
- **Momento de aplicação:** a vida é calculada quando o boss é criado. Ela não
  é recalculada continuamente durante a luta.
- **Escopo:** esta fórmula altera bosses; inimigos comuns não a utilizam.

### 5.2 Fórmula completa

Para um boss da fase `p`, criado no instante `t`, com coeficiente de grupo `P(n)`:

```text
HP(p, t, n) = B(p) × D(p) × T(t) × P(n)

m = max(0, t / 60)
T(t) = 1 + 0,06 × m^0,85
```

Onde:

| Símbolo | Unidade | Domínio | Descrição |
|---|---:|---:|---|
| `HP(p,t,n)` | HP | `(0, +∞)` | Vida máxima atribuída ao boss ao surgir. |
| `B(p)` | HP | `(0, +∞)` | Vida base específica da fase. |
| `D(p)` | adimensional | `(0, +∞)` | Multiplicador fixo de durabilidade da fase. |
| `T(t)` | adimensional | `[1, +∞)` | Multiplicador crescente pelo tempo total da run. |
| `P(n)` | adimensional | `[1, +∞)` no contrato atual | Coeficiente de vida para o tamanho do grupo. Em solo vale `1`. |
| `t` | segundos | `[0, +∞)` | Tempo total registrado em `time_alive`. |
| `m` | minutos | `[0, +∞)` | Tempo normalizado para a curva. |

Pontuação e eliminações não são argumentos de `HP(p,t,n)`.

### 5.3 Bases e durabilidade por fase

Modelo atual: `boss_hp_durability_v3_time_only` (11/11/2026). A v3 dobra todos
os coeficientes da v2 — a vida final de cada boss é exatamente o dobro.

| Fase | `B(p)` | Origem da base | `D(p)` v2 | `D(p)` v3 | `B(p) × D(p)` em solo, `t = 0` |
|---:|---:|---|---:|---:|---:|
| 1 | 4.860 | `BOSS_BASE_HP` | 3,00 | 6,00 | 29.160 |
| 2 | 8.910 | base específica | 3,25 | 6,50 | 57.915 |
| 3 | 17.280 | base específica | 3,50 | 7,00 | 120.960 |
| 4 | 25.380 | base específica | 3,75 | 7,50 | 190.350 |
| 5 | 35.100 | base específica | 4,00 | 8,00 | 280.800 |
| 6 | 21.870 | `4.860 × 4,5` | 3,75 | 7,50 | 164.025 |
| 7 | 8.505 | `4.860 × 1,75` | 4,50 | 9,00 | 76.545 |

A curva temporal `T(t)` continua por cima: na fase 5 aos 20 min de run a vida
chega a ≈495.800 em solo.

As bases não são monotônicas entre as fases. Isso não é automaticamente um
erro, pois cada boss pode ter defesa, cura, estágios e janelas de vulnerabilidade
diferentes, mas é um ponto que deve ser avaliado na auditoria global.

### 5.4 Comportamento da curva temporal

Para `m > 0`:

```text
dT/dm = 0,051 × m^-0,15
```

A curva é sempre crescente, não tem teto e cresce de forma sublinear. Portanto,
o multiplicador continua aumentando em runs de muitas horas, mas sua taxa de
crescimento diminui progressivamente.

| Tempo da run | `T(t)` aproximado |
|---:|---:|
| 0 min | 1,00× |
| 25 min | 1,93× |
| 1 h | 2,95× |
| 2 h | 4,51× |
| 3 h | 5,96× |
| 10 h | 14,79× |

Não existe `min`, `clamp` ou tempo máximo nessa função.

### 5.5 Exemplo reproduzível

Boss da fase 5, em solo, após 25 minutos:

```text
B(5) = 35.100
D(5) = 4
P(1) = 1
T(1.500 s) = 1 + 0,06 × 25^0,85 ≈ 1,9255

HP(5, 1.500, 1) = 35.100 × 4 × 1,9255 × 1
HP(5, 1.500, 1) ≈ 270.347,3
```

O runtime conserva ponto flutuante no cálculo. Arredondamentos apresentados no
relatório ou neste documento são apenas para leitura.

### 5.6 Invariantes e testes

Devem permanecer verdadeiros:

1. `T(0) = 1`.
2. Se `t2 > t1 ≥ 0`, então `T(t2) > T(t1)`.
3. `lim(t→∞) T(t) = +∞`.
4. Alterar pontos ou eliminações sem alterar `t`, `p` e `n` não muda a vida.
5. A fórmula não altera a vida dos inimigos comuns.

Evidência automatizada atual:

- `tests/boss_farm_balance_smoke.gd`: curva de 0 min até 10 h e independência
  de pontos/eliminações, inclusive comparação entre `0` e `999.999`.
- `tests/test_boss_stats_scaling.gd`: bases e escalonamento por fase.
- `tests/boss_party_scaling_smoke.gd`: composição com o coeficiente de grupo.

### 5.7 Código proprietário

- Constantes do modelo: `scripts/main_runtime_state.gd`.
- Cálculo da vida: `scripts/main_runtime_core.gd::_boss_hp_for_phase()`.
- Curva temporal: `scripts/main_runtime_core.gd::_boss_time_hp_multiplier()`.

### 5.8 Perguntas para auditoria matemática e de design

1. A potência `0,85` mantém uma duração saudável em runs reais de 3 a 10 horas?
2. A taxa `0,06` produz tempo de luta adequado para builds médias e extremas?
3. A derivada elevada perto de `m = 0` possui algum efeito relevante nos
   primeiros minutos, mesmo com o cálculo discreto feito na criação do boss?
4. As bases não monotônicas das fases 5, 6 e 7 são compensadas corretamente
   pelas mecânicas defensivas e pelos estágios de cada boss?
5. A composição multiplicativa entre base, fase, tempo e grupo é preferível a
   uma composição parcialmente aditiva?

---

## 6. `BOSS-PARTY-001` — Escalonamento por grupo

- **Estado:** Parcial.
- A vida final usa o coeficiente multiplicativo `P(n)`.
- Em solo, `P(1) = 1`.
- O runtime também mantém coeficientes separados para vida, pressão e ritmo.
- A tabela/função completa, os limites e a autoridade multiplayer ainda precisam
  ser registrados quando a validação multiplayer for retomada.

Essa pendência não muda a confirmação da curva temporal em solo.

---

## 7. `AI-UMBRA-001` — Contrato matemático da inferência

### 7.1 Estado

- **Estado:** Parcial.
- **Modelo declarado:** `umbra_dqn_2_0_actions_23`.
- **Dimensões declaradas:** `24 → 128 → 64 → 23`.
- **Objetivo desta entrada:** preservar a interface matemática do modelo sem
  afirmar que treinamento, recompensa ou seleção final já foram auditados.

### 7.2 Forma geral da rede

Para um vetor de observação `x ∈ R^24`, a forma esperada é:

```text
h1 = ReLU(W1 × x + b1)       com h1 ∈ R^128
h2 = ReLU(W2 × h1 + b2)      com h2 ∈ R^64
q  = W3 × h2 + b3            com q  ∈ R^23
```

As 23 saídas representam valores ou preferências associados às 23 ações do
contrato. Ainda precisam ser documentados: normalização de cada entrada,
tratamento de ações impossíveis, estratégia de exploração, desempate e caminho
de fallback.

### 7.3 Vetor de entrada, na ordem do contrato

```text
boss_hp_ratio, distance_to_player, under_fire,
player_velocity_x, player_velocity_y, boss_player_dx, boss_player_dy,
hazard_vortex, hazard_prison, hazard_thorns, hazard_overload_laser,
hazard_discharge, hazard_miasma, rats_active, siphon_active, dimension_map,
threat_x, threat_y, player_edge_x, player_edge_y, boss_edge_x, boss_edge_y,
player_corner_pressure, player_center_distance
```

A ordem faz parte da interface binária do modelo. Trocar posições sem treinar e
exportar pesos compatíveis altera o significado matemático da rede.

### 7.4 Vetor de ações, na ordem do contrato

```text
FUGIR, INTERCEPTAR, ORBITAR, CERCAR, ATAQUE, SIFON, TELEPORTE,
TELEPORTE_JUKE, TRANSMUTAR_VORTICE, TRANSMUTAR_GRAVIDADE,
TRANSMUTAR_NECROSE, TRANSMUTAR_RESSONANCIA, TRANSMUTAR_HEMORRAGIA,
TRANSMUTAR_ATRITO, TRANSMUTAR_RASTRO, VORTICE, PRISAO, MIASMA,
DESCARGA_ELETRICA, PRAGA_RATOS, LASER_SOBRECARGA,
CAMINHO_ESPINHOS, NENHUMA
```

### 7.5 Pendências obrigatórias

1. Definir domínio, unidade e normalização de cada uma das 24 entradas.
2. Confirmar funções de ativação e orientação das matrizes no runtime.
3. Registrar como `q` é transformado na ação executada.
4. Registrar fallback heurístico e condições que rejeitam pesos incompatíveis.
5. Separar claramente inferência em jogo de treinamento fora do jogo.

---

## 8. `AI-LEARNING-001` — Aprendizado e memória dos bosses

- **Estado:** A auditar.

Esta entrada deve distinguir quatro camadas que não podem ser tratadas como se
fossem o mesmo cálculo:

1. **Observação:** dados medidos do jogador e do estado da luta.
2. **Inferência:** escolha feita por heurística, política ou rede já treinada.
3. **Memória:** informação temporária da luta, agregada da run ou persistente.
4. **Treinamento:** atualização de parâmetros/pesos a partir de experiência.

Para cada boss que aprende ou se adapta, registrar:

- estado observado `s_t` e suas unidades;
- ação escolhida `a_t`;
- recompensa `r_t`, com cada bônus e penalidade;
- fator de desconto `γ`;
- taxa de aprendizado `α`;
- política de exploração, como `ε` e sua curva de decaimento;
- função de perda e atualização dos pesos;
- tamanho, retenção e amostragem da memória;
- momento em que dados são persistidos ou esquecidos;
- separação entre jogadores, perfis, runs e modos solo/multiplayer;
- limites e mecanismos contra aprendizado degenerado ou explorável.

Até essa auditoria ser concluída, não se deve descrever memória adaptativa como
prova de treinamento neural ativo.

---

## 9. Fichas reservadas para a próxima auditoria

### 9.1 `COMBAT-DAMAGE-001` — Dano

Registrar, na ordem real de aplicação:

```text
dano base
→ bônus aditivos
→ bônus multiplicativos
→ crítico
→ vulnerabilidade/resistência
→ armadura/redução
→ escudos e absorções
→ arredondamento
→ dano final e limite mínimo
```

Também registrar dano por segundo, frequência de ataque, projéteis múltiplos,
área, perfuração, dano periódico e interação entre cartas.

### 9.2 `COMBAT-CRIT-001` — Crítico

Registrar:

- chance base e chance final;
- limite mínimo e máximo;
- distribuição aleatória ou pseudoaleatória;
- multiplicador crítico base e bônus;
- interação com dano periódico, área, invocações e múltiplos projéteis;
- ordem entre crítico, armadura e vulnerabilidade;
- valor esperado: `E[dano]` para cada configuração relevante.

### 9.3 `ECON-SHOP-001` — Economia da loja

Registrar:

- fontes e sumidouros de pontos/moeda;
- custo inicial e crescimento por compra, reroll, fase e tempo;
- peso das raridades e probabilidade real de oferta;
- efeito de cartas que alteram preço, oferta ou ganho;
- retorno esperado por minuto e por inimigo;
- inflação da run e capacidade de compra esperada;
- cenários médio, azarado e extremo;
- mecanismos que impedem loops infinitos ou estados sem saída.

### 9.4 `ECON-CARDS-001` — Valor das cartas

Para cada carta numérica ou mecânica, registrar:

- fórmula por quantidade de cópias;
- empilhamento aditivo ou multiplicativo;
- limite, piso e retornos decrescentes;
- interações e exceções;
- efeito esperado sobre dano, sobrevivência, mobilidade ou economia;
- valor imediato versus valor acumulado ao longo da run.

### 9.5 `SCORE-001` — Pontuação e recompensas

Registrar:

- recompensa base por tipo de inimigo;
- bônus de minibosses e bosses;
- multiplicadores de fase, dificuldade e grupo;
- compartilhamento ou propriedade da pontuação;
- prevenção de duplicação;
- relação entre risco, tempo para matar e recompensa.

---

## 10. Modelo obrigatório para novas entradas

Copiar esta ficha para qualquer cálculo novo ou alterado:

```markdown
## `<ID>` — Nome do modelo

- Estado: Confirmado | Parcial | A auditar | Histórico
- Intenção de design:
- Código proprietário:
- Testes:
- Última alteração:

### Variáveis
| Símbolo | Unidade | Domínio | Descrição | Origem |

### Fórmula
Escrever a fórmula completa e a ordem das operações.

### Limites e casos extremos
Piso, teto, clamp, zero, negativos, infinito, NaN, overflow e entradas ausentes.

### Exemplo reproduzível
Entradas, contas intermediárias e resultado final.

### Invariantes
Propriedades que nunca podem ser quebradas.

### Interações
Outros sistemas, cartas, fases, jogadores ou estados que alteram o resultado.

### Evidência
Teste automatizado, cenário manual e resultado observado.

### Perguntas para auditoria
Hipóteses, riscos e decisões que precisam de revisão matemática ou de design.
```

## 11. Processo de manutenção

1. Toda mudança de fórmula deve atualizar sua entrada neste caderno.
2. A mudança deve registrar antes/depois, motivo e efeito esperado.
3. Fórmulas removidas passam para **Histórico**; não devem simplesmente sumir.
4. Exemplos devem usar valores que também possam ser reproduzidos por teste.
5. Uma revisão matemática futura deve gerar uma lista separada de achados, sem
   reescrever silenciosamente a intenção de design.
6. Resultados de partidas reais devem ser comparados com as previsões deste
   documento; divergências podem revelar erro de implementação ou modelo
   incompleto.

## 12. Histórico de revisões

| Data | Versão | Alteração |
|---|---:|---|
| 2026-11-09 | 1.0 | Criação do caderno; registro completo de `BOSS-HP-001`; contrato parcial da UMBRA; criação do índice e das fichas de auditoria futuras. |
