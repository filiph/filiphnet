// Line-for-line port of the TypeScript raytracer to idiomatic Dart. Type
// information that was missing in the TypeScript version was intentionally
// left out here, too.

import 'dart:async';
import 'dart:html';
import 'dart:math';

class Vector {
  final num x, y, z;
  Vector(this.x, this.y, this.z);

  operator *(num k) => new Vector(k * x, k * y, k * z);
  operator -(Vector o) => new Vector(x - o.x, y - o.y, z - o.z);
  operator +(Vector o) => new Vector(x + o.x, y + o.y, z + o.z);
  num dot(Vector o) => x * o.x + y * o.y + z * o.z;
  num mag() => sqrt(x * x + y * y + z * z);

  Vector norm() {
    var mag = this.mag();
    var div = (mag == 0) ? double.INFINITY : 1.0 / mag;
    return this * div;
  }

  Vector cross(Vector o) =>
      new Vector(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);
}

class Color {
  final double r, g, b;
  const Color(this.r, this.g, this.b);

  scale(double k) => new Color(k * r, k * g, k * b);
  operator +(Color v) => new Color(r + v.r, g + v.g, b + v.b);
  operator *(Color v) => new Color(r * v.r, g * v.g, b * v.b);

  static const white = const Color(1.0, 1.0, 1.0);
  static const grey = const Color(0.5, 0.5, 0.5);
  static const black = const Color(0.0, 0.0, 0.0);
  static const background = Color.black;
  static const defaultColor = Color.black;

  toDrawingColor() {
    var legalize = (num d) => ((d > 1 ? 1 : d) * 255).toInt();
    return "${legalize(r)}, ${legalize(g)}, ${legalize(b)}";
  }
}

class Camera {
  Vector pos, forward, right, up;

  Camera(this.pos, Vector lookAt) {
    var down = new Vector(0.0, -1.0, 0.0);
    forward = (lookAt - pos).norm();
    right = forward.cross(down).norm() * 1.5;
    up = forward.cross(right).norm() * 1.5;
  }
}

class Ray {
  Vector start, dir;
  Ray(this.start, this.dir);
}

class Intersection {
  Thing thing;
  Ray ray;
  double dist;
  Intersection(this.thing, this.ray, this.dist);
}

abstract class Surface {
  Color diffuse(Vector pos);
  Color specular(Vector pos);
  double reflect(Vector pos);
  int get roughness;
}

abstract class Thing {
  Intersection intersect(Ray ray);
  Vector normal(Vector pos);
  Surface get surface;
}

class Light {
  Vector pos;
  Color color;
  Light(this.pos, this.color);
}

class Scene {
  List<Thing> things;
  List<Light> lights;
  Camera camera;
  Scene(this.things, this.lights, this.camera);
}

class Sphere implements Thing {
  double radius2, radius;
  Vector center;
  Surface surface;

  Sphere(this.center, double radius, this.surface)
      : radius = radius,
        radius2 = radius * radius;

  Vector normal(Vector pos) => (pos - center).norm();
  intersect(Ray ray) {
    var eo = center - ray.start;
    var v = eo.dot(ray.dir);
    var dist = 0.0;
    if (v >= 0) {
      var disc = radius2 - (eo.dot(eo) - v * v);
      if (disc >= 0) {
        dist = v - sqrt(disc);
      }
    }
    if (dist == 0) {
      return null;
    } else {
      return new Intersection(this, ray, dist);
    }
  }
}

class Plane implements Thing {
  Vector norm;
  double offset;
  Surface surface;
  Plane(this.norm, this.offset, this.surface);

  Intersection intersect(Ray ray) {
    var denom = norm.dot(ray.dir);
    if (denom > 0) {
      return null;
    } else {
      var dist = (norm.dot(ray.start) + offset) / (-denom);
      return new Intersection(this, ray, dist);
    }
  }

  Vector normal(Vector pos) => norm;
}

// Ugh. We're trying to emulate 'module' here, without a separate file.
// Dart programs don't normally use classes in this way.
class Surfaces {
  static final Surface shiny =
      new CustomSurface((_) => Color.white, (_) => Color.grey, (_) => 0.7, 250);
  static final Surface checkerboard = new CustomSurface(
      (Vector pos) {
        if ((pos.z.floor() + pos.x.floor()) % 2 != 0) {
          return Color.white;
        } else {
          return Color.black;
        }
      },
      (_) => Color.white,
      (pos) {
        if ((pos.z.floor() + pos.x.floor()) % 2 != 0) {
          return 0.1;
        } else {
          return 0.7;
        }
      },
      150);
}

class CustomSurface implements Surface {
  final Function _diffuse, _specular, _reflect;
  final int roughness;
  CustomSurface(this._diffuse, this._specular, this._reflect, this.roughness);

  Color diffuse(Vector pos) => _diffuse(pos);
  Color specular(Vector pos) => _specular(pos);
  double reflect(Vector pos) => _reflect(pos);
}

class RayTracer {
  int _maxDepth = 5;

  _intersections(Ray ray, Scene scene) {
    double closest = double.INFINITY;
    Intersection closestInter = null;
    for (Thing thing in scene.things) {
      Intersection inter = thing.intersect(ray);
      if (inter != null && inter.dist < closest) {
        closestInter = inter;
        closest = inter.dist;
      }
    }
    return closestInter;
  }

  _testRay(Ray ray, Scene scene) {
    var isect = _intersections(ray, scene);
    if (isect != null) {
      return isect.dist;
    } else {
      return null;
    }
  }

  Color _traceRay(Ray ray, Scene scene, int depth) {
    var isect = _intersections(ray, scene);
    if (isect == null) {
      return Color.background;
    } else {
      return _shade(isect, scene, depth);
    }
  }

  _shade(Intersection isect, Scene scene, int depth) {
    var d = isect.ray.dir;
    var pos = d * isect.dist + isect.ray.start;
    var normal = isect.thing.normal(pos);
    var reflectDir = d - normal * normal.dot(d) * 2.0;
    var naturalColor = Color.background +
        _getNaturalColor(isect.thing, pos, normal, reflectDir, scene);
    var reflectedColor = (depth >= _maxDepth)
        ? Color.grey
        : _getReflectionColor(
            isect.thing, pos, normal, reflectDir, scene, depth);
    return naturalColor + reflectedColor;
  }

  _getReflectionColor(Thing thing, Vector pos, Vector normal, Vector rd,
      Scene scene, int depth) {
    var color = _traceRay(new Ray(pos, rd), scene, depth + 1);
    var scale = thing.surface.reflect(pos);
    return color.scale(scale);
  }

  _getNaturalColor(
      Thing thing, Vector pos, Vector norm, Vector rd, Scene scene) {
    var addLight = (col, light) {
      var ldis = light.pos - pos;
      var livec = ldis.norm();
      var neatIsect = _testRay(new Ray(pos, livec), scene);
      var isInShadow = (neatIsect == null) ? false : (neatIsect <= ldis.mag());
      if (isInShadow) {
        return col;
      } else {
        var illum = livec.dot(norm);
        var lcolor =
            (illum > 0) ? light.color.scale(illum) : Color.defaultColor;
        var specular = livec.dot(rd.norm());
        var scolor = (specular > 0)
            ? light.color.scale(pow(specular, thing.surface.roughness))
            : Color.defaultColor;
        return col +
            (thing.surface.diffuse(pos) * lcolor) +
            (thing.surface.specular(pos) * scolor);
      }
    };
    return scene.lights.fold(Color.defaultColor, addLight);
  }

  render(scene, ctx, screenWidth, screenHeight) {
    var getPoint = (x, y, camera) {
      var recenterX = (x) => (x - (screenWidth / 2.0)) / 2.0 / screenWidth;
      var recenterY = (y) => -(y - (screenHeight / 2.0)) / 2.0 / screenHeight;
      return (camera.forward +
              camera.right * recenterX(x) +
              camera.up * recenterY(y))
          .norm();
    };

    for (var y = 0; y < screenHeight; y++) {
      for (var x = 0; x < screenWidth; x++) {
        var color = _traceRay(
            new Ray(scene.camera.pos, getPoint(x, y, scene.camera)), scene, 0);
        ctx.fillStyle = "rgb(${color.toDrawingColor()})";
        ctx.fillRect(x, y, x + 1, y + 1);
      }
    }
  }
}

defaultScene() => new Scene([
  new Plane(new Vector(0.0, 1.0, 0.0), 0.0, Surfaces.checkerboard),
  new Sphere(new Vector(0.0, 1.0, -0.25), 1.0, Surfaces.shiny),
  new Sphere(new Vector(-1.0, 0.5, 1.5), 0.5, Surfaces.shiny)
], [
  new Light(new Vector(-2.0, 2.5, 0.0), new Color(0.49, 0.07, 0.07)),
  new Light(new Vector(1.5, 2.5, 1.5), new Color(0.07, 0.07, 0.49)),
  new Light(new Vector(1.5, 2.5, -1.5), new Color(0.07, 0.49, 0.071)),
  new Light(new Vector(0.0, 3.5, 0.0), new Color(0.21, 0.21, 0.35))
], new Camera(new Vector(3.0, 2.0, 4.0), new Vector(-1.0, 0.5, 0.0)));

void main() {
  int width = 256;
  int height = 256;

  CanvasElement canvas = querySelector("#dart-canvas");
  Element info = querySelector("#dart-info");
  ButtonElement button = querySelector("#dart-button");

  int i = 0;
  int rendersPerBatch = 1;  // Change to run several raytraces on first click.
  var times = [];

  button.onClick.listen((_) async {
    info.text = "Rendering...";
    var ctx = canvas.context2D;
    ctx.clearRect(0, 0, width, height);
    // Take the time to show the above to user.
    await new Future.delayed(const Duration(milliseconds: 100));
    var start = window.performance.now();
    var rayTracer = new RayTracer();
    rayTracer.render(defaultScene(), ctx, width, height);
    var time = window.performance.now() - start;
    info.text = "Rendered in ${time.round()} ms.";
    times.add(time);
    print(times);
    i++;
    if (i < rendersPerBatch) button.click();
  });
}
