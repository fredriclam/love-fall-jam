-- Projectile model

local Model = {}
-- Tile factory
function Model.newProjectile(x, y, isHeadingLeft, sourceID)
    -- Store object state
    local self = {
        x = x,
        y = y,
        width = 8, 
        height = 8,
        isHeadingLeft = isHeadingLeft,
        dx = 16.0,
        sourceID = sourceID,
        sx = 2.0,
        sy = 2.0,
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

    local updatePos = function()
        local dx = self.dx
        if self.isHeadingLeft then
            dx = -dx
        end
        self.x = self.x + dx
    end

    local update = function()
        updatePos()
    end

    local getX = function() return self.x end
    local getY = function() return self.y end
    local getdx = function() return self.dx end
    local getdy = function() return self.dy end
    local getSourceID = function() return self.sourceID end
    local getSX = function()  return self.sx end
    local getSY = function() return self.sy end
    local isHeadingLeft = function() return self.isHeadingLeft end

    return {
        bbox = bbox,
        boundingBox = boundingBox,
        getX = getX,
        getY = getY,
        getdx = getdx,
        getdy = getdy,
        getSourceID = getSourceID,
        getSX = getSX,
        getSY = getSY,
        isHeadingLeft = isHeadingLeft,
        updatePos = updatePos,
        update = update,
    }
end

-- Export Model object
return Model