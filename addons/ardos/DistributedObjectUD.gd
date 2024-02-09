class_name DistributedObjectUD extends DistributedObjectBase


## 
var air : ServerRepository :
	get:
		return self.repository


func send_update(field_name: String, args: Array = []):
	var _dg: Datagram = self.dclass.ai_format_update(field_name, self.do_id, self.do_id, self.air.our_channel, args)
	self.air.send(_dg)
