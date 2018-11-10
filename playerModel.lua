-- Player model

local Model = {}
    
-- Data
-- setmetatable(self)
-- self.__index = self
Model.x = 300             -- Initial x
Model.y = 200             -- Initial y

-- Boundaries
Model.groundHeight = 13*32  -- Hardcoded ground level y
Model.boundaryxMax = 18*32  -- Hardcoded horizontal bounding box
Model.boundaryxMin = 6*32   -- Hardcoded horizontal bounding box

-- Physics
Model.gravIntensity = 8     -- Gravity strength
Model.jumpIntensity = 40    -- Speed impulse on jump
Model.dxStep = 10           -- Hardcoded speed
Model.dy = 0                -- Variable vertical speed
Model.grounded = false      -- Flag to mark when standing on ground

function Model.jump(self)
    if Model.grounded then
        Model.dy = -Model.jumpIntensity
        Model.grounded = false
    end
end
function Model.left(self)
    Model.x = Model.x - Model.dxStep
end
function Model.right(self)
    Model.x = Model.x + Model.dxStep
end
function Model.grav(self)
    -- Update speed
    if not Model.grounded then
        Model.dy = Model.dy + Model.gravIntensity
        -- Update position
        Model.y = Model.y + Model.dy
    end
end
function Model.checkGroundCollision(self)
    -- Hard-coded ground
    if Model.y > Model.groundHeight then
        -- Send to ground height
        Model.y = Model.groundHeight
        -- Kill speed
        Model.dy = 0
        -- Set grounded
        Model.grounded = true
    end
    -- Hard-coded wall clamping
    if Model.x < Model.boundaryxMin then
        Model.x = Model.boundaryxMin
    end
    if Model.x > Model.boundaryxMax - 32 then -- Adjust for top-left anchor
        Model.x = Model.boundaryxMax - 32
    end
    
end
function Model.checkCollision(self, obj)
    
end

-- Export Model object
return Model