#tryinclude <cwx>

#pragma semicolon 1
#pragma newdecls required

#define CWX_LIBRARY		"cwx"
#define FILE_WEAPONS	"data/freak_fortress_2/loadout.cfg"

#if defined __cwx_included
static bool Loaded;
#endif

static ArrayList LoadoutList;

void Weapons_PluginStart()
{
	RegAdminCmd("ff2_refresh", Weapons_DebugRefresh, ADMFLAG_CHEATS, "Refreshes weapons and attributes");
	RegAdminCmd("ff2_reloadweapons", Weapons_DebugReload, ADMFLAG_RCON, "Reloads the weapons config");
	
	#if defined __cwx_included
	Loaded = LibraryExists(CWX_LIBRARY);
	#endif
}

public void Weapons_LibraryAdded(const char[] name)
{
	#if defined __cwx_included
	if(!Loaded && StrEqual(name, CWX_LIBRARY))
		Loaded = true;
	#endif
}

public void Weapons_LibraryRemoved(const char[] name)
{
	#if defined __cwx_included
	if(Loaded && StrEqual(name, CWX_LIBRARY))
		Loaded = false;
	#endif
}

void Weapons_PrintStatus()
{
	#if defined __cwx_included
	PrintToServer("'%s' is %sloaded", CWX_LIBRARY, Loaded ? "" : "not ");
	#else
	PrintToServer("'%s' not compiled", CWX_LIBRARY);
	#endif
}

static Action Weapons_DebugRefresh(int client, int args)
{
	if(client)
	{
		TF2_RemoveAllItems(client);
		
		int entity, i;
		while(TF2U_GetWearable(client, entity, i))
		{
			TF2Tools_RemoveWearable(client, entity);
		}
		
		TF2Tools_RegeneratePlayer(client);
	}
	else
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
	}
	return Plugin_Handled;
}

static Action Weapons_DebugReload(int client, int args)
{
	if(Weapons_ConfigsExecuted(true))
	{
		FReplyToCommand(client, "Reloaded");

		for(int target = 1; target <= MaxClients; target++)
		{
			if(IsClientInGame(target) && !Client(target).IsBoss && !Client(target).MinionType)
			{
				TF2_RemoveAllItems(target);
				
				int entity, i;
				while(TF2U_GetWearable(target, entity, i))
				{
					TF2Tools_RemoveWearable(target, entity);
				}
				
				TF2Tools_RegeneratePlayer(target);
			}
		}
	}
	else if(client && CheckCommandAccess(client, "sm_rcon", ADMFLAG_RCON))
	{
		FReplyToCommand(client, "Config Error, use sm_rcon to print errors");
	}
	else
	{
		FReplyToCommand(client, "Config Error");
	}
	return Plugin_Handled;
}

bool Weapons_ConfigsExecuted(bool force = false)
{
	if(LoadoutList)
	{
		int length = LoadoutList.Length;
		for(int i; i < length; i++)
		{
			DeleteCfg(LoadoutList.Get(i));
		}

		delete LoadoutList;
	}

	if(Enabled || force)
	{
		ConfigMap cfg = new ConfigMap(FILE_WEAPONS);
		if(!cfg)
			return false;

		StringMapSnapshot snap = cfg.Snapshot();

		int entries = snap.Length;
		if(entries)
		{
			char buffer[PLATFORM_MAX_PATH];

			LoadoutList = new ArrayList();

			PackVal val;
			for(int i = 0; i < entries; i++)
			{
				int length = snap.KeyBufferSize(i) + 1;

				char[] key = new char[length];
				snap.GetKey(i, key, length);

				cfg.GetArray(key, val, sizeof(val));

				if(val.tag == KeyValType_Section && val.cfg)
				{
					FormatEx(buffer, sizeof(buffer), "data/freak_fortress_2/%s.cfg", key);
					ConfigMap loadout = new ConfigMap(buffer);
					if(loadout)
					{
						loadout.Set("key", key);
						loadout.Set("name", key);
						ImportValuesIntoConfigMap(val.cfg, loadout);

						int pos = LoadoutList.Push(loadout);
						
						if(LoadoutList.Length > 1)
						{
							bool defaul;
							if(val.cfg.GetBool("default", defaul, false) && defaul)
							{
								LoadoutList.SwapAt(0, pos);
							}
						}
					}
				}
			}

			if(!LoadoutList.Length)
				delete LoadoutList;
		}

		delete snap;
		DeleteCfg(cfg);
	}
	
	return true;
}

bool Weapons_ConfigEnabled()
{
	return view_as<bool>(LoadoutList);
}

void Weapons_EntityCreated(int entity, const char[] classname)
{
	if(Weapons_ConfigEnabled() && (!StrContains(classname, "tf_wea") || !StrContains(classname, "tf2c_wea") || !StrContains(classname, "tf_powerup_bottle")))
		SDKHook(entity, SDKHook_SpawnPost, Weapons_Spawn);
}

static void Weapons_Spawn(int entity)
{
	RequestFrame(Weapons_SpawnFrame, EntIndexToEntRef(entity));
}

static void Weapons_SpawnFrame(int ref)
{
	if(!Weapons_ConfigEnabled() || !IsRoundActive())
		return;
	
	int entity = EntRefToEntIndex(ref);
	if(entity == INVALID_ENT_REFERENCE)
		return;
	
	if((HasEntProp(entity, Prop_Send, "m_bDisguiseWearable") && GetEntProp(entity, Prop_Send, "m_bDisguiseWearable")) ||
		(HasEntProp(entity, Prop_Send, "m_bDisguiseWeapon") && GetEntProp(entity, Prop_Send, "m_bDisguiseWeapon")))
		return;
	
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(client < 1 || client > MaxClients || Client(client).IsBoss || Client(client).MinionType == 1)
		return;
	
	bool temp;
	char loadout[32];
	Client(client).GetLoadout(loadout, sizeof(loadout));
	ConfigMap cfg = FindWeaponSection(entity, loadout, _, client, temp);
	if(!cfg)
		return;
	
	bool found;
	if(cfg.GetBool("strip", found, false) && found)
		SetEntProp(entity, Prop_Send, "m_bOnlyIterateItemViewAttributes", true);
	
	int current;
	
	if(cfg.GetInt("clip", current))
	{
		temp = true;
		
		if(HasEntProp(entity, Prop_Data, "m_iClip1"))
			SetEntProp(entity, Prop_Data, "m_iClip1", current);
	}
	
	if(cfg.GetInt("ammo", current))
	{
		temp = true;
		
		if(HasEntProp(entity, Prop_Send, "m_iPrimaryAmmoType"))
		{
			int type = GetEntProp(entity, Prop_Send, "m_iPrimaryAmmoType");
			if(type >= 0)
				SetEntProp(client, Prop_Data, "m_iAmmo", current, _, type);
		}
	}

	if(temp)
		SetEntProp(entity, Prop_Send, "m_iAccountID", 0);

	// 어트리뷰 적용은 weapon.sp의 TF2Items_OnGiveNamedItem에서 통합 관리
	// config 기반 어트리뷰 적용 제거 (중복 방지)
}

static ConfigMap FindMatchingLoadout(const char[] loadou)
{
	static char buffer[32];

	ConfigMap cfg;
	for(int i = LoadoutList.Length - 1; i >= 0; i--)
	{
		cfg = LoadoutList.Get(i);
		if(cfg.Get("key", buffer, sizeof(buffer)) && StrEqual(buffer, loadou))
			break;
	}

	return cfg;
}

static ConfigMap FindWeaponSection(int entity, const char[] loadou, char cwx[64] = "", int client = 0, bool &temp = false)
{
	char buffer1[64];

	ConfigMap loadout = FindMatchingLoadout(loadou);
	
	#if defined __cwx_included
	if(Loaded && CWX_GetItemUIDFromEntity(entity, cwx, sizeof(cwx)) && CWX_IsItemUIDValid(cwx))
	{
		Format(buffer1, sizeof(buffer1), "CWX.%s", cwx);
		ConfigMap cfg = loadout.GetSection(buffer1);
		if(cfg)
			return FindClassSection(cfg, client, temp);
	}
	#endif
	
	cwx[0] = 0;
	
	if(client && Client(client).MinionType == 2)
		return loadout.GetSection("Classnames.ff2_weapon_teuton");

	ConfigMap cfg = loadout.GetSection("Indexes");
	if(cfg)
	{
		StringMapSnapshot snap = cfg.Snapshot();
		
		int entries = snap.Length;
		if(entries)
		{
			int index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
			char buffer2[12];
			for(int i; i < entries; i++)
			{
				int length = snap.KeyBufferSize(i)+1;
				char[] key = new char[length];
				snap.GetKey(i, key, length);
				
				bool found;
				int current;
				do
				{
					int add = SplitString(key[current], " ", buffer2, sizeof(buffer2));
					found = add != -1;
					if(found)
					{
						current += add;
					}
					else
					{
						strcopy(buffer2, sizeof(buffer2), key[current]);
					}
					
					if(StringToInt(buffer2) == index)
					{
						PackVal val;
						cfg.GetArray(key, val, sizeof(val));
						if(val.tag == KeyValType_Section)
						{
							delete snap;
							return FindClassSection(val.cfg, client, temp);
						}
						
						break;
					}
				} while(found);
			}
		}
		
		delete snap;
	}
	
	GetEntityClassname(entity, buffer1, sizeof(buffer1));
	Format(buffer1, sizeof(buffer1), "Classnames.%s", buffer1);
	cfg = loadout.GetSection(buffer1);
	if(cfg)
		return FindClassSection(cfg, client, temp);
	
	return null;
}

static ConfigMap FindClassSection(ConfigMap cfg, int client, bool &temp)
{
	if(client)
	{
		TFClassType class = Client(client).IsBoss ? TFClass_Unknown : TF2_GetPlayerClass(client);

		char classname[16];
		TF2Tools_GetClassName(class, classname, sizeof(classname));
		
		ConfigMap section = cfg.GetSection(classname);
		if(section)
		{
			temp = true;
			return section;
		}
		
		section = cfg.GetSection("other");
		if(section)
		{
			temp = true;
			return section;
		}
	}

	temp = false;
	return cfg;
}
