local service = {}
service.dependencies = {Remotes = {"placeItem", "deleteItem"}, GameServices = {"ReplicatedStorage"}, Services = {"cellService"}, Components = {"mainComponents", "rootedEffect"}, Packages = {"ecr", "spr", "vide"}}

local checkedVectors = {"origin", "offset", "mouseCell", "normal"}

function service:update(world)
    if self.queue.size < 1 then
        return
    end

    local grid = self.cellService.grid

    for id in self.queue do
        local occupied = world:try_get(id, self.component)

        for i, entity in grid do
            if entity == id then
                grid[i] = nil
            end
        end

        if occupied then
            for _, cell in occupied do
                grid[cell] = id
            end
        end
    end

    local groundedCells = {}
    local groundedIds = {}
    for id, cells in world:view(self.cts.CellOccupation, self.cts.Placed, self.cts.Grounded) do
        table.move(cells, 1, #cells, #groundedCells + 1, groundedCells)
        table.insert(groundedIds, id)
    end

    local anchoredIds = {}
    local connected = self.cellService:getConnectedCells(groundedCells)
    for _, cell in connected do
        local id = self.cellService.grid[cell]

        if table.find(anchoredIds, id) then
            continue
        end

        table.insert(anchoredIds, id)
    end

    for id in world:view(self.cts.Placed, self.cts.CellOccupation):exclude(self.cts.Grounded) do
        if not table.find(groundedIds, id) and not table.find(anchoredIds,  id) then
            world:remove(id, self.cts.Placed)
            world:remove(id, self.cts.CellOccupation)

            local model = world:try_get(id, self.cts.Model)

            if not model then continue end

            for _, part in model:GetDescendants() do
                if not part:IsA("BasePart") then continue end

                part.Anchored = false
            end

            task.delay(1.5,  function()
                for _, part in model:GetDescendants() do
                    if not part:IsA("BasePart") then continue end

                    part.Material = Enum.Material.Neon
                    self.spr.target(part, 1, 1, {Transparency = 1, Color = Color3.new(1, 0, 0)})
                end

                task.wait(1.25)
                model:Destroy()
            end)
        end
    end
end

function service:checkGrounded(cells: Vector3) 
    for _, cell in cells do
        if cell.Y == 0 then
            return true
        end
    end

    local groundedCells = {}
    for _, grounded in self.registry:view(self.cts.CellOccupation, self.cts.Placed, self.cts.Grounded) do
        table.move(grounded, 1, #grounded, #groundedCells + 1, groundedCells)
    end

    local connected = self.cellService:getConnectedCells(groundedCells)
    table.move(connected, 1, #connected, #groundedCells + 1, groundedCells)

    return self.cellService:isTouching(groundedCells, cells)
end

function service:run()
    self.registry = self.mainComponents.registry
    self.cts = self.mainComponents.components
    self.component = self.cts.CellOccupation
    self.queue = self.ecr.queue()

    local function changed(entity)
        self.queue:add(entity)
    end

    self.registry:on_add(self.component):connect(changed)
    self.registry:on_change(self.component):connect(changed)
    self.registry:on_remove(self.component):connect(changed)

    self.deleteItem.On(function(plr: Player, entity: number)
        if not self.registry:contains(entity) or not self.registry:has(entity, self.cts.Placed, self.cts.Model) or self.registry:get(entity, self.cts.Placed) ~= plr.Name then
            return
        end

        local model = self.registry:get(entity, self.cts.Model)

        self.registry:destroy(entity)
        model:Destroy()
    end)

    self.placeItem.On(function(plr: number, data: {
		item: string,
		origin: Vector3,
		rotation: CFrame,
		offset: Vector3,
		mouseCell: Vector3,
		normal: Vector3
	})

        local storageModel = self.replicatedStorage.Placeables:FindFirstChild(data.item)
        assert(storageModel, "Requested item doesn't exist")
        local size = storageModel:GetAttribute("Size")

        for _, vector in checkedVectors do
            data[vector] = self.cellService:roundCell(data[vector])
        end

        local cells = self.cellService:getCellsFromBox(size, data.origin, data.rotation, data.offset)
        cells = self.cellService:refineCells(cells, data.mouseCell, data.normal)
        local center = self.cellService:cellToPosition(self.cellService:getCenterOfCells(cells))

        if not self.cellService:checkCells(cells) or not self:checkGrounded(cells) then
            return
        end

        local targetCF = CFrame.new(center) * data.rotation
        local initialCF = targetCF + Vector3.new(0, 5, 0)

        local model = self.replicatedStorage.Placeables:FindFirstChild(data.item):Clone()
        model:PivotTo(initialCF)
        model.Parent = workspace

        local collideEnabled = {}

        for _, part in model:GetDescendants() do
            if not part:IsA("BasePart") then continue end

            if part.CanCollide then
                table.insert(collideEnabled, part)
            end

            part.CanCollide = false
        end

        local entity = self.registry:create()

        if self.cellService:isGrounded(cells) then
            self.registry:add(entity, self.cts.Grounded)
        end

        self.registry:set(entity, self.cts.Placed, plr.Name)
        self.registry:set(entity, self.cts.CellOccupation, cells)
        self.registry:set(entity, self.cts.Model, model)
        self.registry:set(entity, self.cts.LinkedCFrame, CFrame.new(center) * data.rotation)
        self.registry:add(entity, self.cts.Replicated)

        local target = self.vide.source(initialCF)

        self.vide.root(function(destructor)
            local spring = self.vide.spring(target, 0.3, 1.1)

            self.vide.effect(function()
                if self.registry:contains(entity) then
                    self.registry:set(entity, self.cts.LinkedCFrame, spring())
                else
                    destructor()
                end
            end)
        end)

        local sizeTarget = self.vide.source(1)

        self.vide.root(function(destructor)
            local sizeSpring = self.vide.spring(sizeTarget, 0.3, 0.7)

            self.vide.effect(function()
                if self.registry:contains(entity) then
                    model:ScaleTo(sizeSpring())
                else
                    destructor()
                end
            end)
        end)

        target(targetCF)
        task.wait(0.3)
        sizeTarget(1.15)
        task.wait(0.25)
        sizeTarget(1)
        task.wait(0.25)

        for _, part in collideEnabled do
            part.CanCollide = true
        end
    end)
end


return service