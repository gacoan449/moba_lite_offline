enum MobaPhase { loading, laning, objective, siege, finished }

class TeamState {
  int kills = 0;
  int towers = 0;
  double nexusHp = 5000;
  bool hasDrakeBuff = false;
  bool hasTurtleShield = false;
}

class MobaMatchState {
  MobaPhase phase = MobaPhase.loading;
  double time = 0;
  final TeamState blue = TeamState();
  final TeamState red = TeamState();

  void update(double dt) {
    time += dt;
    phase = time < 150
        ? MobaPhase.laning
        : time < 480
            ? MobaPhase.objective
            : time < 720
                ? MobaPhase.siege
                : MobaPhase.siege;
  }

  bool get turtleAvailable => time >= 180 && time <= 330;
  bool get drakeAvailable => time >= 480;
  bool get matchOver => blue.nexusHp <= 0 || red.nexusHp <= 0;
}