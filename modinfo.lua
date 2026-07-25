---@diagnostic disable: lowercase-global

local L = locale
local function en_zh(en, zh)
    return L ~= "zh" and L ~= "zhr" and L ~= "zht" and en or zh
end

--The name of the mod displayed in the 'mods' screen.
name = en_zh("Combined Status", "综合状态显示")

--A description of the mod.
description = en_zh("Displays Health, Hunger, Sanity, Temperature, Seasons, Moon Phase, and World Day.", "显示血量、饥饿值、精神值、温度、季节、月相和天数。")

--Who wrote this awesome mod?
author = "rezecib, Kiopho, Soilworker, hotmatrixx, penguin0616"

--A version number so you can ask people if they are running an old version of your mod.
version = "1.9.5"

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
	冰冰羊 for providing the Chinese translation
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
		label = en_zh("Temperature", "温度"),
		hover = en_zh("Show the temperature of the player.", "显示玩家温度"),
		options =	{
						{description = en_zh("Show", "显示"), data = true},
						{description = en_zh("Hide", "隐藏"), data = false},
					},
		default = true,
	},
	{
		name = "SHOWWORLDTEMP",
		label = en_zh("Show World Temp", "显示世界温度"),
		hover = en_zh("Show the temperature of the world\n(this does not take into account heat sources such as fires).", "显示世界温度（这不考虑热源，如火灾）"),
		options =	{
						{description = en_zh("Show", "显示"), data = true},
						{description = en_zh("Hide", "隐藏"), data = false},
					},
		default = false,
	},
	{
		name = "SHOWTEMPBADGES",
		label = en_zh("Show Temp Icons", "显示温度图标"),
		hover = en_zh("Show images that indicate which temperature is which.", "显示用于区分不同温度的图标。"),
		options =	{
						{description = en_zh("Show", "显示"), data = true, hover = en_zh("Badges will only be shown if both temperatures are shown.", "只有当两个温度都显示时，才会显示图标。")},
						{description = en_zh("Hide", "隐藏"), data = false, hover = en_zh("Badges will never be shown.", "永远不会显示图标")},
					},
		default = true,
	},
	{
		name = "UNIT",
		label = en_zh("Temperature Unit", "温度单位"),
		hover = en_zh("Do the right thing, and leave this on Game.", "做正确的事，把这个保持在游戏单位。"),
		options =	{
						{description = en_zh("Game Units", "游戏单位"), data = "T",
							hover = en_zh("The temperature numbers used by the game."
								.."\nFreeze at 0, overheat at 70; get warned 5 from each.",
										  "游戏使用的温度数值。"
								.."\n在0度冻结，在70度过热；每5度警示一次")
						},
						{description = en_zh("Celsius", "摄氏"), data = "C",
							hover = en_zh("The temperature numbers used by the game, but halved to be more reasonable."
								.."\nFreeze at 0, overheat at 35; get warned 2.5 from each.",
										  "游戏使用的温度数值，但减半以更合理。"
								.."\n在0度冻结，在35度过热；每2.5度警示一次")
						},
						{description = en_zh("Fahrenheit", "华氏"), data = "F",
							hover = en_zh("Your favorite temperature units that make no sense."
								.."\nFreeze at 32, overheat at 158; get warned 9 from each.",
										  "你最喜欢的奇怪温度单位。"
								.."\n在32度冻结，在158度过热；每9度警示一次")
						},
					},
		default = "T",
	},
	{
		name = "SHOWWANINGMOON",
		label = en_zh("Show Waning", "显示月相状态"),
		hover = en_zh("Show both the waxing and waning moon phases separately."
			 .. "\nDoesn't do anything in DST, which already shows waxing and waning.",
					  "分别展示出盈月和亏月的阶段。"
			 .. "\n在饥荒联机版上没有任何作用，因为它自带这个功能。"
					),
		options =	{
						{description = en_zh("Show", "显示"), data = true},
						{description = en_zh("Don't", "不要"), data = false},
					},
		default = true,
	},
	{
		name = "SHOWMOON",
		label = en_zh("Show Moon", "显示月相"),
		hover = en_zh("Show the moon phase during day and dusk.", "设定要在哪个时段显示月相状态"),
		options =	{
						{description = en_zh("Night Only", "只有晚上"), data = 0, hover = en_zh("Show the moon only at night, like usual.", "像往常一样，只在晚上显示月相。")},
						{description = en_zh("Dusk", "黄昏"), data = 1, hover = en_zh("Show the moon during both night and dusk.", "在黄昏和夜晚时显示月相。")},
						{description = en_zh("Always", "始终"), data = 2, hover = en_zh("Show the moon at all times.", "全天显示月相。")},
					},
		default = 1,
	},
	{
		name = "SHOWNEXTFULLMOON",
		label = en_zh("Predict Full Moon", "预测满月"),
		hover = en_zh("Predicts the day number of the next full moon,"
			 .. "\nshowing it on the moon badge when moused over.",
					  "预测下一个满月的天数，"
			 .. "\n当鼠标移到月相图标上时显示。"
			),
		options =	{
						{description = en_zh("Yes", "是"), data = true},
						{description = en_zh("No", "否"), data = false},
					},
		default = true,
	},
	{
		name = "FLIPMOON",
		label = en_zh("Flip Moon", "翻转月相"),
		hover = en_zh("Flips the moon phase (Yes restores the old behavior)."
			.. "\nYes shows the moon as it looks in the Southern Hemisphere.",
					  "翻转月相（开启后恢复旧版的行为方式）。"
			.. "\n开启后显示南半球视角下的月相。"),
		options =	{
						{description = en_zh("Yes", "是"), data = true, hover = en_zh("Show the moon like it is in Southern Hemisphere.", "展示南半球的月相")},
						{description = en_zh("No", "否"), data = false, hover = en_zh("Show the moon like it is in the Northern Hemisphere.", "展示北半球的月相")},
					},
		default = false,
	},
	{
		name = "SEASONOPTIONS",
		label = en_zh("Season Clock", "季节时钟"),
		hover = en_zh("Adds a clock that shows the seasons, and rearranges the status badges to fit better."
		.."\nAlternatively, adds a badge that shows days into the season and days remaining when moused over.",
					  "添加一个显示季节的时钟，并重新排列状态徽章以获得更好的显示效果。"
		.."\n或者添加一个徽章，显示当前季节已过天数，在鼠标悬停时显示剩余天数。"),
		options =	{
						{description = en_zh("Micro", "微型"), data = "Micro"},
						{description = en_zh("Compact", "紧凑型"), data = "Compact"},
						{description = en_zh("Clock", "时钟型"), data = "Clock"},
						{description = en_zh("No", "否"), data = ""},
					},
		default = "Clock",
	},
	{
		name = "SHOWNAUGHTINESS",
		label = en_zh("Naughtiness", "淘气值"),
		hover = en_zh("Show the naughtiness of the player.\nDoes not work in Don't Starve Together.", "显示玩家的淘气值。\n此功能无法在饥荒联机版使用。"),
		options =	{
						{description = en_zh("Show", "显示"), data = true},
						{description = en_zh("Hide", "隐藏"), data = false},
					},
		default = true,
	},
	{
		name = "SHOWBEAVERNESS",
		label = en_zh("Log Meter", "木头值"),
		hover = en_zh("Show the log meter for Woodie when he is human.\nDoes not work in Don't Starve Together.", "当伍迪是人类时，显示他的木头值。\n此功能无法在饥荒联机版使用。"),
		options =	{
						{description = en_zh("Always", "始终"), data = true},
						{description = en_zh("Beaver", "海狸"), data = false},
					},
		default = true,
	},
	{
		name = "HIDECAVECLOCK",
		label = en_zh("Cave Clock", "洞穴时钟"),
		hover = en_zh("Show the clock in the caves. Only works for Reign of Giants single-player.", "在洞穴中显示时钟。仅适用于单机版巨人国。"),
		options =	{
						{description = en_zh("Show", "显示"), data = false},
						{description = en_zh("Hide", "隐藏"), data = true},
					},
		default = false,
	},
	{
		name = "SHOWSTATNUMBERS",
		label = en_zh("Stat Numbers", "属性数值"),
		hover = en_zh("Show the health, hunger, and sanity numbers.", "显示当前的生命值、饥饿值和精神值的数字"),
		options =	{
						{description = en_zh("Current/Max", "当前/最大值"), data = "Detailed"},
						{description = en_zh("Always", "始终显示"), data = true},
						{description = en_zh("Hover", "悬停显示"), data = false},
					},
		default = true,
	},
	{
		name = "SHOWMAXONNUMBERS",
		label = en_zh("Show Max Text", "显示最大值文本"),
		hover = en_zh("Show the \"Max:\" text on the maximum stat numbers to make it clearer.", "在最大数值属性上显示“最大值：”文字，使其更直观。"),
		options =	{
						{description = en_zh("Show", "显示"), data = true},
						{description = en_zh("Hide", "隐藏"), data = false},
					},
		default = true,
	},
	{
		name = "SHOWCLOCKTEXT",
		label = en_zh("Show Clock Text", "显示时钟上的文字"),
		hover = en_zh("Show the text on the clock (day number) and season clock (current season).\nIf hidden, the text will only be shown when hovering over.", "在时钟（天数）和季节时钟（当前季节）上显示文字。\n如果隐藏，则只会在鼠标悬停时才会显示。"),
		options =	{
						{description = en_zh("Show", "显示"), data = true},
						{description = en_zh("Hide", "隐藏"), data = false},
					},
		default = true,
	},
	{
		name = "HUDSCALEFACTOR",
		label = en_zh("HUD Scale", "HUD缩放"),
		hover = en_zh("Lets you adjust the size of the badges and clocks independently of the rest of the game HUD scale.", "允许你独立调整状态徽章和时钟的大小，而不受游戏其它HUD缩放比例影响。"),
		options = hud_scale_options,
		default = 100,
	},
}
