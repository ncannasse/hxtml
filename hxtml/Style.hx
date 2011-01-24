package hxtml;

enum DisplayStyle {
	Inline;
	Block;
	None;
}

enum BgRepeatMode {
	BRM_xy;
	BRM_x;
	BRM_y;
	BRM_no;
}

typedef CssClass = {
	var parent : Null<CssClass>;
	var node : Null<String>;
	var className : Null<String>;
	var pseudoClass : Null<String>;
	var id : Null<String>;
}

class Style {
	
	public var marginLeft : Null<Int>;
	public var marginTop : Null<Int>;
	public var marginRight : Null<Int>;
	public var marginBottom : Null<Int>;

	public var paddingLeft : Null<Int>;
	public var paddingTop : Null<Int>;
	public var paddingRight : Null<Int>;
	public var paddingBottom : Null<Int>;
	
	public var font : Context.Font; // family + style
	public var fontSize : Null<Float>;
	public var textColor : Null<Int>;
	public var underline : Null<Bool>;
	public var lineHeight : Null<Int>;
	
	public var bgColor : Null<Int>;
	public var bgTransparent : Null<Bool>;
	public var bgImage : Null<String>;
	public var bgRepeatX : Null<Bool>;
	public var bgRepeatY : Null<Bool>;
	
	public var width : Null<Int>;
	public var height : Null<Int>;
	
	public var display : Null<DisplayStyle>;

	public function new() {
	}
	
	public function margin( top, right, bottom, left ) {
		marginTop = top;
		marginRight = right;
		marginBottom = bottom;
		marginLeft = left;
	}

	public function padding( top, right, bottom, left ) {
		paddingTop = top;
		paddingRight = right;
		paddingBottom = bottom;
		paddingLeft = left;
	}
	
	public function inherit( s : Style ) {
		if( font == null )
			font = s.font;
		if( fontSize == null )
			fontSize = s.fontSize;
		if( textColor == null )
			textColor = s.textColor;
		if( underline == null )
			underline = s.underline;
		if( lineHeight == null )
			lineHeight = s.lineHeight;
	}
	
	public function apply( s : Style ) {
		Macros.copyVars(this, s);
	}
	
}