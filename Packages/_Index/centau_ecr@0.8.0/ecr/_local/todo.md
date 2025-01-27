- instead of using removing event to remove from observers, check if entity has component during iteration
- improve docs
- add batch set
- add greater customization to observers
- `O(n)` where `n = component_types_entity_has` destroy (currently `O(n)` where `n = component_types_registry_has`)
- add snapshots and loaders
- sig helper
- move group check to listeners
- patch call constructor if nil
- change logo

```svg
<svg width="248" height="64" viewBox="0 0 248 64" fill="none" xmlns="http://www.w3.org/2000/svg">
<rect x="0.30307" width="64" height="64" rx="8" fill="#D9D9D9"/>
<rect x="68.3031" width="64" height="64" rx="8" fill="#D9D9D9"/>
<rect x="136.303" width="64" height="64" rx="8" fill="#D8560D"/>
<path d="M48.3031 18H22.3031C20.0939 18 18.3031 19.7909 18.3031 22V32M48.3031 46H22.3031C20.0939 46 18.3031 44.2091 18.3031 42V32M18.3031 32H36.3031" stroke="#515151" stroke-width="4"/>
<path d="M116.303 46H90.3031C88.0939 46 86.3031 44.2091 86.3031 42V22C86.3031 19.7909 88.0939 18 90.3031 18H116.303" stroke="#515151" stroke-width="4"/>
<path d="M152.303 48V34M152.303 34V22C152.303 19.7909 154.094 18 156.303 18H178.303C180.512 18 182.303 19.7909 182.303 22V30C182.303 32.2091 180.512 34 178.303 34H176.303M152.303 34H168.303H176.303M176.303 34L179.131 36.8284C179.882 37.5786 180.303 38.596 180.303 39.6569V48" stroke="white" stroke-width="4"/>
<rect x="216.989" y="12.4041" width="32" height="32" transform="rotate(15 216.989 12.4041)" fill="#D8560D"/>
<rect x="236.818" y="21.8583" width="6.4" height="6.4" transform="rotate(15 236.818 21.8583)" fill="white"/>
</svg>
```

```lua
local entity = world:handle(id)

entity:set(ec.Health, 100):set(ec.Team, "Bruh")
entity:remove(ec.Health, ec.Team)
entity:contains()
entity:destroy()

```

```lua
-- old
world:added(component):connect(function)
world:changed(component):connect(function)
world:removing(component):connect(function)

-- new 1
world:track(component)
    :added(function)
    :changed(function)
    :removing(function)
```
