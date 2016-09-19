// Returns which access is relevant to passed network. Used by the program.
/proc/get_camera_access(var/network)
	if(!network)
		return 0

	switch(network)
		if(NETWORK_THUNDER)
			return 0
		if(NETWORK_ENGINE,NETWORK_ENGINEERING,NETWORK_ENGINEERING_OUTPOST,NETWORK_ALARM_ATMOS,NETWORK_ALARM_FIRE,NETWORK_ALARM_POWER)
			return access_engine
		if(NETWORK_MEDICAL)
			return access_medical
		if(NETWORK_RESEARCH,NETWORK_RESEARCH_OUTPOST)
			return access_research
		if(NETWORK_MINE,NETWORK_SUPPLY,NETWORK_CIVILIAN_WEST,NETWORK_EXPEDITION,NETWORK_CALYPSO,NETWORK_POD)
			return access_mailsorting // Cargo office - all cargo staff should have access here.
		if(NETWORK_COMMAND,NETWORK_TELECOM)
			return access_heads
		if(NETWORK_CRESCENT,NETWORK_ERT)
			return access_cent_specops

	return access_security // Default for all other networks

/datum/computer_file/program/camera_monitor
	filename = "cammon"
	filedesc = "Camera Monitoring"
	nanomodule_path = /datum/nano_module/program/camera_monitor
	program_icon_state = "generic"
	extended_desc = "This program allows remote access to station's camera system. Some camera networks may have additional access requirements."
	size = 12
	available_on_ntnet = 1
	requires_ntnet = 1

/datum/nano_module/program/camera_monitor
	name = "Camera Monitoring program"
	var/obj/machinery/camera/current_camera = null
	var/current_network = null

/datum/nano_module/program/camera_monitor/ui_interact(mob/user, ui_key = "main", datum/nanoui/ui = null, force_open = 1, state = default_state)
	var/list/data = host.initial_data()

	data["current_camera"] = current_camera ? current_camera.nano_structure() : null
	data["current_network"] = current_network

	var/list/all_networks[0]
	for(var/network in using_map.station_networks)
		all_networks.Add(list(list(
							"tag" = network,
							"has_access" = can_access_network(user, get_camera_access(network))
							)))

	all_networks = modify_networks_list(all_networks)

	data["networks"] = all_networks

	if(current_network)
		data["cameras"] = camera_repository.cameras_in_network(current_network)

	ui = nanomanager.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		ui = new(user, src, ui_key, "sec_camera.tmpl", "Camera Monitoring", 900, 800, state = state)
		// ui.auto_update_layout = 1 // Disabled as with suit sensors monitor - breaks the UI map. Re-enable once it's fixed somehow.

		ui.add_template("mapContent", "sec_camera_map_content.tmpl")
		ui.add_template("mapHeader", "sec_camera_map_header.tmpl")
		ui.set_initial_data(data)
		ui.open()

// Intended to be overriden by subtypes to manually add non-station networks to the list.
/datum/nano_module/program/camera_monitor/proc/modify_networks_list(var/list/networks)
	return networks

/datum/nano_module/program/camera_monitor/proc/can_access_network(var/mob/user, var/network_access)
	// No access passed, or 0 which is considered no access requirement. Allow it.
	if(!network_access)
		return 1

	return check_access(user, access_security) || check_access(user, network_access)

/datum/nano_module/program/camera_monitor/Topic(href, href_list)
	if(..())
		return 1

	if(href_list["switch_camera"])
		var/obj/machinery/camera/C = locate(href_list["switch_camera"]) in cameranet.cameras
		if(!C)
			return
		if(!(current_network in C.network))
			return

		switch_to_camera(usr, C)
		return 1

	else if(href_list["switch_network"])
		if(!(href_list["switch_network"] in using_map.station_networks))
			return

		// Either security access, or access to the specific camera network's department is required in order to access the network.
		if(can_access_network(usr, get_camera_access(href_list["switch_network"])))
			current_network = href_list["switch_network"]
		else
			usr << "\The [nano_host()] shows an \"Network Access Denied\" error message."
		return 1

	else if(href_list["reset"])
		reset_current()
		usr.reset_view(current_camera)
		return 1

/datum/nano_module/program/camera_monitor/proc/switch_to_camera(var/mob/user, var/obj/machinery/camera/C)
	//don't need to check if the camera works for AI because the AI jumps to the camera location and doesn't actually look through cameras.
	if(isAI(user))
		var/mob/living/silicon/ai/A = user
		// Only allow non-carded AIs to view because the interaction with the eye gets all wonky otherwise.
		if(!A.is_in_chassis())
			return 0

		A.eyeobj.setLoc(get_turf(C))
		A.client.eye = A.eyeobj
		return 1

	set_current(C)
	user.machine = nano_host()
	user.reset_view(C)
	return 1

/datum/nano_module/program/camera_monitor/proc/set_current(var/obj/machinery/camera/C)
	if(current_camera == C)
		return

	if(current_camera)
		reset_current()

	current_camera = C
	if(current_camera)
		var/mob/living/L = current_camera.loc
		if(istype(L))
			L.tracking_initiated()

/datum/nano_module/program/camera_monitor/proc/reset_current()
	if(current_camera)
		var/mob/living/L = current_camera.loc
		if(istype(L))
			L.tracking_cancelled()
	current_camera = null

/datum/nano_module/program/camera_monitor/check_eye(var/mob/user as mob)
	if(!current_camera)
		return 0
	var/viewflag = current_camera.check_eye(user)
	if ( viewflag < 0 ) //camera doesn't work
		reset_current()
	return viewflag


// ERT Variant of the program
/datum/computer_file/program/camera_monitor/ert
	filename = "ntcammon"
	filedesc = "Advanced Camera Monitoring"
	extended_desc = "This program allows remote access to station's camera system. Some camera networks may have additional access requirements. This version has an integrated database with additional encrypted keys."
	size = 14
	nanomodule_path = /datum/nano_module/program/camera_monitor/ert
	available_on_ntnet = 0

/datum/nano_module/program/camera_monitor/ert
	name = "Advanced Camera Monitoring Program"
	available_to_ai = FALSE


/datum/computer_file/program/camera_monitor/battle
	filename = "shipcameras"
	filedesc = "Advanced Camera Monitoring"
	extended_desc = "This program allows remote access to ship camera systems. Some camera networks may have additional access requirements. This version has an integrated database with additional encrypted keys."
	size = 14
	nanomodule_path = /datum/nano_module/program/camera_monitor/battle
	available_on_ntnet = 0

/datum/nano_module/program/camera_monitor/battle
	name = "Advanced Camera Monitoring Program"
	available_to_ai = TRUE

/datum/nano_module/program/camera_monitor/battle/modify_networks_list(var/list/networks)
	var/obj/item/modular_computer/movable
	if(program)
		movable = program.computer
	if(!movable) return
	var/list/network = list()
	var/obj/effect/overmap/linked = map_sectors["[movable.z]"]
	if(linked)
		network.Add("[linked.name]")
	var/area/ship_battle/A = get_area(movable)
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

	return network