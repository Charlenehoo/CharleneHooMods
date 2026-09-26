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
        local body = ply.Body

        -- 1) 世界坐标 -> ply 本地空间 -> body 本地空间 -> body 的世界空间
        local localPos = ply:WorldToLocal(pos)
        local worldPos = body:LocalToWorld(localPos)

        -- 2) normal 只需要方向旋转（不能加平移），做一次 direction 变换
        local localDir = ply:WorldToLocal(pos + normal) - localPos
        local worldNormal = body:LocalToWorld(localDir) - body:LocalToWorld(vector_origin)

        ent = body
        pos = worldPos
        normal = worldNormal

        log.Debug("swap: ", ply, " ->", body)
    end

    originalDecalEx(mat, ent, pos, normal, color, w, h)
end
