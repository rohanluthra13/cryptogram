import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var viewModel: PuzzleViewModel
    @StateObject private var dailyPuzzleManager = DailyPuzzleManager()
    @Environment(\.typography) private var typography
    @State private var currentDate: Date
    @Binding var showCalendar: Bool
    var onSelectDate: (Date) -> Void
    
    init(showCalendar: Binding<Bool>, onSelectDate: @escaping (Date) -> Void) {
        self._showCalendar = showCalendar
        self.onSelectDate = onSelectDate
        // Initialize to the first day of current month
        let calendar = Calendar.current
        let now = Date()
        self._currentDate = State(initialValue: calendar.dateInterval(of: .month, for: now)?.start ?? now)
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]
    private let minDate = DateComponents(calendar: .current, year: 2025, month: 4, day: 23).date!
    private let minMonth = DateComponents(calendar: .current, year: 2025, month: 4, day: 1).date!
    
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday
        return cal
    }
    
    private var monthStart: Date {
        calendar.dateInterval(of: .month, for: currentDate)?.start ?? Date()
    }
    
    private var monthDays: [Date?] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: monthStart),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthStart).weekday else {
            return []
        }
        
        // Calculate offset for first day of month
        let offset = (firstWeekday + 5) % 7 // Convert to Monday-based
        
        // Create array with nil padding for empty cells
        var days: [Date?] = Array(repeating: nil, count: offset)
        
        // Add actual days
        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                days.append(date)
            }
        }
        
        // Pad to complete last week if needed
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    private func isDateAvailable(_ date: Date) -> Bool {
        let today = Date()
        return date >= minDate && date <= today
    }
    
    private func isPuzzleCompleted(_ date: Date) -> Bool {
        let dateString = formatDateForKey(date)
        if let data = UserDefaults.standard.data(forKey: "dailyPuzzleProgress-\(dateString)"),
           let progress = try? JSONDecoder().decode(DailyPuzzleProgress.self, from: data) {
            return progress.isCompleted
        }
        return false
    }
    
    private func formatDateForKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func canNavigateToPreviousMonth() -> Bool {
        // Get the start of the current displayed month
        let currentMonthStart = calendar.dateInterval(of: .month, for: currentDate)?.start ?? currentDate
        
        // Get the start of the minimum allowed month (April 2025)
        let minMonthStart = calendar.dateInterval(of: .month, for: minMonth)?.start ?? minMonth
        
        // Can navigate back if current month is after the minimum month
        let canNavigate = currentMonthStart > minMonthStart
        return canNavigate
    }
    
    private func canNavigateToNextMonth() -> Bool {
        // Get the start of the current displayed month
        let currentMonthStart = calendar.dateInterval(of: .month, for: currentDate)?.start ?? currentDate
        
        // Get the start of today's month
        let todayMonthStart = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        
        // Can navigate forward if current displayed month is before today's month
        return currentMonthStart < todayMonthStart
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Month navigation
            HStack {
                Button(action: {
                    withAnimation {
                        currentDate = calendar.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(canNavigateToPreviousMonth() ? Color("Text") : Color("Text").opacity(0.3))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .disabled(!canNavigateToPreviousMonth())
                
                Spacer()
                
                Text(dateFormatter.string(from: currentDate))
                    .font(.system(size: 15, weight: .regular, design: typography.fontOption.design))
                    .foregroundColor(Color("Text"))
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(canNavigateToNextMonth() ? Color("Text") : Color("Text").opacity(0.3))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .disabled(!canNavigateToNextMonth())
            }
            .padding(.horizontal)
            
            // Calendar grid
            VStack(spacing: 0) {
                // Day labels
                HStack(spacing: 0) {
                    ForEach(dayLabels, id: \.self) { label in
                        Text(label)
                            .font(typography.caption)
                            .foregroundColor(Color("Text"))
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.bottom, 8)
                .overlay(
                    Rectangle()
                        .fill(Color("Border"))
                        .frame(height: 1),
                    alignment: .bottom
                )
                
                // Calendar days
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 15) {
                    ForEach(Array(monthDays.enumerated()), id: \.offset) { _, date in
                        if let date = date {
                            DayCell(
                                date: date,
                                isAvailable: isDateAvailable(date),
                                isCompleted: isPuzzleCompleted(date),
                                onTap: {
                                    if isDateAvailable(date) {
                                        showCalendar = false
                                        onSelectDate(date)
                                    }
                                }
                            )
                        } else {
                            Color.clear
                                .frame(height: 50)
                        }
                    }
                }
            }
            .padding()
        }
        .padding(.vertical)
        .frame(width: 350)
    }
}

struct DayCell: View {
    @Environment(\.typography) private var typography
    let date: Date
    let isAvailable: Bool
    let isCompleted: Bool
    let onTap: () -> Void
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                if isCompleted {
                    Image(systemName: "checkmark")
                        .foregroundColor(isAvailable ? Color(hex: "#01780F").opacity(0.5) : Color("Text").opacity(0.3))
                        .font(.system(size: 16))
                } else {
                    Image(systemName: "square")
                        .foregroundColor(isAvailable ? Color("Text") : Color("Text").opacity(0.3))
                        .font(.system(size: 18))
                }
                
                Text(dayNumber)
                    .font(typography.caption)
                    .foregroundColor(isAvailable ? Color("Text") : Color("Text").opacity(0.3))
            }
            .frame(height: 50)
        }
        .disabled(!isAvailable)
    }
}