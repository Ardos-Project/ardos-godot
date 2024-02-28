class_name DistributedNodeAI extends DistributedObjectAI

var node: Node3D = null


func _ready():
	node = Node3D.new()
	add_child(node)


##
func set_x(x: float):
	self.node.position.x = x


##
func get_x() -> float:
	return self.node.position.x


##
func d_set_x(x: float):
	self.send_update("setX", [x])


##
func b_set_x(x: float):
	self.set_x(x)
	self.d_set_x(x)


##
func set_y(y: float):
	self.node.position.y = y


##
func get_y() -> float:
	return self.node.position.y


##
func d_set_y(y: float):
	self.send_update("setY", [y])


##
func b_set_y(y: float):
	self.set_y(y)
	self.d_set_y(y)


##
func set_z(z: float):
	self.node.position.z = z


##
func get_z() -> float:
	return self.node.position.z


##
func d_set_z(z: float):
	self.send_update("setZ", [z])


##
func b_set_z(z: float):
	self.set_z(z)
	self.d_set_z(z)


##
func set_h(h: float):
	self.node.rotation_degrees.x = h


##
func get_h() -> float:
	return self.node.rotation_degrees.x


##
func d_set_h(h: float):
	self.send_update("setH", [h])


##
func b_set_h(h: float):
	self.set_h(h)
	self.d_set_h(h)


##
func set_p(p: float):
	self.node.rotation_degrees.y = p


##
func get_p() -> float:
	return self.node.rotation_degrees.y


##
func d_set_p(p: float):
	self.send_update("setP", [p])


##
func b_set_p(p: float):
	self.set_p(p)
	self.d_set_p(p)


##
func set_r(r: float):
	self.node.rotation_degrees.z = r


##
func get_r() -> float:
	return self.node.rotation_degrees.z


##
func d_set_r(r: float):
	self.send_update("setR", [r])


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
func get_pos() -> Array:
	return [self.get_x(), self.get_y(), self.get_z()]


##
func d_set_pos(x: float, y: float, z: float):
	self.send_update("setPos", [x, y, z])


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
func get_hpr() -> Array:
	return [self.get_h(), self.get_p(), self.get_r()]


##
func d_set_hpr(h: float, p: float, r: float):
	self.send_update("setHpr", [h, p, r])


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
	self.send_update("setPosHpr", [x, y, z, h, p, r])


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
	self.send_update("setXy", [x, y])


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
	self.send_update("setXz", [x, z])


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
	self.send_update("setXyh", [x, y, h])


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
	self.send_update("setXyzh", [x, y, z, h])


##
func b_set_xyzh(x: float, y: float, z: float, h: float):
	self.set_xyzh(x, y, z, h)
	self.d_set_xyzh(x, y, z, h)
