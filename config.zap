opt server_output = "src/server/network.luau"
opt client_output = "src/client/network.luau"

event entityUpdate = {
	from: Server,
	type: Reliable,
	call: SingleAsync,
	data: struct {
		id: u32,
		components: struct {component: string, value: enum "type" {
			model {value: Instance},
			placed {value: string},
			remove {value: string},
			cellOccupation {value: Vector3[]}
		}}[]
	}[]
}

event destroyEntity = {
	from: Server,
	type: Reliable,
	call: SingleAsync,
	data: struct {
		id: u32
	}[]
}

event placeItem = {
	from: Client,
	type: Reliable,
	call: ManyAsync,
	data: struct {
		item: string,
		origin: Vector3,
		rotation: CFrame,
		offset: Vector3,
		mouseCell: Vector3,
		normal: Vector3
	}
}

event deleteItem = {
	from: Client,
	type: Reliable,
	call: ManyAsync,
	data: u32
}

event gridData = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: struct {
		cell: Vector3,
		occupied: boolean
	}[]
}

event gridUpdate = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: struct {
		cell: Vector3,
		occupied: boolean
	}[]
}

event requestData = {
	from: Client,
	type: Reliable,
	call: SingleAsync
}

event retrieveData = {
	from: Client,
	type: Reliable,
	call: ManyAsync,
	data: boolean?
}

event replicatorUpdate = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: struct {
		state: unknown,
		player: Instance (Player),
		index: string
	}
}

event sendNotification = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: struct {
		duration: u8?,
		text: string,
		color: Color3?
	}
}