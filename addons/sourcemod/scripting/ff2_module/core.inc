#if defined _ff2_core_included
    #endinput
#endif
#define _ff2_core_included

/**
 * FF2 Core Definitions
 *
 * Contains all core constants, global variables, enums, forward handles,
 * and boss/player variable arrays.
 */

// ========================================================================
// Version & Constants
// ========================================================================

#define MAJOR_REVISION "2023"
#define MINOR_REVISION "8"
#define STABLE_REVISION "12"
// #define DEV_REVISION ""
#if !defined DEV_REVISION
	#define PLUGIN_VERSION MAJOR_REVISION..."."...MINOR_REVISION..."."...STABLE_REVISION  //2.0.0
#else
	#define PLUGIN_VERSION MAJOR_REVISION..."."...MINOR_REVISION..."."...STABLE_REVISION..."-"...DEV_REVISION  //semver.org
#endif

#define UPDATE_URL ""

#define MAXENTITIES 2048

#define HEALTHBAR_CLASS "monster_resource"
#define HEALTHBAR_PROPERTY "m_iBossHealthPercentageByte"
#define HEALTHBAR_MAX 255
#define MONOCULUS "eyeball_boss"

#define FF2_CONFIGS "configs/freak_fortress_2"
#define FF2_SETTINGS "data/freak_fortress_2"
#define FF2_SUBPLUGIN_ROOT_PATH	"freak_fortress_2"

#define BOSS_CONFIG "characters.cfg"
#define DOORS_CONFIG "doors.cfg"
#define WEAPONS_CONFIG "weapons.cfg"
#define MAPS_CONFIG	"maps.cfg"
#define HUDS_CONFIG "hud_setting.cfg"
#define CHANGELOG "changelog.txt"

#define ENT_REFKEY_LENGTH	20
#define KILLSTREAK_DAMAGE_INTERVAL 500
#define HUD_DISPLAY_NAME_MAX_LENGTH		128

#define min(%1,%2)            (((%1) < (%2)) ? (%1) : (%2))
#define max(%1,%2)            (((%1) > (%2)) ? (%1) : (%2))

#define FOREACH_PLAYER(%1) for(int %1 = 1; %1 <= MaxClients; %1++)

// ========================================================================
// Global State Variables
// ========================================================================

bool Enabled=true;
bool Enabled2=true;

TFTeam OtherTeam=TFTeam_Red;
TFTeam BossTeam=TFTeam_Blue;
int playing;
int healthcheckused;
int RedAlivePlayers;
int BlueAlivePlayers;
int StartingPlayers;
int RoundCount;
int character[MAXPLAYERS+1];

ArrayList bossesArray;
ArrayList bossesArrayOriginal; // FIXME: ULTRA HACKY HACK
ArrayList subpluginArray;

int FF2CharSet;
int validCharsets[64];
char FF2CharSetString[42];
bool isCharSetSelected;

KeyValues kvCharacterConfig;

Handle OnCheckRules;
Handle OnApplyBossHealthCorrection;

KeyValues kvWeaponMods;
KeyValues kvHudConfigs;

int ChangeLogLastTime;

int Boss[MAXPLAYERS+1];

FF2HudQueue PlayerHudQueue[MAXPLAYERS+1] = {null, ...};

// TODO: REMOVE THIS
int shortname[MAXPLAYERS+1];

// 투사체 유도 시스템
// 플레이어별: 유도 활성화 및 강도
bool g_bHomingEnabled[MAXPLAYERS+1];
float g_flHomingStrength[MAXPLAYERS+1];
// 투사체별: owner, 타이머, 강도 (homing-rocket2.sp 방식)
#define HOMING_LIMIT 2048
int g_iHomingOwner[HOMING_LIMIT];
Handle g_hHomingTimer[HOMING_LIMIT];
float g_flHomingProjStr[HOMING_LIMIT];

// 개척자정의 발사 감지용
int g_iLastButtons[MAXPLAYERS+1];
int g_iLastClip141[MAXPLAYERS+1];

// 유래카 즉시건설 SDKCall
Handle g_hSDKStartBuilding;
Handle g_hSDKFinishBuilding;

// 예방접종기(998) 레이저 공격
Handle g_hVaccinatorTimer[MAXPLAYERS+1];
int g_iVaccinatorLaser; // TE beam model index

// 파이프 폭발 SDKCall + 벽폭발 추적
Handle g_hSDKCallDetonate;
bool g_bPipeWallExplode[HOMING_LIMIT]; // 벽 접촉시 즉시 폭발 대상 유탄

// ========================================================================
// Enums
// ========================================================================

enum FF2RoundState
{
	FF2RoundState_Loading=-1,
	FF2RoundState_Setup,
	FF2RoundState_RoundRunning,
	FF2RoundState_RoundEnd,
}

enum FF2WeaponSpecials
{
	FF2WeaponSpecial_PreventDamage,
	FF2WeaponSpecial_RemoveOnDamage,
	FF2WeaponSpecial_JarateOnChargedHit,
}

enum FF2WeaponModType
{
	FF2WeaponMod_AddAttrib,
	FF2WeaponMod_RemoveAttrib,
	FF2WeaponMod_Replace,
	FF2WeaponMod_OnHit,
	FF2WeaponMod_OnTakeDamage,
}

enum Operators
{
	Operator_None=0,
	Operator_Add,
	Operator_Subtract,
	Operator_Multiply,
	Operator_Divide,
	Operator_Exponent,
};

// ========================================================================
// Forward Handles
// ========================================================================

Handle PreAbility;
Handle OnAbility;
Handle OnTriggerHurt;
Handle OnBossSelected;
Handle OnAddQueuePoints;
Handle OnLoadCharacterSet;
Handle OnLoseLife;
Handle OnAlivePlayersChanged;
Handle OnParseUnknownVariable;

// ff2_modules/general.inc
Handle OnWaveStarted;
Handle OnPlayBoss;
Handle OnAddRage;
Handle OnSpecialAttack;
Handle OnSpecialAttack_Post;

// ========================================================================
// Boss/Player Variable Arrays (from methodmap.sp)
// ========================================================================

int Incoming[MAXPLAYERS+1];

// int Damage[MAXPLAYERS+1];
// int LastNoticedDamage[MAXPLAYERS+1];
//int Assist[MAXPLAYERS+1];
int uberTarget[MAXPLAYERS+1];
int shield[MAXPLAYERS+1];
int detonations[MAXPLAYERS+1];
// int queuePoints[MAXPLAYERS+1];

int FF2Flags[MAXPLAYERS+1];

int BossHealthMax[MAXPLAYERS+1];
int BossHealth[MAXPLAYERS+1];
int BossHealthLast[MAXPLAYERS+1];
int BossLives[MAXPLAYERS+1];
int BossLivesMax[MAXPLAYERS+1];
int BossRageDamage[MAXPLAYERS+1];
float BossSpeed[MAXPLAYERS+1];
float BossCharge[MAXPLAYERS+1][8];
float BossMaxRageCharge[MAXPLAYERS+1];
float BossSkillDuration[MAXPLAYERS+1][3];

// Music variables
int muteSound[MAXPLAYERS+1];
bool playBGM[MAXPLAYERS+1] = {true, ...};
char currentBGM[MAXPLAYERS+1][PLATFORM_MAX_PATH];
char currentMusicPhase[MAXPLAYERS+1][64];
Handle MusicTimer[MAXPLAYERS+1];
