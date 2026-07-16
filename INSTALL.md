# Instalação do Godot Agent Kit

Copie o conteúdo desta pasta para a raiz do projeto Godot, no mesmo nível de `project.godot`.

## Windows

1. Coloque o executável da Godot no `PATH` ou defina `GODOT_BIN`:

```powershell
$env:GODOT_BIN = "C:\\caminho\\Godot_v4.x-stable_win64.exe"
```

2. Execute:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\validate_godot.ps1 -Deep
```

3. Para testar uma cena específica:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\validate_godot.ps1 -Scene "res://cenas/minha_cena.tscn"
```

## Linux/macOS

```bash
chmod +x tools/validate_godot.sh
GODOT_BIN=/caminho/para/godot bash tools/validate_godot.sh --deep
```

## Gemini CLI

Os comandos do projeto ficam em `.gemini/commands/`:

- `/godot-implement <tarefa>`
- `/godot-verify <contexto opcional>`

Depois de adicionar ou editar comandos, use `/commands reload` se a sua instalação do Gemini CLI exigir recarregamento.

## Codex e Antigravity

- `AGENTS.md` contém as regras permanentes.
- `.agents/skills/godot-engineer/SKILL.md` orienta implementação Godot.
- `.agents/skills/godot-test-repair/SKILL.md` impõe o ciclo testar → corrigir → testar novamente.
- `GEMINI.md` reforça as mesmas obrigações para Gemini/Antigravity.

## Observação importante

O smoke test inicia a cena principal ou a cena escolhida e roda uma quantidade definida de frames. Isso detecta erros de inicialização e dos caminhos executados nesse período, mas não substitui testes focados para interações específicas. Para uma mecânica alterada, o agente deve também executar ou criar um caminho determinístico que exercite essa mecânica.
