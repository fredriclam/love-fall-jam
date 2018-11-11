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
Model.attackAnimDuration = 0.35          -- Seconds
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
    if Model.grounded and not Model.isAttacking then
        Model.dy = -Model.jumpIntensity
        Model.grounded = false
    end
end

-- Handle left walk
function Model.left(self)
    if not (Model.isAttacking and Model.grounded) then
        Model.isWalking = true
        Model.x = Model.x - Model.dxStep
        Model.headingLeft = true
    end
end

-- Handle right walk
function Model.right(self)
    if not (Model.isAttacking and Model.grounded) then
        Model.isWalking = true
        Model.x = Model.x + Model.dxStep
        Model.headingLeft = false
    end
end

-- Handle gravity updates
function Model.grav(self)
    -- Update speed
    if not Model.grounded then
        Model.dy = Model.dy + Model.gravIntensity
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
    -- Hard-coded ground support
    if Model.dy >= 0 and Model.bbox().bottom >= Model.groundHeight then
        Model.grounded = true
    end
    -- If going through ground limit
    if Model.bbox().bottom > Model.groundHeight then
        -- Send to ground height
        Model.y = Model.groundHeight - Model.height
        -- Kill speed
        Model.dy = 0
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
function Model.checkCollision(obj)
    -- Alias
    box1 = Model.bbox()
    box2 = obj.bbox()

    -- Debug
    -- print(box1.right .. ' ' .. box2.left .. ' ' .. box1.bottom .. ' ' .. box2.top)

    -- Check for ground underneath our feet regardless of collisions
    if math.abs(box1.bottom - box2.top) < 1e-5 and
       box1.right > box2.left and box1.left < box2.right then -- Close enough bottom to top
        Model.grounded = true
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
            Model.x = Model.x + corrections[best]
        else -- Correct y
            Model.y = Model.y + corrections[best]
        end

        -- Grounding if case 4
        if best == 4 then
            Model.grounded = true
        end
    end
end

-- Performs series of updates before animation state update
function Model.earlyUpdate(self)
    Model.isWalking = false
    Model.grav()
    -- Update position y based on velocity
    Model.y = Model.y + Model.dy
end

-- Performs series of clamping and animation updates (called after checking key presses)
function Model.lateUpdate(collisionList)
    Model.grounded = false
    -- Check collision against stage bounds
    Model.checkGroundCollision()
    -- Check collision against all modeled tiles
    for k, v in pairs(collisionList) do
        Model.checkCollision(v)
    end

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