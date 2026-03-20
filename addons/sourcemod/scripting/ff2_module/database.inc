#if defined _ff2_database_included
    #endinput
#endif
#define _ff2_database_included

/**
 * FF2 Database Management
 * SQLite database layer with StringMap caching.
 */

#define FF2_DB_CONFIG "ff2"

#if !defined _ff2_db_included
enum FF2DataType
{
	FF2Data_Int = 0,
	FF2Data_Float,
	FF2Data_String
};
#endif

// db_simple 호환용 별칭
#define DBSDataTypes FF2DataType
#define DBSData_Int FF2Data_Int
#define DBSData_Float FF2Data_Float
#define DBSData_String FF2Data_String

static Database g_hDB = null;

static StringMap g_hPlayerSettings[MAXPLAYERS+1];
static StringMap g_hPlayerHud[MAXPLAYERS+1];
static StringMap g_hPlayerMusic[MAXPLAYERS+1];

void FF2DB_Init()
{
	char error[256];
	g_hDB = SQL_Connect(FF2_DB_CONFIG, true, error, sizeof(error));

	if(g_hDB == null)
	{
		LogError("[FF2] Database connection failed: %s", error);
		return;
	}

	g_hDB.Query(DB_GenericCallback,
		"CREATE TABLE IF NOT EXISTS ff2_player_setting ("
		... "steam_id VARCHAR(32) NOT NULL, "
		... "setting_id VARCHAR(64) NOT NULL, "
		... "value VARCHAR(128) NOT NULL DEFAULT '', "
		... "PRIMARY KEY (steam_id, setting_id))");

	g_hDB.Query(DB_GenericCallback,
		"CREATE TABLE IF NOT EXISTS ff2_player_hud_setting ("
		... "steam_id VARCHAR(32) NOT NULL, "
		... "hud_id VARCHAR(64) NOT NULL, "
		... "setting_value INTEGER NOT NULL DEFAULT 0, "
		... "last_saved_time VARCHAR(32) NOT NULL DEFAULT '', "
		... "PRIMARY KEY (steam_id, hud_id))");

	g_hDB.Query(DB_GenericCallback,
		"CREATE TABLE IF NOT EXISTS ff2_player_music_setting ("
		... "steam_id VARCHAR(32) NOT NULL, "
		... "music_id VARCHAR(64) NOT NULL, "
		... "setting_value INTEGER NOT NULL DEFAULT 0, "
		... "last_saved_time VARCHAR(32) NOT NULL DEFAULT '', "
		... "PRIMARY KEY (steam_id, music_id))");
}

public void DB_GenericCallback(Database db, DBResultSet results, const char[] error, any data)
{
	if(error[0] != '\0')
	{
		LogError("[FF2] Database query error: %s", error);
	}
}

// --- Client Data Load ---

void FF2DB_LoadPlayerData(int client)
{
	if(IsFakeClient(client) || g_hDB == null)
		return;

	delete g_hPlayerSettings[client];
	delete g_hPlayerHud[client];
	delete g_hPlayerMusic[client];

	g_hPlayerSettings[client] = new StringMap();
	g_hPlayerHud[client] = new StringMap();
	g_hPlayerMusic[client] = new StringMap();

	char authId[32], query[256];
	GetClientAuthId(client, AuthId_Steam2, authId, sizeof(authId));

	Format(query, sizeof(query),
		"SELECT setting_id, value FROM ff2_player_setting WHERE steam_id = '%s'", authId);
	g_hDB.Query(DB_OnSettingsLoaded, query, GetClientUserId(client));

	Format(query, sizeof(query),
		"SELECT hud_id, setting_value FROM ff2_player_hud_setting WHERE steam_id = '%s'", authId);
	g_hDB.Query(DB_OnHudLoaded, query, GetClientUserId(client));

	Format(query, sizeof(query),
		"SELECT music_id, setting_value FROM ff2_player_music_setting WHERE steam_id = '%s'", authId);
	g_hDB.Query(DB_OnMusicLoaded, query, GetClientUserId(client));
}

public void DB_OnSettingsLoaded(Database db, DBResultSet results, const char[] error, any userId)
{
	if(error[0] != '\0')
	{
		LogError("[FF2] Settings load error: %s", error);
		return;
	}

	int client = GetClientOfUserId(userId);
	if(client <= 0 || g_hPlayerSettings[client] == null)
		return;

	char settingId[64], value[128];
	while(results.FetchRow())
	{
		results.FetchString(0, settingId, sizeof(settingId));
		results.FetchString(1, value, sizeof(value));
		g_hPlayerSettings[client].SetString(settingId, value);
	}
}

public void DB_OnHudLoaded(Database db, DBResultSet results, const char[] error, any userId)
{
	if(error[0] != '\0')
	{
		LogError("[FF2] HUD load error: %s", error);
		return;
	}

	int client = GetClientOfUserId(userId);
	if(client <= 0 || g_hPlayerHud[client] == null)
		return;

	char hudId[64];
	while(results.FetchRow())
	{
		results.FetchString(0, hudId, sizeof(hudId));
		g_hPlayerHud[client].SetValue(hudId, results.FetchInt(1));
	}
}

public void DB_OnMusicLoaded(Database db, DBResultSet results, const char[] error, any userId)
{
	if(error[0] != '\0')
	{
		LogError("[FF2] Music load error: %s", error);
		return;
	}

	int client = GetClientOfUserId(userId);
	if(client <= 0 || g_hPlayerMusic[client] == null)
		return;

	char musicId[64];
	while(results.FetchRow())
	{
		results.FetchString(0, musicId, sizeof(musicId));
		g_hPlayerMusic[client].SetValue(musicId, results.FetchInt(1));
	}
}

// --- Client Disconnect ---

void FF2DB_OnClientDisconnect(int client)
{
	delete g_hPlayerSettings[client];
	delete g_hPlayerHud[client];
	delete g_hPlayerMusic[client];
	g_hPlayerSettings[client] = null;
	g_hPlayerHud[client] = null;
	g_hPlayerMusic[client] = null;
}

// --- Settings ---

void FF2DB_GetSettingString(int client, const char[] settingId, char[] value, int buffer)
{
	value[0] = '\0';
	if(g_hPlayerSettings[client] != null)
	{
		g_hPlayerSettings[client].GetString(settingId, value, buffer);
	}
}

void FF2DB_SetSettingString(int client, const char[] settingId, const char[] value)
{
	if(g_hPlayerSettings[client] == null || g_hDB == null)
		return;

	g_hPlayerSettings[client].SetString(settingId, value);

	char authId[32], query[512], escapedValue[256];
	GetClientAuthId(client, AuthId_Steam2, authId, sizeof(authId));
	g_hDB.Escape(value, escapedValue, sizeof(escapedValue));

	Format(query, sizeof(query),
		"INSERT OR REPLACE INTO ff2_player_setting (steam_id, setting_id, value) VALUES ('%s', '%s', '%s')",
		authId, settingId, escapedValue);
	g_hDB.Query(DB_GenericCallback, query);
}

int FF2DB_GetSettingInt(int client, const char[] settingId)
{
	char value[32];
	FF2DB_GetSettingString(client, settingId, value, sizeof(value));
	return StringToInt(value);
}

void FF2DB_SetSettingInt(int client, const char[] settingId, int value)
{
	char strValue[32];
	IntToString(value, strValue, sizeof(strValue));
	FF2DB_SetSettingString(client, settingId, strValue);
}

// --- HUD ---

int FF2DB_GetHudSetting(int client, const char[] hudId)
{
	int value = 0;
	if(g_hPlayerHud[client] != null)
	{
		g_hPlayerHud[client].GetValue(hudId, value);
	}
	return value;
}

void FF2DB_SetHudSetting(int client, const char[] hudId, int value)
{
	if(g_hPlayerHud[client] == null || g_hDB == null)
		return;

	g_hPlayerHud[client].SetValue(hudId, value);

	char authId[32], query[512], timeStr[32];
	GetClientAuthId(client, AuthId_Steam2, authId, sizeof(authId));
	FormatTime(timeStr, sizeof(timeStr), "%Y-%m-%d %H:%M:%S", GetTime());

	Format(query, sizeof(query),
		"INSERT OR REPLACE INTO ff2_player_hud_setting (steam_id, hud_id, setting_value, last_saved_time) VALUES ('%s', '%s', %d, '%s')",
		authId, hudId, value, timeStr);
	g_hDB.Query(DB_GenericCallback, query);
}

// --- Music ---

int FF2DB_GetMusicSetting(int client, const char[] musicId)
{
	int value;
	if(g_hPlayerMusic[client] != null && g_hPlayerMusic[client].GetValue(musicId, value))
	{
		return value;
	}
	return 1; // 기본값: 활성화
}

void FF2DB_SetMusicSetting(int client, const char[] musicId, int value)
{
	if(g_hPlayerMusic[client] == null || g_hDB == null)
		return;

	g_hPlayerMusic[client].SetValue(musicId, value);

	char authId[32], query[512], timeStr[32];
	GetClientAuthId(client, AuthId_Steam2, authId, sizeof(authId));
	FormatTime(timeStr, sizeof(timeStr), "%Y-%m-%d %H:%M:%S", GetTime());

	Format(query, sizeof(query),
		"INSERT OR REPLACE INTO ff2_player_music_setting (steam_id, music_id, setting_value, last_saved_time) VALUES ('%s', '%s', %d, '%s')",
		authId, musicId, value, timeStr);
	g_hDB.Query(DB_GenericCallback, query);
}
