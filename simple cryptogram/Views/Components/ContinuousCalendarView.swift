import SwiftUI

struct ContinuousCalendarView: View {
    @Environment(PuzzleViewModel.self) private var viewModel
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.typography) private var typography
    @State private var currentMonthIndex: Int
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @Binding var showCalendar: Bool
    var onSelectDate: (Date) -> Void
    
    // Constants
    private let monthWidth: CGFloat = 350
    
    init(showCalendar: Binding<Bool>, onSelectDate: @escaping (Date) -> Void) {
        self._showCalendar = showCalendar
        self.onSelectDate = onSelectDate
        
        // Calculate initial month index based on current date
        let calendar = Calendar.current
        let now = Date()
        let minMonth = DateComponents(calendar: .current, year: 2025, month: 4, day: 1).date!
        
        let components = calendar.dateComponents([.year, .month], from: now)
        let minComponents = calendar.dateComponents([.year, .month], from: minMonth)
        
        let currentYear = components.year ?? 2025
        let currentMonth = components.month ?? 1
        let minYear = minComponents.year ?? 2025
        let minMonthValue = minComponents.month ?? 4
        
        let index = (currentYear - minYear) * 12 + (currentMonth - minMonthValue)
        self._currentMonthIndex = State(initialValue: max(0, index))
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
    
    private var maxMonthIndex: Int {
        let now = Date()
        let components = calendar.dateComponents([.year, .month], from: now)
        let minComponents = calendar.dateComponents([.year, .month], from: minMonth)
        
        guard let year = components.year, let month = components.month,
              let minYear = minComponents.year, let minMonth = minComponents.month else { return 0 }
        
        return (year - minYear) * 12 + (month - minMonth)
    }
    
    private func monthDate(for index: Int) -> Date {
        calendar.date(byAdding: .month, value: index, to: minMonth) ?? minMonth
    }
    
    private func monthDays(for date: Date) -> [Date?] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: date),
              let monthStart = calendar.dateInterval(of: .month, for: date)?.start,
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
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
    
    private var visibleMonthIndices: [Int] {
        // Return indices for current, previous, and next months
        let indices = [currentMonthIndex - 1, currentMonthIndex, currentMonthIndex + 1]
        return indices.filter { $0 >= 0 && $0 <= maxMonthIndex }
    }
    
    var body: some View {
        VStack(spacing: 20) {
                // Navigation header
                HStack {
                    Button(action: {
                        if currentMonthIndex > 0 {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentMonthIndex -= 1
                            }
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(currentMonthIndex > 0 ? Color("Text") : Color("Text").opacity(0.3))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .disabled(currentMonthIndex <= 0)
                    
                    Spacer()
                    
                    Text(dateFormatter.string(from: monthDate(for: currentMonthIndex)))
                        .font(.system(size: 15, weight: .regular, design: typography.fontOption.design))
                        .foregroundColor(Color("Text"))
                    
                    Spacer()
                    
                    Button(action: {
                        if currentMonthIndex < maxMonthIndex {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentMonthIndex += 1
                            }
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(currentMonthIndex < maxMonthIndex ? Color("Text") : Color("Text").opacity(0.3))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .disabled(currentMonthIndex >= maxMonthIndex)
                }
                .padding(.horizontal)
            
            // Calendar container
            ZStack {
                ForEach(visibleMonthIndices, id: \.self) { index in
                    CalendarMonthView(
                        monthDate: monthDate(for: index),
                        monthDays: monthDays(for: monthDate(for: index)),
                        isDateAvailable: isDateAvailable,
                        isPuzzleCompleted: isPuzzleCompleted,
                        onSelectDate: { date in
                            onSelectDate(date)
                        }
                    )
                    .frame(width: monthWidth)
                    .offset(x: CGFloat(index - currentMonthIndex) * monthWidth + dragOffset)
                }
            }
            .frame(width: monthWidth, height: 400, alignment: .center)
            .clipped()
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        isDragging = false
                        
                        // Determine if we should change months based on drag distance
                        let threshold = monthWidth * 0.3
                        
                        if dragOffset > threshold && currentMonthIndex > 0 {
                            // Swipe right - go to previous month
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                currentMonthIndex -= 1
                                dragOffset = 0
                            }
                        } else if dragOffset < -threshold && currentMonthIndex < maxMonthIndex {
                            // Swipe left - go to next month
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                currentMonthIndex += 1
                                dragOffset = 0
                            }
                        } else {
                            // Snap back to current month
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                dragOffset = 0
                            }
                        }
                    }
            )
        }
        .padding(.vertical)
        .frame(width: monthWidth)
    }
}

struct CalendarMonthView: View {
    @Environment(\.typography) private var typography
    @Environment(AppSettings.self) private var appSettings
    let monthDate: Date
    let monthDays: [Date?]
    let isDateAvailable: (Date) -> Bool
    let isPuzzleCompleted: (Date) -> Bool
    let onSelectDate: (Date) -> Void
    
    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Day labels
            HStack(spacing: 0) {
                ForEach(Array(dayLabels.enumerated()), id: \.offset) { _, label in
                    Text(label)
                        .font(.system(size: appSettings.textSize.calendarLabelSize, design: typography.fontOption.design))
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
            .padding(.bottom, 12)
            
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
}

struct DayCell: View {
    @Environment(\.typography) private var typography
    @Environment(AppSettings.self) private var appSettings
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
                ZStack {
                    Color.clear
                        .frame(width: 20, height: 20)

                    if isCompleted {
                        Image(systemName: "checkmark")
                            .foregroundColor(isAvailable ? Color(hex: "#01780F").opacity(0.5) : Color("Text").opacity(0.3))
                            .font(.system(size: 16))
                    } else {
                        Image(systemName: "square")
                            .foregroundColor(isAvailable ? Color("Text") : Color("Text").opacity(0.3))
                            .font(.system(size: 18))
                    }
                }

                Text(dayNumber)
                    .font(.system(size: appSettings.textSize.calendarDaySize, design: typography.fontOption.design))
                    .foregroundColor(isAvailable ? Color("Text") : Color("Text").opacity(0.3))
            }
            .frame(height: 50)
        }
        .disabled(!isAvailable)
    }
}