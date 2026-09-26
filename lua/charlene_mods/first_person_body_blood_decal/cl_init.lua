-- lua\charlene_mods\first_person_body_blood_decal\cl_init.lua

---@type FirstPersonBodyBloodDecalShared
local shared = include("shared.lua")

---@type Log
local log = include("charlene_mods/log.lua")

if not shared then
    log.Error("FirstPersonBodyBloodDecal: shared module not loaded, client module aborted")
    return
end

---@class PlayerWithBody:Player
---@field Body Entity@C_PhysPropClientside

-- ============================================================
-- 1) 把贴到玩家身上的 decal 重定向到 ply.Body
-- ============================================================

local originalDecalEx = util.DecalEx
if originalDecalEx then
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
else
    log.Error("Cannot find function: util.DecalEx")
end

-- ============================================================
-- 2) 接收服务端通知，清理本地玩家 Body 上的 decal
--    每个客户端的 ply.Body 都是本地实体，所以只需要由本人处理
-- ============================================================

net.Receive(shared.NET_CLEAR_DECALS, function ()
    local ply = LocalPlayer() --[[@as PlayerWithBody]]
    if not IsValid(ply) then return end

    local body = ply.Body
    if not IsValid(body) then return end

    body:RemoveAllDecals()
    log.Debug("cleared all decals on local body, body =", body)
end)
