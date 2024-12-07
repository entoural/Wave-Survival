local runner = {}
local systems = {"grid", "mouse", "placer", "movingModel"}
runner.dependencies = {Services = systems, GameServices = {"RunService"}, Components = {"mainComponents"}}

function runner:run()
    local registry = self.mainComponents.registry

    self.runService.Heartbeat:Connect(function(dt)
        for _, v in systems do
            self[v]:update(registry, dt)
        end
    end)
end

return runner