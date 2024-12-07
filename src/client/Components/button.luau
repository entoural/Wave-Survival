local component = {}
component.dependencies = {Packages = {"vide", "signal"}, Components = {"rootedEffect"}}
setmetatable(component, {__call = function(_, ...)
    return component:new(...)
end})

type props = {instance: TextButton | ImageButton, toggle: boolean?, clickValue: boolean?}

function component:new(source, props)
    local button = setmetatable({}, {__index = component})

    button.clicked = self.signal.new()
    button.hovered = self.vide.source(false)

    button.locked = false
    button.source = source
    button.props = props

    if props.toggle then
        button.toggled = source
    end

    props.instance.MouseButton1Click:Connect(function()
        button.clicked:Fire()
        if props.toggle and not button.locked then
            source(not source())
        else
            source(props.clickValue)
        end
    end)

    props.instance.MouseEnter:Connect(function()
        button.hovered(true)
    end)
    props.instance.MouseLeave:Connect(function()
        button.hovered(false)
    end)

    return button
end


return component