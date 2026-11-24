extends Node

enum State {
	IDLE,
	FLYING_TO_PICKUP,
	WAITING_FOR_PICKUP,
	FLYING_TO_DELIVERY,
	WAITING_FOR_SPACE,
	BLOCKED
}

@export var accepted_job_types: Array[StringName] = [&"hauling"]
@export_range(0.1, 3600.0) var job_check_interval: float = 2.0

var ai: ShipAI
var current_job: JobData
var state: State = State.IDLE
var retry_timer: Timer
@onready var job_board: Node = get_node("/root/JobBoard")


func initialize(controller: ShipAI) -> void:
	ai = controller
	ai.add_to_group("economy_ships")
	ai.arrived.connect(_on_arrived)

	# Vorhandene Ladung ohne zugeordneten Job darf nicht ueberschrieben werden.
	if ai.data.cargo_amount > 0:
		state = State.BLOCKED
		push_warning("Frachter: Zum ersten Test Cargo Amount auf 0 setzen.")
		return

	retry_timer = Timer.new()
	retry_timer.wait_time = maxf(job_check_interval, 0.1)
	add_child(retry_timer)
	retry_timer.timeout.connect(_on_retry_timeout)
	retry_timer.start()

	# Erst suchen, nachdem die Szene ihre anderen Objekte erzeugt hat.
	_look_for_job.call_deferred()


func _on_retry_timeout() -> void:
	match state:
		State.IDLE:
			_look_for_job()
		State.WAITING_FOR_PICKUP:
			_load_cargo()
		State.WAITING_FOR_SPACE:
			_unload_cargo()


func _look_for_job() -> void:
	if state != State.IDLE or current_job != null:
		return
	if ai.data.cargo_capacity <= 0:
		return

	# Das Board reserviert den aeltesten passenden Auftrag fuer diese ShipAI.
	current_job = job_board.take_job(accepted_job_types, ai)
	if current_job == null:
		return
	if not _stations_exist():
		return
	if current_job.get_remaining_amount() == 0:
		_finish_job()
		return

	print("Frachter nimmt Job: ", current_job.amount, " Einheiten ", current_job.ware_type)
	state = State.FLYING_TO_PICKUP
	_fly_to_target(current_job.target)


func _fly_to_target(target: StationAI) -> void:
	# Die Bewegung selbst bleibt in ShipAI und dem aktiven Simulationsmodus.
	ai.fly_to(target.data.position)


func _on_arrived() -> void:
	match state:
		State.FLYING_TO_PICKUP:
			_load_cargo()
		State.FLYING_TO_DELIVERY:
			_unload_cargo()


func _load_cargo() -> void:
	if not _stations_exist():
		return

	# Wie viel soll auf dieser Tour mitgenommen werden?
	var desired_load: int = mini(
		current_job.get_remaining_amount(),
		ai.data.cargo_capacity
	)

	# Bereits geladene Ware berücksichtigen.
	var missing: int = maxi(
		0,
		desired_load - ai.data.cargo_amount
	)

	var loaded: int = current_job.target.remove_ware(
		current_job.ware_type,
		missing
	)

	if loaded > 0:
		ai.data.cargo_type = current_job.ware_type
		ai.data.cargo_amount += loaded

		print(
			"Frachter lädt ",
			loaded,
			" Einheiten ",
			ai.data.cargo_type
		)

	# Noch nicht genug? An der Mine bleiben und später nachladen.
	if ai.data.cargo_amount < desired_load or ai.data.cargo_amount == 0:
		state = State.WAITING_FOR_PICKUP
		return

	state = State.FLYING_TO_DELIVERY
	_fly_to_target(current_job.next_target)

func _unload_cargo() -> void:
	if not _stations_exist():
		return

	var unloaded: int = current_job.next_target.add_ware(ai.data.cargo_type, ai.data.cargo_amount)
	ai.data.cargo_amount -= unloaded
	current_job.delivered_amount += unloaded
	if unloaded > 0:
		print("Frachter liefert ", unloaded, " Einheiten ", ai.data.cargo_type)

	# Passt nicht alles ins Depot, bleibt der Rest an Bord.
	if ai.data.cargo_amount > 0:
		state = State.WAITING_FOR_SPACE
		return

	ai.data.cargo_type = ""
	if current_job.get_remaining_amount() > 0:
		state = State.FLYING_TO_PICKUP
		_fly_to_target(current_job.target)
	else:
		_finish_job()


func _finish_job() -> void:
	if not job_board.complete_job(current_job, ai):
		state = State.BLOCKED
		push_warning("Frachter: Der Auftrag konnte nicht abgeschlossen werden.")
		return

	print("Frachter hat Job abgeschlossen: ", current_job.amount, " Einheiten ", current_job.ware_type)
	current_job = null
	state = State.IDLE
	_look_for_job.call_deferred()


func _stations_exist() -> bool:
	if is_instance_valid(current_job.target) and is_instance_valid(current_job.next_target):
		if current_job.target.data != null and current_job.next_target.data != null:
			return true

	# Bei entfernten Stationen pausieren. Vorhandene Ladung bleibt in ShipData.
	state = State.BLOCKED
	push_warning("Frachter: Eine Job-Station oder ihre StationData fehlt.")
	return false
