class_name DemoServerUD extends ServerRepository

var auth_mgr: AuthMgrUD = null


func _init(
	dc_file_names: PackedStringArray = [],
	suffix: String = "",
	min_channel: int = 0,
	max_channel: int = 0
):
	super._init(dc_file_names, suffix, min_channel, max_channel)

	self.set_game_do_id(4619)


func _handle_connected():
	super._handle_connected()

	# Set our connection name with Ardos.
	self.set_con_name("DemoClientUD")

	# Root parent object for all AI distributed objects.
	# Generated with the fairies game id.
	var root_obj: DistributedObjectAI = DistributedObjectAI.new()
	root_obj.generate_with_required_and_id(self.get_game_do_id(), 0, 0)

	self._create_globals()

	print("UberDOG online!")


## Create Uberdog "singleton" distributed objects.
func _create_globals():
	# Generate the auth manager.
	auth_mgr = self.generate_global_object(4665, "AuthMgr")
