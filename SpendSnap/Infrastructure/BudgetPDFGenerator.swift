// Infrastructure/BudgetPDFGenerator.swift
// SpendSnap

import UIKit

/// Generates a professional PDF budget report with charts and detailed breakdowns.
struct BudgetPDFGenerator {
    
    private let pw: CGFloat = 595.0   // A4 width
    private let ph: CGFloat = 842.0   // A4 height
    private let m: CGFloat = 40.0     // margin
    private var cw: CGFloat { pw - m * 2 }
    
    private let titleFont = UIFont.boldSystemFont(ofSize: 20)
    private let h1 = UIFont.boldSystemFont(ofSize: 13)
    private let h2 = UIFont.boldSystemFont(ofSize: 10)
    private let body = UIFont.systemFont(ofSize: 9)
    private let bodyB = UIFont.boldSystemFont(ofSize: 9)
    private let cap = UIFont.systemFont(ofSize: 7.5)
    
    // Chart colors matching the app
    private let chartColors: [UIColor] = [
        UIColor(red: 0.04, green: 0.52, blue: 0.89, alpha: 1),  // blue
        UIColor(red: 0, green: 0.72, blue: 0.58, alpha: 1),      // green
        UIColor(red: 0.42, green: 0.36, blue: 0.9, alpha: 1),    // purple
        UIColor(red: 0.88, green: 0.44, blue: 0.33, alpha: 1),   // orange
        UIColor(red: 0.99, green: 0.80, blue: 0.43, alpha: 1),   // yellow
        UIColor(red: 0.70, green: 0.74, blue: 0.76, alpha: 1),   // gray
        UIColor(red: 0, green: 0.81, blue: 0.79, alpha: 1),      // teal
        UIColor(red: 0.84, green: 0.19, blue: 0.19, alpha: 1),   // red
    ]
    
    func generateBudgetPDF(
        monthTitle: String,
        incomeEntries: [IncomeEntry],
        recurringEntries: [MonthlyExpenseEntry],
        dailyExpenses: [Expense],
        groups: [ExpenseGroup],
        totalIncome: Decimal,
        totalRecurring: Decimal,
        totalDaily: Decimal,
        balance: Decimal
    ) -> URL? {
        let totalExpenses = totalRecurring + totalDaily
        let cs = CurrencyService.shared
        
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pw, height: ph))
        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            var y = m
            
            // ── HEADER ──
            y = drawText(monthTitle, at: y, font: titleFont, color: .black)
            y = drawText("Monthly Budget Report  •  Generated \(Date().formatted(date: .abbreviated, time: .shortened))", at: y, font: cap, color: .gray)
            y += 12
            
            // ── BALANCE CARD ──
            let cardH: CGFloat = 70
            UIColor.systemGray6.setFill()
            UIBezierPath(roundedRect: CGRect(x: m, y: y, width: cw, height: cardH), cornerRadius: 8).fill()
            
            let balVal = dbl(balance)
            let balColor = balance >= 0 ? UIColor.systemGreen : UIColor.systemRed
            drawCentered("Balance", at: y + 6, font: cap, color: .gray)
            drawCentered(sgd(balance), at: y + 18, font: UIFont.boldSystemFont(ofSize: 22), color: balColor)
            
            // Income / Expense side by side
            let leftX = m + cw * 0.25
            let rightX = m + cw * 0.75
            drawCentered(sgd(totalIncome), at: y + 44, font: bodyB, color: .systemGreen, centerX: leftX)
            drawCentered("Income", at: y + 56, font: cap, color: .gray, centerX: leftX)
            drawCentered(sgd(totalExpenses), at: y + 44, font: bodyB, color: .systemRed, centerX: rightX)
            drawCentered("Expenses", at: y + 56, font: cap, color: .gray, centerX: rightX)
            y += cardH + 14
            
            // ── DONUT CHART: Expense Breakdown by Group ──
            y = drawSectionBar("Expense Breakdown by Group", at: y)
            
            var groupData: [(name: String, total: Decimal, color: UIColor)] = []
            for (i, group) in groups.enumerated() {
                let entries = recurringEntries.filter { $0.expenseGroup?.id == group.id }
                let total = entries.reduce(Decimal(0)) { $0 + cs.convertToSGD(amount: $1.amount, from: $1.currency) }
                if total > 0 { groupData.append((group.name, total, chartColors[i % chartColors.count])) }
            }
            if totalDaily > 0 { groupData.append(("Daily Expenses", totalDaily, UIColor(red: 1, green: 0.42, blue: 0.42, alpha: 1))) }
            
            if !groupData.isEmpty {
                let chartSize: CGFloat = 120
                let chartX = m + 10
                let chartCenterX = chartX + chartSize / 2
                let chartCenterY = y + chartSize / 2
                
                // Draw donut
                var startAngle: CGFloat = -.pi / 2
                let totalForChart = groupData.reduce(Decimal(0)) { $0 + $1.total }
                for item in groupData {
                    let pct = totalForChart > 0 ? CGFloat(dbl(item.total / totalForChart)) : 0
                    let endAngle = startAngle + pct * 2 * .pi
                    let path = UIBezierPath()
                    path.addArc(withCenter: CGPoint(x: chartCenterX, y: chartCenterY), radius: chartSize / 2, startAngle: startAngle, endAngle: endAngle, clockwise: true)
                    path.addArc(withCenter: CGPoint(x: chartCenterX, y: chartCenterY), radius: chartSize / 4, startAngle: endAngle, endAngle: startAngle, clockwise: false)
                    path.close()
                    item.color.setFill()
                    path.fill()
                    startAngle = endAngle
                }
                
                // Legend
                let legendX = chartX + chartSize + 20
                var legendY = y + 4
                for item in groupData {
                    item.color.setFill()
                    UIBezierPath(roundedRect: CGRect(x: legendX, y: legendY + 2, width: 8, height: 8), cornerRadius: 2).fill()
                    let pct = totalForChart > 0 ? dbl(item.total / totalForChart * 100) : 0
                    let text = "\(item.name)  \(sgd(item.total))  (\(String(format: "%.0f", pct))%)"
                    (text as NSString).draw(at: CGPoint(x: legendX + 14, y: legendY), withAttributes: [.font: body, .foregroundColor: UIColor.black])
                    legendY += 16
                }
                
                y += max(chartSize + 10, legendY - y + 10)
            }
            
            // ── INCOME TABLE ──
            if !incomeEntries.isEmpty {
                y = checkPage(y, need: 60, ctx: ctx)
                y = drawSectionBar("Income", at: y)
                for entry in incomeEntries {
                    y = drawRow2(entry.name, "\(Currency.symbol(for: entry.currency))\(fmt(entry.amount))", at: y)
                }
                y = drawDivider(at: y)
                y = drawRow2B("Total Income", sgd(totalIncome), at: y, valueColor: .systemGreen)
                y += 10
            }
            
            // ── GROUP SECTIONS ──
            for group in groups {
                let allEntries = recurringEntries.filter { $0.expenseGroup?.id == group.id }
                guard !allEntries.isEmpty else { continue }
                
                let fixedEntries = allEntries.filter { $0.entryType == "fixed" }
                let petrolEntries = allEntries.filter { $0.entryType == "petrol" }
                let groceryEntries = allEntries.filter { $0.entryType == "grocery" }
                let groupTotal = allEntries.reduce(Decimal(0)) { $0 + cs.convertToSGD(amount: $1.amount, from: $1.currency) }
                
                y = checkPage(y, need: 50 + CGFloat(allEntries.count) * 16, ctx: ctx)
                y = drawSectionBar("\(group.name)  —  \(sgd(groupTotal))", at: y)
                
                // Fixed items
                for entry in fixedEntries {
                    let sym = Currency.symbol(for: entry.currency)
                    let paid = entry.isPaid ? " ✓" : ""
                    let src = entry.paymentSource?.name ?? ""
                    y = drawRow3("\(entry.name)\(paid)", src, "\(sym)\(fmt(entry.amount))", at: y)
                }
                
                // Petrol detail table
                if !petrolEntries.isEmpty {
                    y += 4
                    y = drawText("  Petrol Fill-ups", at: y, font: h2, color: UIColor.darkGray)
                    // Header row
                    y = drawPetrolHeader(at: y)
                    var prevOdo: Double? = nil
                    var prevLiters: Double? = nil
                    let sorted = petrolEntries.sorted { $0.createdAt < $1.createdAt }
                    for entry in sorted {
                        let eff: String
                        if let po = prevOdo, let pl = prevLiters, let co = entry.odometerReading, co > po, pl > 0 {
                            eff = String(format: "%.1f", (co - po) / pl)
                        } else { eff = "—" }
                        
                        let dateStr = entry.createdAt.formatted(.dateTime.day().month(.abbreviated))
                        let station = entry.vendor ?? "—"
                        let sym = Currency.symbol(for: entry.currency)
                        let amt = "\(sym)\(fmt(entry.amount))"
                        let liters = entry.litersFilled != nil ? String(format: "%.1f", entry.litersFilled!) : "—"
                        let odo = entry.odometerReading != nil ? String(format: "%.0f", entry.odometerReading!) : "—"
                        
                        y = drawPetrolRow(date: dateStr, station: station, amount: amt, liters: liters, odo: odo, efficiency: eff, at: y)
                        prevOdo = entry.odometerReading
                        prevLiters = entry.litersFilled
                    }
                    
                    // Summary
                    let totalPetrol = petrolEntries.reduce(Decimal(0)) { $0 + cs.convertToSGD(amount: $1.amount, from: $1.currency) }
                    let totalLiters = petrolEntries.compactMap(\.litersFilled).reduce(0, +)
                    let avgPPL: String
                    if totalLiters > 0 {
                        let avg = dbl(totalPetrol) / totalLiters
                        avgPPL = String(format: "%.3f", avg)
                    } else { avgPPL = "—" }
                    y += 2
                    y = drawRow2B("  Total Petrol: \(sgd(totalPetrol))   |   \(String(format: "%.1f", totalLiters))L   |   Avg \(avgPPL)/L", "", at: y, valueColor: .darkGray)
                }
                
                // Grocery detail
                if !groceryEntries.isEmpty {
                    y += 4
                    y = drawText("  Grocery Purchases", at: y, font: h2, color: UIColor.darkGray)
                    for entry in groceryEntries.sorted(by: { $0.createdAt < $1.createdAt }) {
                        let dateStr = entry.createdAt.formatted(.dateTime.day().month(.abbreviated))
                        let shop = entry.vendor ?? entry.name
                        let sym = Currency.symbol(for: entry.currency)
                        y = drawRow3("  \(dateStr)  \(shop)", entry.paymentSource?.name ?? "", "\(sym)\(fmt(entry.amount))", at: y)
                    }
                    let totalGrocery = groceryEntries.reduce(Decimal(0)) { $0 + cs.convertToSGD(amount: $1.amount, from: $1.currency) }
                    y = drawRow2B("  Total: \(sgd(totalGrocery))  (\(groceryEntries.count) trips)", "", at: y, valueColor: .darkGray)
                }
                
                y = drawDivider(at: y)
                y += 6
            }
            
            // ── DAILY EXPENSES ──
            y = checkPage(y, need: 40, ctx: ctx)
            y = drawSectionBar("Daily Expenses", at: y)
            y = drawRow2("Items", "\(dailyExpenses.count)", at: y)
            y = drawRow2B("Total", sgd(totalDaily), at: y, valueColor: .black)
            y += 10
            
            // ── FUND ALLOCATION BAR CHART ──
            y = checkPage(y, need: 120, ctx: ctx)
            y = drawSectionBar("Fund Allocation by Source", at: y)
            
            let allocation = computeAllocation(recurringEntries: recurringEntries, dailyExpenses: dailyExpenses)
            
            // Horizontal bar chart
            let barMaxWidth: CGFloat = cw * 0.55
            let maxVal = allocation.first?.1 ?? 1
            for (i, item) in allocation.enumerated() {
                let label = item.0
                let val = item.1
                let pct = totalExpenses > 0 ? dbl(val / totalExpenses * 100) : 0
                let barWidth = maxVal > 0 ? barMaxWidth * CGFloat(dbl(val / maxVal)) : 0
                let color = chartColors[i % chartColors.count]
                
                // Label
                let labelAttrs: [NSAttributedString.Key: Any] = [.font: body, .foregroundColor: UIColor.black]
                (label as NSString).draw(at: CGPoint(x: m + 8, y: y + 2), withAttributes: labelAttrs)
                
                // Bar
                let barX = m + cw * 0.25
                color.setFill()
                UIBezierPath(roundedRect: CGRect(x: barX, y: y + 1, width: barWidth, height: 12), cornerRadius: 3).fill()
                
                // Value
                let valStr = "\(sgd(val))  (\(String(format: "%.0f", pct))%)"
                let valAttrs: [NSAttributedString.Key: Any] = [.font: body, .foregroundColor: UIColor.black]
                let valSize = (valStr as NSString).size(withAttributes: valAttrs)
                (valStr as NSString).draw(at: CGPoint(x: m + cw - valSize.width - 8, y: y + 2), withAttributes: valAttrs)
                
                y += 18
            }
            y += 4
            y = drawDivider(at: y)
            y = drawRow2B("Total", sgd(totalExpenses), at: y, valueColor: .black)
            
            // Footer
            let footerAttrs: [NSAttributedString.Key: Any] = [.font: cap, .foregroundColor: UIColor.gray]
            let footer = "SpendSnap — \(monthTitle) Budget Report"
            (footer as NSString).draw(at: CGPoint(x: m, y: ph - m), withAttributes: footerAttrs)
        }
        
        let fileName = "Budget_\(monthTitle.replacingOccurrences(of: " ", with: "_")).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do { try data.write(to: url); return url }
        catch { print("PDF write error: \(error)"); return nil }
    }
    
    // ── Drawing Helpers ──
    
    private func drawText(_ text: String, at y: CGFloat, font: UIFont, color: UIColor) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let sz = (text as NSString).boundingRect(with: CGSize(width: cw, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
        (text as NSString).draw(in: CGRect(x: m, y: y, width: cw, height: sz.height), withAttributes: attrs)
        return y + sz.height + 4
    }
    
    private func drawCentered(_ text: String, at y: CGFloat, font: UIFont, color: UIColor, centerX: CGFloat? = nil) {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let sz = (text as NSString).size(withAttributes: attrs)
        let cx = centerX ?? (m + cw / 2)
        (text as NSString).draw(at: CGPoint(x: cx - sz.width / 2, y: y), withAttributes: attrs)
    }
    
    private func drawSectionBar(_ text: String, at y: CGFloat) -> CGFloat {
        UIColor.systemGray5.setFill()
        UIBezierPath(roundedRect: CGRect(x: m, y: y, width: cw, height: 20), cornerRadius: 4).fill()
        let attrs: [NSAttributedString.Key: Any] = [.font: h2, .foregroundColor: UIColor.black]
        (text as NSString).draw(at: CGPoint(x: m + 8, y: y + 3), withAttributes: attrs)
        return y + 24
    }
    
    private func drawRow2(_ left: String, _ right: String, at y: CGFloat) -> CGFloat {
        let la: [NSAttributedString.Key: Any] = [.font: body, .foregroundColor: UIColor.black]
        let ra: [NSAttributedString.Key: Any] = [.font: body, .foregroundColor: UIColor.black]
        (left as NSString).draw(at: CGPoint(x: m + 8, y: y), withAttributes: la)
        let rs = (right as NSString).size(withAttributes: ra)
        (right as NSString).draw(at: CGPoint(x: m + cw - rs.width - 8, y: y), withAttributes: ra)
        return y + 14
    }
    
    private func drawRow2B(_ left: String, _ right: String, at y: CGFloat, valueColor: UIColor) -> CGFloat {
        let la: [NSAttributedString.Key: Any] = [.font: bodyB, .foregroundColor: UIColor.black]
        let ra: [NSAttributedString.Key: Any] = [.font: bodyB, .foregroundColor: valueColor]
        (left as NSString).draw(at: CGPoint(x: m + 8, y: y), withAttributes: la)
        if !right.isEmpty {
            let rs = (right as NSString).size(withAttributes: ra)
            (right as NSString).draw(at: CGPoint(x: m + cw - rs.width - 8, y: y), withAttributes: ra)
        }
        return y + 14
    }
    
    private func drawRow3(_ left: String, _ center: String, _ right: String, at y: CGFloat) -> CGFloat {
        (left as NSString).draw(at: CGPoint(x: m + 8, y: y), withAttributes: [.font: body, .foregroundColor: UIColor.black])
        if !center.isEmpty {
            (center as NSString).draw(at: CGPoint(x: m + cw * 0.5, y: y), withAttributes: [.font: cap, .foregroundColor: UIColor.gray])
        }
        let ra: [NSAttributedString.Key: Any] = [.font: body, .foregroundColor: UIColor.black]
        let rs = (right as NSString).size(withAttributes: ra)
        (right as NSString).draw(at: CGPoint(x: m + cw - rs.width - 8, y: y), withAttributes: ra)
        return y + 14
    }
    
    // Petrol table
    private func drawPetrolHeader(at y: CGFloat) -> CGFloat {
        let cols = ["Date", "Station", "Amount", "Liters", "Odo", "km/L"]
        let xs: [CGFloat] = [m + 10, m + 60, m + 160, m + 250, m + 310, m + 380]
        UIColor.systemGray5.setFill()
        UIBezierPath(rect: CGRect(x: m + 8, y: y, width: cw - 16, height: 14)).fill()
        for (i, col) in cols.enumerated() {
            (col as NSString).draw(at: CGPoint(x: xs[i], y: y + 1), withAttributes: [.font: cap, .foregroundColor: UIColor.darkGray])
        }
        return y + 16
    }
    
    private func drawPetrolRow(date: String, station: String, amount: String, liters: String, odo: String, efficiency: String, at y: CGFloat) -> CGFloat {
        let xs: [CGFloat] = [m + 10, m + 60, m + 160, m + 250, m + 310, m + 380]
        let a: [NSAttributedString.Key: Any] = [.font: body, .foregroundColor: UIColor.black]
        (date as NSString).draw(at: CGPoint(x: xs[0], y: y), withAttributes: a)
        // Truncate station to fit
        let stationTrunc = String(station.prefix(14))
        (stationTrunc as NSString).draw(at: CGPoint(x: xs[1], y: y), withAttributes: a)
        (amount as NSString).draw(at: CGPoint(x: xs[2], y: y), withAttributes: a)
        (liters as NSString).draw(at: CGPoint(x: xs[3], y: y), withAttributes: a)
        (odo as NSString).draw(at: CGPoint(x: xs[4], y: y), withAttributes: a)
        let effColor = efficiency != "—" ? UIColor.systemGreen : UIColor.gray
        (efficiency as NSString).draw(at: CGPoint(x: xs[5], y: y), withAttributes: [.font: bodyB, .foregroundColor: effColor])
        return y + 14
    }
    
    private func drawDivider(at y: CGFloat) -> CGFloat {
        UIColor.systemGray4.setStroke()
        let p = UIBezierPath(); p.move(to: CGPoint(x: m + 8, y: y)); p.addLine(to: CGPoint(x: m + cw - 8, y: y)); p.lineWidth = 0.5; p.stroke()
        return y + 4
    }
    
    private func checkPage(_ y: CGFloat, need: CGFloat, ctx: UIGraphicsPDFRendererContext) -> CGFloat {
        if y + need > ph - m { ctx.beginPage(); return m }; return y
    }
    
    // ── Formatting ──
    private func sgd(_ v: Decimal) -> String { String(format: "S$%.2f", dbl(v)) }
    private func fmt(_ v: Decimal) -> String { String(format: "%.2f", dbl(v)) }
    private func dbl(_ v: Decimal) -> Double { NSDecimalNumber(decimal: v).doubleValue }
    
    private func computeAllocation(recurringEntries: [MonthlyExpenseEntry], dailyExpenses: [Expense]) -> [(String, Decimal)] {
        let cs = CurrencyService.shared
        var d: [String: Decimal] = [:]
        for e in recurringEntries { d[e.paymentSource?.name ?? "Unassigned", default: 0] += cs.convertToSGD(amount: e.amount, from: e.currency) }
        for e in dailyExpenses { d[e.paymentSource?.name ?? "Unassigned", default: 0] += cs.convertToSGD(amount: e.amount, from: e.currency) }
        return d.sorted { $0.value > $1.value }
    }
}
