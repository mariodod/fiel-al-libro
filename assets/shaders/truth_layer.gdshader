shader_type canvas_item;
render_mode unshaded;

// ─────────────────────────────────────────────────────────────────────────
//  TRUTH LAYER — the one shader that carries the whole art direction.
//
//  D2: the truth layer is global. Changing the world's reality is a float
//  write, never an asset swap. This is the single biggest cost-saver in the
//  entire project: one shader family, one uniform, two looks.
//
//  truth_layer = 0.0  →  Reality Truth: chalky, high-key, cool-neutral,
//                        honest geometry, long afternoon shadows.
//  truth_layer = 1.0  →  Book Truth:   saturated, warm, gilded, pen-and-ink
//                        contours, theatrical light.
//  ink_amount   = 0..1  →  The Ink: neither truth. Edges fray. Text smears.
//
//  ── UPGRADE PATH ──────────────────────────────────────────────────────
//  The outline pass below is a luminance Sobel over the screen texture,
//  because canvas_item shaders cannot read the depth buffer
//  (hint_depth_texture is not supported there). For true depth-silhouette
//  outlines, move this into a CompositorEffect (Godot 4.3+) with a
//  RDShaderFile — that is a Phase 1 task, not a Phase 0 one. The
//  luminance pass already reads as ink on a painterly image.
//
//  See GDD.md §4.3.
// ─────────────────────────────────────────────────────────────────────────

global uniform float truth_layer = 0.0;
global uniform float ink_amount = 0.0;
global uniform float layer_blend_speed = 1.0;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear;

group_uniforms reality;
uniform vec4 reality_tint : source_color = vec4(0.94, 0.92, 0.86, 1.0);
uniform float reality_saturation : hint_range(0.0, 2.0) = 0.52;
uniform float reality_contrast : hint_range(0.5, 2.0) = 1.14;
group_uniforms;

group_uniforms book;
uniform vec4 book_tint : source_color = vec4(1.00, 0.86, 0.62, 1.0);
uniform float book_saturation : hint_range(0.0, 2.0) = 1.38;
uniform float book_contrast : hint_range(0.5, 2.0) = 1.24;
uniform float book_bloom : hint_range(0.0, 1.0) = 0.22;
group_uniforms;

group_uniforms line_art;
// Screen-space edge detect → pen-and-ink contour. This is what makes
// low-poly read as illustration instead of as a blockout.
//
// These numbers were set before the post-process ever actually rendered
// (a Control under a CanvasLayer does not get a size from its anchors —
// see src/ui/post_process.gd), so they had never been looked at. They
// are now tuned against a real screenshot: heavy enough to read as ink,
// light enough that a character is still a character and not a blob.
uniform float line_strength : hint_range(0.0, 4.0) = 1.25;
uniform float line_width : hint_range(1.0, 6.0) = 1.2;
uniform float line_threshold : hint_range(0.0, 1.0) = 0.12;
uniform vec4 ink_color : source_color = vec4(0.09, 0.07, 0.05, 1.0);
group_uniforms;

group_uniforms paper;
uniform float grain_strength : hint_range(0.0, 0.5) = 0.055;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.26;
uniform float paper_warmth : hint_range(0.0, 1.0) = 0.35;
group_uniforms;

group_uniforms ink;
uniform float ink_smear : hint_range(0.0, 1.0) = 0.35;
uniform float ink_darken : hint_range(0.0, 1.0) = 0.25;
group_uniforms;


float hash21(vec2 p) {
	p = fract(p * vec2(233.34, 851.73));
	p += dot(p, p + 23.45);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float luma_of(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

vec3 grade(vec3 col, float saturation, float contrast, vec4 tint) {
	float l = luma_of(col);
	col = mix(vec3(l), col, saturation);
	col = (col - 0.5) * contrast + 0.5;
	col *= tint.rgb;
	return col;
}

// Godot 4's canvas_item built-ins do not include SCREEN_PIXEL_SIZE or
// VIEWPORT_SIZE, so the pixel footprint is derived from the screen
// texture's own dimensions.
vec2 pixel_step() {
	return 1.0 / max(vec2(textureSize(screen_tex, 0)), vec2(1.0));
}

// A 3x3 Sobel over luminance. Cheap, and on a high-contrast painterly
// image it reads as a pen-and-ink contour.
float edge_detect(vec2 uv, float width) {
	vec2 px = width * pixel_step();

	float tl = luma_of(texture(screen_tex, uv + vec2(-px.x, -px.y)).rgb);
	float tc = luma_of(texture(screen_tex, uv + vec2(0.0, -px.y)).rgb);
	float tr = luma_of(texture(screen_tex, uv + vec2(px.x, -px.y)).rgb);
	float ml = luma_of(texture(screen_tex, uv + vec2(-px.x, 0.0)).rgb);
	float mr = luma_of(texture(screen_tex, uv + vec2(px.x, 0.0)).rgb);
	float bl = luma_of(texture(screen_tex, uv + vec2(-px.x, px.y)).rgb);
	float bc = luma_of(texture(screen_tex, uv + vec2(0.0, px.y)).rgb);
	float br = luma_of(texture(screen_tex, uv + vec2(px.x, px.y)).rgb);

	float gx = (tr + 2.0 * mr + br) - (tl + 2.0 * ml + bl);
	float gy = (bl + 2.0 * bc + br) - (tl + 2.0 * tc + tr);
	return sqrt(gx * gx + gy * gy);
}

void fragment() {
	// The ColorRect must cover the full viewport (full-rect anchors).
	vec2 uv = SCREEN_UV;

	// ── The Ink: warp the sample before anything else. ────────────────
	float ink = clamp(ink_amount, 0.0, 1.0);
	if (ink > 0.001) {
		float n = value_noise(uv * 18.0 + vec2(0.0, TIME * 0.05));
		float n2 = value_noise(uv * 42.0 - vec2(TIME * 0.03, 0.0));
		uv += (vec2(n, n2) - 0.5) * ink * ink_smear * 0.02;
	}

	vec3 col = texture(screen_tex, uv).rgb;

	// ── Truth grade ───────────────────────────────────────────────────
	float t = clamp(truth_layer, 0.0, 1.0);
	vec3 reality = grade(col, reality_saturation, reality_contrast, reality_tint);
	vec3 book = grade(col, book_saturation, book_contrast, book_tint);
	col = mix(reality, book, t);

	// Book layer gets a soft glow, like light through old paper.
	if (t > 0.001) {
		vec2 bpx = 2.0 * pixel_step();
		vec3 blurred = texture(screen_tex, uv + vec2(0.0, bpx.y)).rgb
			+ texture(screen_tex, uv - vec2(0.0, bpx.y)).rgb
			+ texture(screen_tex, uv + vec2(bpx.x, 0.0)).rgb
			+ texture(screen_tex, uv - vec2(bpx.x, 0.0)).rgb;
		blurred *= 0.25;
		col = mix(col, max(col, blurred), t * book_bloom);
	}

	// ── Pen-and-ink contour ───────────────────────────────────────────
	// Stronger in the Book layer: the world becomes a printed page.
	float edge = edge_detect(uv, line_width);
	float line_amount = smoothstep(line_threshold, line_threshold + 0.35, edge) * line_strength;
	line_amount = clamp(line_amount, 0.0, 1.0);
	line_amount *= mix(0.55, 1.0, t);
	// The Ink frays the line instead of drawing it.
	line_amount *= (1.0 - ink * 0.6);
	col = mix(col, ink_color.rgb, line_amount * 0.8);

	// ── Paper grain ───────────────────────────────────────────────────
	// The world is already a text. It just does not know it.
	float grain = hash21(SCREEN_UV * vec2(1920.0, 1080.0) + TIME * 0.5) - 0.5;
	col += grain * grain_strength;
	// Warm the paper slightly toward the Book layer.
	col = mix(col, col * vec3(1.02, 1.0, 0.95), paper_warmth * t);

	// ── Ink darkening (DLC 3) ─────────────────────────────────────────
	col *= (1.0 - ink * ink_darken);

	// ── Vignette ──────────────────────────────────────────────────────
	vec2 d = SCREEN_UV - vec2(0.5);
	float vig = 1.0 - dot(d, d) * vignette_strength * 2.4;
	col *= clamp(vig, 0.0, 1.0);

	COLOR = vec4(col, 1.0);
}
