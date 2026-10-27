# Ranking v2 e observatório da Umbra

## Escopo

Somente servidor/site Ruptura. Não altera gameplay, saves, cartas, APK/EXE/Linux,
assinaturas v1 dos relatórios ou contratos de lobby. `serverScore` mantém o cálculo
legado necessário à validação do cliente; `score` público e `ranking.parts` usam
mérito v2. O HUD de builds antigas pode continuar exibindo a pontuação antiga;
a regra nova é do ranking do site, não uma alteração silenciosa da economia.

## Mérito

- +1.000 por fase da campanha além da primeira (máximo fase 5).
- +2.000 por boss distinto superado.
- Por boss superado com dano recebido registrado:
  `round(500 / (1 + damage / (500 * min(bossPhase, 5))))`.
- +3.000 por vitória.
- Nenhum ponto por tempo, velocidade de kill, abates comuns, dano bruto,
  número de cartas, HP restante ou moedas. Melhor run por perfil; não cumulativo.
- Empates compartilham posição; ID só estabiliza a ordem visual, sem prêmio.

Valores em `ranking_policy.json`. O registro `d21f9000b1e8370f59` foi retirado
da competição por balanceamento legado. Permanece no arquivo auditado e no backup.
Não é banimento do perfil nem do nome Mika; futuras runs participam normalmente.
O ranking é recalculado na leitura, sem apagar/regravar os relatórios históricos.

Relatórios antigos não enviam confirmação de morte de boss. A chegada a um
boss posterior da campanha permite inferir a conclusão de anteriores alcançados;
vitória confirma o boss 5. A inferência é identificada por boss. Fonte de dano
ausente (inclusive truncada pelo top-N do cliente) não concede bônus de no-hit.
Não existe normalização perfeita de versões/builds antigas: menos dano bruto
recebido é uma métrica de resistência, não habilidade pura. A integridade segue
as verificações preexistentes; relatórios client-side não são prova anti-cheat
independente. Esta publicação não muda o protocolo de assinatura.

## Umbra: dados, não promessas

`/leaderboard/umbra` explica observação, encoder/GRU e heads, validação da política,
fallback heurístico, executor autoritativo, três escopos de memória, isolamento
multiplayer e agregação da VPS. O código de inferência não comprova que um modelo
compatível foi carregado em toda run. Agregação semanal não é treino por gradiente.

`/umbra/observatory/latest` fornece resultados públicos agregados. Não exporta
vetores privados completos nem estado oculto da política. Pressão por encontro:
`round(50 * damage/(damage+2500) + 50 * hits/(hits+10))`.
Sem ambos os registros, pressão = null. A média usa somente dados disponíveis.
É um índice descritivo, não chance de vitória ou impossibilidade. Evasões do boss
não entram: falta telemetria de ataques recebidos/tentativas/esquivas confirmadas.
Cobertura de observação usa `umbraKnowledge.totalPercent` com >=30 s de amostra;
não deve ser apresentada como percentual de aprendizado.

Estado em `UMBRA_OBSERVATORY_PATH`, por padrão
`<LEADERBOARD_PATH>.umbra_observatory.json`. Não incluir esse arquivo em deploys.
Inicialização fixa `baselineAt` e IDs históricos, sem sobrescrever marcos existentes.
Deduplicação por ID da run; evidência resumida preservada mesmo quando o ranking
gira seu arquivo limitado. Primeiros 3 encontros medidos por versão/modo formam
referência fixa; exige outros 3 para publicar delta. Nova versão abre outro grupo.
Por jogador, usa a última versão/modo e a mesma regra 3+3. Comparações continuam
observacionais: builds, jogadores, tentativas e balanceamento são confundidores.

Arquivo inválido não é zerado. O painel fica indisponível, com aviso, sem derrubar
lobby, ranking ou atualizador. Escrita em temporário + rename; permissões 0600.
Um processo relay é o escritor. Backups do diretório de dados devem incluir o marco.

## Validação

Executar com Node (compatível com Node 18 da VPS):

```
node ranking_observatory_smoke.js
node leaderboard_smoke.js
node umbra_mind_smoke.js
node room_lifecycle_smoke.js
node player_progress_smoke.js
node streaming_opt_in_smoke.js
node streaming_fps_smoke.js
node streaming_http_mjpeg_smoke.js
```

Smoke específico cobre fórmula, invariância temporal/econômica, limites, dado
ausente vs zero, retirada exata, novos registros do mesmo perfil, baseline após
reinício, deduplicação, retenção independente, coortes incompatíveis e HTML seguro.
Verificação visual: desktop 1440×1000, mobile 390×844 e landscape 844×390.
Não substitui playtest de combate: nenhuma nova telemetria foi implementada no
cliente nesta publicação. Contagem confiável de esquivas e avaliação causal da
adaptação exigem instrumentação e experimentos controlados futuros.

## Publicação e rollback

Backup do código anterior e dos dados do Ruptura antes de ativar. Copiar somente
os módulos do servidor e reiniciar `ruptura-relay` com zero salas ativas.
Não alterar Nginx, outros serviços, builds ou manifests de atualização.
Verificar HTTP público: health, ranking, página Umbra, API, retirada do registro,
fórmulas, mente existente e manifests Android/Windows/Linux inalterados.
Rollback restaura os arquivos de código do backup e reinicia somente o relay.
Não restaurar banco inteiro após novas partidas sem conciliação dos registros.

## Página de downloads

`/leaderboard/downloads` lê os três manifestos oficiais no momento da requisição.
Não fixa versão, tamanho, nome, notas ou hash no HTML; uma nova publicação válida
atualiza os cartões automaticamente. Links relativos conservam o domínio HTTPS
visitado e apontam para os mesmos endpoints usados pelo atualizador. Windows,
Linux e Android mostram instruções próprias, tamanho, data, filename e SHA-256.

Os endpoints continuam verificando que o nome solicitado é exatamente o arquivo
do manifesto atual, enviam `Content-Disposition: attachment`, `Accept-Ranges:
bytes` e suportam GET/HEAD/206. A página não hospeda cópias adicionais, não
altera os binários e não expõe caminhos locais. O domínio e o endereço IP antigo
servem o mesmo arquivo; clientes existentes permanecem compatíveis.
