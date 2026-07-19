local this = {};

local modules = require("Journal_Notification.modules");

this.font = nil;

function this.init_font()
    local cached_config = modules.config.current_config.ui_font;
	
	local reframework_font_size = 16;

    if cached_config.scale_with_reframework_font_size then
        reframework_font_size = modules.reframework_globals.imgui.get_default_font_size();
    end

	local final_size = modules.utils.math.round(cached_config.size_scale_modifier * reframework_font_size);

	this.font = modules.reframework_globals.d2d.Font.new(cached_config.family, final_size, cached_config.bold, cached_config.italic);
end

function this.argb_color_to_abgr_color(argb_color)
	local alpha = (argb_color >> 24) & 0xFF;
	local red = (argb_color >> 16) & 0xFF;
	local green = (argb_color >> 8) & 0xFF;
	local blue = argb_color & 0xFF;

	local abgr_color = 0x1000000 * alpha + 0x10000 * blue + 0x100 * green + red;

	return abgr_color;
end

function this.color_to_argb(color)
	local alpha = (color >> 24) & 0xFF;
	local red = (color >> 16) & 0xFF;
	local green = (color >> 8) & 0xFF;
	local blue = color & 0xFF;

	return alpha, red, green, blue;
end

function this.argb_to_color(alpha, red, green, blue)
	return 0x1000000 * alpha + 0x10000 * red + 0x100 * green + blue;
end

function this.scale_color_opacity(color, scale)
	local alpha, red, green, blue = this.color_to_argb(color);
	local new_alpha = math.floor(alpha * scale);
	if new_alpha < 0 then
		new_alpha = 0;
	end
	if new_alpha > 255 then
		new_alpha = 255;
	end

	return this.argb_to_color(new_alpha, red, green, blue);
end

function this.get_alignment_shifts(text, alignment)
	local cached_default_language = modules.language.default_language.customization_menu;

	if alignment == cached_default_language.top_left or alignment == nil then
		return 0, 0;
	end

	local width, height;

	local use_d2d = modules.reframework_globals.d2d ~= nil and modules.config.current_config.settings.use_d2d_if_available;

    if use_d2d and this.font ~= nil then
        width, height = modules.reframework_globals.d2d.Font.measure(this.font, text);
    else
        local text_size = modules.reframework_globals.imgui.calc_text_size(text);
        width = text_size.x;
        height = text_size.y;
    end

	if alignment == cached_default_language.top_middle then
		return -width / 2, 0;
	elseif alignment == cached_default_language.top_right then
		return -width, 0;
	elseif alignment == cached_default_language.middle_left then
		return 0, -height / 2;
	elseif alignment == cached_default_language.center then
		return -width / 2, -height / 2;
	elseif alignment == cached_default_language.middle_right then
		return -width, -height / 2;
	elseif alignment == cached_default_language.bottom_left then
		return 0, -height;
	elseif alignment == cached_default_language.bottom_middle then
		return -width / 2, -height;
	elseif alignment == cached_default_language.bottom_right then
		return -width, -height;
	end

	return 0, 0;
end

function this.draw_label(label, position, opacity_scale, ...)
    if label == nil or not label.visible then
        return;
    end

	local text = string.format("%s", table.unpack({...}));

    if text == "" then
        return;
    end

	local alignment_x, alignment_y = this.get_alignment_shifts(text, label.settings.alignment);

	local scaled_label_offset_x, scaled_label_offset_y = modules.utils.misc.scale_position(label.offset.x, label.offset.y);

	local position_x = position.x + scaled_label_offset_x + alignment_x;
	local position_y = position.y + scaled_label_offset_y + alignment_y;

	local use_d2d = modules.reframework_globals.d2d ~= nil and modules.config.current_config.settings.use_d2d_if_available;

	if label.shadow.visible then
		local new_shadow_color = label.shadow.color;

		if opacity_scale < 1 then
			new_shadow_color = this.scale_color_opacity(new_shadow_color, opacity_scale);
		end

		if use_d2d then
			modules.reframework_globals.d2d.text(this.font, text, position_x + label.shadow.offset.x, position_y + label.shadow.offset.y, new_shadow_color);
		else
			new_shadow_color = this.argb_color_to_abgr_color(new_shadow_color);
			modules.reframework_globals.draw.text(text, position_x + label.shadow.offset.x, position_y + label.shadow.offset.y, new_shadow_color);
		end
	end

	local new_color = label.color;
    if opacity_scale < 1 then
        new_color = this.scale_color_opacity(new_color, opacity_scale);
    end

	if use_d2d then
		modules.reframework_globals.d2d.text(this.font, text, position_x, position_y, new_color);
	else
		new_color = this.argb_color_to_abgr_color(new_color);
		modules.reframework_globals.draw.text(text, position_x, position_y, new_color);
	end
end

function this.init_module()
end

return this;
