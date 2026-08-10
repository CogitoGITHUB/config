#version 320 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

uniform float time;
uniform vec2  surface_size;
uniform float is_active;

void main() {
    float wave = sin(v_texcoord.y * 20.0 + time * 2.0) * 0.002 * is_active;
    vec4 col = texture(tex, v_texcoord + vec2(wave, 0.0));
    col.rgb *= mix(0.6, 1.0, is_active);
    fragColor = col;
}