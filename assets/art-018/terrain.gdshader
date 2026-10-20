shader_type canvas_item;
uniform sampler2D stone_texture: repeat_enable, filter_linear;
uniform sampler2D theme_atlas: filter_linear;
uniform vec2 world_dimensions = vec2(0.0);
void fragment() {
 vec4 mask = texture(TEXTURE,UV);
 vec2 pixel=world_dimensions.x>0.0 ? UV*world_dimensions : UV/TEXTURE_PIXEL_SIZE;
 float theme=mask.b>mask.r*1.2 ? 1.0 : (mask.r>mask.g*1.8 ? 2.0 : 0.0);
 vec2 tile=clamp(fract(pixel/360.),vec2(.003),vec2(.997));
 vec3 stone=texture(theme_atlas,vec2((tile.x+theme)/3.0,tile.y)).rgb;
 vec3 rim=theme<.5 ? vec3(.28,.43,.18) : (theme<1.5 ? vec3(.70,.86,.96) : vec3(.30,.17,.16));
 vec3 light_rim=theme<.5 ? vec3(.58,.72,.31) : (theme<1.5 ? vec3(.94,.98,1.) : vec3(.95,.40,.12));

 float above=texture(TEXTURE,UV-vec2(0.,7.)*TEXTURE_PIXEL_SIZE).a;
 float below=texture(TEXTURE,UV+vec2(0.,5.)*TEXTURE_PIXEL_SIZE).a;
 float side=min(texture(TEXTURE,UV-vec2(3.,0.)*TEXTURE_PIXEL_SIZE).a,texture(TEXTURE,UV+vec2(3.,0.)*TEXTURE_PIXEL_SIZE).a);
 stone=mix(stone*.55,stone,side);
 stone=mix(stone,rim,1.-above);
 float grass=texture(TEXTURE,UV-vec2(0.,3.)*TEXTURE_PIXEL_SIZE).a;
 stone=mix(stone,light_rim,1.-grass);
 stone=mix(stone,stone*.48,1.-below);
 COLOR=vec4(stone,mask.a);
}



