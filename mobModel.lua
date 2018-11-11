-- Mob model
-- Collision is checked here for mob-projectile. For mob-player, see playerModel.

local Model = {}

-- Static variables
Model.baseMobSpeed = 2.0
Model.baseAccel = 0.1

-- Tile factory
function Model.newMob(type, x, y, width, height, dx, dy)
    -- Store object state
    local self = {
        x = x,
        y = y,
        type = type,
        dx = dx,
        dy = dy,
        sx = 2,
        sy = 2,
        width = width, 
        height = height,
        ticker = 0,
        animCycleDuration = 1,
        animState = 0,

        maxAngleDegrees = 15,       -- Max chasing angle
        maxSpeed = math.sqrt(dx*dx + dy*dy) -- Compute from initial speed
    }
    -- Return representation of bounding box for collisions
    local bbox = function()
        return {
            left = self.x,
            right = self.x + self.width,
            top = self.y,
            bottom = self.y + self.height,
        }
    end

    -- Update position of mob
    local updatePos = function(targetX, targetY)
        -- Compute unit heading vector
        local deltaX = targetX - self.x
        local deltaY = targetY - self.y
        local norm = math.sqrt(deltaX*deltaX + deltaY*deltaY)
        deltaX = deltaX / norm
        deltaY = deltaY / norm
        local dxNew = self.dx + Model.baseAccel*deltaX
        local dyNew = self.dy + Model.baseAccel*deltaY        
        -- Penalize x-speed if angle is too large to make it "float" to correct altitude
        if math.abs(dyNew / dxNew) > math.abs(math.tan(math.rad(self.maxAngleDegrees))) then
            deltaX = 0.1*deltaX
        end
        -- Apply tracking acceleration
        self.dx = self.dx + Model.baseAccel*deltaX
        self.dy = self.dy + Model.baseAccel*deltaY
        -- Limit speed
        local speedRatio = math.sqrt(self.dx*self.dx + self.dy*self.dy) / self.maxSpeed
        if speedRatio > 1 then
            self.dx = self.dx / speedRatio
            self.dy = self.dy / speedRatio
        end
        -- Update position
        self.x = self.x + self.dx
        self.y = self.y + self.dy
    end

    -- Update animation state of mob
    local updateAnim = function()
        -- Update ticker
        self.ticker = self.ticker + love.timer.getDelta()
        -- Clock range reduction (essentially mod, reduce to prevent overflow)
        while self.ticker > self.animCycleDuration do
            self.ticker = self.ticker - self.animCycleDuration
        end
        -- Use anim keyframes
        for i = 1, self.type["frames"] do
            if self.ticker <= i*(1.0/self.type["frames"])*self.animCycleDuration then
                self.animState = i-1
                return
            end
        end
    end

    -- Collision checker with projectile
    local checkCollision = function(obj)
        -- Alias
        box1 = bbox()
        box2 = obj.bbox()

        -- Classic rect collision
        if box1.right > box2.left and box1.left < box2.right and
        box1.top < box2.bottom and box1.bottom > box2.top
        then -- Select minimum push off (positive quantities)
            return true
        end
    end

    -- Update wrapper
    local update = function(targetX, targetY)
        updatePos(targetX, targetY)
        updateAnim()
    end

    local getAnimState = function()
        return self.animState
    end

    local getType = function()
        return self.type
    end
    local getX = function()
        return self.x
    end
    local getY = function()
        return self.y
    end
    local getdx = function()
        return self.dx
    end
    local getdy = function()
        return self.dy
    end
    local getSX = function()
        return self.sx
    end
    local getSY = function()
        return self.sy
    end

    return {
        bbox = bbox,
        boundingBox = boundingBox,
        update = update,
        updatePos = updatePos,
        updateAnim = updateAnim,
        getAnimState = getAnimState,
        getType = getType,
        getX = getX,
        getY = getY,
        getdx = getdx,
        getdy = getdy,
        getSX = getSX,
        getSY = getSY,
        checkCollision = checkCollision,
    }
end

-- Export Model object
return Model