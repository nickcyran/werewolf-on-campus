extends Node3D

func _ready() -> void:
	print("hi")
	push_warning("HELLO")
	push_error("HELLO")

func _process(delta):
	print("running...")
