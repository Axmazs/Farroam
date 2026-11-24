extends Node

@export var ware_type: String = "ore"
@export_range(1, 10000) var production_amount: int = 10
@export_range(0.1, 3600.0) var production_interval: float = 2.0

var station: StationAI
var production_timer: Timer
var total_produced: int = 0


func initialize(controller: StationAI) -> void:
	station = controller
	production_timer = Timer.new()
	production_timer.wait_time = maxf(production_interval, 0.1)
	add_child(production_timer)
	production_timer.timeout.connect(_produce)
	production_timer.start()


func _produce() -> void:
	# add_ware begrenzt die tatsaechliche Produktion auf den freien Lagerplatz.
	total_produced += station.add_ware(ware_type, production_amount)


func get_activity_text() -> String:
	return "Produktion: +%d %s / %.1f s" % [production_amount, ware_type, production_interval]
