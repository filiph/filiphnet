import 'dart:html';

import 'package:slot_machine/slot_machine.dart';

void main() {
  var container = querySelector("#slot_container");
  var resultEl = querySelector("#slot_result");
  RangeInputElement probabilityEl = querySelector("#probability");
  var probabilitySpan = querySelector("#probability_span");
  var startButton = querySelector("#start_button");
  
  num probability = 0.75;
  probabilityEl.onChange.listen((_) {
    probability = probabilityEl.valueAsNumber / 100;
    probabilitySpan.text = "${probabilityEl.value}%";
  });
  
  startButton.onClick.listen((_) {
    container.children.clear();
    resultEl.children.clear();

    var slotMachine = new SlotMachineAnimation.fromProbability(probability);
    // slotMachine.allowCriticalSuccess = false;
    // slotMachine.allowCriticalFailure = false;
    container.append(slotMachine.canvasEl);
    resultEl.append(slotMachine.resultEl);
    slotMachine.roll()
    .then(print);
  });
}

