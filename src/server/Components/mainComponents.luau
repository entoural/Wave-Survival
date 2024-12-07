local component = {}
component.dependencies = {Packages = {"ecr"}}

function component:run()
    self.components = self.ecr.name {
        Grounded = self.ecr.tag(),
        Placed = self.ecr.component() :: string,
        LinkedCFrame = self.ecr.component() :: CFrame,
        Offset = self.ecr.component() :: CFrame,
        Model = self.ecr.component() :: Model | BasePart,
        CellOccupation = self.ecr.component() :: {Vector3},
        Replicated = self.ecr.tag()
    }

    self.registry = self.ecr.registry()
end

return component