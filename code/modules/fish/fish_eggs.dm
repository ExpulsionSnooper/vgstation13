/obj/item/fish_eggs
	name = "fish eggs"
	desc = "Eggs laid by a fish. This cluster seems... empty?"
	icon = 'icons/obj/fish_items.dmi'
	icon_state = "eggs"
	w_class = W_CLASS_SMALL
	var/fish_type = "dud"
	var/acidic = FALSE
	var/hatching = TRUE

/obj/item/fish_eggs/New()
	..()

/obj/item/fish_eggs/goldfish
	name = "goldfish eggs"
	desc = "Goldfish eggs, surprisingly, don't contain actual gold."
	icon_state = "gold_eggs"
	fish_type = "goldfish"

/obj/item/fish_eggs/clownfish
	name = "clownfish eggs"
	desc = "Even as eggs, they are funnier than the clown. HONK!"
	icon_state = "clown_eggs"
	fish_type = "clownfish"

/obj/item/fish_eggs/shark
	name = "shark eggs"
	desc = "We're gonna need a- Oh wait, they're still eggs."
	icon_state = "shark_eggs"
	fish_type = "shark"

/*/obj/item/fish_eggs/babycarp
	name = "baby space carp eggs"
	desc = "Eggs from the substantially smaller form of the intergalactic terror."
	icon_state = "babycarp_eggs"
	fish_type = "baby space carp"*/

/obj/item/fish_eggs/catfish
	name = "catfish eggs"
	desc = "A bottom-feeding species noted for their similarity to cats and Tajaran."
	icon_state = "catfish_eggs"
	fish_type = "catfish"

/obj/item/fish_eggs/feederfish
	name = "feeder fish eggs"
	desc = "These generic fish are commonly found being eaten by larger fish."
	icon_state = "feederfish_eggs"
	fish_type = "feederfish"

/obj/item/fish_eggs/salmon
	name = "salmon eggs"
	desc = "A collection of salmon eggs."
	icon_state = "salmon_eggs"
	fish_type = "salmon"

/obj/item/fish_eggs/shrimp
	name = "shrimp eggs"
	desc = "Eggs for shrimp. You figured they'd be smaller though..."
	icon_state = "shrimp_eggs"
	fish_type = "shrimp"

/obj/item/fish_eggs/electric_eel
	name = "electric eel eggs"
	desc = "A pile of eggs for a slimy, shocking, sea-serpent."
	icon_state = "electric_eel_eggs"
	fish_type = "electric eel"

/obj/item/fish_eggs/glofish
	name = "glofish eggs"
	desc = "A cluster of bright neon eggs belonging to a bio-luminescent species of fish."
	icon_state = "glofish_eggs"
	fish_type = "glofish"

/obj/item/fish_eggs/seadevil
	name = "sea devil"
	desc = "An aquatic offshoot of gremlins that engage in the peculiar behavior of hatching fish eggs to eat mature adults."
	icon_state = "seadevil"
	fish_type = "sea devil"
	hatching = FALSE

/obj/item/fish_eggs/lobster
	name = "lobster eggs"
	desc = "A clutch of reddish-orange eggs, belonging to lobsters."
	icon_state = "catfish_eggs"
	fish_type = "lobster"

/obj/item/fish_eggs/seadevil/New()
	..()
	processing_objects += src

/obj/item/fish_eggs/seadevil/process()
	if(istype(loc, /turf) && prob(60))
		Move(get_step(loc, pick(cardinal)))