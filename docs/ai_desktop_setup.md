# AI Desktop Setup

Depois de puxar este branch no desktop fixo, rode no PowerShell dentro do repo:

```powershell
git fetch origin
git checkout codex/online-stabilization
git pull
powershell -ExecutionPolicy Bypass -File .\tools\setup_codex_desktop_ai.ps1 -ConfigureCodex
```

O script:

- verifica/instala `uv`;
- adiciona o MCP `godot-ai` no `~\.codex\config.toml`;
- mantém o bloco idempotente, sem duplicar a configuração;
- aponta o Codex para `http://127.0.0.1:8000/mcp`.

Também estão versionados:

- `addons/godot_ai/`, habilitado em `project.godot`;
- `AGENTS.md`;
- as skills locais da Ruptura em `.agents/skills/`;
- os scripts de validação existentes do projeto.

Depois do setup, abra o projeto no Godot 4.7+ e reinicie o Codex Desktop. Para validar o ambiente:

```powershell
$env:GODOT_BIN="C:\caminho\para\Godot_v4.7-stable_win64_console.exe"
powershell -ExecutionPolicy Bypass -File .\tools\validate_godot.ps1 -Deep
```
