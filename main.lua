-- LOVE callback definitions

playerModel = require "playerModel"
tileModel = require "tileModel"
bgTiles = require "backgroundTileMap"
fgTiles = require "foregroundTileMap"
mobModel = require "mobModel"
projectileModel = require "projectileModel"

-- Shared constants
local tileCountHorizontal = 24  -- Num tiles horizontally in window
local tileCountVertical = 18    -- Num tiles vertically in window
local screenHeight = tileCountVertical*32
local screenWidth = tileCountHorizontal*32

local globalLevel = 1                     -- Level of the global stage
local mobMaxCount = 10                    -- Max number of mobs
local currentSpawnChance = 0              -- Initial spawn chance (increases every failed spawn)
local spawnTimer = 0                      -- Spawn timer (s)
local defaultSpawnCheckInterval = 1.0     -- Seconds
local defaultSpawnChanceIncrement = 0.1   -- Increments of spawn chance at level 1
local mobCount = 0                        -- Current number of mobs
local mobsDefeated = 0                    -- Number of mobs defeated in total
local previousDefeated = 0                -- Secondary counter for mobs defeated in previous levels

-- Game state enumeration
local gameStates = {
    ready = 0,
    playing = 1,
    lose = 2,
    win = 3,
}
-- Current global game state
local currentGameState = gameStates["playing"]
-- Global timers
local loseTimer = 0                    -- Decumulates after losing
-- Graphical
local headAdjustment = 11           -- Number of pixels to translate downward due to headAdjustment
local backgroundScale = 2.0         -- Isotropic scaling for background texture
local backgroundShiftStep = 50      -- Number of pixels to advance background by per level
local backgroundDepth = 0           -- Current background depth
local backgroundAdjustRate = 0.05
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
-- Progress requirements
local levelObjectives = { -- Number of mobs needed to advance level
    6,
    6,
    8,
    8,
    12, -- 5
    14,
    14, -- 7
}


function love.load()
    -- Window stuff after load
    -- love.window.setTitle("/fredric/")
    -- love.window.setMode(24*32, 18*32)
    
    -- Colour mask
    -- love.graphics.setColor(0,0,0)
    love.graphics.setNewFont(18)
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
    findPlayerSprite = function(headingLeft, id, j)
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

    -- Define global map from 0-based i, j indices to 16x16 sprites on spritesheet
    --   Dependent on spritesheet loading
    findMobSprite = function(type, state)
        -- Compute y to start at, with shift for red/blue flavour
        local y = 6*32 + 16*(type["flavour"]-1)
        local x = 0
        if type["level"] == 1 then
            -- Default to x = 0
        elseif type["level"] == 2 then -- Animated level 2 mobs
            x = 16*(state+1) -- 0-indexed state assumed
        elseif type["level"] == 3 then
            x = 3*16+(state+1) -- 0-indexed state assumed
        end

        return love.graphics.newQuad(x, y, 16, 16,
                                     spritesheet:getWidth(), spritesheet:getHeight())
    end

    -- Define global map from 0-based i, j indices to 8x8 sprites on spritesheet
    --   Dependent on spritesheet loading
    findProjectileSprite = function(ID, facingLeft)
        local x = 0
        local y = (ID-1)*16
        if facingLeft then
            y = y + 8
        end
        return love.graphics.newQuad(x, y, 8, 8,
                                     spritesheet:getWidth(), spritesheet:getHeight())        
    end

    findBackground = function(depth, jitter)
        local x = jitter + 0.5*(spritesheet:getWidth() - screenWidth/backgroundScale) -- Location if sample from centre of BG texture
        local y = 7*32 + depth
        return love.graphics.newQuad(x, y, screenWidth/backgroundScale, screenHeight/backgroundScale,
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
        defeat = love.audio.newSource("defeat.wav", "static"),
    }

    -- Init players
    players = {
        playerModel.newPlayer(1, 10*32, 10*32),
        playerModel.newPlayer(2, 12*32, 10*32),
    }
    sounds["bgm"]:setLooping(true)
    sounds["bgm"]:play()

    -- Init mob list
    mobList = {}
    projectilesList = {}
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
    -- For this draw cycle, draw at double the size (without affecting internal representation)
    -- love.graphics.scale(2,2)

    -- Draw background in all states
    targetDepth = globalLevel * backgroundShiftStep
    if backgroundDepth ~= targetDepth then -- Proportional approach to depth
        backgroundDepth = backgroundDepth + backgroundAdjustRate*(targetDepth - backgroundDepth)
    end
    local jitter = 0
    love.graphics.draw(spritesheet, findBackground(backgroundDepth, jitter), 0, 0, 0.0, backgroundScale, backgroundScale)

    -- Shared tasks
    if currentGameState == gameStates["playing"]  or currentGameState == gameStates["lose"] then
        -- Draw background
        drawTileMap(bgTiles)
        -- Print instructions on screen (background layer)
        if globalLevel == 1 then
            love.graphics.printf("SURVIVE", 0.*screenWidth, 0.2*screenHeight, screenWidth, "center")
            love.graphics.printf("WASD + E", 0.*screenWidth, 0.25*screenHeight, 2*0.35*screenWidth, "center")
            love.graphics.printf("ARROWS + /", 0.*screenWidth, 0.25*screenHeight, 2*0.7*screenWidth, "center")
        end
        -- Draw players
        for i = 1, 2 do
            love.graphics.draw(spritesheet, findPlayerSprite(players[i].isHeadingLeft(), players[i].getID(), players[i].getAnimState()),
                            players[i].getX(), players[i].getY(), 0.0, players[i].getSX(), players[i].getSY())
        end
        -- Draw mobs
        -- Move mobs
        for k, v in pairs(mobList) do
            love.graphics.draw(spritesheet, findMobSprite(v.getType(), v.getAnimState()), v.getX(), v.getY(), 
                            0.0, v.getSX(), v.getSY())
            
        end
        -- Draw foreground
        drawTileMap(fgTiles)
        -- Draw projectiles
        for k, v in pairs(projectilesList) do
            love.graphics.draw(spritesheet, findProjectileSprite(v.getSourceID(), v.isHeadingLeft()),
                    v.getX(), v.getY(), 0.0, v.getSX(), v.getSY())
        end

        -- UI: draw progress bar
        love.graphics.draw(spritesheet, love.graphics.newQuad(32, 0, 16, 16, spritesheet:getWidth(), spritesheet:getHeight()),
            0.7*screenWidth, 0.9*screenHeight, 0.0, 2, 2)

        -- 
        local barXMin = 0.75*screenWidth
        local barXMax = 0.82*screenWidth
        local barXMiniscus = mobsDefeated / levelObjectives[globalLevel] * (barXMax - barXMin) + barXMin
        love.graphics.setColor(0, 0, 0, 100)
        love.graphics.rectangle("line", barXMin, 0.9*screenHeight, barXMax-barXMin, 16)
        love.graphics.setColor(0, 1, 0, 100)
        love.graphics.rectangle("fill", barXMin, 0.9*screenHeight, barXMiniscus-barXMin, 16)
        
        
        -- UI: draw stage info
        love.graphics.draw(spritesheet, love.graphics.newQuad(48, 0, 16, 16, spritesheet:getWidth(), spritesheet:getHeight()),
            0.85*screenWidth, 0.9*screenHeight, 0.0, 2, 2)
        -- Placeholder stage text
        love.graphics.setColor(0, 0, 0, 100)
        love.graphics.printf(globalLevel, 0.*screenWidth, 0.9*screenHeight-5, 2*0.9*screenWidth, "center")

        -- UI: reset color filter
        love.graphics.setColor(1, 1, 1, 100)
    end -- playing and lose states
    if currentGameState == gameStates["lose"] then
        if loseTimer > -4 then -- Lose timer from what it's set to (>0) down to -4
            -- Print statistics
            love.graphics.setColor(93/255, 22/255, 187/255, 100)
            love.graphics.printf("You vanquished " .. previousDefeated + mobsDefeated .. " Things", 0.*screenWidth, 0.45*screenHeight, 2*0.5*screenWidth, "center")
            love.graphics.printf("Restarting...", 0.*screenWidth, 0.5*screenHeight, 2*0.5*screenWidth, "center")
            love.graphics.setColor(1, 1, 1, 100)
        else
            currentGameState = gameStates["ready"]
        end
        -- Update lose timer
        loseTimer = loseTimer - love.timer.getDelta()
    end

end

function love.update()
    -- Pausing music
    if not love.window.hasFocus then
        sounds["bgm"]:pause()
    end

    if currentGameState == gameStates["playing"] then
        -- Check for objective
        if mobsDefeated >= levelObjectives[globalLevel] then
            -- Level up
            globalLevel = globalLevel + 1
            -- Reset mobs defeated
            previousDefeated = previousDefeated + mobsDefeated
            mobsDefeated = 0
        end
        -- Update players
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
                    -- Compute spawn position
                    local x = players[i].getX()
                    if not players[i].isHeadingLeft then
                        x = x + players[i].getWidth()
                    end
                    local y = players[i].getY() + headAdjustment
                    table.insert(projectilesList, projectileModel.newProjectile(x, y, players[i].isHeadingLeft(), players[i].getID()))
                    sounds["beams"][i]:stop()
                    sounds["beams"][i]:play()
                end
            end
            -- Resolve ground, mob collision and animation state
            local isHit = players[i].lateUpdate(collisionList, mobList)
            if isHit then
                sounds["defeat"]:play()
                currentGameState = gameStates["lose"]
                loseTimer = 1.0 -- Set lose timer for delayed animation
                love.graphics.setColor(1, 0, 0, 100) -- Flash red on next draw cycle
            end
        end
        -- Mob spawn sampler
        sampleSpawns()
        -- Call mob update
        for k, v in pairs(mobList) do
            -- Update using opposite player's coordinates
            v.update(players[3 - v.getType()["flavour"]].getX(), players[3 - v.getType()["flavour"]].getY())
        end
        -- Call projectiles update
        for k, v in pairs(projectilesList) do
            -- Update using opposite player's coordinates
            v.update()
            if v.getX() > screenWidth or v.getX() < 0 then
                table.remove(projectilesList, k)
            end
        end
        -- Check mob-projectile collision
        for kMob, mob in pairs(mobList) do
            for kProj, proj in pairs(projectilesList) do
                if mob.getType()["flavour"] == proj.getSourceID() then -- It's a match!
                    if mob.checkCollision(proj) then -- Delete mob and projectile
                        table.remove(mobList, kMob)
                        mobCount = mobCount - 1
                        mobsDefeated = mobsDefeated + 1
                        table.remove(projectilesList, kProj)
                        -- Play sound
                        sounds["destroy"]:stop()
                        sounds["destroy"]:play()
                    end
                end
            end
        end
    end -- game state: playing
end

-- Spawn sampler
function sampleSpawns()
    -- Update spawnCheckInterval, spawnChanceIncrement as a function of level
    local spawnCheckInterval = math.max(0.5, 7/(7+globalLevel)) * defaultSpawnCheckInterval
    local spawnChanceIncrement = math.min(2, (1+globalLevel/7)) * defaultSpawnChanceIncrement
    -- Update spawn timer
    spawnTimer = spawnTimer + love.timer.getDelta()
    if spawnTimer > spawnCheckInterval and mobCount < mobMaxCount then -- allow spawning
        -- Checked; reduce spawn timer
        spawnTimer = spawnTimer - spawnCheckInterval
        -- Check to see if spawn
        if love.math.random() < currentSpawnChance then
            -- Reset spawner
            currentSpawnChance = 0

            local width = 32
            local height = 32
            local type = {
                flavour = -1,
                level = 1,
                frames = 1,
            }
            -- Roll side it spawns on
            local x
            if love.math.random() < 0.5 then
                x = 0
            else
                x = screenWidth - width
            end
            -- Roll y
            local y = love.math.randomNormal(0.25*screenHeight, 0.5*screenHeight)
            -- Clamp y
            if y > screenHeight - height then
                y = screenHeight - height
            end
            if y < 0 then
                y = 0
            end
            -- Roll type
            if love.math.random() < 0.5 then
                type["flavour"] = 1
            else
                type["flavour"] = 2
            end
            -- Compute level as a function of level
            -- L:   L1   L2   L3  mobs
            -- 1:  100%
            -- 2:   70%  30% 
            -- 3:   40%  60%
            -- 4:   10%  90%
            -- 5:   10%  60%  30%
            -- 6:   10%  30%  60%
            -- 7+:  10%  10%  80%
            if globalLevel == 1 then
                -- Keep level 1
            elseif globalLevel <= 4 then -- Distribution of level 1 and 2 mobs
                if love.math.random() < 0.3 * (globalLevel-1) then -- level up some ombs
                    type["level"] = 2
                end
            elseif globalLevel <= 6 then
                if love.math.random() < 0.1 then
                    -- Keep level 1
                elseif love.math.random() < 0.1 + 0.6 - 0.3*(globalLevel-5) then
                    type["level"] = 2
                else
                    type["level"] = 3
                end
            else
                if love.math.random() < 0.1 then
                    -- Keep level 1
                elseif love.math.random() < 0.4 then
                    type["level"] = 2
                else
                    type["level"] = 3
                end
            end
            -- Associate number of frames with level of mob
            type["frames"] = type["level"]
            -- Gen dx (times correct sign function)
            local dx = (type["level"] * mobModel.baseMobSpeed) * (0.5*screenWidth - x) / math.abs((0.5*screenWidth - x))
            -- Gen dy
            local dy = 0
            -- Gen new mob
            table.insert(mobList, mobModel.newMob(type, x, y, width, height, dx, dy))
            mobCount = mobCount + 1
        else -- Increase spawn chance ~(1 - exponentially)
            currentSpawnChance = currentSpawnChance + (1 - currentSpawnChance)*spawnChanceIncrement
        end
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
