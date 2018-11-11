-- Mob model

local Model = {}
-- Tile factory
function Model.newMob(type, x, y, width, height, dx, dy)
    -- Store object state
    local self = {
        x = x,
        y = y,
        type = type,
        dx = dx,
        dy = dy,
        width = width, 
        height = height,
        ticker = 0,
        animCycleDuration = 0.5,
        animState = 0
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
    local updatePos = function()
        self.x = self.x + dx
        self.y = self.y + dy
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
            if self.ticker <= (1.0/self.type["frames"])*self.animCycleDuration then
                self.animState = i-1
                return
            end
        end
    end

    -- Update wrapper
    local update = function()
        updatePos()
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
        getdy = getdy
    }
end

-- Export Model object
return Model