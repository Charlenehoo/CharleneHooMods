-- lua\autorun\client\test.lua
concommand.Add("test", function ()
    util.Decal(
        "Cross",
        LocalPlayer():GetShootPos(),
        LocalPlayer():GetShootPos() + LocalPlayer():GetAimVector() * 1000,
        LocalPlayer()
    )
end)
