uniform sampler2D tex0;
varying vec2 tcoord;
varying vec4 color;

uniform float frequency;
uniform float glitchAmount;
uniform vec2 resolution;
uniform float time;

void main() {
	vec3 val = vec3(0.0);//texture2D(tex0, tcoord);

	// colour offset glitch
	val.r = texture2D(tex0, tcoord + vec2(glitchAmount / resolution.x, 0.0)).r;
	val.g = texture2D(tex0, tcoord).g;
	val.b = texture2D(tex0, tcoord + vec2(-glitchAmount / resolution.x, 0.0)).b;

	// the scanline
	//val *= max(vec3(mod(gl_FragCoord.y + time, spacing)) + vec3(0.25), vec3(1.0));
	//val *= 0.8+0.2*sin(10.0*time+uv.y*900.0);
	val *= 0.8 + 0.2 * sin(frequency * gl_FragCoord.y + time);

	gl_FragColor = color * vec4(val.rgb, 1.0);
}
