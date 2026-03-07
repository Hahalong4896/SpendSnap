// Infrastructure/PDFReportGenerator.swift
// SpendSnap

import UIKit

/// Generates a shareable PDF monthly spending report with photos,
/// correct currency display, date-grouped expenses, and daily chart.
struct PDFReportGenerator {
    
    // MARK: - Data Model
    
    struct ReportData {
        let monthTitle: String
        let totalSpend: Decimal
        let transactionCount: Int
        let dailyAverage: Decimal
        let categoryBreakdown: [(name: String, colorHex: String, total: Decimal)]
        let topExpenses: [Expense]  // All expenses sorted by amount
        let previousMonthTotal: Decimal
        let monthOverMonthChange: Decimal
    }
    
    // MARK: - Page Constants
    
    private static let pageWidth: CGFloat = 595
    private static let pageHeight: CGFloat = 842
    private static let margin: CGFloat = 40
    private static let contentWidth: CGFloat = 595 - 80
    
    // MARK: - Text Styles
    
    private static let titleAttrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 28, weight: .bold),
        .foregroundColor: UIColor.black
    ]
    private static let subtitleAttrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 16, weight: .medium),
        .foregroundColor: UIColor.darkGray
    ]
    private static let sectionAttrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
        .foregroundColor: UIColor.black
    ]
    private static let bodyAttrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 12),
        .foregroundColor: UIColor.black
    ]
    private static let boldAttrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
        .foregroundColor: UIColor.black
    ]
    private static let headerAttrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
        .foregroundColor: UIColor.darkGray
    ]
    private static let footerAttrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 9),
        .foregroundColor: UIColor.gray
    ]
    private static let smallAttrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 10),
        .foregroundColor: UIColor.darkGray
    ]
    private static let dateSectionAttrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
        .foregroundColor: UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
    ]
    
    // MARK: - Generate
    
    static func generateReport(data: ReportData) -> URL? {
        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        )
        
        let pdfData = renderer.pdfData { context in
            context.beginPage()
            var y: CGFloat = margin
            
            // ━━━ HEADER ━━━
            y = drawHeader(data: data, y: y, context: context)
            
            // ━━━ SUMMARY ━━━
            y = drawSummary(data: data, y: y, context: context)
            
            // ━━━ CATEGORY BREAKDOWN ━━━
            y = drawCategoryBreakdown(data: data, y: y, context: context)
            
            // ━━━ PIE CHART ━━━
            y = drawPieChart(data: data, y: y, context: context)

            // ━━━ DAILY SPENDING CHART ━━━
            y = drawDailyChart(data: data, y: y, context: context)
            
            // ━━━ ALL EXPENSES BY DATE ━━━
            y = drawExpensesByDate(data: data, y: y, context: context)
            
            // ━━━ MONTH COMPARISON ━━━
            if data.previousMonthTotal > 0 {
                y = drawMonthComparison(data: data, y: y, context: context)
            }
            
            // ━━━ FOOTER on last page ━━━
            drawFooter(context: context)
        }
        
        // Save
        let fileName = "SpendSnap_Report_\(data.monthTitle.replacingOccurrences(of: " ", with: "_")).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try pdfData.write(to: tempURL)
            return tempURL
        } catch {
            print("Failed to write PDF: \(error)")
            return nil
        }
    }
    
    // MARK: - Header
    
    private static func drawHeader(data: ReportData, y: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        var y = y
        
        "SpendSnap Report".draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
        y += 38
        
        data.monthTitle.draw(at: CGPoint(x: margin, y: y), withAttributes: subtitleAttrs)
        y += 30
        
        drawLine(y: y, context: context.cgContext)
        y += 15
        
        return y
    }
    
    // MARK: - Summary
    
    private static func drawSummary(data: ReportData, y: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        var y = y
        
        "Summary".draw(at: CGPoint(x: margin, y: y), withAttributes: sectionAttrs)
        y += 28
        
        let totalStr = String(format: "S$%.2f", NSDecimalNumber(decimal: data.totalSpend).doubleValue)
        let avgStr = String(format: "S$%.2f", NSDecimalNumber(decimal: data.dailyAverage).doubleValue)
        
        // Check if mixed currencies
        let currencies = Set(data.topExpenses.map { $0.currency })
        let note = currencies.count > 1 ? " (converted to SGD)" : ""
        
        drawKeyValue("Total Spend:", totalStr + note, y: y); y += 20
        drawKeyValue("Transactions:", "\(data.transactionCount)", y: y); y += 20
        drawKeyValue("Daily Average:", avgStr, y: y); y += 28
        
        
        
        drawLine(y: y, context: context.cgContext)
        y += 15
        
        return y
    }
    
    // MARK: - Category Breakdown
    
    private static func drawCategoryBreakdown(data: ReportData, y: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        var y = y
        
        "Category Breakdown".draw(at: CGPoint(x: margin, y: y), withAttributes: sectionAttrs)
        y += 28
        
        let col1 = margin
        let col2 = margin + contentWidth * 0.50
        let col3 = margin + contentWidth * 0.78
        
        "Category".draw(at: CGPoint(x: col1, y: y), withAttributes: headerAttrs)
        "Amount".draw(at: CGPoint(x: col2, y: y), withAttributes: headerAttrs)
        "%".draw(at: CGPoint(x: col3, y: y), withAttributes: headerAttrs)
        y += 18
        
        drawLine(y: y, context: context.cgContext, alpha: 0.3)
        y += 6
        
        for item in data.categoryBreakdown {
            y = checkPageBreak(y: y, needed: 20, context: context)
            
            let amountStr = String(format: "S$%.2f", NSDecimalNumber(decimal: item.total).doubleValue)
            
            let pct = data.totalSpend > 0
                ? NSDecimalNumber(decimal: item.total / data.totalSpend * 100).doubleValue
                : 0
            let pctStr = String(format: "%.1f%%", pct)
            
            // Color dot
            let dotRect = CGRect(x: col1, y: y + 4, width: 8, height: 8)
            let color = colorFromHex(item.colorHex)
            context.cgContext.setFillColor(color.cgColor)
            context.cgContext.fillEllipse(in: dotRect)
            
            item.name.draw(at: CGPoint(x: col1 + 14, y: y), withAttributes: bodyAttrs)
            amountStr.draw(at: CGPoint(x: col2, y: y), withAttributes: boldAttrs)
            pctStr.draw(at: CGPoint(x: col3, y: y), withAttributes: bodyAttrs)
            y += 20
        }
        
        y += 12
        drawLine(y: y, context: context.cgContext)
        y += 15
        
        return y
    }

    // MARK: - Pie Chart

    private static func drawPieChart(data: ReportData, y: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        guard !data.categoryBreakdown.isEmpty, data.totalSpend > 0 else { return y }
        
        var y = checkPageBreak(y: y, needed: 200, context: context)
        
        // Chart dimensions
        let centerX: CGFloat = margin + 85
        let centerY: CGFloat = y + 85
        let radius: CGFloat = 75
        let innerRadius: CGFloat = 45  // Donut hole
        
        var startAngle: CGFloat = -.pi / 2  // Start from top
        
        for item in data.categoryBreakdown {
            let proportion = data.totalSpend > 0
                ? CGFloat(NSDecimalNumber(decimal: item.total / data.totalSpend).doubleValue)
                : 0
            let endAngle = startAngle + (proportion * 2 * .pi)
            
            let color = colorFromHex(item.colorHex)
            context.cgContext.setFillColor(color.cgColor)
            
            // Draw donut segment
            let path = CGMutablePath()
            path.addArc(center: CGPoint(x: centerX, y: centerY),
                         radius: radius,
                         startAngle: startAngle,
                         endAngle: endAngle,
                         clockwise: false)
            path.addArc(center: CGPoint(x: centerX, y: centerY),
                         radius: innerRadius,
                         startAngle: endAngle,
                         endAngle: startAngle,
                         clockwise: true)
            path.closeSubpath()
            
            context.cgContext.addPath(path)
            context.cgContext.fillPath()
            
            startAngle = endAngle
        }
        
        // Centre text — total
        let totalStr = String(format: "S$%.0f", NSDecimalNumber(decimal: data.totalSpend).doubleValue)
        let centerTotalAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .bold),
            .foregroundColor: UIColor.black
        ]
        let centerLabelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.darkGray
        ]
        
        let totalSize = (totalStr as NSString).size(withAttributes: centerTotalAttrs)
        totalStr.draw(at: CGPoint(x: centerX - totalSize.width / 2, y: centerY - 8),
                      withAttributes: centerTotalAttrs)
        
        let label = "Total (SGD)"
        let labelSize = (label as NSString).size(withAttributes: centerLabelAttrs)
        label.draw(at: CGPoint(x: centerX - labelSize.width / 2, y: centerY + 8),
                   withAttributes: centerLabelAttrs)
        
        // Legend — right side of chart
        let legendX: CGFloat = margin + 190
        var legendY: CGFloat = y + 10
        
        let legendNameAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.black
        ]
        let legendValueAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
            .foregroundColor: UIColor.black
        ]
        let legendPctAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.darkGray
        ]
        
        for item in data.categoryBreakdown.prefix(10) {
            // Color dot
            let dotRect = CGRect(x: legendX, y: legendY + 3, width: 8, height: 8)
            context.cgContext.setFillColor(colorFromHex(item.colorHex).cgColor)
            context.cgContext.fillEllipse(in: dotRect)
            
            // Name
            item.name.draw(at: CGPoint(x: legendX + 14, y: legendY), withAttributes: legendNameAttrs)
            
            // Amount + percentage
            let amountStr = String(format: "S$%.2f", NSDecimalNumber(decimal: item.total).doubleValue)
            let pct = NSDecimalNumber(decimal: item.total / data.totalSpend * 100).doubleValue
            let pctStr = String(format: "(%.0f%%)", pct)
            
            amountStr.draw(at: CGPoint(x: legendX + 120, y: legendY), withAttributes: legendValueAttrs)
            pctStr.draw(at: CGPoint(x: legendX + 190, y: legendY), withAttributes: legendPctAttrs)
            
            legendY += 16
        }
        
        y += 180
        y += 10
        drawLine(y: y, context: context.cgContext)
        y += 15
        
        return y
    }
    
    // MARK: - Daily Spending Chart
    
    private static func drawDailyChart(data: ReportData, y: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        var y = checkPageBreak(y: y, needed: 180, context: context)
        
        "Daily Spending".draw(at: CGPoint(x: margin, y: y), withAttributes: sectionAttrs)
        y += 28
        
        // Build daily totals
        let calendar = Calendar.current
        var dailyTotals: [Int: Decimal] = [:]
        
        for expense in data.topExpenses {
            let day = calendar.component(.day, from: expense.date)
            dailyTotals[day, default: 0] += expense.amount
        }
        
        guard !dailyTotals.isEmpty else { return y }
        
        let maxDay = dailyTotals.keys.max() ?? 1
        let maxAmount = dailyTotals.values.max() ?? 1
        let maxAmountDouble = NSDecimalNumber(decimal: maxAmount).doubleValue
        
        // Chart dimensions
        let chartX = margin + 35
        let chartWidth = contentWidth - 40
        let chartHeight: CGFloat = 100
        let chartTop = y
        let chartBottom = y + chartHeight
        
        // Y-axis labels
        let topLabel = String(format: "%.0f", maxAmountDouble)
        let midLabel = String(format: "%.0f", maxAmountDouble / 2)
        let axisAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8),
            .foregroundColor: UIColor.gray
        ]
        topLabel.draw(at: CGPoint(x: margin, y: chartTop - 4), withAttributes: axisAttrs)
        midLabel.draw(at: CGPoint(x: margin, y: chartTop + chartHeight / 2 - 4), withAttributes: axisAttrs)
        "0".draw(at: CGPoint(x: margin + 20, y: chartBottom - 4), withAttributes: axisAttrs)
        
        // Draw horizontal grid lines
        context.cgContext.setStrokeColor(UIColor(white: 0.85, alpha: 1).cgColor)
        context.cgContext.setLineWidth(0.3)
        for fraction in [0.0, 0.5, 1.0] as [CGFloat] {
            let lineY = chartBottom - (chartHeight * fraction)
            context.cgContext.move(to: CGPoint(x: chartX, y: lineY))
            context.cgContext.addLine(to: CGPoint(x: chartX + chartWidth, y: lineY))
        }
        context.cgContext.strokePath()
        
        // Draw bars
        let barWidth = max(chartWidth / CGFloat(maxDay) - 2, 3)
        let barSpacing = chartWidth / CGFloat(maxDay)
        
        for day in 1...maxDay {
            let total = dailyTotals[day] ?? 0
            let totalDouble = NSDecimalNumber(decimal: total).doubleValue
            let barHeight = maxAmountDouble > 0
                ? CGFloat(totalDouble / maxAmountDouble) * chartHeight
                : 0
            
            let barX = chartX + (CGFloat(day - 1) * barSpacing) + (barSpacing - barWidth) / 2
            let barY = chartBottom - barHeight
            
            let barRect = CGRect(x: barX, y: barY, width: barWidth, height: barHeight)
            
            if total > 0 {
                // Blue bar
                context.cgContext.setFillColor(UIColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 0.8).cgColor)
                let path = UIBezierPath(roundedRect: barRect,
                                        byRoundingCorners: [.topLeft, .topRight],
                                        cornerRadii: CGSize(width: 2, height: 2))
                path.fill()
            }
        }
        
        // X-axis day labels (every 5 days)
        for day in stride(from: 1, through: maxDay, by: 5) {
            let labelX = chartX + (CGFloat(day - 1) * barSpacing)
            "\(day)".draw(at: CGPoint(x: labelX, y: chartBottom + 4), withAttributes: axisAttrs)
        }
        
        y = chartBottom + 20
        drawLine(y: y, context: context.cgContext)
        y += 15
        
        return y
    }
    
    // MARK: - All Expenses Grouped by Date
    
    private static func drawExpensesByDate(data: ReportData, y: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        var y = y
        
        "All Expenses".draw(at: CGPoint(x: margin, y: y), withAttributes: sectionAttrs)
        y += 28
        
        // Group expenses by date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        let grouped = Dictionary(grouping: data.topExpenses) { expense in
            Calendar.current.startOfDay(for: expense.date)
        }
        
        // Sort by date descending
        let sortedDates = grouped.keys.sorted(by: >)
        
        let photoSize: CGFloat = 40
        let rowHeight: CGFloat = 42
        
        for date in sortedDates {
            guard let expenses = grouped[date] else { continue }
            
            // Date section header
            y = checkPageBreak(y: y, needed: 30, context: context)
            let dateStr = dateFormatter.string(from: date)
            
            // Daily total
            // Group by currency for daily total display
            let cs = CurrencyService.shared
            let currencyTotals = Dictionary(grouping: expenses, by: { $0.currency })
                .mapValues { $0.reduce(Decimal(0)) { $0 + $1.amount } }

            let sgdDayTotal = expenses.reduce(Decimal(0)) { $0 + cs.convertToSGD(amount: $1.amount, from: $1.currency) }

            // Build display string
            var dailyTotalStr = ""
            let sortedCurrencies = currencyTotals.sorted { $0.value > $1.value }
            for (code, total) in sortedCurrencies {
                let sym = (Currency(rawValue: code) ?? .sgd).symbol
                if !dailyTotalStr.isEmpty { dailyTotalStr += " + " }
                dailyTotalStr += String(format: "%@%.2f", sym, NSDecimalNumber(decimal: total).doubleValue)
            }

            // Add SGD equivalent if mixed currencies
            let hasForeignCurrency = currencyTotals.keys.contains(where: { $0 != "SGD" })
            if hasForeignCurrency && currencyTotals.count > 1 {
                dailyTotalStr += String(format: " ≈ S$%.2f", NSDecimalNumber(decimal: sgdDayTotal).doubleValue)
            }
            
            // Draw date header with background
            let headerRect = CGRect(x: margin, y: y, width: contentWidth, height: 20)
            context.cgContext.setFillColor(UIColor(white: 0.94, alpha: 1).cgColor)
            context.cgContext.fill(headerRect)
            
            dateStr.draw(at: CGPoint(x: margin + 6, y: y + 3), withAttributes: dateSectionAttrs)
            
            // Daily total right-aligned
            let dailyTotalLabel = dailyTotalStr
            let totalWidth = (dailyTotalLabel as NSString).size(withAttributes: smallAttrs).width
            dailyTotalLabel.draw(at: CGPoint(x: margin + contentWidth - totalWidth - 6, y: y + 4), withAttributes: smallAttrs)
            
            y += 22
            
            // Show exchange rate if foreign currency used that day
            if hasForeignCurrency {
                let rateStrs = currencyTotals.keys
                    .filter { $0 != "SGD" }
                    .compactMap { code -> String? in
                        guard let rate = cs.rates[code] else { return nil }
                        return String(format: "1 %@ = %.4f SGD", code, rate)
                    }
                if !rateStrs.isEmpty {
                    let rateText = rateStrs.joined(separator: "  |  ")
                    let rateAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 8),
                        .foregroundColor: UIColor.gray
                    ]
                    rateText.draw(at: CGPoint(x: margin + 6, y: y), withAttributes: rateAttrs)
                    y += 14
                }
            }
            
            // Sort expenses within the day by amount descending
            let sortedExpenses = expenses.sorted { $0.amount > $1.amount }
            
            for expense in sortedExpenses {
                y = checkPageBreak(y: y, needed: rowHeight + 5, context: context)
                
                // Photo thumbnail
                let photoRect = CGRect(x: margin, y: y, width: photoSize, height: photoSize)
                
                if expense.photoFileName != "no_photo",
                   let image = PhotoStorageService.loadPhoto(named: expense.photoFileName) {
                    context.cgContext.saveGState()
                    let path = UIBezierPath(roundedRect: photoRect, cornerRadius: 5)
                    path.addClip()
                    image.draw(in: photoRect)
                    context.cgContext.restoreGState()
                    
                    context.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
                    context.cgContext.setLineWidth(0.5)
                    UIBezierPath(roundedRect: photoRect, cornerRadius: 5).stroke()
                } else {
                    context.cgContext.setFillColor(UIColor(white: 0.93, alpha: 1).cgColor)
                    UIBezierPath(roundedRect: photoRect, cornerRadius: 5).fill()
                    
                    let noPhotoAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 8),
                        .foregroundColor: UIColor.gray
                    ]
                    "No photo".draw(at: CGPoint(x: margin + 2, y: y + 15), withAttributes: noPhotoAttrs)
                }
                
                // Text details
                let textX = margin + photoSize + 10
                let categoryName = expense.category?.name ?? "Others"
                
                // Currency-aware amount
                let symbol = (Currency(rawValue: expense.currency) ?? .sgd).symbol
                let amountStr = String(format: "%@%.2f", symbol, NSDecimalNumber(decimal: expense.amount).doubleValue)
                
                // Category name (bold)
                categoryName.draw(at: CGPoint(x: textX, y: y + 2), withAttributes: boldAttrs)
                
                // Vendor/notes
                let detail = expense.vendor ?? expense.note ?? ""
                if !detail.isEmpty {
                    detail.draw(at: CGPoint(x: textX, y: y + 18), withAttributes: smallAttrs)
                }
                
               
                
                // Amount (right-aligned)
                let amountWidth = (amountStr as NSString).size(withAttributes: boldAttrs).width
                let amountX = margin + contentWidth - amountWidth
                amountStr.draw(at: CGPoint(x: amountX, y: y + 8), withAttributes: boldAttrs)
                
                y += rowHeight
            }
            
            // Subtle separator between date groups
            y += 4
            drawLine(y: y, context: context.cgContext, alpha: 0.2)
            y += 8
        }
        
        y += 8
        drawLine(y: y, context: context.cgContext)
        y += 15
        
        return y
    }
    
    // MARK: - Month Comparison
    
    private static func drawMonthComparison(data: ReportData, y: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        var y = checkPageBreak(y: y, needed: 80, context: context)
        
        "Month-over-Month Comparison".draw(at: CGPoint(x: margin, y: y), withAttributes: sectionAttrs)
        y += 28
        
        let prevStr = String(format: "S$%.2f", NSDecimalNumber(decimal: data.previousMonthTotal).doubleValue)
        let changeVal = NSDecimalNumber(decimal: data.monthOverMonthChange).doubleValue
        let direction = changeVal >= 0 ? "more" : "less"
        let changeStr = String(format: "%.1f%% %@", abs(changeVal), direction)
        
        drawKeyValue("Previous Month:", prevStr, y: y); y += 20
        drawKeyValue("Change:", changeStr, y: y); y += 28
        
        return y
    }
    
    // MARK: - Footer
    
    private static func drawFooter(context: UIGraphicsPDFRendererContext) {
        let footer = "Generated by SpendSnap on \(Date().formatted(date: .long, time: .shortened))"
        footer.draw(at: CGPoint(x: margin, y: pageHeight - 30), withAttributes: footerAttrs)
    }
    
    // MARK: - Drawing Helpers
    
    private static func drawLine(y: CGFloat, context: CGContext, alpha: CGFloat = 1.0) {
        context.setStrokeColor(UIColor.lightGray.withAlphaComponent(alpha).cgColor)
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: margin, y: y))
        context.addLine(to: CGPoint(x: margin + contentWidth, y: y))
        context.strokePath()
    }
    
    private static func drawKeyValue(_ key: String, _ value: String, y: CGFloat) {
        key.draw(at: CGPoint(x: margin, y: y), withAttributes: bodyAttrs)
        value.draw(at: CGPoint(x: margin + 130, y: y), withAttributes: boldAttrs)
    }
    
    private static func checkPageBreak(y: CGFloat, needed: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        if y + needed > pageHeight - 50 {
            drawFooter(context: context)
            context.beginPage()
            return margin
        }
        return y
    }
    
    private static func colorFromHex(_ hex: String) -> UIColor {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: 1.0
        )
    }
    
    /// Determines the most common currency from expenses for summary display
    private static func formatAmount(_ amount: Decimal, expenses: [Expense]) -> String {
        // Find most common currency
        let currencyCounts = Dictionary(grouping: expenses, by: { $0.currency })
            .mapValues { $0.count }
        let mainCurrency = currencyCounts.max(by: { $0.value < $1.value })?.key ?? "SGD"
        let symbol = (Currency(rawValue: mainCurrency) ?? .sgd).symbol
        
        return String(format: "%@%.2f", symbol, NSDecimalNumber(decimal: amount).doubleValue)
    }
}
