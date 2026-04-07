-- @ScriptType: LocalScript
local Player = game.Players.LocalPlayer
local PlayerScripts = Player:WaitForChild("PlayerScripts")
local PlayerModule = require(PlayerScripts:WaitForChild("PlayerModule"))
local Controls = PlayerModule:GetControls()

Controls:Disable()