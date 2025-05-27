import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var viewModel: PuzzleViewModel
    @StateObject private var dailyPuzzleManager = DailyPuzzleManager()
    @State private var currentDate = Date()
    @Binding var showCalendar: Bool
    var onSelectDate: (Date) -> Void
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]
    private let minDate = DateComponents(calendar: .current, year: 2025, month: 4, day: 23).date!
    
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
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentDate) ?? Date()
        return previousMonth >= minDate
    }
    
    private func canNavigateToNextMonth() -> Bool {
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? Date()
        let today = Date()
        return calendar.compare(nextMonth, to: today, toGranularity: .month) != .orderedDescending
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Month navigation
            HStack {
                Button(action: {
                    if canNavigateToPreviousMonth() {
                        currentDate = calendar.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(canNavigateToPreviousMonth() ? Color("Text") : Color("Text").opacity(0.3))
                }
                .disabled(!canNavigateToPreviousMonth())
                
                Spacer()
                
                Text(dateFormatter.string(from: currentDate))
                    .font(.headline)
                    .foregroundColor(Color("Text"))
                
                Spacer()
                
                Button(action: {
                    if canNavigateToNextMonth() {
                        currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(canNavigateToNextMonth() ? Color("Text") : Color("Text").opacity(0.3))
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
                            .font(.caption)
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
        .background(Color("Background"))
        .cornerRadius(20)
        .shadow(radius: 10)
    }
}

struct DayCell: View {
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
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(isAvailable ? Color("PrimaryApp") : Color("Text").opacity(0.3))
                        .font(.system(size: 20))
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(isAvailable ? Color("Text") : Color("Text").opacity(0.3))
                        .font(.system(size: 20))
                }
                
                Text(dayNumber)
                    .font(.caption)
                    .foregroundColor(isAvailable ? Color("Text") : Color("Text").opacity(0.3))
            }
            .frame(height: 50)
        }
        .disabled(!isAvailable)
    }
}