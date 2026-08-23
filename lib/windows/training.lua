-- Training mode window: persistent sector selection, timing and traffic tools.

local training = require('lib.training_sectors')
local settings = require('lib.core.settings')
local traffic = require('lib.traffic')
local state = require('lib.core.state')
local theme = require('lib.ui.theme')

local M = {}

local function formatTime(ms)
    if not ms or ms == math.huge then return "--:--.---" end
    local seconds = ms / 1000
    local minutes = math.floor(seconds / 60)
    return string.format("%d:%06.3f", minutes, seconds - minutes * 60)
end

local function hint(text)
    ui.pushFont(ui.Font.Small)
    ui.textColored(text, theme.text.muted)
    ui.popFont()
end

local function drawSectorList()
    local sectors = training.sectors()
    ui.header("Training sector")

    if #sectors == 0 then
        ui.textColored("No saved sectors for this car and track", theme.text.muted)
    else
        local selected = training.selected()
        ui.combo("##trainingSector", selected and selected.name or "Select sector", function()
            for i, sector in ipairs(sectors) do
                if ui.selectable(sector.name, i == training.selectedIndex()) then
                    training.select(i)
                end
                if ui.itemHovered() then
                    ui.setTooltip(string.format("Best %s · %d run%s", formatTime(sector.bestTimeMs),
                        #(sector.history or {}), #(sector.history or {}) == 1 and "" or "s"))
                end
            end
        end)
    end

    local active = training.isActive()
    if ui.checkbox("Training mode", active) then training.setActive(not active) end
    ui.sameLine()
    if ui.button("New sector", vec2(110, 0)) then training.newSector() end

    ui.dummy(vec2(0, 4))
    settings.getTrainingButton():control(vec2(-1, 0))

    if training.isMapping() then
        if training.pendingStart() == nil then
            hint("Press once at the start point.")
        elseif training.pendingStart() == false then
            hint("Saving car state…")
        else
            hint("Start saved. Drive to the finish and press again.")
        end
    else
        hint("Hold to return to the selected start; the timer starts when released.")
    end
end

local function drawTiming()
    local sector = training.selected()
    if not sector then return end

    ui.dummy(vec2(0, 8))
    ui.header("Run")
    local run = training.run()
    local liveTime = run and run.elapsedMs or sector.lastTimeMs
    ui.text("Time")
    ui.sameLine(90)
    ui.pushFont(ui.Font.Monospace)
    ui.text(formatTime(liveTime))
    ui.popFont()

    ui.text("Best")
    ui.sameLine(90)
    ui.textColored(formatTime(sector.bestTimeMs), theme.delta.positive)

    ui.text("Corners")
    local corners = sector.corners or {}
    if #corners == 0 then
        ui.sameLine(90)
        ui.textColored("None", theme.text.muted)
    else
        for i, corner in ipairs(corners) do
            ui.sameLine(i == 1 and 90 or 0)
            ui.text(corner.name or ("Corner " .. tostring(corner.number or i)))
            if i < #corners then
                ui.sameLine(0, 4)
                ui.textColored("›", theme.text.muted)
            end
        end
    end
end

local function drawTraffic()
    ui.dummy(vec2(0, 8))
    ui.treeNode("Traffic training", function()
        if not traffic.hasAICars() then
            hint("Start a practice session with AI cars to use traffic scenarios.")
            return
        end
        if not state.trackCorners or #state.trackCorners == 0 then
            hint("Record corners before deploying traffic scenarios.")
            return
        end

        for i, scenario in ipairs(traffic.allScenarios()) do
            local selected = i == traffic.currentScenarioIndex()
            if ui.selectable(scenario.name, selected) then
                while traffic.currentScenarioIndex() ~= i do traffic.nextScenario() end
            end
            if ui.itemHovered() then ui.setTooltip(scenario.desc) end
        end

        if ui.button("Deploy selected traffic", vec2(-1, 0)) then
            if not traffic.isInitialized() then traffic.init() end
            local name = traffic.teleportScenario(state.trackCorners)
            if name then ac.setMessage("Traffic", name) end
        end
    end)
end

function M.draw(dt)
    drawSectorList()
    drawTiming()
    drawTraffic()
end

return M
