local service = {}
service.dependencies = {Components = {"mainComponents"}, Services = {"cellService"}, Packages = {"ecr"}}

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
end


return service