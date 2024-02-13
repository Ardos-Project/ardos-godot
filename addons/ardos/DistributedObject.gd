class_name DistributedObject extends DistributedObjectBase

##
var cr: ClientRepository:
	get:
		return self.repository


func send_update(field_name: String, args: Array = [], send_to_id: int = self.do_id):
	var _dg: Datagram = self.dclass.client_format_update(field_name, send_to_id or self.do_id, args)
	self.cr.send(_dg)
