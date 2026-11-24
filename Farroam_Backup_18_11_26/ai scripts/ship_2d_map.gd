extends ShipSimulation


func _ready() -> void:
	set_process(false)


func start() -> void:
	set_process(data.speed > 0.0)


func stop() -> void:
	set_process(false)


func _process(delta: float) -> void:
	var point := Vector2(data.position.x, data.position.z)
	var destination := Vector2(data.destination.x, data.destination.z)

	point = point.move_toward(destination, data.speed * delta)

	data.position.x = point.x
	data.position.z = point.y

	if point == destination:
		set_process(false)
		arrived.emit()
