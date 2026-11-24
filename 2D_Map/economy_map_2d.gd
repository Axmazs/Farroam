extends Node2D

# economy_overlay.gd muss im selben Ordner wie dieses Skript liegen.
const OVERLAY_SCRIPT := preload("economy_overlay.gd")

# Logische Objekte und sichtbare Marker werden getrennt erzeugt.
@export var sector_generator_scene: PackedScene
@export var sector_count: int = 3
var sectors: Array[Sector] = []
var overlay: CanvasLayer

func _ready() -> void:



	overlay = OVERLAY_SCRIPT.new() as CanvasLayer
	overlay.set("map_root", self)
	# Ohne Marker-Szenen zeichnet die Anzeige einfache Symbole als Ersatz.
	overlay.set("draw_station_symbols", depot_marker_scene == null or mining_station_marker_scene == null)
	overlay.set("draw_ship_symbols", freighter_marker_scene == null)
	add_child(overlay)




func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				set_map_mode(false)
			KEY_2:
				set_map_mode(true)


func set_map_mode(map_open: bool) -> void:
	for ship: Ship in ships:
		ship.ai.set_map_mode(map_open)
	for marker: Node2D in markers:
		var data: ShipData = marker.get("data")
		marker.position = Vector2(data.position.x, data.position.z)
		marker.set_process(map_open)
	visible = map_open
	overlay.visible = map_open


func random_station_position() -> Vector2:
	var point: Vector2 = random_sector_position()
	for attempt: int in range(40):
		var separated: bool = true
		for other: Vector2 in station_points:
			if point.distance_to(other) < 150.0:
				separated = false
				break
		if separated:
			break
		point = random_sector_position()
	station_points.append(point)
	return point


func random_sector_position() -> Vector2:
	var bounds: Rect2 = sector_border.get_rect()
	var radius: float = minf(bounds.size.x, bounds.size.y) * 0.45
	var angle: float = randf_range(0.0, TAU)
	var distance: float = sqrt(randf()) * radius
	var point: Vector2 = bounds.get_center() + Vector2.from_angle(angle) * distance
	return sector_border.transform * point
