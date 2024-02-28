class_name DistributedSmoothNode extends DistributedNode

enum _Flags { NEW_X = 0x01, NEW_Y = 0x02, NEW_Z = 0x04 }

# Target CharacterBody3D to smooth.
var _target_node: CharacterBody3D = null

var _broadcast_pos: bool = false
var _broadcast_pos_ival: float = 0.1
var _broadcast_delta: float = 0.0

# Used in determining whether we need to broadcast.
var _last_pos: Vector3 = Vector3()
# Used in determing where we're moving to.
var _target_pos: Vector3 = Vector3()

# Speed in which movement is lerped.
var _speed: float = 1.0


## This is *not* a distributed method.
## It exists to obfuscate away having to manually call set_smooth_* whenever
## the node this is bound to moves. It's a handy set-and-forget for things
## such as owner-views of controlled nodes (avatars), etc.
## Interval is the minimum delta time in seconds in which a broadcast should be
## sent to the server. Lower values may result in higher accuracy, but more
## network spam.
func set_broadcast_pos(enable: bool, interval: float = 0.1):
	self._broadcast_pos = true
	self._broadcast_pos_ival = interval


## This is *not* a distributed method.
## Sets the speed in which this node moves when lerping.
## This is generally set by a player controller of some sort, matched to
## the current animation rate playing.
func set_speed(speed: float):
	self._speed = speed


# TODO: This class needs to be more general than just CharacterBodies.
# We should be able to just access the `self.node` property instead of using it
# as a container. This will require moving away from `move_and_slide` and doing
# the lerping/smoothing ourselves.
func set_target_smooth_node(target: CharacterBody3D):
	self._target_node = target


func set_x(x: float):
	_target_pos.x = x
	super.set_x(x)


func set_y(y: float):
	_target_pos.y = y
	super.set_y(y)


func set_z(z: float):
	_target_pos.z = z
	super.set_z(z)


##
func set_smooth_x(x: float):
	self._target_pos.x = x


##
func d_set_smooth_x(x: float):
	self.send_update("setSmoothX", [x])


##
func b_set_smooth_x(x: float):
	self.set_smooth_x(x)
	self.d_set_smooth_x(x)


##
func set_smooth_y(y: float):
	self._target_pos.y = y


##
func d_set_smooth_y(y: float):
	self.send_update("setSmoothY", [y])


##
func b_set_smooth_y(y: float):
	self.set_smooth_y(y)
	self.d_set_smooth_y(y)


##
func set_smooth_z(z: float):
	self._target_pos.z = z


##
func d_set_smooth_z(z: float):
	self.send_update("setSmoothZ", [z])


##
func b_set_smooth_z(z: float):
	self.set_smooth_z(z)
	self.d_set_smooth_z(z)


##
func set_smooth_pos(x: float, y: float, z: float):
	self.set_smooth_x(x)
	self.set_smooth_y(y)
	self.set_smooth_z(z)


##
func d_set_smooth_pos(x: float, y: float, z: float):
	self.send_update("setSmoothPos", [x, y, z])


##
func b_set_smooth_pos(x: float, y: float, z: float):
	self.set_smooth_pos(x, y, z)
	self.d_set_smooth_pos(x, y, z)


## Returns true if at least some of the bits of compare are set in flags, but
## no bits outside of compare are set. That is to say, that the only things
## that are changed are the bits indicated in compare.
func _has_flag_changed(flags: int, compare: int) -> bool:
	return (flags & compare) != 0 and (flags & ~compare) == 0


##
func _send_broadcast_pos():
	var curr_pos: Vector3 = self._target_node.get_position()
	var flags: int = 0

	if not is_equal_approx(curr_pos.x, self._last_pos.x):
		flags |= _Flags.NEW_X

	if not is_equal_approx(curr_pos.y, self._last_pos.y):
		flags |= _Flags.NEW_Y

	if not is_equal_approx(curr_pos.z, self._last_pos.z):
		flags |= _Flags.NEW_Z

	# Only X has changed.
	if self._has_flag_changed(flags, _Flags.NEW_X):
		self.d_set_smooth_x(curr_pos.x)
	# Only Y has changed.
	elif self._has_flag_changed(flags, _Flags.NEW_Y):
		self.d_set_smooth_y(curr_pos.y)
	# Only Z has changed.
	elif self._has_flag_changed(flags, _Flags.NEW_Z):
		self.d_set_smooth_z(curr_pos.z)
	# Otherwise, if at least 2 flags have changed, send everything.
	elif flags != 0:
		self.d_set_smooth_pos(curr_pos.x, curr_pos.y, curr_pos.z)

	self._last_pos = curr_pos


## We do the actual smoothing logic in the physics process step.
func _physics_process(delta):
	if not self.is_generated() or not self._target_node:
		return

	# If we've enabled position broadcasting, we can assume we have an OV of
	# this object and handle the smoothing locally. All we need to do is
	# broadcast our current pos to the server when appropriate.
	if self._broadcast_pos:
		self._broadcast_delta += delta
		if self._broadcast_delta >= self._broadcast_pos_ival:
			self._broadcast_delta = 0
			self._send_broadcast_pos()

	# Otherwise, this a remote object that has come off of the server.
	# We can use a combination of the nodes velocity and `move_and_slide()` to lerp.
	else:
		var direction: Vector3 = self._target_node.position.direction_to(_target_pos)
		if not direction.is_zero_approx():
			self._target_node.velocity.x = direction.x * self._speed
			self._target_node.velocity.y = direction.y * self._speed
			self._target_node.velocity.z = direction.z * self._speed
		else:
			self._target_node.velocity.x = move_toward(self._target_node.velocity.x, 0, self._speed)
			self._target_node.velocity.y = move_toward(self._target_node.velocity.y, 0, self._speed)
			self._target_node.velocity.z = move_toward(self._target_node.velocity.z, 0, self._speed)

	# move_and_slide does the heavy lifting here.
	self._target_node.move_and_slide()
