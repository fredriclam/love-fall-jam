-- Player model

local Model = {}
function Model:new()
    x = 300             -- Initial x
    y = 200             -- Initial y
    groundHeight = 300  -- Hardcoded ground level y
    gravIntensity = 15  -- Gravity strength
    jumpIntensity = 80  -- Speed impulse on jump
    dxStep = 10  -- Hardcoded speed
    dy = 0  -- Variable vertical speed
    inAir = false
    -- setmetatable(self)
    -- self.__index = self
end

function Model.jump(self)
    if grounded then
        dy = -jumpIntensity
        grounded = false
    end
end
function Model.left(self)
    x = x - dxStep
end
function Model.right(self)
    x = x + dxStep
end
function Model.grav(self)
    -- Update speed
    if not grounded then
        dy = dy + gravIntensity
    end
    -- Update position
    y = y + dy
end
function Model.checkGroundCollision(self)
    -- Hard-coded ground
    if y > groundHeight then
        -- Send to ground height
        y = groundHeight
        -- Kill speed
        dy = 0
        -- Set grounded
        grounded = true
    end
end

-- Export Model class
return Model