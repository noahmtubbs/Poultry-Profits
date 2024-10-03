-- Poultry Profits: Egg-cellent Business - Level 1 Prototype

-- Define the player (square) with attributes for tracking eggs and movement speed.
local player = {
    x = 550,   -- Adjusted for the right half of the screen
    y = 150,   -- Adjusted for the right half of the screen
    size = 50, -- Size of the square
    speed = 200, -- Movement speed
    carryingEggs = 0, -- Current number of eggs the player is carrying
    maxCapacity = 10, -- Max capacity of eggs the player can carry
}

-- Define chickens with initial positions
local chickens = {
    {x = 600, y = 400},
    {x = 800, y = 500},
    {x = 700, y = 300},
    {x = 900, y = 200},
    {x = 650, y = 250},
    {x = 750, y = 450}
}

-- Define the eggs
local eggs = {}
local eggSpawnInterval = 2    -- Interval to spawn new eggs
local eggSpawnTimer = 0       -- Timer to track spawning

-- Initialize money counter
local money = 0

-- Marketplace position and size
local marketplace = {
    x = 850, -- Placing the marketplace within the right half
    y = 100,
    width = 100,
    height = 100
}

-- Pop-up message state
local showFullInventoryMessage = false

-- Customers
local customers = {}
local customerSpawnInterval = 5    -- Time interval to spawn customers
local customerSpawnTimer = 0       -- Timer to track customer spawning
local customerSpeed = 50           -- Speed at which customers move
local customerQueue = {}           -- Queue for customers at the marketplace

-- Window dimensions
local windowWidth = 1000
local windowHeight = 600

-- Helper function to check collision between objects
function checkCollision(a, b)
    return a.x < b.x + (b.width or 20) and
           a.x + player.size > b.x and
           a.y < b.y + (b.height or 20) and
           a.y + player.size > b.y
end

-- Function to spawn a new customer at the left side of the screen
function spawnCustomer()
    -- Create a new customer with random y position and moving toward the marketplace
    local customer = {
        x = 0,   -- Start at the left edge
        y = math.random(50, windowHeight - 50),  -- Random Y position
        width = 30,
        height = 50,
        speed = customerSpeed,  -- Speed of movement
    }
    table.insert(customers, customer)
end

-- Load function (called once at the start)
function love.load()
    love.window.setMode(windowWidth, windowHeight)
    love.window.setTitle("Poultry Profits: Egg-cellent Business") -- Set window title
end

-- Update function (called continuously)
function love.update(dt)
    -- Player movement (restricted to the right half of the screen)
    if love.keyboard.isDown("right") and player.x + player.size < windowWidth then
        player.x = player.x + player.speed * dt
    end
    if love.keyboard.isDown("left") and player.x > windowWidth / 2 then
        player.x = player.x - player.speed * dt
    end
    if love.keyboard.isDown("up") and player.y > 0 then
        player.y = player.y - player.speed * dt
    end
    if love.keyboard.isDown("down") and player.y + player.size < windowHeight then
        player.y = player.y + player.speed * dt
    end

    -- Spawn new eggs periodically
    eggSpawnTimer = eggSpawnTimer + dt
    if eggSpawnTimer >= eggSpawnInterval then
        eggSpawnTimer = 0
        spawnEgg()
    end

    -- Animate and check for egg collection
    for _, egg in ipairs(eggs) do
        -- Animate egg (bounce)
        egg.y = egg.y + egg.ySpeed * dt
        if egg.y >= egg.maxY or egg.y <= egg.minY then
            egg.ySpeed = -egg.ySpeed
        end

        -- Check if the player collects the egg
        if not egg.collected and checkCollision(player, egg) then
            if player.carryingEggs < player.maxCapacity then
                egg.collected = true
                player.carryingEggs = player.carryingEggs + 1
            else
                showFullInventoryMessage = true -- Show pop-up message
            end
        end
    end

    -- Remove collected eggs from the list
    for i = #eggs, 1, -1 do
        if eggs[i].collected then
            table.remove(eggs, i)
        end
    end

    -- Customer movement and queue management
    customerSpawnTimer = customerSpawnTimer + dt
    if customerSpawnTimer >= customerSpawnInterval then
        customerSpawnTimer = 0
        spawnCustomer()  -- Spawn a new customer
    end

    -- Move customers toward the marketplace
    for i, customer in ipairs(customers) do
        if customer.x < windowWidth / 2 then
            customer.x = customer.x + customer.speed * dt
        else
            -- Customer reaches the marketplace and joins the queue
            table.insert(customerQueue, customer)
            table.remove(customers, i)
        end
    end

    -- Handle customer transactions if they reach the front of the queue
    if #customerQueue > 0 then
        local frontCustomer = customerQueue[1]
        if player.carryingEggs > 0 then
            money = money + player.carryingEggs * 10
            player.carryingEggs = 0
            table.remove(customerQueue, 1)  -- Customer leaves the queue after purchase
        end
    end
end

-- Draw function (called continuously to render the game)
function love.draw()
    -- Draw the left half (UI area)
    love.graphics.setColor(0.9, 0.9, 0.9) -- Light grey for the UI area
    love.graphics.rectangle("fill", 0, 0, windowWidth / 2, windowHeight)

    -- Display customer-related information on the left side
    love.graphics.setColor(0, 0, 0) -- Set text color to black
    love.graphics.print("Inventory", 20, 20)
    love.graphics.print("Current Eggs: " .. player.carryingEggs, 20, 50)
    love.graphics.print("Money: " .. money .. " KSH", 20, 80)

    -- Display pop-up message if inventory is full
    if showFullInventoryMessage then
        love.graphics.setColor(1, 0, 0, 0.8) -- Semi-transparent red background
        love.graphics.rectangle("fill", 50, 120, 300, 100) -- Rectangle for message background
        love.graphics.setColor(1, 1, 1) -- Set text color to white
        love.graphics.printf("Inventory is full! Please sell eggs.", 50, 150, 300, "center") -- Display message
    end

    -- Draw the right half (gameplay area)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", windowWidth / 2, 0, windowWidth / 2, windowHeight) -- Right half boundary

    -- Draw the player (square)
    love.graphics.setColor(1, 0, 0) -- Set color to red (RGB)
    love.graphics.rectangle("fill", player.x, player.y, player.size, player.size)

    -- Draw the chickens
    love.graphics.setColor(1, 1, 0) -- Set color to yellow (RGB)
    for _, chicken in ipairs(chickens) do
        love.graphics.rectangle("fill", chicken.x, chicken.y, player.size, player.size)
    end

    -- Draw the eggs
    love.graphics.setColor(1, 1, 1) -- Set color to white (RGB)
    for _, egg in ipairs(eggs) do
        if not egg.collected then
            love.graphics.circle("fill", egg.x, egg.y, 10) -- Draw eggs as small circles
        end
    end

    -- Draw the marketplace
    love.graphics.setColor(0, 1, 0) -- Set color to green (RGB)
    love.graphics.rectangle("fill", marketplace.x, marketplace.y, marketplace.width, marketplace.height)
    
    -- Label the marketplace
    love.graphics.setColor(0, 0, 0) -- Set color to black for text
    love.graphics.print("Marketplace", marketplace.x + 10, marketplace.y + 40)

    -- Draw customers moving toward the marketplace
    love.graphics.setColor(0, 0, 1) -- Set color to blue for customers
    for _, customer in ipairs(customers) do
        love.graphics.rectangle("fill", customer.x, customer.y, customer.width, customer.height)
    end

    -- Draw the queue of customers at the marketplace
    local queueOffset = 0
    for _, customer in ipairs(customerQueue) do
        love.graphics.rectangle("fill", marketplace.x - 50 - queueOffset, marketplace.y, customer.width, customer.height)
        queueOffset = queueOffset + 40 -- Space between customers in the queue
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
