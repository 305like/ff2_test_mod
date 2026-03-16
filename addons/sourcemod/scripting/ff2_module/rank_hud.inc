#if defined _ff2_rank_hud_included
	#endinput
#endif
#define _ff2_rank_hud_included

// Rank HUD - 데미지 순위 표시 (rank_hud.sp 에서 변환)

int g_currentDamageRank[MAXPLAYERS+1];

void RankHud_Init()
{
	CreateTimer(0.1, RankHud_UpdateTimer, _, TIMER_REPEAT);

	LoadTranslations("ff2_just_hud_thing.phrases");
}

public Action RankHud_UpdateTimer(Handle timer)
{
	if(!IsFF2Enabled() || CheckRoundState() != FF2RoundState_RoundRunning)
		return Plugin_Continue;

	RankHud_UpdateDamageRank();
	return Plugin_Continue;
}

void RankHud_OnCalledQueue(FF2HudQueue hudQueue, int client)
{
	SetGlobalTransTarget(client);

	int ranking;
	char text[256];
	FF2HudDisplay hudDisplay = null;
	hudQueue.GetName(text, sizeof(text));

	RankHud_UpdateDamageRank();

	if(StrEqual(text, "Player"))
	{
		ranking = RankHud_GetClientRanking(client);
		RankHud_GetClientRankingString(ranking, text, sizeof(text));

		Format(text, sizeof(text), "%t: %s ", "Rank", text);
		if(ranking != -1)
			Format(text, sizeof(text), "%s(↑ %d, ↓%d)", text, RankHud_GetRankingGap(ranking, ranking-1), RankHud_GetRankingGap(ranking, ranking+1));

		hudDisplay = FF2HudDisplay.CreateDisplay("Your Rank", text);
		hudQueue.AddHud(hudDisplay, client);
	}
	else if(StrEqual(text, "Observer"))
	{
		int observer = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
		if(!IsBoss(observer))
		{
			ranking = RankHud_GetClientRanking(observer);
			RankHud_GetClientRankingString(ranking, text, sizeof(text));

			Format(text, sizeof(text), "%t: %s ", "Rank", text);
			if(ranking != -1)
				Format(text, sizeof(text), "%s(↑ %d, ↓%d)", text, RankHud_GetRankingGap(ranking, ranking-1), RankHud_GetRankingGap(ranking, ranking+1));

			hudDisplay = FF2HudDisplay.CreateDisplay("Observer Target Player Rank", text);
			hudQueue.AddHud(hudDisplay, client, observer);
		}
	}
}

void RankHud_GetClientRankingString(int rankingPos, char[] text, int bufferLength)
{
	if(rankingPos >= 0)
		Format(text, bufferLength, "%d", rankingPos + 1);
	else
		Format(text, bufferLength, "??");
}

int RankHud_GetRankingGap(int ranking, int targetRanking)
{
	if(ranking < 0 || targetRanking < 0 || ranking == targetRanking
		|| !IsValidClient(g_currentDamageRank[ranking]) || !IsValidClient(g_currentDamageRank[targetRanking]))
		return 0;

	int result = GetClientDamage(g_currentDamageRank[ranking]) - GetClientDamage(g_currentDamageRank[targetRanking]);
	return result > 0 ? result : result * -1;
}

int RankHud_GetClientRanking(int client)
{
	for(int loop = 0; loop < MAXPLAYERS + 1; loop++)
	{
		if(g_currentDamageRank[loop] == client)
			return loop;
	}

	return -1;
}

void RankHud_UpdateDamageRank()
{
	int tempTop[MAXPLAYERS+1];
	TFTeam bossTeam = BossTeam;

	RankHud_CopyArray(tempTop, 0, MAXPLAYERS, g_currentDamageRank);

	for(int client = 1; client <= MaxClients; client++)
	{
		tempTop[client] = 0;

		if(!IsClientInGame(client) || (IsBoss(client) && TF2_GetClientTeam(client) == bossTeam))
			continue;

		tempTop[client] = GetClientDamage(client);
	}

	SortIntegers(tempTop, MAXPLAYERS+1, Sort_Descending);

	for(int client = 0; client <= MAXPLAYERS; client++)
	{
		for(int target = 1; target <= MaxClients; target++)
		{
			if(!IsClientInGame(target) || (IsBoss(target) && TF2_GetClientTeam(target) == bossTeam))
				continue;

			if(tempTop[client] == GetClientDamage(target))
			{
				g_currentDamageRank[client] = target;
				break;
			}
		}
	}
}

void RankHud_CopyArray(int[] array, int startPos, int endPos, int[] vicArray)
{
	for(int loop = startPos; loop == endPos; endPos > startPos ? loop-- : loop++)
	{
		vicArray[loop] = array[loop];
	}
}
