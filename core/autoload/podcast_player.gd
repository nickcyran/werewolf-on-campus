extends Node

var started := false
var paused := false

var _player: AudioStreamPlayer
# Seek requested while not actively playing; applied when playback (re)starts.
var _pending_seek := -1.0


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)
	_player.stream = load("res://assets/media/TriCityPod.mp3")
	DayClock.day_ended.connect(stop)


func play() -> void:
	if not started:
		_player.play(maxf(_pending_seek, 0.0))
		started = true
		paused = false
		GameManager.mark_source_visited("tricitypod")
	elif paused:
		_player.stream_paused = false
		paused = false
		if _pending_seek >= 0.0:
			_player.seek(_pending_seek)
	_pending_seek = -1.0


func pause() -> void:
	if started and not paused:
		_player.stream_paused = true
		paused = true


func stop() -> void:
	_player.stop()
	started = false
	paused = false
	_pending_seek = -1.0


func set_volume(linear: float) -> void:
	_player.volume_db = linear_to_db(clampf(linear, 0.0, 1.0)) if linear > 0.001 else -80.0


func seek(ratio: float) -> void:
	var duration := get_duration()
	if duration <= 0.0:
		return
	var pos := ratio * duration
	if is_playing():
		_player.seek(pos)
	else:
		_pending_seek = pos


func is_playing() -> bool:
	return started and not paused


func get_position() -> float:
	if _pending_seek >= 0.0 and not is_playing():
		return _pending_seek
	return _player.get_playback_position()


func get_duration() -> float:
	return _player.stream.get_length() if _player.stream else 0.0


func get_progress() -> float:
	var d := get_duration()
	return get_position() / d if d > 0.0 else 0.0
