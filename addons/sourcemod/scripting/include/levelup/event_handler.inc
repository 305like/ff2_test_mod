/**
 * ============================================================================
 *  이벤트 핸들러 모듈 (Event Handler Module)
 *  TF2 레벨업 시스템의 게임 이벤트 및 타이머 처리
 * ============================================================================
 */

#if defined _event_handler_included
 #endinput
#endif
#define _event_handler_included

// ============================================================================
// 전역 변수 선언
// ============================================================================

// 타이머 핸들
Handle g_Timer_RewardUpdate = INVALID_HANDLE;      // 주기적 보상 타이머
Handle g_Timer_AddRevivePoint = INVALID_HANDLE;    // 부활 포인트 증가 타이머
Handle g_Timer_HUDUpdate = INVALID_HANDLE;

// 보상 설정
const float REWARD_INTERVAL = 600.0;               // 보상 지급 간격 (10분)
const int REWARD_POINTS = 100;                      // 타이머 보상 포인트
const int REWARD_EXP = 50;                          // 타이머 보상 경험치

// 데미지 누적 보상
const int DAMAGE_THRESHOLD = 2000;                  // 데미지 누적 기준
const int DAMAGE_REWARD_POINTS = 40;                // 누적 달성 시 포인트
const int DAMAGE_REWARD_EXP = 20;                   // 누적 달성 시 경험치

// 처치 보상
const int KILL_REWARD_POINTS = 20;                  // 처치 시 포인트
const int KILL_REWARD_EXP = 20;                     // 처치 시 경험치

// 부활 시스템 설정
const int REVIVE_POINT_BASE = 200;                  // 기본 부활 비용
const int REVIVE_COUNT_BASE = 2;                    // 기본 부활 횟수
const int REVIVE_POINT_MULTIPLIER = 2;              // 부활 시 가격 배수
const int REVIVE_POINT_INCREMENT = 100;             // 시간당 부활 포인트 증가량
const float REVIVE_POINT_INTERVAL = 300.0;          // 부활 포인트 증가 간격 (5분)
const int REVIVE_HEAL_AMOUNT = 2000;                // 부활 시 블루팀 회복량

// ============================================================================
// 이벤트 등록 및 초기화
// ============================================================================

/**
 * 모든 게임 이벤트를 등록합니다.
 */
void Event_Register()
{
    HookEvent("player_spawn", Event_OnPlayerSpawn, EventHookMode_Post);
    HookEvent("player_hurt", Event_OnPlayerHurt, EventHookMode_Post);
    HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Post);
    HookEvent("player_regenerate", Event_OnPlayerRegenerate, EventHookMode_Post);
    HookEvent("post_inventory_application", Event_OnPlayerSpawn, EventHookMode_Post);
    HookEvent("player_changeclass", Event_OnPlayerChangeClass, EventHookMode_Post);
    HookEvent("player_class", Event_OnPlayerChangeClass, EventHookMode_Post);
    HookEvent("player_team", Event_OnPlayerChangeClass, EventHookMode_Post);
    HookEvent("teamplay_round_start", Event_OnRoundStart);
    HookEvent("teamplay_round_win", Event_OnRoundEnd);

    PrintToServer("[Event Handler] 이벤트 등록 완료");
}

// ============================================================================
// 타이머 관리
// ============================================================================

/**
 * 타이머를 초기화하고 시작합니다.
 */
void Timer_Initialize()
{
    // ✅ HUD 타이머 시작 (최우선!)
    if (g_Timer_HUDUpdate == INVALID_HANDLE)
    {
        g_Timer_HUDUpdate = CreateTimer(1.0, Menu_ShowHUD, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        PrintToServer("[Event Handler] HUD 타이머 시작 (1초 간격)");
    }
    
    // 주기적 보상 타이머 시작
    if (g_Timer_RewardUpdate == INVALID_HANDLE)
    {
        g_Timer_RewardUpdate = CreateTimer(REWARD_INTERVAL, Timer_RewardUpdate, _, TIMER_REPEAT);
        PrintToServer("[Event Handler] 보상 타이머 시작 (%.0f초 간격)", REWARD_INTERVAL);
    }
}

/**
 * 모든 타이머를 정리합니다. (플러그인 종료 시 호출)
 */
void Timer_Cleanup()
{
    // ✅ HUD 타이머 정리
    if (g_Timer_HUDUpdate != INVALID_HANDLE)
    {
        KillTimer(g_Timer_HUDUpdate);
        g_Timer_HUDUpdate = INVALID_HANDLE;
        PrintToServer("[Event Handler] HUD 타이머 정리");
    }
    
    // 보상 타이머 정리
    if (g_Timer_RewardUpdate != INVALID_HANDLE)
    {
        KillTimer(g_Timer_RewardUpdate);
        g_Timer_RewardUpdate = INVALID_HANDLE;
        PrintToServer("[Event Handler] 보상 타이머 정리");
    }

    // 부활 포인트 타이머 정리
    if (g_Timer_AddRevivePoint != INVALID_HANDLE)
    {
        KillTimer(g_Timer_AddRevivePoint);
        g_Timer_AddRevivePoint = INVALID_HANDLE;
        PrintToServer("[Event Handler] 부활 포인트 타이머 정리");
    }
}

/**
 * 주기적으로 모든 플레이어에게 경험치와 포인트를 지급합니다.
 */
public Action Timer_RewardUpdate(Handle timer)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && g_playerDataList[i].isLoadComplete)
        {
            PlayerData_AddPoint(i, REWARD_POINTS);
            PlayerData_AddExp(i, REWARD_EXP);
            CPrintToChat(i, "{olive}[EXP&Point]{default} 10분간 플레이하여 {rare}[%d 경험치]{default} {unique}[%d 포인트]{default}를 얻었습니다!",
                REWARD_EXP, REWARD_POINTS);
        }
    }

    return Plugin_Continue;
}

/**
 * 주기적으로 모든 플레이어의 부활 포인트를 증가시킵니다.
 */
public Action Timer_RevivePointUpdate(Handle timer)
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsClientInGame(client) && !IsFakeClient(client))
        {
            g_playerDataList[client].revivePoint += REVIVE_POINT_INCREMENT;
        }
    }

    // 타이머 재설정
    g_Timer_AddRevivePoint = CreateTimer(REVIVE_POINT_INTERVAL, Timer_RevivePointUpdate, _);

    return Plugin_Continue;
}

/**
 * HUD를 업데이트합니다. (추후 구현 가능)
 */
public Action Timer_HUDUpdate(Handle timer)
{
    // TODO: HUD 업데이트 로직 구현
    return Plugin_Continue;
}

/**
 * 플레이어에게 공유 속성을 적용합니다.
 * @param timer     타이머 핸들
 * @param client    클라이언트 인덱스
 */
public Action Timer_ApplySharedAttribute(Handle timer, any client)
{
    if (!IsClientInGame(client))
    {
        return Plugin_Continue;
    }

    // FF2 보스에게는 속성 적용하지 않음
    if (Levelup_IsBoss(client))
        return Plugin_Continue;

    int team = GetClientTeam(client);

    // 팀별 스탯 적용 여부 확인
    if (team == 2)
    {
        if (!g_redEnableStatApply.IntValue)
        {
            TF2Attrib_RemoveAll(client);
            return Plugin_Continue;
        }
    }
    else if (team == 3)
    {
        if (!g_blueEnableStatApply.IntValue)
        {
            TF2Attrib_RemoveAll(client);
            return Plugin_Continue;
        }
    }

    // 무기에 속성 적용
    for (int slot = 0; slot <= 5; slot++)
    {
        int weapon = GetPlayerWeaponSlot(client, slot);
        if (IsValidEntity(weapon))
        {
            for (int i = 0; i < sizeof(g_playerAttributes[client][CLASS_WEAPON]); i++)
            {
                int id = g_playerAttributes[client][CLASS_WEAPON][i].id;
                int upgrade = g_playerAttributes[client][CLASS_WEAPON][i].upgrade;

                if (upgrade <= 0)
                {
                    continue;
                }

                float result = 0.0;
                Address attr = TF2Attrib_GetByName(client, g_attributeTable[CLASS_WEAPON][id].uid);

                if (attr == Address_Null)
                {
                    result = (g_attributeTable[CLASS_WEAPON][id].defaultValue * 0.01) +
                             (float(upgrade) * g_attributeTable[CLASS_WEAPON][id].value * 0.01);
                }
                else
                {
                    float current = TF2Attrib_GetValue(attr);
                    result = current + (float(upgrade) * g_attributeTable[CLASS_WEAPON][id].value * 0.01);
                }

                TF2Attrib_SetByName(weapon, g_attributeTable[CLASS_WEAPON][id].uid, result);
            }
        }
    }

    // 공유 속성 적용
    for (int i = 0; i < sizeof(g_playerAttributes[client][CLASS_SHARED]); i++)
    {
        int id = g_playerAttributes[client][CLASS_SHARED][i].id;
        int upgrade = g_playerAttributes[client][CLASS_SHARED][i].upgrade;

        if (upgrade <= 0)
        {
            continue;
        }

        Address attr = TF2Attrib_GetByName(client, g_attributeTable[CLASS_SHARED][id].uid);
        float result = 0.0;

        if (attr == Address_Null)
        {
            // 새로운 속성 적용
            if (g_attributeTable[CLASS_SHARED][id].additiveMode == ADDITIVE_NUMBER)
            {
                result = g_attributeTable[CLASS_SHARED][id].defaultValue +
                         (float(upgrade) * g_attributeTable[CLASS_SHARED][id].value);
            }
            else if (g_attributeTable[CLASS_SHARED][id].additiveMode == ADDITIVE_PERCENT)
            {
                result = (g_attributeTable[CLASS_SHARED][id].defaultValue * 0.01) +
                         (float(upgrade) * g_attributeTable[CLASS_SHARED][id].value * 0.01);
            }
            else if (g_attributeTable[CLASS_SHARED][id].additiveMode == MINUS_NUMBER)
            {
                result = g_attributeTable[CLASS_SHARED][id].defaultValue -
                         (float(upgrade) * g_attributeTable[CLASS_SHARED][id].value);
            }
            else if (g_attributeTable[CLASS_SHARED][id].additiveMode == MINUS_PERCENT)
            {
                result = (g_attributeTable[CLASS_SHARED][id].defaultValue * 0.01) -
                         (float(upgrade) * g_attributeTable[CLASS_SHARED][id].value * 0.01);
            }

            TF2Attrib_SetByName(client, g_attributeTable[CLASS_SHARED][id].uid, result);
        }
        else
        {
            // 기존 속성에 추가
            float current = TF2Attrib_GetValue(attr);

            if (g_attributeTable[CLASS_SHARED][id].additiveMode == ADDITIVE_NUMBER)
            {
                result = current + (float(upgrade) * g_attributeTable[CLASS_SHARED][id].value);
            }
            else if (g_attributeTable[CLASS_SHARED][id].additiveMode == ADDITIVE_PERCENT)
            {
                result = current + (float(upgrade) * g_attributeTable[CLASS_SHARED][id].value * 0.01);
            }
            else if (g_attributeTable[CLASS_SHARED][id].additiveMode == MINUS_NUMBER)
            {
                result = current - (float(upgrade) * g_attributeTable[CLASS_SHARED][id].value);
            }
            else if (g_attributeTable[CLASS_SHARED][id].additiveMode == MINUS_PERCENT)
            {
                result = current - (float(upgrade) * g_attributeTable[CLASS_SHARED][id].value * 0.01);
            }

            TF2Attrib_SetByName(client, g_attributeTable[CLASS_SHARED][id].uid, result);
        }
    }

    return Plugin_Continue;
}

/**
 * 무기 속성을 적용합니다. (추후 필요 시 구현)
 */
public Action Timer_ApplyWeaponAttribute(Handle timer, any client)
{
    // TODO: 무기 속성 적용 로직 구현
    return Plugin_Continue;
}

// ============================================================================
// 게임 이벤트 핸들러
// ============================================================================

/**
 * 플레이어 스폰 이벤트 핸들러
 * 클래스별 속성을 적용합니다.
 */
public Action Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    PrintToServer("[Event Handler] OnPlayerSpawn: %d", client);

    if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client) || !IsClientAuthorized(client))
    {
        return Plugin_Continue;
    }

    // FF2 보스에게는 속성 적용하지 않음
    if (Levelup_IsBoss(client))
        return Plugin_Continue;

    // 데이터 로드 안됐으면 스킵
    if (!PlayerData_IsLoaded(client))
        return Plugin_Continue;

    int team = GetClientTeam(client);

    // 팀별 스탯 적용 여부 확인
    if (team == 2 && !g_redEnableStatApply.IntValue)
    {
        TF2Attrib_RemoveAll(client);
        return Plugin_Continue;
    }
    else if (team == 3 && !g_blueEnableStatApply.IntValue)
    {
        TF2Attrib_RemoveAll(client);
        return Plugin_Continue;
    }

    // 기존 속성 제거
    TF2Attrib_RemoveAll(client);

    // 클래스별 속성 적용
    ApplyClassAttributes(client);

    // 공유 속성은 0.5초 후 적용
    CreateTimer(0.5, Timer_ApplySharedAttribute, client);

    return Plugin_Continue;
}

/**
 * 플레이어 피해 이벤트 핸들러
 * 데미지 누적 및 보상 처리
 */
public Action Event_OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int damage = event.GetInt("damageamount");

    if (attacker <= 0 || victim <= 0 || !IsClientInGame(attacker) ||
        attacker == victim || IsFakeClient(attacker))
    {
        return Plugin_Continue;
    }

    // FF2 보스에게는 경험치/포인트 보상 적용하지 않음
    if (Levelup_IsBoss(attacker))
        return Plugin_Continue;

    // 데미지 누적
    //g_playerDataList[attacker].damage += damage;

	ExpLevel_TrackDamage(attacker, damage);

	/*
    // 누적 데미지 달성 확인
    int multiple = 1;
    if (g_playerDataList[attacker].damage >= DAMAGE_THRESHOLD)
    {
        multiple = g_playerDataList[attacker].damage / DAMAGE_THRESHOLD;

        for (int i = 0; i < multiple; i++)
        {
            PlayerData_AddExp(attacker, DAMAGE_REWARD_EXP);
            PlayerData_AddPoint(attacker, DAMAGE_REWARD_POINTS);
        }

        CPrintToChat(attacker, "{olive}[EXP&Point]{default} 데미지 누적 달성! {rare}[%d 경험치]{default} {unique}[%d 포인트]{default} 획득!",
            DAMAGE_REWARD_EXP * multiple, DAMAGE_REWARD_POINTS * multiple);

        g_playerDataList[attacker].damage -= multiple * DAMAGE_THRESHOLD;
    }*/

    return Plugin_Continue;
}

/**
 * 플레이어 사망 이벤트 핸들러
 * 처치자에게 보상을 지급하고 피해자에게 부활 메뉴를 표시합니다.
 */
 
public Action Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));

    // ✅ 데드링어 체크
    int deathFlags = event.GetInt("death_flags");
    bool isDeadRinger = (deathFlags & 32) != 0;  // 32 = TF_DEATHFLAG_DEADRINGER

    // ✅ 데드링어가 아닐 때만 부활 메뉴 표시
    if (!isDeadRinger && victim > 0 && IsClientInGame(victim) && !IsFakeClient(victim))
    {
        Menu_ShowRevive(victim);
    }

    // ✅ 처치자 보상 (FF2 보스 제외)
    if (attacker > 0 && IsClientInGame(attacker) && !IsFakeClient(attacker) && attacker != victim && !Levelup_IsBoss(attacker))
    {
        PlayerData_AddExp(attacker, KILL_REWARD_EXP);
        PlayerData_AddPoint(attacker, KILL_REWARD_POINTS);

        CPrintToChat(attacker, "{olive}[EXP&Point]{default} 적 처치! {rare}[%d 경험치]{default} {unique}[%d 포인트]{default} 획득!",
            KILL_REWARD_EXP, KILL_REWARD_POINTS);
    }

    return Plugin_Continue;
}

/**
 * 플레이어 재생 이벤트 핸들러
 * 속성을 다시 적용합니다.
 */
public Action Event_OnPlayerRegenerate(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    PrintToServer("[Event Handler] OnPlayerRegenerate: %d", client);

    if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
    {
        return Plugin_Continue;
    }

    // FF2 보스에게는 속성 적용하지 않음
    if (Levelup_IsBoss(client))
        return Plugin_Continue;

    int team = GetClientTeam(client);

    // 팀별 스탯 적용 여부 확인
    if (team == 2 && !g_redEnableStatApply.IntValue)
    {
        TF2Attrib_RemoveAll(client);
        return Plugin_Continue;
    }
    else if (team == 3 && !g_blueEnableStatApply.IntValue)
    {
        TF2Attrib_RemoveAll(client);
        return Plugin_Continue;
    }

    // 기존 속성 제거 후 재적용
    TF2Attrib_RemoveAll(client);
    ApplyClassAttributes(client);
    CreateTimer(0.5, Timer_ApplySharedAttribute, client);

    return Plugin_Continue;
}

/**
 * 플레이어 클래스 변경 이벤트 핸들러
 * 새 클래스의 속성을 적용합니다.
 */
public Action Event_OnPlayerChangeClass(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    PrintToServer("[Event Handler] OnPlayerChangeClass: %d", client);

    if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
    {
        return Plugin_Continue;
    }

    // FF2 보스에게는 속성 적용하지 않음
    if (Levelup_IsBoss(client))
        return Plugin_Continue;

    int team = GetClientTeam(client);

    // 팀별 스탯 적용 여부 확인
    if (team == 2 && !g_redEnableStatApply.IntValue)
    {
        TF2Attrib_RemoveAll(client);
        return Plugin_Continue;
    }
    else if (team == 3 && !g_blueEnableStatApply.IntValue)
    {
        TF2Attrib_RemoveAll(client);
        return Plugin_Continue;
    }

    // 기존 속성 제거 후 재적용
    TF2Attrib_RemoveAll(client);
    ApplyClassAttributes(client);
    CreateTimer(0.5, Timer_ApplySharedAttribute, client);

    return Plugin_Continue;
}

/**
 * 라운드 시작 이벤트 핸들러
 * 부활 시스템을 초기화합니다.
 */
public Action Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    PrintToServer("[Event Handler] OnRoundStart");

    // 부활 포인트 타이머 시작
    g_Timer_AddRevivePoint = CreateTimer(REVIVE_POINT_INTERVAL, Timer_RevivePointUpdate, _);

    // 모든 플레이어의 부활 정보 초기화
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client) || IsFakeClient(client) || !g_playerDataList[client].isLoadComplete)
        {
            continue;
        }

        Revive_Initialize(client);
    }

    return Plugin_Continue;
}

/**
 * 라운드 종료 이벤트 핸들러
 * 타이머를 정리합니다.
 */
public Action Event_OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    PrintToServer("[Event Handler] OnRoundEnd");

    // 부활 포인트 타이머 정리
    if (g_Timer_AddRevivePoint != INVALID_HANDLE)
    {
        KillTimer(g_Timer_AddRevivePoint);
        g_Timer_AddRevivePoint = INVALID_HANDLE;
    }

    return Plugin_Continue;
}

// ============================================================================
// 부활 시스템
// ============================================================================

/**
 * 플레이어의 부활 정보를 초기화합니다.
 * @param client    클라이언트 인덱스
 */
void Revive_Initialize(int client)
{
    if (!IsClientInGame(client) || IsFakeClient(client))
    {
        return;
    }

    g_playerDataList[client].revivePoint = REVIVE_POINT_BASE;
    g_playerDataList[client].reviveCount = REVIVE_COUNT_BASE;

    PrintToServer("[Event Handler] Revive initialized for client %d: Point=%d, Count=%d",
        client, REVIVE_POINT_BASE, REVIVE_COUNT_BASE);
}

/**
 * 플레이어가 부활할 수 있는지 확인합니다.
 * @param client    클라이언트 인덱스
 * @return          부활 가능 여부
 */
bool Revive_CanRevive(int client)
{
    if (!IsClientInGame(client) || IsFakeClient(client))
    {
        return false;
    }

    // 이미 살아있음
    if (IsPlayerAlive(client))
    {
		PrintToChat(client, "당신은 이미 살아있습니다!");
        return false;
    }

    // 포인트 부족
    if (g_playerDataList[client].point < g_playerDataList[client].revivePoint)
    {
		PrintToChat(client, "포인트가 부족합니다!");
        return false;
    }

    // 부활 횟수 소진
    if (g_playerDataList[client].reviveCount <= 0)
    {
		PrintToChat(client, "부활 횟수를 전부 소진하였습니다!");
        return false;
    }

    return true;
}

/**
 * 플레이어를 부활시킵니다.
 * @param client    클라이언트 인덱스
 */
void Revive_DoRevive(int client)
{
    if (!Revive_CanRevive(client))
    {
        return;
    }

    // 포인트 차감
    PlayerData_TakePoint(client, g_playerDataList[client].revivePoint);

    // 부활 비용 증가 및 횟수 감소
    g_playerDataList[client].revivePoint *= REVIVE_POINT_MULTIPLIER;
    g_playerDataList[client].reviveCount--;

    // 플레이어 부활
    TF2_RespawnPlayer(client);

    // 효과음 재생 및 무적 부여
    EmitSoundToAll("misc/point_revive.mp3");
    TF2_AddCondition(client, TFCond_Ubercharged, 3.0);

    // 블루팀 회복
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 3)
        {
            HealClient(i, REVIVE_HEAL_AMOUNT);
        }
    }

    // 부활 메시지
    char respawnText[256];
    Format(respawnText, sizeof(respawnText), "%s님이 부활권을 사용하여 부활하였습니다.",
        g_playerDataList[client].basenick);

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            PrintCenterText(i, respawnText);
        }
    }

    PrintToServer("[Event Handler] Client %d revived. New cost: %d, Remaining: %d",
        client, g_playerDataList[client].revivePoint, g_playerDataList[client].reviveCount);
}

/**
 * 플레이어의 부활 포인트를 증가시킵니다.
 * @param client    클라이언트 인덱스
 * @param points    증가시킬 포인트
 */
void Revive_AddPoint(int client, int points)
{
    if (!IsClientInGame(client) || IsFakeClient(client))
    {
        return;
    }

    g_playerDataList[client].revivePoint += points;
}

/**
 * 클래스별 속성을 적용합니다.
 * @param client    클라이언트 인덱스
 */
void ApplyClassAttributes(int client)
{
    TFClassType class = TF2_GetPlayerClass(client);
	Attribute_ApplyToPlayer(client, class);
}
