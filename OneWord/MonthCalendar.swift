//
//  MonthCalendar.swift
//  OneWord
//
//  A SwiftUI month grid. macOS's DatePicker(.graphical) bridges to the legacy
//  NSDatePicker calendar — cramped metrics, hard blue selection, stepper arrows —
//  and ignores SwiftUI styling, so it can't be made to match the app. Drawing the
//  grid here is what gets the monochrome editorial look and a real hover state.
//

import SwiftUI

struct MonthCalendar: View {
    @Binding var selection: Date
    /// Days after this render dimmed and aren't selectable.
    var latest: Date = .now
    var onPick: (Date) -> Void

    @Environment(\.colorScheme) private var scheme
    @State private var month: Date
    @State private var hovered: Date?

    private let calendar = Calendar.current
    private static let cell = CGSize(width: 34, height: 30)

    init(selection: Binding<Date>, latest: Date = .now, onPick: @escaping (Date) -> Void) {
        _selection = selection
        _month = State(initialValue: selection.wrappedValue)
        self.latest = latest
        self.onPick = onPick
    }

    var body: some View {
        let t = Theme.of(scheme)
        VStack(spacing: 0) {
            header(t)
            weekdayRow(t)
            grid(t)
            todayButton(t)
        }
        .padding(14)
        // No background fill — the popover's own material, border and shadow are
        // what separate it from the page. Painting it opaque erased those edges.
    }

    // MARK: - Header

    private func header(_ t: Theme) -> some View {
        HStack(spacing: 2) {
            Text(month.formatted(.dateTime.month(.wide).year()))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(t.ink)
                .contentTransition(.numericText())
            Spacer(minLength: 8)
            step("chevron.left", by: -1, t)
            step("chevron.right", by: 1, t)
        }
        .padding(.bottom, 12)
    }

    private func step(_ symbol: String, by delta: Int, _ t: Theme) -> some View {
        Button {
            guard let next = calendar.date(byAdding: .month, value: delta, to: month) else { return }
            withAnimation(.easeOut(duration: 0.18)) { month = next }
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(t.ink)
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // Nothing to browse past the newest allowed month.
        .disabled(delta > 0 && calendar.isDate(month, equalTo: latest, toGranularity: .month))
    }

    // MARK: - Grid

    private func weekdayRow(_ t: Theme) -> some View {
        HStack(spacing: 2) {
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.system(size: 10, weight: .semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(t.muted)
                    .frame(width: Self.cell.width)
            }
        }
        .padding(.bottom, 6)
    }

    private func grid(_ t: Theme) -> some View {
        let columns = Array(repeating: GridItem(.fixed(Self.cell.width), spacing: 2), count: 7)
        return LazyVGrid(columns: columns, spacing: 2) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                if let day { dayCell(day, t) } else { Color.clear.frame(height: Self.cell.height) }
            }
        }
    }

    private func dayCell(_ date: Date, _ t: Theme) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selection)
        let isToday = calendar.isDateInToday(date)
        let isFuture = calendar.startOfDay(for: date) > calendar.startOfDay(for: latest)
        let isHovered = hovered.map { calendar.isDate($0, inSameDayAs: date) } ?? false

        return Button {
            selection = date
            onPick(date)
        } label: {
            Text(date.formatted(.dateTime.day()))
                .font(.system(size: 13, weight: isSelected || isToday ? .semibold : .regular))
                .foregroundStyle(isSelected ? t.background : (isFuture ? t.muted.opacity(0.4) : t.ink))
                .frame(width: Self.cell.width, height: Self.cell.height)
                .background {
                    let shape = RoundedRectangle(cornerRadius: 7, style: .continuous)
                    if isSelected {
                        shape.fill(t.ink)
                    } else if isHovered, !isFuture {
                        shape.fill(t.hairline)
                    } else if isToday {
                        shape.strokeBorder(t.rule, lineWidth: 1)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
        .onHover { hovered = $0 ? date : nil }
    }

    /// Only an escape hatch back to today — nothing to show when you're already there.
    @ViewBuilder
    private func todayButton(_ t: Theme) -> some View {
        if !calendar.isDateInToday(selection) {
            Divider().padding(.top, 10)
            Button {
                let today = Date()
                selection = today
                month = today
                onPick(today)
            } label: {
                Text("Go to Today")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(t.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(t.hairline, in: Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .padding(.top, 10)
        }
    }

    // MARK: - Date math

    /// Leading blanks so the 1st lands under its weekday, then the month's days.
    private var days: [Date?] {
        guard let start = calendar.dateInterval(of: .month, for: month)?.start,
              let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
        let leading = (calendar.component(.weekday, from: start) - calendar.firstWeekday + 7) % 7
        return Array(repeating: nil, count: leading)
            + range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: start) }
    }

    /// Rotated so the first column matches the locale's first weekday.
    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let shift = calendar.firstWeekday - 1
        return Array(symbols[shift...] + symbols[..<shift])
    }
}

#Preview {
    MonthCalendar(selection: .constant(.now)) { _ in }
}
