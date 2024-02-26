class_name DistributedAvatar extends DistributedNode

const AVATAR_INSTANCE = preload("res://demo/avatar.tscn")

var _avatar_node: Node3D = null
var _avatar_anim: AnimationPlayer = null
var _color: int = 0


func _ready():
	super._ready()

	self.node.add_child(_avatar_node)


func generate():
	self._avatar_node = AVATAR_INSTANCE.instantiate()
	self._avatar_anim = self._avatar_node.get_node("Visuals/mixamo_base/AnimationPlayer")


func set_avatar_name(avatar_name: String) -> void:
	self._avatar_node.get_node("Visuals/Username").text = avatar_name


func set_color(color: int):
	self._color = color
