shader_type canvas_item;
render_mode unshaded;

// ─────────────────────────────────────────────────────────────────────────
//  MAP VARIANT — one portolan, two readings (GDD.md §11.4).
//
//  The map screen shows the Book and Reality versions side by side. Both
//  draw the same SVG; this shader is the whole difference between them:
//  gilded and saturated for the Book, chalky and desaturated for Reality.
//  No second asset, no second drawing to maintain.
// ─────────────────────────────────────────────────────────────────────────

uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float saturation : hint_range(0.0, 2.0) = 1.0;
uniform float brightness : hint_range(0.0, 2.0) = 1.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float luma = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	vec3 col = mix(vec3(luma), tex.rgb, saturation);
	col *= tint.rgb * brightness;
	COLOR = vec4(col, tex.a);
}
