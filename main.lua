-- aliases
lg = love.graphics
lm = love.mouse
lk = love.keyboard

zoomSpeed = 1
scrollSpeed = 1
nbColors = 6
colorDensity = 6


function love.load()
	local source = [[
		// CPU / GPU shared variables
		extern float width;
		extern float height;
		extern vec4 bounds;
		extern float maxIterations;
		extern float density;

		// main function: returns color of pixel at screen_coords.xy
		vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
		{
			// compute complex number z=x+iy given pixel coordinates
			float x0 = bounds.x + screen_coords.x / width * bounds.z;
			float y0 = bounds.y + screen_coords.y / height * bounds.w;

			float x = x0;
			float y = y0;
			float i;
			for (i = 0; x * x + y * y < 4 && i < maxIterations; i++)
			{
				// z = z^2 + z0
				float tmp = x * x - y * y + x0;
				y = 2 * x * y + y0;
				x = tmp;
			}
			float c = i / maxIterations;
			// lookup color in texture
			return texture2D(texture, vec2(c * density, 0.5));
		}
	]]
	effect = lg.newPixelEffect(source)
	
	-- color table texture generation
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
	-- send shared variables values to gpu
	bounds = {-2.5, -1, 3.5, 2} -- {left, top, width, height} format. = complex plane [-2.5, 1] + i * [-1, 1]
	maxIterations = 200
	
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

function love.update(dt) -- manage inputs
	local updateBounds = false
	local updateIter = false
	-- zoom
	if lm.isDown('l') then
		zoom(1 - zoomSpeed * dt, lm.getPosition())
		updateBounds = true
	elseif lm.isDown('r') then
		zoom(1 + zoomSpeed * dt, lm.getPosition())
		updateBounds = true
	end
	-- scroll
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
	-- details
	if lk.isDown("pageup") then
		maxIterations = maxIterations + 1
		updateIter = true
	elseif lk.isDown("pagedown") then
		maxIterations = math.max(maxIterations - 1, 1)
		updateIter = true
	end
	-- send new values to GPU
	if updateBounds then effect:send("bounds", bounds) end
	if updateIter then effect:send("maxIterations", maxIterations) end
	lg.setCaption("iterations: " .. maxIterations .. " @" .. love.timer.getFPS() .. "fps")
end

function love.draw()
	-- draw a fullscreen quad with color table as texture
	lg.draw(colors, 0, 0, 0, lg.getWidth() / colors:getWidth(), lg.getHeight() / colors:getHeight())
end

