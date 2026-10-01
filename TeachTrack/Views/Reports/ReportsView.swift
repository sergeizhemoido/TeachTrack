//
//  ReportsView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/11/26.
//
import SwiftUI

struct ReportsView: View {

    @State private var useDateRange = false
    @State private var startDate = Calendar.current.dateInterval(
        of: .month, for: .now
    )?.start ?? .now
    @State private var endDate = Date()

    private var selectedRange: ReportDateRange? {
        useDateRange ? ReportDateRange(from: startDate, through: endDate) : nil
    }

    var body: some View {

        List {
            TeachTrackHero(
                eyebrow: "Insights",
                title: "Understand your work",
                detail: "Explore lessons, attendance, and financial activity.",
                symbol: "chart.bar.xaxis",
                color: TeachTrackDesign.sunflower
            )

            Section("Report Period") {
                Toggle("Use Date Range", isOn: $useDateRange)
                    .accessibilityIdentifier("reportDateRangeToggle")
                if useDateRange {
                    DatePicker("From", selection: $startDate, displayedComponents: .date)
                        .accessibilityIdentifier("reportStartDatePicker")
                    DatePicker("Through", selection: $endDate, displayedComponents: .date)
                        .accessibilityIdentifier("reportEndDatePicker")
                }
            }
            .onChange(of: startDate) { _, newValue in
                if Calendar.current.startOfDay(for: newValue) >
                    Calendar.current.startOfDay(for: endDate) {
                    endDate = newValue
                }
            }
            .onChange(of: endDate) { _, newValue in
                if Calendar.current.startOfDay(for: newValue) <
                    Calendar.current.startOfDay(for: startDate) {
                    startDate = newValue
                }
            }

            NavigationLink {
                LessonHistoryReportView(range: selectedRange)
            } label: {
                TeachTrackIconRow(
                    title: "Lesson History",
                    detail: "Completed and past lessons",
                    symbol: "calendar",
                    color: TeachTrackDesign.sky
                )
            }
            .accessibilityLabel("Lesson History")

            NavigationLink {
                FinanceHistoryView(range: selectedRange)
            } label: {
                TeachTrackIconRow(
                    title: "Payment and Charge History",
                    detail: "Every financial entry",
                    symbol: "list.bullet.rectangle",
                    color: TeachTrackDesign.blue
                )
            }
            .accessibilityLabel("Payment and Charge History")

            NavigationLink {

                RevenueReportView(range: selectedRange)

            } label: {

                TeachTrackIconRow(
                    title: "Revenue",
                    detail: "Earnings and receipts",
                    symbol: "dollarsign.circle",
                    color: TeachTrackDesign.amber
                )
            }
            .accessibilityLabel("Revenue")

            NavigationLink {

                AttendanceReportView(range: selectedRange)

            } label: {

                TeachTrackIconRow(
                    title: "Attendance",
                    detail: "Student participation",
                    symbol: "person.3",
                    color: TeachTrackDesign.coral
                )
            }
            .accessibilityLabel("Attendance")

            NavigationLink {

                DebtReportView(range: selectedRange)

            } label: {

                TeachTrackIconRow(
                    title: "Debts",
                    detail: "Unpaid lesson balances",
                    symbol: "exclamationmark.triangle",
                    color: TeachTrackDesign.warning
                )
            }
            .accessibilityLabel("Debts")
        }
        .teachTrackScreen()
        .navigationTitle("Reports")
        .navigationBarTitleDisplayMode(.inline)
    }
}
