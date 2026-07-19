local this = {};

local modules = require("Journal_Notification.modules");

this.current_language = {};

--[[
	EXAMPLE: 
	unicode_glyph_ranges = {
		0x0020, 0x00FF, -- Basic Latin + Latin Supplement
		0x2000, 0x206F, -- General Punctuation
		0x3000, 0x30FF, -- CJK Symbols and Punctuations, Hiragana, Katakana
		0x31F0, 0x31FF, -- Katakana Phonetic Extensions
		0x4e00, 0x9FAF, -- CJK Ideograms
		0xFF00, 0xFFEF, -- Half-width characters
		0
	},
]]

this.default_language = {
	font_name = "",
	unicode_glyph_ranges = {0},
	
	customization_menu = {
		mod_name = "Journal Notification";

		enabled = "Enabled",
		reset_config = "Reset Config",

		menu_font_change_disclaimer = "Changing Language and Menu Font Size several times will cause a crash!",
        language = "Language",
		
		global_modifiers = "Global Modifiers",
		position_modifier = "Position Modifier",
		scale_position_modifier_with_resolution = "Scale Position Modifier with Resolution",

		ui_font = "UI Font",
		menu_font = "Menu Font",
		font_notice = "Any changes to the font require script reload!",
		family = "Family",
		bold = "Bold",
        italic = "Italic",
        size_scale_modifier = "Size Scale Modifier",
		scale_with_reframework_font_size = "Scale with REFramework Font Size",
		
		settings = "Settings",
        use_d2d_renderer_if_available = "Use Direct2D Renderer if Available",
		
		timer_delays = "Timer Delays",
		update_singletons_delay = "Update Singletons (sec)",
        update_window_size_delay = "Update Window Size (sec)",
		update_game_data_delay = "Update Game Data (sec)",
		update_player_data_delay = "Update Player Data (sec)",

		render_during_cutscenes = "Render during Cutscenes",
		render_when_game_timer_is_paused = "Render when Game Timer is Paused",
		render_in_winters_house_intro = "Render in Winters' House (Intro)",
		render_when_player_cant_take_damage = "Render when Player can't take Damage",
		render_when_player_cant_use_items = "Render when Player can't use Items",

		notify_about_new_diary_entries = "Notify about New Diary Entries",
		notify_about_new_files = "Notify about New Files",
		notify_about_new_recipes = "Notify about New Recipes",
		notify_about_new_tips = "Notify about New Tips",

		notify_about_completed_diary_entries = "Notify about Completed Diary Entries",
		notify_about_completed_files = "Notify about Completed Files",
		notify_about_completed_recipes = "Notify about Completed Recipes",
		notify_about_completed_tips = "Notify about Completed Tips",

		ignore_consecutive_journal_updates = "Ignore Consecutive Journal Updates",
		
		duration_sec = "Duration (sec)",
		fade_in_duration_sec = "Fade In Duration (sec)",
        fade_out_duration_sec = "Fade Out Duration (sec)",
		cooldown_duration_sec = "Cooldown Duration (sec)",

		x = "X",
		y = "Y",

		notification_label = "Notification Label",

		visible = "Visible",

		offset = "Offset",
		color = "Color",
        shadow = "Shadow",

		ui = "UI",
		position = "Position",
        anchor = "Anchor",
		
		top_left = "Top-Left",
		top_middle = "Top-Middle",
		top_right = "Top-Right",
		middle_left = "Middle-Left",
		center = "Center",
		middle_right = "Middle-Right",
		bottom_left = "Bottom-Left",
		bottom_middle = "Bottom-Middle",
		bottom_right = "Bottom-Right",

        alignment = "Alignment",
		include = "Include",
		current_value = "Current Value",
		max_value = "Max Value",
		
		debug = "Debug",
		current_time = "Current Time",
		everything_seems_to_be_ok = "Everything seems to be OK!",
		history = "History",
		history_size = "History Size",
    },
	
    ui = {
        journal_updated = "Journal Updated",
	}
};

this.language_folder = tostring(this.default_language.customization_menu.mod_name) .. "\\languages\\";
this.mod_name_underscore = this.default_language.customization_menu.mod_name:gsub(" ", "_");
this.language_names = { "default" };
this.languages = { this.default_language };

function this.load()
	local language_files = modules.reframework_globals.fs.glob([[Journal Notification\\languages\\.*json]]);

	if language_files == nil then
		return;
	end

	for i, language_file_name in ipairs(language_files) do

		local language_name = language_file_name:gsub(this.language_folder, ""):gsub(".json","");

		local loaded_language = modules.reframework_globals.json.load_file(language_file_name);
		if loaded_language ~= nil then

			modules.log.info(tostring(language_file_name) .. ".json loaded successfully");
			table.insert(this.language_names, language_name);

			local merged_language = modules.utils.table.merge(this.default_language, loaded_language);
			table.insert(this.languages, merged_language);

			this.save(language_file_name, merged_language);
		else
			modules.log.error("Failed to load " .. tostring(language_file_name) .. ".json");
		end
	end
end

function this.save(file_name, language_table)
	local success = modules.reframework_globals.json.dump_file(file_name, language_table);
	if success then
		modules.log.info(tostring(file_name) .. " saved successfully");
	else
		modules.log.error("Failed to saved " .. tostring(file_name));
	end
end

function this.save_default()
	this.save(this.language_folder .. "en-us.json", this.default_language);
end

function this.update(index)
	this.current_language = this.languages[index];
end

function this.init_module()
	this.save_default();
	this.load();
	this.current_language = this.default_language;
end

return this;
