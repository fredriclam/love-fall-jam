-- LOVE callback definitions

player = require "playerModel"
tileModel = require "tileModel"
tileMap = require "tileMap"

-- Globals
tileCountHorizontal = 24
tileCountVertical = 18

function love.load()
    -- Window stuff after load
    -- love.window.setTitle("/fredric/")
    -- love.window.setMode(24*32, 18*32)
    

    -- Colour mask
    -- love.graphics.setColor(0,0,0)
    love.graphics.setNewFont(12)
    love.graphics.setBackgroundColor(55/255,155/255,0/255)
    -- Deep purple
    -- love.graphics.setBackgroundColor(18/255,3/255,41/255)

    -- Loading spritesheet
    spritesheet = love.graphics.newImage("spritesheet.png")
    -- Use crisper filter for resizing
    spritesheet:setFilter('nearest', 'nearest')
    
    -- Define global map from 0-based i, j indices to sprite cell on spritesheet
    --   Dependent on spritesheet loading
    sheetCell = function(i, j) return love.graphics.newQuad(32*j, 32*i,
        32, 32, spritesheet:getWidth(), spritesheet:getHeight()) end
end

-- Draw foreground tiles (after player is drawn)
function tileDrawForeground()
    local globalOffsetX = 0
    local globalOffsetY = 0
    local tileX = 32
    local tileY = 32
    for i = 1, tileCountVertical do
        for j = 1, tileCountHorizontal do
            -- Assume tile textures on row "1"
            love.graphics.draw(spritesheet, sheetCell(1, tileMap[i][j]),
                globalOffsetX + (j-1)*tileX, globalOffsetY + (i-1)*tileY)
        end
    end
end

function love.draw()
    -- love.graphics.print("Placeholder", quad, 50, 50)

    -- Draw player
    love.graphics.draw(spritesheet, sheetCell(0, 0), player.x, player.y)
    -- Draw foreground
    tileDrawForeground()
end

function love.update()
    -- Resolve gravity on player (acc and velocity)
    player.grav()
    if love.keyboard.isDown("up") then
        player.jump()
    end
    if love.keyboard.isDown("left") then
        player.left()
    end
    if love.keyboard.isDown("right") then
        player.right()
    end
    -- Check to see if in ground
    player.checkGroundCollision()
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