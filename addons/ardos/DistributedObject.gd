class_name DistributedObject extends DistributedObjectBase

##
var cr: ClientRepository:
	get:
		return self.repository


##
func send_update(field_name: String, args: Array = [], send_to_id: int = self.do_id):
	var _dg: Datagram = self.dclass.client_format_update(field_name, send_to_id, args)
	self.cr.send(_dg)


##
func set_location(parent_id: int, zone_id: int):
	self.cr.collection_manager._store_object_location(self, parent_id, zone_id)
