local growwallActive=false
local growwalkActive=false
local growwallMaxHeight=10
local growwallAutoExtend=false
local growwallNodeMarker="wool:red"
local growwallNodeTarget="default:sandstonebrick"
local growwallFileName="/home/david/.minetest/mods/growwall/sun.bmp"


-- Don't edit these
local voxManip		-- handle to a voxelmanipulator
local oldPos = {x=0,y=0,z=0}		-- players most recent position


minetest.register_chatcommand("/growwall", {
	params = "",
	description = "Activate growwall",
	func = function(name, param)
		growwallActive = not growwallActive
		if growwallActive == true then 
			minetest.chat_send_all("growwallActive=true")
		else
			minetest.chat_send_all("growwallActive=false")
		end

		-- possibly add params
		return true
	end,
})

minetest.register_on_punchnode(
	function(pos, node, puncher)
		if growwallActive == true then
			voxManip = minetest.get_voxel_manip()
			if node.name ~= growwallNodeMarker then
				growblock(pos)
			else
				checkSurround(pos)
			end
			voxManip = nil
		end
	end
)


minetest.register_chatcommand("/growbmp", {
	params = "",
	description = "Load a bmp and place it in the minetest world",
	func = function(name, param)

		local f = assert(io.open(growwallFileName, "rb"));
		local bmp = f:read("*a");
		f:close();

		voxManip = minetest.get_voxel_manip()
		DrawBitmap(bmp);
		voxManip = nil
	end,
})


minetest.register_chatcommand("/growwalk", {
	params = "",
	description = "Activate growwalk",
	func = function(name, param)
		growwalkActive = not growwalkActive
		if growwalkActive == true then
			local player = minetest.get_player_by_name("singleplayer")
			local oldPos = player:getpos()
			oldPos = {x=(math.floor(oldPos.x+0.5)), y=(math.floor(oldPos.y+0.5)), z=(math.floor(oldPos.z+0.5))}
 
			minetest.chat_send_all("growwalkActive=true")
			voxManip = minetest.get_voxel_manip()
		else
			minetest.chat_send_all("growwalkActive=false")
			voxManip = nil
		end
		return true
	end,
})


minetest.register_globalstep(function(dtime)
	if growwalkActive == true then
		local player = minetest.get_player_by_name("singleplayer")
		local pos = player:getpos()
		pos = {x=(math.floor(pos.x+0.5)), y=(math.floor(pos.y+0.5)), z=(math.floor(pos.z+0.5))}

		if pos.x~=oldPos.x or pos.z~=oldPos.z then
			growblock(oldPos)
			oldPos = pos
		end
	end
end)



------------------------------
-- Simple growth functions
------------------------------


function checkSurround(pos)
	for dy=-3,3 do
		for dx=-1,1 do
			for dz=-1,1 do
				local p = {x=pos.x+dx, y=pos.y+dy, z=pos.z+dz}
				voxManip:read_from_map(p, p)
				if (minetest.get_node(p).name == growwallNodeMarker) then
--					local p1 = {x=pos.x+dx, y=pos.y+1, z=pos.z+dz}
--					voxManip:read_from_map(p1, p1)
--					if (minetest.get_node(p1).name == "air") then
--						print(p.x..",".. p.y..",".. p.z)
						growblock(p)
						checkSurround(p)
--					end
				end
			end
		end
	end
end


function growblock(pos)
	print(pos.x..",".. pos.y..",".. pos.z)
	for dy=0,growwallMaxHeight do
		local p = {x=pos.x, y=math.floor(pos.y+dy), z=pos.z}
		voxManip:read_from_map(p, p)

		-- place only replaces air and water
		--minetest.place_node(p, {name=growwallNodeTarget})
		minetest.set_node(p, {name=growwallNodeTarget})
	end
end



------------------------------
-- BITMAP management functions
------------------------------

function error(err)
	-- Replace with your own error output method:
	minetest.chat_send_all(err)
	print("ERROR growwall:".. err)
end

-- Helper function: Parse a 16-bit WORD from the binary string
function ReadWORD(str, offset)
	local loByte = str:byte(offset);
	local hiByte = str:byte(offset+1);
	return hiByte*256 + loByte;
end

-- Helper function: Parse a 32-bit DWORD from the binary string
function ReadDWORD(str, offset)
	local loWord = ReadWORD(str, offset);
	local hiWord = ReadWORD(str, offset+2);
	return hiWord*65536 + loWord;
end

-- Process a bitmap file in a string, and call DrawPoint for each pixel
function DrawBitmap(bytecode)

	if 1==0 then
		-- This code could easily be used to modify the placement of the image
		local player = minetest.get_player_by_name(name)
		local pos = player:getpos()
		pos.x, pos.y, pos.z = math.floor(pos.x), math.floor(pos.y), math.floor(pos.z)



		for x = pos.x-1, pos.x+1 do
			for z = pos.z-1, pos.z+1 do
				minetest.place_node({x=x, y=pos.y, z=z}, {name="displayallnodes:Background"})
				minetest.place_node({x=x, y=pos.y+1, z=z}, {name="displayallnodes:Background"})
			end
		end
		minetest.remove_node(pos)
		minetest.place_node(pos, {name="displayallnodes:White"})
	   	meta = minetest.get_meta(pos)
		meta:set_string("nodeCount", 0);

		player:setpos({x=pos.x, y=pos.y+1, z=pos.z})
		player:set_look_yaw(0)
		player:get_look_pitch(0)

		local nodeMax = 0
		-- key is node name, eg default:stone	value is definition table
		for key, value in pairs(minetest.registered_nodes) do
			nodeMax = nodeMax + 1
		end
		minetest.chat_send_all("placing".. nodeMax.. " nodes")

	   	meta:set_string("nodeMax", nodeMax);
	end

	-------------------------
	-- Parse BITMAPFILEHEADER
	-------------------------
	minetest.chat_send_all("Parse BITMAPFILEHEADER")

	local offset = 1;
	local bfType = ReadWORD(bytecode, offset);
	if(bfType ~= 0x4D42) then
		error("Not a bitmap file (Invalid BMP magic value)");
		return;
	end
	local bfOffBits = ReadWORD(bytecode, offset+10);

	-------------------------
	-- Parse BITMAPINFOHEADER
	-------------------------
	minetest.chat_send_all("Parse BITMAPINFOHEADER")

	offset = 15; -- BITMAPFILEHEADER is 14 bytes long
	local biWidth = ReadDWORD(bytecode, offset+4);
	local biHeight = ReadDWORD(bytecode, offset+8);
	local biBitCount = ReadWORD(bytecode, offset+14);
	local biCompression = ReadDWORD(bytecode, offset+16);
	if(biBitCount ~= 24) then
		error("Only 24-bit bitmaps supported (Is " .. biBitCount .. "bpp)");
		return;
	end
	if(biCompression ~= 0) then
		error("Only uncompressed bitmaps supported (Compression type is " .. biCompression .. ")");
		return;
	end

	---------------------
	-- Parse bitmap image
	---------------------
	local player = minetest.get_player_by_name("singleplayer")
	nodeCount = 0
	for y = biHeight-1, 0, -1 do
		offset = bfOffBits + (biWidth*biBitCount/8)*y + 1;
		for x = 0, biWidth-1 do
			local b = bytecode:byte(offset);
			local g = bytecode:byte(offset+1);
			local r = bytecode:byte(offset+2);
			offset = offset + 3;

			local wallHeight = math.floor((255 - r)/10)	-- use r channel of RGB for wall height
			if wallHeight>0 then
				if (nodeCount % 50) == 0 then
					minetest.chat_send_all("placed ".. nodeCount.. " pixels")
				end
				nodeCount = nodeCount+1
				for height = 0, wallHeight do
					local p = {x=x, y=height, z=y}
					voxManip:read_from_map(p, p)

--					print((x).. ", 0, ".. (y).. ": ".. (wallHeight))
--					print(p.x.. ": ".. p.y.. ": ".. p.z.. ": ".. height)
					-- moving the player around might solves the problem with sections missing if blocks have not been generated, but is quite slow
--					player:setpos(p)
					--if you only want certain blocks replaced then use this conditional:-
	--				local n = minetest.get_node(p).name
	--				if (n == "air") then
					-- place only replaces air and water
	--				minetest.place_node(p, {name=growwallNodeTarget})
					minetest.set_node(p, {name=growwallNodeTarget})
	--				end
				end
			end
		end
	end
	minetest.chat_send_all("completed placing nodes")
end




