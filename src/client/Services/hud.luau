local service = {}
service.dependencies = {Components = {"hudButton", "rootedEffect", "interactSound"}, Packages = {"vide", "spr"}, GameServices = {"Players", "UserInputService"}}

service.buttons = {}
service.states = {}

function service:cir(pos, gui)
    local circle = self.vide.create "Frame" {
        Size = UDim2.fromScale(0, 0),
        Transparency = 1,
        BackgroundColor3 = Color3.new(0.8, 0.8, 0.8),
        ZIndex = 5,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(pos.X, pos.Y),
        Parent = gui:WaitForChild("Main"),
        {
            self.vide.create "UICorner" {
                CornerRadius = UDim.new(1, 0)
            },
            self.vide.create "UIAspectRatioConstraint" {
                AspectRatio = 1
            }
        }
    }

    self.spr.target(circle, 0.4, 4, {Size = UDim2.fromScale(0.035, 0.1)})
    self.spr.target(circle, 0.4, 5, {BackgroundTransparency = 0.7})
    task.wait(0.25)
    self.spr.target(circle, 0.4, 5, {BackgroundTransparency = 1})
    self.spr.target(circle, 0.4, 5, {Size = UDim2.fromScale(0, 0)})
    task.wait(0.1)
    circle:Destroy()
end

function service:run()
    local plr = self.players.LocalPlayer
    local gui = plr:WaitForChild("PlayerGui")

    for _, frame in gui:WaitForChild("Main").HudBar:GetChildren() do
        if not frame:IsA("Frame") then continue end

        local state = self.vide.source(false)

        self.states[frame.Name] = state

        local newButton =  self.hudButton(state, frame, frame.Detect.UIStroke.Color)
        self.interactSound(newButton.button)
        table.insert(self.buttons, newButton)

        self.rootedEffect(function()
            local enabled = state()
            if enabled then
                for _, button in self.buttons do
                    if button == newButton then continue end

                    button.button.source(false)
                end
            end
        end)
    end

    self.userInputService.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

        local pos = self.userInputService:GetMouseLocation()

        self:cir(pos, gui)
    end)
end

return service