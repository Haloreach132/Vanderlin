/datum/round_event_control/malum_diligence
	name = "Malum's Diligence"
	track = EVENT_TRACK_INTERVENTION
	typepath = /datum/round_event/malum_diligence
	weight = 8
	earliest_start = 10 MINUTES
	max_occurrences = 2
	min_players = 15
	allowed_storytellers = list(/datum/storyteller/malum)

/datum/round_event/malum_diligence/start()
	SSmapping.add_world_trait(/datum/world_trait/malum_diligence, 20 MINUTES)
