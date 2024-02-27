class_name DistributedDistrict extends DistributedObject

static var DISTRICTS: Array = []

var _name: String = ""
var _available: bool = false


func announce_generate():
	super.announce_generate()

	DISTRICTS.append(self)


func delete():
	super.delete()

	DISTRICTS.erase(self)


func set_district_name(district_name: String) -> void:
	self._name = district_name


func set_available(available: bool) -> void:
	self._available = available
