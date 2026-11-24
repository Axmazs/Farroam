extends Node

# Bedarfsmeldung wird in _on_supply_needed in einen Transportjob umgewandelt.
signal supply_needed(ware_type: String, amount: int)

@export var supply_station: StationAI
@export_range(0.1, 3600.0) var check_interval: float = 5.0
@export var minimum_stock: Dictionary[String, int] = {
	"ore": 20,
	"food": 10
}

var station: StationAI
var check_timer: Timer
# Pro Warenart hoechstens ein offener oder angenommener Auftrag dieses Depots.
var pending_jobs: Dictionary[String, JobData] = {}


func initialize(controller: StationAI) -> void:
	station = controller
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
	for ware_type in minimum_stock:
		var missing: int = minimum_stock[ware_type] - station.get_stock(ware_type)
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

	if JobBoard.post_job(new_job):
		pending_jobs[ware_type] = new_job
		print("Depot hat Transportjob gepostet: ", amount, " Einheiten ", ware_type)
