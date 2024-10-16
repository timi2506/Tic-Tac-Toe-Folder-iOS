import SwiftUI

struct TicTacToeView: View {
    @State private var board: [[String]] = Array(repeating: Array(repeating: "", count: 3), count: 3)
    @State private var currentPlayer = "X"
    @State private var gameResult: String?
    @State private var showAlert = false
    @State private var showFileManager = false // New state to control FileManagerView presentation
    @Environment(\.colorScheme) var colorScheme // Get current color scheme

    var body: some View {
        VStack {
            Text("Tic-Tac-Toe")
                .font(.largeTitle)
                .padding(.bottom, 20)
                .onTapGesture(count: 3) { // Detect triple tap
                    showFileManager = true
                }
            
            // Game Board Grid
            VStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 10) {
                        ForEach(0..<3, id: \.self) { col in
                            Button(action: {
                                handleTap(row: row, col: col)
                            }) {
                                Text(board[row][col])
                                    .font(.system(size: 50))
                                    .frame(width: 80, height: 80)
                                    .background(Color.gray.opacity(0.2))
                                    .foregroundColor(board[row][col] == "X" || board[row][col] == "O" ? (colorScheme == .dark ? Color.white : Color.black) : Color.clear) // Change color based on player and color scheme
                            }
                            .disabled(board[row][col] != "" || gameResult != nil) // Disable if already tapped or game over
                        }
                    }
                }
            }
            .padding()
            
            // Reset Button
            Button(action: resetGame) {
                Text("Reset Game")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Game Over"),
                message: Text(gameResult ?? ""),
                dismissButton: .default(Text("OK"), action: resetGame)
            )
        }
        .sheet(isPresented: $showFileManager) {
            FileManagerView() // Present FileManagerView when triple-tap detected
        }
    }
    
    private func handleTap(row: Int, col: Int) {
        // Mark the current cell with the current player's symbol
        if board[row][col] == "" {
            board[row][col] = currentPlayer
            // Check for win or draw
            if checkWin(for: currentPlayer) {
                gameResult = "\(currentPlayer) Wins!"
                showAlert = true
            } else if checkDraw() {
                gameResult = "It's a Draw!"
                showAlert = true
            } else {
                // Switch player
                currentPlayer = currentPlayer == "X" ? "O" : "X"
            }
        }
    }
    
    private func checkWin(for player: String) -> Bool {
        // Check rows and columns
        for i in 0..<3 {
            if board[i][0] == player && board[i][1] == player && board[i][2] == player {
                return true
            }
            if board[0][i] == player && board[1][i] == player && board[2][i] == player {
                return true
            }
        }
        // Check diagonals
        if board[0][0] == player && board[1][1] == player && board[2][2] == player {
            return true
        }
        if board[0][2] == player && board[1][1] == player && board[2][0] == player {
            return true
        }
        return false
    }
    
    private func checkDraw() -> Bool {
        // Check if there are no empty cells left and no winner
        return board.joined().allSatisfy { $0 != "" }
    }
    
    private func resetGame() {
        board = Array(repeating: Array(repeating: "", count: 3), count: 3)
        currentPlayer = "X"
        gameResult = nil
    }
}

struct TicTacToeView_Previews: PreviewProvider {
    static var previews: some View {
        TicTacToeView()
            .preferredColorScheme(.dark) // Preview in dark mode
        TicTacToeView()
            .preferredColorScheme(.light) // Preview in light mode
    }
}
