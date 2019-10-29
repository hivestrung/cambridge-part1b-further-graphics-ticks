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
const vec3 lightGreen = vec3(0.4, 1, 0.4);
const vec3 lightBlue = vec3(0.4, 0.4, 1);
const vec3 black = vec3(0., 0., 0.);
const float specular_shininess = 256;

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
  vec3 d = abs(pt) - vec3(1); // 1 = radius
  return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
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

// tick 4:
float torus(vec3 pt) {
  float major = 3;
  float minor = 1;
  return length(vec2(length(pt.xz) - major, pt.y))-minor;
}


float shapes(vec3 pt){
  vec3 torus1 = translate(pt, vec3(0, 3, 0));
  return torus(torus1);
}
float plane(vec3 pt) {
  return pt.y + 1; // plane at y + 1 = 0 i.e. y = -1
}

float scene(vec3 pt) {
  float objects = shapes(pt);
  return unionShapes(objects, plane(pt));
}

vec3 getColor(vec3 pt) {
  if (pt.y-(-1) < CLOSE_ENOUGH){
    float dist = mod(shapes(pt), 5);
    if (dist <= 4.75){
      return mix(lightGreen, lightBlue, mod(dist, 1));
    }
    else {
      return black;
    }
  }
  else {
    return vec3(1);
  }
}
// changed normal so it acts on scene
vec3 getNormal(vec3 pt) {
  return normalize(GRADIENT(pt, scene));
}

///////////////////////////////////////////////////////////////////////////////

float shade(vec3 eye, vec3 pt, vec3 n) {
  float val = 0;

  val += 0.1;  // Ambient

  // diffuse 1.0
  // specular 1.0
  // specular shininess 256

  for (int i = 0; i < LIGHT_POS.length(); i++) {

    // diffuse, coefficient of 1.0
    vec3 l = normalize(LIGHT_POS[i] - pt);
    val += max(dot(n, l), 0);

    // specular
    vec3 v = normalize(pt - eye);
    vec3 r = normalize(reflect(l, n));
    val += pow(max(dot(v, r), 0), specular_shininess);
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
    d = scene(camPos + t * rayDir);
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
