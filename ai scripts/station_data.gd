class_name StationData
extends Resource

@export var station_type: String = "depot"
@export var cargo_capacity: int = 100

# Warenname -> vorhandene Menge. Alle Waren teilen sich cargo_capacity.
@export var stock: Dictionary[String, int] = {
	"ore": 0,
	"food": 0
}

# Beide Positionen sind Weltkoordinaten.
@export var position: Vector3 = Vector3.ZERO
@export var landing_position: Vector3 = Vector3.ZERO


func get_cargo_amount() -> int:
	var total: int = 0
	for amount: int in stock.values():
		total += amount
	return total
