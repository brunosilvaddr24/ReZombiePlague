#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

new g_iGameMode_AVS;

new g_iClass_Assassin;
new g_iClass_Sniper;

public plugin_init()
{
	register_plugin("[ReZP] Game Mode: Assassins vs. Snipers", REZP_VERSION_STR, "fl0wer");

	RZ_CHECK_CLASS_EXISTS(g_iClass_Assassin, "assassin");
	RZ_CHECK_CLASS_EXISTS(g_iClass_Sniper, "sniper");

	new gameMode = g_iGameMode_AVS = rz_gamemode_create("avs");

	rz_gamemode_set_name_langkey(gameMode, "RZ_GAMEMODE_AVS");
	rz_gamemode_set_notice_langkey(gameMode, "RZ_GAMEMODE_NOTICE_AVS");
	rz_gamemode_set_hudcolor(gameMode, { 200, 150, 20 });
	rz_gamemode_set_chance(gameMode, 20);
	rz_gamemode_set_minalives(gameMode, 8);
}

public rz_gamemode_start_post(mode, Array:alivesArray)
{
	if (mode != g_iGameMode_AVS)
		return;

	new alivesNum = ArraySize(alivesArray);
	new maxAssassins = floatround(alivesNum * 0.5, floatround_ceil);
	new Float:health;
	
	new item;
	new player;
	
	for (new i = 0; i < maxAssassins; i++)
	{
		item = random_num(0, ArraySize(alivesArray) - 1);
		player = ArrayGetCell(alivesArray, item);

		rz_class_player_change(player, 0, g_iClass_Assassin);

		health = Float:get_entvar(player, var_health) * 0.5;

		set_entvar(player, var_health, health);
		set_entvar(player, var_max_health, health);

		ArrayDeleteItem(alivesArray, item);
	}

	alivesNum = ArraySize(alivesArray);

	for (new i = 0; i < alivesNum; i++)
	{
		player = ArrayGetCell(alivesArray, i);

		rz_class_player_change(player, 0, g_iClass_Sniper);

		health = Float:get_entvar(player, var_health) * 1.5;

		set_entvar(player, var_health, health);
		set_entvar(player, var_max_health, health);
	}

	rz_class_override_default(TEAM_TERRORIST, g_iClass_Assassin);
	rz_class_override_default(TEAM_CT, g_iClass_Sniper);
}
