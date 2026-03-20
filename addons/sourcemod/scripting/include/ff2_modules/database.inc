#if defined _ff2_db_included
 #endinput
#endif
#define _ff2_db_included

enum FF2DataType
{
	FF2Data_Int = 0,
	FF2Data_Float,
	FF2Data_String
};

/**
 * Get Player's setting data (Int or Float).
 *
 * @param client            client's index
 * @param settingId         setting ID
 * @param type              FF2Data_Int or FF2Data_Float
 * @return                  setting value
 */
native any FF2_GetSettingData(int client, const char[] settingId, FF2DataType type);

/**
 * Get Player's setting data (String).
 *
 * @param client            client's index
 * @param settingId         setting ID
 * @param value             buffer to store the value
 * @param buffer            buffer size
 */
native void FF2_GetSettingStringData(int client, const char[] settingId, char[] value, int buffer);

/**
 * Set Player's setting data (Int or Float).
 *
 * @param client            client's index
 * @param settingId         setting ID
 * @param value             value to set
 * @param type              FF2Data_Int or FF2Data_Float
 */
native void FF2_SetSettingData(int client, const char[] settingId, any value, FF2DataType type);

/**
 * Set Player's setting data (String).
 *
 * @param client            client's index
 * @param settingId         setting ID
 * @param value             value to set
 */
native void FF2_SetSettingStringData(int client, const char[] settingId, char[] value);

public SharedPlugin __pl_ff2_db=
{
	name="ff2_db",
	file="freak_fortress_2.smx",
	#if defined REQUIRE_PLUGIN
		required=1,
	#else
		required=0,
	#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_ff2_db_SetNTVOptional()
{
    MarkNativeAsOptional("FF2_GetSettingData");
    MarkNativeAsOptional("FF2_GetSettingStringData");
    MarkNativeAsOptional("FF2_SetSettingData");
    MarkNativeAsOptional("FF2_SetSettingStringData");
}
#endif
