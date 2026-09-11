#!/usr/bin/env python3
"""
Local desktop admin for Ruptura Temporal leaderboard files.

This tool intentionally does not expose an HTTP endpoint. It edits a selected
leaderboard JSON file on this computer, creates backups before saving, and
rebuilds the derived player profiles using the same score/profile rules used by
the Node relay.
"""

from __future__ import annotations

import copy
import csv
import getpass
import hashlib
import hmac
import json
import os
import platform
import secrets
import sys
import tempfile
import time
import urllib.error
import urllib.request
import uuid
from datetime import datetime
from pathlib import Path
from typing import Any

PROJECT_ROOT = Path(__file__).resolve().parent
DEFAULT_LEADERBOARD_PATH = PROJECT_ROOT / "server" / "leaderboard_runs.json"
CONFIG_PATH = PROJECT_ROOT / ".leaderboard_admin.local.json"
BACKUP_DIR = PROJECT_ROOT / ".leaderboard_admin_backups"
APP_TITLE = "Ruptura Leaderboard Admin"
DEFAULT_SERVER_RUNS_URL = os.environ.get("RUPTURA_LEADERBOARD_URL", "http://72.61.217.238:8090/runs")


def safe_number(value: Any, fallback: float = 0.0) -> float:
    try:
        if value is None or value == "":
            return fallback
        number = float(value)
        if number != number:
            return fallback
        return number
    except (TypeError, ValueError):
        return fallback


def profile_key_for_run(run: dict[str, Any]) -> str:
    profile_id = str(run.get("profileId") or "").strip()
    if profile_id:
        return profile_id
    player = str(run.get("player") or "Jogador").strip().lower() or "jogador"
    digest = hashlib.sha1(player.encode("utf-8")).hexdigest()[:16]
    return f"name-{digest}"


def sanitize_player_name(value: Any) -> str:
    name = " ".join(str(value or "").replace("\n", " ").replace("\r", " ").split())
    name = "".join(char for char in name if char.isprintable())
    return name[:32].strip()


def run_matches_player_identity(run: dict[str, Any], selected: dict[str, Any]) -> bool:
    selected_profile_id = str(selected.get("profileId") or "").strip()
    if selected_profile_id:
        return str(run.get("profileId") or "").strip() == selected_profile_id
    selected_profile_key = str(selected.get("profileKey") or profile_key_for_run(selected)).strip()
    run_profile_key = str(run.get("profileKey") or profile_key_for_run(run)).strip()
    if selected_profile_key and run_profile_key == selected_profile_key:
        return True
    selected_player = str(selected.get("player") or "").strip().lower()
    return bool(selected_player) and str(run.get("player") or "").strip().lower() == selected_player


def rename_player_identity(store: dict[str, Any], selected: dict[str, Any], new_name: str) -> int:
    clean_name = sanitize_player_name(new_name)
    if not clean_name:
        raise ValueError("Nome vazio.")
    renamed = 0
    now = datetime.now().isoformat(timespec="seconds")
    for run in store.get("runs", []):
        if not isinstance(run, dict) or not run_matches_player_identity(run, selected):
            continue
        old_name = str(run.get("player") or "")
        if old_name != clean_name:
            history = run.get("adminPreviousPlayers")
            if not isinstance(history, list):
                history = []
            if old_name and old_name not in history:
                history.append(old_name)
            run["adminPreviousPlayers"] = history[-8:]
        run["player"] = clean_name
        run["adminRenamedAt"] = now
        renamed += 1
    return renamed


def compute_stored_run_score(run: dict[str, Any]) -> int:
    stats = run.get("playerStats") if isinstance(run.get("playerStats"), dict) else {}
    score = round(safe_number(run.get("durationSeconds")) * 2)
    score += int(safe_number(run.get("kills"))) * 20
    score += int(safe_number(run.get("phase"))) * 250
    score += round(safe_number(run.get("bossDamage")) / 12)
    score += int(safe_number(run.get("cardsTotal"))) * 15
    score += round(max(0.0, safe_number(stats.get("hp"))) * 0.5)
    if str(run.get("result") or "") == "Vitoria":
        score += 1500
    return max(0, int(score))


def run_sort_key(run: dict[str, Any]) -> tuple[float, float, float]:
    return (
        safe_number(run.get("score")),
        safe_number(run.get("durationSeconds")),
        safe_number(run.get("endedUnix")),
    )


def normalize_store(raw: Any) -> dict[str, Any]:
    if not isinstance(raw, dict):
        raw = {}
    runs = raw.get("auditedRuns")
    if not isinstance(runs, list):
        runs = raw.get("runs")
    profiles = raw.get("profiles")
    store = {
        "runs": [run for run in runs if isinstance(run, dict)] if isinstance(runs, list) else [],
        "profiles": profiles if isinstance(profiles, dict) else {},
    }
    for key, value in raw.items():
        if key not in store:
            store[key] = value
    return store


def rebuild_profiles(store: dict[str, Any]) -> None:
    profiles: dict[str, dict[str, Any]] = {}
    for run in store.get("runs", []):
        if not isinstance(run, dict):
            continue
        key = profile_key_for_run(run)
        existing = profiles.get(key, {})
        canonical_player = str(existing.get("player") or run.get("player") or "Jogador")[:32]
        ended_unix = safe_number(run.get("endedUnix"))
        first_seen = safe_number(existing.get("firstSeen"), ended_unix)
        profiles[key] = {
            "player": canonical_player,
            "profileId": str(run.get("profileId") or existing.get("profileId") or "")[:64],
            "firstSeen": min(first_seen, ended_unix),
            "lastSeen": max(safe_number(existing.get("lastSeen")), ended_unix),
            "bestScore": max(
                safe_number(existing.get("bestScore")),
                0 if run.get("rankEligible") is False else safe_number(run.get("score")),
            ),
            "runs": max(0, int(safe_number(existing.get("runs")))) + 1,
        }
        run["profileKey"] = key
        run["player"] = canonical_player
    store["profiles"] = profiles


def normalize_before_save(store: dict[str, Any]) -> None:
    runs = [run for run in store.get("runs", []) if isinstance(run, dict)]
    runs.sort(key=run_sort_key, reverse=True)
    store["runs"] = runs
    rebuild_profiles(store)


def read_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {"runs": [], "profiles": {}}
    with path.open("r", encoding="utf-8-sig") as handle:
        return normalize_store(json.load(handle))


def find_local_leaderboard_candidates() -> list[Path]:
    candidates: list[Path] = []
    if DEFAULT_LEADERBOARD_PATH.exists() and DEFAULT_LEADERBOARD_PATH.stat().st_size > 2:
        candidates.append(DEFAULT_LEADERBOARD_PATH)
    log_dir = PROJECT_ROOT / ".agent_logs"
    if log_dir.exists():
        candidates.extend(
            sorted(
                (
                    path
                    for path in log_dir.glob("*leaderboard*.json")
                    if path.is_file() and path.stat().st_size > 2 and path.name != "leaderboard_admin_selftest.json"
                ),
                key=lambda path: (path.stat().st_mtime, path.stat().st_size),
                reverse=True,
            )
        )
    unique: list[Path] = []
    seen: set[str] = set()
    for path in candidates:
        key = str(path.resolve()).lower()
        if key not in seen:
            seen.add(key)
            unique.append(path)
    return unique


def fetch_server_snapshot(url: str = DEFAULT_SERVER_RUNS_URL) -> dict[str, Any]:
    request = urllib.request.Request(url, headers={"User-Agent": "RupturaLeaderboardAdmin/1.0"})
    with urllib.request.urlopen(request, timeout=12) as response:
        charset = response.headers.get_content_charset() or "utf-8"
        payload = response.read().decode(charset, errors="replace")
    return normalize_store(json.loads(payload))


def atomic_write_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_name = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".tmp", dir=str(path.parent))
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as handle:
            json.dump(data, handle, ensure_ascii=False, indent=2)
            handle.write("\n")
        os.replace(tmp_name, path)
    finally:
        if os.path.exists(tmp_name):
            os.unlink(tmp_name)


def backup_file(path: Path) -> Path | None:
    if not path.exists():
        return None
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = BACKUP_DIR / f"{path.stem}_{stamp}{path.suffix or '.json'}"
    backup_path.write_bytes(path.read_bytes())
    return backup_path


def machine_payload() -> str:
    parts = [
        platform.node(),
        getpass.getuser(),
        str(uuid.getnode()),
        str(PROJECT_ROOT).lower(),
        platform.system(),
    ]
    return "|".join(parts)


def machine_hash(secret: str) -> str:
    return hashlib.sha256(f"{machine_payload()}|{secret}".encode("utf-8")).hexdigest()


def hash_password(password: str, salt_hex: str) -> str:
    salt = bytes.fromhex(salt_hex)
    return hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, 220_000).hex()


def load_config() -> dict[str, Any] | None:
    if not CONFIG_PATH.exists():
        return None
    try:
        with CONFIG_PATH.open("r", encoding="utf-8") as handle:
            return json.load(handle)
    except (OSError, json.JSONDecodeError):
        return None


def save_config(config: dict[str, Any]) -> None:
    atomic_write_json(CONFIG_PATH, config)


def format_seconds(value: Any) -> str:
    seconds = int(max(0, safe_number(value)))
    return f"{seconds // 60:02d}:{seconds % 60:02d}"


def format_date(run: dict[str, Any]) -> str:
    ended = safe_number(run.get("endedUnix"))
    if ended > 0:
        try:
            return datetime.fromtimestamp(ended).strftime("%Y-%m-%d %H:%M:%S")
        except (OSError, OverflowError, ValueError):
            pass
    return str(run.get("date") or "")


def suspicion_text(run: dict[str, Any]) -> str:
    reasons = run.get("suspicionReasons")
    if isinstance(reasons, list) and reasons:
        return ", ".join(str(reason) for reason in reasons[:6])
    return ""


def run_status(run: dict[str, Any]) -> str:
    if run.get("rankEligible") is False:
        return "RECUSADA"
    if run.get("suspicious") is True:
        return "SUSPEITA"
    return "RANKING"


def is_probably_run_match(run: dict[str, Any], needle: str) -> bool:
    if not needle:
        return True
    fields = [
        run.get("id"),
        run.get("player"),
        run.get("profileId"),
        run.get("profileKey"),
        run.get("version"),
        run.get("platform"),
        run.get("result"),
        run.get("manifestation"),
        run.get("manifestationKey"),
        run.get("spectrum"),
        run.get("spectrumKey"),
        suspicion_text(run),
    ]
    return needle in " ".join(str(field or "").lower() for field in fields)


def create_default_run_id(run: dict[str, Any]) -> str:
    source = json.dumps(run, ensure_ascii=False, sort_keys=True) + str(time.time_ns())
    return hashlib.sha1(source.encode("utf-8")).hexdigest()[:18]


def mark_run_accepted(run: dict[str, Any]) -> None:
    score = int(safe_number(run.get("serverScore"), 0) or safe_number(run.get("score"), 0))
    if score <= 0:
        score = compute_stored_run_score(run)
    run["score"] = max(1, int(score))
    run["serverScore"] = int(run["score"])
    run["rankEligible"] = True
    run["suspicious"] = False
    previous = run.get("suspicionReasons")
    if isinstance(previous, list) and previous:
        run["adminClearedReasons"] = [str(reason) for reason in previous[:12]]
    run["suspicionReasons"] = []
    run["adminDecision"] = "accepted"
    run["adminDecisionAt"] = datetime.now().isoformat(timespec="seconds")


def mark_run_rejected(run: dict[str, Any], reason: str = "admin_rejected") -> None:
    reasons = run.get("suspicionReasons")
    if not isinstance(reasons, list):
        reasons = []
    if reason not in reasons:
        reasons.append(reason)
    if int(safe_number(run.get("serverScore"))) <= 0:
        run["serverScore"] = compute_stored_run_score(run)
    run["score"] = 0
    run["rankEligible"] = False
    run["suspicious"] = True
    run["suspicionReasons"] = reasons
    run["adminDecision"] = "rejected"
    run["adminDecisionAt"] = datetime.now().isoformat(timespec="seconds")


def write_audit_csv(path: Path, runs: list[dict[str, Any]]) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(
            [
                "status",
                "player",
                "score",
                "version",
                "result",
                "duration",
                "phase",
                "kills",
                "boss_damage",
                "cards",
                "ended",
                "id",
                "reasons",
            ]
        )
        for run in runs:
            writer.writerow(
                [
                    run_status(run),
                    run.get("player", ""),
                    int(safe_number(run.get("score"))),
                    run.get("version", ""),
                    run.get("result", ""),
                    format_seconds(run.get("durationSeconds")),
                    int(safe_number(run.get("phase"))),
                    int(safe_number(run.get("kills"))),
                    int(safe_number(run.get("bossDamage"))),
                    int(safe_number(run.get("cardsTotal"))),
                    format_date(run),
                    run.get("id", ""),
                    suspicion_text(run),
                ]
            )


def run_self_test() -> None:
    sample_path = PROJECT_ROOT / ".agent_logs" / "leaderboard_smoke_runs.json"
    if sample_path.exists():
        store = read_json(sample_path)
    else:
        store = {
            "runs": [
                {
                    "id": "selftest",
                    "player": "QA",
                    "profileId": "qa",
                    "version": "self-test",
                    "result": "Derrota",
                    "durationSeconds": 120,
                    "phase": 1,
                    "kills": 10,
                    "bossDamage": 600,
                    "cardsTotal": 2,
                    "playerStats": {"hp": 400},
                    "endedUnix": int(time.time()),
                    "rankEligible": True,
                    "suspicious": False,
                    "suspicionReasons": [],
                }
            ],
            "profiles": {},
        }
    audited_probe = normalize_store({"runs": [], "auditedRuns": [copy.deepcopy(store["runs"][0])], "profiles": {}})
    if len(audited_probe.get("runs", [])) != 1:
        raise RuntimeError("self-test did not prefer auditedRuns")
    before_runs = len(store["runs"])
    if before_runs <= 0:
        raise RuntimeError("self-test sample has no runs")
    run = store["runs"][0]
    run["score"] = compute_stored_run_score(run)
    mark_run_rejected(run, "self_test_reject")
    mark_run_accepted(run)
    renamed = rename_player_identity(store, run, "QA Renomeado")
    if renamed <= 0 or str(run.get("player")) != "QA Renomeado":
        raise RuntimeError("self-test did not rename selected player identity")
    normalize_before_save(store)
    out_path = PROJECT_ROOT / ".agent_logs" / "leaderboard_admin_selftest.json"
    atomic_write_json(out_path, store)
    reloaded = read_json(out_path)
    if len(reloaded.get("runs", [])) != before_runs:
        raise RuntimeError("self-test changed run count")
    if not reloaded.get("profiles"):
        raise RuntimeError("self-test did not rebuild profiles")
    print(f"LEADERBOARD_ADMIN_SELF_TEST_OK runs={before_runs} profiles={len(reloaded['profiles'])}")


def launch_gui() -> None:
    try:
        import tkinter as tk
        from tkinter import filedialog, messagebox, simpledialog, ttk
    except ImportError as exc:
        raise SystemExit(f"Tkinter indisponivel nesta instalacao do Python: {exc}") from exc

    class LeaderboardAdmin(tk.Tk):
        def __init__(self) -> None:
            super().__init__()
            self.withdraw()
            self.title(APP_TITLE)
            self.geometry("1360x820")
            self.minsize(1120, 680)
            self.store: dict[str, Any] = {"runs": [], "profiles": {}}
            self.file_path = DEFAULT_LEADERBOARD_PATH
            self.filtered_runs: list[dict[str, Any]] = []
            self.current_run: dict[str, Any] | None = None
            self.dirty = False
            if not self.authenticate():
                self.destroy()
                return
            self.build_ui(tk, ttk)
            self.load_file(self.file_path, quiet=True)
            self.deiconify()

        def authenticate(self) -> bool:
            config = load_config()
            if config is None:
                password = simpledialog.askstring(APP_TITLE, "Crie a senha local deste painel:", show="*", parent=self)
                if not password:
                    return False
                confirm = simpledialog.askstring(APP_TITLE, "Confirme a senha local:", show="*", parent=self)
                if password != confirm:
                    messagebox.showerror(APP_TITLE, "As senhas nao conferem.")
                    return False
                secret = secrets.token_hex(32)
                salt = secrets.token_hex(16)
                config = {
                    "createdAt": datetime.now().isoformat(timespec="seconds"),
                    "machineHash": machine_hash(secret),
                    "adminSecret": secret,
                    "passwordSalt": salt,
                    "passwordHash": hash_password(password, salt),
                }
                save_config(config)
                return True
            secret = str(config.get("adminSecret") or "")
            if not secret or not hmac.compare_digest(str(config.get("machineHash") or ""), machine_hash(secret)):
                messagebox.showerror(
                    APP_TITLE,
                    "Este painel esta bloqueado para outra maquina, usuario ou pasta de projeto.",
                )
                return False
            password = simpledialog.askstring(APP_TITLE, "Senha local do painel:", show="*", parent=self)
            if not password:
                return False
            expected = str(config.get("passwordHash") or "")
            actual = hash_password(password, str(config.get("passwordSalt") or ""))
            if not hmac.compare_digest(expected, actual):
                messagebox.showerror(APP_TITLE, "Senha incorreta.")
                return False
            return True

        def build_ui(self, tk_mod: Any, ttk_mod: Any) -> None:
            self.style = ttk_mod.Style(self)
            try:
                self.style.theme_use("clam")
            except tk_mod.TclError:
                pass
            self.configure(bg="#071017")
            self.status_var = tk_mod.StringVar(value="Pronto")
            self.search_var = tk_mod.StringVar()
            self.filter_var = tk_mod.StringVar(value="Todos")
            self.path_var = tk_mod.StringVar(value=str(self.file_path))

            top = ttk_mod.Frame(self, padding=10)
            top.pack(fill="x")
            ttk_mod.Label(top, text="Arquivo:").pack(side="left")
            ttk_mod.Entry(top, textvariable=self.path_var, width=92).pack(side="left", padx=6, fill="x", expand=True)
            ttk_mod.Button(top, text="Abrir", command=self.choose_file).pack(side="left", padx=3)
            ttk_mod.Button(top, text="Baixar servidor", command=self.import_from_server).pack(side="left", padx=3)
            ttk_mod.Button(top, text="Recarregar", command=self.reload_file).pack(side="left", padx=3)
            ttk_mod.Button(top, text="Salvar", command=self.save_file).pack(side="left", padx=3)
            ttk_mod.Button(top, text="Salvar como", command=self.save_as).pack(side="left", padx=3)

            filters = ttk_mod.Frame(self, padding=(10, 0, 10, 10))
            filters.pack(fill="x")
            ttk_mod.Label(filters, text="Busca:").pack(side="left")
            search = ttk_mod.Entry(filters, textvariable=self.search_var, width=36)
            search.pack(side="left", padx=6)
            search.bind("<KeyRelease>", lambda _event: self.refresh_table())
            ttk_mod.Label(filters, text="Filtro:").pack(side="left", padx=(12, 0))
            combo = ttk_mod.Combobox(
                filters,
                textvariable=self.filter_var,
                values=("Todos", "Ranking", "Recusadas", "Suspeitas"),
                state="readonly",
                width=12,
            )
            combo.pack(side="left", padx=6)
            combo.bind("<<ComboboxSelected>>", lambda _event: self.refresh_table())
            ttk_mod.Button(filters, text="Exportar CSV", command=self.export_csv).pack(side="right", padx=3)
            ttk_mod.Button(filters, text="Backup agora", command=self.backup_now).pack(side="right", padx=3)

            body = ttk_mod.PanedWindow(self, orient="horizontal")
            body.pack(fill="both", expand=True, padx=10, pady=(0, 10))

            left = ttk_mod.Frame(body)
            body.add(left, weight=3)
            columns = (
                "status",
                "score",
                "player",
                "version",
                "result",
                "duration",
                "phase",
                "kills",
                "boss",
                "cards",
                "ended",
            )
            self.tree = ttk_mod.Treeview(left, columns=columns, show="headings", selectmode="browse")
            headings = {
                "status": ("Status", 92),
                "score": ("Score", 90),
                "player": ("Player", 150),
                "version": ("Versao", 90),
                "result": ("Resultado", 95),
                "duration": ("Tempo", 75),
                "phase": ("Fase", 55),
                "kills": ("Abates", 70),
                "boss": ("Dano boss", 92),
                "cards": ("Cartas", 65),
                "ended": ("Data/hora", 150),
            }
            for column, (label, width) in headings.items():
                self.tree.heading(column, text=label)
                self.tree.column(column, width=width, minwidth=45, anchor="w")
            self.tree.pack(side="left", fill="both", expand=True)
            self.tree.bind("<<TreeviewSelect>>", self.on_select)
            scroll = ttk_mod.Scrollbar(left, orient="vertical", command=self.tree.yview)
            scroll.pack(side="right", fill="y")
            self.tree.configure(yscrollcommand=scroll.set)

            right = ttk_mod.Frame(body)
            body.add(right, weight=2)
            actions = ttk_mod.Frame(right)
            actions.pack(fill="x", pady=(0, 8))
            ttk_mod.Button(actions, text="Aceitar no ranking", command=self.accept_selected).pack(side="left", padx=3)
            ttk_mod.Button(actions, text="Recusar", command=self.reject_selected).pack(side="left", padx=3)
            ttk_mod.Button(actions, text="Recalcular score", command=self.recompute_selected).pack(side="left", padx=3)
            ttk_mod.Button(actions, text="Renomear jogador", command=self.rename_selected_player).pack(side="left", padx=3)
            ttk_mod.Button(actions, text="Remover", command=self.remove_selected).pack(side="left", padx=3)
            ttk_mod.Button(actions, text="Aplicar edicao JSON", command=self.apply_json_edit).pack(side="right", padx=3)

            self.summary = tk_mod.StringVar(value="Selecione uma run.")
            ttk_mod.Label(right, textvariable=self.summary, justify="left").pack(fill="x", pady=(0, 4))
            self.text = tk_mod.Text(right, wrap="none", undo=True, height=30, bg="#071017", fg="#d7faff", insertbackground="#00ffe0")
            self.text.pack(fill="both", expand=True)
            yscroll = ttk_mod.Scrollbar(right, orient="vertical", command=self.text.yview)
            yscroll.place(relx=1.0, rely=0.18, relheight=0.82, anchor="ne")
            self.text.configure(yscrollcommand=yscroll.set)

            status = ttk_mod.Frame(self, padding=(10, 0, 10, 8))
            status.pack(fill="x")
            ttk_mod.Label(status, textvariable=self.status_var).pack(side="left")
            ttk_mod.Label(status, text="Local only | sem endpoint web | backup automatico ao salvar").pack(side="right")

        def load_file(self, path: Path, quiet: bool = False) -> None:
            self.file_path = Path(path)
            self.path_var.set(str(self.file_path))
            try:
                self.store = read_json(self.file_path)
                if not self.store.get("runs") and not self.file_path.exists():
                    candidates = find_local_leaderboard_candidates()
                    if candidates:
                        self.file_path = candidates[0]
                        self.path_var.set(str(self.file_path))
                        self.store = read_json(self.file_path)
                    else:
                        try:
                            self.store = fetch_server_snapshot()
                            self.file_path = PROJECT_ROOT / ".agent_logs" / "leaderboard_live_import.json"
                            self.path_var.set(str(self.file_path))
                            self.set_status("Arquivo local nao existe; dados baixados do servidor. Use Salvar para gravar.")
                        except Exception:
                            pass
                normalize_before_save(self.store)
                self.dirty = False
                self.refresh_table()
                if self.store["runs"]:
                    self.set_status(f"Carregado: {len(self.store['runs'])} runs, {len(self.store['profiles'])} profiles")
                else:
                    self.set_status(
                        "Nenhuma run carregada. O arquivo local padrao nao existe; clique em 'Baixar servidor' "
                        "ou abra um snapshot em .agent_logs."
                    )
            except Exception as exc:  # noqa: BLE001 - GUI must show the exact local error.
                if not quiet:
                    messagebox.showerror(APP_TITLE, f"Falha ao abrir JSON:\n{exc}")
                self.set_status(f"Falha ao abrir: {exc}")

        def choose_file(self) -> None:
            filename = filedialog.askopenfilename(
                title="Abrir leaderboard JSON",
                initialdir=str((self.file_path.parent if self.file_path else PROJECT_ROOT)),
                filetypes=(("JSON", "*.json"), ("Todos", "*.*")),
            )
            if filename:
                self.load_file(Path(filename))

        def reload_file(self) -> None:
            if self.dirty and not messagebox.askyesno(APP_TITLE, "Existem mudancas nao salvas. Recarregar mesmo assim?"):
                return
            self.load_file(Path(self.path_var.get()))

        def import_from_server(self) -> None:
            if self.dirty and not messagebox.askyesno(APP_TITLE, "Existem mudancas nao salvas. Baixar do servidor mesmo assim?"):
                return
            url = simpledialog.askstring(
                APP_TITLE,
                "URL do endpoint de runs:",
                initialvalue=DEFAULT_SERVER_RUNS_URL,
                parent=self,
            )
            if not url:
                return
            try:
                self.store = fetch_server_snapshot(url.strip())
                normalize_before_save(self.store)
                self.file_path = PROJECT_ROOT / ".agent_logs" / "leaderboard_live_import.json"
                self.path_var.set(str(self.file_path))
                self.dirty = True
                self.current_run = None
                self.text.delete("1.0", "end")
                self.summary.set("Dados baixados do servidor. Revise e salve se quiser gravar localmente.")
                self.refresh_table()
                self.set_status(
                    f"Servidor baixado: {len(self.store['runs'])} runs, {len(self.store['profiles'])} profiles. "
                    "Use Salvar para criar o arquivo local."
                )
            except (urllib.error.URLError, json.JSONDecodeError, OSError) as exc:
                self.set_status(f"Falha ao baixar servidor: {exc}")
                messagebox.showerror(APP_TITLE, f"Falha ao baixar servidor:\n{exc}")

        def save_file(self) -> None:
            self.file_path = Path(self.path_var.get())
            try:
                normalize_before_save(self.store)
                backup = backup_file(self.file_path)
                atomic_write_json(self.file_path, self.store)
                self.dirty = False
                self.refresh_table()
                msg = f"Salvo em {self.file_path}"
                if backup:
                    msg += f" | backup: {backup.name}"
                self.set_status(msg)
                messagebox.showinfo(APP_TITLE, msg)
            except Exception as exc:  # noqa: BLE001
                self.set_status(f"Falha ao salvar: {exc}")
                messagebox.showerror(APP_TITLE, f"Falha ao salvar:\n{exc}")

        def save_as(self) -> None:
            filename = filedialog.asksaveasfilename(
                title="Salvar leaderboard JSON",
                initialdir=str(self.file_path.parent),
                initialfile=self.file_path.name,
                defaultextension=".json",
                filetypes=(("JSON", "*.json"), ("Todos", "*.*")),
            )
            if filename:
                self.path_var.set(filename)
                self.save_file()

        def backup_now(self) -> None:
            backup = backup_file(Path(self.path_var.get()))
            if backup:
                self.set_status(f"Backup criado: {backup}")
                messagebox.showinfo(APP_TITLE, f"Backup criado:\n{backup}")
            else:
                messagebox.showwarning(APP_TITLE, "Arquivo ainda nao existe; nada para copiar.")

        def export_csv(self) -> None:
            filename = filedialog.asksaveasfilename(
                title="Exportar CSV de auditoria",
                initialdir=str(PROJECT_ROOT),
                initialfile="leaderboard_audit.csv",
                defaultextension=".csv",
                filetypes=(("CSV", "*.csv"), ("Todos", "*.*")),
            )
            if not filename:
                return
            write_audit_csv(Path(filename), self.store.get("runs", []))
            self.set_status(f"CSV exportado: {filename}")

        def refresh_table(self) -> None:
            for item in self.tree.get_children():
                self.tree.delete(item)
            filter_name = self.filter_var.get()
            needle = self.search_var.get().strip().lower()
            self.filtered_runs = []
            for run in self.store.get("runs", []):
                if filter_name == "Ranking" and run.get("rankEligible") is False:
                    continue
                if filter_name == "Recusadas" and run.get("rankEligible") is not False:
                    continue
                if filter_name == "Suspeitas" and run.get("suspicious") is not True:
                    continue
                if not is_probably_run_match(run, needle):
                    continue
                self.filtered_runs.append(run)
            for index, run in enumerate(self.filtered_runs):
                self.tree.insert(
                    "",
                    "end",
                    iid=str(index),
                    values=(
                        run_status(run),
                        int(safe_number(run.get("score"))),
                        str(run.get("player") or ""),
                        str(run.get("version") or ""),
                        str(run.get("result") or ""),
                        format_seconds(run.get("durationSeconds")),
                        int(safe_number(run.get("phase"))),
                        int(safe_number(run.get("kills"))),
                        int(safe_number(run.get("bossDamage"))),
                        int(safe_number(run.get("cardsTotal"))),
                        format_date(run),
                    ),
                )
            self.set_status(
                f"Exibindo {len(self.filtered_runs)} de {len(self.store.get('runs', []))} runs | "
                f"profiles {len(self.store.get('profiles', {}))}"
            )

        def on_select(self, _event: Any = None) -> None:
            selection = self.tree.selection()
            if not selection:
                return
            index = int(selection[0])
            self.current_run = self.filtered_runs[index]
            self.text.delete("1.0", "end")
            self.text.insert("1.0", json.dumps(self.current_run, ensure_ascii=False, indent=2))
            self.summary.set(
                f"{run_status(self.current_run)} | {self.current_run.get('player', '')} | "
                f"score {int(safe_number(self.current_run.get('score')))} | "
                f"{format_seconds(self.current_run.get('durationSeconds'))} | "
                f"id {self.current_run.get('id', '')}\n"
                f"Razoes: {suspicion_text(self.current_run) or 'nenhuma'}"
            )

        def require_selection(self) -> dict[str, Any] | None:
            if self.current_run is None:
                messagebox.showwarning(APP_TITLE, "Selecione uma run primeiro.")
                return None
            return self.current_run

        def accept_selected(self) -> None:
            run = self.require_selection()
            if not run:
                return
            mark_run_accepted(run)
            self.mark_dirty_and_refresh("Run aceita no ranking.")

        def reject_selected(self) -> None:
            run = self.require_selection()
            if not run:
                return
            reason = simpledialog.askstring(APP_TITLE, "Motivo da recusa:", initialvalue="admin_rejected", parent=self)
            if reason is None:
                return
            mark_run_rejected(run, reason.strip() or "admin_rejected")
            self.mark_dirty_and_refresh("Run recusada.")

        def recompute_selected(self) -> None:
            run = self.require_selection()
            if not run:
                return
            score = compute_stored_run_score(run)
            run["serverScore"] = score
            if run.get("rankEligible") is not False:
                run["score"] = score
            self.mark_dirty_and_refresh(f"Score recalculado: {score}")

        def rename_selected_player(self) -> None:
            run = self.require_selection()
            if not run:
                return
            current = sanitize_player_name(run.get("player") or "Jogador")
            new_name = simpledialog.askstring(
                APP_TITLE,
                "Novo nome para este jogador:",
                initialvalue=current,
                parent=self,
            )
            if new_name is None:
                return
            try:
                count = rename_player_identity(self.store, run, new_name)
                if count <= 0:
                    messagebox.showwarning(APP_TITLE, "Nenhuma run encontrada para essa identidade.")
                    return
                self.current_run = run
                self.mark_dirty_and_refresh(f"Jogador renomeado em {count} run(s).")
            except ValueError as exc:
                messagebox.showerror(APP_TITLE, str(exc))

        def remove_selected(self) -> None:
            run = self.require_selection()
            if not run:
                return
            if not messagebox.askyesno(APP_TITLE, f"Remover definitivamente a run {run.get('id', '')}?"):
                return
            self.store["runs"].remove(run)
            self.current_run = None
            self.text.delete("1.0", "end")
            self.summary.set("Run removida. Salve para confirmar no arquivo.")
            self.mark_dirty_and_refresh("Run removida.")

        def apply_json_edit(self) -> None:
            run = self.require_selection()
            if not run:
                return
            try:
                edited = json.loads(self.text.get("1.0", "end"))
                if not isinstance(edited, dict):
                    raise ValueError("A edicao precisa ser um objeto JSON.")
                if not str(edited.get("id") or "").strip():
                    edited["id"] = create_default_run_id(edited)
                runs = self.store.get("runs", [])
                position = runs.index(run)
                runs[position] = edited
                self.current_run = edited
                self.mark_dirty_and_refresh("Edicao JSON aplicada.")
            except Exception as exc:  # noqa: BLE001
                messagebox.showerror(APP_TITLE, f"JSON invalido:\n{exc}")

        def mark_dirty_and_refresh(self, message: str) -> None:
            normalize_before_save(self.store)
            self.dirty = True
            self.refresh_table()
            self.text.delete("1.0", "end")
            if self.current_run:
                self.text.insert("1.0", json.dumps(self.current_run, ensure_ascii=False, indent=2))
            self.set_status(message + " Lembre de salvar.")

        def set_status(self, message: str) -> None:
            self.status_var.set(message)

    LeaderboardAdmin().mainloop()


def main() -> int:
    if "--self-test" in sys.argv:
        run_self_test()
        return 0
    launch_gui()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

