package ;

import phoenix.Shader;
import luxe.Vector;

class GlitchEffect {
	public var scanlineShader:Shader;

	var glitchLength:Float = 0.1;
	var glitchTime:Float = 0;
	var nextGlitch:Float = 0;
	var glitching:Bool = false;

	var frequencyTime:Float = 0;

	var loaded:Bool = false;

	public function new() {
	}

	public function onload() {
		scanlineShader = Luxe.resources.find_shader('assets/scanlines.glsl|default');
		scanlineShader.set_float('glitchAmount', 0);
		scanlineShader.set_float('frequency', 1.5);
		scanlineShader.set_float('time', 0);
		scanlineShader.set_vector2('resolution', new Vector(Luxe.screen.w, Luxe.screen.h));
		nextGlitch = Luxe.utils.random.float(0.1, 5);
		loaded = true;
	}

	public function update(dt:Float) {
		if(!loaded) return;

		frequencyTime += dt;
		scanlineShader.set_float('time', frequencyTime);

		if(glitching) {
			glitchTime += dt;
			if(glitchTime >= glitchLength) {
				glitching = false;
				nextGlitch = Luxe.utils.random.float(0.1, 5);
				scanlineShader.set_float('glitchAmount', 0);
			}
		}
		else {
			nextGlitch -= dt;
			if(nextGlitch <= 0) {
				glitching = true;
				glitchTime = 0;
				scanlineShader.set_float('glitchAmount', 5);
			}
		}
	}
}