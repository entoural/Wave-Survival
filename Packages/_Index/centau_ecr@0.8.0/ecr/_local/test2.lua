do
    local N = 1e6
    local name = ""
    
    local start = os.clock()
    for i = 1, N do

    end
    local stop = os.clock()
    print(`{name}: {math.floor((stop-start)/N*1e9)} ns`)
end

local function KEY(id)
    return bit32.band(id, 12)
end

local data = { 123123123 }
local state = {}

local function f1(...)
    for i = 1, select("#", ...) do
        local x = select(i, ...)
        state.x = x
    end
end

local function f2(...)
    local i = 1
    local x = ...
    repeat
        state.x = x
        -- stuff
        i += 1
        x = select(i, ...)
    until x == nil
end

do
    local N = 1e7
    local name = ""
    
    local start = os.clock()
    for i = 1, N do
        f1()
    end
    local stop = os.clock()
    print(`{name}: {math.floor((stop-start)/N*1e9)} ns`)
end

do
    local N = 1e7
    local name = ""
    
    local start = os.clock()
    for i = 1, N do
        f2()
    end
    local stop = os.clock()
    print(`{name}: {math.floor((stop-start)/N*1e9)} ns`)
end
