-- level3.lua

return {
    chickens = {
        {x = 600, y = 300},
        {x = 650, y = 250},
        {x = 700, y = 350},
        {x = 750, y = 400},
        {x = 800, y = 450}
    },
    initialMoney = 1400,
    weather = 'winter',
    objective = function()
        return money >= 2200
    end,
    predatorsActive = true
}
