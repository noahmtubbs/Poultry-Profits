-- level2.lua

return {
    chickens = {
        {x = 500, y = 300},
        {x = 650, y = 250},
        {x = 700, y = 350},
        {x = 800, y = 400},
        {x = 850, y = 450} -- 新增的鸡
    },
    initialMoney = 100,
    weather = 'rainy',
    objective = function()
        return money >= 1000
    end
}
