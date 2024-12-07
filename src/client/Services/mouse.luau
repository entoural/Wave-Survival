local service = {}
service.dependencies = {Packages = {"ecr"}, Components = {"mainComponents"}, GameServices = {"UserInputService"}}
service.cam = workspace.CurrentCamera

function service:update(world)
    local mousePosition = self.userInputService:GetMouseLocation()
    local rayData = self.cam:ViewportPointToRay(mousePosition.X, mousePosition.Y, 0)
    local cts = self.mainComponents.components

    for id, mouse in world:view(cts.Mouse) do
        local hit = workspace:Raycast(rayData.Origin, rayData.Direction * (mouse.maxRange or 1000), mouse.params)
        world:set(id, cts.Mouse, {params = mouse.params, hit = hit, maxRange = mouse.maxRange})
    end
end

return service