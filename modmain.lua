Assets = {
	Asset("ATLAS", "images/status_bgs.xml"),
	Asset("ATLAS", "images/rain.xml"),
	
	--Note that the default behavior actually uses these for waxing, based on N Hemisphere moon
	Asset("ANIM", "anim/moon_waning_phases.zip"),
	Asset("ANIM", "anim/moon_aporkalypse_waning_phases.zip"),
}

local function CheckDlcEnabled(dlc)
	-- if the constant doesn't even exist, then they can't have the DLC
	if not GLOBAL.rawget(GLOBAL, dlc) then return false end
	GLOBAL.assert(GLOBAL.rawget(GLOBAL, "IsDLCEnabled"), "Old version of game, please update (IsDLCEnabled function missing)")
	return GLOBAL.IsDLCEnabled(GLOBAL[dlc])
end

local DST = GLOBAL.TheSim.GetGameID ~= nil and GLOBAL.TheSim:GetGameID() == "DST"
local ROG = DST or CheckDlcEnabled("REIGN_OF_GIANTS")
local CSW = CheckDlcEnabled("CAPY_DLC")
local HML = CheckDlcEnabled("PORKLAND_DLC")

local SHOWSTATNUMBERS = GetModConfigData("SHOWSTATNUMBERS")
local SHOWDETAILEDSTATNUMBERS = SHOWSTATNUMBERS == "Detailed"
local SHOWMAXONNUMBERS = GetModConfigData("SHOWMAXONNUMBERS")
local SHOWCLOCKTEXT = GetModConfigData("SHOWCLOCKTEXT") ~= false
local SHOWTEMPERATURE = GetModConfigData("SHOWTEMPERATURE")
local SHOWNAUGHTINESS = GetModConfigData("SHOWNAUGHTINESS")
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

local CHECK_MODS = {
	["workshop-1402200186"] = "TROPICAL",
	["workshop-874857181"] = "CHINESE",
	["workshop-2189004162"] = "INSIGHT",
}
local HAS_MOD = {}
--If the mod is a]ready loaded at this point
for mod_name, key in pairs(CHECK_MODS) do
	HAS_MOD[key] = HAS_MOD[key] or (GLOBAL.KnownModIndex:IsModEnabled(mod_name) and mod_name)
end
--If the mod hasn't loaded yet
for k,v in pairs(GLOBAL.KnownModIndex:GetModsToLoad()) do
	local mod_type = CHECK_MODS[v]
	if mod_type then
		HAS_MOD[mod_type] = v
	end
	-- Have to special-case this check because there are so many variants of RPG HUD that this is really the best way to check
    if string.match(GLOBAL.KnownModIndex:GetModInfo(v).name or "", "RPG HUD") then
		HAS_MOD.RPGHUD = true
    end
end

local require = GLOBAL.require
local Widget = require('widgets/widget')
local Image = require('widgets/image')
local Text = require('widgets/text')
local PlayerBadge = require("widgets/playerbadge" .. (DST and "" or "_combined_status"))
local UIAnim = require "widgets/uianim"
local Minibadge = require("widgets/minibadge")
if not DST then
	table.insert(Assets, Asset("ATLAS", "images/avatars_combined_status.xml"))
	table.insert(Assets, Asset("IMAGE", "images/avatars_combined_status.tex"))
	table.insert(Assets, Asset("ANIM", "anim/cave_clock.zip"))
end
local Badge = require("widgets/badge")

local badges = {}
local function BadgePostConstruct(self)
	if self.active == nil then
		self.active = true
	end
	
	self:SetScale(.9,.9,.9)
	-- Make sure that badge scaling animations are adjusted accordingly (e.g. WX's upgrade animation)
	local _ScaleTo = self.ScaleTo
	self.ScaleTo = function(self, from, to, ...)
		return _ScaleTo(self, from*.9, to*.9, ...)
	end
	
	if not SHOWSTATNUMBERS then return end
	
	self.bg = self:AddChild(Image("images/status_bgs.xml", "status_bgs.tex"))
	self.bg:SetScale(SHOWDETAILEDSTATNUMBERS and 0.55 or .4,.43,0)
	self.bg:SetPosition(-.5, -40, 0)
	
	self.num:SetFont(GLOBAL.NUMBERFONT)
	self.num:SetSize(SHOWDETAILEDSTATNUMBERS and 20 or 28)
	self.num:SetPosition(2, -40.5, 0)
	self.num:SetScale(1,.78,1)

	self.num:MoveToFront()
	if self.active then
		self.num:Show()
	end

	badges[self] = self
	self.maxnum = self:AddChild(Text(GLOBAL.NUMBERFONT, SHOWMAXONNUMBERS and 25 or 33))
	self.maxnum:SetPosition(6, 0, 0)
	self.maxnum:MoveToFront()
	self.maxnum:Hide()
	
	local OldOnGainFocus = self.OnGainFocus
	function self:OnGainFocus()
		OldOnGainFocus(self)
		if self.active then
			self.maxnum:Show()
		end
	end

	local OldOnLoseFocus = self.OnLoseFocus
	function self:OnLoseFocus()
		OldOnLoseFocus(self)
		self.maxnum:Hide()
		if self.active then
			self.num:Show()
		end
	end
	
	local maxtxt = SHOWMAXONNUMBERS and "Max:\n" or ""
	function self:CombinedStatusUpdateNumbers(max)
		-- avoid updating numbers on hidden badges
		if not self.active then return end
		local maxnum_str = tostring(math.ceil(max or 100))
		self.maxnum:SetString(maxtxt..maxnum_str)
		if SHOWDETAILEDSTATNUMBERS then
			self.num:SetString(self.num:GetString().."/"..maxnum_str)
		end
	end
	
	-- for health/hunger/sanity/beaverness
	local OldSetPercent = self.SetPercent
	if OldSetPercent then
		function self:SetPercent(val, max, ...)
			OldSetPercent(self, val, max, ...)
			self:CombinedStatusUpdateNumbers(max)
		end
	end
	
	-- for moisture
	local OldSetValue = self.SetValue
	if OldSetValue then
		function self:SetValue(val, max, ...)
			OldSetValue(self, val, max, ...)
			self:CombinedStatusUpdateNumbers(max)
		end
	end
	
	-- for boatmeter in DST
	local OldRefreshHealth = self.RefreshHealth
	if OldRefreshHealth then
		function self:RefreshHealth(...)
			OldRefreshHealth(self, ...)
			self:CombinedStatusUpdateNumbers(self.boat.components.healthsyncer.max_health)
		end
	end
end
AddClassPostConstruct("widgets/badge", BadgePostConstruct)

local function BoatBadgePostConstruct(self)
	local nudge = HAS_MOD.RPGHUD and 75 or 12.5
	self.bg:SetPosition(-.5, nudge-40)
	
	self.num:SetFont(GLOBAL.NUMBERFONT)
	self.num:SetSize(SHOWDETAILEDSTATNUMBERS and 20 or 28)
	self.num:SetPosition(2, nudge-40.5)
	self.num:SetScale(1,.78,1)
	self.num:MoveToFront()
	self.num:Show()
end
if (CSW or HML or HAS_MOD.TROPICAL) and SHOWSTATNUMBERS then
	AddPrefabPostInit("world", function()
		AddClassPostConstruct("widgets/boatbadge", BoatBadgePostConstruct)
	end)
end
local function BoatMeterPostConstruct(self)
	self.active = false
	BadgePostConstruct(self)
	self.inst:ListenForEvent("open_meter", function()
		self.active = true
		self.bg:Show()
		self.num:Show()
	end)
	self.inst:ListenForEvent("close_meter", function()
		self.active = false
		self.bg:Hide()
		self.num:Hide()
	end)
	if self.boat == nil then
		self.bg:Hide()
		self.num:Hide()
	end
end
if DST and SHOWSTATNUMBERS then
	AddClassPostConstruct("widgets/boatmeter", BoatMeterPostConstruct)
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
if ROG or CSW or HML then
	AddClassPostConstruct("widgets/moisturemeter", MoistureMeterPostConstruct)
end

local function InspirationBadgePostConstruct(self)
	local inspiration_buff_scale = 0.6
	for _, slot in ipairs(self.slots) do
		slot:SetScale(inspiration_buff_scale, inspiration_buff_scale)
	end
	for _, buff in ipairs(self.buffs) do
		buff:SetScale(inspiration_buff_scale, inspiration_buff_scale)
	end
	if self.maxnum then
		self.maxnum:MoveToFront()
	end
end
if DST and SHOWSTATNUMBERS and GLOBAL.kleifileexists("scripts/widgets/inspirationbadge.lua") then
	AddClassPostConstruct("widgets/inspirationbadge", InspirationBadgePostConstruct)
end

local function FindSeasonTransitions()
	if DST then return {"autumn", "winter", "spring", "summer"} end
	local season_trans = {}
	-- scrape the SeasonManager's length data to see what seasons are enabled (covers Hamlet, Shipwrecked, RoG, Vanilla)
	local longest_season_str = 0
	local season_orders = {
		"autumn", "winter", "spring", "summer",
		"mild", "wet", "green", "dry",
		"temperate", "humid", "lush",
	}
	for i, season in ipairs(season_orders) do
		if GLOBAL.GetSeasonManager()[season .. "enabled"] then -- or GLOBAL.GetSeasonManager()[season .. "_enabled"] then
			table.insert(season_trans, season)
		end
	end
	-- Vanilla DS doesn't use the "seasonenabled" vars on its SeasonManager
	if #season_trans == 0 then
		season_trans = {"summer", "winter"}
	end
	return season_trans
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
	local season_trans = FindSeasonTransitions()
	if not DST then
		-- weird seasons with long names might require smaller text, check and adjust
		local longest_season_str = 0
		for i, season in ipairs(season_trans) do
			longest_season_str = math.max(longest_season_str, GLOBAL.STRINGS.UI.SANDBOXMENU[season:upper()]:len())
		end
		if longest_season_str > 6 then
			self.season.num:SetScale(.7, .6, 1)
		end
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
			or (1-GLOBAL.GetSeasonManager().percent_season) * GLOBAL.GetSeasonManager():GetSeasonLength()
		days = math.floor(days+0.5)
		if focused and not MICROSEASONS then -- show days left until next season
			local season_i = season_lookup[season]
			local season_length = 0
			if season_i == nil then --The current season wasn't in our list of current seasons
				-- this happens during the Aporkalypse,
				-- because it's technically a season but not part of the normal ordering
				return -- we don't have anything to display, so don't change the text at all
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
			if seasonstr == nil or seasonstr == "" then
				-- attempt to capitalize it (e.g. for Aporkalypse which has no user-facing string)
				seasonstr = season:sub(1,1):upper() .. season:sub(2):lower()
			end
			local total = DST
				and GLOBAL.TheWorld.state[season .. "length"]
				or GLOBAL.GetSeasonManager():GetSeasonLength()
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
		self.inst:ListenForEvent("daycomplete", function() self.inst:DoTaskInTime(0, function() UpdateText() end) end, GLOBAL.GetWorld())
		self.inst:ListenForEvent("seasonChange", function() UpdateText() end, GLOBAL.GetWorld())
	end
	UpdateText()
end

local function ControlsPostConstruct(self)
	if self.clock then
		if not HAS_MOD.CHINESE then
			if self.clock.text_upper then --should only be in Shipwrecked(-compatible) worlds
				self.clock.text_upper:SetScale(.8, .8, 0)
				self.clock.text_lower:SetScale(.8, .8, 0)
			else
				local text = DST and "_text" or "text"
				self.clock[text]:SetPosition(5, 0)
				self.clock[text]:SetScale(.8, .8, 0)
			end
		end
		if SHOWSEASONCLOCK then
			self.seasonclock = self.sidepanel:AddChild(GLOBAL.require("widgets/seasonclock")(self.owner, DST, FindSeasonTransitions, SHOWCLOCKTEXT, HAS_MOD.CHINESE))
			self.seasonclock:SetPosition(50, 10)
			self.seasonclock:SetScale(0.8, 0.8, 0.8)
			self.clock:SetPosition(-50, 10)
			self.clock:SetScale(0.8, 0.8, 0.8)
		elseif MICROSEASONS then
			AddSeasonBadge(self)
		end
		
		if not DST and GLOBAL.GetWorld():IsCave() then
			if not HIDECAVECLOCK then
				self.clock:Show()
			end
			self.status:SetPosition(0, -110)
		end
	end
	
	self.sidepanel:SetPosition(-100, -70)
	
	local _SetHUDSize = self.SetHUDSize
	function self:SetHUDSize()
		_SetHUDSize(self)
		local scale = GLOBAL.TheFrontEnd:GetHUDScale()*HUDSCALEFACTOR
		self.topright_root:SetScale(scale)
	end
	self:SetHUDSize()
	
	-- Show/hide maxnum but not num when asked to show/hide (e.g. for Controller Inventory)
	local statusholder = DST and self.status or self
	_ShowStatusNumbers = statusholder.ShowStatusNumbers
	function statusholder:ShowStatusNumbers(...)
		_ShowStatusNumbers(self, ...)
		-- Fix for https://forums.kleientertainment.com/klei-bug-tracker/dont-starve-together-return-of-them/with-controller-after-drying-off-a-floating-1-shows-for-moisture-r24283/
		if self.moisturemeter and not self.moisturemeter.active then
			self.moisturemeter.num:Hide()
		end
		for _,badge in pairs(badges) do
			if badge and badge.maxnum and badge.active then
				badge.maxnum:Show()
			end
		end
	end
	function statusholder:HideStatusNumbers()
		for _,badge in pairs(badges) do
			if badge and badge.maxnum then
				badge.maxnum:Hide()
			end
		end
	end	
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

if SHOWNAUGHTINESS and DST then
	if not HAS_MOD.INSIGHT then
		SHOWNAUGHTINESS = false
	end
end

if SHOWNAUGHTINESS and not DST then
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
		local function UpdateNaughty(_, data) -- player, data
			if DST then
				data = type(data) == "table" and data or {}
			else
				data = self.owner.components.kramped
			end
			local actions = type(data.actions) == "number" and data.actions or 0
			local threshold = type(data.threshold) == "number" and data.threshold or 0
			self.naughtiness.num:SetString(actions .. "/" .. threshold)
		end
		self.naughtiness:SetPosition(65.5, 0)
		self.naughtiness.bg:SetScale(.55, .43, 1)
		self.inst:ListenForEvent("naughtydelta", UpdateNaughty, self.owner)
		if SHOWTEMPBADGES then
			self.naughtybadge = self:AddChild(PlayerBadge('krampus', {80/255, 60/255, 30/255, 1}, false, 0))
			self.naughtybadge:SetScale(0.35, 0.35, 1)
			self.naughtybadge:SetPosition(41, -35.5)
			if DST then
				-- head in DS is a UIAnim, head in DST is a Image
				-- GetAnimState is nil on the default head since it's not a UIAnim, and is instead an Image
				self.naughtybadge.head:Hide() -- i planned to just :Kill() the widget, but in case someone is relying on the Image existing for whatever reason
				-- so i just assign a member called real_head with a UIAnim
				self.naughtybadge.real_head = self.naughtybadge.icon:AddChild(UIAnim())
			else
				-- avoid duplicating lines here, so just assigning the head to a different member
				self.naughtybadge.real_head = self.naughtybadge.head
			end
			self.naughtybadge.real_head:GetAnimState():SetBank('krampus')
			self.naughtybadge.real_head:GetAnimState():SetBuild('krampus_build')
			self.naughtybadge.real_head:GetAnimState():SetPercent('hit', 1)
			self.naughtybadge.real_head:SetScale(0.1)
			self.naughtybadge.real_head:SetPosition(0, -32)
			self.naughtiness.bg:SetPosition(4, -40)
			self.naughtiness.num:SetPosition(10, -40.5)
			self.naughtiness.num:SetScale(0.9, .7, 1)
		end
		if not DST then -- DS only
			self.owner.components.kramped:OnNaughtyAction(0)
		end
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
		--Note this is deprecated now in DST but might as well keep it for backwards-compatibility.
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
	
	if DST then
		if self.inspirationbadge ~= nil then
			self.inspirationbadge:SetPosition(-62, -52)
		end
		local OldAddInspiration = self.AddInspiration
		self.AddInspiration = function(self, ...)
			OldAddInspiration(self, ...)
			if self.inspirationbadge ~= nil then
				self.inspirationbadge:SetPosition(-62, -52)
			end
		end
	end
	
	local _boatx = -62
	if self.pethealthbadge or self.inspirationbadge then
		_boatx = _boatx - 62
	end
	if self.pethealthbadge then
		self.pethealthbadge:SetPosition(-62, -52)
	end
	
	if self.boatmeter then
		self.boatmeter:SetPosition(_boatx, -52)
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

local has_proxied_world_clock_day = false
local function ProxyWorldClockDay()
	if not has_proxied_world_clock_day then
		has_proxied_world_clock_day = true
		
		-- Replace GLOBAL.STRINGS.UI.HUD with a proxy table that uses a metatable to intercept accesses to it
		-- this allows us to construct WORLD_CLOCKDAY from the current contents of WORLD and WORLD_CLOCKDAY
		local HUD_original = GLOBAL.STRINGS.UI.HUD
		local HUD_proxy = {}
		local HUD_metatable = {
			__index = function(t, k)
				-- someone asked for the value for k from this table; compose for clockdays and pass through for others
				if k == "WORLD_CLOCKDAY" or k == "WORLD_CLOCKDAY_V2" then
					return HUD_original.WORLD .. "\n" .. HUD_original[k]
				end
				return HUD_original[k]
			end,
			__newindex = function(t, k, v)
				-- someone assigned to this table; pass it through to the original
				HUD_original[k] = v
			end,
		}
		GLOBAL.setmetatable(HUD_proxy, HUD_metatable)
		GLOBAL.STRINGS.UI.HUD = HUD_proxy
	end
end

-- Only run this in Vanilla and RoG (DST already records these)
if not SHOWCLOCKTEXT and not (DST or CSW or HML)then
	local function RecordTextWidgetFontAndSize()
		-- Need to make font and size available for UIClockPostInit below
		_Text_SetFont = Text.SetFont
		function Text:SetFont(font, ...)
			_Text_SetFont(self, font, ...)
			self.font = font
		end
		_Text_SetSize = Text.SetSize
		function Text:SetSize(size, ...)
			_Text_SetSize(self, size, ...)
			self.size = size
		end
		_Text_ctor = Text._ctor
		function Text:_ctor(font, size, ...)
			_Text_ctor(self, font, size, ...)
			self.font = font
			self.size = size
		end
	end
	-- Run it after World init so it doesn't run on menus, but runs before UIClock's constructor
	AddPrefabPostInit("world", RecordTextWidgetFontAndSize)
end

local function UIClockPostInit(self)
	if not SHOWCLOCKTEXT then
		if CSW or HML then
			-- These have a different clock string approach that does an animation to show all text on hover
			-- So we just need to show/hide on focus gained/lost
			self.AnimateDayString = function() end
			if self.animate_task ~= nil then
				self.animate_task:Cancel()
			end
			self.text_upper:SetPosition(5, 15, 0)
			self.text_lower:SetPosition(5, -15, 0)
			self.text_upper:Hide()
			self.text_lower:Hide()
			local _UIClock_OnGainFocus = self.OnGainFocus
			function self:OnGainFocus(...)
				_UIClock_OnGainFocus(self, ...)
				self:UpdateDayString()
				self.text_upper:Show()
				self.text_lower:Show()
				return true
			end
			local _UIClock_OnLoseFocus = self.OnLoseFocus
			function self:OnLoseFocus(...)
				_UIClock_OnLoseFocus(self, ...)
				self.text_upper:Hide()
				self.text_lower:Hide()
				return true
			end
		else
			-- In Vanilla, RoG, and DST we need something fancier
			-- Change UpdateDayString and UpdateWorldString to write to a fake invisible Text,
			-- so we can capture the output strings to assemble the one we want
			local text = DST and "_text" or "text"
			local text_proxy = Text(self[text].font, self[text].size)
			local day_text = ""
			local world_text = ""
			local function BuildString()
				self[text]:SetString(day_text .. "\n" .. world_text)
			end
			text_proxy:Hide()
			if DST then
				self[text]:SetSize(text_proxy.size*0.75)
			end
			self[text]:Hide()
			local _UIClock_UpdateDayString = self.UpdateDayString
			function self:UpdateDayString(...)
				local _text = self[text]
				self[text] = text_proxy
				_UIClock_UpdateDayString(self, ...)
				self[text] = _text
				day_text = text_proxy:GetString()
				BuildString()
			end
			if DST then
				local _UIClock_UpdateWorldString = self.UpdateWorldString
				function self:UpdateWorldString(...)
					local _text = self[text]
					self[text] = text_proxy
					_UIClock_UpdateWorldString(self, ...)
					self[text] = _text
					world_text = text_proxy:GetString()
					BuildString()
				end
			end
			-- Then change the OnGainFocus and OnLoseFocus to show/hide the text we want
			local _UIClock_OnGainFocus = self.OnGainFocus
			function self:OnGainFocus(...)
				-- this one is a bit messy because DST has UpdateWorldString,
				-- but V/RoG do it all in the OnGainFocus...
				local _text = self[text]
				if not DST then
					self[text] = text_proxy
				end
				_UIClock_OnGainFocus(self, ...)
				if DST then
					self:UpdateWorldString()
				else
					self[text] = _text
					world_text = text_proxy:GetString()
					self:UpdateDayString()
					BuildString()
				end
				self[text]:Show()
				return true
			end
			local _UIClock_OnLoseFocus = self.OnLoseFocus
			function self:OnLoseFocus(...)
				_UIClock_OnLoseFocus(self, ...)
				self[text]:Hide()
				return true
			end
		end
	end
	
	if DST then
		ProxyWorldClockDay()
		
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
			
			local moon_build = "moon_"
			local aporkalypse = HML and GLOBAL.GetAporkalypse()
			if aporkalypse and aporkalypse:IsActive() then
				moon_build = moon_build .. "aporkalypse_"
			end
			if (SHOWWANINGMOON and waning) == FLIPMOON then
				moon_build = moon_build .. "waning_"
			end
			moon_build = moon_build .. "phases"
			
			self.moonanim:GetAnimState():OverrideSymbol("swap_moon", moon_build, sym or "moon_full")
			self.moonanim:GetAnimState():PlayAnimation("trans_out") 
			self.moonanim:GetAnimState():PushAnimation("idle", true) 
		end
		
		if SHOWMOONDAY or GLOBAL.GetClock():IsNight() or (SHOWMOONDUSK and GLOBAL.GetClock():IsDusk()) then
			self:ShowMoon()
		end
		
		if SHOWMOONDAY then
			self.inst:ListenForEvent( "daytime", function(inst, data) 
				self:ShowMoon()
			end, GLOBAL.GetWorld())
		elseif SHOWMOONDUSK then
			self.inst:ListenForEvent( "dusktime", function(inst, data) 
				self:ShowMoon()
			end, GLOBAL.GetWorld())
		
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
			if self.bloodmoon_active then
				return "full"
			end
			
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

local PlayerHud = require("screens/playerhud")
local PlayerHud_OpenControllerInventory = PlayerHud.OpenControllerInventory
function PlayerHud:OpenControllerInventory(...)
	PlayerHud_OpenControllerInventory(self, ...)
	if self.controls.clock then
		self.controls.clock:OnGainFocus()
	end
	if SHOWSEASONCLOCK and self.controls.seasonclock then
		self.controls.seasonclock:OnGainFocus()
	end
end
local PlayerHud_CloseControllerInventory = PlayerHud.CloseControllerInventory
function PlayerHud:CloseControllerInventory(...)
	PlayerHud_CloseControllerInventory(self, ...)
	if self.controls.clock then
		self.controls.clock:OnLoseFocus()
	end
	if SHOWSEASONCLOCK and self.controls.seasonclock then
		self.controls.seasonclock:OnLoseFocus()
	end
end
