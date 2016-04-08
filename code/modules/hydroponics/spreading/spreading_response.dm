/obj/effect/plant/HasProximity(var/atom/movable/AM)

	if(!is_mature() || seed.get_trait(TRAIT_SPREAD) != 2)
		return

	var/mob/living/M = AM
	if(!istype(M))
		return

	if(!buckled_mob && !M.buckled && !M.anchored && (issmall(M) || prob(round(seed.get_trait(TRAIT_POTENCY)/6))))
		//wait a tick for the Entered() proc that called HasProximity() to finish (and thus the moving animation),
		//so we don't appear to teleport from two tiles away when moving into a turf adjacent to vines.
		spawn(1)
			entangle(M)

/obj/effect/plant/attack_hand(var/mob/user)
	manual_unbuckle(user)

/obj/effect/plant/attack_generic(var/mob/user)
	if(istype(user))
		manual_unbuckle(user)

/obj/effect/plant/proc/trodden_on(var/mob/living/victim)
	if(!is_mature())
		return
	var/mob/living/carbon/human/H = victim
	if(prob(round(seed.get_trait(TRAIT_POTENCY)/4)))
		entangle(victim)
	if(istype(H) && H.shoes)
		return
	seed.do_thorns(victim,src)
	seed.do_sting(victim,src,pick("r_foot","l_foot","r_leg","l_leg"))

/obj/effect/plant/proc/unbuckle()
	if(buckled_mob)
		if(buckled_mob.buckled == src)
			buckled_mob.buckled = null
			buckled_mob.anchored = initial(buckled_mob.anchored)
			buckled_mob.update_canmove()
		buckled_mob = null
	return

/obj/effect/plant/proc/manual_unbuckle(mob/user as mob)
	if(buckled_mob)
		var/fail_chance = 50
		if(seed)
			fail_chance = seed.get_trait(TRAIT_POTENCY) * (user == buckled_mob ? 5 : 2)
		if(prob(100 - fail_chance))
			if(buckled_mob != user)
				buckled_mob.visible_message(\
					"<span class='notice'>\The [user.name] frees \the [buckled_mob.name] from \the [src].</span>",\
					"<span class='notice'>\The [user.name] frees you from \the [src].</span>",\
					"<span class='warning'>You hear shredding and ripping.</span>")
			else
				buckled_mob.visible_message(\
					"<span class='notice'>\The [buckled_mob.name] struggles free of \the [src].</span>",\
					"<span class='notice'>You untangle \the [src] from around yourself.</span>",\
					"<span class='warning'>You hear shredding and ripping.</span>")
			unbuckle()
		else
			health -= rand(1,5)
			var/text = pick("rip","tear","pull", "bite", "tug")
			user.visible_message(\
				"<span class='warning'>\the [user.name] [text]s at \the [src].</span>",\
				"<span class='warning'>You [text] at \the [src].</span>",\
				"<span class='warning'>You hear shredding and ripping.</span>")
	return

/obj/effect/plant/proc/entangle(var/mob/living/victim)

	if(buckled_mob)
		return

	if(victim.buckled)
		return

	//grabbing people
	if(!victim.anchored && victim.loc != get_turf(src))
		var/can_grab = 1
		if(istype(victim, /mob/living/carbon/human))
			var/mob/living/carbon/human/H = victim
			if(istype(H.shoes, /obj/item/clothing/shoes/magboots) && (H.shoes.item_flags & NOSLIP))
				can_grab = 0
		if(can_grab)
			if(Adjacent(victim))
				src.visible_message("<span class='danger'>Tendrils lash out from \the [src] and drag \the [victim] in!</span>")
				victim.forceMove(get_turf(src))
			else if(prob(round(seed.get_trait(TRAIT_POTENCY)/5)))
				src.visible_message("<span class='danger'>Tendrils lash out from \the [src] and trip \the [victim]!</span>")
				victim.Weaken((seed.get_trait(TRAIT_POTENCY) / 2))
				step_to(victim, src)


	//entangling people
	if(victim.loc == src.loc)
		victim.Weaken(seed.get_trait(TRAIT_POTENCY))
		spawn(0)
		buckle_mob(victim)

		victim.set_dir(pick(cardinal))
		victim << "<span class='danger'>Tendrils [pick("wind", "tangle", "tighten")] around you!</span>"
