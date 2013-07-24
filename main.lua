lg = love.graphics
lm = love.mouse
lk = love.keyboard
zoomSpeed = 1
scrollSpeed = 1
nbColors = 6
colorDensity = 6


function love.load()
    local source = [[
        extern float width;
        extern float height;
        extern vec4 bounds;
        extern float maxIterations;
        extern float density;
        
        vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
        {
            float x = bounds.x + screen_coords.x / width * bounds.z;
            float y = bounds.y + screen_coords.y / height * bounds.w;
            float x0 = x;
            float y0 = y;
            float i;
            for (i = 0; x * x + y * y < 4 && i < maxIterations; i++)
            {
                float tmp = x * x - y * y + x0;
                y = 2 * x * y + y0;
                x = tmp;
            }
            float c = i / maxIterations;
            //return vec4(c,c,c,1);
            return texture2D(texture, vec2(c * density, 0.5));
        }
    ]]
    effect = lg.newPixelEffect(source)
    local warn = effect:getWarnings() 
    if (not warn == "No errors") then
        error(warn)
    end
    bounds = {-2.5, -1, 3.5, 2}
    maxIterations = 50
    local colorTable = love.image.newImageData(nbColors, 1)
    colorTable:mapPixel(
        function (x, y, r, g, b, a)                
            return 50 + math.random(51, 255),
                50 + math.random(51, 255),
                50 + math.random(51, 255),
                255
        end)
    colors = lg.newImage(colorTable)          
    colors:setWrap("repeat", "repeat")
    effect:send("width", lg.getWidth())
    effect:send("height", lg.getHeight())
    effect:send("bounds", bounds)
    effect:send("maxIterations", maxIterations)
    effect:send("density", colorDensity)
    lg.setPixelEffect(effect)
end

function zoom(factor, mousex, mousey)
    local normalizedx = mousex / lg.getWidth()
    local realx = normalizedx * bounds[3] + bounds[1]
    local normalizedy = 1 - mousey / lg.getHeight() 
    local realy = normalizedy * bounds[4] + bounds[2]
    bounds[3] = bounds[3] * factor
    bounds[4] = bounds[4] * factor
    bounds[1] = realx - normalizedx * bounds[3]
    bounds[2] = realy - normalizedy * bounds[4]
end

function love.update(dt)
    local updateBounds = false
    local updateIter = false
    if lm.isDown('l') then
        zoom(1 - zoomSpeed * dt, lm.getPosition())
        updateBounds = true
    elseif lm.isDown('r') then
        zoom(1 + zoomSpeed * dt, lm.getPosition())
        updateBounds = true
    end
    if lk.isDown("up") then
        bounds[2] = bounds[2] + scrollSpeed * dt * bounds[4]
        updateBounds = true
    elseif lk.isDown("down") then
        bounds[2] = bounds[2] - scrollSpeed * dt * bounds[4]
        updateBounds = true
    end
    if lk.isDown("right") then
        bounds[1] = bounds[1] + scrollSpeed * dt * bounds[3]
        updateBounds = true
    elseif lk.isDown("left") then
        bounds[1] = bounds[1] - scrollSpeed * dt * bounds[3]
        updateBounds = true
    end
    if lk.isDown("pageup") then
        maxIterations = maxIterations + 1
        updateIter = true
    elseif lk.isDown("pagedown") then
        maxIterations = math.max(maxIterations - 1, 1)
        updateIter = true
    end
    if updateBounds then effect:send("bounds", bounds) end
    if updateIter then effect:send("maxIterations", maxIterations) end
end

function love.draw()
    lg.draw(colors, 0, 0, 0, lg.getWidth() / colors:getWidth(), lg.getHeight() / colors:getHeight())
end

