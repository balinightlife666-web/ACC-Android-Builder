-- LOST & FOUND: NIGHT SHIFT — personal runtime entrypoint.
-- Core decisions remain RETURN / STORE / QUARANTINE / SECURITY.
-- M4-E.1 patches routine-case depth first; M4-E.1D then adds a presentation-only
-- anti-repeat layer before PersonalShiftRuntime starts. Mystery canon and economy
-- remain owned by the underlying registry/runtime.

local M4E1CaseDepth = require(script.Parent:WaitForChild("M4E1CaseDepth"))
M4E1CaseDepth.Apply()

local M4E1DAntiRepeat = require(script.Parent:WaitForChild("M4E1DAntiRepeat"))
M4E1DAntiRepeat.Apply()

local M6CSeasonalContentService = require(script.Parent:WaitForChild("M6CSeasonalContentService"))
local seasonalReady = M6CSeasonalContentService.RegisterDefinitions()
if not seasonalReady then
    warn("[LostAndFound] M6-C seasonal definitions are not ready; live-service activation will fail closed.")
end

-- Register seasonal definitions before publishing live-service state. This prevents an
-- activation tick from becoming visible before its collectible/case registries exist.
local LiveServiceEventService = require(script.Parent:WaitForChild("LiveServiceEventService"))
LiveServiceEventService.Start()

local PersonalShiftRuntime = require(script.Parent:WaitForChild("PersonalShiftRuntime"))
PersonalShiftRuntime.Start()
