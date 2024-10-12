-- Poultry Profits: Egg-cellent Business - Level 1 Prototype

-- Define the player (square) with attributes for tracking eggs and movement speed.
local player = {
    x = 100,   -- Adjusted for screen positioning (slightly above left bottom corner)
    y = 500,   -- Adjusted for screen positioning (slightly above left bottom corner)
    size = 50, -- Size of the square
    speed = 200, -- Movement speed
    carryingEggs = 0, -- Current number of eggs the player is carrying
    maxCapacity = 10, -- Max capacity of eggs the player can carry
}

-- Define chickens with initial positions (for egg collection)
local chickens = {
    {x = 600, y = 400, hasEgg = false, nextEggTimer = 0},
    {x = 800, y = 200, hasEgg = false, nextEggTimer = 0},
    {x = 700, y = 300, hasEgg = false, nextEggTimer = 0},
    {x = 750, y = 450, hasEgg = false, nextEggTimer = 0}
}

-- Define the eggs (for collection)
local eggs = {}
local eggSpawnInterval = 5    -- Egg spawn interval for each chicken (independently)
local eggSpawnTimer = 0       -- Timer to track spawning

-- Initialize money counter and egg storage
money = 0  -- Global variable for money
totalEggsInMarket = 0  -- Global variable for eggs stored in the market (start with 0)
marketCapacity = 50  -- Max capacity of the market

-- Marketplace position and size (formerly warehouse)
local marketplace = {
    x = 850,
    y = 220, -- Positioned for easy access
    width = 100,
    height = 100,
    color = {0, 0, 1}  -- Initially blue
}

-- Customers (will be shown on the market screen)
local customers = {}
local maxCustomers = 5  -- We will generate five customers directly
local customerWidth = 30
local customerHeight = 50
local currentCustomerIndex = 1  -- Start with the first customer
local customerNeeds = {}  -- Stores the number of eggs each customer needs
local savedCustomerNeeds = {}  -- Save the needs of customers to avoid changing
local customerRequirementText = ""  -- Display customer requirement text
local customerFlashRedTime = 0  -- Timer to flash red for customers with insufficient eggs

-- Window dimensions
local windowWidth = 1000
local windowHeight = 600

-- Screen management
local currentScreen = "farm"  -- Can be "farm" or "market"
local buttonY = windowHeight - 50  -- Y position for the button
local buttonHeight = 50
local buttonWidth = windowWidth
local isAtMarketplace = false      -- Track if player is near marketplace for manual selling

-- Egg and sale prices
local eggPrice = 20  -- Each egg sells for 20 KSH

-- Helper function to check if two objects are within collision range
function checkCollision(a, b)
    return a.x < b.x + (b.width or 20) and
           a.x + player.size > b.x and
           a.y < b.y + (b.height or 20) and
           a.y + player.size > b.y
end

-- Function to check if the player is within a larger pickup range (1.5x player size)
function isInPickupRange(a, b)
    local distance = math.sqrt((a.x - b.x)^2 + (a.y - b.y)^2)
    return distance <= player.size * 1.5  -- Increase the pickup range
end

-- Function to spawn a new egg at a specific chicken's position
function spawnEgg(chicken)
    table.insert(eggs, {
        x = chicken.x + 20,
        y = chicken.y + 70,
        minY = chicken.y + 70,
        maxY = chicken.y + 90,
        ySpeed = 50, -- Bouncing speed
        collected = false,
        chicken = chicken -- Associate the egg with its chicken
    })
    chicken.hasEgg = true  -- Mark that this chicken has laid an egg
end

-- Function to spawn customers, ensuring customers do not regenerate
function spawnCustomersAtMarket()
    if #customers == 0 then  -- Only spawn customers if the list is empty
        local startX = marketplace.x - customerWidth - 50  -- Ensure customers are to the left of the marketplace with some gap
        local startY = marketplace.y + marketplace.height / 2 - customerHeight / 2  -- Align vertically with the marketplace
        for i = 1, maxCustomers do
            local customer = {
                x = startX - (i - 1) * (customerWidth + 20),  -- Horizontal arrangement starting from right
                y = startY,  -- All customers are aligned horizontally
                width = customerWidth,
                height = customerHeight,
                needs = savedCustomerNeeds[i] or math.random(2, 20)  -- Use saved needs if available, else random
            }
            table.insert(customers, customer)
            table.insert(customerNeeds, customer.needs)
        end
        savedCustomerNeeds = customerNeeds  -- Save customer needs for future reference
    end
end

-- Function to display global info (eggs, money, total eggs in market)
function displayGlobalInfo()
    love.graphics.setColor(0.5, 0, 0)  -- Deep red color for text
    love.graphics.print("Eggs: " .. player.carryingEggs .. "/" .. player.maxCapacity, 20, 20)
    love.graphics.print("Money: " .. money .. " KSH", 20, 50)
    love.graphics.print("Total Eggs in Market: " .. totalEggsInMarket .. "/" .. marketCapacity, 20, 80)
end

-- Function to display customer requirement info in the middle-top of the screen
function displayCustomerRequirement()
    if customerRequirementText ~= "" then
        love.graphics.setColor(0, 0, 1)  -- Blue color for text
        love.graphics.printf(customerRequirementText, 0, 10, windowWidth, "center")  -- Centered text at the top
    end
end

-- Function to shift customers forward after selling eggs
function shiftCustomersForward()
    table.remove(customers, currentCustomerIndex)  -- Remove the first customer
    table.remove(customerNeeds, currentCustomerIndex)  -- Remove the associated customer needs
    savedCustomerNeeds = customerNeeds  -- Update saved needs
    -- Shift remaining customers forward (to the right)
    for i = 1, #customers do
        customers[i].x = customers[i].x + customerWidth + 20
    end
end

-- Load function (called once at the start)
function love.load()
    love.window.setMode(windowWidth, windowHeight)
    love.window.setTitle("Poultry Profits: Egg-cellent Business") -- Set window title
end

-- Update function (called continuously)
function love.update(dt)
    -- Allow player movement with both arrow keys and WASD
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

    -- Egg collection logic (chickens independently lay eggs after intervals)
    if currentScreen == "farm" then
        for _, chicken in ipairs(chickens) do
            if not chicken.hasEgg then
                chicken.nextEggTimer = chicken.nextEggTimer + dt
                if chicken.nextEggTimer >= eggSpawnInterval then
                    spawnEgg(chicken)
                    chicken.nextEggTimer = 0  -- Reset the egg timer for this chicken
                end
            end
        end

        -- Make eggs bounce
        for _, egg in ipairs(eggs) do
            egg.y = egg.y + egg.ySpeed * dt
            if egg.y >= egg.maxY or egg.y <= egg.minY then
                egg.ySpeed = -egg.ySpeed
            end
        end

    elseif currentScreen == "market" then
        -- Marketplace interaction logic (storing eggs)
        if isInPickupRange(player, marketplace) then
            marketplace.color = {0, 1, 0} -- Change color to green when in range
            if love.mouse.isDown(1) and player.carryingEggs > 0 then  -- Left click to store eggs
                local transferableEggs = math.min(player.carryingEggs, marketCapacity - totalEggsInMarket)
                if transferableEggs > 0 then
                    totalEggsInMarket = totalEggsInMarket + transferableEggs
                    player.carryingEggs = player.carryingEggs - transferableEggs
                end
            end
        else
            marketplace.color = {0, 0, 1} -- Blue when out of range
        end

        -- Selling logic for customers
        if #customers > 0 then
            local currentCustomer = customers[currentCustomerIndex]
            if isInPickupRange(player, currentCustomer) then
                currentCustomer.color = {1, 1, 0}  -- Change customer color to yellow when in range
                customerRequirementText = "Customer needs " .. customerNeeds[currentCustomerIndex] .. " eggs"

                -- If player clicks and has enough eggs, sell to customer
                if love.mouse.isDown(1) then
                    if totalEggsInMarket >= customerNeeds[currentCustomerIndex] then
                        -- Sell eggs
                        totalEggsInMarket = totalEggsInMarket - customerNeeds[currentCustomerIndex]
                        money = money + customerNeeds[currentCustomerIndex] * eggPrice
                        customerRequirementText = ""  -- Clear the text after sale
                        -- Shift remaining customers forward and remove the first one
                        shiftCustomersForward()
                    else
                        currentCustomer.color = {1, 0, 0}  -- Flash red for insufficient eggs
                        customerFlashRedTime = 1  -- Flash red for 1 second
                    end
                end
            else
                currentCustomer.color = {0, 0, 1}  -- Blue when out of range
            end

            -- Handle red flashing for insufficient eggs
            if customerFlashRedTime > 0 then
                customerFlashRedTime = customerFlashRedTime - dt
                if customerFlashRedTime <= 0 then
                    customers[currentCustomerIndex].color = {0, 0, 1}  -- Revert back to blue after flash
                end
            end
        end
    end
end

-- Draw function (called continuously to render the game)
function love.draw()
    -- Background rendering for both screens
    if currentScreen == "farm" then
        love.graphics.setColor(0.9, 0.9, 0.9)  -- Light grey background for farm
        love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)
    elseif currentScreen == "market" then
        love.graphics.setColor(0.8, 0.8, 0.8)  -- Light grey background for market
        love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)
    end

    -- Display global information on both screens
    displayGlobalInfo()

    -- Display customer requirement at the top of the screen in market mode
    if currentScreen == "market" then
        displayCustomerRequirement()
    end

    -- Draw the player on both screens
    love.graphics.setColor(1, 0, 0)  -- Red color for player
    love.graphics.rectangle("fill", player.x, player.y, player.size, player.size)

    if currentScreen == "farm" then
        -- Draw the chickens on the farm screen
        love.graphics.setColor(1, 1, 0)  -- Yellow color for chickens
        for _, chicken in ipairs(chickens) do
            love.graphics.rectangle("fill", chicken.x, chicken.y, player.size, player.size)
        end

        -- Draw the eggs on the farm screen
        for _, egg in ipairs(eggs) do
            if not egg.collected then
                if isInPickupRange(player, egg) then
                    love.graphics.setColor(0, 1, 0) -- Green when in range
                else
                    love.graphics.setColor(1, 1, 1) -- White when out of range
                end
                love.graphics.circle("fill", egg.x, egg.y, 10)
            end
        end

    elseif currentScreen == "market" then
        -- Draw marketplace on the market screen
        love.graphics.setColor(marketplace.color)  -- Marketplace color changes
        love.graphics.rectangle("fill", marketplace.x, marketplace.y, marketplace.width, marketplace.height)
        love.graphics.setColor(0, 0, 0)  -- Label color
        love.graphics.print("Market", marketplace.x + 10, marketplace.y + 40)

        -- Draw customers horizontally near the marketplace (to the left)
        for i, customer in ipairs(customers) do
            love.graphics.setColor(customer.color or {0, 0, 1}) -- Blue color for customers, yellow when in range
            love.graphics.rectangle("fill", customer.x, customer.y, customer.width, customer.height)
        end
    end

    -- Draw the screen toggle button (switch between farm and market)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.rectangle("fill", 0, buttonY, buttonWidth, buttonHeight)
    love.graphics.setColor(0, 0, 0)
    if currentScreen == "farm" then
        love.graphics.printf("Go to Market", 0, buttonY + 15, windowWidth, "center")
    else
        love.graphics.printf("Go to Farm", 0, buttonY + 15, windowWidth, "center")
    end
end

-- Mouse click handler for collecting eggs and storing/selling eggs
function love.mousepressed(x, y, button, istouch, presses)
    if y >= buttonY and y <= buttonY + buttonHeight and button == 1 then
        -- Switch between farm and market screens
        if currentScreen == "farm" then
            currentScreen = "market"
            player.x = 100  -- Reset player to slightly above left bottom on switching to market
            player.y = 500
            spawnCustomersAtMarket()  -- Spawn customers when switching to market
        else
            currentScreen = "farm"
            player.x = 100  -- Reset player to slightly above left bottom on switching to farm
            player.y = 500
        end
    elseif currentScreen == "farm" and button == 1 then
        -- Check if any eggs are in range and collect them with mouse click
        for _, egg in ipairs(eggs) do
            if not egg.collected and isInPickupRange(player, egg) then
                if player.carryingEggs < player.maxCapacity then
                    egg.collected = true
                    player.carryingEggs = player.carryingEggs + 1
                    egg.chicken.hasEgg = false -- Allow the chicken to lay another egg
                end
            end
        end
    end
end
