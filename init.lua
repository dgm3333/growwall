local growwallActive=false
local growwalkActive=false
local wallMaxHeight=10
local wallAutoExtend=false
local markerNodeType="wool:red"
local outputNodeType="default:sandstonebrick"

-- Import section
local importScale=1	-- Recommend leaving this at 1, as at the moment scaling hasn't been properly implemented- all it will do is create gaps between the blocks, and unless they are multiples of 2 the gaps will be relatively irregular
local importOffsetX=1000
local importOffsetY=10
local importOffsetZ=0

local bitmapFileName="/home/david/.minetest/mods/growwall/hogwarts.bmp"
local binvoxFileName="/home/david/.minetest/mods/growwall/Hogwarts.binvox"

-- binvox can be downloaded from:-
-- http://www.cs.princeton.edu/~min/binvox/
-- Instructions for using it are here:-
-- http://minecraft.gamepedia.com/Programs_and_editors/Binvox

-- to import binvox files (ie 3D meshes converted to voxels/nodes which can be directly imported into minetest use the following command line (for linux):-
--cd '/home/david/.minetest/mods/binvox' 
--./binvox -ri -bi 1 Hogwarts.obj	-- this converts a mesh to voxels, but keeps it hollow





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
			if node.name ~= markerNodeType then
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

		local f = assert(io.open(bitmapFileName, "rb"));
		local bmp = f:read("*a");
		f:close();

		voxManip = minetest.get_voxel_manip()
		DrawBitmap(bmp);
		voxManip = nil
	end,
})


minetest.register_chatcommand("/growbnv", {
	params = "",
	description = "Load a binvox file and place it in the minetest world",
	func = function(name, param)
		voxManip = minetest.get_voxel_manip()
		readBinvox()
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
				if (minetest.get_node(p).name == markerNodeType) then
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
	for dy=0,wallMaxHeight do
		local p = {x=pos.x, y=math.floor(pos.y+dy), z=pos.z}
		voxManip:read_from_map(p, p)

		-- place only replaces air and water
		--minetest.place_node(p, {name=outputNodeType})
		minetest.set_node(p, {name=outputNodeType})
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
	local bfType = ReadWORD(bytecode, offset);		-- 2 bytes the header field used to identify the BMP & DIB file
	if(bfType ~= 0x4D42) then
		error("Not a bitmap file (Invalid BMP magic value)");
		return;
	end
	local bfOffBits = ReadDWORD(bytecode, offset+10);	-- 4 bytes the offset, i.e. starting address, of the byte where the bitmap image data (pixel array) can be found.

	-------------------------
	-- Parse BITMAPINFOHEADER
	-------------------------
	minetest.chat_send_all("Parse BITMAPINFOHEADER")

	offset = 15; -- BITMAPFILEHEADER is 14 bytes long
	local biWidth = ReadDWORD(bytecode, offset+4);		-- 4 bytes the bitmap width in pixels (signed integer)
	local biHeight = ReadDWORD(bytecode, offset+8);		-- 4 bytes the bitmap height in pixels (signed integer)
	local biBitCount = ReadWORD(bytecode, offset+14);	-- 2 bytes the number of bits per pixel, which is the color depth of the image.
	local biCompression = ReadDWORD(bytecode, offset+16);	-- 4 bytes the compression method being used. 
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

	--The size of each row is rounded up to a multiple of 4 bytes (a 32-bit DWORD) by padding, which 
	--  must be appended to the end of the rows
	biRowLength = biWidth*biBitCount/8
	biRowLengthPadded = (math.floor((biRowLength/4)-0.00000001)+1)*4

	--Normally pixels are stored "upside-down" with respect to normal image raster scan order, 
	-- starting in the lower left corner, going from left to right, and then row by row from the bottom to the top of the image
	for y = biHeight-1, 0, -1 do
		offset = bfOffBits + 1 + biRowLengthPadded*y;
		for x = 0, biWidth-1 do
			local b = bytecode:byte(offset);
			local g = bytecode:byte(offset+1);
			local r = bytecode:byte(offset+2);
			offset = offset + 3;

			local wallHeight = math.floor((255 - r)/10)	-- use r channel of RGB for wall height
			if wallHeight>0 then
				if (nodeCount % 1000) == 0 then
					minetest.chat_send_all("placed ".. nodeCount.. " pixels/nodes")
				end
				nodeCount = nodeCount+1
				for height = 0, wallHeight do
					local p = {x=((x*importScale)+importOffsetX), y=((height*importScale)+importOffsetY), z=((y*importScale)+importOffsetZ)}
					voxManip:read_from_map(p, p)

					minetest.set_node(p, {name=outputNodeType})
	--				end
				end
			end
		end
	end
	minetest.chat_send_all("completed placing nodes")
end


-- Process a binvox file, and create nodes
-- chatcommand("/growbnv"
function readBinvox()

--	local voxels
	local dimX, dimY, dimZ = 0,0,0
	local size
	local tx, ty, tz
	local scale

	local binvoxFileName="/home/david/.minetest/mods/binvox/Hogwarts.binvox"
	
	io.input(io.open(binvoxFileName, "rb"))


	--
	-- read header
	--
	line = io.read("*line")
        if line:find("#binvox") == nil then
		minetest.chat_send_all("Error: first line reads [".. line.. "] instead of [#binvox]")
		return false;
	end
	print(line)

--	version_string = line.substring(8);
--	version = Integer.parseInt(version_string);
--	print("reading binvox version " + version);

	local done = false
	while (done==false) do

		line = io.read("*line")
		print(line)

	        if line:find("data") ~= nil then
			done = true;
		else
		        if line:find("dim") ~= nil then
--				local dimensions = {}
--				for dimension in line:gmatch("%S+") do table.insert(dimensions, dimension) end
				dimX = 256	--tonumber(dimensions[1])
				dimY = 256	--tonumber(dimensions[2])
				dimZ = 256	--tonumber(dimensions[3])
				print("binvox dimensions: X:".. tostring(dimX).. ", Y:".. tostring(dimY).. ", Z:".. tostring(dimZ));
				minetest.chat_send_all("binvox dimensions: X:".. tostring(dimX).. ", Y:".. tostring(dimY).. ", Z:".. tostring(dimZ));
			else
			        if line:find("translate") ~= nil then
					-- tx = binvox_data.read(2);
					-- ty = binvox_data.read(2);
					-- tz = binvox_data.read(2);
				else
				        if line:find("scale") ~= nil then
						-- scale = binvox_data.read(2);
					else
						minetest.chat_send_all("  unrecognized keyword [".. line.. "], skipping");
					end
				end
			end
		end
	end  -- while

	if (done == false) then
		minetest.chat_send_all("binvox: error reading header");
		return false;
	end
	if (dimX == 0) then
		minetest.chat_send_all("binvox: missing dimensions in header");
		return false;
	end

	local size = dimX * dimY * dimZ
--	local voxels[size];

	--
	-- read voxel data
	--
	local value, count, index, end_index, nodeCount, x, y, z, zwpy = 0,0,0,0,0,0,0,0,0

	print("**********")
	minetest.chat_send_all("Reading binvox data")
	while (end_index < size) do
		value=0
		while (value==0) do
			print("V:".. tostring(value).. " C:".. tostring(count).. " I:".. tostring(index))
			index = index + count
			if (index > size) then 
				io.close()
				return false 
			end
			value = string.byte(io.read(1))	-- this will be a 1 if voxel is present, else 0/nil if not
			count = string.byte(io.read(1))	-- this is the number of times value will be repeated along the axis
			if (count == 0) then 
				io.close()
				return false 
			end
		end

		x = math.floor(index / (dimY*dimZ))
		zwpy = index % (dimY*dimZ) 	-- z*w + y
		z = math.floor(zwpy / dimX)
		y = zwpy % dimX

		end_index = index + count
		for i = 0, count do 
--			voxels[i] = value 
			print("binvox voxel: X:".. x.. ", Y:".. y.. ", Z:".. z)
			-- applying no scaling means the entire model will take up a 256x256x256 node cube
			-- scaling is set in the locals (visible to the entire mod) in the first section
			local p = {x=((-x*importScale)+importOffsetX), y=((y*importScale)+importOffsetY), z=((z*importScale)+importOffsetZ)}		-- -ve x corrects mirroring from blender obj output - not sure if this is universal
			voxManip:read_from_map(p, p)
			minetest.set_node(p, {name=outputNodeType})
			y = y + 1
			nodeCount = nodeCount + 1
			if (nodeCount % 1000) == 0 then
				minetest.chat_send_all("placed ".. nodeCount.. " nodes/voxels")
			end
		end

	end  -- while

	minetest.chat_send_all("Completed placement of ".. nodeCount.. " nodes/voxels")
	print("  read ".. nodeCount.. " voxels")
	io.close()
	return true

end  -- read_binvox

  

