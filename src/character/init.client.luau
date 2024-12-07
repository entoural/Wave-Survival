local packagesFolder = game:GetService("ReplicatedStorage"):WaitForChild("Packages")

-- Required packages: GoodSignal
local goodSignal = require(packagesFolder.signal)


type indexedDictionaries = {[string]: {}}

local network = require(game:GetService("Players").LocalPlayer.PlayerScripts.Client.network)
local remotes: indexedDictionaries = {}
local packages: indexedDictionaries = {}
local cachedGameServices: indexedDictionaries = {}
local cachedModules: indexedDictionaries = {}

local dependencyReferences = {
    ["Remotes"] = remotes,
    ["Packages"] = packages
}

local cycleTypes: {[string]: number} = {
    ["Components"] = 1,
    ["Services"] = 2,
    ["Game Runners"] = 3
}

local cycleYielding: {[string]: {hasFinished: boolean, signal: {}}} = {
    ["Components"] = {hasFinished = false, signal = goodSignal.new()},
    ["Services"] = {hasFinished = false, signal = goodSignal.new()},
    ["Game Runners"] = {hasFinished = false, signal = goodSignal.new()}
}

local function filterName(moduleName: string)
    return moduleName:gsub("^[%d+] ", "")
end


local API = {
    yieldForEOC = function(moduleType: string, callback: () -> any)
        if not callback then
            warn("Did not pass a callback to moduleloader API")
        end

        if not cycleYielding[moduleType].hasFinished then
            cycleYielding[moduleType].signal:Wait()
        end
        callback()
    end,

    yieldFor = function(_: string, moduleName: string, callback: ({}) -> any)
        if not callback then
            warn("Did not pass a callback to moduleloader API")
        end

        for cachedModuleType, dictionary in cachedModules do
            if dictionary[moduleName] then
                if not cycleYielding[cachedModuleType].hasFinished then
                    cycleYielding[cachedModuleType].signal:Wait()
                end

                callback(dictionary[moduleName])
                return
            end
        end

        local moduleTypes = {}
        for index, order in cycleTypes do
            moduleTypes[order] = index
        end

        for _, cycleModuleType in moduleTypes do
            local cycle = cycleYielding[cycleModuleType]

            if not cycle.hasFinished then
                cycle.signal:Wait()

                local cached = cachedModules[cycleModuleType][moduleName]

                if cached then
                    callback(cached)
                    return
                end
            end
        end

        error(`Unable to find module {moduleName}`)
    end
}

function genAPI(moduleType: string)
    local newAPI = {}

    for func, _ in API do
        newAPI[func] = function(...)
            task.spawn(API[func], moduleType, ...)
        end
    end

    return newAPI
end

-- Gets all packages and network remotes (from Zap)
function sortPackagesAndNetwork()
    for _, package in packagesFolder:GetChildren() do
        if package:IsA("ModuleScript") then
            packages[package.Name] = require(package)
        end
    end

    for name, remote in network do
        if name ~= "SendEvents" then
            remotes[name] = remote
        end
    end
end

-- Just makes the first character of the string lowercase
function forceCamelCase(str: string)
    return string.lower(string.sub(str, 1, 1)) .. string.sub(str, 2)
end

-- Sorts an array of modules by their execution priority (found in Instance name). Ex. '[2] PlayerService'
function sortByPriority(modules: {ModuleScript})
    local function getPriority(module: ModuleScript)
        return tonumber(module.Name:match("^[(%d+)]")) or 20
    end

    table.sort(modules, function(a: ModuleScript, b: ModuleScript)
        return getPriority(a) < getPriority(b)
    end)
end

-- Inserts dependencies into the modulescript
function injectDependencies(module: {}, moduleType: string, moduleName: string)
    for dependency, array in module.dependencies do
        if cycleTypes[dependency] then
            if cycleTypes[dependency] > cycleTypes[moduleType] then
                warn(`{moduleName} contains a dependency of a module type ran further in the run cycle, it has not been injected.`)
                continue
            end

            for _, moduleDependency in array do
                local cachedModule = cachedModules[dependency][moduleDependency]
                if not cachedModule then
                    warn(`Module {moduleDependency} does not exist in cached modules of type {dependency}`)
                    continue
                end

                module[moduleDependency] = cachedModule
            end
        elseif dependency == "GameServices" then
            for _, serviceDependency in array do
                local camelCasedDependency = forceCamelCase(serviceDependency)

                local cachedGameService = cachedGameServices[camelCasedDependency]
                if cachedGameService then
                    module[camelCasedDependency] = cachedGameService
                else
                    local success, msg = pcall(function()
                        return game:GetService(serviceDependency)
                    end)

                    if success then
                        module[camelCasedDependency] = msg
                    else
                        warn(`Couldn't get roblox service {serviceDependency}`)
                    end
                end
            end
        elseif dependencyReferences[dependency] then
            local referenced = dependencyReferences[dependency]

            for _, requiredDependency in array do
                module[requiredDependency] = referenced[requiredDependency]
            end
        end
    end
end

function getNonIsolatedCount(modules: {{}})
    local nonIsolatedCount = 0

    for _, requiredModule in modules do
        if not requiredModule.cycleIsolated then
            nonIsolatedCount += 1
        end
    end

    return nonIsolatedCount
end

-- Sorts modules by execution order, requires them, caches them, injects their dependencies, and calls their 'run' method
function runCycle(moduleType: string, modules: {ModuleScript}?)
    local modulesArray = modules or script:FindFirstChild(moduleType):GetChildren()
    sortByPriority(modulesArray)
    cachedModules[moduleType] = {}

    local indexedModuleReturns = {}
    for _, module in modulesArray do
        local filteredName = filterName(module.Name)
        local returnedDictionary = require(module)

        cachedModules[moduleType][filteredName] = returnedDictionary
        indexedModuleReturns[filteredName] = returnedDictionary
    end

    for moduleName, module: {} in indexedModuleReturns do
        if not module.dependencies then
            continue
        end

        injectDependencies(module, moduleType, moduleName)
    end

    local finishedRunning = 0
    local nonIsolatedCount = getNonIsolatedCount(indexedModuleReturns) or 0

    task.spawn(function()
        while finishedRunning < nonIsolatedCount do
            task.wait()
        end

        game:GetService("RunService").Heartbeat:Wait()

        cycleYielding[moduleType].hasFinished = true
        cycleYielding[moduleType].signal:Fire()
    end)

    for _, moduleInstance: {ModuleScript} in modulesArray do
        local module = require(moduleInstance)

        local moduleAPI = genAPI(moduleType)
        local function run()
            if module.run then
                module:run(moduleAPI)
            end
            finishedRunning += 1
        end

        if module.synchronous then
            run()
        else
            task.spawn(run)
        end
    end

    cycleYielding[moduleType].signal:Wait()
end

-- Calls runCycle for each module type in order
function beginCycling()
    local moduleTypes = {}
    for index, order in cycleTypes do
        moduleTypes[order] = index
    end

    for _, moduleType in moduleTypes do
        runCycle(moduleType)
    end
end

sortPackagesAndNetwork()
beginCycling()