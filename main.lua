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

-- Globals
local globalLevel = 1                     -- Level of the global stage
local mobMaxCount = 10                    -- Max number of mobs
local currentSpawnChance = 0              -- Initial spawn chance (increases every failed spawn)
local spawnTimer = 0                      -- Spawn timer (s)
local defaultSpawnCheckInterval = 0.7     -- Seconds
local defaultSpawnChanceIncrement = 0.1   -- Increments of spawn chance at level 1
local mobCount = 0                        -- Current number of mobs
local mobsDefeated = 0                    -- Number of mobs defeated in total
local previousDefeated = 0                -- Secondary counter for mobs defeated in previous levels
local playerHitBoxAdjustment = 5          -- Trimming the hitbox
local victoryAttained = false
local playerDown = false
-- Game state enumeration
local gameStates = {
    ready = 0,
    playing = 1,
    lose = 2,
    win = 3,
}
-- Current global game state
local currentGameState = gameStates["ready"]
-- Global timers
local stateTimer = 0                    -- Decumulates after losing
-- Graphical
local defaultFontSize = 18
local headAdjustment = 11           -- Number of pixels to translate downward due to headAdjustment
local backgroundScale = 2.0         -- Isotropic scaling for background texture
local backgroundShiftStep = 80      -- Number of pixels to advance background by per level
local backgroundDepth = 0           -- Current background depth
local backgroundAdjustRate = 0.02
-- Audio
local isAudioOn = true
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
    2,
    2,
    4,
    4,
    6, -- 5
    6,
    10, -- 7
}
local finalLevel = 7
local levelObjectives = { -- Number of mobs needed to advance level
    1,
    1,
    0,
    0,
    0, -- 5
    1,
    1, -- 7
}

function initPlayers()
    return {
        playerModel.newPlayer(1, 2*16, 2*(32-playerHitBoxAdjustment), 10*32, 10*32),
        playerModel.newPlayer(2, 2*16, 2*(32-playerHitBoxAdjustment), 12*32, 10*32),
    }
end

function love.load()
    -- Window stuff after load
    -- love.window.setTitle("/fredric/")
    -- love.window.setMode(24*32, 18*32)
    
    -- Colour mask
    -- love.graphics.setColor(0,0,0)
    font = love.graphics.setNewFont(defaultFontSize)
    love.graphics.setBackgroundColor(55/255,155/255,0/255)
    -- Deep purple
    -- love.graphics.setBackgroundColor(18/255,3/255,41/255)

    -- Loading spritesheet
    spritesheet = love.graphics.newImage("/resource/spritesheet.png")
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
        return love.graphics.newQuad(32*j, 32*i+playerHitBoxAdjustment, 16, 32-playerHitBoxAdjustment,
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
        jump = love.audio.newSource("/resource/jump.wav", "static"),
        beams = {
            love.audio.newSource("/resource/beam1.wav", "static"),
            love.audio.newSource("/resource/beam2.wav", "static"),
        },
        victory = love.audio.newSource("/resource/victory.wav", "static"),
        destroy = love.audio.newSource("/resource/destroy.wav", "static"),
        bgm = love.audio.newSource("/resource/bgm.wav", "static"),
        defeat = love.audio.newSource("/resource/defeat.wav", "static"),
    }

    -- Init players
    players = initPlayers()
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
    local jitterX = 2*math.cos( 2*love.timer.getTime() )
    local jitterY = 10*math.sin( love.timer.getTime() )
    love.graphics.draw(spritesheet, findBackground(backgroundDepth + jitterX, jitterY), 0, 0, 0.0, backgroundScale, backgroundScale)

    -- Shared tasks
    if currentGameState == gameStates["playing"]  or currentGameState == gameStates["lose"]
       or currentGameState == gameStates["victory"]
    then
        -- Draw background
        drawTileMap(bgTiles)
        -- Print instructions on screen (background layer) only in playing mode
        if globalLevel == 1 and currentGameState == gameStates["playing"] then
            love.graphics.setColor(0, 0, 0, 100)
            love.graphics.printf("SURVIVE", 0.*screenWidth, 0.2*screenHeight, screenWidth, "center")
            love.graphics.printf("WASD + E", 0.*screenWidth, 0.25*screenHeight, 2*0.35*screenWidth, "center")
            love.graphics.printf("ARROWS + /", 0.*screenWidth, 0.25*screenHeight, 2*0.7*screenWidth, "center")
            love.graphics.setColor(1, 1, 1, 100)
        end
        -- Draw players
        for k, v in pairs(players) do
            love.graphics.draw(spritesheet, findPlayerSprite(v.isHeadingLeft(), v.getID(), v.getAnimState()),
                            v.getX(), v.getY(), 0.0, v.getSX(), v.getSY())
        end
        -- Draw mobs
        for k, v in pairs(mobList) do
            love.graphics.draw(spritesheet, findMobSprite(v.getType(), v.getAnimState()), v.getX(), v.getY(), 
                            0.0, v.getSX(), v.getSY())
            -- print(v.getType()["frames"])
        end
        -- Draw foreground
        drawTileMap(fgTiles)
        -- Draw projectiles
        for k, v in pairs(projectilesList) do
            love.graphics.draw(spritesheet, findProjectileSprite(v.getSourceID(), v.isHeadingLeft()),
                    v.getX(), v.getY(), 0.0, v.getSX(), v.getSY())
        end

        -- UI: draw progress bar
        if globalLevel < 3 then
            love.graphics.setColor(0, 0, 0, 100)
        else
            love.graphics.setColor(1, 1, 1, 100)
        end
        love.graphics.draw(spritesheet, love.graphics.newQuad(32, 0, 16, 16, spritesheet:getWidth(), spritesheet:getHeight()),
            0.7*screenWidth, 0.9*screenHeight, 0.0, 2, 2)

        -- 
        local barXMin = 0.755*screenWidth
        local barXMax = 0.825*screenWidth
        local barXMiniscus = mobsDefeated / levelObjectives[globalLevel] * (barXMax - barXMin) + barXMin
        if globalLevel < 3 then
            love.graphics.setColor(0, 0, 0, 100)
        else
            love.graphics.setColor(1, 1, 1, 100)
        end
        love.graphics.rectangle("line", barXMin, 0.91*screenHeight, barXMax-barXMin, 16)
        love.graphics.setColor(0, 1, 0, 100)
        love.graphics.rectangle("fill", barXMin, 0.91*screenHeight, barXMiniscus-barXMin, 16)
        
        
        -- UI: draw STG indicator
        if globalLevel < 3 then
            love.graphics.setColor(0, 0, 0, 100)
        else
            love.graphics.setColor(1, 1, 1, 100)
        end
        love.graphics.draw(spritesheet, love.graphics.newQuad(48, 0, 16, 16, spritesheet:getWidth(), spritesheet:getHeight()),
            0.87*screenWidth, 0.91*screenHeight, 0.0, 2, 2)
        -- Placeholder stage text
        love.graphics.printf(globalLevel, 0.*screenWidth, 0.91*screenHeight-4, 2*0.93*screenWidth, "center")

        -- UI: reset color filter
        love.graphics.setColor(1, 1, 1, 100)
    end -- playing and lose states

    -- Pure game states
    if currentGameState == gameStates["ready"] then
        love.graphics.setColor(0, 0, 0, 100)
        love.graphics.printf("Enter to start your", 0.*screenWidth, 0.35*screenHeight, 2*0.5*screenWidth, "center")
        love.graphics.printf("2-player game: WASD + E, arrows keys + /", 0.*screenWidth, 0.75*screenHeight, 2*0.5*screenWidth, "center")
        love.graphics.printf("You can shoot them down, but use the right weapon.", 0.*screenWidth, 0.8*screenHeight, 2*0.5*screenWidth, "center")
        love.graphics.setNewFont(1.5*defaultFontSize)
        -- Placeholder title
        love.graphics.printf("Doomed Descent", 0.*screenWidth, 0.4*screenHeight, 2*0.5*screenWidth, "center")
        -- Sound toggle
        love.graphics.setNewFont(0.5*defaultFontSize)
        love.graphics.printf("[M] to toggle sound", 0.*screenWidth, 0.95*screenHeight, 2*0.9*screenWidth, "center")
        love.graphics.setNewFont(defaultFontSize)
        love.graphics.setColor(1, 1, 1, 100)
    elseif currentGameState == gameStates["lose"] then
        if stateTimer > -3 then -- Lose timer from what it's set to (>0) down to -3
            -- Print statistics
            if globalLevel < 3 then
                love.graphics.setColor(93/255, 22/255, 187/255, 100)
            else
                love.graphics.setColor(1, 1, 1, 100)
            end
            -- Build output string str
            local str = "You vanquished " .. previousDefeated + mobsDefeated .. " Thing"
            if previousDefeated + mobsDefeated ~= 1 then
                str = str .. "s"
            end
            str = str .. "."
            love.graphics.printf(str, 0.*screenWidth, 0.45*screenHeight, 2*0.5*screenWidth, "center")
            love.graphics.printf("Restarting...", 0.*screenWidth, 0.5*screenHeight, 2*0.5*screenWidth, "center")
            love.graphics.setColor(1, 1, 1, 100)
        else
            stageReset()
            currentGameState = gameStates["ready"]
        end
        -- Update lose timer
        stateTimer = stateTimer - love.timer.getDelta()
    elseif currentGameState == gameStates["victory"] then
        love.graphics.setNewFont(1.5*defaultFontSize)
        -- Victory message
        love.graphics.printf("All quiet. Victory?", 0.*screenWidth, 0.25*screenHeight, 2*0.5*screenWidth, "center")
        love.graphics.setNewFont(defaultFontSize)
        love.graphics.printf("Enter to return to main menu.", 0.*screenWidth, 0.35*screenHeight, 2*0.5*screenWidth, "center")
        if playerDown then
            love.graphics.setColor(1, 0, 0, 100)
            love.graphics.setNewFont(1.5*defaultFontSize)
            love.graphics.printf("Grim.", 0.*screenWidth, 0.65*screenHeight, 2*0.5*screenWidth, "center")
            love.graphics.setNewFont(defaultFontSize)
            love.graphics.setColor(1, 1, 1, 100)
        end
    end -- Pure game states

end

function love.update()
    -- Pausing music
    if not love.window.hasFocus then
        sounds["bgm"]:pause()
    end

    -- Shared tasks
    if currentGameState == gameStates["playing"] or currentGameState == gameStates["victory"] then -- game state: playing
        -- Check if reached objective
        if mobsDefeated >= levelObjectives[globalLevel] then
            -- Check for victory
            if globalLevel == finalLevel then -- Change to victory state
                currentGameState = gameStates["victory"]
                if not victoryAttained then
                    sounds["victory"]:play()
                    victoryAttained = true
                end
            else
                -- Level up
                globalLevel = globalLevel + 1
                -- Reset spawn timer
                spawnTimer = 0
                -- Cache mobs defeated count to previousDefeated and Reset mobs defeated
                previousDefeated = previousDefeated + mobsDefeated
                mobsDefeated = 0
            end
            
        end
        -- Wrap to skip is player downed
        if not playerDown then
            for keyPlayer, player in pairs(players) do
                -- Resolve gravity on player (acc and velocity), walking state
                player.earlyUpdate()
                -- Resolve pressed keys
                if love.keyboard.isDown(keySets[keyPlayer]["up"]) then
                    if player.jump() then
                        sounds["jump"]:stop()
                        sounds["jump"]:play()
                    end
                end
                if love.keyboard.isDown(keySets[keyPlayer]["left"]) and not love.keyboard.isDown(keySets[keyPlayer]["right"]) then
                    player.left()
                end
                if love.keyboard.isDown(keySets[keyPlayer]["right"]) and not love.keyboard.isDown(keySets[keyPlayer]["left"]) then
                    player.right()
                end
                if love.keyboard.isDown(keySets[keyPlayer]["shoot"]) then
                    if player.executeAttack() then
                        -- Compute spawn position
                        local x = player.getX()
                        if not player.isHeadingLeft then
                            x = x + player.getWidth()
                        end
                        local y = player.getY() + headAdjustment
                        table.insert(projectilesList, projectileModel.newProjectile(x, y, player.isHeadingLeft(), player.getID()))
                        sounds["beams"][keyPlayer]:stop()
                        sounds["beams"][keyPlayer]:play()
                    end
                end
                -- Resolve ground, mob collision and animation state
                local isHit = player.lateUpdate(collisionList, mobList)
                if isHit then
                    sounds["defeat"]:play()
                    currentGameState = gameStates["lose"]
                    stateTimer = 1.0 -- Set lose timer for delayed animation
                    -- love.graphics.setColor(1, 0, 0, 100) -- Flash red on next draw cycle
                end
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
        -- Easter egg: post-victory friendly fire
        if currentGameState == gameStates["victory"] then -- allow friendly fire
            for keyPlayer, player in pairs(players) do
                local isHit = false
                -- Check for hit against opposite player's projectiles
                for keyProj, proj in pairs(projectilesList) do
                    if proj.getSourceID() ~= keyPlayer then
                        isHit = isHit or player.checkHostileCollision(proj)
                    end
                end
                if isHit then
                    -- Delete player
                    table.remove(players, keyPlayer)
                    -- Flash red on next draw cycle
                    love.graphics.setColor(1, 0, 0, 100)
                    -- Raise flag for player down
                    playerDown = true
                end
            end
        end
    end -- game state: playing or victory
end

-- Spawn sampler
function sampleSpawns()
    -- Update spawnCheckInterval, spawnChanceIncrement as a function of level
    local spawnCheckInterval = math.max(0.5, 7/(7+globalLevel)) * defaultSpawnCheckInterval
    local spawnChanceIncrement = math.min(2, (1+globalLevel/7)) * defaultSpawnChanceIncrement
    -- Update spawn timer
    spawnTimer = spawnTimer + love.timer.getDelta()
    if spawnTimer > spawnCheckInterval and mobCount < mobMaxCount -- When timer fills, and enough space
       and mobCount < levelObjectives[globalLevel] - mobsDefeated then -- allow spawning (no more than objective)
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
    -- Handle audio controls
    if key == "m" then
        if isAudioOn then
            love.audio.setVolume(0.0)
            isAudioOn = false
        else
            love.audio.setVolume(1.0)
            isAudioOn = true
        end
    end

    -- Handle enter to switch state (single press)
    if currentGameState == gameStates["ready"] then
        if love.keyboard.isDown("return") then
            sounds["beams"][1]:play()
            currentGameState = gameStates["playing"]
        end
    elseif currentGameState == gameStates["victory"] then
        if love.keyboard.isDown("return") then
            sounds["beams"][1]:play()
            stageReset()
            currentGameState = gameStates["ready"]
        end
    end
end

-- Resets globals (closure)
function stageReset()
    -- Reset counters and playing timers
    globalLevel = 1
    currentSpawnChance = 0
    spawnTimer = 0
    mobCount = 0
    mobsDefeated = 0
    previousDefeated = 0
    victoryAttained = false
    playerDown = false
    
    -- Destroy all instances, relying on automatic garbage collector
    mobList = {}
    players = {}
    projectilesList = {}

    -- Destroy all instances
    -- for k, v in pairs(mobList) do
    --     table.remove(mobList, k)
    -- end
    -- for k, v in pairs(players) do
    --     table.remove(players, k)
    -- end
    -- for k, v in pairs(projectilesList) do
    --     table.remove(projectilesList, k)
    -- end
    

    -- Re-initialize players
    players = initPlayers()
    
end