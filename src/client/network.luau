--!native
--!optimize 2
--!nocheck
--!nolint
--#selene: allow(unused_variable, incorrect_standard_library_use, global_usage)
-- Client generated by Zap v0.6.8 (https://github.com/red-blox/zap)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local outgoing_buff: buffer
local outgoing_used: number
local outgoing_size: number
local outgoing_inst: { Instance }
local outgoing_apos: number

local incoming_buff: buffer
local incoming_read: number
local incoming_inst: { Instance }
local incoming_ipos: number

-- thanks to https://dom.rojo.space/binary.html#cframe
local CFrameSpecialCases = {
	CFrame.Angles(0, 0, 0),
	CFrame.Angles(math.rad(90), 0, 0),
	CFrame.Angles(0, math.rad(180), math.rad(180)),
	CFrame.Angles(math.rad(-90), 0, 0),
	CFrame.Angles(0, math.rad(180), math.rad(90)),
	CFrame.Angles(0, math.rad(90), math.rad(90)),
	CFrame.Angles(0, 0, math.rad(90)),
	CFrame.Angles(0, math.rad(-90), math.rad(90)),
	CFrame.Angles(math.rad(-90), math.rad(-90), 0),
	CFrame.Angles(0, math.rad(-90), 0),
	CFrame.Angles(math.rad(90), math.rad(-90), 0),
	CFrame.Angles(0, math.rad(90), math.rad(180)),
	CFrame.Angles(0, math.rad(-90), math.rad(180)),
	CFrame.Angles(0, math.rad(180), math.rad(0)),
	CFrame.Angles(math.rad(-90), math.rad(-180), math.rad(0)),
	CFrame.Angles(0, math.rad(0), math.rad(180)),
	CFrame.Angles(math.rad(90), math.rad(180), math.rad(0)),
	CFrame.Angles(0, math.rad(0), math.rad(-90)),
	CFrame.Angles(0, math.rad(-90), math.rad(-90)),
	CFrame.Angles(0, math.rad(-180), math.rad(-90)),
	CFrame.Angles(0, math.rad(90), math.rad(-90)),
	CFrame.Angles(math.rad(90), math.rad(90), 0),
	CFrame.Angles(0, math.rad(90), 0),
	CFrame.Angles(math.rad(-90), math.rad(90), 0),
}

local function alloc(len: number)
	if outgoing_used + len > outgoing_size then
		while outgoing_used + len > outgoing_size do
			outgoing_size = outgoing_size * 2
		end

		local new_buff = buffer.create(outgoing_size)
		buffer.copy(new_buff, 0, outgoing_buff, 0, outgoing_used)

		outgoing_buff = new_buff
	end

	outgoing_apos = outgoing_used
	outgoing_used = outgoing_used + len

	return outgoing_apos
end

local function read(len: number)
	local pos = incoming_read
	incoming_read = incoming_read + len

	return pos
end

local function save()
	return {
		buff = outgoing_buff,
		used = outgoing_used,
		size = outgoing_size,
		inst = outgoing_inst,
	}
end

local function load(data: {
	buff: buffer,
	used: number,
	size: number,
	inst: { Instance },
})
	outgoing_buff = data.buff
	outgoing_used = data.used
	outgoing_size = data.size
	outgoing_inst = data.inst
end

local function load_empty()
	outgoing_buff = buffer.create(64)
	outgoing_used = 0
	outgoing_size = 64
	outgoing_inst = {}
end

load_empty()

local types = {}
if not RunService:IsRunning() then
	local noop = function() end
	return table.freeze({
		SendEvents = noop,
		entityUpdate = table.freeze({
			SetCallback = noop
		}),
		destroyEntity = table.freeze({
			SetCallback = noop
		}),
		placeItem = table.freeze({
			Fire = noop
		}),
		deleteItem = table.freeze({
			Fire = noop
		}),
		gridData = table.freeze({
			On = noop
		}),
		gridUpdate = table.freeze({
			On = noop
		}),
		requestData = table.freeze({
			Fire = noop
		}),
		retrieveData = table.freeze({
			Fire = noop
		}),
		replicatorUpdate = table.freeze({
			On = noop
		}),
		sendNotification = table.freeze({
			On = noop
		}),
	}) :: Events
end
if RunService:IsServer() then
	error("Cannot use the client module on the server!")
end
local reliable = ReplicatedStorage:WaitForChild("ZAP_RELIABLE")
local unreliable = ReplicatedStorage:WaitForChild("ZAP_UNRELIABLE")

assert(reliable:IsA("RemoteEvent"), "Expected ZAP_RELIABLE to be a RemoteEvent")
assert(unreliable:IsA("UnreliableRemoteEvent"), "Expected ZAP_UNRELIABLE to be an UnreliableRemoteEvent")


local function SendEvents()
	if outgoing_used ~= 0 then
		local buff = buffer.create(outgoing_used)
		buffer.copy(buff, 0, outgoing_buff, 0, outgoing_used)

		reliable:FireServer(buff, outgoing_inst)

		outgoing_buff = buffer.create(64)
		outgoing_used = 0
		outgoing_size = 64
		table.clear(outgoing_inst)
	end
end

RunService.Heartbeat:Connect(SendEvents)

local events = table.create(10)
local event_queue: { [number]: { any } } = table.create(10)
event_queue[1] = {}
event_queue[2] = {}
events[5] = {}
event_queue[5] = {}
events[6] = {}
event_queue[6] = {}
events[9] = {}
event_queue[9] = {}
events[10] = {}
event_queue[10] = {}
reliable.OnClientEvent:Connect(function(buff, inst)
	incoming_buff = buff
	incoming_inst = inst
	incoming_read = 0
	incoming_ipos = 0
	local len = buffer.len(buff)
	while incoming_read < len do
		local id = buffer.readu8(buff, read(1))
		if id == 1 then
			local value
			value = {}
			local len_1 = buffer.readu16(incoming_buff, read(2))
			for i_1 = 1, len_1 do
				local val_1
				val_1 = {}
				val_1.id = buffer.readu32(incoming_buff, read(4))
				val_1.components = {}
				local len_2 = buffer.readu16(incoming_buff, read(2))
				for i_2 = 1, len_2 do
					local val_2
					val_2 = {}
					local len_3 = buffer.readu16(incoming_buff, read(2))
					val_2.component = buffer.readstring(incoming_buff, read(len_3), len_3)
					val_2.value = {}
					local enum_value_1 = buffer.readu8(incoming_buff, read(1))
					if enum_value_1 == 0 then
						val_2.value.type = "model"
						incoming_ipos = incoming_ipos + 1
						val_2.value.value = incoming_inst[incoming_ipos]
						assert(val_2.value.value ~= nil)
					elseif enum_value_1 == 1 then
						val_2.value.type = "placed"
						local len_4 = buffer.readu16(incoming_buff, read(2))
						val_2.value.value = buffer.readstring(incoming_buff, read(len_4), len_4)
					elseif enum_value_1 == 2 then
						val_2.value.type = "remove"
						local len_5 = buffer.readu16(incoming_buff, read(2))
						val_2.value.value = buffer.readstring(incoming_buff, read(len_5), len_5)
					elseif enum_value_1 == 3 then
						val_2.value.type = "cellOccupation"
						val_2.value.value = {}
						local len_6 = buffer.readu16(incoming_buff, read(2))
						for i_3 = 1, len_6 do
							local val_3
							val_3 = Vector3.new(buffer.readf32(incoming_buff, read(4)), buffer.readf32(incoming_buff, read(4)), buffer.readf32(incoming_buff, read(4)))
							val_2.value.value[i_3] = val_3
						end
					else
						error("Invalid variant")
					end
					val_1.components[i_2] = val_2
				end
				value[i_1] = val_1
			end
			if events[1] then
				task.spawn(events[1], value)
			else
				table.insert(event_queue[1], value)
				if #event_queue[1] > 64 then
					warn(`[ZAP] {#event_queue[1]} events in queue for entityUpdate. Did you forget to attach a listener?`)
				end
			end
		elseif id == 2 then
			local value
			value = {}
			local len_1 = buffer.readu16(incoming_buff, read(2))
			for i_1 = 1, len_1 do
				local val_1
				val_1 = {}
				val_1.id = buffer.readu32(incoming_buff, read(4))
				value[i_1] = val_1
			end
			if events[2] then
				task.spawn(events[2], value)
			else
				table.insert(event_queue[2], value)
				if #event_queue[2] > 64 then
					warn(`[ZAP] {#event_queue[2]} events in queue for destroyEntity. Did you forget to attach a listener?`)
				end
			end
		elseif id == 5 then
			local value
			value = {}
			local len_1 = buffer.readu16(incoming_buff, read(2))
			for i_1 = 1, len_1 do
				local val_1
				val_1 = {}
				val_1.cell = Vector3.new(buffer.readf32(incoming_buff, read(4)), buffer.readf32(incoming_buff, read(4)), buffer.readf32(incoming_buff, read(4)))
				val_1.occupied = buffer.readu8(incoming_buff, read(1)) == 1
				value[i_1] = val_1
			end
			if events[5][1] then
				for _, cb in events[5] do
					task.spawn(cb, value)
				end
			else
				table.insert(event_queue[5], value)
				if #event_queue[5] > 64 then
					warn(`[ZAP] {#event_queue[5]} events in queue for gridData. Did you forget to attach a listener?`)
				end
			end
		elseif id == 6 then
			local value
			value = {}
			local len_1 = buffer.readu16(incoming_buff, read(2))
			for i_1 = 1, len_1 do
				local val_1
				val_1 = {}
				val_1.cell = Vector3.new(buffer.readf32(incoming_buff, read(4)), buffer.readf32(incoming_buff, read(4)), buffer.readf32(incoming_buff, read(4)))
				val_1.occupied = buffer.readu8(incoming_buff, read(1)) == 1
				value[i_1] = val_1
			end
			if events[6][1] then
				for _, cb in events[6] do
					task.spawn(cb, value)
				end
			else
				table.insert(event_queue[6], value)
				if #event_queue[6] > 64 then
					warn(`[ZAP] {#event_queue[6]} events in queue for gridUpdate. Did you forget to attach a listener?`)
				end
			end
		elseif id == 9 then
			local value
			value = {}
			if buffer.readu8(incoming_buff, read(1)) == 1 then
				incoming_ipos = incoming_ipos + 1
				value.state = incoming_inst[incoming_ipos]
			else
				value.state = nil
			end
			incoming_ipos = incoming_ipos + 1
			value.player = incoming_inst[incoming_ipos]
			assert(value.player ~= nil)
			assert(value.player:IsA("Player"))
			local len_1 = buffer.readu16(incoming_buff, read(2))
			value.index = buffer.readstring(incoming_buff, read(len_1), len_1)
			if events[9][1] then
				for _, cb in events[9] do
					task.spawn(cb, value)
				end
			else
				table.insert(event_queue[9], value)
				if #event_queue[9] > 64 then
					warn(`[ZAP] {#event_queue[9]} events in queue for replicatorUpdate. Did you forget to attach a listener?`)
				end
			end
		elseif id == 10 then
			local value
			value = {}
			if buffer.readu8(incoming_buff, read(1)) == 1 then
				value.duration = buffer.readu8(incoming_buff, read(1))
			else
				value.duration = nil
			end
			local len_1 = buffer.readu16(incoming_buff, read(2))
			value.text = buffer.readstring(incoming_buff, read(len_1), len_1)
			if buffer.readu8(incoming_buff, read(1)) == 1 then
				value.color = Color3.fromRGB(buffer.readu8(incoming_buff, read(1)), buffer.readu8(incoming_buff, read(1)), buffer.readu8(incoming_buff, read(1)))
			else
				value.color = nil
			end
			if events[10][1] then
				for _, cb in events[10] do
					task.spawn(cb, value)
				end
			else
				table.insert(event_queue[10], value)
				if #event_queue[10] > 64 then
					warn(`[ZAP] {#event_queue[10]} events in queue for sendNotification. Did you forget to attach a listener?`)
				end
			end
		else
			error("Unknown event id")
		end
	end
end)
local returns = table.freeze({
	SendEvents = SendEvents,
	placeItem = table.freeze({
		Fire = function(Value: ({
			item: (string),
			origin: (Vector3),
			rotation: (CFrame),
			offset: (Vector3),
			mouseCell: (Vector3),
			normal: (Vector3),
		}))
			alloc(1)
			buffer.writeu8(outgoing_buff, outgoing_apos, 3)
			local len_1 = #Value.item
			alloc(2)
			buffer.writeu16(outgoing_buff, outgoing_apos, len_1)
			alloc(len_1)
			buffer.writestring(outgoing_buff, outgoing_apos, Value.item, len_1)
			alloc(4)
			buffer.writef32(outgoing_buff, outgoing_apos, Value.origin.X)
			alloc(4)
			buffer.writef32(outgoing_buff, outgoing_apos, Value.origin.Y)
			alloc(4)
			buffer.writef32(outgoing_buff, outgoing_apos, Value.origin.Z)
			local axis_1, angle_1 = Value.rotation:ToAxisAngle()
			axis_1 = axis_1 * angle_1
			alloc(4)
			buffer.writef32(outgoing_buff, outgoing_apos, Value.rotation.Position.X)
			alloc(4)
			buffer.writef32(outgoing_buff, outgoing_apos, Value.rotation.Position.Y)
			alloc(4)
			buffer.writef32(outgoing_buff, outgoing_apos, Value.rotation.Position.Z)
			alloc(4)
			buffer.writef32(outgoing_buff, outgoing_apos, axis_1.X)
			alloc(4)
			buffer.writef32(outgoing_buff, outgoing_apos, axis_1.Y)
			alloc(4)
			buffer.writef32(outgoing_buff, outgoing_apos, axis_1.Z)
			alloc(4)
			buffer.writef32(outgoing_buff, outgoing_apos, Value.offset.X)
			alloc(4)
			buffer.writef32(outgoing_buff, outgoing_apos, Value.offset.Y)
			alloc(4)
			buffer.writef32(outgoing_buff, outgoing_apos, Value.offset.Z)
			alloc(4)
			buffer.writef32(outgoing_buff, outgoing_apos, Value.mouseCell.X)
			alloc(4)
			buffer.writef32(outgoing_buff, outgoing_apos, Value.mouseCell.Y)
			alloc(4)
			buffer.writef32(outgoing_buff, outgoing_apos, Value.mouseCell.Z)
			alloc(4)
			buffer.writef32(outgoing_buff, outgoing_apos, Value.normal.X)
			alloc(4)
			buffer.writef32(outgoing_buff, outgoing_apos, Value.normal.Y)
			alloc(4)
			buffer.writef32(outgoing_buff, outgoing_apos, Value.normal.Z)
		end,
	}),
	deleteItem = table.freeze({
		Fire = function(Value: (number))
			alloc(1)
			buffer.writeu8(outgoing_buff, outgoing_apos, 4)
			alloc(4)
			buffer.writeu32(outgoing_buff, outgoing_apos, Value)
		end,
	}),
	requestData = table.freeze({
		Fire = function(Value: (boolean))
			alloc(1)
			buffer.writeu8(outgoing_buff, outgoing_apos, 7)
			alloc(1)
			buffer.writeu8(outgoing_buff, outgoing_apos, Value and 1 or 0)
		end,
	}),
	retrieveData = table.freeze({
		Fire = function(Value: ((boolean)?))
			alloc(1)
			buffer.writeu8(outgoing_buff, outgoing_apos, 8)
			if Value == nil then
				alloc(1)
				buffer.writeu8(outgoing_buff, outgoing_apos, 0)
			else
				alloc(1)
				buffer.writeu8(outgoing_buff, outgoing_apos, 1)
				alloc(1)
				buffer.writeu8(outgoing_buff, outgoing_apos, Value and 1 or 0)
			end
		end,
	}),
	entityUpdate = table.freeze({
		SetCallback = function(Callback: (({ ({
			id: (number),
			components: ({ ({
				component: (string),
				value: ({
					type: "model",
					value: (Instance),
				} | {
					type: "placed",
					value: (string),
				} | {
					type: "remove",
					value: (string),
				} | {
					type: "cellOccupation",
					value: ({ (Vector3) }),
				}),
			}) }),
		}) })) -> ()): () -> ()
			events[1] = Callback
			for _, value in event_queue[1] do
				task.spawn(Callback, value)
			end
			event_queue[1] = {}
			return function()
				events[1] = nil
			end
		end,
	}),
	destroyEntity = table.freeze({
		SetCallback = function(Callback: (({ ({
			id: (number),
		}) })) -> ()): () -> ()
			events[2] = Callback
			for _, value in event_queue[2] do
				task.spawn(Callback, value)
			end
			event_queue[2] = {}
			return function()
				events[2] = nil
			end
		end,
	}),
	gridData = table.freeze({
		On = function(Callback: (({ ({
			cell: (Vector3),
			occupied: (boolean),
		}) })) -> ())
			table.insert(events[5], Callback)
			for _, value in event_queue[5] do
				task.spawn(Callback, value)
			end
			event_queue[5] = {}
			return function()
				table.remove(events[5], table.find(events[5], Callback))
			end
		end,
	}),
	gridUpdate = table.freeze({
		On = function(Callback: (({ ({
			cell: (Vector3),
			occupied: (boolean),
		}) })) -> ())
			table.insert(events[6], Callback)
			for _, value in event_queue[6] do
				task.spawn(Callback, value)
			end
			event_queue[6] = {}
			return function()
				table.remove(events[6], table.find(events[6], Callback))
			end
		end,
	}),
	replicatorUpdate = table.freeze({
		On = function(Callback: (({
			state: ((unknown)),
			player: (Player),
			index: (string),
		})) -> ())
			table.insert(events[9], Callback)
			for _, value in event_queue[9] do
				task.spawn(Callback, value)
			end
			event_queue[9] = {}
			return function()
				table.remove(events[9], table.find(events[9], Callback))
			end
		end,
	}),
	sendNotification = table.freeze({
		On = function(Callback: (({
			duration: ((number)?),
			text: (string),
			color: ((Color3)?),
		})) -> ())
			table.insert(events[10], Callback)
			for _, value in event_queue[10] do
				task.spawn(Callback, value)
			end
			event_queue[10] = {}
			return function()
				table.remove(events[10], table.find(events[10], Callback))
			end
		end,
	}),
})
type Events = typeof(returns)
return returns
