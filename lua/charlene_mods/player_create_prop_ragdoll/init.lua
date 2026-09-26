-- lua\charlene_mods\player_create_prop_ragdoll\init.lua
AddCSLuaFile("shared.lua")

---@type PlayerCreatePropRagdollShared
local shared = include("shared.lua")
local MODULE_NAME = (shared and shared.MODULE_NAME) or "PlayerCreatePropRagdoll"

---@type Log
local log = include("charlene_mods/log.lua")

if not shared then
    log.Error(MODULE_NAME .. ": shared module not loaded, module aborted")
    return
end

local plyMeta = FindMetaTable("Player")
if not plyMeta then
    log.Error(MODULE_NAME .. ": FindMetaTable('Player') failed, module aborted")
    return
end

local originalCreateRagdoll = plyMeta.CreateRagdoll
if not originalCreateRagdoll then
    log.Error(MODULE_NAME .. ": missing method Player.CreateRagdoll, module aborted")
    return
end

---Sync the pose of the ragdoll to the given player
---@param ply Player
---@param ragdoll Entity
---@return boolean ok
local function syncPos(ply, ragdoll)
    local physCount = ragdoll:GetPhysicsObjectCount()
    if physCount < 1 then
        log.Warn("prop_ragdoll has no physics objects, player =", ply)
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

---@param ply Player
---@param ragdoll Entity
local function syncBaseAttrs(ply, ragdoll)
    ragdoll:SetPos(ply:GetPos())
    ragdoll:SetAngles(ply:GetAngles())
    ragdoll:SetBloodColor(ply:GetBloodColor())
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
    if not IsValid(ragdoll) then
        log.Warn("ents.Create('prop_ragdoll') returned invalid, player =", ply)
        return nil
    end

    if not syncModel(ply, ragdoll) then
        ragdoll:Remove()
        return nil
    end

    syncBaseAttrs(ply, ragdoll)
    ragdoll:Spawn()

    if not syncPos(ply, ragdoll) then
        ragdoll:Remove()
        return nil
    end

    return ragdoll
end

---@param ply Player
plyMeta.CreateRagdoll = function (ply)
    local ragdoll = createPropRagdoll(ply)
    if not ragdoll or not ragdoll:IsValid() then
        log.Warn("custom ragdoll creation failed, falling back to original, ply =", ply)
        return originalCreateRagdoll(ply)
    end
    ply:SetNW2Entity(shared.NW2_KEY_RAGDOLL, ragdoll)
    ragdoll:SetNW2Entity(shared.NW2_KEY_OWNER, ply)
    hook.Run("CreateEntityRagdoll", ply, ragdoll)
    log.Trace("custom ragdoll created, ply =", ply, "ragdoll =", ragdoll)
    return ragdoll
end

hook.Add("PostPlayerDeath", MODULE_NAME .. "PostPlayerDeath", function (ply)
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
    player:SetNW2Entity(shared.NW2_KEY_RAGDOLL, NULL)
end)
