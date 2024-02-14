class_name AuthMgr extends DistributedObject


func announce_generate():
	super.announce_generate()

	# Say hello to the AuthMgrUD!
	self.send_update("login", ["godot-client"])
