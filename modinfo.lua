--The name of the mod displayed in the 'mods' screen.
name = "Combined Status"

--A description of the mod.
description = "Displays Health, Hunger, Sanity, Temperature, Seasons, Moon Phase, and World Day."

--Who wrote this awesome mod?
author = "rezecib, Kiopho, Soilworker, hotmatrixx"

--A version number so you can ask people if they are running an old version of your mod.
version = "1.8.3"

--This lets other players know if your mod is out of date. This typically needs to be updated every time there's a new game update.
api_version = 6
api_version_dst = 10
priority = 0

--Compatible with both the base game and Reign of Giants
dont_starve_compatible = true
reign_of_giants_compatible = true
shipwrecked_compatible = true
hamlet_compatible = true
dst_compatible = true

--This lets clients know if they need to get the mod from the Steam Workshop to join the game
all_clients_require_mod = false

--This determines whether it causes a server to be marked as modded (and shows in the mod list)
client_only_mod = true

--This lets people search for servers with this mod by these tags
server_filter_tags = {}

icon_atlas = "combinedstatus.xml"
icon = "combinedstatus.tex"

forumthread = "/files/file/1136-combined-status/"

--[[
Credits:
	Kiopho for writing the original mod and giving me permission to maintain it for DST!
	Soilworker for making SeasonClock and allowing me to incorporate it
	hotmatrixx for making BetterMoon and allowing me to incorporate it
	penguin0616 for adding support for networked naughtiness in DST via their Insight mod
]]

local hud_scale_options = {}
for i = 1,21 do
	local scale = (i-1)*5 + 50
	hud_scale_options[i] = {description = ""..(scale*.01), data = scale}
end

configuration_options =
{
	{
		name = "SHOWTEMPERATURE",
		label = "Temperature",
		hover = "Show the temperature of the player.",
		options =	{
						{description = "Show", data = true},
						{description = "Hide", data = false},
					},
		default = true,
	},	
	{
		name = "SHOWWORLDTEMP",
		label = "Show World Temp",
		hover = "Show the temperature of the world\n(this does not take into account heat sources such as fires).",
		options =	{
						{description = "Show", data = true},
						{description = "Hide", data = false},
					},
		default = false,
	},	
	{
		name = "SHOWTEMPBADGES",
		label = "Show Temp Icons",
		hover = "Show images that indicate which temperature is which.",
		options =	{
						{description = "Show", data = true, hover = "Badges will only be shown if both temperatures are shown."},
						{description = "Hide", data = false, hover = "Badges will never be shown."},
					},
		default = true,
	},	
	{
		name = "UNIT",
		label = "Temperature Unit",
		hover = "Do the right thing, and leave this on Game.",
		options =	{
						{description = "Game Units", data = "T",
							hover = "The temperature numbers used by the game."
								.."\nFreeze at 0, overheat at 70; get warned 5 from each."},
						{description = "Celsius", data = "C",
							hover = "The temperature numbers used by the game, but halved to be more reasonable."
								.."\nFreeze at 0, overheat at 35; get warned 2.5 from each."},
						{description = "Fahrenheit", data = "F",
							hover = "Your favorite temperature units that make no sense."
								.."\nFreeze at 32, overheat at 158; get warned 9 from each."},
					},
		default = "T",
	},
	{
		name = "SHOWWANINGMOON",
		label = "Show Waning",
		hover = "Show both the waxing and waning moon phases separately."
			 .. "\nDoesn't do anything in DST, which already shows waxing and waning.",
		options =	{
						{description = "Show", data = true},
						{description = "Don't", data = false},
					},
		default = true,
	},
	{
		name = "SHOWMOON",
		label = "Show Moon",
		hover = "Show the moon phase during day and dusk.",
		options =	{
						{description = "Night Only", data = 0, hover = "Show the moon only at night, like usual."},
						{description = "Dusk", data = 1, hover = "Show the moon during both night and dusk."},
						{description = "Always", data = 2, hover = "Show the moon at all times."},
					},
		default = 1,
	},
	{
		name = "SHOWNEXTFULLMOON",
		label = "Predict Full Moon",
		hover = "Predicts the day number of the next full moon,"
			 .. "\nshowing it on the moon badge when moused over.",
		options =	{
						{description = "Yes", data = true},
						{description = "No", data = false},
					},
		default = true,
	},
	{
		name = "FLIPMOON",
		label = "Flip Moon",
		hover = "Flips the moon phase (Yes restores the old behavior)."
			.. "\nYes shows the moon as it looks in the Southern Hemisphere.",
		options =	{
						{description = "Yes", data = true, hover = "Show the moon like it is in Southern Hemisphere."},
						{description = "No", data = false, hover = "Show the moon like it is in the Northern Hemisphere."},
					},
		default = false,
	},
	{
		name = "SEASONOPTIONS",
		label = "Season Clock",
		hover = "Adds a clock that shows the seasons, and rearranges the status badges to fit better."
		.."\nAlternatively, adds a badge that shows days into the season and days remaining when moused over.",
		options =	{
						{description = "Micro", data = "Micro"},
						{description = "Compact", data = "Compact"},
						{description = "Clock", data = "Clock"},
						{description = "No", data = ""},
					},
		default = "Clock",
	},
	{
		name = "SHOWNAUGHTINESS",
		label = "Naughtiness",
		hover = "Show the naughtiness of the player.\nDoes not work in Don't Starve Together.",
		options =	{
						{description = "Show", data = true},
						{description = "Hide", data = false},
					},
		default = true,
	},	
	{
		name = "SHOWBEAVERNESS",
		label = "Log Meter",
		hover = "Show the log meter for Woodie when he is human.\nDoes not work in Don't Starve Together.",
		options =	{
						{description = "Always", data = true},
						{description = "Beaver", data = false},
					},
		default = true,
	},	
	{
		name = "HIDECAVECLOCK",
		label = "Cave Clock",
		hover = "Show the clock in the caves. Only works for Reign of Giants single-player.",
		options =	{
						{description = "Show", data = false},
						{description = "Hide", data = true},
					},
		default = false,
	},	
	{
		name = "SHOWSTATNUMBERS",
		label = "Stat Numbers",
		hover = "Show the health, hunger, and sanity numbers.",
		options =	{
						{description = "Current/Max", data = "Detailed"},
						{description = "Always", data = true},
						{description = "Hover", data = false},
					},
		default = true,
	},	
	{
		name = "SHOWMAXONNUMBERS",
		label = "Show Max Text",
		hover = "Show the \"Max:\" text on the maximum stat numbers to make it clearer.",
		options =	{
						{description = "Show", data = true},
						{description = "Hide", data = false},
					},
		default = true,
	},	
	{
		name = "SHOWCLOCKTEXT",
		label = "Show Clock Text",
		hover = "Show the text on the clock (day number) and season clock (current season).\nIf hidden, the text will only be shown when hovering over.",
		options =	{
						{description = "Show", data = true},
						{description = "Hide", data = false},
					},
		default = true,
	},	
	{
		name = "HUDSCALEFACTOR",
		label = "HUD Scale",
		hover = "Lets you adjust the size of the badges and clocks independently of the rest of the game HUD scale.",
		options = hud_scale_options,
		default = 100,
	},	
}