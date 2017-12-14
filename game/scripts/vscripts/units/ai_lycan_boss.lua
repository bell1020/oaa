
function Spawn( entityKeyValues )
	if thisEntity == nil then
		return
	end

	if IsServer() == false then
		return
	end

	thisEntity.LYCAN_BOSS_SUMMONED_UNITS = { }
	thisEntity.LYCAN_BOSS_MAX_SUMMONS = 50
	thisEntity.nCAST_SUMMON_WOLVES_COUNT = 0

	thisEntity.hSummonWolvesAbility = thisEntity:FindAbilityByName( "lycan_boss_summon_wolves" )
	thisEntity.hShapeshiftAbility = thisEntity:FindAbilityByName( "lycan_boss_shapeshift" )
	thisEntity.hClawLungeAbility = thisEntity:FindAbilityByName( "lycan_boss_claw_lunge" )
	thisEntity.hClawAttackAbility = thisEntity:FindAbilityByName( "lycan_boss_claw_attack" )
	thisEntity.hRuptureBallAbility = thisEntity:FindAbilityByName( "lycan_boss_rupture_ball" )

	thisEntity:SetContextThink( "LycanBossThink", LycanBossThink, 1 )
end


function LycanBossThink()
	if GameRules:IsGamePaused() == true or GameRules:State_Get() == DOTA_GAMERULES_STATE_POST_GAME or thisEntity:IsAlive() == false then
		return 1
  end

  if not thisEntity.bInitialized then
		thisEntity.vInitialSpawnPos = thisEntity:GetOrigin()
    thisEntity.bInitialized = true
	end

	local hEnemies = FindUnitsInRadius( thisEntity:GetTeamNumber(), thisEntity:GetOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_CLOSEST, false )
	if #hEnemies == 0 then
    RetreatHome()
    return 2.0
  end

  local fDist = ( thisEntity:GetOrigin() - thisEntity.vInitialSpawnPos ):Length2D()
	if fDist > 2000 then
		RetreatHome()
		return 2.0
	end

	thisEntity.bShapeshift = thisEntity:FindModifierByName( "modifier_lycan_boss_shapeshift" ) ~= nil
	if thisEntity.bShapeshift then
		if thisEntity.hClawLungeAbility ~= nil and thisEntity.hClawLungeAbility:IsFullyCastable() then
			return CastClawLunge( hEnemies[ RandomInt( 1, #hEnemies ) ] )
		end
	else
		if thisEntity:GetHealthPercent() < 50 then
			if thisEntity.hShapeshiftAbility:IsFullyCastable() then
				return CastShapeshift()
			end
		end
  end

	-- Check that the children we have in our list are still valid
	for i, hSummonedUnit in ipairs( thisEntity.LYCAN_BOSS_SUMMONED_UNITS ) do
		if hSummonedUnit == nil or hSummonedUnit:IsNull() or hSummonedUnit:IsAlive() == false then
			table.remove( thisEntity.LYCAN_BOSS_SUMMONED_UNITS, i )
		end
	end

	-- Have we hit our minion limit?
	if #thisEntity.LYCAN_BOSS_SUMMONED_UNITS < thisEntity.LYCAN_BOSS_MAX_SUMMONS then
		if thisEntity.hSummonWolvesAbility ~= nil and thisEntity.hSummonWolvesAbility:IsFullyCastable() then
			return CastSummonWolves()
		end
	end

	local hRuptureTargets = { }
	for _, hEnemy in pairs( hEnemies ) do
		if hEnemy ~= nil and hEnemy:IsAlive() and hEnemy:IsRealHero() then
			local flDist = ( hEnemy:GetOrigin() - thisEntity:GetOrigin() ):Length2D()
			if flDist > 500 then
				table.insert( hRuptureTargets, hEnemy )
			end
		end
	end

	-- Cast Rupture Ball on someone far away
	if thisEntity.hRuptureBallAbility ~= nil and thisEntity.hRuptureBallAbility:IsFullyCastable() then
		if #hRuptureTargets > 0 then
			return CastRuptureBall( hRuptureTargets[ RandomInt( 1, #hRuptureTargets ) ] )
		end
	end

	if thisEntity.hClawAttackAbility ~= nil and thisEntity.hClawAttackAbility:IsFullyCastable() then
		return CastClawAttack( hEnemies[ 1 ] )
	end

	return 0.5
end


function RetreatHome()
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
		Position = thisEntity.vInitialSpawnPos
  })
end


function CastClawAttack( enemy )
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
		TargetIndex = enemy:entindex(),
		AbilityIndex = thisEntity.hClawAttackAbility:entindex(),
	})

	return 1.00
end

function CastClawLunge( enemy )
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
		AbilityIndex = thisEntity.hClawLungeAbility:entindex(),
		Position = enemy:GetOrigin(),
	})

	return 0.5
end

function CastSummonWolves()
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
		AbilityIndex = thisEntity.hSummonWolvesAbility:entindex(),
	})

	return 0.6
end


function CastShapeshift()
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
		AbilityIndex = thisEntity.hShapeshiftAbility:entindex(),
	})

	return 1
end

function CastRuptureBall( unit )
	ExecuteOrderFromTable({
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
		AbilityIndex = thisEntity.hRuptureBallAbility:entindex(),
		Position = unit:GetOrigin(),
		Queue = false,
	})

	return 1
end
