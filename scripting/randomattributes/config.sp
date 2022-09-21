#define CONFIG_FILEPATH_ATTRIBUTES	"configs/randomattributes/attributes.cfg"
#define CONFIG_FILEPATH_SETTINGS	"configs/randomattributes/settings.cfg"
#define INDEX_MAX_LENGTH 	512

enum
{
	ConfigAttribute_Index = 0,
	ConfigAttribute_Type,
	ConfigAttribute_Min,
	ConfigAttribute_Max,
}

enum
{
	ConfigAttributeType_Invalid = -1,
	ConfigAttributeType_Int = 0,
	ConfigAttributeType_Float,
}

void Config_RefreshAttributes()
{
	if (!g_cvEnabled.BoolValue)
		return;
	
	char sConfigPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sConfigPath, sizeof(sConfigPath), CONFIG_FILEPATH_ATTRIBUTES);
	if (!FileExists(sConfigPath))
	{
		SetFailState("[Random Attributes] Attributes config file is missing! (%s)", sConfigPath);
		return;
	}
	
	g_aAttributes.Clear();

	KeyValues kv = new KeyValues("Attributes");
	if (!kv.ImportFromFile(sConfigPath))
	{
		SetFailState("[Random Attributes] Config file for could not find Attributes!");
		return;
	}
	
	if (!kv.GotoFirstSubKey())
	{
		SetFailState("[Random Attributes] Config file could not find first Attributes subkey!");
		return;
	}
	
	int iAttribCount = 0;
	do
	{
		char sIndex[INDEX_MAX_LENGTH], sType[8];
		int iType = -1;
		kv.GetSectionName(sIndex, sizeof(sIndex));
		kv.GetString("type", sType, sizeof(sType));
		float flMin = kv.GetFloat("min", 0.0);
		float flMax = kv.GetFloat("max", 0.0);
		
		if (StrEqual(sType, "int", false))
		{
			iType = ConfigAttributeType_Int;
		}
		else if (StrEqual(sType, "float", false))
		{
			iType = ConfigAttributeType_Float;
		}
		else
		{
			LogError("[Random Attributes] Index %s in Attributes Config has an invalid type: %s", sIndex, sType);
			continue;
		}
		
		char[][] sArray = new char[INDEX_MAX_LENGTH][8];
		int iLength = ExplodeString(sIndex, " ", sArray, INDEX_MAX_LENGTH, 8);
		
		for (int i = 0; i < iLength; i++)
		{
			int iIndex;
			
			if (!StringToIntEx(sArray[i], iIndex))
			{
				LogError("[Random Attributes] Attributes config couldn't read attribute index %s", sArray[i]);
				continue;
			}
			
			ConfigAttribute attribute;
			attribute.iIndex = iIndex;
			attribute.iType = iType;
			attribute.flMin = flMin;
			attribute.flMax = flMax;
			
			g_aAttributes.PushArray(attribute);
			iAttribCount++;
		}
	}
	while (kv.GotoNextKey());
	
	delete kv;
	PrintToServer("[Random Attributes] Loaded Attributes config with %d attributes.", g_aAttributes.Length);
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientInGame(iClient))
		{
			for (int iSlot = TFWeaponSlot_Primary; iSlot <= TFWeaponSlot_Melee; iSlot++)
			{
				UpdateClientSlot(iClient, iSlot);
				ApplyToClientSlot(iClient, iSlot);
			}
		}
	}
}

void Config_RefreshSettings()
{
	if (!g_cvEnabled.BoolValue)
		return;
	
	char sConfigPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sConfigPath, sizeof(sConfigPath), CONFIG_FILEPATH_SETTINGS);
	if (!FileExists(sConfigPath))
	{
		PrintToServer("[Random Attributes] Settings config file is missing! (%s)\nSettings will be unchanged.", sConfigPath);
		return;
	}

	KeyValues kv = new KeyValues("Settings");
	if (!kv.ImportFromFile(sConfigPath))
	{
		PrintToServer("[Random Attributes] Settings config file could not find Settings!\nSettings will be unchanged.");
		return;
	}
	
	int iAmount, iActiveOnly, iRerollDeath, iRerollSlot;
	char sTeam[8], sBlacklist[INDEX_MAX_LENGTH];
	
	if (kv.JumpToKey("Default"))
	{
		iAmount = kv.GetNum("amount", -1);
		iActiveOnly = kv.GetNum("active_only", -1);
		iRerollDeath = kv.GetNum("reroll_on_death", -1);
		iRerollSlot = kv.GetNum("reroll_on_slot_change", -1);
		kv.GetString("only_allow_team", sTeam, sizeof(sTeam));
		kv.GetString("blacklist", sBlacklist, sizeof(sBlacklist));	// Ideally this one shouldn't be used in Default, but may as well put it here
		
		kv.GoBack();
	}
	
	bool bDone = false;
	ConVar cvGamemode = FindConVar("redsun_currentgamemode");
	
	if (cvGamemode != INVALID_HANDLE)
	{
		if (kv.JumpToKey("RedSunGamemode"))
		{
			char sGamemodeName[64];
			cvGamemode.GetString(sGamemodeName, sizeof(sGamemodeName));
			
			if (kv.GotoFirstSubKey())
			{
				do
				{
					char sCompare[64];
					kv.GetSectionName(sCompare, sizeof(sCompare));
					
					if (!StrEqual(sGamemodeName, sCompare, false))
						continue;
					
					iAmount = kv.GetNum("amount", iAmount);
					iActiveOnly = kv.GetNum("active_only", iActiveOnly);
					iRerollDeath = kv.GetNum("reroll_on_death", iRerollDeath);
					iRerollSlot = kv.GetNum("reroll_on_slot_change", iRerollSlot);
					kv.GetString("only_allow_team", sTeam, sizeof(sTeam), sTeam);
					kv.GetString("blacklist", sBlacklist, sizeof(sBlacklist), sBlacklist);
					
					bDone = true;
				}
				while (kv.GotoNextKey() && !bDone);
				
				kv.GoBack();
			}
			kv.GoBack();
		}
	}

	if (kv.JumpToKey("Map") && !bDone)
	{
		char sMapName[64];
		GetCurrentMap(sMapName, sizeof(sMapName));
		
		if (kv.GotoFirstSubKey())
		{
			do
			{
				char sCompare[64];
				kv.GetSectionName(sCompare, sizeof(sCompare));
				
				if (strncmp(sMapName, sCompare, strlen(sCompare)) != 0)
					continue;
				
				iAmount = kv.GetNum("amount", iAmount);
				iActiveOnly = kv.GetNum("active_only", iActiveOnly);
				iRerollDeath = kv.GetNum("reroll_on_death", iRerollDeath);
				iRerollSlot = kv.GetNum("reroll_on_slot_change", iRerollSlot);
				kv.GetString("only_allow_team", sTeam, sizeof(sTeam), sTeam);
				kv.GetString("blacklist", sBlacklist, sizeof(sBlacklist), sBlacklist);
				
				bDone = true;
			}
			while (kv.GotoNextKey() && !bDone);
			
			kv.GoBack();
		}
		kv.GoBack();
	}
	
	delete kv;
	
	// Set each value
	if (iAmount >= 1)
		g_cvAttributesPerWeapon.SetInt(iAmount);
	
	if (iActiveOnly >= 0)
		g_cvActiveOnlyMode.SetInt(iActiveOnly);
	
	if (iRerollDeath >= 0)
		g_cvRerollDeath.SetInt(iRerollDeath);
	
	if (iRerollSlot >= 0)
		g_cvRerollSlot.SetInt(iRerollSlot);
	
	g_cvOnlyAllowTeam.SetString(sTeam);
	
	if (sBlacklist[0] && g_aAttributes)
	{
		char[][] sArray = new char[INDEX_MAX_LENGTH][8];
		int iLength = ExplodeString(sBlacklist, " ", sArray, INDEX_MAX_LENGTH, 8); 
		int iCount;
		
		for (int i = 0; i < iLength; i++)
		{
			int iAttIndex;
			
			if (!StringToIntEx(sArray[i], iAttIndex))
			{
				LogError("[Random Attributes] Config Blacklist couldn't read attribute index %s", sArray[i]);
				continue;
			}
			
			int iArrayIndex = g_aAttributes.FindValue(iAttIndex, ConfigAttribute::iIndex);
			
			if (iArrayIndex > -1)
			{
				g_aAttributes.Erase(iArrayIndex);
				iCount++;
			}
		}
		
		if (iCount)
			PrintToServer("[Random Attributes] Removed %d blacklisted attributes (new count is %d).", iCount, g_aAttributes.Length);
	}
}