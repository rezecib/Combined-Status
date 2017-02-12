local Image = require "widgets/image"
local Widget = require "widgets/widget"
local UIAnim = require "widgets/uianim"

local PlayerBadge = Class(Widget, function(self, prefab, colour, image)
    Widget._ctor(self, "PlayerBadge")
    self.isFE = false
    self:SetClickable(false)

    self.root = self:AddChild(Widget("root"))
    -- self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)

    self.icon = self.root:AddChild(Widget("target"))
    self.icon:SetScale(.8)

    self.headbg = self.icon:AddChild(Image("images/avatars_combined_status.xml", "avatar_bg.tex"))
	if image then
		self.head = self.icon:AddChild(Image(image.atlas, image.image))
	else
		self.head = self.icon:AddChild(UIAnim())
		self.head:GetAnimState():SetBank("wilson")
		self.head:GetAnimState():SetBuild(prefab)
		self.head:GetAnimState():Hide("ARM_carry")
		self.head:GetAnimState():Hide("ARM_normal")
		self.head:GetAnimState():Hide("ARM_upper")
		self.head:GetAnimState():Hide("ARM_lower")
		self.head:GetAnimState():Hide("leg")
		self.head:GetAnimState():Hide("foot")
		self.head:GetAnimState():Hide("torso")
		self.head:GetAnimState():Hide("hand")
		self.head:GetAnimState():SetPercent("research", 1)
		self.head:SetScale(0.2)
		self.head:SetPosition(0, -45, 0)
	end
    self.headframe = self.icon:AddChild(Image("images/avatars_combined_status.xml", "avatar_frame_white.tex"))
    self.headframe:SetTint(unpack(colour))
end)
return PlayerBadge
