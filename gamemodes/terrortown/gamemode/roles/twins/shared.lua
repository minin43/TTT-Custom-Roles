-------------
-- CONVARS --
-------------

local twins_enabled = CreateConVar("ttt_twins_enabled", "0", FCVAR_REPLICATED)
local twins_invulnerability_timer = CreateConVar("ttt_twins_invulnerability_timer", "20", FCVAR_REPLICATED)

-- TODO: Figure out where to put twins ConVars in ULX, CONVARS.md, and the docs website

--------------------
-- PLAYER METHODS --
--------------------

local plymeta = FindMetaTable("Player")

function plymeta:GetTwin() return self:GetGoodTwin() or self:GetEvilTwin() end
function plymeta:IsTwin() return self:GetTwin() end
function plymeta:IsActiveTwin() return self:IsActiveGoodTwin() or self:IsActiveEvilTwin() end

-------------------
-- ROLE SPAWNING --
-------------------

ROLE_BLOCK_SPAWN_CONVARS[ROLE_GOODTWIN] = true
ROLE_BLOCK_SPAWN_CONVARS[ROLE_EVILTWIN] = true

hook.Add("TTTRoleSpawnsArtificially", "Twins_TTTRoleSpawnsArtificially", function(role)
    if role == ROLE_GOODTWIN or role == ROLE_EVILTWIN then
        if GetConVar("ttt_twins_enabled"):GetBool() then
            return true
        end
    end
end)