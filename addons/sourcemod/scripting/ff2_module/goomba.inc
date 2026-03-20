#if defined _ff2_goomba_included
    #endinput
#endif
#define _ff2_goomba_included

/**
 * FF2 Goomba Stomp Module
 * Integrated goomba stomp system (merged from goomba.sp + goomba_tf.sp)
 * Original author: Flyflo
 */

#define GOOMBA_STOMP_SOUND "goomba/stomp.wav"
#define GOOMBA_REBOUND_SOUND "goomba/rebound.wav"

#define GOOMBA_IMMUNFLAG_NONE           0
#define GOOMBA_IMMUNFLAG_ATTACKER       (1 << 0)
#define GOOMBA_IMMUNFLAG_VICTIM         (1 << 1)

// ConVars
ConVar g_cvGoombaEnabled;
ConVar g_cvGoombaMinSpeed;
ConVar g_cvGoombaReboundPower;
ConVar g_cvGoombaDmgMultiplier;
ConVar g_cvGoombaDmgAdd;
ConVar g_cvGoombaSounds;
ConVar g_cvGoombaParticles;
ConVar g_cvGoombaImmunity;
ConVar g_cvGoombaCloakImmun;
ConVar g_cvGoombaStunImmun;
ConVar g_cvGoombaUberImmun;
ConVar g_cvGoombaUndisguise;
ConVar g_cvGoombaCloakedImmun;
ConVar g_cvGoombaBonkedImmun;

// Client cookies
Handle g_hGoombaCookie;

// Per-client state
int g_iGoombaSingleStomp[MAXPLAYERS+1];
int g_iGoombaFakekill[MAXPLAYERS+1];
bool g_bGoombaTeleportAtFrameEnd[MAXPLAYERS+1];
float g_flGoombaTeleportVel[MAXPLAYERS+1][3];

// Forwards
Handle g_hForwardOnStomp;
Handle g_hForwardOnStompPost;

/**
 * Initialize goomba stomp system - call from OnPluginStart
 */
void Goomba_Init()
{
	g_cvGoombaEnabled = CreateConVar("goomba_enabled", "1", "Enable/Disable goomba stomp", 0, true, 0.0, true, 1.0);
	g_cvGoombaMinSpeed = CreateConVar("goomba_minspeed", "360.0", "Minimum falling speed to trigger stomp", 0, true, 0.0);
	g_cvGoombaReboundPower = CreateConVar("goomba_rebound_power", "300.0", "Rebound jump power after stomp", 0, true, 0.0);
	g_cvGoombaDmgMultiplier = CreateConVar("goomba_dmg_lifemultiplier", "1.0", "Damage multiplier based on victim health", 0, true, 0.0);
	g_cvGoombaDmgAdd = CreateConVar("goomba_dmg_add", "50.0", "Bonus damage after multiplier", 0, true, 0.0);
	g_cvGoombaSounds = CreateConVar("goomba_sounds", "1", "Enable stomp sounds", 0, true, 0.0, true, 1.0);
	g_cvGoombaParticles = CreateConVar("goomba_particles", "1", "Enable stomp particles", 0, true, 0.0, true, 1.0);
	g_cvGoombaImmunity = CreateConVar("goomba_immunity", "1", "Enable immunity system", 0, true, 0.0, true, 1.0);
	g_cvGoombaCloakImmun = CreateConVar("goomba_cloak_immun", "1", "Prevent cloaked spies from stomping", 0, true, 0.0, true, 1.0);
	g_cvGoombaStunImmun = CreateConVar("goomba_stun_immun", "1", "Prevent stunned players from being stomped", 0, true, 0.0, true, 1.0);
	g_cvGoombaUberImmun = CreateConVar("goomba_uber_immun", "1", "Prevent ubered players from being stomped", 0, true, 0.0, true, 1.0);
	g_cvGoombaUndisguise = CreateConVar("goomba_undisguise", "1", "Undisguise spies after stomping", 0, true, 0.0, true, 1.0);
	g_cvGoombaCloakedImmun = CreateConVar("goomba_cloaked_immun", "0", "Prevent cloaked spies from being stomped", 0, true, 0.0, true, 1.0);
	g_cvGoombaBonkedImmun = CreateConVar("goomba_bonked_immun", "1", "Prevent bonked scouts from being stomped", 0, true, 0.0, true, 1.0);

	g_hGoombaCookie = RegClientCookie("goomba_client_pref", "Goomba immunity preference", CookieAccess_Private);

	g_hForwardOnStomp = CreateGlobalForward("OnStomp", ET_Event, Param_Cell, Param_Cell, Param_FloatByRef, Param_FloatByRef, Param_FloatByRef);
	g_hForwardOnStompPost = CreateGlobalForward("OnStompPost", ET_Ignore, Param_Cell, Param_Cell, Param_Float, Param_Float, Param_Float);

	RegConsoleCmd("goomba_toggle", Goomba_CmdToggle, "Toggle goomba immunity");
	RegConsoleCmd("goomba_status", Goomba_CmdStatus, "Show goomba immunity status");
	RegConsoleCmd("goomba_on", Goomba_CmdOn, "Enable stomp");
	RegConsoleCmd("goomba_off", Goomba_CmdOff, "Disable stomp");

	CreateNative("EmitStompParticles", Native_EmitStompParticles);
}

public int Native_EmitStompParticles(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	Goomba_EmitParticles(client);
	return 0;
}

/**
 * Precache goomba sounds - call from OnMapStart
 */
void Goomba_OnMapStart()
{
	PrecacheSound(GOOMBA_STOMP_SOUND, true);
	PrecacheSound(GOOMBA_REBOUND_SOUND, true);

	char path[128];
	Format(path, sizeof(path), "sound/%s", GOOMBA_STOMP_SOUND);
	AddFileToDownloadsTable(path);
	Format(path, sizeof(path), "sound/%s", GOOMBA_REBOUND_SOUND);
	AddFileToDownloadsTable(path);
}

/**
 * Hook client for stomp detection - call from OnClientPutInServer
 */
void Goomba_OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_StartTouch, Goomba_OnStartTouch);
	SDKHook(client, SDKHook_PreThinkPost, Goomba_OnPreThinkPost);
	g_iGoombaSingleStomp[client] = 0;
	g_bGoombaTeleportAtFrameEnd[client] = false;
}

/**
 * Update immunity on spawn - call from player_spawn event
 */
void Goomba_OnPlayerSpawn(int client)
{
	CreateTimer(0.1, Goomba_Timer_UpdateImmunity, client, TIMER_FLAG_NO_MAPCHANGE);
}

// ============================================================
// Stomp Detection
// ============================================================

public Action Goomba_OnStartTouch(int client, int other)
{
	if(!g_cvGoombaEnabled.BoolValue)
		return Plugin_Continue;

	if(other <= 0 || other > MaxClients)
		return Plugin_Continue;

	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Continue;

	if(!IsClientInGame(other) || !IsPlayerAlive(other))
		return Plugin_Continue;

	float clientPos[3], victimPos[3], victimMaxs[3];
	GetClientAbsOrigin(client, clientPos);
	GetClientAbsOrigin(other, victimPos);
	GetEntPropVector(other, Prop_Send, "m_vecMaxs", victimMaxs);

	float heightDiff = clientPos[2] - victimPos[2];
	if(heightDiff <= victimMaxs[2])
		return Plugin_Continue;

	float velocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", velocity);
	if(velocity[2] >= g_cvGoombaMinSpeed.FloatValue * -1.0)
		return Plugin_Continue;

	if(g_iGoombaSingleStomp[client] != 0)
		return Plugin_Continue;

	if(!Goomba_AreValidTargets(client, other))
		return Plugin_Continue;

	float fallSpeed = velocity[2] * -1.0; // 양수로 변환

	int immunityResult = Goomba_CheckImmunity(client, other);
	if(immunityResult == GOOMBA_IMMUNFLAG_NONE)
	{
		if(Goomba_DoStomp(client, other, fallSpeed))
		{
			Goomba_PlayReboundSound(client);
			Goomba_EmitParticles(other);
		}
		g_iGoombaSingleStomp[client] = 1;
		CreateTimer(0.5, Goomba_Timer_SingleStomp, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if(immunityResult & GOOMBA_IMMUNFLAG_VICTIM)
	{
		CPrintToChat(client, "{olive}[FF2]{default} Stomp is disabled for the victim.");
	}

	return Plugin_Continue;
}

public Action Goomba_Timer_SingleStomp(Handle timer, int client)
{
	g_iGoombaSingleStomp[client] = 0;
	return Plugin_Stop;
}

bool Goomba_AreValidTargets(int client, int victim)
{
	if(victim <= 0 || victim > MaxClients)
		return false;

	if(!IsPlayerAlive(victim))
		return false;

	if(GetClientTeam(client) == GetClientTeam(victim))
		return false;

	if(GetEntProp(victim, Prop_Data, "m_takedamage", 1) == 0)
		return false;

	if(g_cvGoombaUberImmun.BoolValue && TF2_IsPlayerInCondition(victim, TFCond_Ubercharged))
		return false;

	if(g_cvGoombaStunImmun.BoolValue && TF2_IsPlayerInCondition(victim, TFCond_Dazed))
		return false;

	if(g_cvGoombaCloakImmun.BoolValue && TF2_IsPlayerInCondition(client, TFCond_Cloaked))
		return false;

	if(g_cvGoombaCloakedImmun.BoolValue && TF2_IsPlayerInCondition(victim, TFCond_Cloaked))
		return false;

	if(g_cvGoombaBonkedImmun.BoolValue && TF2_IsPlayerInCondition(victim, TFCond_Bonked))
		return false;

	return true;
}

// ============================================================
// Stomp Execution
// ============================================================

bool Goomba_DoStomp(int attacker, int victim, float fallSpeed)
{
	float damageMultiplier = g_cvGoombaDmgMultiplier.FloatValue;
	float damageBonus = g_cvGoombaDmgAdd.FloatValue;
	float jumpPower = g_cvGoombaReboundPower.FloatValue;

	// Fire pre-stomp forward
	Action result;
	Call_StartForward(g_hForwardOnStomp);
	Call_PushCell(attacker);
	Call_PushCell(victim);
	Call_PushFloatRef(damageMultiplier);
	Call_PushFloatRef(damageBonus);
	Call_PushFloatRef(jumpPower);
	Call_Finish(result);

	if(result == Plugin_Handled || result == Plugin_Stop)
		return false;

	// Rebound jump
	if(jumpPower > 0.0)
	{
		float angles[3], vel[3];
		GetClientEyeAngles(attacker, angles);
		GetEntPropVector(attacker, Prop_Data, "m_vecVelocity", vel);
		angles[0] = DegToRad(angles[0]);
		angles[1] = DegToRad(angles[1]);
		vel[0] = jumpPower * Cosine(angles[0]) * Cosine(angles[1]);
		vel[1] = jumpPower * Cosine(angles[0]) * Sine(angles[1]);
		vel[2] = jumpPower + 100.0;

		g_bGoombaTeleportAtFrameEnd[attacker] = true;
		g_flGoombaTeleportVel[attacker] = vel;
	}

	// Deal damage - 낙하속도 비례 데미지
	// 최소속도(goomba_minspeed) = 360 에서 최소 데미지 500
	// 속도가 빠를수록 데미지 증가: 500 + (낙하속도 - 최소속도) × 배율
	float minSpeed = g_cvGoombaMinSpeed.FloatValue;
	float speedRatio = (fallSpeed - minSpeed) / minSpeed; // 0.0 ~ ...
	float stompDamage = 500.0 + (speedRatio * 500.0);     // 최소 500, 2배속도=1000, 3배속도=1500 ...

	if(IsBoss(attacker))
	{
		// 보스 → 플레이어: 고정 1000 데미지 (낙하거리 무관)
		stompDamage = 1000.0;
	}

	g_iGoombaFakekill[victim] = 1;
	SDKHooks_TakeDamage(victim, attacker, attacker, stompDamage,
		DMG_PREVENT_PHYSICS_FORCE | DMG_CRUSH | DMG_ALWAYSGIB);
	g_iGoombaFakekill[victim] = 0;

	// Fire post-stomp forward (damageBonus에 실제 적용된 데미지를 전달)
	Call_StartForward(g_hForwardOnStompPost);
	Call_PushCell(attacker);
	Call_PushCell(victim);
	Call_PushFloat(damageMultiplier);
	Call_PushFloat(stompDamage);
	Call_PushFloat(jumpPower);
	Call_Finish();

	return true;
}

// ============================================================
// Rebound Teleport (deferred to PreThinkPost)
// ============================================================

public void Goomba_OnPreThinkPost(int client)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		g_bGoombaTeleportAtFrameEnd[client] = false;
		return;
	}

	if(g_bGoombaTeleportAtFrameEnd[client])
	{
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, g_flGoombaTeleportVel[client]);
		if(g_cvGoombaSounds.BoolValue)
		{
			EmitSoundToAll(GOOMBA_REBOUND_SOUND, client);
		}
	}
	g_bGoombaTeleportAtFrameEnd[client] = false;
}

// ============================================================
// Death Event Handling
// ============================================================

/**
 * Handle goomba death event - call from player_death event (EventHookMode_Pre)
 */
Action Goomba_OnPlayerDeath(Event event)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));

	if(g_iGoombaFakekill[victim] == 1)
	{
		event.SetBool("goomba", true);
	}

	if(event.GetBool("goomba"))
	{
		int killer = GetClientOfUserId(event.GetInt("attacker"));

		int damageBits = event.GetInt("damagebits");
		event.SetString("weapon_logclassname", "goomba");
		event.SetString("weapon", "taunt_scout");
		event.SetInt("damagebits", damageBits | DMG_ACID);
		event.SetInt("customkill", 0);
		event.SetInt("playerpenetratecount", 0);

		if(!(event.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER))
		{
			Goomba_PlayStompSound(victim);
			PrintHintText(victim, "You've been stomped!");
		}

		if(g_cvGoombaUndisguise.BoolValue && IsValidClient(killer))
		{
			TF2_RemovePlayerDisguise(killer);
		}
	}

	return Plugin_Continue;
}

// ============================================================
// Sounds & Particles
// ============================================================

void Goomba_PlayStompSound(int client)
{
	if(IsClientInGame(client) && g_cvGoombaSounds.BoolValue)
	{
		EmitSoundToClient(client, GOOMBA_STOMP_SOUND, client);
	}
}

void Goomba_PlayReboundSound(int client)
{
	if(IsClientInGame(client) && g_cvGoombaSounds.BoolValue)
	{
		EmitSoundToAll(GOOMBA_REBOUND_SOUND, client);
	}
}

void Goomba_EmitParticles(int client)
{
	if(!g_cvGoombaParticles.BoolValue)
		return;

	int particle = Goomba_AttachParticle(client, "mini_fireworks");
	if(particle != -1)
	{
		CreateTimer(5.0, Goomba_Timer_DeleteParticle, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
	}
}

int Goomba_AttachParticle(int entity, const char[] particleType)
{
	int particle = CreateEntityByName("info_particle_system");
	if(IsValidEdict(particle))
	{
		float pos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		pos[2] += 74.0;
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);

		char tName[128];
		Format(tName, sizeof(tName), "target%i", entity);
		DispatchKeyValue(entity, "targetname", tName);
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);

		SetVariantString(tName);
		SetVariantString("flag");
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");

		return particle;
	}
	return -1;
}

public Action Goomba_Timer_DeleteParticle(Handle timer, int ref)
{
	int particle = EntRefToEntIndex(ref);
	if(particle > MaxClients && IsValidEntity(particle))
	{
		char classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if(StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(particle, "Kill");
		}
	}
	return Plugin_Stop;
}

// ============================================================
// Immunity System
// ============================================================

int Goomba_CheckImmunity(int attacker, int victim)
{
	int result = GOOMBA_IMMUNFLAG_NONE;

	if(!g_cvGoombaImmunity.BoolValue)
		return result;

	char cookieAttacker[16], cookieVictim[16];
	Goomba_GetImmunityCookie(attacker, cookieAttacker, sizeof(cookieAttacker));
	Goomba_GetImmunityCookie(victim, cookieVictim, sizeof(cookieVictim));

	if(StrEqual(cookieAttacker, "on") || StrEqual(cookieAttacker, "next_off"))
		result |= GOOMBA_IMMUNFLAG_ATTACKER;

	if(StrEqual(cookieVictim, "on") || StrEqual(cookieVictim, "next_off"))
		result |= GOOMBA_IMMUNFLAG_VICTIM;

	return result;
}

void Goomba_GetImmunityCookie(int client, char[] buffer, int maxlen)
{
	if(!AreClientCookiesCached(client))
	{
		strcopy(buffer, maxlen, "off");
	}
	else
	{
		GetClientCookie(client, g_hGoombaCookie, buffer, maxlen);
		if(buffer[0] == '\0')
			strcopy(buffer, maxlen, "off");
	}
}

public Action Goomba_Timer_UpdateImmunity(Handle timer, int client)
{
	if(!IsValidClient(client))
		return Plugin_Stop;

	char cookie[16];
	Goomba_GetImmunityCookie(client, cookie, sizeof(cookie));

	if(StrEqual(cookie, "next_off"))
		SetClientCookie(client, g_hGoombaCookie, "off");
	else if(StrEqual(cookie, "next_on"))
		SetClientCookie(client, g_hGoombaCookie, "on");

	return Plugin_Stop;
}

// ============================================================
// Client Commands
// ============================================================

public Action Goomba_CmdToggle(int client, int args)
{
	if(!g_cvGoombaImmunity.BoolValue)
	{
		ReplyToCommand(client, "[Goomba] Immunity system is disabled.");
		return Plugin_Handled;
	}

	char cookie[16];
	Goomba_GetImmunityCookie(client, cookie, sizeof(cookie));

	if(StrEqual(cookie, "off") || StrEqual(cookie, "next_off"))
	{
		SetClientCookie(client, g_hGoombaCookie, "next_on");
		ReplyToCommand(client, "[Goomba] Stomp disabled. Applied at respawn.");
	}
	else
	{
		SetClientCookie(client, g_hGoombaCookie, "next_off");
		ReplyToCommand(client, "[Goomba] Stomp enabled. Applied at respawn.");
	}
	return Plugin_Handled;
}

public Action Goomba_CmdStatus(int client, int args)
{
	if(!g_cvGoombaImmunity.BoolValue)
	{
		ReplyToCommand(client, "[Goomba] Immunity system is disabled.");
		return Plugin_Handled;
	}

	char cookie[16];
	Goomba_GetImmunityCookie(client, cookie, sizeof(cookie));

	if(StrEqual(cookie, "on"))
		ReplyToCommand(client, "[Goomba] Stomp is currently disabled.");
	else if(StrEqual(cookie, "off"))
		ReplyToCommand(client, "[Goomba] Stomp is currently enabled.");
	else if(StrEqual(cookie, "next_off"))
		ReplyToCommand(client, "[Goomba] Stomp will be enabled at respawn.");
	else if(StrEqual(cookie, "next_on"))
		ReplyToCommand(client, "[Goomba] Stomp will be disabled at respawn.");

	return Plugin_Handled;
}

public Action Goomba_CmdOn(int client, int args)
{
	if(!g_cvGoombaImmunity.BoolValue)
	{
		ReplyToCommand(client, "[Goomba] Immunity system is disabled.");
		return Plugin_Handled;
	}

	char cookie[16];
	Goomba_GetImmunityCookie(client, cookie, sizeof(cookie));
	if(!StrEqual(cookie, "off"))
	{
		SetClientCookie(client, g_hGoombaCookie, "next_off");
		ReplyToCommand(client, "[Goomba] Stomp enabled. Applied at respawn.");
	}
	return Plugin_Handled;
}

public Action Goomba_CmdOff(int client, int args)
{
	if(!g_cvGoombaImmunity.BoolValue)
	{
		ReplyToCommand(client, "[Goomba] Immunity system is disabled.");
		return Plugin_Handled;
	}

	char cookie[16];
	Goomba_GetImmunityCookie(client, cookie, sizeof(cookie));
	if(!StrEqual(cookie, "on"))
	{
		SetClientCookie(client, g_hGoombaCookie, "next_on");
		ReplyToCommand(client, "[Goomba] Stomp disabled. Applied at respawn.");
	}
	return Plugin_Handled;
}
