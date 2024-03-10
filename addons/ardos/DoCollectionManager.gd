class_name DoCollectionManager extends Node

"""
"""

const BAD_DO_ID: int = 0
const BAD_ZONE_ID: int = 0
const BAD_CHANNEL_ID: int = 0

## This should be re-defined to the global DoId of this game.
var GAME_GLOBALS_ID: int = 0

## Dictionary of Distributed Object's mapped by their DoId's.
var do_by_id: Dictionary = {}

## As above, with the exception that this maps only distributed objects we have
## an 'owner' view of as a client (OV). This will never be populated on a server.
var do_by_id_ov: Dictionary = {}

## Table of Distributed Object's stored in a hierarchical way.
## parentId->zoneId->set(child DoIds)
var _do_table: Dictionary = {}
## Array of DoId's currently stored in the _do_table.
var _do_table_ids: Array = []


## Returns a distributed object instance stored by this manager (or null.)
func get_do(do_id: int) -> DistributedObjectBase:
	return self.do_by_id.get(do_id)


## Returns a distributed object OV instance stored by this manager (or null.)
func get_do_ov(do_id: int) -> DistributedObjectBase:
	return self.do_by_id_ov.get(do_id)


## Adds a distributed object underneath this manager for tracking.
func add_do_to_tables(
	do: DistributedObjectBase, parent_id: int = 0, zone_id: int = 0, owner_view: bool = false
):
	if not owner_view:
		parent_id = parent_id or do.parent_id
		zone_id = zone_id or do.zone_id

	var do_table: Dictionary = self.do_by_id_ov if owner_view else self.do_by_id

	# Make sure the object isn't already present.
	if do.do_id in do_table:
		var table_name: String = "do_by_id_ov" if owner_view else "do_by_id"
		assert(false, "do_id: %d already in %s!" % [do.do_id, table_name])
		return

	do_table[do.do_id] = do

	# Store the distributed object by location.
	# N.B: We don't do this for OV's as they're 'locationless' by their nature.
	if not owner_view:
		if self._is_valid_location(parent_id, zone_id):
			self._store_object_location(do, parent_id, zone_id)


## Removes a distributed object from this manager.
func remove_do_from_tables(do: DistributedObjectBase):
	var parent_id: int = do.parent_id
	var zone_id: int = do.zone_id

	if self._is_valid_location(parent_id, zone_id):
		var parent_do: DistributedObjectBase = get_do(parent_id)
		if parent_do:
			parent_do.handle_child_leave(do, zone_id)

		self._delete_object_location_table(do, parent_id, zone_id)

	if do.do_id in self.do_by_id:
		self.do_by_id[do.do_id] = null

	if do.do_id in self.do_by_id_ov:
		self.do_by_id_ov[do.do_id] = null


## Returns true if a location is valid within the DO hierarchy.
func _is_valid_location(parent_id: int, zone_id: int) -> bool:
	return parent_id != BAD_DO_ID and zone_id != BAD_ZONE_ID


## An object is changing location within the DO hierarchy.
## Store it, and notify existing objects that might care.
func _store_object_location(do: DistributedObjectBase, parent_id: int, zone_id: int):
	var old_parent_id: int = do.parent_id
	var old_zone_id: int = do.zone_id

	if old_parent_id != parent_id:
		# Notify any existing parent that we're moving away.
		var old_parent_do: DistributedObjectBase = get_do(old_parent_id)
		if old_parent_do:
			old_parent_do.handle_child_leave(do, old_zone_id)

		self._delete_object_location_table(do, old_parent_id, old_zone_id)

	elif old_zone_id != zone_id:
		# Remove old location.
		var old_parent_do: DistributedObjectBase = get_do(old_parent_id)
		if old_parent_do:
			old_parent_do.handle_child_leave_zone(do, old_zone_id)

		self._delete_object_location_table(do, old_parent_id, old_zone_id)

	else:
		# Object is already at that parent and zone.
		return

	# Add to new location:
	self._store_object_location_table(do, parent_id, zone_id)
	# Set the new parent and zone on the object.
	do.parent_id = parent_id
	do.zone_id = zone_id

	if old_parent_id != parent_id:
		# Give the parent a chance to run code when a new child
		# sets location to it. For example, the parent may want to
		# scene graph reparent the child to some subnode it owns.
		var parent_do: DistributedObjectBase = get_do(parent_id)
		if parent_do:
			parent_do.handle_child_arrive(do, zone_id)
		elif parent_id not in [BAD_DO_ID, GAME_GLOBALS_ID]:
			print(
				(
					"[DoCollectionManager] WARNING: store_object_location(%d): parent %d not present"
					% [do.do_id, parent_id]
				)
			)

	elif old_zone_id != zone_id:
		var parent_do: DistributedObjectBase = get_do(parent_id)
		if parent_do:
			parent_do.handle_child_arrive_zone(do, zone_id)
		elif parent_id not in [BAD_DO_ID, GAME_GLOBALS_ID]:
			print(
				(
					"[DoCollectionManager] WARNING: store_object_location(%d): parent %d not present"
					% [do.do_id, parent_id]
				)
			)


##
func _store_object_location_table(do: DistributedObjectBase, parent_id: int, zone_id: int):
	var do_id: int = do.do_id
	if do_id in self._do_table_ids:
		assert(
			false,
			(
				"_store_object_location_table(%s %d) already in _do_table_ids; duplicate generate()? or didn't clean up previous instance of DO?"
				% [do.dclass.get_name(), do_id]
			)
		)
		return

	var parent_zone_dict: Dictionary = self._do_table.get(parent_id, {})
	var zone_do_set: Array = parent_zone_dict.get(zone_id, [])

	zone_do_set.append(do_id)
	self._do_table_ids.append(do_id)


##
func _delete_object_location_table(do: DistributedObjectBase, parent_id: int, zone_id: int):
	if not self._is_valid_location(parent_id, zone_id):
		return
	
	var do_id: int = do.do_id
	if do_id not in self._do_table_ids:
		assert(
			false,
			(
				"delete_object_location_table(%s %d) not in _do_table_ids; duplicate delete()? or invalid previous location on a new object?"
				% [do.dclass.get_name(), do_id]
			)
		)
		return

	var parent_zone_dict: Dictionary = self._do_table.get(parent_id)
	if not parent_zone_dict:
		assert(false, "_delete_object_location_table: parentId: %d not found" % parent_id)
		return

	var zone_do_set: Array = parent_zone_dict.get(zone_id)
	if not zone_do_set:
		assert(false, "_delete_object_location_table: zoneId: %d not found" % zone_id)
		return

	if do_id not in zone_do_set:
		assert(false, "_delete_object_location_table: objId: %d not found" % do_id)
		return

	# Clear out the DoId.
	zone_do_set.erase(do_id)
	self._do_table_ids.erase(do_id)

	if len(zone_do_set) == 0:
		parent_zone_dict[zone_id] = null
		if len(parent_zone_dict) == 0:
			self._do_table[parent_id] = null
