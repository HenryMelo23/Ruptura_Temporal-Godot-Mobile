# Disparo direcional de Geovana

Referências de identidade: `../../Geo1.png`, `../../Geo2.png`; vista traseira: `../../Geo1-up.png`. Os originais permanecem intactos.

Geração: ferramenta integrada de imagens. A prancha fonte fica em `source_magenta.png`. A primeira tentativa desenhou um fundo quadriculado; a revisão final pediu fundo magenta uniforme para permitir separação técnica do personagem.

Especificação enviada ao gerador: preservar a personagem dos dois frames de repouso, cabelo castanho e franja, óculos ciano/preto, jaleco branco aberto, camisa ciano listrada, saia azul-marinho e sapatos marrons. Prancha de 1536 × 1024, seis colunas (sul, norte, nordeste, noroeste, sudoeste, sudeste), duas linhas (extensão do disparo, recuo). Mesmo tamanho de cabeça e corpo, pés fixos, pequenos movimentos de braço, cabelo e jaleco. Energia ciano discreta na mão. Sem arma nova, texto, moldura ou cenário. Na revisão final, sul aponta verticalmente para baixo e norte verticalmente para cima; o fundo deve ser magenta puro.

Preparação autorizada: `tools/prepare_directional_fire.py` separa o fundo magenta por cor, associa os componentes de cada personagem e alinha os pés em uma tela transparente de 256 × 430. Os valores RGB dos pixels mantidos não são repintados ou reamostrados. A imagem fonte permite reproduzir os recortes. O corpo mantém aproximadamente 80 pixels de altura no jogo; a área adicional comporta a mão elevada.

Integração: dois frames por direção, 90 ms por frame, com retorno ao repouso após 180 ms. O disparo usa a direção registrada na emissão. Movimento, dano, congelamento e habilidades especiais mantêm suas prioridades. Os índices de rede 0/1 continuam correspondendo ao disparo horizontal existente; os índices 2–13 representam as seis novas direções na ordem acima.

Validação reproduzível: `tests/player_attack_animation_movement_smoke.gd` e `tests/player_directional_fire_visual_smoke.gd`. Capturas de comparação com o repouso e das seis direções nas duas resoluções ficam em `.agent_logs/player_fire/`.
