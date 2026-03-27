#tryinclude <tf_econ_dynamic>
#tryinclude <tf_custom_attributes>

#pragma semicolon 1
#pragma newdecls required

#define TFEY_LIBRARY	"tf2econdynamic"
#define TCA_LIBRARY		"tf2custattr"

#if !defined CUSTOMATTRIBFF2_INCLUDED
#define CUSTOMATTRIBFF2_INCLUDED	-69420.69
#endif

#if defined __tf_econ_dyn_included
static bool TFEYLoaded;
#endif

#if defined __tf_custom_attributes_included
static bool TCALoaded;
#endif

#if defined IS_MAIN_FF2
static int HasCritGlow[MAXTF2PLAYERS];
#endif

void CustomAttrib_PluginLoad()
{
	#if defined __tf_custom_attributes_included
	MarkNativeAsOptional("TF2CustAttr_GetFloat");
	MarkNativeAsOptional("TF2CustAttr_SetString");
	MarkNativeAsOptional("TF2CustAttr_GetString");
	#endif
	
	#if defined IS_MAIN_FF2
	#if defined __tf_econ_dyn_included
	MarkNativeAsOptional("TF2EconDynAttribute.TF2EconDynAttribute");
	MarkNativeAsOptional("TF2EconDynAttribute.SetClass");
	MarkNativeAsOptional("TF2EconDynAttribute.SetName");
	MarkNativeAsOptional("TF2EconDynAttribute.SetDescriptionFormat");
	MarkNativeAsOptional("TF2EconDynAttribute.SetCustom");
	MarkNativeAsOptional("TF2EconDynAttribute.Register");
	#endif
	#endif
}

void CustomAttrib_PluginStart()
{
	#if defined __tf_custom_attributes_included
	TCALoaded = LibraryExists(TCA_LIBRARY);
	#endif
}

stock void CustomAttrib_AllPluginsLoaded()
{
	#if defined __tf_econ_dyn_included
	TFEYLoaded = GetFeatureStatus(FeatureType_Native, "TF2EconDynAttribute.TF2EconDynAttribute") == FeatureStatus_Available;
	if(TFEYLoaded)
	{
		#if defined IS_MAIN_FF2
		AddAttributes();
		#endif
	}
	#endif
}

public void CustomAttrib_LibraryAdded(const char[] name)
{
	#if defined __tf_custom_attributes_included
	if(!TCALoaded && StrEqual(name, TCA_LIBRARY))
		TCALoaded = true;
	#endif
}

public void CustomAttrib_LibraryRemoved(const char[] name)
{
	#if defined __tf_custom_attributes_included
	if(TCALoaded && StrEqual(name, TCA_LIBRARY))
		TCALoaded = false;
	#endif
}

stock void CustomAttrib_PrintStatus()
{
	#if defined __tf_econ_dyn_included
	if(GetFeatureStatus(FeatureType_Native, "TF2EconDynAttribute.TF2EconDynAttribute") != FeatureStatus_Available)
		TFEYLoaded = false;

	PrintToServer("'%s' is %sloaded", TFEY_LIBRARY, TFEYLoaded ? "" : "not ");
	#else
	PrintToServer("'%s' not compiled", TFEY_LIBRARY);
	#endif

	#if defined __tf_custom_attributes_included
	PrintToServer("'%s' is %sloaded", TCA_LIBRARY, TCALoaded ? "" : "not ");
	#else
	PrintToServer("'%s' not compiled", TCA_LIBRARY);
	#endif
}

stock void CustomAttrib_ApplyFromCfg(int entity, ConfigMap cfg)
{
	StringMapSnapshot snap = cfg.Snapshot();
	
	int entries = snap.Length;
	for(int i; i < entries; i++)
	{
		int length = snap.KeyBufferSize(i) + 1;
		
		char[] key = new char[length];
		snap.GetKey(i, key, length);
		
		static PackVal attribute;	
		cfg.GetArray(key, attribute, sizeof(attribute));
		if(attribute.tag == KeyValType_Value)
		{
			#if defined __tf_custom_attributes_included
			if(TCALoaded)
				TF2CustAttr_SetString(entity, key, attribute.data);
			#endif
			
			Attrib_SetString(entity, key, _, attribute.data);
		}
	}
	
	delete snap;
}

stock float CustomAttrib_FindOnPlayer(int client, const char[] name, bool multi = false)
{
	float total = multi ? 1.0 : 0.0;
	bool found = CustomAttrib_Get(client, name, total);
	
	int i;
	int entity;
	float value;
	while(TF2U_GetWearable(client, entity, i))
	{
		if(CustomAttrib_Get(entity, name, value))
		{
			if(!found)
			{
				total = value;
				found = true;
			}
			else if(multi)
			{
				total *= value;
			}
			else
			{
				total += value;
			}
		}
	}

	int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	while(TF2_GetItem(client, entity, i))
	{
		if(active != entity && Attrib_Get(entity, "provide on active", 128, value) && value)
			continue;
		
		if(CustomAttrib_Get(entity, name, value))
		{
			if(!found)
			{
				total = value;
				found = true;
			}
			else if(multi)
			{
				total *= value;
			}
			else
			{
				total += value;
			}
		}
	}
	
	return total;
}

stock float CustomAttrib_FindOnWeapon(int client, int entity, const char[] name, bool multi = false)
{
	float total = multi ? 1.0 : 0.0;
	bool found = CustomAttrib_Get(client, name, total);
	
	int i;
	int wear;
	float value;
	while(TF2U_GetWearable(client, wear, i))
	{
		if(CustomAttrib_Get(wear, name, value))
		{
			if(!found)
			{
				total = value;
				found = true;
			}
			else if(multi)
			{
				total *= value;
			}
			else
			{
				total += value;
			}
		}
	}
	
	if(entity != -1)
	{
		char classname[18];
		GetEntityClassname(entity, classname, sizeof(classname));
		if(!StrContains(classname, "tf_wea") || !StrContains(classname, "tf2c_wea") || StrEqual(classname, "tf_powerup_bottle"))
		{
			if(CustomAttrib_Get(entity, name, value))
			{
				if(!found)
				{
					total = value;
				}
				else if(multi)
				{
					total *= value;
				}
				else
				{
					total += value;
				}
			}
		}
	}
	
	return total;
}

stock bool CustomAttrib_Get(int weapon, const char[] name, float &value = 0.0)
{
	#if defined __tf_custom_attributes_included
	if(TCALoaded)
	{
		float result = TF2CustAttr_GetFloat(weapon, name, CUSTOMATTRIBFF2_INCLUDED);
		if(result != CUSTOMATTRIBFF2_INCLUDED)
		{
			value = result;
			return true;
		}
	}
	#endif

	return Attrib_Get(weapon, name, _, value);
}

stock bool CustomAttrib_GetString(int weapon, const char[] name, char[] buffer, int length)
{
	#if defined __tf_custom_attributes_included
	if(TCALoaded)
	{
		if(TF2CustAttr_GetString(weapon, name, buffer, length))
			return true;
	}
	#endif

	return Attrib_GetString(weapon, name, _, buffer, length);
}

#if !defined IS_MAIN_FF2
	#endinput
#endif

#if defined __tf_econ_dyn_included
static void AddAttributes()
{
	TF2EconDynAttribute attrib = new TF2EconDynAttribute();

	attrib.SetName("damage vs bosses");
	attrib.SetClass("ff2.mult_dmg_vs_boss");
	attrib.SetDescriptionFormat("value_is_percentage");
	attrib.SetCustom("description_ff2_string", "damage vs bosses");
	attrib.Register();

	attrib.SetName("multi boss rage");
	attrib.SetClass("ff2.multi_victim_rage_on_hit");
	attrib.SetDescriptionFormat("value_is_percentage");
	attrib.SetCustom("description_ff2_string", "multi boss rage");
	attrib.Register();

	attrib.SetName("mid-air damage vs bosses");
	attrib.SetClass("ff2.mult_airborne_vs_boss");
	attrib.SetDescriptionFormat("value_is_percentage");
	attrib.SetCustom("description_ff2_string", "mid-air damage vs bosses");
	attrib.Register();

	attrib.SetName("charge outlines bosses");
	attrib.SetClass("ff2.mod_charge_outline_boss");
	attrib.SetDescriptionFormat("additive");
	attrib.SetCustom("description_ff2_string", "charge outlines bosses");
	attrib.Register();

	attrib.SetName("mod crit type on bosses");
	attrib.SetClass("ff2.set_critype_vs_boss");
	attrib.SetDescriptionFormat("additive");
	attrib.SetCustom("description_ff2_string", "mod crit type on bosses");
	attrib.Register();

	attrib.SetName("mod fire rate hit stale");
	attrib.SetClass("ff2.stale_boss_hit_firerate");
	attrib.SetDescriptionFormat("additive");
	attrib.SetCustom("description_ff2_string", "mod fire rate hit stale");
	attrib.Register();

	attrib.SetName("mod reload time hit stale");
	attrib.SetClass("ff2.stale_boss_hit_reload");
	attrib.SetDescriptionFormat("additive");
	attrib.SetCustom("description_ff2_string", "mod reload time hit stale");
	attrib.Register();

	attrib.SetName("mod recharge time hit stale");
	attrib.SetClass("ff2.stale_boss_hit_charge");
	attrib.SetDescriptionFormat("additive");
	attrib.SetCustom("description_ff2_string", "mod recharge time hit stale");
	attrib.Register();

	attrib.SetName("primary damage vs bosses");
	attrib.SetClass("ff2.mult_slot0_dmg_vs_boss");
	attrib.SetDescriptionFormat("value_is_percentage");
	attrib.SetCustom("description_ff2_string", "primary damage vs bosses");
	attrib.Register();

	attrib.SetName("secondary damage vs bosses");
	attrib.SetClass("ff2.mult_slot1_dmg_vs_boss");
	attrib.SetDescriptionFormat("value_is_percentage");
	attrib.SetCustom("description_ff2_string", "secondary damage vs bosses");
	attrib.Register();

	attrib.SetName("melee damage vs bosses");
	attrib.SetClass("ff2.mult_slot2_dmg_vs_boss");
	attrib.SetDescriptionFormat("value_is_percentage");
	attrib.SetCustom("description_ff2_string", "melee damage vs bosses");
	attrib.Register();

	attrib.SetName("mod crit type glow");
	attrib.SetClass("ff2.set_critype");
	attrib.SetDescriptionFormat("additive");
	attrib.SetCustom("description_ff2_string", "mod crit type glow");
	attrib.Register();

	attrib.SetName("primary ammo from damage");
	attrib.SetClass("ff2.mod_ammo1_gain_vs_boss");
	attrib.SetDescriptionFormat("additive");
	attrib.SetCustom("description_ff2_string", "primary ammo from damage");
	attrib.Register();

	attrib.SetName("secondary ammo from damage");
	attrib.SetClass("ff2.mod_ammo2_gain_vs_boss");
	attrib.SetDescriptionFormat("additive");
	attrib.SetCustom("description_ff2_string", "secondary ammo from damage");
	attrib.Register();

	attrib.SetName("backstab damage percent");
	attrib.SetClass("ff2.mod_old_backstab");
	attrib.SetDescriptionFormat("additive");
	attrib.SetCustom("description_ff2_string", "backstab damage percent");
	attrib.Register();

	attrib.SetName("backstab stale restore");
	attrib.SetClass("ff2.stale_boss_stab_time");
	attrib.SetDescriptionFormat("additive");
	attrib.SetCustom("description_ff2_string", "");
	attrib.Register();

	attrib.SetName("backstab stale multi");
	attrib.SetClass("ff2.stale_boss_stab_damage");
	attrib.SetDescriptionFormat("additive");
	attrib.SetCustom("description_ff2_string", "");
	attrib.Register();

	attrib.SetName("mod airblast stale");
	attrib.SetClass("ff2.stale_boss_airblast_refire");
	attrib.SetDescriptionFormat("additive");
	attrib.SetCustom("description_ff2_string", "mod airblast stale");
	attrib.Register();

	attrib.SetName("mod airblast rage");
	attrib.SetClass("ff2.mod_airblast_boss_rage");
	attrib.SetDescriptionFormat("additive");
	attrib.SetCustom("description_ff2_string", "mod airblast rage");
	attrib.Register();

	attrib.SetName("medigun charge adds crit boost");
	attrib.SetClass("ff2.medigun_with_crits");
	attrib.SetDescriptionFormat("additive");
	attrib.SetCustom("description_ff2_string", "medigun charge adds crit boost");
	attrib.Register();

	attrib.SetName("mod stun boss on hit");
	attrib.SetClass("ff2.mod_stun_on_hit");
	attrib.SetDescriptionFormat("additive");
	attrib.SetCustom("description_ff2_string", "mod stun boss on hit");
	attrib.Register();

	attrib.SetName("mod rage loss on hit");
	attrib.SetClass("ff2.mod_rage_on_hit");
	attrib.SetDescriptionFormat("additive");
	attrib.SetCustom("description_ff2_string", "mod rage loss on hit");
	attrib.Register();

	attrib.SetName("jarate is rage loss");
	attrib.SetClass("ff2.jarate_rage");
	attrib.SetDescriptionFormat("additive");
	attrib.SetCustom("description_ff2_string", "jarate is rage loss");
	attrib.Register();

	attrib.SetName("melee sickle climb");
	attrib.SetClass("ff2.mod_melee_climb");
	attrib.SetDescriptionFormat("additive");
	attrib.SetCustom("description_ff2_string", "melee sickle climb");
	attrib.Register();

	attrib.SetName("boost on damage drain multi");
	attrib.SetClass("ff2.mod_boost_decay");
	attrib.SetDescriptionFormat("value_is_percentage");
	attrib.SetCustom("description_ff2_string", "");
	attrib.Register();

	attrib.SetName("milk limit DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_1");
	attrib.SetCustom("description_ff2_string", "milk limit DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("hit stale DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_2");
	attrib.SetCustom("description_ff2_string", "hit stale DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("sentry death DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_3");
	attrib.SetCustom("description_ff2_string", "sentry death DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("jarate limit DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_4");
	attrib.SetCustom("description_ff2_string", "jarate limit DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("boost limit DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_5");
	attrib.SetCustom("description_ff2_string", "boost limit DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("teleport no spawn DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_6");
	attrib.SetCustom("description_ff2_string", "teleport no spawn DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("vaccinator DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_7");
	attrib.SetCustom("description_ff2_string", "vaccinator DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("cloak on hit DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_8");
	attrib.SetCustom("description_ff2_string", "cloak on hit DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("cloak and dagger no DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_9");
	attrib.SetCustom("description_ff2_string", "cloak and dagger no DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("laugh is slow DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_10");
	attrib.SetCustom("description_ff2_string", "laugh is slow DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("caber boss crit DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_11");
	attrib.SetCustom("description_ff2_string", "caber boss crit DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("start with uber DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_12");
	attrib.SetCustom("description_ff2_string", "start with uber DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("mark limit DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_13");
	attrib.SetCustom("description_ff2_string", "mark limit DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("health drop on damage DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_14");
	attrib.SetCustom("description_ff2_string", "health drop on damage DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("resist effects stuns DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_15");
	attrib.SetCustom("description_ff2_string", "resist effects stuns DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("kill effects boss hits DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_16");
	attrib.SetCustom("description_ff2_string", "kill effects boss hits DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("backstabs DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_17");
	attrib.SetCustom("description_ff2_string", "backstabs DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("disguise resistance DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_18");
	attrib.SetCustom("description_ff2_string", "disguise resistance DISPLAY ONLY");
	attrib.Register();

	attrib.SetName("sapper boss effect DISPLAY ONLY");
	attrib.SetClass("ff2.displayonly_19");
	attrib.SetCustom("description_ff2_string", "sapper boss effect DISPLAY ONLY");
	attrib.Register();
	
	delete attrib;
}
#endif

void CustomAttrib_PlayerDeath(int client)
{
	HasCritGlow[client] = 0;
}

void CustomAttrib_OnHitBossPre(int attacker, int victim, float &damage, int &damagetype, int weapon, int damagecustom, int &critType)
{
	float value = CustomAttrib_FindOnWeapon(attacker, weapon, "damage vs bosses", true);
	if(value != 1.0)
		damage *= value;

	value = CustomAttrib_FindOnWeapon(attacker, weapon, "multi boss rage", true);
	if(value != 1.0)
		Client(victim).RageDebuff *= value;

	// Backburner: x4 damage on back-attack
	if(weapon != -1)
	{
		int weaponIdx = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		if(weaponIdx == 40 || weaponIdx == 1146)	// Backburner
		{
			if(WeaponSpecial_IsBackAttack(attacker, victim))
			{
				damage *= 4.0;
			}
		}
		else if(weaponIdx == 594)	// Phlogistinator: halved damage without Mmmph
		{
			if(!TF2_IsPlayerInCondition(attacker, TFCond_CritMmmph))
			{
				damage *= 0.5;
			}
		}

		// 이방인(224): 적중 시 자신에게 addcond 66 (속도버프) 3초
		if(weaponIdx == 224)
		{
			TF2_AddCondition(attacker, view_as<TFCond>(66), 3.0);
		}

		// 가정파괴범(153): 보스 적중 시 3초 스턴
		if(weaponIdx == 153 && Client(victim).IsBoss)
		{
			TF2_StunPlayer(victim, 3.0, 0.0, TF_STUNFLAGS_SMALLBONK, attacker);
		}

		// 아이랜더(132)/아이언9번골프채(482,1082)/반블리츠(266)/클레이브모어(327)/퇴거통보(426): 적중 시 이속버프 3초
		if(weaponIdx == 132 || weaponIdx == 482 || weaponIdx == 1082 || weaponIdx == 266 || weaponIdx == 327 || weaponIdx == 426)
		{
			TF2_AddCondition(attacker, TFCond_SpeedBuffAlly, 3.0);
		}
	}

	// 스파이 은폐 피해 배율 적용
	float cloakMult = WeaponSpecial_GetCloakDamageMultiplier(victim);
	if(cloakMult != 1.0)
	{
		damage *= cloakMult;
	}

	if(damagecustom == TF_CUSTOM_BURNING || damagecustom == TF_CUSTOM_BLEEDING || damagecustom == TF_CUSTOM_BURNING_FLARE || damagecustom == TF_CUSTOM_BURNING_ARROW)
		return;

	if(TF2_IsPlayerInCondition(attacker, TFCond_BlastJumping))
	{
		value = CustomAttrib_FindOnWeapon(attacker, weapon, "mid-air damage vs bosses", true);
		if(value != 1.0)
		{
			damage *= value;
			
			if(CustomAttrib_FindOnWeapon(attacker, weapon, "mod crit while airborne"))
			{
				if(!Attributes_OnBackstabBoss(attacker, victim, damage, weapon, false))
				{
					EmitGameSoundToClient(victim, "TFPlayer.DoubleDonk", attacker);
					EmitGameSoundToClient(attacker, "TFPlayer.DoubleDonk", victim);
					
					if(MultiBosses())
					{
						Bosses_PlaySoundToAll(victim, "sound_marketed", _, victim, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT, _, SNDVOL_BOSS);
					}
					else
					{
						Bosses_PlaySoundToAll(victim, "sound_marketed", _, _, _, _, _, SNDVOL_BOSS);
					}
				}
				
				CustomAttrib_OnBackstabBoss(victim, damage, weapon);
				
				Bosses_UseSlot(victim, 7, 7);
			}
		}
	}
	
	value = CustomAttrib_FindOnWeapon(attacker, weapon, "mod stun boss on hit");
	if(value)
		TF2Tools_StunPlayer(victim, value, 0.0, TF_STUNFLAGS_SMALLBONK|TF_STUNFLAG_NOSOUNDOREFFECT, attacker);
	
	value = CustomAttrib_FindOnWeapon(attacker, weapon, "mod rage loss on hit");
	if(value)
		ApplyRage(victim, attacker, -value);
	
	if(weapon != -1 && HasEntProp(weapon, Prop_Send, "m_AttributeList"))
	{
		if(critType != 2 && !(damagetype & DMG_CRIT))
		{
			value = float(critType);
			if(CustomAttrib_Get(weapon, "mod crit type on bosses", value))
				critType = RoundFloat(value);
		}
		
		value = CustomAttrib_FindOnWeapon(attacker, weapon, "charge outlines bosses");
		if(value > 0.0)
		{
			if(HasEntProp(weapon, Prop_Send, "m_flChargedDamage"))
			{
				value *= 1.0 + (GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage") / 50.0);
			}
			else if(HasEntProp(weapon, Prop_Send, "m_flMinicritCharge"))
			{
				value *= 1.0 + (GetEntPropFloat(weapon, Prop_Send, "m_flMinicritCharge") / 50.0);
			}
			else
			{
				value *= 1.0 + ((GetEntPropFloat(attacker, Prop_Send, "m_flHypeMeter") + GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter")) / 50.0);
			}
			
			Gamemode_SetClientGlow(victim, value);
		}

		char buffer[36];
		if(CustomAttrib_GetString(weapon, "mod attribute hit stale", buffer, sizeof(buffer)))
		{
			char buffers[2][16];
			ExplodeString(buffer, ";", buffers, sizeof(buffers), sizeof(buffers[]));
			
			int attrib = StringToInt(buffers[0]);
			if(attrib)
			{
				SetEntProp(weapon, Prop_Send, "m_iAccountID", 0);
				
				float initial = 1.0;
				Attrib_Get(weapon, _, attrib, initial);
				Attrib_Set(weapon, _, attrib, initial + StringToFloat(buffers[1]));
			}
		}
		
		value = CustomAttrib_FindOnWeapon(attacker, weapon, "mod fire rate hit stale");
		if(value != 0.0)
		{
			SetEntProp(weapon, Prop_Send, "m_iAccountID", 0);
			
			float initial = 1.0;
			Attrib_Get(weapon, "fire rate penalty", 5, initial);
			Attrib_Set(weapon, "fire rate penalty", 5, initial + value);
		}

		value = CustomAttrib_FindOnWeapon(attacker, weapon, "mod reload time hit stale");
		if(value != 0.0)
		{
			SetEntProp(weapon, Prop_Send, "m_iAccountID", 0);
			
			float initial = 1.0;
			Attrib_Get(weapon, "Reload time increased", 96, initial);
			Attrib_Set(weapon, "Reload time increased", 96, initial + value);
		}

		value = CustomAttrib_FindOnWeapon(attacker, weapon, "mod recharge time hit stale");
		if(value != 0.0)
		{
			SetEntProp(weapon, Prop_Send, "m_iAccountID", 0);
			
			float initial = 1.0;
			Attrib_Get(weapon, "effect bar recharge rate increased", 278, initial);
			Attrib_Set(weapon, "effect bar recharge rate increased", 278, initial + value);
		}

		if(GetEntityClassname(weapon, buffer, sizeof(buffer)))
		{
			int slot = TF2_GetClassnameSlot(buffer);
			if(slot >= TFWeaponSlot_Primary && slot <= TFWeaponSlot_Melee)
			{
				static const char AttribName[][] = { "primary damage vs bosses", "secondary damage vs bosses", "melee damage vs bosses" };
				value = CustomAttrib_FindOnPlayer(attacker, AttribName[slot], true);
				if(value != 1.0)
					damage *= value;
			}

			if(StrEqual(buffer, "tf_weapon_stickbomb"))
			{
				// Ullapool Caber gets a critical explosion
				if(!GetEntProp(weapon, Prop_Send, "m_iDetonated"))
				{
					damagetype |= DMG_CRIT;
					critType = 2;
					
					if(MultiBosses())
					{
						Bosses_PlaySoundToAll(victim, "sound_cabered", _, victim, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT, _, SNDVOL_BOSS);
					}
					else
					{
						Bosses_PlaySoundToAll(victim, "sound_cabered", .volume = SNDVOL_BOSS);
					}
				}
			}
		}
	}
	
	if((!critType && !(damagetype & DMG_CRIT)) && ((TF2_IsPlayerInCondition(attacker, TFCond_BlastJumping) && Attrib_FindOnWeapon(attacker, weapon, "rocketjump attackrate bonus", 621)) ||
	   ((TF2_IsPlayerInCondition(attacker, TFCond_Disguised) || TF2_IsPlayerInCondition(attacker, TFCond_DisguiseRemoved)) && Attrib_FindOnWeapon(attacker, weapon, "damage bonus while disguised", 410))))
	{
		critType = 1;
	}
}

void CustomAttrib_OnHitBossPost(int attacker, int newPlayerDamage, int lastPlayerDamage)
{
	float value = CustomAttrib_FindOnPlayer(attacker, "primary ammo from damage");
	if(value)
	{
		int ammo = DamageGoal(RoundFloat(value), newPlayerDamage, lastPlayerDamage);
		if(ammo)
		{
			if(value < 0.0)
				ammo = -ammo;
			
			ammo += GetEntProp(attacker, Prop_Data, "m_iAmmo", _, 1);
			if(ammo < 0)
				ammo = 0;
			
			SetEntProp(attacker, Prop_Data, "m_iAmmo", ammo, _, 1);
		}
	}

	value = CustomAttrib_FindOnPlayer(attacker, "secondary ammo from damage");
	if(value)
	{
		int ammo = DamageGoal(RoundFloat(value), newPlayerDamage, lastPlayerDamage);
		if(ammo)
		{
			if(value < 0.0)
				ammo = -ammo;
			
			ammo += GetEntProp(attacker, Prop_Data, "m_iAmmo", _, 2);
			if(ammo < 0)
				ammo = 0;
			
			SetEntProp(attacker, Prop_Data, "m_iAmmo", ammo, _, 2);
		}
	}
}

void CustomAttrib_OnAirblastBoss(int victim, int attacker)
{
	int weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	if(weapon != -1)
	{
		float value;
		if(CustomAttrib_Get(weapon, "mod airblast stale", value))
		{
			SetEntProp(weapon, Prop_Send, "m_iAccountID", 0);
			
			float initial = 1.0;
			Attrib_Get(weapon, "mult airblast refire time", 256, initial);
			Attrib_Set(weapon, "mult airblast refire time", 256, initial + value);
		}

		if(CustomAttrib_Get(weapon, "mod airblast rage", value))
			ApplyRage(victim, attacker, value);
	}
}

void CustomAttrib_OnBackstabBoss(int victim, float &damage, int weapon, float &time = 0.0, float &multi = 0.0)
{
	if(weapon != -1 && HasEntProp(weapon, Prop_Send, "m_AttributeList"))
	{
		CustomAttrib_Get(weapon, "backstab damage percent", multi);
		if(multi > 0.0)
			damage = float(Client(victim).MaxHealth * Client(victim).MaxLives) * multi / 3.0;
		
		CustomAttrib_Get(weapon, "backstab stale restore", time);
		CustomAttrib_Get(weapon, "backstab stale multi", multi);
	}
}

void CustomAttrib_OnJarateBoss(int victim, int attacker, int weapon, float &jarate)
{
	float value;
	if(CustomAttrib_Get(weapon, "jarate is rage loss", value))
	{
		ApplyRage(victim, attacker, value);
		jarate = 0.0;
	}
}

void CustomAttrib_OnInventoryApplication(int userid)
{
	RequestFrame(WeaponSwitchFrame, userid);
}

void CustomAttrib_OnWeaponSwitch(int client)
{
	RequestFrame(WeaponSwitchFrame, GetClientUserId(client));
}

static void WeaponSwitchFrame(int userid)
{
	int client = GetClientOfUserId(userid);
	if(client)
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(weapon != -1 && HasEntProp(weapon, Prop_Send, "m_AttributeList"))
		{
			TFClassType class = TF2_GetPlayerClass(client);

			switch(HasCritGlow[client])
			{
				case 1:
				{
					TF2Tools_RemoveCondition(client, (class == TFClass_Scout || class == TFClass_Heavy) ? TFCond_Buffed : TFCond_CritCola);
				}
				case 2:
				{
					TF2Tools_RemoveCondition(client, TFCond_CritOnDamage);
				}
			}
			
			float type = 0.0;
			CustomAttrib_Get(weapon, "mod crit type glow", type);
			switch(RoundFloat(type))
			{
				case 1:
				{
					TF2Tools_AddCondition(client, (class == TFClass_Scout || class == TFClass_Heavy) ? TFCond_Buffed : TFCond_CritCola);
					HasCritGlow[client] = 1;
				}
				case 2:
				{
					TF2Tools_AddCondition(client, TFCond_CritOnDamage);
					HasCritGlow[client] = 2;
				}
				default:
				{
					HasCritGlow[client] = 0;
				}
			}
		}
	}
}

void CustomAttrib_OnUberDeployed(int client)
{
	int weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(weapon != -1)
	{
		char classname[36];
		GetEntityClassname(weapon, classname, sizeof(classname));
		if(StrEqual(classname, "tf_weapon_medigun"))
		{
			if(CustomAttrib_Get(weapon, "medigun charge adds crit boost"))
			{
				CreateTimer(0.4, UberTimer, EntIndexToEntRef(weapon), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

static Action UberTimer(Handle timer, int ref)
{
	int weapon = EntRefToEntIndex(ref);
	if(weapon != -1)
	{
		int client = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
		if(client != -1 && IsPlayerAlive(client))
		{
			if(GetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel") > 0.05)
			{
				if(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == weapon)
				{
					TF2Tools_AddCondition(client, TFCond_HalloweenCritCandy, 0.5, client);

					if(GetEntProp(weapon, Prop_Send, "m_bHealing"))
					{
						int target = GetEntPropEnt(weapon, Prop_Send, "m_hHealingTarget");
						if(target != -1)
							TF2Tools_AddCondition(target, TFCond_HalloweenCritCandy, 0.5, client);
					}
				}

				return Plugin_Continue;
			}
		}
	}
	
	return Plugin_Stop;
}

static void ApplyRage(int victim, int attacker, float amount)
{
	if(Client(victim).RageDamage > 0.0)
	{
		float rage = Client(victim).GetCharge(0);
		float maxrage = Client(victim).RageMax;
		if(rage < maxrage)
		{
			rage += amount;
			if(rage > maxrage)
			{
				Bosses_PlaySoundToAll(victim, "sound_full_rage", _, victim, SNDCHAN_AUTO, SNDLEVEL_AIRCRAFT, _, SNDVOL_BOSS);
				rage = maxrage;
			}
			else if(rage < 0.0)
			{
				rage = 0.0;
			}
			
			Client(victim).SetCharge(0, rage);

			rage = amount / 100.0 * Client(victim).RageDamage;
			Client(attacker).Assist += RoundFloat(GetClientTeam(victim) == GetClientTeam(attacker) ? rage : -rage);
		}
	}
}

void CustomAttrib_CalcIsAttackCritical(int client, int weapon)
{
	float damage;
	if(CustomAttrib_Get(weapon, "melee sickle climb", damage))
	{
		float pos[3];
		float ang[3];
		GetClientEyePosition(client, pos);
		GetClientEyeAngles(client, ang);
		
		Handle trace = TR_TraceRayFilterEx(pos, ang, MASK_SOLID, RayType_Infinite, TraceRay_DontHitSelf, client);

		if(TR_DidHit(trace) && TR_GetEntityIndex(trace) == 0)
		{
			float vec[3];
			TR_GetPlaneNormal(trace, vec);
			GetVectorAngles(vec, vec);

			if(vec[0] < 30.0 || vec[0] > 330.0)
			{
				if(vec[0] > -30.0)
				{
					TR_GetEndPosition(vec, trace);

					if(GetVectorDistance(pos, vec, true) < 10000.0)
					{
						GetEntPropVector(client, Prop_Data, "m_vecVelocity", vec);
						vec[2] = 600.0;
						TeleportEntity(client, _, _, vec);

						if(damage > 0.0)
							SDKHooks_TakeDamage(client, client, client, damage, DMG_CLUB, 0);

						ClientCommand(client, "playgamesound player/taunt_clip_spin.wav");
					}
				}
			}
		}

		delete trace;
	}
}

static bool TraceRay_DontHitSelf(int entity, int mask, any data)
{
	return (entity != data);
}

// 유도 시야 체크용 트레이스 필터: 투사체 자신 + 다른 투사체 모두 무시
static bool HomingTraceFilter(int entity, int contentsMask, any data)
{
	if(entity == data)
		return false;

	if(entity > 0 && IsValidEntity(entity))
	{
		char classname[64];
		GetEntityClassname(entity, classname, sizeof(classname));
		if(StrContains(classname, "tf_projectile") != -1)
			return false;
	}

	return true;
}

// ============================================================
// Weapon Special: Back-Attack Detection (Backburner)
// ============================================================
bool WeaponSpecial_IsBackAttack(int attacker, int victim)
{
	float attackerPos[3], victimPos[3], victimAng[3], attackDir[3], fwd[3];
	GetClientAbsOrigin(attacker, attackerPos);
	GetClientAbsOrigin(victim, victimPos);
	GetClientEyeAngles(victim, victimAng);

	SubtractVectors(victimPos, attackerPos, attackDir);
	GetAngleVectors(victimAng, fwd, NULL_VECTOR, NULL_VECTOR);

	attackDir[2] = 0.0;
	fwd[2] = 0.0;
	NormalizeVector(attackDir, attackDir);
	NormalizeVector(fwd, fwd);

	return (GetVectorDotProduct(attackDir, fwd) > 0.0);
}

// ============================================================
// Weapon Special: Homing Projectile System
// ============================================================
#define HOMING_LIMIT 2049

static bool g_bHomingEnabled[MAXTF2PLAYERS];
static float g_flHomingStrength[MAXTF2PLAYERS];
static bool g_bHomingBodyTarget[MAXTF2PLAYERS];	// true = 몸통 유도, false = 머리(눈) 유도
static int g_iHomingOwner[HOMING_LIMIT];
static Handle g_hHomingTimer[HOMING_LIMIT];
static float g_flHomingProjStr[HOMING_LIMIT];
static bool g_bHomingProjBody[HOMING_LIMIT];	// 투사체별 몸통 유도 여부

void WeaponSpecial_HomingReset()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		g_bHomingEnabled[i] = false;
		g_flHomingStrength[i] = 0.0;
	}
}

void WeaponSpecial_HomingSetup(int client)
{
	g_bHomingEnabled[client] = false;
	g_flHomingStrength[client] = 0.0;
	g_bHomingBodyTarget[client] = false;

	if(Client(client).IsBoss || !IsRoundActive())
		return;

	// Secondary weapons: Flare Gun / Detonator / Scorch Shot
	int secWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(IsValidEntity(secWeapon))
	{
		int secIdx = GetEntProp(secWeapon, Prop_Send, "m_iItemDefinitionIndex");
		if(secIdx == 39 || secIdx == 351 || secIdx == 1081)	// Flare Gun / Detonator / Scorch Shot
		{
			g_bHomingEnabled[client] = true;
			g_flHomingStrength[client] = 0.5;
		}
		else if(secIdx == 1180)	// Gas Passer: 유도 + 탄약 3 고정
		{
			g_bHomingEnabled[client] = true;
			g_flHomingStrength[client] = 0.5;

			int ammoType = GetEntProp(secWeapon, Prop_Send, "m_iPrimaryAmmoType");
			if(ammoType >= 0)
				SetEntProp(client, Prop_Data, "m_iAmmo", 3, _, ammoType);
		}
		else if(secIdx == 812)	// 혈적자(Flying Guillotine): 탄약 3 고정
		{
			int ammoType = GetEntProp(secWeapon, Prop_Send, "m_iPrimaryAmmoType");
			if(ammoType >= 0)
				SetEntProp(client, Prop_Data, "m_iAmmo", 3, _, ammoType);
		}
	}

	// Primary weapons: Huntsman / Crusader Crossbow / Pomson / Widowmaker / etc.
	int priWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if(IsValidEntity(priWeapon))
	{
		int priIdx = GetEntProp(priWeapon, Prop_Send, "m_iItemDefinitionIndex");
		if(priIdx == 56 || priIdx == 1005)	// Huntsman
		{
			g_bHomingEnabled[client] = true;
			g_flHomingStrength[client] = 0.25;
			g_bHomingBodyTarget[client] = true;	// 몸통 유도
		}
		else if(priIdx == 1092)	// Fortified Compound
		{
			g_bHomingEnabled[client] = true;
			g_flHomingStrength[client] = 0.9;
		}
		else if(priIdx == 305)	// Crusader's Crossbow
		{
			g_bHomingEnabled[client] = true;
			g_flHomingStrength[client] = 0.2;
		}
		else if(priIdx == 527)	// Widowmaker
		{
			g_bHomingEnabled[client] = true;
			g_flHomingStrength[client] = 0.8;
		}
		else if(priIdx == 588)	// Pomson 6000
		{
			g_bHomingEnabled[client] = true;
			g_flHomingStrength[client] = 0.4;
		}
	}
}

// 유도 대상 투사체인지 확인 (SpawnPost 안 불리는 경우를 위해 별도 함수)
static bool IsHomingProjectileClass(const char[] classname)
{
	return (StrContains(classname, "tf_projectile_flare") != -1 ||
		StrContains(classname, "tf_projectile_arrow") != -1 ||
		StrContains(classname, "tf_projectile_energy_ball") != -1 ||
		StrContains(classname, "tf_projectile_rocket") != -1 ||
		StrContains(classname, "tf_projectile_sentryrocket") != -1 ||
		StrEqual(classname, "tf_projectile_jar_gas") ||
		StrEqual(classname, "tf_projectile_jar") ||
		StrEqual(classname, "tf_projectile_jar_milk"));
}

static bool g_bHomingChecked[HOMING_LIMIT];	// SpawnPost에서 이미 처리했는지

void WeaponSpecial_OnEntityDestroyed(int entity)
{
	if(entity > 0 && entity < HOMING_LIMIT)
	{
		g_hHomingTimer[entity] = null;
		g_iHomingOwner[entity] = 0;
		g_flHomingProjStr[entity] = 0.0;
		g_bHomingProjBody[entity] = false;
		g_bHomingChecked[entity] = false;
	}
}

void WeaponSpecial_OnEntityCreated(int entity, const char[] classname)
{
	if(entity > 0 && entity < HOMING_LIMIT)
		g_bHomingChecked[entity] = false;

	if(entity < HOMING_LIMIT && IsHomingProjectileClass(classname))
	{

		SDKHook(entity, SDKHook_SpawnPost, WeaponSpecial_HomingSpawnPost);
		// SpawnPost가 안 불릴 수 있으므로 RequestFrame으로도 체크
		RequestFrame(WeaponSpecial_HomingFrameCheck, EntIndexToEntRef(entity));
	}
}

static void WeaponSpecial_HomingSpawnPost(int entity)
{

	WeaponSpecial_HomingApply(entity, "SpawnPost");
}

static void WeaponSpecial_HomingFrameCheck(int entref)
{
	int entity = EntRefToEntIndex(entref);
	if(entity == INVALID_ENT_REFERENCE || !IsValidEntity(entity) || entity >= HOMING_LIMIT)
		return;

	// SpawnPost에서 이미 처리됐으면 스킵
	if(g_bHomingChecked[entity])
		return;

	// 투사체 클래스 재확인
	char cls[64];
	GetEntityClassname(entity, cls, sizeof(cls));
	if(!IsHomingProjectileClass(cls))
		return;


	WeaponSpecial_HomingApply(entity, "Frame");
}

static void WeaponSpecial_HomingApply(int entity, const char[] source)
{
	if(!IsValidEntity(entity) || entity >= HOMING_LIMIT)
		return;

	g_bHomingChecked[entity] = true;

	// 이미 타이머가 있으면 중복 방지
	if(g_hHomingTimer[entity] != null)
		return;

	char cls[64];
	GetEntityClassname(entity, cls, sizeof(cls));

	int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	if(owner < 1 || owner > MaxClients || !IsClientInGame(owner))
	{

		return;
	}

	if(!g_bHomingEnabled[owner])
	{

		return;
	}

	g_iHomingOwner[entity] = owner;
	g_flHomingProjStr[entity] = g_flHomingStrength[owner];
	g_bHomingProjBody[entity] = g_bHomingBodyTarget[owner];

	g_hHomingTimer[entity] = CreateTimer(0.01, Timer_HomingUpdate, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

}

static int g_iHomingTick[HOMING_LIMIT];

static Action Timer_HomingUpdate(Handle timer, any entref)
{
	int entity = EntRefToEntIndex(entref);
	if(entity == INVALID_ENT_REFERENCE || !IsValidEntity(entity) || entity >= HOMING_LIMIT)
	{
		if(entity > 0 && entity < HOMING_LIMIT)
			g_hHomingTimer[entity] = null;

		return Plugin_Stop;
	}

	int owner = g_iHomingOwner[entity];
	if(owner <= 0 || owner > MaxClients || !IsClientInGame(owner) || !IsPlayerAlive(owner))
	{
		g_hHomingTimer[entity] = null;

		return Plugin_Stop;
	}

	g_iHomingTick[entity]++;

	int target = WeaponSpecial_HomingFindTarget(entity, GetClientTeam(owner));
	if(target <= 0)
	{
		if(g_iHomingTick[entity] % 30 == 1)

		return Plugin_Continue;
	}

	float projPos[3], targetPos[3];
	float projVel[3], projAng[3];

	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", projPos);

	// 몸통 유도: 배꼽 높이 (발 + 눈 중간), 머리 유도: 눈 위치
	if(g_bHomingProjBody[entity])
	{
		float feet[3], eyes[3];
		GetClientAbsOrigin(target, feet);
		GetClientEyePosition(target, eyes);
		targetPos[0] = feet[0];
		targetPos[1] = feet[1];
		targetPos[2] = (feet[2] + eyes[2]) * 0.5;
	}
	else
	{
		GetClientEyePosition(target, targetPos);
	}

	GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", projVel);
	float projSpeed = GetVectorLength(projVel);
	if(projSpeed < 1.0)
		return Plugin_Continue;

	// LERP 방식: 현재 방향과 타겟 방향을 t 비율로 보간
	float targetDir[3], curDir[3];
	SubtractVectors(targetPos, projPos, targetDir);
	NormalizeVector(targetDir, targetDir);
	NormalizeVector(projVel, curDir);

	float t = g_flHomingProjStr[entity];
	projVel[0] = curDir[0] * (1.0 - t) + targetDir[0] * t;
	projVel[1] = curDir[1] * (1.0 - t) + targetDir[1] * t;
	projVel[2] = curDir[2] * (1.0 - t) + targetDir[2] * t;

	NormalizeVector(projVel, projVel);
	GetVectorAngles(projVel, projAng);

	SetEntPropVector(entity, Prop_Data, "m_angRotation", projAng);
	ScaleVector(projVel, projSpeed);
	SetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", projVel);

	return Plugin_Continue;
}

static int WeaponSpecial_HomingFindTarget(int entity, int ownerTeam)
{
	float entityPos[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", entityPos);

	int closest = 0;
	float closestDist = 3000.0;

	for(int client = 1; client <= MaxClients; client++)
	{
		if(!IsClientInGame(client) || !IsPlayerAlive(client))
			continue;

		if(GetClientTeam(client) == ownerTeam)
			continue;

		float pos[3];
		GetClientEyePosition(client, pos);
		float dist = GetVectorDistance(entityPos, pos);

		if(dist > closestDist)
			continue;

		Handle trace = TR_TraceRayFilterEx(entityPos, pos, MASK_SOLID, RayType_EndPoint, HomingTraceFilter, entity);
		bool blocked = TR_DidHit(trace);
		int hitEntity = -1;
		if(blocked)
			hitEntity = TR_GetEntityIndex(trace);
		delete trace;

		if(blocked && hitEntity != client)
			continue;

		if(dist < closestDist)
		{
			closest = client;
			closestDist = dist;
		}
	}
	return closest;
}

// ============================================================
// Weapon Special: Candy Cane Health Pack on Hit
// ============================================================
void WeaponSpecial_CandyCaneCheck(int attacker, int victim, int weapon)
{
	if(weapon == -1)
		return;

	int weaponIdx = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	if(weaponIdx == 317)	// Candy Cane
	{
		float position[3];
		GetClientAbsOrigin(victim, position);
		position[2] += 20.0;

		float velocity[3];
		velocity[0] = GetRandomFloat(-50.0, 50.0);
		velocity[1] = GetRandomFloat(-50.0, 50.0);
		velocity[2] = 75.0;

		int entity = CreateEntityByName("item_healthkit_small");
		if(IsValidEntity(entity))
		{
			DispatchKeyValue(entity, "OnPlayerTouch", "!self,Kill,,0,-1");
			DispatchSpawn(entity);
			SetEntProp(entity, Prop_Send, "m_iTeamNum", GetClientTeam(attacker));
			TeleportEntity(entity, position);
			SDKCall_DropSingleInstance(entity, velocity, attacker, 0.1);
		}
	}
}

// ============================================================
// Weapon Special: Eyelander Head Collection
// ============================================================
void WeaponSpecial_EyelanderCheck(int attacker, int weapon)
{
	if(weapon == -1)
		return;

	int weaponIdx = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	// Eyelander, HHHH, Nessie's Nine Iron, Festive Eyelander
	if(weaponIdx == 132 || weaponIdx == 266 || weaponIdx == 482 || weaponIdx == 1082)
	{
		int heads = GetEntProp(attacker, Prop_Send, "m_iDecapitations") + 1;
		SetEntProp(attacker, Prop_Send, "m_iDecapitations", heads);
		TF2Tools_AddCondition(attacker, TFCond_DemoBuff, -1.0);

		// +15 HP per head
		int maxhp = SDKCall_GetMaxHealth(attacker);
		int hp = GetClientHealth(attacker) + 15;
		if(hp > maxhp + (heads * 15))
			hp = maxhp + (heads * 15);
		SetEntityHealth(attacker, hp);

		// Speed boost
		TF2Tools_AddCondition(attacker, TFCond_SpeedBuffAlly, 0.01);
	}
}

// ============================================================
// Weapon Special: Soldier Banner Buff Sync
// ============================================================
static Handle g_hSoldierBuffTimer;

void WeaponSpecial_BannerStart()
{
	WeaponSpecial_BannerStop();
	g_hSoldierBuffTimer = CreateTimer(0.5, Timer_SoldierBuffSync, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

void WeaponSpecial_BannerStop()
{
	if(g_hSoldierBuffTimer != null)
	{
		delete g_hSoldierBuffTimer;
		g_hSoldierBuffTimer = null;
	}
}

static Action Timer_SoldierBuffSync(Handle timer)
{
	if(!Enabled)
	{
		g_hSoldierBuffTimer = null;
		return Plugin_Stop;
	}

	for(int client = 1; client <= MaxClients; client++)
	{
		if(!IsClientInGame(client) || !IsPlayerAlive(client) || Client(client).IsBoss)
			continue;

		if(TF2_GetPlayerClass(client) != TFClass_Soldier)
			continue;

		if(TF2_IsPlayerInCondition(client, TFCond_Buffed))
		{
			TF2Tools_AddCondition(client, TFCond_DefenseBuffed, 0.6);
			TF2Tools_AddCondition(client, TFCond_RegenBuffed, 0.6);
		}
	}
	return Plugin_Continue;
}
