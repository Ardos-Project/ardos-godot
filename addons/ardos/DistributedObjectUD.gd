class_name DistributedObjectUD extends DistributedObjectBase

##
var air: ServerRepository:
	get:
		return self.repository


func _init(repo: ConnectionRepository):
	super._init(repo)


func send_update(field_name: String, args: Array = []):
	var _dg: Datagram = self.dclass.ai_format_update(
		field_name, self.do_id, self.do_id, self.air.our_channel, args
	)
	self.air.send(_dg)


func announce_generate():
	self.air.register_for_channel(self.do_id)
	super.announce_generate()


func delete():
	self.air.unregister_for_channel(self.do_id)
	super.delete()


## Unique 64-bit channel id for avatars.
func get_avatar_connection_channel(do_id: int) -> int:
	return self.air.get_avatar_connection_channel(do_id)


## Unique 64-bit channel id for accounts.
func get_account_connection_channel(do_id: int) -> int:
	return self.air.get_account_connection_channel(do_id)


## Returns the account id packed into the hi 32-bits of a client channel.
func get_account_id_from_channel(channel: int) -> int:
	return self.air.get_account_id_from_channel(channel)


## Returns the avatar id packed into the lo 32-bits of a client channel.
func get_avatar_id_from_channel(channel: int) -> int:
	return self.air.get_avatar_id_from_channel(channel)
