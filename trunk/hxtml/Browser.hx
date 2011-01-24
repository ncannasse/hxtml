package hxtml;
import hxtml.Dom;

class Browser {

	public var ctx : Context;
	public var url : String;
	public var dom : Dom;
	public var css : CssEngine;
	var ids : Hash<Dom>;
	
	var invalid : Bool;
	var loaded : Bool;
	
	public function new(c) {
		this.ctx = c;
	}
	
	public function browse( url : String ) {
		var me = this;
		ctx.loadText(url, function(data) {
			me.url = url;
			me.showHTML(data);
		});
	}
	
	public function invalidate() {
		if( invalid ) return;
		invalid = true;
		haxe.Timer.delay(refresh, 1);
	}
	
	public function register(id, d) {
		ids.set(id, d);
	}
	
	public inline function isLoaded() {
		return loaded;
	}
	
	public function notLoaded() {
		loaded = false;
	}
	
	public dynamic function onLoaded() {
	}

	function showHTML( data : String ) {
		var x = Xml.parse(data).firstElement();
		css = new CssEngine(this);
		ids = new Hash();
		dom = make(x);
		refresh();
	}
	
	public function refresh() {
		trace("REFRESH");
		invalid = false;
		loaded = true;
		ctx.clear();
		dom.updateStyle();
		dom.updateSize(ctx.pageWidth,null);
		dom.updatePos(0, 0);
		dom.render();
		if( loaded )
			onLoaded();
	}
	
	public function getById(id) {
		return ids.get(id);
	}

	function make( x : Xml ) : Dom {
		// create element
		switch( x.nodeType ) {
		case Xml.CData:
			throw "assert";
		case Xml.PCData, Xml.Comment:
			return new DomText(this,x.nodeValue);
		}
		var d : Dom;
		var name = x.nodeName.toLowerCase();
		var allowSpaces = true, allowComments = false;
		switch( name ) {
		case "head", "link", "meta", "title":
			allowSpaces = false;
			d = new DomHidden(this, name);
		case "html":
			allowSpaces = false;
			d = new Dom(this, name);
		case "div", "span", "body", "br":
			d = new Dom(this, name);
		case "a":
			d = new DomLink(this, name);
		case "img":
			d = new DomImage(this, name);
		case "style":
			d = new DomStyle(this, name);
			allowComments = true;
		default:
			throw "Unsupported html node : " + x.nodeName;
		}
		// build children
		var prev : Dom = null, hasText = false;
		for( c in x ) {
			// remove empty texts
			switch( c.nodeType ) {
			case Xml.PCData:
				if( ~/^[ \n\r\t]*$/.match(c.nodeValue) ) {
					if( !allowSpaces || prev == null )
						continue;
					if( prev.name != null )
						hasText = true;
					else
						prev.getText().appendSpace();
					continue;
				}
				if( hasText ) {
					hasText = false;
					c.nodeValue = " " + c.nodeValue;
				}
			case Xml.Comment:
				if( !allowComments )
					continue;
			default:
				if( hasText ) {
					hasText = false;
					d.addChild(new DomText(this, " "));
				}
			}
			prev = make(c);
			d.addChild(prev);
		}
		// init attributes
		for( a in x.attributes() )
			d.setAttribute(a.toLowerCase(), x.get(a));
		return d;
	}
	
}