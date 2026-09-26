-- lua\charlene_mods\player_create_prop_ragdoll\shared.lua

local MODULE_NAME = "PlayerCreatePropRagdoll"
if _G[MODULE_NAME] then return _G[MODULE_NAME] end

---@type Log
local log = include("charlene_mods/log.lua")

local plyMeta = FindMetaTable("Player")
if not plyMeta then
    log.Error(MODULE_NAME .. ": FindMetaTable('Player') failed, shared module aborted")
    return nil
end

local originalGetRagdollEntity = plyMeta.GetRagdollEntity
if not originalGetRagdollEntity then
    log.Error(MODULE_NAME .. ": Missing method Player.GetRagdollEntity, module aborted")
    return nil
end

local entMeta = FindMetaTable("Entity")
if not entMeta then
    log.Error(MODULE_NAME .. ": FindMetaTable('Entity') failed, shared module aborted")
    return nil
end

local originalGetRagdollOwner = entMeta.GetRagdollOwner
if not originalGetRagdollOwner then
    log.Error(MODULE_NAME .. ": Missing method Entity.GetRagdollOwner, module aborted")
    return nil
end

local Shared = {
    NW2KeyRagdoll = MODULE_NAME .. "Ragdoll",
    NW2KeyOwner   = MODULE_NAME .. "Owner",
}
_G[MODULE_NAME] = Shared

---@param self Player
---@return Entity
plyMeta.GetRagdollEntity = function (self)
    local ragdoll = self:GetNW2Entity(Shared.NW2KeyRagdoll)
    if IsValid(ragdoll) then return ragdoll end
    return originalGetRagdollEntity(self)
end

---@param self Entity
---@return Player
entMeta.GetRagdollOwner = function (self)
    local ply = self:GetNW2Entity(Shared.NW2KeyOwner)
    if IsValid(ply) then return ply end
    return originalGetRagdollOwner(self)
end

return Shared
