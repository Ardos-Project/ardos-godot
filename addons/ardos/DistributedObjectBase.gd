class_name DistributedObjectBase extends Node

"""
The Distributed Object class is the base class for all network based
(i.e. distributed) objects. These will usually (always?) have a
dclass entry in a *.dc file.
"""

var repository = null
var dclass: GDDCClass = null
var do_id: int = 0
var parent_id: int = 0
var zone_id: int = 0

var __generated: bool = false


func _init(repo: ConnectionRepository):
	self.repository = repo


## First generate (not from cache).
func generate_init():
	pass


## Inheritors should put functions that require self.zoneId or
## other networked info in this function.
func generate():
	pass


## Called after the object has been generated and all
## of its required fields filled in. Overwrite when needed.
func announce_generate():
	self.__generated = true


## Override this to handle cleanup right before this object
## gets deleted.
func delete():
	self.__generated = false


## A new child has just setLocation beneath us. Give us a
## chance to run code when a new child sets location to us. For
## example, we may want to scene graph reparent the child to
## some subnode we own.
func handle_child_arrive(child_obj: DistributedObjectBase, zone_id: int):
	pass


## A child has just changed zones beneath us with setLocation.
## Give us a chance to run code when an existing child sets
## location to us. For example, we may want to scene graph
## reparent the child to some subnode we own.
func handle_child_arrive_zone(child_obj: DistributedObjectBase, zone_id: int):
	pass


## A child is about to setLocation away from us. Give us a
## chance to run code just before a child sets location away from us.
func handle_child_leave(child_obj: DistributedObjectBase, zone_id: int):
	pass


## A child is about to setLocation to another zone beneath us.
## Give us a chance to run code just before a child sets
## location to that zone.
func handle_child_leave_zone(child_obj: DistributedObjectBase, zone_id: int):
	pass


##
func update_required_fields(di: DatagramIterator):
	self.dclass.receive_update_broadcast_required(self, di)
	self.announce_generate()


##
func update_all_required_fields(di: DatagramIterator):
	self.dclass.receive_update_all_required(self, di)
	self.announce_generate()


##
func update_required_fields_other(di: DatagramIterator):
	self.dclass.receive_update_broadcast_required(self, di)
	# Announce generate after updating all the required fields,
	# but before we update the non-required fields.
	self.announce_generate()

	self.dclass.receive_update_other(self, di)


##
func update_all_required_fields_other(di: DatagramIterator):
	self.dclass.receive_update_all_required(self, di)
	# Announce generate after updating all the required fields,
	# but before we update the non-required fields.
	self.announce_generate()

	self.dclass.receive_update_other(self, di)


##
func update_required_fields_owner(di: DatagramIterator):
	self.dclass.receive_update_broadcast_required_owner(self, di)
	self.announce_generate()


##
func update_required_fields_other_owner(di: DatagramIterator):
	self.dclass.receive_update_broadcast_required_owner(self, di)
	# Announce generate after updating all the required fields,
	# but before we update the non-required fields.
	self.announce_generate()

	self.dclass.receive_update_other(self, di)
