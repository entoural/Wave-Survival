--[[

By centau_ri
v0.2

Things to know:

- You can set a max size, the leaderboard size will never be bigger than this.
  Max size is 100 by default.
- Add and remove functions return the new leaderboard.
- Leaderboard entries are sorted from highest to lowest.

Example:

```
local DataStoreService = game:GetService("DataStoreService")
local Leaderboard = require(Leaderboard)

local leaderboardStore = DataStoreService:GetDataStore("Leaderboards")

local sickShotLeaderboard = Leaderboard.new(leaderboardStore, "SickShot")

sickShotLeaderboard.MaxSize = 1000

local function addScore(score, player)
    sickShotLeaderboard:AddAsync(score, { UserId = player.UserId })
end

local function removeScores(player)
    sickShotLeaderboard:RemoveAsync(function(entry)
        return entry.Extra.UserId == player.UserId -- return true to remove score
    end)
end
```

]]

type Leaderboard<T = unknown> = {
    DataStore: DataStore,
    Key: string,
    MaxSize: number,

    AddAsync: (self: Leaderboard<T>, score: number, extra: T?) -> { Entry<T> },
    RemoveAsync: (self: Leaderboard<T>, remover: (entry: Entry<T>) -> boolean) -> { Entry<T> },
    GetAsync: (self: Leaderboard<T>) -> { Entry<T> },
    WipeAsync: (self: Leaderboard<T>) -> ()
}

type Entry<T> = {
    Score: number,
    Extra: T
}

local Leaderboard = {}

local DEFAULT_EXTRA = {} :: any

function Leaderboard.new<T>(datastore: DataStore, key: string): Leaderboard<T>
    local self = {}

    self.DataStore = datastore
    self.Key = key
    self.MaxSize = 100

    function self.AddAsync(self: Leaderboard<T>, score: number, extra: T?): { Entry<T> }
        local ok, result = pcall(function()
            return self.DataStore:UpdateAsync(self.Key, function(data: { Entry<T> })
                data = data or {}

                local inserted = false

                -- loop over all scores and insert into the first place the new score is larger
                -- sorted from Largest to Lowest
                for i, entry in data do
                    if score > entry.Score then
                        table.insert(data, i, { Score = score, Extra = extra or DEFAULT_EXTRA})
                        inserted = true
                        break
                    end
                end

                -- if it hasn't been inserted already then it means it is the lowest score
                -- add to the end
                if not inserted then
                    table.insert(data, { Score = score, Extra = extra or DEFAULT_EXTRA })
                end

                -- remove lowest entries until data is within max size
                while #data > self.MaxSize do
                    table.remove(data)
                end
                
                return data
            end)
        end)

        if not ok then error(`an error occured while adding to leaderboard {self.Key}:\n{result}`) end
        
        return table.freeze(result)
    end

    function self.RemoveAsync(self: Leaderboard<T>, remover: (Entry<T>) -> boolean): { Entry<T> }
        local ok, result = pcall(function()
            return self.DataStore:UpdateAsync(self.Key, function(data: { Entry<T> })
                data = data or {}

                -- loop over all scores and check using remover
                -- loop backwards so removal does not affect iteration order
                for i = #data, 1, -1 do
                    if remover(data[i]) then
                        table.remove(data, i)
                    end
                end

                -- remove lowest entries until data is within max size
                while #data > self.MaxSize do
                    table.remove(data)
                end
                
                return data
            end)
        end)

        if not ok then error(`an error occured while removing from leaderboard {self.Key}:\n{result}`) end
        
        return table.freeze(result)
    end

    function self.GetAsync(self: Leaderboard<T>): { Entry<T> }
        local ok, result = pcall(function()
            return self.DataStore:GetAsync(self.Key)
        end)

        if not ok then error(`an error occured while getting leaderboard {self.Key}:\n{result}`) end

        return result
    end

    function self.WipeAsync(self: Leaderboard<T>)
        local ok, err = pcall(function()
            return self.DataStore:RemoveAsync(self.Key)
        end)

        if not ok then error(`an error occured while wiping leaderboard {self.Key}:\n{err}`) end
    end

    return self
end

return Leaderboard
