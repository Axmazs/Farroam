extends Node2D

const OVERLAY_SCRIPT := preload("economy_overlay.gd")

@export var sector_generator_scene: PackedScene
@export_range(1, 32) var sector_count: int = 3
@export_range(1.0, 1000.0) var sector_gap_km: float = 50.0

@onready var sector_camera: SectorCamera2D = $Camera2D

var sectors: Array[Sector] = []
var overlay: CanvasLayer
# Nur die zusammengefassten Kameragrenzen; kein weiterer Simulationssektor.
var view_bounds: SectorData
var draw_station_symbols: bool = false
var draw_ship_symbols: bool = false


func _ready() -> void:
	assert(sector_generator_scene != null, "Am Map-Root Sector Generator Scene zuweisen.")
	assert(sector_camera != null, "Camera2D braucht sector_camera_2d.gd.")
	process_priority = 100
	var old_border := get_node_or_null("SectorBorderSprite") as CanvasItem
	if old_border != null:
		old_border.hide()

	for index: int in range(sector_count):
		var generated := sector_generator_scene.instantiate() as Sector
		assert(generated != null, "Die Sektor-Szene braucht class_name Sector am Root.")
		generated.name = "Sector_%02d" % [index + 1]
		generated.add_to_group("economy_sectors")
		if generated.data == null:
			generated.data = SectorData.new()
		else:
			generated.data = generated.data.duplicate(true) as SectorData
		generated.data.sector_id = StringName(generated.name)
		# Feste Reihe, mit Abstand zwischen den anfaenglichen Kartenkreisen.
		var initial_radius_km: float = maxf(generated.data.minimum_map_radius_km, generated.data.spawn_radius_km + generated.data.border_padding_km)
		var spacing_m: float = (2.0 * initial_radius_km + sector_gap_km) * SectorData.METERS_PER_KM
		var wiggleroom_km: float = 200.0
		var galaxy_width_m: float = sqrt(float(sector_count)) * spacing_m + wiggleroom_km * SectorData.METERS_PER_KM
		var position_found: bool = false

		for attempt in range(300):
			var half_width_m: float = galaxy_width_m * 0.5

			var candidate: Vector3 = Vector3(
				randf_range(-half_width_m, half_width_m),
				0.0,
				randf_range(-half_width_m, half_width_m)
			)

			var position_free: bool = true

			for existing_sector: Sector in sectors:
				var distance_m: float = candidate.distance_to(existing_sector.data.center)

				if distance_m < spacing_m:
					position_free = false
					break

			if position_free:
				generated.data.center = candidate
				position_found = true
				break

			# Nach jeweils drei Fehlversuchen den Bereich vergrößern.
			if (attempt + 1) % 3 == 0:
				galaxy_width_m *= 1.25

		if not position_found:
			push_error("Keine freie Position für den Sektor gefunden.")
			generated.free()
			return
		
		add_child(generated)
		sectors.append(generated)
		name_sector_objects(generated)

		var station_generator: Node = generated.get_node("Stations")
		var ship_generator: Node = generated.get_node("Ships")
		draw_station_symbols = draw_station_symbols or station_generator.get("depot_marker_scene") == null or station_generator.get("mining_station_marker_scene") == null
		draw_ship_symbols = draw_ship_symbols or ship_generator.get("freighter_marker_scene") == null

	view_bounds = SectorData.new()
	for generated: Sector in sectors:
		view_bounds.center += generated.data.center / float(sectors.size())
	update_view_bounds()
	sector_camera.initialize(view_bounds, self)
	update_marker_scales()

	# Die gemeinsame Anzeige wird genau einmal erzeugt.
	overlay = OVERLAY_SCRIPT.new() as CanvasLayer
	overlay.set("map_root", self)
	overlay.set("draw_station_symbols", draw_station_symbols)
	overlay.set("draw_ship_symbols", draw_ship_symbols)
	add_child(overlay)
	sector_camera.economy_panel = overlay.get("panel") as PanelContainer

func name_sector_objects(generated: Sector) -> void:
	for station: StationAI in generated.mines + generated.depots:
		station.name = "%s_%s" % [generated.name, station.name]
	for ship: Ship in generated.ships:
		ship.name = "%s_%s" % [generated.name, ship.name]


func _process(_delta: float) -> void:
	if view_bounds == null:
		return
	for generated: Sector in sectors:
		generated.data.refresh_bounds()
	update_view_bounds()
	update_marker_scales()
	queue_redraw()


func update_view_bounds() -> void:
	var required: float = view_bounds.minimum_map_radius_km * SectorData.METERS_PER_KM
	for generated: Sector in sectors:
		required = maxf(required, generated.data.center.distance_to(view_bounds.center) + generated.data.map_radius_m)
	if required > view_bounds.map_radius_m:
		view_bounds.map_radius_m = required
		view_bounds.radius_changed.emit(required)


func update_marker_scales() -> void:
	var to_screen: Transform2D = get_global_transform_with_canvas()
	var screen_scale := Vector2(to_screen.x.length(), to_screen.y.length()).max(Vector2.ONE * 0.000001)
	for generated: Sector in sectors:
		# spawn_marker() legt sichtbare Marker direkt unter dem Sektor an.
		for child: Node in generated.get_children():
			if child is Node2D:
				var marker := child as Node2D
				if not marker.has_meta("map_base_scale"):
					marker.set_meta("map_base_scale", marker.scale)
				var base_scale: Vector2 = marker.get_meta("map_base_scale")
				marker.scale = base_scale / screen_scale


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				set_map_mode(false)
			KEY_2:
				set_map_mode(true)


func set_map_mode(map_open: bool) -> void:
	for generated: Sector in sectors:
		for ship: Ship in generated.ships:
			ship.ai.set_map_mode(map_open)
		for marker: Node2D in generated.markers:
			var ship_data: ShipData = marker.get("data")
			marker.position = Vector2(ship_data.position.x, ship_data.position.z)
			marker.set_process(map_open)
		for child: Node in generated.get_children():
			if child is Node2D:
				(child as Node2D).visible = map_open
	visible = map_open
	if overlay != null:
		overlay.visible = map_open


func _draw() -> void:
	var screen_scale: float = maxf(get_global_transform_with_canvas().x.length(), 0.000001)
	for generated: Sector in sectors:
		var point := Vector2(generated.data.center.x, generated.data.center.z)
		draw_arc(point, generated.data.map_radius_m, 0.0, TAU, 256, Color("d8edf4"), 2.0 / screen_scale, true)
