class_name ReliabilityIndicatorData
extends RefCounted

static var _indicators: Array[ReliabilityIndicator]


static func get_indicators() -> Array[ReliabilityIndicator]:
	if _indicators.is_empty():
		_indicators = _load_indicators()
	return _indicators


static func _load_indicators() -> Array[ReliabilityIndicator]:
	return [
		preload("res://data/reliability_indicators/indicator_00.tres"),
		preload("res://data/reliability_indicators/indicator_01.tres"),
		preload("res://data/reliability_indicators/indicator_02.tres"),
		preload("res://data/reliability_indicators/indicator_03.tres"),
		preload("res://data/reliability_indicators/indicator_04.tres"),
		preload("res://data/reliability_indicators/indicator_05.tres"),
		preload("res://data/reliability_indicators/indicator_06.tres"),
		preload("res://data/reliability_indicators/indicator_07.tres"),
		preload("res://data/reliability_indicators/indicator_08.tres"),
		preload("res://data/reliability_indicators/indicator_09.tres"),
		preload("res://data/reliability_indicators/indicator_10.tres"),
		preload("res://data/reliability_indicators/indicator_11.tres"),
		preload("res://data/reliability_indicators/indicator_12.tres"),
		preload("res://data/reliability_indicators/indicator_13.tres"),
		preload("res://data/reliability_indicators/indicator_14.tres"),
		preload("res://data/reliability_indicators/indicator_15.tres"),
		preload("res://data/reliability_indicators/indicator_16.tres"),
		preload("res://data/reliability_indicators/indicator_17.tres"),
		preload("res://data/reliability_indicators/indicator_18.tres"),
	]
