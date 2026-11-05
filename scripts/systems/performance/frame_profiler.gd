class_name RTFrameProfiler
extends RefCounted

## Profiler de quadro por secoes. Desligado por padrao (uma checagem de bool).
## Uso: begin("update") no inicio de um bloco e mark("nome") ao fim de cada trecho;
## o tempo desde a marca anterior vai para "nome". report() devolve medias em ms.

static var enabled: bool = false
static var _last_us: int = 0
static var totals: Dictionary = {}
static var peaks: Dictionary = {}
static var counts: Dictionary = {}
static var frames: int = 0
## Benchmark-only: section names whose drawing is skipped, to attribute draw calls.
static var skip: Dictionary = {}


static func skipped(name: String) -> bool:
	return enabled and skip.has(name)


static func reset() -> void:
	totals.clear()
	peaks.clear()
	counts.clear()
	frames = 0


static func begin() -> void:
	if enabled:
		_last_us = Time.get_ticks_usec()


static func mark(name: String) -> void:
	if not enabled:
		return
	var now: int = Time.get_ticks_usec()
	var spent: int = now - _last_us
	totals[name] = int(totals.get(name, 0)) + spent
	counts[name] = int(counts.get(name, 0)) + 1
	if spent > int(peaks.get(name, 0)):
		peaks[name] = spent
	_last_us = now


static func end_frame() -> void:
	if enabled:
		frames += 1


static func report() -> Array:
	var rows: Array = []
	for name in totals.keys():
		var n: int = maxi(1, frames)
		rows.append({"name": name, "avg_ms": float(totals[name]) / 1000.0 / float(n), "peak_ms": float(peaks.get(name, 0)) / 1000.0})
	rows.sort_custom(func(a, b): return float(a["avg_ms"]) > float(b["avg_ms"]))
	return rows
