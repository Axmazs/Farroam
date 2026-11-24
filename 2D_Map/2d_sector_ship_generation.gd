extends Node

@export var freighter_scene: PackedScene
@export var freighter_marker_scene: PackedScene

@onready var sector: Sector = get_parent() as Sector

func spawn_freighter(index: int) -> void:
	var ship := freighter_scene.instantiate() as Ship
	assert(ship != null and ship.data != null, "Freighter-Szene mit ship.gd und ShipData zuweisen.")
	ship.name = "Frachter_%d" % [index + 1]
	ship.data = ship.data.duplicate(true) as ShipData
	var point: Vector2 = sector.random_sector_position()
	ship.data.position = Vector3(point.x, 0.0, point.y)
	add_child(ship)
	sector.ships.append(ship)
	
	if freighter_marker_scene != null:
		var marker: Node2D = sector.spawn_marker(
			freighter_marker_scene,
			point,
			ship.data
		)

		sector.markers.append(marker)

func generate(freighter_count: int) -> void:
	for index: int in range(freighter_count):
		spawn_freighter(index)
