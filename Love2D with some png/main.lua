-- main.lua

-- Main Game File

local cash = require("cash")
local gameFeatures = require("gameFeatures")
local marketplaceImage


-- Global variables and objects
shop = {
    x = 200,
    y = 500,
    width = 100,
    height = 50,
    size = 50,
    color = {0.5, 0.5, 0.5},
    upgrades = {},
    selectedUpgrade = 1,
    upgradeRects = {}
}

player = {
    x = 100,
    y = 500,
    size = 50,
    speed = 180,
    carryingEggs = 0,
    carryingFeed = 5,
    maxCapacity = 10,
    maxFeedCapacity = 20,
    level = 1,
    abilities = {},
    quests = {},
    hasEggMagnet = false,
    hasFarmhand = false,
    hasGuardDog = false,
    inventory = {}
}

-- Base Resolution for scaling
baseWidth = 1000
baseHeight = 600
scaleX = 1
scaleY = 1

-- Initialize Chickens
Chicken = {}
Chicken.__index = Chicken

function Chicken:new(x, y)
    local chicken = {
        x = x,
        y = y,
        size = 50,
        hasEgg = false,
        nextEggTimer = 0,
        eggLayingInterval = 6,
        hunger = 100,
        isFed = true,
        isSleeping = false,
        goldenEggChance = 5,
        baseY = y,
        direction = math.random() * 2 * math.pi,
        changeDirectionTimer = math.random(2, 5),
        speed = 30
    }
    setmetatable(chicken, Chicken)
    return chicken
end

function Chicken:update(dt, weather, isNight)
    if isNight then
        self.isSleeping = true
    else
        self.isSleeping = false
    end

    if not self.isSleeping then
        local hungerRate = 0.5
        if weather == 'winter' then
            hungerRate = hungerRate + 0.3
        end
        self.hunger = math.max(0, self.hunger - dt * hungerRate)
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
                elseif weather == 'winter' then
                    adjustedEggLayingInterval = adjustedEggLayingInterval + 1
                end

                if self.nextEggTimer >= adjustedEggLayingInterval then
                    spawnEgg(self)
                    self.nextEggTimer = 0
                end
            end
        end

        -- Chicken random movement
        self.changeDirectionTimer = self.changeDirectionTimer - dt
        if self.changeDirectionTimer <= 0 then
            self.direction = math.random() * 2 * math.pi
            self.changeDirectionTimer = math.random(2, 5)
        end

        local oldX, oldY = self.x, self.y
        self.x = self.x + math.cos(self.direction) * self.speed * dt
        self.y = self.y + math.sin(self.direction) * self.speed * dt

        -- Keep chicken within right half and above buttonY
        local minX = baseWidth / 2
        local maxX = baseWidth - self.size
        local minY = 0
        local maxY = buttonY - self.size - 10  -- Avoid market button area

        if self.x < minX or self.x > maxX then
            self.x = oldX
            self.direction = math.pi - self.direction
        end

        if self.y < minY or self.y > maxY then
            self.y = oldY
            self.direction = -self.direction
        end
    end
end

-- Initialize chickens
chickens = {}

function initializeChickens(chickenPositions)
    chickens = {}
    for _, pos in ipairs(chickenPositions) do
        local chicken = Chicken:new(pos.x, pos.y)
        chicken.baseY = pos.y
        table.insert(chickens, chicken)
    end
end

-- Eggs
eggs = {}

-- Money and Market
money = 0
highScore = 0
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

-- Weather System
weather = 'sunny'
weatherTimer = 0
weatherDuration = 60

-- Window Dimensions
windowWidth = baseWidth
windowHeight = baseHeight

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
    "Use WASD or arrow keys to move your character.",
    "Approach a chicken and press the spacebar to collect eggs.",
    "If you have feed, approach a chicken and press 'F' to feed it.",
    "Visit the shop to buy upgrades and feed.",
    "Sell your eggs at the market to earn money.",
    "Protect your chickens from predators!",
    "Press 'P' at any time to pause the game.",
    "Press 'Enter' to start your farming adventure!"
}

-- Mouse Interaction
mouseOverUpgrade = nil

-- Fonts (Use default fonts)
titleFont = love.graphics.newFont(48)     -- Using default font with size 48
hudFont = love.graphics.newFont(18)
messageFont = love.graphics.newFont(24)

-- Game States
gameState = "mainMenu"

-- Level Management
currentLevel = 1
totalLevels = 3
allowedWeather = {}

-- Level Objective
levelObjective = nil
levelCompleted = false

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
    local range = ((a.width or a.size) + (b.width or b.size)) / 2 + 10
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
    maxCustomers = math.min(10, 3 + math.floor(currentDay / 2))
    local startX = marketplace.x - customerWidth - 50
    local startY = marketplace.y + marketplace.height / 2 - customerHeight / 2
    for i = 1, maxCustomers do
        local need = math.random(2, 10)
        local customer = {
            x = startX - (i - 1) * (customerWidth + 30),
            y = startY,
            width = customerWidth,
            height = customerHeight,
            needs = need,
            color = {0, 0, 1},
            highlight = false
        }
        table.insert(customers, customer)
        table.insert(customerNeeds, need)
        table.insert(customerTimers, customerTimeLimit)
    end
end

function displayGlobalInfo()
    love.graphics.setFont(hudFont)
    love.graphics.setColor(0, 0, 0)
    local infoY = 80
    love.graphics.print("Level: " .. currentLevel, baseWidth / 2 - 50, 20)  -- Level Display at top center
    love.graphics.print("Day: " .. currentDay, 20, infoY)
    love.graphics.print("Eggs: " .. player.carryingEggs .. "/" .. player.maxCapacity, 20, infoY + 20)
    love.graphics.print("Feed: " .. player.carryingFeed .. "/" .. player.maxFeedCapacity, 20, infoY + 40)
    love.graphics.print("Money: " .. money .. " KSH", 20, infoY + 60)
    love.graphics.print("Eggs in Market: " .. totalEggsInMarket .. "/" .. marketCapacity, 20, infoY + 80)
    love.graphics.print("High Score: " .. highScore .. " KSH", 20, infoY + 100)
    if isNight then
        love.graphics.print("Time: Night", 20, infoY + 120)
    else
        love.graphics.print("Time: Day", 20, infoY + 120)
    end
    love.graphics.print("Weather: " .. weather, 20, infoY + 140)
end

function getLevelObjective()
    if currentLevel == 1 then
        return 400
    elseif currentLevel == 2 then
        return 1400
    elseif currentLevel == 3 then
        return 2200
    else
        return "N/A"
    end
end

function love.load()
    -- Load the chicken image
    chickenImage = love.graphics.newImage("assets/chicken.png")
     -- Load the player image
     playerImage = love.graphics.newImage("assets/player.png")
    -- Load the marketplace image
     marketplaceImage = love.graphics.newImage("assets/marketplace.png")
    love.window.setMode(windowWidth, windowHeight, {resizable=true, fullscreen=true})
    love.window.setTitle("Poultry Profits: Egg-cellent Business")
    math.randomseed(os.time())
    dog.x = barn.x + barn.width + 10
    dog.y = barn.y
    loadLevel(currentLevel)
end

function initializeQuests()
    player.quests = {}
end

function loadLevel(levelNumber)
    if levelNumber > totalLevels then
        currentLevel = 1
        -- Reset game variables for new game
        money = 0
        highScore = 0
        currentDay = 1
        player.carryingEggs = 0
        player.carryingFeed = 5
    else
        currentLevel = levelNumber
    end

    local status, levelData = pcall(require, "level" .. currentLevel)
    if not status then
        print("Error loading level" .. currentLevel .. ".lua")
        return
    end

    initializeGame(levelData)
end

function initializeGame(levelData)
    allowedWeather = {'sunny', 'rainy', 'stormy', 'winter'}
    weather = levelData.weather or 'sunny'

    -- Initialize chickens
    initializeChickens(levelData.chickens)

    -- Set level objective
    levelObjective = levelData.objective or function() return false end
    levelCompleted = false

    -- Initialize shop upgrades
    gameFeatures.upgradeSystem.init()

    -- Initialize quests
    initializeQuests()

    -- Reset timers
    dayTimer = 0
    weatherTimer = 0

    -- Initialize predators based on level
    predatorsActive = levelData.predatorsActive or false
    for _, predator in pairs(predators) do
        predator.isActive = false
        predator.spawnTimer = 0
    end

    -- Initialize random events
    gameFeatures.randomEvents.init()

    -- Initialize customers
    spawnCustomersAtMarket()

    -- Set initial money
    money = levelData.initialMoney or money
end

function love.resize(w, h)
    windowWidth = w
    windowHeight = h
    scaleX = windowWidth / baseWidth
    scaleY = windowHeight / baseHeight
    buttonY = baseHeight - (50)
    buttonWidth = baseWidth
end

function love.update(dt)
    if gameState == "mainMenu" then
        return
    elseif gameState == "tutorial" then
        return
    elseif gameState == "paused" then
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

        updateHighScore()

        dayTimer = dayTimer + dt
        if dayTimer >= dayDuration then
            currentDay = currentDay + 1
            dayTimer = 0
            isNight = not isNight
            if not isNight then
                spawnCustomersAtMarket()
            end
        end

        weatherTimer = weatherTimer + dt
        if weatherTimer >= weatherDuration then
            local previousWeather = weather
            weather = allowedWeather[math.random(#allowedWeather)]
            if weather ~= previousWeather then
                table.insert(messages, {text = "The weather has changed to " .. weather .. "!", timer = 3})
            end
            weatherTimer = 0
        end

        handlePlayerMovement(dt)

        if currentScreen == "farm" then
            gameFeatures.upgradeSystem.update()
            updateFarm(dt)
        elseif currentScreen == "market" then
            updateMarket(dt)
        end

        -- Market and customer highlighting
        if currentScreen == "market" then
            if isInPickupRange(player, marketplace) then
                marketplace.color = {0, 1, 0}
            else
                marketplace.color = {0, 0, 1}
            end

            for _, customer in ipairs(customers) do
                if isInPickupRange(player, customer) then
                    if totalEggsInMarket >= customer.needs then
                        customer.highlight = {0, 1, 0}  -- Green if enough eggs
                    else
                        customer.highlight = {1, 0, 0}  -- Red if not enough eggs
                    end
                else
                    customer.highlight = false
                end
            end
        end

        if isInPickupRange(player, shop) then
            shop.color = {0, 1, 0}
        else
            shop.color = {0.5, 0.5, 0.5}
        end

        if checkCollision(player, {x = 0, y = buttonY, width = baseWidth, height = buttonHeight}) then
            buttonHover = true
        else
            buttonHover = false
        end

        updateQuests()
        checkAchievements()
        if currentScreen == "farm" and isInPickupRange(player, shop) then
            local mouseX, mouseY = love.mouse.getPosition()
            -- Adjust mouse coordinates for scaling
            mouseX = mouseX / scaleX
            mouseY = mouseY / scaleY
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

        updateDog(dt)
        gameFeatures.randomEvents.update(dt)
        cash.updateCashRegister(dt)

        for i = #customerTimers, 1, -1 do
            customerTimers[i] = customerTimers[i] - dt
            if customerTimers[i] <= 0 then
                table.remove(customers, i)
                table.remove(customerNeeds, i)
                table.remove(customerTimers, i)
            end
        end

        if predatorsActive then
            updatePredators(dt)
        end

        checkLevelCompletion()
    end
end

function updateHighScore()
    if money > highScore then
        highScore = money
    end
end

function handlePlayerMovement(dt)
    local speedMultiplier = 1
    if weather == 'winter' then
        speedMultiplier = 0.8
    end

    local adjustedSpeed = player.speed * speedMultiplier * dt

    if (love.keyboard.isDown("right") or love.keyboard.isDown("d")) and player.x + player.size < baseWidth then
        player.x = player.x + adjustedSpeed
    end
    if (love.keyboard.isDown("left") or love.keyboard.isDown("a")) and player.x > 0 then
        player.x = player.x - adjustedSpeed
    end
    if (love.keyboard.isDown("up") or love.keyboard.isDown("w")) and player.y > 0 then
        player.y = player.y - adjustedSpeed
    end
    if (love.keyboard.isDown("down") or love.keyboard.isDown("s")) and player.y + player.size < baseHeight then
        player.y = player.y + adjustedSpeed
    end
end

function updateFarm(dt)
    for _, chicken in ipairs(chickens) do
        chicken:update(dt, weather, isNight)
    end

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

    if predatorsActive then
        updatePredators(dt)
    end

    if player.hasEggMagnet then
        for _, egg in ipairs(eggs) do
            if not egg.collected then
                local dx = player.x - egg.x
                local dy = player.y - egg.y
                local distance = math.sqrt(dx * dx + dy * dy)
                if distance < 100 then
                    local pullStrength = (100 - distance) / 100
                    egg.x = egg.x + dx * pullStrength * dt
                    egg.y = egg.y + dy * pullStrength * dt
                end
            end
        end
    end

    if player.hasFarmhand then
        for _, egg in ipairs(eggs) do
            if not egg.collected then
                local distance = math.sqrt((player.x - egg.x)^2 + (player.y - egg.y)^2)
                if distance < 50 and player.carryingEggs < player.maxCapacity then
                    egg.collected = true
                    if egg.isGolden then
                        player.carryingEggs = player.carryingEggs + 1
                        money = money + goldenEggPrice
                        table.insert(messages, {text = "Farmhand collected a golden egg! +" .. goldenEggPrice .. " KSH", timer = 3})
                    else
                        player.carryingEggs = player.carryingEggs + 1
                        table.insert(messages, {text = "Collected an egg!", timer = 2})
                    end
                    egg.chicken.hasEgg = false
                    achievements.eggCollector.progress = achievements.eggCollector.progress + 1
                end
            end
        end
    end
end

function updateMarket(dt)
    -- Placeholder function if you want to add market-specific updates
end

function updateDog(dt)
    if player.hasGuardDog then
        if dog.isActive then
            if dog.targetPredator and dog.targetPredator.isActive then
                local dx = dog.targetPredator.x - dog.x
                local dy = dog.targetPredator.y - dog.y
                local distance = math.sqrt(dx * dx + dy * dy)
                if distance > 0 then
                    dog.x = dog.x + (dx / distance) * dog.speed * dt
                    dog.y = dog.y + (dy / distance) * dog.speed * dt
                end

                if checkCollision(dog, dog.targetPredator) then
                    dog.targetPredator.isActive = false
                    table.insert(messages, {text = "Your guard dog caught a predator!", timer = 2})
                    dog.targetPredator = nil
                    dog.isActive = false
                end
            else
                dog.targetPredator = nil
                dog.isActive = false
            end
        else
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

function updatePredators(dt)
    for name, predator in pairs(predators) do
        if #chickens > 0 then
            local adjustedInterval = predator.spawnInterval - (currentDay * 1)
            adjustedInterval = math.max(adjustedInterval, 20)

            if isNight and name == "fox" then
                adjustedInterval = adjustedInterval - 10
            end

            if weather == 'stormy' and name == "hawk" then
                adjustedInterval = adjustedInterval + 10
            end

            if not predator.isActive then
                predator.spawnTimer = predator.spawnTimer + dt
                if predator.spawnTimer >= adjustedInterval then
                    predator.isActive = true
                    if name == "hawk" then
                        predator.x = math.random(0, baseWidth)
                        predator.y = -50
                    elseif name == "fox" then
                        predator.x = -50
                        predator.y = math.random(100, buttonY - 100)
                    elseif name == "snake" then
                        predator.x = baseWidth + 50
                        predator.y = math.random(100, buttonY - 100)
                    end
                    predator.targetChicken = chickens[math.random(1, #chickens)]
                    predator.spawnTimer = 0

                    if player.hasGuardDog and (name == "fox" or name == "snake") then
                        dog.isActive = true
                        dog.targetPredator = predator
                    end
                end
            else
                if predator.targetChicken == nil or #chickens == 0 then
                    predator.isActive = false
                else
                    local dx = predator.targetChicken.x - predator.x
                    local dy = predator.targetChicken.y - predator.y
                    local distance = math.sqrt(dx * dx + dy * dy)
                    if distance > 0 then
                        predator.x = predator.x + (dx / distance) * predator.speed * dt
                        predator.y = predator.y + (dy / distance) * predator.speed * dt
                    end

                    if checkCollision(predator, predator.targetChicken) then
                        for i, chicken in ipairs(chickens) do
                            if chicken == predator.targetChicken then
                                table.remove(chickens, i)
                                table.insert(messages, {text = "A chicken was taken by a predator!", timer = 3})
                                break
                            end
                        end
                        predator.isActive = false
                    end

                    if player.hasGuardDog and (name == "hawk") then
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

function updateQuests()
    -- Placeholder as quests are not implemented
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
    if not achievements.masterFarmer.unlocked and money >= achievements.masterFarmer.threshold then
        achievements.masterFarmer.unlocked = true
        table.insert(messages, {text = "Achievement Unlocked: Master Farmer!", timer = 3})
    end
    if not achievements.questMaster.unlocked and achievements.questMaster.completed >= achievements.questMaster.threshold then
        achievements.questMaster.unlocked = true
        table.insert(messages, {text = "Achievement Unlocked: Quest Master!", timer = 3})
    end
end

function checkLevelCompletion()
    if not levelCompleted and levelObjective() then
        levelCompleted = true
        table.insert(messages, {text = "Level " .. currentLevel .. " Completed!", timer = 5})
        -- Delay level transition to allow message to be displayed
        love.timer.sleep(2)
        currentLevel = currentLevel + 1
        loadLevel(currentLevel)
    end
end

function love.draw()
    -- Apply scaling
    love.graphics.push()
    love.graphics.scale(scaleX, scaleY)

    if gameState == "mainMenu" then
        drawMainMenu()
    elseif gameState == "tutorial" then
        drawTutorial()
    elseif gameState == "paused" then
        drawPauseMenu()
    elseif gameState == "playing" then
        if isNight then
            love.graphics.setColor(0.678, 0.847, 0.902)
        else
            love.graphics.setColor(0.9, 0.9, 0.9)
        end
        love.graphics.rectangle("fill", 0, 0, baseWidth, baseHeight)

        -- Weather overlays with adjusted opacity
        if weather == 'rainy' then
            love.graphics.setColor(0, 0, 1, 0.1)
            love.graphics.rectangle("fill", 0, 0, baseWidth, baseHeight)
        elseif weather == 'stormy' then
            love.graphics.setColor(0.5, 0.5, 0.5, 0.3)
            love.graphics.rectangle("fill", 0, 0, baseWidth, baseHeight)
            -- Occasional lightning flashes
            if math.random() < 0.01 then
                love.graphics.setColor(1, 1, 1, 0.8)
                love.graphics.rectangle("fill", 0, 0, baseWidth, baseHeight)
            end
        elseif weather == 'winter' then
            love.graphics.setColor(0.9, 0.9, 1)
            love.graphics.rectangle("fill", 0, 0, baseWidth, baseHeight)
            -- Snow overlay
            love.graphics.setColor(1, 1, 1, 0.3)
            for i = 1, 100 do
                local snowX = math.random(0, baseWidth)
                local snowY = math.random(0, baseHeight)
                love.graphics.circle("fill", snowX, snowY, 2)
            end
        end

        displayGlobalInfo()

        love.graphics.setFont(messageFont)
        for i, message in ipairs(messages) do
            love.graphics.setColor(0, 0, 0)
            love.graphics.printf(message.text, 0, 220 + i * 20, baseWidth, "center")
        end

        drawPlayer()

        if currentScreen == "farm" then
            drawFarm()
        elseif currentScreen == "market" then
            drawMarket()
        end

        if buttonHover then
            love.graphics.setColor(0.5, 0.5, 1)
        else
            love.graphics.setColor(0.7, 0.7, 0.7)
        end
        love.graphics.rectangle("fill", 0, buttonY, buttonWidth, buttonHeight)
        love.graphics.setColor(0, 0, 0)
        love.graphics.setFont(hudFont)
        if currentScreen == "farm" then
            love.graphics.printf("Go to Market", 0, buttonY + 15, baseWidth, "center")
        else
            love.graphics.printf("Go to Farm", 0, buttonY + 15, baseWidth, "center")
        end

        if isPaused then
            drawPauseMenu()
        end
    end

    if cash.isCashRegisterOpen() then
        cash.drawCashRegister()
    end

    love.graphics.pop() -- Reset scaling
end

function drawPlayer()
    love.graphics.setColor(1, 1, 1) -- Reset color to white
    love.graphics.draw(playerImage, player.x, player.y)
end

function drawMainMenu()
    love.graphics.setColor(0.2, 0.6, 0.8)
    love.graphics.rectangle("fill", 0, 0, baseWidth, baseHeight)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(titleFont)
    love.graphics.printf("🐔 Poultry Profits 🥚", 0, 100, baseWidth, "center")
    love.graphics.setFont(hudFont)
    love.graphics.printf("Press 'T' to Read Tutorial", 0, 200, baseWidth, "center")
    love.graphics.printf("Press 'Y' to Start Game", 0, 240, baseWidth, "center")
    love.graphics.printf("Press 'Esc' to Exit", 0, 280, baseWidth, "center")
end

function drawTutorial()
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.rectangle("fill", 0, 0, baseWidth, baseHeight)
    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(messageFont)
    love.graphics.printf(tutorialMessages[tutorialStep], 50, baseHeight / 2 - 50, baseWidth - 100, "center")
    love.graphics.printf("Press 'Enter' to continue", 0, baseHeight - 100, baseWidth, "center")
end

function drawPauseMenu()
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, baseWidth, baseHeight)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(titleFont)
    love.graphics.printf("Game Paused", 0, baseHeight / 2 - 100, baseWidth, "center")
    love.graphics.setFont(hudFont)
    love.graphics.printf("Press 'P' to Resume", 0, baseHeight / 2 - 50, baseWidth, "center")
    love.graphics.printf("Press 'Esc' to Main Menu", 0, baseHeight / 2, baseWidth, "center")
end

function drawFarm()
    -- Draw the barn
    love.graphics.setColor(0.5, 0.25, 0)
    love.graphics.rectangle("fill", barn.x, barn.y, barn.width, barn.height)
    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(hudFont)
    love.graphics.print("Barn (Level " .. barn.level .. ")", barn.x - 10, barn.y - 20)

    -- Draw chickens
    for _, chicken in ipairs(chickens) do
        -- Set color based on chicken state (optional for tinting)
        if chicken.isSleeping then
            love.graphics.setColor(0.7, 0.7, 0.7, 1) -- Grey tint for sleeping
        elseif chicken.hunger < 30 then
            love.graphics.setColor(1, 0, 0, 1) -- Red tint if hungry
        elseif chicken.isFed then
            love.graphics.setColor(1, 1, 0, 1) -- Yellow tint if fed
        else
            love.graphics.setColor(0.5, 0.5, 0, 1) -- Default tint
        end

        -- Calculate scaling based on desired chicken size
        local scale = chicken.size / chickenImage:getWidth()

        -- Draw the chicken image at (x, y) with scaling
        love.graphics.draw(chickenImage, chicken.x, chicken.y, 0, scale, scale)

        -- Reset color to white to avoid affecting other drawings
        love.graphics.setColor(1, 1, 1, 1)

        -- Draw the hunger bar above the chicken
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("fill", chicken.x, chicken.y - 10, (chicken.hunger / 100) * chicken.size, 5)
        love.graphics.setColor(1, 1, 1, 1) -- Reset color
    end

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

    love.graphics.setColor(shop.color)
    love.graphics.rectangle("fill", shop.x, shop.y, shop.width, shop.height)
    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(hudFont)
    love.graphics.print("Shop", shop.x + 20, shop.y + 15)

    if predatorsActive then
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
    end

    if player.hasGuardDog then
        love.graphics.setColor(0.5, 0.35, 0)
        love.graphics.rectangle("fill", dog.x, dog.y, dog.size, dog.size)
        love.graphics.setColor(0, 0, 0)
        love.graphics.setFont(hudFont)
        love.graphics.print("Dog", dog.x + 5, dog.y + 15)
    end

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

        shop.upgradeRects = {}

        for i, upgrade in ipairs(shop.upgrades) do
            local upgradeX = shop.x - 30
            local upgradeY = shop.y - 290 + i * 20
            local upgradeWidth = 280
            local upgradeHeight = 20

            shop.upgradeRects[i] = {x = upgradeX, y = upgradeY, width = upgradeWidth, height = upgradeHeight}

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
    -- Calculate scaling factors to match the marketplace background size
    local backgroundWidth, backgroundHeight = marketplace.width, marketplace.height
    local imageWidth, imageHeight = marketplaceImage:getDimensions()
    local scaleX = backgroundWidth / imageWidth
    local scaleY = backgroundHeight / imageHeight

    -- Draw the marketplace image at the marketplace background coordinates with scaling
    love.graphics.draw(marketplaceImage, marketplace.x, marketplace.y, 0, scaleX, scaleY)

    

    -- Draw customers
    for i, customer in ipairs(customers) do
        if customer.highlight then
            if type(customer.highlight) == "table" then
                love.graphics.setColor(customer.highlight)
            else
                love.graphics.setColor(0, 1, 0)
            end
        else
            love.graphics.setColor(customer.color)
        end
        love.graphics.rectangle("fill", customer.x, customer.y, customer.width, customer.height)
        love.graphics.setColor(0, 0, 0)
        love.graphics.setFont(hudFont)
        love.graphics.print(customer.needs .. " eggs", customer.x - 10, customer.y - 20)
        love.graphics.print("T: " .. math.floor(customerTimers[i]) .. " ", customer.x - 10, customer.y - 35)
    end
end



function love.keypressed(key)
    key = string.lower(key)

    if key == "f11" then
        local isFullscreen = love.window.getFullscreen()
        love.window.setFullscreen(not isFullscreen)
    end

    if cash.isCashRegisterOpen() then
        cash.handleCashRegisterKeypress(key)
        return
    end

    if key == "escape" then
        if gameState == "mainMenu" then
            love.event.quit()
        elseif gameState == "playing" then
            isPaused = true
            gameState = "paused"
        elseif gameState == "paused" then
            gameState = "mainMenu"
            isPaused = false
            -- Reset game variables when returning to main menu
            currentLevel = 1
            loadLevel(currentLevel)
        end
    end

    if gameState == "mainMenu" then
        if key == "t" then
            gameState = "tutorial"
            tutorialStep = 1
        elseif key == "y" then
            gameState = "playing"
            tutorialStep = #tutorialMessages
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

        if key == "space" then
            handleSpacebarAction()
        elseif key == "f" then
            handleFeedAction()
        end

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

function handleSpacebarAction()
    if cash.isCashRegisterOpen() then
        return
    end

    if currentScreen == "market" then
        for i, customer in ipairs(customers) do
            if isInPickupRange(player, customer) and totalEggsInMarket >= customer.needs then
                cash.openCashRegister(customer)
                return
            elseif isInPickupRange(player, customer) and totalEggsInMarket < customer.needs then
                table.insert(messages, {text = "Not enough eggs to sell!", timer = 2})
                return
            end
        end

        if isInPickupRange(player, marketplace) then
            if player.carryingEggs > 0 then
                local transferableEggs = math.min(player.carryingEggs, marketCapacity - totalEggsInMarket)
                if transferableEggs > 0 then
                    totalEggsInMarket = totalEggsInMarket + transferableEggs
                    player.carryingEggs = player.carryingEggs - transferableEggs
                    table.insert(messages, {text = "Stored " .. transferableEggs .. " eggs in the market.", timer = 2})
                else
                    table.insert(messages, {text = "Market storage is full!", timer = 2})
                end
            else
                table.insert(messages, {text = "You have no eggs to store!", timer = 2})
            end
            return
        end
    elseif currentScreen == "farm" then
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
                        table.insert(messages, {text = "Collected an egg!", timer = 2})
                    end
                    egg.chicken.hasEgg = false
                    achievements.eggCollector.progress = achievements.eggCollector.progress + 1
                else
                    table.insert(messages, {text = "Your egg basket is full!", timer = 2})
                end
                return
            end
        end

        if predatorsActive then
            for name, predator in pairs(predators) do
                if predator.isActive and isInPickupRange(player, predator) then
                    predator.isActive = false
                    achievements.chickenGuardian.count = achievements.chickenGuardian.count + 1
                    table.insert(messages, {text = "You chased away a predator!", timer = 2})
                    return
                end
            end
        end
    end

    if buttonHover then
        currentScreen = currentScreen == "farm" and "market" or "farm"
        player.x, player.y = 100, 500
    end
end

function handleFeedAction()
    if currentScreen == "farm" then
        for _, chicken in ipairs(chickens) do
            if isInPickupRange(player, chicken) and player.carryingFeed > 0 then
                chicken.hunger = 100
                chicken.isFed = true
                player.carryingFeed = player.carryingFeed - 1
                table.insert(messages, {text = "Fed chicken!", timer = 2})
                return
            end
        end
    end
end

function love.mousepressed(x, y, button)
    -- Adjust mouse coordinates based on scaling
    x = x / scaleX
    y = y / scaleY

    if cash.isCashRegisterOpen() then
        cash.handleCashRegisterMouse(x, y)
        return
    end

    if gameState == "playing" then
        if currentScreen == "farm" and isInPickupRange(player, shop) then
            if mouseOverUpgrade and button == 1 then
                local selectedUpgrade = shop.upgrades[mouseOverUpgrade]
                if money >= selectedUpgrade.cost then
                    money = money - selectedUpgrade.cost
                    selectedUpgrade.action()
                    table.insert(messages, {text = "Purchased: " .. selectedUpgrade.name, timer = 2})
                else
                    table.insert(messages, {text = "Not enough money for that upgrade.", timer = 2})
                end
            end
        end
    end
end
