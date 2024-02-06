extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	var _cr = ClientRepository.new(["data/dclass/demo.dc"])
	_cr.name = "ClientRepository"
	add_child(_cr)
