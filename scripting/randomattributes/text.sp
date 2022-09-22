#pragma semicolon 1
#pragma newdecls required

enum
{
	ATTDESCFORM_VALUE_IS_PERCENTAGE,			// Printed as:	((m_flValue*100)-100.0)
	ATTDESCFORM_VALUE_IS_INVERTED_PERCENTAGE,	// Printed as:	((m_flValue*100)-100.0) if it's > 1.0, or ((1.0-m_flModifier)*100) if it's < 1.0
	ATTDESCFORM_VALUE_IS_ADDITIVE,				// Printed as:	m_flValue
	ATTDESCFORM_VALUE_IS_ADDITIVE_PERCENTAGE,	// Printed as:	(m_flValue*100)
	ATTDESCFORM_VALUE_IS_OR,					// Printed as:  m_flValue, but results are ORd together instead of added
	ATTDESCFORM_VALUE_IS_DATE,					// Printed as a date
	ATTDESCFORM_VALUE_IS_ACCOUNT_ID,			// Printed as steam user name
	ATTDESCFORM_VALUE_IS_PARTICLE_INDEX,		// Printed as a particle description
	ATTDESCFORM_VALUE_IS_KILLSTREAKEFFECT_INDEX,// Printed as killstreak effect description
	ATTDESCFORM_VALUE_IS_KILLSTREAK_IDLEEFFECT_INDEX,  // Printed as idle effect description
	ATTDESCFORM_VALUE_IS_ITEM_DEF,				// Printed as item name
	ATTDESCFORM_VALUE_IS_FROM_LOOKUP_TABLE,		// Printed as a string from a lookup table, specified by the attribute definition name
};

float TranslateValue(int iFormat, float flVal)
{
	switch (iFormat)
	{
		case ATTDESCFORM_VALUE_IS_PERCENTAGE: return (flVal * 100.0) - 100.0;
		case ATTDESCFORM_VALUE_IS_INVERTED_PERCENTAGE: return flVal > 1.0 ? (flVal * 100.0) - 100.0 : (1.0 - flVal) * 100.0;
		case ATTDESCFORM_VALUE_IS_ADDITIVE: return flVal;
		case ATTDESCFORM_VALUE_IS_ADDITIVE_PERCENTAGE: return flVal * 100.0;
		case ATTDESCFORM_VALUE_IS_OR: return flVal;
	}
	
	return 0.0;
}

// https://github.com/nosoop/stocksoup/blob/c78b640bc6798d086c152b56cbfe566c724c2204/memory.inc#L25
int LoadStringFromAddress(Address addr, char[] buffer, int maxlen, bool &bIsNullPointer = false)
{
	if (!addr) {
		bIsNullPointer = true;
		return 0;
	}
	
	int c;
	char ch;
	do {
		ch = view_as<int>(LoadFromAddress(addr + view_as<Address>(c), NumberType_Int8));
		buffer[c] = ch;
	} while (ch && ++c < maxlen - 1);
	return c;
}

stock void SendTextMsgOne(const int iClient, const char[] sMessage, const char[] sParam1="", const char[] sParam2="", const char[] sParam3="", const char[] sParam4="")
{
	BfWrite message = UserMessageToBfWrite(StartMessageOne("TextMsg", iClient, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS));

	message.WriteByte(2);	// HUD_PRINTCONSOLE
	message.WriteString(sMessage);
	
	message.WriteString(sParam1);
	message.WriteString(sParam2);
	message.WriteString(sParam3);
	message.WriteString(sParam4);
	
	EndMessage();
}

void DisplaySlotAttributes(int iClient, int iSlot)
{
	if (g_bDisplayedAttributes[iClient][iSlot] || !IsPlayerAlive(iClient) || !IsValidEdict(TF2_GetItemInSlot(iClient, iSlot)))
		return;
	
	char sSlotName[128];
	Format(sSlotName, sizeof(sSlotName), "%s\n%s\n%s\n", PLACEHOLDER_LINE, g_sSlotName[iSlot], PLACEHOLDER_LINE);
	SendTextMsgOne(iClient, sSlotName);
	
	int iLength = g_aClientAttributes[iClient][iSlot].Length;
	
	for (int i = 0; i < iLength; i++)
	{
		ClientAttribute attribute;
		g_aClientAttributes[iClient][iSlot].GetArray(i, attribute);
		
		Address pAttribDef = TF2Econ_GetAttributeDefinitionAddress(attribute.iIndex);
		
		char sDescription[256];
		LoadStringFromAddress(view_as<Address>(LoadFromAddress(pAttribDef + view_as<Address>(0x28), NumberType_Int32)), sDescription, sizeof(sDescription));
		
		// If there's a localized description, use that. If there isn't one, use the internal attribute name instead
		if (sDescription[0])
		{
			int iFormat = LoadFromAddress(pAttribDef + view_as<Address>(0x24), NumberType_Int32);
			float flVal = TranslateValue(iFormat, attribute.flValue);
			
			char sVal[16];
			IntToString(RoundToFloor(flVal), sVal, sizeof(sVal));
			SendTextMsgOne(iClient, sDescription, sVal);
		}
		else
		{
			TF2Econ_GetAttributeName(attribute.iIndex, sDescription, sizeof(sDescription));
			Format(sDescription, sizeof(sDescription), "%s [%.2f]", sDescription, attribute.flValue);
			SendTextMsgOne(iClient, sDescription);
		}	
	}
	
	// Lazy empty new line so the attributes dont get too mixed with console messages
	SendTextMsgOne(iClient, " ");
	g_bDisplayedAttributes[iClient][iSlot] = true;
}

void Frame_DisplayClientAttributes(int iClient)
{
	if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return;
	
	for (int iSlot = TFWeaponSlot_Primary; iSlot <= TFWeaponSlot_Melee; iSlot++)
		DisplaySlotAttributes(iClient, iSlot);
}