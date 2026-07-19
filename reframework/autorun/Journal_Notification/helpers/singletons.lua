local this = {};

local modules = require("Journal_Notification.modules");

local scene_manager_name = "via.SceneManager";
local event_system_app_name = "app.EventSystemApp";
local scene_transition_manager_name = "app.SceneTransitionManager";

this.scene_manager = nil;
this.event_system_app = nil;
this.scene_transition_manager = nil;

function this.update()
	this.update_scene_manager();
    this.update_event_system_app();
	this.update_scene_transition_manager();
end

function this.update_scene_manager()
	this.scene_manager = modules.reframework_globals.sdk.get_native_singleton(scene_manager_name);
    if this.scene_manager == nil then
        modules.error_handler.report("singletons.update_scene_manager", "No SceneManager");
    end
	
	return this.scene_manager;
end

function this.update_event_system_app()
	this.event_system_app = modules.reframework_globals.sdk.get_managed_singleton(event_system_app_name);
	if this.event_system_app == nil then
		modules.error_handler.report("singletons.update_event_system_app","No EventSystemApp");
	end

	return this.event_system_app;
end

function this.update_scene_transition_manager()
	this.scene_transition_manager = modules.reframework_globals.sdk.get_managed_singleton(scene_transition_manager_name);
	if this.scene_transition_manager == nil then
		modules.error_handler.report("singletons.update_scene_transition_manager", "No SceneTransitionManager");
	end

	return this.scene_transition_manager;
end

function this.init_module()
	this.update();
end

return this;
