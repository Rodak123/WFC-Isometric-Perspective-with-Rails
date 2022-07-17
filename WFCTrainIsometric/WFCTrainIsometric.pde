
Tile[] tiles;
float tileSize;

float tileScale = 3;
float scaledTileSize;

Cell[] cells;
PVector[] cellPositions;

int SIZE = 16;

int PERFRAME = 1;
int iterations = 0;

boolean collapsed;

ArrayList<Cell> order;

void setup() {
  size(800, 800, P2D);

  order = new ArrayList<Cell>();

  tileSize = width/ (float)SIZE - (1/(float)SIZE); // for fixing stroke
  tiles = getTiles();

  cells = new Cell[SIZE*SIZE];
  
  scaledTileSize = tileSize * tileScale;
  
  cellPositions = new PVector[cells.length];
  for (int i=0; i<SIZE; i++) {
    for (int j=0; j<SIZE; j++) {
      int index = i + j * SIZE;
      cellPositions[index] = toScreenCoords(i,j,tileSize).sub(scaledTileSize*0.5,0);
    }
  }

  startOver();
}

Tile[] getTiles() {
  ArrayList<Tile> tiles = new ArrayList<Tile>();

  addTile(tiles, "grass", "GGG,GGG,GGG,GGG");

  addTile(tiles, "rail_straight", "GGG,GRG,GGG,GRG");
  addTile(tiles, "rail_corner", "GGG,GRG,GRG,GGG");
  addTile(tiles, "rail_cross", "GRG,GRG,GRG,GRG");

  Tile[] tilesArr = new Tile[tiles.size()];
  for (int i=0; i<tilesArr.length; i++)
    tilesArr[i] = tiles.get(i);

  for (Tile tile : tilesArr)
    tile.analyze(tilesArr);

  return tilesArr;
}

void addTile(ArrayList<Tile> tiles, String imgPath, String edges) {
  Tile tile = new Tile(imgPath, edges);
  tiles.add(tile);
  for (int i=1; i<4; i++)
    tiles.add(tile.rotate(i));
}

void draw() {
  background(0);
  
  translate(width*0.5,height*0.25);
  
  if (!collapsed) {
    if (PERFRAME == -1) {
      do {
        updateCells();
      } while (!collapsed);
      return;
    }
    for (int i=0; i<PERFRAME; i++)
      updateCells();
  }
  imageMode(CORNER);
  for (int i=0; i<SIZE; i++) {
    for (int j=0; j<SIZE; j++) {
      int index = i + j * SIZE;
      Cell cell = cells[index];
      PVector cellPosition = cellPositions[index];
      if (cell.collapsed) {
        noTint();
        image(tiles[cell.options[0]].img, cellPosition.x, cellPosition.y, scaledTileSize,scaledTileSize);
      } else {
        tint(255, 255/(float)cell.options.length);
        for (int o=0; o<cell.options.length; o++)
          image(tiles[cell.options[o]].img, cellPosition.x, cellPosition.y, scaledTileSize, scaledTileSize);
      }
    }
  }
}

ArrayList<Cell> getNotCollapsedCells() {
  ArrayList<Cell> notCollapsedCells = new ArrayList<Cell>();
  for (Cell cell : cells)
    if (!cell.collapsed)
      notCollapsedCells.add(cell);
  return notCollapsedCells;
}

ArrayList<Cell> getLeastEntropyCells(ArrayList<Cell> notCollapsedCells) {
  int leastEntropy = tiles.length;
  for (Cell cell : notCollapsedCells)
    if (leastEntropy > cell.options.length)
      leastEntropy = cell.options.length;

  ArrayList<Cell> leastEntropyCells = new ArrayList<Cell>();
  for (Cell cell : notCollapsedCells)
    if (leastEntropy == cell.options.length)
      leastEntropyCells.add(cell);
  return leastEntropyCells;
}

void startOver() {
  order.clear();
  collapsed = false;
  for (int i=0; i<cells.length; i++) {
    cells[i] = new Cell();
  }
}

int[] allOptions() {
  int[] options = new int[tiles.length];
  for (int i=0; i<options.length; i++)
    options[i] = i;
  return options;
}

void checkValid(IntList options, IntList valid) {
  for (int i=options.size()-1; i>=0; i--) {
    int option = options.get(i);
    if (!valid.hasValue(option))
      options.remove(i);
  }
}

String listToString(IntList list) {
  String str = "[ ";
  for (int i=0; i<list.size(); i++) {
    str += list.get(i);
    if (i < list.size()-1)
      str += " , ";
  }
  str += " ]";
  return str;
}

void updateCells() {
  ArrayList<Cell> notCollapsedCells = getNotCollapsedCells();

  if (notCollapsedCells.size() == 0) {
    collapsed = true;
    println("Total Iterations: " + iterations);
    return; // all collapsed / done
  }
  if (iterations % 100 == 0 && iterations != 0)
    println("Iterations: " + iterations);
  iterations++;

  ArrayList<Cell> leastEntropyCells = getLeastEntropyCells(notCollapsedCells);

  Cell collapsing = leastEntropyCells.get(floor(random(leastEntropyCells.size())));

  if (collapsing.options.length == 0) {
    startOver();
    return;
    // got stuck
  }

  collapsing.collapsed = true;
  collapsing.options = new int[]{collapsing.options[floor(random(collapsing.options.length))]};
  order.add(collapsing);

  Cell[] nextCells = new Cell[cells.length];
  for (int i=0; i<SIZE; i++) {
    for (int j=0; j<SIZE; j++) {
      int index = i + j * SIZE;
      if (cells[index].collapsed) {
        nextCells[index] = cells[index];
      } else {
        IntList options = new IntList(allOptions());

        // UP
        if (j > 0) {
          Cell other = cells[i + (j-1) * SIZE];
          IntList validOptions = new IntList();
          for (int option : other.options) {
            int[] valid = tiles[option].down;
            for (int validOption : valid)
              if (!validOptions.hasValue(validOption))
                validOptions.append(validOption);
          }
          checkValid(options, validOptions);
        }

        // RIGHT
        if (i < SIZE-1) {
          Cell other = cells[(i+1) + j * SIZE];
          IntList validOptions = new IntList();
          for (int option : other.options) {
            int[] valid = tiles[option].left;
            for (int validOption : valid)
              if (!validOptions.hasValue(validOption))
                validOptions.append(validOption);
          }
          checkValid(options, validOptions);
        }

        // DOWN
        if (j < SIZE-1) {
          Cell other = cells[i + (j+1) * SIZE];
          IntList validOptions = new IntList();
          for (int option : other.options) {
            int[] valid = tiles[option].up;
            for (int validOption : valid)
              if (!validOptions.hasValue(validOption))
                validOptions.append(validOption);
          }
          checkValid(options, validOptions);
        }

        // LEFT
        if (i > 0) {
          Cell other = cells[(i-1) + j * SIZE];
          IntList validOptions = new IntList();
          for (int option : other.options) {
            int[] valid = tiles[option].right;
            for (int validOption : valid)
              if (!validOptions.hasValue(validOption))
                validOptions.append(validOption);
          }
          checkValid(options, validOptions);
        }
        nextCells[index] = new Cell(options.array());
      }
    }
  }

  cells = nextCells;
}

// converts array indexies (0,1) to coords on screen aligned by the isometric grid
PVector toScreenCoords(float x, float y, float size) {
  PVector i = new PVector(1.0, 0.5);
  PVector j = new PVector(-1.0, 0.5);
  PVector iso = new PVector();
  iso.x = (x * i.x * 0.5 * size + y * j.x * 0.5 * size);
  iso.y = (x * i.y * 0.5 * size + y * j.y * 0.5 * size);
  return iso;
}
