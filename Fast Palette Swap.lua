-- Fast palette swapper for Aseprite
-- Copyright 2021, NovaSquirel
-- 
-- Copying and distribution of this file, with or without modification, are permitted in any medium without royalty, provided the copyright notice and this notice are preserved. This file is offered as-is, without any warranty.

function switch_to_palette(fname)
	if fname == "" then return end

	local newPalette = Palette{ fromFile=fname }
	if not newPalette then
		print("Could not load palette")
		return
	end
	oldPalette = app.activeSprite.palettes[1]
	if #newPalette < #oldPalette then  -- Never move to a smaller palette, to be safe
		newPalette:resize(#oldPalette)
	end
	app.activeSprite:setPalette(newPalette)
end

local dlg = Dialog("Fast Palette Swap")
dlg
  :button{text="1",onclick=function() switch_to_palette(dlg.data.pal1) end}
  :button{text="2",onclick=function() switch_to_palette(dlg.data.pal2) end}
  :button{text="3",onclick=function() switch_to_palette(dlg.data.pal3) end}
  :button{text="4",onclick=function() switch_to_palette(dlg.data.pal4) end}
  :newrow()
  :file{ id="pal1", title="Select a file for palette 1", open=true}
  :file{ id="pal2", title="Select a file for palette 2", open=true}
  :file{ id="pal3", title="Select a file for palette 3", open=true}
  :file{ id="pal4", title="Select a file for palette 4", open=true}
  :show{wait=false}
