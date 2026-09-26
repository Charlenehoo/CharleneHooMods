---@type Log
local log = include("charlene_mods/log.lua")

local originalDecal = util.Decal
util.Decal = function (name, startPos, endPos, filter)
    log.Trace("util.Decal is called")
    log.Trace("name: ", name, "; start: ", startPos, "; end: ", endPos, "; filter: ", filter)
    originalDecal(name, startPos, endPos, filter)
end

local originalDecalEx = util.DecalEx
util.DecalEx = function (material, ent, position, normal, color, w, h)
    local materialName = material:GetName()
    local materialShader = material:GetShader()
    local materialWidth = material:Width()
    local materialHeight = material:Height()
    log.Trace(
        "materialName: ", materialName,
        "; materialShader: ", materialShader,
        "; materialWidth: ", materialWidth,
        "; materialHeight: ", materialHeight
    )
    log.Trace(
        "ent: ", ent,
        "; position: ", position,
        "; normal: ", normal,
        "; color: ", color,
        "; w: ", w,
        "; h: ", h
    )
    originalDecalEx(material, ent, position, normal, color, w, h)
end

log.Info("sh_decal_monitor loaded")
