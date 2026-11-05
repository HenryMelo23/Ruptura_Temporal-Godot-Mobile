extends SceneTree

## Cada escolha da tela de build tem relatorio, e numeros-chave batem com o codigo.

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("BUILD_CHOICE_DOSSIER_FAIL " + message)
	quit(1)


func _text(d: Dictionary) -> String:
	var parts: Array = [String(d.get("tagline", ""))]
	for row in d.get("rows", []):
		parts.append(String(row.get("text", "")))
	return " ".join(parts)


func _fmt(value: float) -> String:
	var s := ("%.1f" % value) if absf(value - round(value)) > 0.01 else str(int(round(value)))
	return s.replace(".", ",")


func _run() -> void:
	var counted := 0
	for entry in game.MANIFESTATIONS:
		var d := RTBuildChoiceDossier.manifestation(String(entry["key"]))
		_check(not d.is_empty() and Array(d["rows"]).size() >= 4, "manifestation without dossier: %s" % entry["key"])
		counted += 1
	for entry in game.AURAS:
		var d := RTBuildChoiceDossier.spectrum(String(entry["name"]))
		_check(not d.is_empty() and Array(d["rows"]).size() == 3, "spectrum without dossier: %s" % entry["name"])
		counted += 1
	for entry in game.HENRY_MUTATIONS:
		_check(not RTBuildChoiceDossier.mutation(String(entry["key"])).is_empty(), "mutation without dossier: %s" % entry["key"])
		counted += 1
	for entry in game.HENRY_EFFECTS:
		_check(not RTBuildChoiceDossier.effect(String(entry["key"])).is_empty(), "effect without dossier: %s" % entry["key"])
		counted += 1
	# Numeros que os jogadores relataram errados ou que mudam com balanceamento.
	var lac := _text(RTBuildChoiceDossier.manifestation("lacerante"))
	_check(lac.contains("%s s para o segundo" % _fmt(game.LACERANTE_TP_CHAIN_WINDOW)), "lacerante TP window out of sync")
	_check(lac.contains("%d%% menos dano" % int(round((1.0 - game.LACERANTE_DAMAGE_TAKEN_MULT) * 100.0))), "lacerante damage reduction out of sync")
	var ele := _text(RTBuildChoiceDossier.manifestation("eletrica"))
	_check(ele.contains("após %s s" % _fmt(game.SECONDARY_ELETRICA_DRAIN_DELAY)), "eletrica drain delay out of sync")
	_check(ele.contains("%s s no caminho" % _fmt(game.TP_ELECTRIC_DURATION)), "eletrica TP duration out of sync")
	var par := _text(RTBuildChoiceDossier.manifestation("parasitica"))
	_check(par.contains("por %s s" % _fmt(game.PARASITE_MARK_DURATION)) and par.contains("%s s" % _fmt(game.PARASITE_FEAST_DURATION)), "parasitica durations out of sync")
	var pri := _text(RTBuildChoiceDossier.manifestation("prismatica"))
	_check(pri.contains("%s s" % _fmt(game.SECONDARY_PRISMATICA_DURATION)) and pri.contains("%d px" % int(RTRangedAttackRange.BASE_RANGE)), "prismatica numbers out of sync")
	var gra := _text(RTBuildChoiceDossier.manifestation("gravitante"))
	_check(gra.contains("%d px" % int(RTGravitanteController.WELL_RADIUS)) and gra.contains("%s s" % _fmt(RTGravitanteController.WELL_DURATION)), "gravitante TP well out of sync")
	var rac := _text(RTBuildChoiceDossier.spectrum("Racional"))
	_check(rac.contains("%s s" % _fmt(AuraSystem.RATIONAL_STILL_TIME)) and rac.contains("Por %s s" % _fmt(AuraSystem.RATIONAL_DILATION_TIME)), "racional numbers out of sync")
	_check(_text(RTBuildChoiceDossier.spectrum("Impulsiva")).contains("%d abates" % AuraSystem.IMPULSIVE_KILLS), "impulsiva kills out of sync")
	_check(_text(RTBuildChoiceDossier.spectrum("Devota")).contains("%d cargas" % AuraSystem.DEVOTED_CHARGES), "devota charges out of sync")
	_check(_text(RTBuildChoiceDossier.spectrum("Crepuscular")).contains("Fases de %s s" % _fmt(AuraSystem.CREPUSCULAR_PHASE_TIME)) or String(RTBuildChoiceDossier.spectrum("Crepuscular")["rows"][0]["title"]).contains(_fmt(AuraSystem.CREPUSCULAR_PHASE_TIME)), "crepuscular phase out of sync")
	# A fonte do jogo nao tem estes glifos.
	for entry in game.MANIFESTATIONS:
		var t := _text(RTBuildChoiceDossier.manifestation(String(entry["key"])))
		for glyph in ["ª", "º", "~", "‹", "›"]:
			_check(not t.contains(glyph), "unsupported glyph %s in %s" % [glyph, entry["key"]])
	print("BUILD_CHOICE_DOSSIER_OK entries=%d numbers_synced=true glyphs=true" % counted)
	game.free()
	quit(0)
