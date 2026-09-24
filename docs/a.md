# docs/naming_convention.md

```markdown
## 核心原则

越靠上的规则优先级越高

## 缩写

缩写视为整体, 如 NPCPos(PascalCase) npcPos(camelCase) NPC_POS(UPPER_CASE)

## 文件与目录

- 目录名、文件名：`lower_case/lower_case.lua`

## 常量

- 表字段作为常量：`Table.UPPER_CASE`
- 普通变量作为常量：`UPPER_CASE`

## 表

- 表作为枚举表 - 名词单数 - `PascalCase`
- 表作为纯函数库 - `lower_case`
- 表作为命名空间 - `PascalCase`
- 表作为类 - `PascalCase`
- 表作为容器，如数组、字典 - 视为普通变量

## 表字段

- 表字段作为常量 → 见「常量」
- 表字段作为枚举 - `Table.UPPER_CASE`
- 表字段 - `Table.PascalCase`
- 类私有字段 - `Table._PascalCase`

## 函数

- 函数 - 视为普通变量

## 变量

- 常量变量 → 见「常量」
- local 普通变量 - `camelCase`
- global 普通变量 - `PascalCase`（实际全局普通变量就是 `_G` 的表字段，那么 `PascalCase` 很恰当）

## 形参与循环变量

- 形参 - `camelCase`
- 循环变量 - `camelCase`

## 领域事件

- PascalCase, 可以随便加入前缀后缀, 比如 CADOnRagdollCreated
```

# lua/autorun/client/charlene_mods_cl_init.lua

```lua
include("charlene_mods/cl_first_person_body_blood_decal.lua")
```

# lua/autorun/client/test.lua

```lua
concommand.Add("test_ragdoll_decal_v4", function ()
    local ply = LocalPlayer()

    local name = util.DecalMaterial("Blood")
    print("decal material name:", name)

    local mat = Material(name)
    print("shader:", mat:GetShader(), "error:", mat:IsError())

    for _, rag in ipairs(ents.FindByClass("prop_ragdoll")) do
        local center = rag:WorldSpaceCenter()
        local tr = util.TraceLine({
            start  = center + Vector(1, 0, 0) * 100,
            endpos = center - Vector(1, 0, 0) * 100,
            filter = { ply },
        })

        if tr.Hit and tr.Entity == rag then
            util.DecalEx(mat, rag, tr.HitPos, tr.HitNormal, Color(255, 255, 255), 50, 50)
            print("applied with", name)
        end
    end
end)
```

# lua/autorun/server/test.lua

```lua
concommand.Add("test_spawn_player_ragdoll", function (ply)
    if not IsValid(ply) then ply = Entity(1) end
    if not IsValid(ply) then return end

    local ragdoll = ents.Create("prop_ragdoll")
    if not IsValid(ragdoll) then
        print("failed to create ragdoll")
        return
    end

    ragdoll:SetModel(ply:GetModel())
    ragdoll:SetPos(ply:GetPos() + ply:GetAimVector() * 100 + Vector(0, 0, 50))
    ragdoll:Spawn()

    print("spawned ragdoll EntIndex:", ragdoll:EntIndex(), "model:", ragdoll:GetModel())
end)
```

# lua/entities/charlene_mods_aim_dummy/init.lua

```lua
-- lua/entities/charlene_mods_aim_dummy/init.lua

AddCSLuaFile("shared.lua")
include("shared.lua")

local DUMMY_MODEL = "models/editor/cube_small.mdl"
local RELATION_PRIO = 100
local POSITION_OFFSET = 16

function ENT:Initialize()
    self:SetModel(DUMMY_MODEL)
    self:SetModelScale(0.03125) -- 0.03125 = 1 / 32
    self:SetNPCClass(CLASS_NONE)
    self:SetSolid(SOLID_NONE)
    self:SetNoDraw(false)
    self:SetCollisionGroup(COLLISION_GROUP_NONE)

    ---@type Player?
    self._Owner = nil
    ---@type NPC?
    self._NPC = nil
    ---@type string?
    self._BoneName = nil
    ---@type boolean
    self._Enabled = false
end

---启用：绑定 owner / npc / boneName，并立即更新一次位置和关系
---@param owner Player
---@param npc NPC
---@param boneName string
---@return boolean
function ENT:Enable(owner, npc, boneName)
    if not IsValid(owner) or not IsValid(npc) or not boneName then
        return false
    end

    -- 换 NPC 时先解除旧关系
    local oldNPC = self._NPC
    if IsValid(oldNPC) and oldNPC ~= npc then
        oldNPC:AddEntityRelationship(self, D_NU, 0)
    end

    self._Owner = owner
    self._NPC = npc
    self._BoneName = boneName
    self._Enabled = true

    self:_UpdatePosition()
    npc:AddEntityRelationship(self, D_HT, RELATION_PRIO)

    return true
end

---停用：解除关系，清空绑定。dummy 本身保留，可被复用
function ENT:Disable()
    local npc = self._NPC
    if IsValid(npc) then
        npc:AddEntityRelationship(self, D_NU, 0)
    end

    self._Owner = nil
    self._NPC = nil
    self._BoneName = nil
    self._Enabled = false
end

---@return boolean
function ENT:IsEnabled()
    return self._Enabled
end

---私有：三点一线，dummy 位于 NPC shootPos 和玩家骨骼连线上
---@return boolean
function ENT:_UpdatePosition()
    local owner = self._Owner
    local npc = self._NPC
    local boneName = self._BoneName
    if not IsValid(owner) or not IsValid(npc) or not boneName then
        return false
    end

    local boneID = owner:LookupBone(boneName)
    if not boneID then return false end

    local bonePos = owner:GetBonePosition(boneID)
    if not bonePos then return false end

    local shootPos = npc:GetShootPos()
    local toNPC = (shootPos - bonePos):GetNormalized()

    self:SetPos(bonePos + toNPC * POSITION_OFFSET)
    return true
end

function ENT:Think()
    if not self._Enabled then return end

    local owner = self._Owner
    local npc = self._NPC

    -- owner 消失：自我移除
    if not IsValid(owner) then
        self:Remove()
        return
    end

    -- owner 死亡 / npc 消失：停用但不移除，允许复用
    if not owner:Alive() or not IsValid(npc) then
        self:Disable()
        return
    end

    self:_UpdatePosition()
    npc:AddEntityRelationship(self, D_HT, RELATION_PRIO)

    self:NextThink(CurTime())
    return true
end
```

# lua/entities/charlene_mods_aim_dummy/shared.lua

```lua
AddCSLuaFile()

ENT.Base = "base_ai"
ENT.Type = "ai"

ENT.PrintName = "NPC Aim Dummy"
ENT.Category = "Charlene Mods"
ENT.Spawnable = false
ENT.AdminOnly = true
```

# lua/weapons/gmod_tool/stools/charlene_mods_npc_aim_bone.lua

```lua
-- lua/weapons/gmod_tool/stools/charlene_mods_npc_aim_bone.lua

TOOL.Category = "Charlene Mods"
TOOL.Name = "NPC Aim Bone"
TOOL.Command = nil
TOOL.ConfigName = ""

local MODULE_NAME = "NPCAimBone"

if CLIENT then
    language.Add("Tool.charlene_mods_npc_aim_bone.name", "NPC Aim Bone")
    language.Add("Tool.charlene_mods_npc_aim_bone.desc",
        "Left: pick NPC and sort bones by distance to hit. Right: place dummy at first shared bone.")
    language.Add("Tool.charlene_mods_npc_aim_bone.left",
        "Left click: select NPC and sort bones by distance to hit")
    language.Add("Tool.charlene_mods_npc_aim_bone.right",
        "Right click: place dummy at first shared bone")
    return
end

-- ============================================================
-- 服务端
-- ============================================================

---@class AimBoneState
---@field Dummy Entity?
---@field NPC Entity?
---@field SortedBones { name: string, distSqr: number }[]?

---@type table<Player, AimBoneState>
local plyToState = {}

---@param ply Player
---@return AimBoneState
local function getState(ply)
    local state = plyToState[ply]
    if not state then
        state = {}
        plyToState[ply] = state
    end
    return state
end

---@param ply Player
local function destroyState(ply)
    local state = plyToState[ply]
    if not state then return end

    local dummy = state.Dummy
    if IsValid(dummy) then
        dummy:Disable()
        dummy:Remove()
    end

    plyToState[ply] = nil
end

-- 兜底：玩家死亡 / 失效时清理
hook.Add("Think", MODULE_NAME .. ".CleanupThink", function ()
    for ply in pairs(plyToState) do
        if not IsValid(ply) or not ply:Alive() then
            destroyState(ply)
        end
    end
end)

hook.Add("PlayerDisconnected", MODULE_NAME .. ".PlayerDisconnected", function (ply)
    destroyState(ply)
end)

-- ============================================================
-- Tool
-- ============================================================

---@param self Tool
function TOOL:Deploy()
    local ply = self:GetOwner()
    if IsValid(ply) then
        ply:SetNoTarget(true)
    end
end

---@param self Tool
function TOOL:Holster()
    local ply = self:GetOwner()
    if IsValid(ply) then
        ply:SetNoTarget(false)
        destroyState(ply)
    end
end

---@param self Tool
---@param trace TraceResult
---@return boolean
function TOOL:LeftClick(trace)
    local npc = trace.Entity
    if not IsValid(npc) or not npc:IsNPC() then
        return false
    end

    local ply = self:GetOwner()
    if not IsValid(ply) then return false end

    local state = getState(ply)

    -- 按命中位置排序骨骼
    local hitPos = trace.HitPos
    local bones = {}
    for i = 0, npc:GetBoneCount() - 1 do
        local pos = npc:GetBonePosition(i)
        local name = npc:GetBoneName(i)
        if pos and name then
            bones[#bones + 1] = { name = name, distSqr = pos:DistToSqr(hitPos) }
        end
    end
    table.sort(bones, function (a, b) return a.distSqr < b.distSqr end)

    state.NPC = npc
    state.SortedBones = bones
    return true
end

---@param self Tool
---@param trace TraceResult
---@return boolean
function TOOL:RightClick(trace)
    local ply = self:GetOwner()
    if not IsValid(ply) then return false end

    local state = getState(ply)
    local npc = state.NPC
    local bones = state.SortedBones
    if not IsValid(npc) or not bones then return false end

    -- 找第一个 NPC 和玩家共有的骨骼名
    local matchedName
    for _, bone in ipairs(bones) do
        if ply:LookupBone(bone.name) then
            matchedName = bone.name
            break
        end
    end
    if not matchedName then return false end

    -- 创建或复用 dummy
    if not IsValid(state.Dummy) then
        local dummy = ents.Create("charlene_mods_aim_dummy")
        if not IsValid(dummy) then return false end

        dummy:SetOwner(ply)
        dummy:Spawn()

        state.Dummy = dummy
    end

    -- 委托给 dummy 自己处理位置和关系
    state.Dummy:Enable(ply, npc, matchedName)
    return true
end
```
