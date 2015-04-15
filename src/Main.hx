import luxe.Color;
import luxe.Input;
import luxe.Log;
import luxe.Rectangle;
import luxe.Sprite;
import luxe.Visual;
import luxe.Vector;
import phoenix.Batcher;
import phoenix.geometry.QuadGeometry;
import phoenix.RenderTexture;
import phoenix.Texture;
import luxe.Parcel;
import phoenix.Shader;

class Main extends luxe.Game {
	var loaded:Bool = false;

	// normal sprites
	var cityScape:Sprite;

	// bloom stuff
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

	override function ready() {
		// load the parcel
		Luxe.loadJSON("assets/parcel.json", function(jsonParcel) {
			var parcel = new Parcel();
			parcel.from_json(jsonParcel.json);

			// show a loading bar
			// use a fancy custom loading bar (https://github.com/FuzzyWuzzie/CustomLuxePreloader)
			new DigitalCircleParcelProgress({
				parcel: parcel,
				oncomplete: assetsLoaded
			});
			
			// start loading!
			parcel.load();
		});
	} //ready

	function assetsLoaded(_) {
		// load things normally
		Luxe.renderer.clear_color = new Color(1, 0, 0, 1);

		cityScape = new Sprite({
			texture: Luxe.resources.find_texture('assets/edmonton.png'),
			pos: Luxe.screen.mid,
			size: new Vector(1024, 1024),
			depth: 0
		});

		// BEGIN SHADERS
		bloomBrightShader = Luxe.resources.find_shader('assets/isolate_bright.glsl|default');
		bloomBrightShader.set_float('brightPassThreshold', 0.5);

		bloomBlurShader = Luxe.resources.find_shader('assets/blur.glsl|default');
		bloomBlurShader.set_float('blur', 1 / 1024);
		bloomBlurShader.set_vector2('dir', new Vector(1, 0));
		// END SHADERS

		// BEGIN SCREEN
		screenRenderTexture = new RenderTexture(Luxe.resources, new Vector(1024, 1024));

		screenBatcher = Luxe.renderer.create_batcher({
			name: 'screenBatcher',
			no_add: true
		});
		screenBatcher.view.viewport = Luxe.camera.viewport;

		screenVisual = new Visual({
			texture: screenRenderTexture,
			pos: new Vector(0, Luxe.screen.h - 1024),
			size: new Vector(1024, 1024),
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
			size: new Vector(1024, 1024),
			batcher: brightBatcher,
			shader: bloomBrightShader
		});

		postBrightTexture = new RenderTexture(Luxe.resources, new Vector(1024, 1024));
		// END BRIGHTNESS CLAMPER

		// BEGIN HORIZONTAL BLUR
		postHorizBlurTexture = new RenderTexture(Luxe.resources, new Vector(1024, 1024));

		horizBlurBatcher = Luxe.renderer.create_batcher({
			name: 'horizBlurBatcher',
			no_add: true
		});
		horizBlurBatcher.view.viewport = Luxe.camera.viewport;

		horizBlurVisual = new Visual({
			texture: postBrightTexture,
			pos: new Vector(),
			size: new Vector(1024, 1024),
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
			pos: new Vector(0, Luxe.screen.h - 1024),
			size: new Vector(1024, 1024),
			batcher: vertBlurBatcher,
			shader: bloomBlurShader
		});
		cast(vertBlurVisual.geometry, QuadGeometry).flipy = true;
		// END VERTICAL BLUR

		loaded = true;
	}

	override function onkeyup( e:KeyEvent ) {
		if(e.keycode == Key.escape) {
			Luxe.shutdown();
		}

	} //onkeyup

	override public function onmousemove(event:MouseEvent) {
		if(!loaded) {
			return;
		}

		// set the amount of blur in the bloom filter based on the mouse's x-axis
		var blurPart:Float = 3 * event.pos.x / Luxe.screen.w;
		bloomBlurShader.set_float('blur', blurPart / 1024);

		// set the bloom threshold to the mouse's y-axis
		var threshold:Float = event.pos.y / Luxe.screen.h;
		bloomBrightShader.set_float('brightPassThreshold', threshold);
	}

	override function onprerender() {
		if(!loaded) {
			// if the parcel hasn't loaded yet, don't bother with this stuff
			return;
		}

		// render everything to our screen render texture
		Luxe.renderer.target = screenRenderTexture;
	}

	override function onpostrender() {
		if(!loaded) {
			// if the parcel hasn't loaded yet, don't bother with this stuff
			return;
		}

		// by now, everything will have been rendered to the screenRenderTexture

		// do another pass, rendering only the _bright_ areas of the image
		// this result will be stored in `postBrightTexture`
		Luxe.renderer.target = postBrightTexture;
		Luxe.renderer.clear(new Color(0, 0, 0, 0));
		brightBatcher.draw();

		// do another pass, which will blur the `postBrightTexture` image
		// and store the result in the `postHorizBlurTexture`
		Luxe.renderer.target = postHorizBlurTexture;
		Luxe.renderer.clear(new Color(0, 0, 0, 0));
		// set the blur direction for the shader
		bloomBlurShader.set_vector2('dir', new Vector(1, 0));
		horizBlurBatcher.draw();

		// do another pass, this time rendering to the screen (finally!)
		Luxe.renderer.target = null;
		Luxe.renderer.clear(new Color(0, 0, 0, 0));

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

	override function update(dt:Float) {
	} //update

} //Main
