-- LOST & FOUND: NIGHT SHIFT — personal runtime entrypoint.
-- Core decisions remain RETURN / STORE / QUARANTINE / SECURITY.
-- M4-E.1 patches routine-case depth first; M4-E.1D then adds a presentation-only
-- anti-repeat layer before PersonalShiftRuntime starts. Mystery canon and economy
-- remain owned by the underlying registry/runtime.

local M4E1CaseDepth = require(script.Parent:WaitForChild("M4E1CaseDepth"))
M4E1CaseDepth.Apply()

local M4E1DAntiRepeat = require(script.Parent:WaitForChild("M4E1DAntiRepeat"))
M4E1DAntiRepeat.Apply()

local PersonalShiftRuntime = require(script.Parent:WaitForChild("PersonalShiftRuntime"))
PersonalShiftRuntime.Start()
