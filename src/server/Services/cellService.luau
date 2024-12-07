local service = {}
service.grid = {}
service.dependencies = {GameServices = {"Players"}, Remotes = {"gridData", "gridUpdate"}, Packages = {"ecr"}, Services = {"initialData"}}

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
                    x - 1 - offset.X, y - 1 - offset.Y, z - 1 - offset.Z
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
            table.insert(newVector, if isAxis then cell[axis] + (offset * normalSign) else cell[axis])
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
        for i,v in cells do
            min = min:Max(v)
            max = max:Min(v)
        end
    else
        min = min:Max(table.unpack(cells))
        max = max:Min(table.unpack(cells))
    end

    return (min + max)/2
end

function service:formatGrid(gridToFormat: {Vector3})
    local grid = {}
    for cell in gridToFormat or self.grid do
        table.insert(grid, {cell = cell, occupied = true})
    end

    return grid
end

function service:updateCell(cell: Vector3, occupied: true | nil)
    self.grid[cell] = occupied
    self.updateQueue:add({cell = cell, occupied = if occupied then true else false})
end

function service:occupyCells(cells: {Vector3})
    for _, cell in cells do
        self:updateCell(cell, true)
    end
end

function service:removeCells(cells: {Vector3})
    for _, cell in cells do
        self:updateCell(cell)
    end
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

function service:isTouching(cells: {Vector3}, touchingCells: {Vector3}): boolean
    local visited = {}

    local function explore(cell)
        if visited[cell] then return end
        visited[cell] = true

        if table.find(touchingCells, cell) then
            return true
        end
    end

    for _, cell in cells do
        for _, offset in neighbors do
            if explore(cell + offset) then
                return true
            end
        end
    end
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

function service:isGrounded(cells: Vector3)
    for _, cell in cells do
        if cell.Y == 0 then
            return true
        end
    end
end

function service:update()
    --[[local grid = {}
    for _, cellInfo in self.updateQueue do
        table.insert(grid, cellInfo)
    end

    self.gridUpdate.FireAll(grid)]]
end

function service:run(API)
    self.updateQueue = self.ecr.queue()
    self.origin = CFrame.new(0, 0, 0)

    API.yieldFor("initialData", function(initialData)
        initialData.requested:Connect(function(plr: Player)
            local grid = self:formatGrid()
            if #grid < 1 then
                return
            end

            self.gridData.Fire(plr, self:formatGrid())
        end)
    end)
end

return service