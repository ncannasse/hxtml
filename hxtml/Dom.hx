package hxtml;
import hxtml.Style;

class Dom {

	var browser : Browser;
	
	public var name(default, null) : String;
	public var childs(default, null) : Array<Dom>;
	public var style : Style;
	public var defStyle(default, null) : Style;
	public var parent : Dom;
	
	var ctx(getContext, null) : Context;
	var e : Context.Element;
	var prev : Dom;
	var next : Dom;
	
	
	public var id : String;
	public var classes : Array<String>;
	
	public var preferredWidth : Int;
	public var preferredHeight : Int;
	
	public var posX : Int;
	public var posY : Int;
	
	public var contentWidth : Int;
	public var contentHeight : Int;

	public var totalWidth : Int;
	public var totalHeight : Int;
	
	public var lineIndex : Int;
	
	public function new(b, name) {
		this.browser = b;
		this.name = name;
		this.defStyle = browser.css.makeDefaultStyle(this);
	}
	
	inline function getContext() {
		return browser.ctx;
	}
	
	public inline function getText() : DomText {
		return cast this;
	}
	
	public function addChild( c : Dom ) {
		if( c.parent != null ) throw "assert";
		if( childs == null )
			childs = [];
		childs.push(c);
		c.parent = this;
		var prev = childs[childs.length - 2];
		if( prev != null ) {
			c.prev = prev;
			prev.next = c;
		}
	}
	
	public function setAttribute( a : String, v : String ) {
		switch( a ) {
		case "id":
			id = v;
			browser.register(id, this);
		case "style":
			new CssParser().parse(v,defStyle);
		case "class":
			classes = ~/[ \t]+/g.split(StringTools.trim(v));
		default:
			throw "Unsupported attribute " + name + "." + a;
		}
	}

	public function updateStyle() {
		browser.css.applyClasses(this);
		if( parent != null )
			style.inherit(parent.style);
		if( childs != null )
			for( d in childs )
				d.updateStyle();
	}

	function initElement() {
	}
	
	public function render() {
		e = ctx.createElement((parent == null) ? ctx.root : parent.e);
		e.setPos(posX, posY);
		var plr = style.paddingLeft + style.paddingRight;
		var ptb = style.paddingTop + style.paddingBottom;
		if( style.bgColor != null && !style.bgTransparent )
			ctx.addBackground(e, style.bgColor, contentWidth + plr, contentHeight + ptb);
		if( style.bgImage != null ) {
			var me = this;
			var img = ctx.loadImage(style.bgImage, function(_) {
				me.browser.invalidate();
			});
			if( img == null )
				browser.notLoaded();
			else {
				var bw = contentWidth + plr;
				var bh = contentHeight + ptb;
				if( style.bgRepeatX == false && bw > img.width ) bw = img.width;
				if( style.bgRepeatY == false && bh > img.height ) bh = img.height;
				ctx.addBackgroundImage(e, img, style, bw, bh);
			}
		}
		initElement();
		if( childs != null )
			for( d in childs )
				d.render();
	}
	
	public function updateSize( width : Int, height : Null<Int> ) {
		var plr = style.paddingLeft + style.paddingRight;
		var ptb = style.paddingTop + style.paddingBottom;
		var mlr = style.marginLeft + style.marginRight;
		var mtb = style.marginTop + style.marginBottom;
		
		if( style.width != null )
			width = style.width;
		if( style.height != null )
			height = style.height;
		
		contentWidth = 0;
		contentHeight = 0;
	
		// inline childs
		if( childs != null ) {
			var allowedWidth = width - (mlr + plr);
			var lineWidth = 0, lineHeight = 0;
			var i = 0, count = childs.length, breakLine = false, lineIndex = 0;
			while( i < count ) {
				var d = childs[i++];
				var isBlock = (d.style.display == Block);
				// create new line
				if( isBlock && lineWidth > 0 ) {
					contentHeight += lineHeight;
					if( lineWidth > contentWidth )
						contentWidth = lineWidth;
					lineWidth = 0;
					lineHeight = 0;
					lineIndex++;
				}
				d.updateSize(allowedWidth - lineWidth, height);
				// check breakable
				if( d.name == null && browser.isLoaded() && lineWidth + d.totalWidth > allowedWidth ) {
					var d2 : Dom = d.getText().breakAt(allowedWidth - lineWidth);
					if( d2 != null ) {
						d2.next = d.next;
						d2.prev = d;
						d.next = d2;
						d2.parent = this;
						d2.updateStyle();
						d.updateSize(allowedWidth, height);
						childs.insert(i, d2);
						count++;
					}
				}
				// create new line
				if( lineWidth > 0 && (isBlock || lineWidth + d.totalWidth > allowedWidth) ) {
					contentHeight += lineHeight;
					if( lineWidth > contentWidth )
						contentWidth = lineWidth;
					lineWidth = 0;
					lineHeight = 0;
					lineIndex++;
				}
				// add to current line
				lineWidth += d.totalWidth;
				d.lineIndex = lineIndex;
				if( d.totalHeight > lineHeight ) lineHeight = d.totalHeight;
			}
			if( lineWidth > contentWidth )
				contentWidth = lineWidth;
			contentHeight += lineHeight;
		}
		if( contentWidth < preferredWidth )
			contentWidth = preferredWidth;
		if( contentHeight < preferredHeight )
			contentHeight = preferredHeight;
		if( style.width != null )
			contentWidth = style.width;
		if( style.height != null )
			contentHeight = style.height;
		totalWidth = contentWidth + mlr + plr;
		totalHeight = contentHeight + mtb + ptb;
	}
	
	public function updatePos(x, y) {
		x += style.marginLeft;
		y += style.marginTop;
		posX = x;
		posY = y;
		if( childs != null ) {
			var lineWidth = 0, lineHeight = 0;
			var px0 = style.paddingLeft;
			var px = px0, py = style.paddingTop;
			for( d in childs ) {
				var isBlock = d.style.display == Block;
				if( isBlock || (lineWidth > 0 && lineWidth + d.totalWidth > contentWidth) ) {
					py += lineHeight;
					px = px0;
					lineWidth = 0;
					lineHeight = 0;
				}
				d.updatePos(px, py);
				px += d.totalWidth;
				lineWidth += d.totalWidth;
				if( d.totalHeight > lineHeight ) lineHeight = d.totalHeight;
				if( isBlock ) {
					py += lineHeight;
					px = px0;
					lineWidth = 0;
					lineHeight = 0;
				}
			}
		}
	}
	
}

class DomText extends Dom {
	
	public var text : String;
	var telt : Context.Text;
	var trim : Bool;
	
	public function new(b,t) {
		super(b, null);
		text = ~/[ \r\n\t]+/g.split(t).join(" ");
	}

	public function breakAt( width : Int ) {
		var index = telt.getCharIndex(width);
		trace("BREAK #" + text + "# at " + width + " = "+index);
		if( index < 0 ) throw "assert";
		var start = 0;
		while( true ) {
			var pos = text.indexOf(" ", start);
			if( pos == -1 || pos > index ) break;
			start = pos + 1;
		}
		if( start == 0 )
			return null;
		var tsub = text.substr(start);
		text = text.substr(0, start - 1);
		telt = null;
		return new DomText(browser, tsub);
	}
	
	override function updateSize(w, h) {
		// first update
		if( !trim ) {
			trim = true;
			if( parent == null || parent.childs.length == 1 ) {
				text = StringTools.trim(text);
				if( text == "" ) text = " ";
			} else {
				if( prev == null || prev.style.display == Block )
					text = StringTools.ltrim(text);
				if( next == null || next.style.display == Block )
					text = StringTools.rtrim(text);
			}
		}
		if( text != "" ) {
			telt = ctx.createText(text, style);
			preferredWidth = telt.width;
			preferredHeight = telt.height;
		}
		super.updateSize(w,h);
	}
	
	override function initElement() {
		if( telt != null ) ctx.addText(e, telt);
	}

	override function updatePos( x, y ) {
		posX = x;
		posY = y + totalHeight - preferredHeight;
	}

}

class DomLink extends Dom {
	
	public var href : String;
	
	override function setAttribute( a : String, v : String ) {
		switch( a ) {
		case "href":
			href = v;
		default:
			super.setAttribute(a, v);
		}
	}
		
	override function initElement() {
		var me = this;
		if( href != null ) e.setClick(function() me.browser.browse(me.href));
	}
	
}

class DomHidden extends Dom {
	
	var hrefLink : String;
	
	override function setAttribute( a, v ) {
		switch( name ) {
		case "link":
			switch( a ) {
			case "rel":
				return;
			case "type":
				return;
			case "href":
				hrefLink = v;
				return;
			}
		}
		super.setAttribute(a, v);
	}
	
	override function render() {
	}

	override function updateStyle() {
		super.updateStyle();
		if( hrefLink != null ) {
			var me = this;
			me.browser.notLoaded();
			ctx.loadText(hrefLink, function(data) {
				me.browser.css.addRules(data);
				me.browser.invalidate();
			});
			hrefLink = null;
		}
	}
	
	override function updateSize(w, h) {
	}

	override function updatePos(x,y) {
	}
	
}

class DomImage extends Dom {
	
	var src : String;
	var image : Context.Image;
	
	function onLoaded(i) {
		image = i;
		browser.invalidate();
	}
	
	override function updateSize(w,h) {
		if( image == null && src != null ) {
			image = ctx.loadImage(src, onLoaded);
			if( image == null ) {
				browser.notLoaded();
				return;
			}
		}
		preferredWidth = image.width;
		preferredHeight = image.height;
		super.updateSize(w,h);
	}
	
	override function initElement() {
		if( image != null )
			ctx.addImage(e, style.paddingLeft, style.paddingTop, image);
	}
	
	override function setAttribute( a : String, v : String ) {
		switch( a ) {
		case "src":
			src = v;
		default:
			super.setAttribute(a, v);
		}
	}
	
}