import SwiftUI
import LocalAuthentication

struct TicTacToeView: View {
    @State private var board: [[String]] = Array(repeating: Array(repeating: "", count: 3), count: 3)
    @State private var currentPlayer = "X"
    @State private var gameResult: String?
    @State private var showGameResultSheet = false
    @State private var showFileManager = false
    @State private var authenticationFailed = false // For showing the custom alert for authentication failure
    @State private var showAuthAlert = false // For showing custom alert manually
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            Text("Tic-Tac-Toe")
                .font(.largeTitle)
                .padding(.bottom, 20)
                .onTapGesture(count: 3) {
                    authenticateUser()
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
                                    .foregroundColor(board[row][col] == "X" || board[row][col] == "O" ? (colorScheme == .dark ? Color.white : Color.black) : Color.clear)
                            }
                            .disabled(board[row][col] != "" || gameResult != nil)
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
        .sheet(isPresented: $showGameResultSheet) {
            gameResultMenu()
        }
        .sheet(isPresented: $showFileManager) {
            FileManagerView()
        }
        .alert(isPresented: $showAuthAlert) { // This handles the authentication failure alert
            Alert(
                title: Text("Authentication Failed"),
                message: Text("Please try again."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // This menu will be displayed when the game ends
    @ViewBuilder
    private func gameResultMenu() -> some View {
        VStack {
            Text(gameResult ?? "")
                .font(.largeTitle)
                .padding()
            
            HStack {
                Button(action: resetGame) {
                    Text("Reset Game")
                        .font(.headline)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    showGameResultSheet = false
                }) {
                    Text("Cancel")
                        .font(.headline)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding(.top, 20)
        }
    }
    
    private func handleTap(row: Int, col: Int) {
        if board[row][col] == "" {
            board[row][col] = currentPlayer
            if checkWin(for: currentPlayer) {
                gameResult = "\(currentPlayer) Wins!"
                showGameResultSheet = true
            } else if checkDraw() {
                gameResult = "It's a Draw!"
                showGameResultSheet = true
            } else {
                currentPlayer = currentPlayer == "X" ? "O" : "X"
            }
        }
    }
    
    private func checkWin(for player: String) -> Bool {
        for i in 0..<3 {
            if board[i][0] == player && board[i][1] == player && board[i][2] == player {
                return true
            }
            if board[0][i] == player && board[1][i] == player && board[2][i] == player {
                return true
            }
        }
        if board[0][0] == player && board[1][1] == player && board[2][2] == player {
            return true
        }
        if board[0][2] == player && board[1][1] == player && board[2][0] == player {
            return true
        }
        return false
    }
    
    private func checkDraw() -> Bool {
        return board.joined().allSatisfy { $0 != "" }
    }
    
    private func resetGame() {
        board = Array(repeating: Array(repeating: "", count: 3), count: 3)
        currentPlayer = "X"
        gameResult = nil
        showGameResultSheet = false
    }
    
    private func authenticateUser() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Please authenticate to access the File Manager"

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        showFileManager = true
                    } else {
                        showAuthAlert = true
                    }
                }
            }
        } else if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Please authenticate to access the File Manager"

            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        showFileManager = true
                    } else {
                        showAuthAlert = true
                    }
                }
            }
        } else {
            showAuthAlert = true
        }
    }
}

struct TicTacToeView_Previews: PreviewProvider {
    static var previews: some View {
        TicTacToeView()
            .preferredColorScheme(.dark)
        TicTacToeView()
            .preferredColorScheme(.light)
    }
}
