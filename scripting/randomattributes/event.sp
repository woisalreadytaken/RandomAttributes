void Event_Init()
{
	HookEvent("teamplay_round_win", Event_RoundEnd);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("post_inventory_application", Event_PostInventoryApplication);
}

public Action Event_RoundEnd(Event event, const char[] sName, bool bDontBroadcast)
{
	if (!g_cvEnabled.BoolValue)
		return Plugin_Continue;
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		for (int iSlot = 0; iSlot <= TFWeaponSlot_Melee; iSlot++)
		{
			UpdateClientSlot(iClient, iSlot);
			ApplyToClientSlot(iClient, iSlot);
		}
	}
	
	return Plugin_Continue;
}

public Action Event_PlayerDeath(Event event, const char[] sName, bool bDontBroadcast)
{
	if (!g_cvEnabled.BoolValue || g_cvRerollDeath.IntValue <= 0)
		return Plugin_Continue;
		
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	int iAttacker = GetClientOfUserId(event.GetInt("attacker"));
	bool bDeadRinger = (event.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER) != 0;
	
	if (!bDeadRinger && ((0 < iAttacker <= MaxClients && IsClientInGame(iAttacker) && iClient != iAttacker) || g_cvRerollDeath.IntValue >= 2))
	{
		for (int iSlot = 0; iSlot <= TFWeaponSlot_Melee; iSlot++)
		{
			UpdateClientSlot(iClient, iSlot);
			ApplyToClientSlot(iClient, iSlot);
		}
	}
	
	return Plugin_Continue;
}

public Action Event_PostInventoryApplication(Event event, const char[] sName, bool bDontBroadcast)
{
	if (!g_cvEnabled.BoolValue)
		return Plugin_Continue;
	
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	
	for (int iSlot = 0; iSlot <= TFWeaponSlot_Melee; iSlot++)
	{
		if (!g_bDisplayedAttributes[iClient][iSlot] && TF2_GetItemInSlot(iClient, iSlot) != -1)
			DisplaySlotAttributes(iClient, iSlot);
	}
	
	return Plugin_Continue;
}