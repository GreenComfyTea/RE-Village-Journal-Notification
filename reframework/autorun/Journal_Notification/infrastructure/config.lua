local this = {};

local modules = require("Journal_Notification.modules");

local version = "1.0";

this.current_config = nil;
this.config_file_name = tostring(modules.language.default_language.customization_menu.mod_name) .. "/config.json";

this.default_config = {};

function this.init()
	this.default_config = {
		enabled = true,
		
		version = version,
		language = "default",

		customization_menu = {
			position = {
				x = 480,
				y = 200
			},

			size = {
				width = 875,
				height = 480
			},

			pivot = {
				x = 0,
				y = 0
			}
        },
		
        global_modifiers = {
            position_modifier = 1,
			scale_position_modifier_with_resolution = true
		},

		menu_font = {
            size_scale_modifier = 1,
			scale_with_reframework_font_size = true,
		},

		ui_font = {
			family = "Consolas",
			bold = false,
            italic = false,
			size_scale_modifier = 1.95,
			scale_with_reframework_font_size = true,
		},

		settings = {
			timer_delays = {
				update_singletons_delay = 0.25,
				update_window_size_delay = 0.25,
				update_game_data_delay = 0.1,
				update_player_data_delay = 0.1
			},
			
            use_d2d_if_available = true,

			render_during_cutscenes = false,
			render_when_game_timer_is_paused = false,
			render_when_player_cant_take_damage = false,
			render_when_player_cant_use_items = false,
			render_in_winters_house_intro = false,

			notify_about_new_diary_entries = true,
			notify_about_new_files = true,
			notify_about_new_recipes = true,
			notify_about_new_tips = true,
			notify_about_completed_diary_entries = false,
			notify_about_completed_files = false,
			notify_about_completed_recipes = false,
			notify_about_completed_tips = false,
			ignore_consecutive_journal_updates = true,

            duration = 10,
            fade_in_duration = 0.166,
            fade_out_duration = 0.166,
			cooldown_duration = 0.25
		},

        ui = {
            visible = true,
			
            position = {
				x = 0,
                y = 32,
				anchor = "Bottom-Middle"
            },
		
			notification_label = {
				visible = true,

				settings = {
                    alignment = "Bottom-Middle",
				},

				offset = {
					x = 0,
					y = 0
				},
				
				color = 0xFFBCBCC5,

				shadow = {
					visible = true,
					offset = {
						x = 1,
						y = 1
					},
					color = 0xFF000000
				}
            },
		},

		debug = {
			history_size = 64
		}
	};
end

function this.load()
	local loaded_config = modules.reframework_globals.json.load_file(this.config_file_name);
	if loaded_config ~= nil then
		modules.log.info("config.json loaded successfully");
		this.current_config = modules.utils.table.merge(this.default_config, loaded_config);
	else
		modules.log.error("Failed to load config.json");
		this.current_config = modules.utils.table.deep_copy(this.default_config);
	end
end

function this.save()
	-- save current config to disk, replacing any existing file
	local success = modules.reframework_globals.json.dump_file(this.config_file_name, this.current_config);
	if success then
		modules.log.info("config.json saved successfully");
	else
		modules.log.error("Failed to save config.json");
	end
end

function this.reset()
	this.current_config = modules.utils.table.deep_copy(this.default_config);
	this.current_config.version = version;
end

function this.init_module()
	this.init();
	this.load();
	this.current_config.version = version;

	modules.language.update(modules.utils.table.find_index(modules.language.language_names, this.current_config.language));
end

return this;
