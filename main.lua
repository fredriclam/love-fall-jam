-- LOVE callback definitions

playerModel = require "playerModel"

function love.load()
    -- Window stuff
    love.window.setTitle("/fredric/")
    love.graphics.setNewFont(12)

    -- love.graphics.setColor(0,0,0)
    love.graphics.setBackgroundColor(150/255,90/255,0/255)
    -- Instantiate player model
    player = playerModel:new()

    -- Loading spritesheet
    spritesheet = love.graphics.newImage("spritesheet.png")
    -- Use crisper filter for resizing
    spritesheet:setFilter('nearest', 'nearest')
    
    -- Map from index to sprite cell
    sheetCell = function(n) return love.graphics.newQuad(32*n, 0, 32, 32, spritesheet:getWidth(), spritesheet:getHeight()) end
end

function love.draw()
    -- love.graphics.print("Placeholder", quad, 50, 50)
    love.graphics.draw(spritesheet, sheetCell(1), x, y)
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