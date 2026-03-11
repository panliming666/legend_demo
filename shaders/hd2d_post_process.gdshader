shader_type canvas_item;

// ============================================================================
// HD-2D 后期处理着色器 - 纯正HD-2D风格
// ============================================================================
// 核心理念：
// 1. 不破坏原生3D渲染的清晰度
// 2. 只做色彩增强和电影感调色
// 3. 保持像素精灵的锐利边缘
// 4. 参考八方旅人的色彩分级风格
// ============================================================================

// === 色彩分级参数 ===
uniform float brightness : hint_range(0.5, 1.5) = 1.0;
uniform float contrast : hint_range(0.5, 2.0) = 1.15;
uniform float saturation : hint_range(0.5, 2.0) = 1.2;

// === 色调映射参数 ===
uniform float exposure : hint_range(0.1, 3.0) = 1.0;
uniform float gamma : hint_range(0.5, 2.5) = 1.0;

// === 色彩偏移（模拟胶片感） ===
uniform vec3 shadow_tint : source_color = vec3(0.1, 0.15, 0.25);  // 阴影偏蓝
uniform vec3 highlight_tint : source_color = vec3(1.0, 0.95, 0.85); // 高光偏暖
uniform float tint_strength : hint_range(0.0, 1.0) = 0.3;

// === 色温调整 ===
uniform float temperature : hint_range(-1.0, 1.0) = 0.1;  // 正值偏暖，负值偏冷

// === 暗角效果 ===
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.25;
uniform float vignette_radius : hint_range(0.0, 2.0) = 0.8;
uniform float vignette_softness : hint_range(0.0, 1.0) = 0.5;

// === 色调曲线（类似Photoshop曲线调整） ===
uniform float curve_shadows : hint_range(0.0, 2.0) = 1.1;
uniform float curve_midtones : hint_range(0.5, 1.5) = 1.0;
uniform float curve_highlights : hint_range(0.0, 2.0) = 0.95;

// === 色彩分离（色差效果，轻微） ===
uniform float chromatic_aberration : hint_range(0.0, 0.01) = 0.001;
uniform bool enable_chromatic_aberration = false;

// === 锐化（可选） ===
uniform float sharpen_amount : hint_range(0.0, 1.0) = 0.0;
uniform bool enable_sharpen = false;

void fragment() {
	// 获取原始颜色
	vec4 original_color = texture(TEXTURE, UV);
	vec3 color = original_color.rgb;
	
	// =====================================================
	// 1. 曝光调整
	// =====================================================
	color *= exposure;
	
	// =====================================================
	// 2. 色温调整
	// =====================================================
	vec3 temp_adjust = vec3(1.0);
	if (temperature > 0.0) {
		// 偏暖
		temp_adjust.r = 1.0 + temperature * 0.1;
		temp_adjust.b = 1.0 - temperature * 0.05;
	} else {
		// 偏冷
		temp_adjust.r = 1.0 + temperature * 0.05;
		temp_adjust.b = 1.0 - temperature * 0.1;
	}
	color *= temp_adjust;
	
	// =====================================================
	// 3. 色调曲线（S曲线增强对比）
	// =====================================================
	// 这是一个简化的色调曲线，用于增强画面对比度
	float luminance = dot(color, vec3(0.299, 0.587, 0.114));
	
	// 对阴影、中间调、高光分别调整
	vec3 shadows = pow(color, vec3(1.0 / curve_shadows));
	vec3 midtones = color * curve_midtones;
	vec3 highlights = pow(color, vec3(curve_highlights));
	
	// 根据亮度混合
	color = mix(shadows, midtones, smoothstep(0.0, 0.5, luminance));
	color = mix(color, highlights, smoothstep(0.5, 1.0, luminance));
	
	// =====================================================
	// 4. 对比度调整
	// =====================================================
	color = mix(vec3(0.5), color, contrast);
	
	// =====================================================
	// 5. 饱和度调整
	// =====================================================
	vec3 gray = vec3(dot(color, vec3(0.299, 0.587, 0.114)));
	color = mix(gray, color, saturation);
	
	// =====================================================
	// 6. 阴影/高光着色（电影感色调）
	// =====================================================
	// 阴影区域添加蓝色调
	vec3 shadow_color = mix(color, color * shadow_tint, (1.0 - luminance) * tint_strength);
	// 高光区域添加暖色调
	vec3 highlight_color = mix(shadow_color, shadow_color * highlight_tint, luminance * tint_strength);
	color = highlight_color;
	
	// =====================================================
	// 7. 暗角效果
	// =====================================================
	if (vignette_strength > 0.0) {
		vec2 uv = UV - 0.5;
		float dist = length(uv) * 2.0;
		float vignette = 1.0 - smoothstep(
			vignette_radius - vignette_softness,
			vignette_radius + vignette_softness,
			dist
		);
		vignette = mix(1.0, vignette, vignette_strength);
		color *= vignette;
	}
	
	// =====================================================
	// 8. 色差效果（可选，模拟镜头色散）
	// =====================================================
	if (enable_chromatic_aberration && chromatic_aberration > 0.0) {
		vec2 direction = UV - 0.5;
		float dist = length(direction);
		
		float r = texture(TEXTURE, UV + direction * chromatic_aberration * dist).r;
		float g = color.g;
		float b = texture(TEXTURE, UV - direction * chromatic_aberration * dist).b;
		
		color = vec3(r, g, b);
	}
	
	// =====================================================
	// 9. 锐化（可选）
	// =====================================================
	if (enable_sharpen && sharpen_amount > 0.0) {
		vec2 texel_size = TEXTURE_PIXEL_SIZE;
		vec3 blur = (
			texture(TEXTURE, UV + vec2(texel_size.x, 0.0)).rgb +
			texture(TEXTURE, UV - vec2(texel_size.x, 0.0)).rgb +
			texture(TEXTURE, UV + vec2(0.0, texel_size.y)).rgb +
			texture(TEXTURE, UV - vec2(0.0, texel_size.y)).rgb
		) * 0.25;
		
		color = color + (color - blur) * sharpen_amount;
	}
	
	// =====================================================
	// 10. 亮度调整
	// =====================================================
	color *= brightness;
	
	// =====================================================
	// 11. Gamma校正
	// =====================================================
	color = pow(color, vec3(1.0 / gamma));
	
	// =====================================================
	// 12. 最终色彩范围限制
	// =====================================================
	color = clamp(color, vec3(0.0), vec3(1.0));
	
	// 输出最终颜色
	COLOR = vec4(color, original_color.a);
}

// ============================================================================
// 备用：更简单的"复古游戏"风格着色器版本
// ============================================================================
// 如果需要更复古的效果，可以取消注释以下代码并注释掉上面的代码

/*
void fragment_simple() {
	vec4 original_color = texture(TEXTURE, UV);
	vec3 color = original_color.rgb;
	
	// 简单的色彩增强
	// 增加对比度
	color = mix(vec3(0.5), color, 1.2);
	
	// 增加饱和度
	vec3 gray = vec3(dot(color, vec3(0.299, 0.587, 0.114)));
	color = mix(gray, color, 1.15);
	
	// 轻微偏暖的色调
	color.r *= 1.05;
	color.b *= 0.98;
	
	// 轻微暗角
	vec2 uv = UV - 0.5;
	float vignette = 1.0 - length(uv) * 0.5;
	color *= vignette;
	
	COLOR = vec4(color, original_color.a);
}
*/

// ============================================================================
// 技术说明：
// ============================================================================
// 1. 这个着色器的设计原则是"增强而不破坏"
// 2. 所有调整都是可配置的，方便美术调整
// 3. 没有马赛克化、扫描线等破坏清晰度的效果
// 4. 像素锐利度由 Sprite3D 的 TEXTURE_FILTER_NEAREST 保证
// 5. 深度感由 3D 环境的光影和 DOF 提供
// 6. 色彩风格参考了《八方旅人》和《三角战略》
// ============================================================================
