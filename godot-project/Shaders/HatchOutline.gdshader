shader_type spatial;
render_mode cull_front, unshaded, depth_draw_always;

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform highp float outline_width = 1.0;

group_uniforms Shape;
uniform float displacementStrength = 0.1;
uniform float noiseDensity = 8.0;
group_uniforms;

const float displacementSpeed = 0.;

vec2 voronoi_noise_randomVector (vec2 uv, float offset)
{
    mat2 m;
	m[0][0] = 15.27;
	m[0][1] = 47.63;
	m[1][0] = 99.41;
	m[1][1] = 89.98;
    uv = fract(sin(m * uv) * 46839.32);
    return vec2(sin(uv.y*+offset)*0.5+0.5, cos(uv.x*offset)*0.5+0.5);
}

float Voronoi(vec2 uv, float AngleOffset, float CellDensity)
{
	float Out = 0.0;
	float Cells = 0.0;
    vec2 g = floor(uv * CellDensity);
    vec2 f = fract(uv * CellDensity);
    float t = 8.0;
    vec3 res = vec3(8.0, 0.0, 0.0);

    for(int y=-1; y<=1; y++)
    {
        for(int x=-1; x<=1; x++)
        {
            vec2 lattice = vec2(float(x),float(y));
            vec2 offset = voronoi_noise_randomVector(lattice + g, AngleOffset);
            float d = distance(lattice + offset, f);
            if(d < res.x)
            {
                res = vec3(d, offset.x, offset.y);
                Out = res.x;
                Cells = res.y;
            }
        }
    }
	return Out;
}

vec3 RotateAboutAxis(vec3 In, vec3 Axis, float Rotation)
{
    Rotation = radians(Rotation);
    float s = sin(Rotation);
    float c = cos(Rotation);
    float one_minus_c = 1.0 - c;

    Axis = normalize(Axis);
   	mat3 rot_mat;
	rot_mat[0][0] = one_minus_c * Axis.x * Axis.x + c;
	rot_mat[0][1] = one_minus_c * Axis.x * Axis.y - Axis.z * s;
	rot_mat[0][2] = one_minus_c * Axis.z * Axis.x + Axis.y * s;
	rot_mat[1][0] = one_minus_c * Axis.x * Axis.y + Axis.z * s;
	rot_mat[1][1] = one_minus_c * Axis.y * Axis.y + c;
	rot_mat[1][2] = one_minus_c * Axis.y * Axis.z - Axis.x * s;
	rot_mat[2][0] = one_minus_c * Axis.z * Axis.x - Axis.y * s;
	rot_mat[2][1] = one_minus_c * Axis.y * Axis.z + Axis.x * s;
	rot_mat[2][2] = one_minus_c * Axis.z * Axis.z + c;
	return rot_mat *  In;
}

float RandomRange(vec2 Seed, float Min, float Max)
{
    float randomno =  fract(sin(dot(Seed, vec2(12.9898, 78.233)))*43758.5453);
    return mix(Min, Max, randomno);
}

float VoronoiOffset(vec3 uv, float rn){
	//float randomno = RandomRange(vec2(TIME), 0., 100.) * 0.0001;
	vec3 rotateduv = RotateAboutAxis(uv, vec3(0., 1., 0.), 90.);
	float noiseOffset = pow(Voronoi(uv.xy + (TIME * displacementSpeed + rn), 2.0, noiseDensity), 0.9);
	float rotatedNoiseOffset = pow(Voronoi(rotateduv.xy + (TIME * displacementSpeed + rn), 2.0, noiseDensity), 0.9);
	noiseOffset = noiseOffset + rotatedNoiseOffset;
	return clamp((noiseOffset), 0.0, 1.0) * displacementStrength;
}

void vertex() {
	vec2 uv = UV;
	vec3 position = VERTEX;
	vec3 normal = NORMAL;

	float noiseOffset = VoronoiOffset(position, INSTANCE_CUSTOM.x);
	vec3 newPosition = position + normal * noiseOffset;

	vec3 posPlusTangent = position + TANGENT * 0.01;
    noiseOffset = VoronoiOffset(posPlusTangent, INSTANCE_CUSTOM.x);
    posPlusTangent = posPlusTangent + normal * noiseOffset;

    vec3 posPlusBitangent = position + BINORMAL * 0.01;
    noiseOffset = VoronoiOffset(posPlusBitangent, INSTANCE_CUSTOM.x);
    posPlusBitangent = posPlusBitangent + normal * noiseOffset;

    vec3 modifiedTangent = posPlusTangent - newPosition;
    vec3 modifiedBitangent = posPlusBitangent - newPosition;
    vec3 modifiedNormal = cross(modifiedTangent, modifiedBitangent);
    vec3 newNormal = normalize(modifiedNormal);

	vec4 clip_position = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(newPosition, 1.0));
	vec3 clip_normal = mat3(PROJECTION_MATRIX) * (mat3(MODELVIEW_MATRIX) * newNormal);
	clip_position.xy += normalize(clip_normal.xy) / VIEWPORT_SIZE * clip_position.w * outline_width * 1.0;
	POSITION = clip_position;
}

void fragment() {
	ALBEDO = outline_color.rgb;
	ALPHA = outline_color.a;
}