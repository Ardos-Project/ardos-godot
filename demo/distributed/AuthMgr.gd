class_name AuthMgr extends DistributedObject


func announce_generate():
	super.announce_generate()


##
func login(username: String):
	self.send_update("login", [username])
