# Release 2.0.54 — validação

Versão/código: **2.0.54 / 25400**. Publicação: concluída.

## Artefatos

| Plataforma | Arquivo | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| Windows x64 | `Ruptura_Temporal_2.0.54.exe` | 1013071312 | `2f97b715b18bd0e85905f03921e3f7a2367b5ba1feaf61bafce69ae2e78e8ba3` |
| Linux x64 | `Ruptura_Temporal_2.0.54.x86_64` | 977248512 | `64e1e6d18a9f4ce15fa1d15699e79b83294e6d5e2c4e90dabe90a547907527ad` |
| Android arm64 | `ruptura_temporal_mobile_2.0.54.apk` | 927093041 | `48511ae9aae18eae03c753ac11a86e8f392717b0c6d5b18b25ff6dc91bf93443` |

APK `org.rupturatemporal.godotmobile`: assinatura verificada e certificado igual ao APK 2.0.53. Credenciais não foram incluídas neste documento nem nos artefatos de publicação.

## Validações concluídas

- Exportações release das três plataformas; formatos PE/ELF, versão Android e assinatura conferidos.
- `tools/validate_godot.sh --deep`: passou. Permanece aviso de seis ObjectDB no encerramento do smoke geral, sem erro de parsing.
- ENet local: lobby/pronto, espectador e loja; três jogadores iniciaram a partida e receberam vitória autoritativa.
- Bateria estendida: autoridade do combate, transporte bidirecional de habilidades/projéteis e ciclo de vida da sala passaram.
- Boss 4: sincronização multiplayer passou. Henry Barométrico e Colosso: smokes focados passaram.
- Linux exportado: inicialização headless até o primeiro frame lógico do menu, sem erro de runtime.
- APK release instalado no emulador com sucesso; abertura gráfica não validada devido a erros de apresentação Vulkan/SwiftShader no emulador.

## Correções restritas aos testes

- Cápsula de Barganha: referências antigas de texturas substituídas pelos caminhos atuais.
- Integração multiplayer: janela de espera da vitória compatível com os sete segundos de observação do host; Henry valida sua tela de vitória, Geovana valida evolução de espectro.
- Matriz de manifestações: cliente de teste seleciona explicitamente Geovana; o segundo jogador do lobby agora é Henry por contrato.

Nenhuma alteração de gameplay foi feita para satisfazer esses testes.

## Limites

Não houve execução nativa em Windows, teste em celular físico ou partida prolongada sob perda artificial de pacotes. Os testes não certificam ausência absoluta de travamentos. A captura gráfica automatizada do Linux exportado não concluiu; o teste headless não equivale a QA visual. O orçamento de arquitetura continua acima do baseline preexistente em múltiplos owners; baseline não foi alterado nesta publicação.

## Servidor e retenção

O runtime remoto foi sincronizado com os arquivos do payload e reiniciado em 2.0.54. Perfis, ranking e dados persistentes foram preservados. A bateria pública de lobby/pronto, espectador e autoridade de combate passou; ping observado no combate: 31–32 ms. Três jogadores entraram e iniciaram a partida no servidor público. O soak público de 60 segundos manteve os três conectados; houve picos transitórios de 383–433 ms durante o envio simultâneo dos artefatos, sem desconexão. Os três downloads responderam com HTTP 206, tamanho total correto e suporte a retomada.

O servidor mantém somente 2.0.53 e 2.0.54. Os três artefatos 2.0.52 foram removidos definitivamente após a validação da nova versão.

Logs locais: `.agent_logs/release_2.0.54_*`. Alterações preexistentes do worktree preservadas; sem commit/push automático.
