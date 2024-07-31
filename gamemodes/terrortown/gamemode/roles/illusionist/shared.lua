AddCSLuaFile()

------------------
-- ROLE CONVARS --
------------------

local illusionist_hides_monsters = CreateConVar("ttt_illusionist_hides_monsters", "0", FCVAR_REPLICATED, "Whether the illusionist should prevent monsters from knowing who their team mates are", 0, 1)

ROLE_CONVARS[ROLE_ILLUSIONIST] = {}
table.insert(ROLE_CONVARS[ROLE_ILLUSIONIST], {
    cvar = "ttt_illusionist_hides_monsters",
    type = ROLE_CONVAR_TYPE_BOOL
})

---------------------
-- CREDIT TRANSFER --
---------------------

hook.Add("TTTPlayerCanSendCreditsTo", "Illusionist_TTTPlayerCanSendCreditsTo", function(sender, target, canSend)
    if GetGlobalBool("ttt_illusionist_alive", false) and (sender:IsTraitorTeam() or (sender:IsMonsterTeam() and illusionist_hides_monsters:GetBool())) then
        return false
    end
end)