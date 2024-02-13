class_name DistributedObjectAI extends DistributedObjectBase

##
var air: ServerRepository:
	get:
		return self.repository

## Should this distributed object's channel not be released upon deletion?
## This should be false for DO's generated on this server.
var do_not_dealloc_channel: bool = false


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
