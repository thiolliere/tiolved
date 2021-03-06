require ("tiolved")

function love.load()
	local t=love.timer.getTime()
	-- parsering tmx file to a lua table
	map=love.filesystem.load("source/orthogonal.lua")()
	tloadmap=" time to load map="..love.timer.getTime()-t

	-- creation of the gid, a local object full of data
	local gid=tiolved.gid(map,"source/")

	-- creation of tileset, an object that animate tile (tileset:update(dt)) 
	-- and draw tile stored in spritebatch (tileset:draw())
	-- use tileset:add(...) to add tile in spritebatch
	tileset=tiolved.tileset(gid,map)

	-- interpretation of interpreted layers
	local toremove={} -- you must not remove in an array while looping in it
	for i,v in ipairs (map.layers) do
		if v.name=="collision" then
			-- create.collision(v)
			table.insert(toremove,i)
		end
	end
	for _,v in ipairs(toremove) do
		table.remove(map.layers,v)
	end

	-- rendering of drawned layers
	-- this object draws tile of layers in tileset spritebatch 
	-- ( use layers:draw() )
	layers=tiolved.layers(map,tileset)
	-- useful function
	toMap,toRender=tiolved.usefulfunc(map)
end

function love.update(dt)
	tileset:update(dt)

	x=love.mouse:getX()
	y=love.mouse:getY()
	xmap,ymap=toMap(x,y)
	xrender,yrender=toRender(xmap,ymap)

	if love.keyboard.isDown("escape") then
		love.event.quit()
	end
end

function love.draw()
	layers:draw() -- must be call before tileset:draw()
	tileset:draw()
	love.graphics.print(
		"x="..x..", y="..y..
		"\nxmap="..xmap..", ymap="..ymap..
		"\nxrender="..xrender..", yrender="..yrender..
		"\n"..tloadmap
	)
end
