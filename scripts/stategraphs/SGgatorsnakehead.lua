require("stategraphs/commonstates")

local function doattackfn(inst, data)
    if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
        inst.sg:GoToState(inst.sg:HasStateTag("lure") and "attack_pre" or "attack")
    end
end

local function onattackedfn(inst, data)
    if not (inst.sg:HasStateTag("busy") or
            inst.sg:HasStateTag("invisible") or
            inst.sg:HasStateTag("nohit") or
            inst.components.health:IsDead()) then
        --Will handle the playing of the "hit" animation
        inst.sg:GoToState("hit")
    end
end

local function ChangeToLure(inst)
    inst.components.pickable.canbepicked = true
    ChangeToInventoryPhysics(inst)
    inst.components.sanityaura.aura = 0
end

local function ChangeToWorm(inst)
    inst.components.pickable.canbepicked = false
    ChangeToCharacterPhysics(inst)
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_SMALL
end

local actionhandlers =
{
    ActionHandler(ACTIONS.PICKUP, "action"),
    ActionHandler(ACTIONS.PICK, "action"),
    ActionHandler(ACTIONS.HARVEST, "action"),
    ActionHandler(ACTIONS.EAT, "eat"),
}

local events =
{
    EventHandler("locomote", function(inst)
        if inst.components.locomotor:WantsToMoveForward() then
            if inst.sg:HasStateTag("idle") then
                inst.sg.statemem.walking = true
                inst.sg:GoToState("walk_start")
            end
        elseif inst.sg:HasStateTag("moving") then
            inst.sg.statemem.walking = true
            inst.sg:GoToState("walk_stop")
        end
    end),
    CommonHandlers.OnLocomote(false, true),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnSleep(),
    EventHandler("doattack", doattackfn),
    EventHandler("attacked", onattackedfn),
    EventHandler("dolure", function(inst)
        inst.sg:GoToState("lure_enter")
    end),
}

local states =
{
    State{
        name = "idle_enter",
        tags = { "idle", "invisible", "dirt" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("head_idle_loop")
            inst.SoundEmitter:KillAllSounds()
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "idle",
        tags = { "idle", "invisible", "dirt" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("head_idle_loop", true)
            inst.SoundEmitter:KillAllSounds()
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "idle_exit",
        tags = { "idle", "invisible", "dirt" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("head_idle_pst")
            inst.SoundEmitter:KillAllSounds()
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "action",
        tags = { "busy" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("pickup")
            inst.SoundEmitter:KillAllSounds()    
            inst.SoundEmitter:PlaySound("dontstarve/creatures/worm/emerge")
        end,

        timeline =
        {	
			TimeEvent(1 * FRAMES, function(inst)
                inst:turnonlight()
            end),
            TimeEvent(10 * FRAMES, function(inst)
                inst.sg:AddStateTag("nohit")
            end),
            TimeEvent(15 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/worm/bite")
                inst:PerformBufferedAction()
            end),
            TimeEvent(23 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/worm/retract")
				inst:turnofflight()
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "eat",

        onenter = function(inst, playanim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/worm/emerge")
        end,

        timeline =
        {	
			TimeEvent(1 * FRAMES, function(inst)
                inst:turnonlight()
            end),
            TimeEvent(20 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/worm/eat") end),
            TimeEvent(30 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/worm/eat") end),
            TimeEvent(40 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/worm/eat") end),
            TimeEvent(60 * FRAMES, function(inst)
                inst.sg:AddStateTag("nohit")
                inst:PerformBufferedAction()
            end),
            TimeEvent(75 * FRAMES, function(inst) 
			inst.SoundEmitter:PlaySound("dontstarve/creatures/worm/retract")
			inst:turnonlight()			
			end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        }
    },

    State{
        name = "taunt",
        tags = { "taunting" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.SoundEmitter:PlaySound("dontstarve/creatures/worm/emerge")
            inst.AnimState:PlayAnimation("taunt")
        end,

        timeline =
        {	
			TimeEvent(1 * FRAMES, function(inst)
                inst:turnonlight()
            end),
            TimeEvent(20 * FRAMES, function(inst)
                inst.sg:AddStateTag("nohit")
				inst:turnofflight()
            end),
            TimeEvent(30 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/worm/retract") end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("walk")
            end),
        },
    },

    State{
        name = "attack_pre",
        tags = { "canrotate", "invisible" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("atk_pre")
            inst:turnofflight()
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("attack")
            end),
        },
    },

    State{
        name = "attack",
        tags = { "attack", "nohit" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("atk")
            inst.components.combat:StartAttack()
            inst.SoundEmitter:PlaySound("dontstarve/creatures/worm/emerge")
        end,

        timeline =
        {
            --[[TimeEvent(20 * FRAMES, function(inst)
                inst.sg:AddStateTag("nohit")
            end),]]
			TimeEvent(1 * FRAMES, function(inst)
                inst:turnonlight()
				local x, y, z = inst.Transform:GetWorldPosition()
				SpawnPrefab("sparks").Transform:SetPosition(x, y + .25 + math.random() * 2, z)
				SpawnPrefab("sparks").Transform:SetPosition(x, y + .25 + math.random() * 2, z)
            end),
            TimeEvent(25 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/worm/bite")
                inst.components.combat:DoAttack()
				local x, y, z = inst.Transform:GetWorldPosition()
				SpawnPrefab("sparks").Transform:SetPosition(x, y + .25 + math.random() * 2, z)
				SpawnPrefab("sparks").Transform:SetPosition(x, y + .25 + math.random() * 2, z)
				SpawnPrefab("sparks").Transform:SetPosition(x, y + .25 + math.random() * 2, z)
            end),
            TimeEvent(40 * FRAMES, function(inst) 
			inst.SoundEmitter:PlaySound("dontstarve/creatures/worm/retract")
			inst:turnofflight()
			end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("walk")
            end),
        },
    },

    State{
        name = "death",
        tags = { "busy" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("death")
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot(inst:GetPosition())
        end,

        timeline =
        {
            TimeEvent(FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/worm/retract")
                inst.SoundEmitter:PlaySound("dontstarve/creatures/worm/death")
            end),
        },
    },

    State{
        name = "hit",
        tags = { "busy", "hit" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("hit")
        end,

        timeline =
        {	
			
            TimeEvent(FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/creatures/worm/hurt")
			inst:turnonlight()
			end),
			
            TimeEvent(20 * FRAMES, function(inst) 
			inst.SoundEmitter:PlaySound("dontstarve/creatures/worm/retract")
			inst:turnofflight()
			end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "walk_start",
        tags = { "moving", "canrotate", "dirt", "invisible" },

        onenter = function(inst)
            --inst.components.locomotor:WalkForward()
			if inst.components.combat.target ~= nil then
            inst.AnimState:PlayAnimation("head_idle_pre")
            if not inst.SoundEmitter:PlayingSound("walkloop") then
                inst.SoundEmitter:PlaySound("dontstarve/creatures/worm/move", "walkloop")
            end
			else
			inst.sg:GoToState("idle")
			end
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg.statemem.walking = true
				if nst.sg.statemem.targetpos ~= nil then
						local xdiff = inst.sg.statemem.targetpos.x - inst.sg.statemem.startpos.x
						local zdiff = inst.sg.statemem.targetpos.z - inst.sg.statemem.startpos.z
						local oldr = math.sqrt(xdiff*xdiff+zdiff*zdiff)
						local mod = 0.5
						if oldr < 7 then
						mod = 1
						elseif oldr > 15 then
						mod = 0.3
						end
						if not TheWorld.Map:IsPassableAtPoint(inst.sg.statemem.startpos.x+(xdiff*mod), 0, inst.sg.statemem.startpos.z+(zdiff*mod)) then
							inst.sg:GoToState("walk")
						else
							inst.sg:GoToState("idle")
						end
					else
						inst.sg:GoToState("idle")
					end
            end),
        },

        onexit = function(inst)
            if not inst.sg.statemem.walking then
                inst.SoundEmitter:KillSound("walkloop")
            end
        end,
    },

    State{
        name = "walk",
        tags = { "moving", "canrotate", },

        onenter = function(inst)
            --inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("head_idle_pst")
            if not inst.SoundEmitter:PlayingSound("walkloop") then
                inst.SoundEmitter:PlaySound("dontstarve/creatures/worm/move", "walkloop")
            end
        end,

        timeline =
        {
            TimeEvent(0, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/worm/dirt") end),
            TimeEvent(10 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/worm/dirt") end),
            TimeEvent(20 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/worm/dirt") end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg.statemem.walking = true
				if inst.components.combat.target ~= nil then
				inst.sg.statemem.startpos = Vector3(inst.Transform:GetWorldPosition())
				inst.sg.statemem.targetpos = Vector3(inst.components.combat.target.Transform:GetWorldPosition())
				local xdiff = inst.sg.statemem.targetpos.x - inst.sg.statemem.startpos.x
				local zdiff = inst.sg.statemem.targetpos.z - inst.sg.statemem.startpos.z
				local oldr = math.sqrt(xdiff*xdiff+zdiff*zdiff)
				local mod = 0.5
				if oldr < 7 then
				 mod = 1
				elseif oldr > 15 then
				 mod = 0.3
				end
				inst.Physics:Teleport(inst.sg.statemem.startpos.x+(xdiff*mod),0,inst.sg.statemem.startpos.z+(zdiff*mod))
				if oldr < 2 then
				inst.sg:GoToState("attack_pre")
				else
				inst.sg:GoToState("walk_pst")
				end
				else
                inst.sg:GoToState("walk_stop")
				end
            end),
        },

        onexit = function(inst)
            if not inst.sg.statemem.walking then
                inst.SoundEmitter:KillSound("walkloop")
            end
        end,
    },

    State{
        name = "walk_pst",
        tags = { "canrotate" },

        onenter = function(inst)
            --inst.components.locomotor:StopMoving()
			inst.Physics:ClearMotorVelOverride()
            --inst.AnimState:PlayAnimation("walk_pst")
            if not inst.SoundEmitter:PlayingSound("head_idle_loop") then
                inst.SoundEmitter:PlaySound("dontstarve/creatures/worm/move", "walkloop")
				
            end
			inst.sg:GoToState("walk_start")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("walk_start")
            end),
        },

        onexit = function(inst)
            if not inst.sg.statemem.walking then
                inst.SoundEmitter:KillSound("walkloop")
            end
        end,
    },  
    State{
        name = "walk_stop",
        tags = { "canrotate"},

        onenter = function(inst)
            --inst.components.locomotor:StopMoving()
			inst.Physics:ClearMotorVelOverride()
            inst.AnimState:PlayAnimation("head_idle_pre")
            if not inst.SoundEmitter:PlayingSound("head_idle_loop") then
                inst.SoundEmitter:PlaySound("dontstarve/creatures/worm/move", "walkloop")
            end
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },

        onexit = function(inst)
            if not inst.sg.statemem.walking then
                inst.SoundEmitter:KillSound("walkloop")
            end
        end,
    },  
    State{
        name = "lure_enter",
        tags = { "invisible", "lure" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("lure_enter")
            inst.SoundEmitter:KillAllSounds()
            ChangeToLure(inst)
            inst:turnonlight()
        end,

        timeline =
        {
            TimeEvent(FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/worm/lure_emerge") end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg.statemem.islure = true
                inst.sg:GoToState("lure", true)
            end),
        },

        onexit = function(inst)
            if not inst.sg.statemem.islure then
                ChangeToWorm(inst)
            end
        end,
    },

    State{
        name = "lure",
        tags = { "invisible", "lure" },

        onenter = function(inst, islure)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle_loop", true)
            inst.SoundEmitter:KillAllSounds()
            if not islure then
                ChangeToLure(inst)
            end
            inst.sg:SetTimeout(GetRandomWithVariance(TUNING.WORM_LURE_TIME, TUNING.WORM_LURE_VARIANCE))
        end,

        ontimeout = function(inst)
            inst.sg.statemem.islure = true
            inst.sg:GoToState("lure_exit", true)
        end,

        onexit = function(inst)
            inst.lastluretime = GetTime()
            if not inst.sg.statemem.islure then
                ChangeToWorm(inst)
            end
        end,
    },

    State{
        name = "lure_exit",
        tags = { "invisible", "lure" },

        onenter = function(inst, islure)
            inst.AnimState:PlayAnimation("lure_exit")
            inst.SoundEmitter:KillAllSounds()
            if not islure then
                ChangeToLure(inst)
            end
            inst:turnofflight()
        end,

        timeline =
        {
            TimeEvent(FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/worm/lure_retract") end),
        }, 

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle_enter")
            end),
        },

        onexit = ChangeToWorm,
    },
}

CommonStates.AddFrozenStates(states)

return StateGraph("shockworm", states, events, "idle", actionhandlers)
