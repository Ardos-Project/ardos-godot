class_name ClientRepository extends ConnectionRepository

"""
This maintains a client-side connection with an Ardos server.
"""

var _heartbeat_timer = Timer.new()
var _heartbeat_interval: int = 10  # 10 seconds.
var _version: String = ""


func _init(dc_file_names: PackedStringArray = [], dc_suffix: String = ""):
	self.dc_suffix = dc_suffix
	self.owner_views = true

	self.read_dc_file(dc_file_names)

	# Heartbeat timer is "processed" each physics frame.
	# Should help with reliability.
	_heartbeat_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	_heartbeat_timer.name = "Heartbeat Timer"
	_heartbeat_timer.timeout.connect(_send_heartbeat)

	# The interval in which heartbeat messages are sent.
	# This should be LESS than whatever was set in the Ardos config to allow for
	# network latency, dropped packets and application freezing/lag.
	if ProjectSettings.has_setting("application/ardos/heartbeat_interval"):
		_heartbeat_interval = ProjectSettings.get_setting("application/ardos/heartbeat_interval")


func _ready():
	add_child(_heartbeat_timer)


func connect_to_server(host: String, port: int, version: String) -> void:
	self._version = version
	super._connect_to_server(host, port)


func _handle_connected():
	# Send a hello packet to start the auth process.
	var _dg: Datagram = Datagram.new()
	_dg.add_uint16(MessageTypes.CLIENT_HELLO)
	_dg.add_uint32(self.dc_hash_val)
	_dg.add_string(self._version)
	self.send(_dg)


func _handle_disconnected():
	# Stop sending heartbeat messages.
	self._heartbeat_timer.stop()
	# Emit the disconnected signal.
	self.disconnected_from_server.emit()


func _handle_datagram(di: DatagramIterator):
	var msg_type: int = di.get_uint16()
	if msg_type == MessageTypes.CLIENT_HELLO_RESP:
		# Start sending heartbeat messages.
		self._heartbeat_timer.start(_heartbeat_interval)
		# Emit the connected signal.
		self.connected_to_server.emit()
	elif msg_type == MessageTypes.CLIENT_EJECT:
		# We've been forcefully disconnected by the server.
		var reason: int = di.get_uint16()
		var message: String = di.get_string()
		print("Disconnected by server %s - %s" % [reason, message])
	elif msg_type == MessageTypes.CLIENT_ENTER_OBJECT_REQUIRED:
		self._handle_generate_with_required(di)
	elif msg_type == MessageTypes.CLIENT_ENTER_OBJECT_REQUIRED_OTHER:
		self._handle_generate_with_required(di, true)
	elif msg_type == MessageTypes.CLIENT_ENTER_OBJECT_REQUIRED_OTHER_OWNER:
		self._handle_generate_with_required_other_owner(di)
	elif msg_type == MessageTypes.CLIENT_OBJECT_SET_FIELD:
		self._handle_set_field(di)
	elif msg_type == MessageTypes.CLIENT_OBJECT_LEAVING:
		self._handle_leaving(di)
	elif msg_type == MessageTypes.CLIENT_OBJECT_LEAVING_OWNER:
		self._handle_leaving(di, true)
	elif msg_type == MessageTypes.CLIENT_DONE_INTEREST_RESP:
		self._handle_interest_done(di)
	elif msg_type == MessageTypes.CLIENT_OBJECT_LOCATION:
		self._handle_location(di)
	else:
		print("Unknown message type: ", msg_type)


func _send_heartbeat() -> void:
	# Send off a heartbeat message.
	var _dg: Datagram = Datagram.new()
	_dg.add_uint16(MessageTypes.CLIENT_HEARTBEAT)
	self.send(_dg)


##
func _handle_generate_with_required(di: DatagramIterator, other: bool = false):
	var parent_id: int = di.get_uint32()
	var zone_id: int = di.get_uint32()
	var class_id: int = di.get_uint16()
	var do_id: int = di.get_uint32()

	var dclass: GDDCClass = self._dclasses_by_number[class_id]
	var dclass_name = dclass.get_name() + self._dc_suffix

	# Get the class definition.
	var class_def = self._dc_imports.get(dclass_name)
	if not class_def:
		print("[ClientRepository] ERROR: Could not construct an undefined %s" % dclass_name)
		return

	if self.collection_manager.do_by_id.has(do_id):
		# ...it is in our dictionary.
		# Just update it.
		var dist_obj: DistributedObject = self.collection_manager.get_do(do_id)
		dist_obj.generate()
		dist_obj.set_location(parent_id, zone_id)
		if other:
			dist_obj.update_required_fields_other(di)
		else:
			dist_obj.update_required_fields(di)
	# TODO: Cacheable objects.
	# elif self.cache.has(do_id)
	else:
		# ...it is not in the dictionary or the cache.
		# Construct a new one.
		var dist_obj: DistributedObject = class_def.new()
		dist_obj.repository = self
		dist_obj.dclass = dclass
		dist_obj.do_id = do_id
		dist_obj.name = "%d - %s" % [do_id, dclass_name]
		self.collection_manager.add_do_to_tables(dist_obj, parent_id, zone_id)

		# Now for generation:
		dist_obj.generate_init()  # Only called when constructed.
		dist_obj.generate()
		if other:
			dist_obj.update_all_required_other_fields(di)
		else:
			dist_obj.update_all_required_fields(di)

		add_child(dist_obj)
		dist_obj.announce_generate()


func _handle_generate_with_required_other_owner(di: DatagramIterator):
	var do_id: int = di.get_uint32()
	var parent_id: int = di.get_uint32()
	var zone_id: int = di.get_uint32()
	var class_id: int = di.get_uint16()

	var dclass: GDDCClass = self._dclasses_by_number[class_id]
	var dclass_name = dclass.get_name() + "OV"

	# Get the class definition.
	var class_def = self._dc_imports.get(dclass_name)
	if not class_def:
		print("[ClientRepository] ERROR: Could not construct an undefined %s" % dclass_name)
		return

	if self.collection_manager.do_by_id_ov.has(do_id):
		# ...it is in our dictionary.
		# Just update it.
		assert(false, "Duplicate owner generate for %d (%s)" % [do_id, dclass_name])
		var dist_obj: DistributedObject = self.collection_manager.get_do_ov(do_id)
		dist_obj.generate()
		dist_obj.update_required_fields_other(di)
	# TODO: Cacheable objects.
	# elif self.cache.has(do_id)
	else:
		# ...it is not in the dictionary or the cache.
		# Construct a new one.
		var dist_obj: DistributedObject = class_def.new()
		dist_obj.repository = self
		dist_obj.dclass = dclass
		dist_obj.do_id = do_id
		dist_obj.name = "[Owner] %d - %s" % [do_id, dclass_name]
		self.collection_manager.add_do_to_tables(dist_obj, parent_id, zone_id, true)

		# Now for generation:
		dist_obj.generate_init()  # Only called when constructed.
		dist_obj.generate()
		dist_obj.update_all_required_other_fields(di)

		add_child(dist_obj)
		dist_obj.announce_generate()


##
func _handle_set_field(di: DatagramIterator):
	var do_id: int = di.get_uint32()

	# First, try to update an OV we might have on this object.
	var do_ov: DistributedObject = self.collection_manager.get_do_ov(do_id)
	if do_ov:
		# Decode the field update data.
		var data: Array = do_ov.dclass.receive_update(di)
		if len(data) != 0:
			var callable: Callable = Callable(do_ov, data.pop_front())
			callable.callv(data)

		# Reset the datagram iterator for receive_update again below.
		di.seek_payload()
		di.get_uint16()  # Skip message type.

	# Next, try to update a client view we might have on this object.
	var do: DistributedObject = self.collection_manager.get_do(do_id)
	if do:
		# Decode the field update data.
		var data: Array = do.dclass.receive_update(di)
		if len(data) != 0:
			var callable: Callable = Callable(do, data.pop_front())
			callable.callv(data)


##
func _handle_leaving(di: DatagramIterator, owner: bool = false):
	var do_id: int = di.get_uint32()

	var do_table: Dictionary = (
		self.collection_manager.do_by_id_ov if owner else self.collection_manager.do_by_id
	)

	var do: DistributedObject = do_table.get(do_id)
	if not do:
		print("[ClientRepository] WARNING: Received leaving for unknown object %d" % do_id)
		return

	# TODO: Caching.
	self.collection_manager.remove_do_from_tables(do)
	do.delete()

	# Delete the object from the scene graph.
	do.queue_free()


##
func _handle_interest_done(di: DatagramIterator):
	# TODO.
	pass


##
func _handle_location(di: DatagramIterator):
	var do_id: int = di.get_uint32()
	var parent_id: int = di.get_uint32()
	var zone_id: int = di.get_uint32()

	var do: DistributedObject = self.collection_manager.get_do(do_id)
	if not do:
		print(
			"[ClientRepository] WARNING: Asked to update location of non-existent obj: %d" % do_id
		)
		return

	do.set_location(parent_id, zone_id)
