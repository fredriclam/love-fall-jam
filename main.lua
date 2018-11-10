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

    -- Define global map from 0-based i, j indices to 16x32 (half-size) sprites on spritesheet
    -- with custom shift for left-facing sprites.
    --   Dependent on spritesheet loading
    sheetCellHalf = function(i, j)
        if player.headingLeft then
            i = i + 1
        end
        return love.graphics.newQuad(16*j, 32*i,
        16, 32, spritesheet:getWidth(), spritesheet:getHeight())
    end

    
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

-- Draw animated player
function playerDraw()
    -- Draw player
    love.graphics.draw(spritesheet, sheetCellHalf(2, player.animState), player.x, player.y, 0.0, player.sx, player.sy)
end

function love.draw()
    -- love.graphics.print("Placeholder", quad, 50, 50)

    -- For this draw cycle, draw at double the size (without affecting internal representation)
    -- love.graphics.scale(1.1,1.1)

    -- Draw player
    playerDraw()
    -- Draw foreground
    tileDrawForeground()
end

function love.update()
    -- Resolve gravity on player (acc and velocity), walking state
    player.earlyUpdate()
    
    -- Resolve pressed keys
    if love.keyboard.isDown("up") then
        player.jump()
    end
    if love.keyboard.isDown("left") and not love.keyboard.isDown("right") then
        player.left()
    end
    if love.keyboard.isDown("right") and not love.keyboard.isDown("left") then
        player.right()
    end
    if love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then
        player.executeAttack()
    end
    -- Resolve ground collision and animation state
    player.lateUpdate()
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