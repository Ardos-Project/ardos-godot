extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	# Load the DCFile data.
	var dc_file_res = load("res://data/demo.dc")
	
	# Create a new DCFile and read in the above data.
	var dc_file = GDDCFile.new()
	dc_file.read(dc_file_res)
	
	# Print out some information about the DC file.
	print(dc_file.get_num_classes())
	dc_file.clear()
	print(dc_file.get_num_classes())
