local signal = setmetatable({}, {
    __add = function(self: any, fn: () -> ())
        print ":3"
        return self
    end
})

signal += function()

end

local _ = signal 



