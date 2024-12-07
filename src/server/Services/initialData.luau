local service = {}
service.dependencies = {Remotes = {"requestData"}, Packages = {"signal"}}

function service:run()
    self.requested = self.signal.new()

    self.requestData.SetCallback(function(plr: Player)
        self.requested:Fire(plr)
    end)
end

return service