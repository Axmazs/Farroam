extends Node2D

@export var freighter_scene: PackedScene
@export var freighter_marker_scene: PackedScene
@export var depot_scene: PackedScene
@export var mining_station_scene: PackedScene
@export var raider_scene: PackedScene

@export var freighter_count := 2
@export var raider_count := 4
@export var depot_count := 1
@export var mining_station_count := 1

@onready var sector_border: Sprite2D = $SectorBorderSprite

var ships: Array[Ship] = []
var markers: Array[ShipMarker2D] = []


func _ready() -> void:
	for _i in range(depot_count):
		spawn_marker(depot_scene)

	for _i in range(mining_station_count):
		spawn_marker(mining_station_scene)

	for _i in range(freighter_count):
		spawn_freighter()

	if raider_scene != null:
		for _i in range(raider_count):
			spawn_marker(raider_scene)


func spawn_marker(marker_scene: PackedScene) -> void:
	var marker := marker_scene.instantiate() as Node2D
	marker.position = random_sector_position()
	add_child(marker)


func spawn_freighter() -> void:
	var ship := freighter_scene.instantiate() as Ship

	assert(
		ship.data != null,
		"In freighter.tscn fehlt die ShipData-Ressource."
	)

	ship.data = ship.data.duplicate() as ShipData

	var point := random_sector_position()
	ship.data.position = Vector3(point.x, 0.0, point.y)

	add_child(ship)
	ships.append(ship)

	var marker := freighter_marker_scene.instantiate() as ShipMarker2D
	marker.data = ship.data
	marker.position = Vector2(ship.data.position.x, ship.data.position.z)

	add_child(marker)
	markers.append(marker)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				set_map_mode(false)
			KEY_2:
				set_map_mode(true)


func set_map_mode(map_open: bool) -> void:
	for ship in ships:
		ship.ai.set_map_mode(map_open)

	for marker in markers:
		marker.position = Vector2(
			marker.data.position.x,
			marker.data.position.z
		)
		marker.set_process(map_open)

	visible = map_open
	print("2D-Map" if map_open else "No-Map")


func random_sector_position() -> Vector2:
	var bounds := sector_border.get_rect()
	var radius := minf(bounds.size.x, bounds.size.y) * 0.45
	var angle := randf_range(0.0, TAU)
	var distance := sqrt(randf()) * radius

	var point := bounds.get_center() + Vector2.from_angle(angle) * distance
	return sector_border.transform * point
