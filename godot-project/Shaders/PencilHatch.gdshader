shader_type spatial;

group_uniforms default_params;
uniform sampler2D _mainTex: filter_nearest,repeat_enable;
uniform vec4 _tint : source_color = vec4(1.0, 1.0, 1.0, 1.0); 
uniform float _brightness = 0.02;
group_uniforms;

group_uniforms hatching;
uniform vec4 _strokeColor : source_color = vec4(0.0, 0.0, 0.0, 1.0); 
uniform float _hatchTiling = 3.0;
uniform float _hatchWeight : hint_range(0.01, 2.0) = 1.0;
uniform sampler2D _hatch0: filter_nearest,repeat_enable;
uniform sampler2D _hatch1: filter_nearest,repeat_enable;
uniform sampler2D _hatch2: filter_nearest,repeat_enable;
uniform sampler2D _hatch3: filter_nearest,repeat_enable;
uniform sampler2D _hatch4: filter_nearest,repeat_enable;
uniform sampler2D _hatch5: filter_nearest,repeat_enable;
group_uniforms;

varying float vCamDist;

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    vCamDist = abs(distance(world_pos, CAMERA_POSITION_WORLD)) * _hatchWeight;
	
}

vec3 Hatching2(vec2 uv, float intensity, float dist, 
              sampler2D Hatch0_R, sampler2D Hatch0_G, sampler2D Hatch0_B, 
              sampler2D Hatch1_R, sampler2D Hatch1_G, sampler2D Hatch1_B) 
{
    float log2_dist = log2(dist);
				
    vec2 floored_log_dist = floor((log2_dist + vec2(0.0, 1.0)) * 0.5) * 2.0 - vec2(0.0, 1.0);				
    vec2 uv_scale = min(vec2(1.0), pow(vec2(2.0), floored_log_dist));

    float uv_blend = abs(fract(log2_dist * 0.5) * 2.0 - 1.0);
    
    vec2 scaledUVA = uv / uv_scale.x; // Larger scale
    vec2 scaledUVB = uv / uv_scale.y; // Smaller scale

    // Sample the six textures based on scaled UVs
    float hatch0A_R = texture(Hatch0_R, scaledUVA).r;
    float hatch0A_G = texture(Hatch0_G, scaledUVA).r;
    float hatch0A_B = texture(Hatch0_B, scaledUVA).r;

    float hatch1A_R = texture(Hatch1_R, scaledUVA).r;
    float hatch1A_G = texture(Hatch1_G, scaledUVA).r;
    float hatch1A_B = texture(Hatch1_B, scaledUVA).r;

    float hatch0B_R = texture(Hatch0_R, scaledUVB).r;
    float hatch0B_G = texture(Hatch0_G, scaledUVB).r;
    float hatch0B_B = texture(Hatch0_B, scaledUVB).r;

    float hatch1B_R = texture(Hatch1_R, scaledUVB).r;
    float hatch1B_G = texture(Hatch1_G, scaledUVB).r;
    float hatch1B_B = texture(Hatch1_B, scaledUVB).r;

    // Blend between different scale samples
    float hatch0_R = mix(hatch0A_R, hatch0B_R, uv_blend);
    float hatch0_G = mix(hatch0A_G, hatch0B_G, uv_blend);
    float hatch0_B = mix(hatch0A_B, hatch0B_B, uv_blend);

    float hatch1_R = mix(hatch1A_R, hatch1B_R, uv_blend);
    float hatch1_G = mix(hatch1A_G, hatch1B_G, uv_blend);
    float hatch1_B = mix(hatch1A_B, hatch1B_B, uv_blend);

    vec3 overbright = vec3(max(0.0, intensity - 1.0));

    // Compute weights
    vec3 weightsA = clamp((intensity * 6.0) + vec3(-0, -1, -2), 0., 1.);
    vec3 weightsB = clamp((intensity * 6.0) + vec3(-3, -4, -5), 0., 1.);

    weightsA.xy -= weightsA.yz;
    weightsA.z -= weightsB.x;
    weightsB.xy -= weightsB.yz;

    vec3 hatch0 = vec3(hatch0_R, hatch0_G, hatch0_B) * weightsA;
    vec3 hatch1 = vec3(hatch1_R, hatch1_G, hatch1_B) * weightsB;

    vec3 hatching = overbright + hatch0.r + hatch0.g + hatch0.b + hatch1.r + hatch1.g + hatch1.b;
		
    return hatching;
}

void fragment() {
	//vec2 uv = UV * _hatchTiling;
	//
	//vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	//float camDist = abs(distance(world_pos, CAMERA_POSITION_WORLD)) * _hatchWeight;
	//vec3 lightDir = normalize(vec3(0., 8.5, 0.) - world_pos);
	//
	//
	//vec3 diffuseLight = clamp(dot(NORMAL, lightDir), 0.0, 1.0) * 1. * vec3(1.) / PI;
	//float lightIntensity = dot(diffuseLight, vec3(0.2326, 0.7152, 0.0722)) + _brightness;
	//
	//vec3 hatch = Hatching(uv, lightIntensity, camDist, _hatch0, _hatch1);
	//vec3 finalCol = mix(_strokeColor.rgb, _tint.rgb, hatch);
	
	ALBEDO = vec3(1.);
}

void light() {
	vec2 uv = UV * _hatchTiling;
	float camDist = vCamDist;	
	
	vec4 mainCol = texture(_mainTex, UV);
	vec3 diffuseLight = clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * LIGHT_COLOR / PI * mainCol.rgb;
	float lightIntensity = dot(diffuseLight, vec3(0.2326, 0.7152, 0.0722)) + _brightness;
	
	vec3 hatch = Hatching2(uv, lightIntensity, camDist, _hatch0, _hatch1, _hatch2, _hatch3, _hatch4,
	_hatch5);
	vec3 finalCol = mix(_strokeColor.rgb, _tint.rgb, hatch);

 	DIFFUSE_LIGHT = finalCol;
}
