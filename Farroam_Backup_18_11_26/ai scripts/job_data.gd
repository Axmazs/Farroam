class_name JobData
extends Resource

@export var job_type: StringName = &"hauling"
@export var ware_type: String = "ore"
@export var amount: int = 0



# Erst bei target abholen, dann bei next_target abliefern.
# Referenzen auf die logischen Stationen, nicht auf deren Marker.
var target: StationAI
var next_target: StationAI

var status: StringName = &"open"
var assigned_to: Node

# amount bleibt die urspruenglich bestellte Menge.
var delivered_amount: int = 0


func get_remaining_amount() -> int:
	return maxi(0, amount - delivered_amount)
