// Infrastructure/BudgetPDFGenerator.swift
// SpendSnap

import UIKit
import PDFKit

/// Generates a PDF report from the monthly budget workspace data.
/// Includes: income summary, recurring expenses by group, daily expense total,
/// balance overview, and fund allocation by payment source.
struct BudgetPDFGenerator {
    
    // MARK: - Configuration
    
    private let pageWidth: CGFloat = 595.0    // A4
    private let pageHeight: CGFloat = 842.0   // A4
    private let margin: CGFloat = 40.0
    private let lineSpacing: CGFloat = 6.0
    
    private var contentWidth: CGFloat { pageWidth - (margin * 2) }
    
    // MARK: - Fonts
    
    private let titleFont = UIFont.boldSystemFont(ofSize: 22)
    private let headerFont = UIFont.boldSystemFont(ofSize: 14)
    private let subheaderFont = UIFont.boldSystemFont(ofSize: 11)
    private let bodyFont = UIFont.systemFont(ofSize: 10)
    private let bodyBoldFont = UIFont.boldSystemFont(ofSize: 10)
    private let captionFont = UIFont.systemFont(ofSize: 8)
    
    // MARK: - Generate
    
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
        
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        
        let data = renderer.pdfData { context in
            context.beginPage()
            var y = margin
            
            // ── Title ──
            y = drawText(monthTitle, at: y, font: titleFont, color: UIColor.black)
            y = drawText("Monthly Budget Report", at: y + 4, font: captionFont, color: UIColor.gray)
            y = drawText("Generated \(Date().formatted(date: .abbreviated, time: .shortened))", at: y, font: captionFont, color: UIColor.gray)
            y += 16
            
            // ── Balance Summary ──
            y = drawSectionHeader("Balance Overview", at: y)
            y = drawTwoColumn("Total Income", formatSGD(totalIncome), at: y, valueColor: UIColor.systemGreen)
            y = drawTwoColumn("Total Recurring Expenses", formatSGD(totalRecurring), at: y, valueColor: UIColor.systemRed)
            y = drawTwoColumn("Total Daily Expenses", formatSGD(totalDaily), at: y, valueColor: UIColor.systemRed)
            y = drawDivider(at: y)
            let balanceColor = balance >= 0 ? UIColor.systemGreen : UIColor.systemRed
            y = drawTwoColumn("Balance", formatSGD(balance), at: y, font: bodyBoldFont, valueColor: balanceColor)
            y += 16
            
            // ── Income ──
            if !incomeEntries.isEmpty {
                y = checkPageBreak(y: y, needed: 60, context: context)
                y = drawSectionHeader("Income", at: y)
                for entry in incomeEntries {
                    let sym = Currency.symbol(for: entry.currency)
                    let amtStr = "\(sym)\(formatAmount(entry.amount))"
                    let sourceStr = entry.paymentSource?.name ?? ""
                    y = drawThreeColumn(entry.name, sourceStr, amtStr, at: y)
                }
                y = drawDivider(at: y)
                y = drawTwoColumn("Total Income", formatSGD(totalIncome), at: y, font: bodyBoldFont, valueColor: UIColor.systemGreen)
                y += 14
            }
            
            // ── Recurring Groups ──
            for group in groups {
                let groupEntries = recurringEntries.filter { $0.expenseGroup?.id == group.id }
                guard !groupEntries.isEmpty else { continue }
                
                y = checkPageBreak(y: y, needed: 50 + CGFloat(groupEntries.count) * 18, context: context)
                
                let cs = CurrencyService.shared
                let groupTotal = groupEntries.reduce(Decimal(0)) { $0 + cs.convertToSGD(amount: $1.amount, from: $1.currency) }
                
                y = drawSectionHeader("\(group.name)  —  \(formatSGD(groupTotal))", at: y)
                
                for entry in groupEntries {
                    let sym = Currency.symbol(for: entry.currency)
                    let amtStr = "\(sym)\(formatAmount(entry.amount))"
                    let sourceStr = entry.paymentSource?.name ?? ""
                    let paidStr = entry.isPaid ? " ✓" : ""
                    y = drawThreeColumn("\(entry.name)\(paidStr)", sourceStr, amtStr, at: y)
                }
                y = drawDivider(at: y)
                y += 10
            }
            
            // ── Daily Expenses Summary ──
            y = checkPageBreak(y: y, needed: 50, context: context)
            y = drawSectionHeader("Daily Expenses", at: y)
            y = drawTwoColumn("Items", "\(dailyExpenses.count)", at: y)
            y = drawTwoColumn("Total", formatSGD(totalDaily), at: y, font: bodyBoldFont, valueColor: UIColor.black)
            y += 14
            
            // ── Fund Allocation ──
            y = checkPageBreak(y: y, needed: 80, context: context)
            y = drawSectionHeader("Fund Allocation by Source", at: y)
            
            let allocation = computeAllocation(recurringEntries: recurringEntries, dailyExpenses: dailyExpenses)
            for (sourceName, total) in allocation {
                let pct = totalExpenses > 0
                    ? NSDecimalNumber(decimal: total / totalExpenses * 100).doubleValue
                    : 0
                y = drawTwoColumn(sourceName, "\(formatSGD(total))  (\(String(format: "%.0f", pct))%)", at: y)
            }
            y = drawDivider(at: y)
            y = drawTwoColumn("Total", formatSGD(totalExpenses), at: y, font: bodyBoldFont, valueColor: UIColor.black)
            
            // ── Footer ──
            let footerY = pageHeight - margin
            let footerText = "SpendSnap — \(monthTitle) Budget Report"
            let footerAttr: [NSAttributedString.Key: Any] = [.font: captionFont, .foregroundColor: UIColor.gray]
            (footerText as NSString).draw(at: CGPoint(x: margin, y: footerY), withAttributes: footerAttr)
        }
        
        // Save to temp directory
        let fileName = "Budget_\(monthTitle.replacingOccurrences(of: " ", with: "_")).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Failed to write budget PDF: \(error)")
            return nil
        }
    }
    
    // MARK: - Drawing Helpers
    
    private func drawText(_ text: String, at y: CGFloat, font: UIFont, color: UIColor) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let size = (text as NSString).boundingRect(
            with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin, attributes: attrs, context: nil
        )
        (text as NSString).draw(in: CGRect(x: margin, y: y, width: contentWidth, height: size.height), withAttributes: attrs)
        return y + size.height + lineSpacing
    }
    
    private func drawSectionHeader(_ text: String, at y: CGFloat) -> CGFloat {
        // Draw background bar
        let barHeight: CGFloat = 22
        UIColor.systemGray5.setFill()
        UIBezierPath(roundedRect: CGRect(x: margin, y: y, width: contentWidth, height: barHeight), cornerRadius: 4).fill()
        
        let attrs: [NSAttributedString.Key: Any] = [.font: subheaderFont, .foregroundColor: UIColor.black]
        (text as NSString).draw(at: CGPoint(x: margin + 8, y: y + 4), withAttributes: attrs)
        return y + barHeight + lineSpacing
    }
    
    private func drawTwoColumn(_ left: String, _ right: String, at y: CGFloat, font: UIFont? = nil, valueColor: UIColor = UIColor.black) -> CGFloat {
        let f = font ?? bodyFont
        let leftAttrs: [NSAttributedString.Key: Any] = [.font: f, .foregroundColor: UIColor.black]
        let rightAttrs: [NSAttributedString.Key: Any] = [.font: f, .foregroundColor: valueColor]
        
        (left as NSString).draw(at: CGPoint(x: margin + 8, y: y), withAttributes: leftAttrs)
        
        let rightSize = (right as NSString).size(withAttributes: rightAttrs)
        (right as NSString).draw(at: CGPoint(x: margin + contentWidth - rightSize.width - 8, y: y), withAttributes: rightAttrs)
        
        return y + 16
    }
    
    private func drawThreeColumn(_ left: String, _ center: String, _ right: String, at y: CGFloat) -> CGFloat {
        let leftAttrs: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.black]
        let centerAttrs: [NSAttributedString.Key: Any] = [.font: captionFont, .foregroundColor: UIColor.gray]
        let rightAttrs: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.black]
        
        (left as NSString).draw(at: CGPoint(x: margin + 8, y: y), withAttributes: leftAttrs)
        
        if !center.isEmpty {
            (center as NSString).draw(at: CGPoint(x: margin + contentWidth * 0.45, y: y + 1), withAttributes: centerAttrs)
        }
        
        let rightSize = (right as NSString).size(withAttributes: rightAttrs)
        (right as NSString).draw(at: CGPoint(x: margin + contentWidth - rightSize.width - 8, y: y), withAttributes: rightAttrs)
        
        return y + 16
    }
    
    private func drawDivider(at y: CGFloat) -> CGFloat {
        UIColor.systemGray4.setStroke()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin + 8, y: y))
        path.addLine(to: CGPoint(x: margin + contentWidth - 8, y: y))
        path.lineWidth = 0.5
        path.stroke()
        return y + lineSpacing
    }
    
    private func checkPageBreak(y: CGFloat, needed: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        if y + needed > pageHeight - margin {
            context.beginPage()
            return margin
        }
        return y
    }
    
    // MARK: - Formatting
    
    private func formatSGD(_ amount: Decimal) -> String {
        let value = NSDecimalNumber(decimal: amount).doubleValue
        return String(format: "S$%.2f", value)
    }
    
    private func formatAmount(_ amount: Decimal) -> String {
        let value = NSDecimalNumber(decimal: amount).doubleValue
        return String(format: "%.2f", value)
    }
    
    // MARK: - Allocation Computation
    
    private func computeAllocation(recurringEntries: [MonthlyExpenseEntry], dailyExpenses: [Expense]) -> [(String, Decimal)] {
        let cs = CurrencyService.shared
        var dict: [String: Decimal] = [:]
        
        for entry in recurringEntries {
            let name = entry.paymentSource?.name ?? "Unassigned"
            let sgd = cs.convertToSGD(amount: entry.amount, from: entry.currency)
            dict[name, default: 0] += sgd
        }
        
        for expense in dailyExpenses {
            let name = expense.paymentSource?.name ?? "Unassigned"
            let sgd = cs.convertToSGD(amount: expense.amount, from: expense.currency)
            dict[name, default: 0] += sgd
        }
        
        return dict.sorted { $0.value > $1.value }
    }
}
