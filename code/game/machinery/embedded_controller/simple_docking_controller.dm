//a docking port that uses a single door
/obj/structure/machinery/embedded_controller/radio/simple_docking_controller
	name = "docking hatch controller"
	var/tag_door
	var/datum/computer/file/embedded_program/docking/simple/docking_program

/obj/structure/machinery/embedded_controller/radio/simple_docking_controller/Initialize()
	. = ..()
	docking_program = new/datum/computer/file/embedded_program/docking/simple(src)
	program = docking_program

/obj/structure/machinery/embedded_controller/radio/simple_docking_controller/Destroy()
	QDEL_NULL(docking_program)
	return ..()

//A docking controller program for a simple door based docking port
/datum/computer/file/embedded_program/docking/simple
	var/tag_door

/datum/computer/file/embedded_program/docking/simple/New(obj/structure/machinery/embedded_controller/M)
	..(M)
	memory["door_status"] = list(state = "closed", lock = "locked") //assume closed and locked in case the doors dont report in

	if (istype(M, /obj/structure/machinery/embedded_controller/radio/simple_docking_controller))
		var/obj/structure/machinery/embedded_controller/radio/simple_docking_controller/controller = M

		tag_door = controller.tag_door? controller.tag_door : "[id_tag]_hatch"

		spawn(10)
			signal_door("update") //signals connected doors to update their status


/datum/computer/file/embedded_program/docking/simple/receive_signal(datum/signal/signal, receive_method, receive_param)
	var/receive_tag = signal.data["tag"]

	if(!receive_tag)
		return

	if(receive_tag==tag_door)
		memory["door_status"]["state"] = signal.data["door_status"]
		memory["door_status"]["lock"] = signal.data["lock_status"]

	..(signal, receive_method, receive_param)

/datum/computer/file/embedded_program/docking/simple/receive_user_command(command)
	switch(command)
		if("force_door")
			if (override_enabled)
				if(memory["door_status"]["state"] == "open")
					close_door()
				else
					open_door()
		if("toggle_override")
			if (override_enabled)
				disable_override()
			else
				enable_override()


/datum/computer/file/embedded_program/docking/simple/proc/signal_door(command)
	var/datum/signal/signal = new
	signal.data["tag"] = tag_door
	signal.data["command"] = command
	post_signal(signal, RADIO_AIRLOCK)

///datum/computer/file/embedded_program/docking/simple/proc/signal_mech_sensor(command)
// signal_door(command)
// return

/datum/computer/file/embedded_program/docking/simple/proc/open_door()
	if(memory["door_status"]["state"] == "closed")
		//signal_mech_sensor("enable")
		signal_door("secure_open")
	else if(memory["door_status"]["lock"] == "unlocked")
		signal_door("lock")

/datum/computer/file/embedded_program/docking/simple/proc/close_door()
	if(memory["door_status"]["state"] == "open")
		signal_door("secure_close")
		//signal_mech_sensor("disable")
	else if(memory["door_status"]["lock"] == "unlocked")
		signal_door("lock")

//tell the docking port to start getting ready for docking - e.g. pressurize
/datum/computer/file/embedded_program/docking/simple/prepare_for_docking()
	return //don't need to do anything

//are we ready for docking?
/datum/computer/file/embedded_program/docking/simple/ready_for_docking()
	return 1 //don't need to do anything

//we are docked, open the doors or whatever.
/datum/computer/file/embedded_program/docking/simple/finish_docking()
	open_door()

//tell the docking port to start getting ready for undocking - e.g. close those doors.
/datum/computer/file/embedded_program/docking/simple/prepare_for_undocking()
	close_door()

//are we ready for undocking?
/datum/computer/file/embedded_program/docking/simple/ready_for_undocking()
	return (memory["door_status"]["state"] == "closed" && memory["door_status"]["lock"] == "locked")

