//These procs handle putting s tuff in my hands
//as they handle all relevant stuff like adding it to the player's screen and updating their overlays.

//Returns the thing we're currently holding
/mob/proc/get_active_held_item()
	return get_item_for_held_index(active_hand_index)


//Finds the opposite limb for the active one (eg: upper left arm will find the item in upper right arm)
//So we're treating each "pair" of limbs as a team, so "both" refers to them
/mob/proc/get_inactive_held_item()
	return get_item_for_held_index(get_inactive_hand_index())


//Finds the opposite index for the active one (eg: upper left arm will find the item in upper right arm)
//So we're treating each "pair" of limbs as a team, so "both" refers to them
/mob/proc/get_inactive_hand_index()
	var/other_hand = 0
	if(!(active_hand_index % 2))
		other_hand = active_hand_index-1 //finding the matching "left" limb
	else
		other_hand = active_hand_index+1 //finding the matching "right" limb
	if(other_hand < 0 || other_hand > held_items.len)
		other_hand = 0
	return other_hand


/mob/proc/get_item_for_held_index(i)
	if(i > 0 && i <= held_items.len)
		return held_items[i]
	return FALSE


//Odd = left. Even = right
/mob/proc/held_index_to_dir(i)
	if(!(i % 2))
		return "r"
	return "l"


//Check we have an organ for this hand slot (Dismemberment), Only relevant for humans
/mob/proc/has_hand_for_held_index(i,extra_checks)
	return TRUE


//Check we have an organ for our active hand slot (Dismemberment),Only relevant for humans
/mob/proc/has_active_hand()
	return has_hand_for_held_index(active_hand_index)


//Finds the first available (null) index OR all available (null) indexes in held_items based on a side.
//Lefts: 1, 3, 5, 7...
//Rights:2, 4, 6, 8...
/mob/proc/get_empty_held_index_for_side(side = LEFT_HANDS, all = FALSE)
	var/list/empty_indexes = all ? list() : null
	for(var/i in (side == LEFT_HANDS) ? 1 : 2 to held_items.len step 2)
		if(!held_items[i])
			if(!all)
				return i
			empty_indexes += i
	return empty_indexes


//Same as the above, but returns the first or ALL held *ITEMS* for the side
/mob/proc/get_held_items_for_side(side = LEFT_HANDS, all = FALSE)
	var/list/holding_items = all ? list() : null
	for(var/i in (side == LEFT_HANDS) ? 1 : 2 to held_items.len step 2)
		var/obj/item/I = held_items[i]
		if(I)
			if(!all)
				return I
			holding_items += I
	return holding_items


/mob/proc/get_empty_held_indexes()
	var/list/L
	for(var/i in 1 to held_items.len)
		if(!held_items[i])
			if(!L)
				L = list()
			L += i
	return L

/mob/proc/get_held_index_of_item(obj/item/I)
	return held_items.Find(I)


//Sad that this will cause some overhead, but the alias seems necessary
//*I* may be happy with a million and one references to "indexes" but others won't be
/mob/proc/is_holding(obj/item/I)
	return get_held_index_of_item(I)


//Checks if we're holding an item of type: typepath
/mob/proc/is_holding_item_of_type(typepath)
	for(var/obj/item/I in held_items)
		if(istype(I, typepath))
			return I
	return FALSE

//Checks if we're holding a tool that has given quality
//Returns the tool that has the best version of this quality
/mob/proc/is_holding_tool_quality(quality)
	var/obj/item/best_item
	var/best_quality = INFINITY

	for(var/obj/item/I in held_items)
		if(I.tool_behaviour == quality && I.toolspeed < best_quality)
			best_item = I
			best_quality = I.toolspeed

	return best_item


//To appropriately fluff things like "they are holding [I] in their [get_held_index_name(get_held_index_of_item(I))]"
//Can be overridden to pass off the fluff to something else (eg: science allowing people to add extra robotic limbs, and having this proc react to that
// with say "they are holding [I] in their Nanotrasen Brand Utility Arm - Right Edition" or w/e
/mob/proc/get_held_index_name(i)
	var/list/hand = list()
	if(i > 2)
		hand += "upper "
	var/num = 0
	if(!(i % 2))
		num = i-2
		hand += "right hand"
	else
		num = i-1
		hand += "left hand"
	num -= (num*0.5)
	if(num > 1) //"upper left hand #1" seems weird, but "upper left hand #2" is A-ok
		hand += " #[num]"
	return hand.Join()



//Returns if a certain item can be equipped to a certain slot.
// Currently invalid for two-handed items - call obj/item/mob_can_equip() instead.
/mob/proc/can_equip(obj/item/I, slot, disable_warning = FALSE, bypass_equip_delay_self = FALSE)
	return FALSE

/mob/proc/can_put_in_hand(I, hand_index)
	if(hand_index > held_items.len)
		return FALSE
	if(!put_in_hand_check(I))
		return FALSE
	if(!has_hand_for_held_index(hand_index))
		return FALSE
	return !held_items[hand_index]

/mob/proc/put_in_hand(obj/item/I, hand_index, forced = FALSE, ignore_anim = TRUE)
	if(hand_index == null || (!forced && !can_put_in_hand(I, hand_index)))
		return FALSE

	if(isturf(I.loc) && !ignore_anim)
		I.do_pickup_animation(src)
	if(get_item_for_held_index(hand_index) != null)
		return FALSE
//		dropItemToGround(get_item_for_held_index(hand_index), force = TRUE)
	I.forceMove(src)
	held_items[hand_index] = I
	I.plane = ABOVE_HUD_PLANE
	I.equipped(src, ITEM_SLOT_HANDS)
	if(QDELETED(I)) // this is here because some ABSTRACT items like slappers and circle hands could be moved from hand to hand then delete, which meant you'd have a null in your hand until you cleared it (say, by dropping it)
		held_items[hand_index] = null
		return FALSE
	if(I.possible_item_intents)
		update_a_intents()
	if(I.pulledby)
		I.pulledby.stop_pulling()
	update_inv_hands()
	I.pixel_x = initial(I.pixel_x)
	I.pixel_y = initial(I.pixel_y)
	if(hud_used)
		hud_used.throw_icon?.update_appearance()
		hud_used.give_intent?.update_appearance()
	if((istype(I, /obj/item/weapon) || istype(I, /obj/item/gun) || I.force >= 15) && !forced && client)
		// is this the right hand?
		var/right_hand = FALSE
		if(hand_index == LEFT_HANDS)
			right_hand = TRUE
		log_message("[key_name(src)] has equipped [I] in their [right_hand ? "right hand" : "left hand"], combat mode: [cmode ? "COMBAT" : "PASSIVE"].", LOG_ATTACK, color="#3333ff") // into attack logs
	return hand_index

//Puts the item into the first available left hand if possible and calls all necessary triggers/updates. returns 1 on success.
/mob/proc/put_in_l_hand(obj/item/I)
	return put_in_hand(I, get_empty_held_index_for_side(LEFT_HANDS))

//Puts the item into the first available right hand if possible and calls all necessary triggers/updates. returns 1 on success.
/mob/proc/put_in_r_hand(obj/item/I)
	return put_in_hand(I, get_empty_held_index_for_side(RIGHT_HANDS))

/mob/proc/put_in_hand_check(obj/item/I)
	return FALSE					//nonliving mobs don't have hands

/mob/living/put_in_hand_check(obj/item/I)
	if(istype(I) && (((mobility_flags & MOBILITY_PICKUP) || (I.item_flags & ABSTRACT)) \
		&& !(SEND_SIGNAL(src, COMSIG_LIVING_TRY_PUT_IN_HAND, I) & COMPONENT_LIVING_CANT_PUT_IN_HAND)))
		return TRUE
	return FALSE

//Puts the item into our active hand if possible. returns TRUE on success.
/mob/proc/put_in_active_hand(obj/item/I, forced = FALSE, ignore_animation = TRUE)
	return put_in_hand(I, active_hand_index, forced, ignore_animation)


//Puts the item into our inactive hand if possible, returns TRUE on success
/mob/proc/put_in_inactive_hand(obj/item/I, forced = FALSE, ignore_animation = TRUE)
	return put_in_hand(I, get_inactive_hand_index(), forced, ignore_animation)


//Puts the item our active hand if possible. Failing that it tries other hands. Returns TRUE on success.
//If both fail it drops it on the floor and returns FALSE.
//This is probably the main one you need to know :)
/mob/proc/put_in_hands(obj/item/I, del_on_fail = FALSE, merge_stacks = TRUE, forced = FALSE)
	if(!I)
		return FALSE

	if(put_in_active_hand(I, forced))
		return TRUE

	var/hand = get_empty_held_index_for_side(LEFT_HANDS)
	if(!hand)
		hand =  get_empty_held_index_for_side(RIGHT_HANDS)
	if(hand)
		if(put_in_hand(I, hand, forced))
			return TRUE
	if(del_on_fail)
		qdel(I)
		return FALSE
	I.forceMove(drop_location())
	I.layer = initial(I.layer)
	I.plane = initial(I.plane)
	I.dropped(src)
	return FALSE

/mob/proc/drop_all_held_items()
	. = FALSE
	for(var/obj/item/I in held_items)
		. |= dropItemToGround(I)

//Here lie drop_from_inventory and before_item_take, already forgotten and not missed.

/mob/proc/canUnEquip(obj/item/I, force)
	if(!I)
		return TRUE
	if(HAS_TRAIT(I, TRAIT_NODROP) && !force)
		return FALSE
	return TRUE

/mob/proc/putItemFromInventoryInHandIfPossible(obj/item/I, hand_index, force_removal = FALSE)
	if(!can_put_in_hand(I, hand_index))
		return FALSE
	if(!temporarilyRemoveItemFromInventory(I, force_removal))
		return FALSE
	I.remove_item_from_storage(src)
	if(!put_in_hand(I, hand_index))
		qdel(I)
		CRASH("Assertion failure: putItemFromInventoryInHandIfPossible") //should never be possible
	return TRUE

//The following functions are the same save for one small difference

/**
 * Used to drop an item (if it exists) to the ground.
 * * Will pass as TRUE is successfully dropped, or if there is no item to drop.
 * * Will pass FALSE if the item can not be dropped due to TRAIT_NODROP via doUnEquip()
 * If the item can be dropped, it will be forceMove()'d to the ground and the turf's Entered() will be called.
*/
/mob/proc/dropItemToGround(obj/item/I, force = FALSE, silent = TRUE)
	. = doUnEquip(I, force, drop_location(), FALSE, silent = silent)
	if(. && I) //ensure the item exists and that it was dropped properly.
		I.pixel_x = initial(I.pixel_x) + rand(-6,6)
		I.pixel_y = initial(I.pixel_x) + rand(-6,6)
		I.afterdrop()

//for when the item will be immediately placed in a loc other than the ground
/mob/proc/transferItemToLoc(obj/item/I, newloc = null, force = FALSE, silent = TRUE)
	return doUnEquip(I, force, newloc, FALSE, silent = silent)

//visibly unequips I but it is NOT MOVED AND REMAINS IN SRC
//item MUST BE FORCEMOVE'D OR QDEL'D
/mob/proc/temporarilyRemoveItemFromInventory(obj/item/I, force = FALSE, idrop = TRUE)
	return doUnEquip(I, force, null, TRUE, idrop, silent = TRUE)

//DO NOT CALL THIS PROC
//use one of the above 3 helper procs
//you may override it, but do not modify the args
/mob/proc/doUnEquip(obj/item/I, force, newloc, no_move, invdrop = TRUE, silent = FALSE) //Force overrides TRAIT_NODROP for things like wizarditis and admin undress.
													//Use no_move if the item is just gonna be immediately moved afterward
													//Invdrop is used to prevent stuff in pockets dropping. only set to false if it's going to immediately be replaced
	if(!I) //If there's nothing to drop, the drop is automatically succesfull. If(unEquip) should generally be used to check for TRAIT_NODROP.
		update_inv_hands()
		update_a_intents()
		return TRUE

	if(HAS_TRAIT(I, TRAIT_NODROP) && !force)
		return FALSE

	if((SEND_SIGNAL(I, COMSIG_ITEM_PRE_UNEQUIP, force, newloc, no_move, invdrop, silent) & COMPONENT_ITEM_BLOCK_UNEQUIP) && !force)
		return FALSE

	var/hand_index = get_held_index_of_item(I)
	if(hand_index)
		held_items[hand_index] = null
		update_inv_hands()
	if(atkswinging)
		stop_attack(FALSE)
	if(I)
		if(IS_WEAKREF_OF(I, offered_item))
			offered_item = null
		if(client)
			client.screen -= I
		I.layer = initial(I.layer)
		I.plane = initial(I.plane)
		I.appearance_flags &= ~NO_CLIENT_COLOR
		if(!no_move && !(I.item_flags & DROPDEL))	//item may be moved/qdel'd immedietely, don't bother moving it
			if (isnull(newloc))
				I.moveToNullspace()
			else
				I.forceMove(newloc)
		I.dropped(src, silent)
	if(hud_used)
		hud_used.throw_icon?.update_appearance()
		hud_used.give_intent?.update_appearance()
	update_a_intents()
	SEND_SIGNAL(I, COMSIG_ITEM_POST_UNEQUIP, force, newloc, no_move, invdrop, silent)
	SEND_SIGNAL(src, COMSIG_MOB_UNEQUIPPED_ITEM, I, force, newloc, no_move, invdrop, silent)
	return TRUE

//Outdated but still in use apparently. This should at least be a human proc.
//Daily reminder to murder this - Remie.
/mob/living/proc/get_equipped_items(include_pockets = FALSE)
	return

/mob/living/carbon/get_equipped_items(include_pockets = FALSE)
	var/list/items = list()
	if(backr)
		items += backr
	if(backl)
		items += backl
	if(head)
		items += head
	if(wear_mask)
		items += wear_mask
	if(wear_neck)
		items += wear_neck
	return items

/mob/living/carbon/human/get_equipped_items(include_pockets = FALSE)
	var/list/items = ..()
	if(belt)
		items += belt
	if(beltr)
		items += beltr
	if(beltl)
		items += beltl
	if(backr)
		items += backr
	if(backl)
		items += backl
	if(gloves)
		items += gloves
	if(shoes)
		items += shoes
	if(wear_ring)
		items += wear_ring
	if(wear_wrists)
		items += wear_wrists
	if(wear_armor)
		items += wear_armor
	if(wear_pants)
		items += wear_pants
	if(cloak)
		items += cloak
	if(mouth)
		items += mouth
	if(wear_shirt)
		items += wear_shirt
	return items

/mob/living/proc/unequip_everything()
	var/list/items = list()
	items |= get_equipped_items(TRUE)
	for(var/I in items)
		dropItemToGround(I)
	drop_all_held_items()


/mob/living/carbon/proc/check_obscured_slots(transparent_protection)
	var/obscured = NONE
	var/hidden_slots = NONE

	for(var/obj/item/I in get_equipped_items())
		hidden_slots |= I.flags_inv
		if(transparent_protection)
			hidden_slots |= I.transparent_protection

	if(hidden_slots & HIDENECK)
		obscured |= ITEM_SLOT_NECK
	if(hidden_slots & HIDEMASK)
		obscured |= ITEM_SLOT_MASK
	if(hidden_slots & HIDEGLOVES)
		obscured |= ITEM_SLOT_GLOVES
	if(hidden_slots & HIDEJUMPSUIT)
		obscured |= ITEM_SLOT_PANTS
	if(hidden_slots & HIDESHOES)
		obscured |= ITEM_SLOT_SHOES
	if(hidden_slots & HIDEBELT)
		obscured |= ITEM_SLOT_BELT_R
		obscured |= ITEM_SLOT_BELT_L
		obscured |= ITEM_SLOT_BELT

	return obscured

/obj/item/proc/equip_to_best_slot(mob/M)
	if(src != M.get_active_held_item())
		to_chat(M, span_warning("I are not holding anything to equip!"))
		return FALSE

	if(M.equip_to_appropriate_slot(src))
		M.update_inv_hands()
		return TRUE
	else
		if(equip_delay_self)
			return

	if(M.active_storage && M.active_storage.parent && SEND_SIGNAL(M.active_storage.parent, COMSIG_TRY_STORAGE_INSERT, src,M))
		return TRUE

	var/list/obj/item/possible = list(M.get_inactive_held_item(), M.get_item_by_slot(ITEM_SLOT_BELT))
	for(var/i in possible)
		if(!i)
			continue
		var/obj/item/I = i
		if(SEND_SIGNAL(I, COMSIG_TRY_STORAGE_INSERT, src, M))
			return TRUE

	to_chat(M, span_warning("I couldn't equip that."))
	return FALSE


/mob/verb/quick_equip()
	set name = "quick-equip"
	set hidden = 1

	DEFAULT_QUEUE_OR_CALL_VERB(VERB_CALLBACK(src, PROC_REF(execute_quick_equip)))

///proc extender of [/mob/verb/quick_equip] used to make the verb queuable if the server is overloaded
/mob/proc/execute_quick_equip()
	var/obj/item/I = get_active_held_item()
	if (I)
		I.equip_to_best_slot(src)

/mob/proc/getBeltSlot()
	return ITEM_SLOT_BELT

//Inventory.dm is -kind of- an ok place for this I guess

//This is NOT for dismemberment, as the user still technically has 2 "hands"
//This is for multi-handed mobs, such as a human with a third limb installed
//This is a very rare proc to call (besides admin fuckery) so
//any cost it has isn't a worry
/mob/proc/change_number_of_hands(amt)
	if(amt < held_items.len)
		for(var/i in held_items.len to amt step -1)
			dropItemToGround(held_items[i])
	held_items.len = amt

	if(hud_used)
		hud_used.build_hand_slots()


/mob/living/carbon/human/change_number_of_hands(amt)
	var/old_limbs = held_items.len
	if(amt < old_limbs)
		for(var/i in hand_bodyparts.len to amt step -1)
			var/obj/item/bodypart/BP = hand_bodyparts[i]
			BP.dismember()
			hand_bodyparts[i] = null
		hand_bodyparts.len = amt
	else if(amt > old_limbs)
		hand_bodyparts.len = amt
		for(var/i in old_limbs+1 to amt)
			var/path = /obj/item/bodypart/l_arm
			if(!(i % 2))
				path = /obj/item/bodypart/r_arm

			var/obj/item/bodypart/BP = new path ()
			BP.owner = src
			BP.held_index = i
			add_bodypart(BP)
			hand_bodyparts[i] = BP
	..() //Don't redraw hands until we have organs for them
