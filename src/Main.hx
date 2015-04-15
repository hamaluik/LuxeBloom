import luxe.Color;
import luxe.Input;
import luxe.Log;
import luxe.Sprite;
import luxe.Vector;
import phoenix.Texture;
import luxe.Parcel;

class Main extends luxe.Game {
	// normal sprites
	var cityScape:Sprite;

	var bloomEffect:BloomEffect = new BloomEffect();

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

		var cityScapeTexture:Texture = Luxe.resources.find_texture('assets/edmonton.png');
		cityScape = new Sprite({
			texture: cityScapeTexture,
			pos: Luxe.screen.mid,
			size: new Vector(cityScapeTexture.width_actual, cityScapeTexture.height_actual),
			depth: 0
		});

		bloomEffect.onload();
	}

	override function onkeyup( e:KeyEvent ) {
		if(e.keycode == Key.escape) {
			Luxe.shutdown();
		}

	} //onkeyup

	override public function onmousemove(event:MouseEvent) {
		// set the amount of blur in the bloom filter based on the mouse's x-axis
		bloomEffect.radius = 3 * event.pos.x / Luxe.screen.w;

		// set the bloom threshold to the mouse's y-axis
		bloomEffect.threshold = event.pos.y / Luxe.screen.h;
	}

	override function onprerender() {
		bloomEffect.onprerender();
	}

	override function onpostrender() {
		bloomEffect.onpostrender();
	}

} //Main
