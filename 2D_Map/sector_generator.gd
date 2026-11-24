class_name Sector
extends Node

@export var data: SectorData

@export var mining_station_count: int = 1
@export var depot_count: int = 2
@export var freighter_count: int = 2

@onready var stations: Node = $Stations
@onready var ship_generator: Node = $Ships

var ships: Array[Ship] = []
var markers: Array[Node2D] = []
var mines: Array[StationAI] = []
var depots: Array[StationAI] = []
var station_points: Array[Vector2] = []


func _ready() -> void:
	if data == null:
		data = SectorData.new()
	else:
		data = data.duplicate(true) as SectorData

	# Zuerst Stationen, anschließend Schiffe erzeugen.
	stations.generate(mining_station_count, depot_count)
	ship_generator.generate(freighter_count)

	# Objekte für die Berechnung der Sektorgrenze registrieren.
	for station: StationAI in mines + depots:
		data.register_entity(station.data)
		station.tree_exiting.connect(
			data.unregister_entity.bind(station.data)
		)

	for ship: Ship in ships:
		data.register_entity(ship.data)
		ship.tree_exiting.connect(
			data.unregister_entity.bind(ship.data)
		)

	data.refresh_bounds()


func spawn_marker(
	scene: PackedScene,
	point: Vector2,
	entity_data: Resource = null
) -> Node2D:
	var marker := scene.instantiate() as Node2D

	assert(marker != null, "Marker-Szene muss Node2D sein.")

	marker.position = point

	# Daten setzen, bevor der Marker zum Szenenbaum kommt.
	if entity_data != null:
		marker.set("data", entity_data)

	add_child(marker)
	return marker

func random_sector_position() -> Vector2:
	var point: Vector3 = data.random_spawn_position()
	return Vector2(point.x, point.z)
