# Biblia do Catalogo Temporal

Este documento registra a direcao canonica usada pelo Catalogo Temporal do Ruptura Temporal. Ele e interno: serve para manter as entradas coerentes quando novas fases, inimigos, manifestacoes, espectros e cartas forem adicionados.

## Fontes Consultadas

- LIVRO: `C:\Users\luish\Downloads\Ruptura_Temporal_Livro_Inicio.docx`.
- JOGO ATUAL: `scripts/main.gd`, constantes `MANIFESTATIONS`, `AURAS`, `CARDS`, dados de inimigos, bosses e fases.
- GAME BASE: `Game Base/README.md`.
- GAME BASE: documentos mecanicos e narrativos historicos do projeto, usados apenas como referencia interna.

Observacao: o arquivo citado no pedido como `Ruptura_Temporal_Livro_Inicio(1).docx` nao estava no workspace com esse nome exato. Foi localizado e lido o manuscrito equivalente em Downloads, com o nome `Ruptura_Temporal_Livro_Inicio.docx`.

## Principios Do Universo

Ruptura Temporal nasce de uma relacao humana antes de nascer como sistema. O manuscrito estabelece Geovana e Henrique como eixo emocional: curiosidade, afeto, escolhas pequenas, fisica, computacao, mundos alternativos e a ideia de que o tempo prepara encontros. O jogo transforma esse nucleo em acao: cada fase e uma ferida diferente onde a realidade perdeu obediencia.

A Ruptura nao deve ser tratada como simples portal. Ela e fenomeno, cicatriz e forca ativa. Ela reescreve mapa, inimigos, economia, bosses e o proprio corpo de Geovana. O Catalogo Temporal deve soar como um arquivo reconstruido dentro desse caos, misturando leitura de campo, memoria quebrada e notas diretas de Geovana.

## Termos Oficiais

- Geovana: protagonista, pessoa no centro da anomalia e fonte das Manifestacoes estabilizadas.
- Henrique: ausencia afetiva e motor narrativo da travessia.
- D37: assinatura tecnica recorrente da anomalia, usada como coordenada de investigacao.
- Ruptura: fenomeno dimensional que altera regras de tempo, materia, memoria e combate.
- Ressonancia: modo como a Ruptura vibra em Geovana e se torna padrao utilizavel.
- Manifestacao: forma de combate, com disparo, habilidade, ultimate e evolucoes.
- Espectro: postura mental/estrategica que altera a forma da run ser sustentada.
- Cartas: fragmentos compraveis de possibilidade que mudam a run.
- Arauto: prova intermediaria da Ruptura, portador de fragmentos de evolucao.
- Fragmento: concentrado de escolha, risco e memoria recuperada.

## Vozes Do Catalogo

- Registro tecnico: objetivo, usado para classificar materia, perigo e comportamento sem inventar entidades externas.
- Nota de campo de Geovana: pessoal, direta, cansada quando preciso, sem transformar tudo em piada.
- Registro corrompido: usado em UMBRA, Nexo, entidades temporais e fenomenos instaveis.
- Registro externo: usado para culto do Pai-Rato, documentos antigos, faccoes e relatos recuperados.

## Diferencas Conceituais

Ruptura e a ferida. Ressonancia e a vibracao legivel dessa ferida. Manifestacao e o uso corporal dessa vibracao em combate. Espectro e a postura mental que decide quanto dessa pressao Geovana consegue carregar.

## Fases E Dimensoes

- Fase 1 e Fase 6 podem iniciar a run. A Fase 6-1 deve funcionar como espelho organico da primeira fase: novos inimigos, mas progressao e curva inspiradas no Primeiro Rasgo.
- Fase 2 amplia projeteis e controle de arena.
- Fase 3 introduz culto, veneno, ritual e perda de conforto.
- Fase 4 trabalha geometria, gravidade e espaco como ameaca.
- Fase 5 e UMBRA devem preservar a ideia de mente adaptativa, memoria e punicao de habitos.
- Fase 6 e a Chaga: mapa vivo, pustulas, lodarios, enguias, sanguessugas e uma Matriarca que controla o terreno.

## Classificacao De Entradas

- Inimigos de pressao direta: Comum, Pinguim Atirador, Devoto, Lodario.
- Inimigos de ruptura de conforto: Espreitador, Projetador, Enguia do Miasma, Sanguessuga Cronal.
- Suportes e controladores: Curater, Rebobinador, Cristalizado, Briguer Escudeiro, Incensario, Guardiao.
- Inimigos de economia/risco: Larapio.
- Bosses de aprendizagem: Caranguejo Cosmico, Nevasca, Pai-Rato, Nexo da Ruptura, UMBRA, Matriarca da Chaga.
- Nucleos centrais: Ruptura, Geovana, Arauto, Henrique, D37, Manifestacoes, Espectros e Cartas.

## Regras De Escrita

Cada entrada deve responder:

- O que e?
- De onde veio?
- Por que existe?
- Como ameaca ou ajuda Geovana?
- Como funciona em jogo?
- Como se conecta ao universo?

O texto mecanico deve explicar experiencia de combate, nao apenas numero. Numeros exatos podem existir em painel tecnico/debug, mas o Catalogo Temporal principal deve priorizar leitura, prioridade e funcao.

## Origem Das Entradas

- Manifestacoes: JOGO ATUAL + GAME BASE. A fonte mecanica real continua sendo `MANIFESTATIONS`.
- Espectros: JOGO ATUAL + GAME BASE. A fonte mecanica real continua sendo `AURAS`.
- Cartas: JOGO ATUAL + GAME BASE. A fonte mecanica real continua sendo `CARDS`.
- Inimigos da fase 1 a 4: JOGO ATUAL + documento `mecanicas-inimigos-fases.md`.
- Inimigos da fase 6: JOGO ATUAL + expansao canonica baseada na Chaga.
- Bosses: JOGO ATUAL + GAME BASE. UMBRA tambem usa os documentos de IA.
- Geovana e Henrique: LIVRO + JOGO ATUAL.
- D37 e Ruptura: combinacao de LIVRO, GAME BASE e expansao coerente.

## Arquitetura Atual Do Catalogo

O conteudo novo fica em `scripts/catalog/catalog_repository.gd`, com adapters para Manifestacoes, Espectros e Cartas. O `main.gd` continua desenhando a tela por compatibilidade com a cena atual, mas passa a consultar o reposititorio, filtros, busca, validacao e relacoes. O proximo passo natural e mover a apresentacao manual para uma cena `Control` propria quando houver janela maior de QA.

## Criterio Para Novas Entradas

Uma nova entrada so deve entrar no catalogo se possuir:

- id estavel;
- nome exibido;
- resumo;
- identidade;
- historia;
- funcionamento;
- textura ou placeholder seguro;
- relacoes validas;
- origem marcada neste documento ou em outro documento canonico.
