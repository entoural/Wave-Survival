local service = {}
service.lastTilt = CFrame.Angles(0, 0, 0)
service.dependencies = {Services = {"cellService", "replication"}, Components = {"mainComponents", "rootedEffect"}, Packages = {"ecr", "vide"}, GameServices = {"Players", "ReplicatedStorage", "UserInputService"}, Remotes = {"placeItem", "deleteItem"}}

service.rotation = CFrame.Angles(0, 0, 0)

local defaultCFrame = CFrame.new(Vector3.new(0, -20, 0))
local rotateKeys = {
    [Enum.KeyCode.R] = "Y",
    [Enum.KeyCode.T] = "X",
    [Enum.KeyCode.Y] = "Z"
}

service.rotationComponents = {X = 0, Y = 0, Z = 0}

function service:update(world)
    local mouse = world:get(self.ecr.context, self.cts.Mouse)

    if self.deleting() then
        if not mouse.hit and self.borderModel then
            self.borderModel:Destroy()
            self.borderModel = nil
            self.deleteSelection = nil
        elseif mouse.hit then
            local hitInstance = mouse.hit.Instance
            local hitModel
            local hitId

            for id, model in world:view(self.cts.Model, self.cts.Placed) do
                if hitInstance:IsDescendantOf(model) and model:FindFirstChild("Hitbox") then
                    hitModel = model
                    hitId = id
                    break
                end
            end

            if not hitModel then
                if self.borderModel then
                    self.borderModel:Destroy()
                    self.borderModel = nil
                    self.deleteSelection = nil
                end

                return
            end

            if self.deleteSelection ~= hitId then
                if self.borderModel then
                    self.borderModel:Destroy()
                end

                local color = if world:try_get(hitId, self.cts.Placed) == self.plr.Name then Color3.new(1, 0, 0) else Color3.new(0.5, 0.5, 0.5)

                local size = hitModel:GetAttribute("Size")
                self.borderModel = self.cellService:generateCellsOutline(size, color)
                self.borderModel.Name = "Border"

                self.borderModel:PivotTo(hitModel.Hitbox.CFrame)

                self.deleteSelection = hitId
            end
        end

        return
    end

    if not self.enabled() then return end

    local currentPivot = world:get(self.ecr.context, self.cts.PlacingCFrame)
    if not mouse.hit then
        world:set(self.ecr.context, self.cts.PlacingCFrame, defaultCFrame)

        for id in world:view(self.cts.Placing, self.cts.Model, self.cts.LinkedCFrame):use(self.cts.Placing) do
            local offset = world:has(id, self.cts.Offset)
            if offset then
                world:remove(id, self.cts.Offset)
            end

            world:set(id, self.cts.LinkedCFrame, defaultCFrame)
        end

        return
    end

    local mouseCell = self.cellService:hitToCell(mouse.hit)
    local pos = self.cellService:cellToPosition(mouseCell)
    local origin = self.cellService:getCell(pos)
    local rotation = self.rotation

    local cells = self.cellService:getCellsFromBox(self.size, origin, rotation, self.offset)
    cells = self.cellService:refineCells(cells, mouseCell, mouse.hit.Normal)
    local center = self.cellService:cellToPosition(self.cellService:getCenterOfCells(cells))

    local newCF = CFrame.new(center)
    local nextCF = currentPivot:Lerp(newCF or defaultCFrame, math.min(1, 0.1))

    self.lastTilt = self.cellService:getTilt(newCF, currentPivot, self.lastTilt)

    local finalCF = if self.lastTilt then self.lastTilt * rotation else rotation
    for id in world:view(self.cts.Placing, self.cts.Model, self.cts.LinkedCFrame):exclude(self.cts.Placed):use(self.cts.Placing) do
        world:set(id, self.cts.LinkedCFrame, nextCF)
        world:set(id, self.cts.Offset, finalCF)
    end

    world:set(self.ecr.context, self.cts.PlacingCFrame, nextCF)

    if self.cellService:checkCells(cells) then
        for _, part in self.borderModel:GetChildren() do
            part.Color = Color3.new(0, 1, 0)
        end
    else
        for _, part in self.borderModel:GetChildren() do
            part.Color = Color3.new(1, 0, 0)
        end
    end
end

function service:configure(modelName)
    local model = self.replicatedStorage.Placeables:FindFirstChild(modelName):Clone()
    assert(model, "Couldn't find the model")

    self.size = model:GetAttribute("Size")
    self.offset = model:GetAttribute("Offset")
    self.model = model

    for id, tempModel in self.registry:view(self.cts.Model, self.cts.Placing, self.cts.LinkedCFrame) do
        self.registry:destroy(id)
        tempModel:Destroy()
    end

    self.borderModel = nil
    self.selectedModel = nil

    self.borderModel = self.cellService:generateCellsOutline(self.size)
    self.borderModel.Name = "Border"

    local borderEntity = self.registry:create()
    self.selectedModel = self.registry:create()

    for _, part in model:GetDescendants() do
        if not part:IsA("BasePart") then continue end

        part.Anchored = true
        part.CanCollide = false
        part.Transparency /= 2
    end
    model.Parent = workspace
    self.registry:set(self.selectedModel, self.cts.LinkedCFrame, defaultCFrame)
    self.registry:set(self.selectedModel, self.cts.Model, model)
    self.registry:add(self.selectedModel, self.cts.Placing)

    self.registry:set(borderEntity, self.cts.LinkedCFrame, defaultCFrame)
    self.registry:set(borderEntity, self.cts.Model, self.borderModel)
    self.registry:add(borderEntity, self.cts.Placing)
end

function service:disable()
    for id, tempModel in self.registry:view(self.cts.Model, self.cts.Placing, self.cts.LinkedCFrame) do
        self.registry:destroy(id)
        tempModel:Destroy()
    end

    self.offset = Vector3.new(0, 0, 0)
    self.borderModel = nil
    self.selectedModel = nil
end

function service:updateRotation()
    local components = self.rotationComponents
    self.rotation = CFrame.Angles(math.rad(components.X), math.rad(components.Y), math.rad(components.Z))
end

function service:run(API)
    self.plr = self.players.LocalPlayer
    self.cts = self.mainComponents.components

    self.registry = self.mainComponents.registry
    self.registry:context()

    self.selectedItem = self.vide.source("Dirt Block")

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params:AddToFilter(workspace:WaitForChild("Baseplate"))

    self.registry:set(self.ecr.context, self.cts.Mouse, {params = params})
    self.registry:set(self.ecr.context, self.cts.PlacingCFrame, defaultCFrame)

    API.yieldFor("hud", function(hud)
        self.enabled = hud.states.Build
        self.deleting = hud.states.Delete

        self.rootedEffect(function()
            local enabled = self.enabled()

            if enabled then
                self:configure(self.selectedItem())
            else
                self:disable()
            end
        end)
    end)

    self.userInputService.InputEnded:Connect(function(input, gp)
        local axis = rotateKeys[input.KeyCode]
        if gp or not axis then return end

        self.rotationComponents[axis] = ((self.rotationComponents[axis] % 360) + 90) % 360

        self:updateRotation()
    end)

    self.userInputService.InputEnded:Connect(function(input, gp)
        if gp or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

        if self.deleting and self.deleting() then
            local selected = self.deleteSelection
            if not selected or self.registry:try_get(selected, self.cts.Placed) ~= self.plr.Name then
                return
            end

            local serverId = self.replication:getServerId(selected)
            assert(serverId, "Couln't find the server entity ID for the model to delete")

            self.deleteItem.Fire(serverId)
        elseif not self.enabled or not self.enabled() then
            return
        end

        if not self.enabled() or gp or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

        local mouse = self.registry:get(self.ecr.context, self.cts.Mouse)
        if not mouse.hit then
            return
        end

        assert(self.size and self.rotation and self.model, "Doesn't have all values to request place")

        local mouseCell = self.cellService:hitToCell(mouse.hit)
        local pos = self.cellService:cellToPosition(mouseCell)
        local origin = self.cellService:getCell(pos)
        local normal = mouse.hit.Normal

        if not mouseCell or not pos or not origin then
            return
        end

        local offset = self.offset or Vector3.new(math.floor((self.size.X - 1) / 2), 0, 0)

        local cells = self.cellService:getCellsFromBox(self.size, origin, self.rotation, offset)
        cells = self.cellService:refineCells(cells, mouseCell, normal)

        if not self.cellService:checkCells(cells) then
            return
        end

        self:updateRotation()
        self.placeItem.Fire({origin = origin, rotation = CFrame.Angles(self.rotation:ToOrientation()), offset = offset, mouseCell = mouseCell, normal = normal, item = self.model.Name})
    end)

    local function modelAdded(entity, model)
        if not self.registry:has(entity, self.cts.Placed) then
            return
        end

        local mouse = self.registry:get(self.ecr.context, self.cts.Mouse)
        mouse.params:AddToFilter(model.PrimaryPart or model)
    end

    self.registry:on_add(self.cts.Model):connect(modelAdded)
    self.registry:on_change(self.cts.Model):connect(modelAdded)
    self.registry:on_remove(self.cts.Placed):connect(function(entity)
        local model = self.registry:try_get(entity, self.cts.Model)
        local mouse = self.registry:get(self.ecr.context, self.cts.Mouse)
        if not model then
            return
        end

        local found = table.find(mouse.params.FilterDescendantsInstances, model.PrimaryPart or model)
        if found then
            local clone = table.clone(mouse.params.FilterDescendantsInstances)
            table.remove(clone, found)
            mouse.params.FilterDescendantsInstances = clone
        end
    end)
end


return service