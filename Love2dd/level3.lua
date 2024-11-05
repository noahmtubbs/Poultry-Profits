-- level3.lua

return {
    -- Chickens are present and more are added
    chickens = {
        {x = 500, y = 300},
        {x = 650, y = 250},
        {x = 700, y = 350},
        {x = 800, y = 400},
        {x = 850, y = 450} -- New chicken
    },
    -- Initial Money
    initialMoney = 1400,
    -- Initial Weather (Winter is active)
    weather = 'winter',
    -- Level Objective
    objective = function()
        return money >= 99999 -- Adjust as needed for Level 3
    end,
    -- Predators are active in Level 3
    predatorsActive = true
}
