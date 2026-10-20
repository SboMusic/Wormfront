# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends RefCounted
## Tema condiviso: pannelli in ardesia, bordi ottone e accenti turchesi.
static func style(bg: Color, border: Color, width: int=2) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(9)
	box.set_content_margin_all(4)
	box.shadow_color = Color(0.015,0.025,0.04,0.45)
	box.shadow_size = 5
	box.shadow_offset = Vector2(0,3)
	return box
static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 17
	for type in ["Button","OptionButton","MenuButton"]:
		theme.set_stylebox("normal",type,style(Color("213645"),Color("67818b")))
		theme.set_stylebox("hover",type,style(Color("345665"),Color("e8bc73")))
		theme.set_stylebox("pressed",type,style(Color("163f47"),Color("66ded1")))
		theme.set_stylebox("focus",type,style(Color(0,0,0,0),Color("f5ce88")))
		theme.set_stylebox("disabled",type,style(Color("202a33"),Color("3b4b55")))
		theme.set_color("font_color",type,Color("f7e9cf"))
		theme.set_color("font_hover_color",type,Color.WHITE)
		theme.set_color("font_disabled_color",type,Color("84919a"))
	theme.set_stylebox("panel","Panel",style(Color("132632f0"),Color("947b56")))
	theme.set_stylebox("panel","PanelContainer",style(Color("132632f5"),Color("947b56")))
	theme.set_stylebox("panel","PopupMenu",style(Color("132632"),Color("d6ad6b")))
	theme.set_stylebox("normal","LineEdit",style(Color("0c1a27"),Color("4d6b79")))
	theme.set_stylebox("focus","LineEdit",style(Color("132f3b"),Color("70cfbf")))
	theme.set_color("font_color","Label",Color("f4ead8"))
	theme.set_color("font_shadow_color","Label",Color("081622"))
	theme.set_constant("shadow_offset_x","Label",1)
	theme.set_constant("shadow_offset_y","Label",2)
	return theme
static func apply_branch(node: Node, theme: Theme) -> void:
	if node is Control:
		node.theme = theme
	for child in node.get_children():
		apply_branch(child,theme)

