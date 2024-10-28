-- main.lua

local cash = require("cash")


-- Remove 'local' to make these variables global
shop = {
    x = 200,
    y = 500,
    width = 100,
    height = 50,
    size = 50,
    color = {0.5, 0.5, 0.5},
    upgrades = {},
    selectedUpgrade = 1,
    upgradeRects = {} -- For mouse interaction
}

player = {
    x = 100,
    y = 500,
    size = 50,
    speed = 150,
    carryingEggs = 0,
    carryingFeed = 5,
    maxCapacity = 10,
    maxFeedCapacity = 20,
    level = 1,
    experience = 0,
    experienceToLevelUp = 100,
    abilities = {},
    quests = {},
    hasEggMagnet = false, -- New ability
    hasFarmhand = false,  -- New ability
    hasGuardDog = false,  -- New ability
    inventory = {}        -- For inventory system
}

-- Chickens
Chicken = {}
Chicken.__index = Chicken

function Chicken:new(x, y)
    local chicken = {
        x = x,
        y = y,
        size = 50,
        hasEgg = false,
        nextEggTimer = 0,
        eggLayingInterval = 6, -- Adjusted for balance
        hunger = 100,
        isFed = true,
        isSleeping = false,
        goldenEggChance = 5 -- Default 5% chance
    }
    setmetatable(chicken, Chicken)
    return chicken
end

function Chicken:update(dt)
    -- At night, chickens sleep
    if isNight then
        self.isSleeping = true
    else
        self.isSleeping = false
    end

    if not self.isSleeping then
        -- Decrease hunger over time
        self.hunger = math.max(0, self.hunger - dt * 0.5)
        if self.hunger <= 0 then
            self.isFed = false
        end

        if self.isFed then
            if not self.hasEgg then
                self.nextEggTimer = self.nextEggTimer + dt

                local adjustedEggLayingInterval = self.eggLayingInterval
                if weather == 'rainy' then
                    adjustedEggLayingInterval = adjustedEggLayingInterval + 1
                elseif weather == 'stormy' then
                    adjustedEggLayingInterval = adjustedEggLayingInterval + 2
                end

                if self.nextEggTimer >= adjustedEggLayingInterval then
                    spawnEgg(self)
                    self.nextEggTimer = 0
                end
            end
        end
    end
end

-- Initialize chickens
chickens = {}

function initializeChickens()
    chickens = {
        Chicken:new(600, 400),
        Chicken:new(800, 200),
        Chicken:new(700, 300),
        Chicken:new(750, 450)
    }
end

-- Eggs
eggs = {}

-- Money and Market
money = 0
highScore = 0 -- Track high score
totalEggsInMarket = 0
marketCapacity = 50
eggPrice = 20
goldenEggPrice = 100

-- Marketplace
marketplace = {
    x = 850,
    y = 220,
    width = 100,
    height = 100,
    color = {0, 0, 1}
}

-- Barn
barn = {
    x = 300,
    y = 500,
    width = 100,
    height = 50,
    level = 1,
    capacity = 4,
    upgradeCost = 500
}

-- Customers
customers = {}
maxCustomers = 3
customerWidth = 30
customerHeight = 50
customerNeeds = {}
customerTimers = {}
customerTimeLimit = 120

-- Messages
messages = {}

-- Achievements
achievements = {
    eggCollector = {unlocked = false, threshold = 50, progress = 0},
    chickenGuardian = {unlocked = false, threshold = 5, count = 0},
    masterFarmer = {unlocked = false, threshold = 5000, progress = 0},
    questMaster = {unlocked = false, threshold = 3, completed = 0},
}

-- Quests
quests = {}

function generateRandomQuest()
    local questTypes = {"Collect Eggs", "Earn Money", "Reach Level"}
    local questType = questTypes[math.random(#questTypes)]
    local quest = {}
    if questType == "Collect Eggs" then
        local amount = math.random(10, 50)
        quest = {
            description = "Collect " .. amount .. " eggs",
            completed = false,
            condition = function() return achievements.eggCollector.progress >= amount end,
            reward = amount * 5
        }
    elseif questType == "Earn Money" then
        local amount = math.random(500, 2000)
        quest = {
            description = "Earn " .. amount .. " KSH",
            completed = false,
            condition = function() return money >= amount end,
            reward = math.floor(amount * 0.1)
        }
    elseif questType == "Reach Level" then
        local targetLevel = player.level + math.random(1, 3)
        quest = {
            description = "Reach Level " .. targetLevel,
            completed = false,
            condition = function() return player.level >= targetLevel end,
            reward = targetLevel * 100
        }
    end
    return quest
end

-- Weather System
weather = 'sunny'
weatherTimer = 0
weatherDuration = 60 -- seconds

-- Window Dimensions
windowWidth = 1000
windowHeight = 600

-- Screen Management
currentScreen = "farm"
buttonY = windowHeight - 50
buttonHeight = 50
buttonWidth = windowWidth
buttonHover = false

-- Day-Night Cycle
dayTimer = 0
dayDuration = 90
currentDay = 1
isNight = false

-- Combo Multiplier
comboMultiplier = 1
comboTimer = 0
comboDuration = 5

-- Pause Functionality
isPaused = false

-- Predators
predators = {
    fox = {
        x = 0,
        y = 0,
        size = 50,
        speed = 100,
        isActive = false,
        targetChicken = nil,
        spawnTimer = 0,
        spawnInterval = 45
    },
    snake = {
        x = 0,
        y = 0,
        size = 40,
        speed = 80,
        isActive = false,
        targetChicken = nil,
        spawnTimer = 0,
        spawnInterval = 35
    },
    hawk = {
        x = 0,
        y = 0,
        size = 60,
        speed = 120,
        isActive = false,
        targetChicken = nil,
        spawnTimer = 0,
        spawnInterval = 50
    }
}

-- Guard Dog
dog = {
    x = 0,
    y = 0,
    size = 40,
    speed = 200,
    isActive = false,
    targetPredator = nil
}

-- Tutorial Variables
tutorialStep = 1
tutorialMessages = {
    "Welcome to Poultry Profits!",
    "Use the WASD or Arrow keys to move your character.",
    "Collect eggs from the chickens by moving near them and pressing Spacebar.",
    "Feed chickens by moving near them and pressing Spacebar if you have feed.",
    "Visit the shop to buy upgrades and feed.",
    "Sell eggs at the market to earn money.",
    "Complete quests to earn rewards.",
    "Protect your chickens from predators!",
    "Press 'P' to pause the game at any time.",
    "Press 'Enter' to start your farming adventure!"
}

-- Mouse Interaction
mouseOverUpgrade = nil

-- Fonts
titleFont = love.graphics.newFont(36)
hudFont = love.graphics.newFont(16)
messageFont = love.graphics.newFont(20)

-- Game States
gameState = "mainMenu" -- Possible states: mainMenu, tutorial, playing, paused

-- Require game features after defining globals
gameFeatures = require("gameFeatures")
randomEvents = gameFeatures.randomEvents
upgradeSystem = gameFeatures.upgradeSystem
inventorySystem = gameFeatures.inventorySystem

-- Helper Functions
function checkCollision(a, b)
    return a.x < b.x + (b.width or b.size) and
           a.x + (a.width or a.size) > b.x and
           a.y < b.y + (b.height or b.size) and
           a.y + (a.height or a.size) > b.y
end

function isInPickupRange(a, b)
    if math.abs(a.x - b.x) > 200 or math.abs(a.y - b.y) > 200 then
        return false
    end
    local aCenterX = a.x + (a.width or a.size) / 2
    local aCenterY = a.y + (a.height or a.size) / 2
    local bCenterX = b.x + (b.width or b.size) / 2
    local bCenterY = b.y + (b.height or b.size) / 2
    local distance = math.sqrt((aCenterX - bCenterX)^2 + (aCenterY - bCenterY)^2)
    local range = ((a.width or a.size) + (b.width or b.size)) / 2 + 50
    return distance <= range
end

function spawnEgg(chicken)
    local isGoldenEgg = math.random(1, 100) <= chicken.goldenEggChance
    table.insert(eggs, {
        x = chicken.x + chicken.size / 2,
        y = chicken.y + chicken.size,
        minY = chicken.y + chicken.size,
        maxY = chicken.y + chicken.size + 20,
        ySpeed = 30,
        collected = false,
        chicken = chicken,
        isGolden = isGoldenEgg,
        size = 20
    })
    chicken.hasEgg = true
    if isGoldenEgg then
        table.insert(messages, {text = "A golden egg has been laid!", timer = 3})
    end
end

function spawnCustomersAtMarket()
    customers = {}
    customerNeeds = {}
    customerTimers = {}
    maxCustomers = math.min(10, 3 + math.floor(currentDay / 2)) -- Increase customers over days
    local startX = marketplace.x - customerWidth - 50
    local startY = marketplace.y + marketplace.height / 2 - customerHeight / 2
    for i = 1, maxCustomers do
        local need = math.random(2, 10)
        local customer = {
            x = startX - (i - 1) * (customerWidth + 20),
            y = startY,
            width = customerWidth,
            height = customerHeight,
            needs = need,
            color = {0, 0, 1}
        }
        table.insert(customers, customer)
        table.insert(customerNeeds, need)
        table.insert(customerTimers, customerTimeLimit)
    end
end

function displayGlobalInfo()
    love.graphics.setFont(hudFont)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Day: " .. currentDay, 20, 20)
    love.graphics.print("Level: " .. player.level .. " (XP: " .. player.experience .. "/" .. player.experienceToLevelUp .. ")", 20, 40)
    love.graphics.print("Eggs: " .. player.carryingEggs .. "/" .. player.maxCapacity, 20, 60)
    love.graphics.print("Feed: " .. player.carryingFeed .. "/" .. player.maxFeedCapacity, 20, 80)
    love.graphics.print("Money: " .. money .. " KSH", 20, 100)
    love.graphics.print("Eggs in Market: " .. totalEggsInMarket .. "/" .. marketCapacity, 20, 120)
    love.graphics.print("Combo Multiplier: x" .. string.format("%.1f", comboMultiplier), 20, 140)
    love.graphics.print("High Score: " .. highScore .. " KSH", 20, 160)
    if isNight then
        love.graphics.print("Time: Night", 20, 180)
    else
        love.graphics.print("Time: Day", 20, 180)
    end
    love.graphics.print("Weather: " .. weather, 20, 200)
    local yOffset = 220
    if player.hasFarmhand then
        love.graphics.print("Farmhand: Hired", 20, yOffset)
        yOffset = yOffset + 20
    end
    if player.hasGuardDog then
        love.graphics.print("Guard Dog: Purchased", 20, yOffset)
        yOffset = yOffset + 20
    end
    -- Display current quest
    if #player.quests > 0 then
        local quest = player.quests[1]
        love.graphics.print("Current Quest: " .. quest.description, 20, yOffset)
        yOffset = yOffset + 20
        -- Display progress if applicable
        if quest.description:find("Collect") then
            local target = tonumber(quest.description:match("%d+"))
            local progress = achievements.eggCollector.progress
            love.graphics.print("Progress: " .. progress .. "/" .. target, 20, yOffset)
        elseif quest.description:find("Earn") then
            local target = tonumber(quest.description:match("%d+"))
            love.graphics.print("Progress: " .. money .. "/" .. target .. " KSH", 20, yOffset)
        elseif quest.description:find("Level") then
            local target = tonumber(quest.description:match("%d+"))
            love.graphics.print("Progress: Level " .. player.level .. "/" .. target, 20, yOffset)
        end
    else
        love.graphics.print("No Active Quests", 20, yOffset)
    end
end

-- Load Function
function love.load()
    love.window.setMode(windowWidth, windowHeight)
    love.window.setTitle("Poultry Profits: Egg-cellent Business")
    spawnCustomersAtMarket()
    initializeChickens()
    -- Initialize shop upgrades using the advanced upgrade system
    upgradeSystem.init()
    initializeQuests()
    math.randomseed(os.time())
    dog.x = barn.x + barn.width + 10 -- Start position near the barn
    dog.y = barn.y
    -- Initialize new systems
    randomEvents.init()
    inventorySystem.init()
end

function initializeQuests()
    -- Start with one random quest
    player.quests = {generateRandomQuest()}
end

-- Update Function
function love.update(dt)
    if gameState == "mainMenu" then
        -- Main menu logic
        return
    elseif gameState == "tutorial" then
        -- Tutorial logic
        return
    elseif gameState == "paused" then
        -- Pause menu logic
        return
    elseif gameState == "playing" then
        if isPaused then
            return
        end

        -- Update messages
        for i = #messages, 1, -1 do
            messages[i].timer = messages[i].timer - dt
            if messages[i].timer <= 0 then
                table.remove(messages, i)
            end
        end

        -- Update high score
        updateHighScore()

        -- Time progression
        dayTimer = dayTimer + dt
        if dayTimer >= dayDuration then
            currentDay = currentDay + 1
            dayTimer = 0
            isNight = not isNight
            -- New customers every day
            if not isNight then
                spawnCustomersAtMarket()
            end
        end

        -- Weather progression
        weatherTimer = weatherTimer + dt
        if weatherTimer >= weatherDuration then
            -- Change weather
            local weatherOptions = {'sunny', 'rainy', 'stormy'}
            weather = weatherOptions[math.random(#weatherOptions)]
            weatherTimer = 0
            table.insert(messages, {text = "The weather has changed to " .. weather .. "!", timer = 3})
        end

        -- Combo timer
        if comboMultiplier > 1 then
            comboTimer = comboTimer - dt
            if comboTimer <= 0 then
                comboMultiplier = 1
            end
        end

        -- Player movement
        handlePlayerMovement(dt)

        -- Egg collection logic
        if currentScreen == "farm" then
            updateFarm(dt)
        elseif currentScreen == "market" then
            updateMarket(dt)
        end

        -- Shop interaction
        if isInPickupRange(player, shop) then
            shop.color = {0, 1, 0}
        else
            shop.color = {0.5, 0.5, 0.5}
        end

        -- Screen toggle button interaction
        if checkCollision(player, {x = 0, y = buttonY, width = windowWidth, height = buttonHeight}) then
            buttonHover = true
        else
            buttonHover = false
        end

        -- Update quests
        updateQuests()

        -- Check achievements
        checkAchievements()

        -- Mouse interaction with shop
        if currentScreen == "farm" and isInPickupRange(player, shop) then
            local mouseX, mouseY = love.mouse.getPosition()
            mouseOverUpgrade = nil
            if shop.upgradeRects then
                for i, rect in ipairs(shop.upgradeRects) do
                    if mouseX >= rect.x and mouseX <= rect.x + rect.width and
                       mouseY >= rect.y and mouseY <= rect.y + rect.height then
                        mouseOverUpgrade = i
                        break
                    end
                end
            end
        else
            mouseOverUpgrade = nil
        end

        -- Update Guard Dog
        updateDog(dt)

        -- Update random events
        randomEvents.update(dt)

        -- Update upgrade system if needed
        upgradeSystem.update()
    end
end

function updateHighScore()
    if money > highScore then
        highScore = money
    end
end

function handlePlayerMovement(dt)
    if (love.keyboard.isDown("right") or love.keyboard.isDown("d")) and player.x + player.size < windowWidth then
        player.x = player.x + player.speed * dt
    end
    if (love.keyboard.isDown("left") or love.keyboard.isDown("a")) and player.x > 0 then
        player.x = player.x - player.speed * dt
    end
    if (love.keyboard.isDown("up") or love.keyboard.isDown("w")) and player.y > 0 then
        player.y = player.y - player.speed * dt
    end
    if (love.keyboard.isDown("down") or love.keyboard.isDown("s")) and player.y + player.size < windowHeight then
        player.y = player.y + player.speed * dt
    end
end

function updateFarm(dt)
    for _, chicken in ipairs(chickens) do
        chicken:update(dt)
    end

    -- Egg bouncing animation and remove collected eggs
    for i = #eggs, 1, -1 do
        local egg = eggs[i]
        if egg.collected then
            table.remove(eggs, i)
        else
            egg.y = egg.y + egg.ySpeed * dt
            if egg.y >= egg.maxY or egg.y <= egg.minY then
                egg.ySpeed = -egg.ySpeed
            end
        end
    end

    -- Predator logic
    updatePredators(dt)

    -- Egg Magnet effect
    if player.hasEggMagnet then
        for _, egg in ipairs(eggs) do
            if not egg.collected then
                local dx = player.x - egg.x
                local dy = player.y - egg.y
                local distance = math.sqrt(dx * dx + dy * dy)
                if distance < 100 then -- Magnet radius
                    local pullStrength = (100 - distance) / 100
                    egg.x = egg.x + dx * pullStrength * dt
                    egg.y = egg.y + dy * pullStrength * dt
                end
            end
        end
    end

    -- Farmhand collects eggs
    if player.hasFarmhand then
        for _, egg in ipairs(eggs) do
            if not egg.collected then
                if player.carryingEggs < player.maxCapacity then
                    egg.collected = true
                    if egg.isGolden then
                        player.carryingEggs = player.carryingEggs + 1
                        money = money + goldenEggPrice
                        table.insert(messages, {text = "Farmhand collected a golden egg! +" .. goldenEggPrice .. " KSH", timer = 3})
                    else
                        player.carryingEggs = player.carryingEggs + 1
                    end
                    egg.chicken.hasEgg = false
                    achievements.eggCollector.progress = achievements.eggCollector.progress + 1
                    player.experience = player.experience + 5
                    checkLevelUp()
                end
            end
        end
    end
end




            

function updatePredators(dt)
    for name, predator in pairs(predators) do
        if #chickens > 0 then
            local adjustedInterval = predator.spawnInterval - (currentDay * 1)
            adjustedInterval = math.max(adjustedInterval, 20)

            -- Adjust spawn intervals based on time and weather
            if isNight and name == "fox" then
                adjustedInterval = adjustedInterval - 10 -- Fox more active at night
            end

            if weather == 'stormy' and name == "hawk" then
                adjustedInterval = adjustedInterval + 10 -- Hawks less active during storm
            end

            if not predator.isActive then
                predator.spawnTimer = predator.spawnTimer + dt
                if predator.spawnTimer >= adjustedInterval then
                    predator.isActive = true
                    if name == "hawk" then
                        predator.x = math.random(0, windowWidth)
                        predator.y = -50
                    elseif name == "fox" then
                        predator.x = -50
                        predator.y = math.random(100, windowHeight - 100)
                    elseif name == "snake" then
                        predator.x = windowWidth + 50
                        predator.y = math.random(100, windowHeight - 100)
                    end
                    predator.targetChicken = chickens[math.random(1, #chickens)]
                    predator.spawnTimer = 0

                    -- Activate Guard Dog for fox and snake
                    if player.hasGuardDog and (name == "fox" or name == "snake") then
                        dog.isActive = true
                        dog.targetPredator = predator
                    end
                end
            else
                if predator.targetChicken == nil or #chickens == 0 then
                    predator.isActive = false
                else
                    -- Move towards target chicken
                    local dx = predator.targetChicken.x - predator.x
                    local dy = predator.targetChicken.y - predator.y
                    local distance = math.sqrt(dx * dx + dy * dy)
                    if distance > 0 then
                        predator.x = predator.x + (dx / distance) * predator.speed * dt
                        predator.y = predator.y + (dy / distance) * predator.speed * dt
                    end

                    -- Check if predator reaches the chicken
                    if checkCollision(predator, predator.targetChicken) then
                        -- Remove the chicken
                        for i, chicken in ipairs(chickens) do
                            if chicken == predator.targetChicken then
                                table.remove(chickens, i)
                                table.insert(messages, {text = "A chicken was taken by a predator!", timer = 3})
                                break
                            end
                        end
                        predator.isActive = false
                    end

                    -- Hawk cannot be caught by the dog
                    if player.hasGuardDog and (name == "hawk") then
                        -- Existing guard dog effect remains
                        if math.random() < 0.5 then
                            predator.isActive = false
                            table.insert(messages, {text = "Your guard dog scared away a hawk!", timer = 2})
                        end
                    end
                end
            end
        else
            predator.isActive = false
        end
    end
end

function updateDog(dt)
    if player.hasGuardDog then
        if dog.isActive then
            if dog.targetPredator and dog.targetPredator.isActive then
                -- Move towards the predator
                local dx = dog.targetPredator.x - dog.x
                local dy = dog.targetPredator.y - dog.y
                local distance = math.sqrt(dx * dx + dy * dy)
                if distance > 0 then
                    dog.x = dog.x + (dx / distance) * dog.speed * dt
                    dog.y = dog.y + (dy / distance) * dog.speed * dt
                end

                -- Check if dog reaches the predator
                if checkCollision(dog, dog.targetPredator) then
                    -- Remove the predator
                    dog.targetPredator.isActive = false
                    table.insert(messages, {text = "Your guard dog caught a predator!", timer = 2})
                    dog.targetPredator = nil
                    dog.isActive = false
                end
            else
                -- Predator is no longer active
                dog.targetPredator = nil
                dog.isActive = false
            end
        else
            -- Dog returns to barn
            local dx = (barn.x + barn.width + 10) - dog.x
            local dy = barn.y - dog.y
            local distance = math.sqrt(dx * dx + dy * dy)
            if distance > 0 then
                dog.x = dog.x + (dx / distance) * dog.speed * dt
                dog.y = dog.y + (dy / distance) * dog.speed * dt
            end
        end
    end
end

function updateQuests()
    if #player.quests > 0 then
        local currentQuest = player.quests[1]
        if currentQuest.condition() and not currentQuest.completed then
            currentQuest.completed = true
            money = money + currentQuest.reward
            achievements.questMaster.completed = achievements.questMaster.completed + 1
            table.insert(messages, {text = "Quest Completed! Reward: " .. currentQuest.reward .. " KSH", timer = 3})
            -- Remove completed quest and add a new one
            table.remove(player.quests, 1)
            table.insert(player.quests, generateRandomQuest())
        end
    end
end

function checkAchievements()
    if not achievements.eggCollector.unlocked and achievements.eggCollector.progress >= achievements.eggCollector.threshold then
        achievements.eggCollector.unlocked = true
        table.insert(messages, {text = "Achievement Unlocked: Egg Collector!", timer = 3})
    end
    if not achievements.chickenGuardian.unlocked and achievements.chickenGuardian.count >= achievements.chickenGuardian.threshold then
        achievements.chickenGuardian.unlocked = true
        table.insert(messages, {text = "Achievement Unlocked: Chicken Guardian!", timer = 3})
    end
    if not achievements.masterFarmer.unlocked and achievements.masterFarmer.progress >= achievements.masterFarmer.threshold then
        achievements.masterFarmer.unlocked = true
        table.insert(messages, {text = "Achievement Unlocked: Master Farmer!", timer = 3})
    end
    if not achievements.questMaster.unlocked and achievements.questMaster.completed >= achievements.questMaster.threshold then
        achievements.questMaster.unlocked = true
        table.insert(messages, {text = "Achievement Unlocked: Quest Master!", timer = 3})
    end
end

-- Draw Function
function love.draw()
    if gameState == "mainMenu" then
        drawMainMenu()
    elseif gameState == "tutorial" then
        drawTutorial()
    elseif gameState == "paused" then
        drawPauseMenu()
    elseif gameState == "playing" then
        -- Background
        if isNight then
            love.graphics.setColor(0.1, 0.1, 0.2)
        else
            love.graphics.setColor(0.9, 0.9, 0.9)
        end
        love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)

        -- Weather overlay
        if weather == 'rainy' then
            love.graphics.setColor(0, 0, 1, 0.2)
            love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)
        elseif weather == 'stormy' then
            love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
            love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)
        end

        -- Display global info
        displayGlobalInfo()

        -- Display messages
        love.graphics.setFont(messageFont)
        for i, message in ipairs(messages) do
            love.graphics.setColor(0, 0, 0)
            love.graphics.printf(message.text, 0, 240 + i * 20, windowWidth, "center")
        end

        -- Player
        drawPlayer()

        if currentScreen == "farm" then
            drawFarm()
        elseif currentScreen == "market" then
            drawMarket()
        end

        -- Screen toggle button
        if buttonHover then
            love.graphics.setColor(0.5, 0.5, 1)
        else
            love.graphics.setColor(0.7, 0.7, 0.7)
        end
        love.graphics.rectangle("fill", 0, buttonY, buttonWidth, buttonHeight)
        love.graphics.setColor(0, 0, 0)
        love.graphics.setFont(hudFont)
        if currentScreen == "farm" then
            love.graphics.printf("Go to Market", 0, buttonY + 15, windowWidth, "center")
        else
            love.graphics.printf("Go to Farm", 0, buttonY + 15, windowWidth, "center")
        end

        -- Draw inventory
        inventorySystem.draw()

        -- Pause menu
        if isPaused then
            drawPauseMenu()
        end
    end

    -- 确保收银机界面绘制
    if cash.isCashRegisterOpen() then
        cash.drawCashRegister()
    end
end


function drawPlayer()
    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.ellipse("fill", player.x + player.size / 2, player.y + player.size, player.size / 2, 10)
    -- Player
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", player.x, player.y, player.size, player.size)
end

function drawMainMenu()
    love.graphics.setColor(0.8, 0.9, 1)
    love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)
    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(titleFont)
    love.graphics.printf("Poultry Profits: Egg-cellent Business", 0, 100, windowWidth, "center")
    love.graphics.setFont(hudFont)
    love.graphics.printf("Press 'Enter' to Start Game", 0, 200, windowWidth, "center")
    love.graphics.printf("Press 'Esc' to Exit", 0, 250, windowWidth, "center")
end

function drawTutorial()
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)
    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(messageFont)
    love.graphics.printf(tutorialMessages[tutorialStep], 50, windowHeight / 2 - 50, windowWidth - 100, "center")
    love.graphics.printf("Press 'Enter' to continue", 0, windowHeight - 100, windowWidth, "center")
end

function drawPauseMenu()
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(titleFont)
    love.graphics.printf("Game Paused", 0, windowHeight / 2 - 100, windowWidth, "center")
    love.graphics.setFont(hudFont)
    love.graphics.printf("Press 'P' to Resume", 0, windowHeight / 2 - 50, windowWidth, "center")
    love.graphics.printf("Press 'Esc' to Main Menu", 0, windowHeight / 2, windowWidth, "center")
end

function drawFarm()
    -- Barn
    love.graphics.setColor(0.5, 0.25, 0)
    love.graphics.rectangle("fill", barn.x, barn.y, barn.width, barn.height)
    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(hudFont)
    love.graphics.print("Barn (Level " .. barn.level .. ")", barn.x - 10, barn.y - 20)

    -- Chickens
    for _, chicken in ipairs(chickens) do
        if chicken.isSleeping then
            love.graphics.setColor(0.7, 0.7, 0.7)
        elseif chicken.hunger < 30 then
            love.graphics.setColor(1, 0, 0)
        elseif chicken.isFed then
            love.graphics.setColor(1, 1, 0)
        else
            love.graphics.setColor(0.5, 0.5, 0)
        end
        love.graphics.rectangle("fill", chicken.x, chicken.y, chicken.size, chicken.size)
        -- Chicken hunger bar
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("fill", chicken.x, chicken.y - 10, (chicken.hunger / 100) * chicken.size, 5)
        -- Clamp hunger bar within bounds
        chicken.hunger = math.max(0, math.min(100, chicken.hunger))
        -- Chicken animation
        chicken.y = chicken.y + math.sin(love.timer.getTime() * 2) * 0.5
    end

    -- Eggs
    for _, egg in ipairs(eggs) do
        if not egg.collected then
            if egg.isGolden then
                love.graphics.setColor(1, 0.84, 0)
            elseif isInPickupRange(player, egg) then
                love.graphics.setColor(0, 1, 0)
            else
                love.graphics.setColor(1, 1, 1)
            end
            love.graphics.circle("fill", egg.x, egg.y, 10)
        end
    end

    -- Shop
    love.graphics.setColor(shop.color)
    love.graphics.rectangle("fill", shop.x, shop.y, shop.width, shop.height)
    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(hudFont)
    love.graphics.print("Shop", shop.x + 20, shop.y + 15)

    -- Predators
    for name, predator in pairs(predators) do
        if predator.isActive then
            local color = {0, 0, 0}
            if name == "fox" then
                color = {1, 0.5, 0}
            elseif name == "snake" then
                color = {0, 1, 0}
            elseif name == "hawk" then
                color = {0.5, 0.5, 0.5}
            end
            drawPredator(predator, name:gsub("^%l", string.upper), color)
        end
    end

    -- Guard Dog
    if player.hasGuardDog then
        love.graphics.setColor(0.5, 0.35, 0)
        love.graphics.rectangle("fill", dog.x, dog.y, dog.size, dog.size)
        love.graphics.setColor(0, 0, 0)
        love.graphics.setFont(hudFont)
        love.graphics.print("Dog", dog.x + 5, dog.y + 15)
    end

    -- Shop UI
    drawShopUI()
end

function drawPredator(predator, name, color)
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", predator.x, predator.y, predator.size, predator.size)
    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(hudFont)
    love.graphics.print(name, predator.x + 5, predator.y + 15)
end

function drawShopUI()
    if isInPickupRange(player, shop) then
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.rectangle("fill", shop.x - 50, shop.y - 300, 300, 280)
        love.graphics.setColor(0, 0, 0)
        love.graphics.setFont(hudFont)
        love.graphics.print("Upgrades:", shop.x - 30, shop.y - 290)

        shop.upgradeRects = {} -- Initialize upgrade rects table

        for i, upgrade in ipairs(shop.upgrades) do
            local upgradeX = shop.x - 30
            local upgradeY = shop.y - 290 + i * 20
            local upgradeWidth = 280
            local upgradeHeight = 20

            -- Store the rectangle for this upgrade
            shop.upgradeRects[i] = {x = upgradeX, y = upgradeY, width = upgradeWidth, height = upgradeHeight}

            -- Draw the upgrade
            if mouseOverUpgrade == i then
                love.graphics.setColor(0, 0.5, 1)
            elseif i == shop.selectedUpgrade then
                love.graphics.setColor(1, 0, 0)
            elseif money >= upgrade.cost then
                love.graphics.setColor(0, 0, 0)
            else
                love.graphics.setColor(0.5, 0.5, 0.5)
            end
            love.graphics.print(upgrade.name .. ": " .. upgrade.cost .. " KSH", upgradeX, upgradeY)
        end
        love.graphics.setColor(0, 0, 0)
        love.graphics.print("Click on an upgrade to purchase", shop.x - 30, shop.y - 290 + (#shop.upgrades + 1) * 20)
    end
end

function drawMarket()
    -- Marketplace
    love.graphics.setColor(marketplace.color)
    love.graphics.rectangle("fill", marketplace.x, marketplace.y, marketplace.width, marketplace.height)
    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(hudFont)
    love.graphics.print("Market", marketplace.x + 10, marketplace.y + 40)

    -- Customers
    for i, customer in ipairs(customers) do
        love.graphics.setColor(customer.color)
        love.graphics.rectangle("fill", customer.x, customer.y, customer.width, customer.height)
        love.graphics.setColor(0, 0, 0)
        love.graphics.setFont(hudFont)
        love.graphics.print(customer.needs .. " eggs", customer.x - 10, customer.y - 20)
        love.graphics.print("Time: " .. math.floor(customerTimers[i]), customer.x - 10, customer.y - 35)
    end
end

-- Input Handling
function love.keypressed(key)
    key = string.lower(key)

    if cash.isCashRegisterOpen() then
        cash.handleCashRegisterKeypress(key)
        return -- Skip other key handling while cash register is open
    end
    

    if key == "escape" then
        if gameState == "mainMenu" then
            love.event.quit()
        elseif gameState == "playing" then
            gameState = "mainMenu"
        elseif gameState == "paused" then
            gameState = "mainMenu"
        end
    end

    if gameState == "mainMenu" then
        if key == "return" then
            gameState = "tutorial"
        end
    elseif gameState == "tutorial" then
        if key == "return" then
            tutorialStep = tutorialStep + 1
            if tutorialStep > #tutorialMessages then
                gameState = "playing"
            end
        end
    elseif gameState == "paused" then
        if key == "p" then
            isPaused = false
            gameState = "playing"
        end
    elseif gameState == "playing" then
        if key == "p" then
            isPaused = true
            gameState = "paused"
        end

        if isPaused then
            return
        end

        -- All actions are mapped to the spacebar
        if key == "space" then
            handleSpacebarAction()
        end

        -- Shop menu navigation (optional)
        if currentScreen == "farm" and isInPickupRange(player, shop) then
            if key == "up" then
                shop.selectedUpgrade = shop.selectedUpgrade - 1
                if shop.selectedUpgrade < 1 then
                    shop.selectedUpgrade = #shop.upgrades
                end
                return
            elseif key == "down" then
                shop.selectedUpgrade = shop.selectedUpgrade + 1
                if shop.selectedUpgrade > #shop.upgrades then
                    shop.selectedUpgrade = 1
                end
                return
            end
        end
    end
end

function love.mousepressed(x, y, button)

    if cash.isCashRegisterOpen() then
        cash.handleCashRegisterMouse(x, y)
        return -- Skip other mouse input handling while cash register is open
    end


    if gameState == "playing" then
        if currentScreen == "farm" and isInPickupRange(player, shop) then
            if mouseOverUpgrade and button == 1 then
                local selectedUpgrade = shop.upgrades[mouseOverUpgrade]
                if money >= selectedUpgrade.cost then
                    money = money - selectedUpgrade.cost
                    selectedUpgrade.action()
                    player.experience = player.experience + 20
                    checkLevelUp()
                else
                    table.insert(messages, {text = "Not enough money for that upgrade.", timer = 2})
                end
            end
        end
    end
end

-- Handle player actions with spacebar
function handleSpacebarAction()
    if cash.isCashRegisterOpen() then
        return -- Skip other interactions if the cash register is open
    end

    if currentScreen == "market" then
        -- First, check if near a customer and if conditions are met
        for i, customer in ipairs(customers) do
            if isInPickupRange(player, customer) and totalEggsInMarket >= customer.needs then
                openCashRegister(customer) -- Open the cash register
                return
            end
        end

        -- If no customer interaction, check for market storage
        if isInPickupRange(player, marketplace) then
            if player.carryingEggs > 0 then -- Only store if the player has eggs
                local transferableEggs = math.min(player.carryingEggs, marketCapacity - totalEggsInMarket)
                if transferableEggs > 0 then
                    totalEggsInMarket = totalEggsInMarket + transferableEggs
                    player.carryingEggs = player.carryingEggs - transferableEggs
                    table.insert(messages, {text = "Successfully stored " .. transferableEggs .. " eggs in the market.", timer = 2})
                else
                    table.insert(messages, {text = "Market storage is full!", timer = 2})
                end
            else
                table.insert(messages, {text = "You have no eggs to store!", timer = 2})
            end
            return
        end
    end

    -- Collect eggs
    for _, egg in ipairs(eggs) do
        if not egg.collected and isInPickupRange(player, egg) then
            if player.carryingEggs < player.maxCapacity then
                egg.collected = true
                if egg.isGolden then
                    player.carryingEggs = player.carryingEggs + 1
                    money = money + goldenEggPrice
                    table.insert(messages, {text = "Collected a golden egg! +" .. goldenEggPrice .. " KSH", timer = 3})
                else
                    player.carryingEggs = player.carryingEggs + 1
                end
                egg.chicken.hasEgg = false
                achievements.eggCollector.progress = achievements.eggCollector.progress + 1
                player.experience = player.experience + 5
                checkLevelUp()
            else
                table.insert(messages, {text = "Your egg basket is full!", timer = 2})
            end
            return
        end
    end

    -- Feed chickens with Special Feed
    for _, chicken in ipairs(chickens) do
        if isInPickupRange(player, chicken) and inventorySystem.hasItem("Special Feed") then
            chicken.goldenEggChance = chicken.goldenEggChance + 5 -- Increase chance of golden egg
            inventorySystem.removeItem("Special Feed")
            table.insert(messages, {text = "Fed chicken with Special Feed!", timer = 2})
            return
        end
    end

    -- Feed chickens with regular feed
    for _, chicken in ipairs(chickens) do
        if isInPickupRange(player, chicken) and player.carryingFeed > 0 then
            chicken.hunger = 100
            chicken.isFed = true
            player.carryingFeed = player.carryingFeed - 1
            player.experience = player.experience + 2
            checkLevelUp()
            return
        end
    end

    -- Chase away predators
    for name, predator in pairs(predators) do
        if predator.isActive and isInPickupRange(player, predator) then
            predator.isActive = false
            achievements.chickenGuardian.count = achievements.chickenGuardian.count + 1
            table.insert(messages, {text = "You chased away a predator!", timer = 2})
            player.experience = player.experience + 10
            checkLevelUp()
            return
        end
    end

    -- Toggle screen if near button
    if buttonHover then
        currentScreen = currentScreen == "farm" and "market" or "farm"
        player.x, player.y = 100, 500
    end
end

function checkLevelUp()
    if player.experience >= player.experienceToLevelUp then
        player.level = player.level + 1
        player.experience = player.experience - player.experienceToLevelUp
        player.experienceToLevelUp = player.experienceToLevelUp + 50
        table.insert(messages, {text = "Congratulations! You've reached level " .. player.level .. "!", timer = 3})
        -- Unlock new abilities or upgrades here
    end
end
