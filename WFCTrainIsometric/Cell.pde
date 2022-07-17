class Cell {

  int[] options;
  boolean collapsed;

  Cell() {
    this(allOptions());
  }

  Cell(int[] options) {
    this.options = options;
    collapsed = false;
  }
}
