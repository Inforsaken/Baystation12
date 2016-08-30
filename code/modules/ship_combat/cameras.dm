/obj/machinery/camera/network/battle
	network = list()
	has_circuit = 1
	var/number = 0

/obj/machinery/camera/network/battle/New()
	..()
	var/list/new_network
	var/area/ship_battle/A = get_area(src)
	if(A && istype(A))
		switch(A.team)
			if(1)
				new_network.Add("Team One")
			if(2)
				new_network.Add("Team Two")
			if(3)
				new_network.Add("Team Three")
			if(4)
				new_network.Add("Team Four")
	spawn(10)
		number = 1
		var/area/AB = get_area(src)
		if(AB)
			for(var/obj/machinery/camera/network/battle/C in world)
				if(C == src) continue
				var/area/CA = get_area(C)
				if(CA.type == AB.type)
					if(C.number)
						number = max(number, C.number+1)
			c_tag = "[AB.name] #[number]"

	if(new_network.len)
		replace_networks(uniquelist(new_network))
	invalidateCameraCache()

/obj/machinery/computer/security/battle/New()
	..()
	network.Cut()
	var/area/ship_battle/A = get_area(src)
	if(A && istype(A))
		switch(A.team)
			if(1)
				network.Add("Team One")
			if(2)
				network.Add("Team Two")
			if(3)
				network.Add("Team Three")
			if(4)
				network.Add("Team Four")
	if(network.len)
		current_network = network[1]