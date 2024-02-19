class_name DemoServerAI extends ServerRepository

var district_name: String = ""
var district_id: int = 0

var _district: DistributedDistrictAI = null


func _init(
	dc_file_names: PackedStringArray = [],
	suffix: String = "",
	min_channel: int = 0,
	max_channel: int = 0,
	stateserver_id: int = 0,
	district_name: String = ""
):
	super._init(dc_file_names, suffix, min_channel, max_channel, stateserver_id)

	self.set_game_do_id(4619)

	self.district_name = district_name


func _handle_connected():
	super._handle_connected()

	# Set our connection name with Ardos.
	self.set_con_name("DemoClientAI(%s)" % self.district_name)

	self.district_id = self.allocate_channel()

	# Generate the distributed object to represent this district.
	# Clients will automatically discover these by setting interest
	# in the "management" zone.
	self._district = DistributedDistrictAI.new()
	self._district.set_district_name(self.district_name)
	self._district.generate_with_required_and_id(self.district_id, self.get_game_do_id(), 2)
	self._district.set_ai(self.our_channel)

	self._district.b_set_available(1)

	print("District '%s' online!" % self.district_name)
