-- Player model

local Model = {}
    
-- setmetatable(self)
-- self.__index = self

Model.x = 300             -- Initial x
Model.y = 200             -- Initial y
Model.groundHeight = 400  -- Hardcoded ground level y
Model.gravIntensity = 8  -- Gravity strength
Model.jumpIntensity = 40  -- Speed impulse on jump
Model.dxStep = 10  -- Hardcoded speed
Model.dy = 0  -- Variable vertical speed
Model.grounded = false

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
    if not grounded then
        Model.dy = Model.dy + Model.gravIntensity
    end
    -- Update position
    Model.y = Model.y + Model.dy
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
end

-- Export Model object
return Model