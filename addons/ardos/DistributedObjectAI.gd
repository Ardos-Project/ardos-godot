class_name DistributedObjectAI extends DistributedObjectBase

##
var air: ServerRepository:
	get:
		return self.repository

## Should this distributed object's channel not be released upon deletion?
## This should be false for DO's generated on this server.
var do_not_dealloc_channel: bool = false


func _init(repo: ConnectionRepository):
	super._init(repo)

	self.dclass = self.air._dclasses_by_name[self.get_dc_name()]


## We have to do this terribleness becase Godot doesn't have a method of getting
## the `class_name` attribute. `get_class` will only return the native class
## that this one extends (Node).
func get_dc_name() -> String:
	return "DistributedObjectAI"


## Inheritors should redefine this to take appropriate action on delete.
func delete():
	super.delete()

	if not self.do_not_dealloc_channel:
		self.air.deallocate_channel(self.do_id)

	self.parent_id = 0
	self.zone_id = 0


##
func send_update(field_name: String, args: Array = []):
	var _dg: Datagram = self.dclass.ai_format_update(
		field_name, self.do_id, self.do_id, self.air.our_channel, args
	)
	self.air.send(_dg)


## Sets the AI of this DistributedObjectAI to the specified channel.
func set_ai(ai_channel: int):
	self.air.set_ai(self.do_id, ai_channel)


## Generate an object onto the State Server, choosing an ID from the pool.
## An array of optional field names (non-required) can be included to set on the server.
func generate_with_required(parent_id: int, zone_id: int, optional_fields: PackedStringArray = []):
	self.air.generate_with_required(self, parent_id, zone_id, optional_fields)
	self.generate()
	self.announce_generate()


## Generate an object onto the State Server, specifying its ID and location.
## An array of optional field names (non-required) can be included to set on the server.
func generate_with_required_and_id(
	do_id: int, parent_id: int, zone_id: int, optional_fields: PackedStringArray = []
):
	self.air.generate_with_required_and_id(self, do_id, parent_id, zone_id, optional_fields)
	self.generate()
	self.announce_generate()


##
func set_location(parent_id: int, zone_id: int):
	# Prevent duplicate set_locations from being called.
	if self.parent_id == parent_id and self.zone_id == zone_id:
		return

	self.air.collection_manager._store_object_location(self, parent_id, zone_id)


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
