local this = {};

local modules = require("Journal_Notification.modules");

this.font = nil;
this.full_font_range = {0x1, 0xFFFF, 0};
this.is_opened = false;

this.window_flags = 0x10120;
this.color_picker_flags = 327680;
this.decimal_input_flags = 33;

this.config_changed = false;

this.fonts = {	"Arial", "Arial Black", "Bahnschrift", "Calibri", "Cambria", "Cambria Math", "Candara",
				"Comic Sans MS", "Consolas", "Constantia", "Corbel", "Courier New", "Ebrima",
				"Franklin Gothic Medium", "Gabriola", "Gadugi", "Georgia", "HoloLens MDL2 Assets", "Impact",
				"Ink Free", "Javanese Text", "Leelawadee UI", "Lucida Console", "Lucida Sans Unicode",
				"Malgun Gothic", "Marlett", "Microsoft Himalaya", "Microsoft JhengHei", "Microsoft New Tai Lue",
				"Microsoft PhagsPa", "Microsoft Sans Serif", "Microsoft Tai Le", "Microsoft YaHei",
				"Microsoft Yi Baiti", "MingLiU-ExtB", "Mongolian Baiti", "MS Gothic", "MV Boli", "Myanmar Text",
				"Nirmala UI", "Palatino Linotype", "Segoe MDL2 Assets", "Segoe Print", "Segoe Script", "Segoe UI",
				"Segoe UI Historic", "Segoe UI Emoji", "Segoe UI Symbol", "SimSun", "Sitka", "Sylfaen", "Symbol",
				"Tahoma", "Times New Roman", "Trebuchet MS", "Verdana", "Webdings", "Wingdings", "Yu Gothic"
};

function this.reload_font(pop_push)
	local cached_config = modules.config.current_config;
	local cached_language = modules.language.current_language;

	local font_range = cached_language.unicode_glyph_ranges;

	if cached_language.font_name == "" then
		font_range = nil;

	elseif cached_language.unicode_glyph_ranges == nil
		or modules.utils.table.is_empty(cached_language.unicode_glyph_ranges)
		or #cached_language.unicode_glyph_ranges == 1
		or not modules.utils.number.is_odd(#cached_language.unicode_glyph_ranges)
	then

		

		font_range = this.full_font_range;
	end

    local reframework_font_size = 16;

	if cached_config.menu_font.scale_with_reframework_font_size then
		reframework_font_size = modules.reframework_globals.imgui.get_default_font_size();
	end
	
    local final_size = modules.utils.math.round(cached_config.menu_font.size_scale_modifier * reframework_font_size);
	
	this.font = modules.reframework_globals.imgui.load_font(cached_language.font_name, final_size, font_range);

	if pop_push then
		modules.reframework_globals.imgui.pop_font();
		modules.reframework_globals.imgui.push_font(this.font);
	end
end

function this.init()
	modules.label_customization.init();
	modules.position_customization.init();
end

function this.draw()
	local cached_config = modules.config.current_config;
	local cached_language = modules.language.current_language.customization_menu;

	local window_position = modules.reframework_globals.Vector2f.new(modules.config.current_config.customization_menu.position.x, modules.config.current_config.customization_menu.position.y);
	local window_pivot = modules.reframework_globals.Vector2f.new(modules.config.current_config.customization_menu.pivot.x, modules.config.current_config.customization_menu.pivot.y);
	local window_size = modules.reframework_globals.Vector2f.new(modules.config.current_config.customization_menu.size.width, modules.config.current_config.customization_menu.size.height);
	

	modules.reframework_globals.imgui.set_next_window_pos(window_position, 1 << 3, window_pivot);
	modules.reframework_globals.imgui.set_next_window_size(window_size, 1 << 3);

    modules.reframework_globals.imgui.push_font(this.font);

	this.is_opened = modules.reframework_globals.imgui.begin_window(
		modules.utils.imgui.label(tostring(cached_language.mod_name) .. " v" .. tostring(modules.config.current_config.version), "window"), this.is_opened, this.window_flags);

	if not this.is_opened then
		modules.reframework_globals.imgui.pop_font();
		modules.reframework_globals.imgui.end_window();
		return;
	end

	local changed = false;
	local config_changed = false;
	local language_changed = false;
	local menu_font_changed = false;
	local window_changed = false;
	
	local index = 1;
	local language_index = 1;

	local new_window_position = modules.reframework_globals.imgui.get_window_pos();
	if window_position.x ~= new_window_position.x or window_position.y ~= new_window_position.y then
		window_changed = true;

		modules.config.current_config.customization_menu.position.x = new_window_position.x;
		modules.config.current_config.customization_menu.position.y = new_window_position.y;
	end

	local new_window_size = modules.reframework_globals.imgui.get_window_size();
	if window_size.x ~= new_window_size.x or window_size.y ~= new_window_size.y then
		window_changed = true;

		modules.config.current_config.customization_menu.size.width = new_window_size.x;
		modules.config.current_config.customization_menu.size.height = new_window_size.y;
	end

	if modules.reframework_globals.imgui.button(modules.utils.imgui.label(cached_language.reset_config, "reset_config")) then
		modules.config.reset();
		config_changed = true;
	end

	changed, cached_config.enabled = modules.reframework_globals.imgui.checkbox(modules.utils.imgui.label(cached_language.enabled, "enabled"), cached_config.enabled);
	config_changed = config_changed or changed;

    if modules.reframework_globals.imgui.tree_node(modules.utils.imgui.label(cached_language.language, "language")) then
        modules.reframework_globals.imgui.text(cached_language.menu_font_change_disclaimer);

        changed, language_index = modules.reframework_globals.imgui.combo(
            modules.utils.imgui.label(cached_language.language, "language.language"),
            modules.utils.table.find_index(modules.language.language_names, cached_config.language),
            modules.language.language_names);

        config_changed = config_changed or changed;
        language_changed = language_changed or changed;

        modules.reframework_globals.imgui.tree_pop();
    end
	
	if modules.reframework_globals.imgui.tree_node(modules.utils.imgui.label(cached_language.global_modifiers, "global_modifiers")) then
		changed, cached_config.global_modifiers.position_modifier = modules.reframework_globals.imgui.drag_float(modules.utils.imgui.label(cached_language.position_modifier, "global_modifiers.position_modifier"), cached_config.global_modifiers.position_modifier, 0.001, 0.001, 100, "%.3f");
		config_changed = config_changed or changed;

		changed, cached_config.global_modifiers.scale_position_modifier_with_resolution = modules.reframework_globals.imgui.checkbox(modules.utils.imgui.label(cached_language.scale_position_modifier_with_resolution, "global_modifiers.scale_position_modifier_with_resolution"),
			cached_config.global_modifiers.scale_position_modifier_with_resolution);
		config_changed = config_changed or changed;

		modules.reframework_globals.imgui.tree_pop();
	end

	if modules.reframework_globals.imgui.tree_node(modules.utils.imgui.label(cached_language.menu_font, "menu_font")) then
		modules.reframework_globals.imgui.text(cached_language.menu_font_change_disclaimer);

		changed, cached_config.menu_font.size_scale_modifier = modules.reframework_globals.imgui.drag_float(modules.utils.imgui.label(cached_language.size_scale_modifier, "menu_font.size_scale_modifier"),
			cached_config.menu_font.size_scale_modifier, 0.01, 0.1, 100, "%.2f");
		config_changed = config_changed or changed;
        menu_font_changed = menu_font_changed or changed;

		changed, cached_config.menu_font.scale_with_reframework_font_size = modules.reframework_globals.imgui.checkbox(modules.utils.imgui.label(cached_language.scale_with_reframework_font_size, "menu_font.scale_with_reframework_font_size"), cached_config.menu_font.scale_with_reframework_font_size);
		config_changed = config_changed or changed;
		menu_font_changed = menu_font_changed or changed;

		modules.reframework_globals.imgui.tree_pop();
	end

	if modules.reframework_globals.imgui.tree_node(modules.utils.imgui.label(cached_language.ui_font, "ui_font")) then
		modules.reframework_globals.imgui.text(cached_language.font_notice);
		
		changed, index = modules.reframework_globals.imgui.combo(modules.utils.imgui.label(cached_language.family, "ui_font.family"),
			modules.utils.table.find_index(this.fonts, cached_config.ui_font.family), this.fonts);
		config_changed = config_changed or changed;

		if changed then
			cached_config.ui_font.family = this.fonts[index];
		end

		changed, cached_config.ui_font.bold = modules.reframework_globals.imgui.checkbox(modules.utils.imgui.label(cached_language.bold, "ui_font.bold"),
			cached_config.ui_font.bold);
		config_changed = config_changed or changed;

		changed, cached_config.ui_font.italic = modules.reframework_globals.imgui.checkbox(modules.utils.imgui.label(cached_language.italic, "ui_font.italic"),
			cached_config.ui_font.italic);
        config_changed = config_changed or changed;

		changed, cached_config.ui_font.size_scale_modifier = modules.reframework_globals.imgui.drag_float(
			modules.utils.imgui.label(cached_language.size_scale_modifier, "ui_font.size_scale_modifier"), cached_config.ui_font.size_scale_modifier, 0.01, 0.1, 100, "%.2f");
		config_changed = config_changed or changed;
		
		changed, cached_config.ui_font.scale_with_reframework_font_size = modules.reframework_globals.imgui.checkbox(modules.utils.imgui.label(cached_language.scale_with_reframework_font_size, "ui_font.scale_with_reframework_font_size"), cached_config.ui_font.scale_with_reframework_font_size);
		config_changed = config_changed or changed;

		modules.reframework_globals.imgui.tree_pop();

	end

	if modules.reframework_globals.imgui.tree_node(modules.utils.imgui.label(cached_language.settings, "settings")) then
		if modules.reframework_globals.imgui.tree_node(modules.utils.imgui.label(cached_language.timer_delays, "settings.timer_delays")) then

			changed, cached_config.settings.timer_delays.update_singletons_delay = modules.reframework_globals.imgui.drag_float(
				modules.utils.imgui.label(cached_language.update_singletons_delay, "settings.timer_delays.update_singletons_delay"),
			cached_config.settings.timer_delays.update_singletons_delay, 0.001, 0, 5, "%.3f");
			
			config_changed = config_changed or changed;

			changed, cached_config.settings.timer_delays.update_window_size_delay = modules.reframework_globals.imgui.drag_float(
				modules.utils.imgui.label(cached_language.update_window_size_delay, "settings.timer_delays.update_window_size_delay"),
			cached_config.settings.timer_delays.update_window_size_delay, 0.001, 0, 5, "%.3f");
			
			config_changed = config_changed or changed;

			changed, cached_config.settings.timer_delays.update_game_data_delay = modules.reframework_globals.imgui.drag_float(
				modules.utils.imgui.label(cached_language.update_game_data_delay, "settings.timer_delays.update_game_data_delay"),
			cached_config.settings.timer_delays.update_game_data_delay, 0.001, 0, 5, "%.3f");

			changed, cached_config.settings.timer_delays.update_player_data_delay = modules.reframework_globals.imgui.drag_float(
				modules.utils.imgui.label(cached_language.update_player_data_delay, "settings.timer_delays.update_player_data_delay"),
			cached_config.settings.timer_delays.update_player_data_delay, 0.001, 0, 5, "%.3f");
			
			config_changed = config_changed or changed;

			modules.reframework_globals.imgui.tree_pop();
		end

		modules.reframework_globals.imgui.new_line();
		modules.reframework_globals.imgui.begin_rect();

		changed, cached_config.settings.use_d2d_if_available = modules.reframework_globals.imgui.checkbox(modules.utils.imgui.label(cached_language.use_d2d_renderer_if_available, "settings.use_d2d_renderer_if_available"),
			cached_config.settings.use_d2d_if_available);
		config_changed = config_changed or changed;
	
		modules.reframework_globals.imgui.end_rect(5);
		modules.reframework_globals.imgui.new_line();
		modules.reframework_globals.imgui.begin_rect();

		changed, cached_config.settings.render_during_cutscenes = modules.reframework_globals.imgui.checkbox(modules.utils.imgui.label(cached_language.render_during_cutscenes, "settings.render_during_cutscenes"),
			cached_config.settings.render_during_cutscenes);
		config_changed = config_changed or changed;

		changed, cached_config.settings.render_when_game_timer_is_paused = modules.reframework_globals.imgui.checkbox(modules.utils.imgui.label(cached_language.render_when_game_timer_is_paused, "settings.render_when_game_timer_is_paused"),
			cached_config.settings.render_when_game_timer_is_paused);
		config_changed = config_changed or changed;

		changed, cached_config.settings.render_when_player_cant_take_damage = modules.reframework_globals.imgui.checkbox(modules.utils.imgui.label(cached_language.render_when_player_cant_take_damage, "settings.render_when_player_cant_take_damage"),
			cached_config.settings.render_when_player_cant_take_damage);
		config_changed = config_changed or changed;

		changed, cached_config.settings.render_when_player_cant_use_items = modules.reframework_globals.imgui.checkbox(modules.utils.imgui.label(cached_language.render_when_player_cant_use_items, "settings.render_when_player_cant_use_items"),
			cached_config.settings.render_when_player_cant_use_items);
		config_changed = config_changed or changed;

		modules.reframework_globals.imgui.end_rect(5);
		modules.reframework_globals.imgui.new_line();
		modules.reframework_globals.imgui.begin_rect();

		changed, cached_config.settings.render_in_winters_house_intro = modules.reframework_globals.imgui.checkbox(modules.utils.imgui.label(cached_language.render_in_winters_house_intro, "settings.render_in_winters_house_intro"),
			cached_config.settings.render_in_winters_house_intro);
		config_changed = config_changed or changed;
	
		modules.reframework_globals.imgui.end_rect(5);
		modules.reframework_globals.imgui.new_line();
		modules.reframework_globals.imgui.begin_rect();

		changed, cached_config.settings.notify_about_new_diary_entries = modules.reframework_globals.imgui.checkbox(modules.utils.imgui.label(cached_language.notify_about_new_diary_entries, "settings.notify_about_new_diary_entries"),
			cached_config.settings.notify_about_new_diary_entries);
		config_changed = config_changed or changed;

		changed, cached_config.settings.notify_about_new_files = modules.reframework_globals.imgui.checkbox(modules.utils.imgui.label(cached_language.notify_about_new_files, "settings.notify_about_new_files"),
			cached_config.settings.notify_about_new_files);
		config_changed = config_changed or changed;

		changed, cached_config.settings.notify_about_new_recipes = modules.reframework_globals.imgui.checkbox(modules.utils.imgui.label(cached_language.notify_about_new_recipes, "settings.notify_about_new_recipes"),
			cached_config.settings.notify_about_new_recipes);
		config_changed = config_changed or changed;

		changed, cached_config.settings.notify_about_new_tips = modules.reframework_globals.imgui.checkbox(modules.utils.imgui.label(cached_language.notify_about_new_tips, "settings.notify_about_new_tips"),
			cached_config.settings.notify_about_new_tips);
		config_changed = config_changed or changed;

		modules.reframework_globals.imgui.end_rect(5);
		modules.reframework_globals.imgui.new_line();
		modules.reframework_globals.imgui.begin_rect();

		changed, cached_config.settings.notify_about_completed_diary_entries = modules.reframework_globals.imgui.checkbox(modules.utils.imgui.label(cached_language.notify_about_completed_diary_entries, "settings.notify_about_completed_diary_entries"),
			cached_config.settings.notify_about_completed_diary_entries);
		config_changed = config_changed or changed;

		changed, cached_config.settings.notify_about_completed_files = modules.reframework_globals.imgui.checkbox(modules.utils.imgui.label(cached_language.notify_about_completed_files, "settings.notify_about_completed_files"),
			cached_config.settings.notify_about_completed_files);
		config_changed = config_changed or changed;

		changed, cached_config.settings.notify_about_completed_recipes = modules.reframework_globals.imgui.checkbox(modules.utils.imgui.label(cached_language.notify_about_completed_recipes, "settings.notify_about_completed_recipes"),
			cached_config.settings.notify_about_completed_recipes);
		config_changed = config_changed or changed;

		changed, cached_config.settings.notify_about_completed_tips = modules.reframework_globals.imgui.checkbox(modules.utils.imgui.label(cached_language.notify_about_completed_tips, "settings.notify_about_completed_tips"),
			cached_config.settings.notify_about_completed_tips);
		config_changed = config_changed or changed;

		modules.reframework_globals.imgui.end_rect(5);
		modules.reframework_globals.imgui.new_line();
		modules.reframework_globals.imgui.begin_rect();

		changed, cached_config.settings.ignore_consecutive_journal_updates = modules.reframework_globals.imgui.checkbox(modules.utils.imgui.label(cached_language.ignore_consecutive_journal_updates, "settings.ignore_consecutive_journal_updates"),
			cached_config.settings.ignore_consecutive_journal_updates);
		config_changed = config_changed or changed;

		modules.reframework_globals.imgui.end_rect(5);
		modules.reframework_globals.imgui.new_line();

		changed, cached_config.settings.duration = modules.reframework_globals.imgui.drag_float(
			modules.utils.imgui.label(cached_language.duration_sec, "settings.duration"),
            cached_config.settings.duration, 0.001, 0, 60, "%.3f");
        config_changed = config_changed or changed;
		
        local max_fade_in_duration = math.max(0, cached_config.settings.duration - cached_config.settings.fade_out_duration);
		
		if cached_config.settings.fade_in_duration > max_fade_in_duration then
            cached_config.settings.fade_in_duration = max_fade_in_duration;
			config_changed = true;
		end
			
		changed, cached_config.settings.fade_in_duration = modules.reframework_globals.imgui.drag_float(
			modules.utils.imgui.label(cached_language.fade_in_duration_sec, "settings.fade_in_duration"),
            cached_config.settings.fade_in_duration, 0.001, 0.000, math.min(60, max_fade_in_duration), "%.3f");
        config_changed = config_changed or changed;
		
		local max_fade_out_duration = math.max(0, cached_config.settings.duration - cached_config.settings.fade_in_duration);

		if cached_config.settings.fade_out_duration > max_fade_out_duration then
            cached_config.settings.fade_out_duration = max_fade_out_duration;
			config_changed = true;
		end
			
		changed, cached_config.settings.fade_out_duration = modules.reframework_globals.imgui.drag_float(
			modules.utils.imgui.label(cached_language.fade_out_duration_sec, "settings.fade_out_duration"),
            cached_config.settings.fade_out_duration, 0.001, 0.000, math.min(60, max_fade_out_duration), "%.3f");
        config_changed = config_changed or changed;
		
		changed, cached_config.settings.cooldown_duration = modules.reframework_globals.imgui.drag_float(
			modules.utils.imgui.label(cached_language.cooldown_duration_sec, "settings.cooldown_duration"),
            cached_config.settings.cooldown_duration, 0.001, 0.000, 60, "%.3f");
		config_changed = config_changed or changed;
		
		modules.reframework_globals.imgui.tree_pop();
	end

	if modules.reframework_globals.imgui.tree_node(modules.utils.imgui.label(cached_language.ui, "ui")) then
		changed, cached_config.ui.visible = modules.reframework_globals.imgui.checkbox(modules.utils.imgui.label(cached_language.visible, "ui.visible"), cached_config.ui.visible);
        config_changed = config_changed or changed;

        changed = modules.position_customization.draw("ui", cached_config.ui.position);
		config_changed = config_changed or changed;

		changed = modules.label_customization.draw("ui.notification_label", cached_language.notification_label, cached_config.ui.notification_label);
		config_changed = config_changed or changed;

		modules.reframework_globals.imgui.tree_pop();
	end

	changed = this.draw_debug();
	config_changed = config_changed or changed;
	
	modules.reframework_globals.imgui.end_window();
	modules.reframework_globals.imgui.pop_font();

	if language_changed then
		cached_config.language = modules.language.language_names[language_index];
		modules.language.update(language_index);
		this.init();

		this.reload_font();
	end

	if menu_font_changed then
		this.reload_font();
	end


	if config_changed or language_changed or window_changed then
		modules.config.save();
	end
end

function this.draw_debug()
    local cached_config = modules.config.current_config.debug;
	local cached_language = modules.language.current_language.customization_menu;

	local changed = false;
	local config_changed = false;

	if modules.reframework_globals.imgui.tree_node(modules.utils.imgui.label(cached_language.debug, "debug")) then
		
		modules.reframework_globals.imgui.text_colored(string.format("%s:", cached_language.current_time), 0xFFAAAA66);
		modules.reframework_globals.imgui.same_line();
		modules.reframework_globals.imgui.text(string.format("%.3fs", modules.time.total_elapsed_script_seconds));

		if modules.error_handler.is_empty then
			modules.reframework_globals.imgui.text(cached_language.everything_seems_to_be_ok);
		else
			for error_key, error in pairs(modules.error_handler.list) do

				modules.reframework_globals.imgui.button(modules.utils.imgui.label(string.format("%.3fs", error.time), "debug.list.list_entry_" .. tostring(error)));
				modules.reframework_globals.imgui.same_line();
				modules.reframework_globals.imgui.text_colored(error_key, 0xFFAA66AA);
				modules.reframework_globals.imgui.same_line();
				modules.reframework_globals.imgui.text(error.message);
			end
		end

		if modules.reframework_globals.imgui.tree_node(modules.utils.imgui.label(cached_language.history, "debug.history")) then

			changed, cached_config.history_size = modules.reframework_globals.imgui.drag_int(
				modules.utils.imgui.label(cached_language.history_size, "debug.history.history_size"), cached_config.history_size, 1, 0, 1024);

			config_changed = config_changed or changed;

			if changed then
				modules.error_handler.history = {};
			end

			for index, error in pairs(modules.error_handler.history) do
				modules.reframework_globals.imgui.text_colored(index, 0xFF66AA66);
				modules.reframework_globals.imgui.same_line();
				modules.reframework_globals.imgui.button(modules.utils.imgui.label(string.format("%.3fs", error.time), "debug.history.history_entry_" .. tostring(error)));
				modules.reframework_globals.imgui.same_line();
				modules.reframework_globals.imgui.text_colored(error.key, 0xFFAA66AA);
				modules.reframework_globals.imgui.same_line();
				modules.reframework_globals.imgui.text(error.message);
			end


			modules.reframework_globals.imgui.tree_pop();
		end

		modules.reframework_globals.imgui.tree_pop();
	end

	return config_changed;
end

function this.init_module()
	this.init();
    this.reload_font();
	
    modules.reframework_globals.re.on_config_save(function()
		local cached_config = modules.config.current_config;

		if cached_config.menu_font.scale_with_reframework_font_size then
			this.reload_font();
		end
	end);
end

return this;