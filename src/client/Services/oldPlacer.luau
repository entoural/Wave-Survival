local service = {}
service.lastTilt = CFrame.Angles(0, 0, 0)
service.dependencies = {Services = {"cellService"}, Components = {"mainComponents"}, Packages = {"ecr"}, GameServices = {"Players", "ReplicatedStorage", "UserInputService"},
                        Remotes = {"placeItem"}}

local defaultCFrame = CFrame.new(Vector3.new(0, -20, 0))

local size = Vector3.new(5, 5, 1)

--[[function service:conditionsFulfilled(world)
    --local mouse = world:get(self.ecr.context, self.cts.Mouse)
    if not world:has(self.ecr.context, self.cts.Placing) then
        return
    end

    return true
end

function service:update(world)
    debug.profilebegin("placer")
    local currentPivot = world:get(self.ecr.context, self.cts.PlacingCFrame)
    local mouse = world:get(self.ecr.context, self.cts.Mouse)
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
    local rotation = CFrame.Angles(math.rad(0), math.rad(0), 0)
    local offset = Vector3.new(2, 2, 0)

    local cells = self.cellService:getCellsFromBox(size, origin, rotation, offset)
    cells = self.cellService:refineCells(cells, mouseCell, mouse.hit.Normal)
    local center = self.cellService:cellToPosition(self.cellService:getCenterOfCells(cells))

    local newCF = CFrame.new(center)
    local distance = (newCF.Position - currentPivot.Position).Magnitude
    local nextCF = currentPivot:Lerp(newCF or defaultCFrame, math.min(1, distance / 5 / distance))

    self.lastTilt = self.cellService:getTilt(newCF, currentPivot, self.lastTilt)


    local finalCF = if self.lastTilt then self.lastTilt * rotation else rotation
    for id in world:view(self.cts.Placing, self.cts.Model, self.cts.LinkedCFrame):exclude(self.cts.Placed):use(self.cts.Placing) do
        world:set(id, self.cts.LinkedCFrame, nextCF)
        world:set(id, self.cts.Offset, finalCF)
    end
    world:set(self.ecr.context, self.cts.PlacingCFrame, nextCF)

    if self.cellService:checkCells(cells) then
        for _, part in self.model:GetChildren() do
            part.Color = Color3.new(0, 1, 0)
        end
    else
        for _, part in self.model:GetChildren() do
            part.Color = Color3.new(1, 0, 0)
        end
    end

    debug.profileend("placer")
end

function service:run()
    self.cts = self.mainComponents.components

    self.registry = self.mainComponents.registry
    self.registry:context()

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params:AddToFilter(workspace:WaitForChild("Baseplate"))

    self.model = self.cellService:generateCellsOutline(size)
    self.model.Name = "border"
    local testModel = self.replicatedStorage:WaitForChild("testModel")
    testModel.Size = size * 4
    testModel.Parent = workspace

    self.registry:set(self.ecr.context, self.cts.Mouse, {params = params})
    self.registry:set(self.ecr.context, self.cts.PlacingCFrame, defaultCFrame)

    self.selectedModel = self.registry:create()

    self.registry:set(self.selectedModel, self.cts.LinkedCFrame, defaultCFrame)
    self.registry:set(self.selectedModel, self.cts.Model, workspace.Tester)
    self.registry:add(self.selectedModel, self.cts.Placing)

    local e = self.registry:create()
    self.registry:set(e, self.cts.LinkedCFrame, defaultCFrame)
    self.registry:set(e, self.cts.Model, self.model)
    self.registry:add(e, self.cts.Placing)

    local ee = self.registry:create()
    self.registry:set(ee, self.cts.LinkedCFrame, defaultCFrame)
    self.registry:set(ee, self.cts.Model, testModel)
    self.registry:add(ee, self.cts.Placing)

    self.userInputService.InputEnded:Connect(function(input, gp)
        if gp or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end

        local mouse = self.registry:get(self.ecr.context, self.cts.Mouse)
        if not mouse.hit then
            return
        end

        local mouseCell = self.cellService:hitToCell(mouse.hit)
        local pos = self.cellService:cellToPosition(mouseCell)
        local origin = self.cellService:getCell(pos)
        local rotation = CFrame.Angles(math.rad(0), math.rad(0), 0)
        local offset = Vector3.new(2, 2, 0)

        if not mouseCell or not pos or not origin then
            return
        end

        self.placeItem.Fire({size = size, origin = origin, rotation = rotation, offset = offset, mouseCell = mouseCell, normal = mouse.hit.Normal, item = "beep"})
    end)

    local function modelAdded(entity, model)
        if not self.registry:has(entity, self.cts.Placed) then
            return
        end

        local mouse = self.registry:get(self.ecr.context, self.cts.Mouse)
        mouse.params:AddToFilter(model)
    end

    self.registry:on_add(self.cts.Model):connect(modelAdded)
    self.registry:on_change(self.cts.Model):connect(modelAdded)
    self.registry:on_remove(self.cts.Placed):connect(function(entity)
        local model = self.registry:try_get(entity, self.cts.Model)
        local mouse = self.registry:get(self.ecr.context, self.cts.Mouse)
        if not model then
            return
        end

        local found = table.find(mouse.params.FilterDescendantsInstances, model)
        if found then
            local clone = table.clone(mouse.params.FilterDescendantsInstances)
            table.remove(clone, found)
            mouse.params.FilterDescendantsInstances = clone
        end
    end)
end]]

return service