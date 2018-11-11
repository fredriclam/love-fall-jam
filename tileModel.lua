-- Tile model

local Model = {}
-- Tile factory
function Model.newTile(x, y, width, height)
    -- Store object state
    local self = {
        x = x,
        y = y,
        width = width, 
        height = height,
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
        bbox = bbox,
        boundingBox = boundingBox,
        getx = getx,
        gety = gety,
        getdx = getdx,
        getdy = getdy
    }
end

-- Export Model object
return Model