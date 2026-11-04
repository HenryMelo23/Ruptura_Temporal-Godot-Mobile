# Padrão de terreno das fases definitivas e variantes clássicas EX

Os mundos ilustrados, divididos em chunks e com área 5×, são os mapas definitivos
das fases 1–7. A lógica é compartilhada; cada fase fornece identidade, arte de
terreno, nome e boss por meio do perfil em `RTExperimentalPhaseController`.
Os comandos `FaseEX...` fazem o caminho inverso: abrem como variante de teste o
mapa clássico de 1600×900 que era definitivo antes desta migração.

| Fase definitiva | Atlas expandido | Variante clássica | Boss |
| --- | --- | --- | --- |
| 1 — Ruínas Cósmicas | `phase_ex_terrain_atlas.png` | `FaseEX` | Cronoguejo |
| 2 — Fenda Glacial | `phase_ex2_terrain_atlas.png` | `FaseEX2` | Sentinela Glacial |
| 3 — Catedral e esgoto | `phase_ex3_terrain_atlas.png` | `FaseEX3` | Pai-Rato |
| 4 — Coração do Nexo | `phase_ex4_terrain_atlas.png` | `FaseEX4` | Nexo Anfíbio |
| 5 — Mente da UMBRA | `phase_ex5_terrain_atlas.png` | `FaseEX5` | UMBRA |
| 6 — Chaga de Âmbar | `phase_ex6_terrain_atlas.png` | `FaseEX6` | Matriarca da Chaga |
| 7 — Cinzas da Ruptura | `phase_ex7_terrain_atlas.png` | `FaseEX7` | Fênix |

Digitar novamente o mesmo comando cancela a seleção; digitar outro troca a
versão clássica armada. A escolha vale somente para a próxima nova partida solo.
A variante EX é one-shot e não persiste. Já a campanha definitiva expandida
mantém rota normal, progresso e partida interrompida, incluindo posição e estado
do altar.

## Regras para uma nova fase

1. Inspecionar o mapa original e manter sua paleta, materiais e identidade.
2. Gerar uma base com 15 regiões distintas mais um altar integrado, sem repetir
   uma única composição simétrica. O altar ocupa o índice 5 em todos os atlas. Se a arte gerada deslocar seu
   centro dentro da região, medir `altar_uv` no perfil para normalizar o desenho
   ao centro da célula; nunca deslocar a interação para compensar visualmente.
3. Reutilizar células de 384 unidades, seleção estável por coordenada, mistura de
   bordas em espaço de mundo e descarte de células fora da câmera. Não duplicar
   o controlador nem criar um renderizador por fase.
4. Usar o mesmo centro de célula para arte, descoberta, interação, avisos e
   chegada do boss. A estrutura permanece após o uso; só a interação encerra.
5. Manter área 5×, distâncias de exploração e limites existentes na campanha. Carregar as
   regras, inimigos, ambiente e boss da fase de origem, sem rebalancear por causa
   da troca de arte. A variante EX preserva o mundo clássico de 1600×900.
6. Conferir com a personagem real em cena: leitura de silhueta, escala do chão,
   densidade de detalhes, emendas e altar, em desktop e paisagem móvel, inclusive
   modo leve. O acabamento é detalhado e ilustrado, compatível com a Geovana, conforme a revisão aprovada da EX7: contornos deliberados, áreas de descanso visual e pouco microcascalho. Não copiar materiais de outra fase para obter esse acabamento.
7. Testar campanha/EX1–EX7, altar único, invocação e entrada do boss na célula,
   retorno ao material clássico, persistência da campanha e bloqueio de
   persistência da variante EX.
8. Manter somente a variante clássica EX exclusiva de solo. A campanha expandida
   deve respeitar os contratos online existentes; registrar impactos não testados
   no backlog e não executar multiplayer enquanto o congelamento estiver ativo.

## Atlas e montagem

Cada fase definitiva usa seu atlas em `assets/sprites/experimental/`. A fase 1
usa `phase_ex_terrain_atlas.png`, uma
imagem opaca dividida logicamente em 4 × 4 regiões. São 15 regiões de terreno
e uma região com o altar já desenhado no chão (índice 5, coluna 1 / linha 1,
contagem começando em zero). As imagens antigas ficam preservadas como referência.

Cada célula ocupa 384 × 384 unidades no mundo. O controlador escolhe variantes
estáveis por coordenada e entrega apenas os retângulos visíveis. A seleção do
terreno está em `terrain_chunks`; a mesma fórmula em `CHUNK_SHADER_CODE` permite
misturar os vizinhos nas bordas. Alterar essa fórmula exige manter os dois lados
coerentes. O atlas não é refeito durante a partida.

## Mover a invocação

O centro da célula é a fonte comum para a arte e a interação:

```gdscript
experimental_boss_altar_pos = (Vector2(coluna, linha) + Vector2(0.5, 0.5)) * 384.0
```

O sorteio atual já escolhe centros de células respeitando margem do mapa e
distância mínima do início. Mover essa posição troca a região antiga por terreno
comum e coloca a região de invocação no novo endereço. Não é necessário mover um
sprite separado. Para mudanças durante uma partida, também se deve reiniciar o
estado de descoberta/progresso e reconstruir os marcos que evitam o altar; o
fluxo de nova partida já faz isso. Não mover durante a chamada/luta do boss.

A estrutura permanece no terreno depois da invocação. A apresentação separada
contém somente os avisos, progresso, brilho de interação e orientação após a
descoberta. Os mapas definitivos são o caminho normal; apenas as variantes
clássicas `FaseEX`–`FaseEX7` continuam indisponíveis em multiplayer.

## Critérios visuais

Na fase 1, preservar pedras claras envelhecidas, solo violeta escuro e fissuras
magenta pontuais. Nas demais, seguir os materiais da própria fase. Evitar simetria, grandes marcas repetidas e brilho uniforme no chão.
As bordas são misturadas em espaço de mundo, sem deslocar a textura com a câmera.
Regiões comuns têm uma pequena margem interna recortada para evitar as faixas
retas de cascalho da imagem; o altar usa sua região completa.

Verificação: `tests/experimental_phase_smoke.gd` cobre geometria e invocação;
`tests/experimental_phase_visual_smoke.gd` captura desktop, paisagem móvel,
altar deslocado e estrutura após uso, e verifica retorno ao material do mapa
clássico. A opção `-- --low` exercita a configuração leve. Capturas locais não
substituem medição de desempenho em Android físico.


## Particularidades da fase definitiva 2

Preservar pedra azul-acinzentada, gelo, neve e cristais cianos da Fenda Glacial.
Evitar clarões contínuos e objetos que pareçam obstáculos altos em um piso sem
colisão. A Sentinela Glacial usa suas regras existentes; na campanha, sua entrada
é ancorada no altar. Na `FaseEX2` clássica ela continua chegando ao centro da arena.

Validação específica: `tests/experimental_phase2_smoke.gd`;
`tests/experimental_phase_visual_smoke.gd -- --ex2` (ou `-- --ex2 --low`).
A opção `--phase2-reference` captura a variante clássica para comparação.

`tests/experimental_terrain_render_smoke.gd` verifica no renderizador a posição
fixa do terreno durante deslocamento de câmera e a correspondência do centro
visual do altar com sua âncora nas seis artes. A âncora ajusta a janela de amostra
sobre o terreno contínuo do atlas; não estica, espelha ou cola o altar.


## Particularidades da fase definitiva 3

A história define uma mistura de catedral com esgoto. Preservar lajes sacras
cinzentas, mosaicos quebrados e metal dourado envelhecido, integrados a grades,
umidade e limo verde discreto. Não separar os temas em dois mapas nem transformar
o chão inteiro em um mandala repetido. Os detalhes de esgoto são rasos e não
sugerem obstáculos altos sem colisão.

O altar do Pai-Rato pertence ao próprio piso. Sua entrada na campanha termina nessa
célula; na `FaseEX3` clássica, continua no centro da arena. Inimigos, atributos e
habilidades permanecem os da fase 3.

Validação específica: `tests/experimental_phase3_smoke.gd`;
`tests/experimental_phase_visual_smoke.gd -- --ex3` (ou `-- --ex3 --low`).
A opção `--phase3-reference` captura a variante clássica para comparação.


## Particularidades da fase definitiva 4

Preservar a identidade do Coração do Nexo: pedra escura violeta/cinza, detalhes
geométricos em ouro envelhecido e fissuras magenta com fragmentos de cristal.
Manter cristais baixos e esparsos, evitando obstruções visuais ou brilho uniforme
que concorram com os ataques. Não trazer os elementos de esgoto da EX3.

O selo de invocação do Nexo Anfíbio está integrado ao piso. Seu emblema deve
mostrar um sapo adulto sem cauda, com patas traseiras dobradas; não reutilizar
a anatomia de rato da fase 3. Na campanha, o alvo da
entrada orbital é a célula do altar, com queda de 560 unidades; na `FaseEX4` clássica,
a chegada mantém o alvo original em 68% da largura e 50% da altura da arena.
O comportamento de combate, inimigos e atributos continuam os da fase 4.

Validação específica: `tests/experimental_phase4_smoke.gd`;
`tests/experimental_phase_visual_smoke.gd -- --ex4` (ou `-- --ex4 --low`).
A opção `--phase4-reference` captura a variante clássica para comparação.


## Particularidades da fase definitiva 6

Direção explícita: pântano, doença e ossos. Não usar as fases 3/4 como inspiração
visual. Predominar lama úmida marrom, turfa, água estagnada verde-oliva escura,
raízes podres, fungos discretos e ossadas parcialmente enterradas. Evitar piso
pavimentado dominante, arquitetura de catedral, grades de esgoto, ouro e cristais.
O âmbar deve aparecer como acento orgânico contido, não como iluminação uniforme.

A célula de invocação é um ninho baixo de raízes e costelas integrado na lama,
com uma casca orgânica âmbar no centro; não é um disco de pedra colado ao piso.
Conservar áreas tranquilas para leitura da personagem e dos ataques.

Na campanha, `RTBoss6StageController.arena_center()` resolve o centro do altar.
Entrada, âncora estacionária nos três estágios, eventos especiais, órgãos e
miasma (desenho e colisão) usam esse mesmo centro. Na `FaseEX6` clássica, ele continua
sendo o centro original da arena. Pústulas, Florada Ácida, Maré de Carnificina,
Fissura Perseguidora, poças, quedas de sanguessuga e Foices Vertebrais ficam
limitadas ao encontro local de 1600x900 ao redor do altar, sem usar toda a área
de 3200x2250 como arena. Não alterar atributos, habilidades ou regras.

Validação: `tests/experimental_phase6_smoke.gd`;
`tests/experimental_phase_visual_smoke.gd -- --ex6` e `--ex6 --low`.
`--phase6-reference` captura a variante clássica. Conferir também os eventos especiais,
o miasma e a permanência da Matriarca no altar após o fim da entrada.


## Particularidades da fase definitiva 7

Direção do usuário: floresta queimada cheia de brasas. As duas artes anteriores
(`assets/maps/calm/phase_7.png` e `assets/sprites/Fase7.png`) foram conferidas e
mostram predominantemente pedra/fissuras, por isso não devem ditar o material
desta variante. A EX7 representa chão florestal carbonizado: terra e cinza,
raízes queimadas, casca de árvore, folhas chamuscadas, madeira caída baixa e
bolsões de brasa vermelha/laranja. Não converter a floresta em templo ou lava.

A clareira da Fênix tem uma marca orgânica de penas queimadas/brasas integrada
à cinza. Manter o acabamento ilustrado do jogo e conferir Geovana real em cena:
a personagem deve pertencer ao ambiente, com escala, contraste e densidade
compatíveis, sem aparência de fotografia de fundo ou personagem colada.
Os marcos decorativos ficam na própria arte, como na EX6.

A Fênix chega ao centro da célula e mantém voo, ataques e renascimento. Usar
`boss_encounter_rect` para os limites de voo, mergulho e projéteis locais e para
os quadrantes do fogo (mesma origem/tamanho no desenho e dano). A área de combate
mantém as dimensões normais dentro do mundo 5×. Na `FaseEX7` clássica, preservar o
alvo de entrada 72 unidades acima do centro e os limites originais.

Validação: `tests/experimental_phase7_smoke.gd`, `tests/boss7_fenix_smoke.gd`,
`tests/boss7_fire_progression_smoke.gd` e visual `--ex7` / `--ex7 --low`.
`--phase7-reference` captura a variante clássica para comparação com Geovana.

## Conjunto ilustrado das fases definitivas 1–5 (2026-11-03)

As quatro primeiras artes foram repintadas e a EX5 foi acrescentada. A personagem
real permanece inalterada. Os marcos geométricos provisórios deixam de ser
sobrepostos: os detalhes pertencem ao piso ilustrado.

| Fase | Identidade que deve permanecer | Detalhe que não pode migrar |
| --- | --- | --- |
| 1 | Pedra antiga clara, solo violeta, fissuras temporais; relógio mecânico | Neve, esgoto e emblemas animais |
| 2 | Pedra azul, gelo, neve, cristais; selo glacial | Brasa e lama |
| 3 | Catedral degradada E esgoto, latão, grades, água suja; rato e cruz | Sapo ou floresta |
| 4 | Pedra violeta escura, ouro e cristais magenta; sapo adulto SEM cauda | Cauda de rato, cruz e grades de esgoto |
| 5 | Pedra cinza, circuitos verde-azulados; selo dimensional abstrato | Cérebro literal ou emblema de outro boss |

Na fase 5 as dimensões usam os terrenos definitivos correspondentes; Rastro usa
o piso de esgoto da fase 3. O selo da UMBRA permanece na célula reservada através
de amostragem do atlas EX5 no mesmo shader de chão, sem sprite sobreposto.
A transmutação definitiva troca o terreno em células e mantém as partículas;
o reveal antigo que esticava a imagem inteira permanece apenas na `FaseEX5` clássica.
Entrada, vórtice e origem visual/de dano do laser usam o centro do encontro.
As políticas de IA, tempos, dano e modelo da UMBRA não foram alterados.

Artes geradas pela ferramenta integrada de imagens. Prompts finais: repintar os
atlas EX–EX4 preservando paleta, símbolos e centro do altar, reduzir microgrão
em 65–70%, usar áreas pintadas mais calmas e contornos compatíveis com Geovana;
na EX4, quebrar lajes retangulares em pedras irregulares sem alterar o sapo sem
cauda. Para EX5, criar atlas 4×4 de pedra/circuitos verde-azulados, 15 regiões
comuns e um selo geométrico no índice 5, usando o mapa original como referência.

Galeria local de capturas reais: `.agent_logs/phase_ex_collection/index.html`.
