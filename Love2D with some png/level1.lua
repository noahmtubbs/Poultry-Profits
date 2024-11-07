-- level1.lua

return {
    chickens = {
        {x = 600, y = 300},
        {x = 650, y = 250},
        {x = 700, y = 350},
        {x = 750, y = 400}
    },
    initialMoney = 0,
    weather = 'sunny',
    objective = function()
        return money >= 400
    end,
    predatorsActive = false
}
