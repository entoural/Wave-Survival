local ID_MASK = 0x000F_FFFF
local ID_LSHIFT = ID_MASK + 1

-- creates an id composed of an index and a version
local function ID_CREATE(index: number, ver: number): number
    return ver * ID_LSHIFT + index
end

-- gets the index of an entity id
local function ID_INDEX(id: number): number
    return bit32.band(id, ID_MASK)
end

-- swaps and mixes array values to maximize cache misses
local function scramble(array)
    for i = 1, #array do
        local r = math.random(1, #array)
        array[i], array[r] = array[r], array[i]
    end
end

-- the following benchmarks each iterate through an array of entity ids
-- and uses the id to set a value in an array

local N = 1e6

do -- array index extracted from the id and used as an array index
    local ids = table.create(N)

    for i = 1, N do
        ids[i] = ID_CREATE(i, 1)
    end

    scramble(ids)

    local data = table.create(N)

    local start = os.clock()
    for i = 1, N do
        data[ID_INDEX(ids[i])] = true
    end
    local stop = os.clock()
    print("array index (with recycling): " .. stop - start)
end

do -- id itself is used as a hashmap index
    local ids = table.create(N)

    for i = 1, N do
        ids[i] = i + N*2
    end

    scramble(ids)

    local data = table.create(N)

    local start = os.clock()
    for i = 1, N do
        data[ids[i]] = true
    end
    local stop = os.clock()
    print("hashmap index: " .. stop - start)
end
