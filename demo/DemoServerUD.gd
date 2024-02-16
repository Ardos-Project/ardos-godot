class_name DemoServerUD extends ServerRepository

var auth_mgr: AuthMgrUD = null


func _init(
	dc_file_names: PackedStringArray = [],
	suffix: String = "",
	min_channel: int = 0,
	max_channel: int = 0
):
	super._init(dc_file_names, suffix, min_channel, max_channel)


func _handle_connected():
	super._handle_connected()

	# Set our connection name with Ardos.
	self.set_con_name("DemoClientUD")

	self._create_globals()


## Create Uberdog "singleton" distributed objects.
func _create_globals():
	# Generate the auth manager.
	auth_mgr = self.generate_global_object(4665, "AuthMgr")
