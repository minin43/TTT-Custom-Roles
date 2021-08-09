AddCSLuaFile()

if CLIENT then
    SWEP.PrintName = "Fake Parasite Cure"
    SWEP.Slot = 6

    SWEP.DrawCrosshair = false
    SWEP.ViewModelFOV = 54

    SWEP.EquipMenuData = {
            type =  "Weapon",
            desc =  [[Use on a player to trick them into thinking you cured the parasite.]]
        };

    SWEP.Icon = "vgui/ttt/icon_fakecure"
end

SWEP.Base = "weapon_tttbase"

SWEP.ViewModel = "models/weapons/c_medkit.mdl"
SWEP.WorldModel = "models/weapons/w_medkit.mdl"

SWEP.Primary.ClipSize        = -1
SWEP.Primary.DefaultClip     = -1
SWEP.Primary.Automatic       = true
SWEP.Primary.Delay           = 1
SWEP.Primary.Ammo            = "none"

SWEP.Secondary.ClipSize       = -1
SWEP.Secondary.DefaultClip    = -1
SWEP.Secondary.Automatic      = true
SWEP.Secondary.Ammo           = "none"
SWEP.Secondary.Delay          = 2

SWEP.Kind = WEAPON_EQUIP
SWEP.CanBuy = { ROLE_QUACK }
SWEP.CanBuyDefault = { ROLE_QUACK }
SWEP.NoSights = true
SWEP.HoldType = "slam"

SWEP.UseHands = true
SWEP.ViewModelFlip = false
SWEP.BlockShopRandomization = true

local DEFIB_IDLE = 0
local DEFIB_BUSY = 1
local DEFIB_ERROR = 2

local charge = 3

local beep = Sound("buttons/button17.wav")
local hum = Sound("items/nvg_on.wav")
local cured = Sound("items/smallmedkit1.wav")

if CLIENT then
    function SWEP:Initialize()
        self:AddHUDHelp("cure_help_pri", "cure_help_sec", true)
        self:SetHoldType(self.HoldType)
        return self.BaseClass.Initialize(self)
    end
end

function SWEP:SetupDataTables()
    self:NetworkVar("Int", 0, "State")
    self:NetworkVar("Float", 1, "Begin")
    self:NetworkVar("String", 0, "Message")
end

if SERVER then
    function SWEP:Reset()
        self:SetState(DEFIB_IDLE)
        self:SetBegin(-1)
        self:SetMessage('')
        self.Target = nil
    end

    function SWEP:Error(msg)
        self:SetState(DEFIB_ERROR)
        self:SetBegin(CurTime())
        self:SetMessage(msg)

        self:GetOwner():EmitSound(beep, 60, 50, 1)
        self.Target = nil

        timer.Simple(3 * 0.75, function()
            if IsValid(self) then self:Reset() end
        end)
    end

    function SWEP:DoCure(ply)
        local owner = self:GetOwner()
        if IsValid(ply) and ply:IsPlayer() then
            ply:EmitSound(cured)

            self:Remove()
        else
            if ply == owner then
                self:SetNextPrimaryFire(CurTime() + 1)
            else
                self:SetNextSecondaryFire(CurTime() + 1)
            end
        end
    end

    function SWEP:Begin(ply)
        if not ply or not IsValid(ply) or not ply:IsPlayer() then
            self:Error("INVALID TARGET")
            return
        end

        self:SetState(DEFIB_BUSY)
        self:SetBegin(CurTime())
        if ply == self:GetOwner() then
            self:SetMessage("CURING YOURSELF")
        else
            self:SetMessage("CURING " .. string.upper(ply:Nick()))
        end

        self:GetOwner():EmitSound(hum, 75, math.random(98, 102), 1)

        self.Target = ply
    end

    function SWEP:Think()
        if self:GetState() == DEFIB_BUSY then
            local owner = self:GetOwner()
            if self:GetBegin() + charge <= CurTime() then
                self:DoCure(self.Target)
                self:Reset()
            elseif owner == self.Target then
                if not owner:KeyDown(IN_ATTACK2) then
                    self:Error("CURE ABORTED")
                end
            elseif not owner:KeyDown(IN_ATTACK) or owner:GetEyeTrace(MASK_SHOT_HULL).Entity ~= self.Target then
                self:Error("CURE ABORTED")
            end
        end
    end

    function SWEP:PrimaryAttack()
        if self:GetState() ~= DEFIB_IDLE then return end
        if GetRoundState() ~= ROUND_ACTIVE then return end

        local owner = self:GetOwner()
        local tr = util.TraceLine({
            start = owner:GetShootPos(),
            endpos = owner:GetShootPos() + owner:GetAimVector() * 64,
            filter = owner
        })

        local ent = tr.Entity
        if ent and IsValid(ent) and ent:IsPlayer() then
            self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
            self:Begin(ent)
        end
    end

    function SWEP:SecondaryAttack()
        if self:GetState() ~= DEFIB_IDLE then return end
        if GetRoundState() ~= ROUND_ACTIVE then return end

        local owner = self:GetOwner()
        if owner and IsValid(owner) and owner:IsPlayer() then
            self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
            self:Begin(owner)
        end
    end
end

if CLIENT then
    function SWEP:DrawHUD()
        local state = self:GetState()
        self.BaseClass.DrawHUD(self)

        if state == DEFIB_IDLE then return end

        local timer = self:GetBegin() + charge

        local x = ScrW() / 2.0
        local y = ScrH() / 2.0

        y = y + (y / 3)

        local w, h = 255, 20

        if state == DEFIB_BUSY then
            if timer < 0 then return end

            local cc = math.min(1, 1 - ((timer - CurTime()) / charge))

            surface.SetDrawColor(0, 255, 0, 155)

            surface.DrawOutlinedRect(x - w / 2, y - h, w, h)

            surface.DrawRect(x - w / 2, y - h, w * cc, h)

            surface.SetFont("TabLarge")
            surface.SetTextColor(255, 255, 255, 180)
            surface.SetTextPos((x - w / 2) + 3, y - h - 15)
            surface.DrawText(self:GetMessage())
        elseif state == DEFIB_ERROR then
            surface.SetDrawColor(200 + math.sin(CurTime() * 32) * 50, 0, 0, 155)

            surface.DrawOutlinedRect(x - w / 2, y - h, w, h)

            surface.DrawRect(x - w / 2, y - h, w, h)

            surface.SetFont("TabLarge")
            surface.SetTextColor(255, 255, 255, 180)
            surface.SetTextPos((x - w / 2) + 3, y - h - 15)
            surface.DrawText(self:GetMessage())
        end
    end

    function SWEP:PrimaryAttack() return false end
end

function SWEP:DryFire() return false end