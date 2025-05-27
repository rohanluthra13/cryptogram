import SwiftUI

struct WeeklySnapshot: View {
    @Environment(\.typography) private var typography
    @EnvironmentObject private var viewModel: PuzzleViewModel
    @Binding var navigateToPuzzle: Bool
    
    enum PuzzleStatus {
        case incomplete
        case completed
        case failed
    }
    
    // Get last 7 days including today
    private var lastSevenDays: [(date: Date, dayName: String, dateStr: String)] {
        let calendar = Calendar.current
        let today = Date()
        
        // Generate last 7 days (today and 6 days before)
        return (0..<7).compactMap { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                return nil
            }
            
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEE" // Mon, Tue, etc.
            let dayName = dayFormatter.string(from: date)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d" // May 26
            let dateStr = dateFormatter.string(from: date)
            
            return (date, dayName, dateStr)
        } // No reverse - newest (today) first on left
    }
    
    // Get puzzle status for a given date
    private func getStatus(for date: Date) -> PuzzleStatus {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: date)
        let key = "dailyPuzzleProgress-\(dateStr)"
        
        if let data = UserDefaults.standard.data(forKey: key),
           let progress = try? JSONDecoder().decode(DailyPuzzleProgress.self, from: data) {
            if progress.isCompleted {
                return .completed
            } else if progress.mistakeCount >= 3 {
                return .failed
            }
        }
        return .incomplete
    }
    
    private func statusIcon(for status: PuzzleStatus) -> some View {
        Group {
            switch status {
            case .incomplete, .failed:
                Image(systemName: "square")
                    .font(.system(size: 16))
                    .foregroundColor(CryptogramTheme.Colors.text.opacity(0.3))
            case .completed:
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#01780F").opacity(0.5))
            }
        }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                ForEach(Array(lastSevenDays.enumerated()), id: \.element.date) { index, item in
                    let status = getStatus(for: item.date)
                    
                    Button(action: {
                        viewModel.loadDailyPuzzle(for: item.date)
                        navigateToPuzzle = true
                    }) {
                        VStack(spacing: 8) {
                            // Status icon
                            statusIcon(for: status)
                                .frame(height: 20)
                            
                            // Day of week
                            Text(item.dayName)
                                .font(typography.caption)
                                .foregroundColor(CryptogramTheme.Colors.text)
                            
                            // Date
                            Text(item.dateStr)
                                .font(typography.caption)
                                .foregroundColor(CryptogramTheme.Colors.text.opacity(0.6))
                        }
                        .padding(.bottom, 8) // Add padding at bottom
                        .frame(width: 75, height: 85)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(
                                    CryptogramTheme.Colors.border.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .id(index)
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 95)
        .onAppear {
            // Scroll to the first item (newest date)
            proxy.scrollTo(0, anchor: .leading)
        }
        }
        .padding(.vertical, 12)
    }
}

#Preview {
    @Previewable @State var navigate = false
    WeeklySnapshot(navigateToPuzzle: $navigate)
        .environmentObject(PuzzleViewModel())
        .background(CryptogramTheme.Colors.background)
}