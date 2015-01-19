require ("tmx_parser")
require ("tiled_render")
tiolved={}

tiolved.map={}
tiolved.gid={}
tiolved.layers={}
tiolved.objects={}

function tiolved:init(maptmx)
	tiolved.map=tmx_parser(maptmx)
	tiolved.gid=tiled_render:gid(tiolved.map)
	tiolved.layers=tiled_render:layers(tiolved.map)
	local map=tiolved.map
	local gap=map.height*map.tilewidth/2

	if tiolved.map.orientation=="orthogonal" then
		function tiolved:toMap(x,y)
			return x/map.tilewidth,y/map.tileheight
		end
		function tiolved.toRender(x,y)
			return x*map.tilewidth,y*map.tileheight
		end
	elseif tiolved.map.orientation=="isometric" then
		function tiolved:toMap(x,y)
			local xg=x-gap
			local gap=map.height*map.tilewidth/2
			local a=map.tilewidth
			local b=map.tileheight
			local d=1/(2*map.tilewidth*map.tileheight)
			return d*(b*xg+a*y),d*(-b*xg+a*y)
		end
		function tiolved:toRender(x,y)
			return (x-y)*map.tilewidth+gap,(x+y)*map.tileheight
		end
	end
end

function tiolved:sort(a,b)

end

function tiolved:draw()--(frame)
	for _,v in pairs(tiolved.layers) do 
		love.graphics.draw(v.canvas)
	end
end