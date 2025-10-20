import SwiftUI
import CoreData

struct AddGoalView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var targetAmount = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var reminderEnabled = false
    @State private var reminderTime = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Goal Details")) {
                    TextField("Goal Title", text: $title)
                    
                    TextField("Target Amount", text: $targetAmount)
                        .keyboardType(.decimalPad)
                    
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        .onChange(of: startDate) { newValue in
                            if newValue > endDate {
                                endDate = Calendar.current.date(byAdding: .month, value: 1, to: newValue) ?? newValue
                            }
                        }
                    
                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                }
                
                Section(header: Text("Reminder")) {
                    Toggle("Enable Reminder", isOn: $reminderEnabled)
                    
                    if reminderEnabled {
                        DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                }
                
                Section {
                    Button("Create Goal") {
                        createGoal()
                    }
                    .disabled(title.isEmpty || targetAmount.isEmpty)
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func createGoal() {
        guard let amount = Double(targetAmount), amount > 0 else { return }
        
        let newGoal = SavingGoal(context: viewContext)
        newGoal.id = UUID()
        newGoal.title = title
        newGoal.targetAmount = amount
        newGoal.currentAmount = 0
        newGoal.startDate = startDate
        newGoal.endDate = endDate
        newGoal.createdAt = Date()
        newGoal.isCompleted = false
        newGoal.reminderEnabled = reminderEnabled
        
        if reminderEnabled {
            newGoal.reminderTime = reminderTime
        }
        
        calculateDailyAmount(for: newGoal)
        
        do {
            try viewContext.save()
            
            if reminderEnabled {
                NotificationManager.shared.requestAuthorization { granted in
                    if granted, newGoal.id != nil {
                        NotificationManager.shared.scheduleNotification(for: newGoal, at: reminderTime)
                    }
                }
            }
            
            dismiss()
        } catch {
            let nsError = error as NSError
            print("Error creating goal: \(nsError)")
        }
    }
    
    private func calculateDailyAmount(for goal: SavingGoal) {
        let calendar = Calendar.current
        guard let start = goal.startDate, let end = goal.endDate else { return }
        
        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 1
        let remainingAmount = goal.targetAmount - goal.currentAmount
        
        if days > 0 {
            goal.dailyAmount = remainingAmount / Double(days)
        } else {
            goal.dailyAmount = remainingAmount
        }
    }
}
