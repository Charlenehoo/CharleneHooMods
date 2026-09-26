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

---@param tr TraceResult
function TOOL:LeftClick(tr)
    if CLIENT then
        util.Decal("Cross", tr.StartPos, tr.HitPos, self:GetOwner())

        local dm = util.DecalMaterial("Cross")
        print(dm)
    end
end

---@param tr TraceResult
function TOOL:RightClick(tr)
    if SERVER then
        local e = ents.Create("prop_physics")
        e:SetModel("models/hunter/blocks/cube1x1x1.mdl")
        e:SetPos(tr.HitPos)
        e:Spawn()
    end
end
