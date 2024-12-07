local runner = {}
runner.dependencies = {Services = {"cellService"}, GameServices = {"ReplicatedStorage"}}

function runner:run()
    -- Example usage
    --[[local size = Vector3.new(2, 1, 2)
    local offset = Vector3.new(-1, 0, -1)
    local origin = Vector3.new(1, 0, -2)
    local rotation = CFrame.Angles(0, 0, 0) -- No rotation in this exampl

    local cells = self.cellService:getCellsFromBox(size, origin, rotation, offset)

    for _, cell in cells do
        local newCube = self.replicatedStorage.Tester:Clone()
        newCube.Position = self.cellService:cellToPosition(cell)

        newCube.Parent = workspace
    end]]
end

return runner