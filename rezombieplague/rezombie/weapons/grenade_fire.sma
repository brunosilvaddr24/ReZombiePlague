#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <xs>
#include <reapi>
#include <rezp_inc/rezp_main>
#include <rezp_inc/util_tempentities>

new const FIRE_VIEW_MODEL[] = "models/rezombie/weapons/grenades/fire_v.mdl";
new const FIRE_EXPLODE_SOUND[] = "rezombie/weapons/grenades/explode.wav";
new const FIRE_BURN_SOUND[][] = {
	"rezombie/zombie/burn3.wav",
	"rezombie/zombie/burn4.wav",
	"rezombie/zombie/burn5.wav",
	"rezombie/zombie/burn6.wav",
	"rezombie/zombie/burn7.wav",
};

new const FLAME_SPRITE[] = "sprites/rezombie/weapons/grenades/flame.spr";
new const FLAME_CLASSNAME[] = "ent_pFlame2";

new g_iFlameEntity[MAX_PLAYERS + 1];
new bool:g_bFireDamage[MAX_PLAYERS + 1];

new g_iModelIndex_Flame;
new g_iModelIndex_LaserBeam;
new g_iModelIndex_ShockWave;
new g_iModelIndex_BlackSmoke3;

new g_iGrenade_Fire;

enum _:Forwards
{
	Fw_Return,
	Fw_Fire_Grenade_Burn_Pre,
	Fw_Fire_Grenade_Burn_Post,

}; new gForwards[Forwards];

public plugin_precache()
{
	register_plugin("[ReZP] Grenade: Fire", REZP_VERSION_STR, "fl0wer");

	precache_sound(FIRE_EXPLODE_SOUND);

	for (new i = 0; i < sizeof(FIRE_BURN_SOUND); i++)
		precache_sound(FIRE_BURN_SOUND[i]);

	g_iModelIndex_Flame = precache_model(FLAME_SPRITE);
	g_iModelIndex_LaserBeam = precache_model("sprites/laserbeam.spr");
	g_iModelIndex_ShockWave = precache_model("sprites/shockwave.spr");
	g_iModelIndex_BlackSmoke3 = precache_model("sprites/black_smoke3.spr");

	new grenade = g_iGrenade_Fire = rz_grenade_create("grenade_fire", "weapon_hegrenade");

	set_grenade_var(grenade, RZ_GRENADE_NAME, "RZ_WPN_FIRE_GRENADE");
	set_grenade_var(grenade, RZ_GRENADE_SHORT_NAME, "RZ_WPN_FIRE_SHORT");
	set_grenade_var(grenade, RZ_GRENADE_VIEW_MODEL, FIRE_VIEW_MODEL);

	set_grenade_var(grenade, RZ_GRENADE_DISTANCE_EFFECT, 350.0);
	set_grenade_var(grenade, RZ_GRENADE_PLAYERS_DAMAGE, 100.0);
}

public plugin_init()
{
	RegisterHookChain(RH_SV_StartSound, "@SV_StartSound_Pre", .post = false);
	
	RegisterHookChain(RG_CSGameRules_RestartRound, "@CSGameRules_RestartRound_Post", .post = true);

	RegisterHookChain(RG_CBasePlayer_Killed, "@CBasePlayer_Killed_Pre", .post = false);
	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "@CBasePlayer_ResetMaxSpeed_Post", .post = true);
	RegisterHookChain(RG_CBasePlayer_SetAnimation, "@CBasePlayer_SetAnimation_Pre", .post = false);

	gForwards[Fw_Fire_Grenade_Burn_Pre] = CreateMultiForward("rz_fire_grenade_burn_pre", ET_CONTINUE, FP_CELL);
	gForwards[Fw_Fire_Grenade_Burn_Post] = CreateMultiForward("rz_fire_grenade_burn_post", ET_IGNORE, FP_CELL);
}

public plugin_natives() {
	register_native("rz_grenade_set_user_fire", "@native_grenade_set_user_fire");
}

public rz_grenades_throw_post(id, entity, grenade)
{
	if (grenade != g_iGrenade_Fire)
		return;

	rz_util_set_rendering(entity, kRenderNormal, 16.0, Float:{ 200.0, 0.0, 0.0 }, kRenderFxGlowShell);

	message_begin_f(MSG_ALL, SVC_TEMPENTITY);
	TE_BeamFollow(entity, g_iModelIndex_LaserBeam, 10, 10, { 200, 0, 0 }, 255);
}

public rz_grenades_explode_pre(pEntity, pGrenade)
{
	if (pGrenade != g_iGrenade_Fire)
		return RZ_CONTINUE;

	new pAttacker = get_entvar(pEntity, var_owner);
	new Float:vecOrigin[3];
	new Float:vecOrigin2[3];
	new Float:vecAxis[3];

	get_entvar(pEntity, var_origin, vecOrigin);

	vecAxis = vecOrigin;
	vecAxis[2] += 555.0;

	message_begin_f(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
	TE_BeamCylinder(vecOrigin, vecAxis, g_iModelIndex_ShockWave, 0, 0, 4, 60, 0, { 200, 0, 0 }, 200, 0);

	rh_emit_sound2(pEntity, 0, CHAN_WEAPON, FIRE_EXPLODE_SOUND, VOL_NORM, ATTN_NORM);

	for (new pTarget = 1; pTarget <= MaxClients; pTarget++)
	{
		if (!is_user_alive(pTarget))
			continue;

		get_entvar(pTarget, var_origin, vecOrigin2);
		new Float:pGrenadeDistance = Float:get_grenade_var(pGrenade, RZ_GRENADE_DISTANCE_EFFECT);
		if (vector_distance(vecOrigin, vecOrigin2) > pGrenadeDistance)
			continue;

		// Does not work with bots
		/*if (!ExecuteHamB(Ham_FVisible, pTarget, entity))
			continue;*/ // In the future I will replace it with another option

		if (get_member(pTarget, m_iTeam) != TEAM_TERRORIST)
			continue;

		IgnitePlayer(pTarget, pAttacker, 12.0, Float:get_grenade_var(pGrenade, RZ_GRENADE_PLAYERS_DAMAGE));
	}

	return RZ_BREAK;
}

public rz_class_change_pre(id, attacker, class) {
	Flame_Destroy(id, true);
}

@SV_StartSound_Pre(recipients, entity, channel, sample[], volume, Float:attenuation, flags, pitch) {
	if (!is_user_connected(entity))
		return HC_CONTINUE;

	if (!g_bFireDamage[entity])
		return HC_CONTINUE;

	return HC_SUPERCEDE;
}

@CSGameRules_RestartRound_Post() for (new pTarget = 1; pTarget <= MaxClients; pTarget++) {
	Flame_Destroy(pTarget);
}

@CBasePlayer_Killed_Pre(pVictim, attacker, gib) {
	// maybe spawn?
	Flame_Destroy(pVictim, true);
	g_bFireDamage[pVictim] = false;
}

@CBasePlayer_ResetMaxSpeed_Post(const id)
{
	if (is_nullent(g_iFlameEntity[id]))
		return;

	new Float:burnSpeed = 185.0;
	new Float:maxSpeed = get_entvar(id, var_maxspeed) * 0.75;

	set_entvar(id, var_maxspeed, floatmax(maxSpeed, burnSpeed));
}

@CBasePlayer_SetAnimation_Pre(id, PLAYER_ANIM:playerAnim) {
	if (!g_bFireDamage[id])
		return HC_CONTINUE;

	return HC_SUPERCEDE;
}

@native_grenade_set_user_fire(plugin_id, num_params) {
	enum {
		ArgpTarget = 1,
		ArgpAttacker = 2,
		ArgpDuration = 3,
		ArgpDamage = 4,
	};

	new pTarget = get_param(ArgpTarget);
	new pAttacker = get_param(ArgpAttacker);
	new Float:pDuration = get_param_f(ArgpDuration);
	new Float:pDamage = get_param_f(ArgpDamage);

	if (!is_user_alive(pTarget)) {
		return false;
	}

	IgnitePlayer(pTarget, pAttacker, pDuration, pDamage);
	return true;
}

IgnitePlayer(pTarget, pAttacker, Float:pDuration, Float:pDamage)
{
	ExecuteForward(gForwards[Fw_Fire_Grenade_Burn_Pre], gForwards[Fw_Return], pTarget);

	if (gForwards[Fw_Return] >= RZ_SUPERCEDE)
		return;

	new flame = g_iFlameEntity[pTarget];

	if (is_nullent(flame)) {
		flame = Flame_Create(pTarget, pAttacker, pDuration, pDamage);
	}
	else {
		// Burn again
		Flame_Destroy(pTarget, true);
		flame = Flame_Create(pTarget, pAttacker, pDuration, pDamage);
	}

	g_iFlameEntity[pTarget] = flame;
	rg_reset_maxspeed(pTarget);
	ExecuteForward(gForwards[Fw_Fire_Grenade_Burn_Post], gForwards[Fw_Return], pTarget);
}

Flame_Create(pTarget, pAttacker, Float:pDuration = 0.0, Float:pDamage = 1.0)
{
	new pFlame = rg_create_entity("env_sprite");

	if (is_nullent(pFlame))
		return 0;

	new Float:pGametime = get_gametime();

	set_entvar(pFlame, var_classname, FLAME_CLASSNAME);
	set_entvar(pFlame, var_owner, pAttacker);
	set_entvar(pFlame, var_aiment, pTarget);
	set_entvar(pFlame, var_enemy, pTarget);
	set_entvar(pFlame, var_dmg_take, pDamage);
	set_entvar(pFlame, var_movetype, MOVETYPE_FOLLOW);
	set_entvar(pFlame, var_nextthink, pGametime);
	set_entvar(pFlame, var_dmgtime, pGametime + pDuration);

	set_entvar(pFlame, var_framerate, 1.0);
	set_entvar(pFlame, var_scale, 0.4);
	set_entvar(pFlame, var_rendermode, kRenderTransAdd);
	set_entvar(pFlame, var_renderamt, 255.0);

	engfunc(EngFunc_SetModel, pFlame, FLAME_SPRITE);

	set_ent_data_float(pFlame, "CSprite", "m_lastTime", pGametime);
	set_ent_data_float(pFlame, "CSprite", "m_maxFrame", float(engfunc(EngFunc_ModelFrames, g_iModelIndex_Flame) - 1));

	SetThink(pFlame, "@Flame_Think");

	return pFlame;
}

Flame_Destroy(pTarget, bool:smoke = false)
{
	new pFlame = g_iFlameEntity[pTarget];

	g_iFlameEntity[pTarget] = 0;

	if (is_nullent(pFlame))
		return;

	if (smoke && is_user_connected(pTarget))
	{
		new Float:vecOrigin[3];
		new Float:vecOffset[3];

		get_entvar(pTarget, var_origin, vecOrigin);

		vecOffset = vecOrigin;
		vecOffset[2] -= 50.0;

		message_begin_f(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
		TE_Smoke(vecOffset, g_iModelIndex_BlackSmoke3, random_num(15, 20), random_num(10, 20));
	}

	set_entvar(pFlame, var_flags, FL_KILLME);
}

@Flame_Think(const pEntity)
{
	new pTarget = get_entvar(pEntity, var_enemy);
	new Float:time = get_gametime();

	if ((!is_nullent(pTarget) && get_entvar(pTarget, var_flags) & FL_INWATER) || Float:get_entvar(pEntity, var_dmgtime) <= time)
	{
		Flame_Destroy(pTarget, true);

		if (is_user_alive(pTarget)) {
			rg_reset_maxspeed(pTarget);
		}
		return;
	}

	if (Float:get_entvar(pEntity, var_pain_finished) <= time)
	{
		set_entvar(pEntity, var_pain_finished, time + 0.8);

		if (random_num(0, 4))
			rh_emit_sound2(pTarget, 0, CHAN_VOICE, FIRE_BURN_SOUND[random_num(0, sizeof(FIRE_BURN_SOUND) - 1)], VOL_NORM, ATTN_NORM);

		new pAttacker = get_entvar(pEntity, var_owner);
		if (pAttacker && !is_user_connected(pAttacker))
		{
			pAttacker = 0;
			set_entvar(pEntity, var_owner, 0);
		}

		if (rg_is_player_can_takedamage(pTarget, pAttacker))
		{
			new Float:velocityModifier = get_member(pTarget, m_flVelocityModifier);
			static Float:vecVelocity[3], Float:velocity[3];

			get_entvar(pTarget, var_velocity, vecVelocity);
			get_entvar(pEntity, var_velocity, velocity);

			xs_vec_normalize(velocity, velocity);


			g_bFireDamage[pTarget] = true;
		
			set_member(pTarget, m_LastHitGroup, HITGROUP_GENERIC);

			rg_multidmg_clear();
			rg_multidmg_add(pEntity, pTarget, Float:get_entvar(pEntity, var_dmg_take), DMG_BURN | DMG_NEVERGIB);
			rg_multidmg_apply(pEntity, pAttacker);
	
			g_bFireDamage[pTarget] = false;

			if (is_user_alive(pTarget))
			{
				set_entvar(pTarget, var_velocity, vecVelocity);
				set_member(pTarget, m_flVelocityModifier, velocityModifier);
			}
		}
	}

	new Float:frame = Float:get_entvar(pEntity, var_frame);

	frame++;
	//frame += Float:get_entvar(pEntity, var_framerate) * (time - get_ent_data_float(pEntity, "CSprite", "m_lastTime"));

	if (frame > get_ent_data_float(pEntity, "CSprite", "m_maxFrame"))
		frame = 0.0;

	set_entvar(pEntity, var_frame, frame);
	set_entvar(pEntity, var_nextthink, time + 0.1);

	set_ent_data_float(pEntity, "CSprite", "m_lastTime", time);
}
