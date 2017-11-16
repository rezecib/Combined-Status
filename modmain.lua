Assets = {
	Asset("ATLAS", "images/status_bgs.xml"),
	Asset("ATLAS", "images/rain.xml"),
	
	--Note that the default behavior actually uses these for waxing, based on N Hemisphere moon
	Asset("ANIM", "anim/moon_waning_phases.zip"),
}

local DST = GLOBAL.TheSim:GetGameID() == "DST"
local ROG = DST or GLOBAL.IsDLCEnabled(GLOBAL.REIGN_OF_GIANTS)
local CSW = GLOBAL.rawget(GLOBAL, "CAPY_DLC") and GLOBAL.IsDLCEnabled(GLOBAL.CAPY_DLC)

local SHOWSTATNUMBERS = GetModConfigData("SHOWSTATNUMBERS")
local SHOWMAXONNUMBERS = GetModConfigData("SHOWMAXONNUMBERS")
local SHOWTEMPERATURE = GetModConfigData("SHOWTEMPERATURE")
local SHOWNAUGHTINESS = GetModConfigData("SHOWNAUGHTINESS") and not DST
local SHOWWORLDTEMP = GetModConfigData("SHOWWORLDTEMP")
local SHOWTEMPBADGES = GetModConfigData("SHOWTEMPBADGES")
local SHOWBEAVERNESS = GetModConfigData("SHOWBEAVERNESS")
local HIDECAVECLOCK = GetModConfigData("HIDECAVECLOCK")
local SHOWMOON = GetModConfigData("SHOWMOON")
local SHOWMOONDAY = SHOWMOON > 1
local SHOWMOONDUSK = SHOWMOON > 0
local SHOWWANINGMOON = GetModConfigData("SHOWWANINGMOON")
local SHOWNEXTFULLMOON = GetModConfigData("SHOWNEXTFULLMOON")
local FLIPMOON = GetModConfigData("FLIPMOON")
local waxingmoonanim = FLIPMOON and "moon_phases" or "moon_waning_phases"
local waningmoonanim = FLIPMOON and "moon_waning_phases" or "moon_phases"
local UNIT = GetModConfigData("UNIT")
local SEASONOPTIONS = GetModConfigData("SEASONOPTIONS")
local SHOWSEASONCLOCK = SEASONOPTIONS == "Clock"
local COMPACTSEASONS = SEASONOPTIONS == "Compact"
local MICROSEASONS = SEASONOPTIONS == "Micro"
local HUDSCALEFACTOR = GetModConfigData("HUDSCALEFACTOR")*.01

local UNITS =
{
	T = function(val) return math.floor(val+0.5) .. "\176" end,
	C = function(val) return math.floor(val/2 + 0.5) .. "\176C" end,
	F = function(val) return math.floor(0.9*(val) + 32.5).."\176F" end,
}
--Expose our unit and unit conversion functions to other mods that may deal with temperature
GLOBAL.TUNING.COMBINED_STATUS_UNITS = UNITS
GLOBAL.TUNING.COMBINED_STATUS_UNIT = UNIT

local RPGHUD = false
for _, moddir in ipairs(GLOBAL.KnownModIndex:GetModsToLoad()) do
    if string.match(GLOBAL.KnownModIndex:GetModInfo(moddir).name or "", "RPG HUD") then
		RPGHUD = true
    end
end

local require = GLOBAL.require
local Widget = require('widgets/widget')
local Image = require('widgets/image')
local Text = require('widgets/text')
local PlayerBadge = require("widgets/playerbadge" .. (DST and "" or "_combined_status"))
local Minibadge = require("widgets/minibadge")
if not DST then
	table.insert(Assets, Asset("ATLAS", "images/avatars_combined_status.xml"))
	table.insert(Assets, Asset("IMAGE", "images/avatars_combined_status.tex"))
	table.insert(Assets, Asset("ANIM", "anim/cave_clock.zip"))
end
local Badge = require("widgets/badge")

local function BadgePostConstruct(self)
	self:SetScale(.9,.9,.9)
	-- Make sure that badge scaling animations are adjusted accordingly (e.g. WX's upgrade animation)
	local _ScaleTo = self.ScaleTo
	self.ScaleTo = function(self, from, to, ...)
		return _ScaleTo(self, from*.9, to*.9, ...)
	end
	
	if not SHOWSTATNUMBERS then return end
	
	self.bg = self:AddChild(Image("images/status_bgs.xml", "status_bgs.tex"))
	self.bg:SetScale(.4,.43,0)
	self.bg:SetPosition(-.5, -40, 0)
	
	self.num:SetFont(GLOBAL.NUMBERFONT)
	self.num:SetSize(28)
	self.num:SetPosition(3.5, -40.5, 0)
	self.num:SetScale(1,.78,1)

	self.num:MoveToFront()
	self.num:Show()

	self.maxnum = self:AddChild(Text(GLOBAL.NUMBERFONT, SHOWMAXONNUMBERS and 25 or 33))
	self.maxnum:SetPosition(6, 0, 0)
	self.maxnum:MoveToFront()
	self.maxnum:Hide()
	
	local OldOnGainFocus = self.OnGainFocus
	function self:OnGainFocus()
		OldOnGainFocus(self)
		self.maxnum:Show()
	end

	local OldOnLoseFocus = self.OnLoseFocus
	function self:OnLoseFocus()
		OldOnLoseFocus(self)
		self.maxnum:Hide()
		self.num:Show()
	end
	
	-- for health/hunger/sanity/beaverness
	local maxtxt = SHOWMAXONNUMBERS and "Max:\n" or ""
	local OldSetPercent = self.SetPercent
	if OldSetPercent then
		function self:SetPercent(val, max, ...)
			self.maxnum:SetString(maxtxt..tostring(math.ceil(max or 100)))
			OldSetPercent(self, val, max, ...)
		end
	end
	
	-- for moisture
	local OldSetValue = self.SetValue
	if OldSetValue then
		function self:SetValue(val, max, ...)
			self.maxnum:SetString(maxtxt..tostring(math.ceil(max)))
			OldSetValue(self, val, max, ...)
		end
	end
end
AddClassPostConstruct("widgets/badge", BadgePostConstruct)

local function BoatBadgePostConstruct(self)
	local nudge = RPGHUD and 75 or 12.5
	self.bg:SetPosition(-.5, nudge-40)
	
	self.num:SetFont(GLOBAL.NUMBERFONT)
	self.num:SetSize(28)
	self.num:SetPosition(3.5, nudge-40.5)
	self.num:SetScale(1,.78,1)
	self.num:MoveToFront()
	self.num:Show()
end
if CSW and SHOWSTATNUMBERS then
	AddClassPostConstruct("widgets/boatbadge", BoatBadgePostConstruct)
end

local function MoistureMeterPostConstruct(self)
	BadgePostConstruct(self)
	if not SHOWSTATNUMBERS then return end
	local OldActivate = self.Activate
	self.Activate = function(self)
		self.num:Show()
		self.bg:Show()
		OldActivate(self)
	end
	local OldDeactivate = self.Deactivate
	self.Deactivate = function(self)
		self.num:Hide()
		self.bg:Hide()
		OldDeactivate(self)
	end
	self.num:Hide()
	self.bg:Hide()
end
if ROG or CSW then
	AddClassPostConstruct("widgets/moisturemeter", MoistureMeterPostConstruct)
end

local function AddSeasonBadge(self)
	if not DST then
		local season = GLOBAL.GetSeasonManager():GetSeason()
		if season == "caves" then -- This is only for vanilla caves; RoG caves know the real season
			-- The season data isn't available in vanilla caves, anyway
			return
		end
	end
	if COMPACTSEASONS then
		self.season = self:AddChild(Minibadge("seasons", self.owner))
		self.season.bg:SetScale(0.6, .86, 1)
		local temp_nudge = SHOWTEMPERATURE and 1 or 0
		temp_nudge = temp_nudge + (SHOWWORLDTEMP and 1 or 0)
		temp_nudge = temp_nudge + (SHOWNAUGHTINESS and 1 or 0)
		self.season:SetPosition(65, -15 - 30*temp_nudge)
		self.season.num:SetScale(0.9, .7, 1)
	elseif MICROSEASONS then
		self.season = self.clock:AddChild(Minibadge("seasons", self.owner))
		self.season:SetPosition(0, -20)
		self.season.bg:SetScale(0.63, .43, 1)
		self.status.season = self.season -- making sure both get aliased to the same place
	end
	local season_trans = {"autumn", "winter", "spring", "summer"}
	if not DST and (GLOBAL.GetWorld():HasTag("shipwrecked") or GLOBAL.GetWorld():HasTag("volcano")) then
		season_trans = {"mild", "wet", "green", "dry"}
		self.season.num:SetScale(.7, .6, 1) -- season names are way longer, e.g. Hurricane
	end
	local season_lookup = {}
	for i,v in ipairs(season_trans) do season_lookup[v] = i end
	local function UpdateText(focused)
		if focused == nil then
			focused = self.season.focus
		end
		local season = DST and GLOBAL.TheWorld.state.season or GLOBAL.GetSeasonManager():GetSeason()
		local days = DST
			and GLOBAL.TheWorld.state.remainingdaysinseason
			or GLOBAL.GetSeasonManager():GetDaysLeftInSeason()
		days = math.floor(days+0.5)
		if focused and not MICROSEASONS then -- show days left until next season
			local season_i = season_lookup[season]
			local season_length = 0
			if season_i == nil then --The current season wasn't in our list of current seasons
				self.season.num:SetString("FAILED") --Let the user know something is wrong
				self.inst:DoTaskInTime(0, function() self.season.UpdateText(focused) end) --Try again next tick
				return --Don't continue with the bad data
			end
			repeat
				season_i = season_i%#season_trans + 1
				local lengthstr = season_trans[season_i] .. "length"
				season_length = DST and GLOBAL.TheWorld.state[lengthstr] or GLOBAL.GetSeasonManager()[lengthstr]
			until season_length and season_length > 0
			local seasonstr = DST
				and GLOBAL.STRINGS.UI.SERVERLISTINGSCREEN.SEASONS[season_trans[season_i]:upper()]
				or GLOBAL.STRINGS.UI.SANDBOXMENU[season_trans[season_i]:upper()]
			self.season.num:SetString(days .. " to\n" .. seasonstr)
		else -- show current season progress
			local seasonstr = DST
				and GLOBAL.STRINGS.UI.SERVERLISTINGSCREEN.SEASONS[season:upper()]
				or GLOBAL.STRINGS.UI.SANDBOXMENU[season:upper()]
			local total = DST
				and GLOBAL.TheWorld.state[season .. "length"]
				or GLOBAL.GetSeasonManager()[season .. "length"]
			if MICROSEASONS then
				if focused then
					self.season.num:SetString(seasonstr)
				else
					self.season.num:SetString((total-days + 1) .. "/" .. total)
				end
			elseif COMPACTSEASONS then
				self.season.num:SetString((total-days + 1) .. "/" .. total .. "\n" .. seasonstr)
			end
		end
	end
	self.season.UpdateText = UpdateText
	self.season.OnGainFocus = function() UpdateText(true) end
	self.season.OnLoseFocus = function() UpdateText(false) end
	if DST then
		self.inst:ListenForEvent("cycleschanged", function() UpdateText() end, GLOBAL.TheWorld)
		self.inst:ListenForEvent("seasonlengthschanged", function() UpdateText() end, GLOBAL.TheWorld)
	else
		self.inst:ListenForEvent("daycomplete", function() UpdateText() end, GLOBAL.GetWorld())
		self.inst:ListenForEvent("seasonChange", function() UpdateText() end, GLOBAL.GetWorld())
	end
	UpdateText()
end

local function ControlsPostConstruct(self)
	if self.clock.text_upper then --should only be in Shipwrecked(-compatible) worlds
		self.clock.text_upper:SetScale(.8, .8, 0)
		self.clock.text_lower:SetScale(.8, .8, 0)
	else
		local text = (DST and "_" or "") .. "text"
		self.clock[text]:SetPosition(5, 0)
		self.clock[text]:SetScale(.8, .8, 0)
	end
	if SHOWSEASONCLOCK then
		self.seasonclock = self.sidepanel:AddChild(GLOBAL.require("widgets/seasonclock")(self.owner, DST))
		self.seasonclock:SetPosition(50, 10)
		self.seasonclock:SetScale(0.8, 0.8, 0.8)
		self.clock:SetPosition(-50, 10)
		self.clock:SetScale(0.8, 0.8, 0.8)
	elseif MICROSEASONS then
		AddSeasonBadge(self)
	end
	
	self.sidepanel:SetPosition(-100, -70)
	
	if not DST and GLOBAL.GetWorld():IsCave() then
		if not HIDECAVECLOCK then
			self.clock:Show()
		end
		self.status:SetPosition(0, -110)
	end
	
	--fixes numbers being hidden when controller crafting is opened
	self.HideStatusNumbers = function() end	
	
	local _SetHUDSize = self.SetHUDSize
	function self:SetHUDSize()
		_SetHUDSize(self)
		local scale = GLOBAL.TheFrontEnd:GetHUDScale()*HUDSCALEFACTOR
		self.topright_root:SetScale(scale)
	end
	self:SetHUDSize()
end
if not DST or GLOBAL.TheNet:GetServerGameMode() ~= "lavaarena" then
	AddClassPostConstruct("widgets/controls", ControlsPostConstruct)
end

local function KrampedPostInit(self)
	local OldOnUpdate = self.OnUpdate
	self.OnUpdate = function(self, dt, ...)
		if self.actions > 0 and self.timetodecay < dt then
			self.inst:PushEvent("naughtydelta")
		end
		OldOnUpdate(self, dt, ...)
	end
	local OldOnNaughtyAction = self.OnNaughtyAction
	self.OnNaughtyAction = function(self, ...)
		OldOnNaughtyAction(self, ...)
		self.inst:PushEvent("naughtydelta")
	end
end
if SHOWNAUGHTINESS then
	AddComponentPostInit('kramped', KrampedPostInit)
end

local function StatusPostConstruct(self)
	self.brain:SetPosition(0, SHOWSEASONCLOCK and 35 or 10)
	self.stomach:SetPosition(-62, 35)
	self.heart:SetPosition(62, 35)
	if DST then
		self.heart.effigyanim:SetPosition(45, 50)
		self.resurrectbutton:SetPosition(0, 25)
	end
	
	local nudge = 0
	if SHOWNAUGHTINESS then	
		self.naughtiness = self:AddChild(Minibadge("naughtiness", self.owner))
		local function UpdateNaughty()
			self.naughtiness.num:SetString(	(self.owner.components.kramped.actions or 0) .. "/" ..
											(self.owner.components.kramped.threshold or 0) 			)
		end
		self.naughtiness:SetPosition(65.5, 0)
		self.naughtiness.bg:SetScale(.55, .43, 1)
		self.inst:ListenForEvent("naughtydelta", UpdateNaughty, self.owner)
		if SHOWTEMPBADGES then
			self.naughtybadge = self:AddChild(PlayerBadge('krampus', {80/255, 60/255, 30/255, 1}, false, 0))
			self.naughtybadge:SetScale(0.35, 0.35, 1)
			self.naughtybadge:SetPosition(41, -35.5)
			self.naughtybadge.head:GetAnimState():SetBank('krampus')
			self.naughtybadge.head:GetAnimState():SetBuild('krampus_build')
			self.naughtybadge.head:GetAnimState():SetPercent('hit', 1)
			self.naughtybadge.head:SetScale(0.1)
			self.naughtybadge.head:SetPosition(0, -32)
			self.naughtiness.bg:SetPosition(4, -40)
			self.naughtiness.num:SetPosition(10, -40.5)
			self.naughtiness.num:SetScale(0.9, .7, 1)
		end
		self.owner.components.kramped:OnNaughtyAction(0)
		nudge = nudge - 30
	end
	
	if SHOWTEMPERATURE then	
		self.temperature = self:AddChild(Minibadge("temperature", self.owner))
		self.inst:ListenForEvent("temperaturedelta",
			function(inst)
				local val = DST
					and self.owner:GetTemperature()
					or	self.owner.components.temperature.current
				self.temperature.num:SetString(UNITS[UNIT](val))
			end,
			self.owner)
		self.temperature:SetPosition(65.5, nudge, 0)
		if SHOWTEMPBADGES then
			self.tempbadge = self:AddChild(PlayerBadge(self.owner.prefab, {80/255, 60/255, 30/255, 1}, false, 0))
			self.tempbadge:SetScale(0.35, 0.35, 1)
			self.tempbadge:SetPosition(41, nudge-35.5)
			self.temperature.bg:SetScale(.5, .43, 1)
			self.temperature.num:SetPosition(8, -40.5)
			self.temperature.num:SetScale(0.9, .7, 1)
		end
		nudge = nudge - 30
	end
	
	if SHOWWORLDTEMP then
		self.worldtemp = self:AddChild(Minibadge("temperature", self.owner))
		local function updatetemp(val)
			self.worldtemp.num:SetString(UNITS[UNIT](val))
		end
		if DST then
			self.inst:WatchWorldState("temperature",
				function(inst)
					updatetemp(GLOBAL.TheWorld.state.temperature)
				end,
				self.owner)
		else
			self.inst:DoPeriodicTask(1, function(inst)
				updatetemp(GLOBAL.GetSeasonManager():GetCurrentTemperature())
			end)
		end
		self.worldtemp:SetPosition(65.5, nudge)
		if SHOWTEMPBADGES then
			if DST then
				self.worldtempbadge = self:AddChild(PlayerBadge(self.owner.prefab, {80/255, 60/255, 30/255, 1}, false, 0))
				self.worldtempbadge.head:SetTexture("images/rain.xml", "rain.tex")
			else
				self.worldtempbadge = self:AddChild(PlayerBadge(self.owner.prefab, {80/255, 60/255, 30/255, 1}, {atlas="images/rain.xml", image="rain.tex"}))
			end
			self.worldtempbadge.head:SetScale(.6, .6, 1)
			self.worldtempbadge:SetScale(0.35, 0.35, 1)
			self.worldtempbadge:SetPosition(41, nudge-35.5)
			self.worldtemp.bg:SetScale(.5, .43, 1)
			self.worldtemp.num:SetPosition(8, -40.5)
			self.worldtemp.num:SetScale(0.9, .7, 1)
		end
	end
	
	-- The badge anims aren't actually aligned identically, so this fixes them
	-- OCD, I know, but it was really obvious with beaverness + wetness next to each other
	self.stomach.anim:SetPosition(0, -2) --move stomach down 2 pixels
	-- if not DST then self.brain.anim:SetPosition(0, -2, 0) end -- check this for DST too?
	--move moisturemeter down 1 pixel
	--move beaverness up 1 pixel; this needs to be done in the AddBeaverness/SetBeaverMode functions
	
	if self.moisturemeter then
		self.moisturemeter:SetPosition(0, SHOWSEASONCLOCK and -52 or -80)
		self.moisturemeter.anim:SetPosition(0, -1)
	end
	
	if COMPACTSEASONS then AddSeasonBadge(self) end
	
	if DST then
		--DST-only functions for Beaverness
		local OldAddBeaverness = self.AddBeaverness
		self.AddBeaverness = function(self, ...)
			OldAddBeaverness(self, ...)
			if self.beaverness ~= nil then
				self.beaverness:SetPosition(-62, -52) -- this is for human, alive
				self.beaverness.anim:SetPosition(0, 1) -- animation alignment fix
			end
		end
		
		-- RemoveBeaverness never gets called... but if at some point it does, I might have issues here
		
		local OldSetBeaverMode = self.SetBeaverMode
		self.SetBeaverMode = function(self, beavermode, ...)
			OldSetBeaverMode(self, beavermode, ...)
			-- for beavermode, this should match the stomach position;
			-- otherwise, it should match the beaverness positioning for AddBeaverness above
			self.beaverness:SetPosition(-62, beavermode and 35 or -52)
		end
	elseif SHOWBEAVERNESS and self.owner.components.beaverness then
		--Single-player; show the beaver badge in human form
		self.beaverbadge = self:AddChild(Badge("beaver_meter", self.owner))
		self.beaverbadge:SetPosition(-62, -52)
		if self.owner.components.beaverness:IsBeaver() then
			self.beaverbadge:Hide()
		end
		self.beaverbadge.inst:ListenForEvent("beavernessdelta", function(inst, data)
			self.beaverbadge:SetPercent(self.owner.components.beaverness:GetPercent(), self.owner.components.beaverness.max)
		end, self.owner)
		self.beaverbadge.inst:ListenForEvent("beaverstart", function(inst)
			self.beaverbadge:Hide()
		end, self.owner)
		self.beaverbadge.inst:ListenForEvent("beaverend", function(inst)
			self.beaverbadge:Show()
		end, self.owner)
		self.owner.components.beaverness:DoDelta(0, true)
	end
	
	-- Puppy Princess Musha badge fix
	self.inst:DoTaskInTime(5, function()
		if self.staminab and self.staminab.bg then
			self.staminab.bg:Kill()
			self.staminab.bg = nil
		end
	end)
end
AddClassPostConstruct("widgets/statusdisplays", StatusPostConstruct)

local function UIClockPostInit(self)	
	if DST then
		GLOBAL.STRINGS.UI.HUD.WORLD_CLOCKDAY = "World\nDay"
	
		if self._cave then return end
		
		--copied code below from components/clock.lua; make sure it stays up-to-date
		local MOON_PHASE_NAMES =
		{
			"new",
			"quarter",
			"half",
			"threequarter",
			"full",
		}
		local MOON_PHASE_LENGTHS = 
		{
			new = 1,
			quarter = 3,
			half = 3,
			threequarter = 3,
			full = 1,
		}
		local offset = 9
		-- end copied code from components/clock.lua
		local MOON_PHASE_SLOTS = { }
		for i = #MOON_PHASE_NAMES-1, 2, -1 do
			for x=1,MOON_PHASE_LENGTHS[MOON_PHASE_NAMES[i]] do
				table.insert(MOON_PHASE_SLOTS, MOON_PHASE_NAMES[i])
			end
		end
		for i,v in ipairs(MOON_PHASE_NAMES) do
			for x=1,MOON_PHASE_LENGTHS[v] do
				table.insert(MOON_PHASE_SLOTS, v)
			end
		end
		
		if SHOWNEXTFULLMOON then
			self._moonanim.moontext = self._moonanim:AddChild(Text(GLOBAL.NUMBERFONT, 25))
			self._moonanim.moontext:SetPosition(-83, 22)
			self._moonanim.OnGainFocus = function() self._moonanim.moontext:Show() end
			self._moonanim.OnLoseFocus = function() self._moonanim.moontext:Hide() end
			local function PredictNextFullMoon()
				local today = GLOBAL.TheWorld.state.cycles
				while(MOON_PHASE_SLOTS[(today+offset)%#MOON_PHASE_SLOTS + 1] ~= "full") do
					today = today + 1
				end
				self._moonanim.moontext:SetString("" .. (today+1))
			end
			PredictNextFullMoon()
			self._moonanim.moontext:Hide()
			self.inst:WatchWorldState("isfullmoon", function(inst, fullmoon)
				if not fullmoon then
					PredictNextFullMoon()
				end
			end)
		end
		
		if SHOWMOONDUSK then
			--it sucks to have to override the whole thing, but... it hasn't changed in forever, so *shrug*
			self.OnPhaseChanged = function(self, phase)
				if self._phase == phase then
					return
				end
				
				if (self._phase == "night" and not SHOWMOONDAY)
				or (self._phase == "day" and SHOWMOONDUSK) then
					self._moonanim:GetAnimState():PlayAnimation("trans_in")
				end

				if phase == "day" then
					if self._phase ~= nil then
						self._anim:GetAnimState():PlayAnimation("trans_night_day")
						self._anim:GetAnimState():PushAnimation("idle_day", true)
					else
						self._anim:GetAnimState():PlayAnimation("idle_day", true)
					end
					if SHOWMOONDAY then self:ShowMoon() end
				elseif phase == "dusk" then
					 if self._phase ~= nil then
						self._anim:GetAnimState():PlayAnimation("trans_day_dusk")
						self._anim:GetAnimState():PushAnimation("idle_dusk", true)
					else
						self._anim:GetAnimState():PlayAnimation("idle_dusk", true)
					end
					if SHOWMOONDUSK then self:ShowMoon() end
				elseif phase == "night" then
					if self._phase ~= nil then
						self._anim:GetAnimState():PlayAnimation("trans_dusk_night")
						self._anim:GetAnimState():PushAnimation("idle_night", true)
					else
						self._anim:GetAnimState():PlayAnimation("idle_night", true)
					end
					self:ShowMoon()
				end

				self._phase = phase
			end
			
			local moonphases = { new = 0, quarter = 1, half = 2, threequarter = 3, full = 4 }
			
			--Really not sure why they kept in the 2, I would expect it to be reverted without warning, so... catch potential future crash?
			local moonphasechanged_fname = self.OnMoonPhaseChanged2 and "OnMoonPhaseChanged2" or "OnMoonPhaseChanged"
			local _OnMoonPhaseChanged = self[moonphasechanged_fname]
			self[moonphasechanged_fname] = function(self, moonphase, ...)
				_OnMoonPhaseChanged(self, moonphase, ...)
				if (SHOWMOONDUSK and self._phase == "dusk" and SHOWMOONDUSK) or (SHOWMOONDAY and self._phase == "day") then
					self:ShowMoon()
				end
			end
		end
		
	else -- Not DST
		-- Cave clock rim
		if GLOBAL.GetWorld():IsCave() then
			self.rim:Kill()
			self.rim = self:AddChild(GLOBAL.require("widgets/uianim")())
			self.rim:GetAnimState():SetBank("clock01")
			self.rim:GetAnimState():SetBuild("cave_clock")
			self.rim:GetAnimState():PlayAnimation("on")
			self.anim:Hide()
		end
	
		-- Moon stuff
		if SHOWMOONDAY then
		
			self:ShowMoon()
			
			self.inst:ListenForEvent( "daytime", function(inst, data) 
				self:ShowMoon()
			end, GLOBAL.GetWorld())
			
		elseif SHOWMOONDUSK then
		
			if GLOBAL.GetClock():IsDusk() then
				self:ShowMoon()
			end
			
			self.inst:ListenForEvent( "dusktime", function(inst, data) 
				self:ShowMoon()
			end, GLOBAL.GetWorld())
		
		end
		
		local moon_syms = 
		{
			new="moon_new",
			quarter="moon_quarter",
			half="moon_half",
			threequarter="moon_three_quarter",
			full="moon_full",
		}
		
		function self:ShowMoon()
			local phase, waning = GLOBAL.GetClock():GetMoonPhase()
			local sym = moon_syms[phase]
			if SHOWWANINGMOON and waning then
				self.moonanim:GetAnimState():OverrideSymbol("swap_moon", waningmoonanim, sym or "moon_full")
			else
				self.moonanim:GetAnimState():OverrideSymbol("swap_moon", waxingmoonanim, sym or "moon_full")
			end
			self.moonanim:GetAnimState():PlayAnimation("trans_out") 
			self.moonanim:GetAnimState():PushAnimation("idle", true) 
		end
		
		if SHOWNEXTFULLMOON then
			self.moonanim.moontext = self.moonanim:AddChild(Text(GLOBAL.NUMBERFONT, 25))
			self.moonanim.moontext:SetPosition(-83, 22)
			self.moonanim.OnGainFocus = function() self.moonanim.moontext:Show() end
			self.moonanim.OnLoseFocus = function() self.moonanim.moontext:Hide() end
			local function PredictNextFullMoon()
				local Clock = GLOBAL.GetClock()
				local day = Clock:GetNumCycles()
				local moon_phase = Clock:GetMoonPhase()
				while(Clock.GetMoonPhase({numcycles=day}) ~= "full") do
					day = day + 1
				end
				self.moonanim.moontext:SetString("" .. (day+1))
			end
			PredictNextFullMoon()
			self.moonanim.moontext:Hide()
			self.inst:ListenForEvent("daycomplete", PredictNextFullMoon, GLOBAL.GetWorld())
		end
	end
end

AddClassPostConstruct("widgets/uiclock", UIClockPostInit)

if not DST and SHOWWANINGMOON then
	local function ClockPostInit(self)
		local moonphases = 
		{
			"new",
			"quarter",
			"half",
			"threequarter",
			"full",
		}
		
		function self:GetMoonPhase()
			local phaselength = 2
			local n = #moonphases-1
			
			local idx = math.floor(self.numcycles/phaselength) % (2*n)
			local waning = false
			
			if idx >= n then
				idx = n*2 - idx
				waning = true
			end
			
			return moonphases[idx+1], waning
		end
	end
	AddComponentPostInit("clock", ClockPostInit)
end

AddClassPostConstruct("screens/playerhud", function(self)
	if GLOBAL.softresolvefilepath("scripts/widgets/beefalowidget.lua") then
		AddClassPostConstruct("widgets/beefalowidget", function(self)
			if self.health and self.hunger and self.hunger.anim then
				self.health:SetScale(1,1,1)
				self.health:SetPosition(80, 164)
				self.hunger:SetScale(1,1,1)
				self.hunger:SetPosition(-3, 164)
				self.hunger.anim:SetPosition(0, -2)
			end
		end)
	end
end)