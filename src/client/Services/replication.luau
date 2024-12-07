local service = {}
service.dependencies = {Packages = {"ecr"}, Remotes = {"entityUpdate", "destroyEntity"}, Components = {"mainComponents"}}

function service:getServerId(clientId: number): number | nil
    for serverId, client in self.serverIds do
        if client == clientId then
            return serverId
        end
    end
end

function service:run()
    self.registry = self.mainComponents.registry
    self.cts = self.mainComponents.components

    self.serverIds = {}

    self.entityUpdate.SetCallback(function(newData)
        for _, entity in newData do
            --[[local id = entity.id

            if not self.registry:contains(entity.id) then
                self.registry:create(entity.id)
            end]]

            local id = self.serverIds[entity.id]
            if not id then
                self.serverIds[entity.id] = self.registry:create()
                id = self.serverIds[entity.id]
            end

            for _, componentDict in entity.components do
                local component = self.cts[componentDict.component]
                local value = componentDict.value.value

                if value == "removed" and self.registry:has(id, component) then
                    self.registry:remove(id, component)
                elseif componentDict.value.value ~= "removed" then
                    self.registry:set(id, component, value)
                end
            end
        end
    end)
end

return service