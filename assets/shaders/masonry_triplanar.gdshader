shader_type spatial;
render_mode cull_back;

// ─────────────────────────────────────────────────────────────────────────
//  MASONRY — triplanar stone courses for the Venture of Montiel's tower.
//
//  The tower is an eight-sided cylinder. A box UV would seam at every
//  corner; triplanar sampling from world position has no seams at all, and
//  is why the masonry is a texture rather than the stacked flat courses
//  the grey-box used. See docs/ART_BRIEF_VENTURE.md, "What is still missing".
//
//  World-space derivatives give a flat, per-face normal. That is deliberate:
//  the house style is flat-shaded gouache, and a faceted blend keeps each
//  of the eight sides reading as a plane. No baked light, no specular —
//  the truth-layer post-process grades the whole screen afterwards.
// ─────────────────────────────────────────────────────────────────────────

uniform sampler2D masonry_tex : source_color, repeat_enable, filter_linear;
uniform float tile_scale : hint_range(0.02, 2.0) = 0.18;
uniform float sharpness : hint_range(1.0, 16.0) = 6.0;
uniform vec4 stone_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

varying vec3 v_world_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Flat per-face normal from world-space derivatives. abs() is enough:
	// only the magnitude of each axis is needed for the blend weights.
	vec3 n = abs(normalize(cross(dFdx(v_world_pos), dFdy(v_world_pos))));
	n = pow(n, vec3(sharpness));
	n /= max(n.x + n.y + n.z, 0.0001);

	vec2 uv_x = v_world_pos.zy * tile_scale;
	vec2 uv_y = v_world_pos.xz * tile_scale;
	vec2 uv_z = v_world_pos.xy * tile_scale;

	vec4 sx = texture(masonry_tex, uv_x);
	vec4 sy = texture(masonry_tex, uv_y);
	vec4 sz = texture(masonry_tex, uv_z);

	vec4 stone = sx * n.x + sy * n.y + sz * n.z;
	ALBEDO = stone.rgb * stone_tint.rgb;
	ROUGHNESS = 0.94;
	METALLIC = 0.0;
	SPECULAR = 0.0;
}
