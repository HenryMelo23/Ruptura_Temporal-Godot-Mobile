class_name RTKeyboardBindingDefaults
extends RefCounted

## Atalhos padrao de teclado/mouse no desktop (primeira execucao, "Restaurar
## padrao" e disparo automatico). Em disparo no cursor o botao esquerdo do
## mouse tambem dispara, sem apagar a tecla configurada (SPACE por padrao).

const KEY_PREFIX := "KEY:"
const MOUSE_PREFIX := "MOUSE:"
const CURSOR_ATTACK_BINDING := MOUSE_PREFIX + "1" # MOUSE_BUTTON_LEFT

## Ordem do save (`_keyboard_binding_serialization_order`): o slot "shop" e
## legado e nao aparece na tela.
const DEFAULTS: Dictionary = {
	"attack": KEY_PREFIX + "32", # SPACE
	"skill": KEY_PREFIX + "81", # Q
	"secondary": KEY_PREFIX + "69", # E
	"dash": KEY_PREFIX + "4194325", # SHIFT
	"lacerante_empower": KEY_PREFIX + "74", # J
	"dance": KEY_PREFIX + "79", # O
	"pause": KEY_PREFIX + "4194305", # ESCAPE
	"shop": KEY_PREFIX + "80", # P
	"boss": KEY_PREFIX + "82", # R
	"interact": KEY_PREFIX + "70", # F
}

## Padrao anterior (ate 2.1.4). Um save identico a ele nunca foi personalizado
## e passa para o padrao novo ao carregar.
const LEGACY_DEFAULTS: Dictionary = {
	"attack": MOUSE_PREFIX + "1",
	"skill": MOUSE_PREFIX + "2",
	"secondary": KEY_PREFIX + "81",
	"dash": KEY_PREFIX + "4194325",
	"lacerante_empower": KEY_PREFIX + "82",
	"dance": KEY_PREFIX + "79",
	"interact": KEY_PREFIX + "69",
	"pause": KEY_PREFIX + "4194305",
	"shop": KEY_PREFIX + "80",
	"boss": KEY_PREFIX + "66",
}


static func defaults() -> Dictionary:
	return DEFAULTS.duplicate()


static func migrate_legacy(bindings: Dictionary) -> Dictionary:
	for action: String in LEGACY_DEFAULTS:
		if String(bindings.get(action, "")) != String(LEGACY_DEFAULTS[action]):
			return bindings
	return defaults()


## Entrou no disparo no cursor: o clique esquerdo passa a ser do ataque, entao
## sai de qualquer outra acao que o usasse.
static func release_cursor_button(bindings: Dictionary) -> void:
	for action: String in bindings.keys():
		if action != "attack" and String(bindings[action]) == CURSOR_ATTACK_BINDING:
			bindings[action] = ""


static func cursor_attack_event(event: InputEvent) -> bool:
	return event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT


static func cursor_label(base_label: String) -> String:
	if base_label in ["MOUSE ESQ.", "SEM TECLA"]:
		return "MOUSE ESQ."
	return "MOUSE ESQ. + " + base_label
