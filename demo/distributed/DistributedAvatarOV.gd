class_name DistributedAvatarOV extends DistributedAvatar

@onready var _pickNameContainer = get_node("/root/Root/UI/PickNameContainer")


func _ready():
	super._ready()

	# Reparent the local camera.
	get_tree().get_first_node_in_group("local_camera").reparent(_avatar_model)

	# We could do this in AuthMgrUD acceptLogin() function,
	# but we just do that here.
	_pickNameContainer.visible = false
