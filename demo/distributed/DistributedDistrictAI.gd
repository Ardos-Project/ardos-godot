class_name DistributedDistrictAI extends DistributedObjectAI

var _district_name: String = ""
var _available: bool = false


func get_dc_name() -> String:
	return "DistributedDistrictAI"


func delete():
	self.b_set_available(0)
	super.delete()


func set_district_name(district_name: String) -> void:
	self._district_name = district_name


func get_district_name() -> String:
	return self._district_name


func d_set_district_name(district_name: String):
	self.send_update("set_district_name", [district_name])


func b_set_district_name(district_name: String):
	self.set_district_name(district_name)
	self.d_set_district_name(district_name)


func set_available(available: bool):
	self._available = available


func get_available() -> bool:
	return self._available


func d_set_available(available: bool):
	self.send_update("set_available", [available])


func b_set_available(available: bool):
	self.set_available(available)
	self.d_set_available(available)
