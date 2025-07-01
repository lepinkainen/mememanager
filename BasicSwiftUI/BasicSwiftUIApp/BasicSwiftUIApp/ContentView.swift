import SwiftUI

struct ContentView: View {
    @State private var textInput: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Enter text here", text: $textInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Print Text") {
                print(textInput)
            }
            .padding()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}