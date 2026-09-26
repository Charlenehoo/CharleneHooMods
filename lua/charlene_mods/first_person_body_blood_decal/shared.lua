-- lua\charlene_mods\first_person_body_blood_decal\shared.lua

local MODULE_NAME = "FirstPersonBodyBloodDecal"
if _G[MODULE_NAME] then return _G[MODULE_NAME] end

---@class FirstPersonBodyBloodDecalShared
---@field MODULE_NAME string
---@field NET_CLEAR_DECALS string

local shared = {}
shared.MODULE_NAME = MODULE_NAME
shared.NET_CLEAR_DECALS = MODULE_NAME .. "ClearDecals"

_G[MODULE_NAME] = shared
return shared
