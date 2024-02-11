class_name DistributedObjectAI extends DistributedObjectBase


## 
var air : ServerRepository :
	get:
		return self.repository
		
## Should this distributed object's channel not be released upon deletion?
## This should be false for DO's generated on this server.
var do_not_dealloc_channel: bool = false


func send_update(field_name: String, args: Array = []):
	var _dg: Datagram = self.dclass.ai_format_update(field_name, self.do_id, self.do_id, self.air.our_channel, args)
	self.air.send(_dg)
