local runner = {}
local systems = {"cellService", "movingModel", "placer", "replication"}
runner.dependencies = {Services = systems, GameServices = {"RunService"}, Components = {"mainComponents"}}

function runner:run()
    local registry = self.mainComponents.registry

    local e = registry:create()
    registry:set(e, self.mainComponents.components.Placed, "eee")
    registry:set(e, self.mainComponents.components.CellOccupation, {Vector3.new(0, 0, 0)})
    registry:add(e, self.mainComponents.components.Replicated)

    self.runService.Heartbeat:Connect(function(dt)
        for _, v in systems do
            self[v]:update(registry, dt)
        end
    end)

    task.wait(6)
    registry:set(e, self.mainComponents.components.Placed, "eeeCHANGED")

    task.wait(5)
    registry:remove(e, self.mainComponents.components.Placed)
    task.wait(2)
    registry:set(e, self.mainComponents.components.Placed, "eeeCHANGED")
end

return runner