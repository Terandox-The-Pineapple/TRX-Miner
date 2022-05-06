--Turtle Slots ( 1=Fackeln, 2=Truhe, 3=Fuel )
--Storage Slots ( 1-3=Reserviert für System, 4-w=Lagerplatz, w-x(3 Slots)=Reserviert für System, x-y=Fackeln, y-z=Kohle )

local run_amount = ...
local whitelist_drops = { "#c:ores", "minecraft:ancient_debris" }
local whitelist_compact = { "minecraft:diamond", "minecraft:lapis_lazuli", "minecraft:raw_iron", "minecraft:redstone", "minecraft:raw_gold", "minecraft:gold_nugget", "minecraft:emerald", "minecraft:raw_copper", "minecraft:coal", "minecraft:gold_ingot" }
local whitelist_keep = { "minecraft:quartz", "minecraft:diamond_block", "minecraft:lapis_block", "minecraft:raw_iron_block", "minecraft:redstone_block", "minecraft:raw_gold_block", "minecraft:gold_ingot", "minecraft:gold_block", "minecraft:emerald_block", "minecraft:raw_copper_block", "minecraft:coal_block", "+compactable", "+ores" }
local whitelist_only_vein_mining = { "minecraft:obsidian" }
local whitelist_area_filler = { "minecraft:deepslate", "minecraft:cobbled_deepslate", "minecraft:stone", "minecraft:cobblestone", "minecraft:netherrack", "#minecraft:nylium" }
local whitelist_replace_lava = { "!minecraft:lava", "!minecraft:water" }

local max_ore_check = 32
local needed_fuel_level = 2000
local turtle_direction = { "N", "E", "S", "W" }
local storage_coal_slots = 2
local storage_torch_slots = 2
local strip_2x2 = false
local do_storage = true
local do_vein_mining = true
local only_vein_mining = false
local tunnel_spacing = 3
local funny_chunk_loading = false
local replace_lava = false
local filler_slots = 2
if fs.exists("data") == false then shell.run("pastebin get F6qPCGfQ data") end
local data_lib = require("data")

local scan_log = fs.open("trx-miner.log","w")
scan_log.flush()
scan_log.write("Log of all vein-mining actions\n")

if fs.exists("trx-miner.conf") == false then
	local options = {}
	options["whitelists"] = {}
	options["whitelists"]["ores"] = whitelist_drops
	options["whitelists"]["compactable"] = whitelist_compact
	options["whitelists"]["must_keep"] = whitelist_keep
	options["whitelists"]["only_vein_mining"] = whitelist_only_vein_mining
	options["whitelists"]["area_filler"] = whitelist_area_filler
	options["whitelists"]["replace_lava"] = whitelist_replace_lava
	options["storage"] = {}
	options["storage"]["coal_slots"] = storage_coal_slots
	options["storage"]["torch_slots"] = storage_torch_slots
	options["storage"]["enabled"] = do_storage
	options["vein_mining"] = {}
	options["vein_mining"]["vein_check_limit"] = max_ore_check
	options["vein_mining"]["do_only_vein_mining"] = only_vein_mining
	options["vein_mining"]["enabled"] = do_vein_mining
	options["mining"] = {}
	options["mining"]["strip2x2"] = strip_2x2
	options["mining"]["tunnel_spacing"] = tunnel_spacing
	options["mining"]["funny_chunk_loading"] = funny_chunk_loading
	options["replace_lava"] = {}
	options["replace_lava"]["enabled"] = replace_lava
	options["replace_lava"]["filler_slots"] = filler_slots
	data_lib.set("options",textutils.serialize(options),"trx-miner.conf")
else
	local new_options = textutils.unserialise(data_lib.get("options","trx-miner.conf"))
	if new_options["whitelists"] ~= nil then
		if new_options["whitelists"]["ores"] ~= nil then whitelist_drops = new_options["whitelists"]["ores"] end
		if new_options["whitelists"]["compactable"] ~= nil then whitelist_compact = new_options["whitelists"]["compactable"] end
		if new_options["whitelists"]["must_keep"] ~= nil then whitelist_keep = new_options["whitelists"]["must_keep"] end
		if new_options["whitelists"]["only_vein_mining"] ~= nil then whitelist_only_vein_mining = new_options["whitelists"]["only_vein_mining"] end
		if new_options["whitelists"]["area_filler"] ~= nil then whitelist_area_filler = new_options["whitelists"]["area_filler"] end
		if new_options["whitelists"]["replace_lava"] ~= nil then whitelist_replace_lava = new_options["whitelists"]["replace_lava"] end
	end
	if new_options["storage"] ~= nil then
		if new_options["storage"]["coal_slots"] ~= nil then storage_coal_slots = new_options["storage"]["coal_slots"] end
		if new_options["storage"]["torch_slots"] ~= nil then storage_torch_slots = new_options["storage"]["torch_slots"] end
		if new_options["storage"]["enabled"] ~= nil then do_storage = new_options["storage"]["enabled"] end
	end
	if new_options["vein_mining"] ~= nil then
		if new_options["vein_mining"]["vein_check_limit"] ~= nil then max_ore_check = new_options["vein_mining"]["vein_check_limit"] end
		if new_options["vein_mining"]["enabled"] ~= nil then do_vein_mining = new_options["vein_mining"]["enabled"] end
		if new_options["vein_mining"]["do_only_vein_mining"] ~= nil then only_vein_mining = new_options["vein_mining"]["do_only_vein_mining"] end
	end
	if new_options["mining"] ~= nil then
		if new_options["mining"]["strip2x2"] ~= nil then strip_2x2 = new_options["mining"]["strip2x2"] end
		if new_options["mining"]["tunnel_spacing"] ~= nil then tunnel_spacing = new_options["mining"]["tunnel_spacing"] end
		if new_options["mining"]["funny_chunk_loading"] ~= nil then funny_chunk_loading = new_options["mining"]["funny_chunk_loading"] end
	end
	if new_options["replace_lava"] ~= nil then
		if new_options["replace_lava"]["enabled"] ~= nil then replace_lava = new_options["replace_lava"]["enabled"] end
		if new_options["replace_lava"]["filler_slots"] ~= nil then filler_slots = tonumber(new_options["replace_lava"]["filler_slots"]) end
	end
	--Set Min and Max Values
	if tunnel_spacing < 2 then tunnel_spacing = 2 end
	if funny_chunk_loading then
		replace_lava = true
		do_vein_mining = true
		do_storage = true
	end
	--Update Config
	new_options["whitelists"] = {}
	new_options["whitelists"]["ores"] = whitelist_drops
	new_options["whitelists"]["compactable"] = whitelist_compact
	new_options["whitelists"]["must_keep"] = whitelist_keep
	new_options["whitelists"]["only_vein_mining"] = whitelist_only_vein_mining
	new_options["whitelists"]["area_filler"] = whitelist_area_filler
	new_options["whitelists"]["replace_lava"] = whitelist_replace_lava
	new_options["storage"] = {}
	new_options["storage"]["coal_slots"] = storage_coal_slots
	new_options["storage"]["torch_slots"] = storage_torch_slots
	new_options["storage"]["enabled"] = do_storage
	new_options["vein_mining"] = {}
	new_options["vein_mining"]["vein_check_limit"] = max_ore_check
	new_options["vein_mining"]["do_only_vein_mining"] = only_vein_mining
	new_options["vein_mining"]["enabled"] = do_vein_mining
	new_options["mining"] = {}
	new_options["mining"]["strip2x2"] = strip_2x2
	new_options["mining"]["tunnel_spacing"] = tunnel_spacing
	new_options["mining"]["funny_chunk_loading"] = funny_chunk_loading
	new_options["replace_lava"] = {}
	new_options["replace_lava"]["enabled"] = replace_lava
	new_options["replace_lava"]["filler_slots"] = filler_slots
	data_lib.set("options",textutils.serialize(new_options),"trx-miner.conf")
end
local my_version = 1.0
if fs.exists("trx-miner.version") == false then
	data_lib.set("version",my_version,"trx-miner.version")
else
	my_version = data_lib.get("version","trx-miner.version")
end
if fs.exists("trx-miner.cversion") == true then shell.run("delete trx-miner.cversion") end
shell.run("pastebin get sNT5F4BB trx-miner.cversion")
shell.run("trx-miner.cversion")
local new_version = data_lib.get("version","trx-miner.cversion")

if (1*new_version) > (1*my_version) and run_amount=="update" then
	data_lib.set("version",new_version,"trx-miner.version")
	shell.run("pastebin get gzweJyen trx-miner.update")
	shell.run("trx-miner.update")
	return true
else
	shell.run("delete trx-miner.cversion")
	if fs.exists("trx-miner.update") then shell.run("delete trx-miner.update") end
end
if do_vein_mining == false then needed_fuel_level = 1000 end
local storage_last_reserved = storage_coal_slots + storage_torch_slots + 3

function main()
	if run_amount == nil then return show_help()
	elseif run_amount == "config" then return shell.run("edit trx-miner.conf")
	elseif run_amount == "version" then return show_version(false)
	elseif run_amount == "setup" then return help_setup(false)
	elseif run_amount == "storage" then return help_storage(false)
	elseif only_vein_mining == true then
		if needFuel(1000) == false then return scan_me_senpai()
		else return false end
	elseif run_amount == "true" then run_amount = 10000 end
	if tonumber(run_amount) > 0 then
		for round=1,run_amount,1 do
			if canRun() then
				dig_tunnel_main()
				compact()
				move_forward(tunnel_spacing+1)
				do_turn_left()
				dig_tunnel_strip()
				compact()
				if strip_2x2 == true then
					do_turn_right()
					turtle.forward()
					do_turn_right()
					turtle.forward()
				else
					do_turn()
					turtle.forward()
				end
				dig_tunnel_strip()
				compact()
				do_turn()
				turtle.forward()
				if do_storage == true then
					do_turn_left()
					use_storage(round)
				else
					do_turn_right()
				end
			else
				break
			end
		end
	else return false end
end

function show_version(help)
	shell.run("clear")
	textutils.slowPrint("Version: "..my_version.."\n"..
		"Newest Version: "..new_version.."\n"..
		"---------------------------------------")
	if help == true then
		textutils.slowPrint("Press B to go back | Press Q to Quit\n"..
		"---------------------------------------")
		local target = read()
		if target == "B" or target == "b" then return true
		elseif target == "Q" or target == "q" then return false
		else return show_version(help) end
	else return true end
end

function show_help()
	shell.run("clear")
	print("Choose 1 option:\n"..
		"1: config\n"..
		"2: version\n"..
		"3: setup\n"..
		"4: storage\n"..
		"5: update\n"..
		"Q: Quit\n")
	local target = read()
	if target == "Q" or target == "q" then return true end
	target = tonumber(target)
	if target == 1 then return shell.run("edit trx-miner.conf")
	elseif target == 2 then 
		if show_version(true) then return show_help()
		else return true end
	elseif target == 3 then
		if help_setup(true) then return show_help()
		else return true end
	elseif target == 4 then
		if help_storage(true) then return show_help()
		else return true end
	elseif target == 5 then
		if (1*new_version) > (1*my_version) then
			data_lib.set("version",new_version,"trx-miner.version")
			shell.run("pastebin get q3ag7ufz trx-miner.update")
			shell.run("trx-miner.update")
			return true
		else return show_help() end
	else return show_help() end
end

function help_storage(help)
	shell.run("clear")
	textutils.slowPrint("If storage is enabled (default = true) :\n"..
		"Place 1 container of choice behind the turtle\n"..
		"Fill the last 2 Slots of this container with Coal or Charcoal\n"..
		"Fill the 2 Slots behind the Coal with Torches\n"..
		"Modded containers are working, too\n"..
		"---------------------------------------")
	if help == true then
		textutils.slowPrint("Press B to go back | Press Q to Quit\n"..
		"---------------------------------------")
		local target = read()
		if target == "B" or target == "b" then return true
		elseif target == "Q" or target == "q" then return false
		else return help_storage(help) end
	else return true end
end

function help_setup(help)
	shell.run("clear")
	textutils.slowPrint("Syntax: 'TRX-Miner <number of runs>'\n"..
		"Example: 'TRX-Miner 4' (Runs the programm 4 times)\n"..
		"The Turtle needs:\n"..
		"1. At Least 13 Torches in Slot 1 (Scales with number of runs)\n"..
		"2. At Least 2 Chests or Barrels in Slot 2\n"..
		"3. At Least 64 Coal or Charcoal in Slot 3\n"..
		"---------------------------------------")
	if help == true then
		textutils.slowPrint("Press B to go back | Press Q to Quit\n"..
		"---------------------------------------")
		local target = read()
		if target == "B" or target == "b" then return true
		elseif target == "Q" or target == "q" then return false
		else return help_setup(help) end
	else return true end
end

function use_storage(round)
	local length = getMainTunnelLength()
	if funny_chunk_loading then 
		do_turn_left()
		turtle.forward()
		do_turn_right()
	end
	if funny_chunk_loading then
		make_way()
	end
	for i=1,round*length,1 do
		turtle.forward()
		if funny_chunk_loading then
			make_way()
		end
	end
	if funny_chunk_loading then
		do_turn_right()
		turtle.forward()
		do_turn_left()
	end
	storage_interact()
	if funny_chunk_loading then
		turtle.up()
		move_forward(2)
		do_turn_left()
		turtle.down()
		turtle.forward()
		do_turn_left()
		move_forward(round*length)
		do_turn_left()
		turtle.forward()
		do_turn_right()
		move_forward(2)
	else
		do_turn()
		move_forward(round*length)
	end
end

function make_way()
	if turtle.detectDown() == false then
		do_replace("D")
	end
end

function getMainTunnelLength()
	local length = 4
	if strip_2x2 == false then length = 3 end
	length = length + (tunnel_spacing-2)
	return length
end

function storage_interact()
	clean_trash()
	for slot=1,16,1 do
		turtle.select(slot)
		turtle.drop()
	end
	local chest=peripheral.wrap("front")
	local storage_size = chest.size()
	local last_storage_slot = chest.size() - storage_last_reserved
	local first_storage_slot = 4
	for slot=1,3,1 do
		chest.pushItems(peripheral.getName(chest),slot,64,last_storage_slot+slot)
	end
	for slot=first_storage_slot,last_storage_slot,1 do
		if chest.getItemDetail(slot) ~= nil then
			if is_in_whitelist(whitelist_compact,chest.getItemDetail(slot,true)) == false or chest.getItemDetail(slot).count < 9 then
				--The cake is a lie
			else
				local stacksize = math.floor(chest.getItemDetail(slot).count / 9)
				local curent_slot = 0
				chest.pushItems(peripheral.getName(chest),slot,64,1)
				for craft_slot=1,9,1 do
					curent_slot = craft_slot
					if craft_slot < 4 then
						--But nothing happened XD
					elseif craft_slot < 7 then
						curent_slot = curent_slot + 1
					else
						curent_slot = curent_slot + 2
					end
					turtle.select(curent_slot)
					turtle.suck(stacksize)
				end
				turtle.select(16)
				turtle.craft()
				drop_off()
				local pushed = false
				local found_1 = false
				local found_2 = false
				if chest.getItemDetail(2) ~= nil then pushed = true end
				if pushed == true then
					for i=first_storage_slot,last_storage_slot,1 do
						if chest.getItemDetail(i) ~= nil then
							if chest.getItemDetail(i).name == chest.getItemDetail(2).name and (chest.getItemDetail(i).count + chest.getItemDetail(2).count) <= 64 then
								chest.pushItems(peripheral.getName(chest),2,64,i)
								found_1 = true
								break
							end
						end
					end
				end
				for i=first_storage_slot,last_storage_slot,1 do
					if chest.getItemDetail(i) ~= nil then
						if chest.getItemDetail(i).name == chest.getItemDetail(1).name and (chest.getItemDetail(i).count + chest.getItemDetail(1).count) <= 64 then
							chest.pushItems(peripheral.getName(chest),1,64,i)
							found_2 = true
							break
						end
					end
				end
				if found_2 == false then chest.pushItems(peripheral.getName(chest),1,64,slot) end
				local free_slot = first_storage_slot
				for l_slot=first_storage_slot,last_storage_slot,1 do
					if chest.getItemDetail(l_slot) == nil then 
						free_slot = l_slot 
						break 
					end
				end
				if found_1 == false then chest.pushItems(peripheral.getName(chest),2,64,free_slot) end
			end
		end
	end
	chest.pushItems(peripheral.getName(chest),last_storage_slot+1,64,1)
	chest.pushItems(peripheral.getName(chest),last_storage_slot+2,64,2)
	chest.pushItems(peripheral.getName(chest),last_storage_slot+3,64,3)
	for slot=1,3,1 do
		turtle.select(slot)
		turtle.suck()
	end
	for slot=first_storage_slot,last_storage_slot,1 do
		local item = chest.getItemDetail(slot)
		if item ~= nil then
			if is_in_whitelist(whitelist_area_filler,item) then
				chest.pushItems(peripheral.getName(chest),slot,64,1)
				local free_slot = 1
				for l_slot=4,16,1 do
					if turtle.getItemDetail(l_slot) == nil then 
						free_slot = l_slot 
						break 
					end
				end
				turtle.select(free_slot)
				turtle.suck()
			end
		end
	end
	storage_get_coal(chest)
	storage_get_torches(chest)
end

function storage_get_coal(chest)
	local storage_size = chest.size()
	local first_coal = storage_size - (storage_coal_slots - 1)
	local last_coal = storage_size
	turtle.select(3)
	if turtle.getItemCount(3) < 64 then
		for slot=first_coal,last_coal,1 do
			if chest.getItemDetail(slot) ~= nil then
				chest.pushItems(peripheral.getName(chest),slot,64-turtle.getItemCount(3),1)
				turtle.suck()
			end
			if turtle.getItemCount(3) == 64 then break end
		end
	end
end

function storage_get_torches(chest)
	local storage_size = chest.size()
	local last_torch = storage_size - storage_coal_slots
	local first_torch = last_torch - (storage_torch_slots - 1)
	turtle.select(1)
	if turtle.getItemCount(1) < 64 then
		for slot=first_torch,last_torch,1 do
			if chest.getItemDetail(slot) ~= nil then
				chest.pushItems(peripheral.getName(chest),slot,64-turtle.getItemCount(1),1)
				turtle.suck()
			end
			if turtle.getItemCount(1) == 64 then break end
		end
	end
end

function compact()
	clean_trash()
	turtle.select(2)
	turtle.place()
	for slot=1,16,1 do
		turtle.select(slot)
		turtle.drop()
	end
	local chest=peripheral.wrap("front")
	local first_slot = 4
	local last_slot = chest.size() - 3
	for slot=1,3,1 do
		chest.pushItems(peripheral.getName(chest),slot,64,last_slot+slot)
	end
	for slot=first_slot,last_slot,1 do
		if chest.getItemDetail(slot) ~= nil then
			if is_in_whitelist(whitelist_compact,chest.getItemDetail(slot,true)) == false or chest.getItemDetail(slot).count < 9 then
				--The cake is a lie
			else
				local stacksize = math.floor(chest.getItemDetail(slot).count / 9)
				local curent_slot = 0
				chest.pushItems(peripheral.getName(chest),slot,64,1)
				for craft_slot=1,9,1 do
					curent_slot = craft_slot
					if craft_slot < 4 then
						--But nothing happened XD
					elseif craft_slot < 7 then
						curent_slot = curent_slot + 1
					else
						curent_slot = curent_slot + 2
					end
					turtle.select(curent_slot)
					turtle.suck(stacksize)
				end
				turtle.select(16)
				turtle.craft()
				drop_off()
				local pushed = false
				local found_1 = false
				local found_2 = false
				if chest.getItemDetail(2) ~= nil then pushed = true end
				if pushed == true then
					for i=first_slot,last_slot,1 do
						if chest.getItemDetail(i) ~= nil then
							if chest.getItemDetail(i).name == chest.getItemDetail(2).name and (chest.getItemDetail(i).count + chest.getItemDetail(2).count) <= 64 then
								chest.pushItems(peripheral.getName(chest),2,64,i)
								found_1 = true
								break
							end
						end
					end
				end
				for i=first_slot,last_slot,1 do
					if chest.getItemDetail(i) ~= nil then
						if chest.getItemDetail(i).name == chest.getItemDetail(1).name and (chest.getItemDetail(i).count + chest.getItemDetail(1).count) <= 64 then
							chest.pushItems(peripheral.getName(chest),1,64,i)
							found_2 = true
							break
						end
					end
				end
				if found_2 == false then chest.pushItems(peripheral.getName(chest),1,64,slot) end
				local free_slot = first_slot
				for l_slot=first_slot,last_slot,1 do
					if chest.getItemDetail(l_slot) == nil then 
						free_slot = l_slot 
						break 
					end
				end
				if found_1 == false then chest.pushItems(peripheral.getName(chest),2,64,free_slot) end
			end
		end
	end
	for slot=1,3,1 do
		chest.pushItems(peripheral.getName(chest),last_slot+slot,64,slot)
	end
	suck_up()
	turtle.select(2)
	turtle.dig()
end

function clean_trash()
	for slot=4,16,1 do
		turtle.select(slot)
		if turtle.getItemCount(slot) > 0 then
			local slot_count, item_count = count_matching_slots(whitelist_area_filler)
			if replace_lava and is_in_whitelist(whitelist_area_filler,turtle.getItemDetail(slot,true)) and slot_count <= filler_slots and item_count <= (filler_slots * 64) then
				--Ich brauche mehr Schokolade...
			elseif replace_lava and is_in_whitelist(whitelist_area_filler,turtle.getItemDetail(slot,true)) and item_count > (filler_slots * 64) then
				turtle.drop(item_count - (filler_slots * 64))
			elseif is_in_whitelist(whitelist_keep,turtle.getItemDetail(slot,true)) == false then 
				turtle.drop() 
			end
		end
	end
end

function suck_up()
	for slot=1,16,1 do
		turtle.select(slot)
		turtle.suck()
	end
end

function drop_off()
	for slot=1,16,1 do
		turtle.select(slot)
		turtle.drop()
	end
end

function dig_tunnel_strip()
	for l=1,6,1 do
		dig_forward(11)
		place_torch()
	end
	if strip_2x2 == true then
		do_turn_right()
		dig_forward(1)
		do_turn_right()
		dig_forward(65)
		turtle.forward()
		do_turn_right()
		turtle.forward()
		do_turn_right()
	else
		do_turn()
		turtle.up()
		move_forward(66)
		turtle.down()
		do_turn()
	end
end

function dig_tunnel_main()
	local depth = getMainTunnelLength()
	dig_forward(depth)
	do_turn_right()
	dig_forward(1)
	do_turn_right()
	dig_forward(depth-1)
	place_torch_up()
	dig_forward(1)
	do_turn_right()
	turtle.forward()
	do_turn_right()
end

function move_forward(amount)
	for i=1,amount,1 do
		turtle.forward()
	end
end

function place_torch_up()
	turtle.select(1)
	turtle.placeUp()
end

function is_in_whitelist(whitelist,item,force)
	force = force or false
	if only_vein_mining == true and force == false then whitelist = whitelist_only_vein_mining end
	for index,id in pairs(whitelist) do
		if string.sub(id,1,1) == "#" then
			local tag = string.sub(id,2,id:len())
			if item.tags and item.tags[tag] == true then return true end
		elseif string.sub(id,1,1) == "+" then
			local table = string.sub(id,2,id:len())
			if table == "ores" then
				if is_in_whitelist(whitelist_drops, item, true) then return true end
			elseif table == "compactable" then
				if is_in_whitelist(whitelist_compact, item, true) then return true end
			elseif table == "must_keep" then
				if is_in_whitelist(whitelist_keep, item, true) then return true end
			elseif table == "only_vein_mining" then
				if is_in_whitelist(whitelist_only_vein_mining, item, true) then return true end
			elseif table == "area_filler" then
				if is_in_whitelist(whitelist_area_filler, item, true) then return true end
			elseif table == "replace_lava" then
				if is_in_whitelist(whitelist_replace_lava, item, true) then return true end
			else
				print("Whitelist '"..table.."' existiert nicht!!!")
				return false
			end
		elseif string.sub(id,1,1) == "!" then
			local name = string.sub(id,2,id:len())
			if name == item.name and item.state.level == 0 then return true end
		else
			if id == item.name then return true end
		end
	end
	return false
end

function do_turn_left()
	turtle.turnLeft()
	turtle_direction = t_rotate(turtle_direction,"L")
	return turtle_direction[1]
end

function do_turn_right()
	turtle.turnRight()
	turtle_direction = t_rotate(turtle_direction,"R")
	return turtle_direction[1]
end

function t_rotate(my_table, direction)
	if my_table ~= nil and direction == "R" then
		local halter = my_table[#my_table]
		local new_table = {}
		new_table[#new_table+1] = halter
		for i=1,#my_table-1,1 do
			new_table[#new_table+1] = my_table[i]
		end
		return new_table
	elseif my_table ~= nil and direction == "L" then
		local halter = my_table[1]
		local new_table = {}
		for i=2,#my_table,1 do
			new_table[#new_table+1] = my_table[i]
		end
		new_table[#new_table+1] = halter
		return new_table
	elseif my_table ~= nil then
		return my_table
	else
		return false
	end
end

function place_torch()
	do_turn()
	turtle.select(1)
	turtle.place()
	do_turn()
end

function dig_forward(amount)
	for round=1,amount,1 do
		do_dig()
		turtle.forward()
		if do_vein_mining then
			scan_me_senpai()
		end
		do_dig_up()
		if do_vein_mining then
			turtle.up()
			scan_me_senpai()
			turtle.down()
		end
	end
end

function scan_me_senpai()
	local matrix = {}
	local scaned = 0
	for i=1,3,1 do
		matrix[i] = {}
		for x=1,3,1 do
			matrix[i][x] = {}
			for y=1,3,1 do
				matrix[i][x][y] = 0
			end
		end
	end
	turtle_direction = { "N", "E", "S", "W" }
	matrix[2][2][2] = 1
	while true do
		if scaned < max_ore_check then
			for i=1,max_ore_check,1 do
				local way = do_scan()
				local max = m_get_max(matrix)
				local z,s,h = m_get_index(matrix,max)
				scan_log.write("List: matrix["..z.."]["..s.."]["..h.."] -M "..max.." -# "..#matrix.."\n")
				if way ~= false then
					scaned = scaned + 1
					local next_zeile, next_spalte, next_hoehe = m_get_next(matrix,way)
					matrix[next_zeile][next_spalte][next_hoehe] = max + 1
					if m_to_small(matrix) == true then matrix = m_extend(matrix) end
					local nz,ns,nh = m_get_index(matrix,(max+1))
					dig_direction(way)
					scan_log.write("Create: matrix["..nz.."]["..ns.."]["..nh.."] -M "..(max+1).." -# "..#matrix.." -W "..way.."\n")
				else
					break
				end
			end
		end
		local m_max = m_get_max(matrix)
		if m_max > 1 then
			local last = m_get_last(matrix)
			move_direction(last)
			local zeile, spalte, hoehe = m_get_index(matrix,m_max)
			matrix[zeile][spalte][hoehe] = 0
			scan_log.write("Delete: matrix["..zeile.."]["..spalte.."]["..hoehe.."] -M "..m_max.." -# "..#matrix.." -L "..last.."\n")
		elseif m_max == 1 then
			while turtle_direction[1] ~= "N" do
				do_turn_right()
			end
			return true
		else
			return false
		end
	end
end

function m_get_last(matrix)
	local m_max = m_get_max(matrix)
	local max_zeile, max_spalte, max_hoehe = m_get_index(matrix,m_max)
	local last_zeile, last_spalte, last_hoehe = m_get_index(matrix,m_max-1)
	local n_index = t_get_index(turtle_direction,"N")
	--{ 1=F , 2=R , 3=B , 4=L }
	local d_last_pos = { 0, 0, 0, 0 }
	local zeile = last_zeile - max_zeile
	local spalte = last_spalte - max_spalte
	local hoehe = last_hoehe - max_hoehe
	if zeile ~= 0 then
		if zeile == 1 then d_last_pos[1] = 1
		elseif zeile == -1 then d_last_pos[3] = 1 end
	elseif spalte ~= 0 then
		if spalte == 1 then d_last_pos[2] = 1
		elseif spalte == -1 then d_last_pos[4] = 1 end
	end
	if n_index > 1 then
		for i=1,n_index-1,1 do
			d_last_pos = t_rotate(d_last_pos,"L")
		end
	end
	if d_last_pos[1] == 1 then return "F"
	elseif d_last_pos[2] == 1 then return "R"
	elseif d_last_pos[3] == 1 then return "B"
	elseif d_last_pos[4] == 1 then return "L"
	elseif hoehe == 1 then return "U"
	elseif hoehe == -1 then return "D"
	else return false end
end


function m_get_next(matrix,next_pos)
	local m_max = m_get_max(matrix)
	local zeile, spalte, hoehe = m_get_index(matrix,m_max)
	local n_index = t_get_index(turtle_direction,"N")
	--{ 1=F , 2=R , 3=B , 4=L }
	local d_next_pos = { 0, 0, 0, 0 }
	if next_pos == "F" then
		d_next_pos[1] = 1
	elseif next_pos == "R" then
		d_next_pos[2] = 1
	elseif next_pos == "L" then
		d_next_pos[4] = 1
	end
	if n_index > 1 then
		for i=1,n_index-1,1 do
			d_next_pos = t_rotate(d_next_pos,"R")
		end
	end
	if d_next_pos[1] == 1 then zeile = zeile + 1
	elseif d_next_pos[2] == 1 then spalte = spalte + 1
	elseif d_next_pos[3] == 1 then zeile = zeile - 1
	elseif d_next_pos[4] == 1 then spalte = spalte - 1
	elseif next_pos == "U" then hoehe = hoehe + 1
	elseif next_pos == "D" then hoehe = hoehe - 1 end
	return zeile, spalte, hoehe
end

function t_get_index(my_table,target)
	for i=1,#my_table,1 do
		if my_table[i] == target then return i end
	end
	return false
end

function m_get_index(matrix, target)
	for zeile=1,#matrix,1 do
		for spalte=1,#matrix[1],1 do
			for hoehe =1,#matrix[1][1],1 do
				if matrix[zeile][spalte][hoehe] == target then return zeile, spalte, hoehe end
			end
		end
	end
	return false
end

function m_extend(matrix)
	local matrix_size = #matrix
	local new_matrix = {}
	for i=1,matrix_size+2,1 do
		new_matrix[i] = {}
		for x=1,matrix_size+2,1 do
			new_matrix[i][x] = {}
			for y=1,matrix_size+2,1 do
				new_matrix[i][x][y] = 0
			end
		end
	end
	for zeile=2,matrix_size+1,1 do
		for spalte=2,matrix_size+1,1 do
			for hoehe=2,matrix_size+1,1 do
				new_matrix[zeile][spalte][hoehe] = matrix[zeile-1][spalte-1][hoehe-1]
			end
		end
	end
	return new_matrix
end

function m_get_max(matrix)
	local max = 0
	for zeile=1,#matrix,1 do
		for spalte=1,#matrix[1],1 do
			for hoehe =1,#matrix[1][1],1 do
				if matrix[zeile][spalte][hoehe] > max then max = matrix[zeile][spalte][hoehe] end
			end
		end
	end
	return max
end

function m_to_small(matrix)
	local m_max = m_get_max(matrix)
	local zeile, spalte, hoehe = m_get_index(matrix,m_max)
	if zeile == 1 or spalte == 1 or hoehe == 1 or zeile == #matrix or spalte == #matrix or hoehe == #matrix then return true
	else return false end
end

function dig_direction(way)
	if way == "U" then
		do_dig_up()
		turtle.up()
		return way
	elseif way == "D" then
		do_dig_down()
		turtle.down()
		return way
	elseif way == "L" then
		do_turn_left()
		do_dig()
		turtle.forward()
		return way
	elseif way == "R" then
		do_turn_right()
		do_dig()
		turtle.forward()
		return way
	elseif way == "F" then
		do_dig()
		turtle.forward()
		return way
	else
		return false
	end
end

function move_direction(way)
	if way == "U" then
		turtle.up()
		return way
	elseif way == "D" then
		turtle.down()
		return way
	elseif way == "L" then
		do_turn_left()
		turtle.forward()
		return way
	elseif way == "R" then
		do_turn_right()
		turtle.forward()
		return way
	elseif way == "F" then
		turtle.forward()
		return way
	elseif way == "B" then
		do_turn()
		turtle.forward()
	else
		return false
	end
end

function do_scan()
	local is_up, data_up = turtle.inspectUp()
	local is_down, data_down = turtle.inspectDown()
	local para = false
	if is_up and para == false then
		if is_in_whitelist(whitelist_drops,data_up) then
			para = "U"
		end
	end
	if is_down and para == false then
		if is_in_whitelist(whitelist_drops,data_down) then
			para = "D"
		end
	end
	do_turn_left()
	local is_left, data_left = turtle.inspect()
	if is_left and para == false then
		if is_in_whitelist(whitelist_drops,data_left) then
			para = "L"
		end
	end
	do_turn()
	local is_right, data_right = turtle.inspect()
	if is_right and para == false then
		if is_in_whitelist(whitelist_drops,data_right) then
			para = "R"
		end
	end
	do_turn_left()
	local is_front, data_front = turtle.inspect()
	if is_front and para == false then
		if is_in_whitelist(whitelist_drops,data_front) then
			para = "F"
		end
	end
	if replace_lava then
		if is_in_whitelist(whitelist_replace_lava,data_up) then do_replace("U") end
		if is_in_whitelist(whitelist_replace_lava,data_down) then do_replace("D") end
		if is_in_whitelist(whitelist_replace_lava,data_left) then do_replace("L") end
		if is_in_whitelist(whitelist_replace_lava,data_right) then do_replace("R") end
		if is_in_whitelist(whitelist_replace_lava,data_front) then do_replace("F") end
	end
	return para
end

function do_replace(way)
	local building_blocks = get_building_blocks()
	if building_blocks ~= false then
		turtle.select(building_blocks)
		if way == "U" then
			turtle.placeUp()
		elseif way == "D" then
			turtle.placeDown()
		elseif way == "L" then
			do_turn_left()
			turtle.place()
			do_turn_right()
		elseif way == "R" then
			do_turn_right()
			turtle.place()
			do_turn_left()
		elseif way == "F" then
			turtle.place()
		else return false end
	end
end

function get_building_blocks()
	for slot=4,16,1 do
		if turtle.getItemDetail(slot,true) ~= nil then
			if is_in_whitelist(whitelist_area_filler,turtle.getItemDetail(slot,true)) then return slot end
		end
	end
	return false
end

function do_turn()
	do_turn_right()
	do_turn_right()
end

function count_matching_slots(whitelist)
	local slot_count = 0
	local count = 0
	for slot=4,16,1 do
		if turtle.getItemDetail(slot) ~= nil then
			if is_in_whitelist(whitelist,turtle.getItemDetail(slot,true)) then
				slot_count = slot_count + 1
				count = count + turtle.getItemCount(slot)
			end
		end
	end
	return slot_count, count
end

function do_dig()
	local is_block, data = turtle.inspect()
	if is_block then
		local slot_count, item_count = count_matching_slots(whitelist_area_filler)
		if is_in_whitelist(whitelist_drops,data) then
			turtle.select(1)
			turtle.dig()
		elseif replace_lava == true and is_in_whitelist(whitelist_area_filler,data) and slot_count <= filler_slots and item_count < (filler_slots*64) then
			turtle.select(1)
			turtle.dig()
		else
			turtle.select(16)
			turtle.dig()
			turtle.drop()
		end
	end
	local done = false
	while done == false do
		if turtle.detect() == true then
			turtle.select(16)
			turtle.dig()
			turtle.drop()
		else
			done = true
		end
	end
end

function do_dig_up()
	local is_block_up, data_up = turtle.inspectUp()
	if is_block_up then
		local slot_count, item_count = count_matching_slots(whitelist_area_filler)
		if is_in_whitelist(whitelist_drops,data_up) then
			turtle.select(1)
			turtle.digUp()
		elseif replace_lava == true and is_in_whitelist(whitelist_area_filler,data_up) and slot_count <= filler_slots and item_count < (filler_slots*64) then
			turtle.select(1)
			turtle.digUp()
		else
			turtle.select(16)
			turtle.digUp()
			turtle.drop()
		end
	end
end

function do_dig_down()
	local is_block_down, data_down = turtle.inspectDown()
	if is_block_down then
		local slot_count, item_count = count_matching_slots(whitelist_area_filler)
		if is_in_whitelist(whitelist_drops,data_down) then
			turtle.select(1)
			turtle.digDown()
		elseif replace_lava == true and is_in_whitelist(whitelist_area_filler,data_down) and slot_count <= filler_slots and item_count < (filler_slots*64) then
			turtle.select(1)
			turtle.digDown()
		else
			turtle.select(16)
			turtle.digDown()
			turtle.drop()
		end
	end
end

function needFuel(amount)
	local fuel = turtle.getFuelLevel()
	if fuel >= amount then
		return false
	else
		turtle.select(3)
		if turtle.getItemCount(3) == 0 then print("Missing Fuel in Slot 3!!!") return false end
		if turtle.getItemCount(3) >= 1 and turtle.getFuelLevel() < amount and turtle.getItemDetail(3,true).tags["minecraft:coals"] == true then
			turtle.refuel(63)
		end
		if turtle.getFuelLevel() >= amount then
			return false
		else
			print("Missing Fuel in Slot 3!!!")
			return true
		end
	end
end

function hasTorch(amount)
	if turtle.getItemCount(1) == 0 then print("Missing Torches in Slot 1!!!") return false end
	if turtle.getItemDetail(1).name == "minecraft:torch" and turtle.getItemCount(1) >= amount then
		return true
	else
		print("Missing Torches in Slot 1!!!")
		return false
	end
end

function hasChest()
	if turtle.getItemCount(2) == 0 then print("Missing 2 Chests or Barrels in Slot 2!!!") return false end
	if turtle.getItemDetail(2).name == "minecraft:chest" or turtle.getItemDetail(2).name == "minecraft:barrel" and turtle.getItemCount(2) >= 2 then
		return true
	else
		print("Missing 2 Chests or Barrels in Slot 2!!!")
		return false
	end
end

function canRun()
	if needFuel(needed_fuel_level) == false and hasTorch(13) and hasChest() and turtle.getItemCount(16) == 0 then
		return true
	else
		print("Programm Finished!!!")
		return false
	end
end

main()
scan_log.close()

return 0