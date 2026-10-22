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
    /// Days before this render dimmed too. nil = back to day zero.
    var earliest: Date?
    /// Shown behind an ⓘ beside the month title — why the dimmed days are dimmed.
    var info: String?
    var onPick: (Date) -> Void

    @Environment(\.colorScheme) private var scheme
    /// For Midnight's palette and rounder day cells.
    @Environment(\.doodle) private var doodle
    @State private var month: Date
    @State private var hovered: Date?
    @State private var showingInfo = false

    private let calendar = Calendar.current
    /// A pointer is happy with 34×30; a thumb wants 44.
    private var cell: CGSize { isPhone ? CGSize(width: 44, height: 40) : CGSize(width: 34, height: 30) }

    init(selection: Binding<Date>, latest: Date = .now, earliest: Date? = nil, info: String? = nil,
         onPick: @escaping (Date) -> Void) {
        _selection = selection
        _month = State(initialValue: selection.wrappedValue)
        self.latest = latest
        self.earliest = earliest
        self.info = info
        self.onPick = onPick
    }

    var body: some View {
        let t = Theme.of(scheme, doodle)
        VStack(spacing: 0) {
            header(t)
            weekdayRow(t)
            grid(t)
            todayButton(t)
        }
        .padding(14)
        // The selection can move from outside (day steppers, "go to today"), and
        // the grid only shows one month — follow it there or the pick vanishes.
        .onChange(of: selection) { _, picked in
            guard !calendar.isDate(picked, equalTo: month, toGranularity: .month) else { return }
            withAnimation(.easeOut(duration: 0.18)) { month = picked }
        }
        // No background fill — the popover's own material, border and shadow are
        // what separate it from the page. Painting it opaque erased those edges.
    }

    // MARK: - Header

    /// The title is a menu, not a label: stepping one month at a time is fine for
    /// last week and useless for last spring.
    private func header(_ t: Theme) -> some View {
        HStack(spacing: 2) {
            Menu {
                Picker("Month", selection: monthBinding) {
                    ForEach(Array(calendar.monthSymbols.enumerated()), id: \.offset) { index, name in
                        Text(name).tag(index + 1)
                    }
                }
                .pickerStyle(.menu)
                Picker("Year", selection: yearBinding) {
                    ForEach(years, id: \.self) { Text(String($0)).tag($0) }
                }
                .pickerStyle(.menu)
            } label: {
                // ponytail: a plain Text label. macOS draws a Menu's label through
                // AppKit, which keeps only simple Text/Image — a hand-drawn chevron
                // beside it gets dropped, so let the menu draw its own indicator.
                Text(month.formatted(.dateTime.month(.wide).year()))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(t.ink)
                    .contentTransition(.numericText())
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help("Jump to a month or year")
            if let info {
                Button { showingInfo = true } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 13))
                        .foregroundStyle(t.muted)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Which days can I pick?")
                .alert("Which days can I pick?", isPresented: $showingInfo) {} message: { Text(info) }
            }
            Spacer(minLength: 8)
            step("chevron.left", by: -1, t)
            step("chevron.right", by: 1, t)
        }
        .padding(.bottom, 12)
    }

    private var monthBinding: Binding<Int> {
        Binding(get: { calendar.component(.month, from: month) },
                set: { jump(month: $0, year: calendar.component(.year, from: month)) })
    }

    private var yearBinding: Binding<Int> {
        Binding(get: { calendar.component(.year, from: month) },
                set: { jump(month: calendar.component(.month, from: month), year: $0) })
    }

    /// Land on that month, clamped between `earliest`'s and `latest`'s — the grid
    /// never browses past the allowed days, whichever way you got there.
    private func jump(month wanted: Int, year: Int) {
        var parts = DateComponents()
        parts.year = year
        parts.month = wanted
        parts.day = 1
        guard let target = calendar.date(from: parts),
              let newest = calendar.dateInterval(of: .month, for: latest)?.start else { return }
        let oldest = earliest.flatMap { calendar.dateInterval(of: .month, for: $0)?.start } ?? target
        withAnimation(.easeOut(duration: 0.18)) { month = max(oldest, min(target, newest)) }
    }

    /// 2001 is the floor because the word rotation counts days from the reference
    /// date — there is no history before day zero.
    private var years: [Int] {
        let newest = calendar.component(.year, from: latest)
        let oldest = max(2001, earliest.map { calendar.component(.year, from: $0) } ?? 2001)
        return Array((oldest...max(oldest, newest)).reversed())
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
        // Nothing to browse past the newest or oldest allowed month.
        .disabled(delta > 0 ? calendar.isDate(month, equalTo: latest, toGranularity: .month)
                            : earliest.map { calendar.isDate(month, equalTo: $0, toGranularity: .month) } ?? false)
    }

    // MARK: - Grid

    private func weekdayRow(_ t: Theme) -> some View {
        HStack(spacing: 2) {
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.system(size: 10, weight: .semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(t.muted)
                    .frame(width: cell.width)
            }
        }
        .padding(.bottom, 6)
    }

    private func grid(_ t: Theme) -> some View {
        let columns = Array(repeating: GridItem(.fixed(cell.width), spacing: 2), count: 7)
        return LazyVGrid(columns: columns, spacing: 2) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                if let day { dayCell(day, t) } else { Color.clear.frame(height: cell.height) }
            }
        }
    }

    private func dayCell(_ date: Date, _ t: Theme) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selection)
        let isToday = calendar.isDateInToday(date)
        let day = calendar.startOfDay(for: date)
        let isFuture = day > calendar.startOfDay(for: latest)
            || earliest.map { day < calendar.startOfDay(for: $0) } ?? false   // out of range either way
        let isHovered = hovered.map { calendar.isDate($0, inSameDayAs: date) } ?? false

        return Button {
            selection = date
            onPick(date)
        } label: {
            Text(date.formatted(.dateTime.day()))
                .font(.system(size: 13, weight: isSelected || isToday ? .semibold : .regular))
                .foregroundStyle(isSelected ? t.background : (isFuture ? t.muted.opacity(0.4) : t.ink))
                .frame(width: cell.width, height: cell.height)
                .background {
                    let shape = RoundedRectangle(cornerRadius: t.radius(7), style: .continuous)
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
