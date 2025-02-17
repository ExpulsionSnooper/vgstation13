/*
 * Paper
 * also scraps of paper
 */

/obj/item/weapon/paper
	name = "paper"
	gender = NEUTER
	icon = 'icons/obj/bureaucracy.dmi'
	inhand_states = list("left_hand" = 'icons/mob/in-hand/left/bureaucracy.dmi', "right_hand" = 'icons/mob/in-hand/right/bureaucracy.dmi')
	icon_state = "paper"
	item_state = "paper"
	throwforce = 0
	w_class = W_CLASS_TINY
	w_type = RECYK_WOOD
	throw_range = 1
	throw_speed = 1
	layer = ABOVE_DOOR_LAYER
	pressure_resistance = 1
	attack_verb = list("slaps")
	autoignition_temperature = AUTOIGNITION_PAPER
	fire_fuel = 1

	var/info		//What's actually written on the paper.
	var/info_links	//A different version of the paper which includes html links at fields and EOF
	var/stamps		//The (text for the) stamps on the paper.
	var/fields		//Amount of user created fields
	var/list/stamped
	var/rigged = 0
	var/spam_flag = 0
	var/display_x = 400
	var/display_y = 400

	var/log=""
	var/obj/item/weapon/photo/img

//lipstick wiping is in code/game/objects/items/weapons/cosmetics.dm!

/obj/item/weapon/paper/New()
	..()
	pixel_y = rand(-8, 8) * PIXEL_MULTIPLIER
	pixel_x = rand(-9, 9) * PIXEL_MULTIPLIER
	spawn(2)
		update_icon()
		updateinfolinks()
		return

/obj/item/weapon/paper/proc/show_text(var/mob/user, var/links = FALSE, var/starred = FALSE)
	var/info_text = links ? info_links : info
	var/info_image = ""

	if(!user.can_read())
		starred = TRUE

	if(starred)
		info_text = stars(info_text)

	if(img)
		user << browse_rsc(img.img, "tmp_photo.png")
		info_image = "<img src='tmp_photo.png' width='192' style='-ms-interpolation-mode:nearest-neighbor' /><br><a href='?src=\ref[src];picture=1'>Remove</a><br>"
	user << browse("<HTML><HEAD><TITLE>[name]</TITLE></HEAD><BODY[color ? " bgcolor=[src.color]":""]>[info_image][info_text][stamps]</BODY></HTML>", "window=[name];size=[display_x]x[display_y]")
	onclose(user, "[name]")

/obj/item/weapon/paper/update_icon()
	icon_state=initial(icon_state)
	if(info)
		icon_state += "_words"

/obj/item/weapon/paper/examine(mob/user)
	if(user.range_check(src))
		show_text(user)
	else
		..() //Only show a regular description if it is too far away to read.
		to_chat(user, "<span class='notice'>It is too far away to read.</span>")

/mob/proc/range_check(paper)
	return Adjacent(paper)

/mob/dead/range_check(paper)
	return 1

/mob/living/silicon/ai/range_check(paper)
	if(ai_flags & HIGHRESCAMS)
		return 1
	return ..()

/obj/item/weapon/paper/verb/rename()
	set name = "Rename paper"
	set category = "Object"
	set src in usr

	if(clumsy_check(usr) && prob(50))
		to_chat(usr, "<span class='warning'>You cut yourself on [src].</span>")
		return
	var/n_name = copytext(sanitize(input(usr, "What would you like to label [src]?", "Paper Labelling", null)  as text), 1, MAX_NAME_LEN)
	if((loc == usr && !usr.isUnconscious()))
		name = "paper[(n_name ? text("- '[n_name]'") : null)]"
	add_fingerprint(usr)
	return

/obj/item/weapon/paper/attack_self(mob/living/user as mob)
	if(user.attack_delayer.blocked())
		return
	if(ishuman(user)) // best not let the monkeys write loveletters
		var/mob/living/carbon/human/H = user
		if((H.attack_type == ATTACK_BITE) && (H.a_intent == I_HELP)) //if biting and helping
			if(!(H.species.anatomy_flags & HAS_LIPS) || (H.species.flags & SPECIES_NO_MOUTH)) // skeletons can apply lipstick but cannot kiss
				to_chat(user, "You have no lips, how are you going to kiss?")
				return
			if(H.check_body_part_coverage(MOUTH))
				to_chat(user, "Remove the equipment covering your mouth, first.")
				return
			add_fingerprint(H)
			user.delayNextAttack(1 SECONDS)
			if(H.lip_style)
				to_chat(user, "<span class='notice'>You kiss the piece of paper, leaving a lipstick impression.</span>")
				src.stamps += (src.stamps=="" ? "<HR>" : "<BR>") + "<i>The [src.name] has a big [H.lip_style] kiss on it.</i>"
				var/image/kissoverlay = image('icons/obj/paper.dmi')
				var/colourcode = "#FF0000" //red default
				switch(H.lip_style) // TODO - make lip_style use RGB values instead of color name in text
					if("jade")
						colourcode = "#00FF00"
					if("black")
						colourcode = "#000000"
					if("blue")
						colourcode = "#0000FF"
					if("purple")
						colourcode = "#800080"
				kissoverlay.icon_state = "lipstick_kiss"
				kissoverlay.icon += colourcode // make the kiss the color of the lipstick
				add_paper_overlay(src,kissoverlay,1,1)
			else
				to_chat(user, "<span class='notice'>You kiss the piece of paper.</span>")


	user.examination(src)
	if(rigged && (Holiday == APRIL_FOOLS_DAY))
		if(spam_flag == 0)
			spam_flag = 1
			playsound(loc, 'sound/items/bikehorn.ogg', 50, 1)
			spawn(20)
				spam_flag = 0
	return

/obj/item/weapon/paper/attack_robot(var/mob/user as mob)
	if(isMoMMI(user) && Adjacent(user))
		return attack_hand(user)
	else
		return attack_ai(user)

/obj/item/weapon/paper/attack_ai(var/mob/living/silicon/ai/user as mob)
	var/dist
	if(istype(user) && user.current) //is AI
		dist = get_dist(src, user.current)
	else //cyborg or AI not seeing through a camera
		dist = get_dist(src, user)
	if(dist < 2 || (istype(user) && (user.ai_flags & HIGHRESCAMS)))
		show_text(user)
	else
		show_text(user, starred = TRUE)
	return

//Normally ghosts can read at any range, but nobody bothered to actually make attack_ghost not be attack_ai who
//normally can't read at any range. This fixes it.
/obj/item/weapon/paper/attack_ghost(mob/user)
	user.examination(src)

/obj/item/weapon/paper/proc/addtofield(var/id, var/text, var/links = 0)
	var/locid = 0
	var/laststart = 1
	var/textindex = 1
	var/softcount = 0
	while(1) // I know this can cause infinite loops and fuck up the whole server, but the if(istart==0) should be safe as fuck
		if(softcount>50)
			break
		if(softcount%25 == 0)
			sleep(1)
		var/istart = 0
		if(links)
			istart = findtext(info_links, "<span class=\"paper_field\">", laststart)
		else
			istart = findtext(info, "<span class=\"paper_field\">", laststart)

		if(istart==0)
			return // No field found with matching id

		softcount++
		laststart = istart+1
		locid++
		if(locid == id)
			var/iend = 1
			if(links)
				iend = findtext(info_links, "</span>", istart)
			else
				iend = findtext(info, "</span>", istart)

			//textindex = istart+26
			textindex = iend
			break

	if(links)
		var/before = copytext(info_links, 1, textindex)
		var/after = copytext(info_links, textindex)
		info_links = before + text + after
	else
		var/before = copytext(info, 1, textindex)
		var/after = copytext(info, textindex)
		info = before + text + after
		updateinfolinks()

/obj/item/weapon/paper/proc/updateinfolinks()
	info_links = info
	var/i = 0
	for(i=1,i<=fields,i++)
		if(i>=50)
			break //abandon ship
		if(i%25 == 0)
			sleep(1)
		addtofield(i, "<A href='?src=\ref[src];write=[i]'>write</A> ", 1)
		addtofield(i, "<A href='?src=\ref[src];help=[i]'>help</A> ", 1)
	info_links +="<A href='?src=\ref[src];write=end'>write</A> "
	info_links +="<A href='?src=\ref[src];help=end'>help</A> "

/obj/item/weapon/paper/proc/clearpaper()
	info = null
	stamps = null
	stamped = list()
	overlays.len = 0
	updateinfolinks()
	update_icon()
	if(istype(loc, /obj/item/weapon/storage/bag/clipboard))
		var/obj/C = loc
		C.update_icon()

/obj/item/weapon/paper/proc/parsepencode(var/mob/user,var/obj/item/i, var/t)
	if(istype(i,/obj/item/weapon/pen))
		//t = parsepencode(t, i, usr, iscrayon) // Encode everything from pencode to html
		var/obj/item/weapon/pen/P=i
		t=P.Format(user,t,src)

	else if(istype(i,/obj/item/toy/crayon))
		var/obj/item/toy/crayon/C=i
		t=C.Format(user,t,src)

	return t


/obj/item/weapon/paper/proc/openhelp(mob/user as mob)
	user << browse({"<HTML><HEAD><TITLE>Pen Help</TITLE></HEAD>
	<BODY>
		<b><center>Crayon & Pen commands</center></b><br>
		<br>
		\[br\] : Creates a linebreak.<br>
		\[center\] - \[/center\] : Centers the text.<br>
		\[b\] - \[/b\] : Makes the text <b>bold</b>.<br>
		\[i\] - \[/i\] : Makes the text <i>italic</i>.<br>
		\[u\] - \[/u\] : Makes the text <u>underlined</u>.<br>
		\[large\] - \[/large\] : Increases the <span style=\"font-size:25px\">size</span> of the text.<br>
		\[table\] - \[/table\] : Creates table using \[row\] and \[cell\] tags.<br>
		\[row\] - Creates a new table row.<br>
		\[cell\] - Creates a new table cell.<br>
		\[sign\] : Inserts a signature of your name in a foolproof way.<br>
		\[field\] : Inserts an invisible field which lets you start type from there. Useful for forms.<br>
		\[date\] : Inserts the current date in the format DAY MONTH, YEAR.<br>
		\[time\] : Inserts the current station time.<br>
		<br>
		<b><center>Pen exclusive commands</center></b><br>
		\[small\] - \[/small\] : Decreases the <span style=\"font-size:15px\">size</span> of the text.<br>
		\[tiny\] - \[/tiny\] : Sharply decreases the <span style=\"font-size:10px\">size</span> of the text.<br>
		\[list\] - \[/list\] : A list.<br>
		\[*\] : A dot used for lists.<br>
		\[hr\] : Adds a horizontal rule.<br>
		\[img\]http://url\[/img\] : Add an image.<br>
		<br>
		<b><center>Fonts</center><br></b>
		\[agency\] - \[/agency\] : <span style=\"font-family:Agency FB\">Agency FB</span><br>
		\[algerian\] - \[/algerian\] : <span style=\"font-family:Algerian\">Algerian</span><br>
		\[arial\] - \[/arial\] : <span style=\"font-family:Arial\">Arial</span><br>
		\[arialb\] - \[/arialb\] : <span style=\"font-family:Arial Black\">Arial Black</span><br>
		\[calibri\] - \[/calibri\] : <span style=\"font-family:Calibri\">Calibri</span><br>
		\[courier\] - \[/courier\] : <span style=\"font-family:Courier\">Courier</span><br>
		\[helvetica\] - \[/helvetica\] : <span style=\"font-family:Helvetica\">Helvetica</span><br>
		\[impact\] - \[/impact\] : <span style=\"font-family:Impact\">Impact</span><br>
		\[palatino\] - \[/palatino\] : <span style=\"font-family:Palatino Linotype\">Palatino Linotype</span><br>
		\[tnr\] - \[/tnr\] : <span style=\"font-family:Times New Roman\">Times New Roman</span>

	</BODY></HTML>"}, "window=paper_help")

/obj/item/weapon/paper/Topic(href, href_list)
	..()
	if(!usr || (usr.stat || usr.restrained()))
		return

	if(href_list["picture"])
		if(!ishigherbeing(usr))
			return
		var/mob/living/carbon/human/H = usr
		H.put_in_hands(img)
		img = null

	if(href_list["write"])
		var/id = href_list["write"]
		//var/t = utf8_sanitize(input(usr, "What text do you wish to add to " + (id=="end" ? "the end of the paper" : "field "+id) + "?", "[name]", null),8192) as message
		//var/t =  utf8_sanitize(input("Enter what you want to write:", "Write", null, null)  as message, MAX_MESSAGE_LEN)
		var/new_text

		//Wrap this part in a loop to prevent text from getting lost
		do
			new_text = sanitize(input("Enter what you want to write:", "Write", new_text) as null|message, MAX_MESSAGE_LEN)
			var/obj/item/i = usr.get_active_hand() // Check to see if he still got that darn pen, also check if he's using a crayon or pen.

			//The user either entered a non-value, or logged off
			if(isnull(new_text) || !usr.key)
				return

			//Not writing with a pen or crayon
			if(!istype(i,/obj/item/weapon/pen) && !istype(i,/obj/item/toy/crayon))
				to_chat(usr, "<span class='warning'>Please ensure your pen is in your active hand and that you're holding the paper.</span>")
				continue

			//Lost the paper or lost consciousness
			if(!Adjacent(usr, 1) || usr.isUnconscious()) //the 1 means that the paper can be in one other item and be written on
				to_chat(usr, "<span class='warning'>You are to unable to write on this paper.</span>")
				continue

		while(isnull(new_text))

		log += "<br />\[[time_stamp()]] [key_name(usr)] added: [new_text]"

		new_text = replacetext(new_text, "\n", "<BR>")

		spawn()
			new_text = parsepencode(usr, usr.get_active_hand() ,new_text)

			//Count the fields
			var/laststart = 1
			while(1)
				var/j = findtext(new_text, "<span class=\"paper_field\">", laststart)
				if(j==0)
					break
				laststart = j+1
				fields++

			if(id!="end")
				addtofield(text2num(id), new_text) // He wants to edit a field, let him.
			else
				info += new_text // Oh, he wants to edit to the end of the file, let him.
				updateinfolinks()

			show_text(usr, links = TRUE)

			update_icon()

			if(istype(loc, /obj/item/weapon/storage/bag/clipboard))
				var/obj/item/weapon/storage/bag/clipboard/C = loc
				C.update_icon()

	if(href_list["help"])
		openhelp(usr)


/obj/item/weapon/paper/attackby(obj/item/weapon/P as obj, mob/user as mob)
	..()

	if(istype(P, /obj/item/weapon/pen) || istype(P, /obj/item/toy/crayon))
		if ( istype(P, /obj/item/weapon/pen/robopen) && P:mode == 2 )
			P:RenamePaper(user,src)
		else
			show_text(user, links = TRUE)
		//openhelp(user)
		return

	else if(istype(P, /obj/item/weapon/stamp))
		var/obj/item/weapon/stamp/S = P
		S.try_stamp(user,src)
	else if(istype(P, /obj/item/weapon/photo) && !istype(src, /obj/item/weapon/paper/envelope))
		if(img)
			to_chat(user, "<span class='notice'>This paper already has a photo attached.</span>")
			return

		if(user.drop_item(P, src))
			img = P
			to_chat(user, "<span class='notice'>You attach the photo to the piece of paper.</span>")
	else if(P.is_hot())
		src.ashify_item(user)
		return 1 //no fingerprints, paper is gone
	add_fingerprint(user)
	return ..()

/obj/item/proc/ashify_item(mob/user)
	var/prot = 0
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		if (M_RESIST_HEAT in H.mutations)
			prot = 1
		else if(H.gloves)
			var/obj/item/clothing/gloves/G = H.gloves
			if(G.max_heat_protection_temperature)
				prot = (G.max_heat_protection_temperature > src.autoignition_temperature)
		if(!prot && clumsy_check(H) && prob(50)) //only fail if human
			H.apply_damage(10,BURN,(pick(LIMB_LEFT_HAND, LIMB_RIGHT_HAND)))
			user.drop_hands()
			user.visible_message( \
				"<span class='notice'>[user] tries to burn the [src.name], but burns \his hand trying!</span>", \
				"<span class='warning'>You try to burn the [src.name], but burn your hand trying!</span>")
			return //you fail before even managing to burn it!
	if(prot) //user is human and is protected from fire, let's make them a badass
		user.visible_message( \
			"<span class='warning'>[user] holds up the [src.name] and sets it on fire, holding it in \his hand as it burns down to ashes. Damn, \he's cold.</span>", \
			"<span class='warning'>You hold up the [src.name] and set it on fire, holding it in your hand as it burns down to ashes. Damn, you're cold.</span>")
	else
		user.visible_message( \
			"<span class='warning'>[user] holds up the [src.name] and sets it on fire, reducing it to a heap of ashes.</span>", \
			"<span class='warning'>You hold up the [src.name] and set it on fire, reducing it to a heap of ashes.</span>")
	var/ashtype = ashtype()
	new ashtype(get_turf(src)) //not using ashify() since it calls for src.loc rather than get_turf(src), and requires the object to be on fire also
	qdel(src)
	return

var/global/list/paper_folding_results = list ( \
	"ball of paper" = /obj/item/weapon/p_folded/ball,
	"paper plane" = /obj/item/weapon/p_folded/plane,
	"paper hat" = /obj/item/weapon/p_folded/hat,
	"folded note" = /obj/item/weapon/p_folded/note_small,
	"origami crane" = /obj/item/weapon/p_folded/crane,
	"origami boat" = /obj/item/weapon/p_folded/boat,
	"origami heart" = /obj/item/weapon/p_folded/folded_heart,
	"envelope" = /obj/item/weapon/paper/envelope,
	)

/obj/item/weapon/paper/verb/fold()
	set category = "Object"
	set name = "Fold paper"
	set src in usr

	if (!canfold(usr))
		return
	var/foldtype = paper_folding_results[input("What do you want to make the paper into?", "Paper Folding") as null|anything in paper_folding_results]
	if (!foldtype)
		return
	if (!canfold(usr))
		return //second check in case some chucklefuck moves the paper or falls down while the menu is open

	usr.drop_item(src, force_drop = 1)	//Drop the original paper to free our hand and call proper inventory handling code
	var/obj/item/P
	if(ispath(foldtype, /obj/item/weapon/p_folded))
		P = new foldtype(get_turf(src), unfolds_into = src) //Let's make a new item that unfolds into the original paper
	else
		P = new foldtype(get_turf(src))
	src.forceMove(P)	//and also contains it, for good measure.
	usr.put_in_hands(P)
	P.pixel_y = src.pixel_y
	P.pixel_x = src.pixel_x
	if (istype(src, /obj/item/weapon/paper/nano))
		P.color = "#9A9A9A"
		if(istype(P, /obj/item/weapon/p_folded))
			var/obj/item/weapon/p_folded/pf = P
			pf.nano = 1
	usr.visible_message("<span class='notice'>[usr] folds \the [src.name] into a [P.name].</span>", "<span class='notice'>You fold \the [src.name] into a [P.name].</span>")
	transfer_fingerprints(src, P)
	return

/obj/item/weapon/paper/proc/canfold(mob/user)
	if(!user)
		return 0
	if(user.stat || user.restrained())
		to_chat(user, "<span class='notice'>You can't do that while restrained.</span>")
		return 0
	if(!user.is_holding_item(src))
		to_chat(user, "<span class='notice'>You'll need [src] in your hands to do that.</span>")
		return 0
	return 1

/obj/item/weapon/paper/AltClick()
	if(is_holder_of(usr, src) && canfold(usr))
		fold()
	else
		return ..()


/obj/item/weapon/paper/proc/sudokize(var/color)
	var/list/sudokus = file2list("data/sudoku.txt")
	info = "<style>\
	td{width: 35px;height: 35px;border: 1px solid black;text-align: center;vertical-align: middle;font-family:Verdana, sans;color:[color];font-weight: bold;}\
	table{border: 3px solid black;}\
	</style>\
	<table cellpadding='0' cellspacing='0'>[pick(sudokus)]</table>"
	updateinfolinks()
	update_icon()

/*
 * Premade paper
 */
/obj/item/weapon/paper/Court
	name = "paper- 'Judgement'"
	info = "For crimes against the station, the offender is sentenced to:<BR>\n<BR>\n"

/obj/item/weapon/paper/Toxin
	name = "paper- 'Chemical Information'"
	info = "Known Onboard Toxins:<BR>\n\tGrade A Semi-Liquid Plasma:<BR>\n\t\tHighly poisonous. You cannot sustain concentrations above 15 units.<BR>\n\t\tA gas mask fails to filter plasma after 50 units.<BR>\n\t\tWill attempt to diffuse like a gas.<BR>\n\t\tFiltered by scrubbers.<BR>\n\t\tThere is a bottled version which is very different<BR>\n\t\t\tfrom the version found in canisters!<BR>\n<BR>\n\t\tWARNING: Highly Flammable. Keep away from heat sources<BR>\n\t\texcept in a enclosed fire area!<BR>\n\t\tWARNING: It is a crime to use this without authorization.<BR>\nKnown Onboard Anti-Toxin:<BR>\n\tAnti-Toxin Type 01P: Works against Grade A Plasma.<BR>\n\t\tBest if injected directly into bloodstream.<BR>\n\t\tA full injection is in every regular Med-Kit.<BR>\n\t\tSpecial toxin Kits hold around 7.<BR>\n<BR>\nKnown Onboard Chemicals (other):<BR>\n\tRejuvenation T#001:<BR>\n\t\tEven 1 unit injected directly into the bloodstream<BR>\n\t\t\twill cure paralysis and sleep toxins.<BR>\n\t\tIf administered to a dying patient it will prevent<BR>\n\t\t\tfurther damage for about units*3 seconds.<BR>\n\t\t\tit will not cure them or allow them to be cured.<BR>\n\t\tIt can be administeredd to a non-dying patient<BR>\n\t\t\tbut the chemicals disappear just as fast.<BR>\n\tSleep Toxin T#054:<BR>\n\t\t5 units wilkl induce precisely 1 minute of sleep.<BR>\n\t\t\tThe effect are cumulative.<BR>\n\t\tWARNING: It is a crime to use this without authorization"

/obj/item/weapon/paper/courtroom
	name = "paper- 'A Crash Course in Legal SOP on SS13'"
	info = "<B>Roles:</B><BR>\nThe Detective is basically the investigator and prosecutor.<BR>\nThe Staff Assistant can perform these functions with written authority from the Detective.<BR>\nThe Captain/HoP/Warden is ct as the judicial authority.<BR>\nThe Security Officers are responsible for executing warrants, security during trial, and prisoner transport.<BR>\n<BR>\n<B>Investigative Phase:</B><BR>\nAfter the crime has been committed the Detective's job is to gather evidence and try to ascertain not only who did it but what happened. He must take special care to catalogue everything and don't leave anything out. Write out all the evidence on paper. Make sure you take an appropriate number of fingerprints. IF he must ask someone questions he has permission to confront them. If the person refuses he can ask a judicial authority to write a subpoena for questioning. If again he fails to respond then that person is to be jailed as insubordinate and obstructing justice. Said person will be released after he cooperates.<BR>\n<BR>\nONCE the FT has a clear idea as to who the criminal is he is to write an arrest warrant on the piece of paper. IT MUST LIST THE CHARGES. The FT is to then go to the judicial authority and explain a small version of his case. If the case is moderately acceptable the authority should sign it. Security must then execute said warrant.<BR>\n<BR>\n<B>Pre-Pre-Trial Phase:</B><BR>\nNow a legal representative must be presented to the defendant if said defendant requests one. That person and the defendant are then to be given time to meet (in the jail IS ACCEPTABLE). The defendant and his lawyer are then to be given a copy of all the evidence that will be presented at trial (rewriting it all on paper is fine). THIS IS CALLED THE DISCOVERY PACK. With a few exceptions, THIS IS THE ONLY EVIDENCE BOTH SIDES MAY USE AT TRIAL. IF the prosecution will be seeking the death penalty it MUST be stated at this time. ALSO if the defense will be seeking not guilty by mental defect it must state this at this time to allow ample time for examination.<BR>\nNow at this time each side is to compile a list of witnesses. By default, the defendant is on both lists regardless of anything else. Also the defense and prosecution can compile more evidence beforehand BUT in order for it to be used the evidence MUST also be given to the other side.\nThe defense has time to compile motions against some evidence here.<BR>\n<B>Possible Motions:</B><BR>\n1. <U>Invalidate Evidence-</U> Something with the evidence is wrong and the evidence is to be thrown out. This includes irrelevance or corrupt security.<BR>\n2. <U>Free Movement-</U> Basically the defendant is to be kept uncuffed before and during the trial.<BR>\n3. <U>Subpoena Witness-</U> If the defense presents god reasons for needing a witness but said person fails to cooperate then a subpoena is issued.<BR>\n4. <U>Drop the Charges-</U> Not enough evidence is there for a trial so the charges are to be dropped. The FT CAN RETRY but the judicial authority must carefully reexamine the new evidence.<BR>\n5. <U>Declare Incompetent-</U> Basically the defendant is insane. Once this is granted a medical official is to examine the patient. If he is indeed insane he is to be placed under care of the medical staff until he is deemed competent to stand trial.<BR>\n<BR>\nALL SIDES MOVE TO A COURTROOM<BR>\n<B>Pre-Trial Hearings:</B><BR>\nA judicial authority and the 2 sides are to meet in the trial room. NO ONE ELSE BESIDES A SECURITY DETAIL IS TO BE PRESENT. The defense submits a plea. If the plea is guilty then proceed directly to sentencing phase. Now the sides each present their motions to the judicial authority. He rules on them. Each side can debate each motion. Then the judicial authority gets a list of crew members. He first gets a chance to look at them all and pick out acceptable and available jurors. Those jurors are then called over. Each side can ask a few questions and dismiss jurors they find too biased. HOWEVER before dismissal the judicial authority MUST agree to the reasoning.<BR>\n<BR>\n<B>The Trial:</B><BR>\nThe trial has three phases.<BR>\n1. <B>Opening Arguments</B>- Each side can give a short speech. They may not present ANY evidence.<BR>\n2. <B>Witness Calling/Evidence Presentation</B>- The prosecution goes first and is able to call the witnesses on his approved list in any order. He can recall them if necessary. During the questioning the lawyer may use the evidence in the questions to help prove a point. After every witness the other side has a chance to cross-examine. After both sides are done questioning a witness the prosecution can present another or recall one (even the EXACT same one again!). After prosecution is done the defense can call witnesses. After the initial cases are presented both sides are free to call witnesses on either list.<BR>\nFINALLY once both sides are done calling witnesses we move onto the next phase.<BR>\n3. <B>Closing Arguments</B>- Same as opening.<BR>\nThe jury then deliberates IN PRIVATE. THEY MUST ALL AGREE on a verdict. REMEMBER: They mix between some charges being guilty and others not guilty (IE if you supposedly killed someone with a gun and you unfortunately picked up a gun without authorization then you CAN be found not guilty of murder BUT guilty of possession of illegal weaponry.). Once they have agreed they present their verdict. If unable to reach a verdict and feel they will never they call a deadlocked jury and we restart at Pre-Trial phase with an entirely new set of jurors.<BR>\n<BR>\n<B>Sentencing Phase:</B><BR>\nIf the death penalty was sought (you MUST have gone through a trial for death penalty) then skip to the second part. <BR>\nI. Each side can present more evidence/witnesses in any order. There is NO ban on emotional aspects or anything. The prosecution is to submit a suggested penalty. After all the sides are done then the judicial authority is to give a sentence.<BR>\nII. The jury stays and does the same thing as I. Their sole job is to determine if the death penalty is applicable. If NOT then the judge selects a sentence.<BR>\n<BR>\nTADA you're done. Security then executes the sentence and adds the applicable convictions to the person's record.<BR>\n"

/obj/item/weapon/paper/hydroponics
	name = "paper- 'Greetings from Billy Bob'"
	info = "<B>Hey fellow botanist!</B><BR>\n<BR>\nI didn't trust the station folk so I left<BR>\na couple of weeks ago. But here's some<BR>\ninstructions on how to operate things here.<BR>\nYou can grow plants and each iteration they become<BR>\nstronger, more potent and have better yield, if you<BR>\nknow which ones to pick. Use your botanist's analyzer<BR>\nfor that. You can turn harvested plants into seeds<BR>\nat the seed extractor, and replant them for better stuff!<BR>\nSometimes if the weed level gets high in the tray<BR>\nmutations into different mushroom or weed species have<BR>\nbeen witnessed. On the rare occassion even weeds mutate!<BR>\n<BR>\nEither way, have fun!<BR>\n<BR>\nBest regards,<BR>\nBilly Bob Johnson.<BR>\n<BR>\nPS.<BR>\nHere's a few tips:<BR>\nIn nettles, potency = damage<BR>\nIn amanitas, potency = deadliness + side effect<BR>\nIn Liberty caps, potency = drug power + effect<BR>\nIn chilis, potency = heat<BR>\n<B>Nutrients keep mushrooms alive!</B><BR>\n<B>Water keeps weeds such as nettles alive!</B><BR>\n<B>All other plants need both.</B>"

/obj/item/weapon/paper/djstation
	name = "paper - 'DJ Listening Outpost'"

/obj/item/weapon/paper/djstation/initialize()
	..()
	info = "<B>Welcome new owner!</B><BR><BR>You have purchased the latest in listening equipment. The telecommunication setup we created is the best in listening to common and private radio fequencies. Here is a step by step guide to start listening in on those saucy radio channels:<br>\
	<ol>\
		<li>Equip yourself with a multi-tool</li>\
		<li>Use the multitool on each machine, that is the broadcaster, receiver and the relay.</li>\
		<li>Turn all the machines on, it has already been configured for you to listen on.</li>\
	</ol> Simple as that. Now to listen to the private channels, you'll have to configure the intercoms, located on the front desk. \
	\
	Here is a list of frequencies for you to listen on.<br>\
	<ul>\
		<li>[COMMON_FREQ] - Common Channel</li>\
		<li>[AIPRIV_FREQ] - Private AI Channel</li>\
		<li>[SEC_FREQ] - Security Channel</li>\
		<li>[ENG_FREQ] - Engineering Channel</li>\
		<li>[MED_FREQ] - Medical Channel</li>\
		<li>[COMM_FREQ] - Command Channel</li>\
		<li>[SCI_FREQ] - Science Channel</li>\
		<li>[SER_FREQ] - Service Channel</li>\
		<li>[SUP_FREQ] - Supply Channel</li>"

/obj/item/weapon/paper/intercoms
	name = "paper - 'Ace Reporter Intercom manual'"

/obj/item/weapon/paper/intercoms/initialize()
	..()
	info = "<B>Welcome new owner!</B><BR><BR>You have purchased the latest in listening equipment. The telecommunication setup we created is the best in listening to common and private radio frequencies.Now to listen to the private channels, you'll have to configure the intercoms.<br>\
	Here is a list of frequencies for you to listen on.<br>\
	<ul>\
		<li>[COMMON_FREQ] - Common Channel</li>\
		<li>[AIPRIV_FREQ] - Private AI Channel</li>\
		<li>[SEC_FREQ] - Security Channel</li>\
		<li>[ENG_FREQ] - Engineering Channel</li>\
		<li>[MED_FREQ] - Medical Channel</li>\
		<li>[COMM_FREQ] - Command Channel</li>\
		<li>[SCI_FREQ] - Science Channel</li>\
		<li>[SER_FREQ] - Service Channel</li>\
		<li>[SUP_FREQ] - Supply Channel</li>"

/obj/item/weapon/paper/flag
	icon_state = "flag_neutral"
	item_state = "paper"
	anchored = 1.0

/obj/item/weapon/paper/jobs
	name = "paper- 'Job Information'"
	info = "Information on all formal jobs that can be assigned on Space Station 13 can be found on this document.<BR>\nThe data will be in the following form.<BR>\nGenerally lower ranking positions come first in this list.<BR>\n<BR>\n<B>Job Name</B>   general access>lab access-engine access-systems access (atmosphere control)<BR>\n\tJob Description<BR>\nJob Duties (in no particular order)<BR>\nTips (where applicable)<BR>\n<BR>\n<B>Research Assistant</B> 1>1-0-0<BR>\n\tThis is probably the lowest level position. Anyone who enters the space station after the initial job\nassignment will automatically receive this position. Access with this is restricted. Head of Personnel should\nappropriate the correct level of assistance.<BR>\n1. Assist the researchers.<BR>\n2. Clean up the labs.<BR>\n3. Prepare materials.<BR>\n<BR>\n<B>Staff Assistant</B> 2>0-0-0<BR>\n\tThis position assists the security officer in his duties. The staff assisstants should primarily br\npatrolling the ship waiting until they are needed to maintain ship safety.\n(Addendum: Updated/Elevated Security Protocols admit issuing of low level weapons to security personnel)<BR>\n1. Patrol ship/Guard key areas<BR>\n2. Assist security officer<BR>\n3. Perform other security duties.<BR>\n<BR>\n<B>Technical Assistant</B> 1>0-0-1<BR>\n\tThis is yet another low level position. The technical assistant helps the engineer and the statian\ntechnician with the upkeep and maintenance of the station. This job is very important because it usually\ngets to be a heavy workload on station technician and these helpers will alleviate that.<BR>\n1. Assist Station technician and Engineers.<BR>\n2. Perform general maintenance of station.<BR>\n3. Prepare materials.<BR>\n<BR>\n<B>Medical Assistant</B> 1>1-0-0<BR>\n\tThis is the fourth position yet it is slightly less common. This position doesn't have much power\noutside of the med bay. Consider this position like a nurse who helps to upkeep medical records and the\nmaterials (filling syringes and checking vitals)<BR>\n1. Assist the medical personnel.<BR>\n2. Update medical files.<BR>\n3. Prepare materials for medical operations.<BR>\n<BR>\n<B>Research Technician</B> 2>3-0-0<BR>\n\tThis job is primarily a step up from research assistant. These people generally do not get their own lab\nbut are more hands on in the experimentation process. At this level they are permitted to work as consultants to\nthe others formally.<BR>\n1. Inform superiors of research.<BR>\n2. Perform research alongside of official researchers.<BR>\n<BR>\n<B>Detective</B> 3>2-0-0<BR>\n\tThis job is in most cases slightly boring at best. Their sole duty is to\nperform investigations of crine scenes and analysis of the crime scene. This\nalleviates SOME of the burden from the security officer. This person's duty\nis to draw conclusions as to what happened and testify in court. Said person\nalso should stroe the evidence ly.<BR>\n1. Perform crime-scene investigations/draw conclusions.<BR>\n2. Store and catalogue evidence properly.<BR>\n3. Testify to superiors/inquieries on findings.<BR>\n<BR>\n<B>Station Technician</B> 2>0-2-3<BR>\n\tPeople assigned to this position must work to make sure all the systems aboard Space Station 13 are operable.\nThey should primarily work in the computer lab and repairing faulty equipment. They should work with the\natmospheric technician.<BR>\n1. Maintain SS13 systems.<BR>\n2. Repair equipment.<BR>\n<BR>\n<B>Atmospheric Technician</B> 3>0-0-4<BR>\n\tThese people should primarily work in the atmospheric control center and lab. They have the very important\njob of maintaining the delicate atmosphere on SS13.<BR>\n1. Maintain atmosphere on SS13<BR>\n2. Research atmospheres on the space station. (safely please!)<BR>\n<BR>\n<B>Engineer</B> 2>1-3-0<BR>\n\tPeople working as this should generally have detailed knowledge as to how the propulsion systems on SS13\nwork. They are one of the few classes that have unrestricted access to the engine area.<BR>\n1. Upkeep the engine.<BR>\n2. Prevent fires in the engine.<BR>\n3. Maintain a safe orbit.<BR>\n<BR>\n<B>Medical Researcher</B> 2>5-0-0<BR>\n\tThis position may need a little clarification. Their duty is to make sure that all experiments are safe and\nto conduct experiments that may help to improve the station. They will be generally idle until a new laboratory\nis constructed.<BR>\n1. Make sure the station is kept safe.<BR>\n2. Research medical properties of materials studied of Space Station 13.<BR>\n<BR>\n<B>Scientist</B> 2>5-0-0<BR>\n\tThese people study the properties, particularly the toxic properties, of materials handled on SS13.\nTechnically they can also be called Plasma Technicians as plasma is the material they routinly handle.<BR>\n1. Research plasma<BR>\n2. Make sure all plasma is properly handled.<BR>\n<BR>\n<B>Medical Doctor (Officer)</B> 2>0-0-0<BR>\n\tPeople working this job should primarily stay in the medical area. They should make sure everyone goes to\nthe medical bay for treatment and examination. Also they should make sure that medical supplies are kept in\norder.<BR>\n1. Heal wounded people.<BR>\n2. Perform examinations of all personnel.<BR>\n3. Moniter usage of medical equipment.<BR>\n<BR>\n<B>Security Officer</B> 3>0-0-0<BR>\n\tThese people should attempt to keep the peace inside the station and make sure the station is kept safe. One\nside duty is to assist in repairing the station. They also work like general maintenance personnel. They are not\ngiven a weapon and must use their own resources.<BR>\n(Addendum: Updated/Elevated Security Protocols admit issuing of weapons to security personnel)<BR>\n1. Maintain order.<BR>\n2. Assist others.<BR>\n3. Repair structural problems.<BR>\n<BR>\n<B>Head of Security</B> 4>5-2-2<BR>\n\tPeople assigned as Head of Security should issue orders to the security staff. They should\nalso carefully moderate the usage of all security equipment. All security matters should be reported to this person.<BR>\n1. Oversee security.<BR>\n2. Assign patrol duties.<BR>\n3. Protect the station and staff.<BR>\n<BR>\n<B>Head of Personnel</B> 4>4-2-2<BR>\n\tPeople assigned as head of personnel will find themselves moderating all actions done by personnel. \nAlso they have the ability to assign jobs and access levels.<BR>\n1. Assign duties.<BR>\n2. Moderate personnel.<BR>\n3. Moderate research. <BR>\n<BR>\n<B>Captain</B> 5>5-5-5 (unrestricted station wide access)<BR>\n\tThis is the highest position youi can aquire on Space Station 13. They are allowed anywhere inside the\nspace station and therefore should protect their ID card. They also have the ability to assign positions\nand access levels. They should not abuse their power.<BR>\n1. Assign all positions on SS13<BR>\n2. Inspect the station for any problems.<BR>\n3. Perform administrative duties.<BR>\n"

/obj/item/weapon/paper/photograph
	name = "photo"
	icon_state = "photo"
	var/photo_id = 0.0
	item_state = "paper"

/obj/item/weapon/paper/sop
	name = "paper- 'Standard Operating Procedure'"
	info = "Alert Levels:<BR>\nBlue- Emergency<BR>\n\t1. Caused by fire<BR>\n\t2. Caused by manual interaction<BR>\n\tAction:<BR>\n\t\tClose all fire doors. These can only be opened by reseting the alarm<BR>\nRed- Ejection/Self Destruct<BR>\n\t1. Caused by module operating computer.<BR>\n\tAction:<BR>\n\t\tAfter the specified time the module will eject completely.<BR>\n<BR>\nEngine Maintenance Instructions:<BR>\n\tShut off ignition systems:<BR>\n\tActivate internal power<BR>\n\tActivate orbital balance matrix<BR>\n\tRemove volatile liquids from area<BR>\n\tWear a fire suit<BR>\n<BR>\n\tAfter<BR>\n\t\tDecontaminate<BR>\n\t\tVisit medical examiner<BR>\n<BR>\nToxin Laboratory Procedure:<BR>\n\tWear a gas mask regardless<BR>\n\tGet an oxygen tank.<BR>\n\tActivate internal atmosphere<BR>\n<BR>\n\tAfter<BR>\n\t\tDecontaminate<BR>\n\t\tVisit medical examiner<BR>\n<BR>\nDisaster Procedure:<BR>\n\tFire:<BR>\n\t\tActivate sector fire alarm.<BR>\n\t\tMove to a safe area.<BR>\n\t\tGet a fire suit<BR>\n\t\tAfter:<BR>\n\t\t\tAssess Damage<BR>\n\t\t\tRepair damages<BR>\n\t\t\tIf needed, Evacuate<BR>\n\tMeteor Shower:<BR>\n\t\tActivate fire alarm<BR>\n\t\tMove to the back of ship<BR>\n\t\tAfter<BR>\n\t\t\tRepair damage<BR>\n\t\t\tIf needed, Evacuate<BR>\n\tAccidental Reentry:<BR>\n\t\tActivate fire alrms in front of ship.<BR>\n\t\tMove volatile matter to a fire proof area!<BR>\n\t\tGet a fire suit.<BR>\n\t\tStay secure until an emergency ship arrives.<BR>\n<BR>\n\t\tIf ship does not arrive-<BR>\n\t\t\tEvacuate to a nearby safe area!"

/obj/item/weapon/paper/crumpled
	name = "paper scrap"
	icon_state = "scrap"

/obj/item/weapon/paper/crumpled/update_icon()
	return

/obj/item/weapon/paper/crumpled/bloody
	icon_state = "scrap_bloodied"

/obj/item/weapon/paper/voxresearch/voxresearchclosure
	name = "paper- 'Shutting Down'"
	info = "The recent attack has left us in a more unstable position than we initially assumed.  Both major contracts have been canceled and we are mothballing the facility.  Evacuate and take the fax machine with you.  It costs more to replace it than it does you."

/obj/item/weapon/paper/voxresearch/voxresearch1
	name = "paper- 'Two new contracts'"
	info = "The research station in this quadrant has outsourced initial research into plasma reanimation studies.  Focus on performing the experiments they've contracted us to do.  Do not ask questions."

/obj/item/weapon/paper/voxresearch/voxresearch2
	name = "paper- 'Two new contracts'"
	info = "REDACTED has tasked us to investigate the sentience of REDACTED.  Observe the subjects and evaluate their genetic markers and anatomical structure.  And for christs sake stop using Mr. Muggles DNA on test subjects.  You are not paid to and it is not recommended.  You're facing review."

/obj/item/weapon/paper/voxresearch/voxtradeden
	name = "paper- 'Good spot'"
	info = "We set up here.  No one will look for us here and we can sell wares to eggheads at NT."

/obj/item/weapon/paper/voxresearch/voxresearchescape
	name = "paper- 'Recent Attack'"
	info = "We still do not know who were responsible for the recent attack and escape of several test subjects.  The initial investigation points to the Syndicate but we cannot say for sure at this time.  This has violated our contract with REDACTED and REDACTED.  We may have to close the facility. "

/obj/item/weapon/paper/suitdispenser
	name = "paper- 'Suit Dispenser Manual - How to use them?'"
	info = "Step 1: Place the items that you want the dispenser to dispense on top of one of them, preferably the one below this paper.<BR>\nStep 2: Click the dispenser, and choose <b>Define Preset from items on top</b>.<BR>\nStep 3: Click every dispenser you wish to see dispensing, and click <b>Choose a Preset</b>.<BR>\nTo re-use a dispenser, just click <b>Resupply</b>."

/obj/item/weapon/paper/diy_soda
	name = "paper- 'Instructions'"
	info = "Thank you for purchasing Dr. Pecker's DIY Soda Kit!<BR>\nIt has been scientifically proven to bring your tastebuds into the delicious state and turn your teeth into a molar solution!<BR>\nNow as you may have guessed, you will have to mix this delicious beverage yourself.<BR>\nDon't worry, it's pretty basic stuff. Just remember to never lick the spoon!<BR>\nFirst, mix the contents of all three <b>small vials</b> into the <b>large flask</b>.<BR>\nThen, mix the contents of the <b>small flasks</b> into the <b>large flask</b>.<BR>\nAnd finally, get ready for our secret trademarked ingredient: <BR>\n<b>The element of surprise!</b>"

/obj/item/weapon/paper/spectrometry_decommission
	name = "paper- 'Re:Spectrometry Decommission'"
	info = "The mulebots have finished carrying out the last packs of floor tiles and furnitures from the lab. It was always a matter of time given how little results we got from mass spectrometry, despite how interesting the technology seemed at first.<br>I cannot blame Nanotrasen given the advances in the anomalous energies field, this is definitely a much better investment.<br>I'm not sure where I'll be working now that my contract is over, I think I'll stay at Central Command for the foreseeable future, their testing facilities have a pretty high turnover rate I hear. Please do come say hello the next time you're there!<br><br><i>W.R.</i>"

/obj/item/weapon/paper/outoforder
	name = "paper- 'OUT OF ORDER'"
	info = "<B>OUT OF ORDER</B>"
	
/obj/item/weapon/paper/time_agent
	name = "paper- 'Personal Log - John Beckett'"
	info = "This timeline is doomed. No matter how many alternatives I explore, they all point <b>Back to the Future</b> we must avoid at all costs. Thus, only one solution remains - I must take a <b>Quantum Leap</b> and <b>TimeShift</b> back to the point before the activation of the <b>Chrono Trigger</b> that set us on this calamitous course of history. It may just be a <b>Final Fantasy</b> of mine, but I believe that if I can change the past, I can stop the <b>Doctor Who</b> opened <b>Steins Gate</b> and restore hope to the <b>Outer Wilds</b>, even if it means becoming a <b>Timesplitter</b> in doing so. - <i>John Beckett</i>"

/obj/item/weapon/paper/manifest
	name = "Supply Manifest"

/obj/item/weapon/paper/anomaly
	name = "Anomaly Report"
	var/obj/machinery/artifact/artifact

/obj/item/weapon/paper/anomaly/Destroy()
	artifact = null
	..()

/obj/item/weapon/paper/merchant
	var/identity
	var/list/mugshots = list()
	var/icon_updates = FALSE
	display_y = 500

/obj/item/weapon/paper/merchant/update_icon()
	if(icon_updates)
		..()

/obj/item/weapon/paper/merchant/New(loc,mob/living/carbon/human/merchant)
	if(merchant)
		merchant.client.prefs.update_preview_icon(0) //This is necessary because if they don't check their character sheet it never generates!
		mugshots += fcopy_rsc(merchant.client.prefs.preview_icon_front)
		mugshots += fcopy_rsc(merchant.client.prefs.preview_icon_side)
		apply_text(merchant)
	..()

/obj/item/weapon/paper/merchant/show_text(var/mob/user, var/links = FALSE, var/starred = FALSE)
	var/index = 1
	for(var/image in mugshots)
		user << browse_rsc(image, "previewicon-[identity][index].png")
		index++
	..()

/obj/item/weapon/paper/merchant/proc/apply_text(mob/living/carbon/human/merchant)
	identity = merchant.client.prefs.real_name
	icon = 'icons/obj/items.dmi'
	icon_state = "permit"
	name = "Merchant's Licence - [identity]"
	info = {"<html><style>
			body {color: #000000; background: #ffff0d;}
			h1 {color: #000000; font-size:30px;}
			fieldset {width:140px;}
			</style>
			<body>
			<center><img src="http://ss13.moe/wiki/images/1/17/NanoTrasen_Logo.png"> <h1>Merchant's Licence</h1></center>
			Nanotrasen\'s commercial arm has authorized commercial activity for a merchant who holds a licence for corporate commerce, a process which includes a background check and Nanotrasen loyalty implant. The associate\'s image is displayed below.<BR>
			<fieldset>
	  		<legend>Picture</legend>
			<center><img src="previewicon-[identity]1.png" width="64" height="64"><img src="previewicon-[identity]2.png" width="64" height="64"></center>
			</fieldset><BR>
			Name: [identity]<BR>
			Blood Type: [merchant.dna.b_type]<BR>
			Fingerprint: [md5(merchant.dna.uni_identity)]</body></html>"}

/obj/item/weapon/paper/merchant/report
	icon_updates = TRUE
	display_y = 700

/obj/item/weapon/paper/merchant/report/apply_text(mob/living/carbon/human/merchant)
	identity = merchant.client.prefs.real_name
	name = "Licensed Merchant Report - [identity]"
	info = {"<html><style>
			body {color: #000000; background: #ccffff;}
			h1 {color: #000000; font-size:30px;}
			fieldset {width:140px;}
			</style>
			<body>
			<center><img src="http://ss13.moe/wiki/images/1/17/NanoTrasen_Logo.png"> <h1>ATTN: Internal Affairs</h1></center>
			Nanotrasen\'s commercial arm has noted the presence of a registered merchant who holds a licence for corporate commerce, a process which includes a background check and Nanotrasen loyalty implant. The associate\'s image is enclosed. Please continue to monitor trade on an ongoing basis such that Nanotrasen can maintain highest standard small business enterprise (SBE) partners.<BR>
			<fieldset>
	  		<legend>Picture</legend>
			<center><img src="previewicon-[identity]1.png" width="64" height="64"><img src="previewicon-[identity]2.png" width="64" height="64"></center>
			</fieldset><BR>
			Name: [identity]<BR>
			Blood Type: [merchant.dna.b_type]<BR>
			Fingerprint: [md5(merchant.dna.uni_identity)]</body></html>"}
	CentcommStamp(src)

/obj/item/weapon/paper/traderapplication
	name = "trader application"
	display_x = 500
	display_y = 600
	var/applicant

/obj/item/weapon/paper/traderapplication/New(loc,var/newapp)
	..()
	applicant = newapp
	if(!applicant)
		qdel(src)
	info = {"<html><style>
						body {color: #000000; background: #e7c9a9;}
						h1 {color: #4444ee; font-size:30px;}
  						h2 {color: #4444ee; font-size:14px}
						fieldset {width:140px;}
						</style>
						<body>
						<center><img src="https://ss13.moe/wiki/images/9/92/Shoal-logo.png"> <h1>Trade Pact</h1></center>
						<h2>
                          I, the inker, do solemnly vow that [applicant] (hereafter 'Applicant') can be trusted. By blood and claw, responsibility for this one is bound in blood to me.<BR>
                          <B>JURISDICTION.</B> Disputes related to this contract will be brought before the Shoal Trade Council.<BR>
                          <B>SCOPE.</B> Provisional licensure as a trader shall last the duration of this shift and apply to this sector.<BR>
                          <B>INDEMNIFICATION.</B> The applicant waives legal rights against the Shoal, holding it harmless against all indemnification. Traders are independent contractors and the shoal does not accept responsibility for their actions.<BR>
                          <B>CONFIDENTIALITY.</B> The applicant vows to uphold all Shoal trade secrets.<BR>
                          <B>ASSIGNMENT.</B> The Shoal retains all rights related to its intellectual properties. This contract is not to be construed as a release of IP rights.<BR>
                          <B>ARBITRATION.</B> The applicant is entitled to settle legal disputes before a Shoal Arbitration Flock and must seek this remedy before formal lawsuit.<BR>
                          <B>NOTICE.</B> Notice of intent to dissolve relationship must be given by fax with at least one day advance notice.<BR>
                          <B>FORCE MAJEURE.</B> This contract may be voided if the trade outpost is destroyed.
                         </h2> <BR></body></html>"}
