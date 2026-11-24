class_name ShipMarker2D
extends Node2D

var data: ShipData


func _process(_delta: float) -> void:
	if data != null:
		position = Vector2(data.position.x, data.position.z)
