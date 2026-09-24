---@type Log
local log = include("charlene_mods/log.lua")

local originalDecal = util.Decal
if originalDecal then
    util.Decal = function (name, startPos, endPos, filter)
        log.Trace("name: ", name, "; start: ", startPos, "; end: ", endPos, "; filter: ", filter)

        originalDecal(name, startPos, endPos, filter)
    end
end


local originalDecalEx = util.DecalEx
if originalDecalEx then
    util.DecalEx = function (material, ent, position, normal, color, w, h)
        log.Trace("=======================")
        log.Trace("util.DecalEx is called")

        local materialName = material:GetName()
        local materialShader = material:GetShader()
        local materialWidth = material:Width()
        local materialHeight = IMaterial:Height()
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
        log.Trace("=======================")
        originalDecalEx(material, ent, position, normal, color, w, h)
    end
end
