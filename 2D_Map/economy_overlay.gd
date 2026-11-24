extends CanvasLayer

# Die Simulation schreibt Daten. Diese Anzeige liest sie nur.
@export var map_root: Node2D
@export var draw_station_symbols: bool = false
@export var draw_ship_symbols: bool = false
@export var hover_radius: float = 28.0

class MarkerCanvas extends Control:
	var overlay: Node
	func _draw() -> void:
		overlay.draw_world_status(self)

var stations: Array[Node] = []
var ships: Array[Node] = []
var marker_canvas: MarkerCanvas
var panel: PanelContainer
var info: Label
var jobs_text: Label
var fleet_text: Label
var tooltip: PanelContainer
var tooltip_text: Label
var ui_root: Control
var job_board: Node
var hovered_station: StationAI


func _ready() -> void:
	
	
	layer = 20
	if map_root == null:
		map_root = get_parent() as Node2D
	job_board = get_node_or_null("/root/JobBoard")

	ui_root = Control.new()
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui_root)
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	marker_canvas = MarkerCanvas.new()
	marker_canvas.overlay = self
	marker_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(marker_canvas)
	marker_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	panel = make_panel()
	panel.custom_minimum_size.x = 350.0
	ui_root.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	scroll.add_child(box)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = "WIRTSCHAFT / LIVE"
	title.add_theme_font_size_override("font_size", 20)
	box.add_child(title)
	info = Label.new()
	box.add_child(info)
	box.add_child(HSeparator.new())
	
	var jobs_button := Button.new()
	jobs_button.text = "JOBBOARD"
	jobs_button.toggle_mode = true
	jobs_button.button_pressed = false
	box.add_child(jobs_button)
	jobs_text = Label.new()
	jobs_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(jobs_text)
	jobs_text.hide()
	jobs_button.toggled.connect(jobs_text.set_visible)
	
	var fleet_button := Button.new()
	fleet_button.text = "FRACHTER"
	fleet_button.toggle_mode = true
	fleet_button.button_pressed = false
	box.add_child(fleet_button)
	fleet_text = Label.new()
	fleet_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(fleet_text)
	fleet_text.hide()
	fleet_button.toggled.connect(fleet_text.set_visible)
	
	tooltip = make_panel()
	tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(tooltip)
	tooltip_text = Label.new()
	tooltip_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip.add_child(tooltip_text)
	tooltip.hide()
	
	

	var timer := Timer.new()
	timer.wait_time = 0.25
	add_child(timer)
	timer.timeout.connect(_refresh)
	timer.start()
	_refresh()


func make_panel() -> PanelContainer:
	var result := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("142332f2")
	style.border_color = Color("446079")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	result.add_theme_stylebox_override("panel", style)
	return result


func _refresh() -> void:
	stations = get_tree().get_nodes_in_group("economy_stations")
	ships = get_tree().get_nodes_in_group("economy_ships")
	info.text = "%d Stationen   |   %d Frachter\nMaus: Stationsbestand | B: Panel" % [stations.size(), ships.size()]
	var lines: PackedStringArray = []
	if job_board == null:
		lines.append("Autoload /root/JobBoard fehlt.")
	else:
		var jobs: Array = job_board.get("jobs")
		if jobs.is_empty():
			lines.append("Keine offenen Auftraege")
		for index: int in range(mini(jobs.size(), 6)):
			var job: JobData = jobs[index]
			var worker: String = "frei"
			if is_instance_valid(job.assigned_to):
				worker = worker_name(job.assigned_to)
			var status_text: String = "offen" if job.status == &"open" else "angenommen"
			lines.append("%d. %s | %s | %s" % [index + 1, job.job_type, job.ware_type, status_text])
			lines.append("%s -> %s" % [station_name(job.target), station_name(job.next_target)])
			lines.append("%d/%d geliefert | %s\n" % [job.delivered_amount, job.amount, worker])
		if jobs.size() > 6:
			lines.append("... und %d weitere" % [jobs.size() - 6])
	jobs_text.text = "\n".join(lines)

	lines = []
	for ship: Node in ships:
		var data: ShipData = ship.get("data")
		lines.append("%s | %d/%d %s" % [worker_name(ship), data.cargo_amount, data.cargo_capacity, data.cargo_type])
		var role: Node = ship.get_node_or_null("Job")
		if role != null:
			var names: PackedStringArray = ["Sucht Job", "Zur Abholung", "Wartet auf Ware / Platz", "Zur Lieferung", "Wartet auf Lagerplatz", "Pausiert"]
			var state_id: int = role.get("state")
			if state_id >= 0 and state_id < names.size():
				lines.append("  " + names[state_id])
	fleet_text.text = "\n".join(lines)


func _process(_delta: float) -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	panel.position = Vector2(maxf(8.0, viewport_size.x - 366.0), 16.0)
	panel.size.y = maxf(viewport_size.y - 32.0, 0.0)
	marker_canvas.queue_redraw()
	hovered_station = null
	var mouse: Vector2 = get_viewport().get_mouse_position()
	if not panel.visible or not panel.get_global_rect().has_point(mouse):
		var nearest: float = hover_radius
		for node: Node in stations:
			if not is_instance_valid(node):
				continue
			var station := node as StationAI
			var distance: float = screen_position(station.data.position).distance_to(mouse)
			if distance < nearest:
				nearest = distance
				hovered_station = station
	tooltip.visible = hovered_station != null
	if hovered_station == null:
		return

	var lines: PackedStringArray = [str(hovered_station.name), "Typ: " + hovered_station.data.station_type]
	for ware: String in hovered_station.data.stock:
		lines.append("%s: %d" % [ware, hovered_station.get_stock(ware)])
	lines.append("Lager: %d/%d" % [hovered_station.data.get_cargo_amount(), hovered_station.data.cargo_capacity])
	var role: Node = hovered_station.get_node_or_null("Job")
	if role != null and role.has_method("get_activity_text"):
		lines.append(role.get_activity_text())
	tooltip_text.text = "\n".join(lines)
	var tooltip_size: Vector2 = tooltip.get_combined_minimum_size()
	tooltip.position = (mouse + Vector2(18, 18)).clamp(Vector2.ZERO, (viewport_size - tooltip_size - Vector2(8, 8)).max(Vector2.ZERO))


func screen_position(world_position: Vector3) -> Vector2:
	if map_root == null:
		return Vector2(world_position.x, world_position.z)
	return map_root.get_global_transform_with_canvas() * Vector2(world_position.x, world_position.z)


func draw_world_status(canvas: Control) -> void:
	var font: Font = ThemeDB.fallback_font
	if draw_station_symbols:
		for node: Node in stations:
			if not is_instance_valid(node):
				continue
			var station := node as StationAI
			var point: Vector2 = screen_position(station.data.position)
			var color := Color("f9ce58") if station.data.station_type == "mining_station" else Color("b6e8f4")
			canvas.draw_arc(point, 16.0, 0.0, TAU, 32, color, 2.0, true)
			canvas.draw_line(point - Vector2(22, 0), point + Vector2(22, 0), color, 2.0, true)
			canvas.draw_line(point - Vector2(0, 22), point + Vector2(0, 22), color, 2.0, true)
			canvas.draw_string(font, point + Vector2(-60, 38), str(station.name), HORIZONTAL_ALIGNMENT_CENTER, 120, 14, color)
	for ship: Node in ships:
		if not is_instance_valid(ship):
			continue
		var data: ShipData = ship.get("data")
		var point: Vector2 = screen_position(data.position)
		if draw_ship_symbols:
			canvas.draw_colored_polygon(PackedVector2Array([point + Vector2(10, 0), point + Vector2(-8, -7), point + Vector2(-5, 0), point + Vector2(-8, 7)]), Color("72dec4"))
		var rect := Rect2(point + Vector2(-25, -25), Vector2(50, 5))
		canvas.draw_rect(rect, Color("10202e"))
		var ratio: float = clampf(float(data.cargo_amount) / maxf(float(data.cargo_capacity), 1.0), 0.0, 1.0)
		canvas.draw_rect(Rect2(rect.position, Vector2(rect.size.x * ratio, rect.size.y)), Color("72dec4"))
		canvas.draw_rect(rect, Color("a1b9c6"), false, 1.0)
		canvas.draw_string(font, point + Vector2(-35, -32), "%d/%d" % [data.cargo_amount, data.cargo_capacity], HORIZONTAL_ALIGNMENT_CENTER, 70, 12, Color.WHITE)


func worker_name(worker: Node) -> String:
	if worker.get_parent() != null:
		return str(worker.get_parent().name)
	return str(worker.name)


func station_name(station: StationAI) -> String:
	return str(station.name) if is_instance_valid(station) else "Station fehlt"


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_B:
		panel.visible = not panel.visible
		get_viewport().set_input_as_handled()
