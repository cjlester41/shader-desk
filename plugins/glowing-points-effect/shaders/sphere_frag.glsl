#version 300 es
precision mediump float;

in float vPhase;
out vec4 FragColor;

uniform float time;

// @param glow_color | vec3 | 0.0, 0.8, 1.0 | Color of the points (R,G,B)
uniform vec3 glow_color;

void main() {
    // gl_PointCoord (0.0 to 1.0) maps to the surface of the generated point
    vec2 coord = gl_PointCoord - vec2(0.5);
    float dist = length(coord);

    // Discard pixels outside the radius to make the point a perfect circle
    if (dist > 0.5) {
        discard;
    }

    // Create a soft radial falloff (glow)
    float intensity = 1.0 - smoothstep(0.0, 0.5, dist);
    
    // Add a subtle flicker based on vertex phase [cite: 16, 50]
    float flicker = 0.7 + 0.3 * sin(time * 3.0 + vPhase);

    FragColor = vec4(glow_color * intensity * flicker, intensity);
}