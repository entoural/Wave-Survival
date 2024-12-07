local rootedEffect = {}
setmetatable(rootedEffect, {__call = function(_, ...)
    return rootedEffect:new(...)
end})

rootedEffect.dependencies = {Packages = {"vide"}}

function rootedEffect:new(effect: (destructor: () -> any) -> any)
    self.vide.root(function(destructor)
        self.vide.effect(function()
            effect(destructor)
        end)
    end)
end

return rootedEffect