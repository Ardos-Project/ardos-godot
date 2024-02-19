class_name DoInterestState extends RefCounted

enum State { StateActive, StatePendingDel }

var _description: String = ""
var _state: State
var _context: int = 0
var _callback: Callable
var _parent_id: int = 0
var _zone_ids: Array = []


func _init(
	description: String,
	state: State,
	context: int,
	callback: Callable,
	parent_id: int,
	zone_ids: Array
):
	self._description = description
	self._state = state
	self._context = context
	self._callback = callback
	self._parent_id = parent_id
	self._zone_ids = zone_ids


func is_pending_delete() -> bool:
	return self._state == State.StatePendingDel
