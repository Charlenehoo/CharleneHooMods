-- cl_first_person_body_blood_decal.lua

---@type Log
local log = include("charlene_mods/log.lua")

---@class PlayerWithBody:Player
---@field Body Entity@C_PhysPropClientside

local originalDecalEx = util.DecalEx
if not originalDecalEx then
    log.Error("Cannot find function: util.DecalEx")
    return
end

---@param mat IMaterial
---@param ent Entity
---@param pos Vector
---@param normal Vector
---@param color Color
---@param w number
---@param h number
util.DecalEx = function (mat, ent, pos, normal, color, w, h)
    local ply = LocalPlayer() --[[@as PlayerWithBody]]

    if IsValid(ply) and ent == ply and IsValid(ply.Body) then
        ent = ply.Body
        log.Debug("swap: ", ply, " ->", Body)
    end

    originalDecalEx(mat, ent, pos, normal, color, w, h)
end
