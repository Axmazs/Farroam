class_name StationAI
extends Node

signal stock_changed

@export var data: StationData
@onready var job: Node = get_node_or_null("Job")


func _ready() -> void:
	add_to_group("economy_stations")
	if data == null:
		data = StationData.new()

	# Die allgemeine Stationsszene darf einen leeren Job-Node haben.
	if job != null and job.has_method("initialize"):
		job.initialize(self)


func get_stock(ware_type: String) -> int:
	return data.stock.get(ware_type, 0)


func get_free_capacity() -> int:
	return maxi(0, data.cargo_capacity - data.get_cargo_amount())


# Gibt zurueck, wie viele Einheiten tatsaechlich eingelagert wurden.
func add_ware(ware_type: String, amount: int) -> int:
	if amount <= 0:
		return 0

	var added: int = mini(amount, get_free_capacity())
	if added > 0:
		data.stock[ware_type] = get_stock(ware_type) + added
		stock_changed.emit()
	return added


# Gibt zurueck, wie viele Einheiten tatsaechlich entnommen wurden.
func remove_ware(ware_type: String, amount: int) -> int:
	if amount <= 0:
		return 0

	var removed: int = mini(amount, get_stock(ware_type))
	if removed > 0:
		data.stock[ware_type] = get_stock(ware_type) - removed
		stock_changed.emit()
	return removed
