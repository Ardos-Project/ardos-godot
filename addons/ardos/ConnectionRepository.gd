class_name ConnectionRepository extends Node

"""
This is a base class for things that know how to establish a
connection (and exchange datagrams) with Ardos.
This includes ClientRepository and ServerRepository.
"""

signal connected_to_server()
signal disconnected_from_server()


## Size of the length header for datagrams.
## sizeof(uint16_t)
const DG_LENGTH_HEADER_SIZE = 2


## 
var status : StreamPeerTCP.Status :
	get:
		return _socket.get_status()

## 
var dc_hash_val : int : 
	get:
		return _dc_file.get_hash()
		
## This is the string that is appended to symbols read from the DC file.
## The ServerRepository will redefine this to 'AI' or 'UD'.
var dc_suffix: String = ""

## Whether we're supporting 'owner' views of distributed objects
## (i.e. 'receives ownrecv', 'I own this object and have a separate
## view of it regardless of where it currently is located')
var owner_views: bool = false


var _socket: StreamPeerTCP = StreamPeerTCP.new()
var _last_status: StreamPeerTCP.Status = StreamPeerTCP.STATUS_NONE
var _dc_file: GDDCFile = GDDCFile.new()
var _dc_imports: Dictionary = {}
var _dclasses_by_name: Dictionary = {}
var _dclasses_by_number: Dictionary = {}
var _do_by_id: Dictionary = {}
var _data_buf: PackedByteArray = PackedByteArray()


##
func _connect_to_server(host: String, port: int) -> void:
	# connect() would be a better name here,
	# but shadows signalling 'connect()' 
	self._last_status = StreamPeerTCP.STATUS_NONE
	if self._socket.connect_to_host(host, port) != OK:
		self.disconnected_from_server.emit()
		return
	
## Inheritors should override.
func _handle_connected() -> void:
	pass
	
## Inheritors should override.
func _handle_disconnected() -> void:
	pass
	
## Inheritors should override.
func _handle_datagram(di: DatagramIterator) -> void:
	pass

##	
func disconnect_from_server() -> void:
	if self.status == StreamPeerTCP.STATUS_NONE:
		return
		
	self._socket.disconnect_from_host()
	
	# Emit the disconnected signal.
	self.disconnected_from_server.emit()
	
## Sends a packed byte array over the connection.
func send(dg: Datagram) -> bool:
	if self.status != StreamPeerTCP.STATUS_CONNECTED:
		print("[ConnectionRepository] WARNING: Unable to send datagram after connection is closed.")
		return false
		
	var error: int = self._socket.put_data(dg.get_data())
	if error != OK:
		print("[ConnectionRepository] WARNING: Failed to send datagram: ", error)
		return false
		
	return true
	
## Generate an instance of a global distributed object (UD)
## and put it into our local tables.
func generate_global_object(do_id: int, dc_name: String, values = []) -> DistributedObjectBase:
	# Look up the dclass.
	var dclass_name: String = dc_name + dc_suffix
	var dclass: GDDCClass = self._dclasses_by_name.get(dclass_name)
	if not dclass:
		print("[ConnectionRepository] WARNING: Need to define %s" % dclass_name)
		dclass_name = dc_name + "AI"
		dclass = self._dclasses_by_name.get(dclass_name)
		
	if not dclass:
		dclass_name = dc_name
		dclass = self._dclasses_by_name.get(dclass_name)
		
	# Construct the distributed object.
	var class_def = self._dc_imports.get(dclass_name)
	if not class_def:
		print("[ConnectionRepository] ERROR: Could not construct an undefined %s" % dclass_name)
		return
		
	var dist_obj: DistributedObjectBase = class_def.new()
	dist_obj.repository = self
	dist_obj.dclass = dclass
	dist_obj.do_id = do_id
	dist_obj.parent_id = 0
	dist_obj.zone_id = 0
	dist_obj.name = "%d - %s" % [do_id, dclass_name]
	# Put the new distributed object into the dictionary.
	self._do_by_id[do_id] = dist_obj
	# generate_init is only called when constructed.
	dist_obj.generate_init()
	dist_obj.generate()
	# Add the distributed object to the scene graph and call the final generate.
	add_child(dist_obj)
	dist_obj.announce_generate()
	
	return dist_obj
	
## 
func read_dc_file(file_names: PackedStringArray = []) -> void:
	self._dc_imports.clear()
	self._dc_file.clear()
	
	if file_names.is_empty():
		# Load dc file paths from project config.
		if not ProjectSettings.has_setting("application/ardos/dc_files"):
			return
			
		file_names = ProjectSettings.get_setting("application/ardos/dc_files")
		
	for file_name in file_names:
		var dc_file_data = load("res://" + file_name)
		if not self._dc_file.read(dc_file_data):
			print("[ConnectionRepository] ERROR: Could not read dc file: ", file_name)
			return
		
		print("[ConnectionRepository]: Read: ", file_name)
			
	# Import all modules required by the DC file.
	# E.g. from scripts.characters import PlayerCharacter/AI/UD
	for n in range(self._dc_file.get_num_import_modules()):
		# Get the module name: E.g. scripts.characters
		var module_name: String = self._dc_file.get_import_module(n)
		# Convert the module name into a resource path.
		module_name = module_name.replace(".", "/")
		
		# Get the symbol names: E.g. PlayerCharacter/AI/UD
		var import_symbols: PackedStringArray = []
		for i in range(self._dc_file.get_num_import_symbols(n)):
			var symbol_name: String = self._dc_file.get_import_symbol(n, i)
			var suffixes: PackedStringArray = symbol_name.split("/")
			
			symbol_name = suffixes[0]
			suffixes = suffixes.slice(1, suffixes.size())
			
			if suffixes.has(dc_suffix):
				symbol_name += dc_suffix
			elif dc_suffix == "UD" and suffixes.has("AI"):
				symbol_name += "AI"
				
			import_symbols.append(symbol_name)
			
		self._import_module(module_name, import_symbols)
	
	# Now get the class definition for the classes named in the DC file.
	for i in range(self._dc_file.get_num_classes()):
		var dclass = self._dc_file.get_dc_class(i)
		var number = dclass.get_number()
		var cls_name = dclass.get_name() + dc_suffix
		
		# Does the class have a definition defined in dc imports?
		var has_cls: bool = self._dc_imports.has(cls_name)
		if not has_cls and dc_suffix == "UD":
			cls_name = dclass.get_name() + "AI"
			has_cls = self._dc_imports.has(cls_name)
			
		# Also try it whithout the suffix.
		if not has_cls:
			cls_name = dclass.get_name()
			has_cls = self._dc_imports.has(cls_name)
			
		if not has_cls:
			# N.B: This is not an error.
			# TODO: Change this to a debug print.
			print("No class definition for %s." % cls_name)
		
		self._dclasses_by_name[cls_name] = dclass
		if number >= 0:
			self._dclasses_by_number[number] = dclass
			
	# Owner views.
	if owner_views:
		var owner_dc_suffix = dc_suffix + "OV"
		# dict of class names (without 'OV') that have owner views.
		var owner_import_symbols: Dictionary = {}
		
		# Now import all of the modules required by the DC file.
		for n in range(self._dc_file.get_num_import_modules()):
			# Get the module name: E.g. scripts.characters
			var module_name: String = self._dc_file.get_import_module(n)
			# Convert the module name into a resource path.
			module_name = module_name.replace(".", "/")
			
			var import_symbols: PackedStringArray = []
			for i in range(self._dc_file.get_num_import_symbols(n)):
				var symbol_name: String = self._dc_file.get_import_symbol(n, i)
				var suffixes: PackedStringArray = symbol_name.split("/")
				
				symbol_name = suffixes[0]
				suffixes = suffixes.slice(1, suffixes.size())
				
				if suffixes.has(owner_dc_suffix):
					symbol_name += dc_suffix

				import_symbols.append(symbol_name)
				owner_import_symbols[symbol_name] = null
				
			self._import_module(module_name, import_symbols)
			
		# Now get the class definition for the owner classes named
		# in the DC file.
		for i in range(self._dc_file.get_num_classes()):
			var dclass = self._dc_file.get_dc_class(i)
			if owner_import_symbols.has(dclass.get_name() + owner_dc_suffix):
				var number = dclass.get_number()
				var cls_name = dclass.get_name() + owner_dc_suffix
				
				# Does the class have a definition defined in dc imports?
				assert(self._dc_imports.has(cls_name), "No class definition for %s." % cls_name)
				
				self._dclasses_by_name[cls_name] = dclass
			
##
func _import_module(module_name: String, import_symbols: PackedStringArray) -> void:
	for symbol_name in import_symbols:
		var import_path: String = "res://%s/%s.gd" % [module_name, symbol_name]
		assert(ResourceLoader.exists(import_path), "[ConnectionRepository] Symbol %s not defined in module %s." % [symbol_name, module_name])
		self._dc_imports[symbol_name] = load(import_path)

##
func _process(delta: float) -> void:
	# Poll for data.
	# This will also update the socket connection status.
	var error: int = self._socket.poll()
	
	# If we've had a state change of our connection status, handle it.
	if self.status != self._last_status:
		self._last_status = self.status
		match self.status:
			StreamPeerTCP.STATUS_NONE:
				_handle_disconnected()
			StreamPeerTCP.STATUS_CONNECTING:
				print("Connecting to host.")
			StreamPeerTCP.STATUS_CONNECTED:
				# Disable nagle's algorithm.
				self._socket.set_no_delay(true)
				_handle_connected()
			StreamPeerTCP.STATUS_ERROR:
				print("Error with socket stream.")
				_handle_disconnected()
		
	if self.status != StreamPeerTCP.STATUS_CONNECTED:
		return
	
	var available_bytes: int = self._socket.get_available_bytes()
	if available_bytes > 0:
		var data: Array = self._socket.get_partial_data(available_bytes)
		# Check for read error.
		if data[0] != OK:
			print("Error getting data from stream: ", data[0])
			return
		
		# We can't directly handle datagrams as it's possible that multiple have been
  		# buffered together, or we've received a split message.		
		var bytes: PackedByteArray = data[1]
		var size: int = bytes.size()
		
		# First, check if we have one, complete datagram.
		if self._data_buf.is_empty() && size >= DG_LENGTH_HEADER_SIZE:
			# Ok, we at least have a size header. Let's check if we have the full
			# datagram.
			var dg_size: int = bytes.decode_u16(0)
			if (dg_size == size - DG_LENGTH_HEADER_SIZE):
				# We have a complete datagram, lets handle it.
				var _di: DatagramIterator = DatagramIterator.new()
				var _dg: Datagram = Datagram.new()
				_dg.set_data(bytes)
				_di.set_data(_dg)
				_handle_datagram(_di)
				return
				
		# Hmm, we don't. Let's put it into our buffer.
		self._data_buf.append_array(bytes)
		self._process_buffer()

func _process_buffer() -> void:
	while self._data_buf.size() > DG_LENGTH_HEADER_SIZE:
		# We have enough data to know the expected length of the datagram.
		var dg_size: int = self._data_buf.decode_u16(0)
		if self._data_buf.size() >= dg_size + DG_LENGTH_HEADER_SIZE:
			# We have a complete datagram!
			var _di: DatagramIterator = DatagramIterator.new()
			var _dg: Datagram = Datagram.new()
			
			# +1 to make the slice end inclusive.
			var bytes: PackedByteArray = self._data_buf.slice(0, dg_size + DG_LENGTH_HEADER_SIZE + 1)
			_dg.set_data(bytes)
			_di.set_data(_dg)
			
			# Clear out the complete datagram from the data buffer.
			self._data_buf = self._data_buf.slice(dg_size + DG_LENGTH_HEADER_SIZE)
			
			_handle_datagram(_di)
		else:
			return
