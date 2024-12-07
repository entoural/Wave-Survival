--[[
local id = 1023123

local function foo(x: number): number
    return bit32.band(x, 0xFFFF)
end


local map = {}
local values = {}


local y = values[foo(
    map[foo(id)]
)]



print(y)

local BOX = {
    V = "│",
    H = "─",
    TL = "┌",
    BL = "└",
    HD = "┬",
    VR = "├",
    HU = "┴",
    TR = "┐",
    BR = "┘",
   -- VG = color.gray "│"
}
]]




do
    type ISignal<T...> = {
        connect: (self: ISignal<T...>, fn: (T...) -> ()) -> ()
    }
end









type ISignalPrototype = {
    connect: <T...>(self: ISignal<T...>, fn: (T...) -> ()) -> ()
}

type ISignal<T...> = typeof(setmetatable(
    {},
    {} :: ISignalPrototype
))

local visible = if local_player_data.IsSpectator then
    (player_data.IsSpectator or (not local_player_data.IsHunter) or (local_player_data.IsHunter and player_data.IsHunter))
    else ((player == localPlayer) or
        local_player_data.IsSpectator or
        player_data.IsHunter or
        ((not local_player_data.IsHunter) and (not player_data.IsHunter)))

local function PRINT_IDS(reg, show_dense: boolean?)
    local NULL_KEY = 2^16 - 1
    local pool = reg:storage(ecr.entity)
    local map = pool.map
    local entities = pool.entities

    local TAB = "    "

    print "{"
    print(`{TAB}capacity = {pool.capacity}`)
    print(`{TAB}free = {pool.free == NULL_KEY and "X" or pool.free}`)
    print(`{TAB}map = \{`)
    for i = 0, buffer.len(map) - 1, 4 do
        local v = buffer.readu32(map, i)
        print(`{TAB}{TAB}[{i/4}] {INSPECT_ID(v)}`)
    end
    print(`{TAB}}`)

    if show_dense then
        print(`{TAB}entities = \{`)
        print(`{TAB}{TAB}n = {pool.size}`)
        for i = 0, buffer.len(entities) - 1, 4 do
            local v = buffer.readu32(entities, i)
            print(`{TAB}{TAB}[{i/4}] {INSPECT_ID(v)}`)
        end
        print(`{TAB}}`)
    end

    print "}"
end

local function PRINT_POOL(reg, ctype, show_dense: boolean?)
    local pool = reg:storage(ctype)
    local map = pool.map
    local entities = pool.entities

    local TAB = "    "

    print "{"
    print(`{TAB}map_max = {pool.map_max}`)
    print(`{TAB}map = \{`)
    for i = 0, buffer.len(map) - 1, 4 do
        local v = buffer.readu32(map, i)
        print(`{TAB}{TAB}[{i/4}] {INSPECT_ID(v)}`)
    end
    print(`{TAB}}`)
    
    if show_dense then
        print(`{TAB}capacity = {pool.capacity}`)
        print(`{TAB}entities = \{`)
        print(`{TAB}{TAB}n = {pool.size}`)
        for i = 0, buffer.len(entities) - 1, 4 do
            local v = buffer.readu32(entities, i)
            print(`{TAB}{TAB}[{i/4}] {INSPECT_ID(v)}`)
        end
        print(`{TAB}}`)
    end

    print "}"
end

local function INSPECT_ID(id: number): string
    local NULL_VER = 0
    local NULL_KEY = 2^16 - 1

    local MASK_KEY = 0b_0000_0000_0000_0000__1111_1111_1111_1111
    local MASK_VER = 0b_0111_1111_1111_1111__0000_0000_0000_0000
    local MASK_RES = 0b_1000_0000_0000_0000__0000_0000_0000_0000

    local key = bit32.band(id, MASK_KEY)
    local ver = bit32.rshift(bit32.band(id, MASK_VER), 16)
    local res = bit32.band(id, MASK_RES)
    return `{key == NULL_KEY and "_" or key}:{ver == NULL_VER and "_" or ver} {res == 0 and "" or "IN_USE"}`
end
