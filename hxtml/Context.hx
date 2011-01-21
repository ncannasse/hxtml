package hxtml;

class Element {
	
	public var e : flash.display.Sprite;
	
	public function new(e) {
		this.e = e;
	}
	
	public function setPos(x, y) {
		e.x = x;
		e.y = y;
	}
	
	public function setClick( f ) {
		e.addEventListener(flash.events.MouseEvent.CLICK, function(_) f());
	}
	
}

class Image {

	public var width(getWidth, null) : Int;
	public var height(getHeight, null) : Int;
	public var bmp(default,null) : flash.display.BitmapData;
	public var waiting : Array< Image -> Void >;
	
	public function new() {
		waiting = [];
	}
	
	public function setData(bmp) {
		this.bmp = bmp;
	}
	
	function getWidth() {
		return bmp.width;
	}

	function getHeight() {
		return bmp.height;
	}
	
}

class Text {
	public var tf : flash.text.TextField;
	public var width(getWidth, null) : Int;
	public var height(getHeight, null) : Int;
	
	public function new(tf) {
		this.tf = tf;
	}
	
	public function getCharIndex( px : Int ) {
		return tf.getCharIndexAtPoint(px + 2 /* left-margin */, 2);
	}

	public function getBaseLineHeight() {
		return Math.ceil(tf.getLineMetrics(0).ascent) + 1;
	}
	
	function getWidth() {
		return Math.ceil(tf.textWidth);
	}

	function getHeight() {
		return Math.ceil(tf.textHeight) + 1;
	}
	
}

typedef FontStyle = {
	var bold : Bool;
	var italic : Bool;
}

class Font {

	public var f : flash.text.Font;
	
	public function new(f) {
		this.f = f;
	}
	
}

class Context {
	
	var s : flash.display.Sprite;
	var curClick : Dom;
	var clicks : Array<Dom>;
	
	var imageCash : Hash<Image>;
	
	public var root : Element;
	public var pageWidth : Int;
	
	public function new(s, width) {
		this.s = s;
		root = new Element(s);
		clicks = [];
		imageCash = new Hash();
		pageWidth = width;
	}
	
	public function clear() {
		while( s.numChildren > 0 )
			s.removeChild(s.getChildAt(0));
	}

	public function createElement( parent : Element ) {
		var s = new flash.display.Sprite();
		parent.e.addChild(s);
		return new Element(s);
	}
	
	public function createText( text : String, s : Style ) {
		var t = new flash.text.TextField();
		t.width = 0;
		t.autoSize = flash.text.TextFieldAutoSize.LEFT;
		var f = t.defaultTextFormat;
		f.font = s.font.f.fontName;
		f.size = s.fontSize;
		f.color = s.textColor;
		f.underline = s.underline;
		t.defaultTextFormat = f;
		t.text = text;
		t.selectable = false;
		t.alpha = 0.8;
		// remove top-left text margin
		t.x = -2;
		t.y = -1;
		return new Text(t);
	}
	
	public function addText( p : Element, t : Text ) {
		p.e.addChild(t.tf);
	}
	
	public function addBackground( p : Element, color : Int, width : Int, height : Int ) {
		p.e.graphics.beginFill(color);
		p.e.graphics.drawRect(0, 0, width, height);
	}
	
	public function addBackgroundImage( p : Element, i : Image, s : Style, width : Int, height : Int ) {
		p.e.graphics.beginBitmapFill(i.bmp);
		p.e.graphics.drawRect(0, 0, width, height);
	}
	
	public function addImage( p : Element, x : Int, y : Int, i : Image ) {
		var b = new flash.display.Bitmap(i.bmp);
		b.x = x;
		b.y = y;
		p.e.addChild(b);
	}

	public function getNativeFont( name : String, style : FontStyle ) : Font {
		var kstyle = if( style.bold && style.italic )
			flash.text.FontStyle.BOLD_ITALIC;
		else if( style.bold )
			flash.text.FontStyle.BOLD;
		else if( style.italic )
			flash.text.FontStyle.ITALIC;
		else
			flash.text.FontStyle.REGULAR;
		for( f in flash.text.Font.enumerateFonts(true) ) {
			if( f.fontName == name && f.fontStyle == kstyle )
				return new Font(f);
		}
		throw "Font not found " + name + "(" + kstyle + ")";
		return null;
	}
	
	public function loadText( url : String, onLoaded : String -> Void ) {
		var l = new flash.net.URLLoader();
		l.addEventListener(flash.events.Event.COMPLETE, function(_) {
			onLoaded(l.data);
		});
		l.load(new flash.net.URLRequest(url));
	}
	
	public function loadImage( url : String, onLoaded : Image -> Void ) : Image {
		var i = imageCash.get(url);
		if( i != null ) {
			if( i.bmp != null )
				return i;
			i.waiting.push(onLoaded);
			return null;
		}
		var isCached = (url.indexOf("?") < 0 );
		i = new Image();
		if( isCached )
			imageCash.set(url, i);
		i.waiting.push(onLoaded);
		var l = new flash.display.Loader();
		l.contentLoaderInfo.addEventListener(flash.events.Event.COMPLETE, function(_) {
			var img = flash.Lib.as(l.content, flash.display.Bitmap);
			if( img == null ) throw "Invalid image " + url;
			i.setData(img.bitmapData);
			var old = i.waiting;
			i.waiting = [];
			for( f in old )
				f(i);
		});
		l.load(new flash.net.URLRequest(url));
		return null;
	}
	
}