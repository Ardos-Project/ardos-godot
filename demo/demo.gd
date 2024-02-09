extends Node3D


var _client: bool = true


# Called when the node enters the scene tree for the first time.
func _ready():
	if self._client:
		var _cr = DemoClient.new(["data/dclass/demo.dc"])
		_cr.name = "ClientRepository"
		add_child(_cr)

		_cr.connect_to_server("127.0.0.1", 6667, "godot-demo")
	else:
		var _ud = DemoServerUD.new(["data/dclass/demo.dc"])
		_ud.name = "DemoServerUD"
		add_child(_ud)
		
		_ud.connect_to_server("127.0.0.1", 7100)
