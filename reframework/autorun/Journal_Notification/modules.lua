---@diagnostic disable: undefined-global

local this = {
    lua_version = _VERSION,
	globals = _G,
	reframework_globals = {
		d2d = d2d,
		draw = draw,
		fs = fs,
		imgui = imgui,
		json = json,
		log = log,
		re = re,
		reframework = reframework,
		sdk = sdk,
		Vector2f = Vector2f,
		Vector3f = Vector3f,
    },
	language = {},
	config = {},

    game_handler = {},
    player_handler = {},

    bar_customization = {},
    color_customization = {},
	customization_menu = {},
	label_customization = {},
	offset_customization = {},
	position_customization = {},

	drawing = {},
	error_handler = {},
	log = {},
	queue = {},
	screen = {},
    singletons = {},
	throttle = {},
	time = {},
	utils = {},
	
    bar = {},
	label = {},
	percentage_label = {},
    value_label = {},
    health = {},
	ui = {},
};

function this.init_module()
	this.language = require("Journal_Notification.infrastructure.language");
	this.config = require("Journal_Notification.infrastructure.config");

    this.game_handler = require("Journal_Notification.core.game_handler");
	this.player_handler = require("Journal_Notification.core.player_handler");

	this.color_customization = require("Journal_Notification.customization.customizations.color_customization");
    this.label_customization = require("Journal_Notification.customization.customizations.label_customization");
    this.offset_customization = require("Journal_Notification.customization.customizations.offset_customization");
    this.position_customization = require("Journal_Notification.customization.customizations.position_customization");
	this.customization_menu = require("Journal_Notification.customization.customization_menu");

	this.drawing = require("Journal_Notification.helpers.drawing");
    this.error_handler = require("Journal_Notification.helpers.error_handler");
	this.log = require("Journal_Notification.helpers.log");
	this.queue = require("Journal_Notification.helpers.queue");
	this.screen = require("Journal_Notification.helpers.screen");
    this.singletons = require("Journal_Notification.helpers.singletons");
	this.throttle = require("Journal_Notification.helpers.throttle");
	this.time = require("Journal_Notification.helpers.time");
    this.utils = require("Journal_Notification.helpers.utils");

	
	this.ui = require("Journal_Notification.ui.ui");
end

return this;