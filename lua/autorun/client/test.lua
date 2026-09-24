-- lua\autorun\client\test.lua
concommand.Add("test", function ()
    local tr = util.TraceLine(
        {
            start = LocalPlayer():GetShootPos(),
            endpos = LocalPlayer():GetShootPos() + LocalPlayer():GetAimVector() * 1000,
            filter = LocalPlayer(),
            mask = MASK_SHOT,
        }
    )

    local pos = tr.HitPos
    local normal = tr.HitNormal
    local ent = tr.Entity
    if not IsValid(ent) then return end

    local folderDir = "materials/animated_blood/wounds/blood1_mats"
    local vmtKey = 3
    local radius = 32
    local bloodmat = ANIMATED_WOUNDS[folderDir][vmtKey]
    util.DecalEx(bloodmat.mat, ent, pos, normal, white, radius, radius)
end)
