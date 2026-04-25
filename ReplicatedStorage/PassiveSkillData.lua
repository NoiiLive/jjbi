-- @ScriptType: ModuleScript
local PassiveSkillData = {}

PassiveSkillData.Trees = {
	["Emperor"] = {
		Nodes = {
			{ Type = "Passive", Key = "SteelyResolve", Cost = 2 }
		}
	}
}

PassiveSkillData.Passives = {
	["Emperor"] = {
		["SteelyResolve"] = {
			Name = "Steely Resolve",
			Desc = "Grants increased resistance to incoming stun-based combat effects.",
			Type = "Passive"
		}
	}
}

return PassiveSkillData