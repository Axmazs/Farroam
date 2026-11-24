extends Camera2D

const ZOOM_STEP := 1.2

@export var closest_view_size := 300.0
@onready var sector_border: Sprite2D = $"../SectorBorderSprite"

var bounds: Rect2
var sector_center: Vector2
var zoom_out_limit: float
var zoom_in_limit: float


func _ready() -> void:
	fit_sector()
	get_viewport().size_changed.connect(fit_sector)


func fit_sector() -> void:
	bounds = sector_border.global_transform * sector_border.get_rect()
	var viewport_size := get_viewport_rect().size
	sector_center = bounds.get_center()

	zoom_out_limit = minf(
		viewport_size.x / bounds.size.x,
		viewport_size.y / bounds.size.y
	) * 0.95
	var short_side := minf(viewport_size.x, viewport_size.y)
	zoom_in_limit = maxf(zoom_out_limit, short_side / maxf(closest_view_size, 1.0))

	global_position = sector_center
	zoom = Vector2.ONE * zoom_out_limit


func _unhandled_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion != null and (motion.button_mask & MOUSE_BUTTON_MASK_MIDDLE) != 0:
		global_position -= motion.relative / zoom.x
		clamp_to_sector()
		get_viewport().set_input_as_handled()
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or not mouse_event.pressed:
		return

	var new_zoom := zoom.x
	match mouse_event.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			new_zoom *= ZOOM_STEP
		MOUSE_BUTTON_WHEEL_DOWN:
			new_zoom /= ZOOM_STEP
		_:
			return

	new_zoom = clampf(new_zoom, zoom_out_limit, zoom_in_limit)
	var mouse_offset := mouse_event.position - get_viewport_rect().size * 0.5
	global_position += mouse_offset * (1.0 / zoom.x - 1.0 / new_zoom)
	zoom = Vector2.ONE * new_zoom
	clamp_to_sector()
	get_viewport().set_input_as_handled()

	if is_equal_approx(new_zoom, zoom_out_limit):
		global_position = sector_center

	get_viewport().set_input_as_handled()


func clamp_to_sector() -> void:
	var half_view := get_viewport_rect().size * 0.5 / zoom.x
	var half_sector := bounds.size * 0.5
	var max_offset := (half_sector - half_view).max(Vector2.ZERO)
	var offset := (global_position - sector_center).clamp(-max_offset, max_offset)
	var radius := minf(half_sector.x, half_sector.y)
	global_position = sector_center + offset.limit_length(radius)
