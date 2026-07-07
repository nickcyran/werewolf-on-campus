class_name WerewolfFactData
extends RefCounted

static var _facts: Array[WerewolfFact]


static func get_facts() -> Array[WerewolfFact]:
	if _facts.is_empty():
		_facts = _load_facts()
	return _facts


static func fact_count() -> int:
	return get_facts().size()


static func count_matches(player_checked: Dictionary) -> int:
	var facts := get_facts()
	var ok := 0
	for i in range(facts.size()):
		if bool(player_checked.get(i, false)) == facts[i].is_correct:
			ok += 1
	return ok


static func _load_facts() -> Array[WerewolfFact]:
	return [
		preload("res://data/werewolf_facts/fact_01.tres"),
		preload("res://data/werewolf_facts/fact_02.tres"),
		preload("res://data/werewolf_facts/fact_03.tres"),
		preload("res://data/werewolf_facts/fact_04.tres"),
		preload("res://data/werewolf_facts/fact_05.tres"),
		preload("res://data/werewolf_facts/fact_06.tres"),
		preload("res://data/werewolf_facts/fact_07.tres"),
		preload("res://data/werewolf_facts/fact_08.tres"),
	]
