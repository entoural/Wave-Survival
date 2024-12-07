-- Gets modules stored in PlayerScripts

local getter = {}
getter.dependencies = {GameServices = {"Players"}}

function getter:getModule(moduleName: string, callback: (module: {}) -> any)
    self.sharer:getModule(moduleName, callback)
end

function getter:run()
    self.player = self.players.LocalPlayer
    self.scripts = self.player:WaitForChild("PlayerScripts")

    self.sharer = require(self.scripts:WaitForChild("Client").Services.serviceSharer)
end

return getter