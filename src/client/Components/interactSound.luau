local component = {}
component.dependencies = {Packages = {"vide", "signal", "sift"}, Components = {"rootedEffect"}, GameServices = {"SoundService", "Debris"}}
setmetatable(component, {__call = function(_, ...)
    return component:new(...)
end})

type button = {clicked: RBXScriptSignal, hovered: () -> boolean}
type props = {hover: boolean, click: boolean, hoverVolume: number?, clickVolume: number?, hoverId: string?, clickId: string?}

component.defaultProps = {
    hover = true, click = true, hoverVolume = 0.2, clickVolume = 0.5, clickId = "rbxassetid://18497925021", hoverId = "rbxassetid://18497999901"
} :: props

function component:new(button: button, props)
    local interaction = setmetatable({}, {__index = component})

    interaction.props = self.sift.Dictionary.merge(self.defaultProps, props)

    button.clicked:Connect(function()
        if interaction.props.click then
            interaction:playSound("click")
        end
    end)

    local first = true
    self.rootedEffect(function()
        button.hovered()

        if first then
            first = false
            return
        end

        interaction:playSound()
    end)

    return interaction
end

function component:playSound(soundType: "click"?)
    local volume = 1
    local soundId = ""
    if soundType == "click" then
        volume = self.props.clickVolume
        soundId = self.props.clickId
    else
        volume = self.props.hoverVolume
        soundId = self.props.hoverId
    end

    local sound = Instance.new("Sound")
	sound.Parent = self.soundService
	sound.Volume = volume or 1
	sound.SoundId = soundId
	self.soundService:PlayLocalSound(sound)
	self.debris:AddItem(sound, sound.TimeLength)
end


return component