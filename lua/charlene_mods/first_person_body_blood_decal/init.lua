-- lua\charlene_mods\first_person_body_blood_decal\init.lua

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

---@type FirstPersonBodyBloodDecalShared
local shared = include("shared.lua")

---@type Log
local log = include("charlene_mods/log.lua")

if not shared then
    log.Error("FirstPersonBodyBloodDecal: shared module not loaded, server module aborted")
    return
end

hook.Add("PostPlayerDeath", shared.MODULE_NAME .. "PostPlayerDeath", function (ply)
    if not IsValid(ply) then return end

    net.Start(shared.NET_CLEAR_DECALS)
    net.Send(ply)

    log.Debug("notify client to clear body decals, ply =", ply)
end)
