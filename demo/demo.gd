extends Node3D

const DC_FILES: PackedStringArray = ["data/dclass/demo.dc"]


# Called when the node enters the scene tree for the first time.
func _ready():
	if DisplayServer.get_name() == "headless":
		# We're running as a headless server.

		# Fetch the base channel we've been allocated.
		var base_channel: int = int(self._get_cmdline_arg("air-base-channel", "400000000"))
		# Fetch the number of channels we've been allocated.
		var channel_alloc: int = int(self._get_cmdline_arg("air-channel-allocation", "1000000"))
		# Fetch the State Server we've been allocated.
		var stateserver_id: int = int(self._get_cmdline_arg("air-channel-allocation", "1001"))
		# Fetch the Message Director host address.
		var md_host: String = self._get_cmdline_arg("air-connect", "127.0.0.1")

		if "--ud" in OS.get_cmdline_user_args():
			var _cls = load("res://demo/DemoServerUD.gd")

			var _ud = _cls.new(
				DC_FILES, "UD", base_channel, base_channel + channel_alloc, stateserver_id
			)
			_ud.name = "DemoServerUD"
			add_child(_ud)

			_ud.connect_to_server(md_host, 7199)

		elif "--ai" in OS.get_cmdline_user_args():
			var _cls = load("res://demo/DemoServerAI.gd")

			var _ai = _cls.new(
				DC_FILES, "AI", base_channel, base_channel + channel_alloc, stateserver_id
			)
			_ai.name = "DemoServerAI"
			add_child(_ai)

			_ai.connect_to_server(md_host, 7199)
	else:
		# We're running as a client.
		var _cls = load("res://demo/DemoClient.gd")

		var _cr = _cls.new(DC_FILES)
		_cr.name = "ClientRepository"
		add_child(_cr)

		_cr.connect_to_server("127.0.0.1", 6667, "godot-demo")


func _get_cmdline_arg(arg_name: String, default: String = "") -> String:
	# Fetch the value from the cmd line.
	var indx: int = OS.get_cmdline_user_args().find(arg_name)
	if indx != -1:
		return OS.get_cmdline_user_args()[indx + 1]

	# If it doesn't exist, try get it as an environment variable.
	var env_var: String = OS.get_environment(arg_name)
	return env_var if env_var != "" else default
