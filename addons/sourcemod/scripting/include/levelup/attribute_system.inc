/**
 * =============================================================================
 * TF2 Level System - Attribute System Module
 * 속성 시스템 모듈
 *
 * 원본 levelup.sp의 140+ 중복 코드 블록을 일반화된 함수로 최적화
 * 12개 개별 AttributeTable 배열을 2차원 배열로 통합하여 메모리 효율 개선
 * =============================================================================
 */

#if defined _tf2level_attribute_system_included
    #endinput
#endif
#define _tf2level_attribute_system_included

// =============================================================================
// 상수 정의 (공통 상수는 메인 파일에 정의)
// =============================================================================
// CLASS_SCOUT, CLASS_MEDIC 등의 클래스 상수는 메인 파일에 정의
// ADDITIVE_PERCENT 등의 모드 상수도 메인 파일에 정의
// MAX_CLASSES, MAX_ATTRIBUTES도 메인 파일에 정의

// =============================================================================
// 데이터 구조체
// =============================================================================

/**
 * 속성 테이블 구조체
 * 각 클래스의 스킬/속성 정의를 저장
 */
enum struct AttributeTable
{
    char uid[64];           // TF2 속성 고유 ID
    char title[80];         // 메뉴에 표시될 제목
    int class;              // 클래스 ID
    int max;                // 최대 업그레이드 레벨
    int point;              // 업그레이드당 필요 포인트
    float value;            // 업그레이드당 증가값
    float defaultValue;     // 기본값
    int additiveMode;       // 적용 모드
    bool isDisableDrawValue; // 값 표시 비활성화 (ON/OFF 스킬용)
}

// =============================================================================
// 전역 변수
// =============================================================================

// 속성 테이블 (2차원 배열로 통합)
AttributeTable g_attributeTable[MAX_CLASSES][MAX_ATTRIBUTES];

// 클래스별 속성 개수
int g_attributeCount[MAX_CLASSES] = {
    13, // Scout
    14, // Medic
    13, // Soldier
    13, // Pyro
    16, // Spy
    16, // Demoman
    15, // Sniper
    17, // Engineer
    14, // Heavy
    3,  // Hale
    2,  // Shared
    1   // Weapon
};

// ConVar
ConVar g_redEnableStatApply;
ConVar g_blueEnableStatApply;

// =============================================================================
// 초기화 함수
// =============================================================================

/**
 * 속성 시스템 초기화
 * OnPluginStart()에서 호출
 */
stock void Attribute_Initialize()
{
    // ConVar 등록
    g_redEnableStatApply = CreateConVar("levelup_red_enable_stat", "1", "레드팀 속성 적용 활성화");
    g_blueEnableStatApply = CreateConVar("levelup_blue_enable_stat", "0", "블루팀 속성 적용 활성화");
    
    // 속성 테이블 생성
    CreateAttributeTable();
}

/**
 * 속성 계산 함수
 * 업그레이드 레벨에 따라 최종 속성값 계산
 *
 * @param attr          속성 테이블
 * @param upgrade       업그레이드 레벨
 * @return              계산된 속성값
 */
stock float Attribute_Calculate(AttributeTable attr, int upgrade)
{
    if (upgrade <= 0)
        return attr.defaultValue;
    
    float result = 0.0;
    
    switch (attr.additiveMode)
    {
        case ADDITIVE_NUMBER:
        {
            // 고정값 더하기: defaultValue + (upgrade * value)
            result = attr.defaultValue + (float(upgrade) * attr.value);
        }
        case ADDITIVE_PERCENT:
        {
            // 퍼센트 더하기: (defaultValue * 0.01) + (upgrade * value * 0.01)
            result = (attr.defaultValue * 0.01) + (float(upgrade) * attr.value * 0.01);
        }
        case MINUS_NUMBER:
        {
            // 고정값 빼기: defaultValue - (upgrade * value)
            result = attr.defaultValue - (float(upgrade) * attr.value);
        }
        case MINUS_PERCENT:
        {
            // 퍼센트 빼기: (defaultValue * 0.01) - (upgrade * value * 0.01)
            result = (attr.defaultValue * 0.01) - (float(upgrade) * attr.value * 0.01);
        }
        default:
        {
            result = attr.defaultValue;
        }
    }
    
    return result;
}

/**
 * 플레이어에게 속성 적용
 * OnPlayerSpawn 이벤트에서 호출
 *
 * @param client        플레이어 인덱스
 * @param tfClass       TF2 클래스 (TFClass_Scout, TFClass_Soldier 등)
 */
stock void Attribute_ApplyToPlayer(int client, TFClassType tfClass)
{
    if (!IsValidClient(client))
        return;

    // FF2 보스에게는 속성 적용하지 않음
    if (Levelup_IsBoss(client))
        return;

    // FF2 아레나 준비 라운드에서는 속성 적용하지 않음 (GameRules 직접 체크)
    if (LibraryExists("freak_fortress_2"))
    {
        if (!FF2_IsFF2Enabled())
            return;

        RoundState rs = GameRules_GetRoundState();
        if (rs != RoundState_RoundRunning && rs != RoundState_Stalemate)
            return;
    }

    // 팀 확인
    int team = GetClientTeam(client);
    if (team == 2) // 레드팀
    {
        if (!g_redEnableStatApply.BoolValue)
        {
            TF2Attrib_RemoveAll(client);
            return;
        }
    }
    else if (team == 3) // 블루팀
    {
        if (!g_blueEnableStatApply.BoolValue)
        {
            TF2Attrib_RemoveAll(client);
            return;
        }
    }
    
    // 기존 속성 제거
    TF2Attrib_RemoveAll(client);
    
    // TFClassType을 CLASS_ 인덱스로 변환
    int classIdx = TFClassToIndex(tfClass);
    if (classIdx < 0)
        return;
    
    // 해당 클래스의 모든 속성 적용
    int attrCount = g_attributeCount[classIdx];
    for (int i = 0; i < attrCount; i++)
    {
        // 플레이어의 업그레이드 레벨 가져오기 (외부 player_data.inc에서)
        int upgrade = PlayerData_GetAttributeUpgrade(client, classIdx, i);
        
        if (upgrade <= 0)
            continue;

        // 비활성화된 속성 건너뛰기 (uid가 비어있으면 스킵)
        if (StrEqual(g_attributeTable[classIdx][i].uid, ""))
            continue;

        // 속성값 계산
        float result = Attribute_Calculate(g_attributeTable[classIdx][i], upgrade);

        // TF2 속성 적용
        TF2Attrib_SetByName(client, g_attributeTable[classIdx][i].uid, result);
    }
    
    // 공용 속성은 0.5초 후 적용 (타이머 사용)
    CreateTimer(0.5, Timer_ApplySharedAttribute2, client, TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * 공용 속성 적용 타이머
 */
public Action Timer_ApplySharedAttribute2(Handle timer, any client)
{
    if (!IsValidClient(client) || !IsPlayerAlive(client))
        return Plugin_Stop;

    // FF2 보스에게는 속성 적용하지 않음
    if (Levelup_IsBoss(client))
        return Plugin_Stop;

    // FF2 아레나 준비 라운드에서는 속성 적용하지 않음 (GameRules 직접 체크)
    if (LibraryExists("freak_fortress_2"))
    {
        if (!FF2_IsFF2Enabled())
            return Plugin_Stop;

        RoundState rs = GameRules_GetRoundState();
        if (rs != RoundState_RoundRunning && rs != RoundState_Stalemate)
            return Plugin_Stop;
    }

    // SHARED 클래스 속성 적용
    int sharedCount = g_attributeCount[CLASS_SHARED];
    for (int i = 0; i < sharedCount; i++)
    {
        int upgrade = PlayerData_GetAttributeUpgrade(client, CLASS_SHARED, i);
        if (upgrade <= 0)
            continue;

        if (StrEqual(g_attributeTable[CLASS_SHARED][i].uid, ""))
            continue;

        float result = Attribute_Calculate(g_attributeTable[CLASS_SHARED][i], upgrade);
        TF2Attrib_SetByName(client, g_attributeTable[CLASS_SHARED][i].uid, result);
    }
    
    // 무기 속성 적용
    Attribute_ApplyToWeapons(client);
    
    return Plugin_Stop;
}

/**
 * 플레이어의 모든 무기에 속성 적용
 */
stock void Attribute_ApplyToWeapons(int client)
{
    if (!IsValidClient(client) || !IsPlayerAlive(client))
        return;
    
    int weaponCount = g_attributeCount[CLASS_WEAPON];
    
    // 모든 무기 슬롯 순회
    for (int slot = 0; slot < 6; slot++)
    {
        int weapon = GetPlayerWeaponSlot(client, slot);
        if (!IsValidEntity(weapon))
            continue;
        
        // 무기에 속성 적용
        for (int i = 0; i < weaponCount; i++)
        {
            int upgrade = PlayerData_GetAttributeUpgrade(client, CLASS_WEAPON, i);
            if (upgrade <= 0)
                continue;

            if (StrEqual(g_attributeTable[CLASS_WEAPON][i].uid, ""))
                continue;

            float result = Attribute_Calculate(g_attributeTable[CLASS_WEAPON][i], upgrade);
            TF2Attrib_SetByName(weapon, g_attributeTable[CLASS_WEAPON][i].uid, result);
        }
    }
}

/**
 * TFClassType을 CLASS_ 인덱스로 변환
 */
stock int TFClassToIndex(TFClassType tfClass)
{
    switch (tfClass)
    {
        case TFClass_Scout:     return CLASS_SCOUT;
        case TFClass_Medic:     return CLASS_MEDIC;
        case TFClass_Soldier:   return CLASS_SOLDIER;
        case TFClass_Pyro:      return CLASS_PYRO;
        case TFClass_Spy:       return CLASS_SPY;
        case TFClass_DemoMan:   return CLASS_DEMOMAN;
        case TFClass_Sniper:    return CLASS_SNIPER;
        case TFClass_Engineer:  return CLASS_ENGINEER;
        case TFClass_Heavy:     return CLASS_HEAVY;
        default:                return -1;
    }
}

/**
 * 속성 테이블 접근 함수
 */
stock AttributeTable Attribute_GetTable(int classIdx, int attrIdx)
{
    return g_attributeTable[classIdx][attrIdx];
}

stock int Attribute_GetCount(int classIdx)
{
    return g_attributeCount[classIdx];
}

// =============================================================================
// 속성 테이블 생성
// 원본 levelup.sp의 CreateAttributeTable() 함수를 그대로 이식
// =============================================================================

void CreateAttributeTable()
{
	g_attributeTable[CLASS_SCOUT][0].class = CLASS_SCOUT;
	g_attributeTable[CLASS_SCOUT][0].max = 5;
	g_attributeTable[CLASS_SCOUT][0].point = 1;
	g_attributeTable[CLASS_SCOUT][0].uid = "move speed bonus";
	g_attributeTable[CLASS_SCOUT][0].value = float(3);
	g_attributeTable[CLASS_SCOUT][0].defaultValue = float(100);
	g_attributeTable[CLASS_SCOUT][0].additiveMode = ADDITIVE_PERCENT;
	g_attributeTable[CLASS_SCOUT][0].title = "이동속도 %.0f%% 증가 (%dpt)(%d/%d)";
	
	g_attributeTable[CLASS_SCOUT][1].class = CLASS_SCOUT;
	g_attributeTable[CLASS_SCOUT][1].max = 10;
	g_attributeTable[CLASS_SCOUT][1].point = 1;
	g_attributeTable[CLASS_SCOUT][1].uid = "increased jump height";
	g_attributeTable[CLASS_SCOUT][1].value = float(5);
	g_attributeTable[CLASS_SCOUT][1].defaultValue = float(100);
	g_attributeTable[CLASS_SCOUT][1].additiveMode = ADDITIVE_PERCENT;	
	g_attributeTable[CLASS_SCOUT][1].title = "점프높이 %.0f%% 증가 (%dpt)(%d/%d)";	
	
	g_attributeTable[CLASS_SCOUT][2].class = CLASS_SCOUT;
	g_attributeTable[CLASS_SCOUT][2].max = 10;
	g_attributeTable[CLASS_SCOUT][2].point = 1;
	g_attributeTable[CLASS_SCOUT][2].uid = "fire rate bonus";
	g_attributeTable[CLASS_SCOUT][2].value = float(5);
	g_attributeTable[CLASS_SCOUT][2].defaultValue = float(100);
	g_attributeTable[CLASS_SCOUT][2].additiveMode = MINUS_PERCENT;	
	g_attributeTable[CLASS_SCOUT][2].title = "공격속도 %.0f%% 증가 (%dpt)(%d/%d)";	
	
	g_attributeTable[CLASS_SCOUT][3].class = CLASS_SCOUT;
	g_attributeTable[CLASS_SCOUT][3].max = 10;
	g_attributeTable[CLASS_SCOUT][3].point = 1;
	g_attributeTable[CLASS_SCOUT][3].uid = "Reload time decreased";
	g_attributeTable[CLASS_SCOUT][3].value = float(5);
	g_attributeTable[CLASS_SCOUT][3].defaultValue = float(100);
	g_attributeTable[CLASS_SCOUT][3].additiveMode = MINUS_PERCENT;		
	g_attributeTable[CLASS_SCOUT][3].title = "재장전속도 %.0f%% 증가 (%dpt)(%d/%d)";		
	
	g_attributeTable[CLASS_SCOUT][4].class = CLASS_SCOUT; 
	g_attributeTable[CLASS_SCOUT][4].max = 3;
	g_attributeTable[CLASS_SCOUT][4].point = 1;
	g_attributeTable[CLASS_SCOUT][4].uid = "deploy time decreased";
	g_attributeTable[CLASS_SCOUT][4].value = float(15);
	g_attributeTable[CLASS_SCOUT][4].defaultValue = float(100);
	g_attributeTable[CLASS_SCOUT][4].additiveMode = MINUS_PERCENT;		
	g_attributeTable[CLASS_SCOUT][4].title = "무기전환속도 %.0f%% 증가 (%dpt)(%d/%d)";	
	
	g_attributeTable[CLASS_SCOUT][5].class = CLASS_SCOUT;
	g_attributeTable[CLASS_SCOUT][5].max = 0;
	g_attributeTable[CLASS_SCOUT][5].point = 1;
	g_attributeTable[CLASS_SCOUT][5].uid = "";
	g_attributeTable[CLASS_SCOUT][5].value = float(2);
	g_attributeTable[CLASS_SCOUT][5].defaultValue = float(0);
	g_attributeTable[CLASS_SCOUT][5].additiveMode = ADDITIVE_NUMBER;		
	g_attributeTable[CLASS_SCOUT][5].title = "적중 시 체력 %.0f 회복 (%dpt)(%d/%d)";	
	
	g_attributeTable[CLASS_SCOUT][6].class = CLASS_SCOUT; 
	g_attributeTable[CLASS_SCOUT][6].max = 0;
	g_attributeTable[CLASS_SCOUT][6].point = 2;
	g_attributeTable[CLASS_SCOUT][6].uid = "";
	g_attributeTable[CLASS_SCOUT][6].value = float(1);
	g_attributeTable[CLASS_SCOUT][6].defaultValue = float(100);
	g_attributeTable[CLASS_SCOUT][6].additiveMode = ADDITIVE_PERCENT;		
	g_attributeTable[CLASS_SCOUT][6].title = "피해량 %.0f%% 증가 (%dpt)(%d/%d)";		
	
	g_attributeTable[CLASS_SCOUT][7].class = CLASS_SCOUT; 
	g_attributeTable[CLASS_SCOUT][7].max = 5;
	g_attributeTable[CLASS_SCOUT][7].point = 2;
	g_attributeTable[CLASS_SCOUT][7].uid = "effect bar recharge rate increased";
	g_attributeTable[CLASS_SCOUT][7].value = float(5);
	g_attributeTable[CLASS_SCOUT][7].defaultValue = float(100);
	g_attributeTable[CLASS_SCOUT][7].additiveMode = MINUS_PERCENT;		
	g_attributeTable[CLASS_SCOUT][7].title = "재충전속도 %.0f%% 증가 (%dpt)(%d/%d)";		
	
	g_attributeTable[CLASS_SCOUT][8].class = CLASS_SCOUT; 
	g_attributeTable[CLASS_SCOUT][8].max = 5;
	g_attributeTable[CLASS_SCOUT][8].point = 2;
	g_attributeTable[CLASS_SCOUT][8].uid = "max health additive bonus";
	g_attributeTable[CLASS_SCOUT][8].value = float(10);
	g_attributeTable[CLASS_SCOUT][8].defaultValue = float(0);
	g_attributeTable[CLASS_SCOUT][8].additiveMode = ADDITIVE_NUMBER;	
	g_attributeTable[CLASS_SCOUT][8].title = "최대체력 %.0f 증가 (%dpt)(%d/%d)";		
	
	g_attributeTable[CLASS_SCOUT][9].class = CLASS_SCOUT; 
	g_attributeTable[CLASS_SCOUT][9].max = 4;
	g_attributeTable[CLASS_SCOUT][9].point = 3;
	g_attributeTable[CLASS_SCOUT][9].uid = "clip size bonus";
	g_attributeTable[CLASS_SCOUT][9].value = float(50);
	g_attributeTable[CLASS_SCOUT][9].defaultValue = float(100);
	g_attributeTable[CLASS_SCOUT][9].additiveMode = ADDITIVE_PERCENT;	
	g_attributeTable[CLASS_SCOUT][9].title = "장탄수 %.0f%% 증가 (%dpt)(%d/%d)";	
	
	g_attributeTable[CLASS_SCOUT][10].class = CLASS_SCOUT; 
	g_attributeTable[CLASS_SCOUT][10].max = 2;
	g_attributeTable[CLASS_SCOUT][10].point = 3;
	g_attributeTable[CLASS_SCOUT][10].uid = "weapon spread bonus";
	g_attributeTable[CLASS_SCOUT][10].value = float(25);
	g_attributeTable[CLASS_SCOUT][10].defaultValue = float(0);
	g_attributeTable[CLASS_SCOUT][10].additiveMode = MINUS_PERCENT;		
	g_attributeTable[CLASS_SCOUT][10].title = "집탄률 %.0f%% 증가 (%dpt)(%d/%d)";	
	
	g_attributeTable[CLASS_SCOUT][11].class = CLASS_SCOUT; 
	g_attributeTable[CLASS_SCOUT][11].max = 2;
	g_attributeTable[CLASS_SCOUT][11].point = 4;
	g_attributeTable[CLASS_SCOUT][11].uid = "bullets per shot bonus";
	g_attributeTable[CLASS_SCOUT][11].value = float(50);
	g_attributeTable[CLASS_SCOUT][11].defaultValue = float(100);
	g_attributeTable[CLASS_SCOUT][11].additiveMode = ADDITIVE_PERCENT;	
	g_attributeTable[CLASS_SCOUT][11].title = "발사되는 탄환수 %.0f%% 증가 (%dpt)(%d/%d)";	

	g_attributeTable[CLASS_SCOUT][12].class = CLASS_SCOUT;
	g_attributeTable[CLASS_SCOUT][12].max = 1;
	g_attributeTable[CLASS_SCOUT][12].point = 5;
	g_attributeTable[CLASS_SCOUT][12].uid = "cancel falling damage";
	g_attributeTable[CLASS_SCOUT][12].value = float(100);
	g_attributeTable[CLASS_SCOUT][12].defaultValue = float(0);
	g_attributeTable[CLASS_SCOUT][12].additiveMode = ADDITIVE_PERCENT;	
	g_attributeTable[CLASS_SCOUT][12].isDisableDrawValue = true;
	g_attributeTable[CLASS_SCOUT][12].title = "낙하 피해 무시 (%dpt)(%d/%d)";	
	
	g_attributeTable[CLASS_SOLDIER][0].class = CLASS_SOLDIER;
	g_attributeTable[CLASS_SOLDIER][0].max = 5;
	g_attributeTable[CLASS_SOLDIER][0].point = 1;
	g_attributeTable[CLASS_SOLDIER][0].uid = "move speed bonus";
	g_attributeTable[CLASS_SOLDIER][0].value = float(3);
	g_attributeTable[CLASS_SOLDIER][0].defaultValue = float(100);
	g_attributeTable[CLASS_SOLDIER][0].additiveMode = ADDITIVE_PERCENT;		
	g_attributeTable[CLASS_SOLDIER][0].title = "이동속도 %.0f%% 증가 (%dpt)(%d/%d)";
	
	g_attributeTable[CLASS_SOLDIER][1].class = CLASS_SOLDIER;
	g_attributeTable[CLASS_SOLDIER][1].max = 10;
	g_attributeTable[CLASS_SOLDIER][1].point = 1;
	g_attributeTable[CLASS_SOLDIER][1].uid = "fire rate bonus";
	g_attributeTable[CLASS_SOLDIER][1].value = float(5);
	g_attributeTable[CLASS_SOLDIER][1].defaultValue = float(100);
	g_attributeTable[CLASS_SOLDIER][1].additiveMode = MINUS_PERCENT;	
	g_attributeTable[CLASS_SOLDIER][1].title = "공격속도 %.0f%% 증가 (%dpt)(%d/%d)";	
	
	g_attributeTable[CLASS_SOLDIER][2].class = CLASS_SOLDIER;
	g_attributeTable[CLASS_SOLDIER][2].max = 10;
	g_attributeTable[CLASS_SOLDIER][2].point = 1;
	g_attributeTable[CLASS_SOLDIER][2].uid = "Reload time decreased";
	g_attributeTable[CLASS_SOLDIER][2].value = float(5);
	g_attributeTable[CLASS_SOLDIER][2].defaultValue = float(100);
	g_attributeTable[CLASS_SOLDIER][2].additiveMode = MINUS_PERCENT;	
	g_attributeTable[CLASS_SOLDIER][2].title = "재장전속도 %.0f%% 증가 (%dpt)(%d/%d)";		

	g_attributeTable[CLASS_SOLDIER][3].class = CLASS_SOLDIER;
	g_attributeTable[CLASS_SOLDIER][3].max = 3;
	g_attributeTable[CLASS_SOLDIER][3].point = 1;
	g_attributeTable[CLASS_SOLDIER][3].uid = "deploy time decreased";
	g_attributeTable[CLASS_SOLDIER][3].value = float(15);
	g_attributeTable[CLASS_SOLDIER][3].defaultValue = float(100);
	g_attributeTable[CLASS_SOLDIER][3].additiveMode = MINUS_PERCENT;	
	g_attributeTable[CLASS_SOLDIER][3].title = "무기전환속도 %.0f%% 증가 (%dpt)(%d/%d)";		
	
	g_attributeTable[CLASS_SOLDIER][4].class = CLASS_SOLDIER;
	g_attributeTable[CLASS_SOLDIER][4].max = 0;
	g_attributeTable[CLASS_SOLDIER][4].point = 1;
	g_attributeTable[CLASS_SOLDIER][4].uid = "";
	g_attributeTable[CLASS_SOLDIER][4].value = float(5);
	g_attributeTable[CLASS_SOLDIER][4].defaultValue = float(0);
	g_attributeTable[CLASS_SOLDIER][4].additiveMode = ADDITIVE_NUMBER;		
	g_attributeTable[CLASS_SOLDIER][4].title = "적중시 체력 %.0f 회복 (%dpt)(%d/%d)";	
	
	g_attributeTable[CLASS_SOLDIER][5].class = CLASS_SOLDIER;
	g_attributeTable[CLASS_SOLDIER][5].max = 0;
	g_attributeTable[CLASS_SOLDIER][5].point = 2;
	g_attributeTable[CLASS_SOLDIER][5].uid = "";
	g_attributeTable[CLASS_SOLDIER][5].value = float(1);
	g_attributeTable[CLASS_SOLDIER][5].defaultValue = float(100);
	g_attributeTable[CLASS_SOLDIER][5].additiveMode = ADDITIVE_PERCENT;	
	g_attributeTable[CLASS_SOLDIER][5].title = "피해량 %.0f%% 증가 (%dpt)(%d/%d)";		
	
	g_attributeTable[CLASS_SOLDIER][6].class = CLASS_SOLDIER;
	g_attributeTable[CLASS_SOLDIER][6].max = 10;
	g_attributeTable[CLASS_SOLDIER][6].point = 2;
	g_attributeTable[CLASS_SOLDIER][6].uid = "rocket jump damage reduction";
	g_attributeTable[CLASS_SOLDIER][6].value = float(5);
	g_attributeTable[CLASS_SOLDIER][6].defaultValue = float(100);
	g_attributeTable[CLASS_SOLDIER][6].additiveMode = MINUS_PERCENT;	
	g_attributeTable[CLASS_SOLDIER][6].title = "로켓점프 피해 %.0f%% 감소 (%dpt)(%d/%d)";
	
	g_attributeTable[CLASS_SOLDIER][7].class = CLASS_SOLDIER;
	g_attributeTable[CLASS_SOLDIER][7].max = 5;
	g_attributeTable[CLASS_SOLDIER][7].point = 2;
	g_attributeTable[CLASS_SOLDIER][7].uid = "Blast radius increased";
	g_attributeTable[CLASS_SOLDIER][7].value = float(10);
	g_attributeTable[CLASS_SOLDIER][7].defaultValue = float(100);
	g_attributeTable[CLASS_SOLDIER][7].additiveMode = ADDITIVE_PERCENT;	
	g_attributeTable[CLASS_SOLDIER][7].title = "폭발반경 %.0f%% 증가 (%dpt)(%d/%d)";	
	
	g_attributeTable[CLASS_SOLDIER][8].class = CLASS_SOLDIER;
	g_attributeTable[CLASS_SOLDIER][8].max = 5;
	g_attributeTable[CLASS_SOLDIER][8].point = 2;
	g_attributeTable[CLASS_SOLDIER][8].uid = "Projectile speed increased";
	g_attributeTable[CLASS_SOLDIER][8].value = float(10);
	g_attributeTable[CLASS_SOLDIER][8].defaultValue = float(100);
	g_attributeTable[CLASS_SOLDIER][8].additiveMode = ADDITIVE_PERCENT;	
	g_attributeTable[CLASS_SOLDIER][8].title = "투사체속도 %.0f%% 증가 (%dpt)(%d/%d)";	
	
	g_attributeTable[CLASS_SOLDIER][9].class = CLASS_SOLDIER;
	g_attributeTable[CLASS_SOLDIER][9].max = 5;
	g_attributeTable[CLASS_SOLDIER][9].point = 2;
	g_attributeTable[CLASS_SOLDIER][9].uid = "max health additive bonus";
	g_attributeTable[CLASS_SOLDIER][9].value = float(10);
	g_attributeTable[CLASS_SOLDIER][9].defaultValue = float(0);
	g_attributeTable[CLASS_SOLDIER][9].additiveMode = ADDITIVE_NUMBER;	
	g_attributeTable[CLASS_SOLDIER][9].title = "최대체력 %.0f 증가 (%dpt)(%d/%d)";		
	
	g_attributeTable[CLASS_SOLDIER][10].class = CLASS_SOLDIER;
	g_attributeTable[CLASS_SOLDIER][10].max = 4;
	g_attributeTable[CLASS_SOLDIER][10].point = 3;
	g_attributeTable[CLASS_SOLDIER][10].uid = "clip size bonus";
	g_attributeTable[CLASS_SOLDIER][10].value = float(25);
	g_attributeTable[CLASS_SOLDIER][10].defaultValue = float(100);
	g_attributeTable[CLASS_SOLDIER][10].additiveMode = ADDITIVE_PERCENT;	
	g_attributeTable[CLASS_SOLDIER][10].title = "장탄수 %.0f%% 증가 (%dpt)(%d/%d)";
	
	g_attributeTable[CLASS_SOLDIER][11].class = CLASS_SOLDIER;
	g_attributeTable[CLASS_SOLDIER][11].max = 4;
	g_attributeTable[CLASS_SOLDIER][11].point = 3;
	g_attributeTable[CLASS_SOLDIER][11].uid = "increase buff duration";
	g_attributeTable[CLASS_SOLDIER][11].value = float(25);
	g_attributeTable[CLASS_SOLDIER][11].defaultValue = float(100);
	g_attributeTable[CLASS_SOLDIER][11].additiveMode = ADDITIVE_PERCENT;	
	g_attributeTable[CLASS_SOLDIER][11].title = "깃발유지시간 %.0f%% 증가 (%dpt)(%d/%d)";	
	
	g_attributeTable[CLASS_SOLDIER][12].class = CLASS_SOLDIER;
	g_attributeTable[CLASS_SOLDIER][12].max = 1;
	g_attributeTable[CLASS_SOLDIER][12].point = 5;
	g_attributeTable[CLASS_SOLDIER][12].uid = "rocket specialist";
	g_attributeTable[CLASS_SOLDIER][12].value = float(100);
	g_attributeTable[CLASS_SOLDIER][12].defaultValue = float(0);
	g_attributeTable[CLASS_SOLDIER][12].additiveMode = ADDITIVE_PERCENT;	
	g_attributeTable[CLASS_SOLDIER][12].isDisableDrawValue = true;
	g_attributeTable[CLASS_SOLDIER][12].title = "로켓특화 (%dpt)(%d/%d)";			
	
	g_attributeTable[CLASS_PYRO][0].class = CLASS_PYRO;
	g_attributeTable[CLASS_PYRO][0].max = 5;
	g_attributeTable[CLASS_PYRO][0].point = 1;
	g_attributeTable[CLASS_PYRO][0].uid = "move speed bonus";
	g_attributeTable[CLASS_PYRO][0].value = float(3);
	g_attributeTable[CLASS_PYRO][0].defaultValue = float(100);
	g_attributeTable[CLASS_PYRO][0].additiveMode = ADDITIVE_PERCENT;	
	g_attributeTable[CLASS_PYRO][0].title = "이동속도 %.0f%% 증가 (%dpt)(%d/%d)";	

	g_attributeTable[CLASS_PYRO][1].class = CLASS_PYRO;
	g_attributeTable[CLASS_PYRO][1].max = 10;
	g_attributeTable[CLASS_PYRO][1].point = 1;
	g_attributeTable[CLASS_PYRO][1].uid = "fire rate bonus";
	g_attributeTable[CLASS_PYRO][1].value = float(5);
	g_attributeTable[CLASS_PYRO][1].defaultValue = float(100);
	g_attributeTable[CLASS_PYRO][1].additiveMode = MINUS_PERCENT;	
	g_attributeTable[CLASS_PYRO][1].title = "공격속도 %.0f%% 증가 (%dpt)(%d/%d)";		
	
	g_attributeTable[CLASS_PYRO][2].class = CLASS_PYRO;
	g_attributeTable[CLASS_PYRO][2].max = 10;
	g_attributeTable[CLASS_PYRO][2].point = 1;
	g_attributeTable[CLASS_PYRO][2].uid = "Reload time decreased";
	g_attributeTable[CLASS_PYRO][2].value = float(5);
	g_attributeTable[CLASS_PYRO][2].defaultValue = float(100);
	g_attributeTable[CLASS_PYRO][2].additiveMode = MINUS_PERCENT;	
	g_attributeTable[CLASS_PYRO][2].title = "재장전속도 %.0f%% 증가 (%dpt)(%d/%d)";		
	
	g_attributeTable[CLASS_PYRO][3].class = CLASS_PYRO;
	g_attributeTable[CLASS_PYRO][3].max = 3;
	g_attributeTable[CLASS_PYRO][3].point = 1;
	g_attributeTable[CLASS_PYRO][3].uid = "deploy time decreased";
	g_attributeTable[CLASS_PYRO][3].value = float(15);
	g_attributeTable[CLASS_PYRO][3].defaultValue = float(100);
	g_attributeTable[CLASS_PYRO][3].additiveMode = MINUS_PERCENT;	
	g_attributeTable[CLASS_PYRO][3].title = "무기전환속도 %.0f%% 증가 (%dpt)(%d/%d)";			
	
	g_attributeTable[CLASS_PYRO][4].class = CLASS_PYRO;
	g_attributeTable[CLASS_PYRO][4].max = 0;
	g_attributeTable[CLASS_PYRO][4].point = 1;
	g_attributeTable[CLASS_PYRO][4].uid = "";
	g_attributeTable[CLASS_PYRO][4].value = float(3);
	g_attributeTable[CLASS_PYRO][4].defaultValue = float(0);
	g_attributeTable[CLASS_PYRO][4].additiveMode = ADDITIVE_NUMBER;	
	g_attributeTable[CLASS_PYRO][4].title = "적중시 체력 %.0f 회복 (%dpt)(%d/%d)";	
	
	g_attributeTable[CLASS_PYRO][5].class = CLASS_PYRO;
	g_attributeTable[CLASS_PYRO][5].max = 4;
	g_attributeTable[CLASS_PYRO][5].point = 1;
	g_attributeTable[CLASS_PYRO][5].uid = "weapon burn dmg increased";
	g_attributeTable[CLASS_PYRO][5].value = float(50);
	g_attributeTable[CLASS_PYRO][5].defaultValue = float(100);
	g_attributeTable[CLASS_PYRO][5].additiveMode = ADDITIVE_PERCENT;	
	g_attributeTable[CLASS_PYRO][5].title = "화상피해 %.0f%% 증가 (%dpt)(%d/%d)";		
	
	g_attributeTable[CLASS_PYRO][6].class = CLASS_PYRO;
	g_attributeTable[CLASS_PYRO][6].max = 5;
	g_attributeTable[CLASS_PYRO][6].point = 1;
	g_attributeTable[CLASS_PYRO][6].uid = "weapon burn time increased";
	g_attributeTable[CLASS_PYRO][6].value = float(25);
	g_attributeTable[CLASS_PYRO][6].defaultValue = float(100);
	g_attributeTable[CLASS_PYRO][6].additiveMode = ADDITIVE_PERCENT;	
	g_attributeTable[CLASS_PYRO][6].title = "화상 지속시간 %.0f%% 증가 (%dpt)(%d/%d)";		
	
	g_attributeTable[CLASS_PYRO][7].class = CLASS_PYRO;
	g_attributeTable[CLASS_PYRO][7].max = 0;
	g_attributeTable[CLASS_PYRO][7].point = 2;
	g_attributeTable[CLASS_PYRO][7].uid = "";
	g_attributeTable[CLASS_PYRO][7].value = float(1);
	g_attributeTable[CLASS_PYRO][7].defaultValue = float(100);
	g_attributeTable[CLASS_PYRO][7].additiveMode = ADDITIVE_PERCENT;	
	g_attributeTable[CLASS_PYRO][7].title = "피해량 %.0f%% 증가 (%dpt)(%d/%d)";		

	g_attributeTable[CLASS_PYRO][8].class = CLASS_PYRO;
	g_attributeTable[CLASS_PYRO][8].max = 5;
	g_attributeTable[CLASS_PYRO][8].point = 2;
	g_attributeTable[CLASS_PYRO][8].uid = "max health additive bonus";
	g_attributeTable[CLASS_PYRO][8].value = float(10);
	g_attributeTable[CLASS_PYRO][8].defaultValue = float(0);
	g_attributeTable[CLASS_PYRO][8].additiveMode = ADDITIVE_NUMBER;	
	g_attributeTable[CLASS_PYRO][8].title = "최대체력 %.0f 증가 (%dpt)(%d/%d)";	

	g_attributeTable[CLASS_PYRO][9].class = CLASS_PYRO;
	g_attributeTable[CLASS_PYRO][9].max = 3;
	g_attributeTable[CLASS_PYRO][9].point = 3;
	g_attributeTable[CLASS_PYRO][9].uid = "mult airblast refire time";
	g_attributeTable[CLASS_PYRO][9].value = float(10);
	g_attributeTable[CLASS_PYRO][9].defaultValue = float(100);
	g_attributeTable[CLASS_PYRO][9].additiveMode = MINUS_PERCENT;	
	g_attributeTable[CLASS_PYRO][9].title = "압축공기 발사속도 %.0f%% 증가 (%dpt)(%d/%d)";	

	g_attributeTable[CLASS_PYRO][10].class = CLASS_PYRO;
	g_attributeTable[CLASS_PYRO][10].max = 4;
	g_attributeTable[CLASS_PYRO][10].point = 3;
	g_attributeTable[CLASS_PYRO][10].uid = "flame_speed";
	g_attributeTable[CLASS_PYRO][10].value = float(900);
	g_attributeTable[CLASS_PYRO][10].defaultValue = float(100);
	g_attributeTable[CLASS_PYRO][10].additiveMode = ADDITIVE_NUMBER;	
	g_attributeTable[CLASS_PYRO][10].isDisableDrawValue = true;
	g_attributeTable[CLASS_PYRO][10].title = "사정거리 25% 증가 (%dpt)(%d/%d)";		

	g_attributeTable[CLASS_PYRO][11].class = CLASS_PYRO;
	g_attributeTable[CLASS_PYRO][11].max = 2;
	g_attributeTable[CLASS_PYRO][11].point = 3;
	g_attributeTable[CLASS_PYRO][11].uid = "mult_item_meter_charge_rate";
	g_attributeTable[CLASS_PYRO][11].value = float(15);
	g_attributeTable[CLASS_PYRO][11].defaultValue = float(100);
	g_attributeTable[CLASS_PYRO][11].additiveMode = MINUS_PERCENT;	
	g_attributeTable[CLASS_PYRO][11].title = "가열가속기 재충전 속도 %.0f%% 증가 (%dpt)(%d/%d)";		
	
	g_attributeTable[CLASS_PYRO][12].class = CLASS_PYRO;
	g_attributeTable[CLASS_PYRO][12].max = 1;
	g_attributeTable[CLASS_PYRO][12].point = 4;
	g_attributeTable[CLASS_PYRO][12].uid = "thermal_thruster_air_launch";
	g_attributeTable[CLASS_PYRO][12].value = float(100);
	g_attributeTable[CLASS_PYRO][12].defaultValue = float(0);
	g_attributeTable[CLASS_PYRO][12].additiveMode = ADDITIVE_PERCENT;	
	g_attributeTable[CLASS_PYRO][12].isDisableDrawValue = true;
	g_attributeTable[CLASS_PYRO][12].title = "가열가속기가 공중에서 사용가능합니다 (%dpt)(%d/%d)";		

	g_attributeTable[CLASS_DEMOMAN][0].class = CLASS_DEMOMAN;
	g_attributeTable[CLASS_DEMOMAN][0].max = 5;
	g_attributeTable[CLASS_DEMOMAN][0].point = 1;
	g_attributeTable[CLASS_DEMOMAN][0].uid = "move speed bonus";
	g_attributeTable[CLASS_DEMOMAN][0].value = float(3);
	g_attributeTable[CLASS_DEMOMAN][0].defaultValue = float(100);
	g_attributeTable[CLASS_DEMOMAN][0].additiveMode = ADDITIVE_PERCENT;	
	g_attributeTable[CLASS_DEMOMAN][0].title = "이동속도 %.0f%% 증가 (%dpt)(%d/%d)";		
	
	g_attributeTable[CLASS_DEMOMAN][1].class = CLASS_DEMOMAN;
	g_attributeTable[CLASS_DEMOMAN][1].max = 10;
	g_attributeTable[CLASS_DEMOMAN][1].point = 1;
	g_attributeTable[CLASS_DEMOMAN][1].uid = "fire rate bonus";
	g_attributeTable[CLASS_DEMOMAN][1].value = float(5);
	g_attributeTable[CLASS_DEMOMAN][1].defaultValue = float(100);
	g_attributeTable[CLASS_DEMOMAN][1].additiveMode = MINUS_PERCENT;	
	g_attributeTable[CLASS_DEMOMAN][1].title = "공격속도 %.0f%% 증가 (%dpt)(%d/%d)";	
	
	g_attributeTable[CLASS_DEMOMAN][2].class = CLASS_DEMOMAN;
	g_attributeTable[CLASS_DEMOMAN][2].max = 10;
	g_attributeTable[CLASS_DEMOMAN][2].point = 1;
	g_attributeTable[CLASS_DEMOMAN][2].uid = "Reload time decreased";
	g_attributeTable[CLASS_DEMOMAN][2].value = float(5);
	g_attributeTable[CLASS_DEMOMAN][2].defaultValue = float(100);
	g_attributeTable[CLASS_DEMOMAN][2].additiveMode = MINUS_PERCENT;	
	g_attributeTable[CLASS_DEMOMAN][2].title = "재장전속도 %.0f%% 증가 (%dpt)(%d/%d)";	
	
	g_attributeTable[CLASS_DEMOMAN][3].class = CLASS_DEMOMAN;
	g_attributeTable[CLASS_DEMOMAN][3].max = 3;
	g_attributeTable[CLASS_DEMOMAN][3].point = 1;
	g_attributeTable[CLASS_DEMOMAN][3].uid = "deploy time decreased";
	g_attributeTable[CLASS_DEMOMAN][3].value = float(15);
	g_attributeTable[CLASS_DEMOMAN][3].defaultValue = float(100);
	g_attributeTable[CLASS_DEMOMAN][3].additiveMode = MINUS_PERCENT;	
	g_attributeTable[CLASS_DEMOMAN][3].title = "무기전환속도 %.0f%% 증가 (%dpt)(%d/%d)";		
	
	g_attributeTable[CLASS_DEMOMAN][4].class = CLASS_DEMOMAN;
	g_attributeTable[CLASS_DEMOMAN][4].max = 0;
	g_attributeTable[CLASS_DEMOMAN][4].point = 1;
	g_attributeTable[CLASS_DEMOMAN][4].uid = "";
	g_attributeTable[CLASS_DEMOMAN][4].value = float(2);
	g_attributeTable[CLASS_DEMOMAN][4].defaultValue = float(0);
	g_attributeTable[CLASS_DEMOMAN][4].additiveMode = ADDITIVE_NUMBER;	
	g_attributeTable[CLASS_DEMOMAN][4].title = "적중시 체력 %.0f 회복 (%dpt)(%d/%d)";	
	
	g_attributeTable[CLASS_DEMOMAN][5].class = CLASS_DEMOMAN;
	g_attributeTable[CLASS_DEMOMAN][5].max = 4;
	g_attributeTable[CLASS_DEMOMAN][5].point = 1;
	g_attributeTable[CLASS_DEMOMAN][5].uid = "stickybomb charge rate";
	g_attributeTable[CLASS_DEMOMAN][5].value = float(25);
	g_attributeTable[CLASS_DEMOMAN][5].defaultValue = float(100);
	g_attributeTable[CLASS_DEMOMAN][5].additiveMode = MINUS_PERCENT;	
	g_attributeTable[CLASS_DEMOMAN][5].title = "점착 폭탄 충전속도 %.0f%% 증가 (%dpt)(%d/%d)";	
	
	g_attributeTable[CLASS_DEMOMAN][6].class = CLASS_DEMOMAN;
	g_attributeTable[CLASS_DEMOMAN][6].max = 0;
	g_attributeTable[CLASS_DEMOMAN][6].point = 2;
	g_attributeTable[CLASS_DEMOMAN][6].uid = "";
	g_attributeTable[CLASS_DEMOMAN][6].value = float(1);
	g_attributeTable[CLASS_DEMOMAN][6].defaultValue = float(100);
	g_attributeTable[CLASS_DEMOMAN][6].additiveMode = ADDITIVE_PERCENT;	
	g_attributeTable[CLASS_DEMOMAN][6].title = "피해량 %.0f%% 증가 (%dpt)(%d/%d)";	
	
	g_attributeTable[CLASS_DEMOMAN][7].class = CLASS_DEMOMAN;
	g_attributeTable[CLASS_DEMOMAN][7].max = 5;
	g_attributeTable[CLASS_DEMOMAN][7].point = 2;
	g_attributeTable[CLASS_DEMOMAN][7].uid = "max health additive bonus";
	g_attributeTable[CLASS_DEMOMAN][7].value = float(10);
	g_attributeTable[CLASS_DEMOMAN][7].defaultValue = float(0);
	g_attributeTable[CLASS_DEMOMAN][7].additiveMode = ADDITIVE_NUMBER;	
	g_attributeTable[CLASS_DEMOMAN][7].title = "최대체력 %.0f 증가 (%dpt)(%d/%d)";		
	
	g_attributeTable[CLASS_DEMOMAN][8].class = CLASS_DEMOMAN;
	g_attributeTable[CLASS_DEMOMAN][8].max = 5;
	g_attributeTable[CLASS_DEMOMAN][8].point = 2;
	g_attributeTable[CLASS_DEMOMAN][8].uid = "Blast radius increased";
	g_attributeTable[CLASS_DEMOMAN][8].value = float(10);
	g_attributeTable[CLASS_DEMOMAN][8].defaultValue = float(100);
	g_attributeTable[CLASS_DEMOMAN][8].additiveMode = ADDITIVE_PERCENT;	
	g_attributeTable[CLASS_DEMOMAN][8].title = "폭발반경 %.0f%% 증가 (%dpt)(%d/%d)";	
	
	g_attributeTable[CLASS_DEMOMAN][9].class = CLASS_DEMOMAN;
	g_attributeTable[CLASS_DEMOMAN][9].max = 5;
	g_attributeTable[CLASS_DEMOMAN][9].point = 2;
	g_attributeTable[CLASS_DEMOMAN][9].uid = "Projectile speed increased";
	g_attributeTable[CLASS_DEMOMAN][9].value = float(10);
	g_attributeTable[CLASS_DEMOMAN][9].defaultValue = float(100);
	g_attributeTable[CLASS_DEMOMAN][9].additiveMode = ADDITIVE_PERCENT;	
	g_attributeTable[CLASS_DEMOMAN][9].title = "투사체속도 %.0f%% 증가 (%dpt)(%d/%d)";	
	
	g_attributeTable[CLASS_DEMOMAN][10].class = CLASS_DEMOMAN;
	g_attributeTable[CLASS_DEMOMAN][10].max = 5;
	g_attributeTable[CLASS_DEMOMAN][10].point = 2;
	g_attributeTable[CLASS_DEMOMAN][10].uid = "rocket jump damage reduction";
	g_attributeTable[CLASS_DEMOMAN][10].value = float(10);
	g_attributeTable[CLASS_DEMOMAN][10].defaultValue = float(100);
	g_attributeTable[CLASS_DEMOMAN][10].additiveMode = MINUS_PERCENT;	
	g_attributeTable[CLASS_DEMOMAN][10].title = "폭발점프 피해 %.0f%% 감소 (%dpt)(%d/%d)";	
	
	g_attributeTable[CLASS_DEMOMAN][11].class = CLASS_DEMOMAN;
	g_attributeTable[CLASS_DEMOMAN][11].max = 3;
	g_attributeTable[CLASS_DEMOMAN][11].point = 2;
	g_attributeTable[CLASS_DEMOMAN][11].uid = "sticky arm time bonus";
	g_attributeTable[CLASS_DEMOMAN][11].value = float(33);
	g_attributeTable[CLASS_DEMOMAN][11].defaultValue = float(0);
	g_attributeTable[CLASS_DEMOMAN][11].additiveMode = MINUS_PERCENT;	
	g_attributeTable[CLASS_DEMOMAN][11].title = "폭탄 폭파 대기 시간 %.0f%% 감소 (%dpt)(%d/%d)";		
	
	g_attributeTable[CLASS_DEMOMAN][12].class = CLASS_DEMOMAN;
	g_attributeTable[CLASS_DEMOMAN][12].max = 3;
	g_attributeTable[CLASS_DEMOMAN][12].point = 3;
	g_attributeTable[CLASS_DEMOMAN][12].uid = "charge recharge rate increased";
	g_attributeTable[CLASS_DEMOMAN][12].value = float(15);
	g_attributeTable[CLASS_DEMOMAN][12].defaultValue = float(100);
	g_attributeTable[CLASS_DEMOMAN][12].additiveMode = ADDITIVE_PERCENT;	
	g_attributeTable[CLASS_DEMOMAN][12].title = "돌격 재충전 속도 %.0f%% 증가 (%dpt)(%d/%d)";			
	
	g_attributeTable[CLASS_DEMOMAN][13].class = CLASS_DEMOMAN;
	g_attributeTable[CLASS_DEMOMAN][13].max = 2;
	g_attributeTable[CLASS_DEMOMAN][13].point = 3;
	g_attributeTable[CLASS_DEMOMAN][13].uid = "melee range multiplier";
	g_attributeTable[CLASS_DEMOMAN][13].value = float(100);
	g_attributeTable[CLASS_DEMOMAN][13].defaultValue = float(100);
	g_attributeTable[CLASS_DEMOMAN][13].additiveMode = ADDITIVE_PERCENT;	
	g_attributeTable[CLASS_DEMOMAN][13].title = "근접 공격 범위 %.0f%%증가 (%dpt)(%d/%d)";	
	
	g_attributeTable[CLASS_DEMOMAN][14].class = CLASS_DEMOMAN;
	g_attributeTable[CLASS_DEMOMAN][14].max = 4;
	g_attributeTable[CLASS_DEMOMAN][14].point = 3;
	g_attributeTable[CLASS_DEMOMAN][14].uid = "clip size bonus";
	g_attributeTable[CLASS_DEMOMAN][14].value = float(25);
	g_attributeTable[CLASS_DEMOMAN][14].defaultValue = float(100);
	g_attributeTable[CLASS_DEMOMAN][14].additiveMode = ADDITIVE_PERCENT;	
	g_attributeTable[CLASS_DEMOMAN][14].title = "장탄수 %.0f%% 증가 (%dpt)(%d/%d)";		
	
	g_attributeTable[CLASS_DEMOMAN][15].class = CLASS_DEMOMAN;
	g_attributeTable[CLASS_DEMOMAN][15].max = 1;
	g_attributeTable[CLASS_DEMOMAN][15].point = 4;
	g_attributeTable[CLASS_DEMOMAN][15].uid = "grenade no bounce";
	g_attributeTable[CLASS_DEMOMAN][15].value = float(0);
	g_attributeTable[CLASS_DEMOMAN][15].defaultValue = float(100);
	g_attributeTable[CLASS_DEMOMAN][15].additiveMode = ADDITIVE_PERCENT;	
	g_attributeTable[CLASS_DEMOMAN][15].isDisableDrawValue = true;
	g_attributeTable[CLASS_DEMOMAN][15].title = "유탄이 적게 튀어오릅니다 (%dpt)(%d/%d)";		

	g_attributeTable[CLASS_HEAVY][0].class = CLASS_HEAVY;
	g_attributeTable[CLASS_HEAVY][0].max = 5;
	g_attributeTable[CLASS_HEAVY][0].point = 1;
	g_attributeTable[CLASS_HEAVY][0].uid = "move speed bonus";
	g_attributeTable[CLASS_HEAVY][0].value = float(5);
	g_attributeTable[CLASS_HEAVY][0].defaultValue = float(100);
	g_attributeTable[CLASS_HEAVY][0].additiveMode = ADDITIVE_PERCENT;	
	g_attributeTable[CLASS_HEAVY][0].title = "이동속도 %.0f%% 증가 (%dpt)(%d/%d)";
	
	g_attributeTable[CLASS_HEAVY][1].class = CLASS_HEAVY;
	g_attributeTable[CLASS_HEAVY][1].max = 10;
	g_attributeTable[CLASS_HEAVY][1].point = 1;
	g_attributeTable[CLASS_HEAVY][1].uid = "fire rate bonus";
	g_attributeTable[CLASS_HEAVY][1].value = float(5);
	g_attributeTable[CLASS_HEAVY][1].defaultValue = float(100);
	g_attributeTable[CLASS_HEAVY][1].additiveMode = MINUS_PERCENT;		
	g_attributeTable[CLASS_HEAVY][1].title = "공격속도 %.0f%% 증가 (%dpt)(%d/%d)";	
	
	g_attributeTable[CLASS_HEAVY][2].class = CLASS_HEAVY;
	g_attributeTable[CLASS_HEAVY][2].max = 3;
	g_attributeTable[CLASS_HEAVY][2].point = 1;
	g_attributeTable[CLASS_HEAVY][2].uid = "deploy time decreased";
	g_attributeTable[CLASS_HEAVY][2].value = float(15);
	g_attributeTable[CLASS_HEAVY][2].defaultValue = float(100);
	g_attributeTable[CLASS_HEAVY][2].additiveMode = MINUS_PERCENT;		
	g_attributeTable[CLASS_HEAVY][2].title = "무기전환속도 %.0f%% 증가 (%dpt)(%d/%d)";	

	g_attributeTable[CLASS_HEAVY][3].class = CLASS_HEAVY;
	g_attributeTable[CLASS_HEAVY][3].max = 0;
	g_attributeTable[CLASS_HEAVY][3].point = 1;
	g_attributeTable[CLASS_HEAVY][3].uid = "";
	g_attributeTable[CLASS_HEAVY][3].value = float(2);
	g_attributeTable[CLASS_HEAVY][3].defaultValue = float(0);
	g_attributeTable[CLASS_HEAVY][3].additiveMode = ADDITIVE_NUMBER;		
	g_attributeTable[CLASS_HEAVY][3].title = "적중시 체력 %.0f 회복 (%dpt)(%d/%d)";

	g_attributeTable[CLASS_HEAVY][4].class = CLASS_HEAVY;
	g_attributeTable[CLASS_HEAVY][4].max = 5;
	g_attributeTable[CLASS_HEAVY][4].point = 1;
	g_attributeTable[CLASS_HEAVY][4].uid = "effect bar recharge rate increased";
	g_attributeTable[CLASS_HEAVY][4].value = float(10);
	g_attributeTable[CLASS_HEAVY][4].defaultValue = float(100);
	g_attributeTable[CLASS_HEAVY][4].additiveMode = MINUS_PERCENT;		
	g_attributeTable[CLASS_HEAVY][4].title = "재충전속도 %.0f%% 증가 (%dpt)(%d/%d)";	

	g_attributeTable[CLASS_HEAVY][5].class = CLASS_HEAVY;
	g_attributeTable[CLASS_HEAVY][5].max = 0;
	g_attributeTable[CLASS_HEAVY][5].point = 2;
	g_attributeTable[CLASS_HEAVY][5].uid = "";
	g_attributeTable[CLASS_HEAVY][5].value = float(1);
	g_attributeTable[CLASS_HEAVY][5].defaultValue = float(100);
	g_attributeTable[CLASS_HEAVY][5].additiveMode = ADDITIVE_PERCENT;		
	g_attributeTable[CLASS_HEAVY][5].title = "피해량 %.0f%% 증가 (%dpt)(%d/%d)";
	
	g_attributeTable[CLASS_HEAVY][6].class = CLASS_HEAVY;
	g_attributeTable[CLASS_HEAVY][6].max = 2;
	g_attributeTable[CLASS_HEAVY][6].point = 2;
	g_attributeTable[CLASS_HEAVY][6].uid = "aiming movespeed increased";
	g_attributeTable[CLASS_HEAVY][6].value = float(25);
	g_attributeTable[CLASS_HEAVY][6].defaultValue = float(100);
	g_attributeTable[CLASS_HEAVY][6].additiveMode = ADDITIVE_PERCENT;		
	g_attributeTable[CLASS_HEAVY][6].title = "총열 회전시 이동속도 %.0f%% 증가 (%dpt)(%d/%d)";	

	g_attributeTable[CLASS_HEAVY][7].class = CLASS_HEAVY;
	g_attributeTable[CLASS_HEAVY][7].max = 4;
	g_attributeTable[CLASS_HEAVY][7].point = 2;
	g_attributeTable[CLASS_HEAVY][7].uid = "minigun spinup time decreased";
	g_attributeTable[CLASS_HEAVY][7].value = float(10);
	g_attributeTable[CLASS_HEAVY][7].defaultValue = float(100);
	g_attributeTable[CLASS_HEAVY][7].additiveMode = MINUS_PERCENT;		
	g_attributeTable[CLASS_HEAVY][7].title = "빠른 사격 준비 속도 %.0f%% 증가 (%dpt)(%d/%d)";

	g_attributeTable[CLASS_HEAVY][8].class = CLASS_HEAVY;
	g_attributeTable[CLASS_HEAVY][8].max = 6;
	g_attributeTable[CLASS_HEAVY][8].point = 2;
	g_attributeTable[CLASS_HEAVY][8].uid = "max health additive bonus";
	g_attributeTable[CLASS_HEAVY][8].value = float(25);
	g_attributeTable[CLASS_HEAVY][8].defaultValue = float(0);
	g_attributeTable[CLASS_HEAVY][8].additiveMode = ADDITIVE_NUMBER;		
	g_attributeTable[CLASS_HEAVY][8].title = "최대체력 %.0f 증가 (%dpt)(%d/%d)";

	g_attributeTable[CLASS_HEAVY][9].class = CLASS_HEAVY;
	g_attributeTable[CLASS_HEAVY][9].max = 1;
	g_attributeTable[CLASS_HEAVY][9].point = 3;
	g_attributeTable[CLASS_HEAVY][9].uid = "attack projectiles";
	g_attributeTable[CLASS_HEAVY][9].value = float(1);
	g_attributeTable[CLASS_HEAVY][9].defaultValue = float(0);
	g_attributeTable[CLASS_HEAVY][9].additiveMode = ADDITIVE_NUMBER;		
	g_attributeTable[CLASS_HEAVY][9].isDisableDrawValue = true;
	g_attributeTable[CLASS_HEAVY][9].title = "투사체 파괴 (%dpt)(%d/%d)";

	g_attributeTable[CLASS_HEAVY][10].class = CLASS_HEAVY;
	g_attributeTable[CLASS_HEAVY][10].max = 1;
	g_attributeTable[CLASS_HEAVY][10].point = 3;
	g_attributeTable[CLASS_HEAVY][10].uid = "ring of fire while aiming";
	g_attributeTable[CLASS_HEAVY][10].value = float(50);
	g_attributeTable[CLASS_HEAVY][10].defaultValue = float(0);
	g_attributeTable[CLASS_HEAVY][10].additiveMode = ADDITIVE_NUMBER;		
	g_attributeTable[CLASS_HEAVY][10].title = "총열 회전시 피해 %.0f의 불의고리 생성 (%dpt)(%d/%d)";

	g_attributeTable[CLASS_HEAVY][11].class = CLASS_HEAVY;
	g_attributeTable[CLASS_HEAVY][11].max = 2;
	g_attributeTable[CLASS_HEAVY][11].point = 3;
	g_attributeTable[CLASS_HEAVY][11].uid = "weapon spread bonus";
	g_attributeTable[CLASS_HEAVY][11].value = float(25);
	g_attributeTable[CLASS_HEAVY][11].defaultValue = float(100);
	g_attributeTable[CLASS_HEAVY][11].additiveMode = MINUS_PERCENT;		
	g_attributeTable[CLASS_HEAVY][11].title = "집탄률 %.0f%% 증가 (%dpt)(%d/%d)";

	g_attributeTable[CLASS_HEAVY][12].class = CLASS_HEAVY;
	g_attributeTable[CLASS_HEAVY][12].max = 2;
	g_attributeTable[CLASS_HEAVY][12].point = 4;
	g_attributeTable[CLASS_HEAVY][12].uid = "bullets per shot bonus";
	g_attributeTable[CLASS_HEAVY][12].value = float(25);
	g_attributeTable[CLASS_HEAVY][12].defaultValue = float(100);
	g_attributeTable[CLASS_HEAVY][12].additiveMode = ADDITIVE_PERCENT;		
	g_attributeTable[CLASS_HEAVY][12].title = "발사되는 탄환수 %.0f%% 증가 (%dpt)(%d/%d)";

	g_attributeTable[CLASS_HEAVY][13].class = CLASS_HEAVY;
	g_attributeTable[CLASS_HEAVY][13].max = 1;
	g_attributeTable[CLASS_HEAVY][13].point = 5;
	g_attributeTable[CLASS_HEAVY][13].uid = "crit from behind";
	g_attributeTable[CLASS_HEAVY][13].value = float(1);
	g_attributeTable[CLASS_HEAVY][13].defaultValue = float(0);
	g_attributeTable[CLASS_HEAVY][13].additiveMode = ADDITIVE_NUMBER;		
	g_attributeTable[CLASS_HEAVY][13].isDisableDrawValue = true;
	g_attributeTable[CLASS_HEAVY][13].title = "뒤에서 공격하면 항상 치명타가 들어갑니다 (%dpt)(%d/%d)";
	
	g_attributeTable[CLASS_ENGINEER][0].class = CLASS_ENGINEER;
	g_attributeTable[CLASS_ENGINEER][0].max = 5;
	g_attributeTable[CLASS_ENGINEER][0].point = 1;
	g_attributeTable[CLASS_ENGINEER][0].uid = "move speed bonus";
	g_attributeTable[CLASS_ENGINEER][0].value = float(3);
	g_attributeTable[CLASS_ENGINEER][0].defaultValue = float(100);
	g_attributeTable[CLASS_ENGINEER][0].additiveMode = ADDITIVE_PERCENT;	
	g_attributeTable[CLASS_ENGINEER][0].title = "이동속도 %.0f%% 증가 (%dpt)(%d/%d)";
	
	g_attributeTable[CLASS_ENGINEER][1].class = CLASS_ENGINEER;
	g_attributeTable[CLASS_ENGINEER][1].max = 10;
	g_attributeTable[CLASS_ENGINEER][1].point = 1;
	g_attributeTable[CLASS_ENGINEER][1].uid = "fire rate bonus";
	g_attributeTable[CLASS_ENGINEER][1].value = float(5);
	g_attributeTable[CLASS_ENGINEER][1].defaultValue = float(100);
	g_attributeTable[CLASS_ENGINEER][1].additiveMode = MINUS_PERCENT;		
	g_attributeTable[CLASS_ENGINEER][1].title = "공격속도 %.0f%% 증가 (%dpt)(%d/%d)";	
	
	g_attributeTable[CLASS_ENGINEER][2].class = CLASS_ENGINEER;
	g_attributeTable[CLASS_ENGINEER][2].max = 10;
	g_attributeTable[CLASS_ENGINEER][2].point = 1;
	g_attributeTable[CLASS_ENGINEER][2].uid = "Reload time decreased";
	g_attributeTable[CLASS_ENGINEER][2].value = float(5);
	g_attributeTable[CLASS_ENGINEER][2].defaultValue = float(100);
	g_attributeTable[CLASS_ENGINEER][2].additiveMode = MINUS_PERCENT;		
	g_attributeTable[CLASS_ENGINEER][2].title = "재장전속도 %.0f%% 증가 (%dpt)(%d/%d)";
	
	g_attributeTable[CLASS_ENGINEER][3].class = CLASS_ENGINEER;
	g_attributeTable[CLASS_ENGINEER][3].max = 3;
	g_attributeTable[CLASS_ENGINEER][3].point = 1;
	g_attributeTable[CLASS_ENGINEER][3].uid = "deploy time decreased";
	g_attributeTable[CLASS_ENGINEER][3].value = float(15);
	g_attributeTable[CLASS_ENGINEER][3].defaultValue = float(100);
	g_attributeTable[CLASS_ENGINEER][3].additiveMode = MINUS_PERCENT;		
	g_attributeTable[CLASS_ENGINEER][3].title = "무기전환속도 %.0f%% 증가 (%dpt)(%d/%d)";	
	
	g_attributeTable[CLASS_ENGINEER][4].class = CLASS_ENGINEER;
	g_attributeTable[CLASS_ENGINEER][4].max = 0;
	g_attributeTable[CLASS_ENGINEER][4].point = 1;
	g_attributeTable[CLASS_ENGINEER][4].uid = "";
	g_attributeTable[CLASS_ENGINEER][4].value = float(5);
	g_attributeTable[CLASS_ENGINEER][4].defaultValue = float(0);
	g_attributeTable[CLASS_ENGINEER][4].additiveMode = ADDITIVE_NUMBER;		
	g_attributeTable[CLASS_ENGINEER][4].title = "적중시 체력 %.0f 회복 (%dpt)(%d/%d)";	
	
	g_attributeTable[CLASS_ENGINEER][5].class = CLASS_ENGINEER;
	g_attributeTable[CLASS_ENGINEER][5].max = 4;
	g_attributeTable[CLASS_ENGINEER][5].point = 1;
	g_attributeTable[CLASS_ENGINEER][5].uid = "engy dispenser radius increased";
	g_attributeTable[CLASS_ENGINEER][5].value = float(200);
	g_attributeTable[CLASS_ENGINEER][5].defaultValue = float(100);
	g_attributeTable[CLASS_ENGINEER][5].additiveMode = ADDITIVE_PERCENT;		
	g_attributeTable[CLASS_ENGINEER][5].title = "디스펜서 범위 %.0f%% 증가 (%dpt)(%d/%d)";

	g_attributeTable[CLASS_ENGINEER][6].class = CLASS_ENGINEER;
	g_attributeTable[CLASS_ENGINEER][6].max = 0;
	g_attributeTable[CLASS_ENGINEER][6].point = 1;
	g_attributeTable[CLASS_ENGINEER][6].uid = "";
	g_attributeTable[CLASS_ENGINEER][6].value = float(25);
	g_attributeTable[CLASS_ENGINEER][6].defaultValue = float(100);
	g_attributeTable[CLASS_ENGINEER][6].additiveMode = MINUS_PERCENT;		
	g_attributeTable[CLASS_ENGINEER][6].title = "집탄률 %.0f%% 증가 (%dpt)(%d/%d)";	
	
	g_attributeTable[CLASS_ENGINEER][7].class = CLASS_ENGINEER;
	g_attributeTable[CLASS_ENGINEER][7].max = 0;
	g_attributeTable[CLASS_ENGINEER][7].point = 2;
	g_attributeTable[CLASS_ENGINEER][7].uid = "";
	g_attributeTable[CLASS_ENGINEER][7].value = float(1);
	g_attributeTable[CLASS_ENGINEER][7].defaultValue = float(100);
	g_attributeTable[CLASS_ENGINEER][7].additiveMode = ADDITIVE_PERCENT;		
	g_attributeTable[CLASS_ENGINEER][7].title = "피해량 %.0f%% 증가 (%dpt)(%d/%d)";

	g_attributeTable[CLASS_ENGINEER][8].class = CLASS_ENGINEER;
	g_attributeTable[CLASS_ENGINEER][8].max = 4;
	g_attributeTable[CLASS_ENGINEER][8].point = 2;
	g_attributeTable[CLASS_ENGINEER][8].uid = "maxammo metal increased";
	g_attributeTable[CLASS_ENGINEER][8].value = float(50);
	g_attributeTable[CLASS_ENGINEER][8].defaultValue = float(100);
	g_attributeTable[CLASS_ENGINEER][8].additiveMode = ADDITIVE_PERCENT;		
	g_attributeTable[CLASS_ENGINEER][8].title = "최대금속 보유량 %.0f%% 증가 (%dpt)(%d/%d)";

	g_attributeTable[CLASS_ENGINEER][9].class = CLASS_ENGINEER;
	g_attributeTable[CLASS_ENGINEER][9].max = 5;
	g_attributeTable[CLASS_ENGINEER][9].point = 2;
	g_attributeTable[CLASS_ENGINEER][9].uid = "build rate bonus";
	g_attributeTable[CLASS_ENGINEER][9].value = float(10);
	g_attributeTable[CLASS_ENGINEER][9].defaultValue = float(100);
	g_attributeTable[CLASS_ENGINEER][9].additiveMode = MINUS_PERCENT;		
	g_attributeTable[CLASS_ENGINEER][9].title = "건설속도 %.0f%% 증가 (%dpt)(%d/%d)";	
	
	g_attributeTable[CLASS_ENGINEER][10].class = CLASS_ENGINEER;
	g_attributeTable[CLASS_ENGINEER][10].max = 0;
	g_attributeTable[CLASS_ENGINEER][10].point = 2;
	g_attributeTable[CLASS_ENGINEER][10].uid = "";
	g_attributeTable[CLASS_ENGINEER][10].value = float(10);
	g_attributeTable[CLASS_ENGINEER][10].defaultValue = float(0);
	g_attributeTable[CLASS_ENGINEER][10].additiveMode = ADDITIVE_NUMBER;		
	g_attributeTable[CLASS_ENGINEER][10].title = "최대체력 %.0f 증가 (%dpt)(%d/%d)";		

	g_attributeTable[CLASS_ENGINEER][11].class = CLASS_ENGINEER;
	g_attributeTable[CLASS_ENGINEER][11].max = 5;
	g_attributeTable[CLASS_ENGINEER][11].point = 2;
	g_attributeTable[CLASS_ENGINEER][11].uid = "metal regen";
	g_attributeTable[CLASS_ENGINEER][11].value = float(10);
	g_attributeTable[CLASS_ENGINEER][11].defaultValue = float(0);
	g_attributeTable[CLASS_ENGINEER][11].additiveMode = ADDITIVE_NUMBER;		
	g_attributeTable[CLASS_ENGINEER][11].title = "금속 5초마다 %.0f 생성 (%dpt)(%d/%d)";
	
	g_attributeTable[CLASS_ENGINEER][12].class = CLASS_ENGINEER;
	g_attributeTable[CLASS_ENGINEER][12].max = 4;
	g_attributeTable[CLASS_ENGINEER][12].point = 3;
	g_attributeTable[CLASS_ENGINEER][12].uid = "engy sentry radius increased";
	g_attributeTable[CLASS_ENGINEER][12].value = float(10);
	g_attributeTable[CLASS_ENGINEER][12].defaultValue = float(100);
	g_attributeTable[CLASS_ENGINEER][12].additiveMode = ADDITIVE_PERCENT;		
	g_attributeTable[CLASS_ENGINEER][12].title = "센트리 사정거리 %.0f%% 증가 (%dpt)(%d/%d)";	

	g_attributeTable[CLASS_ENGINEER][13].class = CLASS_ENGINEER;
	g_attributeTable[CLASS_ENGINEER][13].max = 4;
	g_attributeTable[CLASS_ENGINEER][13].point = 3;
	g_attributeTable[CLASS_ENGINEER][13].uid = "engy sentry fire rate increased";
	g_attributeTable[CLASS_ENGINEER][13].value = float(10);
	g_attributeTable[CLASS_ENGINEER][13].defaultValue = float(100);
	g_attributeTable[CLASS_ENGINEER][13].additiveMode = MINUS_PERCENT;		
	g_attributeTable[CLASS_ENGINEER][13].title = "센트리 발사속도 %.0f%% 증가 (%dpt)(%d/%d)";

	g_attributeTable[CLASS_ENGINEER][14].class = CLASS_ENGINEER;
	g_attributeTable[CLASS_ENGINEER][14].max = 4;
	g_attributeTable[CLASS_ENGINEER][14].point = 3;
	g_attributeTable[CLASS_ENGINEER][14].uid = "engy building health bonus";
	g_attributeTable[CLASS_ENGINEER][14].value = float(25);
	g_attributeTable[CLASS_ENGINEER][14].defaultValue = float(100);
	g_attributeTable[CLASS_ENGINEER][14].additiveMode = ADDITIVE_PERCENT;		
	g_attributeTable[CLASS_ENGINEER][14].title = "구조물 내구도 %.0f%% 증가 (%dpt)(%d/%d)";
	
	g_attributeTable[CLASS_ENGINEER][15].class = CLASS_ENGINEER;
	g_attributeTable[CLASS_ENGINEER][15].max = 4;
	g_attributeTable[CLASS_ENGINEER][15].point = 3;
	g_attributeTable[CLASS_ENGINEER][15].uid = "clip size bonus";
	g_attributeTable[CLASS_ENGINEER][15].value = float(25);
	g_attributeTable[CLASS_ENGINEER][15].defaultValue = float(100);
	g_attributeTable[CLASS_ENGINEER][15].additiveMode = ADDITIVE_PERCENT;		
	g_attributeTable[CLASS_ENGINEER][15].title = "장탄수 %.0f%% 증가 (%dpt)(%d/%d)";

	g_attributeTable[CLASS_ENGINEER][16].class = CLASS_ENGINEER;
	g_attributeTable[CLASS_ENGINEER][16].max = 1;
	g_attributeTable[CLASS_ENGINEER][16].point = 4;
	g_attributeTable[CLASS_ENGINEER][16].uid = "bidirectional teleport";
	g_attributeTable[CLASS_ENGINEER][16].value = float(1);
	g_attributeTable[CLASS_ENGINEER][16].defaultValue = float(0);
	g_attributeTable[CLASS_ENGINEER][16].additiveMode = ADDITIVE_NUMBER;		
	g_attributeTable[CLASS_ENGINEER][16].isDisableDrawValue = true;
	g_attributeTable[CLASS_ENGINEER][16].title = "양방향 텔레포트 활성화 (%dpt)(%d/%d)";	
	
	g_attributeTable[CLASS_MEDIC][0].class = CLASS_MEDIC;
	g_attributeTable[CLASS_MEDIC][0].max = 5;
	g_attributeTable[CLASS_MEDIC][0].point = 1;
	g_attributeTable[CLASS_MEDIC][0].uid = "move speed bonus";
	g_attributeTable[CLASS_MEDIC][0].value = float(3);
	g_attributeTable[CLASS_MEDIC][0].defaultValue = float(100);
	g_attributeTable[CLASS_MEDIC][0].additiveMode = ADDITIVE_PERCENT;	
	g_attributeTable[CLASS_MEDIC][0].title = "이동속도 %.0f%% 증가 (%dpt)(%d/%d)";

	g_attributeTable[CLASS_MEDIC][1].class = CLASS_MEDIC;
	g_attributeTable[CLASS_MEDIC][1].max = 10;
	g_attributeTable[CLASS_MEDIC][1].point = 1;
	g_attributeTable[CLASS_MEDIC][1].uid = "fire rate bonus";
	g_attributeTable[CLASS_MEDIC][1].value = float(5);
	g_attributeTable[CLASS_MEDIC][1].defaultValue = float(100);
	g_attributeTable[CLASS_MEDIC][1].additiveMode = MINUS_PERCENT;		
	g_attributeTable[CLASS_MEDIC][1].title = "공격속도 %.0f%% 증가 (%dpt)(%d/%d)";	
	
	g_attributeTable[CLASS_MEDIC][1].class = CLASS_MEDIC;
	g_attributeTable[CLASS_MEDIC][1].max = 10;
	g_attributeTable[CLASS_MEDIC][1].point = 1;
	g_attributeTable[CLASS_MEDIC][1].uid = "Reload time decreased";
	g_attributeTable[CLASS_MEDIC][1].value = float(5);
	g_attributeTable[CLASS_MEDIC][1].defaultValue = float(100);
	g_attributeTable[CLASS_MEDIC][1].additiveMode = MINUS_PERCENT;		
	g_attributeTable[CLASS_MEDIC][1].title = "재장전속도 %.0f%% 증가 (%dpt)(%d/%d)";	
	
	g_attributeTable[CLASS_MEDIC][2].class = CLASS_MEDIC;
	g_attributeTable[CLASS_MEDIC][2].max = 3;
	g_attributeTable[CLASS_MEDIC][2].point = 1;
	g_attributeTable[CLASS_MEDIC][2].uid = "deploy time decreased";
	g_attributeTable[CLASS_MEDIC][2].value = float(15);
	g_attributeTable[CLASS_MEDIC][2].defaultValue = float(100);
	g_attributeTable[CLASS_MEDIC][2].additiveMode = MINUS_PERCENT;	
	g_attributeTable[CLASS_MEDIC][2].title = "무기전환속도 %.0f%% 증가 (%dpt)(%d/%d)";		

	g_attributeTable[CLASS_MEDIC][3].class = CLASS_MEDIC;
	g_attributeTable[CLASS_MEDIC][3].max = 0;
	g_attributeTable[CLASS_MEDIC][3].point = 1;
	g_attributeTable[CLASS_MEDIC][3].uid = "";
	g_attributeTable[CLASS_MEDIC][3].value = float(2);
	g_attributeTable[CLASS_MEDIC][3].defaultValue = float(0);
	g_attributeTable[CLASS_MEDIC][3].additiveMode = ADDITIVE_NUMBER;	
	g_attributeTable[CLASS_MEDIC][3].title = "적중시 체력 %.0f 회복 (%dpt)(%d/%d)";		

	g_attributeTable[CLASS_MEDIC][4].class = CLASS_MEDIC;
	g_attributeTable[CLASS_MEDIC][4].max = 0;
	g_attributeTable[CLASS_MEDIC][4].point = 2;
	g_attributeTable[CLASS_MEDIC][4].uid = "";
	g_attributeTable[CLASS_MEDIC][4].value = float(1);
	g_attributeTable[CLASS_MEDIC][4].defaultValue = float(100);
	g_attributeTable[CLASS_MEDIC][4].additiveMode = ADDITIVE_PERCENT;	
	g_attributeTable[CLASS_MEDIC][4].title = "피해량 %.0f%% 증가 (%dpt)(%d/%d)";		
	
	g_attributeTable[CLASS_MEDIC][5].class = CLASS_MEDIC;
	g_attributeTable[CLASS_MEDIC][5].max = 5;
	g_attributeTable[CLASS_MEDIC][5].point = 2;
	g_attributeTable[CLASS_MEDIC][5].uid = "max health additive bonus";
	g_attributeTable[CLASS_MEDIC][5].value = float(10);
	g_attributeTable[CLASS_MEDIC][5].defaultValue = float(0);
	g_attributeTable[CLASS_MEDIC][5].additiveMode = ADDITIVE_NUMBER;		
	g_attributeTable[CLASS_MEDIC][5].title = "최대체력 %.0f 증가 (%dpt)(%d/%d)";	

	g_attributeTable[CLASS_MEDIC][6].class = CLASS_MEDIC;
	g_attributeTable[CLASS_MEDIC][6].max = 5;
	g_attributeTable[CLASS_MEDIC][6].point = 2;
	g_attributeTable[CLASS_MEDIC][6].uid = "heal rate bonus";
	g_attributeTable[CLASS_MEDIC][6].value = float(10);
	g_attributeTable[CLASS_MEDIC][6].defaultValue = float(100);
	g_attributeTable[CLASS_MEDIC][6].additiveMode = ADDITIVE_PERCENT;	
	g_attributeTable[CLASS_MEDIC][6].title = "치료율 %.0f%% 증가 (%dpt)(%d/%d)";		

	g_attributeTable[CLASS_MEDIC][7].class = CLASS_MEDIC;
	g_attributeTable[CLASS_MEDIC][7].max = 5;
	g_attributeTable[CLASS_MEDIC][7].point = 3;
	g_attributeTable[CLASS_MEDIC][7].uid = "ubercharge rate bonus";
	g_attributeTable[CLASS_MEDIC][7].value = float(5);
	g_attributeTable[CLASS_MEDIC][7].defaultValue = float(100);
	g_attributeTable[CLASS_MEDIC][7].additiveMode = ADDITIVE_PERCENT;		
	g_attributeTable[CLASS_MEDIC][7].title = "우버 충전율 %.0f%% 증가 (%dpt)(%d/%d)";	

	g_attributeTable[CLASS_MEDIC][8].class = CLASS_MEDIC;
	g_attributeTable[CLASS_MEDIC][8].max = 5;
	g_attributeTable[CLASS_MEDIC][8].point = 3;
	g_attributeTable[CLASS_MEDIC][8].uid = "add uber charge on hit";
	g_attributeTable[CLASS_MEDIC][8].value = float(1);
	g_attributeTable[CLASS_MEDIC][8].defaultValue = float(0);
	g_attributeTable[CLASS_MEDIC][8].additiveMode = ADDITIVE_PERCENT;		
	g_attributeTable[CLASS_MEDIC][8].title = "적중시 우버차지 %.0f%% 추가 (%dpt)(%d/%d)";	

	g_attributeTable[CLASS_MEDIC][9].class = CLASS_MEDIC;
	g_attributeTable[CLASS_MEDIC][9].max = 5;
	g_attributeTable[CLASS_MEDIC][9].point = 3;
	g_attributeTable[CLASS_MEDIC][9].uid = "uber duration bonus";
	g_attributeTable[CLASS_MEDIC][9].value = float(1);
	g_attributeTable[CLASS_MEDIC][9].defaultValue = float(0);
	g_attributeTable[CLASS_MEDIC][9].additiveMode = ADDITIVE_NUMBER;		
	g_attributeTable[CLASS_MEDIC][9].title = "우버차지 지속시간 %.0f초증가 (%dpt)(%d/%d)";	

	g_attributeTable[CLASS_MEDIC][10].class = CLASS_MEDIC;
	g_attributeTable[CLASS_MEDIC][10].max = 4;
	g_attributeTable[CLASS_MEDIC][10].point = 3;
	g_attributeTable[CLASS_MEDIC][10].uid = "clip size bonus";
	g_attributeTable[CLASS_MEDIC][10].value = float(100);
	g_attributeTable[CLASS_MEDIC][10].defaultValue = float(100);
	g_attributeTable[CLASS_MEDIC][10].additiveMode = ADDITIVE_PERCENT;		
	g_attributeTable[CLASS_MEDIC][10].title = "장탄수 %.2f%% 증가 (%dpt)(%d/%d)";	

	g_attributeTable[CLASS_MEDIC][11].class = CLASS_MEDIC;
	g_attributeTable[CLASS_MEDIC][11].max = 4;
	g_attributeTable[CLASS_MEDIC][11].point = 3;
	g_attributeTable[CLASS_MEDIC][11].uid = "overheal bonus";
	g_attributeTable[CLASS_MEDIC][11].value = float(25);
	g_attributeTable[CLASS_MEDIC][11].defaultValue = float(100);
	g_attributeTable[CLASS_MEDIC][11].additiveMode = ADDITIVE_PERCENT;		
	g_attributeTable[CLASS_MEDIC][11].title = "과치료 %.0f%% 증가 (%dpt)(%d/%d)";	

	g_attributeTable[CLASS_MEDIC][12].class = CLASS_MEDIC;
	g_attributeTable[CLASS_MEDIC][12].max = 1;
	g_attributeTable[CLASS_MEDIC][12].point = 5;
	g_attributeTable[CLASS_MEDIC][12].uid = "generate rage on heal";
	g_attributeTable[CLASS_MEDIC][12].value = float(100);
	g_attributeTable[CLASS_MEDIC][12].defaultValue = float(0);
	g_attributeTable[CLASS_MEDIC][12].additiveMode = ADDITIVE_PERCENT;		
	g_attributeTable[CLASS_MEDIC][12].isDisableDrawValue = true;
	g_attributeTable[CLASS_MEDIC][12].title = "투사체 보호막생성 (%dpt)(%d/%d)";		

	g_attributeTable[CLASS_MEDIC][13].class = CLASS_MEDIC;
	g_attributeTable[CLASS_MEDIC][13].max = 1;
	g_attributeTable[CLASS_MEDIC][13].point = 5;
	g_attributeTable[CLASS_MEDIC][13].uid = "overheal decay disabled";
	g_attributeTable[CLASS_MEDIC][13].value = float(10000);
	g_attributeTable[CLASS_MEDIC][13].defaultValue = float(0);
	g_attributeTable[CLASS_MEDIC][13].additiveMode = ADDITIVE_PERCENT;		
	g_attributeTable[CLASS_MEDIC][13].isDisableDrawValue = true;
	g_attributeTable[CLASS_MEDIC][13].title = "과치료 체력이 소멸되지 않습니다 (%dpt)(%d/%d)";	
	
	g_attributeTable[CLASS_SNIPER][0].class = CLASS_SNIPER;
	g_attributeTable[CLASS_SNIPER][0].max = 5;
	g_attributeTable[CLASS_SNIPER][0].point = 1;
	g_attributeTable[CLASS_SNIPER][0].uid = "move speed bonus";
	g_attributeTable[CLASS_SNIPER][0].value = float(3);
	g_attributeTable[CLASS_SNIPER][0].defaultValue = float(100);
	g_attributeTable[CLASS_SNIPER][0].additiveMode = ADDITIVE_PERCENT;		
	g_attributeTable[CLASS_SNIPER][0].title = "이동속도 %.0f%% 증가 (%dpt)(%d/%d)";		

	g_attributeTable[CLASS_SNIPER][1].class = CLASS_SNIPER;
	g_attributeTable[CLASS_SNIPER][1].max = 10;
	g_attributeTable[CLASS_SNIPER][1].point = 1;
	g_attributeTable[CLASS_SNIPER][1].uid = "fire rate bonus";
	g_attributeTable[CLASS_SNIPER][1].value = float(5);
	g_attributeTable[CLASS_SNIPER][1].defaultValue = float(100);
	g_attributeTable[CLASS_SNIPER][1].additiveMode = MINUS_PERCENT;	
	g_attributeTable[CLASS_SNIPER][1].title = "공격속도 %.0f%% 증가 (%dpt)(%d/%d)";	

	g_attributeTable[CLASS_SNIPER][2].class = CLASS_SNIPER;
	g_attributeTable[CLASS_SNIPER][2].max = 10;
	g_attributeTable[CLASS_SNIPER][2].point = 1;
	g_attributeTable[CLASS_SNIPER][2].uid = "Reload time decreased";
	g_attributeTable[CLASS_SNIPER][2].value = float(5);
	g_attributeTable[CLASS_SNIPER][2].defaultValue = float(100);
	g_attributeTable[CLASS_SNIPER][2].additiveMode = ADDITIVE_PERCENT;	
	g_attributeTable[CLASS_SNIPER][2].title = "재장전속도 %.0f%% 증가 (%dpt)(%d/%d)";	

	g_attributeTable[CLASS_SNIPER][3].class = CLASS_SNIPER;
	g_attributeTable[CLASS_SNIPER][3].max = 3;
	g_attributeTable[CLASS_SNIPER][3].point = 1;
	g_attributeTable[CLASS_SNIPER][3].uid = "deploy time decreased";
	g_attributeTable[CLASS_SNIPER][3].value = float(15);
	g_attributeTable[CLASS_SNIPER][3].defaultValue = float(100);
	g_attributeTable[CLASS_SNIPER][3].additiveMode = MINUS_PERCENT;	
	g_attributeTable[CLASS_SNIPER][3].title = "무기전환속도 %.0f%% 증가 (%dpt)(%d/%d)";	

	g_attributeTable[CLASS_SNIPER][4].class = CLASS_SNIPER;
	g_attributeTable[CLASS_SNIPER][4].max = 0;
	g_attributeTable[CLASS_SNIPER][4].point = 1;
	g_attributeTable[CLASS_SNIPER][4].uid = "";
	g_attributeTable[CLASS_SNIPER][4].value = float(5);
	g_attributeTable[CLASS_SNIPER][4].defaultValue = float(0);
	g_attributeTable[CLASS_SNIPER][4].additiveMode = ADDITIVE_NUMBER;	
	g_attributeTable[CLASS_SNIPER][4].title = "적중시 체력 %.0f 회복 (%dpt)(%d/%d)";		

	g_attributeTable[CLASS_SNIPER][5].class = CLASS_SNIPER;
	g_attributeTable[CLASS_SNIPER][5].max = 2;
	g_attributeTable[CLASS_SNIPER][5].point = 1;
	g_attributeTable[CLASS_SNIPER][5].uid = "weapon spread bonus";
	g_attributeTable[CLASS_SNIPER][5].value = float(25);
	g_attributeTable[CLASS_SNIPER][5].defaultValue = float(100);
	g_attributeTable[CLASS_SNIPER][5].additiveMode = MINUS_PERCENT;	
	g_attributeTable[CLASS_SNIPER][5].title = "집탄률 %.0f%% 증가 (%dpt)(%d/%d)";	

	g_attributeTable[CLASS_SNIPER][6].class = CLASS_SNIPER;
	g_attributeTable[CLASS_SNIPER][6].max = 2;
	g_attributeTable[CLASS_SNIPER][6].point = 1;
	g_attributeTable[CLASS_SNIPER][6].uid = "effect bar recharge rate increased";
	g_attributeTable[CLASS_SNIPER][6].value = float(25);
	g_attributeTable[CLASS_SNIPER][6].defaultValue = float(100);
	g_attributeTable[CLASS_SNIPER][6].additiveMode = MINUS_PERCENT;	
	g_attributeTable[CLASS_SNIPER][6].title = "재충전속도 %.0f%% 증가 (%dpt)(%d/%d)";		

	g_attributeTable[CLASS_SNIPER][7].class = CLASS_SNIPER;
	g_attributeTable[CLASS_SNIPER][7].max = 0;
	g_attributeTable[CLASS_SNIPER][7].point = 2;
	g_attributeTable[CLASS_SNIPER][7].uid = "";
	g_attributeTable[CLASS_SNIPER][7].value = float(1);
	g_attributeTable[CLASS_SNIPER][7].defaultValue = float(100);
	g_attributeTable[CLASS_SNIPER][7].additiveMode = ADDITIVE_PERCENT;	
	g_attributeTable[CLASS_SNIPER][7].title = "피해량 %.0f%% 증가 (%dpt)(%d/%d)";		

	g_attributeTable[CLASS_SNIPER][8].class = CLASS_SNIPER;
	g_attributeTable[CLASS_SNIPER][8].max = 5;
	g_attributeTable[CLASS_SNIPER][8].point = 2;
	g_attributeTable[CLASS_SNIPER][8].uid = "max health additive bonus";
	g_attributeTable[CLASS_SNIPER][8].value = float(10);
	g_attributeTable[CLASS_SNIPER][8].defaultValue = float(0);
	g_attributeTable[CLASS_SNIPER][8].additiveMode = ADDITIVE_NUMBER;	
	g_attributeTable[CLASS_SNIPER][8].title = "최대체력 %.0f 증가 (%dpt)(%d/%d)";	

	g_attributeTable[CLASS_SNIPER][9].class = CLASS_SNIPER;
	g_attributeTable[CLASS_SNIPER][9].max = 5;
	g_attributeTable[CLASS_SNIPER][9].point = 2;
	g_attributeTable[CLASS_SNIPER][9].uid = "health regen";
	g_attributeTable[CLASS_SNIPER][9].value = float(1);
	g_attributeTable[CLASS_SNIPER][9].defaultValue = float(0);
	g_attributeTable[CLASS_SNIPER][9].additiveMode = ADDITIVE_NUMBER;	
	g_attributeTable[CLASS_SNIPER][9].title = "초당 체력 재생 %.0f 증가 (%dpt)(%d/%d)";		

	g_attributeTable[CLASS_SNIPER][10].class = CLASS_SNIPER;
	g_attributeTable[CLASS_SNIPER][10].max = 4;
	g_attributeTable[CLASS_SNIPER][10].point = 3;
	g_attributeTable[CLASS_SNIPER][10].uid = "sniper charge per sec";
	g_attributeTable[CLASS_SNIPER][10].value = float(50);
	g_attributeTable[CLASS_SNIPER][10].defaultValue = float(100);
	g_attributeTable[CLASS_SNIPER][10].additiveMode = ADDITIVE_PERCENT;	
	g_attributeTable[CLASS_SNIPER][10].title = "충전율 %.0f%% 증가 (%dpt)(%d/%d)";	

	g_attributeTable[CLASS_SNIPER][11].class = CLASS_SNIPER;
	g_attributeTable[CLASS_SNIPER][11].max = 5;
	g_attributeTable[CLASS_SNIPER][11].point = 3;
	g_attributeTable[CLASS_SNIPER][11].uid = "jarate duration";
	g_attributeTable[CLASS_SNIPER][11].value = float(1);
	g_attributeTable[CLASS_SNIPER][11].defaultValue = float(0);
	g_attributeTable[CLASS_SNIPER][11].additiveMode = ADDITIVE_NUMBER;	
	g_attributeTable[CLASS_SNIPER][11].title = "충전사격시 병수도 효과 %.0f초증가 (%dpt)(%d/%d)";		

	g_attributeTable[CLASS_SNIPER][12].class = CLASS_SNIPER;
	g_attributeTable[CLASS_SNIPER][12].max = 4;
	g_attributeTable[CLASS_SNIPER][12].point = 3;
	g_attributeTable[CLASS_SNIPER][12].uid = "headshot damage increase";
	g_attributeTable[CLASS_SNIPER][12].value = float(25);
	g_attributeTable[CLASS_SNIPER][12].defaultValue = float(100);
	g_attributeTable[CLASS_SNIPER][12].additiveMode = ADDITIVE_PERCENT;	
	g_attributeTable[CLASS_SNIPER][12].title = "헤드샷 추가피해 %.0f%% 증가 (%dpt)(%d/%d)";	

	g_attributeTable[CLASS_SNIPER][13].class = CLASS_SNIPER;
	g_attributeTable[CLASS_SNIPER][13].max = 1;
	g_attributeTable[CLASS_SNIPER][13].point = 4;
	g_attributeTable[CLASS_SNIPER][13].uid = "sniper aiming movespeed decreased";
	g_attributeTable[CLASS_SNIPER][13].value = float(4);
	g_attributeTable[CLASS_SNIPER][13].defaultValue = float(1);
	g_attributeTable[CLASS_SNIPER][13].additiveMode = ADDITIVE_NUMBER;	
	g_attributeTable[CLASS_SNIPER][13].isDisableDrawValue = true;
	g_attributeTable[CLASS_SNIPER][13].title = "조준시 이동속도 저하없음 (%dpt)(%d/%d)";	

	g_attributeTable[CLASS_SNIPER][14].class = CLASS_SNIPER;
	g_attributeTable[CLASS_SNIPER][14].max = 1;
	g_attributeTable[CLASS_SNIPER][14].point = 4;
	g_attributeTable[CLASS_SNIPER][14].uid = "sniper full charge damage bonus";
	g_attributeTable[CLASS_SNIPER][14].value = float(100);
	g_attributeTable[CLASS_SNIPER][14].defaultValue = float(100);
	g_attributeTable[CLASS_SNIPER][14].additiveMode = ADDITIVE_PERCENT;	
	g_attributeTable[CLASS_SNIPER][14].title = "완전충전시 피해 %.0f%%증가 (%dpt)(%d/%d)";
	
	g_attributeTable[CLASS_SPY][0].class = CLASS_SPY;
	g_attributeTable[CLASS_SPY][0].max = 5;
	g_attributeTable[CLASS_SPY][0].point = 1;
	g_attributeTable[CLASS_SPY][0].uid = "move speed bonus";
	g_attributeTable[CLASS_SPY][0].value = float(3);
	g_attributeTable[CLASS_SPY][0].defaultValue = float(100);
	g_attributeTable[CLASS_SPY][0].additiveMode = ADDITIVE_PERCENT;
	g_attributeTable[CLASS_SPY][0].title = "이동속도 %.0f%% 증가 (%dpt)(%d/%d)";

	g_attributeTable[CLASS_SPY][1].class = CLASS_SPY;
	g_attributeTable[CLASS_SPY][1].max = 10;
	g_attributeTable[CLASS_SPY][1].point = 1;
	g_attributeTable[CLASS_SPY][1].uid = "fire rate bonus";
	g_attributeTable[CLASS_SPY][1].value = float(5);
	g_attributeTable[CLASS_SPY][1].defaultValue = float(100);
	g_attributeTable[CLASS_SPY][1].additiveMode = MINUS_PERCENT;
	g_attributeTable[CLASS_SPY][1].title = "공격속도 %.0f%% 증가 (%dpt)(%d/%d)";

	g_attributeTable[CLASS_SPY][2].class = CLASS_SPY;
	g_attributeTable[CLASS_SPY][2].max = 10;
	g_attributeTable[CLASS_SPY][2].point = 1;
	g_attributeTable[CLASS_SPY][2].uid = "Reload time decreased";
	g_attributeTable[CLASS_SPY][2].value = float(5);
	g_attributeTable[CLASS_SPY][2].defaultValue = float(100);
	g_attributeTable[CLASS_SPY][2].additiveMode = MINUS_PERCENT;
	g_attributeTable[CLASS_SPY][2].title = "재장전속도 %.0f%% 증가 (%dpt)(%d/%d)";

	g_attributeTable[CLASS_SPY][3].class = CLASS_SPY;
	g_attributeTable[CLASS_SPY][3].max = 10;
	g_attributeTable[CLASS_SPY][3].point = 1;
	g_attributeTable[CLASS_SPY][3].uid = "increased jump height";
	g_attributeTable[CLASS_SPY][3].value = float(5);
	g_attributeTable[CLASS_SPY][3].defaultValue = float(100);
	g_attributeTable[CLASS_SPY][3].additiveMode = ADDITIVE_PERCENT;
	g_attributeTable[CLASS_SPY][3].title = "점프높이 %.0f%% 증가 (%dpt)(%d/%d)";

	g_attributeTable[CLASS_SPY][4].class = CLASS_SPY;
	g_attributeTable[CLASS_SPY][4].max = 3;
	g_attributeTable[CLASS_SPY][4].point = 1;
	g_attributeTable[CLASS_SPY][4].uid = "deploy time decreased";
	g_attributeTable[CLASS_SPY][4].value = float(15);
	g_attributeTable[CLASS_SPY][4].defaultValue = float(100);
	g_attributeTable[CLASS_SPY][4].additiveMode = MINUS_PERCENT;
	g_attributeTable[CLASS_SPY][4].title = "무기전환속도 %.0f%% 증가 (%dpt)(%d/%d)";

	g_attributeTable[CLASS_SPY][5].class = CLASS_SPY;
	g_attributeTable[CLASS_SPY][5].max = 2;
	g_attributeTable[CLASS_SPY][5].point = 1;
	g_attributeTable[CLASS_SPY][5].uid = "weapon spread bonus";
	g_attributeTable[CLASS_SPY][5].value = float(25);
	g_attributeTable[CLASS_SPY][5].defaultValue = float(100);
	g_attributeTable[CLASS_SPY][5].additiveMode = MINUS_PERCENT;
	g_attributeTable[CLASS_SPY][5].title = "집탄률 %.0f%% 증가 (%dpt)(%d/%d)";

	g_attributeTable[CLASS_SPY][6].class = CLASS_SPY;
	g_attributeTable[CLASS_SPY][6].max = 0;
	g_attributeTable[CLASS_SPY][6].point = 1;
	g_attributeTable[CLASS_SPY][6].uid = "";
	g_attributeTable[CLASS_SPY][6].value = float(5);
	g_attributeTable[CLASS_SPY][6].defaultValue = float(0);
	g_attributeTable[CLASS_SPY][6].additiveMode = ADDITIVE_NUMBER;
	g_attributeTable[CLASS_SPY][6].title = "적중시 체력 %.0f 회복 (%dpt)(%d/%d)";

	g_attributeTable[CLASS_SPY][7].class = CLASS_SPY;
	g_attributeTable[CLASS_SPY][7].max = 0;
	g_attributeTable[CLASS_SPY][7].point = 2;
	g_attributeTable[CLASS_SPY][7].uid = "";
	g_attributeTable[CLASS_SPY][7].value = float(1);
	g_attributeTable[CLASS_SPY][7].defaultValue = float(100);
	g_attributeTable[CLASS_SPY][7].additiveMode = ADDITIVE_PERCENT;
	g_attributeTable[CLASS_SPY][7].title = "피해량 %.0f%% 증가 (%dpt)(%d/%d)";

	g_attributeTable[CLASS_SPY][8].class = CLASS_SPY;
	g_attributeTable[CLASS_SPY][8].max = 5;
	g_attributeTable[CLASS_SPY][8].point = 2;
	g_attributeTable[CLASS_SPY][8].uid = "max health additive bonus";
	g_attributeTable[CLASS_SPY][8].value = float(10);
	g_attributeTable[CLASS_SPY][8].defaultValue = float(0);
	g_attributeTable[CLASS_SPY][8].additiveMode = ADDITIVE_NUMBER;
	g_attributeTable[CLASS_SPY][8].title = "최대체력 %.0f 증가 (%dpt)(%d/%d)";

	g_attributeTable[CLASS_SPY][9].class = CLASS_SPY;
	g_attributeTable[CLASS_SPY][9].max = 5;
	g_attributeTable[CLASS_SPY][9].point = 2;
	g_attributeTable[CLASS_SPY][9].uid = "health regen";
	g_attributeTable[CLASS_SPY][9].value = float(1);
	g_attributeTable[CLASS_SPY][9].defaultValue = float(0);
	g_attributeTable[CLASS_SPY][9].additiveMode = ADDITIVE_NUMBER;
	g_attributeTable[CLASS_SPY][9].title = "초당 체력 재생 %.0f 증가 (%dpt)(%d/%d)";

	g_attributeTable[CLASS_SPY][10].class = CLASS_SPY;
	g_attributeTable[CLASS_SPY][10].max = 5;
	g_attributeTable[CLASS_SPY][10].point = 2;
	g_attributeTable[CLASS_SPY][10].uid = "add cloak on hit";
	g_attributeTable[CLASS_SPY][10].value = float(3);
	g_attributeTable[CLASS_SPY][10].defaultValue = float(0);
	g_attributeTable[CLASS_SPY][10].additiveMode = ADDITIVE_NUMBER;
	g_attributeTable[CLASS_SPY][10].title = "적중시 은폐 에너지 %.0f%% 증가 (%dpt)(%d/%d)";

	g_attributeTable[CLASS_SPY][11].class = CLASS_SPY;
	g_attributeTable[CLASS_SPY][11].max = 2;
	g_attributeTable[CLASS_SPY][11].point = 3;
	g_attributeTable[CLASS_SPY][11].uid = "speed_boost_on_hit";
	g_attributeTable[CLASS_SPY][11].value = float(2);
	g_attributeTable[CLASS_SPY][11].defaultValue = float(0);
	g_attributeTable[CLASS_SPY][11].additiveMode = ADDITIVE_NUMBER;
	g_attributeTable[CLASS_SPY][11].title = "적중시 이동속도 %.0f초간 증가 (%dpt)(%d/%d)";

	g_attributeTable[CLASS_SPY][12].class = CLASS_SPY;
	g_attributeTable[CLASS_SPY][12].max = 2;
	g_attributeTable[CLASS_SPY][12].point = 3;
	g_attributeTable[CLASS_SPY][12].uid = "melee range multiplier";
	g_attributeTable[CLASS_SPY][12].value = float(25);
	g_attributeTable[CLASS_SPY][12].defaultValue = float(100);
	g_attributeTable[CLASS_SPY][12].additiveMode = ADDITIVE_PERCENT;
	g_attributeTable[CLASS_SPY][12].title = "근접 공격 범위 %.0f%%증가 (%dpt)(%d/%d)";

	g_attributeTable[CLASS_SPY][13].class = CLASS_SPY;
	g_attributeTable[CLASS_SPY][13].max = 1;
	g_attributeTable[CLASS_SPY][13].point = 4;
	g_attributeTable[CLASS_SPY][13].uid = "air dash count";
	g_attributeTable[CLASS_SPY][13].value = float(100);
	g_attributeTable[CLASS_SPY][13].defaultValue = float(0);
	g_attributeTable[CLASS_SPY][13].additiveMode = ADDITIVE_PERCENT;
	g_attributeTable[CLASS_SPY][13].isDisableDrawValue = true;
	g_attributeTable[CLASS_SPY][13].title = "2단점프 가능 (%dpt)(%d/%d)";

	g_attributeTable[CLASS_SPY][14].class = CLASS_SPY;
	g_attributeTable[CLASS_SPY][14].max = 1;
	g_attributeTable[CLASS_SPY][14].point = 5;
	g_attributeTable[CLASS_SPY][14].uid = "SET BONUS: quiet unstealth";
	g_attributeTable[CLASS_SPY][14].value = float(100);
	g_attributeTable[CLASS_SPY][14].defaultValue = float(0);
	g_attributeTable[CLASS_SPY][14].additiveMode = ADDITIVE_PERCENT;
	g_attributeTable[CLASS_SPY][14].isDisableDrawValue = true;
	g_attributeTable[CLASS_SPY][14].title = "은폐 해제 음량감소 (%dpt)(%d/%d)";

	g_attributeTable[CLASS_SPY][15].class = CLASS_SPY;
	g_attributeTable[CLASS_SPY][15].max = 1;
	g_attributeTable[CLASS_SPY][15].point = 5;
	g_attributeTable[CLASS_SPY][15].uid = "cancel falling damage";
	g_attributeTable[CLASS_SPY][15].value = float(100);
	g_attributeTable[CLASS_SPY][15].defaultValue = float(0);
	g_attributeTable[CLASS_SPY][15].additiveMode = ADDITIVE_PERCENT;
	g_attributeTable[CLASS_SPY][15].isDisableDrawValue = true;
	g_attributeTable[CLASS_SPY][15].title = "낙하 피해 무시 (%dpt)(%d/%d)";
	
	g_attributeTable[CLASS_HALE][0].class = CLASS_HALE;
	g_attributeTable[CLASS_HALE][0].max = 10;
	g_attributeTable[CLASS_HALE][0].point = 1;
	g_attributeTable[CLASS_HALE][0].uid = "move speed bonus";
	g_attributeTable[CLASS_HALE][0].value = float(3);
	g_attributeTable[CLASS_HALE][0].defaultValue = float(100);
	g_attributeTable[CLASS_HALE][0].additiveMode = ADDITIVE_PERCENT;		
	g_attributeTable[CLASS_HALE][0].title = "이동속도 %.0f%% 증가 (%dpt)(%d/%d)";

	g_attributeTable[CLASS_HALE][1].class = CLASS_HALE;
	g_attributeTable[CLASS_HALE][1].max = 5;
	g_attributeTable[CLASS_HALE][1].point = 2;
	g_attributeTable[CLASS_HALE][1].uid = "max health additive bonus";
	g_attributeTable[CLASS_HALE][1].value = float(2000);
	g_attributeTable[CLASS_HALE][1].defaultValue = float(0);
	g_attributeTable[CLASS_HALE][1].additiveMode = ADDITIVE_NUMBER;		
	g_attributeTable[CLASS_HALE][1].title = "최대체력 %.0f증가 (%dpt)(%d/%d)";

	g_attributeTable[CLASS_HALE][2].class = CLASS_HALE;
	g_attributeTable[CLASS_HALE][2].max = 2;
	g_attributeTable[CLASS_HALE][2].point = 2;
	g_attributeTable[CLASS_HALE][2].uid = "melee range multiplier";
	g_attributeTable[CLASS_HALE][2].value = float(50);
	g_attributeTable[CLASS_HALE][2].defaultValue = float(100);
	g_attributeTable[CLASS_HALE][2].additiveMode = ADDITIVE_PERCENT;		
	g_attributeTable[CLASS_HALE][2].title = "근접 공격 범위 %.0f%%증가 (%dpt)(%d/%d)";

	g_attributeTable[CLASS_SHARED][0].class = CLASS_SHARED;
	g_attributeTable[CLASS_SHARED][0].max = 5;
	g_attributeTable[CLASS_SHARED][0].point = 1;
	g_attributeTable[CLASS_SHARED][0].uid = "ammo regen";
	g_attributeTable[CLASS_SHARED][0].value = float(10);
	g_attributeTable[CLASS_SHARED][0].defaultValue = float(0);
	g_attributeTable[CLASS_SHARED][0].additiveMode = ADDITIVE_PERCENT;		
	g_attributeTable[CLASS_SHARED][0].title = "5초마다 탄약 %.0f%%생성 (%dpt)(%d/%d)";		

	g_attributeTable[CLASS_SHARED][1].class = CLASS_SHARED;
	g_attributeTable[CLASS_SHARED][1].max = 0;
	g_attributeTable[CLASS_SHARED][1].point = 2;
	g_attributeTable[CLASS_SHARED][1].uid = "";
	g_attributeTable[CLASS_SHARED][1].value = float(1);
	g_attributeTable[CLASS_SHARED][1].defaultValue = float(100);
	g_attributeTable[CLASS_SHARED][1].additiveMode = ADDITIVE_PERCENT;	
	g_attributeTable[CLASS_SHARED][1].title = "피해량 %.0f%% 증가 (%dpt)(%d/%d)";	
	
	g_attributeTable[CLASS_WEAPON][0].class = CLASS_WEAPON;
	g_attributeTable[CLASS_WEAPON][0].max = 15;
	g_attributeTable[CLASS_WEAPON][0].value = float(1);
	g_attributeTable[CLASS_WEAPON][0].defaultValue = float(100);
	g_attributeTable[CLASS_WEAPON][0].additiveMode = ADDITIVE_PERCENT;
	g_attributeTable[CLASS_WEAPON][0].uid = "damage bonus HIDDEN";

	for (int i=0;i<sizeof(g_playerAttributes);i++){
		for (int i2=0;i2<sizeof(g_playerAttributes[i][CLASS_SCOUT]);i2++)
		{
			g_playerAttributes[i][CLASS_SCOUT][i2].uid = g_attributeTable[CLASS_SCOUT][i2].uid;
			g_playerAttributes[i][CLASS_SCOUT][i2].id = i2;
			g_playerAttributes[i][CLASS_SCOUT][i2].class = g_attributeTable[CLASS_SCOUT][i2].class;
			g_playerAttributes[i][CLASS_SCOUT][i2].upgrade = 0;
		}
	}

	for (int i=0;i<sizeof(g_playerAttributes);i++){
		for (int i2=0;i2<sizeof(g_playerAttributes[i][CLASS_MEDIC]);i2++)
		{
			g_playerAttributes[i][CLASS_MEDIC][i2].uid = g_attributeTable[CLASS_MEDIC][i2].uid;
			g_playerAttributes[i][CLASS_MEDIC][i2].id = i2;
			g_playerAttributes[i][CLASS_MEDIC][i2].class = g_attributeTable[CLASS_MEDIC][i2].class;
			g_playerAttributes[i][CLASS_MEDIC][i2].upgrade = 0;
		}
	}

	for (int i=0;i<sizeof(g_playerAttributes);i++){
		for (int i2=0;i2<sizeof(g_playerAttributes[i][CLASS_SOLDIER]);i2++)
		{
			g_playerAttributes[i][CLASS_SOLDIER][i2].uid = g_attributeTable[CLASS_SOLDIER][i2].uid;
			g_playerAttributes[i][CLASS_SOLDIER][i2].id = i2;
			g_playerAttributes[i][CLASS_SOLDIER][i2].class = g_attributeTable[CLASS_SOLDIER][i2].class;
			g_playerAttributes[i][CLASS_SOLDIER][i2].upgrade = 0;
		}
	}

	for (int i=0;i<sizeof(g_playerAttributes);i++){
		for (int i2=0;i2<sizeof(g_playerAttributes[i][CLASS_SPY]);i2++)
		{
			g_playerAttributes[i][CLASS_SPY][i2].uid = g_attributeTable[CLASS_SPY][i2].uid;
			g_playerAttributes[i][CLASS_SPY][i2].id = i2;
			g_playerAttributes[i][CLASS_SPY][i2].class = g_attributeTable[CLASS_SPY][i2].class;
			g_playerAttributes[i][CLASS_SPY][i2].upgrade = 0;
		}
	}	

	for (int i=0;i<sizeof(g_playerAttributes);i++){
		for (int i2=0;i2<sizeof(g_playerAttributes[i][CLASS_PYRO]);i2++)
		{
			g_playerAttributes[i][CLASS_PYRO][i2].uid = g_attributeTable[CLASS_PYRO][i2].uid;
			g_playerAttributes[i][CLASS_PYRO][i2].id = i2;
			g_playerAttributes[i][CLASS_PYRO][i2].class = g_attributeTable[CLASS_PYRO][i2].class;
			g_playerAttributes[i][CLASS_PYRO][i2].upgrade = 0;
		}
	}

	for (int i=0;i<sizeof(g_playerAttributes);i++){
		for (int i2=0;i2<sizeof(g_playerAttributes[i][CLASS_DEMOMAN]);i2++)
		{
			g_playerAttributes[i][CLASS_DEMOMAN][i2].uid = g_attributeTable[CLASS_DEMOMAN][i2].uid;
			g_playerAttributes[i][CLASS_DEMOMAN][i2].id = i2;
			g_playerAttributes[i][CLASS_DEMOMAN][i2].class = g_attributeTable[CLASS_DEMOMAN][i2].class;
			g_playerAttributes[i][CLASS_DEMOMAN][i2].upgrade = 0;
		}
	}

	for (int i=0;i<sizeof(g_playerAttributes);i++){
		for (int i2=0;i2<sizeof(g_playerAttributes[i][CLASS_SNIPER]);i2++)
		{
			g_playerAttributes[i][CLASS_SNIPER][i2].uid = g_attributeTable[CLASS_SNIPER][i2].uid;
			g_playerAttributes[i][CLASS_SNIPER][i2].id = i2;
			g_playerAttributes[i][CLASS_SNIPER][i2].class = g_attributeTable[CLASS_SNIPER][i2].class;
			g_playerAttributes[i][CLASS_SNIPER][i2].upgrade = 0;
		}
	}	

	for (int i=0;i<sizeof(g_playerAttributes);i++){
		for (int i2=0;i2<sizeof(g_playerAttributes[i][CLASS_ENGINEER]);i2++)
		{
			g_playerAttributes[i][CLASS_ENGINEER][i2].uid = g_attributeTable[CLASS_ENGINEER][i2].uid;
			g_playerAttributes[i][CLASS_ENGINEER][i2].id = i2;
			g_playerAttributes[i][CLASS_ENGINEER][i2].class = g_attributeTable[CLASS_ENGINEER][i2].class;
			g_playerAttributes[i][CLASS_ENGINEER][i2].upgrade = 0;
		}
	}
	
	for (int i=0;i<sizeof(g_playerAttributes);i++){
		for (int i2=0;i2<sizeof(g_playerAttributes[i][CLASS_HEAVY]);i2++)
		{
			g_playerAttributes[i][CLASS_HEAVY][i2].uid = g_attributeTable[CLASS_HEAVY][i2].uid;
			g_playerAttributes[i][CLASS_HEAVY][i2].id = i2;
			g_playerAttributes[i][CLASS_HEAVY][i2].class = g_attributeTable[CLASS_HEAVY][i2].class;
			g_playerAttributes[i][CLASS_HEAVY][i2].upgrade = 0;
		}
	}	

	for (int i=0;i<sizeof(g_playerAttributes);i++){
		for (int i2=0;i2<sizeof(g_playerAttributes[i][CLASS_HALE]);i2++)
		{
			g_playerAttributes[i][CLASS_HALE][i2].uid = g_attributeTable[CLASS_HALE][i2].uid;
			g_playerAttributes[i][CLASS_HALE][i2].id = i2;
			g_playerAttributes[i][CLASS_HALE][i2].class = g_attributeTable[CLASS_HALE][i2].class;
			g_playerAttributes[i][CLASS_HALE][i2].upgrade = 0;
		}
	}

	for (int i=0;i<sizeof(g_playerAttributes);i++){
		for (int i2=0;i2<sizeof(g_playerAttributes[i][CLASS_SHARED]);i2++)
		{
			g_playerAttributes[i][CLASS_SHARED][i2].uid = g_attributeTable[CLASS_SHARED][i2].uid;
			g_playerAttributes[i][CLASS_SHARED][i2].id = i2;
			g_playerAttributes[i][CLASS_SHARED][i2].class = g_attributeTable[CLASS_SHARED][i2].class;
			g_playerAttributes[i][CLASS_SHARED][i2].upgrade = 0;
		}
	}
	
	for (int i=0;i<sizeof(g_playerAttributes);i++){
		for (int i2=0;i2<sizeof(g_playerAttributes[i][CLASS_WEAPON]);i2++)
		{
			g_playerAttributes[i][CLASS_WEAPON][i2].uid = g_attributeTable[CLASS_WEAPON][i2].uid;
			g_playerAttributes[i][CLASS_WEAPON][i2].id = i2;
			g_playerAttributes[i][CLASS_WEAPON][i2].class = g_attributeTable[CLASS_WEAPON][i2].class;
			g_playerAttributes[i][CLASS_WEAPON][i2].upgrade = 0;
		}
	}

}

