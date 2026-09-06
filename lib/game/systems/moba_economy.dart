class PlayerEconomy {
  double gold;
  double experience;
  int level;
  PlayerEconomy({this.gold = 500, this.experience = 0, this.level = 1});

  void minionLastHit() { gold += 45; experience += 38; _levelCheck(); }
  void sharedMinion() { gold += 12; experience += 24; _levelCheck(); }
  void heroTakedown(double bounty) { gold += bounty; experience += 90; _levelCheck(); }
  void towerAssist() { gold += 90; experience += 55; _levelCheck(); }
  void epicObjective() { gold += 180; experience += 130; _levelCheck(); }

  void tick(double dt) => gold += dt * 1.5;

  void _levelCheck() {
    while (level < 15 && experience >= _xpFor(level + 1)) {
      level++;
    }
  }

  double _xpFor(int targetLevel) => targetLevel * targetLevel * 170;
}