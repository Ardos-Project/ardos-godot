class_name DemoClient extends ClientRepository

var auth_mgr: AuthMgr = null


func _init(dc_file_names: PackedStringArray = [], suffix: String = ""):
	super._init(dc_file_names, suffix)


func _handle_connected():
	super._handle_connected()

	self._create_globals()


## Create client-side view of Uberdog "singleton" distributed objects.
func _create_globals():
	# Generate the auth manager.
	auth_mgr = self.generate_global_object(4665, "AuthMgr")
