# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends RefCounted
const W := 2200
const H := 1100
static func ellipse(image: Image, c: Vector2, r: Vector2, fill: bool) -> void:
	for x in range(maxi(0,int(c.x-r.x)),mini(W,int(c.x+r.x)+1)):
		var fraction := 1.0-pow((x-c.x)/r.x,2)
		if fraction <= 0:
			continue
		var dy := sqrt(fraction)*r.y
		var top := clampi(int(c.y-dy),80,1020)
		var bottom := clampi(int(c.y+dy),80,1020)
		if bottom > top:
			image.fill_rect(Rect2i(x,top,1,bottom-top),Color.WHITE if fill else Color.TRANSPARENT)
static func ledge(image: Image, x: int, y: float, width: int, depth: int, phase: float) -> void:
	for px in range(maxi(0,x),mini(W,x+width)):
		var t := float(px-x)/width
		var roof := y+sin(t*TAU+phase)*15+sin(t*PI*5)*5
		var bottom := roof+depth*(.55+.45*sin(t*PI))
		image.fill_rect(Rect2i(px,clampi(int(roof),80,1010),1,maxi(1,int(bottom-roof))),Color.WHITE)
static func create(family: int, rng: RandomNumberGenerator) -> Image:
	var image := Image.create_empty(W,H,false,Image.FORMAT_RGBA8)
	var phase := rng.randf_range(0,TAU)
	match family:
		0,3:
			# Cittadelle: torri alte, stanze, finestre, merli e ponti interrotti.
			for tower in range(7):
				var x := tower*325+rng.randi_range(-40,35)
				var width := rng.randi_range(215,280)
				var top := rng.randi_range(110,300) if tower%2 == 0 else rng.randi_range(300,460)
				var bottom := rng.randi_range(870,1010)
				image.fill_rect(Rect2i(x,top,width,bottom-top),Color.WHITE)
				for y in range(top+65,bottom-45,135):
					image.fill_rect(Rect2i(x+30,y,width-60,78),Color.TRANSPARENT)
					if rng.randf() < .65:
						image.fill_rect(Rect2i(x-2,y+20,38,50),Color.TRANSPARENT)
				for px in range(x,x+width,42):
					image.fill_rect(Rect2i(px,top-25,24,25),Color.WHITE)
				if tower<6:
					ledge(image,x+width-15,top+150,rng.randi_range(80,140),26,phase)
				# Scalinata esterna percorribile su parte della facciata.
				for stair in range(7):
					image.fill_rect(Rect2i(x+width-8+stair*9,top+300+stair*5,15,12),Color.WHITE)
		1:
			# Massiccio scavato: camere collegate, volte e accessi laterali.
			for x in range(W):
				var top := int(140+sin(x*.005+phase)*45+sin(x*.019)*18)
				image.fill_rect(Rect2i(x,top,1,1020-top),Color.WHITE)
			for row in range(4):
				for cave in range(5):
					var center := Vector2(cave*470+rng.randi_range(100,200),270+row*190+rng.randi_range(-20,20))
					ellipse(image,center,Vector2(rng.randf_range(170,240),rng.randf_range(60,85)),false)
				for x in range(W):
					var y := int(270+row*190+sin(x*.006+phase)*28)
					image.fill_rect(Rect2i(x,y,1,48),Color.TRANSPARENT)
			for shaft in range(4):
				var x := rng.randi_range(60,W-110)
				image.fill_rect(Rect2i(x,100,56,850),Color.TRANSPARENT)
		2,5:
			# Falesie irregolari e pilastri, con balconi e tunnel trasversali.
			for col in range(8):
				var x := col*295+rng.randi_range(-50,30)
				var width := rng.randi_range(160,255)
				var top := rng.randi_range(110,490)
				for px in range(maxi(0,x),mini(W,x+width)):
					var roof := int(top+sin(px*.017+phase)*27)
					image.fill_rect(Rect2i(px,roof,1,1020-roof),Color.WHITE)
				for level in range(3):
					var y := top+130+level*170
					if y<970:
						ellipse(image,Vector2(x+width*.5,y),Vector2(width*.38,54),false)
				ledge(image,x-80,top+90,width+110,38,phase+col)
			for high in range(4):
				ledge(image,high*550+100,rng.randi_range(100,210),260,55,phase)
		4:
			# Grandi archi con pilastri spessi, piu terrazze su livelli sfalsati.
			for arch in range(5):
				var cx := arch*470+170+rng.randi_range(-35,35)
				var cy := rng.randi_range(620,790)
				ellipse(image,Vector2(cx,cy),Vector2(270,480),true)
				ellipse(image,Vector2(cx,cy+100),Vector2(175,355),false)
			for shelf in range(7):
				ledge(image,shelf*340+rng.randi_range(-90,20),rng.randi_range(110,350),rng.randi_range(180,280),50,phase)
	image.fill_rect(Rect2i(0,0,W,80),Color.TRANSPARENT)
	image.fill_rect(Rect2i(0,1020,W,80),Color.TRANSPARENT)
	# Passaggi ai bordi per le eliminazioni laterali, senza pareti invisibili.
	image.fill_rect(Rect2i(0,80,20,940),Color.TRANSPARENT)
	image.fill_rect(Rect2i(W-20,80,20,940),Color.TRANSPARENT)
	return image
