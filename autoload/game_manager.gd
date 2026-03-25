extends Node

signal state_changed(new_state: State)
signal focus_entered(interactable: Node3D)

enum State { PLAYING, FOCUSED, PAUSED }

var state: State = State.PLAYING:
	set(value):
		if state == value:
			return
			
		state = value
		state_changed.emit(state)

var focused_interactable: Node3D = null


func request_focus(interactable: Node3D) -> void:
	if state != State.PLAYING:
		return
		
	focused_interactable = interactable
	state = State.FOCUSED
	focus_entered.emit(interactable)


func release_focus() -> void:
	if state != State.FOCUSED:
		return
		
	focused_interactable = null
	state = State.PLAYING


func is_playing() -> bool:
	return state == State.PLAYING
