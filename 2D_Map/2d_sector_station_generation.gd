extends Node

@export var depot_scene: PackedScene
@export var depot_marker_scene: PackedScene
@export var mining_station_scene: PackedScene
@export var mining_station_marker_scene: PackedScene

@onready var sector: Sector = get_parent() as Sector

func create_station(scene: PackedScene, station_name: String, marker_scene: PackedScene) -> StationAI:
	var station := scene.instantiate() as StationAI
	assert(station != null, "Stationsszene braucht station_ai.gd am Root; hier keine Marker-Szene zuweisen.")
	station.name = station_name
	if station.data == null:
		station.data = StationData.new()
	else:
		station.data = station.data.duplicate(true) as StationData

	var point: Vector2 = random_station_position()
	station.data.position = Vector3(point.x, 0.0, point.y)
	station.data.landing_position = station.data.position
	if marker_scene != null:
		sector.spawn_marker(marker_scene, point)
	return station


func random_station_position() -> Vector2:
	var point: Vector2 = sector.random_sector_position()
	for attempt: int in range(40):
		var separated: bool = true
		for other: Vector2 in sector.station_points:
			if point.distance_to(other) < 150.0:
				separated = false
				break
		if separated:
			break
		point = sector.random_sector_position()
	sector.station_points.append(point)
	return point

func generate(mine_count: int, depot_count: int) -> void:
	for index: int in range(mine_count):
		var mine: StationAI = create_station(
			mining_station_scene,
			"Mine_%d" % [index + 1],
			mining_station_marker_scene
		)

		sector.mines.append(mine)
		add_child(mine)

	for index: int in range(depot_count):
		var depot: StationAI = create_station(
			depot_scene,
			"Depot_%d" % [index + 1],
			depot_marker_scene
		)

		# Liefermine setzen, bevor die Depot-Logik startet.
		if not sector.mines.is_empty():
			depot.get_node("Job").set(
				"supply_station",
				sector.mines[index % sector.mines.size()]
			)

		sector.depots.append(depot)
		add_child(depot)
