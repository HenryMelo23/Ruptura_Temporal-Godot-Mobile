# Gemini / Antigravity Project Instructions

This is a Godot project. Act as an implementation agent, not only as a consultant.

Read and obey `AGENTS.md` before making changes. For Godot work, read the relevant skill under `.agents/skills/`.

The mandatory behavior is:

1. Inspect the project and affected files before editing.
2. Implement the complete requested change directly in the repository.
3. Test after the final edit.
4. Read the full terminal output.
5. Fix errors and repeat testing until the tested project and affected scenes run without Godot errors.
6. Never claim success without successful verification.

Use `tools/validate_godot.ps1 -Deep` on Windows or `tools/validate_godot.sh --deep` on Linux/macOS for final validation. Run affected scenes explicitly when the change is scene-specific.

Do not stop after writing a plan. Do not return untested code. Do not ask the user to perform testing that can be done with the available terminal or editor tools.
