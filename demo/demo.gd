extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	var _cr = ClientRepository.new(["data/dclass/demo.dc"])
	_cr.name = "ClientRepository"
	add_child(_cr)

	_cr.connect_to_server("127.0.0.1", 6667, "godot-demo")
