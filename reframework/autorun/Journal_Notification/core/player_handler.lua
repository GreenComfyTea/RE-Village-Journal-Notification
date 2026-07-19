local this = {};

local modules = require("Journal_Notification.modules");

this.player = {};
this.player.is_enable_damage = true;
this.player.is_enable_use_item = true;

local player_core_fps_type_def = modules.reframework_globals.sdk.find_type_definition("app.PlayerCoreFPS");
local character_status_fps_field = player_core_fps_type_def:get_field("CharacterStatus");
local late_update_fps_method = player_core_fps_type_def:get_method("lateUpdate");
local get_is_enable_damage_fps_method = player_core_fps_type_def:get_method("get_IsEnableDamage");
local set_is_enable_damage_fps_method = player_core_fps_type_def:get_method("set_IsEnableDamage");

local player_core_tps_type_def = modules.reframework_globals.sdk.find_type_definition("app.PlayerCoreTPS");
local character_status_tps_field = player_core_tps_type_def:get_field("CharacterStatus");
local late_update_tps_method = player_core_tps_type_def:get_method("lateUpdate");
local get_is_enable_damage_tps_method = player_core_tps_type_def:get_method("get_IsEnableDamage");

local player_status_type_def = modules.reframework_globals.sdk.find_type_definition("app.PlayerStatus");
local get_is_player_method = player_status_type_def:get_method("get_isPlayer");
local get_is_enable_use_item_method = player_status_type_def:get_method("get_isEnableUseItem");

function this.on_late_update_fps(player_core_fps)
    local character_status = character_status_fps_field:get_data(player_core_fps);
    if character_status == nil then
        modules.error_handler.report("player_handler.on_late_update_fps", "No Character Status");
        return;
    end

    local is_player = get_is_player_method:call(character_status);
    if is_player == nil then
        modules.error_handler.report("player_handler.on_late_update_fps", "No IsPlayer");
        return;
    end

    if not is_player then
        return;
    end

	local is_enable_use_item = get_is_enable_use_item_method:call(character_status);
	if is_enable_use_item == nil then
		modules.error_handler.report("player_handler.on_late_update_fps", "No IsEnableUseItem");
		return;
	end

	local is_enable_damage = get_is_enable_damage_fps_method:call(player_core_fps);
    if is_enable_damage == nil then
        modules.error_handler.report("player_handler.on_late_update_fps", "No IsEnableDamage");
        return;
    end

	this.player.is_enable_use_item = is_enable_use_item;
	this.player.is_enable_damage = is_enable_damage;
end

function this.on_late_update_tps(player_core_tps)
    local character_status = character_status_tps_field:get_data(player_core_tps);
    if character_status == nil then
        modules.error_handler.report("player_handler.on_late_update_tps", "No Character Status");
        return;
    end

    local is_player = get_is_player_method:call(character_status);
    if is_player == nil then
        modules.error_handler.report("player_handler.on_late_update_tps", "No IsPlayer");
        return;
    end

    if not is_player then
        return;
    end

    local is_enable_use_item = get_is_enable_use_item_method:call(character_status);
	if is_enable_use_item == nil then
		modules.error_handler.report("player_handler.on_late_update_tps", "No IsEnableUseItem");
		return;
	end
	
    local is_enable_damage = get_is_enable_damage_tps_method:call(player_core_tps);
    if is_enable_damage == nil then
        modules.error_handler.report("player_handler.on_late_update_tps", "No IsEnableDamage");
        return;
    end

	this.player.is_enable_use_item = is_enable_use_item;
    this.player.is_enable_damage = is_enable_damage;
end

function this.on_set_is_enable_damage_fps(is_enable_damage)
    this.player.is_enable_damage = is_enable_damage;
end

function this.init_module()
	modules.reframework_globals.sdk.hook(late_update_fps_method, function(args)
        local player_core_fps = modules.reframework_globals.sdk.to_managed_object(args[2]);

		modules.throttle.throttle(this.on_late_update_fps, modules.config.current_config.settings.timer_delays.update_player_data_delay, player_core_fps);
	end, function(retval)
		return retval;
    end);

    modules.reframework_globals.sdk.hook(late_update_tps_method, function(args)
        local player_core_tps = modules.reframework_globals.sdk.to_managed_object(args[2]);

		modules.throttle.throttle(this.on_late_update_tps, modules.config.current_config.settings.timer_delays.update_player_data_delay, player_core_tps);
	end, function(retval)
		return retval;
    end);

	-- Works for TPS as well
	modules.reframework_globals.sdk.hook(set_is_enable_damage_fps_method, function(args)
        local is_enable_damage = (modules.reframework_globals.sdk.to_int64(args[3]) & 1) == 1;

        this.on_set_is_enable_damage_fps(is_enable_damage);
	end, function(retval)
		return retval;
    end);
end

return this;