class_name DistributedAvatarOV extends DistributedAvatar

"""
Owner view of a DistributedAvatar which implements camera controls and
movement input.
"""

var GRAVITY = ProjectSettings.get_setting("physics/3d/default_gravity")
const JUMP_VELOCITY = 4.5

const WALK_SPEED = 3.0
const RUN_SPEED = 5.0

const SENS_HORIZONTAL = 0.5
const SENS_VERTICAL = 0.5

@onready var _pick_name_container = get_node("/root/Root/UI/PickNameContainer")
@onready var _local_camera = get_tree().get_first_node_in_group("local_camera")

var _cur_speed: float = 0.0
var _running: bool = false
var _anim_locked: bool = false


func _ready():
	super._ready()

	# Reparent the local camera.
	self._local_camera.reparent(_avatar_node, false)
	self._local_camera.get_node("Camera3D").position = Vector3(0, 2.276, 3.168)

	# Start broadcasting our position.
	self.set_broadcast_pos(true)

	# We could do this in AuthMgrUD acceptLogin() function,
	# but just do it here for simplicity.
	self._pick_name_container.visible = false

	# Capture the mouse.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func d_set_anim_state(state: String):
	self.send_update("set_anim_state", [state])


func b_set_anim_state(state: String):
	self.set_anim_state(state)
	self.d_set_anim_state(state)


func _input(event):
	if not self.is_generated():
		return

	if event is InputEventMouseButton and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		# Capture the mouse.
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if Input.is_action_just_pressed("esc"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		self._avatar_node.rotate_y(deg_to_rad(-event.relative.x * SENS_HORIZONTAL))
		self._avatar_node.get_node("Visuals").rotate_y(
			deg_to_rad(event.relative.x * SENS_HORIZONTAL)
		)
		self._local_camera.rotate_x(deg_to_rad(-event.relative.y * SENS_HORIZONTAL))


func _physics_process(delta):
	if not self.is_generated():
		return

	if not self._avatar_anim.is_playing():
		self._anim_locked = false

	if Input.is_action_just_pressed("kick"):
		if self._avatar_anim.current_animation != "kick":
			self.b_set_anim_state("kick")
			self._anim_locked = true

	# Handle gravity.
	if not self._avatar_node.is_on_floor():
		self._avatar_node.velocity.y -= GRAVITY * delta

	# Don't bother running movement input handling if we're anim locked.
	if self._anim_locked:
		return

	_running = Input.is_action_pressed("run")
	if _running:
		_cur_speed = RUN_SPEED
	else:
		_cur_speed = WALK_SPEED

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and self._avatar_node.is_on_floor():
		self._avatar_node.velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (
		(self._avatar_node.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	)
	if direction:
		if not _running and self._avatar_anim.current_animation != "walking":
			self.b_set_anim_state("walking")

		if _running and self._avatar_anim.current_animation != "running":
			self.b_set_anim_state("running")

		if !self._anim_locked and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			self._avatar_node.get_node("Visuals").look_at(self._avatar_node.position + direction)

		self._avatar_node.velocity.x = direction.x * _cur_speed
		self._avatar_node.velocity.z = direction.z * _cur_speed
	else:
		if self._avatar_anim.current_animation != "idle":
			self.b_set_anim_state("idle")

		self._avatar_node.velocity.x = move_toward(self._avatar_node.velocity.x, 0, _cur_speed)
		self._avatar_node.velocity.z = move_toward(self._avatar_node.velocity.z, 0, _cur_speed)

	# Make sure DistributedSmoothNode gets a chance to broadcast our position.
	super._physics_process(delta)
