#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <csgo_colors>

#define PLUGIN_VERSION "1.0"
#define PREFIX "[{purple}♚ {green}FreeRun {purple}♚{default}]"

Handle drpEnabled;
Handle drpTime;

bool Skip = false;
bool TimeSkip = false;

public Plugin:myinfo =
{
	name = "Freerun!",
	author = "Cruze",
	description = "Freerun plugin for deathrun mod because freerun is freerun! ok?",
	version = PLUGIN_VERSION,
	url = ""
}

public void OnPluginStart()
{
	drpEnabled          = CreateConVar("dr_freerun_enable", "1", "Whether to enable plugin.");
	drpTime             = CreateConVar("dr_freerun_time", "120", "The time during which T can enter the command");
   
	HookEvent("round_start", OnFreerunRoundStart);
   
	RegConsoleCmd("sm_fr", Cmdskip);
	RegConsoleCmd("sm_freerun", Cmdskip);
	RegConsoleCmd("sm_skip", Cmdskip);
   
	AutoExecConfig(true, "dr_freerun");
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrEqual(classname, "func_button")) SDKHook(entity, SDKHook_Use, OnButtonUse);
}
public void OnFreerunRoundStart(Handle event, char[] name, bool dbc)
{
	Skip = false;
	TimeSkip = true;
	CreateTimer(GetConVarFloat(drpTime), time);
	for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i))
        {
            if (GetClientTeam(i) == 2) 
            {
                CPrintToChat(i,"%s Type {green}!fr{default} to give {blue}Counter-Terrorists {default}a {green}freerun!", PREFIX);
            }
        }
    }
}
 
public Action time(Handle time)
{
	TimeSkip = false;
}
 
public Action Cmdskip(int client, int args)
{
	if (IsPlayerAlive(client))
	{
		if (client == 0 || !IsClientInGame(client) || GetClientTeam(client) != 2) 
		{
			CPrintToChat(client, "%s You need to be {orange}Terrorist {default}in order have access to this command!", PREFIX);
			return Plugin_Handled;
		}

		if (GetConVarBool(drpEnabled)) 
		{
			if (Skip) 
			{
				CPrintToChat(client, "%s You have already used this command!", PREFIX);
			}
			else if (TimeSkip) 
			{
				Skip = true;
				CPrintToChatAll("%s The {orange}Terrorist {default}decided to give a {green}FREERUN {default}to everyone this round, {green}RUN! {default}:D", PREFIX);
				PrintHintTextToAll("<b>Its </b><b><font color='#00ff00'>FREERUN!</font></b>");
			}
			else 
			{
				int ZeTime = GetConVarInt(drpTime);
				CPrintToChat(client, "%s You can use this command in first {darkred}%d {default}seconds only!", PREFIX, ZeTime);
			}
		}
	}
	else
	{
		CPrintToChat(client, "%s You need to be alive to use this command!", PREFIX);
	}
	return Plugin_Handled;
}

public void OnClientSayCommand_Post(int client, const char[] command, const char[] sArgs)
{
	if (strcmp(sArgs, "fr", false) == 0 || strcmp(sArgs, "freerun", false) == 0)
	{
		Cmdskip(client,0);
	}
}
 
public Action OnButtonUse(int entity, int activator, int client, UseType type, float value)
{
	if(client == 0 || !IsClientInGame(client) || GetClientTeam(client) != 2 ) 
	{
		return Plugin_Continue;
	}

	if(Skip){
		CPrintToChat(client, "%s {lightgreen}You can not activate any {darkred}Traps{lightgreen} as you decided to give freerun. {darkred}Deal {green}with {blue}it.{default}", PREFIX); 
		return Plugin_Handled;
	}
	return Plugin_Continue;
}