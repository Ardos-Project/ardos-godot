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
		pass
	elif msg_type == MessageTypes.CLIENT_ENTER_OBJECT_REQUIRED_OTHER:
		pass
	elif msg_type == MessageTypes.CLIENT_ENTER_OBJECT_REQUIRED_OWNER:
		pass
	elif msg_type == MessageTypes.CLIENT_ENTER_OBJECT_REQUIRED_OTHER_OWNER:
		pass
	elif msg_type == MessageTypes.CLIENT_OBJECT_SET_FIELD:
		pass
	elif msg_type == MessageTypes.CLIENT_OBJECT_LEAVING:
		pass
	elif msg_type == MessageTypes.CLIENT_OBJECT_LEAVING_OWNER:
		pass
	elif msg_type == MessageTypes.CLIENT_DONE_INTEREST_RESP:
		pass
	elif msg_type == MessageTypes.CLIENT_OBJECT_LOCATION:
		pass
	else:
		print("Unknown message type: ", msg_type)

func _send_heartbeat() -> void:
	# Send off a heartbeat message.
	var _dg: Datagram = Datagram.new()
	_dg.add_uint16(MessageTypes.CLIENT_HEARTBEAT)
	self.send(_dg)
