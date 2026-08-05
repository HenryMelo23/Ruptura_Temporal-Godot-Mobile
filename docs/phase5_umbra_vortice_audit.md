# Auditoria e Plano de Port: Habilidade VÓRTICE (Umbra - Fase 5)

## Etapa 1: Auditoria do Game Base (`Game Base/habilidade_boss.py` & `Game Base/GAME5.py`)

### 1. Identificação Geral
- **Nome real da ação**: `VORTICE` (e `TRANSMUTAR_VORTICE` para alternar a dimensão).
- **Dimensão associada**: Dimensão `vortice` (Superfície da Fase 1 - `Sprites/Fase1.png`).

### 2. Condições de Disparo
- A Umbra precisa estar na dimensão `vortice` (`mapa_atual == "Sprites/Fase1.png"` ou `boss5_dimension == "vortice"`).
- Respeita o cooldown da habilidade: `agora - estado_ia.get('ultimo_vortice', 0) >= 12000` (12 segundos).
- Quando a Umbra transmuta para `vortice` via `TRANSMUTAR_VORTICE`, o `ultimo_vortice` é resetado para `0` (`estado_ia['ultimo_vortice'] = 0`), permitindo o uso imediato de VÓRTICE ao entrar na dimensão.
- Nenhuma outra habilidade dimensional pode estar ativa no momento do cast (`vortice_ativo == None`).

### 3. Métricas Técnicas
- **Cooldown**: 12,0 segundos (`12000 ms`).
- **Duração Total**: 8,0 segundos (`8000 ms`).
  - **Telegraph / Aviso**: 1,5 segundos (`1500 ms`).
  - **Execução Ativa**: 6,5 segundos (`6500 ms`).
- **Área de Efeito**:
  - **Centro**: Centro geométrico da arena / tecido dimensional (`alvo_x = largura_mapa // 2`, `alvo_y = altura_mapa // 2`).
  - **Raio de Aviso / Sinalização**: 150 px.
  - **Raio de Sucção**: Até 900 px de distância (`dist_v < 900`).
  - **Raio de Dano**: O dano por tick ocorre somente quando o jogador está a menos de 150 px do centro (`dist_v < 150`).
- **Força de Sucção**:
  - `fator_succao = forca * (1 - min(1, dist_v / 900))`, onde `forca = 2.8` (no Game Base) ou equivalente vetorial em pixels/segundo no Godot.
- **Dano ao Jogador**:
  - Dano por tick quando `dist_v < 150` px. No Game Base: `apolo.receber_dano_punitivo(1, 2.0)` a cada 200 ms. No Godot: Dano contínuo por tick na zona central com multiplicador punitivo.

### 4. Visual e Animação (VFX)
- **Fase de Telegraph (0,0s - 1,5s)**:
  - **Sem sucção e sem dano**.
  - Círculo de aviso preenchido no chão (Raio 150 px): Cor Roxa/Violeta `(138, 43, 226)` com pulso de alpha `50 + sin(tempo * 0.01) * 30`.
  - Borda externa do anel: Cor Rosa/Magenta `(255, 0, 128, 200)` com espessura 3.
  - Anel interno em contração: Anel Branco `(255, 255, 255, 220)` encolhendo de 150 px a 0 px proporcionalmente ao tempo do aviso (`1.0 - progresso`).
- **Fase Ativa (1,5s - 8,0s)**:
  - Atração vetorial puxando o jogador continuamente em direção ao centro.
  - Singularidade circular/espiralada em rotação contínua.
  - Núcleo denso violeta/magenta intenso no centro (raio 150 px) demarcando a área de dano.
  - Raios espiralados e anéis concentricos giratórios nas bordas.
- **Fase de Dissipação (8,0s)**:
  - O vórtice finaliza suavemente e a chave `vortice_ativo` / hazard é destruída sem deixar resíduos visuais.

---

## Etapa 2: Auditoria do Godot Atual (`scripts/main.gd`)

### Estado Atual no Godot
1. `BOSS5_VORTEX_DURATION` está configurado para `6.0` s em vez de `8.0` s.
2. Não há fase de aviso (telegraph) de 1.5s isolada: o VÓRTICE no Godot atual puxava e dava dano desde o t=0.
3. O raio de puxão do Godot usava `radius = 300.0` com fórmula `240.0 * (1.0 - dist / 300.0)`, divergindo do alcance do Game Base (que tem influência até 900px e núcleo de dano de 150px).
4. O VFX atual desenhava apenas 5 arcos verdes genéricos simples com `draw_arc` e `draw_circle`, sem a paleta Roxa/Magenta do Game Base, sem o anel de contração branco de aviso, e sem o centro denso de singularidade.
5. O cooldown é `12.0`s. Transmutar para `vortice` via `TRANSMUTAR_VORTICE` troca o mapa para a Fase 1 (`vortice`).

---

## Plano de Implementação no Godot

1. **Ajuste de Parâmetros**:
   - Atualizar `BOSS5_VORTEX_DURATION` para `8.0` segundos.
   - Definir `BOSS5_VORTEX_WARNING` para `1.5` segundos.
   - Definir raio de aviso / dano central para `150.0` px e raio de sucção física para `750.0` - `900.0` px.

2. **Lógica de Atualização (`_update_phase5_hazards`)**:
   - Durante `warning` (tempo decorrido < 1.5s): NENHUMA sucção e NENHUM dano.
   - Após `warning` (tempo decorrido >= 1.5s):
     - Aplicar força de sucção puxando o player para `hazard["pos"]`.
     - Aplicar dano por tick somente se a distância do player ao centro for menor que 150 px.

3. **VFX Fiel ao Game Base (`_draw_phase5_environment`)**:
   - **Telegraph (0.0s a 1.5s)**:
     - Desenhar círculo preenchido em `(138, 43, 226)` com alfa pulsante.
     - Desenhar borda de 3px em `(255, 0, 128)`.
     - Desenhar anel interno branco `(255, 255, 255)` contraindo de 150px a 0px.
   - **Execução Ativa (1.5s a 8.0s)**:
     - Desenhar singularidade espiralada roxa/magenta/ciano com rotação.
     - Desenhar núcleo denso de dano de 150px.
     - Partículas/linhas de energia sendo sugadas para o centro.

4. **Teste Smoke Dedicado (`tests/phase5_umbra_vortice_visual_smoke.gd`)**:
   - Iniciar run na Fase 5.
   - Forçar transmutação para `vortice`.
   - Disparar `VORTICE`.
   - Capturar screenshots em todas as 4 fases (antes, aviso, execução, dissipação).
   - Validar remoção limpa do hazard sem lixo em `phase5_hazards`.
