shader_type canvas_item;

// Intensity pulsante del glow
uniform float glow_strength : hint_range(0.0, 5.0) = 1.5;
uniform vec4 glow_color : source_color = vec4(0.0, 1.0, 1.0, 1.0); // Cyan
uniform float pulse_speed = 4.0;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    float pulse = 0.5 + 0.5 * sin(TIME * pulse_speed);
    tex.rgb += glow_color.rgb * glow_strength * pulse * tex.a;
    COLOR = tex;
}
