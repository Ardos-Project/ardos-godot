class_name ServerRepository extends ConnectionRepository


# The channel allocated as this server's sender id.
var our_channel: int = 0
var channel_allocator: UniqueIdAllocator = UniqueIdAllocator.new()


# The range of channels this AI controls.
var _min_channel: int = 0
var _max_channel: int = 0


func _init(dc_file_names: PackedStringArray = [], dc_suffix: String = "", min_channel: int = 0, max_channel: int = 0):
	self.dc_suffix = dc_suffix
	
	self.read_dc_file(dc_file_names)
	
	# Save the ranges of channels that the AI controls.
	self._min_channel = min_channel
	self._max_channel = max_channel
	
	# Initialize the channel allocation.
	self.channel_allocator.set_range(min_channel, max_channel)
	
	# Give ourselves the first channel in the range
	self.our_channel = self.allocate_channel()
	
## 
func connect_to_server(host: String, port: int) -> void:
	super._connect_to_server(host, port)

##
func allocate_channel() -> int:
	var channel: int = self.channel_allocator.allocate()
	if channel == -1:
		assert(false, "channelAllocator.allocate() is out of channels")
	
	return channel

func _handle_datagram(di: DatagramIterator):
	var msg_type: int = di.get_uint16()
	if msg_type in [
		MessageTypes.STATESERVER_OBJECT_ENTER_AI_WITH_REQUIRED,
		MessageTypes.STATESERVER_OBJECT_ENTER_AI_WITH_REQUIRED_OTHER
	]:
		self._handle_obj_entry(di, msg_type == MessageTypes.STATESERVER_OBJECT_ENTER_AI_WITH_REQUIRED_OTHER)
	elif msg_type in [
		MessageTypes.STATESERVER_OBJECT_CHANGING_AI,
		MessageTypes.STATESERVER_OBJECT_DELETE_RAM
	]:
		self._handle_obj_exit(di)
	elif msg_type == MessageTypes.STATESERVER_OBJECT_CHANGING_LOCATION:
		pass
	elif msg_type in [
		MessageTypes.DBSERVER_CREATE_OBJECT_RESP,
		MessageTypes.DBSERVER_OBJECT_GET_ALL_RESP,
		MessageTypes.DBSERVER_OBJECT_GET_FIELDS_RESP,
		MessageTypes.DBSERVER_OBJECT_GET_FIELD_RESP,
		MessageTypes.DBSERVER_OBJECT_SET_FIELD_IF_EQUALS_RESP,
		MessageTypes.DBSERVER_OBJECT_SET_FIELDS_IF_EQUALS_RESP
	]:
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
func _handle_obj_entry(di: DatagramIterator, other: bool):
	pass
	
##
func _handle_obj_exit(di: DatagramIterator):
	pass
	
