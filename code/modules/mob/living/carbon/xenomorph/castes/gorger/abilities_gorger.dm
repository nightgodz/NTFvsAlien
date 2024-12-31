/datum/action/ability/activable/xeno/psydrain/free
	ability_cost = 0

// ***************************************
// *********** Drain blood
// ***************************************
/datum/action/ability/activable/xeno/drain
	name = "Drain"
	action_icon_state = "drain"
	action_icon = 'icons/Xeno/actions/gorger.dmi'
	desc = "Hold a marine for some time and drain their blood, while healing. You can't attack during this time and can be shot by the marine. When used on a dead human, you heal, or gain overheal, gradually and don't gain blood."
	use_state_flags = ABILITY_KEYBIND_USE_ABILITY
	cooldown_duration = 15 SECONDS
	ability_cost = 0
	target_flags = ABILITY_MOB_TARGET
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_DRAIN,
	)

/datum/action/ability/activable/xeno/drain/can_use_ability(atom/target, silent = FALSE, override_flags)
	. = ..()
	if(!ishuman(target) || issynth(target))
		if(!silent)
			to_chat(owner, span_xenowarning("We can't drain this!"))
		return FALSE

	var/mob/living/carbon/human/target_human = target
	if(!xeno_owner.Adjacent(target_human))
		if(!silent)
			to_chat(xeno_owner, span_notice("We need to be next to our meal."))
		return FALSE

	if(target_human.stat == DEAD)
		if(xeno_owner.do_actions)
			return FALSE
		return TRUE

	if(!.)
		return

	if(xeno_owner.plasma_stored >= xeno_owner.xeno_caste.plasma_max)
		if(!silent)
			to_chat(xeno_owner, span_xenowarning("No need, we feel sated for now..."))
		return FALSE

#define DO_DRAIN_ACTION(xeno_owner, target_human) \
	xeno_owner.do_attack_animation(target_human, ATTACK_EFFECT_REDSTAB);\
	xeno_owner.visible_message(target_human, span_danger("[xeno_owner] stabs its tail into [target_human]!"));\
	playsound(target_human, SFX_ALIEN_CLAW_FLESH, 25, TRUE);\
	target_human.emote("scream");\
	target_human.apply_damage(damage = 4, damagetype = BRUTE, def_zone = BODY_ZONE_HEAD, blocked = 0, sharp = TRUE, edge = FALSE, updating_health = TRUE);\
\
	var/drain_healing = GORGER_DRAIN_HEAL;\
	HEAL_XENO_DAMAGE(xeno_owner, drain_healing, TRUE);\
	adjustOverheal(xeno_owner, drain_healing);\
	xeno_owner.gain_plasma(xeno_owner.xeno_caste.drain_plasma_gain)

/datum/action/ability/activable/xeno/drain/use_ability(mob/living/carbon/human/target_human)
	if(target_human.stat == DEAD)
		var/overheal_gain = 0
		while((xeno_owner.health < xeno_owner.maxHealth || xeno_owner.overheal < xeno_owner.xeno_caste.overheal_max) &&do_after(xeno_owner, 2 SECONDS, NONE, target_human, BUSY_ICON_HOSTILE))
			overheal_gain = xeno_owner.heal_wounds(2.2)
			adjustOverheal(xeno_owner, overheal_gain)
			xeno_owner.adjust_sunder(-2.5)
		to_chat(xeno_owner, span_notice("We feel fully restored."))
		return
	xeno_owner.face_atom(target_human)
	xeno_owner.emote("roar")
	xeno_owner.AdjustImmobilized(0.5 SECONDS)
	ADD_TRAIT(xeno_owner, TRAIT_HANDS_BLOCKED, src)
	for(var/i = 0; i < GORGER_DRAIN_INSTANCES; i++)
		target_human.Immobilize(GORGER_DRAIN_DELAY)
		if(!do_after(xeno_owner, GORGER_DRAIN_DELAY, IGNORE_HELD_ITEM, target_human))
			break
		DO_DRAIN_ACTION(xeno_owner, target_human)

	REMOVE_TRAIT(xeno_owner, TRAIT_HANDS_BLOCKED, src)
	target_human.blur_eyes(1)
	add_cooldown()

#undef DO_DRAIN_ACTION

/datum/action/ability/activable/xeno/drain/ai_should_use(atom/target)
	return can_use_ability(target, TRUE)

// ***************************************
// *********** Transfusion
// ***************************************

/obj/effect/ebeam/transfusion
	name = "blood transfusion beam"

/datum/action/ability/activable/xeno/transfusion
	name = "Transfusion"
	action_icon_state = "transfusion"
	action_icon = 'icons/Xeno/actions/gorger.dmi'
	desc = "Restores some of the health of another xenomorph, or overheals, at the cost of blood."
	//When used on self, drains blood continuosly, slows you down and reduces damage taken, while restoring health over time.
	cooldown_duration = 2 SECONDS
	ability_cost = 20
	target_flags = ABILITY_MOB_TARGET
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_TRANSFUSION,
	)

	///Used to keep track of the target's previous health for extra_health_check()
	var/target_health

/datum/action/ability/activable/xeno/transfusion/can_use_ability(atom/target, silent = FALSE, override_flags) //it is set up to only return true on specific xeno or human targets
	. = ..()
	if(!.)
		return

	if(!isxeno(target))
		if(!silent)
			to_chat(owner, span_notice("We can only restore familiar biological lifeforms."))
		return FALSE

	var/mob/living/carbon/xenomorph/target_xeno = target

	if(owner.do_actions)
		return FALSE
	if(!line_of_sight(owner, target_xeno, 2) || get_dist(owner, target_xeno) > 2)
		if(!silent)
			to_chat(owner, span_notice("It is beyond our reach, we must be close and our way must be clear."))
		return FALSE
	if(target_xeno.stat == DEAD)
		if(!silent)
			to_chat(owner, span_notice("We can only help living sisters."))
		return FALSE
	target_health = target_xeno.health
	var/datum/beam/transfuse_beam = owner.beam(target_xeno, icon_state= "lichbeam", beam_type = /obj/effect/ebeam/essence_link)
	transfuse_beam.visuals.alpha = 127
	if(!do_after(owner, 1 SECONDS, IGNORE_TARGET_LOC_CHANGE, target_xeno, BUSY_ICON_FRIENDLY, BUSY_ICON_MEDICAL, extra_checks = CALLBACK(src, PROC_REF(extra_health_check), target_xeno)))
		QDEL_NULL(transfuse_beam)
		return FALSE
	QDEL_NULL(transfuse_beam)
	return TRUE

///An extra check for the do_mob in can_use_ability. If the target isn't immobile and has lost health, the ability is cancelled. The ability is also cancelled if the target is knocked into crit DURING the do_mob.
/datum/action/ability/activable/xeno/transfusion/proc/extra_health_check(mob/living/target)
	if((target.health < target_health && !HAS_TRAIT(target, TRAIT_IMMOBILE)) || (target.InCritical() && target_health > target.get_crit_threshold()))
		return FALSE
	target_health = target.health
	return TRUE

/datum/action/ability/activable/xeno/transfusion/use_ability(atom/target)
	var/mob/living/carbon/xenomorph/target_xeno = target
	var/heal_amount = target_xeno.maxHealth * GORGER_TRANSFUSION_HEAL
	HEAL_XENO_DAMAGE(target_xeno, heal_amount, FALSE)
	if(owner.client)
		var/datum/personal_statistics/personal_statistics = GLOB.personal_statistics_list[owner.ckey]
		personal_statistics.heals++
	adjustOverheal(target_xeno, heal_amount)
	new /obj/effect/temp_visual/healing(get_turf(target_xeno))
	if(target_xeno.overheal)
		target_xeno.balloon_alert(xeno_owner, "Overheal: [target_xeno.overheal]/[target_xeno.xeno_caste.overheal_max]")
	add_cooldown()
	succeed_activate()

/datum/action/ability/activable/xeno/transfusion/ai_should_use(atom/target)
	// no healing non-xeno
	if(!isxeno(target))
		return FALSE
	var/mob/living/carbon/xenomorph/target_xeno = target
	if(target_xeno.get_xeno_hivenumber() != owner.get_xeno_hivenumber())
		return FALSE
	// no overhealing
	if(target_xeno.health > target_xeno.maxHealth * (1 - GORGER_TRANSFUSION_HEAL))
		return FALSE
	return can_use_ability(target, TRUE)

// ***************************************
// *********** oppose
// ***************************************

/particles/bulwark_aoe/oppose_aoe
	color = LIGHT_COLOR_BLOOD_MAGIC
	fade = 3 SECONDS

/datum/action/ability/activable/xeno/oppose
	name = "Oppose"
	action_icon_state = "rejuvenation"
	action_icon = 'icons/Xeno/actions/gorger.dmi'
	desc = "Violently suffuse the ground with stored blood. A marine on your tile is staggered and injured, ajacent marines are staggered, and any nearby xenos are healed, including you."
	cooldown_duration = 30 SECONDS
	ability_cost = GORGER_OPPOSE_COST
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_OPPOSE,
	)
	keybind_flags = ABILITY_KEYBIND_USE_ABILITY

/datum/action/ability/activable/xeno/oppose/use_ability(atom/A)
	. = ..()
	add_cooldown()
	succeed_activate()

	playsound(xeno_owner.loc, 'sound/effects/bang.ogg', 25, 0)
	xeno_owner.visible_message(span_xenodanger("[xeno_owner] smashes her fists into the ground!"), \
	span_xenodanger("We smash our fists into the ground!"))

	xeno_owner.create_stomp() //Adds the visual effects. Wom wom wom
	new /obj/effect/temp_visual/oppose_shatter(get_turf(xeno_owner)) //shatter displays stagger range

	var/obj/effect/abstract/particle_holder/aoe_particles = new(owner.loc, /particles/bulwark_aoe/oppose_aoe) //particles display heal range
	aoe_particles.particles.position = generator(GEN_SQUARE, 0, 16 + 3*32, LINEAR_RAND)
	addtimer(CALLBACK(src, PROC_REF(stop_particles), aoe_particles), 0.5 SECONDS)

	var/list/oppose_range = range(3)
	for(var/mob/living/M in oppose_range)
		if(M.stat == DEAD)
			continue
		var/distance = get_dist(M, xeno_owner)
		if(xeno_owner.issamexenohive(M))  //Xenos in range will be healed and overhealed, including you.
			var/mob/living/carbon/xenomorph/target_xeno = M
			var/heal_amount = M.maxHealth * GORGER_OPPOSE_HEAL
			HEAL_XENO_DAMAGE(target_xeno, heal_amount, FALSE)
			adjustOverheal(target_xeno, heal_amount)
			new /obj/effect/temp_visual/healing(get_turf(target_xeno))
			if(owner.client)
				var/datum/personal_statistics/personal_statistics = GLOB.personal_statistics_list[owner.ckey]
				personal_statistics.heals++
		else if(distance == 0) //if we're right on top of them, they take actual damage
			M.take_overall_damage(20, BRUTE, MELEE, updating_health = TRUE, max_limbs = 3)
			to_chat(M, span_userdanger("[xeno_owner] slams her fists into you, crushing you to the ground!"))
			M.adjust_stagger(2 SECONDS)
			M.adjust_slowdown(3)
			shake_camera(M, 3, 3)
		else if(distance <= 1) //marines will only be staggerslowed if they're one tile away from you
			shake_camera(M, 2, 2)
			to_chat(M, span_userdanger("Blood shatters the ground around you!"))
			M.adjust_stagger(2 SECONDS)
			M.adjust_slowdown(3)

///Stops particle spawning, then gives existing particles time to fade out before deleting them.
/datum/action/ability/activable/xeno/oppose/proc/stop_particles(obj/effect/abstract/particle_holder/aoe_particles)
	aoe_particles.particles.spawning = 0
	QDEL_IN(aoe_particles, 3 SECONDS)

/datum/action/ability/activable/xeno/oppose/ai_should_use(atom/target)
	return FALSE

// ***************************************
// *********** Psychic Link
// ***************************************
/datum/action/ability/activable/xeno/psychic_link
	name = "Psychic Link"
	action_icon_state = "psychic_link"
	action_icon = 'icons/Xeno/actions/gorger.dmi'
	desc = "Link to a xenomorph and take some damage in their place. Unrest to cancel."
	cooldown_duration = 50 SECONDS
	ability_cost = 0
	target_flags = ABILITY_MOB_TARGET
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_PSYCHIC_LINK,
	)
	///Timer for activating the link
	var/apply_psychic_link_timer
	///Overlay applied on the target xeno while linking
	var/datum/progressicon/target_overlay

/datum/action/ability/activable/xeno/psychic_link/can_use_ability(atom/target, silent = FALSE, override_flags)
	. = ..()
	if(!.)
		return
	if(apply_psychic_link_timer)
		if(!silent)
			owner.balloon_alert(owner, "cancelled")
		link_cleanup()
		return FALSE
	if(owner.do_actions)
		return FALSE
	if(!isxeno(target))
		if(!silent)
			to_chat(owner, span_notice("We can only link to familiar biological lifeforms."))
		return FALSE
	if(xeno_owner.health <= xeno_owner.maxHealth * GORGER_PSYCHIC_LINK_MIN_HEALTH)
		if(!silent)
			to_chat(owner, span_notice("You are too hurt to link."))
		return FALSE
	if(!line_of_sight(owner, target, GORGER_PSYCHIC_LINK_RANGE))
		if(!silent)
			to_chat(owner, span_notice("It is beyond our reach, we must be close and our way must be clear."))
		return FALSE
	if(HAS_TRAIT(owner, TRAIT_PSY_LINKED))
		if(!silent)
			to_chat(owner, span_notice("You are already linked to a xenomorph."))
		return FALSE
	if(HAS_TRAIT(target, TRAIT_PSY_LINKED))
		if(!silent)
			to_chat(owner, span_notice("[target] is already linked to a xenomorph."))
		return FALSE
	return TRUE

/datum/action/ability/activable/xeno/psychic_link/use_ability(atom/target)
	apply_psychic_link_timer = addtimer(CALLBACK(src, PROC_REF(apply_psychic_link), target), GORGER_PSYCHIC_LINK_CHANNEL, TIMER_UNIQUE|TIMER_STOPPABLE)
	target_overlay = new (target, BUSY_ICON_MEDICAL)
	owner.balloon_alert(owner, "linking...")

///Activates the link
/datum/action/ability/activable/xeno/psychic_link/proc/apply_psychic_link(atom/target)
	link_cleanup()
	if(HAS_TRAIT(owner, TRAIT_PSY_LINKED) || HAS_TRAIT(target, TRAIT_PSY_LINKED))
		return fail_activate()

	var/psychic_link = xeno_owner.apply_status_effect(STATUS_EFFECT_XENO_PSYCHIC_LINK, -1, target, GORGER_PSYCHIC_LINK_RANGE, GORGER_PSYCHIC_LINK_REDIRECT, xeno_owner.maxHealth * GORGER_PSYCHIC_LINK_MIN_HEALTH, TRUE)
	RegisterSignal(psychic_link, COMSIG_XENO_PSYCHIC_LINK_REMOVED, PROC_REF(status_removed))
	target.balloon_alert(xeno_owner, "link successul")
	xeno_owner.balloon_alert(target, "linked to [xeno_owner]")
	if(!xeno_owner.resting)
		xeno_owner.set_resting(TRUE, TRUE)
	RegisterSignal(xeno_owner, COMSIG_XENOMORPH_UNREST, PROC_REF(cancel_psychic_link))
	succeed_activate()

///Removes the status effect on unrest
/datum/action/ability/activable/xeno/psychic_link/proc/cancel_psychic_link(datum/source)
	SIGNAL_HANDLER
	xeno_owner.remove_status_effect(STATUS_EFFECT_XENO_PSYCHIC_LINK)

///Cancels the status effect
/datum/action/ability/activable/xeno/psychic_link/proc/status_removed(datum/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, COMSIG_XENO_PSYCHIC_LINK_REMOVED)
	UnregisterSignal(owner, COMSIG_XENOMORPH_UNREST)
	add_cooldown()

///Clears up things used for the linking
/datum/action/ability/activable/xeno/psychic_link/proc/link_cleanup()
	QDEL_NULL(target_overlay)
	deltimer(apply_psychic_link_timer)
	apply_psychic_link_timer = null


/datum/action/ability/activable/xeno/psychic_link/ai_should_use(atom/target)
	return FALSE

// ***************************************
// *********** Carnage
// ***************************************
/datum/action/ability/activable/xeno/carnage
	name = "Carnage"
	action_icon_state = "carnage"
	action_icon = 'icons/Xeno/actions/gorger.dmi'
	desc = "Enter a state of thirst, gaining movement and healing on your next attack, scaling with missing blood. If your blood is below a certain %, you also knockdown your victim and drain some blood, during which you can't move."
	cooldown_duration = 15 SECONDS
	ability_cost = 0
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_CARNAGE,
	)
	keybind_flags = ABILITY_KEYBIND_USE_ABILITY

/datum/action/ability/activable/xeno/carnage/use_ability(atom/A)
	. = ..()
	xeno_owner.apply_status_effect(STATUS_EFFECT_XENO_CARNAGE, 10 SECONDS, xeno_owner.xeno_caste.carnage_plasma_gain, xeno_owner.maxHealth * GORGER_CARNAGE_HEAL, GORGER_CARNAGE_MOVEMENT)
	add_cooldown()

/datum/action/ability/activable/xeno/carnage/ai_should_use(atom/target)
	if(!iscarbon(target))
		return FALSE
	if(xeno_owner.plasma_stored > xeno_owner.xeno_caste.plasma_max * 0.8 && xeno_owner.health > xeno_owner.maxHealth * 0.9)
		return FALSE
	// nothing gained by slashing allies
	if(target.get_xeno_hivenumber() == xeno_owner.get_xeno_hivenumber())
		return FALSE
	return can_use_ability(target, TRUE)

// ***************************************
// *********** Feast
// ***************************************
#define FEAST_MISCLICK_CD "feast_misclick"
/datum/action/ability/activable/xeno/feast
	name = "Feast"
	action_icon_state = "feast"
	action_icon = 'icons/Xeno/actions/gorger.dmi'
	desc = "Enter a state of rejuvenation. During this time you use a small amount of blood and heal. You can cancel this early."
	cooldown_duration = 180 SECONDS
	ability_cost = 0
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_FEAST,
	)
	keybind_flags = ABILITY_KEYBIND_USE_ABILITY
	use_state_flags = ABILITY_USE_STAGGERED

/datum/action/ability/activable/xeno/feast/can_use_ability(atom/target, silent, override_flags)
	. = ..()
	if(TIMER_COOLDOWN_CHECK(xeno_owner, FEAST_MISCLICK_CD))
		return FALSE
	if(xeno_owner.has_status_effect(STATUS_EFFECT_XENO_FEAST))
		return TRUE
	if(xeno_owner.plasma_stored < xeno_owner.xeno_caste.feast_plasma_drain * 10)
		if(!silent)
			to_chat(xeno_owner, span_notice("Not enough to begin a feast. We need [xeno_owner.xeno_caste.feast_plasma_drain * 10] blood."))
		return FALSE

/datum/action/ability/activable/xeno/feast/use_ability(atom/A)
	. = ..()
	if(xeno_owner.has_status_effect(STATUS_EFFECT_XENO_FEAST))
		to_chat(xeno_owner, span_notice("We decide to end our feast early..."))
		xeno_owner.remove_status_effect(STATUS_EFFECT_XENO_FEAST)
		return

	xeno_owner.emote("roar")
	xeno_owner.visible_message(xeno_owner, span_notice("[xeno_owner] begins to overflow with vitality!"))
	xeno_owner.apply_status_effect(STATUS_EFFECT_XENO_FEAST, GORGER_FEAST_DURATION, xeno_owner.xeno_caste.feast_plasma_drain)
	TIMER_COOLDOWN_START(src, FEAST_MISCLICK_CD, 2 SECONDS)
	add_cooldown()

/datum/action/ability/activable/xeno/feast/ai_should_use(atom/target)
	// cancel the buff when at full health to conserve plasma, otherwise don't cancel
	if(xeno_owner.has_status_effect(STATUS_EFFECT_XENO_FEAST))
		return xeno_owner.health == xeno_owner.maxHealth
	// small damage has more efficient alternatives to be healed with
	if(xeno_owner.health > xeno_owner.maxHealth * 0.7)
		return FALSE
	// should use the ability when there is enough resource for the buff to tick a moderate amount of times
	if(xeno_owner.plasma_stored / xeno_owner.xeno_caste.feast_plasma_drain < 7)
		return FALSE
	return can_use_ability(target, TRUE)

#undef FEAST_MISCLICK_CD
