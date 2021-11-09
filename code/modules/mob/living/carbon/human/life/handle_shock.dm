//Refer to life.dm for caller

/mob/living/carbon/human/handle_shock()
	. = ..()
	if(status_flags & GODMODE || analgesic || (species && species.species_flags & NO_PAIN))
		setShock_Stage(0)
		return //Godmode or some other pain reducers. //Analgesic avoids all traumatic shock temporarily

	switch(traumatic_shock)
		if(200 to INFINITY) //All of these adjust shock_stage based on traumatic_shock
			adjustShock_Stage(5+((traumatic_shock-200)*0.2)) //Uncapped max gain of shock_stage, depending on traumatic_shock.

		if(150 to 200)
			adjustShock_Stage(1+((traumatic_shock-150)*0.08)) //smooth ramp from 1 to 5

		if(100 to 150)
			adjustShock_Stage(1)

		if(5 to 35)
			adjustShock_Stage(-1)

		if(-30 to 5)
			adjustShock_Stage(-2)

		if(-INFINITY to -30)
			adjustShock_Stage(-4+((traumatic_shock+30)*0.2)) //uncapped heal, 1 extra point per 5 traumatic_shock above threshold.

	//This just adds up effects together at each step, with a few small exceptions. Preferable to copy and paste rather than have a billion if statements.
	switch(shock_stage)
		if(10 to 29)
			if(prob(20))
				to_chat(src, span_danger("[pick("You're in a bit of pain", "You ache a little", "You feel some physical discomfort")]."))
		if(30 to 39)
			if(prob(20))
				to_chat(src, span_danger("[pick("It hurts so much", "You really need some painkillers", "Dear god, the pain")]!"))
			stuttering = max(stuttering, 5)
		if(40 to 59)
			if(prob(20))
				to_chat(src, span_danger("[pick("The pain is excruciating", "Please, just end the pain", "Your whole body is going numb")]!"))
			blur_eyes(1)
			stuttering = max(stuttering, 5)
			adjust_stagger(1, FALSE, 1)
			add_slowdown(1)
		if(60 to 79)
			if(!lying_angle && prob(20))
				emote("me", 1, " is having trouble standing.")
			blur_eyes(2)
			stuttering = max(stuttering, 5)
			adjust_stagger(3, FALSE, 3)
			add_slowdown(3)
			if(prob(20))
				to_chat(src, span_danger("[pick("The pain is excruciating", "Please, just end the pain", "Your whole body is going numb")]!"))
		if(80 to 119)
			blur_eyes(2)
			stuttering = max(stuttering, 5)
			adjust_stagger(6, FALSE, 6)
			add_slowdown(6)
			if(prob(20))
				to_chat(src, span_danger("[pick("The pain is excruciating", "Please, just end the pain", "Your whole body is going numb")]!"))
		if(120 to 149)
			blur_eyes(2)
			stuttering = max(stuttering, 5)
			adjust_stagger(9, FALSE, 9)
			add_slowdown(9)
			if(prob(20))
				to_chat(src, span_danger("[pick("The pain is excruciating", "Please, just end the pain", "Your whole body is going numb", "You feel like you could die any moment now")]!"))
		if(150 to INFINITY)
			blur_eyes(2)
			stuttering = max(stuttering, 5)
			adjust_stagger(12, FALSE, 12)
			add_slowdown(12)
			if(prob(20))
				to_chat(src, span_danger("[pick("The pain is excruciating", "Please, just end the pain", "Your whole body is going numb", "You feel like you could die any moment now")]!"))
			if(!COOLDOWN_CHECK(src, last_shock_effect)) //Check to see if we're on cooldown
				return
			if(!lying_angle)
				emote("me", 1, "can no longer stand, collapsing!")
			Paralyze(1 SECONDS)
			COOLDOWN_START(src, last_shock_effect, LIVING_SHOCK_EFFECT_COOLDOWN) //set the cooldown.
