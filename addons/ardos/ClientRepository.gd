class_name ClientRepository extends ConnectionRepository

"""
This maintains a client-side connection with an Ardos server.
"""

var _heartbeat_timer = Timer.new()
var _version: String = ""


func _init(dc_file_names: PackedStringArray = [], dc_suffix: String = ""):
	self.dc_suffix = dc_suffix
	self.owner_views = true

	self.read_dc_file(dc_file_names)
	
	# Heartbeat is "processed" each physics frame.
	# Should help with reliability.
	_heartbeat_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	_heartbeat_timer.name = "Heartbeat Timer"
	_heartbeat_timer.timeout.connect(_send_heartbeat)
	
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
	print("Disconnected from Ardos!")
	
func _handle_datagram(di: DatagramIterator):
	var msg_type: int = di.get_uint16()
	if msg_type == MessageTypes.CLIENT_HELLO_RESP:
		print("Hello from Ardos!")
	else:
		print("Unknown message type: ", msg_type)

func _send_heartbeat() -> void:
	if status != StreamPeerTCP.STATUS_CONNECTED:
		return

	# Send off a heartbeat message.
	var _dg: Datagram = Datagram.new()
	_dg.add_uint16(MessageTypes.CLIENT_HEARTBEAT)
	self.send(_dg)
