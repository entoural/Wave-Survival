local component = {}
component.dependencies = {Packages = {"vide", "signal", "spr", "janitor"}, Components = {"rootedEffect", "button"}, GameServices = {"RunService"}}
setmetatable(component, {__call = function(_, ...)
    return component:new(...)
end})

local rotations = {-20, 20, 0}
local buttons = {}

function component:new(source: () -> boolean, instance: Frame, color: Color3)
    local hudButton = setmetatable({}, {__index = component})

    local button = self.button(source, {instance = instance.Detect, toggle = true})
    hudButton.button = button
    hudButton.color = color
    hudButton.janitor = self.janitor.new()
    hudButton.currentOffset = self.vide.source(0.2)

    local hovering = false
    local enabled = false

    self.rootedEffect(function()
        hovering = button.hovered()

        if hovering then
            self.spr.target(instance.Glow, 1, 4, {ImageTransparency = 0})

            hudButton.janitor:Add(task.spawn(function()
                for _, rotation in rotations do
                    self.spr.target(instance.Icon, 1, 4, {Rotation = rotation})
                    task.wait(0.1)
                end
            end), true, "wiggle")
        else
            if not enabled then
                self.spr.target(instance.Glow, 1, 4, {ImageTransparency = 1})
            end

            if hudButton.janitor:Get("wiggle") then
                hudButton.janitor:Remove("wiggle")
            end
            self.spr.target(instance.Icon, 1, 4, {Rotation = 0})
        end
    end)

    self.rootedEffect(function()
        enabled = source()

        local nextColor = if enabled then color else Color3.new(1, 1, 1)
        self.spr.target(instance.Icon, 1, 4, {ImageColor3 = nextColor})

        if not hovering then
            self.spr.target(instance.Glow, 1, 4, {ImageTransparency = 1})
        end

        if hudButton.janitor:Get("click") then
			hudButton.janitor:Remove("click")
		end


        hudButton.janitor:Add(task.spawn(function()
            self.spr.target(instance.Icon, 0.4, 4, {Size = UDim2.fromScale(0.6, 0.6)})
			task.wait(0.15)
			self.spr.target(instance.Icon, 0.4, 4, {Size = UDim2.fromScale(0.8, 0.8)})
        end), true, "click")
    end)

    self.rootedEffect(function()
        local offset = hudButton.currentOffset()

        local start = NumberSequenceKeypoint.new(0, 0)
        local start0 = NumberSequenceKeypoint.new(offset - 0.01, 0)
        local start1 = NumberSequenceKeypoint.new(offset, 1)

        local end0 = NumberSequenceKeypoint.new(1 - offset + 0.01, 0)
        local end1 = NumberSequenceKeypoint.new(1 - offset, 1)

        local endN =  NumberSequenceKeypoint.new(1, 0)

        local sequence = NumberSequence.new({start, start0, start1, end1, end0, endN})
        instance.Detect.UIStroke.UIGradient.Transparency = sequence
    end)

    table.insert(buttons, hudButton)
    return hudButton
end

function component:run()
    self.runService.Heartbeat:Connect(function(dt)
        for _, button in buttons do
            local clicked = button.button.source()
            local hovering = button.button.hovered()
            local offset = button.currentOffset()

            if (clicked) or (hovering and offset < 0.5) then
                offset += math.clamp(3 * dt, 0, 0.5 - offset)
            elseif not hovering and offset > 0.2 then
                offset -= math.clamp(3 * dt, 0, offset - 0.2)
            end

            button.currentOffset(offset)
        end
    end)
end

return component