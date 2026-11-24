class_name ShipData
extends Resource

@export var cargo_capacity: int = 100
@export var speed: float = 3000.0
@export var cargo_amount: int = 0
@export var cargo_type: String = ""

var position := Vector3.ZERO
var destination := Vector3.ZERO

var departure_position := Vector3.ZERO
var departure_time := 0.0
var arrival_time := 0.0
