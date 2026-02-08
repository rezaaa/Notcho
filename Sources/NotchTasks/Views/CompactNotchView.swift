import SwiftUI

struct CompactNotchView: View {
    let taskCount: Int
    let date: Date

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE · MMM d"
        return formatter.string(from: date)
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(dateString)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.75))

            if taskCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "checklist")
                        .font(.system(size: 10, weight: .semibold))
                    Text("\(taskCount)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color.blue.opacity(0.35))
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.black)
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ZStack {
        Color.black
        CompactNotchView(taskCount: 5, date: Date())
    }
}
