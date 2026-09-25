TOOL.Category = "Charlene Mods"
TOOL.Name = "Test Owner"

---@type Log
local log = include("charlene_mods/log.lua")

---@param tr TraceResult
function TOOL:LeftClick(tr)
    local clickEnt = tr.Entity
    if clickEnt and clickEnt:IsValid() and clickEnt:IsRagdoll() then
        local owner = clickEnt:GetRagdollOwner()
        log.Info("Ragdoll: ", clickEnt, " belongs to owner: ", owner)
    end
end
