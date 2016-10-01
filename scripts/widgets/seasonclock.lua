--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------

local Widget = require "widgets/widget"
local Image = require "widgets/image"
local Text = require "widgets/text"
local UIAnim = require "widgets/uianim"

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local NUM_SEGS = 32
local COLOURS = 
{
	-- Normal seasons
	AUTUMN = Vector3(205 / 255, 79 / 255, 57 / 255),
	WINTER = Vector3(149 / 255, 191 / 255, 242 / 255),
	SPRING = Vector3(84 / 168, 200 / 255, 84 / 255),
	SUMMER = Vector3(255 / 255, 206 / 255, 139 / 255),
	
	-- Shipwrecked seasons
	MILD = Vector3(255 / 255, 206 / 255, 139 / 255),	-- Mild
	WET = Vector3(149 / 255, 191 / 255, 242 / 255),		-- Hurricane
	GREEN = Vector3(84 / 168, 200 / 255, 84 / 255),		-- Monsoon
	DRY = Vector3(205 / 255, 79 / 255, 57 / 255),		-- Dry
}
local DARKEN_PERCENT = .75

--------------------------------------------------------------------------
--[[ Constructor ]]
--------------------------------------------------------------------------
local SeasonClock = Class(Widget, function(self, owner, isdst)
    Widget._ctor(self, "SeasonClock")

    --Member variables
	self._dst = isdst
	local world = self._dst and TheWorld or GetWorld()
    self._cave = (self._dst and world ~= nil and world:HasTag("cave"))
			or (not self._dst and world:IsCave())
	-- may need to add logic  the volcano specifically,
	-- but for now we just need forto mark it as Shipwrecked
	self._volcano = world ~= nil and world:HasTag("volcano")
	self._shipwrecked = world ~= nil and ( world:HasTag("shipwrecked") or self._volcano )
	local CAPY_DLC = rawget(_G, "CAPY_DLC")
	self._rog = self._dst or IsDLCEnabled(REIGN_OF_GIANTS)
		-- this occurs when going from Shipwrecked to RoG
		or (not self._shipwrecked and CAPY_DLC and IsDLCEnabled(CAPY_DLC))
    self._anim = nil
    self._face = nil
    self._segs = {}
    self._rim = nil
    self._hands = nil
    self._text = nil
    self._showingseasons = nil
    self._cycles = nil
    self._phase = nil
    self._time = nil
	self._old_t = 0

    local basescale = 1
    self:SetScale(basescale, basescale, basescale)
    self:SetPosition(0, 0, 0)

	if not self._cave then
		self._anim = self:AddChild(UIAnim())
		self._anim:GetAnimState():SetBank("clock01")
		self._anim:GetAnimState():SetBuild("clock_transitions")
		self._anim:GetAnimState():PlayAnimation("idle_day", true)
	end

    self._face = self:AddChild(Image("images/hud.xml", "clock_NIGHT.tex"))
    self._face:SetClickable(false)

	-- build each segment on the clock and set its rotation and position
    local segscale = .4
    for i = NUM_SEGS, 1, -1 do
        local seg = self:AddChild(Image("images/hud.xml", "clock_wedge.tex"))
        seg:SetScale((i == 1 and 0.5 or 1)*segscale, segscale, segscale)
        seg:SetHRegPoint(ANCHOR_LEFT)
        seg:SetVRegPoint(ANCHOR_BOTTOM)
        seg:SetRotation((i - (i == 1 and 1 or 2)) * (360 / NUM_SEGS))
        seg:SetClickable(false)
        self._segs[i] = seg
    end

    if self._cave then
        self._rim = self:AddChild(UIAnim())
        self._rim:GetAnimState():SetBank("clock01")
        self._rim:GetAnimState():SetBuild("cave_clock")
        self._rim:GetAnimState():PlayAnimation("on")
    else
        self._rim = self:AddChild(Image("images/hud.xml", "clock_rim.tex"))
        self._rim:SetClickable(false)
    end
	
	if self._dst and self._cave then
		self._hands = self:AddChild(Widget("clockhands"))
		self._hands._img = self._hands:AddChild(Image("images/hud.xml", "clock_hand.tex"))
		self._hands._img:SetClickable(false)
		self._hands._animtime = nil
	else
		self._hands = self:AddChild(Image("images/hud.xml", "clock_hand.tex"))
		self._hands:SetClickable(false)
	end

    self._text = self:AddChild(Text(BODYTEXTFONT, 33 / basescale))
    self._text:SetPosition(5, 0 / basescale, 0)

    --Default initialization
    self:UpdateSeasonString()
	
    self:OnSeasonLengthsChanged()
	self:OnCyclesChanged()

    --Register events
	if self._dst then
		self.inst:ListenForEvent("seasontick", function(inst, data) self:OnCyclesChanged(data) end, TheWorld)
		self.inst:ListenForEvent("seasonlengthschanged", function(inst, data) self:OnSeasonLengthsChanged(data) end, TheWorld)
		self.inst:ListenForEvent("phasechanged", function(inst, data) self:OnPhaseChanged(data) end, TheWorld)
	else
		self.inst:ListenForEvent("daycomplete", function(inst, data) self:OnCyclesChanged() self:UpdateSeasonString() end, GetWorld())
		self.inst:ListenForEvent("seasonChange", function() self:UpdateSeasonString() self:OnSeasonLengthsChanged() end, GetWorld())
		if not self._cave then
			self.inst:ListenForEvent("daytime", function(inst, data) self:OnPhaseChanged("day") end, GetWorld())
			self.inst:ListenForEvent("dusktime", function(inst, data) self:OnPhaseChanged("dusk") end, GetWorld())
			self.inst:ListenForEvent("nighttime", function(inst, data) self:OnPhaseChanged("night") end, GetWorld())
			self.inst:ListenForEvent("clocktick", function(inst, data)
				local t = data.normalizedtime
				if data.phase == "day" then
					local segs = 16
					if math.floor(t * segs) > 0 and math.floor(t * segs) ~= math.floor(self._old_t * segs) then
						self._anim:GetAnimState():PlayAnimation("pulse_day") 
						self._anim:GetAnimState():PushAnimation("idle_day", true)            
					end
				end
				self._old_t = t
			end, GetWorld())
		end
	end
end)

--------------------------------------------------------------------------
--[[ Member functions ]]
--------------------------------------------------------------------------

function SeasonClock:UpdateSeasonString()
	local str = ""
	if self._dst then
		str = STRINGS.UI.SERVERLISTINGSCREEN.SEASONS[TheWorld.state.season:upper()]
	else
		local season = GetSeasonManager():GetSeason()
		if season == "caves" then
			self:Hide()
		end
		str = STRINGS.UI.SANDBOXMENU[season:upper()]
	end
	self._text:SetString(str)
    self._showingseasons = true
end

function SeasonClock:UpdateRemainingString()
	local str = ""
	if self._dst then
		str = TheWorld.state.remainingdaysinseason
	else
		str = GetSeasonManager():GetDaysLeftInSeason()
	end
    self._text:SetString(math.floor(str+0.5) .. " days\nleft")
    self._showingseasons = false
end

--------------------------------------------------------------------------
--[[ Event handlers ]]
--------------------------------------------------------------------------

function SeasonClock:OnGainFocus()
    SeasonClock._base.OnGainFocus(self)
    self:UpdateRemainingString()
    return true
end

function SeasonClock:OnLoseFocus()
    SeasonClock._base.OnLoseFocus(self)
    self:UpdateSeasonString()
    return true
end

function SeasonClock:GetSeasonLength(season)
	if self._dst then
		return TheWorld.state[season .. "length"] or TUNING[season:upper() .. "_LENGTH"]
	else -- should work for Vanilla, RoG, and Shipwrecked
		local sm = GetSeasonManager()		
		if sm.seasonmode == "cycle" or sm.seasonmode == "tropical" then
			return sm[season .. "length"] or TUNING[season:upper() .. "_LENGTH"]
		elseif sm.seasonmode:find("endless") then
			local begin,finish = sm.seasonmode:find("endless")
			local endless_season = sm.seasonmode:sub(finish+1)
			local current_season = sm.current_season
			if season == endless_season then
				return endless_season == current_season and 10000 or sm.endless_pre
			else
				return season == current_season and sm.endless_pre or 0
			end
		elseif sm.seasonmode:find("always") then
			local begin,finish = sm.seasonmode:find("always")
			local always_season = sm.seasonmode:sub(finish+1)
			return always_season == season and 10000 or 0
		else
			return 10000
		end
	end
end

function SeasonClock:GetSeasonLengths()
	self.seasons = {"summer", "winter"}
	if self._shipwrecked then
		self.seasons = { "mild", "wet", "green", "dry" }
	elseif self._rog then
		self.seasons = { "autumn", "winter", "spring", "summer" }
	end

	local lengths = {}
	for i,v in ipairs(self.seasons) do
		lengths[v] = self:GetSeasonLength(v)
	end
	return lengths
end

function SeasonClock:OnSeasonLengthsChanged(data)
	--Technically this misbehaves a little if there's a short initial season
	-- followed by an endless season; it only displays the endless season
	--However, I'm leaving this behavior in because a solution would be messy and potentially ambiguous
	if data == nil then
		data = self:GetSeasonLengths()
	end
	local lengths = {}
	local total = 0
	for k,v in pairs(data) do
		total = total + v
	end
	local multiplier = NUM_SEGS/total
	local residuals = {}
	total = 0
	for k,v in pairs(data) do
		local length = v*multiplier
		lengths[k] = math.floor(length)
		total = total + lengths[k]
		table.insert(residuals, {residual = length%1, season = k})
	end
	table.sort(residuals, function(a,b) return a.residual > b.residual end)
	local r = 1
	while total < NUM_SEGS do
		lengths[residuals[r].season] = lengths[residuals[r].season] + 1
		total = total + 1
		r = r + 1
	end
	self.seasonsegments = lengths

    local dark = true
	local season = 1
	local runningtotal = 0
    for i, seg in ipairs(self._segs) do
		while i - runningtotal > lengths[self.seasons[season]] do
			season = season + 1
			runningtotal = i - 1
		end
		
		seg:Show()
		
		local color = COLOURS[self.seasons[season]:upper()]
		if dark then
			color = color * DARKEN_PERCENT
		end
		dark = not dark

		seg:SetTint(color.x, color.y, color.z, 1)
    end
end

function SeasonClock:OnCyclesChanged(data)
	local progress = 0
	local i = 1
	local season = self._dst and TheWorld.state.season or GetSeasonManager():GetSeasonString()
	while season ~= self.seasons[i] and self.seasons[i] do
		progress = progress + self.seasonsegments[self.seasons[i]]
		i = i + 1
	end
	if season ~= self.seasons[i] then -- The current season wasn't in our list of current seasons
		self._text:SetString("FAILED") -- Let the user know something is wrong
		self.inst:DoTaskInTime(0, function() self:OnCyclesChanged() end) -- Try again next tick
		return -- Don't continue with the bad data
	end
	local segments = self.seasonsegments[season]
	local elapsed = self._dst and TheWorld.state.elapseddaysinseason or GetSeasonManager():GetDaysIntoSeason()
	progress = progress + segments*elapsed/self:GetSeasonLength(season)
	progress = progress / NUM_SEGS
	self._hands:SetRotation(progress*360)
    if self._showingseasons then
        self:UpdateSeasonString()
	else
		self:UpdateRemainingString()
    end
end

function SeasonClock:OnPhaseChanged(phase)
	if self._anim then
		if self._phase ~= nil and self._phase ~= phase then
			self._anim:GetAnimState():PlayAnimation("trans_" .. self._phase .. "_" .. phase)
			self._anim:GetAnimState():PushAnimation("idle_" .. phase, true)
		else
			self._anim:GetAnimState():PlayAnimation("idle_" .. phase, true)
		end
	end

    self._phase = phase
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

return SeasonClock