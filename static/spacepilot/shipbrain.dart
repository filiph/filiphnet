part of spaceship_combat;

class NeuroPilotPhenotype extends Phenotype<num> {
  NeuroPilotPhenotype();
  
  NeuroPilotPhenotype.fromBackyWeights(List<Weight> weightObjects) {
    List<List<List<num>>> weights = new List<List<List<num>>>(weightObjects.length);
    for (int i = 0; i < weightObjects.length; i++) {
      List<List<num>> array = weightObjects[i].weights;
      weights[i] = new List<List<num>>(array.length);
      for (int j = 0; j < array.length; j++) {
        weights[i][j] = new List<num>(array[j].length);
        for (int k = 0; k < array[j].length; k++) {
          weights[i][j][k] = array[j][k];
        }
      }
    }
    genes = weights.expand((List<List<num>> planes) => planes.expand((List<num> rows) => rows)).toList(growable: false);
  }
  
  List<num> genes;

  num mutateGene(num gene, num strength) {
    Math.Random random = new Math.Random();
    num delta = (random.nextDouble() * 2 - 1) * strength;
    return (gene + delta).clamp(-1, 1);
  }
}

class NeuroPilotSerialEvaluator extends PhenotypeSerialEvaluator<NeuroPilotPhenotype> {
  NeuroPilotSerialEvaluator(this.brainMode);
  
  /// The [ShipBrainMode] we are evaluating.
  final ShipBrainMode brainMode;
  
  static AIBox2DShip _createBodega(ShipCombatSituation s) {
    return new AIBox2DShip(s, 1.0, 3.0, new Vector2(0.0, 5.0),
          thrusters: [new Thruster(-1.5, -0.5, 1, 0),  // Main thrusters
                      new Thruster(-1.5,  0.5, 1, 0),
                      new Thruster( 1.5,    0, -0.5, 0), // Retarder
                      new Thruster(-1.5, -0.5, 0, 0.2), // Back maneuverability
                      new Thruster(-1.5,  0.5, 0, -0.2),
                      new Thruster( 1.5, -0.5, 0, 0.2),  // Front maneuverability
                      new Thruster( 1.5,  0.5, 0, -0.2)]);
  }
  
  static Box2DShip _createMessenger(ShipCombatSituation s) {
    return new Box2DShip(s, 0.3, 0.5, new Vector2(0.0, 15.0));
  }
  
  Future<num> runOneEvaluation(NeuroPilotPhenotype phenotype, int i) {
    print("Experiment $i");
    if (i >= brainMode.setupFunctions.length) {
      return new Future.value(null);
    }
    ShipCombatSituation s = new ShipCombatSituation(
        fitnessFunction: brainMode.iterativeFitnessFunction);
    currentSituation = s;
    var bodega = _createBodega(s);
    var messenger = _createMessenger(s);
    s.addShip(bodega, evaluatedShip: true);
    s.addShip(messenger);
    bodega.target = messenger;
    bodega.brainMode = brainMode;
    bodega.brainMode.initializeBrain(bodega);
    bodega.brainMode.setBrainFromPhenotype(phenotype);
    bodega.brainMode.setupFunctions[i](s);
    return s.runTest().then((ShipCombatSituation s) {
      if (s.destroyed) return null;
      s.destroy();
      currentSituation = null;
      return s.cummulativeScore;
    });
  }
}

/**
 * A function to be called before experiment. Makes sure everything is set
 * up in an 'interesting' way. Returns the [ShipCombatSituation].
 */
typedef SetupFunction(ShipCombatSituation s);

abstract class ShipBrainMode {
  static final Neuron neuron = new TanHNeuron();
  
  ShipBrainMode();
  
  void initializeBrain(AIBox2DShip ship) {
    neuron.bias = 1;
    outputNeuronsCount = ship.thrusters.length;
    brain = new Backy([inputNeuronsCount, 
                       // 'The optimal size of the hidden layer is usually 
                       // between the size of the input and size of the output 
                       // layers.'
                       (inputNeuronsCount + outputNeuronsCount) ~/ 2,
                       outputNeuronsCount], neuron);
  }
  
  Backy brain;
  
  List<num> _bestPhenotypeGenes;
  NeuroPilotPhenotype get bestPhenotype {
    if (_bestPhenotypeGenes == null) return null;
    var ph = new NeuroPilotPhenotype();
    ph.genes = _bestPhenotypeGenes;
    return ph;
  }
  
  int get inputNeuronsCount;
  int outputNeuronsCount;
  
  List<SetupFunction> get setupFunctions;
  
  /**
   * Takes the [ship] being evaluated, the [worldState] (when also evaluating
   * the effects the phenotype has on its environment, or when evaluating some
   * variables in relation to surroundings) and [userData] (an object that can
   * store state between calls to objective function).
   * 
   * The function must return a positive [num]. The lower the value, the better
   * fit. Returning [:0,0:] means the phenotype is performing perfectly (= is in
   * desired state in relation to its surroundings).
   * 
   * This function will be called periodically, and its return values will be
   * summed.
   */
  num iterativeFitnessFunction(AIBox2DShip ship, Box2DShip target,
                               ShipCombatSituation worldState, 
                               [Object userData]);
  
  /**
   * Generates input for given [ship] and its [target] in a given situation [s].
   * This is feeded to the [brain]'s neural network.
   */
  List<num> getInputs(AIBox2DShip ship, Box2DShip target, ShipCombatSituation s);
  
  /**
   * Takes control of the ship. 
   * 
   * Applies the results of the neural network by sending commands to different
   * systems of the ship, according to current situation.
   */
  void control(AIBox2DShip ship, Box2DShip target, ShipCombatSituation s);
  
  void setBrainFromPhenotype(NeuroPilotPhenotype phenotype) {
    List<num> genes = phenotype.genes;
    int n = 0;
    for (int i = 0; i < brain.weights.length; i++) {
      for (int j = 0; j < brain.weights[i].weights.length; j++) {
        for (int k = 0; k < brain.weights[i].weights[j].length; k++) {
          brain.weights[i].weights[j][k] = genes[n];
          n++;
        }
      }
    }
    assert(n == genes.length);
  }
  
  /**
   * Takes a value and [min] and [max], and returns a number that is suitable
   * for [TanHNeuron] input. (Range from [:-1.0:] to [:1.0:].)
   * 
   * Values lower than [min] will be mapped to [:-1.0:], values higher than 
   * [max] will be mapped to [:1.0:]. Everything between will be mapped
   * lineary.
   * 
   * [min] can also be _higher_ than [max], in which case the function will
   * inverse. In other words, a [value] of [max] will be converted to [:-1.0:],
   * etc.
   */
  static num valueToNeuralInput(num value, num min, num max) {
    if (min == max || min == null || max == null) {
      throw new ArgumentError("The values of min and max must be different "
          "and not null (function called with $min, $max, respectivelly).");
    }
    bool inversed = min > max;
    
    if (value <= min) {
      return inversed ? 1.0 : -1.0;
    }
    if (value >= max) {
      return inversed ? -1.0 : 1.0;
    }
    
    return (value - min) / (max - min) * 2 - 1;
    // For value=3, min=0, max=10.
    // (3 - 0) / (10 - 0) * 2 - 1 = 0.3 * 2 - 1 = -0.4
    // For value=3, min=10, max=0.
    // (3 - 10) / (0 - 10) * 2 - 1 = (-7) / (-10) * 2 - 1 = 0.7 * 2 - 1 = 0.4
    // For value=3.5, min=4, max=3.
    // (3.5 - 4) / (3 - 4) * 2 - 1 = (-0.5) / (-1) * 2 - 1 = 0.5 * 2 - 1 = 0.0
  }
}

typedef num IterativeFitnessFunction(AIBox2DShip ship, Box2DShip target,
                                     ShipCombatSituation worldState, 
                                     [Object userData]);

/**
 * Only controls thrusters.
 */
abstract class ThrusterControllingShipBrainMode extends ShipBrainMode {
  ThrusterControllingShipBrainMode() : super();

  int outputNeuronsCount;
  
  /**
   * Takes control of the thrusters only.
   */
  void control(AIBox2DShip ship, Box2DShip target, ShipCombatSituation s) {
    List<num> outputs = brain.use(getInputs(ship, target, s));
    assert(outputs.length == ship.thrusters.length);
    for (int i = 0; i < ship.thrusters.length; i++) {
      num force = ((outputs[i] + 1) / 2).clamp(0, 1);  // from <-1,1> to <0,1>
      ship.thrust(i, force);
    }
  }
}


int STATUS_UPDATE_FREQ = 10;
int statusUpdateCounter = 0;

class PutOnNoseMode extends ThrusterControllingShipBrainMode {
  PutOnNoseMode() : super();
  
  var _bestPhenotypeGenes = [-0.31012380514400495,1,-0.07465971714954822,-1,0.4390932742380671,1,0.4761198381825338,-1,0.09305732101788222,-1,1,-0.3692183232105115,-0.7100085804940897,0.6776165619253225,-0.14522686688425113,1,-1,0.5351302133232576,-0.02476802866637895,-1,1,0.4308900152960842,-0.2829682526706241,1,0.931953981024773,-0.9417842998270258,-0.09697186602521635,-1,0.6606842188955737,-0.052298541086803985,0.14777928512987493,0.3995991212874406,-0.34798993433366365,-1,-0.9735414126393718,1,-1,-0.6356259110840308,1,0.8738173885091536,-0.6395984683428337,-1,0.4356483735526069,1,-1,-1,0.772469253219868,0.6006447479356358,-1,0.09551737609429178,-0.9625166064410811,-1,-1,-0.37176800552493794,-1,1,-1,0.3368505689428207,0.9225292674110024,-0.10536017214088256,-1,-1,0.21960234848841176,-1,-0.5512635075377732,0.7114815737313644,-1,-1,0.9321337250671611,-0.6576589521216456,-0.3000066193272737,0.4553643481116396,1,-1,0.27456966542617534,0.7369454898806533,-0.05843221056325398,-0.7233250731702285];

  int inputNeuronsCount = 6;
  
  List<num> getInputs(AIBox2DShip ship, Box2DShip target, ShipCombatSituation s) {
    if (target == null) throw "Cannot put nose on null target.";
    List<num> inputs = new List(inputNeuronsCount);
    
    num angVel = ship.body.angularVelocity;
    inputs[0] = ShipBrainMode.valueToNeuralInput(angVel, 0, 2);
    inputs[1] = ShipBrainMode.valueToNeuralInput(angVel, 0, -2);
    inputs[2] = ShipBrainMode.valueToNeuralInput(
        ship.getRelativeVectorTo(target).length, 0, 50);
    num angle = ship.getAngleTo(target);
    inputs[3] = ShipBrainMode.valueToNeuralInput(angle, 0, Math.PI * 2);
    inputs[4] = ShipBrainMode.valueToNeuralInput(angle, 0, - Math.PI * 2);
    inputs[5] = ShipBrainMode.valueToNeuralInput(
        ship.getRelativeVelocityTo(target).length, 0, 5);
    
    return inputs;
  }

  List<SetupFunction> setupFunctions = [
      (ShipCombatSituation s) {
        print("- to the left");
        s.ship.body.setTransform(new Vector2(0.0, 0.0), Math.PI / 4);
      },
      (ShipCombatSituation s) {
        print("- to the right");
        s.ship.body.setTransform(new Vector2(0.0, 0.0), 3 * Math.PI / 4);
      },
      (ShipCombatSituation s) {
        print("- back with impulse");
        s.ship.body.setTransform(new Vector2(0.0, 0.0), - Math.PI / 2);
        s.ship.body.applyLinearImpulse(new Vector2(2.0, 0.0), new Vector2(0.0, -1.0));
      },
      (ShipCombatSituation s) {
        print("- back slightly off");
        s.ship.body.setTransform(new Vector2(0.0, 0.0), - Math.PI / 2 + 0.1);
      }
  ];
  
  num iterativeFitnessFunction(AIBox2DShip ship, Box2DShip target,
                               ShipCombatSituation worldState,
                               [Object userData]) {
    num angleScore = ship.getAngleTo(target).abs();
    num angularScore = ship.body.angularVelocity.abs();
    num relativeScore = ship.getRelativeVelocityTo(target).length;
    num absoluteScore = 
        ship.body.getLinearVelocityFromLocalPoint(new Vector2(0.0, 0.0)).length;
    
    num fitness = 
        (10 * angleScore + angularScore + relativeScore + absoluteScore);
    
    if (ship.body.contactList != null) {
      fitness += 50000;
    }
    
    statusUpdateCounter++;
    if (statusUpdateCounter == STATUS_UPDATE_FREQ) {
      var inputs = ship.brainMode.getInputs(ship, target, worldState);
      experimentStatusEl.text = """ 
Angle (${ship.getAngleTo(target).toStringAsFixed(2)}) ${angleScore < 0.5 ? "*": ""}
AnguV (${ship.body.angularVelocity.toStringAsFixed(2)})
RelV  (${ship.getRelativeVelocityTo(target).length.toStringAsFixed(2)})
AbsV  (${absoluteScore.toStringAsFixed(2)})
SCORE = ${fitness.toStringAsFixed(2)}
CUMSC = ${worldState.cummulativeScore.toStringAsFixed(2)}
INPT  = ${inputs.map((num o) => o.toStringAsFixed(2)).join(" ")}
OUTP  = ${ship.brainMode.brain.use(inputs).map((num o) => o.toStringAsFixed(2)).join(" ")}
""";
          statusUpdateCounter = 0;
    }
    return fitness; 
  }
}

class RamMode extends ThrusterControllingShipBrainMode {
  RamMode() : super();
  
  var _bestPhenotypeGenes = [-1,-0.21414186763937182,-0.9923237386960386,-1,-0.32499690507565293,-1,-0.1541420162315008,0.05253919114156824,-0.6377496625617043,1,-1,-0.6062381506918497,-0.36035078589680647,-0.4527663111751232,0.08511875257206558,0.6431275754055721,0.014536430399076705,0.7058647312553057,0.2313703301879273,0.030241828752782807,-0.9916426613529643,-1,0.8423245602800793,-0.1959763195306108,0.9811867740451166,-0.5596818888829889,0.7096818816400159,1,0.5247805970910993,0.6831649221209533,-0.43638463320329723,-0.4452521703364858,-1,0.16108913651144197,-0.6077066318781632,0.007923413542061164,0.788419136299338,-0.4967670400005586,0.8954297482022853,-0.02291970703206303,-0.730942963102307,0.5127235838190218,0.8151821242376245,-1,-1,0.4582192722405005,0.23198912631514568,-0.6302459228799329,-0.1542277963798644,1,-0.18146961541869988,-1,-0.1363412456504831,0.33159503092436915,-0.5205104439506165,0.6802052658571951,-0.3226176911015066,-0.641860147527106,1,0.06568772682882362,0.7703281772224944,0.32768566232673924,0.9091512232040724,-0.23686887081252794,-1,-0.8013651367705967,0.8128964905073257,0.5106398719511036,-0.3612132247554689,-1,-0.13737279306235406,0.636790672526869,0.13803503402439388,-0.6817824482982322,-0.08420225701011264,1,-0.4496054418665034,-0.7387820960018752];
  
  int inputNeuronsCount = 6;
  
  List<num> getInputs(AIBox2DShip ship, Box2DShip target, ShipCombatSituation s) {
    if (target == null) throw "Cannot put nose on null target.";
    List<num> inputs = new List(inputNeuronsCount);
    
    num angVel = ship.body.angularVelocity;
    inputs[0] = ShipBrainMode.valueToNeuralInput(angVel, 0, 2);
    inputs[1] = ShipBrainMode.valueToNeuralInput(angVel, 0, -2);
    inputs[2] = ShipBrainMode.valueToNeuralInput(
        ship.getRelativeVectorTo(target).length, 0, 50);
    num angle = ship.getAngleTo(target);
    inputs[3] = ShipBrainMode.valueToNeuralInput(angle, 0, Math.PI * 2);
    inputs[4] = ShipBrainMode.valueToNeuralInput(angle, 0, - Math.PI * 2);
    inputs[5] = ShipBrainMode.valueToNeuralInput(
        ship.getRelativeVelocityTo(target).length, 0, 5);
    
    return inputs;
  }
  
  List<SetupFunction> setupFunctions = [
    (ShipCombatSituation s) {
      print("- to the left");
      s.ship.body.setTransform(new Vector2(0.0, 0.0), Math.PI / 4);
    },
    (ShipCombatSituation s) {
      print("- to the right");
      s.ship.body.setTransform(new Vector2(0.0, 0.0), 3 * Math.PI / 4);
    },
    (ShipCombatSituation s) {
      print("- back with impulse");
      s.ship.body.setTransform(new Vector2(0.0, 0.0), - Math.PI / 2);
      s.ship.body.applyLinearImpulse(new Vector2(2.0, 0.0), new Vector2(0.0, -1.0));
    },
    (ShipCombatSituation s) {
      print("- back slightly off");
      s.ship.body.setTransform(new Vector2(0.0, 0.0), - Math.PI / 2 + 0.1);
    }
                                        ];
  
  num iterativeFitnessFunction(AIBox2DShip ship, Box2DShip target,
                               ShipCombatSituation worldState,
                               [Object userData]) {
    statusUpdateCounter++;
    if (statusUpdateCounter == STATUS_UPDATE_FREQ) {
      var inputs = ship.brainMode.getInputs(ship, target, worldState);
      experimentStatusEl.text = """ 
Rammed (${(userData as Map).containsKey("rammed")})
AnguV (${ship.body.angularVelocity.toStringAsFixed(2)})
RelV  (${ship.getRelativeVelocityTo(target).length.toStringAsFixed(2)})
CUMSC = ${worldState.cummulativeScore.toStringAsFixed(2)}
INPT  = ${inputs.map((num o) => o.toStringAsFixed(2)).join(" ")}
OUTP  = ${ship.brainMode.brain.use(inputs).map((num o) => o.toStringAsFixed(2)).join(" ")}
      """;
      statusUpdateCounter = 0;
    }

    if ((userData as Map).containsKey("rammed")) {
      return 0;
    }
    if (ship.body.contactList != null) {
      (userData as Map)["rammed"] = true;
      var score = ship.body.angularVelocity.abs() * 10;  // prefer straight line
      score += ship.getAngleTo(target).abs() * 100; // prefer head on collision
      return score;
    }

    return 1;
  }
}

class RunAwayMode extends ThrusterControllingShipBrainMode {
  int inputNeuronsCount = 6;

  var _bestPhenotypeGenes = [-0.6365017683440641,0.4948233947431637,1,-0.2978041998465111,0.5483557848811249,1,-0.19950995684959594,1,0.9923508371172551,1,0.9703486932827083,0.19704397368841464,0.002260979724461043,0.3799558162277141,1,0.7271738352987316,0.7172617632258849,1,0.2447342310336107,0.14486030445194675,1,-0.08680643368129926,0.28621850573394125,1,1,0.1948468255674236,-0.8618221997472579,-0.5689250971144446,-1,-1,-0.47475301049804663,-1,1,-0.9832649592586187,0.6625999444242254,0.0859548534401322,-0.05183690796488194,1,1,0.9369797133734912,-0.767108902956245,1,0.9834216394806794,1,1,0.5364263388053601,-1,1,-1,-1,-1,-1,-0.7950962936618986,-1,-0.8630781760686892,0.25925360062598557,0.30956986037094847,0.11676731605244162,0.23965856944367991,0.7808912500169252,-1,-1,-0.017289719774240098,0.1845985460885149,1,-1,0.42786145626845595,1,0.8102764068936965,0.6286269633226826,0.7675326785926218,1,-0.3381967560812773,-1,-1,-1,-1,-1];
  
  List<num> getInputs(AIBox2DShip ship, Box2DShip target, ShipCombatSituation s) {
    List<num> inputs = new List<num>(inputNeuronsCount);
    
    num angVel = ship.body.angularVelocity;
    inputs[0] = ShipBrainMode.valueToNeuralInput(angVel, 0, 2);
    inputs[1] = ShipBrainMode.valueToNeuralInput(angVel, 0, -2);
    inputs[2] = ShipBrainMode.valueToNeuralInput(
        ship.getRelativeVectorTo(target).length, 0, 50);
    num angle = ship.getAngleTo(target);
    inputs[3] = ShipBrainMode.valueToNeuralInput(angle, 0, Math.PI * 2);
    inputs[4] = ShipBrainMode.valueToNeuralInput(angle, 0, - Math.PI * 2);
    inputs[5] = ShipBrainMode.valueToNeuralInput(
        ship.getRelativeVelocityTo(target).length, 0, 5);
    
    return inputs;
  }
  
  List<SetupFunction> setupFunctions = [
      (ShipCombatSituation s) {
        print("- to the left");
        s.ship.body.setTransform(new Vector2(0.0, 0.0), Math.PI / 4);
      },
      (ShipCombatSituation s) {
        print("- to the right");
        s.ship.body.setTransform(new Vector2(0.0, 0.0), 3 * Math.PI / 4);
      },
      (ShipCombatSituation s) {
        print("- back with impulse");
        s.ship.body.setTransform(new Vector2(0.0, 0.0), - Math.PI / 2);
        s.ship.body.applyLinearImpulse(new Vector2(2.0, 0.0), new Vector2(0.0, -1.0));
      },
      (ShipCombatSituation s) {
        print("- front with impulse");
        s.ship.body.setTransform(new Vector2(0.0, 0.0), Math.PI / 2);
        s.ship.body.applyLinearImpulse(new Vector2(0.0, 2.0), new Vector2(0.0, -1.0));
      }
  ];

  num iterativeFitnessFunction(AIBox2DShip ship, Box2DShip target, ShipCombatSituation s, [Object userData]) {
    num velocityScore = 1 / (ship.getRelativeVelocityTo(target).length + 1);
    num proximityScore = 1 / Math.pow((ship.getRelativeVectorTo(target).length + 1) / 100, 2);  // 1 / (x/100)^2
    num angleScore = Math.PI - ship.getAngleTo(target).abs();
    
    num fitness = velocityScore + proximityScore + angleScore;
    
    statusUpdateCounter++;
    if (statusUpdateCounter == STATUS_UPDATE_FREQ) {
      var inputs = ship.brainMode.getInputs(ship, ship.target, ship.situation);
      experimentStatusEl.text = """ 
Velo (${velocityScore.toStringAsFixed(2)})
Prox (${proximityScore.toStringAsFixed(2)})
Angl (${angleScore.toStringAsFixed(2)}) ${angleScore < 0.5 ? "*" : ""}
SCORE = ${fitness.toStringAsFixed(2)}
CUMSC = ${s.cummulativeScore.toStringAsFixed(2)}
INPT  = ${inputs.map((num o) => o.toStringAsFixed(2)).join(" ")}
OUTP  = ${ship.brainMode.brain.use(inputs).map((num o) => o.toStringAsFixed(2)).join(" ")}
      """;
      statusUpdateCounter = 0;
    }
    
    if (ship.body.contactList != null) {
      fitness += 50000;
    }
    
    return fitness;
  }

}

class ShipCombatSituation extends Demo {
  /** Constructs a new BoxTest. */
  ShipCombatSituation({this.fitnessFunction, this.maxTimeToRun: 1000}) 
      : super("Box test", new Vector2(0.0, 0.0)) {
    assert (world != null);
  }
  
  void initialize() {
    // Already initialized in constructor.
  }
  
  /**
   * The list of aiShips in the situation. If [fitnessFunction] is provided,
   * the _first_ ship is evaluated (not the others).
   */
  Set<AIBox2DShip> _aiShips = new Set<AIBox2DShip>();
  AIBox2DShip ship;
  
  void addShip(Box2DShip ship, {bool evaluatedShip: false}) {
    if (ship is AIBox2DShip) {
      _aiShips.add(ship);
      if (evaluatedShip) {
        this.ship = ship;
      }
    }
    bodies.add(ship.body);
  }
  
  /// Number of iterations to run this simulation. When set to [:null:], runs
  /// infinitely.
  num maxTimeToRun;
  num currentTime = 0;
  
  IterativeFitnessFunction fitnessFunction;
  num cummulativeScore = 0;
  
  Map userData = {};

  Completer<ShipCombatSituation> _completer = 
      new Completer<ShipCombatSituation>();
  
  Future runTest() {
    initializeAnimation();
    runAnimation(updateCallback);
    return _completer.future;
  }
  
  bool updateCallback(num time) {
    _aiShips.forEach((AIBox2DShip ship) => ship.applyBrain());
    currentTime += 1;
    if (maxTimeToRun != null && currentTime > maxTimeToRun) {
      _completer.complete(this);
      return false; 
    }
    if (fitnessFunction != null) {
      num score = fitnessFunction(ship, ship.target, this, userData);
      if (score == null) throw "Fitness function returned a null value.";
      if (score.isInfinite) {
        cummulativeScore = double.INFINITY;
        _completer.complete(this);
        return false;
      }
      cummulativeScore += score;
    }
    return true; // continue
  }
}

class Box2DShip {
  final ShipCombatSituation situation;
  Body body;
  final List<Thruster> thrusters;
  
  Box2DShip(this.situation, num length, num width, Vector2 position,
      {num initialAngle: 0,
       this.thrusters: const []}) {
    // Create shape
    final PolygonShape shape = new PolygonShape();
    shape.setAsBoxWithCenterAndAngle(width, length, new Vector2.zero(), 0.0);

    // Define fixture (links body and shape)
    final FixtureDef activeFixtureDef = new FixtureDef();
    activeFixtureDef.restitution = 0.5;
    activeFixtureDef.density = 0.05;
    activeFixtureDef.shape = shape;

    // Define body
    final BodyDef bodyDef = new BodyDef();
    bodyDef.type = BodyType.DYNAMIC;
    bodyDef.linearDamping = 0.2;
    bodyDef.angularDamping = 0.2;
    bodyDef.position = position;

    // Create body and fixture from definitions
    body = situation.world.createBody(bodyDef);
    body.createFixture(activeFixtureDef);
    
    body.setTransform(position, initialAngle.toDouble());
  }
  
  /**
   * Burns the thruster number [thrusterIndex] with [relativeForce] of its
   * [Thruster.maxForce].
   */
  void thrust(int thrusterIndex, num relativeForce) {
    if (thrusterIndex > thrusters.length) throw "No such thruster number $thrusterIndex.";
    
    Thruster thruster = thrusters[thrusterIndex];
    Matrix2 rotm = new Matrix2.rotation(-body.angle);
    body.applyForce(thruster.maxForce.scaled(relativeForce.toDouble()).postmultiply(rotm), 
        body.getWorldPoint(thruster.localPosition));
  }
  
  static final Vector2 ORIGIN = new Vector2.zero();
  static final Vector2 FORWARD = new Vector2(1.0, 0.0);
  static final Vector2 RIGHT = new Vector2(0.0, 1.0);
  
  Vector2 getRelativeVectorTo(Box2DShip target) => 
      body.getLocalPoint(target.body.position);
  num getAngleTo(Box2DShip target) {
    Vector2 relativeVectorToTarget = getRelativeVectorTo(target);
    return Math.acos(relativeVectorToTarget.dot(FORWARD) /
        (FORWARD.length * relativeVectorToTarget.length)) *
        (relativeVectorToTarget.dot(RIGHT) > 0 ? 1 : -1);
  }
  /**
   * Returns the velocity vector of the other ship as seen from this ship.
   */
  Vector2 getRelativeVelocityTo(Box2DShip target) {
    return body.getLinearVelocityFromLocalPoint(ORIGIN)
        .sub(target.body.getLinearVelocityFromLocalPoint(ORIGIN));
  }
}

class AIBox2DShip extends Box2DShip {
  AIBox2DShip(ShipCombatSituation situation, num length, num width, 
      Vector2 position, {num initialAngle: 0, List thrusters: const[]}) : 
        super(situation, length, width, position, thrusters: thrusters, initialAngle: initialAngle) {
  }
  
  Box2DShip target;
  
  /**
   * The current AI mode in charge of the ship. Examples: "steer towards point",
   * "stop", "run away", "face other ship", 
   *  
   * If [:null:], the ship is in manual mode.
   */
  ShipBrainMode brainMode;
  
  void applyBrain() {
    if (brainMode != null) {
      brainMode.control(this, target, situation);
    }
  }
}

class Thruster {
  final Vector2 localPosition;
  final Vector2 maxForce;
  Thruster(num x, num y, num maxForwardThrust, num maxLateralThrust) :
    localPosition = new Vector2(x.toDouble(), y.toDouble()),
    maxForce = 
        new Vector2(maxForwardThrust.toDouble(), maxLateralThrust.toDouble()); 
}
