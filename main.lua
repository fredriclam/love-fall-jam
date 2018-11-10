
-- Player model
Player = {}
function Player:new()
    x = 300
    y = 0
    dx = 2
    inAir = false
    -- setmetatable(self)
    -- self.__index = self
end

function Player.jump(self)
    if (not inAir) then
        y = 1
    end
end
function Player.left(self)
    x = x - dx
end
function Player.right(self)
    x = x + dx
end

function love.load()
    love.window.setTitle("/fredric/")
    image = love.graphics.newImage("monkas.png")
    -- image:setFilter('nearest', 'nearest')
    love.graphics.setNewFont(12)
    -- love.graphics.setColor(0,0,0)
    love.graphics.setBackgroundColor(240,55,0)
    -- Instantiate player
    player = Player:new()
    -- Image mask
    quad = love.graphics.newQuad(100, 100, 164, 164, image:getWidth(), image:getHeight())
end
 

function love.draw()
    -- love.graphics.print("Placeholder", quad, 50, 50)
    love.graphics.draw(image, quad, x, 200)
end

function love.update()
    if love.keyboard.isDown("up") then
        Player.jump()
    end
    if love.keyboard.isDown("left") then
        Player.left()
    end
    if love.keyboard.isDown("right") then
        Player.right()
    end
end

-- Controller
function love.keypressed(key, scancode, isrepeat)
    -- if key == "up" then
    --     Player.jump()
    -- elseif key == "left" then
    --     Player.left()
    -- end
    -- print(key)
end