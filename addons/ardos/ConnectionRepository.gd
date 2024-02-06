class_name ConnectionRepository extends Node

"""
This is a base class for things that know how to establish a
connection (and exchange datagrams) with Ardos.
This includes ClientRepository and ServerRepository.
"""

signal connected_to_server()
signal disconnected_from_server()


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


func _init():
	pass

##
func _connect_to_server(host: String, port: int) -> void:
	# connect() would be a better name here,
	# but shadows signalling 'connect()' 
	self._last_status = StreamPeerTCP.STATUS_NONE
	if self._socket.connect_to_host(host, port) != OK:
		self.disconnected_from_server.emit()
		return
		
	# Disable nagle's algorithm.
	self._socket.set_no_delay(true)
	
	# Connected callback.
	_handle_connected()
	
	## Emit the connected signal.
	#self.connected_to_server.emit()
	
## Inheritors should override.
func _handle_connected():
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
	if self.status != StreamPeerTCP.STATUS_CONNECTED:
		return
	
	self._last_status = status
	
	var available_bytes: int = self._socket.get_available_bytes()
	if available_bytes > 0:
		var data: Array = self._socket.get_partial_data(available_bytes)
		# Check for read error.
		if data[0] != OK:
				print("Error getting data from stream: ", data[0])
				

