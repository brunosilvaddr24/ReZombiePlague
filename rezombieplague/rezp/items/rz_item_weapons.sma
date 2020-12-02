#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

new g_iItem_AWP;
new g_iItem_M249;
new g_iItem_SG550;
new g_iItem_G3SG1;

new g_iClass_Human;

public plugin_precache()
{
	register_plugin("[ReZP] Item: Weapons", REZP_VERSION_STR, "fl0wer");

	new item = g_iItem_AWP = rz_item_create("human_awp");

	rz_item_set_name_langkey(item, "RZ_ITEM_WPN_AWP");
	rz_item_set_cost(item, 8);

	item = g_iItem_M249 = rz_item_create("human_m249");

	rz_item_set_name_langkey(item, "RZ_ITEM_WPN_M249");
	rz_item_set_cost(item, 10);

	item = g_iItem_SG550 = rz_item_create("human_sg550");

	rz_item_set_name_langkey(item, "RZ_ITEM_WPN_SG550");
	rz_item_set_cost(item, 12);

	item = g_iItem_G3SG1 = rz_item_create("human_g3sg1");

	rz_item_set_name_langkey(item, "RZ_ITEM_WPN_G3SG1");
	rz_item_set_cost(item, 12);
}

public plugin_init()
{
	g_iClass_Human = rz_class_find("human");
}

public rz_item_select_pre(id, item)
{
	if (item != g_iItem_AWP &&
		item != g_iItem_M249 &&
		item != g_iItem_SG550 &&
		item != g_iItem_G3SG1)
		return RZ_CONTINUE;

	if (rz_class_player_get(id) != g_iClass_Human)
		return RZ_BREAK;

	return RZ_CONTINUE;
}

public rz_item_select_post(id, item)
{
	if (item == g_iItem_AWP)
	{
		rg_give_item(id, "weapon_awp", GT_DROP_AND_REPLACE);
	}
	else if (item == g_iItem_M249)
	{
		rg_give_item(id, "weapon_m249", GT_DROP_AND_REPLACE);
	}
	else if (item == g_iItem_SG550)
	{
		rg_give_item(id, "weapon_sg550", GT_DROP_AND_REPLACE);
	}
	else if (item == g_iItem_G3SG1)
	{
		rg_give_item(id, "weapon_g3sg1", GT_DROP_AND_REPLACE);
	}
}
