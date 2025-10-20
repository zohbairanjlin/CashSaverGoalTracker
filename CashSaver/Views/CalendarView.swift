import SwiftUI
import CoreData

struct CalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SavingGoal.createdAt, ascending: false)],
        animation: .default)
    private var goals: FetchedResults<SavingGoal>
    
    @State private var selectedDate = Date()
    @State private var selectedGoal: SavingGoal?
    
    private var activeGoals: [SavingGoal] {
        goals.filter { !$0.isCompleted }
    }
    
    private func dailyRequiredForGoal(_ goal: SavingGoal, on date: Date) -> Double {
        let calendar = Calendar.current
        guard let startDate = goal.startDate, let endDate = goal.endDate else { return 0 }
        
        if calendar.isDate(date, inSameDayAs: startDate) || (date >= startDate && date <= endDate) {
            return goal.dailyAmount
        }
        return 0
    }
    
    private func depositedForGoal(_ goal: SavingGoal, on date: Date) -> Double {
        let calendar = Calendar.current
        guard let deposits = goal.deposits?.allObjects as? [Deposit] else { return 0 }
        
        return deposits
            .filter { deposit in
                guard let depositDate = deposit.date else { return false }
                return calendar.isDate(depositDate, inSameDayAs: date)
            }
            .reduce(0) { $0 + $1.amount }
    }
    
    private func dateStatus(for date: Date, goal: SavingGoal) -> DateStatus {
        let calendar = Calendar.current
        guard let startDate = goal.startDate, let endDate = goal.endDate else { return .none }
        
        let dateOnly = calendar.startOfDay(for: date)
        let startOnly = calendar.startOfDay(for: startDate)
        let endOnly = calendar.startOfDay(for: endDate)
        
        if dateOnly < startOnly || dateOnly > endOnly {
            return .none
        }
        
        let required = dailyRequiredForGoal(goal, on: date)
        let deposited = depositedForGoal(goal, on: date)
        
        if required > 0 {
            if deposited >= required {
                return .completed
            } else {
                return .incomplete
            }
        }
        
        return .none
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if !activeGoals.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(activeGoals, id: \.id) { goal in
                                GoalSelectorButton(
                                    goal: goal,
                                    isSelected: selectedGoal?.id == goal.id
                                ) {
                                    selectedGoal = goal
                                }
                            }
                        }
                        .padding()
                    }
                    .background(Color.secondary.opacity(0.1))
                    
                    Divider()
                }
                
                if let goal = selectedGoal {
                    ScrollView {
                        VStack(spacing: 0) {
                            CustomCalendarView(
                                selectedDate: $selectedDate,
                                goal: goal,
                                dateStatus: { date in dateStatus(for: date, goal: goal) }
                            )
                            .padding()
                            
                            Divider()
                            
                            VStack(spacing: 20) {
                                VStack(spacing: 12) {
                                    HStack {
                                        Text(selectedDate, style: .date)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                        Spacer()
                                    }
                                    
                                    let required = dailyRequiredForGoal(goal, on: selectedDate)
                                    let deposited = depositedForGoal(goal, on: selectedDate)
                                    let remaining = max(0, required - deposited)
                                    
                                    if required > 0 {
                                        VStack(spacing: 8) {
                                            HStack {
                                                Text("Daily Target:")
                                                    .foregroundColor(.secondary)
                                                Spacer()
                                                Text(String(format: "$%.2f", required))
                                                    .fontWeight(.semibold)
                                            }
                                            
                                            HStack {
                                                Text("Deposited:")
                                                    .foregroundColor(.secondary)
                                                Spacer()
                                                Text(String(format: "$%.2f", deposited))
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(deposited >= required ? .green : .red)
                                            }
                                            
                                            if remaining > 0 {
                                                HStack {
                                                    Text("Still Need:")
                                                        .foregroundColor(.secondary)
                                                    Spacer()
                                                    Text(String(format: "$%.2f", remaining))
                                                        .fontWeight(.bold)
                                                        .foregroundColor(.orange)
                                                }
                                            } else if deposited > 0 {
                                                HStack {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(.green)
                                                    Text("Daily Goal Completed!")
                                                        .foregroundColor(.green)
                                                        .fontWeight(.semibold)
                                                    Spacer()
                                                }
                                            }
                                        }
                                        .padding()
                                        .background(Color.secondary.opacity(0.1))
                                        .cornerRadius(12)
                                    }
                                }
                                .padding()
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Deposits")
                                        .font(.headline)
                                        .padding(.horizontal)
                                    
                                    let deposits = getDepositsForSelectedDate(goal: goal)
                                    
                                    if deposits.isEmpty {
                                        Text("No deposits for this day")
                                            .foregroundColor(.secondary)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                    } else {
                                        ForEach(deposits, id: \.id) { deposit in
                                            VStack(alignment: .leading, spacing: 8) {
                                                HStack {
                                                    Text("Amount:")
                                                    Spacer()
                                                    Text(String(format: "$%.2f", deposit.amount))
                                                        .fontWeight(.semibold)
                                                }
                                                if let note = deposit.note, !note.isEmpty {
                                                    Text(note)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            .padding()
                                            .background(Color.secondary.opacity(0.1))
                                            .cornerRadius(12)
                                            .padding(.horizontal)
                                        }
                                    }
                                }
                                .padding(.bottom)
                            }
                        }
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("Select a goal to view calendar")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Calendar")
            .onAppear {
                if selectedGoal == nil && !activeGoals.isEmpty {
                    selectedGoal = activeGoals.first
                }
            }
        }
    }
    
    private func getDepositsForSelectedDate(goal: SavingGoal) -> [Deposit] {
        let calendar = Calendar.current
        guard let deposits = goal.deposits?.allObjects as? [Deposit] else { return [] }
        
        return deposits.filter { deposit in
            guard let date = deposit.date else { return false }
            return calendar.isDate(date, inSameDayAs: selectedDate)
        }
    }
}

enum DateStatus {
    case none
    case completed
    case incomplete
}

struct GoalSelectorButton: View {
    let goal: SavingGoal
    let isSelected: Bool
    let action: () -> Void
    
    var progress: Double {
        guard goal.targetAmount > 0 else { return 0 }
        return min(goal.currentAmount / goal.targetAmount, 1.0)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(goal.title ?? "")
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
                
                HStack(spacing: 4) {
                    Text(String(format: "$%.0f", goal.currentAmount))
                    Text("/")
                    Text(String(format: "$%.0f", goal.targetAmount))
                }
                .font(.caption)
                .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(isSelected ? .white : .blue)
            }
            .padding()
            .frame(width: 160)
            .background(isSelected ? Color.blue : Color.secondary.opacity(0.2))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CustomCalendarView: View {
    @Binding var selectedDate: Date
    let goal: SavingGoal
    let dateStatus: (Date) -> DateStatus
    
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        
        var dates: [Date] = []
        
        var currentDate = monthFirstWeek.start
        while currentDate < monthInterval.end {
            dates.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
            
            if dates.count > 42 { break }
        }
        
        return dates
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                }
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                
                ForEach(daysInMonth, id: \.self) { date in
                    let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                    let isCurrentMonth = calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
                    let isToday = calendar.isDateInToday(date)
                    let status = dateStatus(date)
                    
                    Button(action: {
                        selectedDate = date
                    }) {
                        Text("\(calendar.component(.day, from: date))")
                            .font(.body)
                            .fontWeight(isToday ? .bold : .regular)
                            .foregroundColor(isSelected ? .white : (isCurrentMonth ? .primary : .secondary))
                            .frame(width: 36, height: 36)
                            .background(
                                ZStack {
                                    if isSelected {
                                        Circle()
                                            .fill(Color.blue)
                                    } else {
                                        switch status {
                                        case .completed:
                                            Circle()
                                                .fill(Color.green.opacity(0.3))
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.green, lineWidth: 2)
                                                )
                                        case .incomplete:
                                            Circle()
                                                .fill(Color.red.opacity(0.3))
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.red, lineWidth: 2)
                                                )
                                        case .none:
                                            if isToday {
                                                Circle()
                                                    .stroke(Color.blue, lineWidth: 2)
                                            }
                                        }
                                    }
                                }
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green.opacity(0.3))
                        .overlay(Circle().stroke(Color.green, lineWidth: 2))
                        .frame(width: 20, height: 20)
                    Text("Completed")
                        .font(.caption)
                }
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.red.opacity(0.3))
                        .overlay(Circle().stroke(Color.red, lineWidth: 2))
                        .frame(width: 20, height: 20)
                    Text("Incomplete")
                        .font(.caption)
                }
            }
            .foregroundColor(.secondary)
        }
    }
    
    private func previousMonth() {
        guard let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) else { return }
        currentMonth = newMonth
    }
    
    private func nextMonth() {
        guard let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) else { return }
        currentMonth = newMonth
    }
}
