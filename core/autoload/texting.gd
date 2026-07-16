extends Node

## Emitted the instant a message becomes visible to the player.
signal message_received(thread_index: int, message: TextingMessage)
## Emitted whenever the total unread count changes.
signal unread_changed(total_unread: int)

@export var threads: Array[TextingThread] = []

var _delivered_counts: Array[int] = []
var _unread_counts: Array[int] = []
var _sfx_player: AudioStreamPlayer


func _ready() -> void:
	_sfx_player = AudioStreamPlayer.new()
	add_child(_sfx_player)
	_delivered_counts.resize(threads.size())
	_delivered_counts.fill(0)
	_unread_counts.resize(threads.size())
	_unread_counts.fill(0)


func reset() -> void:
	for i in _delivered_counts.size():
		_delivered_counts[i] = 0
		_unread_counts[i] = 0
	unread_changed.emit(0)


func _process(_delta: float) -> void:
	if not DayClock.started or DayClock.day_over:
		return

	var progress := DayClock.get_progress()
	var delivered_any := false

	for ti in threads.size():
		var thread_messages := threads[ti].messages
		var delivered: int = _delivered_counts[ti]
		while delivered < thread_messages.size() and thread_messages[delivered].trigger_progress <= progress:
			var msg := thread_messages[delivered]
			delivered += 1
			_unread_counts[ti] += 1
			delivered_any = true
			message_received.emit(ti, msg)
		_delivered_counts[ti] = delivered

	if delivered_any:
		_play_notification_sound()
		unread_changed.emit(get_total_unread())


func get_thread_count() -> int:
	return threads.size()


func get_thread(thread_index: int) -> TextingThread:
	return threads[thread_index]


func get_delivered_messages(thread_index: int) -> Array[TextingMessage]:
	return threads[thread_index].messages.slice(0, _delivered_counts[thread_index])


func get_unread_count(thread_index: int) -> int:
	return _unread_counts[thread_index]


func get_total_unread() -> int:
	var total := 0
	for c in _unread_counts:
		total += c
	return total


func mark_thread_read(thread_index: int) -> void:
	if _unread_counts[thread_index] == 0:
		return
	_unread_counts[thread_index] = 0
	unread_changed.emit(get_total_unread())


## Synthesizes a short two-note chime at runtime so the notification sound
## doesn't depend on an external audio asset.
func _play_notification_sound() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 44100.0
	gen.buffer_length = 0.5
	_sfx_player.stream = gen
	_sfx_player.play()

	var playback: AudioStreamGeneratorPlayback = _sfx_player.get_stream_playback()
	var sample_rate := gen.mix_rate
	var notes: Array[float] = [880.0, 1318.51]
	var note_len := 0.11
	var gap_len := 0.02

	for freq in notes:
		var frames := int(sample_rate * note_len)
		for i in frames:
			var t := float(i) / sample_rate
			var envelope := sin(PI * float(i) / frames)
			var sample := sin(TAU * freq * t) * envelope * 0.3
			playback.push_frame(Vector2(sample, sample))
		var gap_frames := int(sample_rate * gap_len)
		for i in gap_frames:
			playback.push_frame(Vector2.ZERO)
