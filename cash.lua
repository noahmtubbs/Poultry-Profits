-- cash.lua

-- Cash Register Module

-- Cash Register functions
local cashRegisterOpen = false
local changeInput = 0
local saleConfirmation = ""
local showConfirmation = false
local confirmationTimer = 0
local confirmationDuration = 2
local coinButtons = {1, 5, 10, 20, 40}
local billButtons = {50, 100, 200, 500, 1000}
local buttonX, buttonY = 130, 340
local buttonWidth, buttonHeight = 60, 60 -- Increase the size of the buttons
local currentCustomer = nil
local currentEggDemand = 0

-- Coin images (scaled to fit buttons)
local coinImages = {
    love.graphics.newImage("assets/1kenya.png"),
    love.graphics.newImage("assets/5kenya.png"),
    love.graphics.newImage("assets/10kenya.png"),
    love.graphics.newImage("assets/20kenya.png"),
    love.graphics.newImage("assets/40kenya.png")
}

-- Bill images (scaled to fit buttons)
local billImages = {
    love.graphics.newImage("assets/50kenya.png"),
    love.graphics.newImage("assets/100kenya.png"),
    love.graphics.newImage("assets/200kenya.png"),
    love.graphics.newImage("assets/500kenya.png"),
    love.graphics.newImage("assets/1000kenya.png")
}

-- Button definitions
local buttons = {
    {
        text = "Give Change!",
        x = 150,
        y = 520,
        width = 200,
        height = 50,
        onClick = function()
            local totalPrice = currentEggDemand * _G.eggPrice
            local changeToGive = currentCustomer.moneyPaid - totalPrice

            if changeInput == changeToGive then
                saleConfirmation = "Correct change given! Sale successful."
                showConfirmation = true
                confirmationTimer = confirmationDuration

                -- Update player stats
                _G.money = _G.money + totalPrice
                _G.totalEggsInMarket = _G.totalEggsInMarket - currentCustomer.needs
                customersServed = customersServed + 1

                -- Remove customer
                for i = #_G.customers, 1, -1 do
                    if _G.customers[i] == currentCustomer then
                        removeCustomer(i)
                        break
                    end
                end

                spawnNextCustomer()
                currentCustomer = nil
                closeCashRegister()
            else
                saleConfirmation = "Incorrect change! Try again."
                showConfirmation = true
                confirmationTimer = confirmationDuration
            end
        end
    },
    {
        text = "Clear Selection",
        x = 600,
        y = 520,
        width = 200,
        height = 50,
        onClick = function()
            changeInput = 0 -- Reset the change input
        end
    }
}

function openCashRegister(customer)
    cashRegisterOpen = true
    currentCustomer = customer
    currentEggDemand = customer.needs
    customer.moneyPaid = getNearestKSHDenomination(currentEggDemand * _G.eggPrice)
    changeInput = 0 -- Reset change input when opening the cash register
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
            saleConfirmation = ""  -- Reset the confirmation message after it disappears
            
            -- Close the register and remove customer after confirmation is finished
            if closeRegisterAfterConfirmation then
                closeCashRegister()
                removeCurrentCustomer()
                spawnNextCustomer()
                closeRegisterAfterConfirmation = false
            end
        end
    end
end




function drawCashRegister()
    if cashRegisterOpen and currentCustomer then
           -- Cash register background with rounded corners and subtle shadow
           love.graphics.setColor(0.95, 0.95, 0.95)  -- Soft background color
           love.graphics.rectangle("fill", 50, 50, 900, 700, 30)  -- Rounded corners
           love.graphics.setColor(0.3, 0.3, 0.3)  -- Dark border color
           love.graphics.rectangle("line", 50, 50, 900, 700, 30)  -- Dark border with rounded edges
   
           -- Header
           love.graphics.setFont(love.graphics.newFont(30))
           love.graphics.setColor(0, 0, 0)  -- Black text
           love.graphics.print("Cash Register", 400, 80)

           -- Instruction
           love.graphics.setFont(love.graphics.newFont(23))
           love.graphics.print("Use the mouse to", 500, 150)
           love.graphics.print("give correct change!", 500, 170)
   
           -- Customer info and pricing (with added spacing and readability)
           love.graphics.setFont(love.graphics.newFont(18))
           love.graphics.print("Eggs ordered: " .. currentEggDemand .. " eggs", 100, 120)
           love.graphics.print("Price per egg: KSH " .. _G.eggPrice, 100, 140)
           local totalPrice = currentEggDemand * _G.eggPrice
           love.graphics.print("Total: KSH " .. totalPrice, 100, 160)
           love.graphics.print("Customer pays: KSH " .. currentCustomer.moneyPaid, 100, 180)
           love.graphics.print("Change given back: KSH " .. changeInput, 100, 210)

        -- Draw coins in a more visible X shape with increased spacing
        local coinOffsetX = 100
        local coinOffsetY = 275 -- Raised coins up
        local coinSpacingX = 75 -- Increased horizontal space between coins
        local coinSpacingY = 75 -- Vertical space for stacking coins
        local coinScale = 0.12 -- Slightly smaller coins

        -- Top row (1 KSH and 5 KSH)
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(coinImages[1], coinOffsetX, coinOffsetY, 0, coinScale, coinScale)
        love.graphics.draw(coinImages[2], coinOffsetX + coinSpacingX, coinOffsetY, 0, coinScale, coinScale)

        -- Middle row (10 KSH centered)
        love.graphics.draw(coinImages[3], coinOffsetX + coinSpacingX / 2, coinOffsetY + coinSpacingY, 0, coinScale, coinScale)

        -- Bottom row (20 KSH and 40 KSH)
        love.graphics.draw(coinImages[4], coinOffsetX, coinOffsetY + 2 * coinSpacingY, 0, coinScale, coinScale)
        love.graphics.draw(coinImages[5], coinOffsetX + coinSpacingX, coinOffsetY + 2 * coinSpacingY, 0, coinScale, coinScale)

        -- Draw bills horizontally next to each other with more spacing on the right side
        local billX = 350
        local billY = 275 -- Raised bills up
        local billSpacing = 100 -- Increased space between bills
        local billScale = 0.30 -- Slightly smaller bills
        local rotationAngle = math.pi / 2

       -- Draw each bill with consistent scale and rotation
       for i, bill in ipairs(billImages) do
        love.graphics.setColor(1, 1, 1)
        
        -- Adjust the position for rotation
        local billWidth = bill:getWidth() * billScale
        local billHeight = bill:getHeight() * billScale
        
        -- Draw each bill, rotating around its center
        love.graphics.draw(bill, billX + billWidth / 2, billY + billHeight / 2, rotationAngle, billScale, billScale, billWidth / 2, billHeight / 2)
        billX = billX + billSpacing  -- Position each bill next to the previous one
    end

 -- Draw buttons with custom colors and borders
    for _, button in ipairs(buttons) do
    -- Set background color based on button text
    if button.text == "Enter Selection" then
        love.graphics.setColor(0.6, 0.9, 0.6) -- Light green for "Enter Selection"
    elseif button.text == "Clear Selection" then
        love.graphics.setColor(0.96, 0.96, 0.86) -- Light beige for "Clear Selection"
    else
        love.graphics.setColor(1, 1, 1) -- Default white for other buttons
    end
    
    -- Draw button background
    love.graphics.rectangle("fill", button.x, button.y, button.width, button.height)

    -- Draw button border
    love.graphics.setColor(0, 0, 0) -- Black border
    love.graphics.rectangle("line", button.x, button.y, button.width, button.height)

    -- Draw button text
    love.graphics.setColor(0, 0, 0) -- Black text
    love.graphics.printf(button.text, button.x, button.y + button.height / 4, button.width, "center")
end



    -- Confirmation message
    if showConfirmation then
        love.graphics.setColor(0.8, 1, 0.8)
        love.graphics.rectangle("fill", 200, 600, 500, 50)
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", 200, 600, 500, 50)
        love.graphics.print(saleConfirmation, 220, 620)
    end
end
end



function handleCashRegisterKeypress(key)
    if cashRegisterOpen then
        if key == "return" then
            local totalPrice = currentEggDemand * _G.eggPrice
            local changeToGive = currentCustomer.moneyPaid - totalPrice
            
            if changeInput == changeToGive then
                saleConfirmation = "Correct change given! Sale successful."
                showConfirmation = true
                confirmationTimer = confirmationDuration
                
                -- Update player stats and finalize sale
                _G.money = _G.money + totalPrice
                _G.totalEggsInMarket = _G.totalEggsInMarket - currentCustomer.needs
                customersServed = customersServed + 1
                
                -- Remove the current customer
                for i = #_G.customers, 1, -1 do
                    if _G.customers[i] == currentCustomer then
                        removeCustomer(i)
                        break
                    end
                end
                
                spawnNextCustomer()
                currentCustomer = nil
                closeCashRegister()
            else
                saleConfirmation = "Incorrect change! Try again."
                showConfirmation = true
                confirmationTimer = confirmationDuration
            end
        elseif key == "escape" then
            saleConfirmation = "Sale cancelled."
            showConfirmation = true
            confirmationTimer = confirmationDuration
            closeCashRegister()
        end
    end
end





function handleCashRegisterMouse(x, y)
    if cashRegisterOpen then
        -- Coin image click detection
        local coinOffsetX = 100
        local coinOffsetY = 275
        local coinSpacingX = 75
        local coinSpacingY = 75
        local coinScale = 0.12

        -- Check for clicks on the top row
        for i = 1, 2 do
            local coin = coinImages[i]
            local coinWidth, coinHeight = coin:getDimensions()
            local scaledCoinWidth = coinWidth * coinScale
            local scaledCoinHeight = coinHeight * coinScale
            local coinX = coinOffsetX + (i - 1) * coinSpacingX
            local coinY = coinOffsetY

            if x >= coinX and x <= coinX + scaledCoinWidth and y >= coinY and y <= coinY + scaledCoinHeight then
                changeInput = changeInput + coinButtons[i]
            end
        end

        -- Middle coin click detection
        local middleCoin = coinImages[3]
        local middleCoinWidth, middleCoinHeight = middleCoin:getDimensions()
        local scaledMiddleCoinWidth = middleCoinWidth * coinScale
        local scaledMiddleCoinHeight = middleCoinHeight * coinScale
        local middleCoinX = coinOffsetX + coinSpacingX / 2
        local middleCoinY = coinOffsetY + coinSpacingY

        if x >= middleCoinX and x <= middleCoinX + scaledMiddleCoinWidth and y >= middleCoinY and y <= middleCoinY + scaledMiddleCoinHeight then
            changeInput = changeInput + coinButtons[3]
        end

        -- Bottom row coins
        for i = 4, 5 do
            local coin = coinImages[i]
            local coinWidth, coinHeight = coin:getDimensions()
            local scaledCoinWidth = coinWidth * coinScale
            local scaledCoinHeight = coinHeight * coinScale
            local coinX = coinOffsetX + (i - 4) * coinSpacingX
            local coinY = coinOffsetY + 2 * coinSpacingY

            if x >= coinX and x <= coinX + scaledCoinWidth and y >= coinY and y <= coinY + scaledCoinHeight then
                changeInput = changeInput + coinButtons[i]
            end
        end

        -- Bill image click detection
        local billX = 350
        local billY = 325
        local billSpacing = 100
        local rotationAngle = math.pi / 2

        for i, bill in ipairs(billImages) do
            local billWidth, billHeight = bill:getDimensions()
            local scaledBillWidth = billWidth * 0.30
            local scaledBillHeight = billHeight * 0.30
            local centerX = billX + scaledBillWidth / 2
            local centerY = billY + scaledBillHeight / 2

            local dx = x - centerX
            local dy = y - centerY
            local rotatedX = dx * math.cos(rotationAngle) - dy * math.sin(rotationAngle)
            local rotatedY = dx * math.sin(rotationAngle) + dy * math.cos(rotationAngle)
            local halfScaledBillWidth = scaledBillWidth / 2
            local halfScaledBillHeight = scaledBillHeight / 2

            if rotatedX >= -halfScaledBillWidth and rotatedX <= halfScaledBillWidth and rotatedY >= -halfScaledBillHeight and rotatedY <= halfScaledBillHeight then
                changeInput = changeInput + billButtons[i]
            end

            billX = billX + billSpacing
        end

        -- Button click detection
        for _, button in ipairs(buttons) do
            if x >= button.x and x <= button.x + button.width and y >= button.y and y <= button.y + button.height then
                button.onClick()
            end
        end
    end
end

-- Helper function to get nearest KSH denomination
function getNearestKSHDenomination(totalPrice)
    local denominations = {1, 5, 10, 20, 40, 50, 100, 200, 500, 1000}
    for _, denomination in ipairs(denominations) do
        if totalPrice <= denomination then
            return denomination
        end
    end
    return denominations[#denominations]
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
