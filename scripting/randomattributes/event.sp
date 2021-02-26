void Event_Init()
{
	HookEvent("teamplay_round_win", Event_RoundEnd);
	HookEvent("post_inventory_application", Event_PlayerInventoryUpdate);
	HookEvent("player_death", Event_PlayerDeath);
}

public Action Event_RoundEnd(Event event, const char[] sName, bool bDontBroadcast)
{
	if (!g_cvEnabled.BoolValue)
		return Plugin_Continue;
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientInGame(iClient))
			UpdateClient(iClient);
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
		UpdateClient(iClient);
	
	return Plugin_Continue;
}

public Action Event_PlayerInventoryUpdate(Event event, const char[] sName, bool bDontBroadcast)
{
	if (!g_cvEnabled.BoolValue)
		return Plugin_Continue;
		
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	if (TF2_GetClientTeam(iClient) <= TFTeam_Spectator)
		return Plugin_Continue;
		
	if (IsClientInGame(iClient) && IsPlayerAlive(iClient))
	{
		for (int iSlot = 0; iSlot <= TFWeaponSlot_Melee; iSlot++)
		{
			DataPack data = new DataPack();
			data.WriteCell(iClient);
			data.WriteCell(iSlot);
			data.Reset();
			RequestFrame(Frame_ApplyToClientSlot, data);	//Applying to the slot instead of to the weapon directly makes this compatible with gamemodes that give different weapons on spawn regardless of weapon creation settings, as they'd change by next frame
		}
	}
	
	return Plugin_Continue;
}

void Frame_ApplyToClientSlot(DataPack data)
{
	int iClient = data.ReadCell();
	int iSlot = data.ReadCell();
	ApplyToClientSlot(iClient, iSlot);
	delete data;
}