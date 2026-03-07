// Presentation/Components/SpendingCharts.swift
// SpendSnap

import SwiftUI
import Charts

// MARK: - Category Donut Chart

/// Donut chart showing spending distribution by category.
struct CategoryDonutChart: View {
    
    let data: [(name: String, colorHex: String, total: Decimal)]
    let total: Decimal
    
    var body: some View {
        HStack(spacing: 16) {
            // Donut chart
            Chart(data, id: \.name) { item in
                SectorMark(
                    angle: .value("Amount", NSDecimalNumber(decimal: item.total).doubleValue),
                    innerRadius: .ratio(0.6),
                    angularInset: 1.5
                )
                .foregroundStyle(Color(hex: item.colorHex))
                .cornerRadius(4)
            }
            .frame(width: 150, height: 150)
            .overlay {
                // Centre label
                VStack(spacing: 2) {
                    Text("Total")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("S$\(NSDecimalNumber(decimal: total).doubleValue, specifier: "%.0f")")
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
            }
            
            // Legend
            VStack(alignment: .leading, spacing: 6) {
                ForEach(data.prefix(6), id: \.name) { item in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(hex: item.colorHex))
                            .frame(width: 10, height: 10)
                        
                        Text(item.name)
                            .font(.caption)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        let percentage = total > 0
                            ? (NSDecimalNumber(decimal: item.total / total * 100).doubleValue)
                            : 0
                        Text("\(percentage, specifier: "%.0f")%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if data.count > 6 {
                    Text("+\(data.count - 6) more")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Daily Bar Chart

/// Bar chart showing daily spending for the current month.
struct DailyBarChart: View {
    
    let data: [(day: Int, total: Decimal)]
    
    var body: some View {
        Chart(data, id: \.day) { item in
            BarMark(
                x: .value("Day", item.day),
                y: .value("Amount", NSDecimalNumber(decimal: item.total).doubleValue)
            )
            .foregroundStyle(
                item.total > 0
                ? Color.blue.gradient
                : Color.gray.opacity(0.2).gradient
            )
            .cornerRadius(3)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: 5)) { value in
                AxisValueLabel()
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text("$\(doubleValue, specifier: "%.0f")")
                            .font(.caption2)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
