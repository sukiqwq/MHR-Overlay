local non_players = {};
local config;
local table_helpers;
local singletons;
local customization_menu;
local non_player_damage_UI_entity;
local time;
local quest_status;
local drawing;
local language;
local player;

non_players.servant_list = {};
non_players.otomo_list = {};

function non_players.new(id, name, is_otomo)
	local non_player = {};
	non_player.id = id;
	non_player.name = name;

	non_player.is_player = false;
	non_player.is_otomo = is_otomo;

	non_player.join_time = -1;
	non_player.first_hit_time = -1;
	non_player.dps = 0;

	non_player.small_monsters = player.init_damage_sources()
	non_player.large_monsters = player.init_damage_sources();

	non_player.display = {};
	non_player.display.total_damage = 0;
	non_player.display.physical_damage = 0;
	non_player.display.elemental_damage = 0;
	non_player.display.ailment_damage = 0;

	non_players.init_UI(non_player);

	return non_player;
end

function non_players.get_servant(servant_id)
	return non_players.servant_list[servant_id];
end

function non_players.get_otomo(otomo_id)
	return non_players.otomo_list[otomo_id];
end

function non_players.init()
	non_players.servant_list = {};
	non_players.otomo_list = {};
end

local servant_manager_type_def = sdk.find_type_definition("snow.ai.ServantManager");
local get_quest_servant_id_list_method = servant_manager_type_def:get_method("getQuestServantIdList");
local get_ai_control_by_servant_id_method = servant_manager_type_def:get_method("getAIControlByServantID");

local list_type_def = get_quest_servant_id_list_method:get_return_type();
local get_count_method = list_type_def:get_method("get_Count");
local get_item_method = list_type_def:get_method("get_Item");

local ai_control_type_def = get_ai_control_by_servant_id_method:get_return_type();
local get_servant_info_method = ai_control_type_def:get_method("get_ServantInfo");

local servant_info_type_def = get_servant_info_method:get_return_type();
local get_servant_name_method = servant_info_type_def:get_method("get_ServantName");
local get_servant_player_index_method = servant_info_type_def:get_method("get_ServantPlayerIndex");

local lobby_manager_type_def = sdk.find_type_definition("snow.LobbyManager");
local quest_otomo_info_field = lobby_manager_type_def:get_field("_questOtomoInfo");
local otomo_info_field = lobby_manager_type_def:get_field("_OtomoInfo");

local array_otomo_info_type_def = otomo_info_field:get_type();
local array_get_count_method = array_otomo_info_type_def:get_method("get_Count");
local array_get_item_method = array_otomo_info_type_def:get_method("get_Item");

local otomo_info_type_def = sdk.find_type_definition("snow.LobbyManager.OtomoInfo")
local name_field = otomo_info_type_def:get_field("_Name");
local level_field = otomo_info_type_def:get_field("_Level");

--local guid_equals_method = guid_type:get_method("Equals(System.Guid)");

function non_players.update_servant_list()
	if singletons.servant_manager == nil then
		return;
	end

	local quest_servant_id_list = get_quest_servant_id_list_method:call(singletons.servant_manager);
	if quest_servant_id_list == nil then
		customization_menu.status = "No quest servant id list";
		return;
	end

	local servant_count = get_count_method:call(quest_servant_id_list);
	if servant_count == nil then
		customization_menu.status = "No quest servant id list count";
		return;
	end

	for i = 0, servant_count - 1 do
		local servant_id = get_item_method:call(quest_servant_id_list, i);
		if servant_id == nil then
			goto continue;
		end


		local servant_name = "Follower";
		local player_id = -1; 
		local ai_control = get_ai_control_by_servant_id_method:call(singletons.servant_manager, servant_id);
		
		if ai_control ~= nil then
			local servant_info = get_servant_info_method:call(ai_control);
			if servant_info ~= nil then
				local name = get_servant_name_method:call(servant_info);
				
				if name ~= nil then
					servant_name = name;
				end

				local id = get_servant_player_index_method:call(servant_info);
				
				if id == nil then
					goto continue;
				end

				player_id = id;
			end
		end

		if non_players.servant_list[player_id] == nil then
			local servant = non_players.new(player_id, servant_name, false);
			non_players.servant_list[player_id] = servant;
		end

		::continue::
	end
end

function non_players.update_otomo_list(is_on_quest)
	if is_on_quest then
		non_players.update_otomo_list_(quest_otomo_info_field);
	else
		non_players.update_otomo_list_(otomo_info_field);
	end
end

function  non_players.update_otomo_list_(otomo_info_field_)
	-- otomos
	-- offline quest
	--[[if false == true then
		local first_otomo_info = singletons.otomo_manager:call("getMasterOtomoInfo", 0);
		if first_otomo_info then
			local name = first_otomo_info:get_field("Name");
			local id = first_otomo_info:get_field("MemberID");
			--local level = firstOtomo:get_field("Level")
			xy = string.format("%d = %s", id, name);
		end

		local second_tomo_info = singletons.otomo_manager:call("getMasterOtomoInfo", 1);
		if second_tomo_info then
			local name = second_tomo_info:get_field("Name");
			local id = second_tomo_info:get_field("MemberID");
			--local level = firstOtomo:get_field("Level")
			xy = xy .. string.format("\n%d = %s", id, name);
		end
	end--]]

	

	local otomo_info_list = otomo_info_field_:get_data(singletons.lobby_manager);
	
	-- lobby, training area and online quest
	if otomo_info_list == nil then
		customization_menu.status = "No otomo info list";
		return;
	end

	local count = array_get_count_method:call(otomo_info_list);
	if count == nil then
		customization_menu.status = "No otomo info list count";
		return;
	end

	xy = "";
	do return end;
	for i = 0, count - 1 do
		local otomo_info = array_get_item_method:call(otomo_info_list, i);
		if otomo_info == nil then
			goto continue
		end
		local name = otomo_info:get_field("_Name");
		local level = otomo_info:get_field("_Level");
		local guid = otomo_info:get_field("_UniqueID");

		xy = xy .. string.format("[%d] %s - %d\n", level, name, order);

		if non_players.list[player_id] == nil or not guid_equals_method:call(player.list[player_id].guid, player_guid) -- player.list[player_id].guid ~= player_guid
		then
			local _player = non_players.new(player_id, player_guid, player_name, player_master_rank, player_hunter_rank);
			player.list[player_id] = _player;

			if player_name == player.myself.name and player_hunter_rank == player.myself.hunter_rank and player_master_rank ==
				player.myself.master_rank then
				player.myself = _player;
			end
		end

		::continue::
	end
end

function non_players.init_UI(non_player)
	local cached_config = config.current_config.damage_meter_UI;

	non_player.damage_UI = non_player_damage_UI_entity.new(cached_config.damage_bar,
		cached_config.highlighted_damage_bar, cached_config.player_name_label, cached_config.dps_label,
		cached_config.damage_value_label, cached_config.damage_percentage_label);

end

function non_players.draw(non_player, position_on_screen, opacity_scale, top_damage, top_dps)
	non_player_damage_UI_entity.draw(non_player, position_on_screen, opacity_scale, top_damage, top_dps);
end

function non_players.init_module()
	config = require("MHR_Overlay.Misc.config");
	table_helpers = require("MHR_Overlay.Misc.table_helpers");
	singletons = require("MHR_Overlay.Game_Handler.singletons");
	customization_menu = require("MHR_Overlay.UI.customization_menu");
	non_player_damage_UI_entity = require("MHR_Overlay.UI.UI_Entities.non_player_damage_UI_entity");
	time = require("MHR_Overlay.Game_Handler.time");
	quest_status = require("MHR_Overlay.Game_Handler.quest_status");
	drawing = require("MHR_Overlay.UI.drawing");
	language = require("MHR_Overlay.Misc.language");
	player = require("MHR_Overlay.Damage_Meter.player");

	non_players.init();
end

return non_players;