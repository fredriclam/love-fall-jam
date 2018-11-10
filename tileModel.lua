-- Tile model

local Model = {}
-- Tile factory
function Model.newTile(x, y, dx, dy)
    -- Store object state
    local self = {
        x = x,
        y = y,
        dx = dx, 
        dy = dy
    }
    -- Return representation of bounding box for collisions
    local boundingBox = function (v)
        -- pass
    end

    local getx = function()
        return self.x
    end
    local gety = function()
        return self.y
    end
    local getdx = function()
        return self.dx
    end
    local getdy = function()
        return self.dy
    end

    return {
        boundingBox = boundingBox,
        getx = getx,
        gety = gety,
        getdx = getdx,
        getdy = getdy
    }
end

-- Export Model object
return Model