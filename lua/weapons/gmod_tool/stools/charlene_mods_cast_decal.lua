TOOL.Category = "Charlene Mods"
TOOL.Name = "Cast Decal"

-- ANIMATED_WOUNDS = ANIMATED_BLOOD_CREATE_MATERIALS({
--     { dir = "materials/animated_blood/wounds/blood1_mats", animStopTime = 4.2 },
--     { dir = "materials/animated_blood/wounds/blood3_mats", animStopTime = 4.6 },
--     { dir = "materials/animated_blood/wounds/blood9_mats", animStopTime = 4.5 },
--     { dir = "materials/animated_blood/wounds/blood10_mats", animStopTime = 4.5 },
--     { dir = "materials/animated_blood/wounds/blood11_mats", animStopTime = 4.6 },
--     { dir = "materials/animated_blood/wounds/blood12_mats", animStopTime = 4.6 },
-- })

---comment
---@param tr TraceResult
function TOOL:LeftClick(tr)
    if CLIENT then
        local pos = tr.HitPos
        local normal = tr.HitNormal
        local ent = tr.Entity
        if not IsValid(ent) then return false end
        local folderDir = "materials/animated_blood/wounds/blood1_mats"
        local vmtKey = 1
        local radius = 32
        local bloodmat = ANIMATED_WOUNDS[folderDir][vmtKey]
        util.DecalEx(bloodmat.mat, ent, pos, normal, white, radius, radius)
        return true
    end
end
