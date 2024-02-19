class_name DoInterestManager extends Node

const NO_CONTEXT: int = 0

# int -> DoInterestState
var _interests: Dictionary = {}

# 'handle' is a number that represents a single interest set that the
# client has requested; the interest set may be modified.
var _handle_serial_num: int = 0
# High bit is reserved for server interests.
var _handle_mask: int = 0x7FFF

# 'context' refers to a single request to change an interest set.
var _context_serial_num: int = 100
var _context_mask = 0x3FFFFFFF


##
func _get_next_handle() -> int:
	var handle: int = self._handle_serial_num
	while true:
		handle = (handle + 1) & self._handle_mask
		# Skip handles that are already in use
		if not self._interests.has(handle):
			break

		print("[DoInterestManager] WARNING: Interest %d already in use!" % [handle])

	self._handle_serial_num = handle
	return handle


func _get_next_context() -> int:
	var context_id: int = self._context_serial_num
	while true:
		context_id = (context_id + 1) & self._context_mask
		# skip over the 'no context' id
		if context_id != self.NO_CONTEXT:
			break

	self._context_serial_num = context_id
	return context_id


func _handle_interest_done(di: DatagramIterator):
	var context_id: int = di.get_uint32()
	var handle: int = di.get_uint16()

	if not self._interests.has(handle):
		print("[DoInterestManager] WARNING: Handle not found: %d" % handle)
		return

	# If the context matches, send out the callback.
	if self._interests[handle]._context == context_id:
		self._interests[handle]._context = NO_CONTEXT

		if self._interest[handle]._callback.is_valid():
			self._interests[handle]._callback.call()

	self._consider_remove_interest(handle)


## Consider whether we should cull the interest set.
func _consider_remove_interest(handle: int) -> void:
	if self._interests.has(handle):
		if self._interests[handle].is_pending_delete():
			# Make sure there is no pending event for this interest.
			if self._interests[handle]._context == NO_CONTEXT:
				self._interests[handle] = null
