-- main.lua

-- Required Modules
local cash = require("cash")
local gameFeatures = require("gameFeatures")

-- Level Management
currentLevel = 1
totalLevels = 3

-- Global variables and objects
shop = {
    x = 900,
    y = 0,
    width = 100,
    height = 100,
    color = {0.5, 0.5, 0.5},
    upgrades = {},
    selectedUpgrade = 1,
    upgradeRects = {},
    isOpen = false,
}

-- Barn
--barn = {
--    x = 300,
--    y = 500,
--    width = 100,
--    height = 50,
--    level = 1,
--    capacity = 4,
--    upgradeCost = 500
--}

player = {
    x = 100,
    y = 500,
    width = 60,
    height = 90,
    speed = 200,
    carryingEggs = 0,
    carryingFeed = 10,
    maxCapacity = 15,
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

-- music
local music
local musicPlaying = true  -- Track if music is playing or paused
local isPaused = false  -- Track if the game is paused

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

function Chicken:update(dt)
    if isNight then
        self.isSleeping = true
    else
        self.isSleeping = false
    end

    if not self.isSleeping then
        if feedDoesNotDecrease then
            self.hunger = 100
            self.isFed = true
        else
            self.hunger = math.max(0, self.hunger - dt * 0.5)
            if self.hunger <= 0 then
                self.isFed = false
            end
        end

        if self.isFed then
            if not self.hasEgg then
                self.nextEggTimer = self.nextEggTimer + dt
                if self.nextEggTimer >= self.eggLayingInterval then
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

        local minX = baseWidth / 6
        local maxX = 5 * baseWidth / 6
        local minY = baseHeight / 10
        local maxY = 2 * baseHeight / 5

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
    if currentLevel == 1 then
        chickens = {}
        for _, pos in ipairs(chickenPositions) do
            local chicken = Chicken:new(pos.x, pos.y)
            chicken.baseY = pos.y
            table.insert(chickens, chicken)
        end
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
    x = 730,
    y = 180,
    width = 250,
    height = 300,
    color = {0, 0, 1}
}

-- Customers
customers = {}
customerWidth = 90
customerHeight = 90
customerNeeds = {}
customerTimers = {}
customerTimeLimit = 120
customersServed = 0
requiredCustomers = 5

-- Messages
messages = {}

-- Achievements
achievements = {
    eggCollector = {unlocked = false, threshold = 50, progress = 0},
    chickenGuardian = {unlocked = false, threshold = 5, count = 0},
    masterFarmer = {unlocked = false, threshold = 5000, progress = 0},
    questMaster = {unlocked = false, threshold = 3, completed = 0},
}

-- Feed Behavior
feedDoesNotDecrease = false

-- Window Dimensions
windowWidth = baseWidth
windowHeight = baseHeight

-- Screen Management
currentScreen = "farm"
buttonSize = 90
buttonMargin = 10
buttonX = baseWidth - buttonSize - buttonMargin
buttonY = baseHeight - buttonSize - buttonMargin
buttonHover = false 

-- Day-Night Cycle
dayTimer = 0
dayDuration = 90
nightDuration = 30
currentDay = 1
isNight = false
isDay = true
timeInCurrentCycle = 0

-- Pause Functionality
isPaused = false

-- Predators (Only in Level 3)
predators = {
    hyenas = {
        x = 0,
        y = 0,
        size = 50,
        speed = 20,
        isActive = false,
        targetChicken = nil,
        spawnTimer = 0,
        spawnInterval = 45
    },
    snake = {
        x = 0,
        y = 0,
        size = 30,
        speed = 40,
        isActive = false,
        targetChicken = nil,
        spawnTimer = 0,
        spawnInterval = 35
    },
    eagle = {
        x = 0,
        y = 0,
        size = 60,
        speed = 30,
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
    size = 60,
    speed = 250,
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
    "Press 'P' at any time to pause the game.",
    "Turn Music off and on in pause menu",
    "Press 'Enter' to start your farming adventure!"
}

-- Mouse Interaction
mouseOverUpgrade = nil

-- Fonts
titleFont = love.graphics.newFont(48)
hudFont = love.graphics.newFont(18)
messageFont = love.graphics.newFont(24)

-- Game States
gameState = "mainMenu"

-- Level Management
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
    local aCenterX = a.x + (a.width or a.size) / 2
    local aCenterY = a.y + (a.height or a.size) / 2
    local bCenterX = b.x + (b.width or b.size) / 2
    local bCenterY = b.y + (b.height or b.size) / 2
    local distance = math.sqrt((aCenterX - bCenterX)^2 + (aCenterY - bCenterY)^2)
    local range = 50  -- Adjusted pickup range
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

function removeCustomer(index)
    table.remove(customers, index)
    table.remove(customerNeeds, index)
    table.remove(customerTimers, index)
end

function spawnFirstCustomer()
    customers = {}
    customerNeeds = {}
    customerTimers = {}
    spawnNextCustomer()
end

function spawnNextCustomer()
    local need = math.random(2, 8)
    local customer = {
        x = -customerWidth - 50, -- Start off-screen
        y = marketplace.y + (marketplace.height / 2) - (customerHeight / 2) + 50, 
        width = customerWidth,
        height = customerHeight,
        needs = need,
        isMoving = true,
        color = {0, 0, 1},
        highlight = false,
        image = customerImages[math.random(0, 4)] -- Assign a random image
    }
    table.insert(customers, customer)
    table.insert(customerNeeds, need)
    table.insert(customerTimers, customerTimeLimit)
end


function displayGlobalInfo()
    love.graphics.setFont(hudFont)
    love.graphics.setColor(0, 0, 0)
    local infoY = 80
    local requiredCustomersDisplay = requiredCustomers
    if currentLevel == 3 then
        requiredCustomersDisplay = "∞"
    end
    love.graphics.print("Level " .. currentLevel .. " (" .. customersServed .. "/" .. requiredCustomersDisplay .. " customers)", 20, infoY)
    love.graphics.print("Eggs: " .. player.carryingEggs .. "/" .. player.maxCapacity, 20, infoY + 20)
    love.graphics.print("Feed: " .. player.carryingFeed .. "/" .. player.maxFeedCapacity, 20, infoY + 40)
    love.graphics.print("Money: " .. money .. " KSH", 20, infoY + 60)
    love.graphics.print("Eggs in Market: " .. totalEggsInMarket .. "/" .. marketCapacity, 20, infoY + 80)
    love.graphics.print("High Score: " .. highScore .. " KSH", 20, infoY + 100)
    love.graphics.print("Time: " .. (isNight and "Night" or "Day"), 20, infoY + 120)
end

local function calculateScale(image, targetWidth, targetHeight)
    local imageWidth, imageHeight = image:getDimensions()
    local scaleX = targetWidth / imageWidth
    local scaleY = targetHeight / imageHeight
    local scale = math.max(scaleX, scaleY)
    return scale, scale
end

function love.load()
    -- Load images
    chickenImage = love.graphics.newImage("assets/chicken.png")
    playerImage = love.graphics.newImage("assets/player.png")
    marketplaceImage = love.graphics.newImage("assets/marketplace.png")
    eggImage = love.graphics.newImage("assets/egg.png")
    dayBackground = love.graphics.newImage("assets/day.png")  
    nightBackground = love.graphics.newImage("assets/night.png")
    textboardImage = love.graphics.newImage("assets/text.png") 
    dogImage = love.graphics.newImage("assets/dog.png")
    truckImage = love.graphics.newImage("assets/truck.png")
    backgroundImage = love.graphics.newImage("assets/main_menu.png")
    shopIconImage = love.graphics.newImage("assets/shop.png") -- Shop
    shopUIBackgroundImage = love.graphics.newImage("assets/okok.png") -- Shop UI

    music = love.audio.newSource("assets/background_music.mp3", "stream")
    music:setLooping(true)  -- Make the music loop
    music:play()  -- Start playing the music
    
    customerImages = {}
    for i = 0, 4 do
        customerImages[i] = love.graphics.newImage("assets/customer" .. i .. ".png")
    end

    hyenasImage = love.graphics.newImage("assets/hyenas.png")
    eagleImage = love.graphics.newImage("assets/eagle.png")
    snakeImage = love.graphics.newImage("assets/snake.png")

    love.window.setMode(baseWidth, baseHeight, {resizable=true, fullscreen=false})
    love.window.setTitle("Poultry Profits: Egg-cellent Business")
    math.randomseed(os.time())
    dog.x = 50
    dog.y = baseHeight - dog.size - 10
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
    if currentLevel == 1 then
        initializeChickens(levelData.chickens)
    end

    requiredCustomers = levelData.requiredCustomers or 5
    customersServed = 0
    levelCompleted = false

    gameFeatures.upgradeSystem.init()

    initializeQuests()

    dayTimer = 0
    timeInCurrentCycle = 0
    isDay = true
    isNight = false

    dayDuration = levelData.dayDuration
    nightDuration = levelData.nightDuration

    predatorsActive = levelData.predatorsActive or false
    for _, predator in pairs(predators) do
        predator.isActive = false
        predator.spawnTimer = 0
    end

    spawnFirstCustomer()

    money = levelData.initialMoney or money

    if currentLevel == 1 then
        feedDoesNotDecrease = true
    else
        feedDoesNotDecrease = false
    end
end

function love.resize(w, h)
    windowWidth = w
    windowHeight = h
    scaleX = windowWidth / baseWidth
    scaleY = windowHeight / baseHeight
    buttonX = baseWidth - buttonSize - buttonMargin
    buttonY = baseHeight - buttonSize - buttonMargin
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

        -- Update day-night cycle
        dayTimer = dayTimer + dt
        timeInCurrentCycle = timeInCurrentCycle + dt
        if isDay then
            if timeInCurrentCycle >= dayDuration then
                isDay = false
                isNight = true
                timeInCurrentCycle = 0
            end
        else
            if timeInCurrentCycle >= nightDuration then
                isDay = true
                isNight = false
                timeInCurrentCycle = 0
            end
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
                        customer.highlight = {0, 1, 0} -- Green if enough eggs
                    else
                        customer.highlight = {1, 0, 0} -- Red if not enough eggs
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

        -- Check if the player is near the navigation button area
        local buttonArea = {x = buttonX, y = buttonY, width = buttonSize, height = buttonSize}
        buttonHover = isInPickupRange(player, buttonArea)

        -- Update shop upgrade hover state only if shop is open
        if currentScreen == "market" and shop.isOpen then
            local mouseX, mouseY = love.mouse.getPosition()
            -- Adjust mouse coordinates for scaling
            mouseX = mouseX / scaleX
            mouseY = mouseY / scaleY
            mouseOverUpgrade = nil
            if shop.upgradeRects then
                for i, rect in ipairs(shop.upgradeRects) do
                    if isPointInRect(mouseX, mouseY, rect) then
                        mouseOverUpgrade = i
                        break
                    end
                end
            end
        else
            mouseOverUpgrade = nil
        end

        updateDog(dt)
        cash.updateCashRegister(dt)

        -- Update customer timers
        for i = #customerTimers, 1, -1 do
            if customerTimers[i] then
                customerTimers[i] = customerTimers[i] - dt
                if customerTimers[i] <= 0 then
                    removeCustomer(i)
                    spawnNextCustomer()
                end
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
    local adjustedSpeed = player.speed * dt

    if (love.keyboard.isDown("right") or love.keyboard.isDown("d")) and player.x + player.width < baseWidth then
        player.x = player.x + adjustedSpeed
    end
    if (love.keyboard.isDown("left") or love.keyboard.isDown("a")) and player.x > 0 then
        player.x = player.x - adjustedSpeed
    end
    if (love.keyboard.isDown("up") or love.keyboard.isDown("w")) and player.y > 0 then
        player.y = player.y - adjustedSpeed
    end
    if (love.keyboard.isDown("down") or love.keyboard.isDown("s")) and player.y + player.height < baseHeight then
        player.y = player.y + adjustedSpeed
    end
end

function updateFarm(dt)
    for _, chicken in ipairs(chickens) do
        chicken:update(dt)
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
                if distance < 300 then
                    local pullStrength = (300 - distance) / 100
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
    for _, customer in ipairs(customers) do
        if customer.isMoving then
            customer.x = customer.x + 100 * dt
            if customer.x >= marketplace.x - customer.width - 20 then
                customer.x = marketplace.x - customer.width - 20
                customer.isMoving = false
            end
        end
    end
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
                -- 如果没有目标猎物，狗在固定区域巡逻
                -- 例如，狗在左下角和右下角之间来回移动
                local patrolSpeed = 150
                if not dog.patrolDirection then
                    dog.patrolDirection = "right"
                end

                if dog.patrolDirection == "right" then
                    dog.x = dog.x + patrolSpeed * dt
                    if dog.x >= baseWidth - 50 then
                        dog.patrolDirection = "left"
                    end
                elseif dog.patrolDirection == "left" then
                    dog.x = dog.x - patrolSpeed * dt
                    if dog.x <= 50 then
                        dog.patrolDirection = "right"
                    end
                end
            end
        else
            -- 狗未激活时，保持在初始位置或执行其他逻辑
            -- 例如，返回到左下角
            local targetX = 50
            local targetY = baseHeight - dog.size - 10
            local dx = targetX - dog.x
            local dy = targetY - dog.y
            local distance = math.sqrt(dx * dx + dy * dy)
            if distance > 1 then
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

            if isNight and name == "hyenas" then
                adjustedInterval = adjustedInterval - 10
            end

            if not predator.isActive then
                predator.spawnTimer = predator.spawnTimer + dt
                if predator.spawnTimer >= adjustedInterval then
                    predator.isActive = true
                    if name == "eagle" then
                        predator.x = math.random(0, baseWidth)
                        predator.y = -50
                    elseif name == "hyenas" then
                        predator.x = -50
                        predator.y = math.random(100, buttonY - 100)
                    elseif name == "snake" then
                        predator.x = baseWidth + 50
                        predator.y = math.random(100, buttonY - 100)
                    end
                    predator.targetChicken = chickens[math.random(1, #chickens)]
                    predator.spawnTimer = 0

                    if player.hasGuardDog and (name == "hyenas" or name == "snake") then
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

                    if player.hasGuardDog and name == "eagle" then
                        if math.random() < 0.5 then
                            predator.isActive = false
                            table.insert(messages, {text = "Your guard dog scared away a eagle!", timer = 2})
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
    if not levelCompleted and customersServed >= requiredCustomers and currentLevel < totalLevels then
        levelCompleted = true
        table.insert(messages, {text = "Level " .. currentLevel .. " Completed!", timer = 5})
        -- Delay level transition to allow message to be displayed
        love.timer.sleep(2)
        currentLevel = currentLevel + 1
        loadLevel(currentLevel)
    end
end

function love.draw()
    -- Apply scaling to the entire scene
    love.graphics.push()
    love.graphics.scale(scaleX, scaleY)

    if gameState == "mainMenu" then
        drawMainMenu()
    elseif gameState == "tutorial" then
        drawTutorial()
    elseif gameState == "paused" then
        drawPauseMenu()
    elseif gameState == "playing" then
        -- Draw the background color as a fallback
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.rectangle("fill", 0, 0, baseWidth, baseHeight)

        -- Determine which background to draw based on day/night
        local backgroundImage = isNight and nightBackground or dayBackground

        if backgroundImage then
            -- Calculate scaling to fill the screen while maintaining aspect ratio
            local scale = calculateScale(backgroundImage, baseWidth, baseHeight)
            -- Calculate position to center the image
            local drawWidth = backgroundImage:getWidth() * scale
            local drawHeight = backgroundImage:getHeight() * scale
            local drawX = (baseWidth - drawWidth) / 2
            local drawY = (baseHeight - drawHeight) / 2
            love.graphics.setColor(1, 1, 1) -- Reset color to white for image
            love.graphics.draw(backgroundImage, drawX, drawY, 0, scale, scale)
            local textboardWidth, textboardHeight = textboardImage:getDimensions()
            local targetTextboardWidth = baseWidth / 2 
            local targetTextboardHeight = baseHeight*20 / 50 
            local scaleTextboardX = targetTextboardWidth / textboardWidth
            local scaleTextboardY = targetTextboardHeight / textboardHeight
            local textboardPosX = -105  -- 左侧边距
            local textboardPosY = 16  -- 上侧边距
            love.graphics.draw(textboardImage, textboardPosX, textboardPosY, 0, scaleTextboardX, scaleTextboardY)

        else
            -- If no background image, use a solid color
            if isNight then
                love.graphics.setColor(0.05, 0.05, 0.2) -- Dark blue for night
            else
                love.graphics.setColor(0.53, 0.81, 0.98) -- Light blue for day
            end
            love.graphics.rectangle("fill", 0, 0, baseWidth, baseHeight)
        end

        -- Display global information
        displayGlobalInfo()

        -- Draw messages
        love.graphics.setFont(messageFont)
        for i, message in ipairs(messages) do
            love.graphics.setColor(0, 0, 0)
            love.graphics.printf(message.text, 0, 220 + i * 20, baseWidth, "center")
        end

        -- Draw player
        drawPlayer()

        if currentScreen == "farm" then
            drawFarm()
        elseif currentScreen == "market" then
            drawMarket()
        end

        -- Draw navigation button as truck.png image at the bottom right corner
        if buttonHover then
            love.graphics.setColor(1, 1, 1) -- Full brightness when hovered
        else
            love.graphics.setColor(0.8, 0.8, 0.8) -- Dimmed when not hovered
        end
       
        local scaleXBtn = buttonSize / truckImage:getWidth()
        local scaleYBtn = buttonSize / truckImage:getHeight()
        love.graphics.draw(truckImage, buttonX, buttonY, 0, scaleXBtn, scaleYBtn)

        if isPaused then
            drawPauseMenu()
        end
    end

    -- If cash register is open, draw it above everything else
    if cash.isCashRegisterOpen() then
        cash.drawCashRegister()
    end

    -- Reset scaling
    love.graphics.pop()
end



function drawPlayer()
    local scaleXPlayer = player.width / playerImage:getWidth()
    local scaleYPlayer = player.height / playerImage:getHeight()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(playerImage, player.x, player.y, 0, scaleXPlayer, scaleYPlayer)
end

function drawMainMenu()
    -- Draw the background image at (0, 0)
    love.graphics.draw(backgroundImage, 0, 0, 0, love.graphics.getWidth() / backgroundImage:getWidth(), love.graphics.getHeight() / backgroundImage:getHeight())

    -- Set a color for the overlay (if you want to apply a color filter or overlay effect)
    love.graphics.setColor(0.2, 0.6, 0.8, 0.5) -- RGBA for transparency (optional)
    love.graphics.rectangle("fill", 0, 0, baseWidth, baseHeight) -- Optional overlay, you can remove this if not needed

    -- Reset color to white
    love.graphics.setColor(1, 1, 1)

    -- Set font for title
    love.graphics.setFont(titleFont)
    love.graphics.printf("Poultry Profits", 0, 100, baseWidth, "center")

    -- Set font for HUD
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

  -- Add a "Toggle Music" button
  local buttonX, buttonY, buttonWidth, buttonHeight = 200, baseHeight / 2 + 50, 200, 50
  love.graphics.rectangle("line", buttonX, buttonY, buttonWidth, buttonHeight)
  love.graphics.printf("Toggle Music", buttonX, buttonY + 15, buttonWidth, "center")
  
  -- Display current music state (On or Off)
  local musicState = musicPlaying and "On" or "Off"
  love.graphics.printf("Music: " .. musicState, 0, baseHeight / 2 + 120, baseWidth, "center")
end

function drawFarm()

    -- Draw chickens
    for _, chicken in ipairs(chickens) do
        -- Set color based on chicken state
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

        -- Reset color to white
        love.graphics.setColor(1, 1, 1, 1)

        -- Draw the hunger bar above the chicken
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("fill", chicken.x, chicken.y - 10, (chicken.hunger / 100) * chicken.size, 5)
        love.graphics.setColor(1, 1, 1, 1) -- Reset color
    end

    -- Draw eggs with glow if in range
    for _, egg in ipairs(eggs) do
        if not egg.collected then
            local scale = egg.size / eggImage:getWidth()
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(eggImage, egg.x, egg.y, 0, scale, scale)
            if isInPickupRange(player, egg) then
                love.graphics.setColor(1, 1, 0, 0.3)
                love.graphics.circle("fill", egg.x + (egg.size / 2), egg.y + (egg.size / 2), egg.size + 10)
            end
        end
    end

    -- Draw predators if active
    if predatorsActive then
        for name, predator in pairs(predators) do
            if predator.isActive then
                local color = {0, 0, 0}
                if name == "hyenas" then
                    color = {1, 0.5, 0}
                elseif name == "snake" then
                    color = {0, 1, 0}
                elseif name == "eagle" then
                    color = {0.5, 0.5, 0.5}
                end
                drawPredator(predator, name:gsub("^%l", string.upper), color)
            end
        end
    end

    -- Draw Guard Dog if purchased
    if player.hasGuardDog then
        -- Set color to white to draw the image without tint
        love.graphics.setColor(1, 1, 1, 1)
        
        -- Calculate scaling factors to match the dog dimensions
        local scaleX = dog.size / dogImage:getWidth()
        local scaleY = dog.size / dogImage:getHeight()
        
        -- Draw the dog image
        love.graphics.draw(dogImage, dog.x, dog.y, 0, scaleX, scaleY)
    end

    
end

function drawPredator(predator, name, color)
    local image = nil

    if name == "Hyenas" then
        image = hyenasImage
    elseif name == "Eagle" then
        image = eagleImage
    elseif name == "Snake" then
        image = snakeImage
    end

        love.graphics.setColor(1, 1, 1, 1)
        local scaleX = predator.size / image:getWidth()
        local scaleY = predator.size / image:getHeight()
        love.graphics.draw(image, predator.x, predator.y, 0, scaleX, scaleY)
end

function drawShopUI()
    if shop.isOpen then
        -- 获取屏幕尺寸的一半
        local bgWidth = (baseWidth / 5)*2
        local bgHeight = baseHeight / 1.8

        -- 设置 Shop UI 背景板的位置，使其居中或根据需求调整
        local uiX = ((baseWidth - bgWidth) /2) +100
        local uiY = -80
        -- 计算缩放比例以适应新的背景板尺寸
        local scaleX = bgWidth*2 / shopUIBackgroundImage:getWidth()
        local scaleY = bgHeight*2 / shopUIBackgroundImage:getHeight()
        local scale = math.min(scaleX, scaleY) -- 保持比例不变

        -- 计算偏移量以居中背景板
        local offsetX = uiX + (bgWidth - shopUIBackgroundImage:getWidth() * scale) / 2
        local offsetY = uiY + (bgHeight - shopUIBackgroundImage:getHeight() * scale) / 2

        -- 绘制 Shop UI 背景板
        love.graphics.setColor(1, 1, 1, 1) -- 设定为不透明
        love.graphics.draw(shopUIBackgroundImage, offsetX, offsetY, 0, scale, scale)

        -- 绘制升级选项的文字
        love.graphics.setColor(0, 0, 0)
        love.graphics.setFont(hudFont)
        shop.upgradeRects = {}

        for i, upgrade in ipairs(shop.upgrades) do
            local upgradeX = uiX + 20
            local upgradeY = uiY + 60 + i * 20  -- 增加每个升级选项的垂直间距，适应新背景板大小
            local upgradeWidth = bgWidth - 40
            local upgradeHeight = 30

            shop.upgradeRects[i] = {x = upgradeX, y = upgradeY, width = upgradeWidth, height = upgradeHeight}

            -- 根据升级状态和鼠标悬停状态设置颜色
            if upgrade.purchased and not upgrade.repeatable then
                love.graphics.setColor(0.5, 0.5, 0.5) -- 已购买且不可重复的升级灰色
            elseif mouseOverUpgrade == i then
                love.graphics.setColor(0, 0.5, 1) -- 鼠标悬停时蓝色
            elseif i == shop.selectedUpgrade then
                love.graphics.setColor(1, 0, 0) -- 选中时红色
            elseif money >= upgrade.cost then
                love.graphics.setColor(0, 0, 0) -- 有钱时黑色
            else
                love.graphics.setColor(0.5, 0.5, 0.5) -- 没有钱时灰色
            end
            love.graphics.print(upgrade.name .. ": " .. upgrade.cost .. " KSH", upgradeX, upgradeY)
        end
        love.graphics.setColor(0, 0, 0)
    end
end





function drawMarket()
    -- Calculate scaling factors to match the marketplace background size
    local scaleXImg = marketplace.width / marketplaceImage:getWidth()
    local scaleYImg = marketplace.height / marketplaceImage:getHeight()

    -- Draw the marketplace image at the marketplace background coordinates with scaling
    love.graphics.draw(marketplaceImage, marketplace.x, marketplace.y, 0, scaleXImg, scaleYImg)

    -- Draw Shop icon
    love.graphics.setColor(1, 1, 1) -- 设置颜色为白色以正确显示图像
    local shopScaleX = shop.width / shopIconImage:getWidth()
    local shopScaleY = shop.height / shopIconImage:getHeight()
    love.graphics.draw(shopIconImage, shop.x, shop.y, 0, shopScaleX, shopScaleY)

    -- 获取当前鼠标位置
    local mouseX, mouseY = love.mouse.getPosition()
    -- 调整鼠标坐标以匹配游戏世界坐标（考虑缩放）
    mouseX = mouseX / scaleX
    mouseY = mouseY / scaleY

    -- 计算鼠标与 Shop 图标中心的距离
    local shopCenterX = shop.x + shop.width / 2
    local shopCenterY = shop.y + shop.height / 2
    local distance = math.sqrt((mouseX - shopCenterX)^2 + (mouseY - shopCenterY)^2)

    -- 定义触发黄色光芒的距离阈值
    local glowRadius = 50  -- 可根据需要调整

    if distance <= glowRadius then
        -- 绘制半透明黄色光芒
        love.graphics.setColor(1, 1, 0, 0.3) -- 半透明黄色
        love.graphics.circle("fill", shopCenterX, shopCenterY, math.max(shop.width, shop.height)*0.5)
    end

    -- Draw Shop UI (only if shop.isOpen)
    drawShopUI()

    -- Yellow glow around marketplace when in range
    if isInPickupRange(player, marketplace) then
        love.graphics.setColor(1, 1, 0, 0.3)
        love.graphics.rectangle("line", marketplace.x - 10, marketplace.y - 10, marketplace.width + 20, marketplace.height + 20)
    end

    -- Draw customers
    for i, customer in ipairs(customers) do
        -- Set color to white to draw the image without tint
        love.graphics.setColor(1, 1, 1, 1)
        
        -- Calculate scaling factors to match the customer dimensions
        local scaleX = customer.width / customer.image:getWidth()
        local scaleY = customer.height / customer.image:getHeight()

        -- Draw the customer image
        love.graphics.draw(customer.image, customer.x, customer.y, 0, scaleX, scaleY)

        -- If the customer is highlighted, draw a glow around them
        if customer.highlight then
            love.graphics.setColor(1, 1, 0, 0.3)
            love.graphics.rectangle("fill", customer.x - 5, customer.y - 5, customer.width + 10, customer.height + 10)
        end

        -- Draw customer needs and timer
        love.graphics.setColor(0, 0, 0)
        love.graphics.setFont(hudFont)

        -- Prepare the two lines of text
        local needsText = customer.needs .. " eggs"
        local timerText = "T: " .. math.floor(customerTimers[i])

        -- Calculate the width and height of each line
        local needsTextWidth = love.graphics.getFont():getWidth(needsText)
        local timerTextWidth = love.graphics.getFont():getWidth(timerText)
        local textHeight = love.graphics.getFont():getHeight()

        -- Calculate the total height for the box (stacking two lines)
        local totalHeight = textHeight * 2 + 10  -- Extra padding between lines

        -- Set the color for the text box (you can change this as needed)
        love.graphics.setColor(1, 1, 1, 0.7)  -- Semi-transparent white box

        -- Calculate the box width (use the wider of the two text lines)
        local boxWidth = math.max(needsTextWidth, timerTextWidth) + 20  -- Make the box wide enough for the wider text

        -- Adjust the y position of the box to be slightly above the customer
        local boxY = customer.y - totalHeight - 10  -- Move the box up by the height of the text box plus some extra space

        -- Draw the text box
        love.graphics.rectangle("fill", customer.x - 10, boxY, boxWidth, totalHeight)

        -- Calculate the x position for centering the text within the box
        local boxX = customer.x - 10 + (boxWidth - needsTextWidth) / 2  -- Centering the "needs" text

        -- Draw the first line of text (needs) centered in the box
        love.graphics.setColor(0, 0, 0)  -- Reset text color to black
        love.graphics.print(needsText, boxX, boxY + 5)  -- Small padding inside the box

        -- Draw the second line of text (timer) centered in the box
        local timerTextX = customer.x - 10 + (boxWidth - timerTextWidth) / 2  -- Centering the "timer" text
        love.graphics.print(timerText, timerTextX, boxY + textHeight + 5)  -- Small padding inside the box
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

        if currentScreen == "market" and isInPickupRange(player, shop) then
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
        if currentScreen == "market" then
            -- 检查是否点击在 shop 按钮上
            if isPointInRect(x, y, shop) and button == 1 then
                shop.isOpen = not shop.isOpen
                return
            end

            -- 如果 shop 已打开，处理升级购买
            if shop.isOpen and button == 1 then
                for i, rect in ipairs(shop.upgradeRects) do
                    if isPointInRect(x, y, rect) then
                        local selectedUpgrade = shop.upgrades[i]
                        if money >= selectedUpgrade.cost then
                            money = money - selectedUpgrade.cost
                            selectedUpgrade.action()
                            selectedUpgrade.purchased = true -- 如果升级是一次性的
                            table.insert(messages, {text = "Purchased: " .. selectedUpgrade.name, timer = 2})
                        else
                            table.insert(messages, {text = "Not enough money for that upgrade.", timer = 2})
                        end
                        return
                    end
                end
            end
        end
    end

    -- 处理暂停时的鼠标点击
    if isPaused then
        -- 定义“Toggle Music”按钮区域
        local toggleMusicButton = {x = 200, y = baseHeight / 2 + 50, width = 200, height = 50}
        if isPointInRect(x, y, toggleMusicButton) and button == 1 then
            toggleMusic()
            return
        end
    end
end


function toggleMusic()
    if musicPlaying then
        music:stop()  -- Stop music
    else
        music:play()  -- Play music
    end
    musicPlaying = not musicPlaying  -- Toggle the music state
end

function isPointInRect(px, py, rect)
    return px >= rect.x and px <= rect.x + rect.width and
           py >= rect.y and py <= rect.y + rect.height
end

