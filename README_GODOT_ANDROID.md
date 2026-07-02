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
2. Abra a pasta `C:\Users\luish\Documents\GitHub\Ruptura_Temporal-Godot-Mobile`.
3. Rode a cena principal `scenes/Main.tscn`.

## Como exportar Android

1. No Godot, abra `Editor > Manage Export Templates` e instale os templates.
2. Abra `Project > Export`.
3. Adicione preset `Android`.
4. Configure um keystore debug ou use o debug keystore do Godot.
5. Exporte o APK.

## Estrategia

Nao vamos tentar converter Python automaticamente. Vamos reaproveitar:

- sprites;
- nomes e identidade visual;
- regras de balanceamento;
- comportamento das manifestacoes.

A implementacao mobile passa a ser nativa Godot, evitando a barreira Pygame/Android.
