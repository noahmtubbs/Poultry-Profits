-- level1.lua

return {
    -- 鸡的初始位置
    chickens = {
        {x = 600, y = 400},
        {x = 800, y = 200},
        {x = 700, y = 300},
        {x = 750, y = 450}
    },
    -- 初始金钱
    initialMoney = 0,
    -- 初始天气
    weather = 'sunny',
    -- 关卡目标
    objective = function()
        return money >= 400
    end
}
