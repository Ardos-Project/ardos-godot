class_name DoInterestHandle extends RefCounted

"""
This class helps to ensure that valid handles get passed in to DoInterestManager funcs
"""

var _handle: int = 0


func _init(handle: int):
	self._handle = handle


func get_handle() -> int:
	return self._handle
