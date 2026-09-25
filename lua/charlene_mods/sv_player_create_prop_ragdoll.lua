-- lua/charlene_mods/sv_player_create_prop_ragdoll.lua

---@type Log
local log = include("charlene_mods/log.lua")

local MODULE_NAME = "PlayerCreatePropRagdoll"

---@type table<Player, Entity|nil>
local plyToRagdollMap = {}

---@param ply Player
---@return Entity|nil
local function createPropRagdoll(ply)
    local model = ply:GetModel()
    if not model or not util.IsValidModel(model) then
        log.Warn("Invalid model for player:", ply, "; model =", model)
        return nil
    end

    local ragdoll = ents.Create("prop_ragdoll")
    if not ragdoll:IsValid() then
        log.Warn("ents.Create('prop_ragdoll') failed")
        return nil
    end

    ragdoll:SetModel(model)
    ragdoll:SetPos(ply:GetPos())
    ragdoll:SetAngles(ply:GetAngles())
    ragdoll:SetBloodColor(ply:GetBloodColor())
    ragdoll:Spawn()

    local physCount = ragdoll:GetPhysicsObjectCount()
    if physCount < 1 then
        log.Warn("prop_ragdoll has no physics objects")
        ragdoll:Remove()
        return nil
    end

    for physNum = 0, physCount - 1 do
        local boneID = ragdoll:TranslatePhysBoneToBone(physNum)
        if boneID >= 0 then
            local bonePos, boneAng = ply:GetBonePosition(boneID)
            local phys = ragdoll:GetPhysicsObjectNum(physNum)

            if bonePos and phys:IsValid() then
                phys:SetPos(bonePos, true)
                phys:SetAngles(boneAng)
                phys:EnableMotion(true)
                phys:Wake()
            end
        end
    end

    ragdoll.GetRagdollOwner = function (self)
        return ply
    end
    hook.Run("CreateEntityRagdoll", ply, ragdoll)
    return ragdoll
end

local meta = FindMetaTable("Player")
if not meta then
    log.Error("Cannot find meta table: Player")
    return
end

---@type fun(ply: Player):Entity
local originalGetRagdollEntity = meta.GetRagdollEntity
if not originalGetRagdollEntity then
    log.Error("Cannot find function: Player.GetRagdollEntity")
    return
end

---@type fun(ply: Player)
local originalCreateRagdoll = meta.CreateRagdoll
if not originalCreateRagdoll then
    log.Error("Cannot find function: Player.originalCreateRagdoll")
    return
end

---@param self Player
---@return Entity
meta.GetRagdollEntity = function (self)
    local tracked = plyToRagdollMap[self]
    if tracked and tracked:IsValid() then
        return tracked
    end
    return originalGetRagdollEntity(self)
end

---@param ply Player
meta.CreateRagdoll = function (ply)
    local ragdoll = createPropRagdoll(ply)
    if not ragdoll or not ragdoll:IsValid() then
        log.Warn("  prop_ragdoll creation failed")
        return originalCreateRagdoll(ply)
    end
    plyToRagdollMap[ply] = ragdoll
end

hook.Add("PlayerDeathThink", MODULE_NAME .. ".PlayerDeathThink", function (ply)
    local ragdoll = ply:GetRagdollEntity()
    if not IsValid(ragdoll) then return end

    if ply:GetObserverMode() ~= OBS_MODE_CHASE then
        ply:Spectate(OBS_MODE_CHASE)
    end
    if ply:GetObserverTarget() ~= ragdoll then
        ply:SpectateEntity(ragdoll)
    end
end)

hook.Add("PlayerSpawn", MODULE_NAME .. ".PlayerSpawn", function (player, transition)
    if transition then return end
    plyToRagdollMap[player] = nil
end)

hook.Add("PlayerDisconnected", MODULE_NAME .. ".PlayerDisconnected", function (ply)
    plyToRagdollMap[ply] = nil
end)
