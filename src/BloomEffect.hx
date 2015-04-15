package ;

import luxe.Visual;
import luxe.Rectangle;
import phoenix.Batcher;
import phoenix.geometry.QuadGeometry;
import phoenix.RenderTexture;
import phoenix.Shader;

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
}