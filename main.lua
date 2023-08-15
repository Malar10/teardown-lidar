--LIDAR mod made by malario
--if you can read this then hi
--reading through this code might make it a lot less scary so yeah
--continue at your own peril
---------------------------------

--Big june update
--make darkness actually dark
--fix color update going crazy if you change max blip amount
--spooky man shards should have the tags as well
--voxel color mode doesnt work if you break the voxels
  --but scanning might be a little laggier
--press esc to leave options
--color mode that shows if things have moved
--a lot more spookiness
--made code a little less messy i hope

--smol june update
--stopped color update happening even if not in dark mode
--stopped unnecessarily filling color array with empty values when increasing blip limit


--august update
--added a warning for mod conflicts
--fixed custom color missing colors
--fixed glitchy text actually breaking sometimes
--added text when you      a spooky man


#include "options.lua"

function init()
	maxdist = 75 --max range of the scanner
	safeScans = 10 --scans until it notices
	spookyManChance = 10 --1 in spookyManChance of something happening
	shadowBlipLimit = 0 --dissappears immediately at the start, increases after every encounter
	spookyManDist = 15


	--stuff you shouldnt change starts here
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

	--options stuff dont delete
	slider = (maxblips / 100000) * 300
	updateSlider = (updaterate / 50) * 300
	hueSlider = (hue / 300) * 359
	lasthue = hue
	-----------------------------
	
	blips = {} 
	lastblip = 0
	blipsVisible = false
	dark = false
	recording = false
	firstEnableDone = false
	colorMode = 1
	recordTime = 1
	recordTimer = recordTime
	radius = 400

	colors = {}
	ColorUpdatedTicks = 0

	voxValues = {}

	shadowBlips = 0
	rebootDone = false
	messageTimer = 0
	messageStage = 0
	messageLine = 0
	spookyMan = 0
	angry = false

	RegisterTool("lidargun", "LIDAR", "MOD/gun.vox", 2)
	SetBool("game.tool.lidargun.enabled", true)

	menuOpen = false
	timeSinceLastMessage = 0
	logCleared = true
	messages = {
	{text = {"disabling view_Finder_v2...", "Initializing backup systems...", "Done!"}, time = {0, 0.75, 2}},
	{text = {"Rebooting view_Finder_v2...", "Disabling backup systems...", "Done!"}, time = {0, 2, 2.5}},
	{text = {'[string "...tent/1167630/2831953724/main.lua"]:491: attempt to index local'.." 'material' (a nil value)", "resolving problems...", "rebooting backup systems...", "Done!"}, time = {0.2, 2, 4, 6}},
	{text = {"Unusual energy readings detected nearby", "Recommended actions:", "-stay vigilant", "-avoid if possible", "-do not inter ct w th t e      s  ", ""}, time = {0, 1, 1.6, 2.2, 3, 3.6}},
	{text = {"Systems failing", "Error", "{Hyperlink Blocked}"}, time = {0, 0, 0}},
	{text = {"you can't run", "they are angry", "you did this to yourself"}, time = {0, 0, 0}},
	{text = {"", "========LIDAR WARNING========", "possible mod conflict detected", "disable any mods that may affect the color balance settings", "", "known conflicting mods:", "-Blink (mod id: 2875792342)", "", "sorry for the inconvenience"}, time = {0, 0, 1, 2, 3, 3, 3, 3, 4}},
	{text = {"you should not have done that"}, time = {1}}
	}
	--content/1167630/2831953724/main.lua    
	--"...32chars"

	local r,g,b = GetPostProcessingProperty("colorbalance")
	startColorbalance = {r, g, b}
	startAmbience = GetEnvironmentProperty("ambience")

	dontclear = false
	WarningDone = false

	--sounds
	blipSound = LoadSound("warning-beep.ogg")
	spark = LoadSound("spark0.ogg")
	turnOff = LoadSound("screen-off.ogg")
	turnOn = LoadSound("clickup.ogg")
	spookyBuzz = LoadSound("light/fluorescent0.ogg")
	click = LoadSound("clickdown.ogg")
	boom = LoadSound("explosion/l0.ogg")
	glassbreak = LoadSound("glass/break-l0.ogg")
end

function draw(dt)

	cam = GetPlayerCameraTransform()

	

	if InputPressed("g") and not consoleActive then --toggle darkness
		PlaySound(click)

		if not angry or (spookiness == false) then
			if dark then
				messageLine = 2		
			else
				messageLine = 1
			end

			messageStage = 1
			messageTimer = 0
			consoleActive = true

		else

			--choose a bunch of random messages and cut them at random parts

			local stages = math.random(1, 5)
			local texts = {}
			local times = {}
			for i=1, stages do
				local j = math.random(1, #messages)
				local h = math.random(1, #messages[j].text)
				local randommessage = messages[j].text[h]

				if string.len(randommessage) > 1 then
					local s = math.min(math.random(1, #randommessage), 6)
					local e = math.random(s, #randommessage)
					table.insert(texts, string.sub(randommessage, s, e))
				else
					table.insert(texts, randommessage)
				end

				table.insert(times, i - 1)
			end

			table.insert(messages, {text = texts, time = times})

			messageStage = 1
			messageLine = #messages
			messageTimer = 0
			consoleActive = true

		end
	end

	if dark and not IsActuallyDark() then
		dark = false

		if not WarningDone then
			WarningDone = true

			for i=1, 20 do
				DebugPrint("")
			end

			messageLine = 7 --send warning message
			messageStage = 1
			messageTimer = 0
			consoleActive = true

			dontclear = true
		end
    end

	ToolStuff(dt)

	if blipsVisible then

		UpdateColors(colorMode, updaterate)

		if recording then
			recordTimer = recordTimer + dt

			if recordTimer > recordTime then
				recordTimer = 0
				Snapshot(math.floor(math.sqrt(maxblips)) / 2, cam, maxdist)
			end
		end
	
		--///////////render blips\\\\\\\\\\\\\\\
		--optimizations here please i beg you

		renderBlips(colorMode)

		
		--\\\\\\\\\\\render blips/////////////
	end


	SpookyStuff(dt)

	ConsoleStuff(dt)

	if menuOpen then
		UiMakeInteractive()
		menu()

		UiPush()
			UiColor(1, 1, 1)
			UiTranslate(UiCenter(), UiHeight() - 125)
			UiFont("bold.ttf", 80)
			if UiTextButton("Return", 20, 20) or InputPressed("esc") then
				menuOpen = false

				if not dark then
					SetPostProcessingProperty("colorbalance", startColorbalance[1], startColorbalance[2], startColorbalance[3])
				else
					blipsVisible = true
				end
			end
		UiPop()
	end


	--DebugWatch("blips", #blips)
	--DebugWatch("dt", dt)
	--DebugWatch("lastblip", lastblip)
	--DebugWatch("colorMode", colorMode)
	--DebugWatch("shadowBlipLimit", shadowBlipLimit)
	--DebugWatch("safeScans", safeScans)
end

function tick()
	if PauseMenuButton("LIDAR settings") then
		menuOpen = true

		if not dark then
			SetPostProcessingProperty("colorbalance", 0, 0, 0)
		else
			blipsVisible = false
		end
	end
end

function ToolStuff(dt)
	if GetString("game.player.tool") == "lidargun" then
		SetToolTransform(Transform(Vec(0.3, -0.4, -0.5), Quat()))
		
		if blipsVisible then

			if InputDown("e") then
				radius = math.min(1000, radius + dt * radius * 2)
			elseif InputDown("q") then
				radius = math.max(50, radius - dt * radius * 2)
			end

			if InputDown("lmb") then --single blip stream
				--Circle(radius, cam, maxdist)
				RandomCircle(radius, 50, cam, maxdist)
			end

			if InputPressed("rmb") then --use all blips for high quality shot
				if safeScans <= 0 then
					if math.random(1, spookyManChance) == spookyManChance then --sometimes spawn spooky man
						SpawnSpookyMan()
					end
				else
					if safeScans == 1 and spookiness == true then
						messageStage = 1
						messageLine = 4
						messageTimer = 0
						consoleActive = true
					end
					safeScans = safeScans - 1
				end

				blips = {}
				lastblip = 0
				Snapshot(math.floor(math.sqrt(maxblips)), cam, maxdist) --141 max res, lags a little
			end

			if InputPressed("mmb") then --start recording
				if recording then
					recording = false
					PlaySound(click)
				else
					recording = true
					PlaySound(turnOn)
				end
			end
		end
	end

	if blipsVisible then
		if InputPressed("b") then
			blips = {}
			lastblip = 0
			PlaySound(turnOff)
		end

		if InputPressed("n") then
			colorMode = colorMode + 1

			if colorMode > 5 then
				colorMode = 1
			end

			ColorUpdatedTicks = 0

			PlaySound(turnOn)
		end
	end
end

function renderBlips(mode)
	local limit = math.min(#blips, maxblips)

	for i=1, limit do 
		local blip = blips[i]

		local color = colors[i]

		DebugCross(blip[1], color[1], color[2], color[3])
	end
end

function UpdateColors(mode, ColorUpdateTicks)

	if ColorUpdatedTicks < ColorUpdateTicks then
		start = math.floor(((ColorUpdatedTicks)/ColorUpdateTicks) * maxblips) + 1
		stop = math.min(((math.floor(ColorUpdatedTicks+1)/ColorUpdateTicks) * maxblips), #blips)

		--DebugPrint("start: "..start)
		--DebugPrint("stop: "..stop)
		--DebugPrint("blips: "..#blips)


		if mode == 1 then
			if customcolor then
				color = ColorThing(hue)
			else
				color = {1, 1, 1}
			end

			for i=start, stop do
				colors[i] = color
			end

		elseif mode == 2 then
			for i=start, stop do
				colors[i] = {voxValues[i][2], voxValues[i][3], voxValues[i][4]}
			end

		elseif mode == 3 then
			for i=start, stop do
				local dist = VecLength(VecSub(blips[i][1], cam.pos))
				local value = math.min(dist * 15, 240)
				colors[i] = ColorThing(value)
			end
		
		elseif mode == 4 then
			for i=start, stop do
				local dynamic = IsBodyDynamic(GetShapeBody(blips[i][2]))
				if dynamic then
					colors[i] = {0, 1, 0}
				else
					colors[i] = {0, 0, 1}
				end
			end
		elseif mode == 5 then
			for i=start, stop do
				local broke = GetShapeMaterialAtPosition(blips[i][2], blips[i][1]) ~= voxValues[i][1]
				if broke then
					colors[i] = {1, 0, 0}
				else
					colors[i] = {0, 1, 0}
				end
			end
		end

		ColorUpdatedTicks = ColorUpdatedTicks + 1

	elseif colorMode == 3 or colorMode == 5 then --keep updating
		ColorUpdatedTicks = 0
	end
end

function scanPoint(cam, dir, maxdist) --could use more optimization, but its not that bad
	hit, d, normal, shape = QueryRaycast(cam.pos, dir, maxdist, 0, true)

	if d < maxdist then
		local hitPos = VecAdd(cam.pos, VecScale(dir, d))

		if lastblip >= maxblips then
			lastblip = 0
		end

		--local color = {1, 1, 1}
		local material, r, g, b = GetShapeMaterialAtPosition(shape, hitPos)
		voxValues[lastblip + 1] = {material, r, g, b}

		if colorMode == 1 then
			if customcolor then
				colors[lastblip + 1] = ColorThing(hue)
			else
				colors[lastblip + 1] = {1, 1, 1}
			end
		elseif colorMode == 2 then
			colors[lastblip + 1] = {r, g, b}
		elseif colorMode == 3 then
			local dist = VecLength(VecSub(hitPos, cam.pos))
			local value = math.min(dist * 15, 240)
			colors[lastblip + 1] = ColorThing(value)
		elseif colorMode == 4 then
			local dynamic = IsBodyDynamic(GetShapeBody(shape))
			if dynamic then
				colors[lastblip + 1] = {0, 1, 0}
			else
				colors[lastblip + 1] = {0, 0, 1}
			end
		elseif colorMode == 5 then
			colors[lastblip + 1] = {0, 1, 0}
		end

		if not HasTag(shape, "error") then
			blips[lastblip + 1] = {hitPos, shape}
			lastblip = lastblip + 1
		else
			shadowBlips = shadowBlips + 1
			PlaySound(spark, cam.pos, 5)
		end
	end
end

function Snapshot(pixels, cam, maxdist)
	maxX = UiWidth()
	maxY = UiHeight()
	Xoffset = (UiWidth() / pixels) / 2
	Yoffset = (UiHeight() / pixels) / 2

	for x=1, pixels do
		for y=1, pixels do
			UiPush()
				if y%2 == 0 then
					UiTranslate(0, -Yoffset)
				else
					UiTranslate(-Xoffset, -Yoffset)
				end
				dir = UiPixelToWorld((x / pixels) * maxX, (y / pixels) * maxY)
			UiPop()

			scanPoint(cam, dir, maxdist)
		end
	end

	PlaySound(blipSound, cam.pos, 0.8)
end

function RandomCircle(radius, pPerT, cam, maxdist)

	for i=1, pPerT do
		x = math.random(-radius, radius)
		maxY = math.sqrt( (radius^2) - (x^2) )
		y = math.random(-maxY, maxY)


		dir = UiPixelToWorld(x + UiCenter() , y + UiMiddle())
		scanPoint(cam, dir, maxdist)

		PlaySound(blipSound, cam.pos, 0.1)
	end
end


function SpookyStuff()

	local spookyMen = FindBodies("spookyman")
	if #spookyMen ~= 0 then

		--stuff when close to spookyman
		local smallestdist = 10
		for i, spookyMan in ipairs(spookyMen) do
			local distfromspookyman = VecLength(VecSub(GetPlayerTransform().pos, GetBodyTransform(spookyMan).pos))
			if distfromspookyman < smallestdist then
				smallestdist = distfromspookyman
			end
		end

		if smallestdist < 2 then -- do damage if close to player
			SetPlayerHealth(GetPlayerHealth() - 0.005)

			glitchBlips(66.6 / math.max(GetPlayerHealth(), 0.05))
			
			if GetPlayerHealth() <= 0 then
				PlaySound(glassbreak, cam.pos, 10)
			end
		end


		if GetPlayerHealth() <= 0 or spookiness == false then
			angry = false
			spookyManChance = 10

			for i, spookyMan in ipairs(spookyMen) do
				Delete(spookyMan)
			end
		end

		for i, spookyMan in ipairs(spookyMen) do
			if IsBodyBroken(spookyMan) then

				messageLine = 8
				messageStage = 1
				messageTimer = 0
				consoleActive = true

				Delete(spookyMan)
				angry = true
				spookyManChance = 1
			end
		end

		if shadowBlips > shadowBlipLimit and not angry then
			if not rebootDone then
				messageStage = 1
				messageLine = 3
				messageTimer = 0
				consoleActive = true
				PlaySound(turnOff, cam.pos, 5)
	
				rebootDone = true
				spookyManChance = math.floor(spookyManChance / 2) --make it twice as likely to show up
				spookyManDist = spookyManDist - 5 
			end
	
			
			shadowBlips = 0
			local spookyMan = FindBody("spookyman")
			if spookyMan ~= 0 then
				Delete(spookyMan)
			end
		end
	end
end

function SpawnSpookyMan()
	if spookiness == true then
		buffer = 1

		local playerTrans = GetPlayerTransform()

		local thing = Transform(cam.pos, playerTrans.rot)

		local fwd = TransformToParentVec(thing, Vec(0, 0, -1))

		local hit, dist = QueryRaycast(thing.pos, fwd, spookyManDist)

		--DebugPrint(dist)

		if dist > buffer then
			
			--calculate position
			entityDist = dist - buffer
			local entityPos = VecAdd(playerTrans.pos, VecScale(fwd, entityDist))
			local entityRot = QuatLookAt(entityPos, playerTrans.pos)
			spookyTrans = Transform(entityPos, entityRot)
			
			--delete old spookyman
			local spookyMan = FindBody("spookyman")
			if spookyMan ~= 0 and not angry then
				Delete(spookyMan)
			end

			--spawn new spookyman
			if math.random(1, 100) ~= 1 or angry then
				Spawn("MOD/spookyman.xml", spookyTrans, true)
			else
				Spawn("MOD/what.xml", spookyTrans, true)--what could this be
				PlaySound(boom)
			end

			--play sounds
			if rebootDone then
				PlaySound(spookyBuzz, spookyTrans.pos, 10)
				PlaySound(spookyBuzz, spookyTrans.pos, 10)
				PlaySound(spookyBuzz, spookyTrans.pos, 10)
				PlaySound(spookyBuzz, spookyTrans.pos, 10)
				PlaySound(spookyBuzz, spookyTrans.pos, 10)
			end

			--increase blip limit
			shadowBlipLimit = math.min(shadowBlipLimit + 50, 500)
		end
	end
end

function Console(i, message, timer)
	local active = true

	local line = messages[i]

	if timer >= line.time[message] then

		if dontclear == false or i == 7 then
			DebugPrint(line.text[message])
		end

		if message + 1 > #line.text then
			active = false
		end

		message = message + 1

		timeSinceLastMessage = 0
		logCleared = false
	end

	return message, active
end

function ConsoleStuff(dt)
	if consoleActive then
		messageStage, consoleActive = Console(messageLine, messageStage, messageTimer)


		if messageLine == 1 then
			if messageStage == 3 then
				dark = true
				SetPostProcessingProperty("colorbalance", 0, 0, 0)

				if rebootDone then
					SetEnvironmentProperty("ambience", "indoor/cave.ogg")
				end

			elseif messageStage == 4 then
				blipsVisible = true
				PlaySound(turnOn)

				local spookyMan = FindBody("spookyman")
				if spookyMan == 0 then
					Spawn("MOD/spookyman.xml", spookyTrans, true)
				end

				if not firstEnableDone then
					Snapshot(math.floor(math.sqrt(maxblips)), cam, maxdist)
					firstEnableDone = true
				end
			end

		elseif messageLine == 2 then
			if messageStage == 2 then
				
				local spookyMan = FindBody("spookyman")
				if spookyMan ~= 0 then
					Delete(spookyMan)
				end

			elseif messageStage == 3 then
				dark = false
				SetPostProcessingProperty("colorbalance", startColorbalance[1], startColorbalance[2], startColorbalance[3])
				SetEnvironmentProperty("ambience", startAmbience)

			elseif messageStage == 4 then
				blipsVisible = false
				PlaySound(turnOff)
			end

		elseif messageLine == 3 then

			if messageStage == 2 then
				blipsVisible = false
				SetEnvironmentProperty("ambience", "")
			
			elseif messageStage == 5 then
				blipsVisible = true
				SetEnvironmentProperty("ambience", "indoor/cave.ogg")
				PlaySound(turnOn, cam.pos, 5)
				
				PlaySound(spookyBuzz, spookyTrans.pos, 10)
				PlaySound(spookyBuzz, spookyTrans.pos, 10)
				PlaySound(spookyBuzz, spookyTrans.pos, 10)
				PlaySound(spookyBuzz, spookyTrans.pos, 10)
				PlaySound(spookyBuzz, spookyTrans.pos, 10)
			end
		end
	end

	if not logCleared and timeSinceLastMessage > 7 and dontclear == false then
		for i=1, 20 do
			DebugPrint("")
		end

		logCleared = true
	end

	timeSinceLastMessage = timeSinceLastMessage + dt
	messageTimer = messageTimer + dt
end

function glitchBlips(intensity)
	if #blips > 0 then
		for i=1, math.random(1, intensity) do
			local randomoffset = Vec(((math.random(1, 200) - 100) * intensity) / 10000, ((math.random(1, 200) - 100) * intensity) / 10000, ((math.random(1, 200) - 100) * intensity) / 10000)
			local j = math.random(1, #blips)
			blips[j][1] = VecAdd(blips[j][1], randomoffset)
			colors[j] = ColorThing(math.random(1, 359))
			PlaySound(spark, blips[j][1], intensity / 666)
		end
	end
end

function ColorThing(H)
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

function IsActuallyDark()
	local r, g, b = GetPostProcessingProperty("colorbalance")
	if r ~= 0 or g ~= 0 or b ~= 0 then
		return false
	end
	return true
end