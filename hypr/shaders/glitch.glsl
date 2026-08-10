#version 320 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

uniform float time;
uniform float is_active;

float rnd(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void main() {
    vec2 uv = v_texcoord;
    float on = step(0.5, is_active);
    float t = floor(time * 8.0);

    vec2 off = vec2(0.0);
    if (rnd(vec2(t, 7.0)) > 0.96) {
        float row = step(0.99, rnd(vec2(floor(v_texcoord.y * 40.0), t)));
        off.x = (rnd(vec2(t, 3.0)) - 0.5) * 0.08 * row;
    }

    vec4 col = texture(tex, v_texcoord + off * on);
    if (rnd(vec2(v_texcoord.y * 60.0, t)) > 0.998)
        col.rb = col.br;

    fragColor = mix(col, texture(tex, v_texcoord), 1.0 - on);
}