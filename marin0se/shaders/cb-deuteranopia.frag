/*
	this code came from [here](https://github.com/PlanetCentauri/ColorblindFilter)
	
	this is for testing color differences in gameplay so we can consider colorblind players, 
	not to help colorblind players directly (as much as we'd like to)
*/
const mat3 m = mat3(0.625, 0.375, 0.0  ,  0.7  , 0.3  , 0.0  ,  0.0  , 0.3   ,0.7  );

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords){
	vec4 vcolor = Texel(texture, texture_coords);
	return vec4(vcolor.rgb * m, vcolor.a); 
}