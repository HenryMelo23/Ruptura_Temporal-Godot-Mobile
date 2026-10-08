# Ruptura Temporal Mobile - Godot

Esta pasta e uma nova rota mobile, separada do Pygame.

## Objetivo

Portar o jogo por camadas para Godot, com exportacao Android nativa:

- menu funcional;
- fase 1 jogavel;
- controles touch;
- Henry com sprites reais;
- inimigos simples;
- boss 1 basico;
- depois portar loja, manifestacoes, passivas e balanceamento.

## Como abrir

1. Instale Godot 4.x.
2. Abra a pasta local deste repositorio.
3. Rode a cena principal `scenes/Main.tscn`.

## Como exportar Android

1. No Godot, abra `Editor > Manage Export Templates` e instale os templates.
2. Para builds locais de teste, use `build_apk.ps1`.
3. Para release, nao gere outro keystore. Use o mesmo keystore, alias e certificado ja publicados, configurados apenas fora do Git:
   - `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`
   - `GODOT_ANDROID_KEYSTORE_RELEASE_USER`
   - `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`
4. Como alternativa local, crie `android_signing.local.ps1` na raiz do projeto com essas mesmas variaveis de ambiente. Esse arquivo e ignorado pelo Git e nao deve ser enviado.
5. Se senha ou caminho de keystore ja entrou no historico da branch, trate como comprometido: altere a senha do mesmo keystore/chave sem trocar o certificado, atualize a configuracao local, e reescreva ou emende o commit antes do merge.

## Estrategia

Nao vamos tentar converter Python automaticamente. Vamos reaproveitar:

- sprites;
- nomes e identidade visual;
- regras de balanceamento;
- comportamento das manifestacoes.

A implementacao mobile passa a ser nativa Godot, evitando a barreira Pygame/Android.
