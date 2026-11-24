class_name SectorCamera2D
extends Camera2D

const ZOOM_STEP: float = 1.2

@export_range(0.1, 1000.0) var closest_view_size_km: float = 5.0

var sector: SectorData
var view_root: Node2D
var zoom_out_limit: float = 1.0
var zoom_in_limit: float = 1.0
var following_overview: bool = true

var economy_panel: PanelContainer



func _ready() -> void:
	get_viewport().size_changed.connect(fit_sector)


func initialize(sector_data: SectorData, map_root: Node2D) -> void:
	sector = sector_data
	view_root = map_root
	sector.radius_changed.connect(_on_radius_changed)
	fit_sector()


func fit_sector() -> void:
	if sector == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var radius: float = maxf(sector.map_radius_m * root_scale(), 1.0)
	zoom_out_limit = minf(viewport_size.x, viewport_size.y) / (2.0 * radius) * 0.92
	zoom_in_limit = maxf(zoom_out_limit, minf(viewport_size.x, viewport_size.y) / (closest_view_size_km * SectorData.METERS_PER_KM * root_scale()))
	if following_overview:
		global_position = sector_center()
		zoom = Vector2.ONE * zoom_out_limit
	else:
		zoom = Vector2.ONE * clampf(zoom.x, zoom_out_limit, zoom_in_limit)
		clamp_to_sector()
	force_update_scroll()


func _on_radius_changed(_radius_m: float) -> void:
	fit_sector()


func sector_center() -> Vector2:
	return view_root.to_global(Vector2(sector.center.x, sector.center.z))


func root_scale() -> float:
	return maxf(maxf(absf(view_root.global_scale.x), absf(view_root.global_scale.y)), 0.001)


func _unhandled_input(event: InputEvent) -> void:
	if sector == null:
		return
	var motion := event as InputEventMouseMotion
	if motion != null and (motion.button_mask & MOUSE_BUTTON_MASK_MIDDLE) != 0:
		global_position -= motion.relative / zoom.x
		clamp_to_sector()
		following_overview = is_equal_approx(zoom.x, zoom_out_limit) and global_position.is_equal_approx(sector_center())
		get_viewport().set_input_as_handled()
		return

	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or not mouse_event.pressed:
		return
	var new_zoom: float = zoom.x
	match mouse_event.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			new_zoom *= ZOOM_STEP
		MOUSE_BUTTON_WHEEL_DOWN:
			new_zoom /= ZOOM_STEP
		_:
			return
	new_zoom = clampf(new_zoom, zoom_out_limit, zoom_in_limit)
	var mouse_offset: Vector2 = mouse_event.position - get_viewport_rect().size * 0.5
	global_position += mouse_offset * (1.0 / zoom.x - 1.0 / new_zoom)
	zoom = Vector2.ONE * new_zoom
	following_overview = is_equal_approx(new_zoom, zoom_out_limit)
	if following_overview:
		global_position = sector_center()
	else:
		clamp_to_sector()
	force_update_scroll()
	get_viewport().set_input_as_handled()


func clamp_to_sector() -> void:
	var radius: float = sector.map_radius_m * root_scale()
	var half_view: Vector2 = get_viewport_rect().size * 0.5 / zoom.x
	var max_offset: Vector2 = (Vector2.ONE * radius - half_view).max(Vector2.ZERO)
	
	var panel_space: float = 0.0
	if economy_panel != null and economy_panel.is_visible_in_tree():
		panel_space = (economy_panel.size.x + 5.0) / zoom.x
	
	var offset: Vector2 = (global_position - sector_center()).clamp(
		-max_offset,
		max_offset + Vector2(panel_space, 0.0)
	)
	global_position = sector_center() + offset
