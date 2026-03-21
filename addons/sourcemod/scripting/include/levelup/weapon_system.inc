#if defined _weapon_system_included
 #endinput
#endif
#define _weapon_system_included

// 이 인클루드를 쓰는 플러그인 쪽에서 아래를 반드시 포함하세요.
// #include <sourcemod>
// #include <sdktools>
// #include <sdktools_sound>

// ============================================================================
// 상수 정의
// ============================================================================

#define MAX_WEAPON_UPGRADE 15

enum WeaponUpgradeResult
{
    WEAPON_UPGRADE_SUCCESS = 0,     // 강화 성공
    WEAPON_UPGRADE_FAIL = 1,        // 강화 실패 (레벨 유지)
    WEAPON_UPGRADE_RESET = 2        // 강화 초기화 (레벨 0으로)
};

// ============================================================================
// 무기 강화 메인 로직
// ============================================================================

WeaponUpgradeResult Weapon_TryUpgrade(int client, int currentLevel)
{
/*
    if (currentLevel < 0 || currentLevel >= MAX_WEAPON_UPGRADE)
    {
        LogError("[WeaponSystem] Invalid weapon level: %d (client: %d)", currentLevel, client);
        return WEAPON_UPGRADE_FAIL;
    }

    int random = GetRandomInt(1, 100);

    int successPercent = RoundToFloor(WEAPON_SUCCESS_TABLE[currentLevel] * 100.0);
    int missPercent    = RoundToFloor(WEAPON_MISS_TABLE[currentLevel] * 100.0);
    int resetPercent   = RoundToFloor(WEAPON_RESET_TABLE[currentLevel] * 100.0);

    PrintToServer("[WeaponSystem] Upgrade attempt - Level: %d, Random: %d, Success: %d%%, Miss: %d%%, Reset: %d%%",
                  currentLevel, random, successPercent, missPercent, resetPercent);

    if (random <= successPercent)
    {
        return WEAPON_UPGRADE_SUCCESS;
    }

    random -= successPercent;

    if (random <= missPercent)
    {
        return WEAPON_UPGRADE_FAIL;
    }

    return WEAPON_UPGRADE_RESET;*/
}

int Weapon_GetUpgradeCost(int level)
{
/*
    if (level < 0 || level >= MAX_WEAPON_UPGRADE)
    {
        return 0;
    }
    return WEAPON_COST_TABLE[level];*/
}

void Weapon_ApplyUpgrade(int client, int weapon, int level)
{
/*
    if (!IsValidClient(client) || !IsValidEntity(weapon))
    {
        return;
    }

    PrintToServer("[WeaponSystem] Applied upgrade - Client: %d, Weapon: %d, Level: %d",
                  client, weapon, level);*/
}

// ============================================================================
// 확률 조회 함수
// ============================================================================

float Weapon_GetSuccessChance(int level)
{
/*
    if (level < 0 || level >= MAX_WEAPON_UPGRADE)
    {
        return 0.0;
    }
    return WEAPON_SUCCESS_TABLE[level];*/
}

float Weapon_GetMissChance(int level)
{
/*
    if (level < 0 || level >= MAX_WEAPON_UPGRADE)
    {
        return 0.0;
    }
    return WEAPON_MISS_TABLE[level];*/
}

float Weapon_GetResetChance(int level)
{
/*
    if (level < 0 || level >= MAX_WEAPON_UPGRADE)
    {
        return 0.0;
    }
    return WEAPON_RESET_TABLE[level];*/
}

// ============================================================================
// 유틸리티 함수
// ============================================================================

bool Weapon_CanAffordUpgrade(int client, int level, int points)
{
/*
    if (!IsValidClient(client))
    {
        return false;
    }
    if (level < 0 || level >= MAX_WEAPON_UPGRADE)
    {
        return false;
    }
    int cost = Weapon_GetUpgradeCost(level);
    return points >= cost;*/
}

void Weapon_ShowUpgradeResult(int client, WeaponUpgradeResult result, int oldLevel, int newLevel)
{
/*
    if (!IsValidClient(client))
    {
        return;
    }

    char message[256];
    char centerText[256];

    switch (result)
    {
        case WEAPON_UPGRADE_SUCCESS:
        {
            Format(message, sizeof(message),
                   "%d번째 강화에 성공하였습니다.", newLevel);
            Format(centerText, sizeof(centerText),
                   "강화 성공! +%d → +%d", oldLevel, newLevel);

            PrintToChat(client, message);
            PrintCenterText(client, centerText);

            if (newLevel >= 10)
            {
                for (int i = 1; i <= MaxClients; i++)
                {
                    if (IsValidClient(i))
                    {
                        char name[MAX_NAME_LENGTH];
                        GetClientName(client, name, sizeof(name));
                        PrintToChat(i, "[알림] %s님이 무기 +%d 강화에 성공했습니다!", name, newLevel);
                        PrintCenterText(i, "[알림] %s님 무기 +%d 강화 성공!", name, newLevel);
                    }
                }
                EmitSoundToAll("misc/success1.mp3");
            }
            else
            {
                // 간단 호출(기본 파라미터 사용)
                EmitSoundToClient(client, "misc/success1.mp3");
            }
            break;
        }

        case WEAPON_UPGRADE_FAIL:
        {
            Format(message, sizeof(message),
                   "%d번째 강화에 실패했습니다.", oldLevel + 1);
            Format(centerText, sizeof(centerText),
                   "강화 실패... +%d 유지", oldLevel);

            PrintToChat(client, message);
            PrintCenterText(client, centerText);
            EmitSoundToClient(client, "misc/failed1.mp3");
            break;
        }

        case WEAPON_UPGRADE_RESET:
        {
            Format(message, sizeof(message),
                   "%d번째 강화가 파괴되었습니다!", oldLevel + 1);
            Format(centerText, sizeof(centerText),
                   "강화 파괴! +%d → +0", oldLevel);

            PrintToChat(client, message);
            PrintCenterText(client, centerText);

            if (oldLevel >= 10)
            {
                for (int i = 1; i <= MaxClients; i++)
                {
                    if (IsValidClient(i))
                    {
                        char name[MAX_NAME_LENGTH];
                        GetClientName(client, name, sizeof(name));
                        PrintToChat(i, "[알림] %s님의 무기 +%d가 파괴되었습니다...", name, oldLevel);
                        PrintCenterText(i, "[알림] %s님 무기 +%d 파괴...", name, oldLevel);
                    }
                }
                EmitSoundToAll("misc/failed1.mp3");
            }
            else
            {
                EmitSoundToClient(client, "misc/failed1.mp3");
            }
            break;
        }
    }*/
}

bool Weapon_CanUpgrade(int level)
{
/*
    return (level >= 0 && level < MAX_WEAPON_UPGRADE);*/
}

bool Weapon_IsValidLevel(int level)
{
/*
    return (level >= 0 && level <= MAX_WEAPON_UPGRADE);*/
}

// ============================================================================
// 강화 통계 함수
// ============================================================================

int Weapon_GetTotalCost(int targetLevel)
{
/*
    if (targetLevel < 0 || targetLevel > MAX_WEAPON_UPGRADE)
    {
        return 0;
    }

    int totalCost = 0;
    for (int i = 0; i < targetLevel; i++)
    {
        totalCost += WEAPON_COST_TABLE[i];
    }
    return totalCost;*/
}

void Weapon_FormatUpgradeInfo(char[] buffer, int maxlen, int level, int points)
{
/*
    if (level >= MAX_WEAPON_UPGRADE)
    {
        Format(buffer, maxlen, "무기 강화가 최대 레벨에 도달했습니다! (+%d)", level);
        return;
    }

    int cost = Weapon_GetUpgradeCost(level);
    float successChance = Weapon_GetSuccessChance(level) * 100.0;
    float missChance    = Weapon_GetMissChance(level) * 100.0;
    float resetChance   = Weapon_GetResetChance(level) * 100.0;

    Format(buffer, maxlen,
           "현재 강화: +%d → +%d\n비용: %d 포인트 (보유: %d)\n성공: %.0f%% | 실패: %.0f%% | 파괴: %.0f%%",
           level, level + 1, cost, points, successChance, missChance, resetChance);*/
}

// ============================================================================
// 모듈 정보
// ============================================================================

#define WEAPON_SYSTEM_VERSION "1.0.0"

void Weapon_PrintVersion()
{
/*
    PrintToServer("[WeaponSystem] Module Version: %s", WEAPON_SYSTEM_VERSION);
    PrintToServer("[WeaponSystem] Max Upgrade Level: %d", MAX_WEAPON_UPGRADE);*/
}
