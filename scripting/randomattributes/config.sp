#define CONFIG_FILEPATH 	"configs/randomattributes.cfg"
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

void Config_Refresh()
{
	if (!g_cvEnabled.BoolValue)
		return;
	
	char sConfigPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sConfigPath, sizeof(sConfigPath), CONFIG_FILEPATH);
	if (!FileExists(sConfigPath))
	{
		SetFailState("Config file for Random Attributes is missing! (%s)", sConfigPath);
		return;
	}
	
	g_aAttributes.Clear();

	KeyValues kv = new KeyValues("Attributes");
	if (!kv.ImportFromFile(sConfigPath))
	{
		SetFailState("Config file for Random Attributes could not find Attributes!");
		return;
	}
	
	if (!kv.GotoFirstSubKey())
	{
		SetFailState("Config file for Random Attributes could not find first Attributes subkey!");
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
			LogError("Random Attributes config's index %s has an invalid type: %s", sIndex, sType);
			continue;
		}
		
		char[][] sArray = new char[INDEX_MAX_LENGTH][8];
		int iLength = ExplodeString(sIndex, " ", sArray, INDEX_MAX_LENGTH, 8);
		
		for (int i = 0; i < iLength; i++)
		{
			int iIndex;
			
			if (!StringToIntEx(sArray[i], iIndex))
			{
				LogError("Random Attributes config couldn't read attribute index %s", sArray[i]);
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
	while (kv.GotoNextKey() || iAttribCount >= MAX_ATTRIBUTES);
	
	g_iAttributeAmount = iAttribCount;
	delete kv;
	PrintToServer("Loaded Random Attributes' config with %d attributes.", iAttribCount);
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientInGame(iClient))
		{
			for (int iSlot = 0; iSlot <= TFWeaponSlot_Melee; iSlot++)
			{
				UpdateClientSlot(iClient, iSlot);
				ApplyToClientSlot(iClient, iSlot);
			}
		}
	}
}