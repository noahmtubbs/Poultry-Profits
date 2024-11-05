-- level1.lua

return {
    -- Chickens are present but no predators will attack
    chickens = {
        {x = 500, y = 300},
        {x = 650, y = 250},
        {x = 700, y = 350},
        {x = 800, y = 400},
        {x = 850, y = 450}
    },
    -- Initial Money
    initialMoney = 0,
    -- Initial Weather (No winter)
    weather = 'sunny', -- Options: 'sunny', 'rainy', 'stormy'
    -- Level Objective
    objective = function()
        return money >= 400
    end,
    -- Predators are not active in Level 1
    predatorsActive = false
}
