#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define HOMING_LIMIT 2048

// 유도 방식
enum {
	HOMING_ADDITIVE = 1,    // 현재 방식: 속도 벡터 가산
	HOMING_LERP = 2,        // 각도 보간 (Angle Lerp)
	HOMING_TURNRATE = 3,    // 각속도 제한 (Max Turn Rate)
	HOMING_REPLACE = 4      // 속도 직접 교체
};

int g_iHomingMode = HOMING_LERP;
float g_flHomingParam = 0.05; // 방식별 파라미터

int g_iHomingOwner[HOMING_LIMIT];
Handle g_hHomingTimer[HOMING_LIMIT];

public Plugin myinfo = {
	name = "Homing Test",
	author = "test",
	description = "로켓 유도 방식 테스트",
	version = "1.1"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_homing", Cmd_Homing, "유도 방식 변경: sm_homing <1-4> [param]");

	for(int i = 0; i < HOMING_LIMIT; i++)
	{
		g_iHomingOwner[i] = 0;
		g_hHomingTimer[i] = INVALID_HANDLE;
	}
}

public Action Cmd_Homing(int client, int args)
{
	if(args < 1)
	{
		PrintToChat(client, "[Homing] 현재 모드: %d (파라미터: %.3f)", g_iHomingMode, g_flHomingParam);
		PrintToChat(client, "[Homing] 사용법: sm_homing <1-4> [param]");
		PrintToChat(client, "  1 = 속도 가산 (param=strength, 기본 1000)");
		PrintToChat(client, "  2 = 각도 보간 Lerp (param=비율 0.0~1.0, 기본 0.05)");
		PrintToChat(client, "  3 = 각속도 제한 (param=최대 각도/틱, 기본 5.0)");
		PrintToChat(client, "  4 = 속도 직접 교체 (param 없음)");
		return Plugin_Handled;
	}

	char arg1[16];
	GetCmdArg(1, arg1, sizeof(arg1));
	g_iHomingMode = StringToInt(arg1);
	if(g_iHomingMode < 1) g_iHomingMode = 1;
	if(g_iHomingMode > 4) g_iHomingMode = 4;

	if(args >= 2)
	{
		char arg2[16];
		GetCmdArg(2, arg2, sizeof(arg2));
		g_flHomingParam = StringToFloat(arg2);
	}
	else
	{
		// 기본값 설정
		switch(g_iHomingMode)
		{
			case HOMING_ADDITIVE: g_flHomingParam = 1000.0;
			case HOMING_LERP: g_flHomingParam = 0.05;
			case HOMING_TURNRATE: g_flHomingParam = 5.0;
			case HOMING_REPLACE: g_flHomingParam = 0.0;
		}
	}

	char modeName[32];
	switch(g_iHomingMode)
	{
		case HOMING_ADDITIVE: modeName = "속도 가산";
		case HOMING_LERP: modeName = "각도 보간 Lerp";
		case HOMING_TURNRATE: modeName = "각속도 제한";
		case HOMING_REPLACE: modeName = "속도 직접 교체";
	}

	PrintToChatAll("[Homing] 모드 변경: %d (%s) 파라미터: %.3f", g_iHomingMode, modeName, g_flHomingParam);
	return Plugin_Handled;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrEqual(classname, "tf_projectile_rocket"))
	{
		SDKHook(entity, SDKHook_SpawnPost, OnRocketSpawnPost);
	}
}

public void OnRocketSpawnPost(int entity)
{
	if(entity <= 0 || entity >= HOMING_LIMIT)
		return;

	int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	if(owner <= 0 || owner > MaxClients || !IsClientInGame(owner))
	{
		PrintToChatAll("[Homing] 로켓 %d: 오너 없음 (owner=%d)", entity, owner);
		return;
	}

	// 무기 제한 제거 - 모든 로켓에 유도 적용
	PrintToChatAll("[Homing] 로켓 %d 유도 활성화 (오너: %N, 모드: %d)", entity, owner, g_iHomingMode);

	g_iHomingOwner[entity] = owner;
	g_hHomingTimer[entity] = CreateTimer(0.01, Timer_Homing, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Homing(Handle timer, any entref)
{
	int entity = EntRefToEntIndex(entref);
	if(entity == INVALID_ENT_REFERENCE || !IsValidEntity(entity) || entity >= HOMING_LIMIT)
	{
		int idx = entref & 0x7FF;
		if(idx > 0 && idx < HOMING_LIMIT)
		{
			g_hHomingTimer[idx] = INVALID_HANDLE;
			g_iHomingOwner[idx] = 0;
		}
		return Plugin_Stop;
	}

	int owner = g_iHomingOwner[entity];
	if(owner <= 0 || owner > MaxClients || !IsClientInGame(owner) || !IsPlayerAlive(owner))
	{
		HomingCleanup(entity);
		return Plugin_Stop;
	}

	// 가장 가까운 적 찾기
	int target = GetClosestEnemy(entity, GetClientTeam(owner));
	if(target <= 0)
		return Plugin_Continue;

	float projPos[3], targetPos[3], projVel[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", projPos);
	GetClientEyePosition(target, targetPos);
	GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", projVel);

	float projSpeed = GetVectorLength(projVel);
	if(projSpeed < 1.0)
		return Plugin_Continue;

	switch(g_iHomingMode)
	{
		case HOMING_ADDITIVE:
		{
			// 방식 1: 속도 벡터 가산
			float targetVec[3];
			SubtractVectors(targetPos, projPos, targetVec);
			NormalizeVector(targetVec, targetVec);
			ScaleVector(targetVec, g_flHomingParam);

			AddVectors(projVel, targetVec, projVel);
			NormalizeVector(projVel, projVel);
			ScaleVector(projVel, projSpeed);
		}
		case HOMING_LERP:
		{
			// 방식 2: 각도 보간 (Lerp)
			float targetVec[3];
			SubtractVectors(targetPos, projPos, targetVec);
			NormalizeVector(targetVec, targetVec);

			float curDir[3];
			NormalizeVector(projVel, curDir);

			float t = g_flHomingParam;
			projVel[0] = curDir[0] * (1.0 - t) + targetVec[0] * t;
			projVel[1] = curDir[1] * (1.0 - t) + targetVec[1] * t;
			projVel[2] = curDir[2] * (1.0 - t) + targetVec[2] * t;

			NormalizeVector(projVel, projVel);
			ScaleVector(projVel, projSpeed);
		}
		case HOMING_TURNRATE:
		{
			// 방식 3: 각속도 제한 (최대 N도/틱)
			float targetVec[3];
			SubtractVectors(targetPos, projPos, targetVec);
			NormalizeVector(targetVec, targetVec);

			float curDir[3];
			NormalizeVector(projVel, curDir);

			float dot = curDir[0]*targetVec[0] + curDir[1]*targetVec[1] + curDir[2]*targetVec[2];
			if(dot > 1.0) dot = 1.0;
			if(dot < -1.0) dot = -1.0;
			float angle = ArcCosine(dot) * (180.0 / 3.14159265);

			float maxAngle = g_flHomingParam;
			if(angle > maxAngle && angle > 0.01)
			{
				float t = maxAngle / angle;
				projVel[0] = curDir[0] * (1.0 - t) + targetVec[0] * t;
				projVel[1] = curDir[1] * (1.0 - t) + targetVec[1] * t;
				projVel[2] = curDir[2] * (1.0 - t) + targetVec[2] * t;
			}
			else
			{
				projVel[0] = targetVec[0];
				projVel[1] = targetVec[1];
				projVel[2] = targetVec[2];
			}

			NormalizeVector(projVel, projVel);
			ScaleVector(projVel, projSpeed);
		}
		case HOMING_REPLACE:
		{
			// 방식 4: 속도 직접 교체 (타겟에게 직진)
			SubtractVectors(targetPos, projPos, projVel);
			NormalizeVector(projVel, projVel);
			ScaleVector(projVel, projSpeed);
		}
	}

	// 속도 및 각도 적용
	float projAng[3];
	GetVectorAngles(projVel, projAng);
	SetEntPropVector(entity, Prop_Data, "m_angRotation", projAng);
	SetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", projVel);

	return Plugin_Continue;
}

void HomingCleanup(int entity)
{
	if(entity <= 0 || entity >= HOMING_LIMIT)
		return;

	g_iHomingOwner[entity] = 0;
	if(g_hHomingTimer[entity] != INVALID_HANDLE)
	{
		KillTimer(g_hHomingTimer[entity]);
		g_hHomingTimer[entity] = INVALID_HANDLE;
	}
}

int GetClosestEnemy(int entity, int ownerTeam)
{
	float entityPos[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", entityPos);

	int closest = -1;
	float closestDist = 3000.0;

	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		if(GetClientTeam(i) == ownerTeam)
			continue;

		float pos[3];
		GetClientEyePosition(i, pos);
		float dist = GetVectorDistance(entityPos, pos);

		if(dist < closestDist)
		{
			// 시야 체크
			Handle trace = TR_TraceRayFilterEx(entityPos, pos, MASK_SOLID, RayType_EndPoint, TraceFilter, entity);
			bool hit = TR_DidHit(trace);
			int hitEnt = TR_GetEntityIndex(trace);
			delete trace;

			if(!hit || hitEnt == i)
			{
				closestDist = dist;
				closest = i;
			}
		}
	}

	return closest;
}

public bool TraceFilter(int entity, int contentsMask, any data)
{
	return (entity != data && entity > MaxClients);
}
