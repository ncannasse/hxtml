package hxtml;
import hxtml.Style;

class CssEngine {
	
	var browser : Browser;
	var rules : Array<{ c : CssClass, s : Style }>;
	
	public function new(b) {
		browser = b;
		rules = [];
	}

	function applyDefaultStyle( s : Style, node : String ) {
		s.display = Inline;
		switch( node ) {
		case "body":
			s.margin(8, 8, 8, 8);
			s.font = browser.ctx.getNativeFont("Times New Roman", { bold : false, italic : false });
			s.fontSize = 16;
		case "html":
			s.bgColor = 0xFFFFFF;
			s.width = browser.ctx.pageWidth;
		case "a":
			s.underline = true;
			s.textColor = 0x0000CC;
		case "div":
			s.display = Block;
		case "br":
			s.display = Block;
		}
		return s;
	}
	
	function randColor() {
		while( true ) {
			var r = Std.random(256);
			var g = Std.random(256);
			var b = Std.random(256);
			if( r + g + b < 256 ) continue;
			return (r << 16) | (g << 8) | b;
		}
		return 0;
	}
	
	public function applyClasses( d : Dom ) {
		var s = new Style();
		applyDefaultStyle(s, d.name);
		d.style = s;
		for( r in rules ) {
			if( !ruleMatch(r.c, d) )
				continue;
			s.apply(r.s);
		}
		if( d.defStyle != null )
			s.apply(d.defStyle);
	}
	
	function ruleMatch( c : CssClass, d : Dom ) {
		if( c.className != null ) {
			if( d.classes == null )
				return false;
			var found = false;
			for( cc in d.classes )
				if( cc == c.className ) {
					found = true;
					break;
				}
			if( !found )
				return false;
		}
		if( c.node != null && c.node != d.name )
			return false;
		if( c.id != null && c.id != d.id )
			return false;
		if( c.parent != null && (d.parent == null || !ruleMatch(c.parent, d.parent)) )
			return false;
		return true;
	}
	
	public function addRules( text : String ) {
		var rules = new CssParser().parseRules(text);
		this.rules = this.rules.concat(rules);
	}
	
}
