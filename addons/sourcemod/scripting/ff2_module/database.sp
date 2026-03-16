#define FF2_PLAYERDATA_PATH "data/ff2_playerdata"

enum FF2DataType
{
	FF2Data_Int = 0,
	FF2Data_Float,
	FF2Data_String
};

static KeyValues g_hPlayerData[MAXPLAYERS+1];

stock void FF2DB_OnClientConnected(int client)
{
	delete g_hPlayerData[client];
	g_hPlayerData[client] = null;
}

stock void FF2DB_LoadPlayerData(int client)
{
	if(IsFakeClient(client))
		return;

	char authId[32], filePath[PLATFORM_MAX_PATH];
	GetClientAuthId(client, AuthId_Steam2, authId, sizeof(authId));
	ReplaceString(authId, sizeof(authId), ":", "_");

	BuildPath(Path_SM, filePath, sizeof(filePath), "%s/%s.cfg", FF2_PLAYERDATA_PATH, authId);

	delete g_hPlayerData[client];
	g_hPlayerData[client] = new KeyValues("PlayerData");

	if(FileExists(filePath))
	{
		g_hPlayerData[client].ImportFromFile(filePath);
	}
}

stock void FF2DB_SavePlayerData(int client)
{
	if(g_hPlayerData[client] == null)
		return;

	char authId[32], filePath[PLATFORM_MAX_PATH], dirPath[PLATFORM_MAX_PATH];
	GetClientAuthId(client, AuthId_Steam2, authId, sizeof(authId));
	ReplaceString(authId, sizeof(authId), ":", "_");

	BuildPath(Path_SM, dirPath, sizeof(dirPath), FF2_PLAYERDATA_PATH);
	if(!DirExists(dirPath))
	{
		CreateDirectory(dirPath, 0o755);
	}

	BuildPath(Path_SM, filePath, sizeof(filePath), "%s/%s.cfg", FF2_PLAYERDATA_PATH, authId);
	g_hPlayerData[client].ExportToFile(filePath);
}

stock void FF2DB_OnClientDisconnect(int client)
{
	FF2DB_SavePlayerData(client);
	delete g_hPlayerData[client];
	g_hPlayerData[client] = null;
}

// --- Settings ---

stock void FF2DB_GetSettingString(int client, const char[] settingId, char[] value, int buffer)
{
	if(g_hPlayerData[client] == null)
	{
		value[0] = '\0';
		return;
	}

	g_hPlayerData[client].Rewind();
	if(g_hPlayerData[client].JumpToKey("settings", true))
	{
		g_hPlayerData[client].GetString(settingId, value, buffer, "");
	}
	else
	{
		value[0] = '\0';
	}
	g_hPlayerData[client].Rewind();
}

stock void FF2DB_SetSettingString(int client, const char[] settingId, const char[] value)
{
	if(g_hPlayerData[client] == null)
		return;

	g_hPlayerData[client].Rewind();
	if(g_hPlayerData[client].JumpToKey("settings", true))
	{
		g_hPlayerData[client].SetString(settingId, value);
	}
	g_hPlayerData[client].Rewind();
	FF2DB_SavePlayerData(client);
}

// --- HUD ---

stock int FF2DB_GetHudSetting(int client, const char[] hudId)
{
	if(g_hPlayerData[client] == null)
		return 0;

	g_hPlayerData[client].Rewind();
	if(g_hPlayerData[client].JumpToKey("hud", true))
	{
		if(g_hPlayerData[client].JumpToKey(hudId, true))
		{
			int val = g_hPlayerData[client].GetNum("value", 0);
			g_hPlayerData[client].Rewind();
			return val;
		}
	}
	g_hPlayerData[client].Rewind();
	return 0;
}

stock void FF2DB_SetHudSetting(int client, const char[] hudId, int value)
{
	if(g_hPlayerData[client] == null)
		return;

	char timeStr[32];
	FormatTime(timeStr, sizeof(timeStr), "%Y-%m-%d %H:%M:%S", GetTime());

	g_hPlayerData[client].Rewind();
	if(g_hPlayerData[client].JumpToKey("hud", true))
	{
		if(g_hPlayerData[client].JumpToKey(hudId, true))
		{
			g_hPlayerData[client].SetNum("value", value);
			g_hPlayerData[client].SetString("last_saved", timeStr);
		}
	}
	g_hPlayerData[client].Rewind();
	FF2DB_SavePlayerData(client);
}

// --- Music ---

stock int FF2DB_GetMusicSetting(int client, const char[] musicId)
{
	if(g_hPlayerData[client] == null)
		return 0;

	g_hPlayerData[client].Rewind();
	if(g_hPlayerData[client].JumpToKey("music", true))
	{
		if(g_hPlayerData[client].JumpToKey(musicId, true))
		{
			int val = g_hPlayerData[client].GetNum("value", 0);
			g_hPlayerData[client].Rewind();
			return val;
		}
	}
	g_hPlayerData[client].Rewind();
	return 0;
}

stock void FF2DB_SetMusicSetting(int client, const char[] musicId, int value)
{
	if(g_hPlayerData[client] == null)
		return;

	char timeStr[32];
	FormatTime(timeStr, sizeof(timeStr), "%Y-%m-%d %H:%M:%S", GetTime());

	g_hPlayerData[client].Rewind();
	if(g_hPlayerData[client].JumpToKey("music", true))
	{
		if(g_hPlayerData[client].JumpToKey(musicId, true))
		{
			g_hPlayerData[client].SetNum("value", value);
			g_hPlayerData[client].SetString("last_saved", timeStr);
		}
	}
	g_hPlayerData[client].Rewind();
	FF2DB_SavePlayerData(client);
}
