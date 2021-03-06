var/list/spawntypes = list()

/proc/populate_spawn_points()
	spawntypes = list()
	for(var/type in typesof(/datum/spawnpoint)-/datum/spawnpoint)
		var/datum/spawnpoint/S = new type()
		spawntypes[S.display_name] = S

/datum/spawnpoint
	var/msg          //Message to display on the arrivals computer.
	var/list/turfs   //List of turfs to spawn on.
	var/display_name //Name used in preference setup.
	var/list/restrict_job = null
	var/list/disallow_job = null

	proc/check_job_spawning(job)
		if(restrict_job && !(job in restrict_job))
			return 0

		if(disallow_job && (job in disallow_job))
			return 0

		return 1

/datum/spawnpoint/proc/get_message()
	return msg

/datum/spawnpoint/arrivals
	display_name = "Arrivals"
	msg = "has arrived on the ship"

/datum/spawnpoint/arrivals/New()
	..()
	turfs = latejoin

/datum/spawnpoint/arrivals/get_message()
	msg = using_map.default_arrival_message
	. = ..()
