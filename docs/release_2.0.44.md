# Ruptura Temporal 2.0.44

## Notas para jogadores

- Ajustes nas runs longas: mais aceleração da build e recompensas após os 30 minutos, mantendo o começo da partida e o perigo dos combates.
- Corrigida a leitura do cache de progresso após reiniciar o jogo, com compatibilidade com o cache anterior.
- Retomar a run e usar retry preservam os rerolls pagos, bônus de Queimar e progresso das evoluções.
- Melhorias internas nos sistemas de save, fases, pontuação e loja, preservando mapas, efeitos e conteúdo já existentes.
- Revisão dos fluxos multiplayer de confirmação no lobby, escolha de manifestação/espectro, loja, pontuação, revive e transição de fase.
- Android mantém a assinatura da versão 2.0.43: não é necessário desinstalar essa versão para atualizar.

## Registro técnico

- Base reconciliada: `f6b5062`, contendo o backup 2.0.43 e as refatorações locais.
- Versão de runtime/presets/conteúdo: `2.0.44`, código `24400`.
- DQN incompatível continua rejeitada; UMBRA usa o fallback existente enquanto
  não houver um modelo treinado compatível de 23 ações.
- Relay publicado na VPS em `2.0.44`; `/health` confirmou `project.version=2.0.44`.
- Manifestos públicos Android e Windows publicados com `version_code=24400`.
- APK Android: `builds/2.0.44/ruptura_temporal_mobile_2.0.44.apk`
  - Tamanho: `1303385775` bytes
  - SHA-256: `7480c9d82b30d2b7ee67ef8d963c6e68ecbb6e1d558cf78741f131f044d2185f`
  - Certificado igual ao APK 2.0.43 validado antes da publicação.
- Windows EXE: `builds/2.0.44/windows/Ruptura_Temporal_2.0.44.exe`
  - Tamanho: `1387017800` bytes
  - SHA-256: `31899b263020c61ac2fac66ab134a4c180e8ec07117db01f9d09d5f0b734fc7f`
- Hash público confirmado por download integral dos endpoints Android e Windows.
- Multiplayer público validado contra a VPS: confirmação de lobby host/client,
  espectador, manifestação/pronto e partida com autoridade de dano.
- Android foi instalado no emulador como `versionName=2.0.44` e
  `versionCode=24400`. A execução no emulador headless ficou limitada por falha
  de apresentação Vulkan do SwiftShader (`VkResult error 5`), sem crash Java ou
  erro de script no pacote.
- As melhorias novas de apresentação de Queimar, loja e inspeção do deck da
  equipe não são declaradas entregues nesta versão.
