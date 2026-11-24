class_name SectorData
extends Resource

signal radius_changed(radius_m: float)

const METERS_PER_KM: float = 1000.0

@export var sector_id: StringName = &"sector_01"
@export var center: Vector3 = Vector3.ZERO
@export_range(1.0, 10000.0) var minimum_map_radius_km: float = 60.0
@export_range(1.0, 10000.0) var spawn_radius_km: float = 120.0
@export_range(0.1, 1000.0) var border_padding_km: float = 10.0

var map_radius_m: float = 0.0
var entities: Array[Resource] = []


func register_entity(data: Resource) -> void:
	assert(data != null and data.get("position") is Vector3, "Sektorobjekt braucht eine Resource mit position: Vector3.")
	if not entities.has(data):
		entities.append(data)


func unregister_entity(data: Resource) -> void:
	entities.erase(data)


func refresh_bounds() -> void:
	# Die Karte waechst nur: bewegte Objekte lassen sie nicht staendig schrumpfen.
	var required: float = maxf(map_radius_m, minimum_map_radius_km * METERS_PER_KM)
	for data: Resource in entities:
		var point: Vector3 = data.get("position")
		required = maxf(required, point.distance_to(center) + border_padding_km * METERS_PER_KM)
	if required > map_radius_m:
		map_radius_m = required
		radius_changed.emit(map_radius_m)


func random_spawn_position() -> Vector3:
	# Gleichmaessig ueber die gesamte Flaeche verteilen, inklusive innerer 60 km.
	var angle: float = randf_range(0.0, TAU)
	var distance: float = sqrt(randf()) * spawn_radius_km * METERS_PER_KM
	return center + Vector3(cos(angle), 0.0, sin(angle)) * distance
