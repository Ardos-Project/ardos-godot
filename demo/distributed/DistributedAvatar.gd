class_name DistributedAvatar extends DistributedNode

const AVATAR_INSTANCE = preload("res://demo/avatar.tscn")

var _avatar_model: Node3D = null
var _color: int = 0


func _ready():
	super._ready()

	self.node.add_child(_avatar_model)


func generate():
	self._avatar_model = AVATAR_INSTANCE.instantiate()


func set_avatar_name(avatar_name: String) -> void:
	self._avatar_model.get_node("Visuals/Username").text = avatar_name


func set_color(color: int):
	self._color = color
