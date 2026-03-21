/*
===Freak Fortress 2===

By Rainbolt Dash: programmer, modeller, mapper, painter.
Author of Demoman The Pirate: http://www.randomfortress.ru/thepirate/
And one of two creators of Floral Defence: http://www.polycount.com/forum/showthread.php?t=73688
And author of VS Saxton Hale Mode
And notoriously famous for creating plugins with terrible code and then abandoning them.

Plugin thread on AlliedMods: http://forums.alliedmods.net/showthread.php?t=182108

Updated by Otokiru, Powerlord, and RavensBro after Rainbolt Dash got sucked into DOTA2

Updated by Wliu, Chris, Lawd, and Carge after Powerlord quit FF2
*/
#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>

#undef REQUIRE_EXTENSIONS
#tryinclude <steamtools>
#define REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#tryinclude <mannvsmann>
// #include <db_simple>
#tryinclude <smac>
#tryinclude <updater>
#define REQUIRE_PLUGIN

#include <adt_array>
#include <morecolors>
#include <sdkhooks>
#include <dhooks>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>
#include <tf2utils>
#include <tf2wearables>
#include <unixtime_sourcemod>

#include <freak_fortress_2>
#include <ff2_modules>

#include <stocksoup/tf/monster_resource>
#include <stocksoup/tf/econ>

#include "ff2_module/core.inc"
#include "ff2_module/database.inc"
#include "ff2_module/sdkcalls.inc"
#include "ff2_module/stocks.inc"
#include "ff2_module/hud.inc"
#include "ff2_module/character.inc"
#include "ff2_module/music.inc"
#include "ff2_module/player.inc"
#include "ff2_module/boss.inc"
#include "ff2_module/commands.inc"
#include "ff2_module/dhooks.inc"
#include "ff2_module/weapon.inc"
#include "ff2_module/goomba.inc"
#include "ff2_module/rank_hud.inc"

#pragma newdecls required

#if defined _steamtools_included
bool steamtools;
#endif
bool mannvsmann = false;

int Stabbed[MAXPLAYERS+1];
int Marketed[MAXPLAYERS+1];
int ComboPunchCount[MAXPLAYERS+1];
float LastCharge[MAXPLAYERS+1];
float OverCharge[MAXPLAYERS+1];
float KSpreeTimer[MAXPLAYERS+1];
int KSpreeCount[MAXPLAYERS+1];
float GlowTimer[MAXPLAYERS+1];
bool emitRageSound[MAXPLAYERS+1];
float g_flZatoichiDrawTime[MAXPLAYERS+1];  // 자토이치를 꺼낸 시간
int g_iAmputatorHits[MAXPLAYERS+1];
Handle KritzTimer[MAXPLAYERS+1];
float g_flSpyCloakDamageMultiplier[MAXPLAYERS+1];


float RocketJumpPosition[MAXPLAYERS+1][3];

int timeType;
float timeleft, maxTime;
int maxWave, currentWave;

// ConVar cvarVersion;
ConVar cvarPointDelay;
ConVar cvarAnnounce;
ConVar cvarEnabled;
ConVar cvarAliveToEnable;
ConVar cvarPointType;
ConVar cvarCrits;
ConVar cvarArenaRounds;
ConVar cvarCircuitStun;
ConVar cvarSpecForceBoss;
ConVar cvarEnableEurekaEffect;
ConVar cvarForceBossTeam;
ConVar cvarHealthBar;
ConVar cvarLastPlayerGlow;
ConVar cvarBossTeleporter;
ConVar cvarBossSuicide;
ConVar cvarShieldCrits;
ConVar cvarCaberDetonations;
ConVar cvarUpdater;
ConVar cvarDebug;
ConVar cvarPreroundBossDisconnect;
ConVar cvarTimerType;

Handle jumpHUD;
Handle rageHUD;
Handle upAddtionalHUD, downAddtionalHUD;
Handle timeleftHUD;
Handle abilitiesHUD;
Handle infoHUD;

int PointDelay=6;
float Announce=120.0;
int AliveToEnable=5;
int PointType;
bool BossCrits=true;
int arenaRounds;
float circuitStun;
bool SpecForceBoss;
bool lastPlayerGlow=true;
bool bossTeleportation=true;
int shieldCrits;
int allowedDetonations;

Handle doorCheckTimer;

float HPTime;
char currentmap[99];
bool checkDoors;
bool bMedieval;
bool firstBlood;
float roundTime;

float tf_arena_preround_time;
int tf_arena_use_queue;
int mp_teams_unbalance_limit;
int tf_arena_first_blood;
int mp_forcecamera;
int tf_dropped_weapon_lifetime;
float tf_feign_death_activate_damage_scale;
float tf_feign_death_damage_scale;
char mp_humans_must_join_team[16];

ConVar cvarNextmap;

TFMonsterResource healthBar;
int g_Monoculus=-1;

static bool executed;

int changeGamemode;

//Handle kvWeaponSpecials;

public Plugin myinfo=
{
	name="Freak Fortress 2",
	author="Rainbolt Dash, FlaminSarge, Powerlord, the 50DKP team",
	description="RUUUUNN!! COWAAAARRDSS!",
	version=PLUGIN_VERSION,
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	char plugin[PLATFORM_MAX_PATH];
	GetPluginFilename(myself, plugin, sizeof(plugin));
	if(!StrContains(plugin, "freak_fortress_2/"))  //Prevent plugins/freak_fortress_2/freak_fortress_2.smx from loading if it exists -.-
	{
		strcopy(error, err_max, "There is a duplicate copy of Freak Fortress 2 inside the /plugins/freak_fortress_2 folder.  Please remove it");
		return APLRes_Failure;
	}

	CreateNative("FF2_IsFF2Enabled", Native_IsFF2Enabled);
	CreateNative("FF2_RegisterSubplugin", Native_RegisterSubplugin);
	CreateNative("FF2_UnregisterSubplugin", Native_UnregisterSubplugin);
	CreateNative("FF2_GetFF2Version", Native_GetFF2Version);
	CreateNative("FF2_GetRoundState", Native_GetRoundState);
	CreateNative("FF2_GetBossUserId", Native_GetBossUserId);
	CreateNative("FF2_GetBossIndex", Native_GetBossIndex);
	CreateNative("FF2_GetBossTeam", Native_GetBossTeam);
	CreateNative("FF2_GetBossName", Native_GetBossName);
	CreateNative("FF2_GetBossKV", Native_GetBossKV);
	CreateNative("FF2_GetBossHealth", Native_GetBossHealth);
	CreateNative("FF2_SetBossHealth", Native_SetBossHealth);
	CreateNative("FF2_GetBossMaxHealth", Native_GetBossMaxHealth);
	CreateNative("FF2_SetBossMaxHealth", Native_SetBossMaxHealth);
	CreateNative("FF2_GetBossLives", Native_GetBossLives);
	CreateNative("FF2_SetBossLives", Native_SetBossLives);
	CreateNative("FF2_GetBossMaxLives", Native_GetBossMaxLives);
	CreateNative("FF2_SetBossMaxLives", Native_SetBossMaxLives);
	CreateNative("FF2_GetBossCharge", Native_GetBossCharge);
	CreateNative("FF2_SetBossCharge", Native_SetBossCharge);
	CreateNative("FF2_GetBossRageDamage", Native_GetBossRageDamage);
	CreateNative("FF2_SetBossRageDamage", Native_SetBossRageDamage);
	CreateNative("FF2_GetBossRageDistance", Native_GetBossRageDistance);
	CreateNative("FF2_GetClientDamage", Native_GetClientDamage);
	CreateNative("FF2_SetClientDamage", Native_SetClientDamage);
	CreateNative("FF2_HasAbility", Native_HasAbility);
	CreateNative("FF2_GetAbilityArgument", Native_GetAbilityArgument);
	CreateNative("FF2_GetAbilityArgumentFloat", Native_GetAbilityArgumentFloat);
	CreateNative("FF2_GetAbilityArgumentString", Native_GetAbilityArgumentString);
	CreateNative("FF2_UseAbility", Native_UseAbility);
	CreateNative("FF2_GetFF2Flags", Native_GetFF2Flags);
	CreateNative("FF2_SetFF2Flags", Native_SetFF2Flags);
	CreateNative("FF2_GetQueuePoints", Native_GetQueuePoints);
	CreateNative("FF2_SetQueuePoints", Native_SetQueuePoints);
	CreateNative("FF2_GetClientGlow", Native_GetClientGlow);
	CreateNative("FF2_SetClientGlow", Native_SetClientGlow);
	CreateNative("FF2_Debug", Native_Debug);

	// ff2_module/music.sp
	CreateNative("FF2_StartMusic", Native_StartMusic);
	CreateNative("FF2_StopMusic", Native_StopMusic);
	CreateNative("FF2_FindSound", Native_FindSound);
	CreateNative("FF2_SetSoundFlags", Native_SetSoundFlags);
	CreateNative("FF2_ClearSoundFlags", Native_ClearSoundFlags);
	CreateNative("FF2_CheckSoundFlags", Native_CheckSoundFlags);

	// ff2_modules/general.inc
	CreateNative("FF2_GetCharacterIndex", Native_GetCharacterIndex);
	CreateNative("FF2_AddBossCharge", Native_AddBossCharge);
	CreateNative("FF2_GetBossMaxCharge", Native_GetBossMaxCharge);
	CreateNative("FF2_SetBossMaxCharge", Native_SetBossMaxCharge);
	CreateNative("FF2_GetBossSkillDuration", Native_GetBossSkillDuration);
	CreateNative("FF2_SetBossSkillDuration", Native_SetBossSkillDuration);
	CreateNative("FF2_GetTimerType", Native_GetTimerType);
	CreateNative("FF2_GetRoundTime", Native_GetRoundTime);
	CreateNative("FF2_SetRoundTime", Native_SetRoundTime);
	CreateNative("FF2_GetClientAssist", Native_GetClientAssist);
	CreateNative("FF2_SetClientAssist", Native_SetClientAssist);
	CreateNative("FF2_EquipBoss", Native_EquipBoss);
	CreateNative("FF2_SpecialAttackToBoss", Native_SpecialAttackToBoss);
	CreateNative("FF2_GetCharacterKV", Native_GetCharacterKV);
	CreateNative("FF2_MakePlayerToBoss", Native_MakePlayerToBoss);
	CreateNative("FF2_GetBossCreatorFlags", Native_GetBossCreatorFlags);
	CreateNative("FF2_GetBossCreators", Native_GetBossCreators);
	CreateNative("FF2_DropWeapon", Native_DropWeapon);
	CreateNative("FF2_EqiupWeaponFromDropped", Native_EqiupWeaponFromDropped);

	OnWaveStarted=CreateGlobalForward("FF2_OnWaveStarted", ET_Hook, Param_Cell); // wave
	OnPlayBoss=CreateGlobalForward("FF2_OnPlayBoss", ET_Hook, Param_Cell); // Boss
	OnAddRage=CreateGlobalForward("FF2_OnAddRage", ET_Hook, Param_Cell, Param_FloatByRef); // Boss
	OnSpecialAttack=CreateGlobalForward("FF2_OnSpecialAttack", ET_Hook, Param_Cell, Param_Cell, Param_Cell, Param_String, Param_FloatByRef);
	OnSpecialAttack_Post=CreateGlobalForward("FF2_OnSpecialAttack_Post", ET_Hook, Param_Cell, Param_Cell, Param_String, Param_Float);
	OnCheckRules=CreateGlobalForward("FF2_OnCheckRules", ET_Hook, Param_Cell, Param_Cell, Param_CellByRef, Param_String, Param_String); // Client, characterIndex, chance, Rule String, value
	OnApplyBossHealthCorrection=CreateGlobalForward("FF2_OnApplyBossHealthCorrection", ET_Hook, Param_Cell, Param_FloatByRef); // boss, multiplier

	// ff2_modules/database.inc
	CreateNative("FF2_GetSettingData", Native_GetSettingData);
	CreateNative("FF2_GetSettingStringData", Native_GetSettingStringData);
	CreateNative("FF2_SetSettingData", Native_SetSettingData);
	CreateNative("FF2_SetSettingStringData", Native_SetSettingStringData);
	
	//ff2_module/hud.sp
	HudInit();

	PreAbility=CreateGlobalForward("FF2_PreAbility", ET_Hook, Param_Cell, Param_String, Param_String, Param_Cell, Param_CellByRef);  //Boss, plugin name, ability name, slot, enabled
	OnAbility=CreateGlobalForward("FF2_OnAbility", ET_Hook, Param_Cell, Param_String, Param_String, Param_Cell, Param_Cell);  //Boss, plugin name, ability name, slot, status
	OnMusic=CreateGlobalForward("FF2_OnMusic", ET_Hook, Param_Cell, Param_String, Param_CellByRef);
	OnTriggerHurt=CreateGlobalForward("FF2_OnTriggerHurt", ET_Hook, Param_Cell, Param_Cell, Param_FloatByRef);
	OnBossSelected=CreateGlobalForward("FF2_OnBossSelected", ET_Hook, Param_Cell, Param_CellByRef, Param_String, Param_Cell);  //Boss, character index, character name, preset
	OnAddQueuePoints=CreateGlobalForward("FF2_OnAddQueuePoints", ET_Hook, Param_Array);
	OnLoadCharacterSet=CreateGlobalForward("FF2_OnLoadCharacterSet", ET_Hook, Param_String);
	OnLoseLife=CreateGlobalForward("FF2_OnLoseLife", ET_Hook, Param_Cell, Param_CellByRef, Param_Cell);  //Boss, lives left, max lives
	OnAlivePlayersChanged=CreateGlobalForward("FF2_OnAlivePlayersChanged", ET_Hook, Param_Cell, Param_Cell);  //Players, bosses
	OnParseUnknownVariable=CreateGlobalForward("FF2_OnParseUnknownVariable", ET_Hook, Param_String, Param_FloatByRef);  //Variable, value

	RegPluginLibrary("freak_fortress_2");
	RegPluginLibrary("ff2_fork_general");
	RegPluginLibrary("ff2_db");

	subpluginArray=CreateArray(64); // Create this as soon as possible so that subplugins have access to it

	#if defined _steamtools_included
	MarkNativeAsOptional("Steam_SetGameDescription");
	#endif
	return APLRes_Success;
}

public void OnPluginStart()
{
	LogMessage("===Freak Fortress 2 Initializing-v%s===", PLUGIN_VERSION);

	// 파이프 폭발 SDKCall 초기화
	Handle hGameConf = LoadGameConfigFile("ff2_pipedetonate");
	if(hGameConf != null)
	{
		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CBaseGrenade::Detonate");
		g_hSDKCallDetonate = EndPrepSDKCall();
		if(g_hSDKCallDetonate == null)
			LogError("[FF2] Failed to create SDKCall for CBaseGrenade::Detonate");
		delete hGameConf;
	}
	else
	{
		LogError("[FF2] Failed to load gamedata ff2_pipedetonate.txt");
	}

	// 유래카 즉시건설 SDKCall 초기화
	Handle hBuildConf = LoadGameConfigFile("ff2_buildings");
	if(hBuildConf != null)
	{
		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(hBuildConf, SDKConf_Virtual, "CBaseObject::StartBuilding");
		g_hSDKStartBuilding = EndPrepSDKCall();
		if(g_hSDKStartBuilding == null)
			LogError("[FF2] Failed to create SDKCall for CBaseObject::StartBuilding");

		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(hBuildConf, SDKConf_Virtual, "CBaseObject::FinishedBuilding");
		g_hSDKFinishBuilding = EndPrepSDKCall();
		if(g_hSDKFinishBuilding == null)
			LogError("[FF2] Failed to create SDKCall for CBaseObject::FinishedBuilding");

		delete hBuildConf;
	}
	else
	{
		LogError("[FF2] Failed to load gamedata ff2_buildings.txt");
	}

	// cvarVersion=CreateConVar("ff2_version", PLUGIN_VERSION, "Freak Fortress 2 Version", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	cvarPointType=CreateConVar("ff2_point_type", "0", "0-Use ff2_point_alive, 1-Use ff2_point_time", _, true, 0.0, true, 1.0);
	cvarPointDelay=CreateConVar("ff2_point_delay", "6", "Seconds to add to the point delay per player", _, true, 0.0);
	cvarAliveToEnable=CreateConVar("ff2_point_alive", "5", "The control point will only activate when there are this many people or less left alive");
	cvarAnnounce=CreateConVar("ff2_announce", "150", "Amount of seconds to wait until FF2 info is displayed again.  0 to disable", _, true, 0.0);
	cvarEnabled=CreateConVar("ff2_enabled", "1", "0-Disable FF2 (WHY?), 1-Enable FF2", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	cvarCrits=CreateConVar("ff2_crits", "0", "Can the boss get random crits?", _, true, 0.0, true, 1.0);
	cvarArenaRounds=CreateConVar("ff2_arena_rounds", "1", "Number of rounds to make arena before switching to FF2 (helps for slow-loading players)", _, true, 0.0);
	cvarCircuitStun=CreateConVar("ff2_circuit_stun", "0.3", "Amount of seconds the Short Circuit stuns the boss for.  0 to disable", _, true, 0.0);
	cvarSpecForceBoss=CreateConVar("ff2_spec_force_boss", "0", "0-Spectators are excluded from the queue system, 1-Spectators are counted in the queue system", _, true, 0.0, true, 1.0);
	cvarEnableEurekaEffect=CreateConVar("ff2_enable_eureka", "0", "0-Disable the Eureka Effect, 1-Enable the Eureka Effect", _, true, 0.0, true, 1.0);
	cvarForceBossTeam=CreateConVar("ff2_force_team", "0", "0-Boss is always on Blu, 1-Boss is on a random team each round, 2-Boss is always on Red", _, true, 0.0, true, 3.0);
	cvarHealthBar=CreateConVar("ff2_health_bar", "1", "0-Disable the health bar, 1-Show the health bar", _, true, 0.0, true, 1.0);
	cvarLastPlayerGlow=CreateConVar("ff2_last_player_glow", "1", "0-Don't outline the last player, 1-Outline the last player alive", _, true, 0.0, true, 1.0);
	cvarBossTeleporter=CreateConVar("ff2_boss_teleporter", "1", "-1 to disallow all bosses from using teleporters, 0 to use TF2 logic, 1 to allow all bosses", _, true, -1.0, true, 1.0);
	cvarBossSuicide=CreateConVar("ff2_boss_suicide", "0", "Allow the boss to suicide after the round starts?", _, true, 0.0, true, 1.0);
	cvarPreroundBossDisconnect=CreateConVar("ff2_replace_disconnected_boss", "1", "If a boss disconnects before the round starts, use the next player in line instead? 0 - No, 1 - Yes", _, true, 0.0, true, 1.0);
	cvarCaberDetonations=CreateConVar("ff2_caber_detonations", "5", "Amount of times somebody can detonate the Ullapool Caber");
	cvarShieldCrits=CreateConVar("ff2_shield_crits", "1", "0 to disable grenade launcher crits when equipping a shield, 1 for minicrits, 2 for crits", _, true, 0.0, true, 2.0);
	cvarUpdater=CreateConVar("ff2_updater", "1", "0-Disable Updater support, 1-Enable automatic updating (recommended, requires Updater)", _, true, 0.0, true, 1.0);
	cvarDebug=CreateConVar("ff2_debug", "0", "0-Disable FF2 debug output, 1-Enable debugging (not recommended)", _, true, 0.0, true, 1.0);
	cvarTimerType=CreateConVar("ff2_timer_type", "1", "0-Disable FF2 round timer, 1-Enable round timer, 2-Enable wave timer", _, true, 0.0, true, 2.0);


	HookEvent("teamplay_round_start", OnRoundStart);
	HookEvent("teamplay_round_win", OnRoundEnd);
	HookEvent("teamplay_broadcast_audio", OnBroadcast, EventHookMode_Pre);
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Pre);
	HookEvent("post_inventory_application", OnPostInventoryApplication, EventHookMode_Pre);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("player_chargedeployed", OnUberDeployed);
	HookEvent("player_hurt", OnPlayerHurt, EventHookMode_Pre);
	HookEvent("object_destroyed", OnObjectDestroyed, EventHookMode_Pre);
	HookEvent("object_deflected", OnObjectDeflected, EventHookMode_Pre);
	HookEvent("deploy_buff_banner", OnDeployBackup);
	HookEvent("player_healed", OnPlayerHealed);
	HookEvent("medigun_shield_blocked_damage", OnMedigunBlockDamage);
	HookEvent("player_builtobject", OnObjectBuilt);

	HookUserMessage(GetUserMessageId("PlayerJarated"), OnJarate);  //Used to subtract rage when a boss is jarated (not through Sydney Sleeper)

	AddCommandListener(OnCallForMedic, "voicemenu");    //Used to activate rages
	AddCommandListener(OnSuicide, "explode");           //Used to stop boss from suiciding
	AddCommandListener(OnSuicide, "kill");              //Used to stop boss from suiciding
	AddCommandListener(OnSuicide, "spectate");			//Used to stop boss from suiciding
	AddCommandListener(OnJoinTeam, "jointeam");         //Used to make sure players join the right team
	AddCommandListener(OnJoinTeam, "autoteam");         //Used to make sure players don't kill themselves and change team
	AddCommandListener(OnChangeClass, "joinclass");     //Used to make sure bosses don't change class

	cvarEnabled.AddChangeHook(CvarChange);
	cvarPointDelay.AddChangeHook(CvarChange);
	cvarAnnounce.AddChangeHook(CvarChange);
	cvarPointType.AddChangeHook(CvarChange);
	cvarAliveToEnable.AddChangeHook(CvarChange);
	cvarCrits.AddChangeHook(CvarChange);
	cvarCircuitStun.AddChangeHook(CvarChange);
	cvarHealthBar.AddChangeHook(HealthbarEnableChanged);
	cvarLastPlayerGlow.AddChangeHook(CvarChange);
	cvarSpecForceBoss.AddChangeHook(CvarChange);
	cvarBossTeleporter.AddChangeHook(CvarChange);
	cvarShieldCrits.AddChangeHook(CvarChange);
	cvarCaberDetonations.AddChangeHook(CvarChange);
	cvarUpdater.AddChangeHook(CvarChange);
	cvarNextmap=FindConVar("sm_nextmap");
	cvarNextmap.AddChangeHook(CvarChangeNextmap);

	AutoExecConfig(true, "freak_fortress_2", "sourcemod/freak_fortress_2");

	FF2Cookie_QueuePoints=RegClientCookie("ff2_cookie_queuepoints", "Client's queue points", CookieAccess_Protected);

	jumpHUD=CreateHudSynchronizer();
	rageHUD=CreateHudSynchronizer();
	upAddtionalHUD = CreateHudSynchronizer();
	downAddtionalHUD = CreateHudSynchronizer();
	abilitiesHUD=CreateHudSynchronizer();
	timeleftHUD=CreateHudSynchronizer();
	infoHUD=CreateHudSynchronizer();

	bossesArray = new ArrayList();
	bossesArrayOriginal = new ArrayList();
	g_hBaseEntityMap = new FF2BaseEntity_Map();

	LoadTranslations("freak_fortress_2.phrases");
	LoadTranslations("common.phrases");

	AddNormalSoundHook(HookSound);

	AddMultiTargetFilter("@hale", BossTargetFilter, "all current Bosses", false);
	AddMultiTargetFilter("@!hale", BossTargetFilter, "all non-Boss players", false);
	AddMultiTargetFilter("@boss", BossTargetFilter, "all current Bosses", false);
	AddMultiTargetFilter("@!boss", BossTargetFilter, "all non-Boss players", false);

	#if defined _steamtools_included
	steamtools=LibraryExists("SteamTools");
	#endif

	#if defined _MVM_included
	mannvsmann=LibraryExists("mannvsmann");
	#endif
	
	FF2DB_Init();

	GameData gamedata = new GameData("potry");

	// ff2_module/sdkcalls.sp
	GameData_Init(gamedata);

	// ff2_module/dhooks.sp
	DHooks_Init(gamedata);

	// ff2_moudle/cmd.sp
	Cmd_Init();

	// ff2_module/goomba.inc
	Goomba_Init();

	// ff2_module/rank_hud.inc
	RankHud_Init();

	delete gamedata;
	CreateTimer(1.0, OverChargeTimer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	    for(int i = 0; i <= MaxClients; i++)
    {
        KritzTimer[i] = INVALID_HANDLE;
    }

}

public bool BossTargetFilter(const char[] pattern, Handle clients)
{
	bool non=StrContains(pattern, "!", false)!=-1;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && FindValueInArray(clients, client)==-1)
		{
			if(Enabled && IsBoss(client))
			{
				if(!non)
				{
					PushArrayCell(clients, client);
				}
			}
			else if(non)
			{
				PushArrayCell(clients, client);
			}
		}
	}
	return true;
}

public void OnLibraryAdded(const char[] name)
{
	#if defined _steamtools_included
	if(StrEqual(name, "SteamTools", false))
	{
		steamtools=true;
	}
	#endif

	#if defined _MVM_included
	if(StrEqual(name, "mannvsmann", false))
	{
		mannvsmann = true;
	}
	#endif

	#if defined _updater_included && !defined DEV_REVISION
	if(StrEqual(name, "updater") && cvarUpdater.BoolValue)
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	#endif
}

public void OnLibraryRemoved(const char[] name)
{
	#if defined _steamtools_included
	if(StrEqual(name, "SteamTools", false))
	{
		steamtools=false;
	}
	#endif

	#if defined _MVM_included
	if(StrEqual(name, "mannvsmann", false))
	{
		mannvsmann = false;
	}
	#endif

	#if defined _updater_included
	if(StrEqual(name, "updater"))
	{
		Updater_RemovePlugin();
	}
	#endif
}

public void OnConfigsExecuted()
{
	tf_arena_preround_time=FindConVar("tf_arena_preround_time").FloatValue;
	tf_arena_use_queue=FindConVar("tf_arena_use_queue").IntValue;
	mp_teams_unbalance_limit=FindConVar("mp_teams_unbalance_limit").IntValue;
	tf_arena_first_blood=FindConVar("tf_arena_first_blood").IntValue;
	mp_forcecamera=FindConVar("mp_forcecamera").IntValue;
	tf_dropped_weapon_lifetime=FindConVar("tf_dropped_weapon_lifetime").BoolValue;
	tf_feign_death_activate_damage_scale=FindConVar("tf_feign_death_activate_damage_scale").FloatValue;
	tf_feign_death_damage_scale=FindConVar("tf_feign_death_damage_scale").FloatValue;
	FindConVar("mp_humans_must_join_team").GetString(mp_humans_must_join_team, sizeof(mp_humans_must_join_team));

	if(IsFF2Map() && cvarEnabled.BoolValue)
	{
		EnableFF2();
	}
	else
	{
		DisableFF2();
	}

	#if defined _updater_included && !defined DEV_REVISION
	if(LibraryExists("updater") && cvarUpdater.BoolValue)
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	#endif
}

public void OnMapStart()
{
	HPTime=0.0;
	doorCheckTimer=null;
	RoundCount=0;

	// 유도 시스템 + 파이프 벽폭발 초기화
	for(int i = 0; i < HOMING_LIMIT; i++)
	{
		g_iHomingOwner[i] = 0;
		g_hHomingTimer[i] = INVALID_HANDLE;
		g_flHomingProjStr[i] = 0.0;
		g_bPipeWallExplode[i] = false;
	}

	for(int client = 0; client <= MaxClients; client++)
	{
		// FF2BasePlayer player = GetBasePlayer(client);
		// player.Flags = 0;

		KSpreeTimer[client]=0.0;
		Incoming[client]=-1;
		MusicTimer[client]=null;
	}

	Handle temp;
	for(int index; index < bossesArray.Length; index++)
	{
		temp = view_as<Handle>(bossesArray.Get(index));
		if(temp != null)
		{
			delete temp;
			bossesArray.Set(index, INVALID_HANDLE);
		}
		temp = view_as<Handle>(bossesArrayOriginal.Get(index));
		if(temp != null)
		{
			delete temp;
			bossesArrayOriginal.Set(index, INVALID_HANDLE);
		}
	}

	bossesArray.Clear();
	bossesArrayOriginal.Clear();

	Goomba_OnMapStart();
}

public void OnMapEnd()
{
	// 맵 변경 전 모든 플레이어의 대기표를 cookie에 저장
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && g_hBasePlayer[i] != null)
		{
			view_as<FF2BasePlayer>(g_hBasePlayer[i]).SaveQueuePointsToCookie(i);
		}
	}

	if(Enabled || Enabled2)
	{
		DisableFF2();  //This resets all the variables for safety
	}
	for(int i = 0; i <= MaxClients; i++)
	{
		OverCharge[i] = 0.0;
	}
}

public void OnPluginEnd()
{
	OnMapEnd();
}

public void EnableFF2()
{
	Enabled=true;
	Enabled2=true;

	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", FF2_SETTINGS, WEAPONS_CONFIG);

	if(kvWeaponMods!=null)
	{
		delete kvWeaponMods;
	}

	kvWeaponMods=new KeyValues("FF2Weapons");

	if(!kvWeaponMods.ImportFromFile(config))
	{
		LogError("[FF2 Configs] Failed to load weapon configuration file!");
		Enabled=false;
		Enabled2=false;
		return;
	}

	ParseChangelog();

	if(kvHudConfigs != null)
		delete kvHudConfigs;
	kvHudConfigs=LoadHudConfig();

	//Cache cvars
	// SetConVarString(FindConVar("ff2_version"), PLUGIN_VERSION);
	Announce=cvarAnnounce.FloatValue;
	PointType=cvarPointType.IntValue;
	PointDelay=cvarPointDelay.IntValue;
	AliveToEnable=cvarAliveToEnable.IntValue;
	BossCrits=cvarCrits.BoolValue;
	arenaRounds=cvarArenaRounds.IntValue;
	circuitStun=cvarCircuitStun.FloatValue;
	lastPlayerGlow=cvarLastPlayerGlow.BoolValue;
	bossTeleportation=cvarBossTeleporter.BoolValue;
	shieldCrits=cvarShieldCrits.IntValue;
	allowedDetonations=cvarCaberDetonations.IntValue;

	//Set some Valve cvars to what we want them to be
	FindConVar("tf_arena_use_queue").SetInt(0);
	FindConVar("mp_teams_unbalance_limit").SetInt(0);
	FindConVar("tf_arena_first_blood").SetInt(0);
	FindConVar("mp_forcecamera").SetInt(0);
	FindConVar("tf_dropped_weapon_lifetime").SetInt(0);
	FindConVar("tf_feign_death_activate_damage_scale").SetFloat(0.3);
	FindConVar("tf_feign_death_damage_scale").SetFloat(1.0);
	FindConVar("mp_humans_must_join_team").SetString("any");
	FindConVar("tf_player_movement_restart_freeze").SetInt(1);

	float time=Announce;
	if(time>1.0)
	{
		CreateTimer(time, Timer_Announce, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}

	CheckToChangeMapDoors();
	MapHasMusic(true);
	FindCharacters();
	strcopy(FF2CharSetString, 2, "");

	bMedieval=FindEntityByClassname(-1, "tf_logic_medieval")!=-1 || FindConVar("tf_medieval").BoolValue;
	FindHealthBar();

	#if defined _steamtools_included
	if(steamtools)
	{
		char gameDesc[64];
		Format(gameDesc, sizeof(gameDesc), "Freak Fortress 2 (%s)", PLUGIN_VERSION);
		Steam_SetGameDescription(gameDesc);
	}
	#endif

	changeGamemode=0;
}

public void DisableFF2()
{
	Enabled=false;
	Enabled2=false;

	FindConVar("tf_arena_use_queue").SetInt(tf_arena_use_queue);
	FindConVar("mp_teams_unbalance_limit").SetInt(mp_teams_unbalance_limit);
	FindConVar("tf_arena_first_blood").SetInt(tf_arena_first_blood);
	FindConVar("mp_forcecamera").SetInt(mp_forcecamera);
	FindConVar("tf_dropped_weapon_lifetime").SetInt(tf_dropped_weapon_lifetime);
	FindConVar("tf_feign_death_activate_damage_scale").SetFloat(tf_feign_death_activate_damage_scale);
	FindConVar("tf_feign_death_damage_scale").SetFloat(tf_feign_death_damage_scale);
	FindConVar("mp_humans_must_join_team").SetString(mp_humans_must_join_team);

	if(doorCheckTimer!=null)
	{
		KillTimer(doorCheckTimer);
		doorCheckTimer=null;
	}

	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			if(BossInfoTimer[client][1]!=null)
			{
				delete BossInfoTimer[client][1];
			}
		}

		if(MusicTimer[client]!=null)
		{
			delete MusicTimer[client];
		}

		bossHasReloadAbility[client]=false;
		bossHasRightMouseAbility[client]=false;
	}

	#if defined _steamtools_included
	if(steamtools)
	{
		Steam_SetGameDescription("Team Fortress");
	}
	#endif

	changeGamemode=0;
}

stock KeyValues LoadChangelog()
{
	char changelog[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, changelog, sizeof(changelog), "%s/%s", FF2_SETTINGS, CHANGELOG);
	if(!FileExists(changelog))
	{
		LogError("[FF2] Changelog %s does not exist!", changelog);
		return null;
	}

	ChangeLogLastTime = GetFileTime(changelog, FileTime_LastChange);
	KeyValues kv=new KeyValues("Changelog");
	kv.ImportFromFile(changelog);

	return kv;
}

public void CvarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(convar==cvarPointDelay)
	{
		PointDelay=StringToInt(newValue);
	}
	else if(convar==cvarAnnounce)
	{
		Announce=StringToFloat(newValue);
	}
	else if(convar==cvarPointType)
	{
		PointType=StringToInt(newValue);
	}
	else if(convar==cvarAliveToEnable)
	{
		AliveToEnable=StringToInt(newValue);
	}
	else if(convar==cvarCrits)
	{
		BossCrits=view_as<bool>(StringToInt(newValue));
	}
	else if(convar==cvarArenaRounds)
	{
		arenaRounds=StringToInt(newValue);
	}
	else if(convar==cvarCircuitStun)
	{
		circuitStun=StringToFloat(newValue);
	}
	else if(convar==cvarLastPlayerGlow)
	{
		lastPlayerGlow=view_as<bool>(StringToInt(newValue));
	}
	else if(convar==cvarSpecForceBoss)
	{
		SpecForceBoss=view_as<bool>(StringToInt(newValue));
	}
	else if(convar==cvarBossTeleporter)
	{
		bossTeleportation=view_as<bool>(StringToInt(newValue));
	}
	else if(convar==cvarShieldCrits)
	{
		shieldCrits=StringToInt(newValue);
	}
	else if(convar==cvarCaberDetonations)
	{
		allowedDetonations=StringToInt(newValue);
	}
	else if(convar==cvarUpdater)
	{
		#if defined _updater_included && !defined DEV_REVISION
		cvarUpdater.IntValue ? Updater_AddPlugin(UPDATE_URL) : Updater_RemovePlugin();
		#endif
	}
	else if(convar==cvarEnabled)
	{
		StringToInt(newValue) ? (changeGamemode=Enabled ? 0 : 1) : (changeGamemode=!Enabled ? 0 : 2);
	}
}

#if defined _smac_included
public Action SMAC_OnCheatDetected(int client, const char[] module, DetectionType type, Handle info)
{
	Debug("SMAC: Cheat detected!");
	if(type==Detection_CvarViolation)
	{
		Debug("SMAC: Cheat was a cvar violation!");
		char cvar[PLATFORM_MAX_PATH];
		KvGetString(info, "cvar", cvar, sizeof(cvar));
		Debug("Cvar was %s", cvar);
		if((StrEqual(cvar, "sv_cheats") || StrEqual(cvar, "host_timescale")) && !(FF2Flags[Boss[client]] & FF2FLAG_CHANGECVAR))
		{
			Debug("SMAC: Ignoring violation");
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}
#endif

public Action Timer_Announce(Handle timer)
{
	static int announcecount=-1;
	announcecount++;
	if(Announce>1.0 && Enabled2)
	{
		switch(announcecount)
		{
			case 1:
			{
				CPrintToChatAll("%t", "VSH and FF2 Group");
			}
			case 3:
			{
				CPrintToChatAll("%t", "FF2 Contributors", PLUGIN_VERSION);
			}
			case 4:
			{
				CPrintToChatAll("{olive}[FF2]{default} %t", "Type ff2 to Open Menu");
			}
			case 5:
			{
				CPrintToChatAll("{olive}[FF2]{default} %t", "Type ff2_advance to Open Menu");
			}
			case 6:
			{
				announcecount=0;
				char timeStr[64], targetTimeStr[64];
				FormatTime(timeStr, sizeof(timeStr), "%Y-%m-%d %H:%M:%S", ChangeLogLastTime);

				for(int client=1; client<=MaxClients; client++)
				{
					if(!IsClientInGame(client)) continue;
					SetGlobalTransTarget(client);

					GetSettingStringData(client, "changelog_last_view_time", targetTimeStr, sizeof(targetTimeStr));
					if(DateToTimestamp(targetTimeStr) < ChangeLogLastTime) // ???
					{
						CPrintToChat(client, "{olive}[FF2]{default} %t", "FF2 Changelog Notice", timeStr);
					}
					else
					{
						CPrintToChat(client, "{olive}[FF2]{default} %t", "Last FF2 Update", PLUGIN_VERSION);
					}
				}
			}
			default:
			{
				CPrintToChatAll("{olive}[FF2]{default} %t", "Type ff2 to Open Menu");
			}
		}
	}
	return Plugin_Continue;
}

stock bool IsFF2Map()
{
	char config[PLATFORM_MAX_PATH];
	GetCurrentMap(currentmap, sizeof(currentmap));
	if(FileExists("bNextMapToFF2"))
	{
		return true;
	}

	BuildPath(Path_SM, config, sizeof(config), "%s/%s", FF2_SETTINGS, MAPS_CONFIG);
	if(!FileExists(config))
	{
		LogError("[FF2] Unable to find %s, disabling plugin.", config);
		return false;
	}

	File file=OpenFile(config, "r");
	if(file==null)
	{
		LogError("[FF2] Error reading maps from %s, disabling plugin.", config);
		return false;
	}

	int tries;
	while(file.ReadLine(config, sizeof(config)) && tries<100)
	{
		tries++;
		if(tries==100)
		{
			LogError("[FF2] Breaking infinite loop when trying to check the map.");
			return false;
		}

		Format(config, strlen(config)-1, config);
		if(!strncmp(config, "//", 2, false))
		{
			continue;
		}

		if(!StrContains(currentmap, config, false) || !StrContains(config, "all", false))
		{
			delete file;
			return true;
		}
	}
	delete file;
	return false;
}


// TODO: Mess
stock bool CheckToChangeMapDoors()
{
	if(!Enabled || !Enabled2)
	{
		return false;
	}

	char config[PLATFORM_MAX_PATH];
	checkDoors=false;
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", FF2_SETTINGS, DOORS_CONFIG);
	if(!FileExists(config))
	{
		if(!strncmp(currentmap, "vsh_lolcano_pb1", 15, false))
		{
			checkDoors=true;
		}
		return checkDoors;
	}

	File file=OpenFile(config, "r");
	if(file==null)
	{
		if(!strncmp(currentmap, "vsh_lolcano_pb1", 15, false))
		{
			checkDoors=true;
		}
		return checkDoors;
	}

	while(!file.EndOfFile() && file.ReadLine(config, sizeof(config)))
	{
		Format(config, strlen(config)-1, config);
		if(!strncmp(config, "//", 2, false))
		{
			continue;
		}

		if(StrContains(currentmap, config, false)!=-1 || !StrContains(config, "all", false))
		{
			delete file;
			checkDoors=true;
			return checkDoors;
		}
	}
	delete file;
	return false;
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(changeGamemode==1)
	{
		EnableFF2();
	}
	else if(changeGamemode==2)
	{
		DisableFF2();
	}
	
	    for(int i = 0; i <= MaxClients; i++)
    {
        Stabbed[i] = 0;
        Marketed[i] = 0;
        KSpreeCount[i] = 0;
        ComboPunchCount[i] = 0;
        emitRageSound[i] = true;
    }

	if(!cvarEnabled.BoolValue)
	{
		#if defined _steamtools_included
		if(steamtools)
		{
			Steam_SetGameDescription("Team Fortress");
		}
		#endif
		Enabled2=false;
	}

	roundTime = GetGameTime();
	Enabled=Enabled2;
	if(!Enabled)
	{
		return Plugin_Continue;
	}

	if(FileExists("bNextMapToFF2"))
	{
		DeleteFile("bNextMapToFF2");
	}

	bool blueBoss;
	switch(cvarForceBossTeam.IntValue)
	{
		case 1:
		{
			blueBoss=view_as<bool>(GetRandomInt(0, 1));
		}
		case 2:
		{
			blueBoss=false;
		}
		default:
		{
			blueBoss=true;
		}
	}

	if(blueBoss)
	{
		SetTeamScore(view_as<int>(TFTeam_Red), GetTeamScore(view_as<int>(OtherTeam)));
		SetTeamScore(view_as<int>(TFTeam_Blue), GetTeamScore(view_as<int>(BossTeam)));
		OtherTeam=TFTeam_Red;
		BossTeam=TFTeam_Blue;
	}
	else
	{
		SetTeamScore(view_as<int>(TFTeam_Red), GetTeamScore(view_as<int>(BossTeam)));
		SetTeamScore(view_as<int>(TFTeam_Blue), GetTeamScore(view_as<int>(OtherTeam)));
		OtherTeam=TFTeam_Blue;
		BossTeam=TFTeam_Red;
	}

	playing=0;

	for(int client = 1; client <= MaxClients; client++)
	{
		if(!IsClientInGame(client)) 	continue;

		FF2BaseEntity player = g_hBasePlayer[client];

		player.Damage = 0;
		player.Assist = 0;
		player.Flags = 0;
		
		uberTarget[client]=-1;
		emitRageSound[client]=true;
		if(IsValidClient(client) && TF2_GetClientTeam(client)>TFTeam_Spectator)
		{
			playing++;
		}
	}

	if(GetClientCount()<=1 || playing<=1)  //Not enough players D:
	{
		CPrintToChatAll("{olive}[FF2]{default} %t", "More Players Needed");
		Enabled=false;
		//DisableSubPlugins();
		SetControlPoint(true);
		return Plugin_Continue;
	}
	else if(RoundCount<arenaRounds)  //We're still in arena mode
	{
		CPrintToChatAll("{olive}[FF2]{default} %t", "Arena Rounds Left", arenaRounds-RoundCount);  //Waiting for players to finish loading.  FF2 will start in {1} more rounds
		Enabled=false;
		//DisableSubPlugins();
		SetArenaCapEnableTime(60.0);
		CreateTimer(71.0, Timer_EnableCap, _, TIMER_FLAG_NO_MAPCHANGE);
		bool toRed;
		TFTeam team;
		for(int client=1; client<=MaxClients; client++)
		{
			if(IsValidClient(client) && (team=TF2_GetClientTeam(client))>TFTeam_Spectator)
			{
				SetEntProp(client, Prop_Send, "m_lifeState", 2);
				if(toRed && team!=TFTeam_Red)
				{
					TF2_ChangeClientTeam(client, TFTeam_Red);
				}
				else if(!toRed && team!=TFTeam_Blue)
				{
					TF2_ChangeClientTeam(client, TFTeam_Blue);
				}
				SetEntProp(client, Prop_Send, "m_lifeState", 0);
				TF2_RespawnPlayer(client);
				toRed=!toRed;
			}
		}
		return Plugin_Continue;
	}

	for(int client = 0; client <= MaxClients; client++)
	{
		Boss[client] = 0;

		if(!IsValidClient(client) || !IsPlayerAlive(client))
			continue;

		FF2BaseEntity player = g_hBasePlayer[client];
		if(!(player.Flags & FF2FLAG_HASONGIVED))
			TF2_RespawnPlayer(client);
	}

	Enabled=true;
	//EnableSubPlugins();
	CheckArena();

	bool[] omit=new bool[MaxClients+1];
	Boss[0]=GetClientWithMostQueuePoints(omit);
	if(Boss[0] == 0)
	{
		Boss[0]=RandomlySelectClient(true, omit);
		CPrintToChatAll("{olive}[FF2]{default} %t", "Randomly Choose Boss Player");
	}

	omit[Boss[0]]=true;

	bool teamHasPlayers[4]; // TODO: 컴파일러 버전 변경으로 인한 Enum 크기 구하는 방법 변경
	for(int client=1; client<=MaxClients; client++)  //Find out if each team has at least one player on it
	{
		if(IsValidClient(client))
		{
			TFTeam team=TF2_GetClientTeam(client);
			if(team>TFTeam_Spectator)
			{
				teamHasPlayers[team]=true;
			}

			if(teamHasPlayers[TFTeam_Blue] && teamHasPlayers[TFTeam_Red])
			{
				break;
			}
		}
	}

	if(!teamHasPlayers[TFTeam_Blue] || !teamHasPlayers[TFTeam_Red])  //If there's an empty team make sure it gets populated
	{
		if(IsValidClient(Boss[0]) && TF2_GetClientTeam(Boss[0])!=BossTeam)
		{
			AssignTeam(Boss[0], BossTeam);
		}

		for(int client=1; client<=MaxClients; client++)
		{
			if(IsValidClient(client) && !IsBoss(client) && TF2_GetClientTeam(client)!=OtherTeam)
			{
				FF2BaseEntity player = g_hBasePlayer[client];
				CreateTimer(0.1, MakeNotBoss, player, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		return Plugin_Continue;  //NOTE: This is needed because OnRoundStart gets fired a second time once both teams have players
	}

	PickCharacter(0, 0);
	if((character[0]<0) || !bossesArray.Get(character[0]))
	{
		LogError("[FF2 Bosses] Couldn't find a boss!");
		return Plugin_Continue;
	}

	FindCompanion(0, playing, omit);  //Find companions for the boss!

	for(int boss; boss<=MaxClients; boss++)
	{
		BossInfoTimer[boss][0]=null;
		BossInfoTimer[boss][1]=null;
		if(Boss[boss])
		{
			AssignTeam(Boss[boss], BossTeam);
			SetEntityMoveType(Boss[boss], MOVETYPE_NONE);
			
			CreateTimer(0.3, MakeBoss, boss, TIMER_FLAG_NO_MAPCHANGE);
			BossInfoTimer[boss][0]=CreateTimer(30.2, BossInfoTimer_Begin, boss, TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	CreateTimer(tf_arena_preround_time - 6.5, StartResponseTimer, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(tf_arena_preround_time - 0.9, StartBossTimer, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(tf_arena_preround_time - 0.4, MessageTimer, _, TIMER_FLAG_NO_MAPCHANGE);

	for(int entity=MaxClients+1; entity<MAXENTITIES; entity++)
	{
		if(!IsValidEntity(entity))
		{
			continue;
		}

		char classname[64];
		GetEntityClassname(entity, classname, sizeof(classname));
		if(StrEqual(classname, "func_regenerate"))
		{
			AcceptEntityInput(entity, "Kill");
		}
		else if (StrEqual(classname, "func_respawnroom") || StrEqual(classname, "func_respawnroomvisualizer"))
		{
			AcceptEntityInput(entity, "Disable");
		}
	}

	healthcheckused=0;
	firstBlood=true;
	return Plugin_Continue;
}

public Action Timer_EnableCap(Handle timer)
{
	if((Enabled || Enabled2) && CheckRoundState()==FF2RoundState_Loading)
	{
		SetControlPoint(true);
		if(checkDoors)
		{
			int ent=-1;
			while((ent=FindEntityByClassname2(ent, "func_door"))!=-1)
			{
				AcceptEntityInput(ent, "Open");
				AcceptEntityInput(ent, "Unlock");
			}

			if(doorCheckTimer==null)
			{
				doorCheckTimer=CreateTimer(5.0, Timer_CheckDoors, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	return Plugin_Continue;
}

public Action BossInfoTimer_Begin(Handle timer, int boss)
{
	BossInfoTimer[boss][0]=null;
	BossInfoTimer[boss][1]=CreateTimer(0.2, BossInfoTimer_ShowInfo, boss, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action BossInfoTimer_ShowInfo(Handle timer, int boss)
{
	if(!IsValidClient(Boss[boss]))
	{
		BossInfoTimer[boss][1]=null;
		return Plugin_Stop;
	}

	if(bossHasReloadAbility[boss])
	{
		SetHudTextParams(0.75, 0.7, 0.15, 255, 255, 255, 255);
		SetGlobalTransTarget(Boss[boss]);
		if(bossHasRightMouseAbility[boss])
		{
			FF2_ShowSyncHudText(Boss[boss], abilitiesHUD, "%t\n%t", "Ability uses Reload", "Ability uses Right Mouse");
		}
		else
		{
			FF2_ShowSyncHudText(Boss[boss], abilitiesHUD, "%t", "Ability uses Reload");
		}
	}
	else if(bossHasRightMouseAbility[boss])
	{
		SetHudTextParams(0.75, 0.7, 0.15, 255, 255, 255, 255);
		SetGlobalTransTarget(Boss[boss]);
		FF2_ShowSyncHudText(Boss[boss], abilitiesHUD, "%t", "Ability uses Right Mouse");
	}
	else
	{
		BossInfoTimer[boss][1]=null;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action Timer_CheckDoors(Handle timer)
{
	if(!checkDoors)
	{
		doorCheckTimer=null;
		return Plugin_Stop;
	}

	if((!Enabled && CheckRoundState()!=FF2RoundState_Loading) || (Enabled && CheckRoundState()!=FF2RoundState_RoundRunning))
	{
		return Plugin_Continue;
	}

	int entity=-1;
	while((entity=FindEntityByClassname2(entity, "func_door"))!=-1)
	{
		AcceptEntityInput(entity, "Open");
		AcceptEntityInput(entity, "Unlock");
	}
	return Plugin_Continue;
}

public void CheckArena()
{
	if(PointType)
	{
		SetArenaCapEnableTime(float(45+PointDelay*(playing-1)));
	}
	else
	{
		SetArenaCapEnableTime(0.0);
		SetControlPoint(false);
	}
}

public Action OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	RoundCount++;

	if(!Enabled)
	{
		return Plugin_Continue;
	}

	executed=false;
	bool bossWin;
	char sound[PLATFORM_MAX_PATH];
	if((view_as<TFTeam>(event.GetInt("team"))==BossTeam))
	{
		bossWin=true;
		if(FindSound("win", sound, sizeof(sound)))
		{
			EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound);
		}
	}

	StopMusic();

	bool isBossAlive;
	for(int boss; boss<=MaxClients; boss++)
	{
		if(IsValidClient(Boss[boss]))
		{
			SetClientGlow(Boss[boss], 0.0, 0.0);
			SDKUnhook(boss, SDKHook_GetMaxHealth, OnGetMaxHealth);  //Temporary:  Used to prevent boss overheal
			if(IsPlayerAlive(Boss[boss]))
			{
				isBossAlive=true;
			}

			for(int slot=1; slot<8; slot++)
			{
				BossCharge[boss][slot]=0.0;
			}

			bossHasReloadAbility[boss]=false;
			bossHasRightMouseAbility[boss]=false;
		}
		else if(IsValidClient(boss))  //Boss here is actually a client index
		{
			shield[boss]=0;
			detonations[boss]=0;
		}

		for(int timer; timer<=1; timer++)
		{
			if(BossInfoTimer[boss][timer]!=null)
			{
				delete BossInfoTimer[boss][timer];
			}
		}
	}

	if(isBossAlive && bossWin)
	{
		char bossName[64], lives[8], text[128];
		int bossindexs[MAXPLAYERS+1], bosscount=0;
		for(int target=1; target<=MaxClients; target++)
		{
			if(IsBoss(target) && BossTeam == TF2_GetClientTeam(target))
			{
				bossindexs[bosscount++]=Boss[target];
			}
		}

		SetHudTextParams(-1.0, 0.2, 10.0, 255, 255, 255, 255);
		for(int client=1; client<=MaxClients; client++)
		{
			if(IsValidClient(client) && !IsFakeClient(client))
			{
				SetGlobalTransTarget(client);
				Format(text, sizeof(text), "");

				for(int loop; loop<bosscount; loop++)
				{
					GetBossName(bossindexs[loop], bossName, sizeof(bossName), client);
					BossLives[bossindexs[loop]]>1 ? Format(lives, sizeof(lives), "x%i", BossLives[bossindexs[loop]]) : strcopy(lives, 2, "");

					if(loop == 0) {
						Format(text, sizeof(text), "%s\n%t", text, "Boss Win Final Health", bossName, Boss[bossindexs[loop]], BossHealth[bossindexs[loop]]-BossHealthMax[bossindexs[loop]]*(BossLives[bossindexs[loop]]-1), BossHealthMax[bossindexs[loop]], lives);
					}
					CPrintToChat(client, "{olive}[FF2]{default} %t", "Boss Win Final Health", bossName, Boss[bossindexs[loop]], BossHealth[bossindexs[loop]]-BossHealthMax[bossindexs[loop]]*(BossLives[bossindexs[loop]]-1), BossHealthMax[bossindexs[loop]], lives);
				}
				FF2_ShowHudText(client, FF2HudChannel_Info, "%s", text);
			}
		}
	}
	else if(!bossWin && FindSound("lose", sound, sizeof(sound), 0))
	{
		EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound);
	}


	int top[3], Damage[MAXPLAYERS+1];
	Damage[0]=0;

	// TODO: 기타 등록된 모든 엔티티를 수집하여 피해량 종합
	FF2BaseEntity baseEnt;
	for(int client=0; client<=MaxClients; client++)
	{
		if(!IsValidClient(client) || (IsBoss(client) && BossTeam == TF2_GetClientTeam(client)))
			continue;

		baseEnt = g_hBasePlayer[client];
		Damage[client] = baseEnt.Damage;

		int assist = baseEnt.Assist;
		if(assist >= 2)
			Damage[client] += assist / 2;

		if(Damage[client] <= 0)		continue;

		SetClientGlow(client, 0.0, 0.0);

		if(Damage[client]>=Damage[top[0]])
		{
			top[2]=top[1];
			top[1]=top[0];
			top[0]=client;
		}
		else if(Damage[client]>=Damage[top[1]])
		{
			top[2]=top[1];
			top[1]=client;
		}
		else if(Damage[client]>=Damage[top[2]])
		{
			top[2]=client;
		}
	}

	if(Damage[top[0]]>9000)
	{
		CreateTimer(1.0, Timer_NineThousand, _, TIMER_FLAG_NO_MAPCHANGE);
	}

	char leaders[3][32];
	for(int i; i<=2; i++)
	{
		if(IsValidClient(top[i]))
		{
			GetClientName(top[i], leaders[i], 32);
		}
		else
		{
			Format(leaders[i], 32, "---");
			top[i]=0;
		}
	}

	SetHudTextParams(-1.0, 0.3, 10.0, 255, 255, 255, 255);
	PrintCenterTextAll("");

	char text[128];  //Do not decl this
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			SetGlobalTransTarget(client);
			//TODO:  Clear HUD text here
			if(IsBoss(client))
			{
				FF2_ShowSyncHudText(client, infoHUD, "%s\n%t:\n1) %i-%s\n2) %i-%s\n3) %i-%s\n\n%t", text, "Top 3", Damage[top[0]], leaders[0], Damage[top[1]], leaders[1], Damage[top[2]], leaders[2], (bossWin ? "Boss Victory" : "Boss Defeat"));
			}
			else
			{
				FF2_ShowSyncHudText(client, infoHUD, "%s\n%t:\n1) %i-%s\n2) %i-%s\n3) %i-%s\n\n%t", text, "Top 3", Damage[top[0]], leaders[0], Damage[top[1]], leaders[1], Damage[top[2]], leaders[2], "Total Damage Dealt", Damage[client]);
			}
		}
	}

	CreateTimer(3.0, Timer_CalcQueuePoints, _, TIMER_FLAG_NO_MAPCHANGE);
	UpdateHealthBar(true);
	return Plugin_Continue;
}

public Action OnBroadcast(Event event, const char[] name, bool dontBroadcast)
{
    char sound[PLATFORM_MAX_PATH];
    event.GetString("sound", sound, sizeof(sound));
    if(!StrContains(sound, "Game.Your", false) || StrEqual(sound, "Game.Stalemate", false))
    {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action Timer_NineThousand(Handle timer)
{
	EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, "saxton_hale/9000.wav", _, SNDCHAN_VOICE, _, _, _, _, _, _, _, false);
	return Plugin_Continue;
}

public Action Timer_CalcQueuePoints(Handle timer)
{
	int damage;
	botqueuepoints+=5;
	int[] add_points=new int[MaxClients+1];
	int[] add_points2=new int[MaxClients+1];

	for(int client = 1; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			FF2BasePlayer player = GetBasePlayer(client);

			damage = player.Damage;
			Event event=CreateEvent("player_escort_score", true);
			event.SetInt("player", client);

			int points;
			while(damage-600>0)
			{
				damage-=600;
				points++;
			}
			event.SetInt("points", points);
			event.Fire();

			if(Boss[0]==client)
			{
				if(IsFakeClient(client))
				{
					botqueuepoints=0;
				}
				else
				{
					add_points[client] = -player.QueuePoints;
					add_points2[client]=add_points[client];
				}
			}
			else if(!IsFakeClient(client) && (TF2_GetClientTeam(client)>TFTeam_Spectator || SpecForceBoss))
			{
				add_points[client]=10;
				add_points2[client]=10;
			}
		}
	}

	Action action;
	Call_StartForward(OnAddQueuePoints);
	Call_PushArrayEx(add_points2, MaxClients+1, SM_PARAM_COPYBACK);
	Call_Finish(action);
	switch(action)
	{
		case Plugin_Stop, Plugin_Handled:
		{
			return Plugin_Continue;
		}
		case Plugin_Changed:
		{
			for(int client=1; client<=MaxClients; client++)
			{
				if(!IsValidClient(client)) 	continue;
				
				FF2BasePlayer player = GetBasePlayer(client);

				if(add_points2[client] > 0)
					CPrintToChat(client, "{olive}[FF2]{default} %t", "Points Earned", add_points2[client]);
				
				player.QueuePoints += add_points2[client];
			}
		}
		default:
		{
			for(int client=1; client<=MaxClients; client++)
			{
				if(!IsValidClient(client)) 	continue;

				FF2BasePlayer player = GetBasePlayer(client);

				if(add_points[client] > 0)
					CPrintToChat(client, "{olive}[FF2]{default} %t", "Points Earned", add_points[client]);
				
				player.QueuePoints += add_points[client];
			}
		}
	}

	return Plugin_Continue;
}

public Action StartResponseTimer(Handle timer)
{
	char sound[PLATFORM_MAX_PATH];
	if(FindSound("begin", sound, sizeof(sound)))
	{
		EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound);
	}
	return Plugin_Continue;
}

public Action StartBossTimer(Handle timer)
{
	CheckAlivePlayers(null);
	StartingPlayers = RedAlivePlayers;

	CreateTimer(0.1, Timer_Move, _, TIMER_FLAG_NO_MAPCHANGE);
	bool isBossAlive;

	static float firstAbilityCooldown = 8.0;

	for(int boss; boss<=MaxClients; boss++)
	{
		if(IsValidClient(Boss[boss]) && IsPlayerAlive(Boss[boss])
			&& BossTeam == TF2_GetClientTeam(Boss[boss]))
		{
			isBossAlive=true;
			// SetEntityMoveType(Boss[boss], MOVETYPE_NONE);

			BossHealthMax[boss]=ParseFormula(boss, "health", RoundFloat(Pow((1,121.2+float(RedAlivePlayers))*(float(RedAlivePlayers)-1.0), 1.0621)+3046.0));
			BossHealth[boss]=BossHealthLast[boss]=BossHealthMax[boss]*BossLivesMax[boss];

			// 초기 쿨타임
			for(int slot = 1; slot < 8; slot++)
			{
				BossCharge[boss][slot] = -firstAbilityCooldown;
			}

			// TODO: 초기 설정 함수 따로 만들어 이전
			SetEntPropFloat(Boss[boss], Prop_Send, "m_flChargeMeter", 0.0);

			TF2Attrib_AddCustomPlayerAttribute(Boss[boss], "charge recharge rate increased", 0.0, firstAbilityCooldown);
		}
	}

	if(!isBossAlive)
	{
		return Plugin_Continue;
	}

	playing=0;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && !IsBoss(client) && IsPlayerAlive(client))
		{
			playing++;
			FF2BaseEntity player = g_hBasePlayer[client];
			CreateTimer(0.15, MakeNotBoss, player, TIMER_FLAG_NO_MAPCHANGE);  //TODO:  Is this needed?
		}
	}

	CorrectionBossHealth();

	CreateTimer(0.1, BossTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.2, StartRound, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.2, ClientTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(2.0, Timer_PrepareBGM_Delayed, 0, TIMER_FLAG_NO_MAPCHANGE);

	if(!PointType)
	{
		SetControlPoint(false);
	}
	return Plugin_Continue;
}

public any GetSettingData(int client, const char[] settingId, DBSDataTypes type)
{
	char data[128];
	GetSettingStringData(client, settingId, data, 128);

	switch(type)
	{
		case DBSData_Int:
		{
			return data[0] != '\0' ? StringToInt(data) : 0;
		}
		case DBSData_Float:
		{
			return data[0] != '\0' ? StringToFloat(data) : 0.0;
		}
		default:
		{
			ThrowError("only DBSData_Int, DBSData_Float supported!");
		}
	}

	return -1;
}

public any Native_GetSettingData(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	char settingId[128];
	GetNativeString(2, settingId, sizeof(settingId));
	DBSDataTypes type = GetNativeCell(3);

	return GetSettingData(client, settingId, type);
}

public void GetSettingStringData(int client, const char[] settingId, char[] value, int buffer)
{
    FF2DB_GetSettingString(client, settingId, value, buffer);
}

public int Native_GetSettingStringData(Handle plugin, int numParams)
{
	int client = GetNativeCell(1), buffer = GetNativeCell(4);
	char settingId[128], value[128];
	GetNativeString(2, settingId, sizeof(settingId));

	GetSettingStringData(client, settingId, value, buffer);
	SetNativeString(3, value, sizeof(value));

	return 0; // ??
}

public void SetSettingData(int client, const char[] settingId, any value, DBSDataTypes type)
{
	// (DBSPlayerData.GetClientData(client)).SetData(FF2DATABASE_CONFIG_NAME, FF2_DB_PLAYERDATA_TABLENAME, settingId, "value", value);
	char data[128];

	switch(type)
	{
		case DBSData_Int:
		{
			Format(data, sizeof(data), "%d", value);
		}
		case DBSData_Float:
		{
			Format(data, sizeof(data), "%.1f", value);
		}
		default:
		{
			ThrowError("KvData_Int, KvData_Float supported!");
		}
	}

	SetSettingStringData(client, settingId, data);
}

public /*void*/int Native_SetSettingData(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	char settingId[128];
	GetNativeString(2, settingId, sizeof(settingId));
	DBSDataTypes type = GetNativeCell(4);

	SetSettingData(client, settingId, GetNativeCellRef(3), type);
	return 0;
}

public void SetSettingStringData(int client, const char[] settingId, char[] value)
{
    FF2DB_SetSettingString(client, settingId, value);
}

public /*void*/int Native_SetSettingStringData(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	char settingId[128], value[128];
	GetNativeString(2, settingId, sizeof(settingId));

	SetSettingStringData(client, settingId, value);
	SetNativeString(3, value, sizeof(value));

	return 0;
}

public Action Timer_Move(Handle timer)
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && IsPlayerAlive(client))
		{
			SetEntityMoveType(client, MOVETYPE_WALK);
		}
	}

	return Plugin_Continue;
}

public Action StartRound(Handle timer)
{
	CreateTimer(10.0, Timer_NextBossPanel, _, TIMER_FLAG_NO_MAPCHANGE);
	UpdateHealthBar(true);

	CreateTimer(6.5, Timer_StartDrawGame, _, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Handled;
}

public Action Timer_StartDrawGame(Handle timer)
{
	int bosscount=0, playerCount=0;

	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && IsPlayerAlive(client))
		{
			playerCount++;

			if(IsBoss(client))
				bosscount++;
		}
	}

	timeType=cvarTimerType.IntValue;
	switch(timeType)
	{
		case FF2Timer_RoundTimer:
		{
			timeleft = (bosscount * 40.0) + (playerCount * 30.0)
				+ 30.0;
		}
		case FF2Timer_WaveTimer:
		{
			maxTime = 30.0 + (playerCount > 18 ? float(playerCount-18) : 0.0), timeleft = maxTime;
			maxWave = 6 + (playerCount > 18 ? 18 : playerCount);
			currentWave = 1;
		}
		default:
		{
			timeleft = -1.0;
		}
	}

	CreateTimer(0.1, Timer_DrawGame, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

void CorrectionBossHealth()
{
	int boss;
	for(int client = 1; client <= MaxClients; client++)
	{
		if(!IsValidClient(client) || !IsPlayerAlive(client)
			|| (boss = GetBossIndex(client)) == -1)
			continue;
		
		Action temp = Plugin_Continue;
		float multiplier = 1.0, multiplier2 = 1.0;

		Call_StartForward(OnApplyBossHealthCorrection);
		Call_PushCell(boss);
		Call_PushFloatRef(multiplier2);
		Call_Finish(temp);

		if(temp != Plugin_Changed)
			continue;

		multiplier = multiplier2;

		int heal = RoundFloat(BossHealthMax[boss] * (multiplier - 1.0));
		// BossHealth[boss] += heal;
		BossHealthMax[boss] += (heal / BossLivesMax[boss]) - (BossLivesMax[boss] - 1); 
		BossHealth[boss] = BossHealthMax[boss] * BossLivesMax[boss];
	}
}

public Action Timer_NextBossPanel(Handle timer)
{
	int clients;
	bool[] added=new bool[MaxClients+1];
	while(clients<3)  //TODO: Make this configurable?
	{
		int client=GetClientWithMostQueuePoints(added);
		if(!IsValidClient(client))  //No more players left on the server
		{
			break;
		}

		if(!IsBoss(client))
		{
			CPrintToChat(client, "{olive}[FF2]{default} %t", "Next Boss");  //"You will become the Boss soon. Type {olive}/ff2next{default} to make sure."
			clients++;
		}
		added[client]=true;
	}

	return Plugin_Continue;
}

public Action MessageTimer(Handle timer)
{
	if(CheckRoundState()!=FF2RoundState_Setup)
	{
		return Plugin_Continue;
	}

	if(checkDoors)
	{
		int entity=-1;
		while((entity=FindEntityByClassname2(entity, "func_door"))!=-1)
		{
			AcceptEntityInput(entity, "Open");
			AcceptEntityInput(entity, "Unlock");
		}

		if(doorCheckTimer==null)
		{
			doorCheckTimer=CreateTimer(5.0, Timer_CheckDoors, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	SetHudTextParams(-1.0, 0.2, 10.0, 255, 255, 255, 255);
	char text[512], textChat[512], lives[8], name[64];  //Do not decl this
	int bossindexs[MAXPLAYERS+1], bosscount=0;

	for(int client=1; client<=MaxClients; client++)
	{
		if(IsBoss(client) && TF2_GetClientTeam(client) == BossTeam)
		{
			bossindexs[bosscount++]=Boss[client];
		}
	}

	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && !IsFakeClient(client))
		{
			SetGlobalTransTarget(client);
			Format(text, sizeof(text), "");

			for(int loop; loop<bosscount; loop++)
			{
				GetBossName(bossindexs[loop], name, sizeof(name), client);
				if(BossLives[bossindexs[loop]]>1)
				{
					Format(lives, sizeof(lives), "x%i", BossLives[bossindexs[loop]]);
				}
				else
				{
					strcopy(lives, 2, "");
				}

				Format(text, sizeof(text), "%s\n%t", text, "Boss Info", Boss[bossindexs[loop]], name, BossHealth[bossindexs[loop]]-BossHealthMax[bossindexs[loop]]*(BossLives[bossindexs[loop]]-1), lives);
				Format(textChat, sizeof(textChat), "{olive}[FF2]{default} %t!", "Boss Info", Boss[bossindexs[loop]], name, BossHealth[bossindexs[loop]]-BossHealthMax[bossindexs[loop]]*(BossLives[bossindexs[loop]]-1), lives);
				ReplaceString(textChat, sizeof(textChat), "\n", "");  //Get rid of newlines
				CPrintToChat(client, "%s", textChat);
			}

			FF2_ShowSyncHudText(client, infoHUD, text);
		}
	}
	return Plugin_Continue;
}

public Action MakeModelTimer(Handle timer, int boss)
{
	int client=Boss[boss];
	if(IsValidClient(client) && IsPlayerAlive(client) && CheckRoundState()!=FF2RoundState_RoundEnd)
	{
		char model[PLATFORM_MAX_PATH];
		KeyValues bossKv = GetCharacterKV(character[boss]);
		bossKv.Rewind();
		bossKv.GetString("model", model, sizeof(model));
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

void EquipBoss(int boss)
{
	KeyValues kv = GetCharacterKV(character[boss]);
	char classname[64], attributes[256], oneAttrib[40][10], bossName[64];
	int client=Boss[boss];

	bool initCaptureAttribute = false;
	char captureAttributeStr[64] = "252 ; 0.8 ; 68 ; %i ; "; // 68: +2 cap rate, 252: knockback scale, 259: goomba

	TF2Attrib_RemoveAll(client);
	TF2_RemoveAllWeapons(client);
	TF2_RemoveAllWearables(client);

	Format(captureAttributeStr, 64, captureAttributeStr, TF2_GetPlayerClass(client)==TFClass_Scout ? 1 : 2);

	kv.Rewind();
	kv.GetString("name", bossName, sizeof(bossName), "=Failed Name=");
	if(kv.JumpToKey("weapons"))
	{
		kv.GotoFirstSubKey();
		do
		{
			char sectionName[32];
			kv.GetSectionName(sectionName, sizeof(sectionName));
			int index=StringToInt(sectionName);

			//NOTE: StringToInt returns 0 on failure which corresponds to tf_weapon_bat,
			//so there's no way to distinguish between an invalid string and 0.
			//Blocked on bug 6438: https://bugs.alliedmods.net/show_bug.cgi?id=6438

			if(index>=0)
			{
				kv.JumpToKey(sectionName);
				kv.GetString("classname", classname, sizeof(classname));
				if(classname[0]=='\0')
				{
					LogError("[FF2 Bosses] No classname specified for weapon %i (character %s)!", index, bossName);
					continue;
				}

				int weapon = -1;
				kv.GetString("attributes", attributes, sizeof(attributes));

				if(StrContains(classname, "tf_wearable") != -1)
				{
					bool demoshield = StrEqual(classname, "tf_wearable_demoshield");
					weapon = demoshield ? TF2_SpawnDemoShield(index, 5, 101) : TF2_SpawnWearable(index, 5, 101);

					TF2Attrib_RemoveAll(weapon); // This is not working on demoshield
					TF2Util_EquipPlayerWearable(client, weapon);

					int attributeCount = ExplodeString(attributes, ";", oneAttrib, sizeof(oneAttrib), sizeof(oneAttrib[]));
					if(attributes[0] != '\0')
					{
						if(attributeCount % 2 != 0)
							ThrowError("%s is not valid!", attributes);

						for(int loop = 0; loop < attributeCount; loop += 2)
						{
							int attribIndex = StringToInt(oneAttrib[loop]);
							float temp = StringToFloat(oneAttrib[loop + 1]);
							Address itemAddress = TF2Attrib_GetByDefIndex(weapon, attribIndex);

							if(itemAddress != Address_Null)
								TF2Attrib_RemoveByDefIndex(weapon, attribIndex);

							TF2Attrib_SetByDefIndex(weapon, attribIndex, temp);
						}
					}

					// 데모쉴드인 경우에만 사용
					if(demoshield)
						SetEntProp(client, Prop_Send, "m_bShieldEquipped", 1);
				}
				else
				{
					if(attributes[0]!='\0')
					{
						Format(attributes, sizeof(attributes), "%s2 ; 3.1 ; %s", !initCaptureAttribute ? captureAttributeStr : "", attributes);
							//2: x3.1 damage
					}
					else
					{
						Format(attributes, sizeof(attributes), "%s2 ; 3.1", !initCaptureAttribute ? captureAttributeStr : "");
							//2: x3.1 damage
					}

					weapon=SpawnWeapon(client, classname, index, 101, 5, attributes);
					if(StrEqual(classname, "tf_weapon_builder", false) && index!=735)  //PDA, normal sapper
					{
						SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 0);
						SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 1);
						SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 2);
						SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 3);
					}
					else if(StrEqual(classname, "tf_weapon_sapper", false) || index==735)  //Sappers
					{
						SetEntProp(weapon, Prop_Send, "m_iObjectType", 3);
						SetEntProp(weapon, Prop_Data, "m_iSubType", 3);
						SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 0);
						SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 1);
						SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 2);
						SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 3);
					}

					// 무기의 투사체 모델 적용
					char model[PLATFORM_MAX_PATH];
					kv.GetString("projectile model", model, sizeof(model));
					if(model[0] != '\0')
					{
						if(!IsModelPrecached(model))
							PrecacheModel(model);
						TF2Attrib_SetFromStringValue(weapon, "custom projectile model", model);
					}

					SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
					initCaptureAttribute = true;

					// FIXME: 본래의 병과가 아닌 다른 무기를 든 경우 산정이 이상하게 됨.
					int ammoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
					if(ammoType != -1)
					{
						int maxAmmo = SDKCall_GetMaxAmmo(client, ammoType, view_as<int>(TF2_GetPlayerClass(client)));
						SetEntProp(client, Prop_Data, "m_iAmmo", maxAmmo, _, ammoType);
					}
				}

				if(!kv.GetNum("show", 0))
				{
					if(HasEntProp(weapon, Prop_Send, "m_iWorldModelIndex"))
						SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", -1);
					SetEntPropFloat(weapon, Prop_Send, "m_flModelScale", 0.001);
				}
			}
			else
			{
				LogError("[FF2 Bosses] Invalid weapon index %s specified for character %s!", sectionName, bossName);
			}
		}
		while(kv.GotoNextKey());
	}

	kv.Rewind();
	TFClassType playerclass=view_as<TFClassType>(kv.GetNum("class", 1));
	if(TF2_GetPlayerClass(client)!=playerclass)
	{
		TF2_SetPlayerClass(client, playerclass, _, !GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass") ? true : false);
	}
}

public Action MakeBoss(Handle timer, int boss)
{
	int client=Boss[boss];
	if(!IsValidClient(client) || CheckRoundState()==FF2RoundState_Loading)
		return Plugin_Continue;

	FF2BaseEntity player = g_hBasePlayer[client];

	if(!IsPlayerAlive(client))
		TF2_RespawnPlayer(client);

	KeyValues kv=GetCharacterKV(character[boss]);
	kv.Rewind();

	BossHealthMax[boss]=ParseFormula(boss, "health", RoundFloat(Pow((760.8+float(RedAlivePlayers))*(float(RedAlivePlayers)-1.0), 1.0341)+2046.0));
	BossLivesMax[boss]=BossLives[boss]=ParseFormula(boss, "lives", 1);
	BossHealth[boss]=BossHealthLast[boss]=BossHealthMax[boss]*BossLivesMax[boss];
	BossRageDamage[boss]=ParseFormula(boss, "rage damage", 1900);
	BossMaxRageCharge[boss] = kv.GetFloat("rage max charge", 100.0);
	BossSpeed[boss]=float((ParseFormula(boss, "speed", 340)));

	for(int slot = 0; slot < 8; slot++)
	{
		BossCharge[boss][slot] = 0.0;
		if(slot < 3)
			BossSkillDuration[boss][slot] = 0.0;
	}

	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
	TF2_RemovePlayerDisguise(client);
	TF2_SetPlayerClass(client, view_as<TFClassType>(kv.GetNum("class", 1)), _, !GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass") ? true : false);
	SDKHook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);  //Temporary:  Used to prevent boss overheal

	switch(kv.GetNum("pickups", 0))  //Check if the boss is allowed to pickup health/ammo
	{
		case 1:
		{
			player.Flags |= FF2FLAG_ALLOW_HEALTH_PICKUPS;
		}
		case 2:
		{
			player.Flags |= FF2FLAG_ALLOW_AMMO_PICKUPS;
		}
		case 3:
		{
			player.Flags |= FF2FLAG_ALLOW_HEALTH_PICKUPS|FF2FLAG_ALLOW_AMMO_PICKUPS;
		}
	}

	CreateTimer(0.2, MakeModelTimer, boss, TIMER_FLAG_NO_MAPCHANGE);
	if(!IsFakeClient(client) && !IsVoteInProgress() && GetClientClassInfoCookie(client) != 1)
	{
		HelpPanelBoss(client, boss);
	}

	if(!IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}

	int entity=-1;
	while((entity=FindEntityByClassname2(entity, "tf_wear*"))!=-1)
	{
		if(IsBoss(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")))
		{
			switch(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"))
			{
				case 493, 233, 234, 241, 280, 281, 282, 283, 284, 286, 288, 362, 364, 365, 536, 542, 577, 599, 673, 729, 791, 839, 5607:  //Action slot items
				{
					//NOOP
				}
				default:
				{
					TF2_RemoveWearable(client, entity);
				}
			}
		}
	}

	entity=-1;
	while((entity=FindEntityByClassname2(entity, "tf_powerup_bottle"))!=-1)
	{
		if(IsBoss(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")))
		{
			TF2_RemoveWearable(client, entity);
		}
	}

	EquipBoss(boss);
	KSpreeCount[boss]=0;
	BossCharge[boss][0]=0.0;

	for(int loop = 0; loop < 3; loop++)
	{
		BossSkillDuration[boss][loop] = 0.0;
	}

	if(MaxClients >= client && Boss[0] == client)
		view_as<FF2BasePlayer>(player).QueuePoints = 0;

	Call_StartForward(OnPlayBoss);
	Call_PushCell(boss);
	Call_Finish();

	return Plugin_Continue;
}


public Action MakeNotBoss(Handle timer, FF2BaseEntity player)
{
	int client = EntRefToEntIndex(player.Ref);

	if(!IsValidClient(client) || !IsPlayerAlive(client)
		|| CheckRoundState()==FF2RoundState_RoundEnd
		|| IsBoss(client) || (player.Flags & FF2FLAG_ALLOWSPAWNINBOSSTEAM)
	)
		return Plugin_Continue;

	if(!IsFakeClient(client) && CheckRoundState() == FF2RoundState_Setup
		&& !IsVoteInProgress() && !(player.Flags & FF2FLAG_CLASSHELPED))
	{
		if(!GetClientClassInfoCookie(client))
			HelpPanelClass(client);
		else if(GetClientClassInfoCookie(client) == 2)
			HelpPanelBoss(client, GetBossIndex(Boss[0]));
	}

	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);  //This really shouldn't be needed but I've been noticing players who still have glow

	SetEntityHealth(client, GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client)); //Temporary: Reset health to avoid an overheal bug
	if(TF2_GetClientTeam(client)==BossTeam)
	{
		AssignTeam(client, OtherTeam);
	}

	CreateTimer(0.1, CheckItems, player, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action CheckItems(Handle timer, FF2BaseEntity player)
{
	int client = EntRefToEntIndex(player.Ref);
	if(!IsValidClient(client) || !IsPlayerAlive(client)
		|| CheckRoundState()==FF2RoundState_RoundEnd
		|| IsBoss(client) || (player.Flags & FF2FLAG_ALLOWSPAWNINBOSSTEAM))
		return Plugin_Continue;

	SetEntityRenderColor(client, 255, 255, 255, 255);
	shield[client]=0;
	int index=-1;
	int[] civilianCheck=new int[MaxClients+1];

	//Cloak and Dagger is NEVER allowed, even in Medieval mode
	int weapon=GetPlayerWeaponSlot(client, 4);

	if(bMedieval)
	{
		return Plugin_Continue;
	}

	for(int slot = TFWeaponSlot_Primary; slot <= TFWeaponSlot_Melee; slot++)
	{
		weapon = GetPlayerWeaponSlot(client, slot);
		if(IsValidEntity(weapon))
		{
			index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
			switch(index)
			{
			}

			if(TF2_GetPlayerClass(client) == TFClass_Medic)
			{
				if(GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 142)  //Gunslinger (Randomizer, etc. compatability)
				{
					SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
					SetEntityRenderColor(weapon, 255, 255, 255, 75);
				}
			}
		}
		else
		{
			civilianCheck[client]++;
		}
	}


	int playerBack=FindPlayerBack(client, 57);  //Razorback
	shield[client]=IsValidEntity(playerBack) ? playerBack : 0;

	// TODO: 이 구문 삭제
	if(IsValidEntity(FindPlayerBack(client, 444)))  //Mantreads
	{
		TF2Attrib_SetByDefIndex(client, 58, 1.5);  //+50% increased push force
	}
	else
	{
		TF2Attrib_RemoveByDefIndex(client, 58);
	}

	TF2Attrib_RemoveByDefIndex(client, 252); // NOTE: 보스 넉백 저항

	int entity=-1;
	while((entity=FindEntityByClassname2(entity, "tf_wearable_demoshield"))!=-1)  //Demoshields
	{
		if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
		{
			shield[client]=entity;
		}
	}

	if(civilianCheck[client]==3)
	{
		civilianCheck[client]=0;
		Debug("Respawning %N to avoid civilian bug", client);
		TF2_RespawnPlayer(client);
	}
	civilianCheck[client]=0;
	return Plugin_Continue;
}

public Action OnObjectDestroyed(Event event, const char[] name, bool dontBroadcast)
{
	if(Enabled)
	{
		int attacker=GetClientOfUserId(event.GetInt("attacker"));
		if(!GetRandomInt(0, 2) && IsBoss(attacker))
		{
			int boss=GetBossIndex(attacker);
			char sound[PLATFORM_MAX_PATH];

			if(FindSound("destroy building", sound, sizeof(sound), boss))
			{
				EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound);
			}
		}
	}
	return Plugin_Continue;
}

public Action OnUberDeployed(Event event, const char[] name, bool dontBroadcast)
{
	int client=GetClientOfUserId(event.GetInt("userid"));
	if(Enabled && IsValidClient(client) && IsPlayerAlive(client))
	{
		int medigun=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(IsValidEntity(medigun))
		{
			char classname[64];
			GetEntityClassname(medigun, classname, sizeof(classname));
			if(StrEqual(classname, "tf_weapon_medigun"))
			{
				TF2_AddCondition(client, TFCond_HalloweenCritCandy, 0.5, client);
				TF2_AddCondition(client, TFCond_Ubercharged, 0.5);
				int target=GetHealingTarget(client);
				if(IsValidClient(target, false) && IsPlayerAlive(target))
				{
					TF2_AddCondition(target, TFCond_HalloweenCritCandy, 0.5, client);
					uberTarget[client]=target;
				}
				else
				{
					uberTarget[client]=-1;
				}
				CreateTimer(0.4, Timer_Uber, EntIndexToEntRef(medigun), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	return Plugin_Continue;
}

public Action Timer_Uber(Handle timer, int medigunid)
{
	int medigun=EntRefToEntIndex(medigunid);
	if(medigun && IsValidEntity(medigun) && CheckRoundState()==FF2RoundState_RoundRunning && GetEntProp(medigun, Prop_Send, "m_bChargeRelease")>0)
	{
		int client=GetEntPropEnt(medigun, Prop_Send, "m_hOwnerEntity");
		float charge=GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel");
		if(IsValidClient(client, false) && IsPlayerAlive(client) && GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon")==medigun)
		{
			int target=GetHealingTarget(client);
			if(charge>0.05)
			{
				TF2_AddCondition(client, TFCond_HalloweenCritCandy, 0.5);
				if(IsValidClient(target, false) && IsPlayerAlive(target))
				{
					TF2_AddCondition(target, TFCond_HalloweenCritCandy, 0.5);
					uberTarget[client]=target;
				}
				else
				{
					uberTarget[client]=-1;
				}
			}
			else
			{
				return Plugin_Stop;
			}
		}
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action Command_GetHPCmd(int client, int args)
{
	if(!IsValidClient(client) || !Enabled || CheckRoundState()!=FF2RoundState_RoundRunning)
	{
		return Plugin_Continue;
	}

	Command_GetHP(client);
	return Plugin_Handled;
}

public Action Command_GetHP(int client)  //TODO: This can rarely show a very large negative number if you time it right
{
	if(IsBoss(client) || GetGameTime()>=HPTime)
	{
		char text[512];  //Do not decl this
		char lives[8], name[64];
		int bossindexs[MAXPLAYERS+1], bosscount=0;

		for(int target=1; target<=MaxClients; target++)
		{
			if(IsBoss(target) && BossTeam == TF2_GetClientTeam(target))
			{
				bossindexs[bosscount++]=Boss[target];
				BossHealthLast[bossindexs[bosscount]]=BossHealth[bossindexs[bosscount]]-BossHealthMax[bossindexs[bosscount]]*(BossLives[bossindexs[bosscount]]-1);
			}
		}

		for(int target=1; target<=MaxClients; target++)
		{
			if(IsValidClient(target) && !IsFakeClient(target) && !(FF2Flags[target] & FF2FLAG_HUDDISABLED))
			{
				SetGlobalTransTarget(target);
				Format(text, sizeof(text), "");

				for(int loop; loop<bosscount; loop++)
				{
					GetBossName(bossindexs[loop], name, sizeof(name), target);
					if(BossLives[bossindexs[loop]]>1)
					{
						Format(lives, sizeof(lives), "x%i", BossLives[bossindexs[loop]]);
					}
					else
					{
						strcopy(lives, 2, "");
					}
					Format(text, sizeof(text), "%s\n%t", text, "Boss Current Health", name, BossHealthLast[bossindexs[loop]], BossHealthMax[bossindexs[loop]], lives);
					CPrintToChat(target, "{olive}[FF2]{default} %t", "Boss Current Health", name, BossHealthLast[bossindexs[loop]], BossHealthMax[bossindexs[loop]], lives);
				}
				PrintCenterText(target, text);
			}
		}

		if(GetGameTime()>=HPTime)
		{
			healthcheckused++;
			HPTime=GetGameTime()+(healthcheckused<3 ? 20.0 : 80.0);
		}
		return Plugin_Continue;
	}

	if(RedAlivePlayers>1)
	{
		char waitTime[128];
		for(int target=1; target<=MaxClients; target++)
		{
			if(IsBoss(target))
			{
				Format(waitTime, sizeof(waitTime), "%s %i,", waitTime, BossHealthLast[Boss[target]]);
			}
		}
		CPrintToChat(client, "{olive}[FF2]{default} %t", "Wait for Health Value", RoundFloat(HPTime-GetGameTime()), waitTime);
	}
	return Plugin_Continue;
}

public Action Command_SetNextBoss(int client, int args)
{
	char name[64], boss[64];

	if(args<1)
	{
		CReplyToCommand(client, "{olive}[FF2]{default} Usage: ff2_special <boss>");
		return Plugin_Handled;
	}
	GetCmdArgString(name, sizeof(name));

	for(int config; config < bossesArray.Length; config++)
	{
		KeyValues kv = bossesArray.Get(config);
		kv.Rewind();
		kv.GetString("name", boss, sizeof(boss));
		if(StrContains(boss, name, false)!=-1)
		{
			Incoming[0]=config;
			CReplyToCommand(client, "{olive}[FF2]{default} Set the next boss to %s", boss);
			return Plugin_Handled;
		}

		kv.GetString("filename", boss, sizeof(boss));
		if(StrContains(boss, name, false)!=-1)
		{
			Incoming[0]=config;
			kv.GetString("name", boss, sizeof(boss));
			CReplyToCommand(client, "{olive}[FF2]{default} Set the next boss to %s", boss);
			return Plugin_Handled;
		}
	}
	CReplyToCommand(client, "{olive}[FF2]{default} Boss could not be found!");
	return Plugin_Handled;
}

public Action Command_Points(int client, int args)
{
	if(!Enabled2)
	{
		return Plugin_Continue;
	}

	if(args!=2)
	{
		CReplyToCommand(client, "{olive}[FF2]{default} Usage: ff2_addpoints <target> <points>");
		return Plugin_Handled;
	}

	char stringPoints[8];
	char pattern[PLATFORM_MAX_PATH];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, stringPoints, sizeof(stringPoints));
	int points=StringToInt(stringPoints);

	char targetName[MAX_TARGET_LENGTH];
	int targets[MAXPLAYERS], matches;
	bool targetNounIsMultiLanguage;

	if((matches=ProcessTargetString(pattern, client, targets, sizeof(targets), 0, targetName, sizeof(targetName), targetNounIsMultiLanguage))<=0)
	{
		ReplyToTargetError(client, matches);
		return Plugin_Handled;
	}

	if(matches>1)
	{
		for(int target = 1; target < matches; target++)
		{
			FF2BasePlayer player = GetBasePlayer(targets[target]);
			if(!IsClientSourceTV(targets[target]) && !IsClientReplay(targets[target]))
			{
				player.QueuePoints += points;
				LogAction(client, targets[target], "\"%L\" added %d queue points to \"%L\"", client, points, targets[target]);
			}
		}
	}
	else
	{
		FF2BasePlayer player = GetBasePlayer(targets[0]);
		player.QueuePoints += points;
		LogAction(client, targets[0], "\"%L\" added %d queue points to \"%L\"", client, points, targets[0]);
	}
	CReplyToCommand(client, "{olive}[FF2]{default} Added %d queue points to %s", points, targetName);
	return Plugin_Handled;
}

public Action Command_StartMusic(int client, int args)
{
	if(Enabled2)
	{
		if(args)
		{
			char pattern[MAX_TARGET_LENGTH];
			GetCmdArg(1, pattern, sizeof(pattern));
			char targetName[MAX_TARGET_LENGTH];
			int targets[MAXPLAYERS], matches;
			bool targetNounIsMultiLanguage;
			if((matches=ProcessTargetString(pattern, client, targets, sizeof(targets), COMMAND_FILTER_NO_BOTS, targetName, sizeof(targetName), targetNounIsMultiLanguage))<=0)
			{
				ReplyToTargetError(client, matches);
				return Plugin_Handled;
			}

			if(matches>1)
			{
				for(int target=1; target<matches; target++)
				{
					StartMusic(targets[target], true);
				}
			}
			else
			{
				StartMusic(targets[0], true);
			}
			CReplyToCommand(client, "{olive}[FF2]{default} Started boss music for %s.", targetName);
		}
		else
		{
			StartMusic(_, true);
			CReplyToCommand(client, "{olive}[FF2]{default} Started boss music for all clients.");
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Command_StopMusic(int client, int args)
{
	if(Enabled2)
	{
		if(args)
		{
			char pattern[MAX_TARGET_LENGTH];
			GetCmdArg(1, pattern, sizeof(pattern));
			char targetName[MAX_TARGET_LENGTH];
			int targets[MAXPLAYERS], matches;
			bool targetNounIsMultiLanguage;
			if((matches=ProcessTargetString(pattern, client, targets, sizeof(targets), COMMAND_FILTER_NO_BOTS, targetName, sizeof(targetName), targetNounIsMultiLanguage))<=0)
			{
				ReplyToTargetError(client, matches);
				return Plugin_Handled;
			}

			if(matches>1)
			{
				for(int target=1; target<matches; target++)
				{
					StopMusic(targets[target], true);
				}
			}
			else
			{
				StopMusic(targets[0], true);
			}
			CReplyToCommand(client, "{olive}[FF2]{default} Stopped boss music for %s.", targetName);
		}
		else
		{
			StopMusic(_, true);
			CReplyToCommand(client, "{olive}[FF2]{default} Stopped boss music for all clients.");
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Command_Charset(int client, int args)
{
	if(!args)
	{
		CReplyToCommand(client, "{olive}[FF2]{default} Usage: ff2_charset <charset>");
		return Plugin_Handled;
	}

	char charset[32], rawText[16][16];
	GetCmdArgString(charset, sizeof(charset));
	int amount=ExplodeString(charset, " ", rawText, 16, 16);
	for(int i; i<amount; i++)
	{
		StripQuotes(rawText[i]);
	}
	ImplodeStrings(rawText, amount, " ", charset, sizeof(charset));

	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", FF2_SETTINGS, BOSS_CONFIG);

	KeyValues Kv=new KeyValues("");
	Kv.ImportFromFile(config);
	for(int i; ; i++)
	{
		Kv.GetSectionName(config, sizeof(config));
		if(StrContains(config, charset, false)>=0)
		{
			CReplyToCommand(client, "{olive}[FF2]{default} Charset for nextmap is %s", config);
			isCharSetSelected=true;
			FF2CharSet=i;
			break;
		}

		if(!Kv.GotoNextKey())
		{
			CReplyToCommand(client, "{olive}[FF2]{default} Charset not found");
			break;
		}
	}
	delete Kv;
	return Plugin_Handled;
}

public Action Command_ReloadSubPlugins(int client, int args)
{
	if(Enabled)
		ReloadSubPlugins();

	CReplyToCommand(client, "{olive}[FF2]{default} Reloaded subplugins!");
	return Plugin_Handled;
}

void ReloadSubPlugins()
{
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "plugins/%s", FF2_SUBPLUGIN_ROOT_PATH);

	ReloadSubPluginFolder(OpenDirectory(path), FF2_SUBPLUGIN_ROOT_PATH);
}

void ReloadSubPluginFolder(DirectoryListing directory, char[] folderPath)
{
	if(directory == null)		return;

	FileType filetype;
	char filename[PLATFORM_MAX_PATH];

	while(directory.GetNext(filename, sizeof(filename), filetype))
	{
		if(filetype == FileType_Directory)
		{
			if(StrEqual(filename, ".") || StrEqual(filename, ".."))
				continue;

			char path[PLATFORM_MAX_PATH], newFolderPath[PLATFORM_MAX_PATH];
			Format(newFolderPath, sizeof(newFolderPath), "%s/%s", folderPath, filename);
			BuildPath(Path_SM, path, sizeof(path), "plugins/%s", newFolderPath);
			ReloadSubPluginFolder(OpenDirectory(path), newFolderPath);			
		}
		else if(filetype == FileType_File && StrContains(filename, ".smx", false) != -1)
		{
			ServerCommand("sm plugins unload %s/%s", folderPath, filename);
			ServerCommand("sm plugins load %s/%s", folderPath, filename);
		}
	}
}

public Action Command_Point_Disable(int client, int args)
{
	if(Enabled)
	{
		SetControlPoint(false);
	}
	return Plugin_Handled;
}

public Action Command_Point_Enable(int client, int args)
{
	if(Enabled)
	{
		SetControlPoint(true);
	}
	return Plugin_Handled;
}

public void OnClientPostAdminCheck(int client)
{
    SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
    Goomba_OnClientPutInServer(client);

    uberTarget[client]=-1;

    g_hBasePlayer[client] = new FF2BasePlayer(client);
    PlayerHudQueue[client] = FF2HudQueue.CreateHudQueue("Player");

    if(!IsFakeClient(client))
    {
        FF2DB_LoadPlayerData(client);
        muteSound[client]=FF2DB_GetSettingInt(client, "sound_mute_flag");

        // Cookie에서 대기표 복원
        view_as<FF2BasePlayer>(g_hBasePlayer[client]).LoadQueuePointsFromCookie();
    }

    if(playBGM[0])
    {
        playBGM[client]=true;
        if(Enabled)
        {
            StartMusic(client, true);
        }
    }
    else
    {
        playBGM[client]=false;
    }
}

public void OnClientCookiesCached(int client)
{
    if(g_hBasePlayer[client] != null && !IsFakeClient(client))
    {
        view_as<FF2BasePlayer>(g_hBasePlayer[client]).LoadQueuePointsFromCookie();
    }
}

public void OnClientDisconnect(int client)
{
    if(Enabled)
    {
        if(IsBoss(client) && !CheckRoundState() && cvarPreroundBossDisconnect.BoolValue)
        {
            int boss=GetBossIndex(client);
            bool[] omit=new bool[MaxClients+1];
            omit[client]=true;
            Boss[boss]=GetClientWithMostQueuePoints(omit);

            if(Boss[boss])
            {
                TF2_ChangeClientTeam(Boss[boss], BossTeam);
                CreateTimer(0.1, MakeBoss, boss, TIMER_FLAG_NO_MAPCHANGE);
                CPrintToChat(Boss[boss], "{olive}[FF2]{default} %t", "Replace Disconnected Boss");
                CPrintToChatAll("{olive}[FF2]{default} %t", "Boss Disconnected", client, Boss[boss]);
            }
        }

        if(IsClientInGame(client) && IsPlayerAlive(client) && CheckRoundState()==FF2RoundState_RoundRunning)
        {
            CreateTimer(0.1, CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
        }
        
        g_flSpyCloakDamageMultiplier[client] = 1.0;
    }

    // ✅ IsFakeClient 체크를 여기로 이동
    if(IsFakeClient(client))
        return;

    PrintToServer("[FF2] ========================================");
    PrintToServer("[FF2] %N 접속 종료", client);
    
    // SQLite 캐시 정리 (설정은 변경 시 즉시 저장됨)
    FF2DB_OnClientDisconnect(client);
    
    PrintToServer("[FF2] ========================================");

    if(MusicTimer[client]!=null)
        delete MusicTimer[client];

    // 대기표 cookie 저장 후 삭제
    if(g_hBasePlayer[client] != null)
    {
        view_as<FF2BasePlayer>(g_hBasePlayer[client]).SaveQueuePointsToCookie(client);
        delete g_hBasePlayer[client];
    }

    delete PlayerHudQueue[client];
    g_flZatoichiDrawTime[client] = 0.0;
    
    // ✅ 크리츠크릭 타이머 정리
    if(KritzTimer[client] != INVALID_HANDLE)
    {
        KillTimer(KritzTimer[client]);
        KritzTimer[client] = INVALID_HANDLE;
    }
}

public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidClient(client))
		Goomba_OnPlayerSpawn(client);

	if(Enabled && CheckRoundState()==FF2RoundState_RoundRunning)
	{
		CreateTimer(0.1, CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action OnPostInventoryApplication(Event event, const char[] name, bool dontBroadcast)
{
	if(!Enabled)
		return Plugin_Continue;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsValidClient(client))
		return Plugin_Continue;

	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");

	if(IsBoss(client))
		CreateTimer(0.1, MakeBoss, GetBossIndex(client), TIMER_FLAG_NO_MAPCHANGE);

	FF2BaseEntity player = g_hBasePlayer[client];
	if(!(player.Flags & FF2FLAG_ALLOWSPAWNINBOSSTEAM))
	{
		if(!(player.Flags & FF2FLAG_HASONGIVED))
		{
			player.Flags |= FF2FLAG_HASONGIVED;
			RemovePlayerBack(client, {57, 133, 405, 444, 608, 642}, 7);
			RemovePlayerTarge(client);
			TF2_RemoveAllWeapons(client);
			TF2_RegeneratePlayer(client);
			CreateTimer(0.1, Timer_RegenPlayer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		CreateTimer(0.2, MakeNotBoss, player, TIMER_FLAG_NO_MAPCHANGE);
	}

	player.Flags &= ~(FF2FLAG_UBERREADY|FF2FLAG_ISBUFFED|FF2FLAG_ALLOWSPAWNINBOSSTEAM|FF2FLAG_USINGABILITY|FF2FLAG_CLASSHELPED|FF2FLAG_CHANGECVAR|FF2FLAG_ALLOW_HEALTH_PICKUPS|FF2FLAG_ALLOW_AMMO_PICKUPS|FF2FLAG_BLAST_JUMPING);
	player.Flags |= FF2FLAG_USEBOSSTIMER;

	return Plugin_Continue;
}

void MakePlayerToBoss(int client, int characterIndex)
{
	int boss = client;

	if(IsBoss(client))
	{
		boss=GetBossIndex(client);
		Boss[boss]=0;
		character[boss]=0;
	}

	if(characterIndex != -1)
	{
		Boss[boss]=client;
		character[boss]=characterIndex;
		MakeBoss(INVALID_HANDLE, boss);
	}
	else
	{
		float pos[3], angles[3], velocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecOrigin", pos);
		GetClientEyeAngles(client, angles);
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);

		if((GetEntityFlags(client) & FL_ONGROUND) > 0
			&& GetEntProp(client, Prop_Send, "m_bDucked") > 0)
			pos[2]-=20.0;

		TF2_RespawnPlayer(client);
		TeleportEntity(client, pos, angles, velocity);
	}
}

public /*void*/int Native_MakePlayerToBoss(Handle plugin, int numParams)
{
	MakePlayerToBoss(GetNativeCell(1), GetNativeCell(2));
	return 0;
}

public Action Timer_RegenPlayer(Handle timer, int userid)
{
	int client=GetClientOfUserId(userid);
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		TF2_RegeneratePlayer(client);
	}

	return Plugin_Continue;
}

public Action ClientTimer(Handle timer)
{
	if(!Enabled || CheckRoundState()==FF2RoundState_RoundEnd || CheckRoundState()==FF2RoundState_Loading)
	{
		return Plugin_Stop;
	}

	char classname[32], hudText[64];
	TFCond cond;
	FF2HudDisplay hudDisplay;
	
	// Hud 구문 분리
	for(int client = 1; client <= MaxClients; client++)
	{
		if(!IsClientInGame(client))	continue;

		FF2BaseEntity player = g_hBasePlayer[client];

		if(!IsBoss(client) && !(player.Flags & FF2FLAG_CLASSTIMERDISABLED))
		{
			SetHudTextParams(-1.0, 0.88, 0.35, 90, 255, 90, 255, 0, 0.35, 0.0, 0.1);
			SetGlobalTransTarget(client);

			PlayerHudQueue[client].SetName("Player");
			if(!IsPlayerAlive(client))
			{
				int observerIndex = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");

				if(IsValidClient(observerIndex) && observerIndex!=client)
				{
					FF2BaseEntity observer = g_hBasePlayer[observerIndex];
					PlayerHudQueue[client].SetName("Observer");

					if(!IsBoss(observerIndex))
					{
						Format(hudText, sizeof(hudText), "%t", "Your Damage Dealt", player.Damage);
						if(player.Assist > 0)
							Format(hudText, sizeof(hudText), "%s + ASSIST: %d", hudText, player.Assist);

						hudDisplay=FF2HudDisplay.CreateDisplay("Your Damage Dealt", hudText);
						PlayerHudQueue[client].AddHud(hudDisplay, client);

						Format(hudText, sizeof(hudText), "%t", "Spectator Damage Dealt", observerIndex, observer.Damage);
						if(observer.Assist > 0)
							Format(hudText, sizeof(hudText), "%s + ASSIST: %d", hudText, observer.Assist);

						hudDisplay=FF2HudDisplay.CreateDisplay("Observer Target Player Damage", hudText);
						PlayerHudQueue[client].AddHud(hudDisplay, client, observerIndex);
					}
					else if(IsBoss(observerIndex))
					{
						int boss=GetBossIndex(observerIndex);
						char lives[8];
						if(BossLives[boss]>1)
						{
							Format(lives, 8, "x%d", BossLives[boss]);
						}
						Format(hudText, sizeof(hudText), "HP: %d / %d%s", BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], lives);
						hudDisplay=FF2HudDisplay.CreateDisplay("Observer Target Boss HP", hudText);
						PlayerHudQueue[client].AddHud(hudDisplay, client);

						if(BossTeam != TF2_GetClientTeam(observerIndex))
						{
							Format(hudText, sizeof(hudText), "%t", "Spectator Damage Dealt", observerIndex, observer.Damage);
							if(observer.Assist > 0)
								Format(hudText, sizeof(hudText), "%s + ASSIST: %d", hudText, observer.Assist);

							hudDisplay = FF2HudDisplay.CreateDisplay("Observer Target Player Damage", hudText);
							PlayerHudQueue[client].AddHud(hudDisplay, client, observerIndex);
						}
					}
				}
				else
				{
					Format(hudText, sizeof(hudText), "%t", "Your Damage Dealt", player.Damage);
					if(player.Assist > 0)
						Format(hudText, sizeof(hudText), "%s + ASSIST: %d", hudText, player.Assist);

					hudDisplay=FF2HudDisplay.CreateDisplay("Your Damage Dealt", hudText);
					PlayerHudQueue[client].AddHud(hudDisplay, client);
				}
			}
			else
			{
				Format(hudText, sizeof(hudText), "%t", "Your Damage Dealt", player.Damage);
				if(player.Assist > 0)
					Format(hudText, sizeof(hudText), "%s + ASSIST: %d", hudText, player.Assist);

				hudDisplay=FF2HudDisplay.CreateDisplay("Your Damage Dealt", hudText);
				PlayerHudQueue[client].AddHud(hudDisplay, client);
			}
			PlayerHudQueue[client].ShowSyncHudQueueText(client, null, FF2HudChannel_Rage);
			PlayerHudQueue[client].DeleteAllDisplay();

			if(!IsPlayerAlive(client)) continue;

			// 투사체 유도 시스템: 플레이어 무기에 따라 활성화
			g_bHomingEnabled[client] = false;
			if(!IsBoss(client))
			{
				// 주 무기 체크
				int priWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
				if(IsValidEntity(priWeapon))
				{
					int priIndex = GetEntProp(priWeapon, Prop_Send, "m_iItemDefinitionIndex");
					if(priIndex == 996) // 통제불능 대포: 상시 치명타
					{
						TF2_AddCondition(client, TFCond_CritOnDamage, 0.5);
					}
					else if(priIndex == 527) // 과부제조기: 유도 미사일
					{
						g_bHomingEnabled[client] = true;
						g_flHomingStrength[client] = 1000.0;
					}
					else if(priIndex == 588) // 폼슨 6000: 유도 탄환
					{
						g_bHomingEnabled[client] = true;
						g_flHomingStrength[client] = 300.0;
					}
					else if(priIndex == 305) // 십자군의 석궁: 약한 유도
					{
						g_bHomingEnabled[client] = true;
						g_flHomingStrength[client] = 50.0;
					}
				}

				// 보조 무기 체크: 유도 + 가스패서 탄약
				int secWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
				if(IsValidEntity(secWeapon))
				{
					int secIndex = GetEntProp(secWeapon, Prop_Send, "m_iItemDefinitionIndex");
					if(secIndex == 39 || secIndex == 351 || secIndex == 1081) // 조명탄/기폭장치
					{
						g_bHomingEnabled[client] = true;
						g_flHomingStrength[client] = 500.0;
					}
					else if(secIndex == 1180) // 가스패서: 유도 + 탄약 3 고정
					{
						g_bHomingEnabled[client] = true;
						g_flHomingStrength[client] = 500.0;

						int ammoType = GetEntProp(secWeapon, Prop_Send, "m_iPrimaryAmmoType");
						if(ammoType >= 0)
							SetEntProp(client, Prop_Data, "m_iAmmo", 3, _, ammoType);
					}
				}
			}

			// Additional HUD Initialize
			PlayerHudQueue[client].SetName("Player Additional");
			SetHudTextParams(-1.0, 0.83, 0.35, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1);

			// Movement speed limit
			float maxspeed = GetEntPropFloat(client, Prop_Send, "m_flMaxspeed");
			if(maxspeed > 500.0 && !TF2_IsPlayerInCondition(client, TFCond_Charging) && !TF2_IsPlayerInCondition(client, TFCond_SpeedBuffAlly))
				SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 500.0);

			TFClassType playerclass=TF2_GetPlayerClass(client);
			int weapon=GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(weapon<=MaxClients || !IsValidEntity(weapon) || !GetEntityClassname(weapon, classname, sizeof(classname)))
			{
				strcopy(classname, sizeof(classname), "");
			}
			bool validwep=!StrContains(classname, "tf_weapon", false);

			int index=(validwep ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);

			// 블랙 박스: 들고 있을 때 상시 크리티컬
			if((index == 228 || index == 1085) && !IsBoss(client))
			{
				TF2_AddCondition(client, TFCond_CritOnFirstBlood, 0.3);
			}

			if(playerclass==TFClass_Medic)
			{
				int medigun=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
				if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary))
				{
					char mediclassname[64];
					if(IsValidEntity(medigun) && GetEntityClassname(medigun, mediclassname, sizeof(mediclassname)) && !StrContains(mediclassname, "tf_weapon_medigun", false))
					{
						int charge=RoundToFloor(GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel")*100);
						Format(hudText, sizeof(hudText), "%T", "Ubercharge", client, charge);
						hudDisplay=FF2HudDisplay.CreateDisplay("Ubercharge", hudText);
						PlayerHudQueue[client].AddHud(hudDisplay, client);

						if(charge==100 && !(player.Flags & FF2FLAG_UBERREADY))
						{
							FakeClientCommandEx(client, "voicemenu 1 7");
							player.Flags |= FF2FLAG_UBERREADY;
						}
					}

				}
				else if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary))
				{
					int healtarget=GetHealingTarget(client, true);
					if(IsValidClient(healtarget) && TF2_GetPlayerClass(healtarget)==TFClass_Scout
						&& GetClientTeam(healtarget) == GetClientTeam(client))
					{
						TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.3);
					}

					// 예방접종기(998): 보스를 향해 공격 버튼 시 초당 12 데미지 (0.3초 틱 = 3.6)
					if(IsValidEntity(weapon))
					{
						int secIdx = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
						if(secIdx == 998 && (GetClientButtons(client) & IN_ATTACK))
						{
							float eyePos[3], eyeAng[3], endPos[3];
							GetClientEyePosition(client, eyePos);
							GetClientEyeAngles(client, eyeAng);
							Handle trace = TR_TraceRayFilterEx(eyePos, eyeAng, MASK_SHOT, RayType_Infinite, TraceFilter_Bullet, client);
							if(TR_DidHit(trace))
							{
								int hitEnt = TR_GetEntityIndex(trace);
								TR_GetEndPosition(endPos, trace);
								if(hitEnt > 0 && hitEnt <= MaxClients && IsClientInGame(hitEnt) && IsPlayerAlive(hitEnt)
									&& IsBoss(hitEnt) && GetVectorDistance(eyePos, endPos) <= 450.0)
								{
									SDKHooks_TakeDamage(hitEnt, client, client, 3.6, DMG_GENERIC);
								}
							}
							delete trace;
						}
					}
				}

				int melee=GetPlayerWeaponSlot(client, TFWeaponSlot_Melee), meleeIndex;
				if(IsValidEntity(melee))
				{
					meleeIndex=GetEntProp(melee, Prop_Send, "m_iItemDefinitionIndex");
					if(meleeIndex == 413)
					{
						int allRageDamage, bossIndex;
						float allCharge;

						for(int target=1; target<=MaxClients; target++)
						{
							if((bossIndex = GetBossIndex(target)) != -1 && TF2_GetClientTeam(target) == BossTeam) {
								allRageDamage += BossRageDamage[bossIndex];
								allCharge += BossCharge[bossIndex][0];
							}
						}
						Format(hudText, sizeof(hudText), "%t (%i / %i)", "Current Boss Rage", RoundFloat(allCharge), RoundFloat(allCharge*(allRageDamage/100.0)), allRageDamage);
						hudDisplay=FF2HudDisplay.CreateDisplay("Current Boss Rage", hudText);
						PlayerHudQueue[client].AddHud(hudDisplay, client);
					}
					if(meleeIndex == 173
						&& (IsValidEntity(medigun) && GetEntProp(medigun, Prop_Send, "m_bChargeRelease") == 0))
					{
						int decapitations=GetEntProp(client, Prop_Send, "m_iDecapitations");
						float minCharge=0.1*(decapitations > 6 ? 6 : decapitations),
							currentCharge=GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel");

						if(minCharge > currentCharge)
							SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", minCharge);
					}
				}
			}
			else if(playerclass==TFClass_Soldier)
			{
				if((player.Flags & FF2FLAG_ISBUFFED) && !(GetEntProp(client, Prop_Send, "m_bRageDraining")))
				{
					player.Flags &= ~FF2FLAG_ISBUFFED;
				}
			}
	

			// 쉴드 게이지 및 오버차지 HUD 표시 (클래스 무관, 쉴드 보유 시)
			if(shield[client] && IsValidEntity(shield[client]))
			{
				int shieldIndex = GetEntProp(shield[client], Prop_Send, "m_iItemDefinitionIndex");
				if(shieldIndex == 57) // Razorback
				{
					float razorCharge = GetEntPropFloat(client, Prop_Send, "m_flItemChargeMeter", TFWeaponSlot_Secondary);
					Format(hudText, sizeof(hudText), "%t: %d%%", "Shield Charge", RoundFloat(razorCharge));
				}
				else // 데모 쉴드
				{
					float charge = GetEntPropFloat(client, Prop_Send, "m_flChargeMeter");
					if(OverCharge[client] > 0.0)
						Format(hudText, sizeof(hudText), "%t: %d%% | %t: %d", "Shield Charge", RoundFloat(charge), "Overcharge", RoundFloat(OverCharge[client]));
					else
						Format(hudText, sizeof(hudText), "%t: %d%%", "Shield Charge", RoundFloat(charge));
				}
				hudDisplay = FF2HudDisplay.CreateDisplay("Shield", hudText);
				PlayerHudQueue[client].AddHud(hudDisplay, client);
			}

			if(RedAlivePlayers==1 && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
			{
				TF2_AddCondition(client, TFCond_HalloweenCritCandy, 0.3);
				if(playerclass==TFClass_Engineer && weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary) && StrEqual(classname, "tf_weapon_sentry_revenge", false))
				{
					SetEntProp(client, Prop_Send, "m_iRevengeCrits", 3);
				}

				if(lastPlayerGlow)
				{
					SetClientGlow(client, 3600.0);
				}
			}
			else if(RedAlivePlayers==2 && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
			{
				TF2_AddCondition(client, TFCond_CritCola, 0.3);
			}
			else if(bMedieval)
			{
				PlayerHudQueue[client].DeleteAllDisplay();
				continue;
			}
			
			if(TF2_GetPlayerClass(client) == TFClass_Medic)
{
	int melee = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	if(IsValidEntity(melee))
	{
		int meleeIndex = GetEntProp(melee, Prop_Send, "m_iItemDefinitionIndex");
		
		// ✅ 먼저 medigun 변수 선언!
		int medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		
		if(meleeIndex == 173
			&& (IsValidEntity(medigun) && GetEntProp(medigun, Prop_Send, "m_bChargeRelease") == 0))
		{
			int decapitations=GetEntProp(client, Prop_Send, "m_iDecapitations");
			float minCharge=0.1*(decapitations > 6 ? 6 : decapitations),
				currentCharge=GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel");

			if(minCharge > currentCharge)
				SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", minCharge);
		}

		// ✅ 메디건 들고 있으면 최소 25% 우버 보장
		if(IsValidEntity(medigun))
		{
			char medigunClass[64];
			GetEntityClassname(medigun, medigunClass, sizeof(medigunClass));
			
			if(StrEqual(medigunClass, "tf_weapon_medigun") 
				&& GetEntProp(medigun, Prop_Send, "m_bChargeRelease") == 0)  // 우버 사용 중이 아닐 때
			{
				float currentCharge = GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel");
				
				if(currentCharge < 0.25)  // 25% 미만이면
				{
					SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", 0.25);  // 25%로 설정
				}
			}
		}
	}
}

			cond=TFCond_HalloweenCritCandy;
			/*
			if(TF2_IsPlayerInCondition(client, TFCond_HalloweenCritCandy) && (playerclass==TFClass_Scout ))
			{
				// || playerclass==TFClass_Heavy
				TF2_AddCondition(client, cond, 0.3);
			}
			*/

			int healer=-1;
			for(int healtarget=1; healtarget<=MaxClients; healtarget++)
			{
				if(IsValidClient(healtarget) && IsPlayerAlive(healtarget) && GetHealingTarget(healtarget, true)==client)
				{
					healer=healtarget;
					break;
				}
			}

			bool addthecrit;
			if(validwep && weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Melee) && StrContains(classname, "tf_weapon_knife", false)==-1)  //Every melee except knives
			{
				addthecrit=true;
				if(index==416)  //Market Gardener
				{
					addthecrit = (player.Flags & FF2FLAG_BLAST_JUMPING) ? true : false;
				}
			}
			else if((!StrContains(classname, "tf_weapon_pistol") ||!StrContains(classname, "tf_weapon_handgun_scout_secondary")))
			{
				addthecrit=true;
				cond=TFCond_Buffed;
				/*
				if(playerclass==TFClass_Scout && cond==TFCond_HalloweenCritCandy)
				{
					cond=TFCond_Buffed;
				}
				*/
			}
			
			// Yes. This is addtional cond.
		if(!StrContains(classname, "tf_weapon_fist"))
		{
			int index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
			if(index == 331)  // 331만 허용
			{
				TF2_AddCondition(client, TFCond_DefenseBuffed, 0.3);
			}
		}

			if(index==16 && IsValidEntity(FindPlayerBack(client, 642)))  //SMG, Cozy Camper
			{
				addthecrit=false;
			}

			switch(playerclass)
			{
				case TFClass_Medic:
				{
					if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary))
					{
						int medigun=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
						char mediclassname[64];
						if(IsValidEntity(medigun) && GetEntityClassname(medigun, mediclassname, sizeof(mediclassname)) && !StrContains(mediclassname, "tf_weapon_medigun", false))
						{
							int charge=RoundToFloor(GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel")*100);
							if(charge==100 && !(player.Flags & FF2FLAG_UBERREADY))
							{
								FakeClientCommand(client, "voicemenu 1 7");  //"I am fully charged!"
								player.Flags |= FF2FLAG_UBERREADY;
							}
						}
					}
					else if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary))
					{
						int healtarget=GetHealingTarget(client, true);
						if(IsValidClient(healtarget) && TF2_GetPlayerClass(healtarget)==TFClass_Scout)
						{
							TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.3);
						}
					}
				}
				case TFClass_DemoMan:
				{
					if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary) && !IsValidEntity(GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary)) && shieldCrits)  //Demoshields
					{
						addthecrit=true;
						if(shieldCrits==1)
						{
							cond=TFCond_Buffed;
						}
					}
				}
				case TFClass_Engineer:
				{
					if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary) && StrEqual(classname, "tf_weapon_sentry_revenge", false))
					{
						int sentry=FindSentry(client);
						if(IsValidEntity(sentry) && IsBoss(GetEntPropEnt(sentry, Prop_Send, "m_hEnemy")))
						{
							SetEntProp(client, Prop_Send, "m_iRevengeCrits", 3);
							TF2_AddCondition(client, TFCond_Kritzkrieged, 0.3);
						}
						else
						{
							if(GetEntProp(client, Prop_Send, "m_iRevengeCrits"))
							{
								SetEntProp(client, Prop_Send, "m_iRevengeCrits", 0);
							}
							else if(TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) && !TF2_IsPlayerInCondition(client, TFCond_Healing))
							{
								TF2_RemoveCondition(client, TFCond_Kritzkrieged);
							}
						}
					}
				}
			}

			PlayerHudQueue[client].ShowSyncHudQueueText(client, null, FF2HudChannel_DownAddtional);
			PlayerHudQueue[client].DeleteAllDisplay();

			if(addthecrit)
			{
				TF2_AddCondition(client, cond, 0.3);
				if(healer!=-1 && cond!=TFCond_Buffed)
				{
					TF2_AddCondition(client, TFCond_Buffed, 0.3);
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action BossTimer(Handle timer)
{
	if(!Enabled || CheckRoundState()==FF2RoundState_RoundEnd)
	{
		return Plugin_Stop;
	}

	bool validBoss;

	// TODO: Add FF2CharacterInfo on this
	FF2BaseEntity baseBoss;
	for(int boss; boss<=MaxClients; boss++)
	{
		int client=Boss[boss];
		/*
		if(!IsPlayerAlive(client) && (BossTeam != TF2_GetClientTeam(client)))
			continue;
		*/

		if(!IsValidClient(client) || !IsPlayerAlive(client))
			continue;

		baseBoss = g_hBasePlayer[client];
		if(!(baseBoss.Flags & FF2FLAG_USEBOSSTIMER))
			continue;
		
		// Debug("BossTimer has started for %d at %f", boss, GetGameTime());

		PlayerHudQueue[client].SetName("Boss");
		FF2HudDisplay bossHudDisplay;
		validBoss=true;
		SetGlobalTransTarget(client);
		char text[64];

		if(BossLivesMax[boss]>1)
		{
			// SetHudTextParams(-1.0, 0.77, 0.12, 255, 255, 255, 255);
			// FF2_ShowSyncHudText(client, livesHUD, "%t", "Boss Lives Left", BossLives[boss], BossLivesMax[boss]);
			Format(text, sizeof(text), "%t", "Boss Lives Left", BossLives[boss], BossLivesMax[boss]);
			bossHudDisplay=FF2HudDisplay.CreateDisplay("Boss Lives Left", text);
			PlayerHudQueue[client].AddHud(bossHudDisplay, client);
		}

		SetHudTextParams(-1.0, 0.83, 0.12, 255, 255, 255, 255);

		for(int loop = SkillType_MaxCounts - 1; loop >= 0; loop--)
		{
			if(BossSkillDuration[boss][loop] <= GetGameTime())		continue;

			SetHudTextParams(-1.0, 0.83, 0.12, 0, 255, 0, 255);
			if(!GetBossSkillName(boss, loop, text, sizeof(text), client))
			{
				switch(loop)
				{
					case SkillType_Rage, SkillType_200Rage:
					{
						Format(text, sizeof(text), "%T", "Rage Duration", client);
					}
					case SkillType_LostLife:
					{
						Format(text, sizeof(text), "%T", "Life Skill Duration", client);
					}
				}
			}

			// FIXME: 라이프 스킬과 분노가 겹치는 경우, 라이프 스킬 이름이 씹힘
			Format(text, sizeof(text), "%s: %.1f", text, BossSkillDuration[boss][loop] - GetGameTime());
			bossHudDisplay=FF2HudDisplay.CreateDisplay("Skill Duration", text);
			PlayerHudQueue[client].AddHud(bossHudDisplay, client);
		}

		char strMaxCharge[8];
		if(BossMaxRageCharge[boss] < 0.0)
		{
			Format(strMaxCharge, sizeof(strMaxCharge), "∞");
		}
		else
		{
			Format(strMaxCharge, sizeof(strMaxCharge), "%i", RoundFloat(BossMaxRageCharge[boss]));
		}

		Format(text, sizeof(text), "%t", "Rage Meter Phrase");
		Format(text, sizeof(text), "%s: %t", text, "Current Rage Meter", RoundFloat(BossCharge[boss][0]), strMaxCharge);
		Format(text, sizeof(text), "%s (%t)", text, "Current Rage Damage", RoundFloat(BossCharge[boss][0]*(BossRageDamage[boss]/100.0)), BossRageDamage[boss]);

		bossHudDisplay=FF2HudDisplay.CreateDisplay("Rage Meter", text);
		PlayerHudQueue[client].AddHud(bossHudDisplay, client);

		if(RoundFloat(BossCharge[boss][0]) >= 100.0)
		{
			if(IsFakeClient(client) && !(baseBoss.Flags & FF2FLAG_BOTRAGE))
			{
				CreateTimer(1.0, Timer_BotRage, boss, TIMER_FLAG_NO_MAPCHANGE);
				baseBoss.Flags |= FF2FLAG_BOTRAGE;
			}
			else
			{
				if(BossSkillDuration[boss][SkillType_Rage] > GetGameTime()
					|| BossSkillDuration[boss][SkillType_200Rage] > GetGameTime())
					SetHudTextParams(-1.0, 0.83, 0.12, 0, 255, 0, 255);
				else if((RoundFloat(BossMaxRageCharge[boss]) >= 200
					&& (100 <= RoundFloat(BossCharge[boss][0]) && RoundFloat(BossCharge[boss][0]) < 200)))
					SetHudTextParams(-1.0, 0.83, 0.12, 255, 228, 0, 255);
				else
					SetHudTextParams(-1.0, 0.83, 0.12, 255, 64, 64, 255);

				Format(text, sizeof(text), "%T", "Activate Rage", client);
				bossHudDisplay=FF2HudDisplay.CreateDisplay("Activate Rage", text);
				PlayerHudQueue[client].AddHud(bossHudDisplay, client);

				char sound[PLATFORM_MAX_PATH];
				if(FindSound("full rage", sound, sizeof(sound), boss) && emitRageSound[boss])
				{
					EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound, client);

					emitRageSound[boss]=false;
				}
			}
		}
		else if(BossTeam != TF2_GetClientTeam(client))
		{
			Format(text, sizeof(text), "%t", "Your Damage Dealt", baseBoss.Damage);
			if(baseBoss.Assist > 0)
				Format(text, sizeof(text), "%s + ASSIST: %d", text, baseBoss.Assist);

			bossHudDisplay=FF2HudDisplay.CreateDisplay("Your Damage Dealt", text);
			PlayerHudQueue[client].AddHud(bossHudDisplay, client);
		}

		PlayerHudQueue[client].ShowSyncHudQueueText(client, null, FF2HudChannel_Rage);
		PlayerHudQueue[client].DeleteAllDisplay();

		SetHudTextParams(-1.0, 0.73, 0.12, 255, 255, 255, 255);
		PlayerHudQueue[client].SetName("Boss Up Additional");

		PlayerHudQueue[client].ShowSyncHudQueueText(client, null, FF2HudChannel_UpAddtional);
		PlayerHudQueue[client].DeleteAllDisplay();

		SetHudTextParams(-1.0, 0.88, 0.12, 255, 255, 255, 255);
		PlayerHudQueue[client].SetName("Boss Down Additional");

		PlayerHudQueue[client].ShowSyncHudQueueText(client, null, FF2HudChannel_DownAddtional);
		PlayerHudQueue[client].DeleteAllDisplay();

		if(RedAlivePlayers==1)
		{
			char message[512], name[64], bossLives[10];  //Do not decl this
			int bossindexs[MAXPLAYERS+1], bosscount=0;

			for(int target=1; target<=MaxClients; target++)  //TODO: Why is this for loop needed when we're already in a boss for loop
			{
				if(IsBoss(target))
				{
					bossindexs[bosscount++]=GetBossIndex(target);
				}
			}

			for(int target=1; target<=MaxClients; target++)
			{
				if(IsValidClient(target) && !IsFakeClient(target) && !(FF2Flags[target] & FF2FLAG_HUDDISABLED))
				{
					SetGlobalTransTarget(target);
					Format(message, sizeof(message), "");

					for(int loop; loop<bosscount; loop++)
					{
						GetBossName(bossindexs[loop], name, sizeof(name), target);

						if(BossLives[bossindexs[loop]]>1)
							Format(bossLives, sizeof(bossLives), "x%i", BossLives[bossindexs[loop]]);
						else
							Format(bossLives, sizeof(bossLives), "");
						Format(message, sizeof(message), "%s\n%t", message, "Boss Current Health", name, BossHealth[bossindexs[loop]]-BossHealthMax[bossindexs[loop]]*(BossLives[bossindexs[loop]]-1), BossHealthMax[bossindexs[loop]], bossLives);
					}
					PrintCenterText(target, message);
				}
			}

			if(lastPlayerGlow)
			{
				SetClientGlow(client, 3600.0);
			}
		}

		HPTime-=0.1;
		if(HPTime<0)
		{
			HPTime=0.0;
		}

		for(int client2; client2<=MaxClients; client2++)
		{
			if(KSpreeTimer[client2]>0)
			{
				KSpreeTimer[client2]-=0.1;
			}
		}
	}

	if(!validBoss)
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}


public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if(!Enabled || CheckRoundState() != FF2RoundState_RoundRunning) 	return Plugin_Continue;
	if(!IsValidClient(client) || !IsPlayerAlive(client))			return Plugin_Continue;

	if(IsBoss(client))
		OnBossThink(client);

	LastCharge[client] = GetEntPropFloat(client, Prop_Send, "m_flChargeMeter");

	// ✅ 자토이치 명예의 구속
	int melee = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	if(IsValidEntity(melee))
	{
		int meleeIndex = GetEntProp(melee, Prop_Send, "m_iItemDefinitionIndex");
		if(meleeIndex == 357)  // Half-Zatoichi
		{
			int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(activeWeapon > 0)
			{
				char weaponClass[64];
				GetEntityClassname(activeWeapon, weaponClass, sizeof(weaponClass));
				
				if(StrEqual(weaponClass, "tf_weapon_katana"))
				{
					if(g_flZatoichiDrawTime[client] == 0.0)
					{
						g_flZatoichiDrawTime[client] = GetGameTime();
					}
					
					float elapsedTime = GetGameTime() - g_flZatoichiDrawTime[client];
					
					if(elapsedTime >= 1.0 && GetEntProp(client, Prop_Send, "m_iKillCountSinceLastDeploy") == 0)
					{
						if(buttons & IN_ATTACK3)
							buttons &= ~IN_ATTACK3;
						
						if(impulse >= 1 && impulse <= 5)
							impulse = 0;
						
						if(!TF2_IsPlayerInCondition(client, TFCond_RestrictToMelee))
							TF2_AddCondition(client, TFCond_RestrictToMelee, 1.0, 0);
						
						return Plugin_Changed;
					}
				}
				else
				{
					g_flZatoichiDrawTime[client] = 0.0;
				}
			}
		}
		else
		{
			g_flZatoichiDrawTime[client] = 0.0;
		}
	}

	// 낙하산 즉시 재전개
	if(!TF2_IsPlayerInCondition(client, TFCond_Parachute) &&
	   TF2_IsPlayerInCondition(client, TFCond_ParachuteDeployed))
	{
		int secondary = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(IsValidEntity(secondary) && 
		   GetEntProp(secondary, Prop_Send, "m_iItemDefinitionIndex") == 1101)
		{
			TF2_RemoveCondition(client, TFCond_ParachuteDeployed);
		}
	}
	
	// 파이로 3도화상 도발 힐
	if(TF2_GetPlayerClass(client) == TFClass_Pyro)
	{
		int meleeWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(IsValidEntity(meleeWeapon) && 
		   GetEntProp(meleeWeapon, Prop_Send, "m_iItemDefinitionIndex") == 593)
		{
			if(TF2_IsPlayerInCondition(client, TFCond_Taunting))
			{
				static float g_flLastHealTime[MAXPLAYERS+1];
				if(GetGameTime() - g_flLastHealTime[client] >= 0.5)
				{
					g_flLastHealTime[client] = GetGameTime();
					
					float clientPos[3];
					GetClientAbsOrigin(client, clientPos);
					int clientTeam = GetClientTeam(client);
					
					for(int i = 1; i <= MaxClients; i++)
					{
						if(!IsValidClient(i) || !IsPlayerAlive(i) || i == client)
							continue;
						
						if(GetClientTeam(i) != clientTeam)
							continue;
						
						float targetPos[3];
						GetClientAbsOrigin(i, targetPos);
						
						if(GetVectorDistance(clientPos, targetPos) <= 150.0)
						{
							int maxHealth = GetEntProp(i, Prop_Data, "m_iMaxHealth");
							int currentHealth = GetClientHealth(i);
							int healAmount = 25;
							int newHealth = currentHealth + healAmount;
							
							if(newHealth > maxHealth)
							{
								healAmount = maxHealth - currentHealth;
								newHealth = maxHealth;
							}
							
							if(healAmount > 0)
							{
								SetEntityHealth(i, newHealth);
								
								Event event = CreateEvent("player_healed", true);
								if(event != null)
								{
									event.SetInt("patient", GetClientUserId(i));
									event.SetInt("healer", GetClientUserId(client));
									event.SetInt("amount", healAmount);
									event.Fire();
								}
								
								SetEntPropEnt(i, Prop_Send, "m_hHealers", client);
							}
						}
					}
				}
			}
		}
	}

	// ✅ 크리츠크릭 치료 시 미니크리 부여
	if(TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		int secondary = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(IsValidEntity(secondary) && 
		   GetEntProp(secondary, Prop_Send, "m_iItemDefinitionIndex") == 35)
		{
			if(GetEntProp(secondary, Prop_Send, "m_bHealing"))
			{
				int healTarget = GetEntPropEnt(secondary, Prop_Send, "m_hHealingTarget");
				if(healTarget > 0 && healTarget <= MaxClients && IsClientInGame(healTarget) && IsPlayerAlive(healTarget))
				{
					if(KritzTimer[client] == INVALID_HANDLE)
					{
						TF2_AddCondition(healTarget, TFCond_CritCola, 0.5, 0);
						KritzTimer[client] = CreateTimer(0.3, Timer_Kritz, EntIndexToEntRef(secondary), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
			else
			{
				if(KritzTimer[client] != INVALID_HANDLE)
				{
					KillTimer(KritzTimer[client]);
					KritzTimer[client] = INVALID_HANDLE;
				}
			}
		}
		else
		{
			if(KritzTimer[client] != INVALID_HANDLE)
			{
				KillTimer(KritzTimer[client]);
				KritzTimer[client] = INVALID_HANDLE;
			}
		}
	}

	// ✅ 절단기(304번) 체력 증가 체크
	if(TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		int meleeSlot = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(IsValidEntity(meleeSlot) && 
		   GetEntProp(meleeSlot, Prop_Send, "m_iItemDefinitionIndex") == 304)
		{
			static int lastHitCount[MAXPLAYERS+1];
			int currentHits = GetEntProp(client, Prop_Send, "m_iDecapitations");
			
			if(currentHits > lastHitCount[client])
			{
				int currentHealth = GetClientHealth(client);
				int healAmount = (currentHits - lastHitCount[client]) * 100;
				int newHealth = currentHealth + healAmount;
				
				SetEntityHealth(client, newHealth);
				lastHitCount[client] = currentHits;
			}
		}
	}
	
	// ✅ 안락한 야영장비(642번) 착용 시 50% 투명 (무기+옷 포함)
	static bool hasCozyWearable[MAXPLAYERS+1];
	static float lastCheckTime[MAXPLAYERS+1];

	float gameTime = GetGameTime();
	if(gameTime - lastCheckTime[client] >= 0.5)
	{
		lastCheckTime[client] = gameTime;

		bool foundCozy = false;

		// 안락한 야영장비 확인
		for(int i = MaxClients + 1; i < GetMaxEntities(); i++)
		{
			if(!IsValidEntity(i))
				continue;
			
			char classname[64];
			GetEntityClassname(i, classname, sizeof(classname));
			
			if(StrContains(classname, "tf_wearable") != -1)
			{
				int owner = GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity");
				if(owner == client)
				{
					int itemIndex = GetEntProp(i, Prop_Send, "m_iItemDefinitionIndex");
					if(itemIndex == 642)
					{
						foundCozy = true;
						break;
					}
				}
			}
		}

		// 상태가 바뀌었을 때만 적용
		if(foundCozy != hasCozyWearable[client])
		{
			hasCozyWearable[client] = foundCozy;
			
			int alpha = foundCozy ? 127 : 255;
			int renderMode = foundCozy ? RENDER_TRANSCOLOR : RENDER_NORMAL;
			
			// 플레이어
			SetEntityRenderMode(client, renderMode);
			SetEntityRenderColor(client, 255, 255, 255, alpha);
			
			// 모든 무기
			for(int slot = 0; slot < 5; slot++)
			{
				int slotWeapon = GetPlayerWeaponSlot(client, slot);
				if(IsValidEntity(slotWeapon))
				{
					SetEntityRenderMode(slotWeapon, renderMode);
					SetEntityRenderColor(slotWeapon, 255, 255, 255, alpha);
				}
			}
			
			// 모든 wearables + 장식품
			int entity = -1;
			char searchClass[][] = {"tf_wearable", "tf_wearable_demoshield", "tf_powerup_bottle"};
			
			for(int i = 0; i < sizeof(searchClass); i++)
			{
				entity = -1;
				while((entity = FindEntityByClassname(entity, searchClass[i])) != -1)
				{
					if(!IsValidEntity(entity)) continue;
					
					int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
					if(owner == client)
					{
						SetEntityRenderMode(entity, renderMode);
						SetEntityRenderColor(entity, 255, 255, 255, alpha);
					}
				}
			}
		}
	}
	
	if(TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		bool isCloaked = TF2_IsPlayerInCondition(client, TFCond_Cloaked) || 
		                 TF2_IsPlayerInCondition(client, TFCond_Stealthed);
		
		if(isCloaked)
		{
			int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			
			if(IsValidEntity(activeWeapon))
			{
				int index = GetEntProp(activeWeapon, Prop_Send, "m_iItemDefinitionIndex");
				float oldMult = g_flSpyCloakDamageMultiplier[client];
				
				switch(index)
				{
					default:
						g_flSpyCloakDamageMultiplier[client] = 0.5;
				}
			}
		}
		else
		{
			g_flSpyCloakDamageMultiplier[client] = 1.0;
		}
	}

	// 개척자의 정의(141): 발사 감지 (clip 감소 감지) → 착탄 위치에 폭발
	if(!IsBoss(client))
	{
		int activeWep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(IsValidEntity(activeWep))
		{
			int wepIndex = GetEntProp(activeWep, Prop_Send, "m_iItemDefinitionIndex");
			if(wepIndex == 141)
			{
				int clip = GetEntProp(activeWep, Prop_Send, "m_iClip1");
				if(clip < g_iLastClip141[client] && g_iLastClip141[client] > 0)
				{
					// clip이 줄었다 = 실제 발사됨
					float eyePos[3], eyeAng[3], endPos[3];
					GetClientEyePosition(client, eyePos);
					GetClientEyeAngles(client, eyeAng);

					Handle trace = TR_TraceRayFilterEx(eyePos, eyeAng, MASK_SHOT, RayType_Infinite, TraceFilter_Bullet, client);
					if(TR_DidHit(trace))
					{
						TR_GetEndPosition(endPos, trace);

						// 시각 폭발 이펙트
						int explosionModel = PrecacheModel("sprites/sprite_fire01.vmt");
						TE_SetupExplosion(endPos, explosionModel, 10.0, 1, 0, 150, 50);
						TE_SendToAll();

						// 반경 150 내 플레이어에게 거리비례 데미지 (60~30, 자가피해 포함)
						float flRadius = 150.0;
						float flMaxDmg = 60.0;
						float flMinDmg = 30.0;
						for(int i = 1; i <= MaxClients; i++)
						{
							if(!IsClientInGame(i) || !IsPlayerAlive(i)) continue;
							float targetPos[3];
							GetEntPropVector(i, Prop_Send, "m_vecOrigin", targetPos);
							targetPos[2] += 40.0;
							float dist = GetVectorDistance(endPos, targetPos);
							if(dist <= flRadius)
							{
								float dmg;
								if(dist <= 60.0)
									dmg = flMaxDmg;
								else
									dmg = flMaxDmg - (flMaxDmg - flMinDmg) * ((dist - 60.0) / (flRadius - 60.0));
								SDKHooks_TakeDamage(i, client, client, dmg, DMG_BLAST);
							}
						}
					}
					delete trace;
				}
				g_iLastClip141[client] = clip;
			}
		}
	}
	g_iLastButtons[client] = buttons;

	return Plugin_Continue;
}

public bool TraceFilter_Bullet(int entity, int contentsMask, int client)
{
	return (entity != client);
}

public Action Timer_Kritz(Handle timer, int medigunid)
{
	int medigun = EntRefToEntIndex(medigunid);
	if(medigun && IsValidEntity(medigun) && CheckRoundState() == FF2RoundState_RoundRunning)
	{
		int client = GetEntPropEnt(medigun, Prop_Send, "m_hOwnerEntity");
		
		if(IsValidClient(client, false) && IsPlayerAlive(client))
		{
			if(GetEntProp(medigun, Prop_Send, "m_bHealing"))
			{
				int healTarget = GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
				if(IsValidClient(healTarget, false) && IsPlayerAlive(healTarget))
				{
					TF2_AddCondition(healTarget, TFCond_CritCola, 0.5, 0);
					return Plugin_Continue;
				}
			}
		}
	}
	
	// 치료가 끝났거나 문제가 생기면 타이머 정리
	for(int i = 1; i <= MaxClients; i++)
	{
		if(KritzTimer[i] == timer)
		{
			KritzTimer[i] = INVALID_HANDLE;
			break;
		}
	}
	return Plugin_Stop;
}

void OnBossThink(int client)
{
	// BossTimer
	FF2BaseEntity baseBoss = g_hBasePlayer[client];
	if(!(baseBoss.Flags & FF2FLAG_USEBOSSTIMER))
		return;

	float tickTime = GetTickInterval();
	int boss = GetBossIndex(client);

	// TODO: "use_fixed_speed"
	if(!TF2_IsPlayerInCondition(client, TFCond_Charging))
	{
		if(TF2_GetClientTeam(client) == BossTeam && BossLivesMax[boss] * BossHealthMax[boss] > BossHealth[boss])
			SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", BossSpeed[boss]+0.8*(100-BossHealth[boss]*100/BossLivesMax[boss]/BossHealthMax[boss]));
		else
			SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", BossSpeed[boss]);
	}

	if(BossHealth[boss]<=0 && IsPlayerAlive(client))  //Wat.  TODO:  Investigate
	{
		BossHealth[boss]=1;
	}

	SetClientGlow(client, -tickTime);

	// 메인 보스의 분노 보정
	if(TF2_GetClientTeam(client) == BossTeam)
	{
		int other=0, fast = ScoutsLeft(other);
		fast -= other;
		AddBossCharge(boss, 0, fast > 0 ? fast * tickTime : 0.0);

		// stock
		AddBossCharge(boss, 0, (tickTime * 0.1));

		if(BossMaxRageCharge[boss] > 0.0 && BossMaxRageCharge[boss] <= BossCharge[boss][0])
		{
			int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(weapon != -1 && weapon == GetPlayerWeaponSlot(client, TFWeaponSlot_Melee)
				&& TF2Util_GetPlayerConditionDuration(client, TFCond_CritOnFirstBlood) < 0.02)
			{
				TF2_AddCondition(client, TFCond_CritOnFirstBlood, 0.1, client);
			}
		}
	}

	// 보스의 어빌리티 틱
	KeyValues kv = GetCharacterKV(character[boss]);
	kv.Rewind();
	if(kv.JumpToKey("abilities"))
	{
		KeyValues abilityKv = new KeyValues("abilities");
		abilityKv.Import(kv);

		char ability[10];
		abilityKv.GotoFirstSubKey();
		do
		{
			char pluginName[64];
			abilityKv.GetSectionName(pluginName, sizeof(pluginName));
			abilityKv.GotoFirstSubKey();
			do
			{
				char abilityName[64];
				abilityKv.GetSectionName(abilityName, sizeof(abilityName));
				int slot = abilityKv.GetNum("slot", 0),
					buttonmode = abilityKv.GetNum("buttonmode", 0);
				if(slot < 1)
				{
					// We don't care about rage/life-loss abilities here
					continue;
				}

				abilityKv.GetString("life", ability, sizeof(ability), "");
				if(!ability[0]) // Just a regular ability that doesn't care what life the boss is on
				{
					UseAbility(boss, pluginName, abilityName, slot, buttonmode);
				}
				else // But these do
				{
					char temp[3];
					ArrayList livesArray=CreateArray(sizeof(temp));
					int count=ExplodeStringIntoArrayList(ability, " ", livesArray, sizeof(temp));
					for(int n; n<count; n++)
					{
						livesArray.GetString(n, temp, sizeof(temp));
						if(StringToInt(temp)==BossLives[boss])
						{
							UseAbility(boss, pluginName, abilityName, slot, buttonmode);
							break;
						}
					}
					delete livesArray;
				}
			}
			while(abilityKv.GotoNextKey());
			abilityKv.GoBack();
		}
		while(abilityKv.GotoNextKey());

		delete abilityKv;
	}
}

public Action Timer_BotRage(Handle timer, int bot)
{
	if(IsValidClient(Boss[bot], false))
		FakeClientCommandEx(Boss[bot], "voicemenu 0 0");

	return Plugin_Continue;
}

public int ScoutsLeft(int& others)
{
	int scouts=0;
	float velocity[3];
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && IsPlayerAlive(client) && TF2_GetClientTeam(client)!=BossTeam)
		{
			if(TF2_GetPlayerClass(client) == TFClass_Scout)
			{
				scouts++;
				continue;
			}

			GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
			if(GetVectorLength(velocity) >= 400.0)
				scouts++;
			else
				others++;
		}
	}
	return scouts;
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if(Enabled)
	{
		if(IsBoss(client) && (condition==TFCond_Jarated || condition==TFCond_MarkedForDeath || (condition==TFCond_Dazed && TF2_IsPlayerInCondition(client, view_as<TFCond>(42)))))
		{
			TF2_RemoveCondition(client, condition);

			if(condition == TFCond_MarkedForDeath) // Fan O' War(Yeah), Sandman balls
			{
				int boss = GetBossIndex(client);
				AddBossCharge(boss, 0, -5.0);
			}
		}
		else if(!IsBoss(client))
		{
			FF2BaseEntity player = g_hBasePlayer[client];

			switch(condition)
			{
				case TFCond_BlastJumping:
				{
					player.Flags |= FF2FLAG_BLAST_JUMPING;
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", RocketJumpPosition[client]);
				}
				case TFCond_RestrictToMelee:
				{
					TF2_RemoveCondition(client, TFCond_RestrictToMelee);
					// TF2_AddCondition(client, TFCond_SpeedBuffAlly, 12.0);
				}
				case TFCond_Bonked:
				{
					// TF2_RemoveCondition(client, TFCond_Bonked);
					// TF2_AddCondition(client, TFCond_HalloweenQuickHeal, 2.0);
					TF2_AddCondition(client, TFCond_MarkedForDeath, 8.0);

					// reload
					// TF2Attrib_AddCustomPlayerAttribute(client, "effect bar recharge rate increased", 100000.0, 8.0);
					// TF2Attrib_AddCustomPlayerAttribute(client, "Reload time increased", 100000.0, 8.0);
				}
			}
		}
	}
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	if(Enabled)
	{
		if(TF2_GetPlayerClass(client)==TFClass_Scout && condition==TFCond_CritHype)
		{
			TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);
		}
		else if(!IsBoss(client) && condition == TFCond_BlastJumping)
		{
			FF2BaseEntity player = g_hBasePlayer[client];
			player.Flags &= ~FF2FLAG_BLAST_JUMPING;
		}
	}
}

public Action OnCallForMedic(int client, const char[] command, int args)
{
	if(!Enabled || !IsPlayerAlive(client) || CheckRoundState()!=FF2RoundState_RoundRunning || !IsBoss(client) || args!=2)
	{
		return Plugin_Continue;
	}

	int boss=GetBossIndex(client);

	char arg1[4], arg2[4];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	if(StringToInt(arg1) || StringToInt(arg2))  //We only want "voicemenu 0 0"-thanks friagram for pointing out edge cases
	{
		return Plugin_Continue;
	}

	if(RoundFloat(BossCharge[boss][0])>=100)
	{
		KeyValues kv = GetCharacterKV(character[boss]);
		int slot = RoundFloat(BossMaxRageCharge[boss]) >= 200 && RoundFloat(BossCharge[boss][0]) >= 200
			? -2 : 0;

		if(BossSkillDuration[boss][SkillType_Rage] > GetGameTime()
			|| BossSkillDuration[boss][SkillType_200Rage] > GetGameTime())
			return Plugin_Handled;

		kv.Rewind();
		if(kv.JumpToKey("abilities"))
		{
			KeyValues abilityKv = new KeyValues("abilities");
			abilityKv.Import(kv);

			char ability[10];
			abilityKv.GotoFirstSubKey();
			do
			{
				char pluginName[64];
				abilityKv.GetSectionName(pluginName, sizeof(pluginName));
				abilityKv.GotoFirstSubKey();
				do
				{
					char abilityName[64];
					abilityKv.GetSectionName(abilityName, sizeof(abilityName));
					if(abilityKv.GetNum("slot", 0) != slot) // Rage is slot 0 or -2
					{
						continue;
					}

					abilityKv.GetString("life", ability, sizeof(ability), "");
					if(!ability[0]) // Just a regular ability that doesn't care what life the boss is on
					{
						if(!UseAbility(boss, pluginName, abilityName, slot))
						{
							return Plugin_Continue;
						}
					}
					else // But these do
					{
						char temp[3];
						ArrayList livesArray=CreateArray(sizeof(temp));
						int count=ExplodeStringIntoArrayList(ability, " ", livesArray, sizeof(temp));
						for(int n; n<count; n++)
						{
							livesArray.GetString(n, temp, sizeof(temp));
							if(StringToInt(temp)==BossLives[boss])
							{
								if(!UseAbility(boss, pluginName, abilityName, slot))
								{
									return Plugin_Continue;
								}
								break;
							}
						}
						delete livesArray;
					}
				}
				while(abilityKv.GotoNextKey());
				abilityKv.GoBack();
			}
			while(abilityKv.GotoNextKey());

			delete abilityKv;
		}

		char sound[PLATFORM_MAX_PATH];
		if(FindSound("ability", sound, sizeof(sound), boss, true))
		{
			EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound, client);
		}
		emitRageSound[boss]=true;

		if(BossMaxRageCharge[boss] < 0.0)
			BossCharge[boss][0] = 0.0;
		else 
			AddBossCharge(boss, 0, slot == 0 ? -100.0 : -200.0);

		int type = slot == 0 ? SkillType_Rage : SkillType_200Rage;
		float duration = GetBossSkillDurationMax(boss, type);
		BossSkillDuration[boss][type] = GetGameTime() + duration;

		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnSuicide(int client, const char[] command, int args)
{
	bool canBossSuicide=cvarBossSuicide.BoolValue;
	if(Enabled && IsBoss(client) && (canBossSuicide ? CheckRoundState()!=FF2RoundState_Setup : true) && CheckRoundState()!=FF2RoundState_RoundEnd)
	{
		CPrintToChat(client, "{olive}[FF2]{default} %t", canBossSuicide ? "Boss Suicide Pre-round" : "Boss Suicide Denied");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnChangeClass(int client, const char[] command, int args)
{
	if(Enabled && IsBoss(client) && IsPlayerAlive(client))
	{
		//Don't allow the boss to switch classes but instead set their *desired* class (for the next round)
		char playerclass[16];
		GetCmdArg(1, playerclass, sizeof(playerclass));
		if(TF2_GetClass(playerclass)!=TFClass_Unknown)  //Ignore cases where the client chooses an invalid class through the console
		{
			SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", TF2_GetClass(playerclass));
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnJoinTeam(int client, const char[] command, int args)
{
	// Only block the commands when FF2 is actively running
	if(!Enabled || RoundCount<arenaRounds || CheckRoundState()==FF2RoundState_Loading)
	{
		return Plugin_Continue;
	}

	// autoteam doesn't come with arguments
	if(StrEqual(command, "autoteam", false))
	{
		TFTeam team=TFTeam_Unassigned, oldTeam=TF2_GetClientTeam(client);
		if(IsBoss(client))
		{
			team=BossTeam;
		}
		else
		{
			team=OtherTeam;
		}

		if(team!=oldTeam)
		{
			TF2_ChangeClientTeam(client, team);
		}
		return Plugin_Handled;
	}

	if(!args)
	{
		return Plugin_Continue;
	}

	TFTeam team=TFTeam_Unassigned, oldTeam=TF2_GetClientTeam(client);
	char teamString[10];
	GetCmdArg(1, teamString, sizeof(teamString));

	if(StrEqual(teamString, "red", false))
	{
		team=TFTeam_Red;
	}
	else if(StrEqual(teamString, "blue", false))
	{
		team=TFTeam_Blue;
	}
	else if(StrEqual(teamString, "auto", false))
	{
		team=OtherTeam;
	}
	else if(StrEqual(teamString, "spectate", false) && !IsBoss(client) && FindConVar("mp_allowspectators").BoolValue)
	{
		team=TFTeam_Spectator;
	}

	if(team==BossTeam && !IsBoss(client))
	{
		team=OtherTeam;
	}
	else if(team==OtherTeam && IsBoss(client))
	{
		team=BossTeam;
	}

	if(team>TFTeam_Unassigned && team!=oldTeam)
	{
		TF2_ChangeClientTeam(client, team);
	}

	if(CheckRoundState()!=FF2RoundState_RoundRunning && !IsBoss(client) || !IsPlayerAlive(client))  //No point in showing the VGUI if they can't change teams
	{
		switch(team)
		{
			case TFTeam_Red:
			{
				ShowVGUIPanel(client, "class_red");
			}
			case TFTeam_Blue:
			{
				ShowVGUIPanel(client, "class_blue");
			}
		}
	}
	return Plugin_Handled;
}

public Action OnPlayerDeath(Event event, const char[] eventName, bool dontBroadcast)
{
	Goomba_OnPlayerDeath(event);

	if(!Enabled || CheckRoundState()!=FF2RoundState_RoundRunning)
	{
		return Plugin_Continue;
	}

	int client=GetClientOfUserId(event.GetInt("userid")), attacker=GetClientOfUserId(event.GetInt("attacker"));
	char sound[PLATFORM_MAX_PATH];
	CreateTimer(0.1, CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
	DoOverlay(client, "");
	if(!IsBoss(client))
	{
		if(!(event.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER))
		{
			OverCharge[client] = 0.0;
			CreateTimer(1.0, Timer_Damage, g_hBasePlayer[client], TIMER_FLAG_NO_MAPCHANGE);
		}

		if(IsBoss(attacker))
		{
			int boss=GetBossIndex(attacker);
			if(firstBlood)  //TF_DEATHFLAG_FIRSTBLOOD is broken
			{
				if(FindSound("first blood", sound, sizeof(sound), boss))
				{
					EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound);
				}
				firstBlood=false;
			}

			if(RedAlivePlayers!=1)  //Don't conflict with end-of-round sounds
			{
				if(GetRandomInt(0, 1) && FindSound("kill", sound, sizeof(sound), boss))
				{
					EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound);
				}
				else if(!GetRandomInt(0, 2))  //1/3 chance for "sound_kill_<class>"
				{
					char classnames[][]={"", "scout", "sniper", "soldier", "demoman", "medic", "heavy", "pyro", "spy", "engineer"};
					char playerclass[32];
					Format(playerclass, sizeof(playerclass), "kill %s", classnames[TF2_GetPlayerClass(client)]);
					if(FindSound(playerclass, sound, sizeof(sound), boss))
					{
						EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound);
					}
				}
			}

			if(GetGameTime()<=KSpreeTimer[boss])
			{
				KSpreeCount[boss]++;
			}
			else
			{
				KSpreeCount[boss]=1;
			}

			if(KSpreeCount[boss]==3)
			{
				if(FindSound("kspree", sound, sizeof(sound), boss))
				{
					EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound);
				}
				KSpreeCount[boss]=0;
			}
			else
			{
				KSpreeTimer[boss]=GetGameTime()+5.0;
			}
		}
	}
	else
	{
		int boss=GetBossIndex(client);
		if((event.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER) > 0)
		{
			// NOTE: This is for avoid instant death bug.
			// DO NOT BROADCAST TO THE CLIENT WHO CAUSES THIS BUG.
			// .. And this might not only boss player. it also happens when obtains dead ringer during the round.
			if(boss != -1)
			{
				dontBroadcast = true;

				for(int target = 1; target <= MaxClients; target++)
				{
					if(IsClientInGame(target) && client != target)
						event.FireToClient(target);
				}

				return Plugin_Changed;
			}

			return Plugin_Continue;
		}

		if(FindSound("lose", sound, sizeof(sound), boss))
		{
			EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound);
		}

		BossHealth[boss]=0;
		UpdateHealthBar(true);

		Stabbed[boss]=0;
		Marketed[boss]=0;
		LastCharge[boss]=0.0;
		ComboPunchCount[boss]=0;
	}

	if(TF2_GetPlayerClass(client)==TFClass_Engineer && !(event.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER))
	{
		char name[PLATFORM_MAX_PATH];
		FakeClientCommand(client, "destroy 2");
		for(int entity=MaxClients+1; entity<MAXENTITIES; entity++)
		{
			if(IsValidEntity(entity))
			{
				GetEntityClassname(entity, name, sizeof(name));
				if(!StrContains(name, "obj_sentrygun") && (GetEntPropEnt(entity, Prop_Send, "m_hBuilder")==client))
				{
					SetVariantInt(GetEntPropEnt(entity, Prop_Send, "m_iMaxHealth")+1);
					AcceptEntityInput(entity, "RemoveHealth");

					Event eventRemoveObject=CreateEvent("object_removed", true);
					eventRemoveObject.SetInt("userid", GetClientUserId(client));
					eventRemoveObject.SetInt("index", entity);
					eventRemoveObject.Fire();
					AcceptEntityInput(entity, "kill");
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action Timer_Damage(Handle timer, FF2BaseEntity player)
{
	int client = EntRefToEntIndex(player.Ref);
	if(IsValidClient(client, false))
	{
		CPrintToChat(client, "{olive}[FF2] %t.{default}", "Total Damage Dealt", player.Damage);
	}
	return Plugin_Continue;
}

public Action OnObjectDeflected(Event event, const char[] name, bool dontBroadcast)
{
	if(!Enabled || event.GetInt("weaponid"))  //0 means that the client was airblasted, which is what we want
	{
		return Plugin_Continue;
	}

	int boss=GetBossIndex(GetClientOfUserId(event.GetInt("ownerid")));
	if(boss != -1)
	{
		AddBossCharge(boss, 0, 7.0); //TODO: Allow this to be customizable

		if(executed)
			timeleft += 5.0;
	}
	return Plugin_Continue;
}

public Action OnJarate(UserMsg msg_id, Handle bf, const int[] players, int playersNum, bool reliable, bool init)
{
	int client=BfReadByte(bf);
	int victim=BfReadByte(bf);
	int boss=GetBossIndex(victim);
	if(boss!=-1)
	{
		int jarate=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(jarate!=-1)
		{
			int index=GetEntProp(jarate, Prop_Send, "m_iItemDefinitionIndex");
			if((index==58 || index==1083 || index==1105) && GetEntProp(jarate, Prop_Send, "m_iEntityLevel")!=-122)  //-122 is the Jar of Ants which isn't really Jarate
				AddBossCharge(boss, 0, -8.0); //TODO: Allow this to be customizable
		}
	}
	return Plugin_Continue;
}

public Action OnDeployBackup(Event event, const char[] name, bool dontBroadcast)
{
	if(Enabled && event.GetInt("buff_type")==2)
	{
		FF2Flags[GetClientOfUserId(event.GetInt("buff_owner"))]|=FF2FLAG_ISBUFFED;
	}
	return Plugin_Continue;
}

public Action OnPlayerHealed(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("patient"));
	int iHealer = GetClientOfUserId(event.GetInt("healer"));
	int healed = event.GetInt("amount");
	int boss = GetBossIndex(client);

	if(CheckRoundState() != FF2RoundState_RoundRunning)
		return Plugin_Continue;

	// TODO: 자가치유 가능 여부 설정
	if(TF2_GetClientTeam(client) != BossTeam && IsBoss(client))
	{
		BossHealth[boss] += healed;

		int maxHealth = BossHealthMax[boss] * BossLivesMax[boss];
		if(BossHealth[boss] > maxHealth)
		{
			BossHealth[boss] = maxHealth;
		}
		UpdateHealthBar(false);
	}
	else if(client != iHealer && iHealer != 0)
	{
		FF2BaseEntity healer = g_hBasePlayer[iHealer];
		healer.Assist += healed/2;
	}

	return Plugin_Continue;
}

public Action OnMedigunBlockDamage(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(TF2_GetClientTeam(client) == BossTeam)
		return Plugin_Continue;

	float damage = event.GetFloat("damage");
	float currentCharge = GetEntPropFloat(client, Prop_Send, "m_flRageMeter");
	int shieldLevel = TF2Attrib_HookValueInt(0, "generate_rage_on_heal", client),
		shieldHp = 800 + (400 * (shieldLevel - 1));

	SetEntPropFloat(client, Prop_Send, "m_flRageMeter", currentCharge - (damage / shieldHp * 100.0));
	return Plugin_Continue;
}

public Action CheckAlivePlayers(Handle timer)
{
	if(CheckRoundState()==FF2RoundState_RoundEnd)
	{
		return Plugin_Continue;
	}

	static int lastAlive = 0;
	RedAlivePlayers=0;
	BlueAlivePlayers=0;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			if(TF2_GetClientTeam(client)==OtherTeam)
			{
				RedAlivePlayers++;
			}
			else if(TF2_GetClientTeam(client)==BossTeam)
			{
				BlueAlivePlayers++;
			}
		}
	}

	if(timer != INVALID_HANDLE)
	{
		Call_StartForward(OnAlivePlayersChanged);  //Let subplugins know that the number of alive players just changed
		Call_PushCell(RedAlivePlayers);
		Call_PushCell(BlueAlivePlayers);
		Call_Finish();

		if(!RedAlivePlayers)
		{
			ForceTeamWin(BossTeam);
		}
		else if((RedAlivePlayers==1 && lastAlive!=1) && BlueAlivePlayers && Boss[0])
		{
			char sound[PLATFORM_MAX_PATH];
			if(FindSound("lastman", sound, sizeof(sound)))
			{
				EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound);
			}
		}
	}

	if(CheckRoundState() < FF2RoundState_RoundRunning)
		return Plugin_Continue;

	// TODO: @limit ConVar
	float actualTimeleft, limit = 90.0;
	if(timeType == FF2Timer_WaveTimer)
	{
		int remainWave = maxWave - currentWave;
		actualTimeleft = (maxTime * (remainWave)) + timeleft;
	}
	else
		actualTimeleft = timeleft;

	// PrintToChatAll("StartingPlayers: %d, AliveToEnable: %d, RedAlivePlayers: %d", StartingPlayers, AliveToEnable, RedAlivePlayers);

	bool aliveOpen = (!PointType && (StartingPlayers >= (AliveToEnable * 2) && RedAlivePlayers <= AliveToEnable)),
		timeOpen = actualTimeleft <= limit;

	if(!executed && (aliveOpen || timeOpen))
	{
		PrintHintTextToAll("%t", "Point Unlocked", AliveToEnable, RoundFloat(limit));

		char sound[64];
		if(GetRandomInt(0, 1))
		{
			Format(sound, sizeof(sound), "vo/announcer_am_capenabled0%i.mp3", GetRandomInt(1, 4));
		}
		else
		{
			Format(sound, sizeof(sound), "vo/announcer_am_capincite0%i.mp3", GetRandomInt(0, 1) ? 1 : 3);
		}
		EmitSoundToAll(sound);

		SetControlPoint(true);
		// SetArenaCapTime(20);
		executed=true;
	}
	else if(executed && (!aliveOpen && !timeOpen))
	{
		SetControlPoint(false);
		executed=false;
	}

	lastAlive = RedAlivePlayers;
	return Plugin_Continue;
}

public Action Timer_DrawGame(Handle timer)
{
	if(CheckRoundState()!=FF2RoundState_RoundRunning || timeleft <= -1.0)
	{
		return Plugin_Stop;
	}

	FF2HudDisplay hudDisplay;

	CheckAlivePlayers(INVALID_HANDLE);
	timeleft-=0.1; // TODO: Forward

	char timeDisplay[6], waveDisplay[20];
	int min=RoundToFloor(timeleft / 60.0), sec=RoundToCeil(timeleft)-(min*60)-1;
	int timeInteger = RoundFloat(timeleft);
	float fraction = FloatFraction(timeleft);

	static int lastNotice = -1;

	if(timeType == FF2Timer_WaveTimer)
		Format(waveDisplay, sizeof(waveDisplay), "WAVE: %d / %d", currentWave, maxWave);

	if(timeleft<60.0)
	{
		Format(timeDisplay, sizeof(timeDisplay), "%.1f", timeleft);
	}
	else
	{
		if(min < 10)
			Format(timeDisplay, sizeof(timeDisplay), "0%i", min);
		else
			IntToString(min, timeDisplay, sizeof(timeDisplay));

		if(sec < 10)
			Format(timeDisplay, sizeof(timeDisplay), "%s:0%i", timeDisplay, sec);
		else
			Format(timeDisplay, sizeof(timeDisplay), "%s:%i", timeDisplay, sec);
	}

	SetHudTextParams(-1.0, 0.17, 0.11, 255, 255, 255, 255);
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && !IsFakeClient(client))
		{
			PlayerHudQueue[client].SetName("Timer");
			SetGlobalTransTarget(client);

			if(timeType == FF2Timer_WaveTimer)
			{
				hudDisplay=FF2HudDisplay.CreateDisplay("Wave", waveDisplay);
				PlayerHudQueue[client].AddHud(hudDisplay, client);
			}

			hudDisplay=FF2HudDisplay.CreateDisplay("Game Timer", timeDisplay);
			PlayerHudQueue[client].AddHud(hudDisplay, client);

			PlayerHudQueue[client].ShowSyncHudQueueText(client, null, FF2HudChannel_Timer);
			PlayerHudQueue[client].DeleteAllDisplay();
		}
	}

	bool notice = false;
	switch(timeType)
	{
		case FF2Timer_WaveTimer:
		{
			if(currentWave == maxWave)
				notice = true;
		}
		default:
		{
			notice = true;
		}
	}

	if(lastNotice != timeInteger && fraction < 0.1)
	{
		lastNotice = timeInteger;

		if(notice)
		{
			switch(timeInteger)
			{
				case 300:
				{
					EmitSoundToAll("vo/announcer_ends_5min.mp3");
				}
				case 120:
				{
					EmitSoundToAll("vo/announcer_ends_2min.mp3");
				}
				case 60:
				{
					EmitSoundToAll("vo/announcer_ends_60sec.mp3");
				}
				case 30:
				{
					EmitSoundToAll("vo/announcer_ends_30sec.mp3");
				}
				case 10:
				{
					EmitSoundToAll("vo/announcer_ends_10sec.mp3");
				}
				case 1, 2, 3, 4, 5:
				{
					char sound[PLATFORM_MAX_PATH];
					Format(sound, sizeof(sound), "vo/announcer_ends_%isec.mp3", timeInteger);
					EmitSoundToAll(sound);
				}
			}
		}


if(timeInteger == 0)
{
    if(timeType == FF2Timer_WaveTimer)
    {
        if(currentWave == maxWave)
        {
            // 여기서 플레이어 전원 죽이기
            for(int client = 1; client <= MaxClients; client++)
            {
                if(IsValidClient(client) && IsPlayerAlive(client))
                {
                    ForcePlayerSuicide(client);
                }
            }

            ForceTeamWin(TFTeam_Unassigned);
            return Plugin_Stop;
        }

        currentWave++;
        timeleft = maxTime;

        Call_StartForward(OnWaveStarted);
        Call_PushCell(currentWave);
        Call_Finish();

        return Plugin_Continue;
    }
    else
    {
        // 여기서 플레이어 전원 죽이기
        for(int client = 1; client <= MaxClients; client++)
        {
            if(IsValidClient(client) && IsPlayerAlive(client))
            {
                ForcePlayerSuicide(client);
            }
        }

        ForceTeamWin(TFTeam_Unassigned);
    }

    return Plugin_Stop;
}


	}

	return Plugin_Continue;
}


bool AddRage = true;
public Action OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if(!Enabled || CheckRoundState()!=FF2RoundState_RoundRunning)
		return Plugin_Continue;

	//TODO: Can this be removed?
	Debug("allseecrit removed");
	event.SetBool("allseecrit", false);

	int iClient = GetClientOfUserId(GetEventInt(event, "userid")),
		iAttacker = GetClientOfUserId(GetEventInt(event, "attacker")),
		damage = GetEventInt(event, "damageamount"),
		boss = GetBossIndex(iClient);

	// FF2BaseEntity client = g_hBasePlayer[iClient];

	if(IsValidClient(iClient) && IsValidClient(iAttacker)
		&& iAttacker != iClient)
	{
		if(TF2_GetClientTeam(iAttacker) != BossTeam)
		{
			FF2BaseEntity attacker = g_hBasePlayer[iAttacker];

			if(IsBoss(iClient))
				attacker.Damage += damage;
			else
				attacker.Assist += damage;
		}
		// 보스 피해 계산
		int targetBoss;
		if((targetBoss = GetBossIndex(iClient)) != -1 && AddRage)
		{
			float adding = damage * 100.0 / BossRageDamage[targetBoss],
				temp = adding; 
			Action action = Plugin_Continue;

			Call_StartForward(OnAddRage);
			Call_PushCell(boss);
			Call_PushFloatRef(temp);
			Call_Finish(action);

			if(action == Plugin_Changed)
				adding = temp;
			
			if(action != Plugin_Handled
				&& action != Plugin_Stop)
				AddBossCharge(targetBoss, 0, adding);
		}
	}
	
	if(!IsBoss(iClient))	return Plugin_Continue;

	for(int lives=1; lives<BossLives[boss]; lives++)
	{
		if(BossHealth[boss]-damage<=BossHealthMax[boss]*lives)
		{
			SetEntityHealth(iClient, (BossHealth[boss]-damage)-BossHealthMax[boss]*(lives-1));  //Set the health early to avoid the boss dying from fire, etc.

			Action action;
			int bossLives=BossLives[boss];  //Used for the forward
			Call_StartForward(OnLoseLife);
			Call_PushCell(boss);
			Call_PushCellRef(bossLives);
			Call_PushCell(BossLivesMax[boss]);
			Call_Finish(action);
			if(action==Plugin_Stop || action==Plugin_Handled)  //Don't allow any damage to be taken and also don't let the life-loss go through
			{
				SetEntityHealth(iClient, BossHealth[boss]);
				return Plugin_Continue;
			}
			else if(action==Plugin_Changed)
			{
				if(bossLives>BossLivesMax[boss])  //If the new amount of lives is greater than the max, set the max to the new amount
				{
					BossLivesMax[boss]=bossLives;
				}
				BossLives[boss]=lives=bossLives;
			}

			char ability[PLATFORM_MAX_PATH];  //FIXME: Create a new variable for the translation string later on
			KeyValues kv = GetCharacterKV(character[boss]);
			kv.Rewind();
			if(kv.JumpToKey("abilities"))
			{
				kv.GotoFirstSubKey();
				do
				{
					char pluginName[64];
					kv.GetSectionName(pluginName, sizeof(pluginName));
					kv.GotoFirstSubKey();
					do
					{
						char abilityName[64];
						kv.GetSectionName(abilityName, sizeof(abilityName));
						if(kv.GetNum("slot")!=-1) // Only activate for life-loss abilities
						{
							continue;
						}

						kv.GetString("life", ability, 10, "");
						if(!ability[0]) // Just a regular ability that doesn't care what life the boss is on
						{
							UseAbility(boss, pluginName, abilityName, -1);
						}
						else // But these do
						{
							char temp[3];
							ArrayList livesArray=CreateArray(sizeof(temp));
							int count=ExplodeStringIntoArrayList(ability, " ", livesArray, sizeof(temp));
							for(int n; n<count; n++)
							{
								livesArray.GetString(n, temp, sizeof(temp));
								if(StringToInt(temp)==BossLives[boss])
								{
									UseAbility(boss, pluginName, abilityName, -1);
									break;
								}
							}
							delete livesArray;
						}
					}
					while(kv.GotoNextKey());
					kv.GoBack();
				}
				while(kv.GotoNextKey());
			}
			BossLives[boss]=lives;

			char bossName[64];
			strcopy(ability, sizeof(ability), BossLives[boss]==1 ? "Boss with 1 Life Left" : "Boss with Multiple Lives Left");

			for(int target=1; target<=MaxClients; target++)
			{
				if(IsValidClient(target) && !(FF2Flags[target] & FF2FLAG_HUDDISABLED))
				{
					GetBossName(boss, bossName, sizeof(bossName), target);
					PrintCenterText(target, "%t", ability, bossName, BossLives[boss]);
				}
			}

			if(BossLives[boss]==1 && FindSound("last life", ability, sizeof(ability), boss))
			{
				EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, ability);
			}
			else if(FindSound("next life", ability, sizeof(ability), boss))
			{
				EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, ability);
			}

			float duration = GetBossSkillDurationMax(boss, SkillType_LostLife);
			BossSkillDuration[boss][SkillType_LostLife] = GetGameTime() + duration;

			break;
		}
	}

	BossHealth[boss]-=damage;

	int[] healers=new int[MaxClients+1];
	int healerCount = 0;
	for(int target=1; target<=MaxClients; target++)
	{
		if(IsValidClient(target) && IsPlayerAlive(target) && (GetHealingTarget(target, true) == iAttacker))
		{
			healers[healerCount++] = target;
		}
	}

	for(int target = 0; target < healerCount; target++)
	{
		if(IsValidClient(healers[target]) && IsPlayerAlive(healers[target]))
		{
			FF2BaseEntity healer = g_hBasePlayer[healers[target]];

			if(damage<10 || uberTarget[healers[target]] == iAttacker)
				healer.Assist += damage;
			else
				healer.Assist += damage / (healerCount + 1);
		}
	}

	UpdateHealthBar(true);
	return Plugin_Continue;
}

void OnBossSmackMiss(int owner, int boss, int weapon)
{

}

public Action OverChargeTimer(Handle timer)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || !IsPlayerAlive(client))
			continue;

		if (!shield[client])
			continue;

		int index = GetEntProp(shield[client], Prop_Send, "m_iItemDefinitionIndex");

		// Splendid Screen 제외 가능
		if (index == 57)
			continue;

		OverCharge[client] = min(100.0, OverCharge[client] + 5.0);
	}

	return Plugin_Continue;
}

public Action OnTakeDamageAlive(int client, int& iAttacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(!Enabled || !IsValidEntity(iAttacker))
	{
		return Plugin_Continue;
	}

	AddRage = true;
	HitOnSmack = true;
	bool bChanged=false, currencyDistributed = false;

	if(CheckRoundState()==FF2RoundState_Setup ||
		(IsBoss(client)	&& TF2_IsPlayerInvulnerable(client)))
	{
		damage=0.0;
		return Plugin_Changed;
	}

	if(iAttacker <= 0 || client == iAttacker)
	{
		if(IsBoss(client))
		{
			int boss = GetBossIndex(client);
			KeyValues bossKv = GetBossKV(boss);
			bossKv.Rewind();

			// Debug("%d, %d, %d, %.1f", client, iAttacker, inflictor, damage);
			if(bossKv.GetNum("enable selfdamage", 0) > 0 && iAttacker > 0)
			{
				// Debug("selfdamage");
				bool noSelfDmg = TF2Attrib_HookValueInt(0, "no_self_blast_dmg", iAttacker) > 0;
				if(noSelfDmg)
				{
					damage=0.0;
					return Plugin_Changed;
				}

				float blastDmgRatio = TF2Attrib_HookValueFloat(1.0, "blast_dmg_to_self", iAttacker);
				if((damagetype & DMG_BLAST) && blastDmgRatio != 1.0)
				{
					damage *= blastDmgRatio;
					return Plugin_Changed;
				}

				return Plugin_Continue;
			}

			damage=0.0;
			return Plugin_Changed;
		}
	}

	int boss=GetBossIndex(client);
	float position[3];
	GetEntPropVector(iAttacker, Prop_Send, "m_vecOrigin", position);
	
	if(IsBoss(iAttacker))
	{
		if(damagecustom == TF_CUSTOM_BACKSTAB)
		{
			damage = GetMeleeDamage(weapon, TFClass_Spy);

			damagetype ^= DMG_CRIT|DMG_RADIUS_MAX;
			damagecustom = 0;

			bChanged = true;
		}
		if(IsValidClient(client) && !IsBoss(client) && !TF2_IsPlayerInCondition(client, TFCond_Bonked))
		{
			if(TF2_IsPlayerInCondition(client, TFCond_DefenseBuffed))
			{
				ScaleVector(damageForce, 9.0);

				// In real: realDamage: 606(202), damage = 39.2
				// realDamage: 130.9, damage: 39.2
				// rage: 62.3, drain: 54.6

				float realDamage = damage * 1.53846; // player damamge -35%
				if(TF2_IsPlayerCritBuffed(iAttacker))
					realDamage *= 3.0;
				else if(TF2_IsPlayerInCondition(iAttacker, TFCond_Buffed))
					realDamage *= 1.35;				
				damage *= 0.3;

				int buffer = TF2Util_GetPlayerConditionProvider(client, TFCond_DefenseBuffed);
				if(!IsValidClient(buffer))	return Plugin_Changed;

				float multiplier = TF2Attrib_HookValueFloat(1.0, "mod_buff_duration", buffer), 
					rage = GetEntPropFloat(buffer, Prop_Send, "m_flRageMeter"),  
					drain = rage - (max(0.0, (realDamage - damage) / (1200.0 * multiplier)) * 100.0);
				SetEntPropFloat(buffer, Prop_Send, "m_flRageMeter", drain);

				// PrintToChatAll("realDamage: %.1f, damage: %.1f", realDamage, damage);
				// PrintToChatAll("rage: %.1f, drain: %.1f", rage, drain);

				return Plugin_Changed;
			}

			if(TF2_IsPlayerInCondition(client, TFCond_DefenseBuffMmmph))
			{
				damage*=9;
				TF2_AddCondition(client, TFCond_Bonked, 0.1);  //In other words, no damage is actually taken
				return Plugin_Changed;
			}

			if(TF2_IsPlayerInCondition(client, TFCond_CritMmmph))
			{
				damage*=0.25;
				return Plugin_Changed;
			}

			if(shield[client] && damage && (!TF2_IsPlayerInvulnerable(client)))
			{
				if(GetEntProp(shield[client], Prop_Send, "m_iItemDefinitionIndex")==57)
				{
					if(GetEntPropFloat(client, Prop_Send, "m_flItemChargeMeter", TFWeaponSlot_Secondary)>=100.0)
					{
						PlayShieldBreakSound(client, position, 0.7);
						SetEntPropFloat(client, Prop_Send, "m_flItemChargeMeter", 0.0, TFWeaponSlot_Secondary);
						return Plugin_Handled;
					}
					return Plugin_Continue;
				}
				else
				{
					float charge = GetEntPropFloat(client, Prop_Send, "m_flChargeMeter") - damage;
					SetEntPropFloat(client, Prop_Send, "m_flChargeMeter",
						max(0.0, charge));

					if(OverCharge[client] > 0.0)
					{
						float absorbed = min(damage, OverCharge[client]);
						OverCharge[client] -= absorbed;
						damage -= absorbed;
						bChanged = true;

						PlayShieldBreakSound(client, position, 0.7);
					}
				}
			}

			if(TF2_GetPlayerClass(client)==TFClass_Soldier)
			{
				bool valid = IsValidEntity((weapon=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary)));
				FF2BaseEntity victim = g_hBasePlayer[client];

				if(valid && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==226  //Battalion's Backup
				&& !(victim.Flags & FF2FLAG_ISBUFFED))
				{
					float charge = GetEntPropFloat(client, Prop_Send, "m_flRageMeter") + (damage * 0.75);
					SetEntPropFloat(client, Prop_Send, "m_flRageMeter",
						charge > 100.0 ? 100.0 : charge);
				}
			}
		}
	}
	else
	{
		FF2BaseEntity victim = g_hBasePlayer[client];

		float victimPosition[3];
		GetEntPropVector(iAttacker, Prop_Send, "m_vecOrigin", position);
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", victimPosition);
		if(boss!=-1)
		{
			if(iAttacker<=MaxClients)
			{
				int index;
				char classname[64];
				if(IsValidEntity(weapon) && weapon>MaxClients && iAttacker<=MaxClients)
				{
					GetEntityClassname(weapon, classname, sizeof(classname));
					if(!StrContains(classname, "eyeball_boss"))  //Dang spell Monoculuses
					{
						index=-1;
						Format(classname, sizeof(classname), "");
					}
					else
					{
						index=GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
					}
				}
				else
				{
					index=-1;
					Format(classname, sizeof(classname), "");
				}

				/*if(kvWeaponMods.JumpToKey("onhit"))
				{
					//TODO
				}

				if(kvWeaponMods.JumpToKey("ontakedamage"))
				{
					//TODO
				}*/

				//Sniper rifles aren't handled by the switch/case because of the amount of reskins there are
				if(StrContains(classname, "tf_weapon_sniperrifle")!=-1)
				{
					if(CheckRoundState()!=FF2RoundState_RoundEnd)
					{
						float charge=(IsValidEntity(weapon) && weapon>MaxClients ? GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage") : 0.0);
						if(index==752)  //Hitman's Heatmaker
						{
							float focus=10+(charge/10);
							if(TF2_IsPlayerInCondition(iAttacker, TFCond_FocusBuff))
							{
								focus/=3;
							}
							float rage=GetEntPropFloat(iAttacker, Prop_Send, "m_flRageMeter");
							SetEntPropFloat(iAttacker, Prop_Send, "m_flRageMeter", (rage+focus>100) ? 100.0 : rage+focus);
						}
						else if(index!=230 && index!=402 && index!=526 && index!=30665)  //Sydney Sleeper, Bazaar Bargain, Machina, Shooting Star
						{
							float time=(GlowTimer[boss]>10 ? 1.0 : 2.0);
							time+=(GlowTimer[boss]>10 ? (GlowTimer[boss]>20 ? 1.0 : 2.0) : 4.0)*(charge/100.0);
							SetClientGlow(Boss[boss], time);
							if(GlowTimer[boss]>30.0)
							{
								GlowTimer[boss]=30.0;
							}
						}

						float distance = GetVectorDistance(position, victimPosition),
							multiplier = ((min(distance, 8000.0) - 8000.0) * -1.0) / 8000.0;

						// NO CRIT
						float damageAdjust = max(3.0 * multiplier, 0.8);
						if(!(damagetype & DMG_CRIT) /*&& !TF2_IsPlayerInCondition(iAttacker, TFCond_Buffed)*/)
							damage *= damageAdjust;
						// MINI CRIT.. Just in case.
						else if((damagetype & DMG_CRIT) && TF2_IsPlayerInCondition(iAttacker, TFCond_Buffed) && !TF2_IsPlayerCritBuffed(iAttacker))
							damage *= damageAdjust;

						bChanged = true;
						currencyDistributed = true;
					}
				}

				// float charge = GetEntPropFloat(iAttacker, Prop_Send, "m_flRageMeter") + (damage * 0.056);
				// SetEntPropFloat(iAttacker, Prop_Send, "m_flRageMeter",
				// 	charge > 100.0 ? 100.0 : charge);

				// 계집애 같은 사내의 소형 권총: 적중 시 자신에게 속도 버프 3초
				if(index == 773)
				{
					TF2_AddCondition(iAttacker, TFCond_SpeedBuffAlly, 3.0);
				}

				// 블루트자우거(36): 적중 시 0.3초 우버
				if(index == 36)
				{
					TF2_AddCondition(iAttacker, TFCond_Ubercharged, 0.3);
				}

				// 약물남용(412): 적중 시 이속 버프 3초
				if(index == 412)
				{
					TF2_AddCondition(iAttacker, TFCond_SpeedBuffAlly, 3.0);
				}

				// 가정파괴범: 적중 시 보스 3초 스턴
				if(index == 153 && IsBoss(client))
				{
					TF2_StunPlayer(client, 3.0, 0.0, TF_STUNFLAGS_SMALLBONK, iAttacker);
				}

				// 아이랜더(132)/아이언9번골프채(482,1082)/반블리츠(266)/클레이브모어(327)/퇴거통보(426): 적중 시 이속버프 3초
				if(index == 132 || index == 482 || index == 1082 || index == 266 || index == 327 || index == 426)
				{
					TF2_AddCondition(iAttacker, TFCond_SpeedBuffAlly, 3.0);
				}

				// 백버너(40/1146): 뒤에서 공격 시 데미지 x4
				{
					int activeWep = GetEntPropEnt(iAttacker, Prop_Send, "m_hActiveWeapon");
					if(IsValidEntity(activeWep))
					{
						int activeIdx = GetEntProp(activeWep, Prop_Send, "m_iItemDefinitionIndex");
						if((activeIdx == 40 || activeIdx == 1146) && IsBackAttack(iAttacker, client))
						{
							damage *= 4.0;
							bChanged = true;
						}
					}
				}

				if(damagecustom==TF_WEAPON_SENTRY_BULLET)
				{
					damagetype |= DMG_PREVENT_PHYSICS_FORCE;
					bChanged = true;
				}

				if(damagecustom==TF_CUSTOM_BURNING_ARROW)
				{
					bChanged = true;
					damage *= 2.0;
				}

				if(damagecustom == TF_CUSTOM_PLASMA_CHARGED)
				{
					bChanged = true;
					AddRage = false;

					float clip = TF2Attrib_HookValueFloat(1.0, "mult_clipsize_upgrade", weapon);
					damage *= clip;
				}

				if(damagecustom == TF_CUSTOM_CHARGE_IMPACT)
				{
					float charge = LastCharge[iAttacker];
					if(charge < 75.0)
					{
						bChanged = true;
						float score = (charge - 100.0) * -1.0,
							tempDamage = (damage * 2.0) + score;
						

						// IncrementHeadCount(iAttacker);
						ScaleVector(damageForce, 10.0 * (score * 0.01));
						damage = tempDamage;

						if(OverCharge[iAttacker] > 50.0
							&& SpecialAttackToBoss(iAttacker, boss, weapon, "shield_slam", tempDamage)
							!= Plugin_Handled)
						{
							float slamPower = OverCharge[iAttacker] * 0.04;
							damage *= slamPower * 0.5;

							TF2_StunPlayer(client, slamPower, 1.0, TF_STUNFLAG_BONKSTUCK, iAttacker);
							OverCharge[iAttacker] = 0.0;
						}
					}
				}

				switch(index)
				{
					// TODO: Apply Attributes
					case 37, 457:
					{
						if(TF2_IsPlayerInCondition(client, TFCond_OnFire))
						{
							float time = TF2Util_GetPlayerBurnDuration(client);
							damage *= 1.0 + (time / 8.0);
							TF2_RemoveCondition(client, TFCond_OnFire);
						}
						else
							damage *= 0.5;

						bChanged = true;
					}
					case 61, 1006:  //Ambassador, Festive Ambassador
					{
						if(damagecustom==TF_CUSTOM_HEADSHOT)
						{
							damage=255.0 > damage ? damage : 255.0;
							bChanged = true;
						}
					}
					case 132, 266, 482, 1082:  //Eyelander, HHHH, Nessie's Nine Iron, Festive Eyelander, Vita-Saw(?)
					{
						IncrementHeadCount(iAttacker);
					}
					case 142:
					{
						if(damagecustom==TF_CUSTOM_COMBO_PUNCH)
						{
							damage*=5.0;
							ScaleVector(damageForce, 5.0);

							EmitSoundToAll("potry_v2/se/homerun_bat.wav", client);
							EmitSoundToAll("potry_v2/se/homerun_bat.wav", client);
							EmitSoundToAll("potry_v2/se/homerun_bat.wav", client);

							SpecialAttackToBoss(iAttacker, boss, weapon, "combo_punch", damage);
							bChanged = true;
							currencyDistributed = true;
						}
					}
					case 214:  //Powerjack
					{
						int health=GetClientHealth(iAttacker);
						int newhealth=health+50;
						if(newhealth<=GetEntProp(iAttacker, Prop_Data, "m_iMaxHealth"))  //No overheal allowed
						{
							SetEntityHealth(iAttacker, newhealth);
						}

						if(TF2_IsPlayerInCondition(iAttacker, TFCond_OnFire))
						{
							TF2_RemoveCondition(iAttacker, TFCond_OnFire);
						}
					}
					case 310:  //Warrior's Spirit
					{
						int health=GetClientHealth(iAttacker);
						int newhealth=health+50;
						if(newhealth<=GetEntProp(iAttacker, Prop_Data, "m_iMaxHealth"))  //No overheal allowed
						{
							SetEntityHealth(iAttacker, newhealth);
						}

						if(TF2_IsPlayerInCondition(iAttacker, TFCond_OnFire))
						{
							TF2_RemoveCondition(iAttacker, TFCond_OnFire);
						}
					}
					case 317:  //Candycane
					{
						SpawnSmallHealthPackAt(client, TF2_GetClientTeam(iAttacker));
					}
					case 327:  //Claidheamh Mòr
					{
						int health=GetClientHealth(iAttacker);
						int newhealth=health+25;
						if(newhealth<=GetEntProp(iAttacker, Prop_Data, "m_iMaxHealth"))  //No overheal allowed
						{
							SetEntityHealth(iAttacker, newhealth);
						}

						if(TF2_IsPlayerInCondition(iAttacker, TFCond_OnFire))
						{
							TF2_RemoveCondition(iAttacker, TFCond_OnFire);
						}

						float charge=GetEntPropFloat(iAttacker, Prop_Send, "m_flChargeMeter");
						if(charge+25.0>=100.0)
						{
							SetEntPropFloat(iAttacker, Prop_Send, "m_flChargeMeter", 100.0);
						}
						else
						{
							SetEntPropFloat(iAttacker, Prop_Send, "m_flChargeMeter", charge+25.0);
						}
					}
					case 349:
					{
						if(TF2_IsPlayerInCondition(client, TFCond_OnFire))
						{
							damage*=2.0;
							bChanged = true;
						}
						else
						{
							TF2_IgnitePlayer(client, iAttacker);
						}
					}

					case 355:  //Fan O' War
					{
						AddBossCharge(boss, 0, -5.0);
					}
					case 357:  //Half-Zatoichi
					{
						SetEntProp(weapon, Prop_Send, "m_bIsBloody", 1);
						if(GetEntProp(iAttacker, Prop_Send, "m_iKillCountSinceLastDeploy")<1)
						{
							SetEntProp(iAttacker, Prop_Send, "m_iKillCountSinceLastDeploy", 1);
						}

						int health=GetClientHealth(iAttacker);
						int max=GetEntProp(iAttacker, Prop_Data, "m_iMaxHealth");
						int newhealth=health+50;
						if(health<max+100)
						{
							if(newhealth>max+100)
							{
								newhealth=max+100;
							}
							SetEntityHealth(iAttacker, newhealth);
						}

						if(TF2_IsPlayerInCondition(iAttacker, TFCond_OnFire))
						{
							TF2_RemoveCondition(iAttacker, TFCond_OnFire);
						}
					}
					case 416:  //Market Gardener (courtesy of Chdata)
					{
						FF2BaseEntity attacker = g_hBasePlayer[iAttacker];

						if(attacker.Flags & FF2FLAG_BLAST_JUMPING)
						{
							/*
							damage=(Pow(float(BossHealthMax[boss]), 0.27037)+512.0-(Marketed[client]/128.0*float(BossHealthMax[boss])));
							if(damage < 500.0)
								damage = 500.0; // x3
							*/

							damage = 200.0;

							float velocity[3]; // TODO: move this when anything use this in OnTakeDamage
							GetEntPropVector(iAttacker, Prop_Data, "m_vecVelocity", velocity);

							float score = FloatAbs(velocity[2]);
							if(velocity[2] < 0.0)
								score *= 0.65;

							float distance = GetVectorDistance(position, RocketJumpPosition[iAttacker]);
							score = score > distance ? score : distance;

							damage += score;
							damagetype|=DMG_CRIT;

							if(SpecialAttackToBoss(iAttacker, boss, weapon, "market_garden", damage) == Plugin_Handled)
								return Plugin_Handled;

							if(Marketed[client]<5)
							{
								Marketed[client]++;
							}

							PrintHintText(iAttacker, "%t", "Market Gardener");  //You just market-gardened the boss!
							PrintHintText(client, "%t", "Market Gardened");  //You just got market-gardened!

							EmitSoundToAll("potry_v2/se/homerun_bat.wav", client);
							EmitSoundToAll("potry_v2/se/homerun_bat.wav", client);
							EmitSoundToAll("potry_v2/se/homerun_bat.wav", client);
							// EmitSoundToClient(client, "player/doubledonk.wav", _, _, _, _, 0.6, _, _, position, _, false);
							bChanged = true;
							currencyDistributed = true;
						}
					}
					case 525, 595:  //Diamondback, Manmelter
					{
						if(GetEntProp(iAttacker, Prop_Send, "m_iRevengeCrits"))  //If a revenge crit was used, give a damage bonus
						{
							damage=255.0;
							bChanged = true;
						}
					}
					case 528:  //Short Circuit
					{
						if(circuitStun)
						{
							TF2_StunPlayer(client, circuitStun, 0.0, TF_STUNFLAGS_SMALLBONK|TF_STUNFLAG_NOSOUNDOREFFECT, iAttacker);
							EmitSoundToAll("weapons/barret_arm_zap.wav", client);
							EmitSoundToClient(client, "weapons/barret_arm_zap.wav");
						}
					}
					case 593:  //Third Degree
					{
						int healers[MAXPLAYERS];
						int healerCount;
						for(int healer; healer<=MaxClients; healer++)
						{
							if(IsValidClient(healer) && IsPlayerAlive(healer) && (GetHealingTarget(healer, true)==iAttacker))
							{
								healers[healerCount]=healer;
								healerCount++;
							}
						}

						for(int healer; healer<healerCount; healer++)
						{
							if(IsValidClient(healers[healer]) && IsPlayerAlive(healers[healer]))
							{
								int medigun=GetPlayerWeaponSlot(healers[healer], TFWeaponSlot_Secondary);
								if(IsValidEntity(medigun))
								{
									char medigunClassname[64];
									GetEntityClassname(medigun, medigunClassname, sizeof(medigunClassname));
									if(StrEqual(medigunClassname, "tf_weapon_medigun", false))
									{
										float uber=GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel")+(0.1/healerCount);
										if(uber>1.0)
										{
											uber=1.0;
										}
										SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", uber);
									}
								}
							}
						}
					}
					case 594:  //Phlogistinator
					{
						if(!TF2_IsPlayerInCondition(iAttacker, TFCond_CritMmmph))
						{
							damage/=2.0;
							bChanged = true;
						}
					}
/*
					case 1099:  //Tide Turner
					{
						SetEntPropFloat(iAttacker, Prop_Send, "m_flChargeMeter", 100.0);
					}
*/
					case 1104:
					{
						static float airStrikeDamage;
						airStrikeDamage+=damage;
						if(airStrikeDamage>=200.0)
						{
							SetEntProp(iAttacker, Prop_Send, "m_iDecapitations", GetEntProp(iAttacker, Prop_Send, "m_iDecapitations")+1);
							airStrikeDamage-=200.0;
						}
					}
				}

				if(damagecustom==TF_CUSTOM_BACKSTAB)
				{
					FF2BaseEntity attacker = g_hBasePlayer[iAttacker];

					bool isSlient = TF2Attrib_HookValueInt(0, "set_silent_killer", iAttacker) > 0;
					damage=BossHealthMax[boss]*(LastBossIndex()+1)*BossLivesMax[boss]*(0.12-Stabbed[boss]/80);
					// damage = BossHealth[boss] * 0.06;
					if(damage < 1500.0)
						damage = 1500.0; // x3
					damagetype|=DMG_CRIT;
					damagecustom=0;

					if(Stabbed[boss]<3)
					{
						Stabbed[boss]++;
					}

					if(!isSlient)
					{
						EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
						EmitSoundToClient(iAttacker, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
						EmitSoundToClient(client, "player/crit_received3.wav", _, _, _, _, 0.7, _, _, _, _, false);
						EmitSoundToClient(iAttacker, "player/crit_received3.wav", _, _, _, _, 0.7, _, _, _, _, false);
						EmitSoundToAll("potry_v2/se/homerun_bat.wav", client);
						EmitSoundToAll("potry_v2/se/homerun_bat.wav", client);
						EmitSoundToAll("potry_v2/se/homerun_bat.wav", client);
					}
					else
					{
						damage *= 0.4;
					}
					
					if(SpecialAttackToBoss(iAttacker, boss, weapon, "backstab", damage) == Plugin_Handled)
						return Plugin_Handled;

					SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()+2.0);
					SetEntPropFloat(iAttacker, Prop_Send, "m_flNextAttack", GetGameTime()+2.0);
					SetEntPropFloat(iAttacker, Prop_Send, "m_flStealthNextChangeTime", GetGameTime()+2.0);

					int viewmodel=GetEntPropEnt(iAttacker, Prop_Send, "m_hViewModel");
					if(viewmodel>MaxClients && IsValidEntity(viewmodel) && TF2_GetPlayerClass(iAttacker)==TFClass_Spy)
					{
						int melee=GetIndexOfWeaponSlot(iAttacker, TFWeaponSlot_Melee);
						int animation=41;
						switch(melee)
						{
							case 225, 356, 423, 461, 574, 649, 1071:  //Your Eternal Reward, Conniver's Kunai, Saxxy, Wanga Prick, Big Earner, Spy-cicle, Golden Frying Pan
							{
								animation=15;
							}
							case 638:  //Sharp Dresser
							{
								animation=31;
							}
						}
						SetEntProp(viewmodel, Prop_Send, "m_nSequence", animation);
					}

					if(!(attacker.Flags & FF2FLAG_HUDDISABLED))
						PrintHintText(iAttacker, "%t", "Backstab");

					if(!(victim.Flags & FF2FLAG_HUDDISABLED))
						PrintHintText(client, "%t", "Backstabbed");

					if(index==225 || index==574)  //Your Eternal Reward, Wanga Prick
					{
						CreateTimer(0.3, Timer_DisguiseBackstab, GetClientUserId(iAttacker), TIMER_FLAG_NO_MAPCHANGE);
					}
					else if(index==356)  //Conniver's Kunai
					{
						int health=GetClientHealth(iAttacker)+200;
						if(health>500)
						{
							health=500;
						}
						SetEntityHealth(iAttacker, health);
					}
					else if(index==461)  //Big Earner
					{
						SetEntPropFloat(iAttacker, Prop_Send, "m_flCloakMeter", 100.0);  //Full cloak
						TF2_AddCondition(iAttacker, TFCond_SpeedBuffAlly, 3.0);  //Speed boost
					}

					if(GetIndexOfWeaponSlot(iAttacker, TFWeaponSlot_Primary)==525)  //Diamondback
					{
						SetEntProp(iAttacker, Prop_Send, "m_iRevengeCrits", GetEntProp(iAttacker, Prop_Send, "m_iRevengeCrits")+2);
					}

					char sound[PLATFORM_MAX_PATH];
					if(FindSound("stabbed", sound, sizeof(sound), boss))
					{
						EmitSoundToAllExcept(FF2SOUND_MUTEVOICE, sound);
					}
					bChanged = true;
					currencyDistributed = true;
				}
				else if(damagecustom==TF_CUSTOM_TELEFRAG)
				{
					damagecustom=0;
					if(!IsPlayerAlive(iAttacker))
					{
						damage=1.0;
						bChanged = true;
					}
					damage=(BossHealth[boss]>9001 ? 9001.0 : float(GetEntProp(Boss[boss], Prop_Send, "m_iHealth"))+90.0);

					int iTeleowner=FindTeleOwner(iAttacker);
					FF2BaseEntity teleowner = g_hBasePlayer[iTeleowner],
						attacker = g_hBasePlayer[iAttacker];

					if(IsValidClient(iTeleowner) && iTeleowner != iAttacker)
					{
						teleowner.Assist += 9001 * 0.5;

						if(!(teleowner.Flags & FF2FLAG_HUDDISABLED))
						{
							PrintHintText(iTeleowner, "TELEFRAG ASSIST!  Nice job setting it up!");
						}
					}

					if(!(attacker.Flags & FF2FLAG_HUDDISABLED))
					{
						PrintHintText(iAttacker, "TELEFRAG! You are a pro!");
					}

					if(!(victim.Flags & FF2FLAG_HUDDISABLED))
					{
						PrintHintText(client, "TELEFRAG! Be careful around quantum tunneling devices!");
					}
					bChanged = true;
					// currencyDistributed = true; // THIS IS NOT SPECIAL ATTACK.
				}
				else if(damagecustom==TF_CUSTOM_BOOTS_STOMP)
				{
					damage*=5;
					bChanged = true;
				}

			}
			else
			{
				char classname[64];
				if(GetEntityClassname(iAttacker, classname, sizeof(classname)) && StrEqual(classname, "trigger_hurt", false))
				{
					Action action;
					Call_StartForward(OnTriggerHurt);
					Call_PushCell(boss);
					Call_PushCell(iAttacker);
					float damage2=damage;
					Call_PushFloatRef(damage2);
					Call_Finish(action);
					if(action!=Plugin_Stop && action!=Plugin_Handled)
					{
						if(action==Plugin_Changed)
						{
							damage=damage2;
						}

						if(damage>1500.0)
						{
							damage=1500.0;
						}

						BossHealth[boss]-=RoundFloat(damage);
						AddBossCharge(boss, 0, damage*100.0/BossRageDamage[boss]);

						if(BossHealth[boss]<=0)  //TODO: Wat
						{
							damage*=5;
						}
						return Plugin_Changed;
					}
					else
					{
						return action;
					}
				}
			}
		}
/*
		else
		{
			int index=(IsValidEntity(weapon) && weapon>MaxClients && attacker<=MaxClients ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);

			switch(index)
			{

			}
		}
*/
	}
	return bChanged ? Plugin_Changed : Plugin_Continue;
}

void KillStreakCheck(int attackerIndex, int client, int boss, float damage, bool currencyDistributed = false)
{	
}

public Action TF2_OnPlayerTeleport(int client, int teleporter, bool& result)
{
	if(Enabled && IsBoss(client))
	{
		result = bossTeleportation;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action OnGetMaxHealth(int client, int& maxHealth)
{
	if(Enabled && IsBoss(client))
	{
		int boss=GetBossIndex(client);
		SetEntityHealth(client, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1));
		maxHealth=BossHealthMax[boss];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action Timer_DisguiseBackstab(Handle timer, int userid)
{
	int client=GetClientOfUserId(userid);
	if(IsValidClient(client, false))
	{
		RandomlyDisguise(client);
	}
	return Plugin_Continue;
}

stock void AssignTeam(int client, TFTeam team)
{
	if(!GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass"))  //Living spectator check: 0 means that no class is selected
	{
		Debug("%N does not have a desired class!", client);
		if(IsBoss(client))
		{
			SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", KvGetNum(GetCharacterKV(character[Boss[client]]), "class", 1));  //So we assign one to prevent living spectators
		}
		else
		{
			Debug("%N was not a boss and did not have a desired class!  Please report this to https://github.com/50DKP/FF2-Official");
		}
	}

	SetEntProp(client, Prop_Send, "m_lifeState", 2);
	TF2_ChangeClientTeam(client, team);
	TF2_RespawnPlayer(client);

	if(GetEntProp(client, Prop_Send, "m_iObserverMode") && IsPlayerAlive(client))  //Welp
	{
		Debug("%N is a living spectator!  Please report this to https://github.com/50DKP/FF2-Official", client);
		if(IsBoss(client))
		{
			TF2_SetPlayerClass(client, view_as<TFClassType>(KvGetNum(GetCharacterKV(character[Boss[client]]), "class", 1)));
		}
		else
		{
			Debug("Additional information: %N was not a boss");
			TF2_SetPlayerClass(client, TFClass_Scout);
		}
		TF2_RespawnPlayer(client);
	}
}

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool& result)
{
	if(!Enabled || CheckRoundState() != FF2RoundState_RoundRunning)
		return Plugin_Continue;

	if(IsBoss(client) && !TF2_IsPlayerCritBuffed(client) && !BossCrits)
	{
		result=false;
		return Plugin_Changed;
	}
	else if(!IsBoss(client))
	{
		int index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");

		switch(index)
		{
			case 307:
			{
				if(allowedDetonations > 0 && detonations[client] < allowedDetonations)
				{
					detonations[client]++;
					PrintHintText(client, "%t", "Detonations Left", allowedDetonations-detonations[client]);
				}

				if(allowedDetonations == 0 || allowedDetonations - detonations[client] > 0)  //Don't reset their caber if they have 0 detonations left
				{
					SetEntProp(weapon, Prop_Send, "m_bBroken", 0);
					SetEntProp(weapon, Prop_Send, "m_iDetonated", 0);
				}
			}
		}
	}

	return Plugin_Continue;
}

stock int GetClientWithMostQueuePoints(bool[] omit)
{
	int winner = 0, maxQueue = -1;
	for(int client = 1; client <= MaxClients; client++)
	{
		FF2BasePlayer player = GetBasePlayer(client), 
			winnerPlayer = GetBasePlayer(winner);	
		
		if(IsValidClient(client) && !omit[client])
		{
			if((winnerPlayer == null || player.QueuePoints >= maxQueue) 
				&& (SpecForceBoss || TF2_GetClientTeam(client) > TFTeam_Spectator))
			{
				winner = client;
				maxQueue = player.QueuePoints;
			}
		}
	}

	return winner;
}

stock int RandomlySelectClient(bool force, bool[] omit)
{
	int count;
	ArrayList array = new ArrayList();

	for(int client = 1; client <= MaxClients; client++)
	{
		FF2BasePlayer player = GetBasePlayer(client);

		if(IsValidClient(client) && !omit[client])
		{
			if(SpecForceBoss
				|| (TF2_GetClientTeam(client)>TFTeam_Spectator
					&& (force || (!force && player.QueuePoints >= 0))))
			{
				array.Push(client);
				count++;
			}
		}
	}

	int winner = -1;
	if(count > 0)
		winner = array.Get(GetRandomInt(0, count-1));

	delete array;

	return winner;
}

stock int LastBossIndex()
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(!Boss[client])
		{
			return client-1;
		}
	}
	return 0;
}

stock void Operate(ArrayList sumArray, int& bracket, float value, ArrayList _operator)
{
	float sum=sumArray.Get(bracket);
	switch(_operator.Get(bracket))
	{
		case Operator_Add:
		{
			sumArray.Set(bracket, sum+value);
		}
		case Operator_Subtract:
		{
			sumArray.Set(bracket, sum-value);
		}
		case Operator_Multiply:
		{
			sumArray.Set(bracket, sum*value);
		}
		case Operator_Divide:
		{
			if(!value)
			{
				LogError("[FF2 Bosses] Detected a divide by 0!");
				bracket=0;
				return;
			}
			sumArray.Set(bracket, sum/value);
		}
		case Operator_Exponent:
		{
			sumArray.Set(bracket, Pow(sum, value));
		}
		default:
		{
			sumArray.Set(bracket, value);  //This means we're dealing with a constant
		}
	}
	_operator.Set(bracket, Operator_None);
}

stock void OperateString(ArrayList sumArray, int& bracket, char[] value, int size, ArrayList _operator)
{
	if(!StrEqual(value, ""))  //Make sure 'value' isn't blank
	{
		Operate(sumArray, bracket, StringToFloat(value), _operator);
		strcopy(value, size, "");
	}
}

/*
 * Parses a mathematical formula and returns the result,
 * or `defaultValue` if there is an error while parsing
 *
 * Variables may be present in the formula as long as they
 * are in the format `{variable}`.  Unknown variables will
 * be passed to the `OnParseUnknownVariable` forward
 *
 * Known variables include:
 * - players
 * - lives
 * - health
 * - speed
 *
 * @param boss          Boss index
 * @param key           The key to retrieve the formula from.  If the
 *                      key is nested, the nested sections must be
 *                      delimited by a `>` symbol like so:
 *                      "plugin name > ability name > distance"
 * @param defaultValue  The default value to return in case of error
 * @return The value of the formula, or `defaultValue` in case of error
 */
stock int ParseFormula(int boss, const char[] key, int defaultValue)
{
	char formula[1024], bossName[64];
	KeyValues kv = GetCharacterKV(character[boss]);
	kv.Rewind();
	kv.GetString("name", bossName, sizeof(bossName), "=Failed name=");

	char keyPortions[5][128];
	int portions=ExplodeString(key, ">", keyPortions, sizeof(keyPortions), 128);
	for(int i=1; i<portions; i++)
	{
		kv.JumpToKey(keyPortions[i]);
	}
	kv.GetString(keyPortions[portions-1], formula, sizeof(formula));

	if(!formula[0])
	{
		return defaultValue;
	}

	int size=1;
	int matchingBrackets;
	for(int i; i<=strlen(formula); i++)  //Resize the arrays once so we don't have to worry about it later on
	{
		if(formula[i]=='(')
		{
			if(!matchingBrackets)
			{
				size++;
			}
			else
			{
				matchingBrackets--;
			}
		}
		else if(formula[i]==')')
		{
			matchingBrackets++;
		}
	}

	ArrayList sumArray=CreateArray(_, size), _operator=CreateArray(_, size);
	int bracket;  //Each bracket denotes a separate sum (within parentheses).  At the end, they're all added together to achieve the actual sum
	bool escapeCharacter;
	sumArray.Set(0, 0.0);  //TODO:  See if these can be placed naturally in the loop
	_operator.Set(bracket, Operator_None);

	char currentCharacter[2], value[16], variable[16];  //We don't decl these because we directly append characters to them and there's no point in decl'ing currentCharacter
	for(int i; i<=strlen(formula); i++)
	{
		currentCharacter[0]=formula[i];  //Find out what the next char in the formula is
		switch(currentCharacter[0])
		{
			case ' ', '\t':  //Ignore whitespace
			{
				continue;
			}
			case '(':
			{
				bracket++;  //We've just entered a new parentheses so increment the bracket value
				sumArray.Set(bracket, 0.0);
				_operator.Set(bracket, Operator_None);
			}
			case ')':
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
				if(_operator.Get(bracket)!=Operator_None)  //Something like (5*)
				{
					LogError("[FF2 Bosses] %s's %s formula has an invalid operator at character %i", bossName, key, i+1);
					delete sumArray;
					delete _operator;
					return defaultValue;
				}

				if(--bracket<0)  //Something like (5))
				{
					LogError("[FF2 Bosses] %s's %s formula has an unbalanced parentheses at character %i", bossName, key, i+1);
					delete sumArray;
					delete _operator;
					return defaultValue;
				}

				Operate(sumArray, bracket, GetArrayCell(sumArray, bracket+1), _operator);
			}
			case '\0':  //End of formula
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
			}
			case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.':
			{
				StrCat(value, sizeof(value), currentCharacter);  //Constant?  Just add it to the current value
			}
			/*case 'n', 'x':  //n and x denote player variables
			{
				Operate(sumArray, bracket, float(playing), _operator);
			}*/
			case '{':
			{
				escapeCharacter=true;
			}
			case '}':
			{
				if(!escapeCharacter)
				{
					LogError("[FF2 Bosses] %s's %s formula has an invalid escape character at character %i", bossName, key, i+1);
					delete sumArray;
					delete _operator;
					return defaultValue;
				}
				escapeCharacter=false;

				if(StrEqual(variable, "players", false))
				{
					int count = max(RedAlivePlayers, 1);
					Operate(sumArray, bracket, float(count), _operator);
				}
				else if(StrEqual(variable, "health", false))
				{
					Operate(sumArray, bracket, float(BossHealth[boss]), _operator);
				}
				else if(StrEqual(variable, "lives", false))
				{
					Operate(sumArray, bracket, float(BossLives[boss]), _operator);
				}
				else if(StrEqual(variable, "speed", false))
				{
					Operate(sumArray, bracket, BossSpeed[boss], _operator);
				}
				else
				{
					Action action;
					float variableValue;
					Call_StartForward(OnParseUnknownVariable);
					Call_PushString(variable);
					Call_PushFloatRef(variableValue);
					Call_Finish();

					if(action==Plugin_Changed)
					{
						Operate(sumArray, bracket, variableValue, _operator);
					}
					else
					{
						LogError("[FF2 Bosses] %s's %s formula has an unknown variable '%s'", bossName, key, variable);
						delete sumArray;
						delete _operator;
						return defaultValue;
					}
				}
				Format(variable, sizeof(variable), ""); // Reset the variable holder
			}
			case '+', '-', '*', '/', '^':
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
				switch(currentCharacter[0])
				{
					case '+':
					{
						_operator.Set(bracket, Operator_Add);
					}
					case '-':
					{
						_operator.Set(bracket, Operator_Subtract);
					}
					case '*':
					{
						_operator.Set(bracket, Operator_Multiply);
					}
					case '/':
					{
						_operator.Set(bracket, Operator_Divide);
					}
					case '^':
					{
						_operator.Set(bracket, Operator_Exponent);
					}
				}
			}
			default:
			{
				if(escapeCharacter)  //Absorb all the characters into 'variable' if we hit an escape character
				{
					StrCat(variable, sizeof(variable), currentCharacter);
				}
				else
				{
					LogError("[FF2 Bosses] %s's %s formula has an invalid character at character %i", bossName, key, i+1);
					delete sumArray;
					delete _operator;
					return defaultValue;
				}
			}
		}
	}

	int result=RoundFloat(GetArrayCell(sumArray, 0));
	delete sumArray;
	delete _operator;
	if(result<=0)
	{
		LogError("[FF2 Bosses] %s has an invalid %s formula, using default!", bossName, key);
		return defaultValue;
	}

	if(bMedieval && StrEqual(key, "health"))
	{
		return RoundFloat(result/3.6);  //TODO: Make this configurable
	}
	return result;
}

stock int GetAbilityArgument(int boss, const char[] pluginName, const char[] abilityName, const char[] argument, int defaultValue = 0, int slot = -3)
{
	if(HasAbility(boss, pluginName, abilityName, slot))
	{
		KeyValues kv=GetCharacterKV(character[boss]);
		return kv.GetNum(argument, defaultValue);
	}
	return defaultValue;
}

stock float GetAbilityArgumentFloat(int boss, const char[] pluginName, const char[] abilityName, const char[] argument, float defaultValue=0.0, int slot = -3)
{
	if(HasAbility(boss, pluginName, abilityName, slot))
	{
		KeyValues kv=GetCharacterKV(character[boss]);
		return kv.GetFloat(argument, defaultValue);
	}
	return defaultValue;
}

stock void GetAbilityArgumentString(int boss, const char[] pluginName, const char[] abilityName, const char[] argument, char[] abilityString, int length, const char[] defaultValue="", int slot = -3)
{
	strcopy(abilityString, length, defaultValue);
	if(HasAbility(boss, pluginName, abilityName, slot))
	{
		KeyValues kv=GetCharacterKV(character[boss]);
		kv.GetString(argument, abilityString, length, defaultValue);
	}
}

stock bool FindSound(const char[] sound, char[] file, int length, int boss=0, bool ability=false, int slot=0)
{
	KeyValues kv=GetCharacterKV(character[boss]);
	if(boss<0 || character[boss]<0 || !kv)
	{
		return false;
	}

	kv.Rewind();
	if(!kv.JumpToKey("sounds"))
	{
		return false;  //Boss doesn't have any sounds
	}

	ArrayList soundsArray=CreateArray(PLATFORM_MAX_PATH);
	char match[PLATFORM_MAX_PATH];
	kv.GotoFirstSubKey();
	do  //Just keep looping until there's no keys left
	{
		if(kv.GetNum(sound))
		{
			if(!ability || kv.GetNum("slot")==slot)
			{
				kv.GetSectionName(match, sizeof(match));
				if(soundsArray.FindString(match)>=0)
				{
					char bossName[64];
					kv.Rewind();
					kv.GetString("name", bossName, sizeof(bossName));
					PrintToServer("[FF2 Bosses] Character %s has a duplicate sound '%s'!", bossName, match);
					continue; // We ignore all duplicates
				}
				soundsArray.PushString(match);
			}
		}
	}
	while(kv.GotoNextKey());

	if(!soundsArray.Length)
	{
		delete soundsArray;
		return false;  //No sounds matching what we want
	}

	soundsArray.GetString(GetRandomInt(0, GetArraySize(soundsArray)-1), file, length);
	delete soundsArray;
	return true;
}

// NOTE:
public Action FF2_OnCheckRules(int client, int characterIndex, int &chance, const char[] ruleName, const char[] value)
{
	int integerValue = StringToInt(value);
	char authId[32];
	GetClientAuthId(client, AuthId_SteamID64, authId, sizeof(authId));

	// CPrintToChatAll("%s: %s", ruleName, value);

	if(StrEqual(ruleName, "admin"))
	{
		AdminId adminId = GetUserAdmin(client);

		if(adminId != INVALID_ADMIN_ID)
		{
			if(!adminId.HasFlag(view_as<AdminFlag>(integerValue), Access_Real))
				return Plugin_Handled;
		}
		return Plugin_Handled;
	}
	if(StrEqual(ruleName, "blocked"))
	{
		return Plugin_Handled;
	}
	if(StrEqual(ruleName, "creator"))
	{
		int flags = GetBossCreatorFlags(authId, characterIndex, true);
		return flags > 0 ? Plugin_Continue : Plugin_Handled;
	}
	if(StrEqual(ruleName, "alive"))
	{
		CheckAlivePlayers(INVALID_HANDLE);
		return RedAlivePlayers + BlueAlivePlayers >= integerValue ? Plugin_Continue : Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action ResetQueuePointsCmd(int client, int args)
{
	if(!Enabled2)
	{
		return Plugin_Continue;
	}

	if(client && !args)  //Normal players
	{
		TurnToZeroPanel(client, client);
		return Plugin_Handled;
	}

	if(!client)  //No confirmation for console
	{
		TurnToZeroPanelH(null, MenuAction_Select, client, 1);
		return Plugin_Handled;
	}

	AdminId admin=GetUserAdmin(client);	 //Normal players
	if((admin==INVALID_ADMIN_ID) || !GetAdminFlag(admin, Admin_Cheats))
	{
		TurnToZeroPanel(client, client);
		return Plugin_Handled;
	}

	if(args!=1)  //Admins
	{
		CReplyToCommand(client, "{olive}[FF2]{default} Usage: ff2_resetqueuepoints <target>");
		return Plugin_Handled;
	}

	char pattern[MAX_TARGET_LENGTH];
	GetCmdArg(1, pattern, sizeof(pattern));
	char targetName[MAX_TARGET_LENGTH];
	int targets[MAXPLAYERS], matches;
	bool targetNounIsMultiLanguage;

	if((matches=ProcessTargetString(pattern, client, targets, 1, 0, targetName, sizeof(targetName), targetNounIsMultiLanguage))<=0)
	{
		ReplyToTargetError(client, matches);
		return Plugin_Handled;
	}

	if(matches>1)
	{
		for(int target=1; target<matches; target++)
		{
			TurnToZeroPanel(client, targets[target]);  //FIXME:  This can only handle one client currently and doesn't iterate through all clients
		}
	}
	else
	{
		TurnToZeroPanel(client, targets[0]);
	}
	return Plugin_Handled;
}

int GetClientClassInfoCookie(int client)
{
	return GetSettingData(client, "class_info_view", DBSData_Int);
}

public Action HookSound(int clients[64], int& numClients, char sound[PLATFORM_MAX_PATH], int& client, int& channel, float& volume, int& level, int& pitch, int& flags, char soundEntry[PLATFORM_MAX_PATH], int& seed)
{
	if(!Enabled || !IsValidClient(client) || channel<1)
	{
		return Plugin_Continue;
	}

	int boss=GetBossIndex(client);
	if(boss==-1)
	{
		return Plugin_Continue;
	}

	if(channel==SNDCHAN_VOICE)
	{
		char newSound[PLATFORM_MAX_PATH];
		if(FindSound("catch phrase", newSound, sizeof(newSound), boss))
		{
			strcopy(sound, sizeof(sound), newSound);
			return Plugin_Changed;
		}

		bool isBlockVoice = false;
		KeyValues bossKv = GetCharacterKV(character[boss]);

		bossKv.Rewind();
		isBlockVoice=bossKv.GetNum("block voice", 0) > 0;

		if(isBlockVoice)
		{
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

stock int GetHealingTarget(int client, bool checkgun=false)
{
	int medigun=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(!checkgun)
	{
		if(GetEntProp(medigun, Prop_Send, "m_bHealing"))
		{
			return GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
		}
		return -1;
	}

	if(IsValidEntity(medigun))
	{
		char classname[64];
		GetEntityClassname(medigun, classname, sizeof(classname));
		if(StrEqual(classname, "tf_weapon_medigun", false))
		{
			if(GetEntProp(medigun, Prop_Send, "m_bHealing"))
			{
				return GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
			}
		}
	}
	return -1;
}

public void CvarChangeNextmap(ConVar convar, const char[] oldValue, const char[] newValue)
{
	CreateTimer(0.1, Timer_DisplayCharsetVote, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_DisplayCharsetVote(Handle timer)
{
	if(isCharSetSelected)
	{
		return Plugin_Continue;
	}

	if(IsVoteInProgress())
	{
		CreateTimer(5.0, Timer_DisplayCharsetVote, _, TIMER_FLAG_NO_MAPCHANGE);  //Try again in 5 seconds if there's a different vote going on
		return Plugin_Continue;
	}

	Menu menu=new Menu(Handler_VoteCharset, view_as<MenuAction>(MENU_ACTIONS_ALL));
	menu.SetTitle("%t", "Vote for Character Set");  //"Please vote for the character set for the next map."

	char config[PLATFORM_MAX_PATH], charset[64];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", FF2_SETTINGS, BOSS_CONFIG);

	KeyValues Kv=new KeyValues("");
	Kv.ImportFromFile(config);
	menu.AddItem("Random", "Random");
	int total, charsets;
	do
	{
		total++;
		if(Kv.GetNum("hidden", 0))  //Hidden charsets are hidden for a reason :P
		{
			continue;
		}
		charsets++;
		validCharsets[charsets]=total;

		Kv.GetSectionName(charset, sizeof(charset));
		menu.AddItem(charset, charset);
	}
	while(Kv.GotoNextKey());
	delete Kv;

	if(charsets>1)  //We have enough to call a vote
	{
		FF2CharSet=charsets;  //Temporary so that if the vote result is random we know how many valid charsets are in the validCharset array
		ConVar voteDuration=FindConVar("sm_mapvote_voteduration");
		VoteMenuToAll(menu, voteDuration ? voteDuration.IntValue : 20);
	}
	return Plugin_Continue;
}

public int Handler_VoteCharset(Menu menu, MenuAction action, int param1, int param2)
{
	if(action==MenuAction_VoteEnd)
	{
		FF2CharSet=param1 ? param1-1 : validCharsets[GetRandomInt(1, FF2CharSet)]-1;  //If param1 is 0 then we need to find a random charset

		char nextmap[42];
		cvarNextmap.GetString(nextmap, sizeof(nextmap));
		menu.GetItem(param1, FF2CharSetString, sizeof(FF2CharSetString));
		CPrintToChatAll("{olive}[FF2]{default} %t", "Character Set Next Map", nextmap, FF2CharSetString);  //"The character set for {1} will be {2}."
		isCharSetSelected=true;
	}
	else if(action==MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

public Action Command_Nextmap(int client, int args)
{
	if(FF2CharSetString[0])
	{
		char nextmap[42];
		cvarNextmap.GetString(nextmap, sizeof(nextmap));
		CPrintToChat(client, "{olive}[FF2]{default} %t", "Character Set Next Map", nextmap, FF2CharSetString);
	}
	return Plugin_Handled;
}

public Action Command_Say(int client, int args)
{
	char chat[128];
	if(GetCmdArgString(chat, sizeof(chat))<1 || !client)
	{
		return Plugin_Continue;
	}

	if(StrEqual(chat, "\"nextmap\"") && FF2CharSetString[0])
	{
		Command_Nextmap(client, 0);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

stock void RemoveShield(int client, int attacker, float position[3])
{
	TF2_RemoveWearable(client, shield[client]);
	PlayShieldBreakSound(client, position);
	TF2_AddCondition(client, TFCond_Bonked, 0.1); // Shows "MISS!" upon breaking shield
	shield[client]=0;
}

//Natives aren't inlined because of https://github.com/50DKP/FF2-Official/issues/263

public bool IsFF2Enabled()
{
	return Enabled;
}

public int Native_IsFF2Enabled(Handle plugin, int numParams)
{
	return IsFF2Enabled();
}

public void RegisterSubplugin(char[] pluginName)
{
	PushArrayString(subpluginArray, pluginName);
}

public /*void*/int Native_RegisterSubplugin(Handle plugin, int numParams)
{
	char pluginName[64];
	GetNativeString(1, pluginName, sizeof(pluginName));
	RegisterSubplugin(pluginName);

	return 0;
}

public void UnregisterSubplugin(char[] pluginName)
{
	int index=FindStringInArray(subpluginArray, pluginName);
	if(index>=0)
	{
		RemoveFromArray(subpluginArray, index);
	}
}

public /*void*/int Native_UnregisterSubplugin(Handle plugin, int numParams)
{
	char pluginName[64];
	GetNativeString(1, pluginName, sizeof(pluginName));
	UnregisterSubplugin(pluginName);

	return 0;
}

public bool GetFF2Version()
{
	int version[3];  //Blame the compiler for this mess -.-
	version[0]=StringToInt(MAJOR_REVISION);
	version[1]=StringToInt(MINOR_REVISION);
	version[2]=StringToInt(STABLE_REVISION);
	SetNativeArray(1, version, sizeof(version));
	#if !defined DEV_REVISION
		return false;
	#else
		return true;
	#endif
}

public int Native_GetFF2Version(Handle plugin, int numParams)
{
	return GetFF2Version();
}

public int Native_GetRoundState(Handle plugin, int numParams)
{
	return view_as<int>(CheckRoundState());
}

int GetBossRageDistance(int boss, const char[] pluginName, const char[] abilityName, int slot = -3)
{
	KeyValues kv = GetCharacterKV(character[boss]);
	if(!kv)  //Invalid boss
	{
		return 0;
	}

	kv.Rewind();
	if(!abilityName[0])  //Return the global rage distance if there's no ability specified
	{
		return ParseFormula(boss, "rage distance", 400);
	}

	if(HasAbility(boss, pluginName, abilityName, slot))
	{
		// char key[128];
		// Format(key, sizeof(key), "distance");

		int distance;
		if((distance = RoundFloat(kv.GetFloat("distance", -1.0))) < 0/*ParseFormula(boss, key, -1))<0*/)  //Distance doesn't exist, return the global rage distance instead
		{
			kv.Rewind();
			distance=ParseFormula(boss, "rage distance", 400);
		}
		return distance;
	}
	return 0;
}

public int Native_GetBossRageDistance(Handle plugin, int numParams)
{
	char pluginName[64], abilityName[64];
	GetNativeString(2, pluginName, sizeof(pluginName));
	GetNativeString(3, abilityName, sizeof(abilityName));
	return GetBossRageDistance(GetNativeCell(1), pluginName, abilityName, GetNativeCell(4));
}

public int GetClientDamage(int client)
{
	FF2BaseEntity player = g_hBasePlayer[client];
	return player.Damage;
}

public int Native_GetClientDamage(Handle plugin, int numParams)
{
	return GetClientDamage(GetNativeCell(1));
}

public void SetClientDamage(int client, int iDamage)
{
	FF2BaseEntity player = g_hBasePlayer[client];
	player.Damage = iDamage;
}

public /*void*/int Native_SetClientDamage(Handle plugin, int numParams)
{
	SetClientDamage(GetNativeCell(1), GetNativeCell(2));
	return 0;
}

public int GetRoundTime()
{
	return view_as<int>(timeleft);
}

public int Native_GetRoundTime(Handle plugin, int numParams)
{
	return GetRoundTime();
}

public void SetRoundTime(float time)
{
	timeleft = time;
}

public /*void*/int Native_SetRoundTime(Handle plugin, int numParams)
{
	SetRoundTime(GetNativeCell(1));
	return 0;
}

public int GetClientAssist(int client)
{
	FF2BaseEntity player = g_hBasePlayer[client];
	return player.Assist;
}

public int Native_GetClientAssist(Handle plugin, int numParams)
{
	return GetClientAssist(GetNativeCell(1));
}

public void SetClientAssist(int client, int assist)
{
	FF2BaseEntity player = g_hBasePlayer[client];
	player.Assist = assist;
}

public /*void*/int Native_SetClientAssist(Handle plugin, int numParams)
{
	SetClientAssist(GetNativeCell(1), GetNativeCell(2));
	return 0;
}

public /*void*/int Native_EquipBoss(Handle plugin, int numParams)
{
	EquipBoss(GetNativeCell(1));
	return 0;
}

public Action SpecialAttackToBoss(int attacker, int victimBoss, int weapon, char[] name, float &damage)
{
	return Forward_OnSpecialAttack(attacker, victimBoss, weapon, name, damage);
}

public /*void*/int Native_SpecialAttackToBoss(Handle plugin, int numParams)
{
	char name[80];
	GetNativeString(4, name, sizeof(name));
	float damage = GetNativeCell(5);
	SpecialAttackToBoss(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3), name, damage);
	return 0;
}

public Action Forward_OnSpecialAttack(int attacker, int victimBoss, int weapon, const char[] name, float &damage)
{
	float tempDamage = damage;
	Action action;
	Call_StartForward(OnSpecialAttack);
	Call_PushCell(attacker);
	Call_PushCell(victimBoss);
	Call_PushCell(weapon);
	Call_PushString(name);
	Call_PushFloatRef(tempDamage);
	Call_Finish(action);

	if(action == Plugin_Stop || action == Plugin_Handled)
	{
		return Plugin_Handled;
	}
	else if(action == Plugin_Changed)
	{
		damage = tempDamage;
	}

	Forward_OnSpecialAttack_Post(attacker, victimBoss, name, damage);
	return Plugin_Continue;
}

public void Forward_OnSpecialAttack_Post(int attacker, int victimBoss, const char[] name, float damage)
{
	Call_StartForward(OnSpecialAttack_Post);
	Call_PushCell(attacker);
	Call_PushCell(victimBoss);
	Call_PushString(name);
	Call_PushFloat(damage);
	Call_Finish();
}

public int GetFF2Flags(int client)
{
	FF2BaseEntity player = g_hBasePlayer[client];
	return player.Flags;
}

public int Native_GetFF2Flags(Handle plugin, int numParams)
{
	return GetFF2Flags(GetNativeCell(1));
}

public void SetFF2Flags(int client, int flags)
{
	FF2BaseEntity player = g_hBasePlayer[client];
	player.Flags = flags;
}

public /*void*/int Native_SetFF2Flags(Handle plugin, int numParams)
{
	SetFF2Flags(GetNativeCell(1), GetNativeCell(2));
	return 0;
}

public int Native_GetQueuePoints(Handle plugin, int numParams)
{
	FF2BasePlayer player = GetBasePlayer(GetNativeCell(1));
	return player.QueuePoints;
}

public /*void*/int Native_SetQueuePoints(Handle plugin, int numParams)
{
	FF2BasePlayer player = GetBasePlayer(GetNativeCell(1));
	player.QueuePoints = GetNativeCell(2);
	return 0;
}

public float GetClientGlow(int client)
{
	return GlowTimer[client];
}

public int Native_GetClientGlow(Handle plugin, int numParams)
{
	return view_as<int>(GetClientGlow(GetNativeCell(1)));
}

// FIXME: 구조가 명확하지 않음
void SetClientGlow(int client, float time1, float time2=-1.0)
{
	if(IsValidClient(client))
	{
		GlowTimer[client]+=time1;
		if(time2>=0)
		{
			GlowTimer[client]=time2;
		}

		if(GlowTimer[client]<=0.0)
		{
			GlowTimer[client]=0.0;
			SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
		}
	}
}

public /*void*/int Native_SetClientGlow(Handle plugin, int numParams)
{
	SetClientGlow(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3));
	return 0;
}

public int Native_Debug(Handle plugin, int numParams)
{
	return cvarDebug.BoolValue;
}

public int Native_GetTimerType(Handle plugin, int numParams)
{
	return timeType;
}

// 네온전멸기 도발 힐 (2프레임당 1 힐, 범위 300)
static int g_iNeonFrameCount = 0;
public void OnGameFrame()
{
	if(!Enabled || CheckRoundState() == FF2RoundState_RoundEnd)
		return;

	// 파이프 벽 접촉 즉시 폭발 체크 (매 틱)
	for(int ent = MaxClients + 1; ent < HOMING_LIMIT; ent++)
	{
		if(!g_bPipeWallExplode[ent])
			continue;

		if(!IsValidEntity(ent))
		{
			g_bPipeWallExplode[ent] = false;
			continue;
		}

		// m_bTouched가 1이면 벽/바닥에 닿은 것
		if(GetEntProp(ent, Prop_Send, "m_bTouched") == 1)
		{
			g_bPipeWallExplode[ent] = false;
			if(g_hSDKCallDetonate != null)
			{
				SDKCall(g_hSDKCallDetonate, ent);
			}
		}
	}

	g_iNeonFrameCount++;
	if(g_iNeonFrameCount < 2)
		return;
	g_iNeonFrameCount = 0;

	for(int client = 1; client <= MaxClients; client++)
	{
		if(!IsClientInGame(client) || !IsPlayerAlive(client) || IsBoss(client))
			continue;

		if(!TF2_IsPlayerInCondition(client, TFCond_Taunting))
			continue;

		// 현재 활성 무기가 네온전멸기인지 확인
		int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(!IsValidEntity(activeWeapon))
			continue;

		int index = GetEntProp(activeWeapon, Prop_Send, "m_iItemDefinitionIndex");
		if(index != 813 && index != 834)
			continue;

		float clientPos[3];
		GetClientAbsOrigin(client, clientPos);
		int clientTeam = GetClientTeam(client);

		for(int i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i) || !IsPlayerAlive(i) || i == client)
				continue;

			if(GetClientTeam(i) != clientTeam)
				continue;

			float targetPos[3];
			GetClientAbsOrigin(i, targetPos);

			if(GetVectorDistance(clientPos, targetPos) <= 300.0)
			{
				int maxHealth = GetEntProp(i, Prop_Data, "m_iMaxHealth");
				int currentHealth = GetClientHealth(i);
				if(currentHealth < maxHealth)
				{
					int newHealth = currentHealth + 1;
					if(newHealth > maxHealth)
						newHealth = maxHealth;
					SetEntityHealth(i, newHealth);
				}
			}
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(cvarHealthBar.BoolValue)
	{
		/*
		if(StrEqual(classname, HEALTHBAR_CLASS))
		{
			healthBar=entity;
		}
		*/
		if(!IsValidEntity(g_Monoculus) && StrEqual(classname, MONOCULUS))
		{
			g_Monoculus=entity;
		}
	}

	if(StrContains(classname, "item_healthkit")!=-1 || StrContains(classname, "item_ammopack")!=-1 || StrEqual(classname, "tf_ammo_pack"))
	{
		SDKHook(entity, SDKHook_Spawn, OnItemSpawned);
	}

	if(StrEqual(classname, "tf_logic_koth"))
	{
		SDKHook(entity, SDKHook_Spawn, Spawn_Koth);
	}

	// 로드앤로크(308)/무쇠폭탄발사기(1151): 유탄 벽 접촉 시 즉시 폭발
	if(StrEqual(classname, "tf_projectile_pipe"))
	{
		SDKHook(entity, SDKHook_SpawnPost, OnPipeSpawnPost);
	}

	// 유도 투사체: 조명탄, 로켓, 가스패서 (homing-rocket2.sp 방식 - Spawn 훅 + Timer)
	if(StrEqual(classname, "tf_projectile_flare") || StrEqual(classname, "tf_projectile_rocket") || StrEqual(classname, "tf_projectile_jar_gas") || StrEqual(classname, "tf_projectile_energy_ball") || StrEqual(classname, "tf_projectile_energy_ring") || StrEqual(classname, "tf_projectile_healing_bolt"))
	{
		SDKHook(entity, SDKHook_SpawnPost, Hook_OnHomingProjectileSpawnPost);
	}
}

// =========================================================================
// 로드앤로크(308)/무쇠폭탄발사기(1151) - 유탄 벽 접촉 시 즉시 폭발
// =========================================================================
public void OnPipeSpawnPost(int entity)
{
	if(!IsValidEntity(entity))
		return;

	int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	if(owner <= 0 || owner > MaxClients || !IsClientInGame(owner))
		return;

	if(IsBoss(owner))
		return;

	int weapon = GetPlayerWeaponSlot(owner, TFWeaponSlot_Primary);
	if(!IsValidEntity(weapon))
		return;

	int index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	if(index == 308 || index == 1151) // 로드앤로크, 무쇠폭탄발사기
	{
		if(entity > 0 && entity < HOMING_LIMIT)
		{
			g_bPipeWallExplode[entity] = true;
		}
	}
}

public void OnObjectBuilt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client <= 0 || !IsClientInGame(client) || IsBoss(client))
		return;

	int building = event.GetInt("index");
	if(!IsValidEntity(building))
		return;

	// 유래카 효과(589) 소지 시 모든 건물 즉시 건설
	int melee = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	if(!IsValidEntity(melee))
		return;

	int meleeIndex = GetEntProp(melee, Prop_Send, "m_iItemDefinitionIndex");
	if(meleeIndex != 589)
		return;

	// 1프레임 뒤에 즉시 건설 처리 (엔티티가 완전히 스폰된 후)
	RequestFrame(Frame_InstantBuild, EntIndexToEntRef(building));
}

public void Frame_InstantBuild(int buildingRef)
{
	int building = EntRefToEntIndex(buildingRef);
	if(!IsValidEntity(building))
		return;

	// SDKCall로 즉시 건설 완료 (MvM 방식)
	if(g_hSDKStartBuilding != null && g_hSDKFinishBuilding != null)
	{
		SDKCall(g_hSDKStartBuilding, building);
		SDKCall(g_hSDKFinishBuilding, building);
	}

	// 다음 프레임에 체력 보정
	RequestFrame(Frame_FixBuildingHealth, EntIndexToEntRef(building));
}

public void Frame_FixBuildingHealth(int buildingRef)
{
	int building = EntRefToEntIndex(buildingRef);
	if(!IsValidEntity(building))
		return;

	// AddHealth 엔진 입력으로 체력 보정 (내부 상태 정상 반영)
	SetVariantInt(150);
	AcceptEntityInput(building, "AddHealth");
}

// =========================================================================
// 백버너: 뒤에서 공격 판정
// =========================================================================
bool IsBackAttack(int attacker, int victim)
{
	float attackerPos[3], victimPos[3], victimAng[3], attackDir[3], fwd[3];
	GetClientAbsOrigin(attacker, attackerPos);
	GetClientAbsOrigin(victim, victimPos);
	GetClientEyeAngles(victim, victimAng);

	// 공격자 → 피격자 방향
	SubtractVectors(victimPos, attackerPos, attackDir);

	// 피격자가 바라보는 방향
	GetAngleVectors(victimAng, fwd, NULL_VECTOR, NULL_VECTOR);

	// Z축 무시 (2D 평면)
	attackDir[2] = 0.0;
	fwd[2] = 0.0;
	NormalizeVector(attackDir, attackDir);
	NormalizeVector(fwd, fwd);

	// 내적 > 0이면 공격자가 피격자의 뒤쪽에 있음 (±90도)
	float dot = GetVectorDotProduct(attackDir, fwd);
	return (dot > 0.0);
}

// =========================================================================
// 투사체 유도 시스템 (homing-rocket2.sp by Leonardo 방식 참조)
// OnEntityCreated → SDKHook_Spawn → Timer 반복으로 유도
// =========================================================================

// SpawnPost 훅: 투사체 생성 후 owner 확인 → 유도 타이머 시작
public void Hook_OnHomingProjectileSpawnPost(int entity)
{
	if(!Enabled || entity <= 0 || entity >= HOMING_LIMIT)
		return;

	int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	if(owner <= 0 || owner > MaxClients)
		return;

	if(!IsClientInGame(owner) || !IsPlayerAlive(owner))
		return;

	if(!g_bHomingEnabled[owner])
		return;

	float strength = g_flHomingStrength[owner];

	// 투사체 데이터 저장
	g_iHomingOwner[entity] = owner;
	g_flHomingProjStr[entity] = strength;

	// 0.01초(10ms) 간격 반복 타이머 시작
	g_hHomingTimer[entity] = CreateTimer(0.01, Timer_HomingUpdate, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

// 타이머: 매 10ms마다 투사체를 가장 가까운 보스 쪽으로 유도
public Action Timer_HomingUpdate(Handle timer, any entref)
{
	int entity = EntRefToEntIndex(entref);
	if(entity == INVALID_ENT_REFERENCE || !IsValidEntity(entity))
	{
		// 엔티티 소멸 → 정리
		int idx = entref & 0x7FF; // ref에서 entity index 추출 시도
		if(idx > 0 && idx < HOMING_LIMIT)
		{
			g_hHomingTimer[idx] = INVALID_HANDLE;
			g_iHomingOwner[idx] = 0;
		}
		return Plugin_Stop;
	}

	if(entity >= HOMING_LIMIT)
	{
		g_hHomingTimer[entity] = INVALID_HANDLE;
		return Plugin_Stop;
	}

	int owner = g_iHomingOwner[entity];
	if(owner <= 0 || owner > MaxClients || !IsClientInGame(owner) || !IsPlayerAlive(owner))
	{
		HomingCleanup(entity);
		return Plugin_Stop;
	}

	// owner가 변경됐는지 확인 (에어블로 반사 등)
	int curOwner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	if(curOwner > 0 && curOwner <= MaxClients && curOwner != owner)
	{
		HomingCleanup(entity);
		return Plugin_Stop;
	}

	// 가장 가까운 적 팀 보스 찾기 (범위 3000, 시야 체크)
	int ownerTeam = GetClientTeam(owner);
	int target = HomingGetClosestBoss(entity, ownerTeam);
	if(target <= 0)
		return Plugin_Continue; // 범위 내 보이는 보스 없으면 직진 유지

	float projPos[3], targetPos[3], targetVec[3];
	float projVel[3], projAng[3];

	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", projPos);
	GetClientEyePosition(target, targetPos); // 보스 눈높이로 유도

	GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", projVel);
	float projSpeed = GetVectorLength(projVel);
	if(projSpeed < 1.0)
		return Plugin_Continue;

	// 타겟 방향 벡터 = 타겟위치 - 투사체위치 → 정규화 → strength 스케일
	SubtractVectors(targetPos, projPos, targetVec);
	NormalizeVector(targetVec, targetVec); // 거리 무관 일정한 방향 벡터
	ScaleVector(targetVec, g_flHomingProjStr[entity]); // strength만큼 유도력

	AddVectors(projVel, targetVec, projVel);
	NormalizeVector(projVel, projVel);
	GetVectorAngles(projVel, projAng);

	SetEntPropVector(entity, Prop_Data, "m_angRotation", projAng);
	ScaleVector(projVel, projSpeed);
	SetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", projVel);

	return Plugin_Continue;
}

// 투사체 유도 데이터 정리
void HomingCleanup(int entity)
{
	if(entity <= 0 || entity >= HOMING_LIMIT)
		return;

	g_iHomingOwner[entity] = 0;
	g_flHomingProjStr[entity] = 0.0;
	if(g_hHomingTimer[entity] != INVALID_HANDLE)
	{
		KillTimer(g_hHomingTimer[entity]);
		g_hHomingTimer[entity] = INVALID_HANDLE;
	}
}

// 가장 가까운 적 팀 플레이어 찾기 (범위 3000, 시야 체크)
int HomingGetClosestBoss(int entity, int ownerTeam)
{
	float entityPos[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", entityPos);

	int closest = 0;
	float closestDist = 999999.0;
	for(int client = 1; client <= MaxClients; client++)
	{
		if(!IsClientInGame(client) || !IsPlayerAlive(client))
			continue;

		// 같은 팀이면 스킵 (적 팀만 타겟)
		if(GetClientTeam(client) == ownerTeam)
			continue;

		float pos[3];
		GetClientEyePosition(client, pos); // 눈높이 기준
		float dist = GetVectorDistance(entityPos, pos);

		// 범위 3000 제한
		if(dist > 3000.0)
			continue;

		// 벽/장애물 시야 체크: 투사체 → 적 사이에 벽이 있으면 스킵
		Handle trace = TR_TraceRayFilterEx(entityPos, pos, MASK_SOLID, RayType_EndPoint, HomingTraceFilter, entity);
		bool blocked = TR_DidHit(trace);
		int hitEntity = -1;
		if(blocked)
			hitEntity = TR_GetEntityIndex(trace);
		delete trace;

		// 레이가 대상 자신에게 맞았거나 아무것도 안 맞았으면 OK (시야 확보)
		if(blocked && hitEntity != client)
			continue; // 벽이나 다른 물체에 막힘

		if(dist < closestDist)
		{
			closest = client;
			closestDist = dist;
		}
	}
	return closest;
}

// 유도 시야 체크용 트레이스 필터: 투사체 자신은 무시
public bool HomingTraceFilter(int entity, int contentsMask, any data)
{
	// data = 투사체 엔티티 → 무시
	if(entity == data)
		return false;

	// 투사체 클래스들 무시
	if(entity > 0 && IsValidEntity(entity))
	{
		char classname[64];
		GetEntityClassname(entity, classname, sizeof(classname));
		if(StrContains(classname, "tf_projectile") != -1)
			return false;
	}

	return true;
}

public void OnEntityDestroyed(int entity)
{
	if(entity > 0 && entity < HOMING_LIMIT)
	{
		// 유도 투사체 정리
		if(g_iHomingOwner[entity] != 0)
		{
			g_iHomingOwner[entity] = 0;
			g_flHomingProjStr[entity] = 0.0;
			g_hHomingTimer[entity] = INVALID_HANDLE;
		}
		// 파이프 벽폭발 정리
		g_bPipeWallExplode[entity] = false;
	}

	if(entity==g_Monoculus)
	{
		g_Monoculus=FindEntityByClassname(-1, MONOCULUS);
		if(g_Monoculus==entity)
		{
			g_Monoculus=FindEntityByClassname(entity, MONOCULUS);
		}
	}

	if(g_hBaseEntityMap != null 		// Before PluginStart
		&& IsEntNetworkable(entity))
	{
		FF2BaseEntity baseEnt = null;
		baseEnt = g_hBaseEntityMap.GetByIndex(entity);

		if(baseEnt == null)
		{
			// LogError("[DEBUG] NULL IN %d!", entity);
			return;
		}

		int entRef = EntIndexToEntRef(entity);
		g_hBaseEntityMap.EraseEntity(entRef);

		delete baseEnt;
	}	
}

public Action Spawn_Koth(int entity)
{
	DispatchSpawn(CreateEntityByName("tf_logic_arena"));
	return Plugin_Stop;  //Stop koth logic from being created
}

public void OnItemSpawned(int entity)
{
	SDKHook(entity, SDKHook_StartTouch, OnPickup);
	SDKHook(entity, SDKHook_Touch, OnPickup);
}

public Action OnPickup(int entity, int client)  //Thanks friagram!
{
	if(IsBoss(client))
	{
		FF2BaseEntity player = g_hBasePlayer[client];

		char classname[32];
		GetEntityClassname(entity, classname, sizeof(classname));

		if(!StrContains(classname, "item_healthkit") && !(player.Flags & FF2FLAG_ALLOW_HEALTH_PICKUPS))
			return Plugin_Handled;
		else if((!StrContains(classname, "item_ammopack") || StrEqual(classname, "tf_ammo_pack")) && !(player.Flags & FF2FLAG_ALLOW_AMMO_PICKUPS))
			return Plugin_Handled;
	}
	return Plugin_Continue;
}

public FF2RoundState CheckRoundState()
{
	switch(GameRules_GetRoundState())
	{
		case RoundState_Init, RoundState_Pregame:
		{
			return FF2RoundState_Loading;
		}
		case RoundState_StartGame, RoundState_Preround:
		{
			return FF2RoundState_Setup;
		}
		case RoundState_RoundRunning, RoundState_Stalemate:  //Oh Valve.
		{
			return FF2RoundState_RoundRunning;
		}
		default:
		{
			return FF2RoundState_RoundEnd;
		}
	}
}

void FindHealthBar()
{
	healthBar=TFMonsterResource.GetEntity(true);
}

public void HealthbarEnableChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(Enabled && cvarHealthBar.BoolValue && IsValidEntity(healthBar.Index))
	{
		UpdateHealthBar(true);
	}
	else if(!IsValidEntity(g_Monoculus) && IsValidEntity(healthBar.Index))
	{
		healthBar.BossHealthPercentageByte=0;
	}
}

void UpdateHealthBar(bool noHealState = false)
{
	if(!Enabled || !cvarHealthBar.BoolValue || IsValidEntity(g_Monoculus) || !IsValidEntity(healthBar.Index) || CheckRoundState()==FF2RoundState_Loading)
	{
		return;
	}

	int healthAmount, maxHealthAmount, bosses, healthPercent;
	static int recently;
	for(int boss; boss<=MaxClients; boss++)
	{
		if(IsValidClient(Boss[boss]) && IsPlayerAlive(Boss[boss]) && TF2_GetClientTeam(Boss[boss]) == BossTeam)
		{
			bosses++;
			healthAmount+=BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1);
			maxHealthAmount+=BossHealthMax[boss];
		}
	}

	if(bosses)
	{
		healthPercent=RoundToCeil(float(healthAmount)/float(maxHealthAmount)*float(HEALTHBAR_MAX));
		healthBar.BossHealthState=(!noHealState && recently < healthAmount) ? HealthState_Healing : HealthState_Default;

		if(healthPercent>HEALTHBAR_MAX)
		{
			healthPercent=HEALTHBAR_MAX;
		}
		else if(healthPercent<=0)
		{
			healthPercent=1;
		}
	}

	healthBar.BossHealthPercentageByte=healthPercent;
	recently=healthAmount;
}

// FF2_DropWeapon - drops a weapon from the player
public int Native_DropWeapon(Handle plugin, int numParams)
{
	int owner = GetNativeCell(1);
	int weapon = GetNativeCell(2);
	// int flags = GetNativeCell(3);

	if(!IsValidClient(owner) || !IsValidEntity(weapon))
		return -1;

	// Use TF2 built-in drop system
	SDKHooks_DropWeapon(owner, weapon);
	return weapon;
}

// FF2_EqiupWeaponFromDropped - stub implementation
public int Native_EqiupWeaponFromDropped(Handle plugin, int numParams)
{
	return 0;
}