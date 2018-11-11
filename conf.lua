function love.conf(t)
    -- Window stuff before the game starts
    t.window.width = 24*32
    t.window.height = 18*32 -- Use 18 32-pixel blocks, times 2 scale
    t.window.title = "/fredric/"
    t.window.borderless = true

    -- Default module inclusions
    t.modules.audio = true
    t.modules.data = false
    t.modules.event = true
    t.modules.font = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.joystick = false
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = false
    t.modules.physics = false
    t.modules.sound = true
    t.modules.system = true
    t.modules.thread = false
    t.modules.timer = true
    t.modules.touch = false
    t.modules.video = false
end