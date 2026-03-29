-- Training window - Traffic simulation controls and checkpoint keybinds
-- Provides scenario selection, train mode toggle, and hotkey configuration

local traffic = require('lib.traffic')
local settings = require('lib.core.settings')
local state = require('lib.core.state')
local theme = require('lib.ui.theme')

local M = {}

local CONTROL_WIDTH = 120

-- Helper: Label on left, control right-aligned
local function labeledControl(label, controlWidth, controlFn)
    ui.text(label)
    ui.sameLine(ui.availableSpaceX() - controlWidth)
    controlFn()
end

-- Helper: Hint text
local function hint(text)
    ui.pushFont(ui.Font.Small)
    ui.textColored(text, theme.text.muted)
    ui.popFont()
end

function M.draw(dt)
    local hasAI = traffic.hasAICars()
    local scenarios = traffic.allScenarios()
    local currentIdx = traffic.currentScenarioIndex()

    -- Status bar
    if not hasAI then
        ui.textColored("No AI opponents in session", theme.delta.negative)
        hint("Start practice with 2-3 AI cars to use traffic simulation")
        ui.dummy(vec2(0, 8))
    elseif not state.trackCorners or #state.trackCorners == 0 then
        ui.textColored("No corners defined", theme.delta.negative)
        hint("Record corners first (hold button on track)")
        ui.dummy(vec2(0, 8))
    else
        local aiCount = traffic.aiCarCount()
        ui.textColored(aiCount .. " AI car" .. (aiCount > 1 and "s" or "") .. " available", theme.delta.positive)
        ui.dummy(vec2(0, 4))
    end

    -- Train Mode
    ui.header("Train Mode")

    local trainActive = traffic.isTrainMode()
    local trainLabel = trainActive and "Train Mode: ON" or "Train Mode: OFF"
    local trainColor = trainActive and theme.delta.positive or theme.text.muted

    ui.textColored(trainLabel, trainColor)
    ui.sameLine(ui.availableSpaceX() - 80)
    if ui.button(trainActive and "Stop##train" or "Start##train", vec2(80, 0)) then
        local newState = traffic.toggleTrainMode(state.trackCorners)
        local msg = newState and "ON — random scenarios each lap" or "OFF"
        ac.setMessage("Train Mode", msg)
    end

    if trainActive then
        local scenarioName = traffic.trainScenarioName()
        if scenarioName then
            hint("Active: " .. scenarioName)
        else
            hint("Waiting for next corner...")
        end
    else
        hint("Auto-deploys random scenarios at random corners each lap")
    end

    ui.dummy(vec2(0, 8))

    -- Scenarios
    ui.header("Scenarios")

    for i, scenario in ipairs(scenarios) do
        local isActive = (i == currentIdx)
        local canUse = hasAI and traffic.aiCarCount() >= scenario.minCars

        if isActive then
            ui.pushStyleColor(ui.StyleColor.Text, theme.delta.positive)
        elseif not canUse then
            ui.pushStyleColor(ui.StyleColor.Text, theme.text.muted)
        end

        local prefix = isActive and "> " or "  "
        local suffix = ""
        if scenario.minCars > 1 then
            suffix = " (" .. scenario.minCars .. " cars)"
        end

        ui.text(prefix .. scenario.name .. suffix)

        if isActive or not canUse then
            ui.popStyleColor()
        end

        -- Show description on hover
        if ui.itemHovered() then
            ui.setTooltip(scenario.desc)
        end
    end

    hint("Press teleport key to deploy, cycles to next scenario")

    ui.dummy(vec2(0, 8))

    -- Hotkeys
    ui.header("Hotkeys")

    labeledControl("Teleport Traffic", CONTROL_WIDTH, function()
        settings.getTrafficTeleportButton():control(vec2(CONTROL_WIDTH, 0))
    end)

    if settings.checkpointEnabled() then
        labeledControl("Save Checkpoint", CONTROL_WIDTH, function()
            settings.getSaveCheckpointButton():control(vec2(CONTROL_WIDTH, 0))
        end)
        labeledControl("Load Checkpoint", CONTROL_WIDTH, function()
            settings.getLoadCheckpointButton():control(vec2(CONTROL_WIDTH, 0))
        end)
        hint("Hold Load to jump back to 1/N")
    end
end

return M
