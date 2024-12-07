local sharer = {}

function sharer:getModule(moduleName: string, callback: (module: {}) -> any)
    while not self.API do
        task.wait()
    end

    self.API.yieldFor(moduleName, callback)
end

function sharer:run(API)
    self.API = API
end

return sharer