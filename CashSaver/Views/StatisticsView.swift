import SwiftUI
import CoreData

struct StatisticsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SavingGoal.createdAt, ascending: false)],
        animation: .default)
    private var goals: FetchedResults<SavingGoal>
    
    var totalSaved: Double {
        goals.reduce(0) { $0 + $1.currentAmount }
    }
    
    var totalTarget: Double {
        goals.reduce(0) { $0 + $1.targetAmount }
    }
    
    var completedGoals: Int {
        goals.filter { $0.isCompleted }.count
    }
    
    var activeGoals: Int {
        goals.filter { !$0.isCompleted }.count
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 16) {
                        StatCard(title: "Total Saved", value: String(format: "$%.2f", totalSaved), color: .green)
                        StatCard(title: "Total Target", value: String(format: "$%.2f", totalTarget), color: .blue)
                        StatCard(title: "Completed Goals", value: "\(completedGoals)", color: .purple)
                        StatCard(title: "Active Goals", value: "\(activeGoals)", color: .orange)
                    }
                    .padding()
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Saving Tips")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ForEach(savingTips, id: \.self) { tip in
                            TipCard(tip: tip)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("Statistics")
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
            }
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct TipCard: View {
    let tip: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
                .font(.title2)
            
            Text(tip)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}

let savingTips = [
    "Set specific, measurable goals with clear deadlines to stay motivated.",
    "Automate your savings by setting up automatic transfers to your savings account.",
    "Track your spending to identify areas where you can cut back and save more.",
    "Start small and gradually increase your savings amount as you get comfortable.",
    "Use the 50/30/20 rule: 50% needs, 30% wants, 20% savings and debt repayment.",
    "Reduce unnecessary subscriptions and redirect that money to your savings goals.",
    "Cook at home more often instead of eating out to save significant amounts.",
    "Challenge yourself with no-spend days or weeks to boost your savings.",
    "Sell items you no longer need and put the proceeds toward your goals.",
    "Take advantage of cashback apps and rewards programs to maximize savings."
]

