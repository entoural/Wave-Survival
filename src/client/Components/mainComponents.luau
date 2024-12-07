local component = {}
component.dependencies = {Packages = {"ecr"}}

function component:run()
    self.components = self.ecr.name {
        Placing = self.ecr.tag(),
        LinkToSelection = self.ecr.tag(),
        Placed = self.ecr.component() :: string,
        CellOccupation = self.ecr.component() :: {Vector3},
        SelectedModel = self.ecr.component() :: string,
        PlacingCFrame = self.ecr.component() :: CFrame,
        CellOutline = self.ecr.component() :: {},
        Mouse = self.ecr.component(function()
            return {}
        end) :: {params: RaycastParams?, hit: RaycastResult?, maxRange: number?},
        LinkedCFrame = self.ecr.component() :: CFrame,
        Offset = self.ecr.component() :: CFrame,
        Model = self.ecr.component() :: Model | BasePart
    }

    self.registry = self.ecr.registry()
end

return component