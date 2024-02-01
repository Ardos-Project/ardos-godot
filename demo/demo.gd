extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	var cr = ConnectionRepository.new()
	cr.read_dc_file(["data/demo.dc"])
