class_name ServerRepository extends ConnectionRepository


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
func allocate_channel() -> int:
	var channel: int = self.channel_allocator.allocate()
	if channel == -1:
		assert(false, "channelAllocator.allocate() is out of channels")
	
	return channel
