extends Site

@export var play_icon: Texture2D
@export var pause_icon: Texture2D

@onready var _play_btn: Button = %PlayBtn
@onready var _play_pause_btn: Button = %PlayPauseBtn
@onready var _progress: HSlider = %Progress
@onready var _time_label: Label = %TimeLabel
@onready var _duration_label: Label = %DurationLabel
@onready var _playable_row: Control = %PlayableRow
@onready var _episode_dur: Label = %EpisodeDur
@onready var _volume_slider: HSlider = %VolumeSlider
@onready var _transcript_btn: Button = %TranscriptBtn
@onready var _transcript_panel: Control = %TranscriptPanel
@onready var _transcript_close_btn: Button = %TranscriptCloseBtn

var _scrubbing := false


func _ready() -> void:
	_play_btn.pressed.connect(_toggle_playback)
	_play_pause_btn.pressed.connect(_toggle_playback)
	_playable_row.gui_input.connect(_on_playable_row_input)
	_transcript_btn.pressed.connect(_toggle_transcript)
	_transcript_close_btn.pressed.connect(_toggle_transcript)
	_progress.drag_started.connect(func(): _scrubbing = true)
	_progress.drag_ended.connect(func(_changed: bool):
		PodcastPlayer.seek(_progress.value)
		_scrubbing = false
	)
	_volume_slider.value_changed.connect(PodcastPlayer.set_volume)
	PodcastPlayer.set_volume(_volume_slider.value)
	_duration_label.text = _fmt(PodcastPlayer.get_duration())
	_episode_dur.text = _fmt(PodcastPlayer.get_duration())
	_refresh_ui()


func _process(_delta: float) -> void:
	if !PodcastPlayer.started || _scrubbing:
		return
	_progress.set_value_no_signal(PodcastPlayer.get_progress())
	_time_label.text = _fmt(PodcastPlayer.get_position())


func _on_playable_row_input(event: InputEvent) -> void:
	if event is InputEventMouseButton && event.pressed && event.button_index == MOUSE_BUTTON_LEFT:
		_toggle_playback()


func _toggle_playback() -> void:
	if PodcastPlayer.is_playing():
		PodcastPlayer.pause()
	else:
		PodcastPlayer.play()
	_refresh_ui()


func _toggle_transcript() -> void:
	_transcript_panel.visible = !_transcript_panel.visible


func _refresh_ui() -> void:
	var playing := PodcastPlayer.is_playing()
	_play_btn.icon = pause_icon if playing else play_icon
	_play_pause_btn.icon = pause_icon if playing else play_icon
	if PodcastPlayer.started:
		_progress.set_value_no_signal(PodcastPlayer.get_progress())
		_time_label.text = _fmt(PodcastPlayer.get_position())


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		PodcastPlayer.stop()


func _fmt(seconds: float) -> String:
	var s := int(seconds)
	@warning_ignore("integer_division")
	return "%d:%02d" % [s / 60, s % 60]
