local ink_assets =
{
    Asset("ANIM", "anim/squid_watershoot.zip"),
}

local ink_prefabs =
{
    "ink_splash",
    "ink_puddle_land",
    "ink_puddle_water",
}

local COLLAPSIBLE_TAGS = { "_combat", "pickable", "NPC_workable" }
local NON_COLLAPSIBLE_TAGS = { "bearger", "flying", "bird", "ghost", "playerghost", "FX", "NOCLICK", "DECOR", "INLIMBO" }

local function OnHitInk(inst, attacker, target)
	
    
	local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, 0, z, 5, nil, NON_COLLAPSIBLE_TAGS, COLLAPSIBLE_TAGS)
    for i, v in ipairs(ents) do
        if v:IsValid() then
            if v.components.combat ~= nil
                and v.components.health ~= nil
                and not v:HasTag("bearger")
                and not v.components.health:IsDead() then
                if v.components.combat:CanBeAttacked() then
                    v.components.combat:GetAttacked(inst, 100)
                end
            end
        end
    end
	
	local boat = TheWorld.Map:GetPlatformAtPoint(x, z)
		
	inst.fx = "groundpound_fx"
	
	if boat then
		local sinkhole = SpawnPrefab("antlion_sinkhole_boat")
		sinkhole.Transform:SetPosition(x, 0, z)
		sinkhole.components.timer:StartTimer("nextrepair", 20 + (math.random() * 10))
	elseif not inst:IsOnOcean() and not boat then
		local sinkhole = SpawnPrefab("bearger_sinkhole")
		sinkhole.Transform:SetPosition(x, 0, z)
		sinkhole.components.timer:StartTimer("nextrepair", 20 + (math.random() * 10))
	elseif inst:IsOnOcean() then
		inst.fx = "splash_green"
	end
					
	SpawnPrefab(inst.fx).Transform:SetPosition(x, 0, z)
	local ring = SpawnPrefab("groundpoundring_fx")
	ring.Transform:SetPosition(x, 0, z)
	ring.Transform:SetScale(0.7, 0.7, 0.7)
	
    inst:Remove()
end

local function oncollide(inst, other)
	local x, y, z = inst.Transform:GetWorldPosition()
	if other ~= nil and other:IsValid() and other:HasTag("_combat") and not other:HasTag("bearger_boulder") or y <= inst:GetPhysicsRadius() + 0.001 then
		OnHitInk(inst, other)
	end
end


local function onthrown(inst)
    inst:AddTag("NOCLICK")
    inst.persists = false
    inst.AnimState:SetBank("bearger_boulder")
    inst.AnimState:SetBuild("bearger_boulder")
    inst.AnimState:PlayAnimation("spin_loop"..math.random(4), true)

	inst.Transform:SetScale(1.1, 1.1, 1.1)
	
    inst.Physics:SetMass(1)
    inst.Physics:SetFriction(10)
    inst.Physics:SetDamping(5)
    inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
    inst.Physics:ClearCollisionMask()
    inst:SetPhysicsRadiusOverride(3)
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:SetCapsule(1.5, 1.5)
	
    inst.Physics:SetCollisionCallback(oncollide)
end

local function projectilefn()
    local inst = CreateEntity()
	
	
    inst:AddTag("bearger_boulder")

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddPhysics()
    inst.entity:AddNetwork()

	local shadow = inst.entity:AddDynamicShadow()
    shadow:SetSize( 1.5, 1 )

    inst.AnimState:SetBank("bearger_boulder")
    inst.AnimState:SetBuild("bearger_boulder")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetHorizontalSpeed(15)
    inst.components.complexprojectile:SetGravity(-20)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(0, .1, 0))
    inst.components.complexprojectile:SetOnLaunch(onthrown)
    inst.components.complexprojectile:SetOnHit(OnHitInk)
    inst.components.complexprojectile.usehigharc = false

    inst.persists = false

    inst:AddComponent("locomotor")

	--inst:DoTaskInTime(0.1, function(inst) inst:DoPeriodicTask(0, TestProjectileLand) end)

    return inst
end

return Prefab("bearger_boulder", projectilefn, ink_assets, ink_prefabs)
