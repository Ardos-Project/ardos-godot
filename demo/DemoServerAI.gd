class_name DemoServerAI extends ServerRepository


func _init(
	dc_file_names: PackedStringArray = [],
	dc_suffix: String = "",
	min_channel: int = 0,
	max_channel: int = 0
):
	super._init(dc_file_names, dc_suffix, min_channel, max_channel)
