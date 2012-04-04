package com.ktxsoftware.kha.backends.flash;

import com.ktxsoftware.flash.utils.AGALMiniAssembler;
import com.ktxsoftware.kha.Color;
import flash.display.BitmapData;
import flash.display.Graphics;
import flash.display.Stage3D;
import flash.display3D.Context3D;
import flash.display3D.Context3DBlendFactor;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.IndexBuffer3D;
import flash.display3D.Program3D;
import flash.display3D.textures.Texture;
import flash.display3D.VertexBuffer3D;
import flash.geom.Matrix;
import flash.geom.Matrix3D;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.Vector;

class Painter extends com.ktxsoftware.kha.Painter {
	var tx : Float;
	var ty : Float;
	var color : Color;
	var context : Context3D;
	var vertexBuffer : VertexBuffer3D;
	var vertices : Vector<Float>;
	var indexBuffer : IndexBuffer3D;
	var projection : Matrix3D;
	var font : Font;
	var textField : TextField;
	var textBitmap : BitmapData;
	var textTexture : Texture;
	
	public function new(context : Context3D, width : Int, height : Int) {
		this.context = context;
		tx = 0;
		ty = 0;
		
		textField = new TextField();
		textField.width = 1024;
		textField.height = 1024;
		textBitmap = new BitmapData(1024, 1024, true, 0xffffff);
		textTexture = Starter.context.createTexture(1024, 1024, Context3DTextureFormat.BGRA, false);
		
		projection = new Matrix3D();
		var right : Float = width;
		var left : Float = 0;
		var top : Float = 0;
		var bottom : Float = height;
		var zNear : Float = 0.1;
		var zFar : Float = 512;
		
		var tx : Float = -(right + left) / (right - left);
		var ty : Float = -(top + bottom) / (top - bottom);
		var tz : Float = -zNear / (zFar - zNear);
			
		var vec : Vector<Float> = new Vector<Float>(16);
		
		vec[ 0] = 2.0 / (right - left); vec[ 1] = 0.0;                  vec[ 2] = 0.0;                  vec[ 3] = 0.0;
		vec[ 4] = 0.0;                  vec[ 5] = 2.0 / (top - bottom); vec[ 6] = 0.0;                  vec[ 7] = 0.0;
		vec[ 8] = 0.0;                  vec[ 9] = 0.0;                  vec[10] = 1.0 / (zFar - zNear); vec[11] = 0.0;
		vec[12] = tx;                   vec[13] = ty;                   vec[14] = tz;                   vec[15] = 1.0;
		
		projection.copyRawDataFrom(vec);
		#if debug
		context.enableErrorChecking = true;
		#end
		context.configureBackBuffer(width, height, 0, false);
		context.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);

		var vertexShader : Array<String> = [
			// Transform our vertices by our projection matrix and move it into temporary register
			"m44 vt0, va0, vc0",
			// Move the temporary register to out position for this vertex
			"mov op, vt0",
			"mov v0, va1"
		];
		
		var fragmentShader : Array<String> = [
			// Simply assing the fragment constant to our out color
			//"mov oc, fc0"
			"tex ft1, v0, fs0 <2d,linear,nomip>",
			"mov oc, ft1"
		];

		var program : Program3D = context.createProgram();
		var vertexAssembler : AGALMiniAssembler = new AGALMiniAssembler();
		vertexAssembler.assemble(Context3DProgramType.VERTEX, vertexShader.join("\n"));
		var fragmentAssembler : AGALMiniAssembler = new AGALMiniAssembler();
		fragmentAssembler.assemble(Context3DProgramType.FRAGMENT, fragmentShader.join("\n"));
		program.upload(vertexAssembler.agalcode(), fragmentAssembler.agalcode());
		context.setProgram(program);
   
		indexBuffer = context.createIndexBuffer(6 * maxCount);
		var indices = new Vector<UInt>(6 * maxCount);
		for (i in 0...maxCount) {
			indices[6 * i + 0] = i * 4 + 0;
			indices[6 * i + 1] = i * 4 + 1;
			indices[6 * i + 2] = i * 4 + 2;
			indices[6 * i + 3] = i * 4 + 1;
			indices[6 * i + 4] = i * 4 + 2;
			indices[6 * i + 5] = i * 4 + 3;
		}
		indexBuffer.uploadFromVector(indices, 0, 6 * maxCount);
		
		vertexBuffer = context.createVertexBuffer(4 * maxCount, 5);
		vertices = new Vector<Float>(20 * maxCount);
		vertexBuffer.uploadFromVector(vertices, 0, 4 * maxCount);
		
		context.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
		context.setVertexBufferAt(1, vertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_2);
		
		context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, projection, true);
	}
	
	public override function begin() {
		context.clear(0, 0, 0, 0);
	}
	
	public override function end() {
		if (image != null && count > 0) flushBuffers();
		context.present();
	}
	
	public override function translate(x : Float, y : Float) {
		tx = x;
		ty = y;
	}
	
	var image : Image;
	var count : Int;
	static var maxCount : Int = 500;
	
	function flushBuffers() : Void {
		context.setTextureAt(0, image.getTexture());
		vertexBuffer.uploadFromVector(vertices, 0, 4 * count);
		context.drawTriangles(indexBuffer, 0, 2 * count);
		count = 0;
	}
	
	override public function drawImage(img : com.ktxsoftware.kha.Image, x : Float, y : Float) : Void {
		drawImage2(img, 0, 0, img.getWidth(), img.getHeight(), x, y, img.getWidth(), img.getHeight());
	}
	
	override public function drawImage2(img : com.ktxsoftware.kha.Image, sx : Float, sy : Float, sw : Float, sh : Float, dx : Float, dy : Float, dw : Float, dh : Float) : Void {
		if (image != img || count >= maxCount) {
			if (image != null) flushBuffers();
			image = cast(img, Image);
			image.getTexture();
			context.setTextureAt(0, image.getTexture());
		}

		var u1 = image.correctU(sx / image.getWidth());
		var u2 = image.correctU((sx + sw) / image.getWidth());
		var v1 = image.correctV(sy / image.getHeight());
		var v2 = image.correctV((sy + sh) / image.getHeight());
		var offset = count * 20;
		vertices[offset +  0] = tx + dx;      vertices[offset +  1] = ty + dy;      vertices[offset +  2] = 1; vertices[offset +  3] = u1; vertices[offset +  4] = v1;
		vertices[offset +  5] = tx + dx + dw; vertices[offset +  6] = ty + dy;      vertices[offset +  7] = 1; vertices[offset +  8] = u2; vertices[offset +  9] = v1;
		vertices[offset + 10] = tx + dx;      vertices[offset + 11] = ty + dy + dh; vertices[offset + 12] = 1; vertices[offset + 13] = u1; vertices[offset + 14] = v2;
		vertices[offset + 15] = tx + dx + dw; vertices[offset + 16] = ty + dy + dh; vertices[offset + 17] = 1; vertices[offset + 18] = u2; vertices[offset + 19] = v2;
		//vertexBuffer.uploadFromVector(vertices, 0, 4);

		//context.drawTriangles(indexBuffer, 0, 2);
		++count;
	}
	
	override public function drawString(text : String, x : Float, y : Float) : Void {
		return;
		textField.defaultTextFormat = new TextFormat(font.name, font.size);
		textField.text = text;
		textBitmap.fillRect(new Rectangle(0, 0, 1024, 1024), 0xffffff);
		textBitmap.draw(textField);
		textTexture.uploadFromBitmapData(textBitmap, 0);
		
		flushBuffers();
		
		var dx = x;
		var dy = y - font.size;
		var dw = 1024;
		var dh = 1024;
		var u1 = 0.0;
		var u2 = 1.0;
		var v1 = 0.0;
		var v2 = 1.0;
		var offset = 0;
		
		vertices[offset +  0] = tx + dx;      vertices[offset +  1] = ty + dy;      vertices[offset +  2] = 1; vertices[offset +  3] = u1; vertices[offset +  4] = v1;
		vertices[offset +  5] = tx + dx + dw; vertices[offset +  6] = ty + dy;      vertices[offset +  7] = 1; vertices[offset +  8] = u2; vertices[offset +  9] = v1;
		vertices[offset + 10] = tx + dx;      vertices[offset + 11] = ty + dy + dh; vertices[offset + 12] = 1; vertices[offset + 13] = u1; vertices[offset + 14] = v2;
		vertices[offset + 15] = tx + dx + dw; vertices[offset + 16] = ty + dy + dh; vertices[offset + 17] = 1; vertices[offset + 18] = u2; vertices[offset + 19] = v2;
		
		context.setTextureAt(0, textTexture);
		vertexBuffer.uploadFromVector(vertices, 0, 4 * 1);
		context.drawTriangles(indexBuffer, 0, 2 * 1);
	}
	
	public override function setColor(r : Int, g : Int, b : Int) {
		color = new Color(r, g, b);
	}
	
	public override function fillRect(x : Float, y : Float, width : Float, height : Float) {
		
	}
	
	override public function setFont(font : com.ktxsoftware.kha.Font) : Void {
		this.font = cast(font, Font);
	}
}