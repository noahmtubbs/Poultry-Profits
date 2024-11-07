-- gameFeatures.lua

local randomEvents = {}

function randomEvents.init()
    randomEvents.timer = 0
    randomEvents.interval = math.random(60, 120)
    randomEvents.activeEvent = nil
    randomEvents.duration = 0
end

function randomEvents.update(dt)
    randomEvents.timer = randomEvents.timer + dt
    if randomEvents.timer >= randomEvents.interval then
        randomEvents.triggerEvent()
        randomEvents.timer = 0
        randomEvents.interval = math.random(60, 120)
    end

    if randomEvents.activeEvent then
        randomEvents.duration = randomEvents.duration - dt
        if randomEvents.duration <= 0 then
            randomEvents.endEvent()
        end
    end
end

function randomEvents.triggerEvent()
    local events = {"drought", "festival", "marketCrash", "feedShortage", "goldenEggRush"}
    local event = events[math.random(#events)]
    randomEvents.activeEvent = event
    randomEvents.duration = math.random(30, 60)

    if event == "drought" then
        for _, chicken in ipairs(chickens) do
            chicken.eggLayingInterval = chicken.eggLayingInterval + 2
        end
        table.insert(messages, {text = "A drought has started! Egg production decreased.", timer = 5})
    elseif event == "festival" then
        eggPrice = eggPrice + 10
        table.insert(messages, {text = "A festival is happening! Egg prices increased.", timer = 5})
    elseif event == "marketCrash" then
        eggPrice = math.max(5, eggPrice - 10)
        table.insert(messages, {text = "Market crash! Egg prices decreased.", timer = 5})
    elseif event == "feedShortage" then
        for _, upgrade in ipairs(shop.upgrades) do
            if upgrade.name == "Buy Feed (+10)" then
                upgrade.cost = upgrade.cost + 50
                break
            end
        end
        table.insert(messages, {text = "Feed shortage! Feed prices increased.", timer = 5})
    elseif event == "goldenEggRush" then
        for _, chicken in ipairs(chickens) do
            chicken.goldenEggChance = 20
        end
        table.insert(messages, {text = "Golden Egg Rush! Higher chance for golden eggs.", timer = 5})
    end
end

function randomEvents.endEvent()
    if randomEvents.activeEvent == "drought" then
        for _, chicken in ipairs(chickens) do
            chicken.eggLayingInterval = chicken.eggLayingInterval - 2
        end
        table.insert(messages, {text = "The drought has ended.", timer = 5})
    elseif randomEvents.activeEvent == "festival" then
        eggPrice = eggPrice - 10
        table.insert(messages, {text = "The festival has ended. Egg prices normalized.", timer = 5})
    elseif randomEvents.activeEvent == "marketCrash" then
        eggPrice = eggPrice + 10
        table.insert(messages, {text = "The market has recovered. Egg prices normalized.", timer = 5})
    elseif randomEvents.activeEvent == "feedShortage" then
        for _, upgrade in ipairs(shop.upgrades) do
            if upgrade.name == "Buy Feed (+10)" then
                upgrade.cost = upgrade.cost - 50
                break
            end
        end
        table.insert(messages, {text = "Feed prices have returned to normal.", timer = 5})
    elseif randomEvents.activeEvent == "goldenEggRush" then
        for _, chicken in ipairs(chickens) do
            chicken.goldenEggChance = 5
        end
        table.insert(messages, {text = "Golden Egg Rush has ended.", timer = 5})
    end

    randomEvents.activeEvent = nil
    randomEvents.duration = 0
end

local upgradeSystem = {}

function upgradeSystem.init()
    shop.upgrades = {}
    upgradeSystem.addUpgrade("Increase Capacity (+5)", 200, function()
        player.maxCapacity = player.maxCapacity + 5
        table.insert(messages, {text = "Increased carrying capacity!", timer = 2})
    end)

    upgradeSystem.addUpgrade("Buy Chicken", 500, function()
        if #chickens < barn.capacity then
            local newChicken = Chicken:new(math.random(500, windowWidth - 60), math.random(100, buttonY - 60))
            newChicken.baseY = newChicken.y
            table.insert(chickens, newChicken)
            table.insert(messages, {text = "Bought a new chicken!", timer = 2})
        else
            table.insert(messages, {text = "Your barn can't hold more chickens!", timer = 2})
        end
    end)

    upgradeSystem.addUpgrade("Buy Feed (+10)", 50, function()
        player.carryingFeed = math.min(player.carryingFeed + 10, player.maxFeedCapacity)
        table.insert(messages, {text = "Bought more feed!", timer = 2})
    end)

    upgradeSystem.addUpgrade("Increase Market Capacity (+20)", 300, function()
        marketCapacity = marketCapacity + 20
        table.insert(messages, {text = "Increased market capacity!", timer = 2})
    end)

    upgradeSystem.addUpgrade("Improve Egg Laying Speed", 400, function()
        for _, chicken in ipairs(chickens) do
            chicken.eggLayingInterval = math.max(1, chicken.eggLayingInterval - 0.5)
        end
        table.insert(messages, {text = "Improved egg laying speed!", timer = 2})
    end)

    upgradeSystem.addUpgrade("Upgrade Barn (Level Up)", barn.upgradeCost, function()
        barn.level = barn.level + 1
        barn.capacity = barn.capacity + 4
        barn.upgradeCost = barn.upgradeCost + 500
        for _, upgrade in ipairs(shop.upgrades) do
            if upgrade.name == "Upgrade Barn (Level Up)" then
                upgrade.cost = barn.upgradeCost
                break
            end
        end
        table.insert(messages, {text = "Upgraded the barn!", timer = 2})
    end)

    upgradeSystem.addUpgrade("Increase Speed", 300, function()
        player.speed = player.speed + 30
        table.insert(messages, {text = "Increased player speed!", timer = 2})
    end)

    upgradeSystem.addUpgrade("Increase Feed Capacity (+10)", 150, function()
        player.maxFeedCapacity = player.maxFeedCapacity + 10
        table.insert(messages, {text = "Increased feed capacity!", timer = 2})
    end)

    upgradeSystem.addUpgrade("Egg Magnet", 800, function()
        player.hasEggMagnet = true
        table.insert(messages, {text = "You acquired the Egg Magnet!", timer = 2})
    end)

    upgradeSystem.addUpgrade("Hire Farmhand", 1000, function()
        player.hasFarmhand = true
        table.insert(messages, {text = "You hired a farmhand!", timer = 2})
    end)

    upgradeSystem.addUpgrade("Guard Dog", 800, function()
        player.hasGuardDog = true
        table.insert(messages, {text = "You bought a guard dog!", timer = 2})
    end)
end

function upgradeSystem.addUpgrade(name, cost, action)
    table.insert(shop.upgrades, {
        name = name,
        cost = cost,
        action = action
    })
end

function upgradeSystem.update()
    -- Placeholder for dynamic upgrade changes
end

-- Return modules
return {
    randomEvents = randomEvents,
    upgradeSystem = upgradeSystem
}
