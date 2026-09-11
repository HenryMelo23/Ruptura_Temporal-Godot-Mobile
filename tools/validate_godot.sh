#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
PROJECT_FILE="$PROJECT_ROOT/project.godot"
LOGS_DIR="$PROJECT_ROOT/.agent_logs"
SMOKE_FRAMES=300
SCENE=""
DEEP=0
SKIP_SMOKE=0

usage() {
  cat <<'EOF'
Usage: tools/validate_godot.sh [options]

Options:
  --godot PATH       Godot editor binary. Defaults to GODOT_BIN or PATH lookup.
  --frames N         Frames used by the smoke test. Default: 300.
  --scene RES_PATH   Smoke-test a specific scene instead of the configured main scene.
  --deep             Parse every GDScript file separately before smoke testing.
  --skip-smoke       Skip the scene smoke test.
  -h, --help         Show this help.
EOF
}

GODOT_BIN_VALUE="${GODOT_BIN:-}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --godot)
      GODOT_BIN_VALUE="${2:?Missing value for --godot}"
      shift 2
      ;;
    --frames)
      SMOKE_FRAMES="${2:?Missing value for --frames}"
      shift 2
      ;;
    --scene)
      SCENE="${2:?Missing value for --scene}"
      shift 2
      ;;
    --deep)
      DEEP=1
      shift
      ;;
    --skip-smoke)
      SKIP_SMOKE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ ! -f "$PROJECT_FILE" ]]; then
  echo "project.godot was not found at: $PROJECT_FILE" >&2
  exit 1
fi

mkdir -p "$LOGS_DIR"

resolve_godot() {
  if [[ -n "$GODOT_BIN_VALUE" ]]; then
    if [[ -x "$GODOT_BIN_VALUE" ]]; then
      printf '%s\n' "$GODOT_BIN_VALUE"
      return
    fi
    if command -v "$GODOT_BIN_VALUE" >/dev/null 2>&1; then
      command -v "$GODOT_BIN_VALUE"
      return
    fi
    echo "GODOT_BIN/--godot does not point to an executable: $GODOT_BIN_VALUE" >&2
    exit 1
  fi

  local candidate
  for candidate in godot godot4 godot-mono; do
    if command -v "$candidate" >/dev/null 2>&1; then
      command -v "$candidate"
      return
    fi
  done

  echo "Godot was not found. Add it to PATH or set GODOT_BIN." >&2
  exit 1
}

GODOT="$(resolve_godot)"

ERROR_REGEX='SCRIPT ERROR:|(^|[[:space:]])ERROR:|Parse Error:|^E[[:space:]]+[0-9]+:[0-9]+:[0-9]+([.][0-9]+)?:|Failed loading resource|Failed to load script|Cannot open file|Invalid call[.]|Invalid access to (property|index)|Node not found:|Assertion failed|Segmentation fault|CrashHandlerException'

run_step() {
  local name="$1"
  local allow_error_text="$2"
  local required_pattern="$3"
  shift 3

  local safe_name log_path status
  safe_name="$(printf '%s' "$name" | tr -c 'A-Za-z0-9_.-' '_')"
  log_path="$LOGS_DIR/${safe_name}.log"

  printf '\n==> %s\n' "$name"
  printf '    %q ' "$GODOT" "$@"
  printf '\n'

  set +e
  "$GODOT" "$@" 2>&1 | tee "$log_path"
  status=${PIPESTATUS[0]}
  set -e

  if [[ $status -ne 0 ]]; then
    echo "$name failed with exit code $status. Log: $log_path" >&2
    exit "$status"
  fi

  if [[ "$allow_error_text" != "1" ]] && grep -Eiq "$ERROR_REGEX" "$log_path"; then
    echo "$name emitted Godot error text:" >&2
    grep -Ein "$ERROR_REGEX" "$log_path" | head -n 12 >&2 || true
    echo "Log: $log_path" >&2
    exit 1
  fi

  if [[ -n "$required_pattern" ]] && ! grep -Eq "$required_pattern" "$log_path"; then
    echo "$name did not emit the required success marker '$required_pattern'. Log: $log_path" >&2
    exit 1
  fi
}

is_godot_ignored_path() {
  local path="$1"
  local dir
  dir="$(dirname "$path")"
  while [[ "$dir" == "$PROJECT_ROOT"/* ]]; do
    if [[ -f "$dir/.gdignore" ]]; then
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

run_step "00_godot_version" 1 "" --version
run_step "01_project_import" 0 "" --headless --path "$PROJECT_ROOT" --import --verbose

if find "$PROJECT_ROOT" -path "$PROJECT_ROOT/.godot" -prune -o \( -name '*.csproj' -o -name '*.cs' \) -print -quit | grep -q .; then
  run_step "02_build_csharp" 0 "" --headless --path "$PROJECT_ROOT" --build-solutions --quit --verbose
fi

if [[ $DEEP -eq 1 ]]; then
  index=0
  while IFS= read -r -d '' script; do
    if is_godot_ignored_path "$script"; then
      continue
    fi
    index=$((index + 1))
    relative="${script#"$PROJECT_ROOT"/}"
    resource_path="res://${relative//\\//}"
    safe_relative="$(printf '%s' "$relative" | tr -c 'A-Za-z0-9_.-' '_')"
    printf -v step_name '03_parse_%04d_%s' "$index" "$safe_relative"
    run_step "$step_name" 0 "" --headless --path "$PROJECT_ROOT" --script "$resource_path" --check-only
  done < <(find "$PROJECT_ROOT" \( -path "$PROJECT_ROOT/.godot" -o -path "$PROJECT_ROOT/.git" \) -prune -o -type f -name '*.gd' -print0 | sort -z)
fi

if [[ $SKIP_SMOKE -eq 0 ]]; then
  user_args=("--frames=$SMOKE_FRAMES")
  if [[ -n "$SCENE" ]]; then
    user_args+=("--scene=$SCENE")
  fi
  run_step "04_smoke_test" 0 "AGENT_SMOKE_TEST_OK" --headless --path "$PROJECT_ROOT" --debug --script res://tools/agent_smoke_test.gd -- "${user_args[@]}"
fi

printf '\nGODOT VALIDATION PASSED\n'
printf 'Project: %s\n' "$PROJECT_ROOT"
printf 'Logs:    %s\n' "$LOGS_DIR"
