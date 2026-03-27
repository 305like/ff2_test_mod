/**
 * FF2 Weapon Modifications (ported to FF2R)
 * Weapon attribute changes for all TF2 classes via TF2Items.
 */

#pragma semicolon 1
#pragma newdecls required

#if defined _tf2items_included

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int iItemDefinitionIndex, Handle& item)
{
	if(!Enabled || RoundStatus < 1 || GameRules_GetProp("m_bInWaitingForPlayers", 1))
	{
		return Plugin_Continue;
	}

	static Handle weapon;
	if(weapon!=null)
	{
		delete weapon;
	}

	// 보스는 무기 오버라이드 건너뜀
	if(Client(client).IsBoss)
	{
		return Plugin_Continue;
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
		Handle itemOverride=PrepareItemHandle(item, _, _, "6 ; 0.3 ; 45 ; 0.1 ; 4 ; 3 ; 96 ; 0.25 ; 2 ; 2.2 ; 76 ; 3.13", false);
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
		Handle itemOverride=PrepareItemHandle(item, _, _, "3 ; 1", false);
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
		Handle itemOverride=PrepareItemHandle(item, _, _, "4 ; 1 ; 16 ; 25 ; 104 ; 0.75 ; 741 ; 0 ; 1 ; 0.34", false);
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
		Handle itemOverride=PrepareItemHandle(item, _, _, "27 ; 1 ; 335 ; 3 ; 97 ; 0.75 ; 104 ; 0.6", false);
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
		Handle itemOverride=PrepareItemHandle(item, _, _, "319 ; 0.75 ; 116 ; 1 ; 107 ; 1.15", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 226: // 부대지원✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "319 ; 0.75 ; 116 ; 1 ; 26 ; 50", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 354: // 전복자✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "319 ; 0.75 ; 116 ; 1 ; 107 ; 1.05 ; 57 ; 5", false);
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
		Handle itemOverride=PrepareItemHandle(item, _, _, "335 ; 1000 ; 103 ; 1.5 ; 6 ; 0.1 ; 392 ; 0.25 ; 97 ; 0.1", false);
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
	
		case 40, 1146: // 백버너✅ (뒤에서 공격 시 x4 데미지 → 코드로 처리)
	{
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
		Handle itemOverride=PrepareItemHandle(item, _, _, "58 ; 3.2 ; 144 ; 1.0", false);
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
		Handle itemOverride=PrepareItemHandle(item, _, _, "280 ; 2 ; 103 ; 1.5 ; 208 ; 1 ; 642 ; 1 ; 801 ; 10 ; 6 ; 1.5");
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
		Handle itemOverride=PrepareItemHandle(item, _, _, "6 ; 0.2 ; 411 ; 2.5 ; 103 ; 2 ; 1 ; 0.33", false);
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
		Handle itemOverride=PrepareItemHandle(item, _, _, "137 ; 1 ; 138 ; 1 ; 6 ; 5", false);
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
		Handle itemOverride=PrepareItemHandle(item, _, _, "138 ; 1 ; 2 ; 0.5 ; 6 ; 1.5", false);
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
		Handle itemOverride=PrepareItemHandle(item, _, _, "3 ; 0.6 ; 103 ; 2 ; 6 ; 0.5 ; 2 ; 1.5", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 996: // 통제불능 대포✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "3 ; 0.25 ; 99 ; 1.5");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 1151: // 무쇠 폭탄 발사기✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "413 ; 1 ; 103 ; 1.25 ; 6 ; 0.5", false);
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
	
		
		case 132, 482, 1082, 266: // 아이랜더, 아이언 9번 골프채✅ (적중시 이속버프 3초 → 코드로 처리)
	{
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
		Handle itemOverride=PrepareItemHandle(item, _, _, "6 ; 2 ; 264 ; 3", false);
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
		Handle itemOverride=PrepareItemHandle(item, _, _, "2 ; 1.3 ; 36 ; 1.25 ; 183 ; 1 ; 86 ; 1", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		
		case 424: // 토미슬라프✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "106 ; 0.2 ; 87 ; 0 ; 6 ; 1.3", false);
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
		Handle itemOverride=PrepareItemHandle(item, _, _, "280 ; 3 ; 103 ; 9999 ; 6 ; 3.5 ; 1 ; 8.3 ; 77 ; 0.2 ; 86 ; 1", false);
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
		Handle itemOverride=PrepareItemHandle(item, _, _, "6 ; 0 ; 45 ; 5 ; 36 ; 5 ; 96 ; 15 ; 79 ; 0.13 ; 1 ; 1", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 1153: // 공황공격✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "413 ; 1 ; 6 ; 0.25 ; 4 ; 5 ; 97 ; 0.25 ; 78 ; 2 ; 1 ; 1 ; 45 ; 0.34 ; 106 ; 0.2", false);
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
		Handle itemOverride=PrepareItemHandle(item, _, _, "6 ; 0 ; 1 ; 0.05 ; 855 ; 0", false);
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
		Handle itemOverride=PrepareItemHandle(item, _, _, "280 ; 2 ; 642 ; 1 ; 103 ; 0.75 ; 100 ; 0.1 ; 2 ; 15 ; 299 ; 0 ; 298 ; 25 ; 6 ; 1.2");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 141: // 개척자의 정의✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "3 ; 0.2 ; 45 ; 0.1 ; 1 ; 50 ; 96 ; 3.5 ; 6 ; 1.8", false);
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	
		case 588: // 폼슨 6000✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "6 ; 3 ; 307 ; 1 ; 335 ; 9999 ; 97 ; 0 ; 15 ; 1 ; 288 ; 1", false);
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
		Handle itemOverride=PrepareItemHandle(item, _, _, "125 ; -25 ; 93 ; 1 ; 732 ; 1 ; 790 ; 1");
		if(itemOverride!=null)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}

		case 142: // 총잡이✅
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "26 ; 75");
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
		Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.75 ; 76 ; 4 ; 392 ; 1 ; 4521 ; -3 ; 4522 ; 10 ; 6 ; 0.25 ; 91 ; -100", false);
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

// =========================================================================
// 솔져 버프 동기화 (배너 하나 사용 시 3종 버프 모두 적용)
// =========================================================================

#define SOLDIER_BUFF_CHECK_INTERVAL 0.5

enum SoldierBuffState
{
	SoldierBuff_None,
	SoldierBuff_Active
};
SoldierBuffState g_SoldierBuffState[MAXPLAYERS + 1];
Handle g_hSoldierBuffTimer = null;

void SoldierBuff_Precache()
{
	PrecacheSound("passtime/crowd_cheer.wav", true);
	PrecacheSound("ambient/bumper_car_cheer1.wav", true);
	PrecacheSound("ambient/bumper_car_cheer2.wav", true);
}

void SoldierBuff_Reset()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		g_SoldierBuffState[i] = SoldierBuff_None;
	}
}

void SoldierBuff_Start()
{
	SoldierBuff_Reset();
	if(g_hSoldierBuffTimer != null)
	{
		delete g_hSoldierBuffTimer;
	}
	g_hSoldierBuffTimer = CreateTimer(SOLDIER_BUFF_CHECK_INTERVAL, Timer_SoldierBuffSync, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

void SoldierBuff_Stop()
{
	SoldierBuff_Reset();
	if(g_hSoldierBuffTimer != null)
	{
		delete g_hSoldierBuffTimer;
		g_hSoldierBuffTimer = null;
	}
}

public Action Timer_SoldierBuffSync(Handle timer)
{
	if(!Enabled)
	{
		g_hSoldierBuffTimer = null;
		return Plugin_Stop;
	}

	for(int client = 1; client <= MaxClients; client++)
	{
		if(!IsClientInGame(client)
			|| !IsPlayerAlive(client)
			|| Client(client).IsBoss
			|| TF2_GetPlayerClass(client) != TFClass_Soldier
			|| GetClientTeam(client) != view_as<int>(TFTeam_Red))
		{
			continue;
		}

		bool hasBuff = TF2_IsPlayerInCondition(client, TFCond_Buffed);

		if(hasBuff)
		{
			if(g_SoldierBuffState[client] == SoldierBuff_None)
			{
				EmitSoundToAll("passtime/crowd_cheer.wav", client);
				EmitSoundToAll("ambient/bumper_car_cheer1.wav", client);
				EmitSoundToAll("ambient/bumper_car_cheer2.wav", client);
			}

			TF2_AddCondition(client, TFCond_DefenseBuffed, SOLDIER_BUFF_CHECK_INTERVAL + 0.1);
			TF2_AddCondition(client, TFCond_RegenBuffed, SOLDIER_BUFF_CHECK_INTERVAL + 0.1);

			g_SoldierBuffState[client] = SoldierBuff_Active;
		}
		else if(g_SoldierBuffState[client] == SoldierBuff_Active)
		{
			TF2_RemoveCondition(client, TFCond_DefenseBuffed);
			TF2_RemoveCondition(client, TFCond_RegenBuffed);

			g_SoldierBuffState[client] = SoldierBuff_None;
		}
	}
	return Plugin_Continue;
}

// =========================================================================
// 안락한 야영장비(642) 착용 시 이동속도 비례 투명화
// 속도 0~10: 90% 투명 (alpha 25), 속도 10~최대: 비례 증가 (alpha 25~255)
// 착용 여부: 0.5초 간격 체크, 투명도: 매 프레임 업데이트
// =========================================================================

// =========================================================================
// 전역 변수
// =========================================================================
static float g_flZatoichiDrawTime[MAXPLAYERS+1];
static bool g_bHasCozyWearable[MAXPLAYERS+1];
static float g_flCozyLastCheck[MAXPLAYERS+1];
static int g_iCozyLastAlpha[MAXPLAYERS+1];
static Handle g_hKritzTimer[MAXPLAYERS+1];
static int g_iLastClip141[MAXPLAYERS+1];
static float g_flSpyCloakDamageMultiplier[MAXPLAYERS+1];
static float g_fl3rdDegreeLastHeal[MAXPLAYERS+1];
static int g_iAmputatorLastHeads[MAXPLAYERS+1];
static float g_flNeonLastHeal[MAXPLAYERS+1];
static float g_flNeonLastAttackTime[MAXPLAYERS+1];

// 방패 과충전 시스템
static int g_iShield[MAXPLAYERS+1];       // 방패 엔티티 인덱스 (0 = 없음)
static float g_flOverCharge[MAXPLAYERS+1]; // 과충전량 (0~100)
static float g_flLastCharge[MAXPLAYERS+1]; // 이전 프레임 m_flChargeMeter 값 (돌격 감지용)

// =========================================================================
// OnGameFrame: 혈적자/가스패서 탄약 3발 고정
// =========================================================================
void WeaponSpecial_OnGameFrame()
{
	if(!Enabled || RoundStatus < 1)
		return;

	for(int client = 1; client <= MaxClients; client++)
	{
		if(!IsClientInGame(client) || !IsPlayerAlive(client) || Client(client).IsBoss)
			continue;

		int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(!IsValidEntity(activeWeapon))
			continue;

		int index = GetEntProp(activeWeapon, Prop_Send, "m_iItemDefinitionIndex");

		// 혈적자(812) / 가스패서(1180): 들고 있을 때 탄약 3발 고정
		if(index == 812 || index == 1180)
		{
			int ammoType = GetEntProp(activeWeapon, Prop_Send, "m_iPrimaryAmmoType");
			if(ammoType >= 0)
				SetEntProp(client, Prop_Data, "m_iAmmo", 3, _, ammoType);
		}
	}
}

Action WeaponSpecial_PlayerRunCmd(int client, int &buttons, int &impulse)
{
	if(!Enabled || RoundStatus < 1 || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Continue;

	// 방패 차지미터 저장 (돌격 감지용)
	WeaponSpecial_SaveLastCharge(client);

	// 보스가 되었거나 사망 등으로 코지캠퍼 상태 해제
	if(Client(client).IsBoss || !g_bHasCozyWearable[client])
	{
		if(g_bHasCozyWearable[client])
		{
			g_bHasCozyWearable[client] = false;
			g_iCozyLastAlpha[client] = 255;
			WeaponSpecial_ApplyCozyAlpha(client, 255);
		}
		if(Client(client).IsBoss)
		{
			g_flZatoichiDrawTime[client] = 0.0;
			return Plugin_Continue;
		}
	}

	// 자토이치 명예의 구속
	Action zatoResult = WeaponSpecial_ZatoichiRunCmd(client, buttons, impulse);
	if(zatoResult != Plugin_Continue)
		return zatoResult;

	// 낙하산(1101) 즉시 재전개
	if(!TF2_IsPlayerInCondition(client, TFCond_Parachute) &&
	   TF2_IsPlayerInCondition(client, TFCond_ParachuteDeployed))
	{
		int secondary = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(IsValidEntity(secondary) &&
		   GetEntProp(secondary, Prop_Send, "m_iItemDefinitionIndex") == 1101)
		{
			TF2_RemoveCondition(client, TFCond_ParachuteDeployed);
		}
	}

	// 3도화상(593) 도발 시 주변 아군 힐
	WeaponSpecial_ThirdDegreeHeal(client);

	// 크리츠크릭(35) 치료 시 미니크리
	WeaponSpecial_KritzkriegMiniCrits(client);

	// 절단기(304) 참수 수 기반 체력 증가
	WeaponSpecial_AmputatorHeads(client);

	// 스파이 은폐 시 피해 배율 설정
	WeaponSpecial_SpyCloakDamage(client);

	// 개척자의 정의(141) 착탄점 폭발
	WeaponSpecial_FrontierJustice(client);

	// 네온전멸기(813, 834) 아군 타격 시 30HP 힐
	WeaponSpecial_NeonAllyHeal(client);

	// 메딕 러버점프
	WeaponSpecial_MedicRubberJump(client, buttons);

	// 0.5초 간격으로 코지캠퍼 착용 여부 체크
	float gameTime = GetGameTime();
	if(gameTime - g_flCozyLastCheck[client] >= 0.5)
	{
		g_flCozyLastCheck[client] = gameTime;

		bool foundCozy = false;
		for(int i = MaxClients + 1; i < GetMaxEntities(); i++)
		{
			if(!IsValidEntity(i))
				continue;

			char classname[64];
			GetEntityClassname(i, classname, sizeof(classname));

			if(StrContains(classname, "tf_wearable") != -1)
			{
				int owner = GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity");
				if(owner == client)
				{
					int itemIndex = GetEntProp(i, Prop_Send, "m_iItemDefinitionIndex");
					if(itemIndex == 642)
					{
						foundCozy = true;
						break;
					}
				}
			}
		}

		// 해제 시 투명도 복원
		if(g_bHasCozyWearable[client] && !foundCozy)
		{
			g_iCozyLastAlpha[client] = 255;
			WeaponSpecial_ApplyCozyAlpha(client, 255);
		}
		g_bHasCozyWearable[client] = foundCozy;
	}

	// 코지캠퍼 미착용이면 스킵
	if(!g_bHasCozyWearable[client])
		return Plugin_Continue;

	// 매 프레임: 이동속도 기반 투명도 계산
	float vel[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vel);
	float speed = GetVectorLength(vel);

	int alpha;
	if(speed <= 10.0)
	{
		// 거의 정지: 90% 투명 (alpha 25)
		alpha = 25;
	}
	else
	{
		// 속도 10 ~ 최대속도: alpha 25 ~ 255 비례
		float maxSpeed = GetEntPropFloat(client, Prop_Data, "m_flMaxspeed");
		if(maxSpeed < 10.0) maxSpeed = 300.0;	// 안전장치

		float ratio = (speed - 10.0) / (maxSpeed - 10.0);
		if(ratio > 1.0) ratio = 1.0;

		alpha = 25 + RoundToNearest(ratio * 230.0);	// 25 ~ 255
	}

	// 변경이 있을 때만 적용 (매 프레임 렌더 호출 최소화)
	if(alpha != g_iCozyLastAlpha[client])
	{
		g_iCozyLastAlpha[client] = alpha;
		WeaponSpecial_ApplyCozyAlpha(client, alpha);
	}
	return Plugin_Continue;
}

// =========================================================================
// 네온전멸기(813, 834) 아군 실제 타격 시 30HP 힐
// m_flNextPrimaryAttack 변화 감지 = 실제 스윙 발생 시점
// =========================================================================
static void WeaponSpecial_NeonAllyHeal(int client)
{
	int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(!IsValidEntity(activeWeapon))
		return;

	int index = GetEntProp(activeWeapon, Prop_Send, "m_iItemDefinitionIndex");
	if(index != 813 && index != 834)
		return;

	// m_flNextPrimaryAttack 변화 감지: 값이 바뀌면 실제 스윙이 발생한 것
	float nextAttack = GetEntPropFloat(activeWeapon, Prop_Send, "m_flNextPrimaryAttack");
	if(nextAttack == g_flNeonLastAttackTime[client])
		return;

	g_flNeonLastAttackTime[client] = nextAttack;

	// 이미 힐 쿨다운 중이면 스킵
	float gameTime = GetGameTime();
	if(gameTime - g_flNeonLastHeal[client] < 0.5)
		return;

	// 트레이스: 눈 위치에서 바라보는 방향으로 근접 범위(128유닛) 체크
	float eyePos[3], eyeAng[3];
	GetClientEyePosition(client, eyePos);
	GetClientEyeAngles(client, eyeAng);

	Handle trace = TR_TraceRayFilterEx(eyePos, eyeAng, MASK_SHOT, RayType_Infinite, WeaponSpecial_TraceFilter, client);
	if(!TR_DidHit(trace))
	{
		delete trace;
		return;
	}

	int target = TR_GetEntityIndex(trace);
	float hitPos[3];
	TR_GetEndPosition(hitPos, trace);
	delete trace;

	if(GetVectorDistance(eyePos, hitPos) > 128.0)
		return;

	// 아군 플레이어만 (자기 자신 제외)
	if(target < 1 || target > MaxClients || !IsClientInGame(target) || !IsPlayerAlive(target))
		return;

	if(GetClientTeam(target) != GetClientTeam(client) || target == client)
		return;

	g_flNeonLastHeal[client] = gameTime;

	int maxHealth = GetEntProp(target, Prop_Data, "m_iMaxHealth");
	int currentHealth = GetClientHealth(target);
	int healAmount = 30;
	int newHealth = currentHealth + healAmount;

	if(newHealth > maxHealth)
	{
		healAmount = maxHealth - currentHealth;
		newHealth = maxHealth;
	}

	if(healAmount > 0)
	{
		SetEntityHealth(target, newHealth);
		ApplyAllyHealEvent(GetClientUserId(client), GetClientUserId(target), healAmount);
		SDKCall_IncrementStat(client, TFSTAT_HEALING, healAmount);
	}
}

// =========================================================================
// 3도화상(593) 도발 시 주변 아군 힐 (150유닛, 0.5초당 25)
// =========================================================================
static void WeaponSpecial_ThirdDegreeHeal(int client)
{
	if(TF2_GetPlayerClass(client) != TFClass_Pyro)
		return;

	int meleeWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	if(!IsValidEntity(meleeWeapon) ||
	   GetEntProp(meleeWeapon, Prop_Send, "m_iItemDefinitionIndex") != 593)
		return;

	if(!TF2_IsPlayerInCondition(client, TFCond_Taunting))
		return;

	if(GetGameTime() - g_fl3rdDegreeLastHeal[client] < 0.5)
		return;

	g_fl3rdDegreeLastHeal[client] = GetGameTime();

	float clientPos[3];
	GetClientAbsOrigin(client, clientPos);
	int clientTeam = GetClientTeam(client);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i) || i == client)
			continue;
		if(GetClientTeam(i) != clientTeam)
			continue;

		float targetPos[3];
		GetClientAbsOrigin(i, targetPos);

		if(GetVectorDistance(clientPos, targetPos) <= 150.0)
		{
			int maxHealth = GetEntProp(i, Prop_Data, "m_iMaxHealth");
			int currentHealth = GetClientHealth(i);
			int healAmount = 25;
			int newHealth = currentHealth + healAmount;

			if(newHealth > maxHealth)
			{
				healAmount = maxHealth - currentHealth;
				newHealth = maxHealth;
			}

			if(healAmount > 0)
			{
				SetEntityHealth(i, newHealth);
				ApplyAllyHealEvent(GetClientUserId(client), GetClientUserId(i), healAmount);
				ApplySelfHealEvent(client, healAmount);
				SDKCall_IncrementStat(client, TFSTAT_HEALING, healAmount);
			}
		}
	}
}

// =========================================================================
// 크리츠크릭(35) 치료 시 미니크리
// =========================================================================
static void WeaponSpecial_KritzkriegMiniCrits(int client)
{
	if(TF2_GetPlayerClass(client) != TFClass_Medic)
		return;

	int secondary = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(!IsValidEntity(secondary) ||
	   GetEntProp(secondary, Prop_Send, "m_iItemDefinitionIndex") != 35)
	{
		if(g_hKritzTimer[client] != null)
		{
			delete g_hKritzTimer[client];
			g_hKritzTimer[client] = null;
		}
		return;
	}

	if(GetEntProp(secondary, Prop_Send, "m_bHealing"))
	{
		int healTarget = GetEntPropEnt(secondary, Prop_Send, "m_hHealingTarget");
		if(healTarget > 0 && healTarget <= MaxClients && IsClientInGame(healTarget) && IsPlayerAlive(healTarget))
		{
			TF2_AddCondition(healTarget, TFCond_CritCola, 0.5, 0);

			if(g_hKritzTimer[client] == null)
				g_hKritzTimer[client] = CreateTimer(0.3, Timer_KritzMiniCrit, EntIndexToEntRef(secondary), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else
	{
		if(g_hKritzTimer[client] != null)
		{
			delete g_hKritzTimer[client];
			g_hKritzTimer[client] = null;
		}
	}
}

public Action Timer_KritzMiniCrit(Handle timer, int medigunRef)
{
	int medigun = EntRefToEntIndex(medigunRef);
	if(medigun != INVALID_ENT_REFERENCE && IsValidEntity(medigun))
	{
		int client = GetEntPropEnt(medigun, Prop_Send, "m_hOwnerEntity");
		if(client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client))
		{
			if(GetEntProp(medigun, Prop_Send, "m_bHealing"))
			{
				int healTarget = GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
				if(healTarget > 0 && healTarget <= MaxClients && IsClientInGame(healTarget) && IsPlayerAlive(healTarget))
				{
					TF2_AddCondition(healTarget, TFCond_CritCola, 0.5, 0);
					return Plugin_Continue;
				}
			}
		}
	}

	// 타이머 종료: 소유자 찾아서 핸들 정리
	for(int i = 1; i <= MaxClients; i++)
	{
		if(g_hKritzTimer[i] == timer)
		{
			g_hKritzTimer[i] = null;
			break;
		}
	}
	return Plugin_Stop;
}

// =========================================================================
// 절단기(304) 참수 수 기반 체력 증가 (+100 per head)
// =========================================================================
static void WeaponSpecial_AmputatorHeads(int client)
{
	if(TF2_GetPlayerClass(client) != TFClass_Medic)
		return;

	int meleeSlot = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	if(!IsValidEntity(meleeSlot) ||
	   GetEntProp(meleeSlot, Prop_Send, "m_iItemDefinitionIndex") != 304)
		return;

	int currentHits = GetEntProp(client, Prop_Send, "m_iDecapitations");
	if(currentHits > g_iAmputatorLastHeads[client])
	{
		int healAmount = (currentHits - g_iAmputatorLastHeads[client]) * 100;
		int newHealth = GetClientHealth(client) + healAmount;
		SetEntityHealth(client, newHealth);
		g_iAmputatorLastHeads[client] = currentHits;
	}
}

// =========================================================================
// 스파이 은폐 시 피해 0.5배
// =========================================================================
static void WeaponSpecial_SpyCloakDamage(int client)
{
	if(TF2_GetPlayerClass(client) != TFClass_Spy)
	{
		g_flSpyCloakDamageMultiplier[client] = 1.0;
		return;
	}

	bool isCloaked = TF2_IsPlayerInCondition(client, TFCond_Cloaked) ||
	                 TF2_IsPlayerInCondition(client, TFCond_Stealthed);

	g_flSpyCloakDamageMultiplier[client] = isCloaked ? 0.5 : 1.0;
}

// 외부에서 접근: 데미지 처리 시 호출
float WeaponSpecial_GetCloakDamageMultiplier(int client)
{
	return g_flSpyCloakDamageMultiplier[client];
}

// =========================================================================
// 개척자의 정의(141) 착탄점 폭발
// =========================================================================
static void WeaponSpecial_FrontierJustice(int client)
{
	int activeWep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(!IsValidEntity(activeWep))
		return;

	int wepIndex = GetEntProp(activeWep, Prop_Send, "m_iItemDefinitionIndex");
	if(wepIndex != 141)
	{
		g_iLastClip141[client] = 0;
		return;
	}

	int clip = GetEntProp(activeWep, Prop_Send, "m_iClip1");
	if(clip < g_iLastClip141[client] && g_iLastClip141[client] > 0)
	{
		float eyePos[3], eyeAng[3], endPos[3];
		GetClientEyePosition(client, eyePos);
		GetClientEyeAngles(client, eyeAng);

		Handle trace = TR_TraceRayFilterEx(eyePos, eyeAng, MASK_SHOT, RayType_Infinite, WeaponSpecial_TraceFilter, client);
		if(TR_DidHit(trace))
		{
			TR_GetEndPosition(endPos, trace);

			int explosionModel = PrecacheModel("sprites/sprite_fire01.vmt");
			TE_SetupExplosion(endPos, explosionModel, 10.0, 1, 0, 150, 50);
			TE_SendToAll();

			float flRadius = 150.0;
			float flMaxDmg = 60.0;
			float flMinDmg = 30.0;
			for(int i = 1; i <= MaxClients; i++)
			{
				if(!IsClientInGame(i) || !IsPlayerAlive(i)) continue;
				float targetPos[3];
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", targetPos);
				targetPos[2] += 40.0;
				float dist = GetVectorDistance(endPos, targetPos);
				if(dist <= flRadius)
				{
					float dmg;
					if(dist <= 60.0)
						dmg = flMaxDmg;
					else
						dmg = flMaxDmg - (flMaxDmg - flMinDmg) * ((dist - 60.0) / (flRadius - 60.0));
					SDKHooks_TakeDamage(i, client, client, dmg, DMG_BLAST);
				}
			}
		}
		delete trace;
	}
	g_iLastClip141[client] = clip;
}

public bool WeaponSpecial_TraceFilter(int entity, int contentsMask, int client)
{
	return (entity != client);
}

// =========================================================================
// 메딕 러버점프: 힐 대상과 공중에서 점프키 누르면 대상쪽으로 끌려감
// =========================================================================
static void WeaponSpecial_MedicRubberJump(int client, int buttons)
{
	if(TF2_GetPlayerClass(client) != TFClass_Medic)
		return;

	if(GetEntityFlags(client) & FL_ONGROUND)
		return;

	int healTarget = WeaponSpecial_GetHealingTarget(client);
	if(healTarget < 1 || healTarget > MaxClients || !IsClientInGame(healTarget) || !IsPlayerAlive(healTarget))
		return;

	if(GetEntityFlags(healTarget) & FL_ONGROUND)
		return;

	if(!(buttons & IN_JUMP))
		return;

	float targetPos[3], clientPos[3];
	GetClientAbsOrigin(healTarget, targetPos);
	GetClientAbsOrigin(client, clientPos);
	targetPos[2] += 120.0;

	float diffPos[3];
	SubtractVectors(targetPos, clientPos, diffPos);
	ScaleVector(diffPos, 0.05);

	float clientVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", clientVelocity);
	AddVectors(clientVelocity, diffPos, clientVelocity);
	SetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", clientVelocity);
}

static int WeaponSpecial_GetHealingTarget(int client)
{
	int medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(!IsValidEntity(medigun))
		return -1;

	char classname[64];
	GetEntityClassname(medigun, classname, sizeof(classname));
	if(!StrEqual(classname, "tf_weapon_medigun", false))
		return -1;

	if(GetEntProp(medigun, Prop_Send, "m_bHealing"))
		return GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");

	return -1;
}

static Action WeaponSpecial_ZatoichiRunCmd(int client, int &buttons, int &impulse)
{
	int melee = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	if(!IsValidEntity(melee))
	{
		g_flZatoichiDrawTime[client] = 0.0;
		return Plugin_Continue;
	}

	int meleeIndex = GetEntProp(melee, Prop_Send, "m_iItemDefinitionIndex");
	if(meleeIndex != 357)
	{
		g_flZatoichiDrawTime[client] = 0.0;
		return Plugin_Continue;
	}

	int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(activeWeapon <= 0)
		return Plugin_Continue;

	char weaponClass[64];
	GetEntityClassname(activeWeapon, weaponClass, sizeof(weaponClass));

	if(StrEqual(weaponClass, "tf_weapon_katana"))
	{
		if(g_flZatoichiDrawTime[client] == 0.0)
			g_flZatoichiDrawTime[client] = GetGameTime();

		float elapsedTime = GetGameTime() - g_flZatoichiDrawTime[client];

		// 1초 경과 + 킬 없으면 무기 교체 차단
		if(elapsedTime >= 1.0 && GetEntProp(client, Prop_Send, "m_iKillCountSinceLastDeploy") == 0)
		{
			if(buttons & IN_ATTACK3)
				buttons &= ~IN_ATTACK3;

			if(impulse >= 1 && impulse <= 5)
				impulse = 0;

			if(!TF2_IsPlayerInCondition(client, TFCond_RestrictToMelee))
				TF2_AddCondition(client, TFCond_RestrictToMelee, 1.0, 0);

			return Plugin_Changed;
		}
	}
	else
	{
		g_flZatoichiDrawTime[client] = 0.0;
	}

	return Plugin_Continue;
}

static void WeaponSpecial_ApplyCozyAlpha(int client, int alpha)
{
	RenderMode renderMode = (alpha < 255) ? RENDER_TRANSCOLOR : RENDER_NORMAL;

	// 플레이어
	SetEntityRenderMode(client, renderMode);
	SetEntityRenderColor(client, 255, 255, 255, alpha);

	// 모든 무기
	for(int slot = 0; slot < 5; slot++)
	{
		int slotWeapon = GetPlayerWeaponSlot(client, slot);
		if(IsValidEntity(slotWeapon))
		{
			SetEntityRenderMode(slotWeapon, renderMode);
			SetEntityRenderColor(slotWeapon, 255, 255, 255, alpha);
		}
	}

	// 모든 wearables + 장식품
	int entity = -1;
	static char searchClass[][] = {"tf_wearable", "tf_wearable_demoshield", "tf_powerup_bottle"};

	for(int i = 0; i < sizeof(searchClass); i++)
	{
		entity = -1;
		while((entity = FindEntityByClassname(entity, searchClass[i])) != -1)
		{
			if(!IsValidEntity(entity)) continue;

			int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			if(owner == client)
			{
				SetEntityRenderMode(entity, renderMode);
				SetEntityRenderColor(entity, 255, 255, 255, alpha);
			}
		}
	}
}

void WeaponSpecial_ResetCozy(int client)
{
	g_bHasCozyWearable[client] = false;
	g_flCozyLastCheck[client] = 0.0;
	g_iCozyLastAlpha[client] = 255;
}

// =========================================================================
// 방패 과충전(OverCharge) 시스템
// =========================================================================

// 스폰/리스폰 시 방패 감지
void WeaponSpecial_DetectShield(int client)
{
	g_iShield[client] = 0;
	g_flOverCharge[client] = 0.0;
	g_flLastCharge[client] = 0.0;

	if(Client(client).IsBoss)
		return;

	// Razorback (57) 감지
	int entity = -1;
	while((entity = FindEntityByClassname(entity, "tf_wearable")) != -1)
	{
		if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client
			&& !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable")
			&& GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex") == 57)
		{
			g_iShield[client] = entity;
			return;
		}
	}

	// 데모맨 방패 감지
	entity = -1;
	while((entity = FindEntityByClassname(entity, "tf_wearable_demoshield")) != -1)
	{
		if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client
			&& !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
		{
			g_iShield[client] = entity;
			return;
		}
	}
}

// 1초마다 과충전 증가 (+5/sec, 최대 100)
public Action WeaponSpecial_OverChargeTimer(Handle timer)
{
	if(!Enabled || RoundStatus < 1)
		return Plugin_Continue;

	for(int client = 1; client <= MaxClients; client++)
	{
		if(!IsClientInGame(client) || !IsPlayerAlive(client) || Client(client).IsBoss)
			continue;

		if(!g_iShield[client])
			continue;

		if(!IsValidEntity(g_iShield[client]))
		{
			g_iShield[client] = 0;
			continue;
		}

		int index = GetEntProp(g_iShield[client], Prop_Send, "m_iItemDefinitionIndex");

		// Razorback(57)는 과충전 없음
		if(index == 57)
			continue;

		if(g_flOverCharge[client] < 100.0)
			g_flOverCharge[client] = (g_flOverCharge[client] + 5.0 > 100.0) ? 100.0 : g_flOverCharge[client] + 5.0;
	}

	return Plugin_Continue;
}

// OnPlayerRunCmd에서 LastCharge 저장 (돌격 감지용)
void WeaponSpecial_SaveLastCharge(int client)
{
	if(g_iShield[client] && IsValidEntity(g_iShield[client]))
	{
		int index = GetEntProp(g_iShield[client], Prop_Send, "m_iItemDefinitionIndex");
		if(index != 57) // 데모 방패만
			g_flLastCharge[client] = GetEntPropFloat(client, Prop_Send, "m_flChargeMeter");
	}
}

// 사망 시 과충전 초기화
void WeaponSpecial_ResetOverCharge(int client)
{
	g_iShield[client] = 0;
	g_flOverCharge[client] = 0.0;
	g_flLastCharge[client] = 0.0;
}

// 방패 깨짐 사운드
void WeaponSpecial_PlayShieldBreakSound(float position[3], float volume = 0.7)
{
	for(int target = 1; target <= MaxClients; target++)
	{
		if(IsClientInGame(target))
			EmitSoundToClient(target, "player/spy_shield_break.wav", _, _, _, _, volume, _, _, position, _, false);
	}
}

// 보스 공격 → 피해자 방패 방어 (sdkhooks.sp에서 호출)
// 반환: true = 데미지 변경됨, false = 변경 없음
// Plugin_Handled 반환 시 = 데미지 완전 흡수
Action WeaponSpecial_ShieldDefense(int victim, float &damage, float position[3])
{
	if(!g_iShield[victim] || damage <= 0.0 || IsInvuln(victim))
		return Plugin_Continue;

	if(!IsValidEntity(g_iShield[victim]))
	{
		g_iShield[victim] = 0;
		return Plugin_Continue;
	}

	int index = GetEntProp(g_iShield[victim], Prop_Send, "m_iItemDefinitionIndex");

	// Razorback(57): 차지 100%일 때 보스 공격 1회 완전 흡수
	if(index == 57)
	{
		if(GetEntPropFloat(victim, Prop_Send, "m_flItemChargeMeter", TFWeaponSlot_Secondary) >= 100.0)
		{
			WeaponSpecial_PlayShieldBreakSound(position, 0.7);
			SetEntPropFloat(victim, Prop_Send, "m_flItemChargeMeter", 0.0, TFWeaponSlot_Secondary);
			return Plugin_Handled;
		}
		return Plugin_Continue;
	}

	// 데모 방패: 차지미터 감소 + 과충전으로 대미지 흡수
	float charge = GetEntPropFloat(victim, Prop_Send, "m_flChargeMeter") - damage;
	SetEntPropFloat(victim, Prop_Send, "m_flChargeMeter",
		charge > 0.0 ? charge : 0.0);

	if(g_flOverCharge[victim] > 0.0)
	{
		float absorbed = (damage < g_flOverCharge[victim]) ? damage : g_flOverCharge[victim];
		g_flOverCharge[victim] -= absorbed;
		damage -= absorbed;

		WeaponSpecial_PlayShieldBreakSound(position, 0.7);
		return Plugin_Changed;
	}

	return Plugin_Changed;
}

// 방패 돌격 → 보스 공격 (sdkhooks.sp에서 호출)
// 반환: true = 데미지 변경됨
bool WeaponSpecial_ShieldOffense(int attacker, int victim, float &damage, float damageForce[3], int damagecustom)
{
	if(damagecustom != TF_CUSTOM_CHARGE_IMPACT)
		return false;

	float charge = g_flLastCharge[attacker];
	if(charge >= 75.0)
		return false;

	float score = (charge - 100.0) * -1.0;
	float tempDamage = (damage * 2.0) + score;

	ScaleVector(damageForce, 10.0 * (score * 0.01));
	damage = tempDamage;

	// 과충전 50% 이상일 때 방패 슬램: 기절 + 추가 대미지
	if(g_flOverCharge[attacker] > 50.0)
	{
		float slamPower = g_flOverCharge[attacker] * 0.04;
		damage *= slamPower * 0.5;

		TF2_StunPlayer(victim, slamPower, 1.0, TF_STUNFLAG_BONKSTUCK, attacker);
		g_flOverCharge[attacker] = 0.0;
	}

	return true;
}

// 과충전 HUD 텍스트 생성 (gamemode.sp에서 호출)
// 반환: true = HUD 표시할 내용 있음
bool WeaponSpecial_GetOverChargeHud(int client, char[] buffer, int maxlen)
{
	if(!g_iShield[client] || !IsValidEntity(g_iShield[client]))
		return false;

	int index = GetEntProp(g_iShield[client], Prop_Send, "m_iItemDefinitionIndex");

	if(index == 57) // Razorback
	{
		float razorCharge = GetEntPropFloat(client, Prop_Send, "m_flItemChargeMeter", TFWeaponSlot_Secondary);
		FormatEx(buffer, maxlen, "Shield: %d%%", RoundFloat(razorCharge));
		return true;
	}

	// 데모 방패
	float charge = GetEntPropFloat(client, Prop_Send, "m_flChargeMeter");
	if(g_flOverCharge[client] > 0.0)
		FormatEx(buffer, maxlen, "Shield: %d%% | Overcharge: %d", RoundFloat(charge), RoundFloat(g_flOverCharge[client]));
	else
		FormatEx(buffer, maxlen, "Shield: %d%%", RoundFloat(charge));

	return true;
}

#endif // _tf2items_included
