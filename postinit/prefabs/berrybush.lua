local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local function SpawnDiseasePuff(inst)
    SpawnPrefab("disease_puff").Transform:SetPosition(inst.Transform:GetWorldPosition())
end

local function dig_up_common(inst, worker, numberries)
    if inst.components.pickable ~= nil and inst.components.lootdropper ~= nil then
        local withered = inst.components.witherable ~= nil and inst.components.witherable:IsWithered()
        local diseased = inst.components.diseaseable ~= nil and inst.components.diseaseable:IsDiseased()

        if diseased then
            SpawnDiseasePuff(inst)
        elseif inst.components.diseaseable ~= nil and inst.components.diseaseable:IsBecomingDiseased() then
            SpawnDiseasePuff(inst)
            if worker ~= nil then
                worker:PushEvent("digdiseasing")
            end
        end

        if withered or inst.components.pickable:IsBarren() then
            inst.components.lootdropper:SpawnLootPrefab("twigs")
            inst.components.lootdropper:SpawnLootPrefab("twigs")
        else
            if inst.components.pickable:CanBePicked() then
                local pt = inst:GetPosition()
                pt.y = pt.y + (inst.components.pickable.dropheight or 0)
                for i = 1, numberries do
                    inst.components.lootdropper:SpawnLootPrefab(inst.components.pickable.product, pt)
                end
            end
            if diseased then
                inst.components.lootdropper:SpawnLootPrefab("twigs")
                inst.components.lootdropper:SpawnLootPrefab("twigs")
            elseif math.random() <= 0.1 then
                inst.components.lootdropper:SpawnLootPrefab("bushcrab")
			else
                inst.components.lootdropper:SpawnLootPrefab("dug_"..inst.prefab)
            end
        end
    end
    inst:Remove()
end

local function dig_up_normal(inst, worker)
    dig_up_common(inst, worker, 1)
end

env.AddPrefabPostInit("berrybush", function(inst)

	if not TheWorld.ismastersim then
		return
	end

	if inst.components.workable ~= nil then
        inst.components.workable:SetOnFinishCallback(dig_up_normal)
    end

end)

local function setberries(inst, pct)
    if inst._setberriesonanimover then
        inst._setberriesonanimover = nil
        inst:RemoveEventCallback("animover", setberries)
    end

    local berries =
        (pct == nil and "") or
        (pct >= .9 and "berriesmost") or
        (pct >= .33 and "berriesmore") or
        "berries"

    for i, v in ipairs({ "berries", "berriesmore", "berriesmost" }) do
        if v == berries then
            inst.AnimState:Show(v)
        else
            inst.AnimState:Hide(v)
        end
    end
end

local function setberriesonanimover(inst)
    if inst._setberriesonanimover then
        setberries(inst, nil)
    else
        inst._setberriesonanimover = true
        inst:ListenForEvent("animover", setberries)
    end
end

local function cancelsetberriesonanimover(inst)
    if inst._setberriesonanimover then
        setberries(inst, nil)
    end
end

local function shake(inst)
    if inst.components.pickable ~= nil and
        not inst.components.pickable:CanBePicked() and
        inst.components.pickable:IsBarren() then
        inst.AnimState:PlayAnimation("shake_dead")
        inst.AnimState:PushAnimation("dead", false)
    else
        inst.AnimState:PlayAnimation("shake")
        inst.AnimState:PushAnimation("idle")
    end
    cancelsetberriesonanimover(inst)
end

local function spawnperd(inst)
    if inst:IsValid() then
        local perd = SpawnPrefab("perd")
        local x, y, z = inst.Transform:GetWorldPosition()
        local angle = math.random() * 2 * PI
        perd.Transform:SetPosition(x + math.cos(angle), 0, z + math.sin(angle))
        perd.sg:GoToState("appear")
        perd.components.homeseeker:SetHome(inst)
        shake(inst)
    end
end

local function onpicked2fn(inst, picker)
    if inst.components.pickable ~= nil then
        --V2C: nil cycles_left means unlimited picks, so use max value for math
        --local old_percent = inst.components.pickable.cycles_left ~= nil and (inst.components.pickable.cycles_left + 1) / inst.components.pickable.max_cycles or 1
        --setberries(inst, old_percent)
        if inst.components.pickable:IsBarren() then
            inst.AnimState:PlayAnimation("idle_to_dead")
            inst.AnimState:PushAnimation("dead", false)
            setberries(inst, nil)
        else
            inst.AnimState:PlayAnimation("picked")
            inst.AnimState:PushAnimation("idle")
            setberriesonanimover(inst)
        end

        if inst.components.diseaseable ~= nil then
            if inst.components.diseaseable:IsDiseased() then
                SpawnDiseasePuff(inst)
            elseif inst.components.diseaseable:IsBecomingDiseased() then
                SpawnDiseasePuff(inst)
                if picker ~= nil then
                    picker:PushEvent("pickdiseasing")
                end
            end
        end
    end

    if not (picker:HasTag("berrythief") or inst._noperd) and math.random() < (IsSpecialEventActive(SPECIAL_EVENTS.YOTG) and TUNING.YOTG_PERD_SPAWNCHANCE or TUNING.PERD_SPAWNCHANCE) then
        inst:DoTaskInTime(3 + math.random() * 3, spawnperd)
    end
	
	if inst.components.pickable ~= nil then
		if math.random() <= 0.1 then
			local x, y, z = inst.Transform:GetWorldPosition()
			SpawnPrefab("mosquito").Transform:SetPosition(x, y, z)
			if math.random() <= 0.75 then
				SpawnPrefab("mosquito").Transform:SetPosition(x, y, z)
			end
			if math.random() <= 0.75 then
				SpawnPrefab("mosquito").Transform:SetPosition(x, y, z)
			end
		end
		
	end
end

env.AddPrefabPostInit("berrybush_juicy", function(inst)

	if not TheWorld.ismastersim then
		return
	end
	
	if inst.components.pickable ~= nil then
		inst.components.pickable.onpickedfn = onpicked2fn
	end
--[[
	inst:AddComponent("childspawner")
    inst.components.childspawner.childname = "mosquito"
    inst.components.childspawner:SetRegenPeriod(TUNING.POND_REGEN_TIME)
    inst.components.childspawner:SetSpawnPeriod(TUNING.POND_SPAWN_TIME)
    inst.components.childspawner:SetMaxChildren(math.random(0,1))
    inst.components.childspawner:StartRegen()
    inst.dayspawn = false
	
    inst.task = inst:DoTaskInTime(0, OnInit)--]]

end)