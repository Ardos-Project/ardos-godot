class_name ServerRepository extends ConnectionRepository

"""
This class interfaces with an Ardos (https://github.com/Ardos/Ardos) server in
order to manipulate objects in the Ardos cluster. It does not require any
specific "gateway" into the Ardos network. Rather, it just connects directly
to any Message Director. Hence, it is an "internal" repository.

This class is suitable for constructing your own AI Servers and UberDOG servers
using Godot. Objects with a "self.air" attribute are referring to an instance
of this class.
"""

## The different auth states a client can be in.
## Used in conjuction with `client_set_auth_state()`
enum ClientAuthState { AUTH_STATE_NEW, AUTH_STATE_ANONYMOUS, AUTH_STATE_ESTABLISHED }

# The channel allocated as this server's sender id.
var our_channel: int = 0
var channel_allocator: UniqueIdAllocator = UniqueIdAllocator.new()
# Configured State Server ID.
var server_id: int = 0

# The range of channels this AI controls.
var _min_channel: int = 0
var _max_channel: int = 0

# Channel ID of the current message sender.
var _msg_sender: int = 0

# Channels this server has opened for receiving messages from the Message Director.
var _open_channels: Array = []


func _init(
	dc_file_names: PackedStringArray = [],
	dc_suffix: String = "",
	min_channel: int = 0,
	max_channel: int = 0,
	stateserver_id: int = 0
):
	self.dc_suffix = dc_suffix

	self.read_dc_file(dc_file_names)

	# Save the ranges of channels that the AI controls.
	self._min_channel = min_channel
	self._max_channel = max_channel

	# Initialize the channel allocation.
	self.channel_allocator.set_range(min_channel, max_channel)

	# Give ourselves the first channel in the range
	self.our_channel = self.allocate_channel()

	# The State Server we are configured to use for creating objects.
	# If this is 0, generating objects is not possible.
	self.server_id = stateserver_id


##
func connect_to_server(host: String, port: int) -> void:
	super._connect_to_server(host, port)


## Allocate an unused channel out of this AIR's configured channel space.
## This is also used to allocate IDs for DistributedObjects, since those
## occupy a channel.
func allocate_channel() -> int:
	var channel: int = self.channel_allocator.allocate()
	if channel == -1:
		assert(false, "channelAllocator.allocate() is out of channels")

	return channel


## Return a previously-allocated channel back to the allocation pool.
func deallocate_channel(channel: int) -> void:
	self.channel_allocator.free_id(channel)


## Register for messages on a specific Message Director channel.
## If the channel is already open by this AIR, nothing will happen.
func register_for_channel(channel: int):
	if channel in self._open_channels:
		return

	self._open_channels.append(channel)

	var dg: Datagram = Datagram.new()
	dg.add_server_control_header(MessageTypes.CONTROL_ADD_CHANNEL)
	dg.add_uint64(channel)
	self.send(dg)


## Unregister a channel subscription on the Message Director. The Message
## Director will cease to relay messages to this AIR sent on the channel.
func unregister_for_channel(channel: int):
	if channel not in self._open_channels:
		return

	self._open_channels.erase(channel)

	var dg: Datagram = Datagram.new()
	dg.add_server_control_header(MessageTypes.CONTROL_REMOVE_CHANNEL)
	dg.add_uint64(channel)
	self.send(dg)


## Set the connection name for this MD client displayed in Ardos logs.
func set_con_name(con_name: String):
	var dg: Datagram = Datagram.new()
	dg.add_server_control_header(MessageTypes.CONTROL_SET_CON_NAME)
	dg.add_string(con_name)
	self.send(dg)


## Sets the AI of the specified DistributedObjectAI to be the specified channel.
## Generally, you should not call this method, and instead call DistributedObjectAI.set_ai.
func set_ai(do_id: int, ai_channel: int):
	var dg: Datagram = Datagram.new()
	dg.add_server_header(do_id, ai_channel, MessageTypes.STATESERVER_OBJECT_SET_AI)
	dg.add_uint64(ai_channel)
	self.send(dg)


## Eject (kick) a client with a given application-specific code and reason.
func client_eject(client_channel: int, code: int, reason: String = ""):
	var dg: Datagram = Datagram.new()
	dg.add_server_header(client_channel, self.our_channel, MessageTypes.CLIENTAGENT_EJECT)
	dg.add_uint16(code)
	dg.add_string(reason)
	self.send(dg)


## Update the auth state of a connected client within the Ardos cluster.
## Generally, this should only be called with `AUTH_STATE_ESTABLISHED`
## Ardos automatically handles new and anonymous connections.
func client_set_auth_state(client_channel: int, state: ClientAuthState):
	var dg: Datagram = Datagram.new()
	dg.add_server_header(client_channel, self.our_channel, MessageTypes.CLIENTAGENT_SET_STATE)
	dg.add_uint16(state)
	self.send(dg)


## Updates the sender channel of the specified client when calling `get_msg_sender()`
## This is typically used to de-anonymize the client. e.g. Set their sender channel
## to their application-specific account id, avatar id, etc.
func client_set_sender_channel(client_channel: int, new_channel: int):
	var dg: Datagram = Datagram.new()
	dg.add_server_header(client_channel, self.our_channel, MessageTypes.CLIENTAGENT_SET_CLIENT_ID)
	dg.add_uint64(new_channel)
	self.send(dg)


## Opens the specified channel on a client for receiving messages.
func client_open_channel(client_channel: int, channel: int):
	var dg: Datagram = Datagram.new()
	dg.add_server_header(client_channel, self.our_channel, MessageTypes.CLIENTAGENT_OPEN_CHANNEL)
	dg.add_uint64(channel)
	self.send(dg)


## Closes a previously opened channel on a client.
func client_close_channel(client_channel: int, channel: int):
	var dg: Datagram = Datagram.new()
	dg.add_server_header(client_channel, self.our_channel, MessageTypes.CLIENTAGENT_CLOSE_CHANNEL)
	dg.add_uint64(channel)
	self.send(dg)


## Declares the specified DistributedObject to be "owned" by the specified
## client channel. This allows the client to call "ownsend" fields, and receive
## "ownrecv" fields. Depending on your Ardos configuration, they may also be
## able to change the location of this object.
func client_add_owner_object(client_channel: int, do_id: int):
	var dg: Datagram = Datagram.new()
	dg.add_server_header(do_id, self.our_channel, MessageTypes.STATESERVER_OBJECT_SET_OWNER)
	dg.add_uint64(client_channel)
	self.send(dg)


## Declares the specified DistributedObject to be a "session object",
## meaning that it is destroyed when the client disconnects.
## Generally used for avatars owned by the client.
func client_add_session_object(client_channel: int, do_id: int):
	var dg: Datagram = Datagram.new()
	dg.add_server_header(
		client_channel, self.our_channel, MessageTypes.CLIENTAGENT_ADD_SESSION_OBJECT
	)
	dg.add_uint32(do_id)
	self.send(dg)


## Removes a previously added session object from a client.
func client_remove_session_object(client_channel: int, do_id: int):
	var dg: Datagram = Datagram.new()
	dg.add_server_header(
		client_channel, self.our_channel, MessageTypes.CLIENTAGENT_REMOVE_SESSION_OBJECT
	)
	dg.add_uint32(do_id)
	self.send(dg)


## Generate an object onto the State Server, choosing an ID from the pool.
## You should use do.generate_with_required(...) instead. This is not meant
## to be called directly unless you really know what you are doing.
func generate_with_required(
	do: DistributedObjectAI, parent_id: int, zone_id: int, optional_fields: PackedStringArray
):
	var do_id: int = self.allocate_channel()
	self.generate_with_required_and_id(do, do_id, parent_id, zone_id, optional_fields)


## Generate an object onto the State Server, specifying its ID and location.
## You should use do.generate_with_required_and_id(...) instead. This is not
## meant to be called directly unless you really know what you are doing.
func generate_with_required_and_id(
	do: DistributedObjectAI,
	do_id: int,
	parent_id: int,
	zone_id: int,
	optional_fields: PackedStringArray
):
	do.do_id = do_id
	self.collection_manager.add_do_to_tables(do, parent_id, zone_id)
	self._send_generate_with_required(do, parent_id, zone_id, optional_fields)


## Returns the channel ID of the current message sender.
func get_msg_sender() -> int:
	return self._msg_sender


## Unique 64-bit channel id for avatars.
func get_avatar_connection_channel(do_id: int) -> int:
	return do_id + (1001 << 32)


## Unique 64-bit channel id for accounts.
func get_account_connection_channel(do_id: int) -> int:
	return do_id + (1003 << 32)


## Returns the account id packed into the hi 32-bits of a client channel.
func get_account_id_from_channel(channel: int) -> int:
	return channel >> 32


## Returns the avatar id packed into the lo 32-bits of a client channel.
func get_avatar_id_from_channel(channel: int) -> int:
	return channel & 0xffffffff


##
func _handle_connected():
	# Listen to our channel...
	self.register_for_channel(self.our_channel)


##
func _send_generate_with_required(
	do: DistributedObjectAI, parent_id: int, zone_id: int, optional_fields: PackedStringArray
):
	var dg: Datagram = do.dclass.ai_format_generate(
		do, do.do_id, parent_id, zone_id, self.server_id, self.our_channel, optional_fields
	)
	self.send(dg)


##
func _handle_datagram(di: DatagramIterator) -> void:
	# Discard target channels, we don't need them.
	di.seek_payload()

	self._msg_sender = di.get_uint64()

	var msg_type: int = di.get_uint16()
	if (
		msg_type
		in [
			MessageTypes.STATESERVER_OBJECT_ENTER_AI_WITH_REQUIRED,
			MessageTypes.STATESERVER_OBJECT_ENTER_AI_WITH_REQUIRED_OTHER
		]
	):
		self._handle_obj_entry(
			di, msg_type == MessageTypes.STATESERVER_OBJECT_ENTER_AI_WITH_REQUIRED_OTHER
		)
	elif (
		msg_type
		in [MessageTypes.STATESERVER_OBJECT_CHANGING_AI, MessageTypes.STATESERVER_OBJECT_DELETE_RAM]
	):
		self._handle_obj_exit(di)
	elif msg_type == MessageTypes.STATESERVER_OBJECT_SET_FIELD:
		self._handle_set_field(di)
	elif msg_type == MessageTypes.STATESERVER_OBJECT_CHANGING_LOCATION:
		self._handle_obj_changing_location(di)
	elif (
		msg_type
		in [
			MessageTypes.DBSERVER_CREATE_OBJECT_RESP,
			MessageTypes.DBSERVER_OBJECT_GET_ALL_RESP,
			MessageTypes.DBSERVER_OBJECT_GET_FIELDS_RESP,
			MessageTypes.DBSERVER_OBJECT_GET_FIELD_RESP,
			MessageTypes.DBSERVER_OBJECT_SET_FIELD_IF_EQUALS_RESP,
			MessageTypes.DBSERVER_OBJECT_SET_FIELDS_IF_EQUALS_RESP
		]
	):
		pass
	elif msg_type == MessageTypes.DBSS_OBJECT_GET_ACTIVATED_RESP:
		pass
	elif msg_type == MessageTypes.STATESERVER_OBJECT_GET_LOCATION_RESP:
		pass
	elif msg_type == MessageTypes.STATESERVER_OBJECT_GET_ALL_RESP:
		pass
	elif msg_type == MessageTypes.CLIENTAGENT_GET_NETWORK_ADDRESS_RESP:
		pass
	elif msg_type >= 20000:
		# These messages belong to the NetMessenger:
		# self.netMessenger.handle(msgType, di)
		pass
	else:
		print("[ServerRepository] ERROR: Received message with unknown MsgType=%d" % msg_type)


##
func _handle_obj_entry(di: DatagramIterator, other: bool) -> void:
	var do_id: int = di.get_uint32()
	var parent_id: int = di.get_uint32()
	var zone_id: int = di.get_uint32()
	var class_id: int = di.get_uint16()

	if class_id not in self._dclasses_by_number:
		assert(false, "Received entry for unknown dclass=%d! (DoId: %d)" % [class_id, do_id])
		return

	if do_id in self.collection_manager.do_by_id:
		# We already know about this object; ignore the entry.
		return

	var dclass = self._dclasses_by_number[class_id]
	var dclass_name = dclass.get_name() + self._dc_suffix

	# Construct the distributed object.
	var class_def = self._dc_imports.get(dclass_name)
	if not class_def:
		print("[ServerRepository] ERROR: Could not construct an undefined %s" % dclass_name)
		return

	var dist_obj: DistributedObjectAI = class_def.new()
	dist_obj.repository = self
	dist_obj.dclass = dclass
	dist_obj.do_id = do_id
	# The DO came in off the server, so we do not unregister the channel when
	# it dies:
	dist_obj.do_not_dealloc_channel = true
	dist_obj.name = "%d - %s" % [do_id, dclass_name]
	self.collection_manager.add_do_to_tables(dist_obj, parent_id, zone_id)

	# Now for generation:
	dist_obj.generate()
	if other:
		dist_obj.update_all_required_fields_other(di)
	else:
		dist_obj.update_all_required_fields(di)
	add_child(dist_obj)


##
func _handle_obj_exit(di: DatagramIterator):
	var do_id: int = di.get_uint32()

	var do: DistributedObjectBase = self.collection_manager.get_do(do_id)
	if not do:
		print("[ServerRepository] WARNING: Received AI exit for unknown object %d" % do_id)
		return

	self.collection_manager.remove_do_from_tables(do)
	do.delete()

	# Delete the object from the scene graph.
	do.queue_free()


##
func _handle_set_field(di: DatagramIterator):
	var do_id: int = di.get_uint32()

	var do: DistributedObjectBase = self.collection_manager.get_do(do_id)
	if not do:
		return

	# Receive the update on the object.
	# This will automatically call the method packed in the update.
	do.dclass.receive_update(do, di)


##
func _handle_obj_changing_location(di: DatagramIterator):
	var do_id: int = di.get_uint32()
	var parent_id: int = di.get_uint32()
	var zone_id: int = di.get_uint32()

	var do: DistributedObjectBase = self.collection_manager.get_do(do_id)
	if not do:
		print("[ServerRepository] WARNING: Received location for unknown doId=%d!" % do_id)
		return

	do.set_location(parent_id, zone_id)
