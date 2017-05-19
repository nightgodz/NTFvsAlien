/* Tables and Racks
 * Contains:
 *		Tables
 *		Wooden tables
 *		Reinforced tables
 *		Racks
 */


/*
 * Tables
 */
/obj/structure/table
	name = "table"
	desc = "A square piece of metal standing on four metal legs. It can not move."
	icon = 'icons/obj/structures.dmi'
	icon_state = "table"
	density = 1
	anchored = 1.0
	layer = 2.8
	throwpass = 1	//You can throw objects over this, despite it's density.")
	climbable = 1
	breakable = 1
	parts = /obj/item/weapon/table_parts

	var/flipped = 0
	var/flip_cooldown = 0 //If flip cooldown exists, don't allow flipping or putting back. This carries a WORLD.TIME value
	var/health = 100

/obj/structure/table/destroy(var/deconstruct = 0)
	if(deconstruct)
		if(parts)
			new parts(loc)
	else
		if(istype(src,/obj/structure/table/reinforced))
			if(prob(50))
				new /obj/item/stack/rods(loc)
			new /obj/item/stack/sheet/metal(loc)
		else if(istype(src,/obj/structure/table/woodentable) || istype(src,/obj/structure/table/gamblingtable))
			new /obj/item/stack/sheet/wood(loc)
		else
			new /obj/item/stack/sheet/metal(loc)
	density = 0
	cdel(src)

/obj/structure/table/proc/update_adjacent()
	for(var/direction in list(1,2,4,8,5,6,9,10))
		if(locate(/obj/structure/table,get_step(src,direction)))
			var/obj/structure/table/T = locate(/obj/structure/table,get_step(src,direction))
			T.update_icon()

/obj/structure/table/New()
	..()
	for(var/obj/structure/table/T in src.loc)
		if(T != src)
			del(T)
	update_icon()
	update_adjacent()

/obj/structure/table/Crossed(atom/movable/O)
	..()
	if(istype(O,/mob/living/carbon/Xenomorph/Ravager) || istype(O,/mob/living/carbon/Xenomorph/Crusher))
		var/mob/living/carbon/Xenomorph/M = O
		if(!M.stat) //No dead xenos jumpin on the bed~
			visible_message("<span class='danger'>[O] plows straight through \the [src]!</span>")
			destroy()

/obj/structure/table/Del()
	update_adjacent()
	..()

/obj/structure/table/Dispose()
	update_adjacent()
	. = ..()

/obj/structure/table/update_icon()
	spawn(2) //So it properly updates when deleting

		if(flipped)
			var/type = 0
			var/tabledirs = 0
			for(var/direction in list(turn(dir,90), turn(dir,-90)) )
				var/obj/structure/table/T = locate(/obj/structure/table,get_step(src,direction))
				if (T && T.flipped && T.dir == src.dir)
					type++
					tabledirs |= direction
			var/base = "table"
			if (istype(src, /obj/structure/table/woodentable))
				base = "wood"
			if (istype(src, /obj/structure/table/reinforced))
				base = "rtable"

			icon_state = "[base]flip[type]"
			if (type==1)
				if (tabledirs & turn(dir,90))
					icon_state = icon_state+"-"
				if (tabledirs & turn(dir,-90))
					icon_state = icon_state+"+"
			return 1

		var/dir_sum = 0
		for(var/direction in list(1,2,4,8,5,6,9,10))
			var/skip_sum = 0
			for(var/obj/structure/window/W in src.loc)
				if(W.dir == direction) //So smooth tables don't go smooth through windows
					skip_sum = 1
					continue
			var/inv_direction //inverse direction
			switch(direction)
				if(1)
					inv_direction = 2
				if(2)
					inv_direction = 1
				if(4)
					inv_direction = 8
				if(8)
					inv_direction = 4
				if(5)
					inv_direction = 10
				if(6)
					inv_direction = 9
				if(9)
					inv_direction = 6
				if(10)
					inv_direction = 5
			for(var/obj/structure/window/W in get_step(src,direction))
				if(W.dir == inv_direction) //So smooth tables don't go smooth through windows when the window is on the other table's tile
					skip_sum = 1
					continue
			if(!skip_sum) //means there is a window between the two tiles in this direction
				var/obj/structure/table/T = locate(/obj/structure/table,get_step(src,direction))
				if(T && !T.flipped)
					if(direction <5)
						dir_sum += direction
					else
						if(direction == 5)	//This permits the use of all table directions. (Set up so clockwise around the central table is a higher value, from north)
							dir_sum += 16
						if(direction == 6)
							dir_sum += 32
						if(direction == 8)	//Aherp and Aderp.  Jezes I am stupid.  -- SkyMarshal
							dir_sum += 8
						if(direction == 10)
							dir_sum += 64
						if(direction == 9)
							dir_sum += 128

		var/table_type = 0 //stand_alone table
		if(dir_sum%16 in cardinal)
			table_type = 1 //endtable
			dir_sum %= 16
		if(dir_sum%16 in list(3,12))
			table_type = 2 //1 tile thick, streight table
			if(dir_sum%16 == 3) //3 doesn't exist as a dir
				dir_sum = 2
			if(dir_sum%16 == 12) //12 doesn't exist as a dir.
				dir_sum = 4
		if(dir_sum%16 in list(5,6,9,10))
			if(locate(/obj/structure/table,get_step(src.loc,dir_sum%16)))
				table_type = 3 //full table (not the 1 tile thick one, but one of the 'tabledir' tables)
			else
				table_type = 2 //1 tile thick, corner table (treated the same as streight tables in code later on)
			dir_sum %= 16
		if(dir_sum%16 in list(13,14,7,11)) //Three-way intersection
			table_type = 5 //full table as three-way intersections are not sprited, would require 64 sprites to handle all combinations.  TOO BAD -- SkyMarshal
			switch(dir_sum%16)	//Begin computation of the special type tables.  --SkyMarshal
				if(7)
					if(dir_sum == 23)
						table_type = 6
						dir_sum = 8
					else if(dir_sum == 39)
						dir_sum = 4
						table_type = 6
					else if(dir_sum == 55 || dir_sum == 119 || dir_sum == 247 || dir_sum == 183)
						dir_sum = 4
						table_type = 3
					else
						dir_sum = 4
				if(11)
					if(dir_sum == 75)
						dir_sum = 5
						table_type = 6
					else if(dir_sum == 139)
						dir_sum = 9
						table_type = 6
					else if(dir_sum == 203 || dir_sum == 219 || dir_sum == 251 || dir_sum == 235)
						dir_sum = 8
						table_type = 3
					else
						dir_sum = 8
				if(13)
					if(dir_sum == 29)
						dir_sum = 10
						table_type = 6
					else if(dir_sum == 141)
						dir_sum = 6
						table_type = 6
					else if(dir_sum == 189 || dir_sum == 221 || dir_sum == 253 || dir_sum == 157)
						dir_sum = 1
						table_type = 3
					else
						dir_sum = 1
				if(14)
					if(dir_sum == 46)
						dir_sum = 1
						table_type = 6
					else if(dir_sum == 78)
						dir_sum = 2
						table_type = 6
					else if(dir_sum == 110 || dir_sum == 254 || dir_sum == 238 || dir_sum == 126)
						dir_sum = 2
						table_type = 3
					else
						dir_sum = 2 //These translate the dir_sum to the correct dirs from the 'tabledir' icon_state.
		if(dir_sum%16 == 15)
			table_type = 4 //4-way intersection, the 'middle' table sprites will be used.

		if(istype(src,/obj/structure/table/reinforced))
			switch(table_type)
				if(0)
					icon_state = "reinf_table"
				if(1)
					icon_state = "reinf_1tileendtable"
				if(2)
					icon_state = "reinf_1tilethick"
				if(3)
					icon_state = "reinf_tabledir"
				if(4)
					icon_state = "reinf_middle"
				if(5)
					icon_state = "reinf_tabledir2"
				if(6)
					icon_state = "reinf_tabledir3"
		else if(istype(src,/obj/structure/table/woodentable))
			switch(table_type)
				if(0)
					icon_state = "wood_table"
				if(1)
					icon_state = "wood_1tileendtable"
				if(2)
					icon_state = "wood_1tilethick"
				if(3)
					icon_state = "wood_tabledir"
				if(4)
					icon_state = "wood_middle"
				if(5)
					icon_state = "wood_tabledir2"
				if(6)
					icon_state = "wood_tabledir3"
		else if(istype(src,/obj/structure/table/gamblingtable))
			switch(table_type)
				if(0)
					icon_state = "gamble_table"
				if(1)
					icon_state = "gamble_1tileendtable"
				if(2)
					icon_state = "gamble_1tilethick"
				if(3)
					icon_state = "gamble_tabledir"
				if(4)
					icon_state = "gamble_middle"
				if(5)
					icon_state = "gamble_tabledir2"
				if(6)
					icon_state = "gamble_tabledir3"
		else
			switch(table_type)
				if(0)
					icon_state = "table"
				if(1)
					icon_state = "table_1tileendtable"
				if(2)
					icon_state = "table_1tilethick"
				if(3)
					icon_state = "tabledir"
				if(4)
					icon_state = "table_middle"
				if(5)
					icon_state = "tabledir2"
				if(6)
					icon_state = "tabledir3"
		if (dir_sum in list(1,2,4,8,5,6,9,10))
			dir = dir_sum
		else
			dir = 2

/obj/structure/table/attack_tk() // no telehulk sorry
	return

/obj/structure/table/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if(istype(mover) && mover.checkpass(PASSTABLE))
		return 1
	var/obj/structure/table/T = locate(/obj/structure/table) in get_turf(mover)
	if(T && !T.flipped) //flipped tables don't count
		return 1
	if (flipped)
		if (get_dir(loc, target) == dir)
			return !density
		else
			return 1
	return 0

/obj/structure/table/CheckExit(atom/movable/O as mob|obj, target as turf)
	if(istype(O) && O.checkpass(PASSTABLE))
		return 1
	if (flipped)
		if (get_dir(loc, target) == dir)
			return !density
		else
			return 1
	return 1

//Flipping tables, nothing more, nothing less
/obj/structure/table/MouseDrop(over_object, src_location, over_location)

	..()

	if(flipped)
		do_put()
	else
		do_flip()

/obj/structure/table/MouseDrop_T(obj/O as obj, mob/user as mob)

	if ((!( istype(O, /obj/item/weapon) ) || user.get_active_hand() != O))
		return ..()
	if(isrobot(user))
		return
	user.drop_held_item()
	if (O.loc != src.loc)
		step(O, get_dir(O, src))
	return


/obj/structure/table/attackby(obj/item/W, mob/user)
	if (!W) return
	if (istype(W, /obj/item/weapon/grab) && get_dist(src,user)<=1)
		var/obj/item/weapon/grab/G = W
		if (istype(G.grabbed_thing, /mob/living))
			var/mob/living/M = G.grabbed_thing
			if (user.grab_level < GRAB_AGGRESSIVE)
				if(user.a_intent == "hurt")
					if (prob(15))	M.Weaken(5)
					M.apply_damage(8,def_zone = "head")
					visible_message("<span class='danger'>[user] slams [M]'s face against [src]!</span>")
					playsound(src.loc, 'sound/weapons/tablehit1.ogg', 25, 1)
				else
					user << "<span class='warning'>You need a better grip to do that!</span>"
					return
			else
				M.forceMove(loc)
				M.Weaken(5)
				visible_message("<span class='danger'>[user] puts [M] on [src].</span>")
		return

	if (istype(W, /obj/item/weapon/wrench))
		user << "\blue Now disassembling table"
		playsound(src.loc, 'sound/items/Ratchet.ogg', 25, 1)
		if(do_after(user,50))
			destroy(1)
		return

	if(isrobot(user))
		return

	if(istype(W, /obj/item/weapon/melee/energy/blade))
		var/datum/effect/effect/system/spark_spread/spark_system = new /datum/effect/effect/system/spark_spread()
		spark_system.set_up(5, 0, src.loc)
		spark_system.start()
		playsound(src.loc, 'sound/weapons/blade1.ogg', 25, 1)
		playsound(src.loc, "sparks", 25, 1)
		for(var/mob/O in viewers(user, 4))
			O.show_message("\blue The [src] was sliced apart by [user]!", 1, "\red You hear [src] coming apart.", 2)
		destroy()
		return

	if(istype(W, /obj/item/weapon/wristblades))
		if(rand(0,2) == 0)
			playsound(src.loc, 'sound/weapons/wristblades_hit.ogg', 25, 1)
			for(var/mob/O in viewers(user, 4))
				O.show_message("\red <b>The [src] was sliced apart by [user]!</b>", 1, "\red <b>You hear [src] coming apart.</b>", 2)
			destroy()
		else
			user << "\red You slice at the table, but only claw it up a little."
		return

	user.drop_inv_item_to_loc(W, loc)


/obj/structure/table/proc/straight_table_check(var/direction)
	var/obj/structure/table/T
	for(var/angle in list(-90,90))
		T = locate() in get_step(src.loc,turn(direction,angle))
		if(T && !T.flipped)
			return 0
	T = locate() in get_step(src.loc,direction)
	if (!T || T.flipped)
		return 1
	if (istype(T,/obj/structure/table/reinforced/))
		var/obj/structure/table/reinforced/R = T
		if (R.status == 2)
			return 0
	return T.straight_table_check(direction)

/obj/structure/table/verb/do_flip()
	set name = "Flip table"
	set desc = "Flips a non-reinforced table"
	set category = "Object"
	set src in oview(1)

	if(!can_touch(usr) || ismouse(usr))
		return

	if(!flip(get_cardinal_dir(usr, src)))
		usr << "<span class='warning'>It won't budge.</span>"
		return

	usr.visible_message("<span class='warning'>[usr] flips \the [src]!</span>")

	if(climbable)
		structure_shaken()

	flip_cooldown = world.time + 50

/obj/structure/table/proc/unflipping_check(var/direction)

	if(world.time < flip_cooldown)
		return 0

	for(var/mob/M in oview(src, 0))
		return 0

	var/list/L = list()
	if(direction)
		L.Add(direction)
	else
		L.Add(turn(src.dir,-90))
		L.Add(turn(src.dir,90))
	for(var/new_dir in L)
		var/obj/structure/table/T = locate() in get_step(src.loc,new_dir)
		if(T)
			if(T.flipped && T.dir == src.dir && !T.unflipping_check(new_dir))
				return 0
	return 1

/obj/structure/table/proc/do_put()
	set name = "Put table back"
	set desc = "Puts flipped table back"
	set category = "Object"
	set src in oview(1)

	if(!can_touch(usr))
		return

	if(!unflipping_check())
		usr << "<span class='warning'>It won't budge.</span>"
		return

	unflip()

	flip_cooldown = world.time + 50

/obj/structure/table/proc/flip(var/direction)

	if(world.time < flip_cooldown)
		return 0

	if(!straight_table_check(turn(direction,90)) || !straight_table_check(turn(direction,-90)))
		return 0

	verbs -=/obj/structure/table/verb/do_flip
	verbs +=/obj/structure/table/proc/do_put

	var/list/targets = list(get_step(src,dir),get_step(src,turn(dir, 45)),get_step(src,turn(dir, -45)))
	for (var/atom/movable/A in get_turf(src))
		if (!A.anchored)
			spawn(0)
				A.throw_at(pick(targets),1,1)

	dir = direction
	if(dir != NORTH)
		layer = 5
	climbable = 0 //flipping tables allows them to be used as makeshift barriers
	flipped = 1
	flags_atom |= ON_BORDER
	for(var/D in list(turn(direction, 90), turn(direction, -90)))
		var/obj/structure/table/T = locate() in get_step(src,D)
		if(T && !T.flipped)
			T.flip(direction)
	update_icon()
	update_adjacent()

	return 1

/obj/structure/table/proc/unflip()

	verbs -=/obj/structure/table/proc/do_put
	verbs +=/obj/structure/table/verb/do_flip

	layer = initial(layer)
	flipped = 0
	climbable = initial(climbable)
	flags_atom &= ~ON_BORDER
	for(var/D in list(turn(dir, 90), turn(dir, -90)))
		var/obj/structure/table/T = locate() in get_step(src.loc,D)
		if(T && T.flipped && T.dir == src.dir)
			T.unflip()
	update_icon()
	update_adjacent()

	return 1

/*
 * Wooden tables
 */
/obj/structure/table/woodentable
	name = "wooden table"
	desc = "Do not apply fire to this. Rumour says it burns easily."
	icon_state = "wood_table"
	parts = /obj/item/weapon/table_parts/wood
	health = 50
/*
 * Gambling tables
 */
/obj/structure/table/gamblingtable
	name = "gambling table"
	desc = "A curved wooden table with a thin carpet of green fabric."
	icon_state = "gamble_table"
	parts = /obj/item/weapon/table_parts/gambling
	health = 50
/*
 * Reinforced tables
 */
/obj/structure/table/reinforced
	name = "reinforced table"
	desc = "A version of the four legged table. It is stronger."
	icon_state = "reinf_table"
	health = 200
	var/status = 2
	parts = /obj/item/weapon/table_parts/reinforced

/obj/structure/table/reinforced/flip(var/direction)
	if (status == 2)
		return 0
	else
		return ..()

/obj/structure/table/reinforced/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if (istype(W, /obj/item/weapon/weldingtool))
		var/obj/item/weapon/weldingtool/WT = W
		if(WT.remove_fuel(0, user))
			if(src.status == 2)
				user << "\blue Now weakening the reinforced table"
				playsound(src.loc, 'sound/items/Welder.ogg', 25, 1)
				if (do_after(user, 50))
					if(!src || !WT.isOn()) return
					user << "\blue Table weakened"
					src.status = 1
			else
				user << "\blue Now strengthening the reinforced table"
				playsound(src.loc, 'sound/items/Welder.ogg', 25, 1)
				if (do_after(user, 50))
					if(!src || !WT.isOn()) return
					user << "\blue Table strengthened"
					src.status = 2
			return
		return

	if (istype(W, /obj/item/weapon/wrench))
		if(src.status == 2)
			return

	..()

/*
 * Racks
 */
/obj/structure/rack
	name = "rack"
	desc = "Different from the Middle Ages version."
	icon = 'icons/obj/objects.dmi'
	icon_state = "rack"
	density = 1
	flags_atom = FPRINT
	anchored = 1.0
	throwpass = 1	//You can throw objects over this, despite it's density.
	breakable = 1
	climbable = 1
	parts = /obj/item/weapon/rack_parts

/obj/structure/rack/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if(air_group || (height==0)) return 1
	if(src.density == 0) //Because broken racks -Agouri |TODO: SPRITE!|
		return 1
	if(istype(mover) && mover.checkpass(PASSTABLE))
		return 1
	else
		return 0

/obj/structure/rack/MouseDrop_T(obj/O as obj, mob/user as mob)
	if ((!( istype(O, /obj/item/weapon) ) || user.get_active_hand() != O))
		return
	if(isrobot(user))
		return
	user.drop_held_item()
	if (O.loc != src.loc)
		step(O, get_dir(O, src))
	return

/obj/structure/rack/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if (istype(W, /obj/item/weapon/wrench))
		destroy(1)
		playsound(src.loc, 'sound/items/Ratchet.ogg', 25, 1)
		return
	if(isrobot(user))
		return
	user.drop_held_item()
	if(W && W.loc)	W.loc = src.loc
	return

/obj/structure/rack/Crossed(atom/movable/O)
	..()
	if(istype(O,/mob/living/carbon/Xenomorph/Ravager) || istype(O,/mob/living/carbon/Xenomorph/Crusher))
		var/mob/living/carbon/Xenomorph/M = O
		if(!M.stat) //No dead xenos jumpin on the bed~
			visible_message("<span class='danger'>[O] plows straight through the [src]!</span>")
			destroy()

/obj/structure/rack/destroy(var/deconstruct = 0)
	if(deconstruct)
		if(parts)
			new parts(loc)
	else
		new /obj/item/stack/sheet/metal(loc)
	density = 0
	del(src)
