-- level3.lua

return {
    chickens = {
        {x = 550, y = 320},
        {x = 700, y = 280},
        {x = 750, y = 360},
        {x = 800, y = 420},
        {x = 850, y = 480},
        {x = 900, y = 500} -- 新增的鸡
    },
    initialMoney = 200,
    weather = 'stormy',
    objective = function()
        return money >= 2000
    end
}
