package kha.graphics2;

import kha.Color;
import kha.FastFloat;
import kha.Font;
import kha.graphics4.BlendingOperation;
import kha.Image;
import kha.math.FastMatrix3;
import kha.math.Matrix3;

class Graphics {
	public function begin(clear: Bool = true, clearColor: Color = null): Void { }
	public function end(): Void { }
	public function flush(): Void { }
	
	//scale-filtering
	//draw/fillPolygon
	
	public function clear(color: Color = null): Void { }
	public function drawImage(img: Image, x: FastFloat, y: FastFloat): Void {
		drawSubImage(img, x, y, 0, 0, img.width, img.height);
	}
	public function drawSubImage(img: Image, x: FastFloat, y: FastFloat, sx: FastFloat, sy: FastFloat, sw: FastFloat, sh: FastFloat): Void {
		drawScaledSubImage(img, sx, sy, sw, sh, x, y, sw, sh);
	}
	public function drawScaledImage(img: Image, dx: FastFloat, dy: FastFloat, dw: FastFloat, dh: FastFloat): Void {
		drawScaledSubImage(img, 0, 0, img.width, img.height, dx, dy, dw, dh);
	}
	public function drawScaledSubImage(image: Image, sx: FastFloat, sy: FastFloat, sw: FastFloat, sh: FastFloat, dx: FastFloat, dy: FastFloat, dw: FastFloat, dh: FastFloat): Void { }
	public function drawRect(x: Float, y: Float, width: Float, height: Float, strength: Float = 1.0): Void { }
	public function fillRect(x: Float, y: Float, width: Float, height: Float): Void { }
	public function drawString(text: String, x: Float, y: Float): Void { }
	public function drawLine(x1: Float, y1: Float, x2: Float, y2: Float, strength: Float = 1.0): Void { }
	public function drawVideo(video: Video, x: Float, y: Float, width: Float, height: Float): Void { }
	public function fillTriangle(x1: Float, y1: Float, x2: Float, y2: Float, x3: Float, y3: Float): Void { }
	
	/**
	The color value is used for geometric primitives as well as for images. Remember to set it back to white to draw images unaltered.
	*/
	public var color(get, set): Color;
	
	public var font(get, set): Font;
	
	public function get_color(): Color {
		return Color.Black;
	}
	
	public function set_color(color: Color): Color {
		return Color.Black;
	}
	
	public function get_font(): Font {
		return null;
	}
	
	public function set_font(font: Font): Font {
		return null;
	}
	
	public var transformation(get, set): FastMatrix3; // works on the top of the transformation stack
	
	public function pushTransformation(transformation: FastMatrix3): Void {
		setTransformation(transformation);
		transformations.push(transformation);
	}
	
	public function popTransformation(): FastMatrix3 {
		var ret = transformations.pop();
		setTransformation(get_transformation());
		return ret;
	}
	
	private inline function get_transformation(): FastMatrix3 {
		return transformations[transformations.length - 1];
	}
	
	private inline function set_transformation(transformation: FastMatrix3): FastMatrix3 {
		setTransformation(transformation);
		return transformations[transformations.length - 1] = transformation;
	}
	
	private inline function translation(tx: FastFloat, ty: FastFloat): FastMatrix3 {
		return FastMatrix3.translation(tx, ty).multmat(transformation);
	}
	
	public function translate(tx: FastFloat, ty: FastFloat): Void {
		transformation = translation(tx, ty);
	}
	
	public function pushTranslation(tx: FastFloat, ty: FastFloat): Void {
		pushTransformation(translation(tx, ty));
	}
	
	private inline function rotation(angle: FastFloat, centerx: FastFloat, centery: FastFloat): FastMatrix3 {
		return FastMatrix3.translation(centerx, centery).multmat(FastMatrix3.rotation(angle)).multmat(FastMatrix3.translation(-centerx, -centery)).multmat(transformation);
	}
	
	public function rotate(angle: FastFloat, centerx: FastFloat, centery: FastFloat): Void {
		transformation = rotation(angle, centerx, centery);
	}
	
	public function pushRotation(angle: FastFloat, centerx: FastFloat, centery: FastFloat): Void {
		pushTransformation(rotation(angle, centerx, centery));
	}
	
	public var opacity(get, set): Float; // works on the top of the opacity stack
	
	public function pushOpacity(opacity: Float): Void {
		setOpacity(opacity);
		opacities.push(opacity);
	}
	
	public function popOpacity(): Float {
		var ret = opacities.pop();
		setOpacity(get_opacity());
		return ret;
	}
	
	public function get_opacity(): Float {
		return opacities[opacities.length - 1];
	}
	
	public function set_opacity(opacity: Float): Float {
		setOpacity(opacity);
		return opacities[opacities.length - 1] = opacity;
	}
	
	public function setScissor(x: Int, y: Int, width: Int, height: Int): Void {
		
	}
	
	#if sys_g4
	private var prog: kha.graphics4.Program;
	
	public var program(get, set): kha.graphics4.Program;
	
	private function get_program(): kha.graphics4.Program {
		return prog;
	}
	
	private function set_program(program: kha.graphics4.Program): kha.graphics4.Program {
		setProgram(program);
		return prog = program;
	}
	#end
	
	public function setBlendingMode(source: BlendingOperation, destination: BlendingOperation): Void {
		
	}
	
	private var transformations: Array<FastMatrix3>;
	private var opacities: Array<Float>;
	
	public function new() {
		transformations = new Array<FastMatrix3>();
		transformations.push(FastMatrix3.identity());
		opacities = new Array<Float>();
		opacities.push(1);
		#if sys_g4
		prog = null;
		#end
	}
	
	private function setTransformation(transformation: FastMatrix3): Void {
		
	}
	
	private function setOpacity(opacity: Float): Void {
		
	}
	
	private function setProgram(program: kha.graphics4.Program): Void {
		
	}
}
