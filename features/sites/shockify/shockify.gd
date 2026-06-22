extends Site

@onready var _play_btn: Button = %PlayBtn
@onready var _play_pause_btn: Button = %PlayPauseBtn
@onready var _progress: HSlider = %Progress
@onready var _time_label: Label = %TimeLabel
@onready var _now_playing_title: Label = %NowPlayingTitle
@onready var _now_playing_channel: Label = %NowPlayingChannel

var _scrubbing := false


func _ready() -> void:
	_play_btn.pressed.connect(_toggle_playback)
	_play_pause_btn.pressed.connect(_toggle_playback)
	_progress.drag_started.connect(func(): _scrubbing = true)
	_progress.drag_ended.connect(func(_changed: bool):
		PodcastPlayer.seek(_progress.value)
		_scrubbing = false
	)
	_refresh_ui()


func _process(_delta: float) -> void:
	if not PodcastPlayer.started or _scrubbing:
		return
	_progress.set_value_no_signal(PodcastPlayer.get_progress())
	_time_label.text = _fmt(PodcastPlayer.get_position())


func _toggle_playback() -> void:
	if PodcastPlayer.is_playing():
		PodcastPlayer.pause()
	else:
		PodcastPlayer.play()
	_refresh_ui()


func _refresh_ui() -> void:
	var playing := PodcastPlayer.is_playing()
	_play_btn.text = "Pause" if playing else "Play"
	_play_pause_btn.text = "Pause" if playing else "Play"
	if PodcastPlayer.started:
		_now_playing_title.text = "TriCityPod"
		_now_playing_channel.text = "TriCityPod"
		_progress.set_value_no_signal(PodcastPlayer.get_progress())
		_time_label.text = _fmt(PodcastPlayer.get_position())


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		PodcastPlayer.stop()


func _fmt(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60]
