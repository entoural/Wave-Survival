local runner = {}
runner.dependencies = {Remotes = {"requestData"}}

function runner:run()
    self.requestData.Fire(true)
end

return runner