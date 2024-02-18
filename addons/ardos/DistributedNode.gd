class_name DistributedNode extends DistributedObject

var node: Node3D = null


func _ready():
	node = Node3D.new()
	add_child(node)


##
func set_x(x: float):
	self.node.position.x = x


##
func d_set_x(x: float):
	self.send_update("set_x", [x])


##
func b_set_x(x: float):
	self.set_x(x)
	self.d_set_x(x)


##
func set_y(y: float):
	self.node.position.y = y


##
func d_set_y(y: float):
	self.send_update("set_y", [y])


##
func b_set_y(y: float):
	self.set_y(y)
	self.d_set_y(y)


##
func set_z(z: float):
	self.node.position.z = z


##
func d_set_z(z: float):
	self.send_update("set_z", [z])


##
func b_set_z(z: float):
	self.set_z(z)
	self.d_set_z(z)


##
func set_h(h: float):
	self.node.rotation_degrees.x = h


##
func d_set_h(h: float):
	self.send_update("set_h", [h])


##
func b_set_h(h: float):
	self.set_h(h)
	self.d_set_h(h)


##
func set_p(p: float):
	self.node.rotation_degrees.y = p


##
func d_set_p(p: float):
	self.send_update("set_p", [p])


##
func b_set_p(p: float):
	self.set_p(p)
	self.d_set_p(p)


##
func set_r(r: float):
	self.node.rotation_degrees.z = r


##
func d_set_r(r: float):
	self.send_update("set_r", [r])


##
func b_set_r(r: float):
	self.set_r(r)
	self.d_set_r(r)


##
func set_pos(x: float, y: float, z: float):
	self.set_x(x)
	self.set_y(y)
	self.set_z(z)


##
func d_set_pos(x: float, y: float, z: float):
	self.send_update("set_pos", [x, y, z])


##
func b_set_pos(x: float, y: float, z: float):
	self.set_pos(x, y, z)
	self.d_set_pos(x, y, z)


##
func set_hpr(h: float, p: float, r: float):
	self.set_h(h)
	self.set_p(p)
	self.set_r(r)


##
func d_set_hpr(h: float, p: float, r: float):
	self.send_update("set_hpr", [h, p, r])


##
func b_set_hpr(h: float, p: float, r: float):
	self.set_hpr(h, p, r)
	self.d_set_hpr(h, p, r)


##
func set_pos_hpr(x: float, y: float, z: float, h: float, p: float, r: float):
	self.set_pos(x, y, z)
	self.set_hpr(h, p, r)


##
func d_set_pos_hpr(x: float, y: float, z: float, h: float, p: float, r: float):
	self.send_update("set_pos_hpr", [x, y, z, h, p, r])


##
func b_set_pos_hpr(x: float, y: float, z: float, h: float, p: float, r: float):
	self.set_pos_hpr(x, y, z, h, p, r)
	self.d_set_pos_hpr(x, y, z, h, p, r)


##
func set_xy(x: float, y: float):
	self.set_x(x)
	self.set_y(y)


##
func d_set_xy(x: float, y: float):
	self.send_update("set_xy", [x, y])


##
func b_set_xy(x: float, y: float):
	self.set_xy(x, y)
	self.d_set_xy(x, y)


##
func set_xz(x: float, z: float):
	self.set_x(x)
	self.set_z(z)


##
func d_set_xz(x: float, z: float):
	self.send_update("set_xz", [x, z])


##
func b_set_xz(x: float, z: float):
	self.set_xz(x, z)
	self.d_set_xz(x, z)


##
func set_xyh(x: float, y: float, h: float):
	self.set_x(x)
	self.set_y(y)
	self.set_h(h)


##
func d_set_xyh(x: float, y: float, h: float):
	self.send_update("set_xyh", [x, y, h])


##
func b_set_xyh(x: float, y: float, h: float):
	self.set_xyh(x, y, h)
	self.d_set_xyh(x, y, h)


##
func set_xyzh(x: float, y: float, z: float, h: float):
	self.set_x(x)
	self.set_y(y)
	self.set_z(z)
	self.set_h(h)


##
func d_set_xyzh(x: float, y: float, z: float, h: float):
	self.send_update("set_xyzh", [x, y, z, h])


##
func b_set_xyzh(x: float, y: float, z: float, h: float):
	self.set_xyzh(x, y, z, h)
	self.d_set_xyzh(x, y, z, h)
