extends Node

# Bedarfsmeldung wird in _on_supply_needed in einen Transportjob umgewandelt.
signal supply_needed(ware_type: String, amount: int)

@export var supply_station: StationAI
@export_range(0.1, 3600.0) var check_interval: float = 5.0
@export var minimum_stock: Dictionary[String, int] = {
	"ore": 30
}

@export var target_stock: Dictionary[String, int] = {
	"ore": 90
}

# Je Verbrauchsschritt werden diese Mengen entnommen.
@export var consumption_per_tick: Dictionary[String, int] = {"ore": 4}
@export_range(0.1, 3600.0) var consumption_interval: float = 3.0

var station: StationAI
var check_timer: Timer
var consumption_timer: Timer
var total_consumed: int = 0
@onready var job_board: Node = get_node("/root/JobBoard")
# Pro Warenart hoechstens ein offener oder angenommener Auftrag dieses Depots.
var pending_jobs: Dictionary[String, JobData] = {}


func initialize(controller: StationAI) -> void:
	station = controller
	consumption_timer = Timer.new()
	consumption_timer.wait_time = maxf(consumption_interval, 0.1)
	add_child(consumption_timer)
	consumption_timer.timeout.connect(_consume_stock)
	consumption_timer.start()

	if supply_station == null or supply_station == station:
		push_warning("Depot: Am Job-Node eine andere Station als Supply Station zuweisen.")
		return

	# Vor der ersten Bestandspruefung verbinden, damit keine Meldung verloren geht.
	supply_needed.connect(_on_supply_needed)
	check_timer = Timer.new()
	check_timer.wait_time = maxf(check_interval, 0.1)
	add_child(check_timer)
	check_timer.timeout.connect(_check_stock)
	check_timer.start()
	_check_stock()


func _check_stock() -> void:
	for ware_type: String in minimum_stock:
		var current: int = station.get_stock(ware_type)

		if current >= minimum_stock[ware_type]:
			continue

		var desired: int = target_stock.get(
			ware_type,
			minimum_stock[ware_type]
		)

		var missing: int = maxi(0, desired - current)

		# Die Bestellung muss ins gemeinsame Lager passen.
		missing = mini(missing, station.get_free_capacity())

		if missing > 0:
			supply_needed.emit(ware_type, missing)


func _on_supply_needed(ware_type: String, amount: int) -> void:
	var existing: JobData = pending_jobs.get(ware_type)
	if existing != null:
		if existing.status == &"open" or existing.status == &"reserved":
			return

	var new_job := JobData.new()
	new_job.job_type = &"hauling"
	new_job.ware_type = ware_type
	new_job.amount = amount
	new_job.target = supply_station
	new_job.next_target = station

	if job_board.post_job(new_job):
		pending_jobs[ware_type] = new_job
		print("Depot hat Transportjob gepostet: ", amount, " Einheiten ", ware_type)


func _consume_stock() -> void:
	for ware_type: String in consumption_per_tick:
		total_consumed += station.remove_ware(ware_type, consumption_per_tick[ware_type])
	# Bedarf direkt nach dem Verbrauch pruefen, sobald die Versorgung konfiguriert ist.
	if check_timer != null:
		_check_stock()


func get_activity_text() -> String:
	var parts: PackedStringArray = []
	for ware_type: String in consumption_per_tick:
		parts.append("%d %s" % [consumption_per_tick[ware_type], ware_type])
	return "Verbrauch: %s / %.1f s" % [", ".join(parts), consumption_interval]
