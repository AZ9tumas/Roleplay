--!strict
-- UI Module entry point
-- This module can be required to initialize all UI controllers

local UIController = require(script.UIController)

return function()
	UIController.init()
end
