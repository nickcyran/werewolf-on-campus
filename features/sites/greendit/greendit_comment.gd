class_name GreenditComment
extends Resource

@export var author: String = ""
@export var time: String = ""
@export var score: int = 0
@export_multiline var body: String = ""
@export var replies: Array[GreenditComment] = []
