package hxtml;
import hxtml.Style;

enum Token {
	TIdent( i : String );
	TString( s : String );
	TInt( i : Int );
	TFloat( f : Float );
	TDblDot;
	TSharp;
	TPOpen;
	TPClose;
	TExclam;
	TComma;
	TEof;
	TPercent;
	TSemicolon;
	TBrOpen;
	TBrClose;
	TDot;
	TSpaces;
	TSlash;
}

enum Value {
	VIdent( i : String );
	VString( s : String );
	VUnit( v : Float, unit : String );
	VFloat( v : Float );
	VInt( v : Int );
	VHex( v : String );
	VList( l : Array<Value> );
	VGroup( l : Array<Value> );
	VUrl( v : String );
	VLabel( v : String, val : Value );
	VSlash;
}

class CssParser {

	var css : String;
	var s : Style;
	var simp : Style;
	var pos : Int;

	var spacesTokens : Bool;
	var tokens : Array<Token>;

	public function new() {
	}


	// ----------------- style apply ---------------------------

	#if debug
	function notImplemented( ?pos : haxe.PosInfos ) {
		haxe.Log.trace("Not implemented", pos);
	}
	#else
	inline function notImplemented() {
	}
	#end

	function applyStyle( r : String, v : Value, s : Style ) : Bool {
		switch( r ) {
		case "margin":
			var i = getGroup(v,getPix);
			if( i != null ) {
				switch( i.length ) {
				case 1:
					var i = i[0];
					s.margin(i, i, i, i);
					return true;
				case 2:
					s.margin(i[0], i[1], i[0], i[1]);
					return true;
				case 3:
					s.margin(i[0], i[1], i[2], i[1]);
					return true;
				case 4:
					s.margin(i[0], i[1], i[2], i[3]);
					return true;
				}
			}
		case "margin-left":
			var i = getPix(v);
			if( i != null ) { s.marginLeft = i; return true; }
		case "margin-right":
			var i = getPix(v);
			if( i != null ) { s.marginRight = i; return true; }
		case "margin-top":
			var i = getPix(v);
			if( i != null ) { s.marginTop = i; return true; }
		case "margin-bottom":
			var i = getPix(v);
			if( i != null ) { s.marginBottom = i; return true; }
		case "padding":
			var i = getGroup(v,getPix);
			if( i != null ) {
				switch( i.length ) {
				case 1:
					var i = i[0];
					s.padding(i, i, i, i);
					return true;
				case 2:
					s.padding(i[0], i[1], i[0], i[1]);
					return true;
				case 3:
					s.padding(i[0], i[1], i[2], i[1]);
					return true;
				case 4:
					s.padding(i[0], i[1], i[2], i[3]);
					return true;
				}
			}
		case "padding-left":
			var i = getPix(v);
			if( i != null ) { s.paddingLeft = i; return true; }
		case "padding-right":
			var i = getPix(v);
			if( i != null ) { s.paddingRight = i; return true; }
		case "padding-top":
			var i = getPix(v);
			if( i != null ) { s.paddingTop = i; return true; }
		case "padding-bottom":
			var i = getPix(v);
			if( i != null ) { s.paddingBottom = i; return true; }
		case "width":
			var i = getPix(v);
			if( i != null ) {
				s.width = i;
				return true;
			}
		case "height":
			var i = getPix(v);
			if( i != null ) {
				s.height = i;
				return true;
			}
		case "background-color":
			var c = getCol(v);
			if( c != null ) {
				s.bgColor = c;
				s.bgTransparent = false;
				return true;
			}
			if( getIdent(v) == "transparent" ) {
				s.bgTransparent = true;
				return true;
			}
		case "background-repeat":
			switch( getIdent(v) ) {
			case "repeat-x": s.bgRepeatX = true; s.bgRepeatY = false; return true;
			case "repeat-y": s.bgRepeatX = false; s.bgRepeatY = true; return true;
			case "repeat": s.bgRepeatX = true; s.bgRepeatY = true; return true;
			case "no-repeat": s.bgRepeatX = false; s.bgRepeatY = false; return true;
			}
		case "background-image":
			switch( v ) {
			case VUrl(url):
				s.bgImage = url;
				return true;
			case VIdent(i):
				if( i == "none" ) {
					s.bgImage = "";
					return true;
				}
			default:
			}
		case "background-attachment":
			switch( getIdent(v) ) {
			case "scroll": notImplemented(); return true;
			case "fixed": notImplemented(); return true;
			}
		case "background-position":
			if( applyComposite(["-inner-bgpos-left","-inner-bgpos-top"], v, s) ) {
				if( s.bgPosY == null )
					s.bgPosY = Percent(0.5);
				if( s.bgPosX == null )
					s.bgPosX = Percent(0.5);
				return true;
			}
		case "-inner-bgpos-top":
			var l = getUnit(v);
			if( l != null ) {
				s.bgPosY = l;
				return true;
			}
			switch( getIdent(v) ) {
			case "top": s.bgPosY = Percent(0); return true;
			case "center": s.bgPosY = Percent(.5); return true;
			case "bottom": s.bgPosY = Percent(1); return true;
			}
		case "-inner-bgpos-left":
			var l = getUnit(v);
			if( l != null ) {
				s.bgPosX = l;
				return true;
			}
			switch( getIdent(v) ) {
			case "left": s.bgPosX = Percent(0); return true;
			case "center": s.bgPosX = Percent(.5); return true;
			case "right": s.bgPosX = Percent(1); return true;
			}
		case "background":
			return applyComposite(["background-color", "background-image", "background-repeat", "background-attachment", "background-position"], v, s);
		case "font-family":
			var l = getList(v,getFontName);
			if( l != null ) {
				s.fontFamily = l;
				return true;
			}
		case "font-style":
			switch( getIdent(v) ) {
			case "normal": s.fontStyle = FSNormal; return true;
			case "italic": s.fontStyle = FSItalic; return true;
			case "oblique": s.fontStyle = FSOblique; return true;
			}
		case "font-variant":
			switch( getIdent(v) ) {
			case "normal": notImplemented(); return true;
			case "small-caps": notImplemented(); return true;
			}
		case "font-weight":
			switch( getIdent(v) ) {
			case "normal", "lighter": s.fontWeight = false; return true;
			case "bold", "bolder": s.fontWeight = true; return true;
			}
			switch(v) {
			case VInt(i):
				s.fontWeight = (i >= 700);
				return true;
			default:
			}
		case "font-size":
			var i = getUnit(v);
			if( i != null ) {
				switch( i ) {
				case Pix(v):
					s.fontSize = v;
				default:
					notImplemented();
				}
				return true;
			}
		case "font":
			var vl = switch( v ) {
			case VGroup(l): l;
			default: [v];
			};
			var v = VGroup(vl);
			applyComposite(["font-style", "font-variant", "font-weight"], v, s);
			applyComposite(["font-size"], v, s);
			if( vl.length > 0 )
				switch( vl[0] ) {
				case VSlash: vl.shift();
				default:
				}
			applyComposite(["line-height"], v, s);
			applyComposite(["font-family"], v, s);
			if( vl.length == 0 )
				return true;
		case "color":
			var c = getCol(v);
			if( c != null ) {
				s.textColor = c;
				return true;
			}
		case "text-decoration":
			var idents = getGroup(v, getIdent);
			for( i in idents )
				switch( i ) {
				case "none": s.textDecoration = TDNone;
				case "underline": s.textDecoration = TDUnderline;
				case "overline", "line-through", "blink": notImplemented();
				default: return false;
				}
			return true;
		case "text-transform":
			switch( getIdent(v) ) {
			case "none": s.textTransform = TFNone; return true;
			case "capitalize": s.textTransform = TFCapitalize; return true;
			case "uppercase": s.textTransform = TFUppercase; return true;
			case "lowercase": s.textTransform = TFLowercase; return true;
			}
		case "line-height":
			var i = getUnit(v);
			if( i != null ) {
				s.lineHeight = i;
				return true;
			}
		case "display":
			switch( getIdent(v) ) {
			case "none": s.display = None; return true;
			case "inline": s.display = Inline; return true;
			case "block": s.display = Block; return true;
			}
		default:
			throw "Not implemented '"+r+"' = "+Std.string(v);
		}
		return false;
	}

	function applyComposite( names : Array<String>, v : Value, s : Style ) {
		var vl = switch( v ) {
		case VGroup(l): l;
		default: [v];
		};
		while( vl.length > 0 ) {
			var found = false;
			for( n in names ) {
				var count = switch( n ) {
				case "background-position": 2;
				default: 1;
				}
				if( count > vl.length ) count = vl.length;
				while( count > 0 ) {
					var v = (count == 1) ? vl[0] : VGroup(vl.slice(0, count));
					if( applyStyle(n, v, s) ) {
						found = true;
						names.remove(n);
						for( i in 0...count )
							vl.shift();
						break;
					}
					count--;
				}
				if( found ) break;
			}
			if( !found )
				return false;
		}
		return true;
	}

	function getGroup<T>( v : Value, f : Value -> Null<T> ) : Null<Array<T>> {
		switch(v) {
		case VGroup(l):
			var a = [];
			for( v in l ) {
				var v = f(v);
				if( v == null ) return null;
				a.push(v);
			}
			return a;
		default:
			var v = f(v);
			return (v == null) ? null : [v];
		}
	}

	function getList<T>( v : Value, f : Value -> Null<T> ) : Null<Array<T>> {
		switch(v) {
		case VList(l):
			var a = [];
			for( v in l ) {
				var v = f(v);
				if( v == null ) return null;
				a.push(v);
			}
			return a;
		default:
			var v = f(v);
			return (v == null) ? null : [v];
		}
	}

	function getPix( v : Value ) : Null<Int> {
		return switch( v ) {
		case VUnit(f, u):
			switch( u ) {
			case "px": Std.int(f);
			case "pt": Std.int(f * 4 / 3);
			default: null;
			}
		case VInt(v):
			v;
		default:
			null;
		};
	}

	function getUnit( v : Value ) : Null<Unit> {
		return switch( v ) {
		case VUnit(f, u):
			switch( u ) {
			case "px": Pix(Std.int(f));
			case "pt": Pix(Std.int(f * 4 / 3));
			case "em": EM(f);
			case "%": Percent(f / 100);
			default: null;
			}
		case VInt(v):
			Pix(v);
		default:
			null;
		};
	}

	function getIdent( v : Value ) : Null<String> {
		return switch( v ) {
		case VIdent(v): v;
		default: null;
		};
	}

	function getCol( v : Value ) : Null<Int> {
		return switch( v ) {
		case VHex(v):
			(v.length == 6) ? Std.parseInt("0x" + v) : ((v.length == 3) ? Std.parseInt("0x"+v.charAt(0)+v.charAt(0)+v.charAt(1)+v.charAt(1)+v.charAt(2)+v.charAt(2)) : null);
		case VIdent(i):
			switch( i ) {
			case "black":	0x000000;
			case "red": 	0xFF0000;
			case "lime":	0x00FF00;
			case "blue":	0x0000FF;
			case "white":	0xFFFFFF;
			case "aqua":	0x00FFFF;
			case "fuchsia":	0xFF00FF;
			case "yellow":	0xFFFF00;
			case "maroon":	0x800000;
			case "green":	0x008000;
			case "navy":	0x000080;
			case "olive":	0x808000;
			case "purple": 	0x800080;
			case "teal":	0x008080;
			case "silver":	0xC0C0C0;
			case "gray", "grey": 0x808080;
			default: null;
			}
		default:
			null;
		};
	}

	function getFontName( v : Value ) {
		return switch( v ) {
		case VString(s): s;
		case VGroup(_):
			var g = getGroup(v, getIdent);
			if( g == null ) null else g.join(" ");
		case VIdent(i): i;
		default: null;
		};
	}

	// ---------------------- generic parsing --------------------

	function unexpected( t : Token ) : Dynamic {
		throw "Unexpected " + Std.string(t);
		return null;
	}

	function expect( t : Token ) {
		var tk = readToken();
		if( tk != t ) unexpected(tk);
	}

	inline function push( t : Token ) {
		tokens.push(t);
	}

	function isToken(t) {
		var tk = readToken();
		if( tk == t ) return true;
		push(tk);
		return false;
	}

	public function parse( css : String, s : Style ) {
		this.css = css;
		this.s = s;
		pos = 0;
		tokens = [];
		parseStyle(TEof);
	}

	function parseStyle( eof ) {
		while( true ) {
			if( isToken(eof) )
				break;
			var r = readIdent();
			expect(TDblDot);
			var v = readValue();
			var s = this.s;
			switch( v ) {
			case VLabel(label, val):
				if( label == "important" ) {
					v = val;
					if( simp == null ) simp = new Style();
					s = simp;
				}
			default:
			}
			if( !applyStyle(r, v, s) )
				throw "Invalid value " + Std.string(v) + " for css " + r;
			if( isToken(eof) )
				break;
			expect(TSemicolon);
		}
	}

	public function parseRules( css : String ) {
		this.css = css;
		pos = 0;
		tokens = [];
		var rules = [];
		while( true ) {
			if( isToken(TEof) )
				break;
			var classes = [];
			while( true ) {
				spacesTokens = true;
				isToken(TSpaces); // skip
				var c = readClass(null);
				spacesTokens = false;
				if( c == null ) break;
				classes.push(c);
				if( !isToken(TComma) )
					break;
			}
			if( classes.length == 0 )
				unexpected(readToken());
			expect(TBrOpen);
			this.s = new Style();
			this.simp = null;
			parseStyle(TBrClose);
			for( c in classes )
				rules.push( { c : c, s : s, imp : false } );
			if( this.simp != null )
				for( c in classes )
					rules.push( { c : c, s : simp, imp : true } );
		}
		return rules;
	}

	// ----------------- class parser ---------------------------

	function readClass( parent ) : CssClass {
		var c : CssClass = {
			parent : parent,
			node : null,
			id : null,
			className : null,
			pseudoClass : null,
		};
		var def = false;
		var last = null;
		while( true ) {
			var t = readToken();
			if( last == null )
				switch( t ) {
				case TDot, TSharp, TDblDot: last = t;
				case TIdent(i): c.node = i; def = true;
				case TSpaces:
					return def ? readClass(c) : null;
				case TBrOpen, TComma:
					push(t);
					break;
				default:
					unexpected(t);
				}
			else
				switch( t ) {
				case TIdent(i):
					switch( last ) {
					case TDot: c.className = i; def = true;
					case TSharp: c.id = i; def = true;
					case TDblDot: c.pseudoClass = i; def = true;
					default: throw "assert";
					}
					last = null;
				default:
					unexpected(t);
				}
		}
		return def ? c : parent;
	}

	// ----------------- value parser ---------------------------

	function readIdent() {
		var t = readToken();
		return switch( t ) {
		case TIdent(i): i;
		default: unexpected(t);
		}
	}

	function readValue(?opt)  : Value {
		var t = readToken();
		var v = switch( t ) {
		case TSharp:
			VHex(readHex());
		case TIdent(i):
			VIdent(i);
		case TString(s):
			VString(s);
		case TInt(i):
			readValueUnit(i, i);
		case TFloat(f):
			readValueUnit(f, null);
		case TSlash:
			VSlash;
		default:
			if( !opt ) unexpected(t);
			push(t);
			null;
		};
		if( v != null ) v = readValueNext(v);
		return v;
	}

	function readHex() {
		var start = pos;
		while( true ) {
			var c = next();
			if( (c >= "A".code && c <= "F".code) || (c >= "a".code && c <= "f".code) || (c >= "0".code && c <= "9".code) )
				continue;
			pos--;
			break;
		}
		return css.substr(start, pos - start);
	}

	function readValueUnit( f : Float, ?i : Int ) {
		var t = readToken();
		return switch( t ) {
		case TIdent(i):
			VUnit(f, i);
		case TPercent:
			VUnit(f, "%");
		default:
			push(t);
			if( i != null )
				VInt(i);
			else
				VFloat(f);
		};
	}

	function readValueNext( v : Value ) : Value {
		var t = readToken();
		return switch( t ) {
		case TPOpen:
			switch( v ) {
			case VIdent(i):
				switch( i ) {
				case "url":
					readValueNext(VUrl(readUrl()));
				default:
					push(t);
					v;
				}
			default:
				push(t);
				v;
			}
		case TExclam:
			var t = readToken();
			switch( t ) {
			case TIdent(i):
				VLabel(i, v);
			default:
				unexpected(t);
			}
		case TComma:
			loopComma(v, readValue());
		default:
			push(t);
			var v2 = readValue(true);
			if( v2 == null )
				v;
			else
				loopNext(v, v2);
		}
	}

	function loopNext(v, v2) {
		return switch( v2 ) {
		case VGroup(l):
			l.unshift(v);
			v2;
		case VList(l):
			l[0] = loopNext(v, l[0]);
			v2;
		case VLabel(lab, v2):
			VLabel(lab, loopNext(v, v2));
		default:
			VGroup([v, v2]);
		};
	}

	function loopComma(v,v2) {
		return switch( v2 ) {
		case VList(l):
			l.unshift(v);
			v2;
		case VLabel(lab, v2):
			VLabel(lab, loopComma(v, v2));
		default:
			VList([v, v2]);
		};
	}

	// ----------------- lexer -----------------------

	inline function isSpace(c) {
		return (c == " ".code || c == "\n".code || c == "\r".code || c == "\t".code);
	}

	inline function isIdentChar(c) {
		return (c >= "a".code && c <= "z".code) || (c >= "A".code && c <= "Z".code) || (c == "-".code);
	}

	inline function isNum(c) {
		return c >= "0".code && c <= "9".code;
	}

	inline function next() {
		return StringTools.fastCodeAt(css, pos++);
	}

	function readUrl() {
		var c0 = next();
		while( isSpace(c0) )
			c0 = next();
		var quote = c0;
		if( quote == "'".code || quote == '"'.code ) {
			pos--;
			switch( readToken() ) {
			case TString(s):
				var c0 = next();
				while( isSpace(c0) )
					c0 = next();
				if( c0 != ")".code )
					throw "Invalid char " + String.fromCharCode(c0);
				return s;
			default: throw "assert";
			}

		}
		var start = pos - 1;
		while( true ) {
			if( StringTools.isEOF(c0) )
				break;
			c0 = next();
			if( c0 == ")".code ) break;
		}
		return StringTools.trim(css.substr(start, pos - start - 1));
	}

	#if false
	function readToken( ?pos : haxe.PosInfos ) {
		var t = _readToken();
		haxe.Log.trace(t, pos);
		return t;
	}

	function _readToken() {
	#else
	function readToken() {
	#end
		var t = tokens.pop();
		if( t != null )
			return t;
		while( true ) {
			var c = next();
			if( StringTools.isEOF(c) )
				return TEof;
			if( isSpace(c) ) {
				if( spacesTokens ) {
					while( isSpace(next()) ) {
					}
					pos--;
					return TSpaces;
				}

				continue;
			}
			if( isIdentChar(c) ) {
				var pos = pos - 1;
				do c = next() while( isIdentChar(c) );
				this.pos--;
				return TIdent(css.substr(pos,this.pos - pos).toLowerCase());
			}
			if( isNum(c) ) {
				var i = 0;
				do {
					i = i * 10 + (c - "0".code);
					c = next();
				} while( isNum(c) );
				if( c == ".".code ) {
					var f : Float = i;
					var k = 0.1;
					while( isNum(c = next()) ) {
						f += (c - "0".code) * k;
						k *= 0.1;
					}
					pos--;
					return TFloat(f);
				}
				pos--;
				return TInt(i);
			}
			switch( c ) {
			case ":".code: return TDblDot;
			case "#".code: return TSharp;
			case "(".code: return TPOpen;
			case ")".code: return TPClose;
			case "!".code: return TExclam;
			case "%".code: return TPercent;
			case ";".code: return TSemicolon;
			case ".".code: return TDot;
			case "{".code: return TBrOpen;
			case "}".code: return TBrClose;
			case ",".code: return TComma;
			case "/".code:
				if( (c = next()) != '*'.code ) {
					pos--;
					return TSlash;
				}
				while( true ) {
					while( (c = next()) != '*'.code ) {
						if( StringTools.isEOF(c) )
							throw "Unclosed comment";
					}
					c = next();
					if( c == "/".code ) break;
					if( StringTools.isEOF(c) )
						throw "Unclosed comment";
				}
				return readToken();
			case "'".code, '"'.code:
				var pos = pos;
				var k;
				while( (k = next()) != c ) {
					if( StringTools.isEOF(k) )
						throw "Unclosed string constant";
					if( k == "\\".code ) {
						throw "todo";
						continue;
					}
				}
				return TString(css.substr(pos, this.pos - pos - 1));
			default:
			}
			pos--;
			throw "Invalid char " + css.charAt(pos);
		}
		return null;
	}

}