#pragma semicolon 1
#pragma newdecls required

static Handle g_hSDKCallGetEquippedWearableForLoadoutSlot;

void SDKCall_Init(GameData hGameData)
{
	g_hSDKCallGetEquippedWearableForLoadoutSlot = PrepSDKCall_GetEquippedWearableForLoadoutSlot(hGameData);
}

static Handle PrepSDKCall_GetEquippedWearableForLoadoutSlot(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTFPlayer::GetEquippedWearableForLoadoutSlot");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create call: CTFPlayer::GetEquippedWearableForLoadoutSlot");
	
	return call;
}

int SDKCall_GetEquippedWearableForLoadoutSlot(int iClient, int iSlot)
{
	if (g_hSDKCallGetEquippedWearableForLoadoutSlot != null)
		return SDKCall(g_hSDKCallGetEquippedWearableForLoadoutSlot, iClient, iSlot);
	return -1;
}