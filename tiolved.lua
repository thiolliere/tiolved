tiolved={}

function tiolved:map(name)
	local firstline = "<%?"
	local object = "<[^/].*/>"
	local begintable = "<[^/].*[^/]>"
	local endtable= "</.*>"

	local stack={}
	local courant=1
	local xml={}
	stack[courant]=xml

	local function readattribute(line)
		local k, n, v
		_,k,n=string.find(line, "%s(%w%w*)=")
		if n then
			line=string.sub(line,k+1)
			_,k=string.find(line,".\"" )
			v=string.sub(line,2,k-1)
			line=string.sub(line,k+1)
		end
		return line,n,v
	end

	local function readline(line)
		local object, objectname, k
		_,k,objectname=string.find(line, "<(%w%w*)")
		line=string.sub(line, k+1)

		object={je=objectname}

		local attr={n=nil,v=nil}
		line,attr.n,attr.v=readattribute(line)
		while attr.n and attr.v do
			object[attr.n]=attr.v
			line,attr.n,attr.v=readattribute(line)
		end
		return object
	end

	for line in love.filesystem.lines(name) do
		if line == "</map>" then
			return xml[1]
		elseif string.find(line,firstline) then
		elseif string.find(line,object) then
			table.insert(stack[courant],readline(line))
		elseif string.find(line,begintable) then
			table.insert(stack[courant],readline(line))
			stack[courant+1]=stack[courant][table.getn(stack[courant])]
			courant=courant+1
		elseif string.find(line,endtable) then
			courant=courant-1
		end
	end
end

function tiolved:gid(map,rep)
	gid={}
	local counter=1
	local i=1
	while map[i].je=="tileset" do
		local tileset=map[i]
		tileset.image=love.graphics.newImage(rep..tileset[1].source)
		local tileinwidth=math.floor(tileset[1].width/tileset.tilewidth)
		local tileinheight=math.floor(tileset[1].height/tileset.tileheight)
		for n = 1,tileinheight do
			for m = 1,tileinwidth do
				local quad = love.graphics.newQuad((m-1)*tileset.tilewidth,(n-1)*tileset.tileheight,tileset.tilewidth,tileset.tileheight,tileset[1].width,tileset[1].height)
				local canvas = love.graphics.newCanvas(tileset.tilewidth,tileset.tileheight)
				love.graphics.setCanvas (canvas)
				love.graphics.draw(tileset.image,quad)
				love.graphics.setCanvas()
				gid[counter]=canvas
				counter=counter+1
			end
		end
		i=i+1
	end
	return gid
end

function tiolved:layers(map,gid)
	local layers={}
	local number=1
	if map.orientation=="orthogonal" then
		for _,v in ipairs(map) do
			if v.je=="layer" then
				local layer={name=v.name,number=number}
				layer.canvas=love.graphics.newCanvas(map.width*map.tilewidth,map.height*map.tileheight)
				love.graphics.setCanvas(layer.canvas)
				j=1
				if v[j].je=="properties" then
					for _,k in ipairs(v[j]) do
						layer[k.name]=k.value
					end
					j=j+1
				end
				-- data :
				for k,l in ipairs(v[j]) do
					if l.gid~="0" then
						local tileheight=gid[tonumber(l.gid)]:getHeight()
						local pos={x=(k-1)%map.width*map.tilewidth,y=(math.ceil(k/map.width))*map.tileheight-tileheight}
						love.graphics.draw(gid[tonumber(l.gid)],pos.x,pos.y)
					end
				end
				love.graphics.setCanvas()
				table.insert(layers,layer)
				number=number+1
			end
		end
	elseif map.orientation=="isometric" then
		local gapx=(map.height-1)*map.tilewidth/2
		local gapy=0
		for _,canvas in ipairs(gid) do
			local height=canvas:getHeight()
			if height>gapy then 
				gapy=height
			end
		end
		gapy=gapy-map.tileheight

		for _,v in ipairs(map) do
			if v.je=="layer" then
				local layer={name=v.name,number=number}
				layer.canvas=love.graphics.newCanvas((map.width+map.height)*map.tilewidth/2,(map.width+map.height)*map.tileheight/2)
				j=1
				if v[j].je=="properties" then
					for _,k in ipairs(v[j]) do
						layer[k.name]=k.value
					end
					j=j+1
				end
				-- data :
				love.graphics.setCanvas(layer.canvas)
				for k,l in ipairs(v[j]) do
					if l.gid~="0" then
						local tileheight=gid[tonumber(l.gid)]:getHeight()
						local pos={x=(k-1)%map.width+1,y=math.ceil(k/map.width)}
						local ipos={}
						ipos.x=gapx+map.tilewidth/2*(pos.x-pos.y)
						ipos.y=gapy+map.tileheight/2*(pos.x+pos.y)-tileheight
						love.graphics.draw(gid[tonumber(l.gid)],ipos.x,ipos.y)
					end
				end
				love.graphics.setCanvas()
				table.insert(layers,layer)
				number=number+1
			end
		end
	end
	return layers
end

function tiolved:usefulfunc(map,gid)
	local toMap,toRender

	if map.orientation=="orthogonal" then
		function toMap(x,y)
			return x/map.tilewidth,y/map.tileheight
		end
		function toRender(x,y)
			return x*map.tilewidth,y*map.tileheight
		end
	elseif map.orientation=="isometric" then
		local gapx=map.height*map.tilewidth/2
		local gapy=0
		for _,canvas in ipairs(gid) do
			local height=canvas:getHeight()
			if height>gapy then 
				gapy=height
			end
		end
		gapy=gapy-map.tileheight

		function toMap(x,y)
			local xg=x-gapx
			local yg=y-gapy
			local a=map.tilewidth/2
			local b=map.tileheight/2
			local d=2/(map.tilewidth*map.tileheight)
			return d*(b*xg+a*yg),d*(-b*xg+a*yg)
		end
		function toRender(x,y)
			return (x-y)*map.tilewidth/2+gapx,(x+y)*map.tileheight/2+gapy
		end
	end
	return toMap,toRender
end

