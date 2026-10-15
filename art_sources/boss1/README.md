# Cronoguejo — atlas-fonte do rework

Os três PNGs desta pasta são os atlas-fonte aprovados do Boss 1. A pasta tem
`.gdignore` para que esses arquivos de produção não sejam importados nem
empacotados no APK/EXE.

- `boss1_motion_atlas_source.png`: idle, locomoção, salto, giro e reação.
- `boss1_combat_atlas_source.png`: bolhas, Pinças em Tenaz, absorção e morte.
- `boss1_ability_atlas_source.png`: areia, maré, chuva de bolhas e rebobinamento.

Cada fonte possui grade 4×4. Os frames usados pelo jogo são normalizados para
257×239 px, com transparência e apoio inferior comum, em
`assets/sprites/boss1/`.

Paleta funcional: roxo para a carapaça cósmica, ciano para tempo/pressão e
âmbar para areia/impacto. Dano e hitboxes continuam controlados pelo runtime;
os sprites apenas apresentam o estado real.
