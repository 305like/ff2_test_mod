/**
 * =============================================================================
 * TF2 Level System - Menu/UI Module
 * =============================================================================
 *
 * 메뉴 시스템 및 UI 표시를 담당하는 모듈
 * - 메인 메뉴, 플레이어 정보, 클래스 스탯 메뉴
 * - 부활, 스킬 초기화, 무기 강화 메뉴
 * - HUD 표시 (레드팀만)
 */

#if defined _menu_system_included
  #endinput
#endif
#define _menu_system_included

// ============================================================================
// 전역 변수
// ============================================================================

// 메뉴 페이지 네비게이션용
int g_prevOpenMenuPage = -1;

// ============================================================================
// HUD 표시 함수
// ============================================================================

/**
 * HUD 텍스트를 주기적으로 표시 (레드팀만)
 * 타이머로 1초마다 호출됨
 */
public Action Menu_ShowHUD(Handle timer)
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client) || IsFakeClient(client))
        {
            continue;
        }

        // 블루팀(3번)은 HUD 표시 안함
        int team = GetClientTeam(client);
        if (team == 3)  // 블루팀
        {
            continue;
        }

        // 레드팀(2번)만 HUD 표시
        char hintText[512];
        Format(hintText, sizeof(hintText),
            "레벨 : %d\n경험치 : %d/%d\n포인트 : %d",
            g_playerDataList[client].level,
            g_playerDataList[client].exp,
            EXP_TABLE[g_playerDataList[client].level],
            g_playerDataList[client].point
        );

        SetHudTextParams(0.01, 0.0, 1.0, 255, 200, 0, 255, 0, 0.0, 0.0, 0.1);
        ShowHudText(client, 4, hintText);
    }

    return Plugin_Continue;
}

// ============================================================================
// 메인 메뉴
// ============================================================================

/**
 * 메인 메뉴를 표시
 * @param client    클라이언트 인덱스
 */
void Menu_ShowMain(int client)
{
    Menu menu = CreateMenu(MenuHandler_Main);
    menu.SetTitle("<< RPG&스킬 헤일 서버에 오신걸 환영합니다 >>");

    menu.AddItem("info",        "내정보");
    menu.AddItem("classStat",   "클래스 스탯");
    menu.AddItem("shop",        "상점");
    menu.AddItem("weaponStat",  "무기 강화");
    menu.AddItem("revive",      "부활권");
    menu.AddItem("inventory",   "인벤토리");
    menu.AddItem("skillReset",  "스킬초기화");

    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

/**
 * 메인 메뉴 핸들러
 */
public int MenuHandler_Main(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_End)
    {
        delete menu;
    }

    if (action != MenuAction_Select)
        return 0;

    char info[32];
    menu.GetItem(item, info, sizeof(info));

    if (StrEqual(info, "info"))
    {
        Menu_ShowPlayerInfo(client);
    }
    else if (StrEqual(info, "classStat"))
    {
        Menu_ShowClassStat(client);
    }
    else if (StrEqual(info, "revive"))
    {
        Menu_ShowRevive(client);
    }
    else if (StrEqual(info, "skillReset"))
    {
        Menu_ShowSkillReset(client);
    }
    else if (StrEqual(info, "weaponStat"))
    {
        Menu_ShowWeaponUpgrade(client);
    }
    else
    {
        PrintToChat(client, "아직 구현되지 않은 메뉴입니다: %s", info);
    }

    return 0;
}

// ============================================================================
// 플레이어 정보 메뉴
// ============================================================================

/**
 * 플레이어 정보 메뉴를 표시
 * @param client    클라이언트 인덱스
 */
void Menu_ShowPlayerInfo(int client)
{
    Menu menu = CreateMenu(MenuHandler_PlayerInfo);

    char buffer[128];
    char name[64];
    GetClientName(client, name, sizeof(name));

    menu.SetTitle("당신의 정보입니다.");

    Format(buffer, sizeof(buffer), "이름 : %s", name);
    menu.AddItem("", buffer, ITEMDRAW_DISABLED);

    Format(buffer, sizeof(buffer), "돈 : %d", g_playerDataList[client].point);
    menu.AddItem("", buffer, ITEMDRAW_DISABLED);

    Format(buffer, sizeof(buffer), "레벨 : %d", g_playerDataList[client].level);
    menu.AddItem("", buffer, ITEMDRAW_DISABLED);

    Format(buffer, sizeof(buffer), "경험치 : %d/%d", g_playerDataList[client].exp, EXP_TABLE[g_playerDataList[client].level]);
    menu.AddItem("", buffer, ITEMDRAW_DISABLED);

    Format(buffer, sizeof(buffer), "강화 : %d", MAX_UPGRADE);
    menu.AddItem("", buffer, ITEMDRAW_DISABLED);

    Format(buffer, sizeof(buffer), "남은 스킬포인트 : %d", g_playerDataList[client].skillpoint);
    menu.AddItem("", buffer, ITEMDRAW_DISABLED);

    menu.AddItem("back", "상위 메뉴로 돌아가기");

    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

/**
 * 플레이어 정보 메뉴 핸들러
 */
public int MenuHandler_PlayerInfo(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_End)
    {
        delete menu;
    }
    else if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(item, info, sizeof(info));

        if (StrEqual(info, "back"))
        {
            Menu_ShowMain(client);
        }
    }

    return 0;
}

// ============================================================================
// 클래스 스탯 메뉴
// ============================================================================

/**
 * 클래스 선택 메뉴를 표시
 * @param client    클라이언트 인덱스
 */
void Menu_ShowClassStat(int client)
{
    Menu menu = CreateMenu(MenuHandler_ClassStat);
    menu.SetTitle("클래스 스탯");

    menu.AddItem("scout",       "스카웃");
    menu.AddItem("soldier",     "솔져");
    menu.AddItem("pyro",        "파이로");
    menu.AddItem("demoman",     "데모맨");
    menu.AddItem("heavy",       "헤비");
    menu.AddItem("engineer",    "엔지니어");
    menu.AddItem("medic",       "메딕");
    menu.AddItem("sniper",      "스나이퍼");
    menu.AddItem("spy",         "스파이");
    menu.AddItem("hale",        "헤일(사용불가)");
    menu.AddItem("shared",      "공용");

    menu.AddItem("back", "상위 메뉴로 돌아가기");

    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

/**
 * 클래스 선택 메뉴 핸들러
 */
public int MenuHandler_ClassStat(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_End)
    {
        delete menu;
    }
    else if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(item, info, sizeof(info));

        if (StrEqual(info, "back"))
        {
            Menu_ShowMain(client);
        }
        else
        {
            // 선택한 클래스의 상세 스탯 메뉴 표시
            Menu_ShowClassStatDetail(client, info);
        }
    }

    return 0;
}

/**
 * 클래스 상세 스탯 메뉴를 표시
 * @param client    클라이언트 인덱스
 * @param classID   클래스 ID (예: "scout", "soldier", etc.)
 */
void Menu_ShowClassStatDetail(int client, const char[] classID)
{
    Menu menu = CreateMenu(MenuHandler_ClassStatDetail);

    // 클래스별로 메뉴 구성
    if (StrEqual(classID, "scout") || StrEqual(classID, "scout_2"))
    {
        bool isPage2 = StrEqual(classID, "scout_2");

        if (isPage2)
            menu.SetTitle("스카웃 (2/2)");
        else
            menu.SetTitle("스카웃 (1/2)");

        menu.Pagination = MENU_NO_PAGINATION;

        // 활성 속성 인덱스 수집
        int activeIndices[16];
        int activeCount = 0;
        for (int i = 0; i < sizeof(g_attributeTable[CLASS_SCOUT]); i++)
        {
            if (!StrEqual(g_attributeTable[CLASS_SCOUT][i].uid, ""))
            {
                activeIndices[activeCount] = i;
                activeCount++;
            }
        }

        // 페이지 1: 첫 7개, 페이지 2: 나머지
        int startIdx = isPage2 ? 7 : 0;
        int endIdx = isPage2 ? activeCount : 7;
        if (endIdx > activeCount) endIdx = activeCount;

        for (int j = startIdx; j < endIdx; j++)
        {
            int i = activeIndices[j];
            char buffer[128];
            Format(buffer, sizeof(buffer), "%s", g_attributeTable[CLASS_SCOUT][i].title);

            if (g_attributeTable[CLASS_SCOUT][i].isDisableDrawValue)
            {
                Format(buffer, sizeof(buffer), buffer, g_attributeTable[CLASS_SCOUT][i].point,
                       g_playerAttributes[client][CLASS_SCOUT][i].upgrade, g_attributeTable[CLASS_SCOUT][i].max);
            }
            else
            {
                Format(buffer, sizeof(buffer), buffer, g_attributeTable[CLASS_SCOUT][i].value, g_attributeTable[CLASS_SCOUT][i].point,
                       g_playerAttributes[client][CLASS_SCOUT][i].upgrade, g_attributeTable[CLASS_SCOUT][i].max);
            }

            char key[64];
            Format(key, sizeof(key), "scout%d_%d", isPage2 ? 2 : 1, i);
            menu.AddItem(key, buffer);
        }

        // 빈 슬롯 채우기 (7번까지)
        int itemsOnPage = endIdx - startIdx;
        for (int j = itemsOnPage; j < 7; j++)
        {
            menu.AddItem("", " ", ITEMDRAW_SPACER);
        }

        // 8번: 뒤로가기, 9번: 다음/이전
        menu.AddItem("back", "뒤로가기");
        if (isPage2)
            menu.AddItem("scout_prev", "이전 페이지");
        else
            menu.AddItem("scout_next", "다음 페이지");
    }
    else if (StrEqual(classID, "medic") || StrEqual(classID, "medic_2"))
    {
        bool isPage2 = StrEqual(classID, "medic_2");
        if (isPage2) menu.SetTitle("메딕 (2/2)");
        else menu.SetTitle("메딕 (1/2)");
        menu.Pagination = MENU_NO_PAGINATION;

        int activeIndices[20]; int activeCount = 0;
        for (int i = 0; i < sizeof(g_attributeTable[CLASS_MEDIC]); i++)
            if (!StrEqual(g_attributeTable[CLASS_MEDIC][i].uid, "")) activeIndices[activeCount++] = i;

        int startIdx = isPage2 ? 7 : 0;
        int endIdx = isPage2 ? activeCount : 7;
        if (endIdx > activeCount) endIdx = activeCount;

        for (int j = startIdx; j < endIdx; j++)
        {
            int i = activeIndices[j];
            char buffer[128];
            Format(buffer, sizeof(buffer), "%s", g_attributeTable[CLASS_MEDIC][i].title);
            if (g_attributeTable[CLASS_MEDIC][i].isDisableDrawValue)
                Format(buffer, sizeof(buffer), buffer, g_attributeTable[CLASS_MEDIC][i].point, g_playerAttributes[client][CLASS_MEDIC][i].upgrade, g_attributeTable[CLASS_MEDIC][i].max);
            else
                Format(buffer, sizeof(buffer), buffer, g_attributeTable[CLASS_MEDIC][i].value, g_attributeTable[CLASS_MEDIC][i].point, g_playerAttributes[client][CLASS_MEDIC][i].upgrade, g_attributeTable[CLASS_MEDIC][i].max);
            char key[64]; Format(key, sizeof(key), "medic%d_%d", isPage2 ? 2 : 1, i);
            menu.AddItem(key, buffer);
        }
        int itemsOnPage = endIdx - startIdx;
        for (int j = itemsOnPage; j < 7; j++) menu.AddItem("", " ", ITEMDRAW_SPACER);
        menu.AddItem("back", "뒤로가기");
        if (isPage2) menu.AddItem("medic_prev", "이전 페이지");
        else menu.AddItem("medic_next", "다음 페이지");
    }
    else if (StrEqual(classID, "soldier") || StrEqual(classID, "soldier_2"))
    {
        bool isPage2 = StrEqual(classID, "soldier_2");
        if (isPage2) menu.SetTitle("솔져 (2/2)");
        else menu.SetTitle("솔져 (1/2)");
        menu.Pagination = MENU_NO_PAGINATION;

        int activeIndices[20]; int activeCount = 0;
        for (int i = 0; i < sizeof(g_attributeTable[CLASS_SOLDIER]); i++)
            if (!StrEqual(g_attributeTable[CLASS_SOLDIER][i].uid, "")) activeIndices[activeCount++] = i;

        int startIdx = isPage2 ? 7 : 0;
        int endIdx = isPage2 ? activeCount : 7;
        if (endIdx > activeCount) endIdx = activeCount;

        for (int j = startIdx; j < endIdx; j++)
        {
            int i = activeIndices[j];
            char buffer[128];
            Format(buffer, sizeof(buffer), "%s", g_attributeTable[CLASS_SOLDIER][i].title);
            if (g_attributeTable[CLASS_SOLDIER][i].isDisableDrawValue)
                Format(buffer, sizeof(buffer), buffer, g_attributeTable[CLASS_SOLDIER][i].point, g_playerAttributes[client][CLASS_SOLDIER][i].upgrade, g_attributeTable[CLASS_SOLDIER][i].max);
            else
                Format(buffer, sizeof(buffer), buffer, g_attributeTable[CLASS_SOLDIER][i].value, g_attributeTable[CLASS_SOLDIER][i].point, g_playerAttributes[client][CLASS_SOLDIER][i].upgrade, g_attributeTable[CLASS_SOLDIER][i].max);
            char key[64]; Format(key, sizeof(key), "soldier%d_%d", isPage2 ? 2 : 1, i);
            menu.AddItem(key, buffer);
        }
        int itemsOnPage = endIdx - startIdx;
        for (int j = itemsOnPage; j < 7; j++) menu.AddItem("", " ", ITEMDRAW_SPACER);
        menu.AddItem("back", "뒤로가기");
        if (isPage2) menu.AddItem("soldier_prev", "이전 페이지");
        else menu.AddItem("soldier_next", "다음 페이지");
    }
    else if (StrEqual(classID, "pyro") || StrEqual(classID, "pyro_2"))
    {
        bool isPage2 = StrEqual(classID, "pyro_2");
        if (isPage2) menu.SetTitle("파이로 (2/2)");
        else menu.SetTitle("파이로 (1/2)");
        menu.Pagination = MENU_NO_PAGINATION;

        int activeIndices[20]; int activeCount = 0;
        for (int i = 0; i < sizeof(g_attributeTable[CLASS_PYRO]); i++)
            if (!StrEqual(g_attributeTable[CLASS_PYRO][i].uid, "")) activeIndices[activeCount++] = i;

        int startIdx = isPage2 ? 7 : 0;
        int endIdx = isPage2 ? activeCount : 7;
        if (endIdx > activeCount) endIdx = activeCount;

        for (int j = startIdx; j < endIdx; j++)
        {
            int i = activeIndices[j];
            char buffer[128];
            Format(buffer, sizeof(buffer), "%s", g_attributeTable[CLASS_PYRO][i].title);
            if (g_attributeTable[CLASS_PYRO][i].isDisableDrawValue)
                Format(buffer, sizeof(buffer), buffer, g_attributeTable[CLASS_PYRO][i].point, g_playerAttributes[client][CLASS_PYRO][i].upgrade, g_attributeTable[CLASS_PYRO][i].max);
            else
                Format(buffer, sizeof(buffer), buffer, g_attributeTable[CLASS_PYRO][i].value, g_attributeTable[CLASS_PYRO][i].point, g_playerAttributes[client][CLASS_PYRO][i].upgrade, g_attributeTable[CLASS_PYRO][i].max);
            char key[64]; Format(key, sizeof(key), "pyro%d_%d", isPage2 ? 2 : 1, i);
            menu.AddItem(key, buffer);
        }
        int itemsOnPage = endIdx - startIdx;
        for (int j = itemsOnPage; j < 7; j++) menu.AddItem("", " ", ITEMDRAW_SPACER);
        menu.AddItem("back", "뒤로가기");
        if (isPage2) menu.AddItem("pyro_prev", "이전 페이지");
        else menu.AddItem("pyro_next", "다음 페이지");
    }
    else if (StrEqual(classID, "spy") || StrEqual(classID, "spy_2"))
    {
        bool isPage2 = StrEqual(classID, "spy_2");
        if (isPage2) menu.SetTitle("스파이 (2/2)");
        else menu.SetTitle("스파이 (1/2)");
        menu.Pagination = MENU_NO_PAGINATION;

        int activeIndices[20]; int activeCount = 0;
        for (int i = 0; i < sizeof(g_attributeTable[CLASS_SPY]); i++)
            if (!StrEqual(g_attributeTable[CLASS_SPY][i].uid, "")) activeIndices[activeCount++] = i;

        int startIdx = isPage2 ? 7 : 0;
        int endIdx = isPage2 ? activeCount : 7;
        if (endIdx > activeCount) endIdx = activeCount;

        for (int j = startIdx; j < endIdx; j++)
        {
            int i = activeIndices[j];
            char buffer[128];
            Format(buffer, sizeof(buffer), "%s", g_attributeTable[CLASS_SPY][i].title);
            if (g_attributeTable[CLASS_SPY][i].isDisableDrawValue)
                Format(buffer, sizeof(buffer), buffer, g_attributeTable[CLASS_SPY][i].point, g_playerAttributes[client][CLASS_SPY][i].upgrade, g_attributeTable[CLASS_SPY][i].max);
            else
                Format(buffer, sizeof(buffer), buffer, g_attributeTable[CLASS_SPY][i].value, g_attributeTable[CLASS_SPY][i].point, g_playerAttributes[client][CLASS_SPY][i].upgrade, g_attributeTable[CLASS_SPY][i].max);
            char key[64]; Format(key, sizeof(key), "spy%d_%d", isPage2 ? 2 : 1, i);
            menu.AddItem(key, buffer);
        }
        int itemsOnPage = endIdx - startIdx;
        for (int j = itemsOnPage; j < 7; j++) menu.AddItem("", " ", ITEMDRAW_SPACER);
        menu.AddItem("back", "뒤로가기");
        if (isPage2) menu.AddItem("spy_prev", "이전 페이지");
        else menu.AddItem("spy_next", "다음 페이지");
    }
    else if (StrEqual(classID, "demoman") || StrEqual(classID, "demoman_2"))
    {
        bool isPage2 = StrEqual(classID, "demoman_2");
        if (isPage2) menu.SetTitle("데모맨 (2/2)");
        else menu.SetTitle("데모맨 (1/2)");
        menu.Pagination = MENU_NO_PAGINATION;

        int activeIndices[20]; int activeCount = 0;
        for (int i = 0; i < sizeof(g_attributeTable[CLASS_DEMOMAN]); i++)
            if (!StrEqual(g_attributeTable[CLASS_DEMOMAN][i].uid, "")) activeIndices[activeCount++] = i;

        int startIdx = isPage2 ? 7 : 0;
        int endIdx = isPage2 ? activeCount : 7;
        if (endIdx > activeCount) endIdx = activeCount;

        for (int j = startIdx; j < endIdx; j++)
        {
            int i = activeIndices[j];
            char buffer[128];
            Format(buffer, sizeof(buffer), "%s", g_attributeTable[CLASS_DEMOMAN][i].title);
            if (g_attributeTable[CLASS_DEMOMAN][i].isDisableDrawValue)
                Format(buffer, sizeof(buffer), buffer, g_attributeTable[CLASS_DEMOMAN][i].point, g_playerAttributes[client][CLASS_DEMOMAN][i].upgrade, g_attributeTable[CLASS_DEMOMAN][i].max);
            else
                Format(buffer, sizeof(buffer), buffer, g_attributeTable[CLASS_DEMOMAN][i].value, g_attributeTable[CLASS_DEMOMAN][i].point, g_playerAttributes[client][CLASS_DEMOMAN][i].upgrade, g_attributeTable[CLASS_DEMOMAN][i].max);
            char key[64]; Format(key, sizeof(key), "demoman%d_%d", isPage2 ? 2 : 1, i);
            menu.AddItem(key, buffer);
        }
        int itemsOnPage = endIdx - startIdx;
        for (int j = itemsOnPage; j < 7; j++) menu.AddItem("", " ", ITEMDRAW_SPACER);
        menu.AddItem("back", "뒤로가기");
        if (isPage2) menu.AddItem("demoman_prev", "이전 페이지");
        else menu.AddItem("demoman_next", "다음 페이지");
    }
    else if (StrEqual(classID, "sniper") || StrEqual(classID, "sniper_2"))
    {
        bool isPage2 = StrEqual(classID, "sniper_2");
        if (isPage2) menu.SetTitle("스나이퍼 (2/2)");
        else menu.SetTitle("스나이퍼 (1/2)");
        menu.Pagination = MENU_NO_PAGINATION;

        int activeIndices[20]; int activeCount = 0;
        for (int i = 0; i < sizeof(g_attributeTable[CLASS_SNIPER]); i++)
            if (!StrEqual(g_attributeTable[CLASS_SNIPER][i].uid, "")) activeIndices[activeCount++] = i;

        int startIdx = isPage2 ? 7 : 0;
        int endIdx = isPage2 ? activeCount : 7;
        if (endIdx > activeCount) endIdx = activeCount;

        for (int j = startIdx; j < endIdx; j++)
        {
            int i = activeIndices[j];
            char buffer[128];
            Format(buffer, sizeof(buffer), "%s", g_attributeTable[CLASS_SNIPER][i].title);
            if (g_attributeTable[CLASS_SNIPER][i].isDisableDrawValue)
                Format(buffer, sizeof(buffer), buffer, g_attributeTable[CLASS_SNIPER][i].point, g_playerAttributes[client][CLASS_SNIPER][i].upgrade, g_attributeTable[CLASS_SNIPER][i].max);
            else
                Format(buffer, sizeof(buffer), buffer, g_attributeTable[CLASS_SNIPER][i].value, g_attributeTable[CLASS_SNIPER][i].point, g_playerAttributes[client][CLASS_SNIPER][i].upgrade, g_attributeTable[CLASS_SNIPER][i].max);
            char key[64]; Format(key, sizeof(key), "sniper%d_%d", isPage2 ? 2 : 1, i);
            menu.AddItem(key, buffer);
        }
        int itemsOnPage = endIdx - startIdx;
        for (int j = itemsOnPage; j < 7; j++) menu.AddItem("", " ", ITEMDRAW_SPACER);
        menu.AddItem("back", "뒤로가기");
        if (isPage2) menu.AddItem("sniper_prev", "이전 페이지");
        else menu.AddItem("sniper_next", "다음 페이지");
    }
    else if (StrEqual(classID, "engineer") || StrEqual(classID, "engineer_2"))
    {
        bool isPage2 = StrEqual(classID, "engineer_2");
        if (isPage2) menu.SetTitle("엔지니어 (2/2)");
        else menu.SetTitle("엔지니어 (1/2)");
        menu.Pagination = MENU_NO_PAGINATION;

        int activeIndices[20]; int activeCount = 0;
        for (int i = 0; i < sizeof(g_attributeTable[CLASS_ENGINEER]); i++)
            if (!StrEqual(g_attributeTable[CLASS_ENGINEER][i].uid, "")) activeIndices[activeCount++] = i;

        int startIdx = isPage2 ? 7 : 0;
        int endIdx = isPage2 ? activeCount : 7;
        if (endIdx > activeCount) endIdx = activeCount;

        for (int j = startIdx; j < endIdx; j++)
        {
            int i = activeIndices[j];
            char buffer[128];
            Format(buffer, sizeof(buffer), "%s", g_attributeTable[CLASS_ENGINEER][i].title);
            if (g_attributeTable[CLASS_ENGINEER][i].isDisableDrawValue)
                Format(buffer, sizeof(buffer), buffer, g_attributeTable[CLASS_ENGINEER][i].point, g_playerAttributes[client][CLASS_ENGINEER][i].upgrade, g_attributeTable[CLASS_ENGINEER][i].max);
            else
                Format(buffer, sizeof(buffer), buffer, g_attributeTable[CLASS_ENGINEER][i].value, g_attributeTable[CLASS_ENGINEER][i].point, g_playerAttributes[client][CLASS_ENGINEER][i].upgrade, g_attributeTable[CLASS_ENGINEER][i].max);
            char key[64]; Format(key, sizeof(key), "engineer%d_%d", isPage2 ? 2 : 1, i);
            menu.AddItem(key, buffer);
        }
        int itemsOnPage = endIdx - startIdx;
        for (int j = itemsOnPage; j < 7; j++) menu.AddItem("", " ", ITEMDRAW_SPACER);
        menu.AddItem("back", "뒤로가기");
        if (isPage2) menu.AddItem("engineer_prev", "이전 페이지");
        else menu.AddItem("engineer_next", "다음 페이지");
    }
    else if (StrEqual(classID, "heavy") || StrEqual(classID, "heavy_2"))
    {
        bool isPage2 = StrEqual(classID, "heavy_2");
        if (isPage2) menu.SetTitle("헤비 (2/2)");
        else menu.SetTitle("헤비 (1/2)");
        menu.Pagination = MENU_NO_PAGINATION;

        int activeIndices[20]; int activeCount = 0;
        for (int i = 0; i < sizeof(g_attributeTable[CLASS_HEAVY]); i++)
            if (!StrEqual(g_attributeTable[CLASS_HEAVY][i].uid, "")) activeIndices[activeCount++] = i;

        int startIdx = isPage2 ? 7 : 0;
        int endIdx = isPage2 ? activeCount : 7;
        if (endIdx > activeCount) endIdx = activeCount;

        for (int j = startIdx; j < endIdx; j++)
        {
            int i = activeIndices[j];
            char buffer[128];
            Format(buffer, sizeof(buffer), "%s", g_attributeTable[CLASS_HEAVY][i].title);
            if (g_attributeTable[CLASS_HEAVY][i].isDisableDrawValue)
                Format(buffer, sizeof(buffer), buffer, g_attributeTable[CLASS_HEAVY][i].point, g_playerAttributes[client][CLASS_HEAVY][i].upgrade, g_attributeTable[CLASS_HEAVY][i].max);
            else
                Format(buffer, sizeof(buffer), buffer, g_attributeTable[CLASS_HEAVY][i].value, g_attributeTable[CLASS_HEAVY][i].point, g_playerAttributes[client][CLASS_HEAVY][i].upgrade, g_attributeTable[CLASS_HEAVY][i].max);
            char key[64]; Format(key, sizeof(key), "heavy%d_%d", isPage2 ? 2 : 1, i);
            menu.AddItem(key, buffer);
        }
        int itemsOnPage = endIdx - startIdx;
        for (int j = itemsOnPage; j < 7; j++) menu.AddItem("", " ", ITEMDRAW_SPACER);
        menu.AddItem("back", "뒤로가기");
        if (isPage2) menu.AddItem("heavy_prev", "이전 페이지");
        else menu.AddItem("heavy_next", "다음 페이지");
    }
    else if (StrEqual(classID, "hale"))
    {
        menu.SetTitle("헤일(사용불가)");

        for (int i = 0; i < sizeof(g_attributeTable[CLASS_HALE]); i++)
        {
            if (!StrEqual(g_attributeTable[CLASS_HALE][i].uid, ""))
            {
                char buffer[128];
                Format(buffer, sizeof(buffer), "%s", g_attributeTable[CLASS_HALE][i].title);
                if (g_attributeTable[CLASS_HALE][i].isDisableDrawValue)
                    Format(buffer, sizeof(buffer), buffer, g_attributeTable[CLASS_HALE][i].point, g_playerAttributes[client][CLASS_HALE][i].upgrade, g_attributeTable[CLASS_HALE][i].max);
                else
                    Format(buffer, sizeof(buffer), buffer, g_attributeTable[CLASS_HALE][i].value, g_attributeTable[CLASS_HALE][i].point, g_playerAttributes[client][CLASS_HALE][i].upgrade, g_attributeTable[CLASS_HALE][i].max);
                char key[64]; Format(key, sizeof(key), "hale_%s", g_attributeTable[CLASS_HALE][i].uid);
                menu.AddItem(key, buffer);
            }
        }
    }
    else if (StrEqual(classID, "shared"))
    {
        menu.SetTitle("공용");

        for (int i = 0; i < sizeof(g_attributeTable[CLASS_SHARED]); i++)
        {
            if (!StrEqual(g_attributeTable[CLASS_SHARED][i].uid, ""))
            {
                char buffer[128];
                Format(buffer, sizeof(buffer), "%s", g_attributeTable[CLASS_SHARED][i].title);
                if (g_attributeTable[CLASS_SHARED][i].isDisableDrawValue)
                    Format(buffer, sizeof(buffer), buffer, g_attributeTable[CLASS_SHARED][i].point, g_playerAttributes[client][CLASS_SHARED][i].upgrade, g_attributeTable[CLASS_SHARED][i].max);
                else
                    Format(buffer, sizeof(buffer), buffer, g_attributeTable[CLASS_SHARED][i].value, g_attributeTable[CLASS_SHARED][i].point, g_playerAttributes[client][CLASS_SHARED][i].upgrade, g_attributeTable[CLASS_SHARED][i].max);
                char key[64]; Format(key, sizeof(key), "shared_%s", g_attributeTable[CLASS_SHARED][i].uid);
                menu.AddItem(key, buffer);
            }
        }
    }

    // 수동 페이지네이션 클래스는 이미 back/nav/display 처리됨
    // hale, shared만 공통 back/display 사용
    bool isManualPagination = (
        StrEqual(classID, "scout") || StrEqual(classID, "scout_2") ||
        StrEqual(classID, "medic") || StrEqual(classID, "medic_2") ||
        StrEqual(classID, "soldier") || StrEqual(classID, "soldier_2") ||
        StrEqual(classID, "pyro") || StrEqual(classID, "pyro_2") ||
        StrEqual(classID, "spy") || StrEqual(classID, "spy_2") ||
        StrEqual(classID, "demoman") || StrEqual(classID, "demoman_2") ||
        StrEqual(classID, "sniper") || StrEqual(classID, "sniper_2") ||
        StrEqual(classID, "engineer") || StrEqual(classID, "engineer_2") ||
        StrEqual(classID, "heavy") || StrEqual(classID, "heavy_2")
    );

    if (!isManualPagination)
    {
        menu.AddItem("back", "상위 메뉴로 돌아가기");
    }

    menu.ExitButton = true;

    if (isManualPagination)
    {
        menu.Display(client, MENU_TIME_FOREVER);
    }
    else if (g_prevOpenMenuPage == -1)
    {
        menu.Display(client, MENU_TIME_FOREVER);
    }
    else
    {
        DisplayMenuAtItem(menu, client, g_prevOpenMenuPage, MENU_TIME_FOREVER);
    }

    g_prevOpenMenuPage = -1;
}

/**
 * 클래스 상세 스탯 메뉴 핸들러
 */
public int MenuHandler_ClassStatDetail(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_End)
    {
        delete menu;
    }
    else if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(item, info, sizeof(info));

        if (StrEqual(info, "back"))
        {
            Menu_ShowClassStat(client);
        }
        else if (StrEqual(info, "scout_next"))
        {
            Menu_ShowClassStatDetail(client, "scout_2");
        }
        else if (StrEqual(info, "scout_prev"))
        {
            Menu_ShowClassStatDetail(client, "scout");
        }
        else if (StrContains(info, "scout") != -1)
        {
            // 키에서 페이지와 배열 인덱스 파싱 (format: "scout1_<idx>" or "scout2_<idx>")
            bool wasPage2 = (info[5] == '2');
            char indexStr[8];
            strcopy(indexStr, sizeof(indexStr), info[7]); // "scoutN_" 이후 부분
            int idx = StringToInt(indexStr);

            if (g_attributeTable[CLASS_SCOUT][idx].max > g_playerAttributes[client][CLASS_SCOUT][idx].upgrade)
            {
                if (g_playerDataList[client].skillpoint >= g_attributeTable[CLASS_SCOUT][idx].point)
                {
                    g_playerDataList[client].skillpoint -= g_attributeTable[CLASS_SCOUT][idx].point;
                    g_playerAttributes[client][CLASS_SCOUT][idx].upgrade++;

                    // 즉시 저장
                    DB_SavePlayerData(client);
                    DB_SaveAllAttributes(client);

                    PrintToServer("스탯 찍음: Client %d - Scout[%d] upgrade=%d",
                                 client, idx, g_playerAttributes[client][CLASS_SCOUT][idx].upgrade);
                }
                else
                {
                    PrintToChat(client, "스킬 포인트가 모자라 강화할 수 없습니다.");
                }
            }

            Menu_ShowClassStatDetail(client, wasPage2 ? "scout_2" : "scout");
        }
        // ---- 페이지 네비게이션 ----
        else if (StrEqual(info, "medic_next")) { Menu_ShowClassStatDetail(client, "medic_2"); }
        else if (StrEqual(info, "medic_prev")) { Menu_ShowClassStatDetail(client, "medic"); }
        else if (StrEqual(info, "soldier_next")) { Menu_ShowClassStatDetail(client, "soldier_2"); }
        else if (StrEqual(info, "soldier_prev")) { Menu_ShowClassStatDetail(client, "soldier"); }
        else if (StrEqual(info, "pyro_next")) { Menu_ShowClassStatDetail(client, "pyro_2"); }
        else if (StrEqual(info, "pyro_prev")) { Menu_ShowClassStatDetail(client, "pyro"); }
        else if (StrEqual(info, "spy_next")) { Menu_ShowClassStatDetail(client, "spy_2"); }
        else if (StrEqual(info, "spy_prev")) { Menu_ShowClassStatDetail(client, "spy"); }
        else if (StrEqual(info, "demoman_next")) { Menu_ShowClassStatDetail(client, "demoman_2"); }
        else if (StrEqual(info, "demoman_prev")) { Menu_ShowClassStatDetail(client, "demoman"); }
        else if (StrEqual(info, "sniper_next")) { Menu_ShowClassStatDetail(client, "sniper_2"); }
        else if (StrEqual(info, "sniper_prev")) { Menu_ShowClassStatDetail(client, "sniper"); }
        else if (StrEqual(info, "engineer_next")) { Menu_ShowClassStatDetail(client, "engineer_2"); }
        else if (StrEqual(info, "engineer_prev")) { Menu_ShowClassStatDetail(client, "engineer"); }
        else if (StrEqual(info, "heavy_next")) { Menu_ShowClassStatDetail(client, "heavy_2"); }
        else if (StrEqual(info, "heavy_prev")) { Menu_ShowClassStatDetail(client, "heavy"); }
        // ---- 메딕 스탯 업그레이드 (키: "medicN_<idx>") ----
        else if (StrContains(info, "medic") != -1)
        {
            bool wasPage2 = (info[5] == '2');
            char indexStr[8]; strcopy(indexStr, sizeof(indexStr), info[7]);
            int idx = StringToInt(indexStr);

            if (g_attributeTable[CLASS_MEDIC][idx].max > g_playerAttributes[client][CLASS_MEDIC][idx].upgrade)
            {
                if (g_playerDataList[client].skillpoint >= g_attributeTable[CLASS_MEDIC][idx].point)
                {
                    g_playerDataList[client].skillpoint -= g_attributeTable[CLASS_MEDIC][idx].point;
                    g_playerAttributes[client][CLASS_MEDIC][idx].upgrade++;
                    DB_SavePlayerData(client);
                    DB_SaveAllAttributes(client);
                    PrintToServer("스탯 찍음: Client %d - Medic[%d] upgrade=%d", client, idx, g_playerAttributes[client][CLASS_MEDIC][idx].upgrade);
                }
                else { PrintToChat(client, "스킬 포인트가 모자라 강화할 수 없습니다."); }
            }
            Menu_ShowClassStatDetail(client, wasPage2 ? "medic_2" : "medic");
        }
        // ---- 솔져 스탯 업그레이드 (키: "soldierN_<idx>") ----
        else if (StrContains(info, "soldier") != -1)
        {
            bool wasPage2 = (info[7] == '2');
            char indexStr[8]; strcopy(indexStr, sizeof(indexStr), info[9]);
            int idx = StringToInt(indexStr);

            if (g_attributeTable[CLASS_SOLDIER][idx].max > g_playerAttributes[client][CLASS_SOLDIER][idx].upgrade)
            {
                if (g_playerDataList[client].skillpoint >= g_attributeTable[CLASS_SOLDIER][idx].point)
                {
                    g_playerDataList[client].skillpoint -= g_attributeTable[CLASS_SOLDIER][idx].point;
                    g_playerAttributes[client][CLASS_SOLDIER][idx].upgrade++;
                    DB_SavePlayerData(client);
                    DB_SaveAllAttributes(client);
                    PrintToServer("스탯 찍음: Client %d - Soldier[%d] upgrade=%d", client, idx, g_playerAttributes[client][CLASS_SOLDIER][idx].upgrade);
                }
                else { PrintToChat(client, "스킬 포인트가 모자라 강화할 수 없습니다."); }
            }
            Menu_ShowClassStatDetail(client, wasPage2 ? "soldier_2" : "soldier");
        }
        // ---- 파이로 스탯 업그레이드 (키: "pyroN_<idx>") ----
        else if (StrContains(info, "pyro") != -1)
        {
            bool wasPage2 = (info[4] == '2');
            char indexStr[8]; strcopy(indexStr, sizeof(indexStr), info[6]);
            int idx = StringToInt(indexStr);

            if (g_attributeTable[CLASS_PYRO][idx].max > g_playerAttributes[client][CLASS_PYRO][idx].upgrade)
            {
                if (g_playerDataList[client].skillpoint >= g_attributeTable[CLASS_PYRO][idx].point)
                {
                    g_playerDataList[client].skillpoint -= g_attributeTable[CLASS_PYRO][idx].point;
                    g_playerAttributes[client][CLASS_PYRO][idx].upgrade++;
                    DB_SavePlayerData(client);
                    DB_SaveAllAttributes(client);
                    PrintToServer("스탯 찍음: Client %d - Pyro[%d] upgrade=%d", client, idx, g_playerAttributes[client][CLASS_PYRO][idx].upgrade);
                }
                else { PrintToChat(client, "스킬 포인트가 모자라 강화할 수 없습니다."); }
            }
            Menu_ShowClassStatDetail(client, wasPage2 ? "pyro_2" : "pyro");
        }
        // ---- 스파이 스탯 업그레이드 (키: "spyN_<idx>") ----
        else if (StrContains(info, "spy") != -1)
        {
            bool wasPage2 = (info[3] == '2');
            char indexStr[8]; strcopy(indexStr, sizeof(indexStr), info[5]);
            int idx = StringToInt(indexStr);

            if (g_attributeTable[CLASS_SPY][idx].max > g_playerAttributes[client][CLASS_SPY][idx].upgrade)
            {
                if (g_playerDataList[client].skillpoint >= g_attributeTable[CLASS_SPY][idx].point)
                {
                    g_playerDataList[client].skillpoint -= g_attributeTable[CLASS_SPY][idx].point;
                    g_playerAttributes[client][CLASS_SPY][idx].upgrade++;
                    DB_SavePlayerData(client);
                    DB_SaveAllAttributes(client);
                    PrintToServer("스탯 찍음: Client %d - Spy[%d] upgrade=%d", client, idx, g_playerAttributes[client][CLASS_SPY][idx].upgrade);
                }
                else { PrintToChat(client, "스킬 포인트가 모자라 강화할 수 없습니다."); }
            }
            Menu_ShowClassStatDetail(client, wasPage2 ? "spy_2" : "spy");
        }
        // ---- 데모맨 스탯 업그레이드 (키: "demomanN_<idx>") ----
        else if (StrContains(info, "demoman") != -1)
        {
            bool wasPage2 = (info[7] == '2');
            char indexStr[8]; strcopy(indexStr, sizeof(indexStr), info[9]);
            int idx = StringToInt(indexStr);

            if (g_attributeTable[CLASS_DEMOMAN][idx].max > g_playerAttributes[client][CLASS_DEMOMAN][idx].upgrade)
            {
                if (g_playerDataList[client].skillpoint >= g_attributeTable[CLASS_DEMOMAN][idx].point)
                {
                    g_playerDataList[client].skillpoint -= g_attributeTable[CLASS_DEMOMAN][idx].point;
                    g_playerAttributes[client][CLASS_DEMOMAN][idx].upgrade++;
                    DB_SavePlayerData(client);
                    DB_SaveAllAttributes(client);
                    PrintToServer("스탯 찍음: Client %d - Demoman[%d] upgrade=%d", client, idx, g_playerAttributes[client][CLASS_DEMOMAN][idx].upgrade);
                }
                else { PrintToChat(client, "스킬 포인트가 모자라 강화할 수 없습니다."); }
            }
            Menu_ShowClassStatDetail(client, wasPage2 ? "demoman_2" : "demoman");
        }
        // ---- 스나이퍼 스탯 업그레이드 (키: "sniperN_<idx>") ----
        else if (StrContains(info, "sniper") != -1)
        {
            bool wasPage2 = (info[6] == '2');
            char indexStr[8]; strcopy(indexStr, sizeof(indexStr), info[8]);
            int idx = StringToInt(indexStr);

            if (g_attributeTable[CLASS_SNIPER][idx].max > g_playerAttributes[client][CLASS_SNIPER][idx].upgrade)
            {
                if (g_playerDataList[client].skillpoint >= g_attributeTable[CLASS_SNIPER][idx].point)
                {
                    g_playerDataList[client].skillpoint -= g_attributeTable[CLASS_SNIPER][idx].point;
                    g_playerAttributes[client][CLASS_SNIPER][idx].upgrade++;
                    DB_SavePlayerData(client);
                    DB_SaveAllAttributes(client);
                    PrintToServer("스탯 찍음: Client %d - Sniper[%d] upgrade=%d", client, idx, g_playerAttributes[client][CLASS_SNIPER][idx].upgrade);
                }
                else { PrintToChat(client, "스킬 포인트가 모자라 강화할 수 없습니다."); }
            }
            Menu_ShowClassStatDetail(client, wasPage2 ? "sniper_2" : "sniper");
        }
        // ---- 엔지니어 스탯 업그레이드 (키: "engineerN_<idx>") ----
        else if (StrContains(info, "engineer") != -1)
        {
            bool wasPage2 = (info[8] == '2');
            char indexStr[8]; strcopy(indexStr, sizeof(indexStr), info[10]);
            int idx = StringToInt(indexStr);

            if (g_attributeTable[CLASS_ENGINEER][idx].max > g_playerAttributes[client][CLASS_ENGINEER][idx].upgrade)
            {
                if (g_playerDataList[client].skillpoint >= g_attributeTable[CLASS_ENGINEER][idx].point)
                {
                    g_playerDataList[client].skillpoint -= g_attributeTable[CLASS_ENGINEER][idx].point;
                    g_playerAttributes[client][CLASS_ENGINEER][idx].upgrade++;
                    DB_SavePlayerData(client);
                    DB_SaveAllAttributes(client);
                    PrintToServer("스탯 찍음: Client %d - Engineer[%d] upgrade=%d", client, idx, g_playerAttributes[client][CLASS_ENGINEER][idx].upgrade);
                }
                else { PrintToChat(client, "스킬 포인트가 모자라 강화할 수 없습니다."); }
            }
            Menu_ShowClassStatDetail(client, wasPage2 ? "engineer_2" : "engineer");
        }
        // ---- 헤비 스탯 업그레이드 (키: "heavyN_<idx>") ----
        else if (StrContains(info, "heavy") != -1)
        {
            bool wasPage2 = (info[5] == '2');
            char indexStr[8]; strcopy(indexStr, sizeof(indexStr), info[7]);
            int idx = StringToInt(indexStr);

            if (g_attributeTable[CLASS_HEAVY][idx].max > g_playerAttributes[client][CLASS_HEAVY][idx].upgrade)
            {
                if (g_playerDataList[client].skillpoint >= g_attributeTable[CLASS_HEAVY][idx].point)
                {
                    g_playerDataList[client].skillpoint -= g_attributeTable[CLASS_HEAVY][idx].point;
                    g_playerAttributes[client][CLASS_HEAVY][idx].upgrade++;
                    DB_SavePlayerData(client);
                    DB_SaveAllAttributes(client);
                    PrintToServer("스탯 찍음: Client %d - Heavy[%d] upgrade=%d", client, idx, g_playerAttributes[client][CLASS_HEAVY][idx].upgrade);
                }
                else { PrintToChat(client, "스킬 포인트가 모자라 강화할 수 없습니다."); }
            }
            Menu_ShowClassStatDetail(client, wasPage2 ? "heavy_2" : "heavy");
        }
        // ---- 헤일 (수동 페이지네이션 없음, 원래 방식) ----
        else if (StrContains(info, "hale") != -1)
        {
            if (g_attributeTable[CLASS_HALE][item].max > g_playerAttributes[client][CLASS_HALE][item].upgrade)
            {
                if (g_playerDataList[client].skillpoint >= g_attributeTable[CLASS_HALE][item].point)
                {
                    g_playerDataList[client].skillpoint -= g_attributeTable[CLASS_HALE][item].point;
                    g_playerAttributes[client][CLASS_HALE][item].upgrade++;
                    DB_SavePlayerData(client);
                    DB_SaveAllAttributes(client);
                    PrintToServer("스탯 찍음: Client %d - Hale[%d] upgrade=%d", client, item, g_playerAttributes[client][CLASS_HALE][item].upgrade);
                }
                else { PrintToChat(client, "스킬 포인트가 모자라 강화할 수 없습니다."); }
            }
            g_prevOpenMenuPage = GetMenuSelectionPosition();
            Menu_ShowClassStatDetail(client, "hale");
        }
        // ---- 공용 (수동 페이지네이션 없음, 원래 방식) ----
        else if (StrContains(info, "shared") != -1)
        {
            if (g_attributeTable[CLASS_SHARED][item].max > g_playerAttributes[client][CLASS_SHARED][item].upgrade)
            {
                if (g_playerDataList[client].skillpoint >= g_attributeTable[CLASS_SHARED][item].point)
                {
                    g_playerDataList[client].skillpoint -= g_attributeTable[CLASS_SHARED][item].point;
                    g_playerAttributes[client][CLASS_SHARED][item].upgrade++;
                    DB_SavePlayerData(client);
                    DB_SaveAllAttributes(client);
                    PrintToServer("스탯 찍음: Client %d - Shared[%d] upgrade=%d", client, item, g_playerAttributes[client][CLASS_SHARED][item].upgrade);
                }
                else { PrintToChat(client, "스킬 포인트가 모자라 강화할 수 없습니다."); }
            }
            g_prevOpenMenuPage = GetMenuSelectionPosition();
            Menu_ShowClassStatDetail(client, "shared");
        }
    }

    return 0;
}

// ============================================================================
// 부활 메뉴
// ============================================================================

/**
 * 부활 메뉴를 표시
 * @param client    클라이언트 인덱스
 */
void Menu_ShowRevive(int client)
{
    int team = GetClientTeam(client);

    if (team == 3)
        return;

    Menu menu = CreateMenu(MenuHandler_Revive);

    char titleBuffer[512];
    Format(titleBuffer, sizeof(titleBuffer),
           "헤일 모드 - 부활 메뉴\n―――――――――――――――――\n현재 사용가능한 포인트 : %d\n―――――――――――――――――\n포인트를 사용하면 즉시 부활합니다.\n라운드 시간이 지나거나 부활하면 가격이 비싸집니다.",
           g_playerDataList[client].point);
    menu.SetTitle(titleBuffer);

    char pointBuffer[128];
    Format(pointBuffer, sizeof(pointBuffer), "%d원으로 부활합니다.(%d회 남음)",
           g_playerDataList[client].revivePoint, g_playerDataList[client].reviveCount);

    menu.AddItem("accept", pointBuffer);
    menu.AddItem("cancel", "부활하지 않습니다.");

    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

/**
 * 부활 메뉴 핸들러
 */
public int MenuHandler_Revive(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_End)
    {
        delete menu;
    }
    else if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(item, info, sizeof(info));

        if (StrEqual(info, "accept"))
        {
			Revive_DoRevive(client);
        }
        else if (StrEqual(info, "cancel"))
        {
            delete menu;
        }
    }

    return 0;
}

// ============================================================================
// 스킬 초기화 메뉴
// ============================================================================

/**
 * 스킬 초기화 메뉴를 표시
 * @param client    클라이언트 인덱스
 */
void Menu_ShowSkillReset(int client)
{
    Menu menu = CreateMenu(MenuHandler_SkillReset);

    char titleBuffer[512];
    Format(titleBuffer, sizeof(titleBuffer),
           "헤일 모드 - 스킬 초기화\n―――――――――――――――――\n―――――――――――――――――\n포인트를 사용하면 스킬을 초기화합니다.\n",
           g_playerDataList[client].point);
    menu.SetTitle(titleBuffer);

    char pointBuffer[128];
    Format(pointBuffer, sizeof(pointBuffer), "%d원으로 초기화합니다.", SKILL_RESET_POINT);

    menu.AddItem("accept", pointBuffer);
    menu.AddItem("cancel", "초기화하지 않습니다.");

    menu.AddItem("back", "상위 메뉴로 돌아가기");

    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

/**
 * 스킬 초기화 메뉴 핸들러
 */
public int MenuHandler_SkillReset(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_End)
    {
        delete menu;
    }
    else if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(item, info, sizeof(info));

        if (StrEqual(info, "accept"))
        {
            if (g_playerDataList[client].point < SKILL_RESET_POINT)
            {
                PrintToChat(client, "포인트가 부족합니다!");
                return 0;
            }

            PlayerData_TakePoint(client, SKILL_RESET_POINT);

            // 모든 클래스의 스탯 초기화
            for (int i = 0; i < sizeof(g_playerAttributes[client][CLASS_SCOUT]); i++)
            {
                g_playerAttributes[client][CLASS_SCOUT][i].upgrade = 0;
            }

            for (int i = 0; i < sizeof(g_playerAttributes[client][CLASS_MEDIC]); i++)
            {
                g_playerAttributes[client][CLASS_MEDIC][i].upgrade = 0;
            }

            for (int i = 0; i < sizeof(g_playerAttributes[client][CLASS_SOLDIER]); i++)
            {
                g_playerAttributes[client][CLASS_SOLDIER][i].upgrade = 0;
            }

            for (int i = 0; i < sizeof(g_playerAttributes[client][CLASS_PYRO]); i++)
            {
                g_playerAttributes[client][CLASS_PYRO][i].upgrade = 0;
            }

            for (int i = 0; i < sizeof(g_playerAttributes[client][CLASS_SPY]); i++)
            {
                g_playerAttributes[client][CLASS_SPY][i].upgrade = 0;
            }

            for (int i = 0; i < sizeof(g_playerAttributes[client][CLASS_DEMOMAN]); i++)
            {
                g_playerAttributes[client][CLASS_DEMOMAN][i].upgrade = 0;
            }

            for (int i = 0; i < sizeof(g_playerAttributes[client][CLASS_SNIPER]); i++)
            {
                g_playerAttributes[client][CLASS_SNIPER][i].upgrade = 0;
            }

            for (int i = 0; i < sizeof(g_playerAttributes[client][CLASS_ENGINEER]); i++)
            {
                g_playerAttributes[client][CLASS_ENGINEER][i].upgrade = 0;
            }

            for (int i = 0; i < sizeof(g_playerAttributes[client][CLASS_HEAVY]); i++)
            {
               g_playerAttributes[client][CLASS_HEAVY][i].upgrade = 0;
            }

            for (int i = 0; i < sizeof(g_playerAttributes[client][CLASS_HALE]); i++)
            {
                g_playerAttributes[client][CLASS_HALE][i].upgrade = 0;
            }

            for (int i = 0; i < sizeof(g_playerAttributes[client][CLASS_SHARED]); i++)
            {
                g_playerAttributes[client][CLASS_SHARED][i].upgrade = 0;
            }

            // 스킬 포인트 재계산
            g_playerDataList[client].skillpoint = 0;
            g_playerDataList[client].skillpoint += g_playerDataList[client].level * 3;

            PrintToChat(client, "스킬이 초기화되었습니다!");
        }
        else if (StrEqual(info, "cancel"))
        {
            // 아무것도 하지 않음
        }
    }

    return 0;
}

// ============================================================================
// 무기 강화 메뉴
// ============================================================================

/**
 * 무기 강화 메뉴를 표시
 * @param client    클라이언트 인덱스
 */
void Menu_ShowWeaponUpgrade(int client)
{
    Menu menu = CreateMenu(MenuHandler_WeaponUpgrade);

    char titleBuffer[1024];
    Format(titleBuffer, sizeof(titleBuffer),
           "헤일 모드 - 강화 메뉴\n―――――――――――――――――\n현재 사용가능한 포인트 : %d\n―――――――――――――――――\n현재 강화 %d -> %d로 강화\n강화 성공 %.0f%%\n강화 실패 %.0f%%\n강화 파괴 %.0f%%\n―――――――――――――――――\n강화 하시겠습니까?",
           g_playerDataList[client].point,
           g_playerAttributes[client][CLASS_WEAPON][0].upgrade,
           g_playerAttributes[client][CLASS_WEAPON][0].upgrade + 1,
           WEAPON_SUCCESS_TABLE[g_playerAttributes[client][CLASS_WEAPON][0].upgrade] * float(100),
           WEAPON_MISS_TABLE[g_playerAttributes[client][CLASS_WEAPON][0].upgrade] * float(100),
           WEAPON_RESET_TABLE[g_playerAttributes[client][CLASS_WEAPON][0].upgrade] * float(100));
    menu.SetTitle(titleBuffer);

    char yesBuffer[128];
    Format(yesBuffer, sizeof(yesBuffer), "예(%d)",
           WEAPON_COST_TABLE[g_playerAttributes[client][CLASS_WEAPON][0].upgrade]);

    menu.AddItem("accept", yesBuffer);
    menu.AddItem("cancel", "아니오");

    menu.AddItem("back", "상위 메뉴로 돌아가기");

    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

/**
 * 무기 강화 메뉴 핸들러
 */
public int MenuHandler_WeaponUpgrade(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_End)
    {
        delete menu;
    }
    else if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(item, info, sizeof(info));

        if (StrEqual(info, "accept"))
        {
            int upgrade = g_playerAttributes[client][CLASS_WEAPON][0].upgrade;

            if (g_playerDataList[client].point < WEAPON_COST_TABLE[upgrade])
            {
                PrintToChat(client, "포인트가 부족합니다!");
                return 0;
            }

            PrintCenterText(client, "강화 중 ...");
            PrintToChat(client, "강화 중 ...");
            EmitSoundToClient(client, "misc/reinforcement.mp3", _, _, SNDLEVEL_RAIDSIREN);
            CreateTimer(5.5, Timer_WeaponUpgrade, client);
        }
        else if (StrEqual(info, "back"))
        {
            Menu_ShowMain(client);
        }
    }

    return 0;
}

/**
 * 무기 강화 타이머 콜백
 */
public Action Timer_WeaponUpgrade(Handle timer, any client)
{
    if (!IsClientInGame(client))
    {
        return Plugin_Continue;
    }

    int upgrade = g_playerAttributes[client][CLASS_WEAPON][0].upgrade;
    int random = GetRandomInt(1, 100);

    int successPercent = RoundToFloor(WEAPON_SUCCESS_TABLE[upgrade] * float(100));
    int missPercent = RoundToFloor(WEAPON_MISS_TABLE[upgrade] * float(100));
    int resetPercent = RoundToFloor(WEAPON_RESET_TABLE[upgrade] * float(100));

    PlayerData_TakePoint(client, WEAPON_COST_TABLE[upgrade]);

    char upgradeText[256];

    if (random <= successPercent)
    {
        // 성공
        Format(upgradeText, sizeof(upgradeText),
               "%d번째 강화에 성공하였습니다.", upgrade + 1);
        PrintToChat(client, upgradeText);
        PrintCenterText(client, upgradeText);

        if (upgrade + 1 >= 7)
        {
            Format(upgradeText, sizeof(upgradeText),
                   "%s님이 %d번째 강화에 성공했습니다.", g_playerDataList[client].basenick, upgrade + 1);
            PrintToChat(client, upgradeText);

            for (int i = 1; i <= MaxClients; i++)
            {
                if (!IsClientInGame(i) || IsFakeClient(i))
                {
                    continue;
                }

                PrintCenterText(i, upgradeText);
            }

            EmitSoundToAll("misc/success1.mp3");
        }
        else
        {
            EmitSoundToClient(client, "misc/success1.mp3", _, _, SNDLEVEL_RAIDSIREN);
        }

        g_playerAttributes[client][CLASS_WEAPON][0].upgrade++;
    }
    else
    {
        random -= successPercent;

        if (random <= missPercent)
        {
            // 실패
            Format(upgradeText, sizeof(upgradeText),
                   "%d번째 강화에 실패했습니다.", upgrade + 1);
            PrintToChat(client, upgradeText);
            PrintCenterText(client, upgradeText);

            if (upgrade + 1 >= 7)
            {
                Format(upgradeText, sizeof(upgradeText),
                       "%s님이 %d번째 강화에 실패했습니다.", g_playerDataList[client].basenick, upgrade + 1);

                for (int i = 1; i <= MaxClients; i++)
                {
                    if (!IsClientInGame(i) || IsFakeClient(i))
                    {
                        continue;
                    }

                    PrintCenterText(i, upgradeText);
                }

                EmitSoundToAll("misc/miss1.mp3");
            }
            else
            {
                EmitSoundToClient(client, "misc/miss1.mp3", _, _, SNDLEVEL_RAIDSIREN);
            }
        }
        else
        {
            // 대실패 (파괴)
            if (resetPercent > 0)
            {
                Format(upgradeText, sizeof(upgradeText),
                       "%d번째 강화에 대실패했습니다.", upgrade + 1);
                PrintToChat(client, upgradeText);
                PrintCenterText(client, upgradeText);

                if (upgrade + 1 >= 7)
                {
                    Format(upgradeText, sizeof(upgradeText),
                           "%s님이 %d번째 강화에 대실패했습니다.", g_playerDataList[client].basenick, upgrade + 1);

                    for (int i = 1; i <= MaxClients; i++)
                    {
                        if (!IsClientInGame(i) || IsFakeClient(i))
                        {
                            continue;
                        }

                        PrintCenterText(i, upgradeText);
                    }

                    EmitSoundToAll("misc/reset1.mp3");
                }
                else
                {
                    EmitSoundToClient(client, "misc/reset1.mp3", _, _, SNDLEVEL_RAIDSIREN);
                }

                // 강화 레벨 초기화
                g_playerAttributes[client][CLASS_WEAPON][0].upgrade = 0;
            }
        }
    }

    return Plugin_Continue;
}
