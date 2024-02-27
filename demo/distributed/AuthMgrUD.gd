class_name AuthMgrUD extends DistributedObjectUD


func login(username: String):
	print("Hello from client! Username: %s" % username)

	var sender: int = self.air.get_msg_sender()

	# Allocate a DoId for the players account.
	# This would usually be resolved via auth.
	var acc_id: int = self.air.allocate_channel()

	# Allocate a DoId for the players avatar.
	# This would usually be stored on an account object of some sort.
	var av_id: int = self.air.allocate_channel()

	# Eject anyone currently logged into the account.
	# NOTE: This won't do anything in this demo as account id's are random.
	self.air.client_eject(
		self.get_account_connection_channel(acc_id),
		100,
		"This account has been logged in from elsewhere."
	)

	# Instruct the client to start receiving messages that are sent to their account channel.
	# If we did this before the above eject, this client would be ejected.
	self.air.client_open_channel(sender, self.get_account_connection_channel(acc_id))

	# Update the sender channel of the client to contain both their account id
	# and avatar id. This is useful later on when we want to identify a client
	# simply via `get_msg_sender()`. Channels are 64-bit, so we pack
	# the hi 32-bits with the account id, and the lo 32-bits with the avatar id.
	self.air.client_set_sender_channel(sender, acc_id << 32 | av_id)

	# Move the client into an established state.
	# This allows them to communicate with non-anonymous UD's, and from the
	# perspective of Ardos, they are now fully privileged within the cluster.
	self.air.client_set_auth_state(sender, ServerRepository.ClientAuthState.AUTH_STATE_ESTABLISHED)

	# Generate the DistributedAvatarAI object for this client.
	var av: DistributedAvatarAI = DistributedAvatarAI.new(self.air)
	av.set_avatar_name(username)
	av.generate_with_required_and_id(av_id, 0, 0)

	# Instruct the client to start receiving messages that are sent to their avatar channel.
	self.air.client_open_channel(sender, self.get_avatar_connection_channel(av_id))

	# Grant ownership of the newly generated avatar to the client.
	# This allows the client to send `ownsend` field updates.
	self.air.client_add_owner_object(acc_id << 32 | av_id, av_id)

	# Add the avatar as a session object for the client.
	# If the client disconnects, the object is automatically deleted.
	# If the object is deleted while the client is connected, the client is ejected.
	self.air.client_add_session_object(self.get_account_connection_channel(sender), av_id)
