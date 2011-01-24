package hxtml;
import hxtml.Style;

enum Token {
	TIdent( i : String );
	TString( s : String );
	TInt( i : Int );
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
	
	function applyStyle( r : String, v : Value, s : Style ) : Bool {
		switch( r ) {
		case "margin":
			var i = getPix(v);
			if( i != null ) {
				s.margin(i, i, i, i);
				return true;
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
			var i = getPix(v);
			if( i != null ) {
				s.padding(i, i, i, i);
				return true;
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
				return true;
			}
			if( getIdent(v) == "transparent" ) {
				s.bgTransparent = true;
				return true;
			}
		case "background-repeat":
			s.bgRepeatX = false;
			s.bgRepeatY = false;
			var error = false;
			var vl = getIdents(v);
			if( vl != null )
				for( i in vl )
					switch( i ) {
					case "repeat-x": s.bgRepeatX = true;
					case "repeat-y": s.bgRepeatY = true;
					case "repeat": s.bgRepeatX = true; s.bgRepeatY = true;
					case "no-repeat": s.bgRepeatX = false; s.bgRepeatY = false;
					default: error = true; break;
					}
			if( !error )
				return true;
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
		case "font-size":
			var i = getPix(v);
			if( i != null ) {
				s.fontSize = i;
				return true;
			}
		case "line-height":
			var i = getPix(v);
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
	
	function getPix( v : Value ) : Null<Int> {
		return switch( v ) {
		case VUnit(f, u):
			(u == "px") ? Std.int(f) : null;
		case VInt(v):
			(v == 0) ? 0 : null;
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
	
	function getIdents( v : Value ) : Null<Array<String>> {
		return switch( v ) {
		case VIdent(v): [v];
		case VList(av):
			var a  = [];
			for( v in av ) {
				var i = getIdent(v);
				if( i == null ) return null;
				a.push(i);
			}
			a;
		default: null;
		};
	}
	
	function getCol( v : Value ) : Null<Int> {
		return switch( v ) {
		case VHex(v):
			(v.length == 6) ? Std.parseInt("0x" + v) : null;
		case VIdent(i):
			switch( i ) {
			case "red": 0xFF0000;
			case "green": 0x00FF00;
			case "blue": 0x0000FF;
			default: null;
			}
		default:
			null;
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
		return switch( t ) {
		case TSharp:
			readValueNext(VHex(readHex()));
		case TIdent(i):
			readValueNext(VIdent(i));
		case TString(s):
			readValueNext(VString(s));
		case TInt(i):
			readValueUnit(i, i);
		default:
			if( !opt ) unexpected(t);
			push(t);
			null;
		};
	}
	
	function readHex() {
		throw "TODO";
		return null;
	}
	
	function readValueUnit( f : Float, ?i : Int ) {
		var t = readToken();
		return readValueNext(switch( t ) {
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
		});
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
			var v2 = readValue();
			throw "TODO";
		default:
			push(t);
			var v2 = readValue(true);
			if( v2 == null )
				v;
			else {
				trace(v2);
				throw "TODO";
			}
		}
	}
	
	/*
	match s {
	| [< v2 = value s >] ->
		function rec loop(v2) {
			var p = punion (pos v) (pos v2);
			match fst v2 {
			| VGroup l -> (VGroup (v :: l), p)
			| VList (v2 :: l) -> (VList (loop v2 :: l), p)
			| VLabel (l,v2) -> (VLabel l (loop v2), p)
			| _ -> (VGroup [v;v2], p)
			}
		}
		loop v2
	| [< (Comma,_); v2 = value s >] ->
		function rec loop(v2) {
			var p = punion (pos v) (pos v2);
			match fst v2 {
			| VList l -> (VList (v :: l), p)
			| VLabel (l,v2) -> (VLabel l (loop v2), p)
			| _ -> (VList [v;v2], p)
			}
		}
		loop v2
	}
	*/
	
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
				if( (c = next()) != '*'.code )
					pos--;
				else {
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
				}
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
			throw "Invalid char " + String.fromCharCode(c);
		}
		return null;
	}
	
}