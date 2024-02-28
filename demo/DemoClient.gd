class_name DemoClient extends ClientRepository

static var INSTANCE: DemoClient = null
static var local_avatar: DistributedAvatarOV = null

@onready var _connecting_container = get_node("/root/Root/UI/ConnectingContainer")
@onready var _pick_name_container = get_node("/root/Root/UI/PickNameContainer")
@onready var _shard_container = get_node("/root/Root/UI/ShardContainer")
@onready var _submit_name_button = get_node("/root/Root/UI/PickNameContainer/VBoxContainer/Button")
@onready var _username_input = get_node("/root/Root/UI/PickNameContainer/VBoxContainer/LineEdit")

var auth_mgr: AuthMgr = null


func _init(dc_file_names: PackedStringArray = [], suffix: String = ""):
	super._init(dc_file_names, suffix)

	self.INSTANCE = self


func _handle_connected():
	super._handle_connected()

	self._create_globals()

	_connecting_container.visible = false
	_pick_name_container.visible = true

	_submit_name_button.pressed.connect(self._submit_username)


## Create client-side view of Uberdog "singleton" distributed objects.
func _create_globals():
	# Generate the auth manager.
	auth_mgr = self.generate_global_object(4665, "AuthMgr")


## Called by DistributedAvatarOV once it's been generated.
func _handle_local_av():
	# We could do this in AuthMgrUD acceptLogin() function,
	# but just do it here for simplicity.
	self._pick_name_container.visible = false
	self._shard_container.visible = true

	# Set interest in the global "management" zone.
	# This is where we've generated DistributedDistrict objects from the Ai.
	self.add_interest(
		self.get_game_do_id(), [2], "Global Management", Callable(self._handle_management_zone)
	)


## Interest has been succesfully set in the global management zone.
func _handle_management_zone():
	print(DistributedDistrict.DISTRICTS.size())


func _submit_username():
	if not _username_input.text:
		return

	_submit_name_button.disabled = true

	auth_mgr.login(_username_input.text)
