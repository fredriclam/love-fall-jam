-- LOVE callback definitions

playerModel = require "playerModel"
tileModel = require "tileModel"
bgTiles = require "backgroundTileMap"
fgTiles = require "foregroundTileMap"

-- Globals
tileCountHorizontal = 24
tileCountVertical = 18

-- Key bindings
local keySets = {
    -- Player 1 key bindings
    {
        up = "w",
        down = "s",
        left = "a",
        right = "d",
        shoot = "e"
    },
    -- Player 2 key bindings
    {
        up = "up",
        down = "down",
        left = "left",
        right = "right",
        shoot = "/"
    },
}


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
    sheetCellHalfSize = function(headingLeft, id, j)
        i = 2 -- Row where first player data is located
        if headingLeft then -- Shift down for left-facing textures
            i = i + 1
        end
        if id == 2 then -- Shift down for second player
            i = i + 2
        end
        return love.graphics.newQuad(32*j, 32*i, 16, 32,
                                     spritesheet:getWidth(), spritesheet:getHeight())
    end

    -- Load models for background tile map only
    collisionList = {}
    for i = 1, tileCountVertical-5 do -- Ignore last 5 rows (optimization)
        for j = 1, tileCountHorizontal do
            if bgTiles[i][j] >= 1 and bgTiles[i][j] ~= 4 then
                -- Push a tile model onto list
                table.insert(collisionList, tileModel.newTile(32*(j-1), 32*(i-1), 32, 32))
            end
        end
    end

    -- Load audio sources into table
    sounds = {
        jump = love.audio.newSource("jump.wav", "static"),
        beams = {
            love.audio.newSource("beam1.wav", "static"),
            love.audio.newSource("beam2.wav", "static"),
        },
        beamRed = love.audio.newSource("beam2.wav", "static"),
        victory = love.audio.newSource("victory.wav", "static"),
        destroy = love.audio.newSource("destroy.wav", "static"),
        bgm = love.audio.newSource("bgm.wav", "static"),
    }

    -- Init players
    players = {
        playerModel.newPlayer(1, 10*32, 10*32),
        playerModel.newPlayer(2, 12*32, 10*32),
    }
end

-- Draw foreground tiles (after player is drawn)
function drawTileMap(tileMap)
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

    -- For this draw cycle, draw at double the size (without affecting internal representation)
    -- love.graphics.scale(1.1,1.1)

    -- Draw background
    drawTileMap(bgTiles)
    -- Draw players
    for i = 1, 2 do
        love.graphics.draw(spritesheet, sheetCellHalfSize(players[i].isHeadingLeft(), players[i].getID(), players[i].getAnimState()),
                           players[i].getX(), players[i].getY(), 0.0, players[i].getSX(), players[i].getSY())
    end
    -- Draw foreground
    drawTileMap(fgTiles)
end

function love.update()
    for i = 1, 2 do
        -- Resolve gravity on player (acc and velocity), walking state
        players[i].earlyUpdate()
        -- Resolve pressed keys
        if love.keyboard.isDown(keySets[i]["up"]) then
            if players[i].jump() then
                sounds["jump"]:stop()
                sounds["jump"]:play()
            end
        end
        if love.keyboard.isDown(keySets[i]["left"]) and not love.keyboard.isDown(keySets[i]["right"]) then
            players[i].left()
        end
        if love.keyboard.isDown(keySets[i]["right"]) and not love.keyboard.isDown(keySets[i]["left"]) then
            players[i].right()
        end
        if love.keyboard.isDown(keySets[i]["shoot"]) then
            if players[i].executeAttack() then
                sounds["beams"][i]:stop()
                sounds["beams"][i]:play()
            end
        end
        -- Resolve ground collision and animation state
        players[i].lateUpdate(collisionList)
    end
    
end

-- Key press controller
function love.keypressed(key, scancode, isrepeat)
    -- if key == "up" then
    --     
    -- elseif key == "left" then
    --     
    -- end
    -- print(key)
end