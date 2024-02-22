class_name DemoClient extends ClientRepository

@onready var _connectingContainer = get_node("/root/Root/UI/ConnectingContainer")
@onready var _pickNameContainer = get_node("/root/Root/UI/PickNameContainer")
@onready var _submitNameButton = get_node("/root/Root/UI/PickNameContainer/VBoxContainer/Button")
@onready var _usernameInput = get_node("/root/Root/UI/PickNameContainer/VBoxContainer/LineEdit")

var auth_mgr: AuthMgr = null


func _init(dc_file_names: PackedStringArray = [], suffix: String = ""):
	super._init(dc_file_names, suffix)


func _handle_connected():
	super._handle_connected()

	self._create_globals()

	_connectingContainer.visible = false
	_pickNameContainer.visible = true

	_submitNameButton.pressed.connect(self._submit_username)


## Create client-side view of Uberdog "singleton" distributed objects.
func _create_globals():
	# Generate the auth manager.
	auth_mgr = self.generate_global_object(4665, "AuthMgr")


func _submit_username():
	if not _usernameInput.text:
		return

	_submitNameButton.disabled = true

	auth_mgr.login(_usernameInput.text)
