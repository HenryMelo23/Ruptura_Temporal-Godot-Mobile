# Ruptura Temporal 2.0.43

Versão: `2.0.43`; código Android/Windows: `24300`.

## Instalação Android e troca de assinatura

Esta distribuição inicia uma nova identidade de assinatura Android, autorizada
após a perda de acesso à senha da chave anterior. O pacote continua sendo
`org.rupturatemporal.godotmobile`.

O Android não permite instalar este APK sobre uma instalação assinada pela chave
antiga, inclusive por meio do atualizador interno. Baixe o APK fora da pasta de
dados do aplicativo, preserve os meios de recuperação da sua conta e desinstale a
versão antiga antes de instalar a 2.0.43. A desinstalação pode apagar saves e outros
dados locais; a recuperação depende do que já estiver sincronizado e da identidade
recuperável do jogador. Não há migração automática dos dados locais nesta release.

O aviso deve constar nas notas do manifest Android e a atualização não deve ser
marcada como obrigatória. As próximas versões devem usar esta mesma nova chave
para permitir atualização sobre a 2.0.43.

Certificado de assinatura Android 2.0.43, SHA-256:

```text
fe5473dd19240e5fae3deb63f7a632482d69a4bfda3fcb76eed10eecc954bf4b
```

A chave privada e sua senha ficam fora do repositório. A configuração
`android_signing.local.ps1` é ignorada pelo Git. O responsável pela publicação deve
manter uma cópia privada da chave, alias e senha para futuras releases.

## Downloads públicos

- [APK Android 2.0.43](http://72.61.217.238:8090/updates/android/download/ruptura_temporal_mobile_2.0.43.apk)
- [EXE Windows 2.0.43](http://72.61.217.238:8090/updates/windows/download/Ruptura_Temporal_2.0.43.exe)

Os manifests em `server/updates/android/latest.json` e
`server/updates/windows/latest.json` registram tamanho e SHA-256 dos artefatos
publicados. O hash do certificado acima identifica a chave de assinatura, não o
conteúdo do APK.
