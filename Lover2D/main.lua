-- Poultry Profits: Egg-cellent Business - Level 1 Prototype

-- Define the player (square) with attributes for tracking eggs and movement speed.
local player = {
    x = 550,   -- Adjusted for screen positioning
    y = 150,   -- Adjusted for screen positioning
    size = 50, -- Size of the square
    speed = 200, -- Movement speed
    carryingEggs = 0, -- Current number of eggs the player is carrying
    maxCapacity = 10, -- Max capacity of eggs the player can carry
}

-- Define chickens with initial positions (for egg collection)
local chickens = {
    {x = 600, y = 400},
    {x = 800, y = 200},
    {x = 700, y = 300},
    {x = 750, y = 450}
}

-- Define the eggs (for collection)
local eggs = {}
local eggSpawnInterval = 2    -- Interval to spawn new eggs
local eggSpawnTimer = 0       -- Timer to track spawning

-- Initialize money counter
local money = 0

-- Marketplace position and size (on the customer screen)
local marketplace = {
    x = 850,
    y = 100,
    width = 100,
    height = 100
}

-- Define the warehouse below the marketplace
local warehouse = {
    x = 850,
    y = 220, -- Positioned directly below the marketplace
    width = 100,
    height = 100
}

-- Customers (will be shown on the customer screen)
local customers = {}
local customerQueue = {}           -- Queue for customers at the marketplace
local customerSpeed = 50           -- Speed at which customers move
local maxCustomers = 1             -- Max number of customers at the marketplace
local customerSpawnTimer = 0       -- Initialize the customerSpawnTimer properly

-- Window dimensions
local windowWidth = 1000
local windowHeight = 600

-- Screen management
local currentScreen = "farm"  -- Can be "farm" or "market"
local buttonY = windowHeight - 50  -- Y position for the button
local buttonHeight = 50
local buttonWidth = windowWidth
local isAtMarketplace = false      -- Track if player is near marketplace for manual selling

-- Helper function to check collision between objects
function checkCollision(a, b)
    return a.x < b.x + (b.width or 20) and
           a.x + player.size > b.x and
           a.y < b.y + (b.height or 20) and
           a.y + player.size > b.y
end

-- Function to spawn a new customer at the left side of the screen
function spawnCustomer()
    -- Only spawn if there are fewer than maxCustomers in the queue
    if #customerQueue < maxCustomers then
        local customer = {
            x = 0,   -- Start at the left edge
            y = math.random(50, windowHeight - 50),  -- Random Y position
            width = 30,
            height = 50,
            speed = customerSpeed,  -- Speed of movement
        }
        table.insert(customers, customer)
    end
end

-- Function to spawn a new egg at a random chicken's position
function spawnEgg()
    local chicken = chickens[math.random(1, #chickens)]
    table.insert(eggs, {
        x = chicken.x + 20,
        y = chicken.y + 70,
        minY = chicken.y + 70,
        maxY = chicken.y + 90,
        ySpeed = 50, -- Bouncing speed
        collected = false
    })
end

-- Load function (called once at the start)
function love.load()
    love.window.setMode(windowWidth, windowHeight)
    love.window.setTitle("Poultry Profits: Egg-cellent Business") -- Set window title
end

-- Update function (called continuously)
function love.update(dt)
    -- Allow player movement on both screens
    if love.keyboard.isDown("right") and player.x + player.size < windowWidth then
        player.x = player.x + player.speed * dt
    end
    if love.keyboard.isDown("left") and player.x > 0 then
        player.x = player.x - player.speed * dt
    end
    if love.keyboard.isDown("up") and player.y > 0 then
        player.y = player.y - player.speed * dt
    end
    if love.keyboard.isDown("down") and player.y + player.size < windowHeight then
        player.y = player.y + player.speed * dt
    end

    if currentScreen == "farm" then
        -- Egg collection logic on the farm screen
        eggSpawnTimer = eggSpawnTimer + dt
        if eggSpawnTimer >= eggSpawnInterval then
            eggSpawnTimer = 0
            spawnEgg() -- Spawn a new egg
        end

        -- Check for egg collection
        for _, egg in ipairs(eggs) do
            egg.y = egg.y + egg.ySpeed * dt
            if egg.y >= egg.maxY or egg.y <= egg.minY then
                egg.ySpeed = -egg.ySpeed
            end
            if not egg.collected and checkCollision(player, egg) then
                if player.carryingEggs < player.maxCapacity then
                    egg.collected = true
                    player.carryingEggs = player.carryingEggs + 1
                else
                    showFullInventoryMessage = true
                end
            end
        end

        -- Remove collected eggs
        for i = #eggs, 1, -1 do
            if eggs[i].collected then
                table.remove(eggs, i)
            end
        end

    elseif currentScreen == "market" then
        -- Customer logic on the market screen
        customerSpawnTimer = customerSpawnTimer + dt
        if customerSpawnTimer >= 20 then  -- Attempt to spawn a customer every 5 seconds
            customerSpawnTimer = 0
            spawnCustomer()
        end

        -- Move customers toward the marketplace
        for i, customer in ipairs(customers) do
            if customer.x < marketplace.x then
                customer.x = customer.x + customer.speed * dt
            else
                table.insert(customerQueue, customer)
                table.remove(customers, i)
            end
        end

        -- Detect if player is near marketplace for manual selling
        isAtMarketplace = checkCollision(player, marketplace)

        -- Manual selling of eggs and reducing the customer queue
        if isAtMarketplace and love.keyboard.isDown("space") then
            if player.carryingEggs > 0 and #customerQueue > 0 then
                money = money + player.carryingEggs * 10
                player.carryingEggs = 0
                table.remove(customerQueue, 1) -- Reduce customer count by 1
            end
        end
    end
end

-- Draw function (called continuously to render the game)
function love.draw()
    -- Display the egg count and money at the top-left in green on both screens
    love.graphics.setColor(0, 1, 0)  -- Green color
    love.graphics.print("Eggs: " .. player.carryingEggs .. "/" .. player.maxCapacity, 20, 20)
    love.graphics.print("Money: " .. money .. " KSH", 20, 50)

    if currentScreen == "farm" then
        -- Farm screen (show player, eggs, and chickens)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", 0, 0, windowWidth, windowHeight)

        -- Draw the player
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("fill", player.x, player.y, player.size, player.size)

        -- Draw the chickens
        love.graphics.setColor(1, 1, 0)
        for _, chicken in ipairs(chickens) do
            love.graphics.rectangle("fill", chicken.x, chicken.y, player.size, player.size)
        end

        -- Draw the eggs
        love.graphics.setColor(1, 1, 1)
        for _, egg in ipairs(eggs) do
            if not egg.collected then
                love.graphics.circle("fill", egg.x, egg.y, 10)
            end
        end

    elseif currentScreen == "market" then
        -- Market screen (show customers and marketplace)
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)

        -- Draw the player on the market screen
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("fill", player.x, player.y, player.size, player.size)

        -- Draw the marketplace
        love.graphics.setColor(0, 1, 0)
        love.graphics.rectangle("fill", marketplace.x, marketplace.y, marketplace.width, marketplace.height)
        love.graphics.setColor(0, 0, 0)
        love.graphics.print("Marketplace", marketplace.x + 10, marketplace.y + 40)

        -- Draw the warehouse below the marketplace
        love.graphics.setColor(0, 0, 1)
        love.graphics.rectangle("fill", warehouse.x, warehouse.y, warehouse.width, warehouse.height)
        love.graphics.setColor(0, 1, 0)
        love.graphics.print("Warehouse", warehouse.x + 10, warehouse.y + 40)

        -- Draw the customers
        love.graphics.setColor(0, 0, 1)
        for _, customer in ipairs(customers) do
            love.graphics.rectangle("fill", customer.x, customer.y, customer.width, customer.height)
        end

        love.graphics.setColor(0, 0, 1)  -- blue color
        love.graphics.print("Eggs: " .. player.carryingEggs .. "/" .. player.maxCapacity, 20, 20)
        love.graphics.print("Money: " .. money .. " KSH", 20, 50)

        -- Draw the queue of customers at the marketplace
        local queueOffset = 0
        for _, customer in ipairs(customerQueue) do
            love.graphics.rectangle("fill", marketplace.x - 50 - queueOffset, marketplace.y, customer.width, customer.height)
            queueOffset = queueOffset + 40
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

-- Mouse click handler
function love.mousepressed(x, y, button, istouch, presses)
    if y >= buttonY and y <= buttonY + buttonHeight and button == 1 then
        -- Switch between farm and market screens
        if currentScreen == "farm" then
            currentScreen = "market"
        else
            currentScreen = "farm"
        end
    end
end