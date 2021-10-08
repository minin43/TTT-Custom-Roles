AddCSLuaFile()

if CLIENT then
    SWEP.PrintName = "Fangs"
    SWEP.EquipMenuData = {
        type = "Weapon",
        desc = "Left-click to suck blood. Right-click to fade."
    };

    SWEP.Slot = 8 -- add 1 to get the slot number key
    SWEP.ViewModelFOV = 54
    SWEP.ViewModelFlip = false
    SWEP.UseHands = true
else
    util.AddNetworkString("TTT_Vampified")
    util.AddNetworkString("TTT_Vampire_Fade")
end

SWEP.InLoadoutFor = { ROLE_VAMPIRE }

SWEP.Base = "weapon_tttbase"
SWEP.Category = WEAPON_CATEGORY_ROLE

SWEP.HoldType = "knife"

SWEP.ViewModel = Model("models/weapons/cstrike/c_knife_t.mdl")
SWEP.WorldModel = Model("models/weapons/w_knife_t.mdl")

SWEP.Primary.Ammo = "fade"
SWEP.Primary.ClipSize = 100
SWEP.Primary.DefaultClip = 100
SWEP.Primary.Automatic = false

SWEP.Secondary.Automatic = false

SWEP.Kind = WEAPON_ROLE
SWEP.LimitedStock = false
SWEP.AllowDrop = false

SWEP.TargetEntity = nil

local STATE_ERROR = -1
local STATE_NONE = 0
local STATE_EAT = 1
local STATE_DRAIN = 2
local STATE_CONVERT = 3
local STATE_KILL = 4

local beep = Sound("npc/fast_zombie/fz_alert_close1.wav")

local vampire_convert = CreateConVar("ttt_vampire_convert_enable", "0")
local vampire_drain = CreateConVar("ttt_vampire_drain_enable", "1")
local vampire_drain_first = CreateConVar("ttt_vampire_drain_first", "0")
local vampire_drain_credits = CreateConVar("ttt_vampire_drain_credits", "0")
local vampire_fang_dead_timer = CreateConVar("ttt_vampire_fang_dead_timer", "0")
local vampire_fang_timer = CreateConVar("ttt_vampire_fang_timer", "5")
local vampire_fang_heal = CreateConVar("ttt_vampire_fang_heal", "50")
local vampire_fang_overheal = CreateConVar("ttt_vampire_fang_overheal", "25")
local vampire_fang_overheal_living = CreateConVar("ttt_vampire_fang_overheal_living", "-1")
local vampire_fang_unfreeze_delay = CreateConVar("ttt_vampire_fang_unfreeze_delay", "1")
local vampire_prime_convert = CreateConVar("ttt_vampire_prime_only_convert", "1")

function SWEP:SetupDataTables()
    self:NetworkVar("Int", 0, "State")
    self:NetworkVar("Int", 1, "FangTime")
    self:NetworkVar("Int", 2, "DeadFangTime")
    self:NetworkVar("Float", 0, "StartTime")
    self:NetworkVar("String", 0, "Message")
    if SERVER then
        self:SetFangTime(vampire_fang_timer:GetInt())
        self:SetDeadFangTime(vampire_fang_dead_timer:GetInt())
        self:Reset()
    end
end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
    self.lastTickSecond = 0
    self.fading = false

    if CLIENT then
        self:AddHUDHelp("Left-click to suck blood", "Right-click to fade", false)
    end
end

function SWEP:Holster()
    self:FireError()
    return not self.fading
end

function SWEP:OnDrop()
    self:Remove()
end

function SWEP:OnRemove()
    self:UnfreezeTarget()
    if SERVER then
        self:Reset()
    end
end

function SWEP:CanConvert()
    return vampire_convert:GetBool() and (not vampire_prime_convert:GetBool() or self:GetOwner():IsVampirePrime())
end

local function GetPlayerFromBody(body)
    local ply = player.GetBySteamID64(body.sid64) or player.GetBySteamID(body.sid)
    if not IsValid(ply) then return false end
    return ply
end

function SWEP:PrimaryAttack()
    if CLIENT then return end

    local tr = self:GetTraceEntity()
    if IsValid(tr.Entity) then
        local ent = tr.Entity
        if ent:GetClass() == "prop_ragdoll" then
            local ply = GetPlayerFromBody(ent)
            if not IsValid(ply) or ply:Alive() then
                self:Error("INVALID TARGET")
                return
            end

            self:Eat(tr.Entity)
        elseif ent:IsPlayer() and vampire_drain:GetBool() then
            if ent:ShouldActLikeJester() then
                self:Error("TARGET IS A JESTER")
            -- Don't allow draining allies or glitches when the vampire is a traitor
            elseif ent:IsVampireAlly() or (TRAITOR_ROLES[ROLE_VAMPIRE] and ent:IsGlitch()) then
                self:Error("TARGET IS AN ALLY")
            else
                self:Drain(ent)
            end
        end
    end
end

function SWEP:SecondaryAttack()
    if self:Clip1() == 100 then
        self:SetClip1(0)

        if SERVER then
            net.Start("TTT_Vampire_Fade")
            net.WriteEntity(self:GetOwner())
            net.Broadcast()
        end
    end
end

function SWEP:GetFangDuration()
    local fang_time = self:GetDeadFangTime()
    if fang_time <= 0 or self:GetState() ~= STATE_EAT then
        fang_time = self:GetFangTime()
    end
    return fang_time
end

function SWEP:Eat(entity)
    self:GetOwner():EmitSound("weapons/ttt/vampireeat.wav")
    self:SetState(STATE_EAT)
    self:SetStartTime(CurTime())
    self:SetMessage("DRAINING BODY")

    self.TargetEntity = entity

    self:SetNextPrimaryFire(CurTime() + self:GetFangDuration())
end

function SWEP:Drain(entity)
    self:GetOwner():EmitSound("weapons/ttt/vampireeat.wav")
    self:SetState(STATE_DRAIN)
    self:SetStartTime(CurTime())
    self:SetMessage("DRAINING")
    self:CancelUnfreeze(entity)

    entity:PrintMessage(HUD_PRINTCENTER, "Someone is draining your blood!")
    self.TargetEntity = entity
    self:DoFreeze()

    self:SetNextPrimaryFire(CurTime() + self:GetFangDuration())
end

function SWEP:CancelUnfreeze(entity)
    if not IsPlayer(entity) then return end
    if not IsValid(self:GetOwner()) then return end
    local timerid = "VampUnfreezeDelay_" .. self:GetOwner():Nick() .. "_" .. entity:Nick()
    if timer.Exists(timerid) then
        self:AdjustFreezeCount(entity, -1, 1)
        timer.Remove(timerid)
    end
end

function SWEP:AdjustFreezeCount(ent, adj, def)
    local freeze_count =  math.max(0, ent:GetNWInt("VampireFreezeCount", def) + adj)
    ent:SetNWInt("VampireFreezeCount", freeze_count)
    return freeze_count
end

function SWEP:DoFreeze()
    self:AdjustFreezeCount(self.TargetEntity, 1, 0)
    self.TargetEntity:Freeze(true)
end

function SWEP:DoUnfreeze()
    local freeze_count = self:AdjustFreezeCount(self.TargetEntity, -1, 1)
    -- Only unfreeze the target if nobody else is draining them
    if freeze_count == 0 then
        self.TargetEntity:Freeze(false)
    end
    self.TargetEntity = nil
end

function SWEP:DoConvert()
    local ply = self.TargetEntity
    ply:StripRoleWeapons()
    if not ply:HasWeapon("weapon_zm_improvised") then
        ply:Give("weapon_zm_improvised")
    end
    ply:SetVampirePreviousRole(ply:GetRole())
    ply:SetRole(ROLE_VAMPIRE)
    ply:SetVampirePrime(false)
    ply:PrintMessage(HUD_PRINTCENTER, "You have become a Vampire! Use your fangs to suck blood or fade from view")

    net.Start("TTT_Vampified")
    net.WriteString(ply:Nick())
    net.Broadcast()

    -- Not actually an error, but it resets the things we want
    self:FireError()

    SendFullStateUpdate()
    -- Reset the victim's max health
    SetRoleMaxHealth(ply)
end

function SWEP:DoKill()
    local attacker = self:GetOwner()
    local dmginfo = DamageInfo()
    dmginfo:SetDamage(10000)
    dmginfo:SetAttacker(attacker)
    dmginfo:SetInflictor(game.GetWorld())
    dmginfo:SetDamageType(DMG_SLASH)
    dmginfo:SetDamageForce(Vector(0, 0, 0))
    dmginfo:SetDamagePosition(attacker:GetPos())
    self.TargetEntity:TakeDamageInfo(dmginfo)

    self:DoHeal(true)
    self:DropBones()

    -- Remove the body
    local rag = self.TargetEntity.server_ragdoll or self.TargetEntity:GetRagdollEntity()
    SafeRemoveEntity(rag)

    local amt = vampire_drain_credits:GetInt()
    if amt > 0 then
        LANG.Msg(attacker, "credit_all", { role = ROLE_STRINGS[ROLE_VAMPIRE], num = amt })
        attacker:AddCredits(amt)
    end

    -- Not actually an error, but it resets the things we want
    self:FireError()
end

function SWEP:DoHeal(living)
    local vamoverheal = vampire_fang_overheal_living:GetInt()
    if not living or vamoverheal < 0 then
        vamoverheal = vampire_fang_overheal:GetInt()
    end

    local vamheal = vampire_fang_heal:GetInt()
    self:GetOwner():SetHealth(math.min(self:GetOwner():Health() + vamheal, self:GetOwner():GetMaxHealth() + vamoverheal))
end

function SWEP:UnfreezeTarget()
    local owner = self:GetOwner()
    if not IsPlayer(self.TargetEntity) then return end

    self:CancelUnfreeze(self.TargetEntity)

    -- Unfreeze the target immediately if there is no delay or no owner
    local delay = vampire_fang_unfreeze_delay:GetFloat()
    if delay <= 0 or not IsPlayer(owner) then
        self:DoUnfreeze()
    else
        timer.Create("VampUnfreezeDelay_" .. owner:Nick() .. "_" .. self.TargetEntity:Nick(), delay, 1, function()
            if not IsPlayer(self.TargetEntity) then return end
            self:DoUnfreeze()
        end)
    end
end

function SWEP:FireError()
    self:SetState(STATE_NONE)
    self:UnfreezeTarget()
    self:SetNextPrimaryFire(CurTime() + 0.1)
end

function SWEP:DropBones()
    local pos = self.TargetEntity:GetPos()

    local skull = ents.Create("prop_physics")
    if not IsValid(skull) then return end
    skull:SetModel("models/Gibs/HGIBS.mdl")
    skull:SetPos(pos)
    skull:Spawn()
    skull:SetCollisionGroup(COLLISION_GROUP_WEAPON)

    local ribs = ents.Create("prop_physics")
    if not IsValid(ribs) then return end
    ribs:SetModel("models/Gibs/HGIBS_rib.mdl")
    ribs:SetPos(pos + Vector(0, 0, 15))
    ribs:Spawn()
    ribs:SetCollisionGroup(COLLISION_GROUP_WEAPON)

    local spine = ents.Create("prop_physics")
    if not IsValid(ribs) then return end
    spine:SetModel("models/Gibs/HGIBS_spine.mdl")
    spine:SetPos(pos + Vector(0, 0, 30))
    spine:Spawn()
    spine:SetCollisionGroup(COLLISION_GROUP_WEAPON)

    local scapula = ents.Create("prop_physics")
    if not IsValid(scapula) then return end
    scapula:SetModel("models/Gibs/HGIBS_scapula.mdl")
    scapula:SetPos(pos + Vector(0, 0, 45))
    scapula:Spawn()
    scapula:SetCollisionGroup(COLLISION_GROUP_WEAPON)
end

function SWEP:Think()
    if CLIENT then return end

    if (CurTime() - self.lastTickSecond > 0.08) and (self:Clip1() <= 100) then
        self:SetClip1(self:Clip1() + math.min(1, 100 - self:Clip1()))
        self.lastTickSecond = CurTime()
    end

    if self:Clip1() < 15 and not self.fading then
        self.fading = true
        self:GetOwner():SetColor(Color(255, 255, 255, 0))
        self:GetOwner():SetMaterial("sprites/heatwave")
        self:GetOwner():EmitSound("weapons/ttt/fade.wav")
    elseif self:Clip1() >= 40 and self.fading then
        self.fading = false
        self:GetOwner():SetColor(Color(255, 255, 255, 255))
        self:GetOwner():SetMaterial("models/glass")
        self:GetOwner():EmitSound("weapons/ttt/unfade.wav")
    end

    if self:GetState() >= STATE_EAT then
        if not IsValid(self:GetOwner()) then
            self:FireError()
            return
        end

        local tr = self:GetTraceEntity()
        if not self:GetOwner():KeyDown(IN_ATTACK) or tr.Entity ~= self.TargetEntity then
            -- Only allow doing the 1/2 progress actions if there are 2 actions enabled (e.g. drain and convert)
            if self:CanConvert() and IsPlayer(self.TargetEntity) and not self.TargetEntity:IsVampire() then
                if self:GetState() == STATE_KILL then
                    self:DoKill()
                    return
                elseif self:GetState() == STATE_CONVERT then
                    self:DoConvert()
                    return
                end
            end

            self:Error("DRAINING ABORTED")
            return
        end

        -- If there is a target and they have been turned to a vampire by someone else, stop trying to drain them
        if self:GetState() ~= STATE_EAT and (not IsPlayer(self.TargetEntity) or self.TargetEntity:IsVampire()) then
            self:Error("DRAINING ABORTED")
            return
        end

        if self:GetState() ~= STATE_DRAIN then
            if CurTime() >= self:GetStartTime() + self:GetFangDuration() then
                -- These seem backwards, but it's due to how the state tracking works.
                -- The "in-progress" state of killing a player is STATE_CONVERT because
                -- when "ttt_vampire_drain_first" is not enabled, the player will be "converting" until the very end.
                -- Therefore, the state will be STATE_CONVERT even though the end intent is to kill.
                -- When "ttt_vampire_drain_first" is enabled, the player will be "killing" until the very end.
                -- Therefore, the state will be STATE_KILL even though the end intent is to convert.
                -- Of course we also have to check that this vampire can actually convert and kill the target if they can't.
                if self:GetState() == STATE_CONVERT then
                    self:DoKill()
                elseif self:GetState() == STATE_KILL then
                    if self:CanConvert() then
                        self:DoConvert()
                    else
                        self:DoKill()
                    end
                else
                    self:DropBones()
                    self:DoHeal()
                    SafeRemoveEntity(self.TargetEntity)

                    -- Not actually an error, but it resets the things we want
                    self:FireError()
                end
            end
        else
            if CurTime() >= self:GetStartTime() + (self:GetFangDuration() / 2) then
                local verb = "CONVERT"
                if vampire_drain_first:GetBool() then
                    self:SetState(STATE_KILL)
                    verb = "KILL"
                else
                    self:SetState(STATE_CONVERT)
                end

                -- Only update the message if this player can convert
                if self:CanConvert() then
                    self:SetMessage("DRAINING - RELEASE TO " .. verb)
                end
            end
        end
    end
end

if CLIENT then
    function SWEP:DrawHUD()
        local x = ScrW() / 2.0
        local y = ScrH() / 2.0

        y = y + (y / 3)

        local w, h = 255, 20

        if self:GetState() >= STATE_EAT then
            local progress = math.TimeFraction(self:GetStartTime(), self:GetStartTime() + self:GetFangDuration(), CurTime())

            if progress < 0 then return end

            progress = math.Clamp(progress, 0, 1)

            surface.SetDrawColor(0, 255, 0, 155)

            surface.DrawOutlinedRect(x - w / 2, y - h, w, h)

            surface.DrawRect(x - w / 2, y - h, w * progress, h)

            surface.SetFont("TabLarge")
            surface.SetTextColor(255, 255, 255, 180)
            surface.SetTextPos((x - w / 2) + 3, y - h - 15)
            surface.DrawText(self:GetMessage())
        elseif self:GetState() == STATE_ERROR then
            surface.SetDrawColor(200 + math.sin(CurTime() * 32) * 50, 0, 0, 155)

            surface.DrawOutlinedRect(x - w / 2, y - h, w, h)

            surface.DrawRect(x - w / 2, y - h, w, h)

            surface.SetFont("TabLarge")
            surface.SetTextColor(255, 255, 255, 180)
            surface.SetTextPos((x - w / 2) + 3, y - h - 15)
            surface.DrawText(self:GetMessage())
        end
    end
else
    function SWEP:Reset()
        self:SetState(STATE_NONE)
        self:SetStartTime(-1)
        self:SetMessage('')
        self:SetNextPrimaryFire(CurTime() + 0.1)
    end

    function SWEP:Error(msg)
        self:SetState(STATE_ERROR)
        self:SetStartTime(CurTime())
        self:SetMessage(msg)

        self:GetOwner():EmitSound(beep, 60, 50, 1)
        self:UnfreezeTarget()

        timer.Simple(0.75, function()
            if IsValid(self) then self:Reset() end
        end)
    end

    function SWEP:GetTraceEntity()
        local spos = self:GetOwner():GetShootPos()
        local sdest = spos + (self:GetOwner():GetAimVector() * 70)
        local kmins = Vector(1,1,1) * -10
        local kmaxs = Vector(1,1,1) * 10

        return util.TraceHull({start=spos, endpos=sdest, filter=self:GetOwner(), mask=MASK_SHOT_HULL, mins=kmins, maxs=kmaxs})
    end
end

if CLIENT then
    net.Receive("TTT_Vampire_Fade", function()
        local ply = net.ReadEntity()
        if not IsValid(ply) or ply:IsSpec() or not ply:Alive() then return end

        local pos = ply:GetPos() + Vector(0, 0, 10)
        local client = LocalPlayer()
        if client:GetPos():Distance(pos) > 1000 then return end

        local emitter = ParticleEmitter(pos)
        for _ = 0, math.random(150, 250) do
            local max_height = ply:GetViewOffset().z + 10
            local height = math.random(0, max_height)

            -- Set width limits based on what the random height is so it vaguely resembles a person-shape (or just their head)
            local width_min = -20
            local width_max = 20

            local location = (height / max_height)
            -- Head
            if location > 0.75 then
                width_min = -5
                width_max = 5
            end

            local partpos = ply:GetPos() + Vector(math.random(width_min, width_max), math.random(width_min, width_max), height)
            local part = emitter:Add("particle/particle_smokegrenade", partpos)
            if part then
                part:SetDieTime(math.random(0.7, 1.2))
                part:SetStartAlpha(math.random(200, 240))
                part:SetEndAlpha(0)
                part:SetColor(math.random(200, 220), math.random(200, 220), math.random(200, 220))

                part:SetStartSize(math.random(6, 8))
                part:SetEndSize(0)

                part:SetRoll(0)
                part:SetRollDelta(0)

                local velocity = VectorRand() * math.random(10, 15);
                velocity.z = 5;
                part:SetVelocity(velocity)
            end
        end

        emitter:Finish()
    end)
end