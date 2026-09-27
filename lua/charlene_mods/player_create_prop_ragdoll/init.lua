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

---@param ply Player
---@param ragdoll Entity
---@return boolean ok
local function synAttrsAfterSpawn(ply, ragdoll)
    ragdoll:SetBloodColor(ply:GetBloodColor())
    ragdoll:SetSkin(ply:GetSkin())

    local bodyGroupCount = ply:GetNumBodyGroups()
    if bodyGroupCount > 0 then
        for bodyGroupID = 0, bodyGroupCount - 1 do
            ragdoll:SetBodygroup(bodyGroupID, ply:GetBodygroup(bodyGroupID))
        end
    end

    local physCount = ragdoll:GetPhysicsObjectCount()
    if physCount < 1 then
        log.Warn("prop_ragdoll has no physics objects, player =", ply)
        return false
    end

    local plyVelocity = ply:GetVelocity()

    for physNum = 0, physCount - 1 do
        local boneID = ragdoll:TranslatePhysBoneToBone(physNum)
        if boneID >= 0 then
            local bonePos, boneAng = ply:GetBonePosition(boneID)
            local phys = ragdoll:GetPhysicsObjectNum(physNum)
            if bonePos and phys:IsValid() then
                phys:SetPos(bonePos, true)
                phys:SetAngles(boneAng)
                phys:SetVelocity(plyVelocity)
                phys:EnableMotion(true)
                phys:Wake()
            end
        end
    end
    return true
end

---@param ply Player
---@param ragdoll Entity
---@return boolean ok
local function synAttrsBeforeSpawn(ply, ragdoll)
    local model = ply:GetModel()
    if not model or not util.IsValidModel(model) then
        log.Warn("invalid model, player =", ply, "model =", model)
        return false
    end
    ragdoll:SetModel(model)
    ragdoll:SetPos(ply:GetPos())
    ragdoll:SetAngles(ply:GetAngles())
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
    if not synAttrsBeforeSpawn(ply, ragdoll) then
        ragdoll:Remove()
        return nil
    end
    ragdoll:Spawn()
    if not synAttrsAfterSpawn(ply, ragdoll) then
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
    ply:Spectate(OBS_MODE_CHASE)
    ply:SpectateEntity(ragdoll)
    hook.Run("CreateEntityRagdoll", ply, ragdoll)
    log.Trace("custom ragdoll created, ply =", ply, "ragdoll =", ragdoll)
    return ragdoll
end

hook.Add("PlayerSpawn", MODULE_NAME .. "PlayerSpawn", function (player, transition)
    if transition then return end
    player:SetNW2Entity(shared.NW2_KEY_RAGDOLL, NULL)
end)
