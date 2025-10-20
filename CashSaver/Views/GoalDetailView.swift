import SwiftUI
import CoreData

struct GoalDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var goal: SavingGoal
    
    @State private var showingAddDeposit = false
    @State private var depositAmount = ""
    @State private var depositNote = ""
    
    var progress: Double {
        guard goal.targetAmount > 0 else { return 0 }
        return min(goal.currentAmount / goal.targetAmount, 1.0)
    }
    
    var deposits: [Deposit] {
        (goal.deposits?.allObjects as? [Deposit] ?? [])
            .sorted { ($0.date ?? Date()) > ($1.date ?? Date()) }
    }
    
    var body: some View {
        List {
            Section(header: Text("Progress")) {
                VStack(spacing: 16) {
                    CircularProgressView(progress: progress)
                        .frame(height: 200)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Current")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("$\(goal.currentAmount, specifier: "%.2f")")
                                .font(.headline)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Target")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("$\(goal.targetAmount, specifier: "%.2f")")
                                .font(.headline)
                        }
                    }
                    
                    if !goal.isCompleted {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Daily Goal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("$\(goal.dailyAmount, specifier: "%.2f")")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.vertical)
            }
            
            if !goal.isCompleted {
                Section {
                    Button(action: { showingAddDeposit = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Deposit")
                        }
                    }
                }
            }
            
            Section(header: Text("History")) {
                if deposits.isEmpty {
                    Text("No deposits yet")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(deposits, id: \.id) { deposit in
                        HStack {
                            VStack(alignment: .leading) {
                                Text("$\(deposit.amount, specifier: "%.2f")")
                                    .font(.headline)
                                if let note = deposit.note, !note.isEmpty {
                                    Text(note)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if let date = deposit.date {
                                Text(date, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteDeposit)
                }
            }
        }
        .navigationTitle(goal.title ?? "")
        .sheet(isPresented: $showingAddDeposit) {
            AddDepositSheet(goal: goal)
        }
    }
    
    private func deleteDeposit(at offsets: IndexSet) {
        withAnimation {
            offsets.map { deposits[$0] }.forEach { deposit in
                goal.currentAmount -= deposit.amount
                viewContext.delete(deposit)
            }
            
            recalculateDailyAmount()
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Error deleting deposit: \(nsError)")
            }
        }
    }
    
    private func recalculateDailyAmount() {
        let calendar = Calendar.current
        guard let end = goal.endDate else { return }
        
        let days = calendar.dateComponents([.day], from: Date(), to: end).day ?? 1
        let remainingAmount = goal.targetAmount - goal.currentAmount
        
        if days > 0 && remainingAmount > 0 {
            goal.dailyAmount = remainingAmount / Double(days)
        } else {
            goal.dailyAmount = 0
        }
    }
}

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 20)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
            
            VStack {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 48, weight: .bold))
                Text("Complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct AddDepositSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var goal: SavingGoal
    
    @State private var amount = ""
    @State private var note = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Deposit Details")) {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    TextField("Note (optional)", text: $note)
                }
                
                Section {
                    Button("Add Deposit") {
                        addDeposit()
                    }
                    .disabled(amount.isEmpty)
                }
            }
            .navigationTitle("New Deposit")
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
    
    private func addDeposit() {
        guard let depositAmount = Double(amount), depositAmount > 0 else { return }
        
        let deposit = Deposit(context: viewContext)
        deposit.id = UUID()
        deposit.amount = depositAmount
        deposit.date = Date()
        deposit.note = note.isEmpty ? nil : note
        deposit.goal = goal
        
        goal.currentAmount += depositAmount
        
        if goal.currentAmount >= goal.targetAmount {
            goal.isCompleted = true
            goal.dailyAmount = 0
        } else {
            recalculateDailyAmount()
        }
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            let nsError = error as NSError
            print("Error adding deposit: \(nsError)")
        }
    }
    
    private func recalculateDailyAmount() {
        let calendar = Calendar.current
        guard let end = goal.endDate else { return }
        
        let days = calendar.dateComponents([.day], from: Date(), to: end).day ?? 1
        let remainingAmount = goal.targetAmount - goal.currentAmount
        
        if days > 0 && remainingAmount > 0 {
            goal.dailyAmount = remainingAmount / Double(days)
        } else {
            goal.dailyAmount = 0
        }
    }
}


