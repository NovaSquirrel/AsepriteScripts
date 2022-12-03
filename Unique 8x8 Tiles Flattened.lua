-- Unique 8x8 tile counter for Aseprite sprites
-- Copyright 2022, NovaSquirel
-- 
-- Copying and distribution of this file, with or without modification, are permitted in any medium without royalty, provided the copyright notice and this notice are preserved. This file is offered as-is, without any warranty.

-- This script looks at all of the visible layers in the current frame of an Aseprite sprite,
-- then calculates how many unique 8x8 tiles there are if it was treated as one layer, taking flips into account.

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

local function checkLayer(layer)
	local cel = layer:cel(frameNumber)
	if cel == nil then return end

	local imageWidth = cel.image.width
	local imageHeight = cel.image.height

	local used8x8Set = {}
	local reused = 0
	local reusedFlips = 0
	local total = 0

	for x=1,imageWidth/8 do
		for y=1,imageHeight/8 do
			local tileImage = Image(8, 8, cel.image.colorMode)
			tileImage:clear()
			tileImage:drawImage(cel.image, Point(-(x-1)*8, -(y-1)*8))

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

	app.alert{title=layer.name, text={"Unique: " .. #used8x8Set, "Reused (all): " .. reused+reusedFlips, "Reused (flips): " .. reusedFlips}}
end

-- Recursively find all of the layers
local function findLayers(layers)
	for i,layer in ipairs(layers) do
		if layer.isVisible and layer.isImage then
			checkLayer(layer)
		end
	end
end

app.command.FlattenLayers({visibleOnly = true})
findLayers(sprite.layers)
app.command.Undo()
