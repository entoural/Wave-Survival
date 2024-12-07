local service = {}
service.dependencies = {Packages = {"ecr"}, Remotes = {"entityUpdate", "destroyEntity"}, Components = {"mainComponents"}, GameServices = {"Players", "RunService"}}

service.replicatedComponents = {"Placed", "CellOccupation", "Model"}
service.componentTypes = {Placed = "placed", CellOccupation = "cellOccupation", Model = "model"}

local function getComponent(array: {{component: string, value: any}}, componentName: string)
    for _, map in array do
        if map.component == componentName then
            return map
        end
    end

    local newComponent = {component = componentName, value = {type = service.componentTypes[componentName]}}
    table.insert(array, newComponent)

    return newComponent
end

function service:update()
    if self.updateQueue.size == 0 then
        return
    end

    local replication = {}
    local foundIds = {}

    local function addComponent(id, componentName, newValue)
        local entity
        if foundIds[id] then
            entity = foundIds[id]
        else
            entity = {id = id, components = {}}
            foundIds[id] = entity
            table.insert(replication, entity)
        end

        local component = getComponent(entity.components, componentName)
        component.value.value = newValue
        return component
    end

    for info in self.updateQueue do
        if info == nil then
            continue
        end

        local component = addComponent(table.unpack(info))
        if info[3] == "removed" then
            component.value.type = "remove"
        end
    end

    if #replication == 0 then
        return
    end

    self.entityUpdate.FireAll(replication)
end

function service:run(API)
    self.cts = self.mainComponents.components
    self.registry = self.mainComponents.registry
    self.updateQueue = self.ecr.queue()
    self.didChange = false

    API.yieldFor("initialData", function(initialData)
        initialData.requested:Connect(function(plr: Player)
        local replication = {}
        local foundIds = {}

        local pool = self.registry:storage(self.cts.Replicated)
        local entities = self.ecr.buffer_to_array(pool.entities, pool.size)

        local function addComponent(id, componentName, newValue)
            local entity
            if foundIds[id] then
                entity = foundIds[id]
            else
                entity = {id = id, components = {}}
                foundIds[id] = entity
                table.insert(replication, entity)
            end

            getComponent(entity.components, componentName).value.value = newValue
        end

        for _, entity in entities do
            for _, componentName in self.replicatedComponents do
                if self.registry:has(entity, self.cts[componentName]) then
                    addComponent(entity, componentName, self.registry:get(entity, self.cts[componentName]))
                end
            end
        end

        if next(replication) == nil then
            return
        end

        self.entityUpdate.Fire(plr, replication)
        end)
    end)

    local function queue(entity, component, data)
        if typeof(data) == "Instance" then
            self.runService.Heartbeat:Wait()
            self.runService.Heartbeat:Wait()
        end

        self.updateQueue:add({entity, component, data})
    end

    for _, componentName in self.replicatedComponents do
        local component = self.cts[componentName]

        self.registry:on_add(component):connect(function(entity, initialData)
            queue(entity, componentName, initialData)
        end)
        self.registry:on_change(component):connect(function(entity, data)
            queue(entity, componentName, data)
        end)
        self.registry:on_remove(component):connect(function(entity)
            self.updateQueue:add({entity, componentName, "removed"})
        end)
    end
end

return service