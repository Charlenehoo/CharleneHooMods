-- log.lua

if _G._CharleneHooLog then return _G._CharleneHooLog end

-- ============================================================
-- 级别枚举：显式声明，索引即级别
--   顺序不可乱动
-- ============================================================

---@enum LogLevel
local LogLevel = {
    TRACE = 1,
    DEBUG = 2,
    INFO  = 3,
    WARN  = 4,
    ERROR = 5,
}

-- ============================================================
-- 配置（文件级闭包，外部不可改）
-- ============================================================

---@type LogLevel
local CurrentLevel = LogLevel.TRACE -- 默认 Trace，发布时改成 WARN / ERROR
local OutFile = nil                 -- nil = 不写文件; 相对 data/, 自动补 .txt
local Fold = true                   -- 连续相同折叠
local MaxTable = 3                  -- table 显示前几项

-- 领域标识（GMod 惯例：SERVER 蓝 / CLIENT 橙）
--   realmName  - 完整名，文件日志用
--   realmTag   - 小写短名 sv / cl，控制台用（与级别大写区分）
--   realmColor - 控制台表头颜色
local realmName = SERVER and "SERVER" or "CLIENT"
local realmTag = SERVER and "sv" or "cl"
local realmColor = SERVER and Color(80, 160, 255) -- 蓝
    or Color(255, 165, 0)                         -- 橙

-- ============================================================
-- 级别定义表：以 LogLevel 枚举值为键
--   Tag   - 大写短标签，控制台与折叠签名用
--   Label - 文件日志显示名，人工右对齐到 5 字符
--           （INFO / WARN 只有 4 字符，手动补前导空格）
--   Color - 控制台正文颜色
-- ============================================================

---@class LevelDef
---@field Tag string
---@field Label string
---@field Color Color

---@type table<LogLevel, LevelDef>
local levelDefs = {
    [LogLevel.TRACE] = { Tag = "TRACE", Label = "TRACE", Color = Color(140, 140, 140) },
    [LogLevel.DEBUG] = { Tag = "DEBUG", Label = "DEBUG", Color = Color(100, 200, 255) },
    [LogLevel.INFO]  = { Tag = "INFO", Label = " INFO", Color = Color(200, 255, 200) },
    [LogLevel.WARN]  = { Tag = "WARN", Label = " WARN", Color = Color(255, 220, 100) },
    [LogLevel.ERROR] = { Tag = "ERROR", Label = "ERROR", Color = Color(255, 100, 100) },
}

-- ============================================================
-- 日志对象
-- ============================================================

---@class Log
---@field Trace fun(...: any)
---@field Debug fun(...: any)
---@field Info fun(...: any)
---@field Warn fun(...: any)
---@field Error fun(...: any)
local log = {}

-- ============================================================
-- 值格式化
-- ============================================================

---@param value number
---@return string
local function formatNumber(value)
    if value == math.floor(value) and math.abs(value) < 1e15 then
        return string.format("%d", value)
    end
    return string.format("%.3f", value)
end

---@param value table
---@return boolean
local function hasToString(value)
    local mt = getmetatable(value)
    return type(mt) == "table" and type(mt.__tostring) == "function"
end

---@type fun(value: any): string
local formatValue -- 前向声明

---@param value any
---@return string
local function briefElement(value)
    if type(value) == "string" then return string.format("%q", value) end
    if type(value) == "table" and not hasToString(value) then return "<table>" end
    return formatValue(value)
end

formatValue = function (value)
    local valueType = type(value)

    -- GMod 的 Vector / Angle 都是 userdata，须用 isvector / isangle 判定
    if valueType == "userdata" then
        if isvector(value) then
            return string.format("Vector(%s, %s, %s)",
                formatNumber(value.x), formatNumber(value.y), formatNumber(value.z))
        end
        if isangle(value) then
            return string.format("Angle(%s, %s, %s)",
                formatNumber(value.p), formatNumber(value.y), formatNumber(value.r))
        end
        return tostring(value)
    end

    if valueType == "function" then return "<function>" end
    if valueType ~= "table" then return tostring(value) end
    if hasToString(value) then return tostring(value) end

    local itemCount = 0
    for _ in pairs(value) do itemCount = itemCount + 1 end
    if itemCount == 0 then return "{} (n=0)" end

    local parts = {}
    local arrayLength = #value
    if arrayLength == itemCount then
        local limit = math.min(itemCount, MaxTable)
        for index = 1, limit do
            parts[index] = briefElement(value[index])
        end
        local tailText = itemCount > limit and ", ..." or ""
        return string.format("[%s%s] (n=%d)", table.concat(parts, ", "), tailText, itemCount)
    end

    local index = 0
    for key, entryValue in pairs(value) do
        index = index + 1
        if index > MaxTable then break end
        local keyString = (type(key) == "string") and key or ("[" .. tostring(key) .. "]")
        parts[index] = keyString .. "=" .. briefElement(entryValue)
    end
    local tailText = itemCount > MaxTable and ", ..." or ""
    return string.format("{%s%s} (n=%d)", table.concat(parts, ", "), tailText, itemCount)
end

-- ============================================================
-- 时间：统一格式 MM:SS.mmm
--   SysTime 与 CurTime 共用，区别仅在时间源
--   小时位模掉（debug 窗口 < 1 小时，回绕无歧义）
-- ============================================================

---@param seconds number
---@return string
local function formatTime(seconds)
    local totalMilliseconds = math.floor(seconds * 1000)
    local totalSeconds = math.floor(totalMilliseconds / 1000)
    return string.format("%02d:%02d.%03d",
        math.floor(totalSeconds / 60) % 60, -- 分钟：模 60 → 2 位
        totalSeconds % 60,                  -- 秒：  模 60 → 2 位
        totalMilliseconds % 1000)           -- 毫秒：模 1000 → 3 位
end

-- ============================================================
-- 调用点 (跳过 C 函数 / 未知源, 应对 hook / timer 回调栈)
-- ============================================================

---@return string
---@return number
local function findCaller()
    if not debug or not debug.getinfo then return "?", 0 end
    for level = 4, 20 do
        local info = debug.getinfo(level, "Sl")
        if not info then break end
        local source = info.short_src or info.source
        if source and source ~= "=[C]" and source ~= "?" and source ~= "" then
            return (source:gsub("^@", "")), info.currentline or 0
        end
    end
    return "?", 0
end

--- 控制台用的 source 截短：只留文件名，超长从头部截断
---@param source string
---@return string
local function shortenSource(source)
    local name = source:match("([^/]+)$") or source
    name = name:gsub("%.lua$", "")
    if #name > 24 then
        name = "~" .. name:sub(-23)
    end
    return name
end

-- ============================================================
-- 输出 (控制台 + 文件), 折叠在此处
-- ============================================================

---@class PendingEntry
---@field LevelColor Color
---@field ConsoleHead string
---@field FileHead string
---@field Text string
---@field Signature string
---@field Count integer

---@type PendingEntry|nil
local pending = nil

---@return string|nil
local function getOutfilePath()
    local path = OutFile
    if not path then return nil end
    if not path:lower():match("%.txt$") then
        path = path .. ".txt"
    end
    return path
end

--- 控制台表头 = realmColor，正文 = levelColor
---@param levelColor Color
---@param consoleHead string
---@param fileHead string
---@param text string
---@param count integer
local function emitLine(levelColor, consoleHead, fileHead, text, count)
    local suffix = (count and count > 1) and (" x" .. count) or ""

    MsgC(realmColor, consoleHead)
    MsgC(levelColor, " " .. text .. suffix .. "\n")

    local path = getOutfilePath()
    if path then file.Append(path, fileHead .. " " .. text .. suffix .. "\n") end
end

local function flushPending()
    if not pending then return end
    local currentPending = pending
    pending = nil
    emitLine(
        currentPending.LevelColor,
        currentPending.ConsoleHead,
        currentPending.FileHead,
        currentPending.Text,
        currentPending.Count
    )
end

-- ============================================================
-- 日志写入公共逻辑
-- ============================================================

---@param level LogLevel
---@param ... any
local function logAt(level, ...)
    if level < CurrentLevel then return end

    local def = levelDefs[level]
    if not def then return end

    local count = select("#", ...)
    local parts = {}
    for index = 1, count do
        local value = select(index, ...)
        parts[index] = formatValue(value)
    end
    local text = table.concat(parts, " ")

    local source, line = findCaller()
    local shortSource = shortenSource(source)
    local tick = engine.TickCount() % 100000 -- 66 tick/s 下覆盖 ≈ 25 分钟

    -- 控制台 Header：时间 | 级别 | realm | 来源:行 | Tick
    --   表头颜色 = realm，正文颜色 = 级别
    local consoleHead = string.format("%s|%s|%s|%s:%d|%05d",
        formatTime(CurTime()),
        def.Tag,
        realmTag,
        shortSource, line,
        tick)

    -- 文件 Header：SysTime | CurTime | 级别 | Realm | 来源:行 | Tick
    local fileHead = string.format("[%s][%s][%s][%s][%s:%d][%05d]",
        formatTime(SysTime()),
        formatTime(CurTime()),
        def.Label,
        realmName,
        source, line,
        tick)

    if not Fold then
        emitLine(def.Color, consoleHead, fileHead, text, 1)
        return
    end

    -- 折叠签名用完整 source，避免同名文件误折叠；用 def.Tag 天然按级别隔离
    local signature = def.Tag .. "\0" .. source .. ":" .. line .. "\0" .. text
    if pending and pending.Signature == signature then
        pending.Count = pending.Count + 1
    else
        flushPending()
        pending = {
            LevelColor  = def.Color,
            ConsoleHead = consoleHead,
            FileHead    = fileHead,
            Text        = text,
            Signature   = signature,
            Count       = 1,
        }
    end
end

-- ============================================================
-- 展平挂载各级别函数：log.Trace / log.Debug / log.Info / log.Warn / log.Error
-- ============================================================

log.Trace = function (...) logAt(LogLevel.TRACE, ...) end
log.Debug = function (...) logAt(LogLevel.DEBUG, ...) end
log.Info = function (...) logAt(LogLevel.INFO, ...) end
log.Warn = function (...) logAt(LogLevel.WARN, ...) end
log.Error = function (...) logAt(LogLevel.ERROR, ...) end

-- 定时 flush, 让折叠计数能看到
timer.Create("CharleneHooLogAutoSave", 1.5, 0, flushPending)

_G._CharleneHooLog = log
return log
