#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <csgo_colors>

#define PLUGIN_VERSION "1.1"

ConVar gc_bfrEnabled, gc_ifrTime, gc_sPrefix;

float g_iFreerunTime;
char PrefixName[128];

int g_bEnabled;
bool Freerun = false;
bool FreerunTime = false;

public Plugin:myinfo =
{
	name = "Freerun!",
	author = "Cruze",
	description = "Freerun plugin for deathrun mod because freerun is freerun! ok?",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/profiles/76561198132924835"
}

public void OnPluginStart()
{
	gc_bfrEnabled          = CreateConVar("sm_freerun_enable", "1", 												"Whether to enable plugin. 1 to enable, any other interger number to disable.");
	gc_sPrefix         	 = CreateConVar("sm_freerun_prefix", "[{purple}♚ {green}FreeRun {purple}♚{default}] ", "Prefix of the plugin. Leave blank for no prefix.");
	gc_ifrTime             = CreateConVar("sm_freerun_time", "120.0", 											"The time during which T can enter the command. 120.0 = ✔. 120 = ✖");
   
	HookEvent("round_start", OnFreerunRoundStart);
   
	RegConsoleCmd("sm_fr", CMD_Freerun);
	RegConsoleCmd("sm_freerun", CMD_Freerun);
   
	AutoExecConfig(true, "dr_freerun");
	LoadTranslations("cruze_freerun.phrases");
	
	HookConVarChange(gc_bfrEnabled, OnSettingChanged);
	HookConVarChange(gc_ifrTime, OnSettingChanged);
}
public int OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(convar == gc_bfrEnabled)
	{
		g_bEnabled = StringToInt(newValue);
	}
	if (convar == gc_ifrTime)
	{
		g_iFreerunTime = StringToFloat(newValue);
	}
}
public void OnConfigsExecuted()
{
	g_bEnabled = GetConVarInt(gc_bfrEnabled);
	g_iFreerunTime	= GetConVarFloat(gc_ifrTime);
	GetConVarString(gc_sPrefix, PrefixName, sizeof(PrefixName));
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrEqual(classname, "func_button")) SDKHook(entity, SDKHook_Use, OnButtonUse);
}
public void OnFreerunRoundStart(Handle event, char[] name, bool dbc)
{
	Freerun = false;
	FreerunTime = true;
	CreateTimer(GetConVarFloat(gc_ifrTime), freeruntime);
	for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && GetClientTeam(i) == 2)
        {
			//CPrintToChat(i,"%s Type {green}!fr{default} to give {blue}Counter-Terrorists {default}a {green}freerun!", g_sPluginPrefix);
			if (g_bEnabled == 1)
				CPrintToChat(i,"%s%t", PrefixName, "RoundStart Message");
        }
    }
}
 
public Action freeruntime(Handle freeruntime)
{
	FreerunTime = false;
}
 
public Action CMD_Freerun(int client, int args)
{
	if (g_bEnabled == 1)
	{
		if (IsPlayerAlive(client))
		{
			if (client == 0 || !IsClientInGame(client) || GetClientTeam(client) != 2) 
			{
				//CPrintToChat(client, "%s You need to be {orange}Terrorist {default}in order have access to this command!", PrefixName);
				CPrintToChat(client, "%s%t", PrefixName, "You need to be T");
				return Plugin_Handled;
			}
			if (FreerunTime)
			{
				Freerun = true;
				for(int iClient = 1; iClient <= MaxClients; iClient++)
				{
					if(IsClientInGame(iClient) && GetClientTeam(iClient) == 3)
					{
						//CPrintToChat(iClient, "%s{orange}Terrorist{default} can no longer press trap buttons!", PrefixName);
						CPrintToChat(iClient, "%s%t", PrefixName, "FreerunCTMsg");
					}
				}
				//CPrintToChatAll("%s The {orange}Terrorist {default}decided to give a {green}FREERUN {default}to everyone this round, {green}RUN! {default}:D", PrefixName);
				CPrintToChatAll("%s%t", PrefixName, "Freerun!");
				PrintHintTextToAll("%t", "Freerun Hint!");
				//PrintHintTextToAll("<b>Its <font color='#00ff00'>FREERUN!</font></b>");
			}
			else if (Freerun) 
			{
				//CPrintToChat(client, "%s You have already used this command!", PrefixName);
				CPrintToChat(client, "%s%t", PrefixName, "Already Used");
			}
			else
			{
				int frTime = RoundToFloor(g_iFreerunTime);
				//CPrintToChat(client, "%s You can use this command in first {darkred}%d {default}seconds only!", PrefixName, frTime);
				CPrintToChat(client, "%s%t", PrefixName, "Too Late", frTime);
			}
		}
		else
		{
			//CPrintToChat(client, "You need to be alive to use this command!", PrefixName);
			CPrintToChat(client, "%s%t", PrefixName, "You need to be alive");
		}
		return Plugin_Handled;
	}
	return Plugin_Stop;
}

public void OnClientSayCommand_Post(int client, const char[] command, const char[] sArgs)
{
	if (strcmp(sArgs, "fr", false) == 0 || strcmp(sArgs, "freerun", false) == 0)
	{
		CMD_Freerun(client,0);
	}
}
 
public Action OnButtonUse(int entity, int activator, int client, UseType type, float value)
{
	if(client == 0 || !IsClientInGame(client) || GetClientTeam(client) != 2 ) 
	{
		return Plugin_Continue;
	}

	if(Freerun)
	{
		//CPrintToChat(client, "%s {lightgreen}You can not activate any {darkred}Traps{lightgreen} as you decided to give freerun. {darkred}Deal {green}with {blue}it.{default}", PrefixName); 
		CPrintToChat(client, "%s%t", PrefixName, "You cannot activate"); 
		return Plugin_Handled;
	}
	return Plugin_Continue;
}