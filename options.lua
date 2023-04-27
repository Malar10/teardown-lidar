function init()
	if HasKey("savegame.mod.maxblips") then
		maxblips = GetFloat("savegame.mod.maxblips")
	else
		maxblips = 20000
	end

	if HasKey("savegame.mod.hue") then
		hue = GetFloat("savegame.mod.hue")
	else
		hue = 0
	end

	if HasKey("savegame.mod.customcolor") then
		customcolor = GetBool("savegame.mod.customcolor")
	else
		customcolor = false
	end

	if HasKey("savegame.mod.updaterate") then
		updaterate = GetFloat("savegame.mod.updaterate")
	else
		updaterate = 10
	end

	if HasKey("savegame.mod.spookiness") then
		spookiness = GetBool("savegame.mod.spookiness")
	else
		spookiness = true
	end

	slider = (maxblips / 100000) * 300
	updateSlider = (updaterate / 50) * 300
	hueSlider = (hue / 359) * 300
	lasthue = hue
	ColorUpdatedTicks = 0
end

function draw()
	menu()

	UiPush()
		UiColor(1, 1, 1)
		UiTranslate(UiCenter(), UiHeight() - 125)
		UiFont("bold.ttf", 80)
		if UiTextButton("Return", 20, 20) then
			Menu()
		end
	UiPop()
end


function menu()
	
	UiAlign("center top")
	UiButtonHoverColor(0.6, 0.6, 0.6)

	UiPush()
		UiColor(1, 1, 1)
		UiTranslate(UiCenter(), 75)
		UiFont("bold.ttf", 80)
		UiText("LIDAR menu", true)
	UiPop()

	UiTranslate(UiWidth() / 4, 0)

	UiPush()
		UiColor(1, 1, 1)
		UiTranslate(UiCenter(), UiHeight() / 4)
		UiFont("bold.ttf", 80)
		UiText("Options", true)
	UiPop()

	UiPush()
		UiColor(1, 1, 1)
		UiTranslate(UiCenter(), UiHeight() / 2.8)
		UiFont("bold.ttf", 50)
		--UiAlign("left top")
	
		if spookiness then
			if UiTextButton("[X] Spookiness", 20, 20) then
				spookiness = false
				SetBool("savegame.mod.spookiness", false)
			end
			UiTranslate(0, 70)
			UiFont("bold.ttf", 35)
			UiText("Spooky", true)
		else
			UiColor(0.7, 0.7, 0.7)
			if UiTextButton("[    ] Spookiness", 20, 20) then
				spookiness = true
				SetBool("savegame.mod.spookiness", true)
			end
			UiTranslate(0, 70)
			UiFont("bold.ttf", 35)
			UiText("No spooky", true)
		end
	UiPop()

	UiPush()
		UiTranslate(UiCenter(), UiHeight() / 2.1)
		
		UiFont("bold.ttf", 50)

		if customcolor then
			if UiTextButton("[X] Custom color:") then
				customcolor = false
				SetBool("savegame.mod.customcolor", false)
				ColorUpdatedTicks = 0
			end

			rgb = ColorThingy(hue)
			UiColor(rgb[1], rgb[2], rgb[3])
			UiTranslate(200, 0)
			UiRect(50, 50)
			

			UiAlign("left top")
			UiTranslate(-375, 60)
			
			UiTranslate(20, 15)
			UiColor(1, 1, 1)
			UiImageBox("ui/common/box-solid-6.png", 316, 16, 6, 6)
			UiColor(0.1, 0.1, 0.1)
			hueSlider = UiSlider("ui/common/dot.png","x",hueSlider, 0, 300)

			hue = (hueSlider / 359) * 300
			if hue ~= lasthue then
				ColorUpdatedTicks = 0
			end
			SetFloat("savegame.mod.hue", hue)
			lasthue = hue
		else
			if UiTextButton("[   ] Custom color") then
				customcolor = true
				SetBool("savegame.mod.customcolor", true)
				ColorUpdatedTicks = 0
			end

			UiColor(1, 1, 1)
			UiTranslate(200, 0)
			UiRect(50, 50)
		end
	UiPop()

	UiPush()
		UiTranslate(UiCenter(), UiHeight() / 1.7)
		

		if maxblips < 30000 then
			UiColor(0.5, 1, 0.5)
		elseif maxblips < 50000 then
			UiColor(1, 1, 0)
		elseif maxblips < 80000 then
			UiColor(1, 0.5, 0)
		else
			UiColor(1, 0, 0)
		end
		UiFont("bold.ttf", 40)
		UiText("Maximum blips: "..math.floor(maxblips+0.5), true)

		UiAlign("left top")
		UiTranslate(-175, 0)
		
		UiTranslate(20, 15)
		UiColor(1, 1, 1)
		UiImageBox("ui/common/box-solid-6.png", 316, 16, 6, 6)
		UiColor(0.1, 0.1, 0.1)
		slider = UiSlider("ui/common/dot.png","x",slider, 0, 300)

		maxblips = ((slider / 300) * 100000)
		SetFloat("savegame.mod.maxblips", maxblips)
	UiPop()

	UiPush()
		UiTranslate(UiCenter(), UiHeight() / 1.45)
		
		UiFont("bold.ttf", 40)
		UiText("Color update time: "..math.floor(updaterate+0.5), true)

		UiAlign("left top")
		UiTranslate(-175, 0)
		
		UiTranslate(20, 15)
		UiColor(1, 1, 1)
		UiImageBox("ui/common/box-solid-6.png", 316, 16, 6, 6)
		UiColor(0.1, 0.1, 0.1)
		updateSlider = UiSlider("ui/common/dot.png","x",updateSlider, 0, 300)

		updaterate = math.max(((updateSlider / 300) * 50), 1)
		SetFloat("savegame.mod.updaterate", updaterate)
	UiPop()

	UiPush()
		UiColor(1, 1, 1)
		UiTranslate(UiWidth() / 2, UiHeight() / 1.25)
		UiFont("bold.ttf", 70)
		if UiTextButton("Reset to Defaults", 20, 20) then
			maxblips = 20000
			slider = (maxblips / 100000) * 300
			spookiness = true

			updaterate = 10
			updateSlider = (updaterate / 50) * 300
			
			ColorUpdatedTicks = 0
			hue = 0
			lasthue = hue
			hueSlider = (hue / 359) * 300
			customcolor = false

			SetFloat("savegame.mod.maxblips", maxblips)
			SetBool("savegame.mod.spookiness", spookiness)
			SetFloat("savegame.mod.hue", hue)
			SetBool("savegame.mod.customcolor", customcolor)
			SetFloat("savegame.mod.updaterate", updaterate)
		end
	UiPop()
	UiTranslate(-UiWidth() / 4, 0)


	UiPush()
		UiColor(1, 1, 1)
		UiTranslate(UiWidth() / 4, UiHeight() / 4)
		UiFont("bold.ttf", 80)
		UiText("Controls", true)
		UiFont("bold.ttf", 30)
		UiText("(can't be changed for now)")
	UiPop()

	UiPush()
		UiColor(1, 1, 1)
		UiTranslate(UiWidth() / 8, UiHeight() / 2.7)
		UiAlign("left top")
		UiFont("bold.ttf", 45)
		UiText("[G] toggle LIDAR on/off", true)
		UiText("[B] clear all blips", true)
		UiText("[N] change display color mode", true)
		UiText("", true)

		UiText("Scanner tool in hand:", true)
		UiText("[E]/[Q] increase/decrease scanner radius", true)
		UiText("[lmb] scan in a circular shape", true)
		UiText("[mmb] toggle low-quality automatic scanning", true)
		UiText("[rmb] take a high-quality snapshot,\n              using up all available blips", true)
	UiPop()
end


function ColorThingy(H)
	--0 <= H < 360
	--0 <= S <= 1
	--0 <= V <= 1

	X = (1 - math.abs( ((H / 60) % 2) - 1 ) )

	if H < 60 then
		RGB = {1, X, 0}
	elseif H < 120 then
		RGB = {X, 1, 0}
	elseif H < 180 then
		RGB = {0, 1, X}
	elseif H < 240 then
		RGB = {0, X, 1}
	elseif H < 300 then
		RGB = {X, 0, 1}
	elseif H < 360 then
		RGB = {1, 0, X}
	end

	return RGB
end