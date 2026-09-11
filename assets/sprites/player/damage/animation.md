# Dano temporal da personagem

Os quatro frames `Geo_Damage1` a `Geo_Damage4` são derivados diretamente de `Geo1.png` e `Geo2.png`, os dois frames canônicos de repouso. O processo em `tools/create_player_damage_frames.py` não redesenha a personagem: conserva a tela nativa de 165 × 254 e aplica somente separação cromática, deslocamento de faixas horizontais e fragmentos temporais próximos à silhueta.

A sequência é lida em 70 ms por frame pelo ciclo de dano existente. A ordem é: impacto sutil, ruptura RGB, glitch forte e estabilização. O efeito usa ciano, azul, magenta e vermelho em pequenas quantidades para permanecer ligado à identidade temporal do jogo. Os arquivos antigos de dano continuam no repositório para preservar compatibilidade histórica, mas não são mais carregados pelo jogo.
