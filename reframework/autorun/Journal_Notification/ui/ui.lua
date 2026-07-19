local this = {};

local modules = require("Journal_Notification.modules");

function this.get_anchored_position()
    local cached_default_language = modules.language.default_language.customization_menu;
    local cached_config = modules.config.current_config;

    local anchor = cached_config.ui.position.anchor;

    local anchor_x = 0;
    local anchor_y = 0;

    if anchor == cached_default_language.top_left then
        anchor_x = 0;
        anchor_y = 0;
    elseif anchor == cached_default_language.top_middle then
        anchor_x = 0.5;
        anchor_y = 0;
    elseif anchor == cached_default_language.top_right then
        anchor_x = 1;
        anchor_y = 0;
    elseif anchor == cached_default_language.middle_left then
        anchor_x = 0;
        anchor_y = 0.5;
    elseif anchor == cached_default_language.center then
        anchor_x = 0.5;
        anchor_y = 0.5;
    elseif anchor == cached_default_language.middle_right then
        anchor_x = 1;
        anchor_y = 0.5;
    elseif anchor == cached_default_language.bottom_left then
        anchor_x = 0;
        anchor_y = 1;
    elseif anchor == cached_default_language.bottom_middle then
        anchor_x = 0.5;
        anchor_y = 1;
    elseif anchor == cached_default_language.bottom_right then
        anchor_x = 1;
        anchor_y = 1;
    end

    local base_x = anchor_x * modules.screen.width;
    local base_y = anchor_y * modules.screen.height;

    local offset_x = cached_config.ui.position.x;
    local offset_y = cached_config.ui.position.y;

    if anchor == cached_default_language.bottom_left
    or anchor == cached_default_language.bottom_middle
    or anchor == cached_default_language.bottom_right then
        offset_y = -offset_y;
    end

    if anchor == cached_default_language.top_right
        or anchor == cached_default_language.middle_right
        or anchor == cached_default_language.bottom_right then
        offset_x = -offset_x;
    end
    
    local scaled_offset_x, scaled_offset_y = modules.utils.misc.scale_position(offset_x, offset_y);

    return {
        x = base_x + scaled_offset_x,
        y = base_y + scaled_offset_y,
    };
end

function this.draw()
    local cached_config = modules.config.current_config;
    local cached_language = modules.language.current_language.ui;

    if not cached_config.ui.visible then
        return;
    end

    if modules.game_handler.animation.state == 'invisible' or modules.game_handler.animation.state == 'cooldown' then
        return;
    end

    local opacity_scale = 1;

    if modules.game_handler.animation.state == 'fade_in' then
        local current_time = modules.time.total_elapsed_script_seconds;
        local progress = (current_time - modules.game_handler.animation.start_time) / modules.game_handler.animation.duration;

        opacity_scale = math.max(0, math.min(1, progress));
    elseif modules.game_handler.animation.state == 'fade_out' then
        local current_time = modules.time.total_elapsed_script_seconds;
        local progress = (current_time - modules.game_handler.animation.start_time) / modules.game_handler.animation.duration;
        
        opacity_scale = math.max(0, math.min(1, 1 - progress));
    end

    local anchored_position = this.get_anchored_position();

    modules.drawing.draw_label(cached_config.ui.notification_label, anchored_position, opacity_scale, cached_language.journal_updated);
end

function this.init_module()
end

return this;