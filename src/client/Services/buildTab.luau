local service = {}
service.dependencies = {Services = {"placer"}, Components = {"button"}, GameServices = {"Players"}, Packages = {"vide"}}

function service:run()
    local plr = self.players.LocalPlayer
    local gui = plr:WaitForChild("PlayerGui")

    local frame = gui:WaitForChild("Main").ToggleableFrames.Build.ScrollingFrame

    for _, instance in frame:GetChildren() do
        if not instance:IsA("TextButton") then continue end

        instance.MouseButton1Click:Connect(function()
            self.placer.selectedItem(instance.Name)
            self.placer:configure(instance.Name)
        end)
    end
end

return service