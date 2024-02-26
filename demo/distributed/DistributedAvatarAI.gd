class_name DistributedAvatarAI extends DistributedSmoothNodeAI

var _avatar_name: String = ""


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
