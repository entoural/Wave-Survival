## Case 1

Replicate entities that get a network id added.

```lua
local observer = world:track(NetworkId)
    :added()
    :latest()

return function()
    for id, networkid in observer do
        replicate(id, networkid)
    end
    observer:clear()
end
```

## Case 2

Update model transforms if either model or transform was manually changed.

```lua
local observer = world:track(Transform, Model)
    :added()
    :changed()
    :latest()

return function()
    for id, transform, model in observer do
        model:PivotTo(transform)
    end
    observer:clear()
end
```

## Case 3

Destroy unused models if they were changed or removed.

```lua
local observer = world:track(Model)
    :added()
    :changed()
    :removed()
    :history()

return function()
    local last: Model? = nil

    for id, model in observer do
        -- if on last iteration a model exists
        -- we know that model is still in use and won't be destroyed
        if last then
            last:Destroy()
        end
        last = model
    end
    observer:clear()
end
```

## Case 4 [TODO]

Get current state of components if they differ for replication.

```lua
local observers = {}

for i, component in replicated do
    observers[i] = world:track(component):--????
end
```
