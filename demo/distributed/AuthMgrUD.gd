class_name AuthMgrUD extends DistributedObjectUD


func login(username: String):
	print("Hello from client! Username: %s" % username)

	var sender: int = self.air.get_msg_sender()

	# Allocate a DoId for the players avatar.
	# This would usually be stored on an account object of some sort.
	var av_id: int = self.air.allocate_channel()

	# Un-sandbox them!
	var _dg: Datagram = Datagram.new()
	_dg.add_server_header(sender, self.air.our_channel, MessageTypes.CLIENTAGENT_SET_STATE)
	_dg.add_uint16(2)  # ESTABLISHED
	self.air.send(_dg)

	var av: DistributedAvatarAI = DistributedAvatarAI.new(self.air)

	# Grant ownership of the newly generated avatar to the client.
	# This allows the client to send `ownsend` field updates.
	_dg = Datagram.new()
	_dg.add_server_header(av_id, self.air.our_channel, MessageTypes.STATESERVER_OBJECT_SET_OWNER)
	_dg.add_uint64(sender)
	self.air.send(_dg)

	# Add the avatar as a session object for the client.
	self.air.client_add_session_object(sender, av_id)
