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
#define RENDER_DEPTH 800
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

// tick 1: replace sphere with cube
float cube(vec3 pt) {
  return max(abs(pt.x), max(abs(pt.y), abs(pt.z))) - 1;
}



// task 2: translation
vec3 translate(vec3 pt, vec3 t){
  mat4 T = mat4(vec4(1, 0, 0, t.x),
  vec4(0, 1, 0, t.y),
  vec4(0, 0, 1, t.z),
  vec4(0, 0, 0, 1)
  );
  return (vec4(pt, 1) * inverse(T)).xyz;
}

// task 2: union
float unionShapes(float a, float b){
  return min(a, b);
}

// task 2: difference
float difference(float a, float b) {
  return max(a, -b);
}

// task 2: blending (renamed smin from slides)
float blend(float a, float b) {
  float k = 0.2;
  float h = clamp(0.5 + 0.5 * (b - a) / k, 0,
  1);
  return mix(b, a, h) - k * h * (1 - h);
}

// task 2: intersection
float intersection(float a, float b){
  return max(a, b);
}

// tick 2: all the shapes
float shapes(vec3 pt) {
  float c1 = cube(pt - vec3(3, 0 ,3));
  float c2 = cube(pt - vec3(-3, 0 ,3));
  float c3 = cube(pt - vec3(3, 0 ,-3));
  float c4 = cube(pt - vec3(-3, 0 ,-3));

  float s1 = sphere(pt - vec3(4, 0, 4));
  float s2 = sphere(pt - vec3(-2, 0, 4));
  float s3 = sphere(pt - vec3(4, 0, -2));
  float s4 = sphere(pt - vec3(-2, 0, -2));
  float union_fl = unionShapes(c4, s4);
  float intersection_fl = intersection(c1, s1);
  float blend_fl = blend(c2, s2);
  float difference_fl = difference(c3, s3);

  return unionShapes(union_fl, unionShapes(intersection_fl, unionShapes(difference_fl, blend_fl)));
}

// changed normal so it acts on cube
vec3 getNormal(vec3 pt) {
  return normalize(GRADIENT(pt, shapes));
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
    d = shapes(camPos + t * rayDir);
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
