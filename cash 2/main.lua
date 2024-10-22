-- Customer Class
Customer = {}
Customer.__index = Customer

function Customer:new(eggPrice)
    local customer = {
        eggsToBuy = 74, -- Random number of eggs (1 to 10)
        moneyPaid = 0,
        x = love.graphics.getWidth(),
        y = love.graphics.getHeight() / 2, -- Start at the right side of the screen
        isWalking = true,
        eggPrice = eggPrice -- Store egg price in customer
    }
    setmetatable(customer, Customer)
    return customer
end

function Customer:update(dt)
    if self.isWalking then
        self.x = self.x - 100 * dt -- Walk left
        if self.x < 300 then
            self.isWalking = false -- Stop walking when reaching cash register area
            
            -- Calculate the total price based on eggs to buy
            local totalPrice = self.eggsToBuy * self.eggPrice
            
            -- Set the payment to the nearest available KSH denomination
            self.moneyPaid = getNearestKSHDenomination(totalPrice)
        end
    end
end

function Customer:draw()
    love.graphics.setColor(0, 0, 1)
    love.graphics.rectangle("fill", self.x, self.y, 20, 20) -- Draw customer as a rectangle
end

-- Helper function to get the nearest KSH denomination based on total price
function getNearestKSHDenomination(totalPrice)
    local denominations = {1, 5, 10, 20, 40, 50, 100, 200, 500, 1000}
    for _, denomination in ipairs(denominations) do
        if totalPrice <= denomination then
            return denomination
        end
    end
    return denominations[#denominations] -- If totalPrice exceeds 1000, return 1000 KSH
end

-- Main game variables
local customers = {}
local cashRegisterOpen = false
local totalMoney = 0
local saleConfirmation = ""
local showConfirmation = false
local confirmationTimer = 0
local confirmationDuration = 2 -- Duration to show the confirmation (in seconds)
local currentCustomer = nil
local eggPrice = 1 -- Price per egg
local changeInput = 0 -- Input for change given back (accumulated)
local changeButtons = {1, 5, 10, 20, 40, 50, 100} -- Denominations for change buttons
local changeButtonX = 130
local changeButtonY = 340
local buttonWidth = 50
local buttonHeight = 30

function love.load()
    love.window.setTitle("Poultry Profits: Cash Register")
    font = love.graphics.newFont(14)
    love.graphics.setFont(font)

    -- Create an initial customer with the eggPrice
    table.insert(customers, Customer:new(eggPrice))
end

function love.update(dt)
    -- Update each customer
    for _, customer in ipairs(customers) do
        customer:update(dt)
    end

    -- Update confirmation timer
    if showConfirmation then
        confirmationTimer = confirmationTimer - dt
        if confirmationTimer <= 0 then
            showConfirmation = false
            saleConfirmation = ""
        end
    end
end

function love.draw()
    -- Draw customers
    for _, customer in ipairs(customers) do
        customer:draw()
    end

    -- Main game info
    love.graphics.print("Press 'R' to open cash register", 10, 10)
    love.graphics.print("Total Money: KSH " .. totalMoney, 10, 30)

    if cashRegisterOpen and currentCustomer then
        -- Cash Register window
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.rectangle("fill", 100, 100, 400, 400)
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", 100, 100, 400, 400)

        love.graphics.print("Cash Register", 220, 120)
        love.graphics.print("Customer wants to buy " .. currentCustomer.eggsToBuy .. " eggs.", 130, 150)
        love.graphics.print("Price per egg: KSH " .. currentCustomer.eggPrice, 130, 180)

        local totalPrice = currentCustomer.eggsToBuy * currentCustomer.eggPrice
        love.graphics.print("Total: KSH " .. totalPrice, 130, 220)

        -- Customer payment display
        love.graphics.print("Customer pays: KSH " .. currentCustomer.moneyPaid, 130, 250)

        -- Calculate change to give
        local changeToGive = currentCustomer.moneyPaid - totalPrice
        love.graphics.print("Change to give: KSH " .. changeToGive, 130, 280)

        -- Input for change given back
        love.graphics.print("Change given back: KSH " .. changeInput, 130, 310)

        -- Draw change buttons
        for i, value in ipairs(changeButtons) do
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.rectangle("fill", changeButtonX + (i - 1) * (buttonWidth + 10), changeButtonY, buttonWidth, buttonHeight)
            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("line", changeButtonX + (i - 1) * (buttonWidth + 10), changeButtonY, buttonWidth, buttonHeight)
            love.graphics.printf(value .. " KSH", changeButtonX + (i - 1) * (buttonWidth + 10), changeButtonY + 5, buttonWidth, "center")
        end

        love.graphics.print("Press 'Enter' to finalize sale, or 'Esc' to cancel", 130, 400)
    end

    -- Show sale confirmation if applicable
    if showConfirmation then
        love.graphics.setColor(0.8, 1, 0.8)
        love.graphics.rectangle("fill", 150, 450, 300, 50)
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", 150, 450, 300, 50)
        love.graphics.print(saleConfirmation, 200, 470)
    end
end

-- Handle keypress events
function love.keypressed(key)
    if cashRegisterOpen then
        if key == "return" then
            -- Finalize the transaction
            local totalPrice = currentCustomer.eggsToBuy * currentCustomer.eggPrice
            local changeToGive = currentCustomer.moneyPaid - totalPrice

            -- Validate the accumulated change input
            if changeInput == changeToGive then
                saleConfirmation = "Correct change given!"
                totalMoney = totalMoney + totalPrice -- Add the sale amount to total money
            else
                saleConfirmation = "Incorrect change! You gave KSH " .. changeInput .. ". Correct change is KSH " .. changeToGive .. "."
            end

            showConfirmation = true
            confirmationTimer = confirmationDuration  -- Reset the timer

            -- Reset cash register and prepare for the next customer
            cashRegisterOpen = false
            currentCustomer = nil
            changeInput = 0 -- Reset change input
        elseif key == "escape" then
            cashRegisterOpen = false
            currentCustomer = nil -- Close cash register without selling
            changeInput = 0 -- Reset change input
        end
    end

    -- Open cash register with 'R' key when a customer is ready
    if key == "r" and #customers > 0 and not cashRegisterOpen then
        currentCustomer = table.remove(customers, 1) -- Get the first customer
        cashRegisterOpen = true
    end
end

-- Handle mouse pressed for change buttons
function love.mousepressed(x, y, button, istouch, presses)
    if cashRegisterOpen and button == 1 then
        -- Check if any change button is clicked
        for i, value in ipairs(changeButtons) do
            if x >= changeButtonX + (i - 1) * (buttonWidth + 10) and x <= changeButtonX + (i - 1) * (buttonWidth + 10) + buttonWidth and
               y >= changeButtonY and y <= changeButtonY + buttonHeight then
                -- Add the clicked denomination value to the total change input
                changeInput = changeInput + value
            end
        end
    end
end

-- Handle text input when the cash register is open
function love.textinput(t)
    -- Not needed now since we use buttons for change input
end
