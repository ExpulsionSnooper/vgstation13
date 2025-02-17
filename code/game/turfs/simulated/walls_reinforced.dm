#define WALLCOMPLETED 0
#define WALLCOVEREXPOSED 1
#define WALLCOVERUNSECURED 2
#define WALLCOVERWEAKENED 3
#define WALLCOVERREMOVED 4
#define WALLRODSUNSECURED 5
#define WALLRODSCUT 6
/turf/simulated/wall/r_wall
	name = "reinforced wall"
	desc = "A huge chunk of reinforced metal and anchored rods used to separate rooms and keep all but the most equipped crewmen out."
	icon_state = "r_wall"
	opacity = 1
	density = 1

	walltype = "rwall"
	hardness = 90

	explosion_block = 2
	girder_type = /obj/structure/girder/reinforced

	penetration_dampening = 20

	var/d_state = WALLCOMPLETED

/turf/simulated/wall/r_wall/examine(mob/user)
	..()
	if(d_state)
		switch(d_state) //How fucked or unfinished is our wall
			if(WALLCOVEREXPOSED)
				to_chat(user, "It has no outer grille")
			if(WALLCOVERUNSECURED)
				to_chat(user, "It has no outer grille and the external reinforced cover is exposed")
			if(WALLCOVERWEAKENED)
				to_chat(user, "It has no outer grille and the external reinforced cover has been welded into")
			if(WALLCOVERREMOVED)
				to_chat(user, "It has no outer grille or external reinforced cover and the external support rods are exposed")
			if(WALLRODSUNSECURED)
				to_chat(user, "It has no outer grille or external reinforced cover and the external support rods are loose")
			if(WALLRODSCUT)
				to_chat(user, "It has no outer grille, external reinforced cover or external support rods and the inner reinforced cover is exposed")//And that's terrible


//We need to export this here because we want to handle it differently
//This took me longer to find this than it should havle
/turf/simulated/wall/r_wall/relativewall()
	if(d_state) //We are fucking building
		return //Fuck off
	..()

/turf/simulated/wall/r_wall/update_icon()
	if(!d_state) //Are we under construction or deconstruction ?
		relativewall() //Well isn't that odd, let's pass this to smoothwall.dm
		relativewall_neighbours() //Let's make sure the other walls know about this travesty
		return //Now fuck off
	icon_state = "r_wall-[d_state]"  //You can thank me later

/turf/simulated/wall/r_wall/attackby(obj/item/W as obj, mob/user as mob)

	if (!user.dexterity_check())
		to_chat(user, "<span class='warning'>You don't have the dexterity to do this!</span>")
		return

	if(istype(W,/obj/item/tool/solder) && bullet_marks)
		var/obj/item/tool/solder/S = W
		if(!S.remove_fuel(bullet_marks*2,user))
			return
		playsound(loc, 'sound/items/Welder.ogg', 100, 1)
		to_chat(user, "<span class='notice'>You remove the bullet marks with \the [W].</span>")
		bullet_marks = 0
		icon = initial(icon)
		return

	//Get the user's location
	if(!istype(user.loc, /turf))
		return	//Can't do this stuff whilst inside objects and such //Thanks BYOND

	if(rotting)
		if(W.is_hot()) //Yes, you can do it with a welding tool, or a lighter, or a candle, or an energy sword
			user.visible_message("<span class='notice'>[user] burns the fungi away with \the [W].</span>", \
			"<span class='notice'>You burn the fungi away with \the [W].</span>")
			playsound(src, 'sound/items/Welder.ogg', 10, 1)
			remove_rot()
			return
		if(istype(W,/obj/item/weapon/soap))
			user.visible_message("<span class='notice'>[user] forcefully scrubs the fungi away with \the [W].</span>", \
			"<span class='notice'>You forcefully scrub the fungi away with \the [W].</span>")
			remove_rot()
			return
		else if(!W.is_sharp() && W.force >= 10 || W.force >= 20)
			user.visible_message("<span class='warning'>With one strong swing, [user] destroys the rotting [src] with \the [W].</span>", \
			"<span class='notice'>With one strong swing, the rotting [src] crumbles away under \the [W].</span>")
			dismantle_wall()

			var/pdiff = performWallPressureCheck(src)
			if(pdiff)
				investigation_log(I_ATMOS, "with a pdiff of [pdiff] has been broken after rotting by [user.real_name] ([formatPlayerPanel(user, user.ckey)]) at [formatJumpTo(get_turf(src))]!")
				message_admins("\The [src] with a pdiff of [pdiff] has been broken after rotting by [user.real_name] ([formatPlayerPanel(user, user.ckey)]) at [formatJumpTo(get_turf(src))]!")
			return

	//THERMITE related stuff. Calls src.thermitemelt() which handles melting simulated walls and the relevant effects
	if(thermite && can_thermite)
		if(W.is_hot()) //HEY CAN THIS SET THE THERMITE ON FIRE ?
			user.visible_message("<span class='warning'>[user] applies \the [W] to the thermite coating \the [src] and waits.</span>", \
			"<span class='warning'>You apply \the [W] to the thermite coating \the [src] and wait...</span>")
			if(do_after(user, src, 100) && W.is_hot()) //Thermite is hard to light up
				thermitemelt(user) //There, I just saved you fifty lines of redundant typechecks and awful snowflake coding
				user.visible_message("<span class='warning'>[user] sets \the [src] ablaze with \the [W]!</span>", \
				"<span class='warning'>You set \the [src] ablaze with \the [W]!</span>")
				return

	//Deconstruction and reconstruction
	switch(d_state)
		if(WALLCOMPLETED)
			if(W.is_wirecutter(user))
				W.playtoolsound(src, 100)
				src.d_state = WALLCOVEREXPOSED
				update_icon()
				user.visible_message("<span class='warning'>[user] cuts out \the [src]'s outer grille.</span>", \
				"<span class='notice'>You cut out \the [src]'s outer grille, exposing the external cover.</span>")
				return

		if(WALLCOVEREXPOSED)
			if(W.is_screwdriver(user))
				user.visible_message("<span class='warning'>[user] begins unsecuring \the [src]'s external cover.</span>", \
				"<span class='notice'>You begin unsecuring \the [src]'s external cover.</span>")
				W.playtoolsound(src, 100)

				if(do_after(user, src, 40) && d_state == WALLCOVEREXPOSED)
					src.d_state = WALLCOVERUNSECURED
					update_icon()
					user.visible_message("<span class='warning'>[user] unsecures \the [src]'s external cover.</span>", \
					"<span class='notice'>You unsecure \the [src]'s external cover.</span>")
				return

			//Repairing outer grille, use welding tool
			else if(iswelder(W))
				var/obj/item/tool/weldingtool/WT = W
				user.visible_message("<span class='notice'>[user] begins mending the damage on \the [src]'s outer grille.</span>", \
				"<span class='notice'>You begin mending the damage on \the [src]'s outer grille.</span>", \
				"<span class='warning'>You hear welding noises.</span>")
				if(WT.do_weld(user, src, 40, 0) && d_state == WALLCOVEREXPOSED)
					src.d_state = WALLCOMPLETED
					update_icon()
					user.visible_message("<span class='notice'>[user] mends the damage on \the [src]'s outer grille.</span>", \
					"<span class='notice'>You mend the damage on \the [src]'s outer grille.</span>", \
					"<span class='warning'>You hear welding noises.</span>")
				return

		if(WALLCOVERUNSECURED)
			if(iswelder(W))
				var/obj/item/tool/weldingtool/WT = W
				user.visible_message("<span class='warning'>[user] begins slicing through \the [src]'s external cover.</span>", \
				"<span class='notice'>You begin slicing through \the [src]'s external cover.</span>", \
				"<span class='warning'>You hear welding noises.</span>")
				if(WT.do_weld(user, src, 60, 0) && d_state == WALLCOVERUNSECURED)
					src.d_state = WALLCOVERWEAKENED
					update_icon()
					user.visible_message("<span class='warning'>[user] finishes weakening \the [src]'s external cover.</span>", \
					"<span class='notice'>You finish weakening \the [src]'s external cover.</span>", \
					"<span class='warning'>You hear welding noises.</span>")

				return
			//Re-secure external cover, unsurprisingly exact same step as above
			else if(W.is_screwdriver(user))
				user.visible_message("<span class='notice'>[user] begins securing \the [src]'s external cover.</span>", \
				"<span class='notice'>You begin securing \the [src]'s external cover.</span>")
				W.playtoolsound(src, 100)

				if(do_after(user, src, 40) && d_state == WALLCOVERUNSECURED)
					src.d_state = WALLCOVEREXPOSED
					update_icon()
					user.visible_message("<span class='warning'>[user] secures \the [src]'s external cover.</span>", \
					"<span class='notice'>You secure \the [src]'s external cover.</span>")
				return

		if(WALLCOVERWEAKENED)
			if(iscrowbar(W))

				user.visible_message("<span class='warning'>[user] starts prying off \the [src]'s external cover.</span>", \
				"<span class='notice'>You struggle to pry off \the [src]'s external cover.</span>", \
				"<span class='warning'>You hear a crowbar.</span>")
				W.playtoolsound(src, 100)

				if(do_after(user, src, 100) && d_state == WALLCOVERWEAKENED)
					playsound(src, 'sound/items/Deconstruct.ogg', 100, 1) //SLAM
					src.d_state = WALLCOVERREMOVED
					update_icon()
					new /obj/item/stack/sheet/plasteel(get_turf(src))
					user.visible_message("<span class='warning'>[user] pries off \the [src]'s external cover.</span>", \
					"<span class='notice'>You pry off \the [src]'s external cover.</span>")
				return

			//Fix welding damage caused above, by welding shit into place again
			else if(iswelder(W))

				var/obj/item/tool/weldingtool/WT = W
				user.visible_message("<span class='notice'>[user] begins fixing the welding damage on \the [src]'s external cover.</span>", \
				"<span class='notice'>You begin fixing the welding damage on \the [src]'s external cover.</span>", \
				"<span class='warning'>You hear welding noises.</span>")

				if(WT.do_weld(user, src, 60, 0) && d_state == WALLCOVERWEAKENED)
					playsound(src, 'sound/items/Welder.ogg', 100, 1) //Not an error, play welder sound again
					src.d_state = WALLCOVERUNSECURED
					update_icon()
					user.visible_message("<span class='warning'>[user] fixes the welding damage on \the [src]'s external cover.</span>", \
					"<span class='notice'>You fix the welding damage on \the [src]'s external cover.</span>", \
					"<span class='warning'>You hear welding noises.</span>")
				return

		if(WALLCOVERREMOVED)
			if(W.is_wrench(user))

				user.visible_message("<span class='warning'>[user] starts loosening the bolts anchoring \the [src]'s external support rods.</span>", \
				"<span class='notice'>You start loosening the bolts anchoring \the [src]'s external support rods.</span>")
				W.playtoolsound(src, 100)

				if(do_after(user, src, 40) && d_state == WALLCOVERREMOVED)
					src.d_state = WALLRODSUNSECURED
					update_icon()
					user.visible_message("<span class='warning'>[user] loosens the bolts anchoring \the [src]'s external support rods.</span>", \
					"<span class='notice'>You loosen the bolts anchoring \the [src]'s external support rods.</span>")
				return

			//Only construction step after reinforced girder, add the second plasteel sheet
			//Acts as a super repair step, incidentally, if there's clearly more than cover damage
			else if(istype(W, /obj/item/stack/sheet/plasteel))
				var/obj/item/stack/sheet/plasteel/P = W
				user.visible_message("<span class='notice'>[user] starts installing an external cover to \the [src].</span>", \
				"<span class='notice'>You start installing an external cover to \the [src].</span>")
				playsound(src, 'sound/items/Deconstruct.ogg', 100, 1)

				if(do_after(user, src, 50) && d_state == WALLCOVERREMOVED)
					P.use(1)
					src.d_state = WALLCOMPLETED //A new pristine reinforced cover, we are done here
					update_icon()
					user.visible_message("<span class='notice'>[user] finishes installing an external cover to \the [src].</span>", \
					"<span class='notice'>You finish installing an external cover to \the [src].</span>")
				return

		if(WALLRODSUNSECURED)
			if(iswelder(W))

				var/obj/item/tool/weldingtool/WT = W
				user.visible_message("<span class='warning'>[user] begins slicing through \the [src]'s external support rods.</span>", \
				"<span class='notice'>You begin slicing through \the [src]'s external support rods.</span>")

				if(WT.do_weld(user, src, 100, 0) && d_state == WALLRODSUNSECURED)
					src.d_state = WALLRODSCUT
					update_icon()
					user.visible_message("<span class='warning'>[user] slices through \the [src]'s external support rods.</span>", \
					"<span class='notice'>You slice through \the [src]'s external support rods, exposing its internal cover.</span>")
				return

			if(istype(W, /obj/item/weapon/pickaxe/plasmacutter))

				user.visible_message("<span class='warning'>[user] begins slicing through \the [src]'s external support rods.</span>", \
				"<span class='notice'>You begin slicing through \the [src]'s external support rods.</span>")
				playsound(src, 'sound/items/Welder.ogg', 100, 1)

				if(do_after(user, src, 70))
					playsound(src, 'sound/items/Welder.ogg', 100, 1)
					src.d_state = WALLRODSCUT
					update_icon()
					user.visible_message("<span class='warning'>[user] slices through \the [src]'s external support rods.</span>", \
					"<span class='notice'>You slice through \the [src]'s external support rods, exposing its internal cover.</span>")
				return

			//Repair step, tighten the anchoring bolts
			else if(W.is_wrench(user))

				user.visible_message("<span class='notice'>[user] starts tightening the bolts anchoring \the [src]'s external support rods.</span>", \
				"<span class='notice'>You start tightening the bolts anchoring \the [src]'s external support rods.</span>")
				W.playtoolsound(src, 100)

				if(do_after(user, src, 40) && d_state == WALLRODSUNSECURED)
					src.d_state = WALLCOVERREMOVED
					update_icon()
					user.visible_message("<span class='notice'>[user] tightens the bolts anchoring \the [src]'s external support rods.</span>", \
					"<span class='notice'>You tighten the bolts anchoring \the [src]'s external support rods.</span>")
				return

		if(WALLRODSCUT)
			if(iscrowbar(W))

				user.visible_message("<span class='warning'>[user] starts prying off [src]'s internal cover.</span>", \
				"<span class='notice'>You struggle to pry off [src]'s internal cover.</span>")
				W.playtoolsound(src, 100)

				if(do_after(user, src, 100) && d_state == WALLRODSCUT)
					user.visible_message("<span class='warning'>[user] pries off [src]'s internal cover.</span>", \
					"<span class='notice'>You pry off [src]'s internal cover.</span>")
					playsound(src, 'sound/items/Deconstruct.ogg', 100, 1)

					var/pdiff = performWallPressureCheck(src)
					if(pdiff)
						investigation_log(I_ATMOS, "with a pdiff of [pdiff] has been dismantled by [user.real_name] ([formatPlayerPanel(user, user.ckey)]) at [formatJumpTo(get_turf(src))]!")
						message_admins("\The [src] with a pdiff of [pdiff] has been dismantled by [user.real_name] ([formatPlayerPanel(user, user.ckey)]) at [formatJumpTo(get_turf(src))]!")

					dismantle_wall() //Mr. Engineer, break down that reinforced wall

				return

			//Repair the external support rods welded through in the previous step, with a welding tool. Naturally
			else if(iswelder(W))

				var/obj/item/tool/weldingtool/WT = W
				if(WT.remove_fuel(1,user))
					user.visible_message("<span class='notice'>[user] begins mending \the [src]'s external support rods.</span>", \
					"<span class='notice'>You begin mending \the [src]'s external support rods.</span>")
					playsound(src, 'sound/items/Welder.ogg', 100, 1)

					if(do_after(user, src, 100) && d_state == WALLRODSCUT)
						playsound(src, 'sound/items/Welder.ogg', 100, 1) //Not an error, play welder sound again
						src.d_state = WALLRODSUNSECURED
						update_icon()
						user.visible_message("<span class='warning'>[user] mends \the [src]'s external support rods.</span>", \
						"<span class='notice'>You mend \the [src]'s external support rods.</span>")
				else
					return

//This is where we perform actions that aren't deconstructing, constructing or thermiting the reinforced wall

	//Drilling
	//Needs a diamond drill or equivalent
	if(istype(W, /obj/item/weapon/pickaxe))

		var/obj/item/weapon/pickaxe/PK = W
		if(!(PK.diggables & DIG_RWALLS))
			return

		user.visible_message("<span class='warning'>[user] begins [PK.drill_verb] straight into \the [src].</span>", \
		"<span class='notice'>You begin [PK.drill_verb] straight into \the [src].</span>")
		PK.playtoolsound(src, 100)
		if(do_after(user, src, (MINE_DURATION * PK.toolspeed) * 50))
			user.visible_message("<span class='notice'>[user]'s [PK] tears though the last of \the [src], leaving nothing but a girder.</span>", \
			"<span class='notice'>Your [PK] tears though the last of \the [src], leaving nothing but a girder.</span>")
			var/pdiff = performWallPressureCheck(src)
			if(pdiff)
				investigation_log(I_ATMOS, "with a pdiff of [pdiff] has been drilled through by [user.real_name] ([formatPlayerPanel(user, user.ckey)]) at [formatJumpTo(get_turf(src))]!")
				message_admins("\The [src] with a pdiff of [pdiff] has been drilled through by [user.real_name] ([formatPlayerPanel(user, user.ckey)]) at [formatJumpTo(get_turf(src))]!")

			dismantle_wall()
		return

	else if(istype(W, /obj/item/mounted))
		return

	//Finally, CHECKING FOR FALSE WALLS if it isn't damaged
	//This is obsolete since reinforced false walls were commented out, but gotta slap the wall with my hand anyways !
	else if(!d_state)
		return attack_hand(user)
	return

/turf/simulated/wall/r_wall/attack_construct(mob/user as mob)
	return 0

/turf/simulated/wall/r_wall/singularity_pull(S, current_size)
	if(current_size >= STAGE_FIVE)
		if(prob(30))
			dismantle_wall()

/turf/simulated/wall/r_wall/dismantle_wall(devastated = 0, explode = 0)
	if(!devastated)
		new /obj/item/stack/sheet/plasteel(src)//Reinforced girder has deconstruction steps too. If no girder, drop ONE plasteel sheet AND rod)
		new girder_type(src)
	else
		new /obj/item/stack/rods(src, 2)
		new /obj/item/stack/sheet/plasteel(src)

	for(var/obj/O in src.contents) //Eject contents!
		if(istype(O,/obj/structure/sign/poster))
			var/obj/structure/sign/poster/P = O
			P.roll_and_drop(src)

	ChangeTurf(dismantle_type)
	update_near_walls()

/turf/simulated/wall/r_wall/ex_act(severity)
	if(rotting)
		severity = 1.0
	switch(severity)
		if(1.0)
			if(prob(66)) //It's "bomb-proof"
				dismantle_wall(0,1) //So it isn't completely destroyed, nice uh ?
			else
				dismantle_wall(1,1) //Fuck it up nicely
		if(2.0)
			if(prob(75) && (d_state == WALLCOMPLETED))//No more infinite plasteel generation!
				src.d_state = WALLCOVERREMOVED
				update_icon()
				new /obj/item/stack/sheet/plasteel(get_turf(src)) //Lose the plasteel needed to get ther)
			else
				dismantle_wall(0,1)
		if(3.0)
			if(prob(15))
				dismantle_wall(0,1)
			else //If prob fails, break the outer safety grille to look like scrap damage
				src.d_state = WALLCOVEREXPOSED
				update_icon()
	return

/turf/simulated/wall/r_wall/dissolvable()
	return 0

#undef WALLCOMPLETED
#undef WALLCOVEREXPOSED
#undef WALLCOVERUNSECURED
#undef WALLCOVERWEAKENED
#undef WALLCOVERREMOVED
#undef WALLRODSUNSECURED
#undef WALLRODSCUT
