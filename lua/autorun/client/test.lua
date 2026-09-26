-- lua\autorun\client\test.lua
concommand.Add("test_create", function ()
    local ply = LocalPlayer()

    local e = ents.CreateClientProp(ply:GetModel())
    if not IsValid(e) then
        print("[test_create] 创建客户端道具失败")
        return
    end

    e:SetPos(ply:GetPos() + ply:GetForward() * 100)
    e:Spawn()
    e:SetIK(false)
    e:PhysicsDestroy() -- 纯渲染用，去掉物理

    -- 等一帧，确保模型和碰撞已经准备好
    timer.Simple(0, function ()
        if not IsValid(e) then return end

        local im = Material("decals/cross")
        if not im or im:IsError() then
            print("[test_create] 材质 decals/cross 加载失败")
            return
        end

        -- 取模型本地包围盒，在顶面贴一个 cross
        local maxs = e:OBBMaxs()
        local topWorldPos = e:LocalToWorld(Vector(maxs.x, 0, maxs.z / 2))
        local topNormal = e:GetForward()

        util.DecalEx(im, e, topWorldPos, topNormal, color_white, 1, 1)
    end)
end)

concommand.Add("test_body", function ()
    local ply = LocalPlayer()

    local e = ply.Body
    if not IsValid(e) then
        print("[test_body] 找到身体失败")
        return
    end

    local im = Material("decals/cross")
    if not im or im:IsError() then
        print("[test_body] 材质 decals/cross 加载失败")
        return
    end

    -- 取模型本地包围盒，在顶面贴一个 cross
    local maxs = e:OBBMaxs()
    local topWorldPos = e:LocalToWorld(Vector(maxs.x, 0, maxs.z / 2))
    local topNormal = e:GetForward()

    util.DecalEx(im, e, topWorldPos, topNormal, color_white, 1, 1)
end)
