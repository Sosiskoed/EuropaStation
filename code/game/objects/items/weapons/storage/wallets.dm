/obj/item/weapon/storage/wallet
	name = "wallet"
	desc = "It can hold a few small and personal things."
	storage_slots = 10
	icon_state = "wallet"
	w_class = 2
	can_hold = list(
		/obj/item/cash,
		/obj/item/weapon/card,
		/obj/item/clothing/mask/smokable/cigarette/,
		/obj/item/device/flashlight/pen,
		/obj/item/seeds,
		/obj/item/stack/medical,
		/obj/item/weapon/disk,
		/obj/item/weapon/implanter,
		/obj/item/weapon/flame/lighter,
		/obj/item/weapon/flame/match,
		/obj/item/weapon/paper,
		/obj/item/weapon/pen,
		/obj/item/weapon/photo,
		/obj/item/weapon/reagent_containers/dropper,
		/obj/item/weapon/screwdriver,
		/obj/item/weapon/stamp)
	slot_flags = SLOT_ID

	var/obj/item/weapon/card/id/front_id = null


/obj/item/weapon/storage/wallet/remove_from_storage(obj/item/W as obj, atom/new_location)
	. = ..(W, new_location)
	if(.)
		if(W == front_id)
			front_id = null
			name = initial(name)
			update_icon()

/obj/item/weapon/storage/wallet/handle_item_insertion(obj/item/W as obj, prevent_warning = 0)
	. = ..(W, prevent_warning)
	if(.)
		if(!front_id && istype(W, /obj/item/weapon/card/id))
			front_id = W
			name = "[name] ([front_id])"
			update_icon()

/obj/item/weapon/storage/wallet/update_icon()

	if(front_id)
		switch(front_id.icon_state)
			if("id")
				icon_state = "walletid"
				return
			if("silver")
				icon_state = "walletid_silver"
				return
			if("gold")
				icon_state = "walletid_gold"
				return
			if("centcom")
				icon_state = "walletid_centcom"
				return
	icon_state = "wallet"


/obj/item/weapon/storage/wallet/GetID()
	return front_id

/obj/item/weapon/storage/wallet/GetAccess()
	var/obj/item/I = GetID()
	if(I)
		return I.GetAccess()
	else
		return ..()

/obj/item/weapon/storage/wallet/random/initialize()
	..()
	var/list/cashtypes = list(/obj/item/cash/c10,/obj/item/cash/c100,/obj/item/cash/c1000,/obj/item/cash/c20,/obj/item/cash/c200,/obj/item/cash/c50, /obj/item/cash/c500)
	var/cashcount = rand(1,3)
	while(cashcount>0)
		cashcount--
		var/item_type = pick(cashtypes)
		new item_type(src)
