local service = {}
service.dependencies = {Packages = {"ecr"}, Components = {"mainComponents"}}

function service:update(world)
    if self.queue.size == 0 then
        return
    end

    for info in self.queue do
        local model = world:try_get(info[1], self.cts.Model)
        if not model then
            continue
        end

        local offset = world:try_get(info[1], self.cts.Offset)
        model:PivotTo(if offset then info[2] * offset else info[2])
    end
end

function service:run()
    self.registry = self.mainComponents.registry
    self.cts = self.mainComponents.components
    self.component = self.cts.LinkedCFrame
    self.queue = self.ecr.queue()

    local function changed(entity, newValue)
        self.queue:add({entity, newValue})
    end

    self.registry:on_add(self.component):connect(changed)
    self.registry:on_change(self.component):connect(changed)
end

return service