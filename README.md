# 📸 SpendSnap

**Photo-Based Spending Tracker for iOS**

SpendSnap makes personal expense tracking effortless. Take a photo of what you're spending on, pick a category, enter the amount — done. At the end of each month, get a clear report showing where your money went.

---

## ✨ Features

### Core
- **Photo capture** — snap a photo of your purchase using the built-in camera
- **Photo library** — choose an existing photo, or skip the photo entirely
- **15 spending categories** — tap-to-pick grid with icons (Breakfast, Lunch, Transport, Shopping, etc.)
- **Multi-currency** — supports SGD, MYR, THB, JPY, EUR, USD, GBP, CNY with flag picker
- **Live exchange rates** — auto-converts all totals to SGD using live API rates

### Dashboard
- Today and monthly spending summaries
- Category breakdown donut chart (Swift Charts)
- Daily spending bar chart
- Recent expenses with photo thumbnails

### History
- Full expense history grouped by date
- Search by category, vendor, or notes
- Filter by category
- Swipe or tap to view, edit, or delete

### Reports
- Monthly spending report with category breakdown
- Month-over-month comparison (% change)
- **PDF export** with photos, donut chart, daily bar chart, and date-grouped expenses
- Share via AirDrop, email, Messages, or save to Files

### Other
- Monthly notification reminder (1st of each month)
- Dark mode support
- All data stored locally on device (SwiftData)
- Settings with exchange rate display and data management

---

## 📱 Screenshots

<!-- Add your screenshots here -->
<!-- ![Dashboard](screenshots/dashboard.png) -->
<!-- ![History](screenshots/history.png) -->
<!-- ![Reports](screenshots/reports.png) -->
<!-- ![New Expense](screenshots/new-expense.png) -->

---

## 🛠 Tech Stack

| Component | Technology |
|-----------|-----------|
| Language | Swift 5.9+ |
| UI | SwiftUI |
| Architecture | MVVM |
| Local Database | SwiftData |
| Camera | AVFoundation + PhotosUI |
| Charts | Swift Charts (iOS 16+) |
| PDF Generation | UIGraphicsPDFRenderer |
| Notifications | UserNotifications |
| Exchange Rates | [open.er-api.com](https://open.er-api.com) (free, no key) |

---

## 📂 Project Structure

```
SpendSnap/
├── App/                          # Entry point, DI
├── Data/
│   ├── Local/                    # CategorySeeder
│   ├── Remote/                   # Phase 3: Firebase/iCloud
│   └── Repositories/             # SwiftData CRUD
├── Domain/
│   ├── Models/                   # Expense, Category, MonthlyReport
│   ├── Protocols/                # Repository interfaces
│   └── UseCases/                 # Business logic (Phase 3+)
├── Infrastructure/
│   ├── Camera/                   # AVFoundation wrapper
│   ├── Notifications/            # Monthly reminders
│   ├── PhotoStorage/             # JPEG file management
│   ├── CurrencyService.swift     # Live exchange rates
│   └── PDFReportGenerator.swift  # PDF export with charts
├── Presentation/
│   ├── Components/               # CategoryGrid, AmountInput, Charts
│   ├── Navigation/               # TabBarView
│   ├── Screens/                  # Dashboard, History, Entry, Report, Settings
│   └── ViewModels/               # Screen logic
└── Resources/                    # Color extensions, Assets
```

---

## 🚀 Getting Started

### Requirements
- Xcode 15+
- iOS 18.0+
- Physical iPhone (camera features don't work in simulator)

### Setup
1. Clone the repository
   ```bash
   git clone https://github.com/YOUR_USERNAME/SpendSnap.git
   ```
2. Open `SpendSnap.xcodeproj` in Xcode
3. Select your physical device as the build target
4. Set your **Team** in Signing & Capabilities
5. Press `Cmd + R` to build and run

### Permissions
The app requests these permissions on first use:
- **Camera** — to photograph purchases
- **Notifications** — for monthly report reminders

---

## 🗺 Roadmap

### ✅ Phase 1 — Foundation (Complete)
Camera capture, category selection, amount entry, local storage

### ✅ Phase 2 — Dashboard & Reports (Complete)
Charts, history, monthly reports, PDF export, multi-currency, exchange rates

### ⬜ Phase 3 — Cloud Sync & Budgeting
Firebase authentication, cloud backup, budget tracking per category

### ⬜ Phase 4 — Polish & App Store
CSV export, onboarding, accessibility, App Store submission

### 🔮 Future
AI auto-classification, OCR receipt scanning, Apple Watch app, Siri shortcuts, widgets

---

## 💰 Cost

| Phase | Annual Cost | Notes |
|-------|-----------|-------|
| Phase 1-2 (Local only) | $99 | Apple Developer Program only |
| Phase 3 (Cloud — free tier) | $99 | Firebase free tier sufficient |
| Phase 3 (Cloud — scaled) | $99 + ~$5-20/mo | Beyond free tier limits |

---

## 📄 License

This project is private and confidential.

---

## 🙏 Acknowledgements

- [SF Symbols](https://developer.apple.com/sf-symbols/) — Category icons
- [open.er-api.com](https://open.er-api.com) — Free exchange rate API
- Built with SwiftUI, SwiftData, Swift Charts, AVFoundation, and PDFKit
