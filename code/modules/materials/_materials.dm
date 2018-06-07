/*
	MATERIAL DATUMS
	This data is used by various parts of the game for basic physical properties and behaviors
	of the metals/materials used for constructing many objects. Each var is commented and should be pretty
	self-explanatory but the various object types may have their own documentation. ~Z

	PATHS THAT USE DATUMS
		turf/simulated/wall
		obj/item/material
		obj/structure/barricade
		obj/item/stack/material
		obj/structure/table

	VALID ICONS
		WALLS
			stone
			metal
			solid
			cult
		DOORS
			stone
			metal
			resin
			wood
*/

//Returns the material the object is made of, if applicable.
//Will we ever need to return more than one value here? Or should we just return the "dominant" material.
/obj/proc/get_material()
	return null

//mostly for convenience
/obj/proc/get_material_name()
	var/material/material = get_material()
	if(material)
		return material.name

// Material definition and procs follow.
/material
	var/name	                          // Unique name for use in indexing the list.
	var/display_name                      // Prettier name for display.
	var/adjective_name
	var/use_name
	var/flags = 0                         // Various status modifiers.
	var/sheet_singular_name = "sheet"
	var/sheet_plural_name = "sheets"
	var/units_per_sheet = SHEET_MATERIAL_AMOUNT
	var/is_fusion_fuel

	// Shards/tables/structures
	var/shard_type = SHARD_SHRAPNEL       // Path of debris object.
	var/shard_icon                        // Related to above.
	var/shard_can_repair = 1              // Can shards be turned into sheets with a welder?
	var/list/recipes                      // Holder for all recipes usable with a sheet of this material.
	var/destruction_desc = "breaks apart" // Fancy string for barricades/tables/objects exploding.

	// Icons
	var/icon_colour                                      // Colour applied to products of this material.
	var/icon_base = "metal"                              // Wall and table base icon tag. See header.
	var/door_icon_base = "metal"                         // Door base icon tag. See header.
	var/icon_reinf = "reinf_metal"                       // Overlay used

	// Attributes
	var/cut_delay = 0            // Delay in ticks when cutting through this wall.
	var/radioactivity            // Radiation var. Used in wall and object processing to irradiate surroundings.
	var/ignition_point           // K, point at which the material catches on fire.
	var/melting_point = 1800     // K, walls will take damage if they're next to a fire hotter than this
	var/integrity = 150          // General-use HP value for products.
	var/opacity = 1              // Is the material transparent? 0.5< makes transparent walls/doors.
	var/explosion_resistance = 5 // Only used by walls currently.
	var/conductive = 1           // Objects with this var add CONDUCTS to flags on spawn.
	var/luminescence
	var/list/composite_material  // If set, object matter var will be a list containing these values.

	// Placeholder vars for the time being, todo properly integrate windows/light tiles/rods.
	var/created_window
	var/rod_product
	var/wire_product
	var/list/window_options = list()

	// Damage values.
	var/hardness = 60            // Prob of wall destruction by hulk, used for edge damage in weapons.
	var/weight = 20              // Determines blunt damage/throwforce for weapons.

	// Noise when someone is faceplanted onto a table made of this material.
	var/tableslam_noise = 'sound/weapons/tablehit1.ogg'
	// Noise made when a simple door made of this material opens or closes.
	var/dooropen_noise = 'sound/effects/stonedoor_openclose.ogg'
	// Noise made when you hit structure made of this material.
	var/hitsound = 'sound/weapons/genhit.ogg'
	// Path to resulting stacktype. Todo remove need for this.
	var/stack_type
	// Wallrot crumble message.
	var/rotting_touch_message = "crumbles under your touch"

	// Mining behavior.
	var/alloy_product
	var/ore_name
	var/ore_desc
	var/ore_can_alloy
	var/ore_smelts_to
	var/ore_compresses_to
	var/ore_result_amount
	var/ore_deposit_radius
	var/ore_overlay

	// Gas behavior.
	var/specific_heat = 20 // J/(mol*K)
	var/molar_mass = 0.032 // kg/mol

	var/gas_tile_overlay
	var/gas_tile_overlay_colour
	var/gas_overlay_limit
	var/gas_flags = 0
	var/gas_burn_product = MATERIAL_CO2

// Placeholders for light tiles and rglass.
/material/proc/build_rod_product(var/mob/user, var/obj/item/stack/used_stack, var/obj/item/stack/target_stack)
	if(!rod_product)
		user << "<span class='warning'>You cannot make anything out of \the [target_stack]</span>"
		return
	if(used_stack.get_amount() < 1 || target_stack.get_amount() < 1)
		user << "<span class='warning'>You need one rod and one sheet of [display_name] to make anything useful.</span>"
		return
	used_stack.use(1)
	target_stack.use(1)
	var/obj/item/stack/S = new rod_product(get_turf(user))
	S.add_fingerprint(user)
	S.add_to_stacks(user)

/material/proc/build_wired_product(var/mob/user, var/obj/item/stack/used_stack, var/obj/item/stack/target_stack)
	if(!wire_product)
		user << "<span class='warning'>You cannot make anything out of \the [target_stack]</span>"
		return
	if(used_stack.get_amount() < 5 || target_stack.get_amount() < 1)
		user << "<span class='warning'>You need five wires and one sheet of [display_name] to make anything useful.</span>"
		return

	used_stack.use(5)
	target_stack.use(1)
	user << "<span class='notice'>You attach wire to the [name].</span>"
	var/obj/item/product = new wire_product(get_turf(user))
	if(!(user.l_hand && user.r_hand))
		user.put_in_hands(product)

// Make sure we have a display name and shard icon even if they aren't explicitly set.
/material/New()
	..()
	if(!display_name)
		display_name = name
	if(!use_name)
		use_name = display_name
	if(!adjective_name)
		adjective_name = display_name
	if(!shard_icon)
		shard_icon = shard_type

// This is a placeholder for proper integration of windows/windoors into the system.
/material/proc/build_windows(var/mob/living/user, var/obj/item/stack/used_stack)
	return 0

// Weapons handle applying a divisor for this value locally.
/material/proc/get_blunt_damage()
	return weight //todo

// Return the matter comprising this material.
/material/proc/get_matter()
	var/list/temp_matter = list()
	if(islist(composite_material))
		for(var/material_string in composite_material)
			temp_matter[material_string] = composite_material[material_string]
	else if(SHEET_MATERIAL_AMOUNT)
		temp_matter[name] = SHEET_MATERIAL_AMOUNT
	return temp_matter

// As above.
/material/proc/get_edge_damage()
	return hardness //todo

// Snowflakey, only checked for alien doors at the moment.
/material/proc/can_open_material_door(var/mob/living/user)
	return 1

// Currently used for weapons and objects made of uranium to irradiate things.
/material/proc/products_need_process()
	return (radioactivity>0) //todo

// Used by walls when qdel()ing to avoid neighbor merging.
/material/placeholder
	name = "placeholder"
	hidden_from_codex = TRUE

// Places a girder object when a wall is dismantled, also applies reinforced material.
/material/proc/place_dismantled_girder(var/turf/target, var/material/reinf_material)
	var/obj/structure/girder/G = new(target)
	if(reinf_material)
		G.reinf_material = reinf_material
		G.reinforce_girder()

// General wall debris product placement.
// Not particularly necessary aside from snowflakey cult girders.
/material/proc/place_dismantled_product(var/turf/target,var/is_devastated)
	for(var/x=1;x<(is_devastated?2:3);x++)
		place_sheet(target)

// Debris product. Used ALL THE TIME.
/material/proc/place_sheet(var/turf/target)
	if(stack_type)
		return new stack_type(target)

// As above.
/material/proc/place_shard(var/turf/target)
	if(shard_type)
		return new /obj/item/material/shard(target, src.name)

// Used by walls and weapons to determine if they break or not.
/material/proc/is_brittle()
	return !!(flags & MATERIAL_BRITTLE)

/material/proc/combustion_effect(var/turf/T, var/temperature)
	return

// Datum definitions follow.
/material/uranium
	name = "uranium"
	lore_text = "A highly radioactive metal. Commonly used as fuel in fission reactors."
	stack_type = /obj/item/stack/material/uranium
	radioactivity = 12
	icon_base = "stone"
	icon_reinf = "reinf_stone"
	icon_colour = "#007A00"
	weight = 22
	door_icon_base = "stone"

/material/diamond
	name = "diamond"
	lore_text = "An extremely hard allotrope of carbon. Valued for use in industrial tools."
	stack_type = /obj/item/stack/material/diamond
	flags = MATERIAL_UNMELTABLE
	cut_delay = 60
	icon_colour = "#00FFE1"
	opacity = 0.4
	shard_type = SHARD_SHARD
	tableslam_noise = 'sound/effects/Glasshit.ogg'
	hardness = 100
	conductive = 0

/material/gold
	name = "gold"
	lore_text = "A heavy, soft, ductile metal. Once considered valuable enough to back entire currencies, now predominantly used in corrosion-resistant electronics."
	stack_type = /obj/item/stack/material/gold
	icon_colour = "#EDD12F"
	weight = 25
	hardness = 25
	integrity = 100
	sheet_singular_name = "ingot"
	sheet_plural_name = "ingots"
	is_fusion_fuel = 1
	ore_smelts_to = MATERIAL_GOLD
	ore_result_amount = 5
	ore_deposit_radius = 1
	ore_overlay = "nugget"
	ore_name = "native gold"

/material/gold/bronze //placeholder for ashtrays
	name = "bronze"
	lore_text = "An alloy of copper and tin."
	icon_colour = "#EDD12F"
	ore_smelts_to = null
	ore_compresses_to = null
	alloy_product = FALSE

/material/silver
	name = "silver"
	lore_text = "A soft, white, lustrous transition metal. Has many and varied industrial uses in electronics, solar panels and mirrors."
	stack_type = /obj/item/stack/material/silver
	icon_colour = "#D1E6E3"
	weight = 22
	hardness = 50
	sheet_singular_name = "ingot"
	sheet_plural_name = "ingots"
	is_fusion_fuel = 1
	ore_smelts_to = MATERIAL_SILVER
	ore_result_amount = 5
	ore_deposit_radius = 2
	ore_overlay = "shiny"
	ore_name = "native silver"

/material/supermatter
	name = "exotic matter"
	lore_text = "Non-baryonic 'exotic' matter features heavily in theoretical artificial wormholes, and underpins the workings of the commonly-used gravity drive."
	icon_colour = "#FFFF00"
	radioactivity = 20
	stack_type = null
	luminescence = 3
	ignition_point = PHORON_MINIMUM_BURN_TEMPERATURE
	icon_base = "stone"
	shard_type = SHARD_SHARD
	hardness = 30
	door_icon_base = "stone"
	sheet_singular_name = "crystal"
	sheet_plural_name = "crystals"
	is_fusion_fuel = 1

/material/stone
	name = "sandstone"
	lore_text = "A clastic sedimentary rock. The cost of boosting it to orbit is almost universally much higher than the actual value of the material."
	stack_type = /obj/item/stack/material/sandstone
	icon_base = "stone"
	icon_reinf = "reinf_stone"
	icon_colour = "#D9C179"
	shard_type = SHARD_STONE_PIECE
	weight = 22
	hardness = 55
	door_icon_base = "stone"
	sheet_singular_name = "brick"
	sheet_plural_name = "bricks"
	conductive = 0

/material/stone/marble
	name = "marble"
	lore_text = "A metamorphic rock largely sourced from Earth. Prized for use in extremely expensive decorative surfaces."
	icon_colour = "#AAAAAA"
	weight = 26
	hardness = 100
	integrity = 201 //hack to stop kitchen benches being flippable, todo: refactor into weight system
	stack_type = /obj/item/stack/material/marble

/material/steel
	name = "steel"
	lore_text = "A strong, flexible alloy of iron and carbon. Probably the single most fundamentally useful and ubiquitous substance in human space."
	stack_type = /obj/item/stack/material/steel
	integrity = 150
	icon_base = "solid"
	icon_reinf = "reinf_over"
	icon_colour = "#666666"
	hitsound = 'sound/weapons/smash.ogg'
	composite_material = list(MATERIAL_HEMATITE = 1875, MATERIAL_GRAPHENE = 1875)
	alloy_product = TRUE

/material/steel/holographic
	name = "holosteel"
	display_name = MATERIAL_STEEL
	stack_type = null
	shard_type = SHARD_NONE
	conductive = 0
	hidden_from_codex = TRUE
	composite_material = null
	alloy_product = FALSE

/material/plasteel
	name = "plasteel"
	lore_text = "When regular high-tensile steel isn't tough enough to get the job done, the smart consumer turns to frankly absurd alloys of steel and an extremely hard platinum metal, osmium."
	stack_type = /obj/item/stack/material/plasteel
	integrity = 400
	melting_point = 6000
	icon_base = "solid"
	icon_reinf = "reinf_over"
	icon_colour = "#777777"
	explosion_resistance = 25
	hardness = 80
	weight = 23
	composite_material = list(MATERIAL_HEMATITE = 1250, MATERIAL_GRAPHENE = 1250, MATERIAL_PLATINUM = 1250)
	hitsound = 'sound/effects/blobattack.ogg'
	alloy_product = TRUE

/material/plasteel/titanium
	name = "titanium"
	lore_text = "A light, strong, corrosion-resistant metal. Perfect for cladding high-velocity ballistic supply pods."
	stack_type = null
	icon_base = "metal"
	door_icon_base = "metal"
	icon_colour = "#D1E6E3"
	icon_reinf = "reinf_metal"
	composite_material = null
	alloy_product = FALSE

/material/glass
	name = "glass"
	lore_text = "A brittle, transparent material made from molten silicates. It is generally not a liquid."
	stack_type = /obj/item/stack/material/glass
	flags = MATERIAL_BRITTLE
	icon_colour = "#00E1FF"
	opacity = 0.3
	integrity = 50
	shard_type = SHARD_SHARD
	tableslam_noise = 'sound/effects/Glasshit.ogg'
	hardness = 50
	weight = 14
	door_icon_base = "stone"
	destruction_desc = "shatters"
	window_options = list("One Direction" = 1, "Full Window" = 4)
	created_window = /obj/structure/window/basic
	rod_product = /obj/item/stack/material/glass/reinforced
	hitsound = 'sound/effects/Glasshit.ogg'
	conductive = 0

/material/glass/build_windows(var/mob/living/user, var/obj/item/stack/used_stack)

	if(!user || !used_stack || !created_window || !window_options.len)
		return 0

	if(!user.IsAdvancedToolUser())
		user << "<span class='warning'>This task is too complex for your clumsy hands.</span>"
		return 1

	var/turf/T = user.loc
	if(!istype(T))
		user << "<span class='warning'>You must be standing on open flooring to build a window.</span>"
		return 1

	var/title = "Sheet-[used_stack.name] ([used_stack.get_amount()] sheet\s left)"
	var/choice = input(title, "What would you like to construct?") as null|anything in window_options

	if(!choice || !used_stack || !user || used_stack.loc != user || user.stat || user.loc != T)
		return 1

	// Get data for building windows here.
	var/list/possible_directions = cardinal.Copy()
	var/window_count = 0
	for (var/obj/structure/window/check_window in user.loc)
		window_count++
		possible_directions  -= check_window.dir

	// Get the closest available dir to the user's current facing.
	var/build_dir = SOUTHWEST //Default to southwest for fulltile windows.
	var/failed_to_build

	if(window_count >= 4)
		failed_to_build = 1
	else
		if(choice in list("One Direction","Windoor"))
			if(possible_directions.len)
				for(var/direction in list(user.dir, turn(user.dir,90), turn(user.dir,180), turn(user.dir,270) ))
					if(direction in possible_directions)
						build_dir = direction
						break
			else
				failed_to_build = 1
			if(!failed_to_build && choice == "Windoor")
				if(!is_reinforced())
					user << "<span class='warning'>This material is not reinforced enough to use for a door.</span>"
					return
				if((locate(/obj/structure/windoor_assembly) in T.contents) || (locate(/obj/machinery/door/window) in T.contents))
					failed_to_build = 1
	if(failed_to_build)
		user << "<span class='warning'>There is no room in this location.</span>"
		return 1

	var/build_path = /obj/structure/windoor_assembly
	var/sheets_needed = window_options[choice]
	if(choice == "Windoor")
		build_dir = user.dir
	else
		build_path = created_window

	if(used_stack.get_amount() < sheets_needed)
		user << "<span class='warning'>You need at least [sheets_needed] sheets to build this.</span>"
		return 1

	// Build the structure and update sheet count etc.
	used_stack.use(sheets_needed)
	new build_path(T, build_dir, 1)
	return 1

/material/glass/proc/is_reinforced()
	return (integrity > 75) //todo

/material/glass/is_brittle()
	return ..() && !is_reinforced()

/material/glass/reinforced
	name = "reinforced glass"
	display_name = "reinforced glass"
	stack_type = /obj/item/stack/material/glass/reinforced
	flags = MATERIAL_BRITTLE
	icon_colour = "#00E1FF"
	opacity = 0.3
	integrity = 100
	shard_type = SHARD_SHARD
	tableslam_noise = 'sound/effects/Glasshit.ogg'
	weight = 17
	composite_material = list(MATERIAL_STEEL = 1875,MATERIAL_GLASS = 3750)
	window_options = list("One Direction" = 1, "Full Window" = 4, "Windoor" = 5)
	created_window = /obj/structure/window/reinforced
	wire_product = null
	rod_product = null

/material/glass/phoron_reinforced
	name = "reinforced borosilicate glass"
	flags = MATERIAL_BRITTLE
	lore_text = "An extremely heat-resistant form of glass."
	icon_colour = "#FC2BC5"
	display_name = "reinforced borosilicate glass"
	stack_type = /obj/item/stack/material/glass/phoronrglass
	composite_material = list() //todo
	created_window = /obj/structure/window/phoronreinforced
	composite_material = list() //todo
	rod_product = null
	integrity = 100

/material/plastic
	name = "plastic"
	lore_text = "A generic polymeric material. Probably the most flexible and useful substance ever created by human science; mostly used to make disposable cutlery."
	stack_type = /obj/item/stack/material/plastic
	flags = MATERIAL_BRITTLE
	icon_base = "solid"
	icon_reinf = "reinf_over"
	icon_colour = "#CCCCCC"
	hardness = 10
	weight = 5
	melting_point = T0C+371 //assuming heat resistant plastic
	conductive = 0

/material/plastic/holographic
	name = "holoplastic"
	display_name = MATERIAL_PLASTIC
	stack_type = null
	shard_type = SHARD_NONE
	hidden_from_codex = TRUE

/material/osmium
	name = "osmium"
	lore_text = "An extremely hard platinum group metal."
	stack_type = /obj/item/stack/material/osmium
	icon_colour = "#9999FF"
	sheet_singular_name = "ingot"
	sheet_plural_name = "ingots"

/material/hydrogen
	name = "hydrogen"
	lore_text = "An extremely abundant element."
	specific_heat = 100
	molar_mass = 0.002
	gas_flags = XGM_GAS_FUEL|XGM_GAS_FUSION_FUEL
	gas_burn_product = MATERIAL_STEAM
	is_fusion_fuel = 1
	icon_colour = "#777777"
	sheet_singular_name = "ingot"
	sheet_plural_name = "ingots"
	mechanics_text = "Hydrogen and its isotopes (deuterium and tritium) can be converted into a fuel rod suitable for a R-UST fusion plant injector by clicking a stack on a fuel compressor. They are the most common fusion fuels."

/material/hydrogen/tritium
	name = "tritium"
	lore_text = "A radioactive isotope of hydrogen. Useful as a fusion reactor fuel material."
	stack_type = /obj/item/stack/material/tritium

/material/hydrogen/deuterium
	name = "deuterium"
	lore_text = "One of the two stable isotopes of hydrogen; also known as heavy hydrogen. Useful as a chemically synthesised fusion reactor fuel material."
	stack_type = /obj/item/stack/material/deuterium
	icon_colour = "#999999"

/material/hydrogen/metallic
	name = "metallic hydrogen"
	display_name = "metallic hydrogen"
	lore_text = "When hydrogen is exposed to extremely high pressures and temperatures, such as at the core of gas giants like Jupiter, it can take on metallic properties and - more importantly - acts as a room temperature superconductor. Achieving solid metallic hydrogen at room temperature, though, has proven to be rather tricky."
	stack_type = /obj/item/stack/material/mhydrogen
	icon_colour = "#E6C5DE"
	ore_smelts_to = MATERIAL_TRITIUM
	ore_compresses_to = MATERIAL_MHYDROGEN
	ore_overlay = "gems"
	ore_name = "raw hydrogen"

/material/platinum
	name = "platinum"
	lore_text = "A very dense, unreactive, precious metal. Has many industrial uses, particularly as a catalyst."
	stack_type = /obj/item/stack/material/platinum
	icon_colour = "#9999FF"
	weight = 27
	sheet_singular_name = "ingot"
	sheet_plural_name = "ingots"
	is_fusion_fuel = 1
	ore_smelts_to = MATERIAL_PLATINUM
	ore_compresses_to = MATERIAL_OSMIUM
	ore_can_alloy = 1
	ore_result_amount = 5
	ore_deposit_radius = 2
	ore_overlay = "shiny"
	ore_name = "raw platinum"

/material/iron
	name = "iron"
	lore_text = "A ubiquitous, very common metal. The epitaph of stars and the primary ingredient in Earth's core."
	stack_type = /obj/item/stack/material/iron
	icon_colour = "#5C5454"
	weight = 22
	sheet_singular_name = "ingot"
	sheet_plural_name = "ingots"
	hitsound = 'sound/weapons/smash.ogg'
	is_fusion_fuel = 1

// Adminspawn only, do not let anyone get this.
/material/elevatorium
	name = "elevatorium"
	display_name = "elevator panelling"
	icon_colour = "#666666"
	stack_type = null
	integrity = 1200
	melting_point = 6000
	explosion_resistance = 200
	hardness = 500
	weight = 500
	hidden_from_codex = TRUE

/material/wood
	name = "wood"
	lore_text = "A fibrous structural material harvested from trees. Don't get a splinter."
	adjective_name = "wooden"
	stack_type = /obj/item/stack/material/wood
	icon_colour = "#824B28"
	integrity = 50
	icon_base = "wood"
	explosion_resistance = 2
	shard_type = SHARD_SPLINTER
	shard_can_repair = 0 // you can't weld splinters back into planks
	hardness = 15
	weight = 18
	melting_point = T0C+300 //okay, not melting in this case, but hot enough to destroy wood
	ignition_point = T0C+288
	dooropen_noise = 'sound/effects/doorcreaky.ogg'
	door_icon_base = "wood"
	destruction_desc = "splinters"
	sheet_singular_name = "plank"
	sheet_plural_name = "planks"
	hitsound = 'sound/effects/woodhit.ogg'
	conductive = 0

/material/wood/holographic
	name = "holowood"
	display_name = "wood"
	stack_type = null
	shard_type = SHARD_NONE
	hidden_from_codex = TRUE

/material/cardboard
	name = "cardboard"
	lore_text = "What with the difficulties presented by growing plants in orbit, a stock of cardboard in space is probably more valuable than gold."
	stack_type = /obj/item/stack/material/cardboard
	flags = MATERIAL_BRITTLE
	integrity = 10
	icon_base = "solid"
	icon_reinf = "reinf_over"
	icon_colour = "#AAAAAA"
	hardness = 1
	weight = 1
	ignition_point = T0C+232 //"the temperature at which book-paper catches fire, and burns." close enough
	melting_point = T0C+232 //temperature at which cardboard walls would be destroyed
	door_icon_base = "wood"
	destruction_desc = "crumples"
	conductive = 0

//TODO PLACEHOLDERS:
/material/leather
	name = "leather"
	icon_colour = "#5C4831"
	flags = MATERIAL_PADDING
	ignition_point = T0C+300
	melting_point = T0C+300
	conductive = 0
	hidden_from_codex = TRUE

/material/carpet
	name = "carpet"
	display_name = "comfy"
	use_name = "red upholstery"
	icon_colour = "#DA020A"
	flags = MATERIAL_PADDING
	ignition_point = T0C+232
	melting_point = T0C+300
	sheet_singular_name = "tile"
	sheet_plural_name = "tiles"
	conductive = 0
	hidden_from_codex = TRUE

/material/cotton
	name = "cotton"
	display_name ="cotton"
	icon_colour = "#FFFFFF"
	flags = MATERIAL_PADDING
	ignition_point = T0C+232
	melting_point = T0C+300
	conductive = 0
	hidden_from_codex = TRUE

/material/cloth_teal
	name = "teal"
	display_name ="teal"
	use_name = "teal cloth"
	icon_colour = "#00EAFA"
	flags = MATERIAL_PADDING
	ignition_point = T0C+232
	melting_point = T0C+300
	conductive = 0
	hidden_from_codex = TRUE

/material/cloth_black
	name = "black"
	display_name = "black"
	use_name = "black cloth"
	icon_colour = "#505050"
	flags = MATERIAL_PADDING
	ignition_point = T0C+232
	melting_point = T0C+300
	conductive = 0
	hidden_from_codex = TRUE

/material/cloth_green
	name = "green"
	display_name = "green"
	use_name = "green cloth"
	icon_colour = "#01C608"
	flags = MATERIAL_PADDING
	ignition_point = T0C+232
	melting_point = T0C+300
	conductive = 0
	hidden_from_codex = TRUE

/material/cloth_purple
	name = "purple"
	display_name = "purple"
	use_name = "purple cloth"
	icon_colour = "#9C56C4"
	flags = MATERIAL_PADDING
	ignition_point = T0C+232
	melting_point = T0C+300
	conductive = 0
	hidden_from_codex = TRUE

/material/cloth_blue
	name = "blue"
	display_name = "blue"
	use_name = "blue cloth"
	icon_colour = "#6B6FE3"
	flags = MATERIAL_PADDING
	ignition_point = T0C+232
	melting_point = T0C+300
	conductive = 0
	hidden_from_codex = TRUE

/material/cloth_beige
	name = "beige"
	display_name = "beige"
	use_name = "beige cloth"
	icon_colour = "#E8E7C8"
	flags = MATERIAL_PADDING
	ignition_point = T0C+232
	melting_point = T0C+300
	conductive = 0
	hidden_from_codex = TRUE

/material/cloth_lime
	name = "lime"
	display_name = "lime"
	use_name = "lime cloth"
	icon_colour = "#62E36C"
	flags = MATERIAL_PADDING
	ignition_point = T0C+232
	melting_point = T0C+300
	conductive = 0
	hidden_from_codex = TRUE

/material/oxygen
	name = "oxygen"
	specific_heat = 20
	molar_mass = 0.032
	gas_flags = XGM_GAS_OXIDIZER | XGM_GAS_FUSION_FUEL
	is_fusion_fuel = TRUE

/material/nitrogen
	name = "nitrogen"
	specific_heat = 20
	molar_mass = 0.028

/material/carbon_dioxide
	name = "carbon dioxide"
	specific_heat = 30
	molar_mass = 0.044

/material/petroleum
	name = "petroleum"
	lore_text = "An ubiquitous fossil fuel with many uses."
	specific_heat = 200
	molar_mass = 0.405
	gas_tile_overlay = "gas_dense"
	gas_tile_overlay_colour = "#FFBB00"
	gas_overlay_limit = 0.7
	gas_flags = XGM_GAS_FUEL | XGM_GAS_CONTAMINANT | XGM_GAS_FUSION_FUEL

/material/nitrous_oxide
	name = "nitrous oxide"
	specific_heat = 40
	molar_mass = 0.044
	gas_tile_overlay = "gas_sparse"
	gas_overlay_limit = 1
	gas_flags = XGM_GAS_OXIDIZER

/material/water
	name = "steam"
	specific_heat = 30
	molar_mass = 0.020
	gas_tile_overlay = "gas_dense"

/material/helium
	name = "helium"
	specific_heat = 80
	molar_mass = 0.004
	gas_flags = XGM_GAS_FUSION_FUEL

/material/fusion_reactant
	name = "boron"
	gas_flags = XGM_GAS_FUSION_FUEL
	is_fusion_fuel = TRUE

/material/fusion_reactant/silicon
	name = "silicon"

/material/fusion_reactant/lithium
	name = "lithium"