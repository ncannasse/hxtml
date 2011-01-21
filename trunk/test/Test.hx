class Test {

	static function main() {
		haxe.Firebug.redirectTraces();
		var mc = new flash.display.Sprite();
		var c = new hxtml.Context(mc, flash.Lib.current.stage.stageWidth);
		var b = new hxtml.Browser(c);
		b.onLoaded = function() {
			var b = new flash.display.BitmapData(c.pageWidth, b.dom.totalHeight, true, 0);
			b.draw(mc);
			var bmp = new flash.display.Bitmap(b);
			bmp.alpha = 0.5;
			flash.Lib.current.addChild(bmp);
		};
		b.browse("test.html");
	}
	
}