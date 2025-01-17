AddCSLuaFile()

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_illusionist_traitor_credits", "0", FCVAR_REPLICATED, "How many extra credits traitors (and monsters if `ttt_illusionist_hides_monsters` is enabled) should receive at the start of the round if there is an illusionist", 0, 10)

local illusionist_hides_monsters = CreateConVar("ttt_illusionist_hides_monsters", "0", FCVAR_REPLICATED, "Whether the illusionist should prevent monsters from knowing who their team mates are", 0, 1)

ROLE_CONVARS[ROLE_ILLUSIONIST] = {}
table.insert(ROLE_CONVARS[ROLE_ILLUSIONIST], {
    cvar = "ttt_illusionist_hides_monsters",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_ILLUSIONIST], {
    cvar = "ttt_illusionist_traitor_credits",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

---------------------
-- CREDIT TRANSFER --
---------------------

hook.Add("TTTPlayerCanSendCreditsTo", "Illusionist_TTTPlayerCanSendCreditsTo", function(sender, target, canSend)
    if GetGlobalBool("ttt_illusionist_alive", false) and (sender:IsTraitorTeam() or (sender:IsMonsterTeam() and illusionist_hides_monsters:GetBool())) then
        return false
    end
end)