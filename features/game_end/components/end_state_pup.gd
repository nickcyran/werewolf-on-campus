class_name EndStatePup extends Control
## The pup that reacts to an end screen's score. The art has wide transparent margins,
## so the texture overhangs this box and the drawn pup fills it.

## Where the paws sit, as a share of the texture's height. The pop grows from here.
const _FEET := 0.9
const _BOB_SECONDS := 0.9

var _tweens: Array[Tween] = []

@onready var _backdrop: Control = %Backdrop
@onready var _disc: Panel = %Disc
@onready var _shadow: TextureRect = %Shadow
@onready var _pup: TextureRect = %Pup


func _ready() -> void:
	modulate.a = 0.0
	_backdrop.resized.connect(_refresh_pivots)
	_pup.resized.connect(_refresh_pivots)


func show_tier(tier: EndStateTier, delay := 0.0) -> void:
	for tw in _tweens:
		if tw.is_valid():
			tw.kill()
	_tweens.clear()

	_pup.texture = tier.pup
	_disc.theme_type_variation = tier.backdrop_style
	_refresh_pivots()

	modulate.a = 1.0
	_backdrop.scale = Vector2(0.3, 0.3)
	_backdrop.modulate.a = 0.0
	_pup.scale = Vector2(0.5, 0.5)
	_pup.modulate.a = 0.0
	_shadow.modulate.a = 0.0

	var pop := _tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(_backdrop, "scale", Vector2.ONE, 0.5).set_delay(delay)
	pop.parallel().tween_property(_backdrop, "modulate:a", 1.0, 0.2).set_delay(delay)
	pop.parallel().tween_property(_pup, "scale", Vector2.ONE, 0.65).set_delay(delay + 0.15)
	pop.parallel().tween_property(_pup, "modulate:a", 1.0, 0.2).set_delay(delay + 0.15)
	pop.parallel().tween_property(_shadow, "modulate:a", 1.0, 0.4).set_delay(delay + 0.15)
	if tier.bob_height > 0.0:
		pop.tween_callback(_start_bob.bind(tier.bob_height))


## Relative steps, so a re-layout mid-bob shifts the base instead of fighting it.
func _start_bob(height: float) -> void:
	var bob := _tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.tween_property(_pup, "position:y", -height, _BOB_SECONDS).as_relative()
	bob.tween_property(_pup, "position:y", height, _BOB_SECONDS).as_relative()


func _refresh_pivots() -> void:
	_backdrop.pivot_offset = _backdrop.size / 2.0
	_pup.pivot_offset = Vector2(_pup.size.x / 2.0, _pup.size.y * _FEET)


func _tween() -> Tween:
	var tw := create_tween()
	_tweens.append(tw)
	return tw
