shader_type canvas_item;

// HD-2D风格后期处理效果

// 像素完美渲染参数
uniform float pixel_scale : hint_range(1.0, 16.0) = 4.0;
uniform bool enable_scanlines = true;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.1;
uniform float pixel_darkening : hint_range(0.0, 1.0) = 0.05;

void fragment() {
	// 获取屏幕UV坐标
	vec2 screen_uv = SCREEN_UV;
	
	// 像素化坐标
	vec2 pixel_uv = floor(screen_uv * SCREEN_PIXEL_SIZE * pixel_scale) / (SCREEN_PIXEL_SIZE * pixel_scale);
	
	// 采样原始颜色
	vec4 original_color = texture(TEXTURE, UV);
	
	// 应用像素完美渲染
	vec4 color = original_color;
	
	// 添加扫描线效果
	if (enable_scanlines) {
		float scanline = mod(screen_uv.y * SCREEN_PIXEL_SIZE.y * pixel_scale * 0.5, 1.0);
		float scanline_factor = 1.0 - (scanline_intensity * abs(scanline - 0.5) * 2.0);
		color.rgb *= scanline_factor;
	}
	
	// 像素间暗化
	vec2 pixel_coords = floor(screen_uv * SCREEN_PIXEL_SIZE * pixel_scale);
	if (mod(pixel_coords.x + pixel_coords.y, 2.0) < 1.0) {
		color.rgb *= (1.0 - pixel_darkening);
	}
	
	// 色彩分级（模拟HD-2D风格）
	// 增加对比度和饱和度
	vec3 graded_color = color.rgb;
	graded_color = mix(vec3(0.5), graded_color, 1.2); // 增加对比度
	graded_color = mix(vec3(dot(graded_color, vec3(0.299, 0.587, 0.114))), graded_color, 1.1); // 增加饱和度
	
	// 色调偏移（模拟复古感）
	graded_color.r = graded_color.r * 1.05;
	graded_color.g = graded_color.g * 0.98;
	graded_color.b = graded_color.b * 1.02;
	
	// 输出最终颜色
	COLOR = vec4(graded_color, original_color.a);
}
