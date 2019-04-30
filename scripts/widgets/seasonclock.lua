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
	
	-- Hamlet seasons
	TEMPERATE = Vector3(255 / 255, 206 / 255, 139 / 255),
	HUMID = Vector3(149 / 255, 191 / 255, 242 / 255),
	LUSH = Vector3(84 / 168, 200 / 255, 84 / 255),
	APORKALYPSE = Vector3(205 / 255, 79 / 255, 57 / 255),
}
local DARKEN_PERCENT = .75

--------------------------------------------------------------------------
--[[ Constructor ]]
--------------------------------------------------------------------------
local SeasonClock = Class(Widget, function(self, owner, isdst, season_transition_fn, show_clock_text, chinese_translation)
    Widget._ctor(self, "SeasonClock")

    --Member variables
	self._dst = isdst
	self._season_transition_fn = season_transition_fn
	local world = self._dst and TheWorld or GetWorld()
    self._cave = (self._dst and world ~= nil and world:HasTag("cave"))
			or (not self._dst and world:IsCave())
    self._anim = nil
    self._face = nil
    self._segs = {}
    self._rim = nil
    self._hands = nil
    self._text = nil
    self._have_focus = nil
    self._cycles = nil
    self._phase = nil
    self._time = nil
	self._old_t = 0
	self._show_clock_text = show_clock_text ~= false
	self._chinese = chinese_translation

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

    self._text = self:AddChild(Text(BODYTEXTFONT, ((self._show_clock_text or self._chinese) and 1 or 0.75) * 33 / basescale))
    self._text:SetPosition(5, 0 / basescale, 0)

    --Default initialization
    self:OnLoseFocus()
	
    self:OnSeasonLengthsChanged()
	self:OnCyclesChanged()
	
    --Register events
	if self._dst then
		local function listen_for_event_delayed(event, fn)
			self.inst:ListenForEvent(event, function(inst, data)
				TheWorld:DoTaskInTime(0, function()
					fn(self, data)
				end)
			end, TheWorld)
		end
		listen_for_event_delayed("seasontick", self.OnCyclesChanged)
		listen_for_event_delayed("seasonlengthschanged", self.OnSeasonLengthsChanged)
		listen_for_event_delayed("phasechanged", self.OnPhaseChanged)
	else
		--Because SeasonManager doesn't push events when season lengths are changed,
		-- we add an interceptor to the SeasonManager to catch the variable assignment (gross...)
		
		local seasonmanager = GetSeasonManager()
		local sm_seasonlengths = {}
		
		-- move the existing season lengths into our local table
		for key,val in pairs(seasonmanager) do
			if type(key) == "string" and key:match("length$") then
				sm_seasonlengths[key] = val
				seasonmanager[key] = nil
			end
		end

		-- intercept table accesses so season lengths are read from our table
		-- (this is needed so that assignments can be intercepted)
		local sm_mt = getmetatable(seasonmanager)
		local sm_mt_index = sm_mt.__index
		sm_mt.__index = function(sm, key)
			-- someone tried to get a season length, return from our local table (and fall back to the original __index)
			if sm_seasonlengths[key] ~= nil then
				-- if it's one of our season lengths, return it from the local table
				return sm_seasonlengths[key]
				-- otherwise, support both types of __index definitions for the previous __index
			elseif type(sm_mt_index) == "table" then
				return sm_mt_index[key]
			elseif type(sm_mt_index) == "function" then
				return sm_mt_index(sm, key)
			end
		end
		
		-- intercept table assignment so we know when season lengths change
		local sm_mt_newindex = sm_mt.__newindex
		sm_mt.__newindex = function(sm, key, val)
			if type(key) == "string" and key:match("length$") then
				-- someone tried to assign a seasonlength, capture and store it in our local table
				sm_seasonlengths[key] = val
				-- and then update the season clock
				self:OnSeasonLengthsChanged()
			elseif sm_mt_newindex then -- fall back to original __newindex, if present
				sm_mt_newindex(sm, key, val)
			else -- and finally fall back to a normal set
				rawset(sm, key, val)
			end
		end
		
		self.inst:ListenForEvent("daycomplete", function(inst, data)
			self.inst:DoTaskInTime(0, function()
				self:OnCyclesChanged()
				if self._have_focus then
					self:OnGainFocus()
				else
					self:OnLoseFocus()
				end
			end)
		end, GetWorld())
		self.inst:ListenForEvent("seasonChange", function()
			self:OnSeasonLengthsChanged()
			if self._have_focus then
				self:OnGainFocus()
			else
				self:OnLoseFocus()
			end
		end, GetWorld())
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

function SeasonClock:GetSeasonString()
	local str = ""
	if self._dst then
		str = STRINGS.UI.SERVERLISTINGSCREEN.SEASONS[TheWorld.state.season:upper()]
	else
		local season = GetSeasonManager():GetSeason()
		if season == "caves" then
			self:Hide()
		end
		str = STRINGS.UI.SANDBOXMENU[season:upper()]
		if str == nil or str == "" then
			-- attempt to capitalize it (e.g. for Aporkalypse which has no user-facing string)
			str = season:sub(1,1):upper() .. season:sub(2):lower()
		end
	end
	return str
end

function SeasonClock:GetRemainingString()
	local days_left = ""
	if self._dst then
		days_left = TheWorld.state.remainingdaysinseason
	else
		-- We ought to be able to use this but it wasn't updated for Hamlet...
		-- days_left = GetSeasonManager():GetDaysLeftInSeason()
		days_left = (1-GetSeasonManager().percent_season) * GetSeasonManager():GetSeasonLength()
	end
	-- unfortunately no good string to capture translations of "left"
	local days_str = STRINGS.UI.HUD.CLOCKDAYS or STRINGS.UI.DEATHSCREEN.DAYS
    return math.floor(days_left+0.5) .. " " .. days_str:lower() .. "\n" .. "left"
end

--------------------------------------------------------------------------
--[[ Event handlers ]]
--------------------------------------------------------------------------

function SeasonClock:OnGainFocus()
    SeasonClock._base.OnGainFocus(self)
	if self._show_clock_text then
		self._text:SetString(self:GetRemainingString())
	else
		self._text:Show()
		self._text:SetString(self:GetSeasonString() .. "\n" .. self:GetRemainingString())
	end
	self._have_focus = true	
    return true
end

function SeasonClock:OnLoseFocus()
    SeasonClock._base.OnLoseFocus(self)
	if self._show_clock_text then
		self._text:SetString(self:GetSeasonString())
	else
		self._text:Hide()
	end
	self._have_focus = false
    return true
end

function SeasonClock:GetSeasonLength(season)
	if self._dst then
		return TheWorld.state[season .. "length"] or TUNING[season:upper() .. "_LENGTH"]
	else -- should work for Vanilla, RoG, and Shipwrecked
		local sm = GetSeasonManager()		
		if sm.seasonmode:find("endless") then
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
			return sm[season .. "length"] or TUNING[season:upper() .. "_LENGTH"] or 10000
		end
	end
end

function SeasonClock:GetSeasonLengths()
	self.seasons = self._season_transition_fn()
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
	-- Although the seasons component pushes a seasontick after seasonlengthschanged,
	-- the delay we have on the event listener can cause them to get out of order
	-- since it's not really that expensive, just run it again to ensure it has the right numbers
	self:OnCyclesChanged()
end

function SeasonClock:OnCyclesChanged(data)
	local progress = 0
	local i = 1
	local season = self._dst and TheWorld.state.season or GetSeasonManager():GetSeason()
	local aporkalypse = false
	if SEASONS.APORKALYPSE and season == SEASONS.APORKALYPSE then
		-- Aporkalypse doesn't have a place on the clock, so use the previous "paused" season
		season = GetSeasonManager().pre_aporkalypse_season or SEASONS.TEMPERATE
		aporkalypse = true
	end
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
	local percent = 0
	if self._dst then
		percent = 1 - TheWorld.state.remainingdaysinseason/math.max(TheWorld.state.remainingdaysinseason, self:GetSeasonLength(season))
	elseif aporkalypse then
		percent = GetSeasonManager().pre_aporkalypse_percent or percent
	else
		percent = GetSeasonManager().percent_season
	end
	progress = progress + segments*percent
	progress = progress / NUM_SEGS
	self._hands:SetRotation(progress*360)
    if self._have_focus then
		self:OnGainFocus()
	else
        self:OnLoseFocus()
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