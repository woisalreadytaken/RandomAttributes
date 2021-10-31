#include <sourcemod>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <tf_econ_data>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION		"0.6"

#define TF_MAXPLAYERS 		34	//32 clients + 1 for 0/world/console + 1 for replay/SourceTV
#define MAX_WEAPON_SLOTS 	3
#define PLACEHOLDER_LINE 	"-----------------------------------------"

ConVar g_cvEnabled;
ConVar g_cvActiveOnlyMode;
ConVar g_cvAttributesPerWeapon;
ConVar g_cvAttributesPerWeaponUpdate;
ConVar g_cvRerollDeath;
ConVar g_cvRerollSlot;

public ArrayList g_aAttributes;
public ArrayList g_aClientAttributes[TF_MAXPLAYERS][MAX_WEAPON_SLOTS];
public bool g_bDisplayedAttributes[TF_MAXPLAYERS][MAX_WEAPON_SLOTS];
public int g_iAttributeAmount;

char g_sSlotName[][] = {
	"Primary",
	"Secondary",
	"Melee"
};

enum struct ConfigAttribute
{
	int iIndex;
	int iType;
	float flMin;
	float flMax;
}

enum struct ClientAttribute
{
	int iIndex;
	float flValue;
}

#include "randomattributes/config.sp"
#include "randomattributes/convar.sp"
#include "randomattributes/command.sp"
#include "randomattributes/event.sp"
#include "randomattributes/text.sp"

public Plugin myinfo =
{
	name = "Random Attributes",
	author = "wo",
	description = "Adds random attributes to primary, secondary and melee weapons.",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/mmmwo/"
}

public void OnPluginStart()
{
	ConVar_Init();
	Command_Init();
	Event_Init();
	
	Enable();
}

public void OnConfigsExecuted()
{
	if (!g_cvEnabled.BoolValue)
		return;
	
	Config_RefreshSettings();
}
public void OnClientPutInServer(int iClient)
{
	if (!g_cvEnabled.BoolValue)
		return;
	
	UpdateClient(iClient);
}

public void OnEntityCreated(int iEntity, const char[] sClassname)
{
	if (!g_cvEnabled.BoolValue)
		return;
	
	if (StrContains(sClassname, "tf_weapon") == 0 || StrContains(sClassname, "tf_wearable") == 0)
	{
		SDKHook(iEntity, SDKHook_Spawn, Hook_WeaponSpawn);
	}
	else if (StrEqual(sClassname, "tf_dropped_weapon"))
	{
		SDKHook(iEntity, SDKHook_Spawn, Hook_DroppedWeaponSpawn);
	}
}

public void Hook_WeaponSpawn(int iWeapon)
{
	if (iWeapon <= MaxClients || !IsValidEdict(iWeapon))
		return;
	
	int iIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
	
	//If it's 65535 and is therefore not a weapon, like the Buff Banner's backpack (which is not the same as the Buff Banner's bugle), don't even bother
	if (iIndex == 65535)
		return;
	
	//Doesn't have to be the exact slot in here, just want to know if it's a primary/secondary/melee weapon
	int iSlot = TF2Econ_GetItemDefaultLoadoutSlot(iIndex);
	
	char sClassname[32];
	GetEntityClassname(iWeapon, sClassname, sizeof(sClassname));
	
	//Sappers aren't secondaries, and we want to randomize them too. We also need a frame to know who's getting the weapon
	if ((iSlot <= TFWeaponSlot_Melee && iSlot != -1) || (StrEqual(sClassname, "tf_weapon_builder") && iIndex != 28))
		RequestFrame(Frame_ApplyOnWeaponSpawn, iWeapon);
	
	//Unhooking it here because otherwise it gets called twice... for some reason...
	SDKUnhook(iWeapon, SDKHook_Spawn, Hook_WeaponSpawn);
}

public void Frame_ApplyOnWeaponSpawn(int iWeapon)
{
	if (iWeapon <= MaxClients || !IsValidEdict(iWeapon))
		return;
	
	int iClient = GetEntPropEnt(iWeapon, Prop_Send, "m_hOwnerEntity");
	
	//Just making sure. This seems to pass when a STT giant is destroyed
	if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return;
	
	TFClassType pClass = TF2_GetPlayerClass(iClient);
	int iIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
	int iSlot = TF2Econ_GetItemLoadoutSlot(iIndex, pClass);
	
	//Attempt to add Randomizer compatibility, if slot is invalid for the player's class, try again but for the weapon's default slot instead
	if (iSlot == -1)
		iSlot = TF2Econ_GetItemDefaultLoadoutSlot(iIndex);
	
	//fuck spies (engineer builder is already ignored at this point)
	char sClassname[32];
	GetEntityClassname(iWeapon, sClassname, sizeof(sClassname));
	
	if (StrEqual(sClassname, "tf_weapon_revolver"))
	{
		iSlot = TFWeaponSlot_Primary;
	}
	else if (StrEqual(sClassname, "tf_weapon_builder"))
	{
		iSlot = TFWeaponSlot_Secondary;
	}
	
	if (iSlot <= TFWeaponSlot_Melee)
	{
		if (g_cvRerollSlot.BoolValue)
			UpdateClientSlot(iClient, iSlot);
		
		ApplyToWeapon(iWeapon, iClient, iSlot);
	}
}

public void Hook_DroppedWeaponSpawn(int iWeapon)
{
	//If attributes are given on weapon creation, attributes of the player will stack with previous attributes this dropped weapon had, and should be disabled in that case
	TF2Attrib_RemoveAll(iWeapon);
	SDKUnhook(iWeapon, SDKHook_Spawn, Hook_WeaponSpawn);
}

public void OnPluginEnd()
{
	if (g_cvEnabled.BoolValue)
		Disable();
}

public void Enable()
{
	if (!g_cvEnabled.BoolValue)
		return;
	
	g_aAttributes = new ArrayList(sizeof(ConfigAttribute));
	bool bSettingsLoaded = false;
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		for (int iSlot = 0; iSlot <= TFWeaponSlot_Melee; iSlot++)
			g_aClientAttributes[iClient][iSlot] = new ArrayList(sizeof(ClientAttribute));
		
		//In case the plugin is enabled mid-match, load the settings config too if there's at least one player ingame
		if (!bSettingsLoaded && IsClientInGame(iClient))
		{
			Config_RefreshSettings();
			bSettingsLoaded = true;
		}
	}
	
	Config_RefreshAttributes();
}

public void Disable()
{	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientInGame(iClient))
		{
			for (int iSlot = 0; iSlot <= TFWeaponSlot_Melee; iSlot++)
			{
				g_aClientAttributes[iClient][iSlot].Clear();
				int iWeapon = GetPlayerWeaponSlot(iClient, iSlot);
				
				if (iWeapon > MaxClients && IsValidEdict(iWeapon))
				{
					TF2Attrib_RemoveAll(iWeapon);
					TF2Attrib_ClearCache(iWeapon);
				}
			}
		}
	}
	
	g_aAttributes.Clear();

}

void UpdateClient(int iClient, bool bRefresh = true)
{
	//Store new information for a client so it can be added later
	for (int iSlot = 0; iSlot <= TFWeaponSlot_Melee; iSlot++)
		UpdateClientSlot(iClient, iSlot, bRefresh);
}

void UpdateClientSlot(int iClient, int iSlot, bool bRefresh = true)
{
	if (!g_cvEnabled.BoolValue)
		return;
		
	//Store new information for a specific weapon slot of a client so it can be added later
	g_aClientAttributes[iClient][iSlot].Clear();
	g_bDisplayedAttributes[iClient][iSlot] = false;
	
	//If Active Only mode is, heh, active, add the 'provide on active' attribute first
	if (g_cvActiveOnlyMode.BoolValue)
	{
		ClientAttribute attribute;
		
		attribute.iIndex = 128;
		attribute.flValue = 1.0;
		
		g_aClientAttributes[iClient][iSlot].PushArray(attribute);
	}
	
	for (int i = 0; i < g_cvAttributesPerWeapon.IntValue; i++)
	{
		ClientAttribute attributeClient;
		ConfigAttribute attributeConfig;
		
		//Get a random available attribute index
		g_aAttributes.GetArray(GetRandomInt(0, g_iAttributeAmount-1), attributeConfig);
		
		attributeClient.iIndex = attributeConfig.iIndex;
		
		//Get the a random value between the max and min values set by the config
		switch (attributeConfig.iType)
		{
			case ConfigAttributeType_Int: attributeClient.flValue = float(GetRandomInt(RoundToNearest(attributeConfig.flMin), RoundToNearest(attributeConfig.flMax)));
			case ConfigAttributeType_Float: attributeClient.flValue = GetRandomFloat(attributeConfig.flMin, attributeConfig.flMax);
			default: LogError("Couldn't fetch attribute type %d to client %N", attributeConfig.iType, iClient);
		}
		
		g_aClientAttributes[iClient][iSlot].PushArray(attributeClient);
	}
	
	if (bRefresh && IsClientInGame(iClient))
	{
		int iWeapon = GetPlayerWeaponSlot(iClient, iSlot);
	
		if (iWeapon > MaxClients && IsValidEdict(iWeapon))
			TF2Attrib_RemoveAll(iWeapon);
	}
}

void ApplyToClientSlot(int iClient, int iSlot)
{
	if (IsClientInGame(iClient))
	{
		int iWeapon = GetPlayerWeaponSlot(iClient, iSlot); 
		ApplyToWeapon(iWeapon, iClient, iSlot);
	}
}

void ApplyToWeapon(int iWeapon, int iClient, int iSlot)
{
	if (iWeapon <= MaxClients || !IsValidEdict(iWeapon) || !IsClientInGame(iClient))
		return;
	
	//Check if the length of the client's slot array is higher than the currently set sm_ra_amount convar. Can happen if the convar is changed but set to not update slots right away
	int iLength = g_aClientAttributes[iClient][iSlot].Length;
	int iExpectedLength = g_cvAttributesPerWeapon.IntValue;

	if (iLength > iExpectedLength)
		iLength = iExpectedLength;
	
	//Get each attribute stored for that slot and apply them to the weapon!
	for (int i = 0; i < iLength; i++)
	{
		ClientAttribute attribute;
		g_aClientAttributes[iClient][iSlot].GetArray(i, attribute);
		TF2Attrib_SetByDefIndex(iWeapon, attribute.iIndex, attribute.flValue);
	}
	
	TF2Attrib_ClearCache(iWeapon);
	DisplaySlotAttributes(iClient, iSlot);
}