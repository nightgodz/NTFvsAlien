// Snow, wood, sandbags, metal, plasteel

/obj/structure/barricade
	icon = 'icons/Marine/barricades.dmi'
	climbable = TRUE
	anchored = TRUE
	density = 1
	throwpass = TRUE //You can throw objects over this, despite its density.
	layer = BELOW_OBJ_LAYER
	climb_delay = 20 //Leaping a barricade is universally much faster than clumsily climbing on a table or rack
	var/stack_type //The type of stack the barricade dropped when disassembled if any.
	var/stack_amount = 5 //The amount of stack dropped when disassembled at full health
	var/destroyed_stack_amount //to specify a non-zero amount of stack to drop when destroyed
	var/health = 100 //Pretty tough. Changes sprites at 300 and 150
	var/maxhealth = 100 //Basic code functions
	var/crusher_resistant = TRUE //Whether a crusher can ram through it.
	var/barricade_resistance = 5 //How much force an item needs to even damage it at all.
	var/barricade_hitsound

	var/barricade_type = "barricade" //"metal", "plasteel", etc.
	var/can_change_dmg_state = 1
	var/damage_state = 0
	var/closed = 0
	var/can_wire = 0
	var/is_wired = 0
	var/image/wired_overlay

	New()
		..()
		spawn(0)
			update_icon()

/obj/structure/barricade/examine(mob/user)
	..()

	if(is_wired)
		user << "<span class='info'>There is a length of wire strewn across the top of this barricade.</span>"
	switch(damage_state)
		if(0) user << "<span class='info'>It appears to be in good shape.</span>"
		if(1) user << "<span class='warning'>It's slightly damaged, but still very functional.</span>"
		if(2) user << "<span class='warning'>It's quite beat up, but it's holding together.</span>"
		if(3) user << "<span class='warning'>It's crumbling apart, just a few more blows will tear it apart.</span>"


/obj/structure/barricade/Bumped(atom/A)
	..()

	if(istype(A, /mob/living/carbon/Xenomorph/Crusher))

		var/mob/living/carbon/Xenomorph/Crusher/C = A

		if(C.momentum < 20)
			return

		if(crusher_resistant)
			health -= 100
			update_health()

		else if(!C.stat)
			visible_message("<span class='danger'>[C] steamrolls through [src]!</span>")
			destroy()

/obj/structure/barricade/CheckExit(atom/movable/O, turf/target)
	if(closed)
		return 1

	if(O && O.throwing)
		if(is_wired && iscarbon(O)) //Leaping mob against barbed wire fails
			var/mob/living/carbon/C = O
			C.visible_message("<span class='danger'>The barbed wire slices into [C]!</span>",
			"<span class='danger'>The barbed wire slices into you!</span>")
			C.apply_damage(10)
			C.KnockDown(2) //Leaping into barbed wire is VERY bad
			return 0
		return 1

	if(((flags_atom & ON_BORDER) && get_dir(loc, target) == dir)) //Barbed wires blocks movement
		return 0
	else
		return 1

/obj/structure/barricade/CanPass(atom/movable/mover, turf/target, height = 0, air_group = 0)
	if(air_group || (height == 0)) return 1 //Barricades are never air-proof
	if(closed)
		return 1

	if(mover && mover.throwing)
		if(is_wired && iscarbon(mover)) //Leaping mob against barbed wire fails
			var/mob/living/carbon/C = mover
			C.visible_message("<span class='danger'>The barbed wire slices into [C]!</span>",
			"<span class='danger'>The barbed wire slices into you!</span>")
			C.apply_damage(10)
			C.KnockDown(2) //Leaping into barbed wire is VERY bad
			return 0
		return 1

	var/obj/structure/S = locate(/obj/structure) in get_turf(mover)
	if(S && S.climbable && !(S.flags_atom & ON_BORDER) && climbable && isliving(mover)) //Climbable objects allow you to universally climb over others
		return 1

	if(!(flags_atom & ON_BORDER) || get_dir(loc, target) == dir)
		return 0
	else
		return 1


/obj/structure/barricade/attack_robot(mob/user as mob)
	return attack_hand(user)


/obj/structure/barricade/attackby(obj/item/W as obj, mob/user)
	if(istype(W, /obj/item/zombie_claws))
		user.visible_message("<span class='danger'>The zombie smashed at the [src.barricade_type] barricade!</span>",
		"<span class='danger'>You smack the [src.barricade_type] barricade!</span>")
		if(barricade_hitsound)
			playsound(src, barricade_hitsound, 25, 1)
		hit_barricade(W)
		return

	if(istype(W, /obj/item/stack/barbed_wire))
		var/obj/item/stack/barbed_wire/B = W


		if(can_wire)
			user.visible_message("<span class='notice'>[user] starts setting up [W.name] on [src].</span>",
			"<span class='notice'>You start setting up [W.name] on [src].</span>")
			if(do_after(user, 20, TRUE, 5, BUSY_ICON_CLOCK) && can_wire)
				user.visible_message("<span class='notice'>[user] sets up [W.name] on [src].</span>",
				"<span class='notice'>You set up [W.name] on [src].</span>")
				if(!closed)
					wired_overlay = image('icons/Marine/barricades.dmi', icon_state = "[src.barricade_type]_wire")
				else
					wired_overlay = image('icons/Marine/barricades.dmi', icon_state = "[src.barricade_type]_closed_wire")
				B.use(1)
				overlays += wired_overlay
				maxhealth += 50
				health += 50
				update_health()
				can_wire = 0
				is_wired = 1
				climbable = FALSE
		return

	if(W.force > barricade_resistance)
		..()
		if(barricade_hitsound)
			playsound(src, barricade_hitsound, 25, 1)
		hit_barricade(W)

/obj/structure/barricade/destroy(deconstruct)
	if(deconstruct && is_wired)
		new /obj/item/stack/barbed_wire(loc)
	if(stack_type)
		var/stack_amt
		if(!deconstruct && destroyed_stack_amount) stack_amt = destroyed_stack_amount
		else stack_amt = round(stack_amount * (health/maxhealth)) //Get an amount of sheets back equivalent to remaining health. Obviously, fully destroyed means 0

		if(stack_amt) new stack_type (loc, stack_amt)
	cdel(src)

/obj/structure/barricade/ex_act(severity)
	switch(severity)
		if(1.0)
			visible_message("<span class='danger'>[src] is blown apart!</span>")
			cdel(src)
			return
		if(2.0)
			health -= rand(33, 66)
		if(3.0)
			health -= rand(10, 33)
	update_health()

/obj/structure/barricade/update_icon()
	if(!closed)
		if(can_change_dmg_state)
			icon_state = "[barricade_type]_[damage_state]"
		else
			icon_state = "[barricade_type]"
		if(flags_atom & ON_BORDER)
			switch(dir)
				if(SOUTH) layer = ABOVE_MOB_LAYER
				if(NORTH) layer = initial(layer) - 0.01
				else layer = initial(layer)
	else
		if(can_change_dmg_state)
			icon_state = "[barricade_type]_closed_[damage_state]"
		else
			icon_state = "[barricade_type]_closed"
		if(flags_atom & ON_BORDER)
			layer = OBJ_LAYER

/obj/structure/barricade/proc/update_overlay()
	if(!is_wired)
		return

	overlays -= wired_overlay
	if(!closed)
		wired_overlay = image('icons/Marine/barricades.dmi', icon_state = "[src.barricade_type]_wire", dir = src.dir, pixel_y = src.pixel_y)
	else
		wired_overlay = image('icons/Marine/barricades.dmi', icon_state = "[src.barricade_type]_closed_wire", dir = src.dir)
	overlays += wired_overlay

/obj/structure/barricade/proc/hit_barricade(obj/item/I)
	if(istype(I, /obj/item/zombie_claws))
		health -= I.force * 0.5
	health -= I.force * 0.5
	update_health()

/obj/structure/barricade/proc/update_health(nomessage)
	health = Clamp(health, 0, maxhealth)

	if(!health)
		if(!nomessage)
			visible_message("<span class='danger'>[src] falls apart!</span>")
		destroy()
		return

	update_damage_state()
	update_icon()

/obj/structure/barricade/proc/update_damage_state()
	var/health_percent = round(health/maxhealth * 100)
	switch(health_percent)
		if(0 to 25) damage_state = 3
		if(25 to 50) damage_state = 2
		if(50 to 75) damage_state = 1
		if(75 to INFINITY) damage_state = 0


/obj/structure/barricade/proc/acid_smoke_damage(var/obj/effect/particle_effect/smoke/S)
	health -= 10
	update_health()

/*----------------------*/
// SNOW
/*----------------------*/

/obj/structure/barricade/snow
	name = "snow barricade"
	desc = "A mound of snow shaped into a sloped wall. Statistically better than thin air as cover."
	icon_state = "snow_0"
	barricade_type = "snow"
	health = 75 //Actual health depends on snow layer
	maxhealth = 75
	can_wire = 0

//Item Attack
/obj/structure/barricade/snow/attackby(obj/item/W as obj, mob/user as mob)
	//Removing the barricades
	if(istype(W, /obj/item/snow_shovel))
		var/obj/item/snow_shovel/S = W
		if(S.mode == 2)
			if(S.working)
				user  << "\red You are already shoveling!"
				return
			user.visible_message("[user.name] starts clearing out \the [src].","You start removing \the [src].")
			S.working = 1
			if(!do_after(user, 100, TRUE, 5, BUSY_ICON_CLOCK))
				user.visible_message("\red \The [user] decides not to clear out \the [src] anymore.")
				S.working = 0
				return
			user.visible_message("\blue \The [user] clears out \the [src].")
			S.working = 0
			cdel(src)
		return

	. = ..()

/obj/structure/barricade/snow/hit_barricade(obj/item/I)
	switch(I.damtype)
		if("fire")
			health -= I.force * 0.6
		if("brute")
			health -= I.force * 0.3

	update_health()
	update_icon()
	return

/obj/structure/barricade/snow/bullet_act(var/obj/item/projectile/P)
	bullet_ping(P)
	health -= round(P.damage/2) //Not that durable.

	if (istype(P.ammo, /datum/ammo/xeno/boiler_gas))
		health -= 50

	update_health()
	return 1

/*----------------------*/
// WOOD
/*----------------------*/

/obj/structure/barricade/wooden
	name = "wooden barricade"
	desc = "A wall made out of wooden planks nailed together. Not very sturdy, but can provide some concealment."
	icon_state = "wooden"
	flags_atom = ON_BORDER
	health = 100
	maxhealth = 100
	layer = OBJ_LAYER
	climbable = FALSE
	throwpass = FALSE
	stack_type = /obj/item/stack/sheet/wood
	stack_amount = 5
	destroyed_stack_amount = 3
	barricade_hitsound = "sound/effects/woodhit.ogg"
	can_change_dmg_state = 0
	barricade_type = "wooden"
	can_wire = 0

/obj/structure/barricade/wooden/attackby(obj/item/W as obj, mob/user as mob)
	if(istype(W, /obj/item/stack/sheet/wood))
		var/obj/item/stack/sheet/wood/D = W
		if(health < maxhealth)
			if(D.get_amount() < 1)
				user << "<span class='warning'>You need one plank of wood to repair [src].</span>"
				return
			visible_message("<span class='notice'>[user] begins to repair [src].</span>")
			if(do_after(user,20, TRUE, 5, BUSY_ICON_CLOCK) && health < maxhealth)
				if (D.use(1))
					health = maxhealth
					visible_message("<span class='notice'>[user] repairs [src].</span>")
		return
	. = ..()

/obj/structure/barricade/wooden/hit_barricade(obj/item/I)
	switch(I.damtype)
		if("fire")
			health -= I.force * 1.5
		if("brute")
			health -= I.force * 0.75
	update_health()

/obj/structure/barricade/wooden/bullet_act(var/obj/item/projectile/P)
	bullet_ping(P)
	health -= round(P.damage/2) //Not that durable.

	if(istype(P.ammo, /datum/ammo/xeno/boiler_gas))
		health -= 50

	update_health()
	return 1

/*----------------------*/
// METAL
/*----------------------*/

/obj/structure/barricade/metal
	name = "metal barricade"
	desc = "A sturdy and easily assembled barricade made of metal plates, often used for quick fortifications. Use a blowtorch to repair."
	icon_state = "metal_0"
	flags_atom = ON_BORDER
	health = 200
	maxhealth = 200
	crusher_resistant = TRUE
	barricade_resistance = 10
	stack_type = /obj/item/stack/sheet/metal
	stack_amount = 4
	destroyed_stack_amount = 2
	barricade_hitsound = "sound/effects/metalhit.ogg"
	barricade_type = "metal"
	can_wire = 1

	var/build_state = 2 //2 is fully secured, 1 is after screw, 0 is after wrench. Crowbar disassembles
	var/tool_cooldown = 0 //Delay to apply tools to prevent spamming
	var/busy = 0 //Standard busy check

/obj/structure/barricade/metal/examine(mob/user)
	..()
	switch(build_state)
		if(2)
			user << "<span class='info'>The protection panel is still tighly screwed in place.</span>"
		if(1)
			user << "<span class='info'>The protection panel has been removed, you can see the anchor bolts.</span>"
		if(0)
			user << "<span class='info'>The protection panel has been removed and the anchor bolts loosened. It's ready to be taken apart.</span>"

/obj/structure/barricade/metal/attackby(obj/item/W, mob/user)

	if(iswelder(W))
		if(busy || tool_cooldown > world.time)
			return
		tool_cooldown = world.time + 10
		if(user.mind && user.mind.skills_list && user.mind.skills_list["engineer"] < SKILL_ENGINEER_METAL)
			user << "<span class='warning'>You're not trained to repair [src]...</span>"
			return
		var/obj/item/weapon/weldingtool/WT = W
		if(health <= maxhealth * 0.3)
			user << "<span class='warning'>[src] has sustained too much structural damage to be repaired.</span>"
			return

		if(health == maxhealth)
			user << "<span class='warning'>[src] doesn't need repairs.</span>"
			return

		if(WT.remove_fuel(0, user))
			user.visible_message("<span class='notice'>[user] begins repairing damage to [src].</span>",
			"<span class='notice'>You begin repairing the damage to [src].</span>")
			playsound(src.loc, 'sound/items/Welder2.ogg', 25, 1)
			busy = 1
			if(do_after(user, 50, TRUE, 5, BUSY_ICON_CLOCK))
				busy = 0
				user.visible_message("<span class='notice'>[user] repairs some damage on [src].</span>",
				"<span class='notice'>You repair [src].</span>")
				health += 150
				update_health()
				playsound(src.loc, 'sound/items/Welder2.ogg', 25, 1)
			else busy = 0
		return

	switch(build_state)
		if(2) //Fully constructed step. Use screwdriver to remove the protection panels to reveal the bolts
			if(isscrewdriver(W))
				if(busy || tool_cooldown > world.time)
					return
				tool_cooldown = world.time + 10
				if(user.mind && user.mind.skills_list && user.mind.skills_list["engineer"] < SKILL_ENGINEER_METAL)
					user << "<span class='warning'>You are not trained to assemble [src]...</span>"
					return
				user.visible_message("<span class='notice'>[user] removes [src]'s protection panel.</span>",
				"<span class='notice'>You remove [src]'s protection panels, exposing the anchor bolts.</span>")
				playsound(src.loc, 'sound/items/Screwdriver.ogg', 25, 1)
				build_state = 1
				return
		if(1) //Protection panel removed step. Screwdriver to put the panel back, wrench to unsecure the anchor bolts
			if(isscrewdriver(W))
				if(busy || tool_cooldown > world.time)
					return
				tool_cooldown = world.time + 10
				if(user.mind && user.mind.skills_list && user.mind.skills_list["engineer"] < SKILL_ENGINEER_METAL)
					user << "<span class='warning'>You are not trained to assemble [src]...</span>"
					return
				user.visible_message("<span class='notice'>[user] set [src]'s protection panel back.</span>",
				"<span class='notice'>You set [src]'s protection panel back.</span>")
				playsound(src.loc, 'sound/items/Screwdriver.ogg', 25, 1)
				build_state = 2
				return
			if(iswrench(W))
				if(busy || tool_cooldown > world.time)
					return
				tool_cooldown = world.time + 10
				if(user.mind && user.mind.skills_list && user.mind.skills_list["engineer"] < SKILL_ENGINEER_METAL)
					user << "<span class='warning'>You are not trained to assemble [src]...</span>"
					return
				user.visible_message("<span class='notice'>[user] loosens [src]'s anchor bolts.</span>",
				"<span class='notice'>You loosen [src]'s anchor bolts.</span>")
				playsound(src.loc, 'sound/items/Ratchet.ogg', 25, 1)
				anchored = FALSE
				build_state = 0
				return
		if(0) //Anchor bolts loosened step. Apply crowbar to unseat the panel and take apart the whole thing. Apply wrench to resecure anchor bolts
			if(iswrench(W))
				if(busy || tool_cooldown > world.time)
					return
				tool_cooldown = world.time + 10


				if(user.mind && user.mind.skills_list && user.mind.skills_list["engineer"] < SKILL_ENGINEER_METAL)
					user << "<span class='warning'>You are not trained to assemble [src]...</span>"
					return
				for(var/obj/structure/barricade/B in loc)
					if(B != src && (B.dir == dir || !(B.flags_atom & ON_BORDER)))
						user << "<span class='warning'>There's already a barricade here.</span>"
						return
				user.visible_message("<span class='notice'>[user] secures [src]'s anchor bolts.</span>",
				"<span class='notice'>You secure [src]'s anchor bolts.</span>")
				playsound(src.loc, 'sound/items/Ratchet.ogg', 25, 1)
				build_state = 1
				anchored = TRUE
				return
			if(iscrowbar(W))
				if(busy || tool_cooldown > world.time)
					return
				tool_cooldown = world.time + 10
				if(user.mind && user.mind.skills_list && user.mind.skills_list["engineer"] < SKILL_ENGINEER_METAL)
					user << "<span class='warning'>You are not trained to assemble [src]...</span>"
					return
				user.visible_message("<span class='notice'>[user] starts unseating [src]'s panels.</span>",
				"<span class='notice'>You start unseating [src]'s panels.</span>")
				playsound(src.loc, 'sound/items/Crowbar.ogg', 25, 1)
				busy = 1
				if(do_after(user, 50, TRUE, 5, BUSY_ICON_CLOCK))
					busy = 0
					user.visible_message("<span class='notice'>[user] takes [src]'s panels apart.</span>",
					"<span class='notice'>You take [src]'s panels apart.</span>")
					playsound(loc, 'sound/items/Deconstruct.ogg', 25, 1)
					destroy(TRUE) //Note : Handles deconstruction too !
				else busy = 0
				return

	. = ..()

/obj/structure/barricade/metal/ex_act(severity)
	switch(severity)
		if(1)
			health -= rand(400, 600)
		if(2)
			health -= rand(150, 350)
		if(3)
			health -= rand(50, 100)

	update_health()

/obj/structure/barricade/metal/bullet_act(obj/item/projectile/P)
	bullet_ping(P)
	health -= round(P.damage/10)

	if(istype(P.ammo, /datum/ammo/xeno/boiler_gas))
		health -= 50

	update_health()
	return 1

/*----------------------*/
// PLASTEEL
/*----------------------*/

/obj/structure/barricade/plasteel
	name = "plasteel barricade"
	desc = "A very sturdy barricade made out of plasteel panels, the pinnacle of strongpoints. Use a blowtorch to repair. Can be flipped down to create a path."
	icon_state = "plasteel_closed_0"
	flags_atom = ON_BORDER
	health = 600
	maxhealth = 600
	crusher_resistant = TRUE
	barricade_resistance = 20
	stack_type = /obj/item/stack/sheet/plasteel
	stack_amount = 5
	destroyed_stack_amount = 2
	barricade_hitsound = "sound/effects/metalhit.ogg"
	barricade_type = "plasteel"
	density = 0
	closed = 1
	can_wire = 1

	var/build_state = 2 //2 is fully secured, 1 is after screw, 0 is after wrench. Crowbar disassembles
	var/tool_cooldown = 0 //Delay to apply tools to prevent spamming
	var/busy = 0 //Standard busy check

/obj/structure/barricade/plasteel/examine(mob/user)
	..()

	switch(build_state)
		if(2)
			user << "<span class='info'>The protection panel is still tighly screwed in place.</span>"
		if(1)
			user << "<span class='info'>The protection panel has been removed, you can see the anchor bolts.</span>"
		if(0)
			user << "<span class='info'>The protection panel has been removed and the anchor bolts loosened. It's ready to be taken apart.</span>"

/obj/structure/barricade/plasteel/attackby(obj/item/W, mob/user)

	if(iswelder(W))
		if(busy || tool_cooldown > world.time)
			return
		tool_cooldown = world.time + 10
		if(user.mind && user.mind.skills_list && user.mind.skills_list["engineer"] < SKILL_ENGINEER_PLASTEEL)
			user << "<span class='warning'>You're not trained to repair [src]...</span>"
			return
		var/obj/item/weapon/weldingtool/WT = W
		if(health <= maxhealth * 0.3)
			user << "<span class='warning'>[src] has sustained too much structural damage to be repaired.</span>"
			return

		if(health == maxhealth)
			user << "<span class='warning'>[src] doesn't need repairs.</span>"
			return

		if(WT.remove_fuel(0, user))
			user.visible_message("<span class='notice'>[user] begins repairing damage to [src].</span>",
			"<span class='notice'>You begin repairing the damage to [src].</span>")
			playsound(src.loc, 'sound/items/Welder2.ogg', 25, 1)
			busy = 1
			if(do_after(user, 50, TRUE, 5, BUSY_ICON_CLOCK))
				busy = 0
				user.visible_message("<span class='notice'>[user] repairs some damage on [src].</span>",
				"<span class='notice'>You repair [src].</span>")
				health += 150
				update_health()
				playsound(src.loc, 'sound/items/Welder2.ogg', 25, 1)
			else busy = 0
		return

	switch(build_state)
		if(2) //Fully constructed step. Use screwdriver to remove the protection panels to reveal the bolts
			if(isscrewdriver(W))
				if(busy || tool_cooldown > world.time)
					return
				tool_cooldown = world.time + 10
				if(user.mind && user.mind.skills_list && user.mind.skills_list["engineer"] < SKILL_ENGINEER_PLASTEEL)
					user << "<span class='warning'>You are not trained to assemble [src]...</span>"
					return

				for(var/obj/structure/barricade/B in loc)
					if(B != src && (B.dir == dir || !(B.flags_atom & ON_BORDER)))
						user << "<span class='warning'>There's already a barricade here.</span>"
						return
				user.visible_message("<span class='notice'>[user] removes [src]'s protection panel.</span>",

				"<span class='notice'>You remove [src]'s protection panels, exposing the anchor bolts.</span>")
				playsound(src.loc, 'sound/items/Screwdriver.ogg', 25, 1)
				build_state = 1
				return

		if(1) //Protection panel removed step. Screwdriver to put the panel back, wrench to unsecure the anchor bolts
			if(isscrewdriver(W))
				if(busy || tool_cooldown > world.time)
					return
				tool_cooldown = world.time + 10
				if(user.mind && user.mind.skills_list && user.mind.skills_list["engineer"] < SKILL_ENGINEER_PLASTEEL)
					user << "<span class='warning'>You are not trained to assemble [src]...</span>"
					return
				user.visible_message("<span class='notice'>[user] set [src]'s protection panel back.</span>",
				"<span class='notice'>You set [src]'s protection panel back.</span>")
				playsound(src.loc, 'sound/items/Screwdriver.ogg', 25, 1)
				build_state = 2
				return
			if(iswrench(W))
				if(busy || tool_cooldown > world.time)
					return
				tool_cooldown = world.time + 10
				if(user.mind && user.mind.skills_list && user.mind.skills_list["engineer"] < SKILL_ENGINEER_PLASTEEL)
					user << "<span class='warning'>You are not trained to assemble [src]...</span>"
					return
				user.visible_message("<span class='notice'>[user] loosens [src]'s anchor bolts.</span>",
				"<span class='notice'>You loosen [src]'s anchor bolts.</span>")
				playsound(src.loc, 'sound/items/Ratchet.ogg', 25, 1)
				anchored = FALSE
				build_state = 0
				return

		if(0) //Anchor bolts loosened step. Apply crowbar to unseat the panel and take apart the whole thing. Apply wrench to rescure anchor bolts
			if(iswrench(W))
				if(busy || tool_cooldown > world.time)
					return
				tool_cooldown = world.time + 10
				if(user.mind && user.mind.skills_list && user.mind.skills_list["engineer"] < SKILL_ENGINEER_PLASTEEL)
					user << "<span class='warning'>You are not trained to assemble [src]...</span>"
					return
				user.visible_message("<span class='notice'>[user] secures [src]'s anchor bolts.</span>",
				"<span class='notice'>You secure [src]'s anchor bolts.</span>")
				playsound(src.loc, 'sound/items/Ratchet.ogg', 25, 1)
				anchored = TRUE
				build_state = 1
				return
			if(iscrowbar(W))
				if(busy || tool_cooldown > world.time)
					return
				tool_cooldown = world.time + 10
				if(user.mind && user.mind.skills_list && user.mind.skills_list["engineer"] < SKILL_ENGINEER_PLASTEEL)
					user << "<span class='warning'>You are not trained to assemble [src]...</span>"
					return
				user.visible_message("<span class='notice'>[user] starts unseating [src]'s panels.</span>",
				"<span class='notice'>You start unseating [src]'s panels.</span>")
				playsound(src.loc, 'sound/items/Crowbar.ogg', 25, 1)
				busy = 1
				if(do_after(user, 50, TRUE, 5, BUSY_ICON_CLOCK))
					busy = 0
					user.visible_message("<span class='notice'>[user] takes [src]'s panels apart.</span>",
					"<span class='notice'>You take [src]'s panels apart.</span>")
					playsound(loc, 'sound/items/Deconstruct.ogg', 25, 1)
					destroy(TRUE) //Note : Handles deconstruction too !
				else busy = 0
				return

	. = ..()

/obj/structure/barricade/plasteel/attack_hand(mob/user as mob)
	if(isXeno(user))
		return

	playsound(src.loc, 'sound/items/Ratchet.ogg', 25, 1)
	closed = !closed
	density = !density

	if(closed)
		user.visible_message("<span class='notice'>[user] flips the [src] closed.</span>",
		"<span class='notice'>You flip the [src] closed.</span>")
	else
		user.visible_message("<span class='notice'>[user] flips the [src] open.</span>",
		"<span class='notice'>You flip the [src] open.</span>")



	update_icon()
	update_overlay()

/obj/structure/barricade/plasteel/ex_act(severity)
	switch(severity)
		if(1)
			health -= rand(450, 650)
		if(2)
			health -= rand(200, 400)
		if(3)
			health -= rand(50, 150)

	update_health()

/obj/structure/barricade/plasteel/bullet_act(obj/item/projectile/P)
	bullet_ping(P)
	health -= round(P.damage/10)

	if(istype(P.ammo, /datum/ammo/xeno/boiler_gas))
		health -= 50

	update_health()
	return 1

/*----------------------*/
// SANDBAGS
/*----------------------*/

/obj/structure/barricade/sandbags
	name = "sandbag barricade"
	desc = "A bunch of bags filled with sand, stacked into a small wall. Surprisingly sturdy, albeit labour intensive to set up. Trusted to do the job since 1914."
	icon_state = "sandbag_0"
	flags_atom = ON_BORDER
	barricade_resistance = 15
	health = 400
	maxhealth = 400
	stack_type = /obj/item/stack/sandbags
	barricade_hitsound = "sound/weapons/Genhit.ogg"
	barricade_type = "sandbag"
	can_wire = 1

	New(loc, dir)
		..()

		if(loc)
			src.loc = loc

		if(dir)
			src.dir = dir

		if(src.dir == SOUTH)
			pixel_y = -7
		if(src.dir == NORTH)
			pixel_y = 7

/obj/structure/barricade/sandbags/attackby(obj/item/W, mob/user)
	if(istype(W, /obj/item/weapon/etool) && user.a_intent != "harm")
		var/obj/item/weapon/etool/ET = W
		if(!ET.folded)
			user.visible_message("<span class='notice'>[user] starts disassembling [src].</span>",
			"<span class='notice'>You start disassembling [src].</span>")
			if(do_after(user, 30, TRUE, 5, BUSY_ICON_CLOCK))
				user.visible_message("<span class='notice'>[user] disassembles [src].</span>",
				"<span class='notice'>You disassemble [src].</span>")
				destroy(TRUE)
		return 1
	else
		. = ..()

/obj/structure/barricade/sandbags/bullet_act(obj/item/projectile/P)
	bullet_ping(P)
	health -= round(P.damage/10)

	if(istype(P.ammo, /datum/ammo/xeno/boiler_gas))
		health -= 50

	update_health()

	return 1

