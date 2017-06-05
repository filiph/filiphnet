library zombie;

import 'dart:html';
import 'details.dart';

class Person extends Entity with KeyboardInput {
  String name;
  int speed = 100;
  
  Person(this.name) : super("img/brain.png");
  
  toString() {
    return name;
  }
}

class ZombieClown extends Entity with ZombieBrain {
  var target;
  int speed = 1;
  ZombieClown() : super("img/clown.png");
}


void main() {
  var filip = new Person("Filip");
  print("Hello $filip!");
  
  var clown = new ZombieClown();
  clown.x = 600;
  clown.y = 500;
  clown.target = filip;
  
  var canvas = querySelector("canvas");
  
  var game = new Game(canvas, [filip, clown]);
  game.onEnterFrame.listen((_) {
    if (clown.hitTestObject(filip)) {
      game.over();
    }
  });
}
