--LIDAR mod made by malario
--if you can read this then hi
--reading through this code might make it a lot less scary so yeah
--continue at your own peril
---------------------------------

--higher maxblips DONE
--different colors based on distance from player DONE
--whole-screen snapshots scale with maxblips DONE
--dynamic color mode? (dynamic stuff different color from static stuff) DONE
--different colors for colorMode 1 DONE

--future plans maybe:
--deployable scanner tower thingy
--even more spookiness. NextBot maybe?
--custom scanner model lol
--material color mode

--CANT DO FOR NOW
--some way to confuse player. make map feel inverted? -> invert horizontal turning, flip blip display horizontally.

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

	slider = (maxblips / 100000) * 300
	updateSlider = (updaterate / 50) * 300
	hueSlider = (hue / 359) * 359
	lasthue = hue
	
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

	shadowBlips = 0
	rebootDone = false
	messageTimer = 0
	messageStage = 0
	messageLine = 0
	spookyMan = 0

	RegisterTool("lidargun", "LIDAR", "MOD/gun.vox", 2)
	SetBool("game.tool.lidargun.enabled", true)

	menuOpen = false
	timeSinceLastMessage = 0
	logCleared = true
	messages = {
	{text = {"view_Finder_v2 disabled", "Initializing backup systems...", "Done!"}, time = {0, 0.5, 2}},
	{text = {"Rebooting view_Finder_v2...", "Disabling backup systems...", "Done!"}, time = {0, 2, 2.5}},
	{text = {'[string "...tent/1167630/2831953724/main.lua"]:491: attempt to index local'.." 'material' (a nil value)", "resolving problems...", "rebooting view_Finder_v1...", "Done!"}, time = {0.2, 2, 4, 6}},
	{text = {"Unknown presence detected nearby", "Recommended action: avoid if possible"}, time = {0, 1}}
	}
	--content/1167630/2831953724/main.lua    
	--"...32chars"

	startExposure = GetEnvironmentProperty("exposure") --doesnt fully work idk why
	startAmbience = GetEnvironmentProperty("ambience")

	if startExposure == 0 then
		startExposure = 1
	end

	--sounds
	blipSound = LoadSound("warning-beep.ogg")
	spark = LoadSound("spark0.ogg")
	turnOff = LoadSound("screen-off.ogg")
	turnOn = LoadSound("clickup.ogg")
	spookyBuzz = LoadSound("light/fluorescent0.ogg")
	click = LoadSound("clickdown.ogg")
	boom = LoadSound("explosion/l0.ogg")
end

function draw(dt)

	cam = GetPlayerCameraTransform()

	if InputPressed("g") and not consoleActive then --make dark

		if dark then
			dark = false

			messageStage = 1
			messageLine = 2
			messageTimer = 0
			consoleActive = true			

		else
			dark = true

			messageStage = 1
			messageLine = 1
			messageTimer = 0
			consoleActive = true
			
		end
	end

	ToolStuff(dt)

	UpdateColors(colorMode, updaterate)

	if blipsVisible then

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
			if UiTextButton("Return", 20, 20) then
				menuOpen = false

				if not dark then
					SetEnvironmentProperty("exposure", startExposure)
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
			SetEnvironmentProperty("exposure", 0, 0)
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

			if colorMode > 4 then
				colorMode = 1
			end

			ColorUpdatedTicks = 0

			PlaySound(turnOn)
		end
	end
end

function renderBlips(mode)

	for i=1, #blips do 
		local blip = blips[i]

		local color = colors[i]

		DebugCross(blip[1], color[1], color[2], color[3])
	end
end

function UpdateColors(mode, ColorUpdateTicks)

	if #colors < maxblips then
		for i=1, maxblips do
			colors[i] = {1, 1, 1}
		end
	end

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
				local material, r, g, b = GetShapeMaterialAtPosition(blips[i][2], blips[i][1])
				colors[i] = {r, g, b}
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
		end

		ColorUpdatedTicks = ColorUpdatedTicks + 1

	elseif colorMode == 3 then --keep updating if colorMode 3
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

		if colorMode == 1 then
			if customcolor then
				colors[lastblip + 1] = ColorThing(hue)
			else
				colors[lastblip + 1] = {1, 1, 1}
			end
		elseif colorMode == 2 then
			local material, r, g, b = GetShapeMaterialAtPosition(shape, hitPos)
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
	--if InputPressed("o") then
	--	SpawnSpookyMan()
	--end

	if shadowBlips > shadowBlipLimit then
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
		Delete(spookyMan)
		spookyMan = 0
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
			
			entityDist = dist - buffer

			entityPos = VecAdd(playerTrans.pos, VecScale(fwd, entityDist))
			entityRot = QuatLookAt(entityPos, playerTrans.pos)
		end		

		if spookyMan ~= 0 then
			Delete(spookyMan)
		end

		if math.random(1, 100) ~= 1 then
			Spawn("MOD/spookyman.xml", Transform(entityPos, entityRot), true)
		else
			Spawn("MOD/what.xml", Transform(entityPos, entityRot), true)--what could this be
			PlaySound(boom)
		end

		spookyMan = FindBody("spookyman")
		spookyTrans = GetBodyTransform(spookyMan)

		if rebootDone then
			PlaySound(spookyBuzz, spookyTrans.pos, 10)
			PlaySound(spookyBuzz, spookyTrans.pos, 10)
			PlaySound(spookyBuzz, spookyTrans.pos, 10)
			PlaySound(spookyBuzz, spookyTrans.pos, 10)
			PlaySound(spookyBuzz, spookyTrans.pos, 10)
		end

		shadowBlipLimit = math.min(shadowBlipLimit + 50, 500)
	end
end

function Console(i, message, timer)
	local active = true

	local line = messages[i]

	if timer >= line.time[message] then

		DebugPrint(line.text[message])

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
			if messageStage == 2 then
				SetEnvironmentProperty("exposure", 0, 0)

				if rebootDone then
					SetEnvironmentProperty("ambience", "indoor/cave.ogg")
				end

			elseif messageStage == 4 then
				blipsVisible = true
				PlaySound(turnOn)

				if spookyMan ~= 0 then
					Spawn("MOD/spookyman.xml", Transform(entityPos), true)
					spookyMan = FindBody("spookyman")
					spookyTrans = GetBodyTransform(spookyMan)
				end

				if not firstEnableDone then
					Snapshot(math.floor(math.sqrt(maxblips)), cam, maxdist)
					firstEnableDone = true
				end
			end

		elseif messageLine == 2 then
			if messageStage == 2 then
				if spookyMan ~= 0 then
					spookyTrans = GetBodyTransform(spookyMan)
					Delete(spookyMan)
				end

			elseif messageStage == 3 then
				SetEnvironmentProperty("exposure", startExposure)
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

	if not logCleared and timeSinceLastMessage > 7 then
		for i=1, 20 do
			DebugPrint("")
		end

		logCleared = true
	end

	timeSinceLastMessage = timeSinceLastMessage + dt
	messageTimer = messageTimer + dt
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