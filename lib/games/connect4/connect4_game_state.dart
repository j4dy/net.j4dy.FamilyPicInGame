import 'dart:math';

/// Represents a cell value on the board.
enum Connect4Cell {
  empty,
  playerA,
  playerB,
}

/// Represents the result of dropping a piece.
enum DropResult {
  ok,
  columnFull,
  gameOver,
}

/// Pure game logic for Connect 4.
class Connect4GameState {
  static const int rows = 6;
  static const int cols = 7;
  static const int winLength = 4;

  final List<List<Connect4Cell>> board;
  Connect4Cell currentPlayer;
  bool _gameOver;

  /// The last move made, for highlighting.
  int? lastRow;
  int? lastCol;

  /// If the game is won, the winning cells.
  List<(int, int)>? winningCells;

  Connect4GameState({
    Connect4Cell firstPlayer = Connect4Cell.playerA,
  })  : board = List.generate(
          rows,
          (_) => List.filled(cols, Connect4Cell.empty),
        ),
        currentPlayer = firstPlayer,
        _gameOver = false;

  /// Reset the game.
  void reset() {
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        board[r][c] = Connect4Cell.empty;
      }
    }
    currentPlayer = Connect4Cell.playerA;
    _gameOver = false;
    lastRow = null;
    lastCol = null;
    winningCells = null;
  }

  bool get isGameOver => _gameOver;

  /// Try to drop a piece in [col] for the current player.
  /// Returns the result, and switches turn if successful.
  DropResult dropInColumn(int col) {
    if (_gameOver) return DropResult.gameOver;
    if (col < 0 || col >= cols) return DropResult.columnFull;

    // Find lowest empty row in this column
    int? targetRow;
    for (var r = rows - 1; r >= 0; r--) {
      if (board[r][col] == Connect4Cell.empty) {
        targetRow = r;
        break;
      }
    }
    if (targetRow == null) return DropResult.columnFull;

    board[targetRow][col] = currentPlayer;
    lastRow = targetRow;
    lastCol = col;

    // Check win
    final winCells = _checkWinAt(targetRow, col);
    if (winCells != null) {
      winningCells = winCells;
      _gameOver = true;
      return DropResult.ok;
    }

    // Check draw
    if (_isBoardFull()) {
      _gameOver = true;
      return DropResult.ok;
    }

    // Switch player
    currentPlayer = (currentPlayer == Connect4Cell.playerA)
        ? Connect4Cell.playerB
        : Connect4Cell.playerA;
    return DropResult.ok;
  }

  bool _isBoardFull() {
    for (var c = 0; c < cols; c++) {
      if (board[0][c] == Connect4Cell.empty) return false;
    }
    return true;
  }

  /// Check if the piece at (row, col) results in a win.
  /// Returns list of winning coordinates if so, null otherwise.
  List<(int, int)>? _checkWinAt(int row, int col) {
    final player = board[row][col];
    if (player == Connect4Cell.empty) return null;

    // Directions: horizontal, vertical, diagonal-down-right, diagonal-down-left
    const dirs = [
      (0, 1),  // horizontal
      (1, 0),  // vertical
      (1, 1),  // diagonal ↘
      (1, -1), // diagonal ↙
    ];

    for (final (dr, dc) in dirs) {
      final cells = <(int, int)>[(row, col)];

      // Positive direction
      var r = row + dr;
      var c = col + dc;
      while (r >= 0 && r < rows && c >= 0 && c < cols && board[r][c] == player) {
        cells.add((r, c));
        r += dr;
        c += dc;
      }

      // Negative direction
      r = row - dr;
      c = col - dc;
      while (r >= 0 && r < rows && c >= 0 && c < cols && board[r][c] == player) {
        cells.add((r, c));
        r -= dr;
        c -= dc;
      }

      if (cells.length >= winLength) {
        return cells;
      }
    }
    return null;
  }

  /// Simple AI: finds the best column to drop in.
  /// Tries to win, then block opponent, then center-preferring heuristic.
  int computeAiMove() {
    final rng = Random();

    // 1. Check if AI can win immediately
    for (var c = 0; c < cols; c++) {
      if (_canDropInColumn(c)) {
        final sim = _simulateDrop(c, currentPlayer);
        if (sim != null) return c;
      }
    }

    // 2. Block opponent's winning move
    final opponent = (currentPlayer == Connect4Cell.playerA)
        ? Connect4Cell.playerB
        : Connect4Cell.playerA;
    for (var c = 0; c < cols; c++) {
      if (_canDropInColumn(c)) {
        final sim = _simulateDrop(c, opponent);
        if (sim != null) return c;
      }
    }

    // 3. Prefer center columns for better position
    final available = <int>[];
    for (var c = 0; c < cols; c++) {
      if (_canDropInColumn(c)) {
        available.add(c);
      }
    }
    if (available.isEmpty) return -1;

    // Sort by distance to center (column 3), prefer center
    available.sort((a, b) {
      final distA = (a - (cols ~/ 2)).abs();
      final distB = (b - (cols ~/ 2)).abs();
      if (distA != distB) return distA.compareTo(distB);
      return rng.nextInt(3) - 1; // random tiebreak
    });

    return available.first;
  }

  bool _canDropInColumn(int col) {
    return col >= 0 && col < cols && board[0][col] == Connect4Cell.empty;
  }

  /// Simulate dropping a piece for [player] in [col].
  /// Returns winning cells if it would be a win, null otherwise.
  List<(int, int)>? _simulateDrop(int col, Connect4Cell player) {
    int? targetRow;
    for (var r = rows - 1; r >= 0; r--) {
      if (board[r][col] == Connect4Cell.empty) {
        targetRow = r;
        break;
      }
    }
    if (targetRow == null) return null;

    board[targetRow][col] = player;
    final win = _checkWinAt(targetRow, col);
    board[targetRow][col] = Connect4Cell.empty;
    return win;
  }
}
