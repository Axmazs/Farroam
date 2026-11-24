extends ShipSimulation

@onready var timer: Timer = $arrivalTimer


func _ready() -> void:
	timer.one_shot = true
	timer.timeout.connect(_on_arrived)


func start() -> void:
	if data.speed <= 0.0:
		return

	var distance := data.position.distance_to(data.destination)
	var duration := maxf(distance / data.speed, 0.001)

	data.departure_position = data.position
	data.departure_time = GameClock.elapsed
	data.arrival_time = GameClock.elapsed + duration

	timer.start(duration)


func stop() -> void:
	if timer.is_stopped():
		return

	var duration := data.arrival_time - data.departure_time
	var elapsed := GameClock.elapsed - data.departure_time
	var progress := clampf(elapsed / duration, 0.0, 1.0)

	data.position = data.departure_position.lerp(
		data.destination,
		progress
	)

	timer.stop()


func _on_arrived() -> void:
	data.position = data.destination
	arrived.emit()
