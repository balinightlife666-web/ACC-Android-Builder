-- LOST & FOUND: NIGHT SHIFT — M4-D runtime entrypoint.
-- Core decisions remain RETURN / STORE / QUARANTINE / SECURITY.
-- The legacy single shared activeCase loop is intentionally replaced by
-- PersonalShiftRuntime so every occupied station owns an isolated job stream.

local PersonalShiftRuntime = require(script.Parent:WaitForChild("PersonalShiftRuntime"))
PersonalShiftRuntime.Start()
