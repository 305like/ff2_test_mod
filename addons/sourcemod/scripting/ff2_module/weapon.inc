#if defined _ff2_weapon_included
    #endinput
#endif
#define _ff2_weapon_included

/**
 * FF2 Weapon Modifications
 * Weapon attribute changes for all TF2 classes via TF2Items.
 */

/*Soon(TM)
void CreateWeaponModsKeyValues()
{
	if(kvWeaponSpecials!=null)
	{
		delete kvWeaponSpecials;
	}

	kvWeaponSpecials=KeyValues("WeaponSpecials");
	for(int i=0; i<sizeof(WeaponSpecials); i++)
	{
		kvWeaponSpecials.JumpToKey(WeaponSpecials[i], true);

		kvWeaponSpecials.KvJumpToKey("ByClassname", true);
		kvWeaponSpecials.GoBack();

		kvWeaponSpecials.JumpToKey("ByIndex", true);
		kvWeaponSpecials.GoBack();

		kvWeaponSpecials.GoBack();
	}
}*/

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int iItemDefinitionIndex, Handle& item)
{
	if(!Enabled /*|| item!=null*/)
	{
		return Plugin_Continue;
	}

	//TODO: "onhit", "ontakedamage"
	//TODO: Also support comma-delimited strings, eg "38, 457" or "tf_weapon_knife, tf_weapon_katana"
	static Handle weapon;
	if(weapon!=null)
	{
		delete weapon;
	}

	if(!IsBoss(client))
	{
		char itemString[8];
		IntToString(iItemDefinitionIndex, itemString, sizeof(itemString));

		kvWeaponMods.Rewind();
		bool differentClass;
		if(kvWeaponMods.JumpToKey(classname) || kvWeaponMods.JumpToKey(itemString))
		{
			Debug("Entered classname %s or index %i", classname, iItemDefinitionIndex);
			if(kvWeaponMods.JumpToKey("replace"))
			{
				Debug("\tEntered replace");
				char newClass[64];
				kvWeaponMods.GetString("classname", newClass, sizeof(newClass));
				Debug("\t\tNew classname is %s", newClass);

				int flags=OVERRIDE_ITEM_DEF|OVERRIDE_ATTRIBUTES|FORCE_GENERATION;
				int index=kvWeaponMods.GetNum("index", -1);
				if(index<0)
				{
					LogError("[FF2 Weapons] \"replace\" is missing item definition index for classname %s or index %i!", classname, iItemDefinitionIndex);
					return Plugin_Stop;
				}

				if(!StrEqual(classname, newClass))
				{
					flags|=OVERRIDE_CLASSNAME;
					differentClass=true;
					strcopy(classname, 64, newClass);
				}

				int level=kvWeaponMods.GetNum("level", -1);
				if(level>-1)
				{
					flags|=OVERRIDE_ITEM_LEVEL;
				}
				else if(differentClass)  //If level wasn't set and we're switching classnames automatically set the level to 1
				{
					level=1;
				}

				int quality=kvWeaponMods.GetNum("quality", -1);
				if(quality>-1)
				{
					flags|=OVERRIDE_ITEM_QUALITY;
				}
				else if(differentClass)  //Ditto here
				{
					quality=0;
				}

				weapon=TF2Items_CreateItem(flags);
				TF2Items_SetClassname(weapon, classname);
				TF2Items_SetQuality(weapon, quality);
				TF2Items_SetLevel(weapon, level);
				Debug("\t\tGave new weapon with classname %s, index %i, quality %i, and level %i", classname, index, quality, level);
				int entity=TF2Items_GiveNamedItem(client, weapon);
				EquipPlayerWeapon(client, entity);

				delete weapon;

				kvWeaponMods.GoBack();
			}

			if(kvWeaponMods.JumpToKey("add"))
			{
				Debug("\tEntered add");
				char attributes[32][8];
				int attribCount;
				for(int key; kvWeaponMods.GotoNextKey(); key+=2)
				{
					if(key>=32)
					{
						LogError("[FF2 Weapons] Weapon %s (index %i) has more than 16 attributes, ignoring the rest", classname, iItemDefinitionIndex);
						break;
					}

					attribCount++;
					kvWeaponMods.GetSectionName(attributes[key], 8);
					kvWeaponMods.GetString(attributes[key], attributes[key+1], 8);
					Debug("\t\tAttribute set %i is %s ; %s", attribCount, attributes[key], attributes[key+1]);
				}

				if(attribCount)
				{
					int entity=FindEntityByClassname(-1, classname);
					for(int attribute; attribute<attribCount; attribute+=2)
					{
						int attrib=StringToInt(attributes[attribute]);
						if(!attrib)  //StringToInt will return 0 on failure, which probably means the attribute was specified by name, not index
						{
							TF2Attrib_SetByName(entity, attributes[attribute], StringToFloat(attributes[attribute+1]));
							Debug("\t\tAdded attribute set %s ; %s", attributes[attribute], attributes[attribute+1]);
						}
						else if(attrib<0)
						{
							LogError("[FF2 Weapons] Ignoring attribute %i passed for weapon %s (index %i) while adding attributes", attrib, classname, iItemDefinitionIndex);
						}
						else
						{
							TF2Attrib_SetByDefIndex(entity, attrib, StringToFloat(attributes[attribute+1]));
							Debug("\t\tAdded attribute set %s ; %s", attributes[attribute], attributes[attribute+1]);
						}
					}
				}
				kvWeaponMods.GoBack();
			}

			if(kvWeaponMods.JumpToKey("remove"))
			{
				Debug("\tEntered remove");
				char attributes[16][8];
				int entity=FindEntityByClassname(-1, classname);
				for(int key; kvWeaponMods.GotoNextKey() && key<16; key++)
				{
					kvWeaponMods.GetSectionName(attributes[key], 8);
					int attribute=StringToInt(attributes[key]);
					if(!attribute)  //StringToInt will return 0 on failure, which probably means the attribute was specified by name, not index
					{
						if(StrEqual(attributes[key], "all"))
						{
							TF2Attrib_RemoveAll(entity);
							Debug("\t\tRemoved all attributes");
							break;  //Just exit the for loop since we've already removed all attributes
						}
						else
						{
							TF2Attrib_RemoveByName(entity, attributes[key]);
							Debug("\t\tRemoved attribute %s", attributes[key]);
						}
					}
					else if(attribute<0)
					{
						LogError("[FF2 Weapons] Ignoring attribute %s passed for weapon %s (index %i) while removing attributes", attributes[key], classname, iItemDefinitionIndex);
					}
					else
					{
						TF2Attrib_RemoveByDefIndex(entity, attribute);
						Debug("\t\tRemoved attribute %i", attribute);
					}
				}
				kvWeaponMods.GoBack();
			}
		}

	}

switch(iItemDefinitionIndex)
{
	// ==================== SCOUT ====================
	
	// === 주무기 (Primary) ===
	case 13, 200, 669, 799, 808, 888, 897, 906, 915, 964, 973: // 스캐터건✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "106 ; 0.90", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	case 772: // 동안의 총✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "6 ; 0.3 ; 45 ; 0.1 ; 4 ; 3 ; 4519 ; 1 ; 96 ; 12 ; 2 ; 2.2 ; 76 ; 3.13", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	case 1103: // 등짝 작렬총✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "179 ; 1 ; 15 ; 0");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	case 220: // 유격수✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "6 ; 0.9");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	case 448: // 탄산총✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "97 ; 0.65");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	case 45, 1078: // 자연의섭리✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "45 ; 1.3");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	// === 보조무기 (Secondary) ===
	case 23, 209: // 권총✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "4 ; 1.5", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	case 294: // 루거모프✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "4 ; 1.5 ; 107 ; 1.05", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	case 30666: // 선장의 고급진 펄스트론 입자 전자기 광선총✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "4 ; 1.5 ; 2 ; 1.05", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	case 222, 1121: // 미치광이 우유✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "280 ; 17 ; 1 ; 10 ; 103 ; 1.5", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	case 812: // 혈적자✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "280 ; 13 ; 278 ; 0 ; 103 ; 2 ; 6 ; 0.5 ; 411 ; 2.5 ; 392 ; 0.25 ; 15 ; 1 ; 288 ; 1", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	case 46, 1145: // 봉크! 원자맛 음료✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "201 ; 1.25 ; 414 ; 8.0", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	case 163: // 훅가콜라✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "201 ; 1.25 ; 278 ; 0.8", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	case 773: // 계집애 같은 사내의 소형 권총✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "4477 ; 32 ; 4478 ; 3 ; 3 ; 1", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	case 449: // 윙어✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "4 ; 0.5 ; 1 ; 2 ; 106 ; 0.5 ; 6 ; 1.5", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	// === 근접무기 (Melee) ===
	case 0, 190, 660: // 방망이✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "2 ; 1.1");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	case 221, 999: // 고등어 이쿠✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "2 ; 1.05 ; 6 ; 0.95");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	case 572: // 비무장 지대✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "2 ; 1.03 ; 6 ; 0.97 ; 107 ; 1.03");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	case 30667: // 광봉✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "2 ; 1.15");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	case 44: // 샌드맨✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "125 ; -35 ; 278 ; 0.8");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	case 317: // 지팡이 사탕✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "26 ; 25 ; 54 ; 0.95 ; 65 ; 1");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	case 648: // 포장지 암살자✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "279 ; 10.0 ; 1 ; 0.05");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	case 325: // 보스턴의 깡패✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "2 ; 1.50");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	case 355: // 죽음의 부채✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.05");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	case 452: // 삼륜검✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "2 ; 3 ; 54 ; 0.85 ; 49 ; 1");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	case 349: // 해를 품은 막대✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.75 ; 60 ; 1");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	case 450: // 인수분해✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "326 ; 1.5 ; 773 ; 1 ; 138 ; 1 ; 1 ; 0.75");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	// ==================== SOLDIER ====================
	
	// === 주무기 (Primary) ===
	
	case 18, 800, 205, 658, 809, 889, 898, 907, 916, 965, 974: // 로켓 발사기✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "99 ; 1.1", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 127: // 직격포✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "100 ; 0.2 ; 103 ; 1.8 ; 114 ; 1 ; 179 ; 1 ; 2 ; 1.5", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 228, 1085: // 블랙 박스✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "4 ; 1 ; 16 ; 25 ; 104 ; 0.75 ; 741 ; 0 ; 4411 ; 1 ; 1 ; 0.34", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 414: // 자유투사✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "4 ; 1.5 ; 103 ; 1.5 ; 1 ; 0.80 ; 99 ; 1.25 ; 135 ; 0.75", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 513: // 원조✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "2 ; 1.05", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 730: // 거지의 바주카✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.5 ; 97 ; 0.75 ; 6 ; 0.5 ; 4 ; 3 ; 417 ; 0 ; 411 ; 0 ; 413 ; 1", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 1104: // 공중 포격포✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "135 ; 0.75 ; 97 ; 0.75 ; 6 ; 0 ; 411 ; 5 ; 1 ; 0.75", true);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 237: // 로켓점퍼✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 3.0 ; 181 ; 0 ; 76 ; 1.0 ; 103 ; 1.5 ; 3 ; 0.25 ; 96 ; 1.5 ; 621 ; 0", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 441: // 소도륙 5000✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "27 ; 1 ; 4522 ; 7 ; 6 ; 0.33 ; 4521 ; -3 ; 335 ; 3  ; 97 ; 0.75 ; 4668 ; 1 ; 104 ; 0.6 ", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	// === 보조무기 (Secondary) ===
	
		case 10, 12, 11, 9, 199, 1141: // 산탄총✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "45 ; 1.2", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 129, 1001: // 사기 증진 깃발✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "4692 ; 0.3 ; 116 ; 1 ; 107 ; 1.15", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 226: // 부대지원✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "4692 ; 0.3 ; 116 ; 1 ; 26 ; 50", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 354: // 전복자✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "4692 ; 0.3 ; 116 ; 1 ; 107 ; 1.05 ; 57 ; 5", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 415: // 부사수✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "2 ; 1.1 ; 3 ; 0.5 ; 114 ; 1 ; 179 ; 1 ; 547 ; 1 ; 178 ; 0.75 ", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 442: // 정의의 들소✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "335 ; 1000 ; 103 ; 1.5 ; 6 ; 0.25 ; 4519 ; 1 ; 392 ; 0.25", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 133: // 건보츠✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "64 ; 0.1 ; 135 ; 0.1", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 444: // 인간딛개✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "26 ; 50 ; 64 ; 0.6 ; 135 ; 0.6", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 1101: // 고지 도약기✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "26 ; 50");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	// === 근접무기 (Melee) ===
		case 357: // 자토이치✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "264 ; 1.5", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 6: // 야전삽✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "2 ; 1.1", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 128: // 등가교환기✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, " 2 ; 6 ; 851 ; 0.1 ; 115 ; 0", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 154: // 고통행 열차✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "264 ; 1.5 ; 852 ; 1.2", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 416: // 마캣가든 모종삽✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "6 ; 1", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 447: // 징계조치✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "6 ; 0 ; 1 ; 0.01", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 775: // 탈출계획
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "414 ; 0");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}

	
	// ==================== PYRO ====================
	
	// === 주무기 (Primary) ===
	
		case 21, 208, 659, 798, 807, 887, 896, 905, 914, 963, 972: // 화염방사기✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "2 ; 1.1");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 40, 1146: // 백버너✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "4421 ; 4.0");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 215: // 기름때 제거기✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "199 ; 1 ; 547 ; 1 ; 178 ; 0.5 ; 71 ; 1 ; 74 ; 0.5 ; 76 ; 1.5 ; 170 ; 1, false");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
		case 30474: // 노스트로모호 네이팜 분사기✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "2 ; 1.1 ; 73 ; 1.5");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 1178: // 용의 격노
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "801 ; 0.4 ; 76 ; 2 ; 171 ; 0.2");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 741: // 무지개 뿌리개✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.75 ; 844 ; 8000, false");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 594: // 플로지스톤✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "2 ; 1.2");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	// === 보조무기 (Secondary) ===

		case 39, 351, 1081: // 조명탄 발사기, 기폭장치✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "25 ; 0.5 ; 58 ; 3.2 ; 144 ; 1.0 ; 4358 ; 20 ; 20 ; 1", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 740: // 그슬린 한방✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "280 ; 2 ; 99 ; 1.5 ; 208 ; 1 ; 103 ; 2.2 ; 2 ; 2", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 1180: // 가스패서✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "848 ; 0 ; 878 ; 0 ; 874 ; 0.5 ; 879 ; 0 ; 845 ; 0 ; 801 ; 10 ; 856 ; 3 ; 280 ; 2 ; 103 ; 1.5 ; 4358 ; 500 ; 1 ; 1.5 ; 208 ; 1 ; 642 ; 1 ; 6 ; 2", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 1179: // 가열가속기✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "874 ; 0.75 ; 26 ; 75 ; 840 ; 0");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 595: // 인간 융해 장치✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "6 ; 0.05 ; 411 ; 2.5 ; 103 ; 2 ; 1 ; 0.67 ; 4521 ; -5 ; 4522 ; 5 ; 4428 ; 5000", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	// === 근접무기 (Melee) ===
	
		case 2, 192: // 소방도끼✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "2 ; 1.1", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 38, 1000: // 소화도끼✅
	{
		Handle itemOverride=PrepareItemHandle(item, "tf_weapon_fireaxe",_, "2067 ; 0 ; 1 ; 1 ; 772 ; 1 ; 21 ; 0.5 ; 22 ; 1 ; 795 ; 2", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 457: // 전사통지✅
	{
		Handle itemOverride=PrepareItemHandle(item, "tf_weapon_fireaxe",_, "2067 ; 0 ; 772 ; 1 ; 2 ; 2 ; 6 ; 1.5", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 153: // 가정파괴범✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "137 ; 1 ; 138 ; 1 ; 4644 ; 3 ; 6 ; 3", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
		case 466: // 쇠매
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "137 ; 1 ; 138 ; 1 ; 149 ; 10 ; 264 ; 0.8", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 214: // 전원잭✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "54 ; 1.33 ; 77 ; 0.5 ; 79 ; 0.5 ; 852 ; 1", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 326: // 효자손✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "108 ; 100 ; 69 ; 0 ; 853 ; 0 ; 2 ; 1 ; 57 ; 25", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 348: // 날카로운 화산파편✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "2 ; 1.2 ; 71	; 1.5 ; 107 ; 0.9 ; 208 ; 1", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 593: // 3도화상✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.75", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
		case 739: // 학대사탕✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.5 ; 16 ; 25 ; 6 ; 0.67", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
		case 813, 834: // 네온전멸기✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "138 ; 1 ; 4367 ; 100 ; 4548 ; -1 ; 4418 ; 1 ; 2 ; 0.5 ; 6 ; 1.5", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
		case 1181: // 화끈한손✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, " 6 ; 0 ; 204 ; 1", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}

	// ==================== DEMOMAN ====================
	
	// === 주무기 (Primary) ===
		case 19, 206: // 유탄발사기✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "4 ; 1.5 ; 76 ; 1.9", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 308: // 로드 앤 로크✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "4430 ; 1 ; 3 ; 0.6 ; 103 ; 2 ; 6 ; 0.5 ; 2 ; 1.5", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 996: // 통제불능 대포✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "3 ; 0.25 ; 99 ; 1.5 ; 4411 ; 1");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 1151: // 무쇠 폭탄 발사기✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "413 ; 1 ; 103 ; 1.25 ; 6 ; 0.5 ; 4430 ; 1", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 405: // 알리바바의 조각된 신발✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "26 ; 75 ; 788 ; 1 ; 107 ; 1.2 ; 249 ; 1.25", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 608: // 밀주업자✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "26 ; 75 ; 788 ; 1 ; 107 ; 1.2 ; 249 ; 1.25", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	// === 보조무기 (Secondary) ===
		case 265: // 점착 점프 장치
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 3.0 ; 181 ; 0 ; 76 ; 1.0 ; 97 ; 1.5 ; 120 ; 1 ; 89 ; -6", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 20, 207, 661, 797, 806, 886, 895, 904, 913, 962, 971: // 점착폭탄 발사기✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "99 ; 1.1", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 130: // 스코틀랜드식 저항운동
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "88 ; 22 ; 100 ; 0.8 ; 6 ; 1 ; 119 ; 0");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 1150: // 순삭 폭탄 발사기✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "126 ; -1 ; 4 ; 0.15 ; 99 ; 1.5 ; 670 ; 0 ; 6 ; 0.75 ; 96 ; 0.75 ; 89 ; -7 ; 727 ; 1", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 131, 1144: // 돌격 방패✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "412 ; 0.66", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 406: // 경이로운 차폐막✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "249 ; 2.0", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 1099: // 조류 조타기✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "202 ; 3", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		// === 근접무기 (Melee) ===
		
		case 1, 191: // 술병✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "2 ; 1.1", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		
		case 609: // 스코틀랜드식 악수✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "6 ; 0.9", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		
		case 132, 482, 1082, 266: // 아이랜더, 아이언 9번 골프채✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "4477 ; 32 ; 4478 ; 3");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		
		case 172: // 스코틀랜드인의 머리따개✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "2 ; 2 ; 54 ; 0.8", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		
		case 327: // 클레이브 모어✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "6 ; 2 ; 264 ; 3 ; 4477 ; 32 ; 4478 ; 3", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		
		case 404: // 페르시아식 설득 도구✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "778 ; 100 ; 782 ; 0 ; 249 ; 0.2 ; 77 ; 1 ; 79 ; 1 ; 246 ; 6", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		
		case 307: // 울라플 막대✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "6 ; 1.5 ; 2 ; 2", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}

	// ==================== HEAVY ====================
	
	// === 주무기 (Primary) ===
	
		
		case 15, 202, 793, 654, 802, 882, 891, 900, 909, 958, 967: // 미니건✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "106 ; 0.9", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		
		case 312: // 황동야수✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "2 ; 1.3 ; 36 ; 1.25 ; 4347 ; 1 ; 183 ; 1 ; 86 ; 1", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		
		case 424: // 토미슬라프✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "106 ; 0.2 ; 87 ; 0 ; 6 ; 1.3 ; 4347 ; 1", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		
		case 298: // 철의장막✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "412 ; 0.66 ; 77 ; 0.25 ; 6 ; 0.67", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
		case 41: // 나타샤✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "280 ; 3 ; 103 ; 9999 ; 6 ; 3.5 ; 4430 ; 1 ; 1 ; 8.3 ; 77 ; 0.2 ; 86 ; 1", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 811, 832: // 화룡포 발열기✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "209 ; 1 ; 76 ; 1.5 ; 430 ; 100 ; 1 ; 0.9", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	// === 보조무기 (Secondary) ===
	
		case 425: // 가족사업✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "4518 ; 1 ; 4519 ; 1 ; 45 ; 5 ; 36 ; 5 ; 96 ; 25 ; 79 ; 0.13 ; 1 ; 1", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 1153: // 공황공격✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "413 ; 1 ; 6 ; 0.25 ; 4 ; 5 ; 4519 ; 1 ; 78 ; 2 ; 96 ; 10 ; 1 ; 1 ; 45 ; 0.34 ; 106 ; 0.2", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
		
		case 42, 1002: // 샌드비치✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "26 ; 50", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 863: // 로보 샌드비치✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "26 ; 60", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		
		case 159: // 달로코스 바✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "26 ; 25 ; 107 ; 1.1", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		
		case 433: // 어육완자✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "26 ; 30 ; 107 ; 1.15", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		
		case 311: // 버팔로 스테이크 샌드비치✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "57 ; 15 ; 144 ; 0 ; 856 ; 1 ; 801 ; 30", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		
		case 1190: // 2인자의 바나나✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "77 ; 1.25 ; 79 ; 1.25", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	// === 근접무기 (Melee) ===
	
		case 5, 195: // ✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "201 ; 1.5", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 239, 1084: // G.R.U✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.5 ; 107 ; 1.5 ; 128 ; 1 ; 191 ; -7", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 1100: // 빵으로 물기✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.5 ; 107 ; 1.5 ; 128 ; 1 ; 191 ; -6", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		
		case 43: // K.G.B✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "326 ; 1.5 ; 250 ; 1 ; 125 ; 50", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 331: // 강철주먹✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "412 ; 0.8 ; 206 ; 1 ; 772 ; 1 ; 853 ; 1 ; 854 ; 1 ; 1 ; 0.5", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 426: // 퇴거 통보✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "6 ; 0 ; 1 ; 0.05 ; 855 ; 0 ; 4477 ; 32 ; 4478 ; 3", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 310: // 전사의 혼✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "852 ; 1 ; 2 ; 1.33 ; 16 ; 50 ; 54 ; 0.9", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 656: // 휴일빵✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "6 ; 16 ; 15 ; 1 ; 288 ; 1", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	// ==================== ENGINEER ====================
	
	// === 주무기 (Primary) ===
	
		case 527: // 과부 제조기✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "280 ; 2 ; 642 ; 1 ; 4358 ; 200 ; 4577 ; 0.15 ; 103 ; 0.1 ; 4406 ; 3000 ; 4448 ; 0.15 ; 100 ; 0.1 ; 2 ; 15 ; 299 ; 0 ; 298 ; 25 ; 4421 ; 0.5 ; 6 ; 1.2");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 141: // 개척자의 정의✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "3 ; 0.2 ; 45 ; 0.1 ; 1 ; 50 ; 96 ; 3.5 ; 6 ; 1.8 ; 4388 ; 50", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 588: // 폼슨 6000✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "4358 ; 300 ; 4539 ; 1 ; 6 ; 3 ; 307 ; 1 ; 335 ; 9999 ; 97 ; 0 ; 15 ; 1 ; 288 ; 1 ; 869 ; 1", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		
		case 997: // 구조대원✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "469 ; -1 ; 474 ; 75 ; 472 ; 0 ; 3 ; 1 ; 1 ; 0.5");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	// === 보조무기 (Secondary) ===
	
		case 140: // 원격 조련장비✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "287 ; 1.1", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}

		case 528: // 합선기✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 30668: // 기거 계수기✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "287 ; 1.15", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}

	// === 근접무기 (Melee) ===
	
		
		case 7, 197, 662, 795, 804, 884, 893, 902, 911, 960, 969: // 렌치✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "92 ; 1.25", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		
		case 329: // 뾰족렌치✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.5 ; 321 ; 0.5 ; 148 ; 1.5 ; 6 ; 0.75 ; 2043 ; 2 ; 95 ; 0.5", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		
		case 155: // 남부의 환영방식✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "149 ; 0 ; 61	; 1 ; 732 ; 100 ; 1 ; 0.5 ; 54 ; 0.75", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		
		case 589: // 유래카 효과✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "125 ; -25 ; 4357 ; 0.75 ; 93 ; 1 ; 732 ; 1 ; 790 ; 1");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 142: // 총잡이✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "124 ; 0 ; 26 ; 75 ; 4353 ; 1");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	// ==================== MEDIC ====================
	
	// === 주무기 (Primary) ===
	
		case 17, 204: // 주사기총✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "17 ; 0.03", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 305, 1079: // 십자군의 쇠뇌✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "4358 ; 15 ; 1 ; 0.2 ; 17 ; 0.03 ; 6 ; 0.75 ; 97 ; 0.15 ");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
		
		case 36: // 블루트자우거✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "4477 ; 57 ; 4478 ; 0.3 ; 6 ; 2 ; 3 ; 0.5 ; 2 ; 1.5 ; 17 ; 0.04 ; 96 ; 2 ; 881 ; 0");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 412: // 약물납용✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "4477 ; 32 ; 4478 ; 3 ; 128 ; 1 ; 191 ; -7 ; 792 ; 1.8 ; 1 ; 1");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	// === 보조무기 (Secondary) ===
		
		case 29, 211, 663, 796, 805, 885, 894, 903, 912, 961, 970: // 메디건✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "10 ; 1.5", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 411: // 응급조치✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "7 ; 1.5 ; 9 ; 0.75", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 35: // 크리츠크릿✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "7 ; 0.75 ; 105 ; 0.5", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 998: // 예방접종✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "7 ; 0.1 ; 4641 ; 10 ; 4648 ; 0.5", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	// === 근접무기 (Melee) ===
	
		case 8, 198, 1143: // 뼈톱✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "2 ; 1.1", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		
		case 37, 1003: // 우버쏘우✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "17 ; 0.2 ; 5 ; 1", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
		
		case 173: // 비타쏘우✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "125 ; -25");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
		
		case 304: // 절단기✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.5 ; 190 ; 0 ; 130 ; 3", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
		
		case 413: // 엄숙한 맹세✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "6 ; 1.2", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	// ==================== SNIPER ====================
	
	// === 주무기 (Primary) ===
	
		
		case 14, 201, 664, 792, 801, 881, 890, 899, 908, 957, 966: // 저격소총✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "2 ; 2 ; 6 ; 0.75");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		
		case 526: // 마키나✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "2 ; 2 ; 5 ; 1.5 ; 304 ; 1.5 ; 305 ; 1");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 30665: // 유성✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "2 ; 2 ; 5 ; 1.5 ; 304 ; 2 ; 305 ; 1");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		
		case 230: // 시드니 마취총✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "6 ; 0.5 ; 90 ; 1.5 ; 42 ; 1 ; 175 ; 0");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		
		case 1092: // 강화된 콤파운드 보우✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "4380 ; 1 ; 4358 ; 500 ; 1 ; 0.1 ; 4577 ; 0.5 ; 5 ; 2");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 56, 1005: // 헌츠맨✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "4358 ; 20 ; 182 ; 3 ; 1 ; 0.5");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 1098: // 클래식✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.1 ; 304 ; 50 ; 91 ; 0.34 ; 4411 ; 1 ; 392 ; 1");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		
		case 851: // 경찰용 제압소총✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "2 ; 3 ; 91 ; -100");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 402: // 시장흥정품✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "91 ; 1 ; 4477 ; 91 ; 4478 ; 3");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 752: // 청부업자의 사건제조기✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.75 ; 76 ; 4 ; 392 ; 1 ; 4521 ; -3 ; 4522 ; 10 ; 6 ; 0.1 ; 91 ; -100", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	// === 보조무기 (Secondary) ===
	
		
		case 16, 203: //기관단총 ✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "6 ; 0.75 ; 4 ; 2", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		
		case 57: //레이저백✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 58: //병수도
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 1105: //자아를 가진 예쁜 반점
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 751: // 청소부의 단축형 소총✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "4477 ; 16 ; 4478 ; 5 ; 5 ; 1 ; 3 ; 1", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
		
		case 231: // 다윈산 차단막
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "26 ; 100 ; 60 ; 1 ; 527 ; 0 ; 412 ; 0.8", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
		
		case 642: // 안락한 야영 장비✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "26 ; 50 ; 107 ; 1.3 ; 57 ; 5", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	// === 근접무기 (Melee) ===
	
		case 3, 193: // 쿠크리✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "2 ; 1.1");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
		
		case 171: // 부족민의 칼✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 1 ");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
		
		case 232: // 부시와카✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "326 ; 1.5 ; 412 ; 1", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
		
		case 401: // 왕중왕✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "224 ; 1 225 ; 1 ; 112 ; 1.2", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	// ==================== SPY ====================
	
	// === 보조무기 (Secondary) ===
		
		case 24, 210, 1142: // 리볼버✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "6 ; 0.8", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
		
		case 61, 1006: // 외교대사✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "5 ; 0.75 ; 3 ; 0.67 ; 1 ; 1 ; 4421 ; 5 ; 4397 ; 1 ; 4396 ; 1 ; 51 ; 0", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
		
		case 161: // 빅킬✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "6 ; 0.8 ; 2 ; 1.1");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		
		case 224: // 이방인✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.75 ; 4477 ; 66 ; 4478 ; 3");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
		
		case 460: // 집행자✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "4343 ; 1 ; 410 ; 1.3 ; 5 ; 1.2");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
		
		case 525: // 다이아몬드 백✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "362 ; 1 ; 1 ; 1 ; 36 ; 1.2");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	// === 근접무기 (Melee) ===
	
		case 4, 194, 665, 749, 803, 883, 892, 901, 910, 959, 968: // 칼✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "6 ; 0.9", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
		
		case 727: // 흑장미✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "6 ; 0.85", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
		
		case 638: // 날카로운 신사✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "6 ; 0.9 ; 107 ; 1.05", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
		
		case 225: // 영원한 안식✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "107 ; 1.05", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
		
		case 356: // 묵인자의 쿠나이✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "125 ; -65");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
		
		case 461: // 재력가✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "54 ; 0.8", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
		
		case 574: // 왕가 부족의 찌르개✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "107 ; 1.1", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
		
		case 649: // 스파이 고드름✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "54 ; 0.9 ; 264 ; 1.5", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	// === PDA1 (기타1) ===
	
	case 735, 736 , 108: // 전자교란기✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "851 ; 1.2");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		
		case 810, 831: // 절차주의 녹음기✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "26 ; 25");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		
		case 933: // Ap-Sap✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "26 ; 25 ; 851 ; 1.1");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		
		case 1102: // 군것질 공격✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "851 ; 1.3");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
	// === PDA2 (기타2) ===
	
		
		case 30, 212: // 투명화 시계✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		
		case 59: // 데드링거✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "726 ; 0 ; 35 ; 1.5 ; 34 ; 1.6 ; 33 ; 1", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		
		case 60: // 망토와 단검✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "84 ; 100 ; 34 ; 5");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		
		case 297: // 열성자의 시계✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
		
		case 947: // 꽥꽥이 시계✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
}
}
/*
 * Prepares a new item handle based on an existing one
 *
 * @param item			Existing item handle
 * @param classname		Classname of the weapon
 * @param index			Index of the weapon
 * @param attributeList	String of attributes in a 'name ; value' pattern (optional)
 * @param preserve		Whether to preserve existing attributes or to overwrite them
 *
 * @return				Item handle on success, null on failure
 */

stock Handle PrepareItemHandle(Handle item, char[] classname="", int index=-1, const char[] attributeList="", bool preserve=true)
{
	// TODO: This duplicates a whole lot of logic in SpawnWeapon
	static Handle weapon;
	int addattribs;

	char attributes[32][32];
	int count=ExplodeString(attributeList, ";", attributes, 32, 32);

	if(count==1) // ExplodeString returns the original string if no matching delimiter was found so we need to special-case this
	{
		if(attributeList[0]!='\0') // Ignore empty attribute list
		{
			LogError("[FF2 Weapons] Unbalanced attributes array '%s' for weapon %s", attributeList, classname);
			if(weapon!=null)
			{
				delete weapon;
			}
			return weapon;
		}
		else
		{
			count=0;
		}
	}
	else if(count % 2) // Unbalanced array, eg "2 ; 10 ; 3"
	{
		LogError("[FF2 Weapons] Unbalanced attributes array %s for weapon %s", attributeList, classname);
		if(weapon!=null)
		{
			delete weapon;
		}
		return weapon;
	}

	int flags=OVERRIDE_ATTRIBUTES;
	if(preserve)
	{
		flags|=PRESERVE_ATTRIBUTES;
	}

	if(weapon==null)
	{
		weapon=TF2Items_CreateItem(flags);
	}
	else
	{
		TF2Items_SetFlags(weapon, flags);
	}

	if(item!=null)
	{
		addattribs=TF2Items_GetNumAttributes(item);
		if(addattribs>0)
		{
			for(int i; i<2*addattribs; i+=2)
			{
				bool dontAdd;
				int attribIndex=TF2Items_GetAttributeId(item, i);
				for(int z; z<count+i; z+=2)
				{
					if(StringToInt(attributes[z])==attribIndex)
					{
						dontAdd=true;
						break;
					}
				}

				if(!dontAdd)
				{
					IntToString(attribIndex, attributes[i+count], 32);
					FloatToString(TF2Items_GetAttributeValue(item, i), attributes[i+1+count], 32);
				}
			}
			count+=2*addattribs;
		}

		if(weapon!=item)  //FlaminSarge: Item might be equal to weapon, so closing item's handle would also close weapon's
		{
			delete item;  //probably returns false but whatever (rswallen-apparently not)
		}
	}

	if(classname[0]!='\0')
	{
		flags|=OVERRIDE_CLASSNAME;
		TF2Items_SetClassname(weapon, classname);
	}

	if(index!=-1)
	{
		flags|=OVERRIDE_ITEM_DEF;
		TF2Items_SetItemIndex(weapon, index);
	}

	if(count>0)
	{
		TF2Items_SetNumAttributes(weapon, count/2);
		int i2;
		for(int i; i<count && i2<16; i+=2)
		{
			int attrib=StringToInt(attributes[i]);
			if(!attrib)
			{
				LogError("[FF2 Weapons] Bad weapon attribute passed: %s ; %s", attributes[i], attributes[i+1]);
				delete weapon;
				return weapon;
			}

			TF2Items_SetAttribute(weapon, i2, StringToInt(attributes[i]), StringToFloat(attributes[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(weapon, 0);
	}
	TF2Items_SetFlags(weapon, flags);
	return weapon;
}
