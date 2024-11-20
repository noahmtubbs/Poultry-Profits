-- gameFeatures.lua

local upgradeSystem = {}

function upgradeSystem.init()
    shop.upgrades = {}

    
    upgradeSystem.addUpgrade("Increase Capacity (+5)", 200, function()
        player.maxCapacity = player.maxCapacity + 5
        table.insert(messages, {text = "Increased carrying capacity!", timer = 2})
    end, true)

    upgradeSystem.addUpgrade("Buy Chicken", 500, function()
        local newChicken = Chicken:new(math.random(400, 600), math.random(350, 450))
        newChicken.baseY = newChicken.y
        table.insert(chickens, newChicken)
        table.insert(messages, {text = "Bought a new chicken!", timer = 2})
    end, true)
    
    upgradeSystem.addUpgrade("Buy Feed (+10)", 50, function()
        player.carryingFeed = math.min(player.carryingFeed + 10, player.maxFeedCapacity)
        table.insert(messages, {text = "Bought more feed!", timer = 2})
    end, true)

    upgradeSystem.addUpgrade("Increase Market Capacity (+20)", 300, function()
        marketCapacity = marketCapacity + 20
        table.insert(messages, {text = "Increased market capacity!", timer = 2})
    end, true)

    upgradeSystem.addUpgrade("Improve Egg Laying Speed", 400, function()
        for _, chicken in ipairs(chickens) do
            chicken.eggLayingInterval = math.max(1, chicken.eggLayingInterval - 0.5)
        end
        table.insert(messages, {text = "Improved egg laying speed!", timer = 2})
    end, true)

    upgradeSystem.addUpgrade("Increase Speed", 300, function()
        player.speed = player.speed + 30
        table.insert(messages, {text = "Increased player speed!", timer = 2})
    end, false)

    upgradeSystem.addUpgrade("Increase Feed Capacity (+10)", 150, function()
        player.maxFeedCapacity = player.maxFeedCapacity + 10
        table.insert(messages, {text = "Increased feed capacity!", timer = 2})
    end, true)

    upgradeSystem.addUpgrade("Egg Magnet", 800, function()
        player.hasEggMagnet = true
        table.insert(messages, {text = "You acquired the Egg Magnet!", timer = 2})
    end, false)

    upgradeSystem.addUpgrade("Hire Farmhand", 1000, function()
        player.hasFarmhand = true
        table.insert(messages, {text = "You hired a farmhand!", timer = 2})
    end, false)

    upgradeSystem.addUpgrade("Guard Dog", 800, function()
        player.hasGuardDog = true
        table.insert(messages, {text = "You bought a guard dog!", timer = 2})
    end, false)
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

function upgradeSystem.purchaseUpgrade(upgradeIndex)
    local upgrade = shop.upgrades[upgradeIndex]
    
    -- Check if the upgrade is non-repeatable and already purchased
    if upgrade.purchased and not upgrade.repeatable then
        table.insert(messages, {text = "This upgrade has already been purchased!", timer = 2})
        return
    end

    -- Check if player has enough money
    if money >= upgrade.cost then
        -- Deduct money
        money = money - upgrade.cost
        -- Execute the upgrade's action
        upgrade.action()

        -- Mark upgrade as purchased (unless repeatable)
        if not upgrade.repeatable then
            upgrade.purchased = true
        end

        table.insert(messages, {text = "Upgrade purchased!", timer = 2})
    else
        table.insert(messages, {text = "Not enough money!", timer = 2})
    end
end


-- Return modules
return {
    upgradeSystem = upgradeSystem
}
