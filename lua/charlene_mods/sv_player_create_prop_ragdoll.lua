-- lua/charlene_mods/sv_player_create_prop_ragdoll.lua

---@type Log
local log = include("charlene_mods/log.lua")

local MODULE_NAME = "PlayerCreatePropRagdoll"

---@type table<Player, Entity|nil>
local plyToRagdollMap = {}

---@type table<Entity, Player>
local ragdollToPlyMap = {}

---@param ply Player
---@return Entity|nil
local function createPropRagdoll(ply)
    local model = ply:GetModel()
    if not model or not util.IsValidModel(model) then
        log.Warn("invalid model, player =", ply, "model =", model)
        return nil
    end

    local ragdoll = ents.Create("prop_ragdoll")
    if not ragdoll:IsValid() then
        log.Warn("ents.Create('prop_ragdoll') returned invalid, player =", ply, "model =", model)
        return nil
    end

    ragdoll:SetModel(model)
    ragdoll:SetPos(ply:GetPos())
    ragdoll:SetAngles(ply:GetAngles())
    ragdoll:SetBloodColor(ply:GetBloodColor())
    ragdoll:Spawn()

    local physCount = ragdoll:GetPhysicsObjectCount()
    if physCount < 1 then
        log.Warn("prop_ragdoll has no physics objects, player =", ply, "model =", model)
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

    plyToRagdollMap[ply] = ragdoll
    ragdollToPlyMap[ragdoll] = ply
    hook.Run("CreateEntityRagdoll", ply, ragdoll)

    log.Trace("prop_ragdoll created, player =", ply, "ragdoll =", ragdoll,
        "EntIndex =", ragdoll:EntIndex(), "physCount =", physCount, "model =", model)
    return ragdoll
end

local plyMeta = FindMetaTable("Player")
if not plyMeta then
    log.Error("FindMetaTable('Player') failed, module aborted")
    return
end

local entMeta = FindMetaTable("Entity")
if not entMeta then
    log.Error("FindMetaTable('Entity') failed, module aborted")
    return
end

---@type fun(self: Player):Entity
local originalGetRagdollEntity = plyMeta.GetRagdollEntity
if not originalGetRagdollEntity then
    log.Error("missing method Player.GetRagdollEntity, module aborted")
    return
end

---@type fun(self: Entity):Player
local originalGetRagdollOwner = entMeta.GetRagdollOwner
if not originalGetRagdollOwner then
    log.Error("missing method Entity.GetRagdollOwner, module aborted")
    return
end

---@type fun(self: Player)
local originalCreateRagdoll = plyMeta.CreateRagdoll
if not originalCreateRagdoll then
    log.Error("missing method Player.CreateRagdoll, module aborted")
    return
end

---@param self Player
---@return Entity
plyMeta.GetRagdollEntity = function (self)
    local tracked = plyToRagdollMap[self]
    if tracked and tracked:IsValid() then
        return tracked
    end
    return originalGetRagdollEntity(self)
end

---@param self Entity
---@return Player
entMeta.GetRagdollOwner = function (self)
    local tracked = ragdollToPlyMap[self]
    if tracked and tracked:IsValid() then
        return tracked
    end
    return originalGetRagdollOwner(self)
end

---@param ply Player
plyMeta.CreateRagdoll = function (ply)
    local ragdoll = createPropRagdoll(ply)
    if not ragdoll or not ragdoll:IsValid() then
        log.Warn("custom ragdoll creation failed, falling back to original, ply =", ply)
        return originalCreateRagdoll(ply)
    end
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
    plyToRagdollMap[player] = nil
end)

hook.Add("EntityRemoved", MODULE_NAME .. "EntityRemoved", function (ent)
    ragdollToPlyMap[ent] = nil
end)

hook.Add("PlayerDisconnected", MODULE_NAME .. "PlayerDisconnected", function (ply)
    plyToRagdollMap[ply] = nil
    for ragdoll, owner in pairs(ragdollToPlyMap) do
        if owner == ply then
            ragdollToPlyMap[ragdoll] = nil
        end
    end
end)
