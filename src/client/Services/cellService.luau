local service = {}
service.grid = {}
service.dependencies = {Remotes = {"gridUpdate", "gridData"}}

local axes = {"X", "Y", "Z"}
local maximums = {X = 60, Y = 20, Z = 60}
local minimums = {X = -60, Y = 0, Z = -60}

local neighbors = {
    Vector3.new(1, 0, 0),
    Vector3.new(-1, 0, 0),
    Vector3.new(0, 1, 0),
    Vector3.new(0, -1, 0),
    Vector3.new(0, 0, 1),
    Vector3.new(0, 0, -1)
}

local axesProps = {
    X = {Vector3.new(0, -0.5, -0.5), Vector3.new(0, -0.5, 0.5), Vector3.new(0, 0.5, -0.5), Vector3.new(0, 0.5, 0.5)},
    Y = {Vector3.new(-0.5, 0, -0.5), Vector3.new(-0.5, 0, 0.5), Vector3.new(0.5, 0, -0.5), Vector3.new(0.5, 0, 0.5)},
    Z = {Vector3.new(-0.5, -0.5, 0), Vector3.new(-0.5, 0.5, 0), Vector3.new(0.5, -0.5, 0), Vector3.new(0.5, 0.5, 0)}
}

function service:getCell(position: Vector3)
    local difference = position - self.origin.Position
    if difference.Y < 0 then
        return
    end

    local cellInfo = {}
    for _, v in axes do
        local sign = math.sign(difference[v])
        local cell = (math.floor(difference[v] + sign) - sign) // 4
        table.insert(cellInfo, cell)
    end

    return Vector3.new(table.unpack(cellInfo))
end

function service:axesToPosition(...)
    local converted = {}

    for i, n in {...} do
        converted[i] = n * 4 + 2
    end

    return converted
end

function service:newPart(props): Part
    local part = Instance.new("Part")
    for i, v in props do
        part[i] = v
    end

    return part
end

function service:newInstance(className, props): Instance
    local instance = Instance.new(className)
    for i, v in props do
        instance[i] = v
    end

    return instance
end

-- Generates a cube outline based on the cellSize
function service:generateCellsOutline(cellSize: Vector3, color: Color3?)
    local parts = {}

    local model = Instance.new("Model")
    local rootPart = self:newPart({Transparency = 1, CanCollide = false, Anchored = true, Size = Vector3.new(0.5, 0.5, 0.5)})

    for _, axis in axes do
        for _, vector in axesProps[axis] do
            local sizeValues = {}
            for _, sizeAxis in axes do
                table.insert(sizeValues, if sizeAxis == axis then cellSize[sizeAxis] * 4 + 0.25 else 0.3)
            end

            local size = Vector3.new(table.unpack(sizeValues))
            local position = vector * cellSize * 4

            table.insert(parts, self:newPart({Size = size, Position = position, CanCollide = false, Anchored = true, Transparency = 0.5, Color = color or Color3.new(0, 1, 0)}))
        end
    end

    model.Parent = workspace
    rootPart.Parent = model
    model.PrimaryPart = rootPart

    for _, part in parts do
        part.Parent = model
        self:newInstance("WeldConstraint", {Part0 = part, Part1 = rootPart, Parent = part})
        part.Anchored = false
    end

    return model
end

function service:cellToPosition(cell: Vector3)
    return Vector3.new(table.unpack(self:axesToPosition(cell.X, cell.Y, cell.Z)))
end

function service:hitToCell(hit: RaycastResult)
    return self:getCell(hit.Position + hit.Normal)
end

function service:hitToPosition(hit: RaycastResult)
    local cell = self:getCell(hit.Position + hit.Normal)
    if not cell then
        return
    end

    return self:cellToPosition(cell)
end

function service:getTilt(newCF, currentCF, lastTilt)
    local difference = newCF.Position - currentCF.Position
    local tiltMax = CFrame.Angles(math.clamp(-difference.Z / 12, -0.15, 0.15), 0, math.clamp(difference.X / 12, -0.15, 0.15))
    return lastTilt:Lerp(if newCF == currentCF then CFrame.Angles(0, 0, 0) else tiltMax, 0.35)
end

-- Self explanatory
function service:getCellsFromBox(size: Vector3, origin: Vector3, rotation: CFrame?, offset: Vector3?): {Vector3}
    if not offset then
        offset = Vector3.new(math.floor((size.X - 1) / 2), 0, 0)
    end
    if not rotation then
        rotation = CFrame.Angles(0, 0, 0)
    end

    local cells = {}

    local center: CFrame = CFrame.new(origin) * rotation
    for x = 1, math.max(1, size.X) do
        for y = 1, math.max(1, size.Y) do
            for z = 1, math.max(1, size.Z) do
                local gridCell: Vector3 = (center * CFrame.new(
                    math.floor(x - 1 - offset.X), math.floor(y - 1 - offset.Y), math.floor(z - 1 - offset.Z)
                )).Position

                table.insert(cells, gridCell)
            end
        end
    end

    return cells
end

-- Makes sure models dont clip below where the mouse is pointing (based on normal)
function service:refineCells(cells: {Vector3}, mouseCell: Vector3, normal: Vector3)
    local axisToCheck
    for _, axis in axes do
        if normal[axis] ~= 0 then
            axisToCheck = axis
            break
        end
    end

    if not axisToCheck then
        warn("Couldn't find an axis to check")
        return cells
    end

    local offset = 0
    local normalSign: number = math.sign(normal[axisToCheck])
    local base: number = mouseCell[axisToCheck]
    for _, cell: Vector3 in cells do
        local n: number = cell[axisToCheck]
        local difference: number = base - n
        if n == base then
            continue
        end

        local sign: number = math.sign(difference)
        if sign == normalSign and math.abs(difference) > offset then
            offset = math.abs(difference)
        end
    end

    if offset == 0 then
        return cells
    end

    local newCells = {}

    for _, cell: Vector3 in cells do
        local newVector = {}
        for  _, axis in axes do
            local isAxis: boolean = axis == axisToCheck
            table.insert(newVector, if isAxis then math.round(cell[axis] + (offset * normalSign)) else math.round(cell[axis]))
        end
        table.insert(newCells, Vector3.new(table.unpack(newVector)))
    end

    return newCells
end

-- Gets the center position of a group of cells (to position models)
function service:getCenterOfCells(cells: {Vector3})

    local min = Vector3.one*-math.huge
    local max = Vector3.one*math.huge

    if #cells > 5000 then
        for _, v in cells do
            min = min:Max(v)
            max = max:Min(v)
        end
    else
        min = min:Max(table.unpack(cells))
        max = max:Min(table.unpack(cells))
    end

    return (min + max)/2
end

function service:cellWithinBounds(cell: Vector3): boolean
    for _, axis in axes do
        local value = cell[axis]
        if value < minimums[axis] or value > maximums[axis] then
            return
        end
    end

    return true
end

function service:getConnectedCells(cells: {Vector3}): {Vector3}
    local visited = {}
    local connectedCells = {}

    local function explore(cell)
        if visited[cell] then return end
        visited[cell] = true

        if self.grid[cell] and self:cellWithinBounds(cell) then
            table.insert(connectedCells, cell)

            for _, offset in neighbors do
                explore(cell + offset)
            end
        end
    end

    for _, cell in cells do
        explore(cell)
    end

    return connectedCells
end

function service:roundCell(cell: Vector3)
    return Vector3.new(math.round(cell.X), math.round(cell.Y), math.round(cell.Z))
end

function service:checkCells(cells: {Vector3}): boolean
    for _, cell in cells do
        if self.grid[self:roundCell(cell)] or not self:cellWithinBounds(cell) then
            return
        end
    end

    return true
end

function service:updateGrid(cells: {{cell: Vector3, occupied: boolean}})
    for _, cell in cells do
        self.grid[cell.cell] = if cell.occupied then true else nil
    end
end

function service:run()
    self.origin = CFrame.new(0, 0, 0)

    self.gridData.On(function(data)
        print("e")
        self:updateGrid(data)
    end)
    self.gridUpdate.On(function(data)
        print("e")
        self:updateGrid(data)
    end)
end

return service