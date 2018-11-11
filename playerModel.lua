-- Player model
-- Agnostic to rendering view, audio, etc. Collides with passed tileModels using method checkCollision
-- self holds the instance variables; exported methods are returned by newPlayer of Model module.

local Model = {}

-- Player factory
function Model.newPlayer(playerID, spawnX, spawnY)

    -- If want to use metatables:
    -- setmetatable(self)
    -- self.__index = self

    local self = {
        playerID = playerID,               -- Just an identifier, not really used internally
        x = spawnX,                        -- Initial x
        y = spawnY,                        -- Initial y
        sx = 2,                            -- Player scale (x)
        sy = 2,
        width = 16 * 2,                    -- Width of bounding box: pixel height times sx
        height = 32 * 2,                   -- Height of bounding box: pixel height times sy

        -- Animation and anim states
        animState = 0,                     -- Enum state
        animCycleDuration = 0.500,         -- Seconds
        ticker = 0,                        -- Clock ticker
        attackAnimDuration = 0.4,          -- Seconds
        attackTime = 0,                    -- Time at which attack was executed
        headingLeft = true,                -- Heading (boolean)
        isAttacking = false,
        isWalking = false,

        -- Boundaries
        groundHeight = 13*32,  -- Hardcoded ground level y
        boundaryxMax = 18*32,  -- Hardcoded horizontal bounding box
        boundaryxMin = 6*32,   -- Hardcoded horizontal bounding box

        -- Physics
        gravIntensity = 0.5,   -- Gravity strength
        jumpIntensity = 10,    -- Speed impulse on jump
        dxStep = 5.5,          -- Hardcoded speed
        dy = 0,                -- Variable vertical speed
        grounded = false,      -- Flag to mark when standing on ground
    }

    -- Handle jump (method requiring self)
    -- Returns success flag
    local jump = function()
        if self.grounded and not self.isAttacking then
            self.dy = -self.jumpIntensity
            self.grounded = false
            return true
        end
        return false
    end

    -- Handle left walk
    local left = function()
        if not (self.isAttacking and self.grounded) then
            self.isWalking = true
            self.x = self.x - self.dxStep
            self.headingLeft = true
        end
    end

    -- Handle right walk
    local right = function()
        if not (self.isAttacking and self.grounded) then
            self.isWalking = true
            self.x = self.x + self.dxStep
            self.headingLeft = false
        end
    end

    -- Handle gravity updates
    local grav = function()
        -- Update speed
        if not self.grounded then
            self.dy = self.dy + self.gravIntensity
        end
    end

    -- Bounding box
    local bbox = function()
        return {
            left = self.x,
            right = self.x + self.width,
            top = self.y,
            bottom = self.y + self.height,
        }
    end

    -- Hardcoded check for collision with ground plane
    local checkGroundCollision = function()
        -- Hard-coded ground support
        if self.dy >= 0 and bbox().bottom >= self.groundHeight then
            self.grounded = true
        end
        -- If going through ground limit
        if bbox().bottom > self.groundHeight then
            -- Send to ground height
            self.y = self.groundHeight - self.height
            -- Kill speed
            self.dy = 0
        end
        -- Hard-coded wall clamping
        if bbox().left < self.boundaryxMin then
            self.x = self.boundaryxMin
        end
        if bbox().right > self.boundaryxMax then -- Adjust for top-left anchor
            self.x = self.boundaryxMax - self.width
        end
    end

    -- Checks for collision with other object
    local checkCollision = function(obj)
        -- Alias
        box1 = bbox()
        box2 = obj.bbox()

        -- Debug
        -- print(box1.right .. ' ' .. box2.left .. ' ' .. box1.bottom .. ' ' .. box2.top)

        -- Check for ground underneath our feet regardless of collisions
        if math.abs(box1.bottom - box2.top) < 1e-5 and
        box1.right > box2.left and box1.left < box2.right then -- Close enough bottom to top
            self.grounded = true
        end

        -- Classic rect collision
        if box1.right > box2.left and box1.left < box2.right and
        box1.top < box2.bottom and box1.bottom > box2.top
        then -- Select minimum push off (positive quantities)
            -- Compute corrections necessary for different rejection cases
            local corrections = {
                box2.left - box1.right,
                box2.right - box1.left,
                box2.bottom - box1.top,
                box2.top - box1.bottom,
            }
            -- Find path of least resistance, i.e., the smallest push possible
            local best = 1
            local min = math.abs(corrections[1])
            for i = 2, 4 do
                if math.abs(corrections[i]) < min then
                    best = i
                    min = math.abs(corrections[best])
                end
            end

            -- Apply corrections
            if best <= 2 then -- Correct x
                self.x = self.x + corrections[best]
            else -- Correct y
                self.dy = 0
                self.y = self.y + corrections[best]
            end

            -- Grounding if case 4
            if best == 4 then
                self.grounded = true
            end
        end
    end

    -- Performs series of updates before animation state update
    local earlyUpdate = function()
        self.isWalking = false
        grav()
        -- Update position y based on velocity
        self.y = self.y + self.dy
    end

    -- Execute an attack (checks if already in attack)
    -- Returns success flag
    local executeAttack = function()
        if not self.isAttacking then
            self.isAttacking = true
            self.attackTime = love.timer.getTime()
            -- More business logic
            return true
        end
        return false
    end

    -- Update animation based on keyframes defined by spritesheet order
    local updateAnim = function()
        -- Update ticker
        self.ticker = self.ticker + love.timer.getDelta()
        -- Clock range reduction (essentially mod, reduce to prevent overflow)
        while self.ticker > self.animCycleDuration do
            self.ticker = self.ticker - self.animCycleDuration
        end

        -- Release attacking state
        if self.isAttacking and love.timer.getTime() - self.attackTime >= self.attackAnimDuration then
            self.isAttacking = false
        end

        -- Use anim keyframes
        if self.isAttacking then
            if self.grounded then
                self.animState = 7 -- Grounded attack
            else
                self.animState = 8 -- Flying attack
            end
        elseif self.grounded then -- Grounded
            if self.isWalking then -- Grounded walking animation frames
                if self.ticker < 0.50*self.animCycleDuration then
                    self.animState = 5
                else
                    self.animState = 6
                end
            else -- Grounded standing animation frames
                if self.ticker < 0.25*self.animCycleDuration then 
                    self.animState = 0
                elseif self.ticker < 0.50*self.animCycleDuration then
                    self.animState = 1
                elseif self.ticker < 0.75*self.animCycleDuration then
                    self.animState = 2
                else
                    self.animState = 3
                end
            end
        else -- In air
            self.animState = 4
        end
    end

    -- Performs series of clamping and animation updates (called after checking key presses)
    local lateUpdate = function(collisionList)
        self.grounded = false
        -- Check collision against stage bounds
        checkGroundCollision()
        -- Check collision against all modeled tiles
        for k, v in pairs(collisionList) do
            checkCollision(v)
        end

        updateAnim()
    end

    local getID = function() return self.playerID end
    local getAnimState = function() return self.animState end
    local isHeadingLeft = function() return self.headingLeft end
    local getX = function() return self.x end
    local getY = function() return self.y end
    local getSX = function() return self.sx end
    local getSY = function() return self.sy end
    local getWidth = function() return self.width end

    return {
        jump = jump,
        left = left,
        right = right,
        grav = grav,
        bbox = bbox,
        checkGroundCollision = checkGroundCollision,
        checkCollision = checkCollision,
        earlyUpdate = earlyUpdate,
        lateUpdate = lateUpdate,
        executeAttack = executeAttack,
        updateAnim = updateAnim,
        getID = getID,
        getAnimState = getAnimState,
        isHeadingLeft = isHeadingLeft,
        getX = getX,
        getY = getY,
        getSX = getSX,
        getSY = getSY,
        getWidth = getWidth,
    }

end

-- Export Model object
return Model