-- LOVE callback definitions

player = require "playerModel"
tileModel = require "tileModel"

function love.load()
    -- Window stuff
    love.window.setTitle("/fredric/")
    love.graphics.setNewFont(12)

    -- love.graphics.setColor(0,0,0)
    love.graphics.setBackgroundColor(150/255,90/255,0/255)

    -- Loading spritesheet
    spritesheet = love.graphics.newImage("spritesheet.png")
    -- Use crisper filter for resizing
    spritesheet:setFilter('nearest', 'nearest')
    
    -- Map from 0-based i, j indices to sprite cell on spritesheet
    sheetCell = function(i, j) return love.graphics.newQuad(32*j, 32*i, 32, 32, spritesheet:getWidth(), spritesheet:getHeight()) end

    -- Build new tile
    t1 = tileModel.newTile(200, 200, 32, 32)
end

function love.draw()
    -- love.graphics.print("Placeholder", quad, 50, 50)
    love.graphics.draw(spritesheet, sheetCell(0, 0), player.x, player.y)
    -- Draw floor
    love.graphics.draw(spritesheet, sheetCell(1, 0), t1.getx(), t1.gety())
end

function love.update()
    -- Resolve gravity on player (acc and velocity)
    player.grav()
    -- Check to see if in ground
    player.checkGroundCollision()
    if love.keyboard.isDown("up") then
        player.jump()
    end
    if love.keyboard.isDown("left") then
        player.left()
    end
    if love.keyboard.isDown("right") then
        player.right()
    end
end

-- Controller
function love.keypressed(key, scancode, isrepeat)
    -- if key == "up" then
    --     player.jump()
    -- elseif key == "left" then
    --     player.left()
    -- end
    -- print(key)
end