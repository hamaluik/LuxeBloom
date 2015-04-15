package ;

import luxe.Visual;
import luxe.Rectangle;
import phoenix.Batcher;
import phoenix.geometry.QuadGeometry;
import phoenix.RenderTexture;
import phoenix.Shader;
import luxe.Vector;
import luxe.Color;

/**
  * @author KentonHamaluik (@FuzzyWuzzie on GitHub)
  */
class BloomEffect {
	var bloomBrightShader:Shader;
	var bloomBlurShader:Shader;

	var screenRenderTexture:RenderTexture;
	var screenBatcher:Batcher;
	var brightBatcher:Batcher;

	var postBrightTexture:RenderTexture;
	var horizBlurBatcher:Batcher;
	var postHorizBlurTexture:RenderTexture;
	var vertBlurBatcher:Batcher;

	var screenVisual:Visual;
	var brightVisual:Visual;
	var horizBlurVisual:Visual;
	var vertBlurVisual:Visual;

	var clearColour:Color = new Color(0, 0, 0, 0);
	var loaded:Bool = false;
	var po2:Float;

	@:isVar public var threshold(default, set):Float;
	@:isVar public var radius(default, set):Float;

	function set_threshold(_t:Float) {
		if(bloomBrightShader != null) {
			bloomBrightShader.set_float('brightPassThreshold', _t);
		}
		return threshold = _t;
	}

	function set_radius(_r:Float) {
		if(bloomBlurShader != null) {
			bloomBlurShader.set_float('blur', _r / po2);
		}
		return radius = _r;
	}

	public function new() {

	}

	public function onload() {
		// calculate the next highest power of 2 from our screen resolution
		// so that we can determine how big we need to make the textures
		po2 = nextLargestPowerOf2(Math.max(Luxe.screen.w, Luxe.screen.h));

		// BEGIN SHADERS
		bloomBrightShader = Luxe.resources.find_shader('assets/isolate_bright.glsl|default');
		bloomBrightShader.set_float('brightPassThreshold', 0.5);

		bloomBlurShader = Luxe.resources.find_shader('assets/blur.glsl|default');
		bloomBlurShader.set_float('blur', 1 / po2);
		bloomBlurShader.set_vector2('dir', new Vector(1, 0));
		// END SHADERS

		// BEGIN SCREEN
		screenRenderTexture = new RenderTexture(Luxe.resources, new Vector(po2, po2));

		screenBatcher = Luxe.renderer.create_batcher({
			name: 'screenBatcher',
			no_add: true
		});
		screenBatcher.view.viewport = Luxe.camera.viewport;

		screenVisual = new Visual({
			texture: screenRenderTexture,
			pos: new Vector(0, Luxe.screen.h - po2),
			size: new Vector(po2, po2),
			batcher: screenBatcher,
		});
		cast(screenVisual.geometry, QuadGeometry).flipy = true;
		// END SCREEN

		// BEGIN BRIGHTNESS CLAMPER
		brightBatcher = Luxe.renderer.create_batcher({
			name: 'brightBatcher',
			no_add: true
		});
		brightBatcher.view.viewport = Luxe.camera.viewport;

		brightVisual = new Visual({
			texture: screenRenderTexture,
			pos: new Vector(),
			size: new Vector(po2, po2),
			batcher: brightBatcher,
			shader: bloomBrightShader
		});

		postBrightTexture = new RenderTexture(Luxe.resources, new Vector(po2, po2));
		// END BRIGHTNESS CLAMPER

		// BEGIN HORIZONTAL BLUR
		postHorizBlurTexture = new RenderTexture(Luxe.resources, new Vector(po2, po2));

		horizBlurBatcher = Luxe.renderer.create_batcher({
			name: 'horizBlurBatcher',
			no_add: true
		});
		horizBlurBatcher.view.viewport = Luxe.camera.viewport;

		horizBlurVisual = new Visual({
			texture: postBrightTexture,
			pos: new Vector(),
			size: new Vector(po2, po2),
			batcher: horizBlurBatcher,
			shader: bloomBlurShader
		});
		// END HORIZONTAL BLUR

		// BEGIN VERTICAL BLUR
		vertBlurBatcher = Luxe.renderer.create_batcher({
			name: 'vertBlurBatcher',
			no_add: true
		});
		vertBlurBatcher.view.viewport = Luxe.camera.viewport;

		vertBlurVisual = new Visual({
			texture: postHorizBlurTexture,
			pos: new Vector(0, Luxe.screen.h - po2),
			size: new Vector(po2, po2),
			batcher: vertBlurBatcher,
			shader: bloomBlurShader
		});
		cast(vertBlurVisual.geometry, QuadGeometry).flipy = true;
		// END VERTICAL BLUR

		// set the default uniform values
		radius = 2;
		threshold = 0.5;

		loaded = true;
	}

	public function onprerender() {
		if(!loaded) {
			// if the parcel hasn't loaded yet, don't bother with this stuff
			return;
		}

		// render everything to our screen render texture
		Luxe.renderer.target = screenRenderTexture;
	}

	public function onpostrender() {
		if(!loaded) {
			// if the parcel hasn't loaded yet, don't bother with this stuff
			return;
		}

		// by now, everything will have been rendered to the screenRenderTexture

		// do another pass, rendering only the _bright_ areas of the image
		// this result will be stored in `postBrightTexture`
		Luxe.renderer.target = postBrightTexture;
		Luxe.renderer.clear(clearColour);
		brightBatcher.draw();

		// do another pass, which will blur the `postBrightTexture` image
		// and store the result in the `postHorizBlurTexture`
		Luxe.renderer.target = postHorizBlurTexture;
		Luxe.renderer.clear(clearColour);
		// set the blur direction for the shader
		bloomBlurShader.set_vector2('dir', new Vector(1, 0));
		horizBlurBatcher.draw();

		// do another pass, this time rendering to the screen (finally!)
		Luxe.renderer.target = null;
		Luxe.renderer.clear(clearColour);

		// draw our saved screen image (it will have been rendered normally in the onrender() function)
		screenBatcher.draw();

		// now draw the bloom effect on top of the saved screen image
		// using additive blending
		Luxe.renderer.blend_mode(BlendMode.src_alpha, BlendMode.one);

		// set the blur shader that this is using to blur in the vertical direction
		// so that we get a nice 2D gaussian blur
		bloomBlurShader.set_vector2('dir', new Vector(0, 1));
		vertBlurBatcher.draw();

		// return to default blending
		Luxe.renderer.blend_mode();
	}

	private static function nextLargestPowerOf2(dimen:Float):Float {
		var y:Float = Math.floor(Math.log(dimen)/Math.log(2));
		return Math.pow(2, y + 1);
	}
}