-- Unique 8x8 tile counter for Aseprite tilemaps
-- Copyright 2022, NovaSquirel
-- 
-- Copying and distribution of this file, with or without modification, are permitted in any medium without royalty, provided the copyright notice and this notice are preserved. This file is offered as-is, without any warranty.

local pc = app.pixelColor
local sprite = app.activeSprite
if not sprite then return app.alert("There is no active sprite") end
local frameNumber = app.activeFrame.frameNumber

-- Does this table contain a value?
local function contains(t, element)
	for _, value in pairs(t) do
		if value == element then
			return true
		end
	end
	return false
end

-- Flip an 8x8 image's bytes only horizontally
local function horizFlipImageBytes(b, stride)
	local pixelSize = #b / 64
	local out = ''
	for y=0,7 do
		local line = string.sub(b, y*stride+1, (y+1)*stride-1+1)
		for x=7,0,-1 do
			out = out .. string.sub(line, x*pixelSize+1, (x+1)*pixelSize-1+1)
		end
	end
	return out
end

-- Flip an 8x8 image's bytes only vertically
local function vertFlipImageBytes(b, stride)
	local out = ''
	for y=7,0,-1 do
		out = out .. string.sub(b, y*stride+1, (y+1)*stride-1+1)
	end
	return out
end

-- Flip an 8x8 image's bytes horizontally and vertically
local function bothFlipImageBytes(b, stride)
	local pixelSize = #b / 64
	local out = ''
	for y=7,0,-1 do
		local line = string.sub(b, y*stride+1, (y+1)*stride-1+1)
		for x=7,0,-1 do
			out = out .. string.sub(line, x*pixelSize+1, (x+1)*pixelSize-1+1)
		end
	end
	return out
end

-- Check one tilemap and look at all of the used tiles
local function checkTilemap(layer)
	local cel = layer:cel(frameNumber)
	if cel == nil then return end

	-- Set up variables first
	local tileset = layer.tileset
	local tileWidth = tileset.grid.tileSize.width
	local tileHeight = tileset.grid.tileSize.height
	local spec8x8 = sprite.spec
	spec8x8.width = 8
	spec8x8.height = 8
	local used8x8Set = {}

	-- Find all of the used tileset entries
	usedTilesetEntries = {}
	for pixel in cel.image:pixels() do
		usedTilesetEntries[pc.tileI(pixel())] = true
	end

	-- Figure out how many unique 8x8 tiles there are in the used tileset entries
	local reused = 0
	local reusedFlips = 0
	local total = 0
	for key,value in pairs(usedTilesetEntries) do
		total = total + 1
		local fullImage = tileset:getTile(key)
		for x=1,tileWidth/8 do
			for y=1,tileHeight/8 do
				local tileImage = Image(spec8x8)
				tileImage:clear()
				tileImage:drawImage(fullImage, Point(-(x-1)*8, -(y-1)*8))

				-- Check if the 8x8 tile already exists in the set of used ones, otherwise add it
				local b = tileImage.bytes
				if contains(used8x8Set, b) then
					reused = reused + 1
				elseif contains(used8x8Set, horizFlipImageBytes(b, tileImage.rowStride)) then
					reusedFlips = reusedFlips + 1
				elseif contains(used8x8Set, vertFlipImageBytes(b, tileImage.rowStride)) then
					reusedFlips = reusedFlips + 1
				elseif contains(used8x8Set, bothFlipImageBytes(b, tileImage.rowStride)) then
					reusedFlips = reusedFlips + 1
				else
					table.insert(used8x8Set, b)
				end
			end
		end
	end
	app.alert{title=layer.name, text={"Unique: " .. #used8x8Set, "Reused (all): " .. reused+reusedFlips, "Reused (flips): " .. reusedFlips, "Metatiles: " .. total}}
end

-- Recursively find all of the layers
local function findLayers(layers)
	for i,layer in ipairs(layers) do
		if layer.isTilemap then
			checkTilemap(layer)
		elseif layer.isGroup then
			findLayers(layer.layers)
		end
	end
end

findLayers(sprite.layers)
