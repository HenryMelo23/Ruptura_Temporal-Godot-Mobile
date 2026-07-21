# Fase 5 mobile - UMBRA

Fonte de verdade inicial: `Game Base/habilidade_boss.py`, `Game Base/GAME5.py`, `Game Base/memoria_predatoria_umbra.json`, `Game Base/umbra_dossie.py`, `Game Base/umbra_profecia.py` e `Game Base/sistema_ratos_umbra.py`.

## Decisao de porte

A UMBRA nao deve depender de PyTorch no celular. No desktop, a mente completa usa `UmbraDQN` e `MemoriaEvolutivaUmbra`; no mobile, a fase importa o dossie/memoria JSON treinado no desktop e usa uma camada leve de pesos por acao, salva em `user://memoria_predatoria_umbra_mobile.json`.

Isso preserva a ideia central:

- o desktop continua sendo o lugar de treino pesado;
- o mobile le a mente aprendida em menor escala;
- durante a luta mobile a UMBRA ainda aprende, mas com atualizacoes simples por recompensa;
- a UMBRA continua usando leitura de movimento, distancia, vida, borda, historico e arquétipo do jogador;
- Apolo nao entra no porte mobile, porque ele era segunda IA de experimento e nao participa do jogo mobile.

## Anatomia desktop da UMBRA

### `UmbraDQN`

Rede neural PyTorch com:

- entrada de 24 features;
- camada linear 128;
- `LeakyReLU`;
- camada linear 64;
- `LeakyReLU`;
- saida com uma pontuacao por acao.

No desktop, isso permite escolher a melhor acao entre as disponiveis, com exploracao probabilistica.

### `MemoriaEvolutivaUmbra`

Responsabilidades:

- carregar `saves/memoria_umbra_dqn.pt`;
- carregar/salvar `saves/tendencias_umbra.json`;
- manter `exploracao`;
- registrar esquivas do jogador por eixo;
- calcular bias bayesiano de movimento;
- discretizar o estado do combate em 24 features;
- decidir uma acao via exploracao ou Q-values;
- treinar a ultima decisao usando recompensa.

No mobile, a parte PyTorch vira `boss5_mobile_weights`. Cada acao tem um peso simples que sobe ou desce conforme sucesso/fracasso.

### Features usadas no desktop

A UMBRA observa:

- percentual de vida dela;
- distancia ate o jogador;
- se esta sob fogo;
- velocidade recente do jogador;
- vetor jogador/boss;
- armadilhas ativas;
- mapa/dimensao atual;
- vetor de ameaca;
- distancia do jogador ate bordas;
- distancia da UMBRA ate bordas;
- jogador em canto;
- distancia do jogador ao centro.

No mobile, a primeira versao ja usa distancia, vida, historico de posicao, borda, movimento lateral, dimensao ativa e pesos salvos.

### Acoes base

A lista original contem:

- `FUGIR`
- `INTERCEPTAR`
- `ORBITAR`
- `CERCAR`
- `ATAQUE`
- `SIFON`
- `TELEPORTE`
- `TELEPORTE_JUKE`
- `TRANSMUTAR_VORTICE`
- `TRANSMUTAR_GRAVIDADE`
- `TRANSMUTAR_NECROSE`
- `TRANSMUTAR_RESSONANCIA`
- `TRANSMUTAR_HEMORRAGIA`
- `TRANSMUTAR_ATRITO`
- `TRANSMUTAR_RASTRO`
- `VORTICE`
- `PRISAO`
- `MIASMA`
- `DESCARGA_ELETRICA`
- `PRAGA_RATOS`
- `LASER_SOBRECARGA`
- `CAMINHO_ESPINHOS`
- `NENHUMA`

Todas foram registradas no mobile como acoes conhecidas. Algumas ainda sao mapeadas para versoes visuais/procedurais simplificadas, mas ja existem no loop de decisao.

## Sistema adaptativo

O desktop carrega `memoria_predatoria_umbra.json` e identifica o perfil do jogador:

- `REFUGIADO_DE_CANTO` vira `CORTAR_BORDAS`;
- `DEPENDENTE_DE_DASH` vira `PUNIR_DASH_PREVISIVEL`;
- `CACADOR_DE_ORBES` vira `ISCA_DE_ORBE`;
- `AGRESSOR_IMPULSIVO` vira `CONTRA_IMPULSO`;
- `ATIRADOR_DISTANTE` vira `QUEBRAR_DISTANCIA`;
- `CORREDOR_CIRCULAR` vira `QUEBRAR_ROTACAO`;
- `SOBREVIVENTE_ADAPTATIVO` vira `RESPEITAR_ADAPTATIVO`.

No mobile, `_build_umbra_predatory_mods()` importa esses modificadores e aplica bias em `_apply_umbra_predatory_bias()`.

## Profecia falsificavel

No desktop, `umbra_profecia.py` cria previsoes sobre o jogador e recompensa/pune a UMBRA se ela acertar ou errar.

No mobile, a primeira etapa nao copia a classe inteira. A equivalencia inicial e:

- historico curto em `phase5_player_history`;
- predicao de posicao por `_predict_player_pos()`;
- `PRISAO`, `DESCARGA_ELETRICA`, `CAMINHO_ESPINHOS` e `ATAQUE` miram posicao futura;
- acerto dessas acoes chama `_umbra_learn()`.

Proxima etapa recomendada: portar uma estrutura explicita de profecias com `tipo`, `target`, `expires`, `confirmed` e `broken`.

## Movimento

Desktop: `movimentacao_inteligente_umbra()` escolhe `FUGIR`, `INTERCEPTAR`, `ORBITAR` ou `CERCAR`, com inercia e repulsao do jogador.

Mobile: `_move_umbra()` reproduz a ideia:

- foge se esta perto demais;
- cerca se o jogador encosta nas bordas;
- intercepta usando historico;
- orbita como comportamento padrao;
- usa lerp de velocidade para evitar tremedeira;
- usa alvo e inercia para parecer pensante.

## Habilidades portadas na base mobile

### ATAQUE

Desktop: `node_ataque_direcionado()` cria projetil preditivo.

Mobile: `_fire_umbra_projectile()` cria `umbra_plasma`, registrado no netcode e desenhado com plasma verde.

### SIFON

Desktop: para a UMBRA, cria parede/estado de stasis, cura e recompensa conforme necessidade.

Mobile: `boss5_siphon_timer` reduz dano recebido, cura parte do dano absorvido, causa dano em area e aumenta peso se usado com sucesso.

### TELEPORTE e TELEPORTE_JUKE

Desktop: usa `node_teleporte_sinalizador()` com sinal real/falso.

Mobile: `phase5_telegraphs` desenha linha/portal. Se `real`, move a UMBRA ao terminar o delay. Se falso, apenas cria leitura visual.

### TRANSMUTAR

Desktop: troca o mapa/dimensao e destrava habilidade daquela dimensao.

Mobile: muda `boss5_dimension`, reseta cooldown da habilidade associada, gera burst visual e teleporta. O mapa ainda permanece o da fase 5 para nao quebrar camera/progresso mobile.

### VORTICE

Desktop: puxa para o centro do tecido dimensional.

Mobile: hazard circular no centro, puxa o jogador e causa dano por tick.

### PRISAO

Desktop: projeta armadilha na rota futura do jogador.

Mobile: usa `_predict_player_pos()`, mostra aviso e aplica stun/dano se o jogador estiver dentro ao fechar.

### MIASMA

Desktop: zona toxica temporal.

Mobile: zona verde em volta do alvo, dano por tick.

### DESCARGA_ELETRICA e LASER_SOBRECARGA

Desktop: descarga/laser com carga e linha de punição.

Mobile: linha com warning; ao ativar, aplica dano/stun se o jogador estiver no segmento.

### CAMINHO_ESPINHOS

Desktop: caminho hostil crescendo pela rota.

Mobile: linha de espinhos entre boss e predicao do jogador, com dano por tick se cruzada.

### PRAGA_RATOS

Desktop: `GerenciadorRatos` cria ratos, colisao, cura e pressao.

Mobile: `phase5_rats` cria perseguidores leves, com cura pequena para UMBRA quando acertam.

## Assets portados

Copiados do snapshot desktop embutido:

- `assets/sprites/Fase5-1.png`;
- `assets/sprites/Geo-Umbra-V2-1.png`;
- `assets/sprites/Geo-Umbra-V2-2.png`;
- `assets/sprites/Geo_Umbra_Escudo-1.png`;
- `assets/sprites/Geo_Umbra_Escudo-2.png`.

Ja existiam no mobile:

- `assets/sprites/Geo-Umbra-V2-1-dano.png`;
- `assets/sprites/Geo-Umbra-V2-2-dano.png`;
- `assets/sprites/Geo-Umbra-V2-3-dano.png`;
- `assets/sprites/Geo-Umbra-V2-4-dano.png`;
- `assets/sprites/Geo-Umbra-V2-5-dano.png`.

## Estrutura mobile criada

Estados principais:

- `phase5_player_history`;
- `phase5_hazards`;
- `phase5_rats`;
- `phase5_telegraphs`;
- `boss5_mobile_weights`;
- `boss5_predatory_mods`;
- `boss5_dimension`;
- `boss5_mental_state`;
- `boss5_velocity`;
- `boss5_target`.

Funcoes principais:

- `_load_umbra_mobile_memory()`;
- `_save_umbra_mobile_memory()`;
- `_build_umbra_predatory_mods()`;
- `_update_boss_phase5()`;
- `_umbra_choose_action()`;
- `_spawn_umbra_action()`;
- `_move_umbra()`;
- `_update_phase5_hazards()`;
- `_update_phase5_rats()`;
- `_draw_phase5_environment()`.

## Fluxo de fase

- derrotar o boss 4 agora cria fragmento para a fase 5;
- `_advance_to_phase(5)` inicia `FASE 5: MENTE DA UMBRA`;
- o botao de boss chama `UMBRA`;
- derrotar a UMBRA finaliza a run em vitoria;
- relatorio de bosses agora considera fases 1 a 5.

## Pendencias de fidelidade fina

- portar a profecia falsificavel como estrutura propria;
- portar todos os detalhes de `renderizar_vfx_umbra()` que ainda dependem de Pygame;
- substituir formas procedurais por sprites especificos onde houver asset dedicado;
- importar/normalizar `saves/memoria_umbra_dqn.pt` para pesos mobile se quisermos converter Q-values reais para JSON;
- criar telemetria de treino desktop -> export mobile;
- adicionar smoke visual com screenshot para a composição da fase 5.
