import SwiftUI
import CoreData

struct GoalsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SavingGoal.createdAt, ascending: false)],
        animation: .default)
    private var goals: FetchedResults<SavingGoal>
    
    @State private var showingAddGoal = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(goals) { goal in
                    NavigationLink(destination: GoalDetailView(goal: goal)) {
                        GoalRowView(goal: goal)
                    }
                }
                .onDelete(perform: deleteGoals)
            }
            .navigationTitle("My Goals")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddGoal = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddGoal) {
                AddGoalView()
            }
        }
    }
    
    private func deleteGoals(offsets: IndexSet) {
        withAnimation {
            offsets.map { goals[$0] }.forEach { goal in
                if let goalId = goal.id {
                    NotificationManager.shared.cancelNotification(for: goalId)
                }
                viewContext.delete(goal)
            }
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Error deleting goal: \(nsError)")
            }
        }
    }
}

struct GoalRowView: View {
    @ObservedObject var goal: SavingGoal
    
    var progress: Double {
        guard goal.targetAmount > 0 else { return 0 }
        return min(goal.currentAmount / goal.targetAmount, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goal.title ?? "")
                    .font(.headline)
                Spacer()
                if goal.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            ProgressView(value: progress)
                .progressViewStyle(.linear)
            
            HStack {
                Text("$\(goal.currentAmount, specifier: "%.2f")")
                Text("/")
                Text("$\(goal.targetAmount, specifier: "%.2f")")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            
            if let endDate = goal.endDate {
                Text("Due: \(endDate, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}


