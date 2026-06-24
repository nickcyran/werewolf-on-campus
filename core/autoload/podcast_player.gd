extends Node

var started := false
var paused := false

var _player: AudioStreamPlayer


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)
	_player.stream = load("res://assets/media/TriCityPod.mp3")
	DayClock.day_ended.connect(stop)


func play() -> void:
	if not started:
		_player.play()
		started = true
		paused = false
	elif paused:
		_player.stream_paused = false
		paused = false


func pause() -> void:
	if started and not paused:
		_player.stream_paused = true
		paused = true


func stop() -> void:
	_player.stop()
	started = false
	paused = false


func seek(ratio: float) -> void:
	var duration := get_duration()
	if duration > 0.0:
		_player.seek(ratio * duration)


func is_playing() -> bool:
	return started and not paused


func get_position() -> float:
	return _player.get_playback_position()


func get_duration() -> float:
	return _player.stream.get_length() if _player.stream else 0.0


func get_progress() -> float:
	var d := get_duration()
	return get_position() / d if d > 0.0 else 0.0
