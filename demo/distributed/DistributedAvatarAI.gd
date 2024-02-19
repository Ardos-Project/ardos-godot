class_name DistributedAvatarAI extends DistributedNodeAI

var _avatar_name: String = ""
var _color: int = 0


func get_dc_name() -> String:
	return "DistributedAvatarAI"


func set_avatar_name(avatar_name: String) -> void:
	self._avatar_name = avatar_name


func get_avatar_name() -> String:
	return self._avatar_name


func d_set_avatar_name(avatar_name: String):
	self.send_update("set_avatar_name", [avatar_name])


func b_set_avatar_name(avatar_name: String):
	self.set_avatar_name(avatar_name)
	self.d_set_avatar_name(avatar_name)


func set_color(color: int):
	self._color = color


func get_color() -> int:
	return self._color


func d_set_color(color: int):
	self.send_update("set_color", [color])


func b_set_color(color: int):
	self.set_color(color)
	self.d_set_color(color)
