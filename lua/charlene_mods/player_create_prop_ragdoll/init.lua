-- lua\charlene_mods\player_create_prop_ragdoll\init.lua
AddCSLuaFile("shared.lua")
local Shared = include("shared.lua")

---@type Log
local log = include("charlene_mods/log.lua")

if not Shared then
    log.Error("shared module not loaded, module aborted")
    return
end

local plyMeta = FindMetaTable("Player")
if not plyMeta then
    log.Error("FindMetaTable('Player') failed, module aborted")
    return
end

local originalCreateRagdoll = plyMeta.CreateRagdoll
if not originalCreateRagdoll then
    log.Error("missing method Player.CreateRagdoll, module aborted")
    return
end

local MODULE_NAME = "PlayerCreatePropRagdoll"

---Sync the pose of the ragdoll to the given player
---@param ply Player
---@param ragdoll Entity
---@return boolean ok
local function syncPos(ply, ragdoll)
    local physCount = ragdoll:GetPhysicsObjectCount()
    if physCount < 1 then
        log.Warn("prop_ragdoll has no physics objects, player =", ply, "model =", model)
        return false
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
    return true
end

---Sync the model of the ragdoll to the given player
---@param ply Player
---@param ragdoll Entity
---@return boolean ok
local function syncModel(ply, ragdoll)
    local model = ply:GetModel()
    if not model or not util.IsValidModel(model) then
        log.Warn("invalid model, player =", ply, "model =", model)
        return false
    end
    ragdoll:SetModel(model)
    return true
end

---@param ply Player
---@return Entity|nil
local function createPropRagdoll(ply)
    local ragdoll = ents.Create("prop_ragdoll")
    if not ragdoll:IsValid() then
        log.Warn("ents.Create('prop_ragdoll') returned invalid, player =", ply, "model =", model)
        return nil
    end

    if not syncModel(ply, ragdoll) then
        ragdoll:Remove()
        return nil
    end

    ragdoll:SetPos(ply:GetPos())
    ragdoll:SetAngles(ply:GetAngles())
    ragdoll:SetBloodColor(ply:GetBloodColor())
    ragdoll:Spawn()

    if not syncPos(ply, ragdoll) then
        ragdoll:Remove()
        return nil
    end

    log.Trace("created, player =", ply, "ragdoll =", ragdoll,
        "EntIndex =", ragdoll:EntIndex(), "physCount =", physCount, "model =", model)
    return ragdoll
end

---@param ply Player
plyMeta.CreateRagdoll = function (ply)
    local ragdoll = createPropRagdoll(ply)
    if not ragdoll or not ragdoll:IsValid() then
        log.Warn("custom ragdoll creation failed, falling back to original, ply =", ply)
        return originalCreateRagdoll(ply)
    end
    ply:SetNW2Entity(Shared.NW2KeyRagdoll, ragdoll)
    ragdoll:SetNW2Entity(Shared.NW2KeyOwner, ply)
    hook.Run("CreateEntityRagdoll", ply, ragdoll)
    log.Trace("custom ragdoll used, ply =", ply, "EntIndex =", ragdoll:EntIndex())
end

hook.Add("PlayerDeathThink", MODULE_NAME .. "PlayerDeathThink", function (ply)
    local ragdoll = ply:GetRagdollEntity()
    if not IsValid(ragdoll) then return end

    if ply:GetObserverMode() ~= OBS_MODE_CHASE then
        ply:Spectate(OBS_MODE_CHASE)
    end
    if ply:GetObserverTarget() ~= ragdoll then
        ply:SpectateEntity(ragdoll)
    end
end)

hook.Add("PlayerSpawn", MODULE_NAME .. "PlayerSpawn", function (player, transition)
    if transition then return end
    player:SetNW2Entity(Shared.NW2KeyRagdoll, NULL)
end)
