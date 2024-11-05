Customer = {}
Customer.__index = Customer

function Customer:new(eggPrice)
    local customer = {
        eggsToBuy = math.random(1, 10), -- Random egg quantity between 1 and 10
        moneyPaid = 0,
        x = love.graphics.getWidth(),
        y = love.graphics.getHeight() / 2,
        isWalking = true,
        eggPrice = eggPrice or 20 -- 确保 eggPrice 始终有一个默认值
    }
    setmetatable(customer, Customer)
    return customer
end

function Customer:update(dt)
    if self.isWalking then
        self.x = self.x - 100 * dt
        if self.x < 300 then
            self.isWalking = false
            self.moneyPaid = getNearestKSHDenomination(self.eggsToBuy * self.eggPrice)
        end
    end
end

function Customer:draw()
    love.graphics.setColor(0, 0, 1)
    love.graphics.rectangle("fill", self.x, self.y, 20, 20)
end

function getNearestKSHDenomination(totalPrice)
    local denominations = {1, 5, 10, 20, 40, 50, 100, 200, 500, 1000}
    for _, denomination in ipairs(denominations) do
        if totalPrice <= denomination then
            return denomination
        end
    end
    return denominations[#denominations]
end

-- Global variables for current customer and their egg demand
local currentCustomer = nil
local currentEggDemand = 0

-- Cash Register functions
local cashRegisterOpen = false
local changeInput = 0
local saleConfirmation = ""
local showConfirmation = false
local confirmationTimer = 0
local confirmationDuration = 2 -- Duration in seconds
local changeButtons = {1, 5, 10, 20, 40, 50, 100}
local buttonX, buttonY = 130, 340
local buttonWidth, buttonHeight = 50, 30

function openCashRegister(customer)
    cashRegisterOpen = true
    currentCustomer = customer
    currentEggDemand = customer.needs -- Set egg demand for cash register
    customer.moneyPaid = getNearestKSHDenomination(currentEggDemand * eggPrice)
end

function closeCashRegister()
    cashRegisterOpen = false
    currentCustomer = nil
    currentEggDemand = 0
    changeInput = 0
    showConfirmation = false
end

function isCashRegisterOpen()
    return cashRegisterOpen
end

function updateCashRegister(dt)
    if showConfirmation then
        confirmationTimer = confirmationTimer - dt
        if confirmationTimer <= 0 then
            showConfirmation = false
            saleConfirmation = ""
        end
    end
end

function drawCashRegister()
    if cashRegisterOpen and currentCustomer then
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.rectangle("fill", 100, 100, 500, 400) -- Widened window width to 500
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", 100, 100, 500, 400)

        love.graphics.print("Cash Register", 250, 120)
        
        -- Use global `currentEggDemand` instead of `currentCustomer.eggsToBuy`
        local totalPrice = currentEggDemand * eggPrice
        love.graphics.print("Customer wants to buy " .. currentEggDemand .. " eggs.", 130, 150)
        love.graphics.print("Price per egg: KSH " .. eggPrice, 130, 180)
        love.graphics.print("Total: KSH " .. totalPrice, 130, 220)
        love.graphics.print("Customer pays: KSH " .. currentCustomer.moneyPaid, 130, 250)

        local changeToGive = currentCustomer.moneyPaid - totalPrice
        love.graphics.print("Change to give: KSH " .. changeToGive, 130, 280)
        love.graphics.print("Change given back: KSH " .. changeInput, 130, 310)

        -- Draw change buttons
        for i, value in ipairs(changeButtons) do
            local x = buttonX + (i - 1) * (buttonWidth + 10)
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.rectangle("fill", x, buttonY, buttonWidth, buttonHeight)
            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("line", x, buttonY, buttonWidth, buttonHeight)
            love.graphics.printf(value .. " KSH", x, buttonY + 5, buttonWidth, "center")
        end

        love.graphics.print("Press 'Enter' to finalize sale, or 'Esc' to cancel", 130, 400)

        if showConfirmation then
            love.graphics.setColor(0.8, 1, 0.8)
            love.graphics.rectangle("fill", 150, 450, 300, 50)
            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("line", 150, 450, 300, 50)
            love.graphics.print(saleConfirmation, 200, 470)
        end
    end
end

function handleCashRegisterKeypress(key)
    if cashRegisterOpen then
        if key == "return" then
            local totalPrice = currentEggDemand * eggPrice
            local changeToGive = currentCustomer.moneyPaid - totalPrice
            if changeInput == changeToGive then
                saleConfirmation = "Correct change given!"
                money = money + totalPrice
                totalEggsInMarket = totalEggsInMarket - currentCustomer.needs

                -- Find and remove the current customer from the queue
                for i = #customers, 1, -1 do
                    if customers[i] == currentCustomer then
                        table.remove(customers, i)
                        table.remove(customerNeeds, i)
                        table.remove(customerTimers, i)
                        break
                    end
                end
                
                -- Shift remaining customers forward in line
                local startX = marketplace.x - customerWidth - 50
                for j, customer in ipairs(customers) do
                    customer.x = startX - (j - 1) * (customerWidth + 30)
                end

                -- Clear the current customer reference
                currentCustomer = nil

                -- Close the cash register window after the sale
                closeCashRegister()

            else
                saleConfirmation = "Incorrect change!"
            end
            showConfirmation = true
            confirmationTimer = confirmationDuration
        elseif key == "escape" then
            closeCashRegister() -- Cancel transaction and close the window
        end
    end
end





function handleCashRegisterMouse(x, y)
    if cashRegisterOpen then
        for i, value in ipairs(changeButtons) do
            local bx = buttonX + (i - 1) * (buttonWidth + 10)
            if x >= bx and x <= bx + buttonWidth and y >= buttonY and y <= buttonY + buttonHeight then
                changeInput = changeInput + value
            end
        end
    end
end

-- Update market function with customer interaction logic
function updateMarket(dt)
    if isInPickupRange(player, marketplace) then
        marketplace.color = {0, 1, 0}
    else
        marketplace.color = {0, 0, 1}
    end

    -- Iterate over customers and update interaction and timers
    for i, customer in ipairs(customers) do
        customerTimers[i] = customerTimers[i] - dt
        if customerTimers[i] <= 0 then
            table.remove(customers, i)
            table.remove(customerNeeds, i)
            table.remove(customerTimers, i)
        elseif isInPickupRange(player, customer) then
            if totalEggsInMarket >= customer.needs then
                customer.color = {0, 1, 0} -- Green indicates ready to interact
            else
                customer.color = {1, 0, 0} -- Red indicates insufficient eggs
            end
        else
            customer.color = {0, 0, 1} -- Blue indicates out of range
        end
    end
end


return {
    openCashRegister = openCashRegister,
    closeCashRegister = closeCashRegister,
    isCashRegisterOpen = isCashRegisterOpen,
    updateCashRegister = updateCashRegister,
    drawCashRegister = drawCashRegister,
    handleCashRegisterKeypress = handleCashRegisterKeypress,
    handleCashRegisterMouse = handleCashRegisterMouse
}