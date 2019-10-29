#version 330

uniform vec2 resolution;
uniform float currentTime;
uniform vec3 camPos;
uniform vec3 camDir;
uniform vec3 camUp;
uniform sampler2D tex;
uniform bool showStepDepth;

in vec3 pos;

out vec3 color;

#define PI 3.1415926535897932384626433832795
#define RENDER_DEPTH 800  //mila: updated render_depth to not lose pixels
#define CLOSE_ENOUGH 0.00001

#define BACKGROUND -1
#define BALL 0
#define BASE 1

#define GRADIENT(pt, func) vec3( \
    func(vec3(pt.x + 0.0001, pt.y, pt.z)) - func(vec3(pt.x - 0.0001, pt.y, pt.z)), \
    func(vec3(pt.x, pt.y + 0.0001, pt.z)) - func(vec3(pt.x, pt.y - 0.0001, pt.z)), \
    func(vec3(pt.x, pt.y, pt.z + 0.0001)) - func(vec3(pt.x, pt.y, pt.z - 0.0001)))

const vec3 LIGHT_POS[] = vec3[](vec3(5, 18, 10));

///////////////////////////////////////////////////////////////////////////////

vec3 getBackground(vec3 dir) {
  float u = 0.5 + atan(dir.z, -dir.x) / (2 * PI);
  float v = 0.5 - asin(dir.y) / PI;
  vec4 texColor = texture(tex, vec2(u, v));
  return texColor.rgb;
}

vec3 getRayDir() {
  vec3 xAxis = normalize(cross(camDir, camUp));
  return normalize(pos.x * (resolution.x / resolution.y) * xAxis + pos.y * camUp + 5 * camDir);
}

///////////////////////////////////////////////////////////////////////////////

float sphere(vec3 pt) {
  return length(pt) - 1;
}

//mila: added code for unit cube
float cube(vec3 pt) {
  return max(max(abs(pt.x), abs(pt.y)), abs(pt.z)) - 1;
  }

//mila: union, intersection, blend, difference
float unite(float v1, float v2) {
  return min(v1, v2);
}

float intersect(float v1, float v2) {
  return max(v1, v2);
}

float blend( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1 - h); }

float difference(float v1, float v2) {
  return max(v1, -v2);
}

//mila: 4 cubes, 4 spheres
float scene_cubes_spheres(vec3 pt) {
  float c1 = cube(pt - vec3(3, 0 ,3));
  float c2 = cube(pt - vec3(-3, 0 ,3));
  float c3 = cube(pt - vec3(3, 0 ,-3));
  float c4 = cube(pt - vec3(-3, 0 ,-3));

  float s1 = sphere(pt - vec3(4, 0, 4));
  float s2 = sphere(pt - vec3(-2, 0, 4));
  float s3 = sphere(pt - vec3(4, 0, -2));
  float s4 = sphere(pt - vec3(-2, 0, -2));

  float union_fl = unite(c4, s4);
  float interesction_fl = intersect(c1, s1);
  float blend_fl = blend(c2, s2, 0.2);
  float difference_fl = difference(c3, s3);

  return min(union_fl, min(interesction_fl, min(difference_fl, blend_fl)));
}

//mila: shading for scene
vec3 getNormal(vec3 pt) {
  return normalize(GRADIENT(pt, scene_cubes_spheres));
}

vec3 getColor(vec3 pt) {
  return vec3(1);
}

///////////////////////////////////////////////////////////////////////////////

float shade(vec3 eye, vec3 pt, vec3 n) {
  float val = 0;

  val += 0.1;  // Ambient

  for (int i = 0; i < LIGHT_POS.length(); i++) {
    vec3 l = normalize(LIGHT_POS[i] - pt);
    val += max(dot(n, l), 0);
  }
  return val;
}

vec3 illuminate(vec3 camPos, vec3 rayDir, vec3 pt) {
  vec3 c, n;
  n = getNormal(pt);
  c = getColor(pt);
  return shade(camPos, pt, n) * c;
}

///////////////////////////////////////////////////////////////////////////////

vec3 raymarch(vec3 camPos, vec3 rayDir) {
  int step = 0;
  float t = 0;

  for (float d = 1000; step < RENDER_DEPTH && abs(d) > CLOSE_ENOUGH; t += abs(d)) {
     //mila: ucnommented line to activate raymarching for cube
     d = scene_cubes_spheres(camPos + t * rayDir);
    step++;
  }

  if (step == RENDER_DEPTH) {
    return getBackground(rayDir);
  } else if (showStepDepth) {
    return vec3(float(step) / RENDER_DEPTH);
  } else {
    return illuminate(camPos, rayDir, camPos + t * rayDir);
  }
}

///////////////////////////////////////////////////////////////////////////////

void main() {
  color = raymarch(camPos, getRayDir());
}