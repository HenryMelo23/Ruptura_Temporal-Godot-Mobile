#!/usr/bin/env python3
"""Desktop administrator for Ruptura Temporal's VPS ranking and audit blocks."""

from __future__ import annotations

from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import queue
import shlex
import stat
import threading
import time
import tkinter as tk
from tkinter import messagebox, simpledialog, ttk
from typing import Any, Callable
from urllib.error import URLError
from urllib.request import Request, urlopen
import uuid

try:
    import keyring
    from keyring.errors import KeyringError, PasswordDeleteError
except ImportError:  # pragma: no cover - guarded by the UI at runtime
    keyring = None
    KeyringError = RuntimeError
    PasswordDeleteError = RuntimeError

try:
    import paramiko
except ImportError as exc:  # pragma: no cover - only reached on an unprepared desktop
    raise SystemExit("A dependência 'paramiko' não está instalada. Execute: python3 -m pip install --user paramiko") from exc

from ranking_admin_core import (
    ModerationError,
    add_synthetic_run,
    moderate_player_store,
    moderate_run_store,
    moderate_security_ip,
    mutate_copy,
    synthetic_ranking_score,
)


APP_TITLE = "Ruptura Temporal — Administração do Ranking"
DEFAULT_HOST = "72.61.217.238"
DEFAULT_USER = "root"
DEFAULT_MANAGER_PORT = 8090
REMOTE_SERVER_ROOT = "/opt/ruptura/Ruptura_Temporal-Godot-Mobile/server"
REMOTE_RANKING_PATH = f"{REMOTE_SERVER_ROOT}/leaderboard_runs.json"
REMOTE_SECURITY_PATH = f"{REMOTE_SERVER_ROOT}/leaderboard_security.json"
REMOTE_BACKUP_ROOT = f"{REMOTE_SERVER_ROOT}/admin_backups/ranking"
REMOTE_AUDIT_PATH = f"{REMOTE_SERVER_ROOT}/ranking_admin_audit.jsonl"
LOCAL_STATE = Path.home() / ".local" / "state" / "ruptura-ranking-admin"
LOCAL_AUDIT = LOCAL_STATE / "audit.log"
LOCAL_CONFIG = Path.home() / ".config" / "ruptura-ranking-admin" / "settings.json"
KEYRING_SERVICE = "ruptura-ranking-admin-vps"
SYNTHETIC_LABEL = "LOSER LOSER — RUN DE POSER"


def load_settings() -> dict[str, Any]:
    try:
        parsed = json.loads(LOCAL_CONFIG.read_text(encoding="utf-8"))
        return parsed if isinstance(parsed, dict) else {}
    except (OSError, ValueError):
        return {}


def save_settings(settings: dict[str, Any]) -> None:
    """Persist only non-secret preferences. The password lives in the OS keyring."""
    LOCAL_CONFIG.parent.mkdir(parents=True, exist_ok=True)
    temporary = LOCAL_CONFIG.with_suffix(".tmp")
    temporary.write_text(json.dumps(settings, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    temporary.chmod(0o600)
    temporary.replace(LOCAL_CONFIG)
    LOCAL_CONFIG.chmod(0o600)


class CredentialVault:
    def __init__(self) -> None:
        try:
            self.available = keyring is not None and keyring.get_keyring().priority > 0
        except Exception:
            self.available = False

    @staticmethod
    def account(host: str, user: str) -> str:
        return f"{user.strip()}@{host.strip()}"

    def get(self, host: str, user: str) -> str:
        if not self.available or keyring is None:
            return ""
        try:
            return keyring.get_password(KEYRING_SERVICE, self.account(host, user)) or ""
        except KeyringError as exc:
            raise RuntimeError(f"O cofre seguro do sistema não respondeu: {exc}") from exc

    def set(self, host: str, user: str, password: str) -> None:
        if not self.available or keyring is None:
            raise RuntimeError("O cofre seguro do sistema não está disponível.")
        try:
            keyring.set_password(KEYRING_SERVICE, self.account(host, user), password)
        except KeyringError as exc:
            raise RuntimeError(f"Não foi possível guardar a entrada no cofre: {exc}") from exc

    def clear(self, host: str, user: str) -> None:
        if not self.available or keyring is None:
            return
        try:
            keyring.delete_password(KEYRING_SERVICE, self.account(host, user))
        except PasswordDeleteError:
            pass
        except KeyringError as exc:
            raise RuntimeError(f"Não foi possível apagar a entrada do cofre: {exc}") from exc


class ConcurrentRemoteChange(RuntimeError):
    pass


class VpsRankingClient:
    def __init__(self) -> None:
        self.ssh: paramiko.SSHClient | None = None
        self.sftp: paramiko.SFTPClient | None = None
        self.host = DEFAULT_HOST
        self.user = DEFAULT_USER
        self.manager_url = f"http://{DEFAULT_HOST}:{DEFAULT_MANAGER_PORT}"
        self.actor = "Administrador local"
        self._lock = threading.RLock()

    @property
    def connected(self) -> bool:
        transport = self.ssh.get_transport() if self.ssh else None
        return bool(transport and transport.is_active() and self.sftp)

    def connect(self, host: str, user: str, password: str, manager_url: str, actor: str) -> None:
        self.close()
        host = host.strip()
        user = user.strip()
        if not host or not user:
            raise ValueError("Informe o endereço da VPS e o usuário SSH.")
        client = paramiko.SSHClient()
        client.load_system_host_keys()
        client.set_missing_host_key_policy(paramiko.RejectPolicy())
        try:
            client.connect(
                hostname=host,
                username=user,
                password=password or None,
                allow_agent=True,
                look_for_keys=True,
                timeout=12,
                banner_timeout=12,
                auth_timeout=15,
            )
            sftp = client.open_sftp()
        except paramiko.ssh_exception.SSHException as exc:
            client.close()
            message = str(exc)
            if "not found in known_hosts" in message:
                message = f"A chave de {host} ainda não é conhecida. Abra um terminal, conecte uma vez com 'ssh {user}@{host}' e confirme a impressão digital."
            raise ConnectionError(message) from exc
        self.ssh = client
        self.sftp = sftp
        self.host = host
        self.user = user
        self.manager_url = manager_url.strip().rstrip("/") or f"http://{host}:{DEFAULT_MANAGER_PORT}"
        self.actor = actor.strip() or "Administrador local"
        self._exec("test -r %s && test -w %s && test -r %s" % tuple(map(shlex.quote, [REMOTE_RANKING_PATH, REMOTE_RANKING_PATH, REMOTE_SECURITY_PATH])))

    def close(self) -> None:
        if self.sftp:
            try:
                self.sftp.close()
            except Exception:
                pass
        if self.ssh:
            try:
                self.ssh.close()
            except Exception:
                pass
        self.sftp = None
        self.ssh = None

    def _require(self) -> tuple[paramiko.SSHClient, paramiko.SFTPClient]:
        if not self.connected or not self.ssh or not self.sftp:
            raise ConnectionError("Conecte à VPS antes de continuar.")
        return self.ssh, self.sftp

    def _exec(self, command: str) -> str:
        ssh, _ = self._require()
        stdin, stdout, stderr = ssh.exec_command(command, timeout=30)
        del stdin
        code = stdout.channel.recv_exit_status()
        output = stdout.read().decode("utf-8", "replace")
        error = stderr.read().decode("utf-8", "replace")
        if code != 0:
            raise RuntimeError(error.strip() or output.strip() or f"Comando remoto falhou ({code}).")
        return output

    def _read_bytes(self, path: str) -> bytes:
        _, sftp = self._require()
        with sftp.open(path, "rb") as handle:
            return handle.read()

    def read_json(self, path: str) -> dict[str, Any]:
        raw = self._read_bytes(path)
        parsed = json.loads(raw.decode("utf-8"))
        if not isinstance(parsed, dict):
            raise ValueError(f"O arquivo remoto {path} não contém um objeto JSON.")
        return parsed

    def _public_snapshot(self) -> dict[str, Any]:
        request = Request(f"{self.manager_url}/runs", headers={"User-Agent": "Ruptura-Ranking-Admin/1"})
        try:
            with urlopen(request, timeout=15) as response:
                parsed = json.load(response)
            return parsed if isinstance(parsed, dict) else {}
        except (OSError, URLError, ValueError):
            return {}

    def fetch_dashboard(self) -> dict[str, Any]:
        with self._lock:
            ranking = self.read_json(REMOTE_RANKING_PATH)
            security = self.read_json(REMOTE_SECURITY_PATH)
            snapshot = self._public_snapshot()
        raw_by_id = {
            str(run.get("id", "")): run
            for run in ranking.get("runs", [])
            if isinstance(run, dict) and run.get("id")
        }
        projected = snapshot.get("auditedRuns") if isinstance(snapshot.get("auditedRuns"), list) else []
        projected_by_id = {str(run.get("id", "")): run for run in projected if isinstance(run, dict)}
        rows: list[dict[str, Any]] = []
        for run_id, raw in raw_by_id.items():
            row = dict(raw)
            row.update(projected_by_id.get(run_id, {}))
            row["rawRankEligible"] = raw.get("rankEligible", True) is not False
            row["manualModeration"] = raw.get("manualModeration")
            rows.append(row)
        rows.sort(key=lambda run: int(run.get("endedUnix", 0) or 0), reverse=True)
        return {"runs": rows, "security": security, "snapshotOnline": bool(projected)}

    def _append_audit(self, event: dict[str, Any]) -> None:
        _, sftp = self._require()
        line = (json.dumps(event, ensure_ascii=False, separators=(",", ":")) + "\n").encode("utf-8")
        with sftp.open(REMOTE_AUDIT_PATH, "ab") as handle:
            handle.write(line)
        try:
            info = sftp.stat(REMOTE_RANKING_PATH)
            sftp.chown(REMOTE_AUDIT_PATH, info.st_uid, info.st_gid)
            sftp.chmod(REMOTE_AUDIT_PATH, 0o640)
        except OSError:
            pass

    def _atomic_mutate(
        self,
        path: str,
        operation: Callable[[dict[str, Any]], Any],
        audit_action: str,
        audit_target: str,
    ) -> Any:
        with self._lock:
            _, sftp = self._require()
            original = self._read_bytes(path)
            original_hash = hashlib.sha256(original).hexdigest()
            document = json.loads(original.decode("utf-8"))
            if not isinstance(document, dict):
                raise ValueError(f"Formato inválido em {path}.")
            candidate, result = mutate_copy(document, operation)
            encoded = (json.dumps(candidate, ensure_ascii=False, indent=2) + "\n").encode("utf-8")

            # Prevent a report accepted during moderation from being overwritten.
            if hashlib.sha256(self._read_bytes(path)).hexdigest() != original_hash:
                raise ConcurrentRemoteChange("O ranking mudou enquanto a ação era preparada. Atualize a lista e tente novamente.")

            info = sftp.stat(path)
            stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
            backup_dir = f"{REMOTE_BACKUP_ROOT}/{stamp}"
            backup_path = f"{backup_dir}/{Path(path).name}"
            self._exec(f"install -d -m 0700 {shlex.quote(backup_dir)} && cp -a {shlex.quote(path)} {shlex.quote(backup_path)}")

            temporary = f"{path}.admin-{uuid.uuid4().hex}.tmp"
            try:
                with sftp.open(temporary, "wb") as handle:
                    handle.write(encoded)
                    handle.flush()
                sftp.chmod(temporary, stat.S_IMODE(info.st_mode))
                sftp.chown(temporary, info.st_uid, info.st_gid)
                sftp.posix_rename(temporary, path)
            finally:
                try:
                    sftp.remove(temporary)
                except OSError:
                    pass

            if hashlib.sha256(self._read_bytes(path)).hexdigest() != hashlib.sha256(encoded).hexdigest():
                raise RuntimeError("A verificação após a escrita falhou. O backup remoto foi preservado.")
            self._append_audit({
                "at": datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z"),
                "actor": self.actor,
                "action": audit_action,
                "target": audit_target,
                "backup": backup_path,
            })
            return result

    def moderate_run(self, run_id: str, decision: str, reason: str, whole_player: bool = False) -> Any:
        if whole_player:
            operation = lambda store: moderate_player_store(store, run_id, decision, reason, self.actor)
            action = f"player_{decision}"
        else:
            operation = lambda store: moderate_run_store(store, run_id, decision, reason, self.actor)
            action = f"run_{decision}"
        return self._atomic_mutate(REMOTE_RANKING_PATH, operation, action, run_id)

    def moderate_ip(self, ip: str, decision: str, reason: str, duration_ms: int | None = None) -> Any:
        operation = lambda store: moderate_security_ip(store, ip, decision, reason, self.actor, duration_ms=duration_ms)
        return self._atomic_mutate(REMOTE_SECURITY_PATH, operation, f"ip_{decision}", ip)

    def add_synthetic(self, specification: dict[str, Any]) -> dict[str, Any]:
        player = str(specification.get("player", "Jogador"))
        operation = lambda store: add_synthetic_run(store, specification, self.actor)
        return self._atomic_mutate(REMOTE_RANKING_PATH, operation, "synthetic_run_added", player)


def fmt_number(value: Any) -> str:
    try:
        return f"{int(float(value or 0)):,}".replace(",", ".")
    except (TypeError, ValueError):
        return "0"


def fmt_timestamp(value: Any, milliseconds: bool = False) -> str:
    try:
        number = float(value or 0)
        if milliseconds:
            number /= 1000
        if number <= 0:
            return "—"
        return datetime.fromtimestamp(number, timezone.utc).astimezone().strftime("%d/%m/%Y %H:%M")
    except (OSError, OverflowError, TypeError, ValueError):
        return "—"


def run_status(run: dict[str, Any]) -> str:
    if run.get("manualSynthetic"):
        return "PARTIDA FALSA"
    moderation = run.get("manualModeration")
    decision = moderation.get("decision") if isinstance(moderation, dict) else ""
    if decision == "blocked":
        return "BLOQUEADA MANUAL"
    if decision == "released":
        return "LIBERADA MANUAL"
    if run.get("rankingWithdrawn"):
        return "RETIRADA DA COMPETIÇÃO"
    if run.get("rankEligible") is False:
        return "AUDITORIA AUTOMÁTICA"
    return "ATIVA"


def _pretty_lines(title: str, value: Any) -> str:
    if isinstance(value, dict):
        rows = [f"{str(key).replace('_', ' ').title()}: {item}" for key, item in value.items()]
    elif isinstance(value, list):
        rows = [json.dumps(item, ensure_ascii=False) if isinstance(item, (dict, list)) else str(item) for item in value]
    else:
        rows = [str(value or "—")]
    return f"{title}\n{'\n'.join(rows) if rows else '—'}\n"


class RunDetailsWindow(tk.Toplevel):
    """Readable inspection surface for one projected/raw run."""

    def __init__(self, parent: tk.Misc, run: dict[str, Any], colors: dict[str, str]) -> None:
        super().__init__(parent)
        self.run = run
        self.colors = colors
        self.title(f"Detalhes da partida — {run.get('player', 'Jogador')}")
        self.geometry("1180x760")
        self.minsize(920, 620)
        self.configure(bg=colors["bg"])
        self.transient(parent)
        self._build()

    def _build(self) -> None:
        fake = bool(self.run.get("manualSynthetic"))
        header = tk.Frame(self, bg="#55272d" if fake else self.colors["panel"], padx=18, pady=14)
        header.pack(fill="x", padx=14, pady=(14, 8))
        title = self.run.get("player", "Jogador")
        tk.Label(header, text=title, bg=header["bg"], fg="#ffffff", font=("DejaVu Sans", 18, "bold"), anchor="w").pack(fill="x")
        if fake:
            tk.Label(
                header,
                text=f"⚠ PARTIDA FALSA • {SYNTHETIC_LABEL} • NÃO TREINA A UMBRA",
                bg=header["bg"], fg="#ffd0a1", font=("DejaVu Sans", 11, "bold"), anchor="w",
            ).pack(fill="x", pady=(6, 0))
        subtitle = (
            f"{run_status(self.run)}   •   ID {self.run.get('id', '—')}   •   "
            f"versão {self.run.get('version', '—')}   •   {fmt_timestamp(self.run.get('endedUnix'))}"
        )
        tk.Label(header, text=subtitle, bg=header["bg"], fg="#a9c3ca", font=("DejaVu Sans", 10), anchor="w").pack(fill="x", pady=(5, 0))

        metrics = tk.Frame(self, bg=self.colors["bg"])
        metrics.pack(fill="x", padx=14, pady=4)
        ranking = self.run.get("ranking") if isinstance(self.run.get("ranking"), dict) else {}
        values = (
            ("MÉRITO", ranking.get("total", self.run.get("score", 0))),
            ("FASE", self.run.get("phase", 0)),
            ("RESULTADO", self.run.get("result", "—")),
            ("DURAÇÃO", self.run.get("duration", "—")),
            ("ELIMINAÇÕES", self.run.get("kills", 0)),
            ("CARTAS", self.run.get("cardsTotal", len(self.run.get("cards", [])) if isinstance(self.run.get("cards"), list) else 0)),
        )
        for index, (label, value) in enumerate(values):
            card = tk.Frame(metrics, bg=self.colors["panel2"], padx=12, pady=9, highlightbackground=self.colors["line"], highlightthickness=1)
            card.grid(row=0, column=index, sticky="nsew", padx=(0 if index == 0 else 4, 0))
            metrics.grid_columnconfigure(index, weight=1)
            tk.Label(card, text=label, bg=self.colors["panel2"], fg=self.colors["muted"], font=("DejaVu Sans", 8, "bold")).pack(anchor="w")
            shown = fmt_number(value) if isinstance(value, (int, float)) else str(value)
            tk.Label(card, text=shown, bg=self.colors["panel2"], fg=self.colors["cyan"], font=("DejaVu Sans", 14, "bold")).pack(anchor="w")

        notebook = ttk.Notebook(self)
        notebook.pack(fill="both", expand=True, padx=14, pady=(8, 14))
        summary = ttk.Frame(notebook, padding=14)
        combat = ttk.Frame(notebook, padding=14)
        bosses = ttk.Frame(notebook, padding=14)
        audit = ttk.Frame(notebook, padding=14)
        raw = ttk.Frame(notebook, padding=14)
        notebook.add(summary, text="Resumo e pontuação")
        notebook.add(combat, text="Build e combate")
        notebook.add(bosses, text="Bosses e mérito")
        notebook.add(audit, text="Auditoria")
        notebook.add(raw, text="JSON bruto")
        self._build_summary(summary, ranking)
        self._build_combat(combat)
        self._build_bosses(bosses, ranking)
        self._build_audit(audit)
        self._text_tab(raw, json.dumps(self.run, ensure_ascii=False, indent=2, default=str), mono=True)

    def _text_tab(self, parent: tk.Misc, content: str, mono: bool = False) -> None:
        text = tk.Text(
            parent, bg=self.colors["panel"], fg=self.colors["text"], relief="flat", padx=14, pady=12,
            font=(("DejaVu Sans Mono", 10) if mono else ("DejaVu Sans", 11)), wrap="word",
        )
        scroll = ttk.Scrollbar(parent, orient="vertical", command=text.yview)
        text.configure(yscrollcommand=scroll.set)
        text.pack(side="left", fill="both", expand=True)
        scroll.pack(side="right", fill="y")
        text.insert("1.0", content)
        text.configure(state="disabled")

    def _build_summary(self, parent: tk.Misc, ranking: dict[str, Any]) -> None:
        parts = ranking.get("parts") if isinstance(ranking.get("parts"), list) else []
        lines = ["COMO O MÉRITO FOI FORMADO", ""]
        if parts:
            for part in parts:
                if isinstance(part, dict):
                    lines.append(f"{part.get('label', part.get('key', 'Parcela'))}: +{fmt_number(part.get('points'))}")
                    lines.append(f"  Regra: {part.get('rule', '—')}")
        else:
            lines.append("O relay ainda não projetou as parcelas desta entrada.")
        lines.extend((
            "", "ECONOMIA DA RUN",
            f"Pontos obtidos: {fmt_number(self.run.get('pointsEarned', self.run.get('scoreTotal', 0)))}",
            f"Pontos gastos: {fmt_number(self.run.get('pointsSpent', 0))}",
            f"Pontos restantes: {fmt_number(self.run.get('scoreCurrent', 0))}",
            "", "IDENTIDADE",
            f"Manifestação: {self.run.get('manifestation', '—')}",
            f"Espectro: {self.run.get('spectrum', '—')}",
            f"Plataforma / papel: {self.run.get('platform', '—')} / {self.run.get('role', '—')}",
        ))
        self._text_tab(parent, "\n".join(lines))

    def _build_combat(self, parent: tk.Misc) -> None:
        sections = [
            _pretty_lines("DANO", {
                "Dano base inicial": self.run.get("baseDamageStart", 0),
                "Dano base final": self.run.get("baseDamageEnd", 0),
                "Dano em bosses": self.run.get("bossDamage", 0),
                "Dano em inimigos": self.run.get("enemyDamage", 0),
                "Dano recebido": self.run.get("damageTaken", 0),
            }),
            _pretty_lines("ATRIBUTOS DO JOGADOR", self.run.get("playerStats", {})),
            _pretty_lines("CARTAS / BUILD", self.run.get("cards", [])),
            _pretty_lines("AMEAÇAS DE DANO", self.run.get("damageThreats", [])),
        ]
        self._text_tab(parent, "\n".join(sections), mono=True)

    def _build_bosses(self, parent: tk.Misc, ranking: dict[str, Any]) -> None:
        columns = ("phase", "reached", "defeated", "damage", "resilience", "evidence")
        tree = ttk.Treeview(parent, columns=columns, show="headings")
        labels = {"phase": "Fase", "reached": "Encontrado", "defeated": "Eliminado", "damage": "Dano recebido", "resilience": "Mérito", "evidence": "Evidência"}
        widths = {"phase": 65, "reached": 100, "defeated": 100, "damage": 135, "resilience": 100, "evidence": 310}
        for column in columns:
            tree.heading(column, text=labels[column])
            tree.column(column, width=widths[column], stretch=column == "evidence")
        rows = ranking.get("bosses") if isinstance(ranking.get("bosses"), list) else self.run.get("bossDetail", [])
        for boss in rows if isinstance(rows, list) else []:
            if not isinstance(boss, dict):
                continue
            tree.insert("", "end", values=(
                boss.get("phase", "—"), "Sim" if boss.get("reached", True) else "Não",
                "Sim" if boss.get("defeated") else "Não", boss.get("damage", boss.get("damage_taken", "—")),
                fmt_number(boss.get("resilience", 0)), boss.get("defeatEvidence", "registro explícito" if boss.get("defeated") is not None else "—"),
            ))
        scroll = ttk.Scrollbar(parent, orient="vertical", command=tree.yview)
        tree.configure(yscrollcommand=scroll.set)
        tree.pack(side="left", fill="both", expand=True)
        scroll.pack(side="right", fill="y")

    def _build_audit(self, parent: tk.Misc) -> None:
        moderation = self.run.get("manualModeration", {})
        history = self.run.get("manualModerationHistory", [])
        lines = [
            "ELEGIBILIDADE",
            f"No ranking: {'SIM' if self.run.get('rankEligible', True) is not False else 'NÃO'}",
            f"Suspeita automática: {'SIM' if self.run.get('suspicious') else 'NÃO'}",
            f"Motivos: {', '.join(map(str, self.run.get('suspicionReasons', []))) or '—'}",
            f"Pode treinar a Umbra: {'SIM' if self.run.get('umbraTrainingEligible', True) else 'NÃO'}",
            f"Motivos Umbra: {', '.join(map(str, self.run.get('umbraTrainingReasons', []))) or '—'}",
            "", "DECISÃO MANUAL ATIVA", json.dumps(moderation, ensure_ascii=False, indent=2) if moderation else "—",
            "", "HISTÓRICO", json.dumps(history, ensure_ascii=False, indent=2) if history else "—",
        ]
        if self.run.get("manualSynthetic"):
            lines.extend(("", "PARTIDA FALSA", f"Selo: {self.run.get('syntheticLabel', SYNTHETIC_LABEL)}", f"Motivo: {self.run.get('syntheticReason', '—')}", f"Criada por: {self.run.get('syntheticCreatedBy', '—')}"))
        self._text_tab(parent, "\n".join(lines), mono=True)


class SyntheticRunDialog(tk.Toplevel):
    def __init__(self, parent: tk.Misc, colors: dict[str, str]) -> None:
        super().__init__(parent)
        self.result: dict[str, Any] | None = None
        self.colors = colors
        self.title("Adicionar partida falsa ao ranking")
        self.geometry("720x710")
        self.resizable(False, False)
        self.configure(bg=colors["bg"])
        self.transient(parent)
        self.grab_set()
        self._build()

    def _build(self) -> None:
        banner = tk.Frame(self, bg="#55272d", padx=16, pady=13)
        banner.pack(fill="x", padx=14, pady=(14, 10))
        tk.Label(banner, text=SYNTHETIC_LABEL, bg=banner["bg"], fg="#ffd0a1", font=("DejaVu Sans", 17, "bold")).pack(anchor="w")
        tk.Label(banner, text="PARTIDA FALSA • entra no ranking • nunca alimenta o aprendizado da Umbra", bg=banner["bg"], fg="#ffffff", font=("DejaVu Sans", 10, "bold")).pack(anchor="w", pady=(4, 0))

        form = ttk.Frame(self, padding=(18, 8))
        form.pack(fill="both", expand=True)
        self.vars = {
            "player": tk.StringVar(value="Rival de Exibição"), "phase": tk.IntVar(value=4),
            "bossesDefeated": tk.IntVar(value=3), "bossDamageTaken": tk.IntVar(value=250),
            "durationMinutes": tk.IntVar(value=25), "kills": tk.IntVar(value=400),
            "pointsEarned": tk.IntVar(value=9000), "pointsSpent": tk.IntVar(value=7000),
            "cardsTotal": tk.IntVar(value=24), "manifestation": tk.StringVar(value="Elétrica"),
            "spectrum": tk.StringVar(value="Impulsiva"), "reason": tk.StringVar(value="Exibição manual claramente identificada"),
            "victory": tk.BooleanVar(value=False),
        }
        fields = (
            ("Nome base do jogador", "player"), ("Fase alcançada (1–5)", "phase"),
            ("Bosses eliminados", "bossesDefeated"), ("Dano recebido por boss", "bossDamageTaken"),
            ("Duração em minutos", "durationMinutes"), ("Inimigos eliminados", "kills"),
            ("Pontos obtidos na run", "pointsEarned"), ("Pontos gastos", "pointsSpent"),
            ("Total de cartas", "cardsTotal"), ("Manifestação", "manifestation"),
            ("Espectro", "spectrum"), ("Motivo administrativo", "reason"),
        )
        numeric = {"phase", "bossesDefeated", "bossDamageTaken", "durationMinutes", "kills", "pointsEarned", "pointsSpent", "cardsTotal"}
        for index, (label, key) in enumerate(fields):
            row, column = divmod(index, 2)
            cell = ttk.Frame(form)
            cell.grid(row=row, column=column, sticky="ew", padx=(0, 12) if column == 0 else (12, 0), pady=5)
            ttk.Label(cell, text=label, style="Muted.TLabel").pack(anchor="w")
            if key in numeric:
                entry = ttk.Spinbox(cell, textvariable=self.vars[key], from_=0 if key != "phase" else 1, to=1000000 if key != "phase" else 5, width=30)
            else:
                entry = ttk.Entry(cell, textvariable=self.vars[key], width=32)
            entry.pack(fill="x", pady=(3, 0))
            self.vars[key].trace_add("write", lambda *_: self._update_preview())
        form.grid_columnconfigure(0, weight=1)
        form.grid_columnconfigure(1, weight=1)
        ttk.Checkbutton(form, text="Vitória (adiciona bônus de conclusão)", variable=self.vars["victory"], command=self._update_preview).grid(row=6, column=0, columnspan=2, sticky="w", pady=(10, 4))
        self.preview_var = tk.StringVar()
        tk.Label(form, textvariable=self.preview_var, bg=self.colors["panel2"], fg=self.colors["cyan"], padx=14, pady=12, anchor="w", font=("DejaVu Sans", 11, "bold")).grid(row=7, column=0, columnspan=2, sticky="ew", pady=(8, 6))
        ttk.Label(form, text="O nome público receberá automaticamente o selo LOSER LOSER — RUN DE POSER. Um backup será criado antes da inclusão.", style="Muted.TLabel", wraplength=650).grid(row=8, column=0, columnspan=2, sticky="w", pady=7)
        buttons = ttk.Frame(form)
        buttons.grid(row=9, column=0, columnspan=2, sticky="e", pady=(12, 0))
        ttk.Button(buttons, text="Cancelar", command=self.destroy).pack(side="left", padx=5)
        ttk.Button(buttons, text="Adicionar partida falsa", style="Danger.TButton", command=self._submit).pack(side="left", padx=5)
        self._update_preview()

    def _integer(self, key: str) -> int:
        return int(self.vars[key].get())

    def _update_preview(self) -> None:
        try:
            score = synthetic_ranking_score(self._integer("phase"), self._integer("bossesDefeated"), self._integer("bossDamageTaken"), bool(self.vars["victory"].get()))
            self.preview_var.set(f"Prévia do mérito: {fmt_number(score)} pontos • selo falso visível no ranking")
        except (ValueError, tk.TclError):
            self.preview_var.set("Preencha os números para calcular o mérito.")

    def _submit(self) -> None:
        try:
            phase = self._integer("phase")
            bosses = self._integer("bossesDefeated")
            if not 1 <= phase <= 5:
                raise ValueError("A fase precisa estar entre 1 e 5.")
            if not 0 <= bosses <= phase:
                raise ValueError("Bosses eliminados precisa ficar entre zero e a fase alcançada.")
            if not self.vars["reason"].get().strip():
                raise ValueError("Informe o motivo administrativo.")
            self.result = {
                "player": self.vars["player"].get(), "phase": phase, "bossesDefeated": bosses,
                "bossDamageTaken": self._integer("bossDamageTaken"), "victory": bool(self.vars["victory"].get()),
                "durationSeconds": self._integer("durationMinutes") * 60, "kills": self._integer("kills"),
                "pointsEarned": self._integer("pointsEarned"), "pointsSpent": self._integer("pointsSpent"),
                "cardsTotal": self._integer("cardsTotal"), "manifestation": self.vars["manifestation"].get(),
                "spectrum": self.vars["spectrum"].get(), "reason": self.vars["reason"].get(),
            }
        except (ValueError, tk.TclError) as exc:
            messagebox.showerror("Dados inválidos", str(exc), parent=self)
            return
        self.destroy()


class RankingAdminApp(tk.Tk):
    COLORS = {
        "bg": "#080d14",
        "panel": "#101923",
        "panel2": "#152231",
        "line": "#26394b",
        "text": "#eaf7f4",
        "muted": "#8aa3ad",
        "cyan": "#53e8d4",
        "green": "#90ef89",
        "amber": "#f4c86b",
        "red": "#ff6b6b",
    }

    def __init__(self) -> None:
        super().__init__()
        self.title(APP_TITLE)
        self.geometry("1420x820")
        self.minsize(1080, 680)
        self.configure(bg=self.COLORS["bg"])
        self.settings = load_settings()
        self.vault = CredentialVault()
        self.client = VpsRankingClient()
        self.events: queue.Queue[tuple[str, Any]] = queue.Queue()
        self.runs: list[dict[str, Any]] = []
        self.security: dict[str, Any] = {}
        self.run_by_tree_id: dict[str, dict[str, Any]] = {}
        self.ip_by_tree_id: dict[str, str] = {}
        self.busy = False
        self._build_style()
        self._build_header()
        self._build_tabs()
        self._build_status()
        self.protocol("WM_DELETE_WINDOW", self._on_close)
        self.after(100, self._drain_events)

    def _build_style(self) -> None:
        style = ttk.Style(self)
        style.theme_use("clam")
        style.configure(".", background=self.COLORS["bg"], foreground=self.COLORS["text"], fieldbackground=self.COLORS["panel"], font=("DejaVu Sans", 10))
        style.configure("TFrame", background=self.COLORS["bg"])
        style.configure("Panel.TFrame", background=self.COLORS["panel"])
        style.configure("TLabel", background=self.COLORS["bg"], foreground=self.COLORS["text"])
        style.configure("Muted.TLabel", foreground=self.COLORS["muted"])
        style.configure("Title.TLabel", font=("DejaVu Sans", 18, "bold"), foreground=self.COLORS["cyan"])
        style.configure("TEntry", padding=7, fieldbackground=self.COLORS["panel2"], foreground=self.COLORS["text"], insertcolor=self.COLORS["cyan"])
        style.configure("TButton", padding=(10, 7), background=self.COLORS["panel2"], foreground=self.COLORS["text"], bordercolor=self.COLORS["line"])
        style.map("TButton", background=[("active", "#20384a"), ("disabled", self.COLORS["panel"])])
        style.configure("Danger.TButton", foreground="#fff3f3", background="#71353a")
        style.map("Danger.TButton", background=[("active", "#98454b")])
        style.configure("Release.TButton", foreground="#07120e", background=self.COLORS["green"])
        style.map("Release.TButton", background=[("active", "#b5ffae")])
        style.configure("TNotebook", background=self.COLORS["bg"], borderwidth=0)
        style.configure("TNotebook.Tab", padding=(18, 9), background=self.COLORS["panel"], foreground=self.COLORS["muted"])
        style.map("TNotebook.Tab", background=[("selected", self.COLORS["panel2"])], foreground=[("selected", self.COLORS["cyan"])])
        style.configure("Treeview", rowheight=28, background=self.COLORS["panel"], fieldbackground=self.COLORS["panel"], foreground=self.COLORS["text"], bordercolor=self.COLORS["line"])
        style.configure("Treeview.Heading", background=self.COLORS["panel2"], foreground=self.COLORS["cyan"], relief="flat", padding=6)
        style.map("Treeview", background=[("selected", "#1d5a62")], foreground=[("selected", "#ffffff")])
        style.configure("TCombobox", padding=6, fieldbackground=self.COLORS["panel2"], foreground=self.COLORS["text"])

    def _build_header(self) -> None:
        outer = ttk.Frame(self, style="Panel.TFrame", padding=14)
        outer.pack(fill="x", padx=14, pady=(14, 8))
        title = ttk.Frame(outer, style="Panel.TFrame")
        title.pack(fill="x")
        ttk.Label(title, text="RUPTURA // CONTROLE DO RANKING", style="Title.TLabel", background=self.COLORS["panel"]).pack(side="left")
        self.connection_badge = tk.Label(title, text="DESCONECTADO", bg="#4f282d", fg="#ffdadd", padx=12, pady=5, font=("DejaVu Sans", 9, "bold"))
        self.connection_badge.pack(side="right")

        fields = ttk.Frame(outer, style="Panel.TFrame")
        fields.pack(fill="x", pady=(12, 0))
        self.host_var = tk.StringVar(value=str(self.settings.get("host", DEFAULT_HOST)))
        self.user_var = tk.StringVar(value=str(self.settings.get("user", DEFAULT_USER)))
        self.password_var = tk.StringVar()
        self.actor_var = tk.StringVar(value=str(self.settings.get("actor", os.environ.get("USER", "Administrador local"))))
        self.manager_var = tk.StringVar(value=str(self.settings.get("managerUrl", f"http://{DEFAULT_HOST}:{DEFAULT_MANAGER_PORT}")))
        for label, variable, width, secret in (
            ("VPS", self.host_var, 17, False),
            ("Usuário", self.user_var, 10, False),
            ("Senha SSH", self.password_var, 19, True),
            ("Operador", self.actor_var, 18, False),
            ("URL do relay", self.manager_var, 31, False),
        ):
            group = ttk.Frame(fields, style="Panel.TFrame")
            group.pack(side="left", padx=(0, 10))
            ttk.Label(group, text=label, style="Muted.TLabel", background=self.COLORS["panel"]).pack(anchor="w")
            ttk.Entry(group, textvariable=variable, width=width, show="•" if secret else "").pack()
        self.connect_button = ttk.Button(fields, text="Conectar", command=self._toggle_connection)
        self.connect_button.pack(side="left", padx=(4, 6), pady=(17, 0))
        self.refresh_button = ttk.Button(fields, text="Atualizar dados", command=self._refresh, state="disabled")
        self.refresh_button.pack(side="left", pady=(17, 0))

        remembered = bool(self.settings.get("rememberLogin", False)) and self.vault.available
        self.remember_var = tk.BooleanVar(value=remembered)
        memory = ttk.Frame(outer, style="Panel.TFrame")
        memory.pack(fill="x", pady=(10, 0))
        self.remember_check = ttk.Checkbutton(memory, text="Lembrar entrada neste computador", variable=self.remember_var, command=self._remember_changed)
        self.remember_check.pack(side="left")
        ttk.Button(memory, text="Esquecer entrada", command=self._forget_login).pack(side="left", padx=(10, 0))
        self.vault_status_var = tk.StringVar(value=(
            "Senha protegida pelo cofre do GNOME; ela não é salva em arquivo."
            if self.vault.available else
            "Cofre do sistema indisponível: a senha não será lembrada."
        ))
        ttk.Label(memory, textvariable=self.vault_status_var, style="Muted.TLabel", background=self.COLORS["panel"]).pack(side="left", padx=(12, 0))
        if not self.vault.available:
            self.remember_check.configure(state="disabled")

    def _build_tabs(self) -> None:
        self.notebook = ttk.Notebook(self)
        self.notebook.pack(fill="both", expand=True, padx=14, pady=8)
        self.runs_tab = ttk.Frame(self.notebook, padding=12)
        self.security_tab = ttk.Frame(self.notebook, padding=12)
        self.audit_tab = ttk.Frame(self.notebook, padding=12)
        self.notebook.add(self.runs_tab, text="Runs do ranking")
        self.notebook.add(self.security_tab, text="Bloqueios automáticos")
        self.notebook.add(self.audit_tab, text="Histórico desta interface")
        self._build_runs_tab()
        self._build_security_tab()
        self._build_audit_tab()

    def _build_runs_tab(self) -> None:
        controls = ttk.Frame(self.runs_tab)
        controls.pack(fill="x", pady=(0, 10))
        self.search_var = tk.StringVar()
        self.search_var.trace_add("write", lambda *_: self._render_runs())
        self.filter_var = tk.StringVar(value="Todas")
        ttk.Label(controls, text="Buscar jogador, ID, versão ou motivo:").pack(side="left")
        ttk.Entry(controls, textvariable=self.search_var, width=34).pack(side="left", padx=(8, 14))
        ttk.Combobox(controls, textvariable=self.filter_var, values=("Todas", "Ativas", "Partidas falsas", "Auditoria automática", "Bloqueadas manualmente", "Liberadas manualmente", "Retiradas"), state="readonly", width=24).pack(side="left")
        self.filter_var.trace_add("write", lambda *_: self._render_runs())
        self.runs_summary = ttk.Label(controls, text="0 runs", style="Muted.TLabel")
        self.runs_summary.pack(side="right")

        table = ttk.Frame(self.runs_tab)
        columns = ("status", "player", "score", "version", "phase", "result", "date", "id", "reason")
        self.run_tree = ttk.Treeview(table, columns=columns, show="headings", selectmode="browse")
        widths = {"status": 165, "player": 180, "score": 90, "version": 85, "phase": 65, "result": 100, "date": 130, "id": 155, "reason": 300}
        labels = {"status": "Estado", "player": "Jogador", "score": "Mérito", "version": "Versão", "phase": "Fase", "result": "Resultado", "date": "Data", "id": "ID da run", "reason": "Motivo / auditoria"}
        for column in columns:
            self.run_tree.heading(column, text=labels[column])
            self.run_tree.column(column, width=widths[column], minwidth=55, stretch=column in {"player", "reason"})
        self.run_tree.tag_configure("blocked", foreground="#ff8a8a")
        self.run_tree.tag_configure("released", foreground="#9cff98")
        self.run_tree.tag_configure("audit", foreground="#ffd27d")
        self.run_tree.tag_configure("withdrawn", foreground="#b2a6bd")
        self.run_tree.tag_configure("synthetic", foreground="#ffb978")
        scroll = ttk.Scrollbar(table, orient="vertical", command=self.run_tree.yview)
        self.run_tree.configure(yscrollcommand=scroll.set)
        self.run_tree.bind("<Double-1>", lambda _event: self._open_run_details())
        self.run_tree.pack(side="left", fill="both", expand=True)
        scroll.pack(side="left", fill="y")

        actions = ttk.Frame(self.runs_tab)
        actions.pack(side="bottom", fill="x", pady=(10, 0))
        ttk.Button(actions, text="Ver detalhes", command=self._open_run_details).pack(side="left", padx=(0, 6))
        ttk.Button(actions, text="Bloquear esta run", style="Danger.TButton", command=lambda: self._run_action("blocked", False)).pack(side="left", padx=(0, 6))
        ttk.Button(actions, text="Liberar esta run", style="Release.TButton", command=lambda: self._run_action("released", False)).pack(side="left", padx=6)
        ttk.Button(actions, text="Restaurar decisão automática", command=lambda: self._run_action("automatic", False)).pack(side="left", padx=6)
        ttk.Separator(actions, orient="vertical").pack(side="left", fill="y", padx=12)
        ttk.Button(actions, text="Bloquear todas do jogador", style="Danger.TButton", command=lambda: self._run_action("blocked", True)).pack(side="left", padx=6)
        ttk.Button(actions, text="Liberar todas do jogador", style="Release.TButton", command=lambda: self._run_action("released", True)).pack(side="left", padx=6)
        ttk.Button(actions, text="Adicionar partida falsa…", style="Danger.TButton", command=self._add_synthetic).pack(side="right", padx=(6, 0))
        table.pack(fill="both", expand=True)

    def _build_security_tab(self) -> None:
        info = ttk.Label(self.security_tab, text="Bloqueios do detector de fraude. Liberar zera strikes e janela de tentativas; restaurar devolve o estado anterior à intervenção manual.", style="Muted.TLabel")
        info.pack(fill="x", pady=(0, 10))
        table = ttk.Frame(self.security_tab)
        columns = ("status", "ip", "player", "strikes", "until", "last_seen", "reason")
        self.security_tree = ttk.Treeview(table, columns=columns, show="headings", selectmode="browse")
        widths = {"status": 150, "ip": 165, "player": 170, "strikes": 65, "until": 145, "last_seen": 145, "reason": 360}
        labels = {"status": "Estado", "ip": "IP", "player": "Último jogador", "strikes": "Strikes", "until": "Bloqueado até", "last_seen": "Última atividade", "reason": "Motivo"}
        for column in columns:
            self.security_tree.heading(column, text=labels[column])
            self.security_tree.column(column, width=widths[column], stretch=column == "reason")
        self.security_tree.tag_configure("blocked", foreground="#ff8a8a")
        self.security_tree.tag_configure("released", foreground="#9cff98")
        self.security_tree.tag_configure("automatic", foreground="#ffd27d")
        scroll = ttk.Scrollbar(table, orient="vertical", command=self.security_tree.yview)
        self.security_tree.configure(yscrollcommand=scroll.set)
        self.security_tree.pack(side="left", fill="both", expand=True)
        scroll.pack(side="left", fill="y")
        actions = ttk.Frame(self.security_tab)
        actions.pack(side="bottom", fill="x", pady=(10, 0))
        ttk.Button(actions, text="Bloquear IP por 24h", style="Danger.TButton", command=lambda: self._ip_action("blocked", 24 * 60 * 60 * 1000)).pack(side="left", padx=(0, 6))
        ttk.Button(actions, text="Bloquear IP por 7 dias", style="Danger.TButton", command=lambda: self._ip_action("blocked", 7 * 24 * 60 * 60 * 1000)).pack(side="left", padx=6)
        ttk.Button(actions, text="Bloqueio manual contínuo", style="Danger.TButton", command=lambda: self._ip_action("blocked", None)).pack(side="left", padx=6)
        ttk.Button(actions, text="Liberar e zerar strikes", style="Release.TButton", command=lambda: self._ip_action("released", None)).pack(side="left", padx=6)
        ttk.Button(actions, text="Restaurar estado automático", command=lambda: self._ip_action("automatic", None)).pack(side="left", padx=6)
        ttk.Button(actions, text="Bloquear outro IP…", command=self._block_new_ip).pack(side="right")
        table.pack(fill="both", expand=True)

    def _build_audit_tab(self) -> None:
        self.audit_text = tk.Text(self.audit_tab, bg=self.COLORS["panel"], fg=self.COLORS["text"], insertbackground=self.COLORS["cyan"], relief="flat", padx=12, pady=12, font=("DejaVu Sans Mono", 10), state="disabled", wrap="word")
        self.audit_text.pack(fill="both", expand=True)
        self._load_local_audit()

    def _build_status(self) -> None:
        self.status_var = tk.StringVar(value="Conecte à VPS para carregar o ranking.")
        self.status = ttk.Label(self, textvariable=self.status_var, style="Muted.TLabel", anchor="w")
        self.status.pack(fill="x", padx=18, pady=(0, 12))

    def _set_busy(self, busy: bool, message: str | None = None) -> None:
        self.busy = busy
        state = "disabled" if busy else ("normal" if self.client.connected else "disabled")
        self.refresh_button.configure(state=state)
        self.connect_button.configure(state="disabled" if busy else "normal")
        self.configure(cursor="watch" if busy else "")
        if message:
            self.status_var.set(message)

    def _settings_payload(self, remember: bool | None = None) -> dict[str, Any]:
        return {
            "host": self.host_var.get().strip(),
            "user": self.user_var.get().strip(),
            "actor": self.actor_var.get().strip(),
            "managerUrl": self.manager_var.get().strip(),
            "rememberLogin": bool(self.remember_var.get() if remember is None else remember),
        }

    def _remember_changed(self) -> None:
        if self.remember_var.get() and not self.vault.available:
            self.remember_var.set(False)
            messagebox.showwarning("Cofre indisponível", "A senha não será salva fora de um cofre seguro do sistema.", parent=self)
            return
        save_settings(self._settings_payload())
        if self.remember_var.get():
            self.vault_status_var.set("Ao conectar, a entrada será guardada com segurança no cofre do GNOME.")
        else:
            self.vault_status_var.set("A entrada atual não será lembrada em novas sessões.")

    def _forget_login(self) -> None:
        try:
            self.vault.clear(self.host_var.get(), self.user_var.get())
            self.remember_var.set(False)
            self.password_var.set("")
            save_settings(self._settings_payload(False))
            self.vault_status_var.set("Entrada apagada do cofre seguro deste computador.")
        except Exception as exc:
            messagebox.showerror("Não foi possível esquecer", str(exc), parent=self)

    def _worker(self, label: str, task: Callable[[], Any], success: Callable[[Any], None]) -> None:
        if self.busy:
            return
        self._set_busy(True, label)

        def run() -> None:
            try:
                self.events.put(("success", (success, task())))
            except Exception as exc:
                self.events.put(("error", exc))

        threading.Thread(target=run, daemon=True).start()

    def _drain_events(self) -> None:
        try:
            while True:
                kind, payload = self.events.get_nowait()
                self._set_busy(False)
                if kind == "success":
                    callback, result = payload
                    callback(result)
                else:
                    self.status_var.set(f"Falha: {payload}")
                    messagebox.showerror("Ação não concluída", str(payload), parent=self)
        except queue.Empty:
            pass
        self.after(100, self._drain_events)

    def _toggle_connection(self) -> None:
        if self.client.connected:
            self.client.close()
            self.password_var.set("")
            self.connection_badge.configure(text="DESCONECTADO", bg="#4f282d", fg="#ffdadd")
            self.connect_button.configure(text="Conectar")
            self.refresh_button.configure(state="disabled")
            self.status_var.set("Conexão encerrada e senha removida da memória da interface.")
            return

        host = self.host_var.get().strip()
        user = self.user_var.get().strip()
        manager_url = self.manager_var.get().strip()
        actor = self.actor_var.get().strip()
        typed_password = self.password_var.get()
        remember = bool(self.remember_var.get())

        def connect() -> tuple[dict[str, Any], str]:
            password = typed_password
            if not password and remember:
                password = self.vault.get(host, user)
            self.client.connect(host, user, password, manager_url, actor)
            warning = ""
            if remember and password:
                try:
                    self.vault.set(host, user, password)
                except Exception as exc:
                    warning = str(exc)
            return self.client.fetch_dashboard(), warning

        def connected(payload: tuple[dict[str, Any], str]) -> None:
            data, warning = payload
            # Paramiko keeps the authenticated transport; the plaintext password
            # is no longer needed after the session has been established.
            self.password_var.set("")
            save_settings(self._settings_payload(remember and not bool(warning)))
            self.connection_badge.configure(text="VPS CONECTADA", bg="#185447", fg="#b9fff1")
            self.connect_button.configure(text="Desconectar")
            self.refresh_button.configure(state="normal")
            self._accept_dashboard(data)
            if warning:
                self.remember_var.set(False)
                self.vault_status_var.set(f"Conectou, mas a entrada não foi lembrada: {warning}")
            elif remember:
                self.vault_status_var.set("Entrada lembrada no cofre seguro do GNOME.")
            self._audit_local("Conexão estabelecida; dados remotos carregados.")

        self._worker("Conectando com segurança à VPS…", connect, connected)

    def _refresh(self) -> None:
        self._worker("Atualizando ranking e bloqueios…", self.client.fetch_dashboard, self._accept_dashboard)

    def _accept_dashboard(self, data: dict[str, Any]) -> None:
        self.runs = data.get("runs", []) if isinstance(data.get("runs"), list) else []
        self.security = data.get("security", {}) if isinstance(data.get("security"), dict) else {}
        self._render_runs()
        self._render_security()
        source = "ranking projetado pelo relay" if data.get("snapshotOnline") else "dados brutos; endpoint público indisponível"
        self.status_var.set(f"Atualizado: {len(self.runs)} runs, {len(self.security.get('ips', {}))} IPs monitorados — {source}.")

    def _run_matches_filter(self, run: dict[str, Any]) -> bool:
        status = run_status(run)
        selected = self.filter_var.get()
        if selected == "Ativas" and status != "ATIVA":
            return False
        if selected == "Partidas falsas" and status != "PARTIDA FALSA":
            return False
        if selected == "Auditoria automática" and status != "AUDITORIA AUTOMÁTICA":
            return False
        if selected == "Bloqueadas manualmente" and status != "BLOQUEADA MANUAL":
            return False
        if selected == "Liberadas manualmente" and status != "LIBERADA MANUAL":
            return False
        if selected == "Retiradas" and status != "RETIRADA DA COMPETIÇÃO":
            return False
        query = self.search_var.get().strip().casefold()
        if not query:
            return True
        reasons = run.get("suspicionReasons", [])
        moderation = run.get("manualModeration")
        haystack = " ".join((
            str(run.get("id", "")), str(run.get("player", "")), str(run.get("profileId", "")),
            str(run.get("version", "")), " ".join(map(str, reasons if isinstance(reasons, list) else [])),
            str(moderation.get("reason", "") if isinstance(moderation, dict) else ""),
        )).casefold()
        return query in haystack

    def _render_runs(self) -> None:
        if not hasattr(self, "run_tree"):
            return
        self.run_tree.delete(*self.run_tree.get_children())
        self.run_by_tree_id.clear()
        visible = 0
        for run in self.runs:
            if not isinstance(run, dict) or not self._run_matches_filter(run):
                continue
            status = run_status(run)
            moderation = run.get("manualModeration")
            reasons = run.get("suspicionReasons", [])
            reason = moderation.get("reason", "") if isinstance(moderation, dict) else ""
            if not reason and isinstance(reasons, list):
                reason = ", ".join(map(str, reasons[:4]))
            if not reason and run.get("rankingWithdrawalReason"):
                reason = str(run.get("rankingWithdrawalReason"))
            if not reason and run.get("manualSynthetic"):
                reason = f"{SYNTHETIC_LABEL}: {run.get('syntheticReason', 'partida sintética')}"
            tag = ""
            if status == "BLOQUEADA MANUAL": tag = "blocked"
            elif status == "LIBERADA MANUAL": tag = "released"
            elif status == "AUDITORIA AUTOMÁTICA": tag = "audit"
            elif status == "RETIRADA DA COMPETIÇÃO": tag = "withdrawn"
            elif status == "PARTIDA FALSA": tag = "synthetic"
            item = self.run_tree.insert("", "end", values=(
                status, run.get("player", "Jogador"), fmt_number(run.get("score")), run.get("version", "—"),
                run.get("phase", 0), run.get("result", "—"), fmt_timestamp(run.get("endedUnix")), run.get("id", ""), reason or "—",
            ), tags=(tag,) if tag else ())
            self.run_by_tree_id[item] = run
            visible += 1
        self.runs_summary.configure(text=f"{visible} de {len(self.runs)} runs")

    def _latest_security_player(self, ip: str) -> str:
        audit = self.security.get("audit", [])
        if isinstance(audit, list):
            for event in audit:
                if isinstance(event, dict) and str(event.get("ip", "")) == ip and event.get("player"):
                    return str(event.get("player"))
        return "—"

    def _render_security(self) -> None:
        self.security_tree.delete(*self.security_tree.get_children())
        self.ip_by_tree_id.clear()
        now_ms = int(time.time() * 1000)
        ips = self.security.get("ips", {})
        if not isinstance(ips, dict):
            return
        ordered = sorted(ips.items(), key=lambda row: (int(row[1].get("blockedUntil", 0) or 0) > now_ms, int(row[1].get("lastSeen", 0) or 0)), reverse=True)
        for ip, state in ordered:
            if not isinstance(state, dict):
                continue
            moderation = state.get("manualModeration")
            decision = moderation.get("decision") if isinstance(moderation, dict) else ""
            blocked = int(state.get("blockedUntil", 0) or 0) > now_ms
            if decision == "released": status, tag = "LIBERADO MANUAL", "released"
            elif decision == "blocked": status, tag = "BLOQUEADO MANUAL", "blocked"
            elif blocked: status, tag = "BLOQUEIO AUTOMÁTICO", "automatic"
            else: status, tag = "MONITORADO", ""
            item = self.security_tree.insert("", "end", values=(
                status, ip, self._latest_security_player(ip), state.get("strikes", 0),
                fmt_timestamp(state.get("blockedUntil"), milliseconds=True), fmt_timestamp(state.get("lastSeen"), milliseconds=True),
                state.get("lastReason", "—") or "—",
            ), tags=(tag,) if tag else ())
            self.ip_by_tree_id[item] = ip

    def _selected_run(self) -> dict[str, Any] | None:
        selection = self.run_tree.selection()
        return self.run_by_tree_id.get(selection[0]) if selection else None

    def _open_run_details(self) -> None:
        run = self._selected_run()
        if not run:
            messagebox.showinfo("Selecione uma partida", "Escolha uma linha e clique em Ver detalhes, ou dê dois cliques nela.", parent=self)
            return
        RunDetailsWindow(self, run, self.COLORS)

    def _add_synthetic(self) -> None:
        if not self.client.connected:
            messagebox.showinfo("Conecte à VPS", "A partida falsa só pode ser adicionada depois de conectar à VPS.", parent=self)
            return
        dialog = SyntheticRunDialog(self, self.COLORS)
        self.wait_window(dialog)
        specification = dialog.result
        if not specification:
            return
        player = str(specification.get("player", "Jogador"))
        if not messagebox.askyesno(
            "Confirmar partida falsa",
            f"Adicionar a partida de {player} ao ranking?\n\n"
            f"Ela aparecerá como '{player} · {SYNTHETIC_LABEL}', terá versão ADMIN-FAKE e ficará fora do aprendizado da Umbra.\n\n"
            "Um backup remoto será criado antes da inclusão.",
            parent=self,
        ):
            return

        def task() -> tuple[dict[str, Any], dict[str, Any]]:
            created = self.client.add_synthetic(specification)
            return created, self.client.fetch_dashboard()

        def done(payload: tuple[dict[str, Any], dict[str, Any]]) -> None:
            created, data = payload
            self._accept_dashboard(data)
            self._audit_local(f"Partida falsa adicionada: id={created.get('id')} jogador={created.get('player')} motivo={created.get('syntheticReason')}")
            messagebox.showinfo(
                "Partida falsa adicionada",
                f"{created.get('player')}\nMérito: {fmt_number(created.get('score'))}\nID: {created.get('id')}\n\nA entrada está marcada e não treina a Umbra.",
                parent=self,
            )

        self._worker("Criando backup e adicionando partida falsa…", task, done)

    def _ask_reason(self, title: str) -> str | None:
        return simpledialog.askstring(title, "Motivo obrigatório (ficará no histórico e no backup):", parent=self)

    def _run_action(self, decision: str, whole_player: bool) -> None:
        run = self._selected_run()
        if not run:
            messagebox.showinfo("Selecione uma run", "Escolha uma linha do ranking antes de continuar.", parent=self)
            return
        reason = self._ask_reason("Registrar decisão")
        if reason is None:
            return
        scope = f"todas as runs de {run.get('player', 'Jogador')}" if whole_player else f"a run {run.get('id', '')}"
        label = {"blocked": "bloquear", "released": "liberar", "automatic": "restaurar a decisão automática de"}[decision]
        if not messagebox.askyesno("Confirmar alteração", f"Deseja {label} {scope}?\n\nNenhuma run será apagada e um backup remoto será criado.", parent=self):
            return
        run_id = str(run.get("id", ""))

        def task() -> Any:
            result = self.client.moderate_run(run_id, decision, reason, whole_player)
            return result, self.client.fetch_dashboard()

        def done(payload: Any) -> None:
            result, data = payload
            count = len(result) if whole_player and isinstance(result, list) else 1
            self._accept_dashboard(data)
            text = f"{count} run(s) atualizada(s): {label}."
            self._audit_local(f"{text} alvo={run_id} motivo={reason}")
            messagebox.showinfo("Ranking atualizado", text, parent=self)

        self._worker("Criando backup e aplicando moderação…", task, done)

    def _selected_ip(self) -> str | None:
        selection = self.security_tree.selection()
        return self.ip_by_tree_id.get(selection[0]) if selection else None

    def _ip_action(self, decision: str, duration_ms: int | None, forced_ip: str | None = None) -> None:
        ip = forced_ip or self._selected_ip()
        if not ip:
            messagebox.showinfo("Selecione um IP", "Escolha uma linha da lista antes de continuar.", parent=self)
            return
        reason = self._ask_reason("Registrar decisão de segurança")
        if reason is None:
            return
        verb = {"blocked": "bloquear", "released": "liberar e zerar strikes de", "automatic": "restaurar o detector automático para"}[decision]
        if not messagebox.askyesno("Confirmar alteração", f"Deseja {verb} {ip}?\n\nA ação será reversível e terá backup remoto.", parent=self):
            return

        def task() -> Any:
            result = self.client.moderate_ip(ip, decision, reason, duration_ms)
            return result, self.client.fetch_dashboard()

        def done(payload: Any) -> None:
            _, data = payload
            self._accept_dashboard(data)
            self._audit_local(f"IP atualizado: decisão={decision} ip={ip} motivo={reason}")
            messagebox.showinfo("Segurança atualizada", f"A decisão para {ip} foi aplicada.", parent=self)

        self._worker("Criando backup e atualizando bloqueio…", task, done)

    def _block_new_ip(self) -> None:
        ip = simpledialog.askstring("Bloquear outro IP", "Endereço IPv4 ou IPv6:", parent=self)
        if ip:
            self._ip_action("blocked", None, ip.strip())

    def _audit_local(self, message: str) -> None:
        LOCAL_STATE.mkdir(parents=True, exist_ok=True)
        stamp = datetime.now().astimezone().isoformat(timespec="seconds")
        with LOCAL_AUDIT.open("a", encoding="utf-8") as handle:
            handle.write(f"{stamp} {message}\n")
        self._load_local_audit()

    def _load_local_audit(self) -> None:
        if not hasattr(self, "audit_text"):
            return
        content = "Nenhuma ação local registrada ainda.\n"
        if LOCAL_AUDIT.exists():
            lines = LOCAL_AUDIT.read_text(encoding="utf-8", errors="replace").splitlines()
            content = "\n".join(lines[-400:]) + "\n"
        self.audit_text.configure(state="normal")
        self.audit_text.delete("1.0", "end")
        self.audit_text.insert("1.0", content)
        self.audit_text.configure(state="disabled")
        self.audit_text.see("end")

    def _on_close(self) -> None:
        self.client.close()
        self.password_var.set("")
        self.destroy()


def main() -> None:
    app = RankingAdminApp()
    app.mainloop()


if __name__ == "__main__":
    main()
