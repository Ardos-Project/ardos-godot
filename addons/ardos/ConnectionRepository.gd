class_name ConnectionRepository extends Node

"""
This is a base class for things that know how to establish a
connection (and exchange datagrams) with Ardos.
This includes ClientRepository and ServerRepository.
"""

signal connected_to_server()
signal disconnected_from_server()

var status : StreamPeerTCP.Status :
	get:
		return _socket.get_status()

var _socket: StreamPeerTCP = StreamPeerTCP.new()
var _lastStatus: StreamPeerTCP.Status = StreamPeerTCP.STATUS_NONE

func _init():
	# Disable nagle's algorithm.
	_socket.set_no_delay(true)

func connect_to_server(host: String, port: int) -> void:
	# connect() would be a better name here,
	# but shadows signalling 'connect()' 
	_lastStatus = StreamPeerTCP.STATUS_NONE
	if _socket.connect_to_host(host, port) != OK:
		disconnected_from_server.emit()
		return
	
	# Emit the connected signal.
	connected_to_server.emit()
	
func disconnect_from_server() -> void:
	if status == StreamPeerTCP.STATUS_NONE:
		return
		
	_socket.disconnect_from_host()
	
	# Emit the disconnected signal.
	disconnected_from_server.emit()
	
func _process(delta: float) -> void:
	if status != StreamPeerTCP.STATUS_CONNECTED:
		return
	
	_lastStatus = status
	
	var available_bytes: int = _socket.get_available_bytes()
	if available_bytes > 0:
		var data: Array = _socket.get_partial_data(available_bytes)
		# Check for read error.
		if data[0] != OK:
				print("Error getting data from stream: ", data[0])
	
func read_dc_file():
	pass
