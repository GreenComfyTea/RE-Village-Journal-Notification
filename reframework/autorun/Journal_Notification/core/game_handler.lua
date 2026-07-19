local this = {};

local modules = require("Journal_Notification.modules");

this.game = {};
this.game.is_cutscene_playing = false;
this.game.is_paused = false;
this.game.is_any_chapter = false;
this.game.is_chapter_1 = false;

this.animation = {};
-- "invisible", "fade_in", "visible", "fade_out", "cooldown"
this.animation.state = "invisible";
this.animation.duration = 0;
this.animation.start_time = 0;

local file_categories = {
    [2421270307] = "diary",
    [3287166677] = "file",
    [2490353024] = "recipe",
    [946802604] = "tip",
}

local journal_update_time_seconds_queue = {};

local timer = nil;
local time_margin = 1 / 30;


local update_time_limit = 0.6;
local pause_off_timer = nil;
local cutscene_off_timer = nil;

local content_timer_type_def = modules.reframework_globals.sdk.find_type_definition("app.ContentTimer");
local on_pause_method = content_timer_type_def:get_method("onPause");

local event_system_app_type_def = modules.reframework_globals.sdk.find_type_definition("app.EventSystemApp");
local is_running_event_method = event_system_app_type_def:get_method("isRunningEvent(System.Boolean)");

local file_manager_type_def = modules.reframework_globals.sdk.find_type_definition("app.FileManager");
local add_file_method = file_manager_type_def:get_method("addFile");
local is_completed_file_method = file_manager_type_def:get_method("isCompletedFile");
local has_recipe_method = file_manager_type_def:get_method("hasRecipe");
local find_data_method = file_manager_type_def:get_method("findData");


local file_manager_user_data_unit_type_def = find_data_method:get_return_type();
local get_category_id_method = file_manager_user_data_unit_type_def:get_method("get_categoryID");

local scene_transition_manager_type_def = modules.reframework_globals.sdk.find_type_definition("app.SceneTransitionManager");
local get_current_chapter_method = scene_transition_manager_type_def:get_method("get_CurrentChapter");

function this.update_is_cutscene()
	local event_system_app = modules.singletons.event_system_app;

	if event_system_app == nil then
		modules.error_handler.report("game_handler.update_is_cutscene", "No EventSystemApp");
        return;
    end

	local is_player_event_playing = is_running_event_method:call(event_system_app, true);
	local is_event_playing = is_running_event_method:call(event_system_app, false);

	if is_player_event_playing == nil then
		modules.error_handler.report("game_handler.update_is_cutscene",  "No IsPlayerEventPlaying");
		is_player_event_playing = false;
	end

	if is_event_playing == nil then
		modules.error_handler.report("game_handler.update_is_cutscene", "No IsEventPlaying");
		is_event_playing = false;
	end

	local is_cutscene_playing = is_player_event_playing or is_event_playing;

	-- Cutscene
	if is_cutscene_playing then
		this.game.is_cutscene_playing = true;
		modules.time.remove_delay_timer(cutscene_off_timer);
		cutscene_off_timer = nil;
		return;
	end

	-- Game No Cutscene, State No Cutscene
	if not this.game.is_cutscene_playing then
		modules.time.remove_delay_timer(cutscene_off_timer);
		cutscene_off_timer = nil;
		return;
	end

	-- Game No Cutscene, State Cutscene, Timer is On
	if cutscene_off_timer ~= nil then
		return;
	end

	-- Game No Cutscene, State Cutscene, Timer is Off
	cutscene_off_timer = modules.time.new_delay_timer(function()
		this.game.is_cutscene_playing = false;
		cutscene_off_timer = nil;
	end,
	1.2 * update_time_limit);
end

function this.get_journal_file_category(file_manager, file_id)
    local file_manager_user_data_unit = find_data_method:call(file_manager, file_id);
    if file_manager_user_data_unit == nil then
        modules.error_handler.report("game_handler.get_journal_file_type", "No FileManager UserData Unit");
        return;
    end

    local category_id = get_category_id_method:call(file_manager_user_data_unit);
    if category_id == nil then
        modules.error_handler.report("game_handler.get_journal_file_type", "No Category ID");
        return;
    end

    return file_categories[category_id];
end

function this.get_clamped_fade_in_duration()
    local cached_config = modules.config.current_config;

    local total_duration = cached_config.settings.fade_in_duration + cached_config.settings.fade_out_duration;
    
    local fade_in_duration_percentage = 0;

    if total_duration > 0 then
        fade_in_duration_percentage = cached_config.settings.fade_in_duration / total_duration;
    end

    local clamped_fade_in_duration = cached_config.settings.fade_in_duration;

    if total_duration > cached_config.settings.duration then
        clamped_fade_in_duration = fade_in_duration_percentage * cached_config.settings.duration;
    end

    return clamped_fade_in_duration;
end

function this.get_clamped_visible_duration()
    local cached_config = modules.config.current_config;

    local clamped_fade_in_duration = this.get_clamped_fade_in_duration();
    local clamped_fade_out_duration = this.get_clamped_fade_out_duration();

    local clamped_duration = cached_config.settings.duration - clamped_fade_in_duration - clamped_fade_out_duration;

    return clamped_duration;
end

function this.get_clamped_fade_out_duration()
    local cached_config = modules.config.current_config;

    local total_duration = cached_config.settings.fade_in_duration + cached_config.settings.fade_out_duration;

    local fade_out_duration_percentage = 0;

    if total_duration > 0 then
        fade_out_duration_percentage = cached_config.settings.fade_out_duration / total_duration;
    end

    local clamped_fade_out_duration = cached_config.settings.fade_out_duration;

    if total_duration > cached_config.settings.duration then
        clamped_fade_out_duration = fade_out_duration_percentage * cached_config.settings.duration;
    end

    return clamped_fade_out_duration;
end

function this.maybe_start_fade_in()
    local cached_config = modules.config.current_config;

    if not cached_config.settings.render_during_cutscenes and this.game.is_cutscene_playing then
        return;
    end

    if not cached_config.settings.render_when_game_timer_is_paused and this.game.is_paused then
        return;
    end

    if not this.game.is_any_chapter then
        return;
    end

    if not cached_config.settings.render_in_winters_house_intro and this.game.is_chapter_1 then
        return;
    end

    if not cached_config.settings.render_when_player_cant_take_damage and not modules.player_handler.player.is_enable_damage then
        return;
    end

    if not cached_config.settings.render_when_player_cant_use_items and not modules.player_handler.player.is_enable_use_item then
        return;
    end

    if journal_update_time_seconds_queue.length <= 0 then
        return;
    end

    if this.animation.state ~= 'invisible' then
        return;
    end

    this.start_fade_in();
end

function this.start_fade_in()
    local current_time = modules.time.total_elapsed_script_seconds;

    this.animation.state = "fade_in";
    this.animation.duration = this.get_clamped_fade_in_duration();
    this.animation.start_time = current_time;

    timer = modules.time.new_delay_timer(this.start_visible, this.animation.duration + time_margin);
end

function this.start_visible()
    local current_time = modules.time.total_elapsed_script_seconds;

    if journal_update_time_seconds_queue.length == 1 then
        this.animation.state = "visible";
        this.animation.duration = this.get_clamped_visible_duration();
        this.animation.start_time = current_time;

        timer = modules.time.new_delay_timer(this.start_fade_out, this.animation.duration + time_margin);
        return;
    end

    this.start_fade_out();
end

function this.start_fade_out()
    local current_time = modules.time.total_elapsed_script_seconds;

    this.animation.state = "fade_out";
    this.animation.duration = this.get_clamped_fade_out_duration();
    this.animation.start_time = current_time;

    timer = modules.time.new_delay_timer(this.start_cooldown, this.animation.duration + time_margin);
end

function this.start_cooldown()
    local cached_config = modules.config.current_config;
    local current_time = modules.time.total_elapsed_script_seconds;

    this.animation.state = "cooldown";
    this.animation.duration = cached_config.settings.cooldown_duration;
    this.animation.start_time = current_time;

    timer = modules.time.new_delay_timer(this.on_cooldown_end, this.animation.duration + time_margin);
end

function this.on_cooldown_end()
    local current_time = modules.time.total_elapsed_script_seconds;

    this.animation.state = "invisible";
    this.animation.duration = math.maxinteger;
    this.animation.start_time = current_time;

    timer = nil;
    journal_update_time_seconds_queue.dequeue();

    this.maybe_start_fade_in();
end

function this.on_pause(is_paused_int)
	if is_paused_int == nil then
		modules.error_handler.report("game_handler.on_pause", "No IsPaused Int");
		return;
	end

	local is_paused = (is_paused_int & 1) == 1;

	-- Pause
	if is_paused then
		this.game.is_paused = true;
		modules.time.remove_delay_timer(pause_off_timer);
		pause_off_timer = nil;
		return;
	end

	-- Game No Pause, State No Pause
	if not this.game.is_paused then
		modules.time.remove_delay_timer(pause_off_timer);
		pause_off_timer = nil;
		return;
	end

	-- Game No Pause, State Pause, Timer is On
	if pause_off_timer ~= nil then
		return;
	end

	-- Game No Pause, State Pause, Timer is Off
	pause_off_timer = modules.time.new_delay_timer(function()
		this.game.is_paused = false;
		pause_off_timer = nil;
	end, update_time_limit);

end

function this.update_chapter()
	this.game.is_any_chapter = false;
	this.game.is_chapter_1 = false;

	local scene_transition_manager = modules.singletons.scene_transition_manager;
	if scene_transition_manager == nil then
		modules.error_handler.report("game_handler.update_chapter", "No sceneTransitionManager");
		return;
	end

	local current_chapter = get_current_chapter_method:call(scene_transition_manager);
	if current_chapter == nil then
		modules.error_handler.report("game_handler.update_chapter", "No currentChapter");
		return;
	end

    if current_chapter == "" then
        return;
    end

    this.game.is_any_chapter = true;
    this.game.is_chapter_1 = current_chapter == "Chapter1";
end


function this.update()
    this.update_is_cutscene();
    this.update_chapter();
    
    if journal_update_time_seconds_queue.length >= 1 and this.animation.state == 'invisible' then
        this.maybe_start_fade_in();
        return;
    end
end

function this.on_add_file(file_manager, file_id)
    local cached_config = modules.config.current_config;

    local file_category = this.get_journal_file_category(file_manager, file_id);
    if file_category == nil then
        return;
    end

    if file_category == "recipe" then
        local has_recipe = has_recipe_method:call(file_manager, file_id);
        if has_recipe == nil then
            modules.error_handler.report("game_handler.on_add_file", "No hasRecipe");
            return;
        end

        if not cached_config.settings.notify_about_new_recipes and not has_recipe then
            return;
        end

        if not cached_config.settings.notify_about_completed_recipes and has_recipe then
            return;
        end
    else
        local is_completed_file = is_completed_file_method:call(file_manager, file_id);
        if is_completed_file == nil then
            modules.error_handler.report("game_handler.on_add_file", "No IsCompletedFile");
            return;
        end

        if file_category == "file" then
            if not cached_config.settings.notify_about_new_files and not is_completed_file then
                return;
            end

            if not cached_config.settings.notify_about_completed_files and is_completed_file then
                return;
            end
        elseif file_category == "tip" then
            if not cached_config.settings.notify_about_new_tips and not is_completed_file then
                return;
            end

            if not cached_config.settings.notify_about_completed_tips and is_completed_file then
                return;
            end
        else
            if not cached_config.settings.notify_about_new_diary_entries and not is_completed_file then
                return;
            end

            if not cached_config.settings.notify_about_completed_diary_entries and is_completed_file then
                return;
            end
        end
    end

    if cached_config.settings.ignore_consecutive_journal_updates and journal_update_time_seconds_queue.length > 0 then
        return;
    end

    journal_update_time_seconds_queue.enqueue(file_category);

    if journal_update_time_seconds_queue.length == 1 and this.animation.state == 'invisible' then
        this.maybe_start_fade_in();
        return;
    end

    if this.animation.state == 'visible' then
        modules.time.remove_delay_timer(timer);
        this.start_fade_out();
        return;
    end
end

function this.init_module()
    journal_update_time_seconds_queue = modules.queue.new();

    modules.reframework_globals.sdk.hook(on_pause_method, function(args)
        local is_paused_int = modules.reframework_globals.sdk.to_int64(args[3]);

		this.on_pause(is_paused_int);
	end, function(retval)
		return retval;
	end);

	modules.reframework_globals.sdk.hook(add_file_method, function(args)
        local file_manager = modules.reframework_globals.sdk.to_managed_object(args[2]);
        local file_id = modules.reframework_globals.sdk.to_int64(args[3]) & 0xFFFFFFFF;

		this.on_add_file(file_manager, file_id);
	end, function(retval)
		return retval;
	end);
end

return this;
