-- Player model

local Model = {}
    
-- Data
-- setmetatable(self)
-- self.__index = self
Model.x = 11*32                         -- Initial x
Model.y = 10*32                         -- Initial y
Model.sx = 2                            -- Player scale (x)
Model.sy = 2
Model.width = 16 * Model.sx             -- Width of bounding box
Model.height = 32 * Model.sy            -- Height of bounding box

-- Animation and anim states
Model.animState = 0                     -- Enum state
Model.animCycleDuration = 0.500         -- Seconds
Model.ticker = 0                        -- Clock ticker
Model.attackAnimDuration = 0.2          -- Seconds
Model.attackTime = 0                    -- Time at which attack was executed
Model.headingLeft = true                -- Heading (boolean)
Model.isAttacking = false
Model.isWalking = false

-- Boundaries
Model.groundHeight = 13*32  -- Hardcoded ground level y
Model.boundaryxMax = 18*32  -- Hardcoded horizontal bounding box
Model.boundaryxMin = 6*32   -- Hardcoded horizontal bounding box

-- Physics
Model.gravIntensity = 0.5   -- Gravity strength
Model.jumpIntensity = 10    -- Speed impulse on jump
Model.dxStep = 3.5          -- Hardcoded speed
Model.dy = 0                -- Variable vertical speed
Model.grounded = false      -- Flag to mark when standing on ground

-- Handle jump
function Model.jump(self)
    if Model.grounded then
        Model.dy = -Model.jumpIntensity
        Model.grounded = false
    end
end

-- Handle left walk
function Model.left(self)
    Model.isWalking = true
    Model.x = Model.x - Model.dxStep
    Model.headingLeft = true
end

-- Handle right walk
function Model.right(self)
    Model.isWalking = true
    Model.x = Model.x + Model.dxStep
    Model.headingLeft = false
end

-- Handle gravity updates
function Model.grav(self)
    -- Update speed
    if not Model.grounded then
        Model.dy = Model.dy + Model.gravIntensity
        -- Update position
        Model.y = Model.y + Model.dy
    end
end

-- Bounding box
function Model.bbox(self)
    return {
        left = Model.x,
        right = Model.x + Model.width,
        top = Model.y,
        bottom = Model.y + Model.height,
    }
end

-- Hardcoded check for collision with ground plane
function Model.checkGroundCollision(self)
    -- Hard-coded ground
    if Model.bbox().bottom > Model.groundHeight then
        -- Send to ground height
        Model.y = Model.groundHeight - Model.height
        -- Kill speed
        Model.dy = 0
        -- Set grounded
        Model.grounded = true
    end
    -- Hard-coded wall clamping
    if Model.bbox().left < Model.boundaryxMin then
        Model.x = Model.boundaryxMin
    end
    if Model.bbox().right > Model.boundaryxMax then -- Adjust for top-left anchor
        Model.x = Model.boundaryxMax - Model.width
    end
    
end

-- Checks for collision with other object
function Model.checkCollision(self, obj)
    
end

-- Performs series of updates before animation state update
function Model.earlyUpdate(self)
    Model.grav()
    Model.isWalking = false
end

-- Performs series of clamping and animation updates (called after checking key presses)
function Model.lateUpdate(self)
    Model.checkGroundCollision()
    Model.updateAnim()
end

-- Execute an attack (checks if already in attack)
function Model.executeAttack(self)
    if not Model.isAttacking then
        Model.isAttacking = true
        Model.attackTime = love.timer.getTime()
        -- More business logic
    end
end

-- Update animation based on keyframes defined by spritesheet order
function Model.updateAnim(self)
    -- Update ticker
    Model.ticker = Model.ticker + love.timer.getDelta()
    -- Clock range reduction (essentially mod, reduce to prevent overflow)
    while Model.ticker > Model.animCycleDuration do
        Model.ticker = Model.ticker - Model.animCycleDuration
    end

    -- Release attacking state
    if Model.isAttacking and love.timer.getTime() - Model.attackTime >= Model.attackAnimDuration then
        Model.isAttacking = false
    end

    -- Use anim keyframes
    if Model.isAttacking then
        if Model.grounded then
            Model.animState = 7 -- Grounded attack
        else
            Model.animState = 8 -- Flying attack
        end
    elseif Model.grounded then -- Grounded
        if Model.isWalking then -- Grounded walking animation frames
            if Model.ticker < 0.50*Model.animCycleDuration then
                Model.animState = 5
            else
                Model.animState = 6
            end
        else -- Grounded standing animation frames
            if Model.ticker < 0.25*Model.animCycleDuration then 
                Model.animState = 0
            elseif Model.ticker < 0.50*Model.animCycleDuration then
                Model.animState = 1
            elseif Model.ticker < 0.75*Model.animCycleDuration then
                Model.animState = 2
            else
                Model.animState = 3
            end
        end
    else -- In air
        Model.animState = 4
    end
end

-- Export Model object
return Model