-- LOST & FOUND: NIGHT SHIFT — personal runtime entrypoint.
-- Core decisions remain RETURN / STORE / QUARANTINE / SECURITY.
-- M4-E.1 patches routine-case depth before PersonalShiftRuntime starts so every
-- occupied station receives the deeper generator while mystery canon stays stable.

local M4E1CaseDepth = require(script.Parent:WaitForChild("M4E1CaseDepth"))
M4E1CaseDepth.Apply()

local PersonalShiftRuntime = require(script.Parent:WaitForChild("PersonalShiftRuntime"))
PersonalShiftRuntime.Start()
