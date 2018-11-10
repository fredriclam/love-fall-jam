-- LOVE callback definitions

playerModel = require "playerModel"

function love.load()
    love.window.setTitle("/fredric/")
    image = love.graphics.newImage("monkas.png")
    -- image:setFilter('nearest', 'nearest')
    love.graphics.setNewFont(12)
    -- love.graphics.setColor(0,0,0)
    love.graphics.setBackgroundColor(50/255,30/255,0/255)
    -- Instantiate player
    player = playerModel:new()
    -- Image mask
    quad = love.graphics.newQuad(100, 100, 164, 164, image:getWidth(), image:getHeight())
end
 

function love.draw()
    -- love.graphics.print("Placeholder", quad, 50, 50)
    love.graphics.draw(image, quad, x, y)
end

function love.update()
    -- Resolve gravity on player (acc and velocity)
    playerModel.grav()
    -- Check to see if in ground
    playerModel.checkGroundCollision()

    if love.keyboard.isDown("up") then
        playerModel.jump()
    end
    if love.keyboard.isDown("left") then
        playerModel.left()
    end
    if love.keyboard.isDown("right") then
        playerModel.right()
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