-- level2.lua

return {
    -- Chickens are present and inherit from Level 1
    chickens = {
        {x = 600, y = 400},
        {x = 800, y = 200},
        {x = 700, y = 300},
        {x = 750, y = 450}
        {x = 850, y = 450}
    },
    -- Initial Money
    initialMoney = 400,
    -- Initial Weather (Winter is active)
    weather = 'winter',
    -- Level Objective
    objective = function()
        return money >= 1400
    end,
    -- Predators are not active in Level 2
    predatorsActive = false
}
