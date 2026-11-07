import SwiftUI

/// Interactive Default-theme widgets for the approved Training Home page.
/// Their outer sizes and positions are owned by HomePageGrid and are unchanged.
struct DefaultTrainingWidgetView: View {
    let widget: HomeWidget
    let palette: ThemePalette
    let state: LogbookState
    let openTraining: () -> Void

    @State private var selectedTemplate: WorkoutTemplate?
    @State private var selectedCalendarDate: Date?

    var body: some View {
        Group {
            if widget.kind == .workoutSplit {
                splitCard
            } else {
                calendarCard
            }
        }
        .sheet(item: $selectedTemplate) { template in
            NavigationStack { WorkoutTemplateScreen(templateID: template.id) }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: Binding(
            get: { selectedCalendarDate != nil },
            set: { if !$0 { selectedCalendarDate = nil } }
        )) {
            WorkoutCalendarScreen(initialDate: selectedCalendarDate ?? .now)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private var tokens: ThemeTokens { LogbookTheme.defaultTheme.tokens }
    private var templates: [WorkoutTemplate] {
        let lookup = Dictionary(uniqueKeysWithValues: state.training.templates.map { ($0.id, $0) })
        return state.training.activeProgram?.templateIDs.compactMap { lookup[$0] } ?? []
    }
    private var upcoming: [WorkoutTemplate] {
        guard !templates.isEmpty else { return [] }
        let start = state.training.activeProgram?.rotationIndex ?? 0
        return (0..<templates.count).map { templates[(start + $0) % templates.count] }.prefix(8).map { $0 }
    }
    private var scheduledID: UUID? { state.training.scheduledTemplate?.id }

    private var splitCard: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(palette.accentColor)
                Text("WORKOUT SPLIT")
                    .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                    .tracking(0.45)
                    .lineLimit(1)
                Spacer(minLength: 2)
                Text(state.training.activeProgram?.name ?? "Program")
                    .font(.system(size: 7.5, weight: .medium, design: .rounded))
                    .lineLimit(1)
                    .foregroundStyle(palette.mutedColor)
            }
            .foregroundStyle(palette.mutedColor)

            if upcoming.isEmpty {
                Spacer(minLength: 0)
                Label("Add workouts to your split", systemImage: "dumbbell")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(palette.mutedColor)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer(minLength: 0)
            } else {
                // Keep the approved compact two-column split even when a program
                // has fewer than eight workouts. Unused cells remain empty.
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 5), GridItem(.flexible(), spacing: 5)], spacing: 5) {
                    ForEach(Array(upcoming.enumerated()), id: \.element.id) { offset, template in
                        splitTile(template, offset: offset)
                    }
                    ForEach(upcoming.count..<8, id: \.self) { _ in
                        Color.clear.frame(maxWidth: .infinity).frame(height: 27)
                    }
                }
                .frame(maxHeight: .infinity)
            }

            Button(action: openTraining) {
                HStack(spacing: 3) {
                    Text("Edit Full Split")
                    Image(systemName: "chevron.right").font(.system(size: 7, weight: .bold))
                    Spacer()
                    if templates.count > 8 { Text("Next 8 of \(templates.count)") }
                }
                .font(.system(size: 8, weight: .semibold, design: .rounded))
                .foregroundStyle(palette.accentColor)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("training-split-full")
        }
        .padding(11)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(tokens.surfaceTint.opacity(tokens.cardOpacity), in: RoundedRectangle(cornerRadius: tokens.cornerRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: tokens.cornerRadius, style: .continuous).stroke(palette.accentColor.opacity(tokens.borderOpacity), lineWidth: 0.9))
        .shadow(color: .black.opacity(tokens.shadowOpacity), radius: tokens.cardShadowRadius, x: 0, y: 7)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home-widget-workout-split")
    }

    private func splitTile(_ template: WorkoutTemplate, offset: Int) -> some View {
        let templateIndex = templates.firstIndex(where: { $0.id == template.id }) ?? 0
        let isNext = template.id == scheduledID
        let lastSession = state.training.visibleCompletedSessions
            .filter { $0.templateID == template.id || ($0.templateID == nil && $0.templateName == template.name) }
            .max { ($0.finishedAt ?? $0.startedAt) < ($1.finishedAt ?? $1.startedAt) }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        let lastText = lastSession.map { formatter.localizedString(for: $0.finishedAt ?? $0.startedAt, relativeTo: .now) } ?? "Not yet"

        return Button { selectedTemplate = template } label: {
            HStack(alignment: .center, spacing: 4) {
                Text("\(templateIndex + 1)")
                    .font(.system(size: 8, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(isNext ? palette.onAccentColor : palette.accentColor)
                    .frame(width: 15, height: 15)
                    .background(isNext ? palette.accentColor : palette.accentColor.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 2) {
                        if isNext { Image(systemName: "play.fill").font(.system(size: 6, weight: .bold)) }
                        Text(template.name).lineLimit(1).minimumScaleFactor(0.75)
                    }
                    Text("Last · \(lastText)")
                        .font(.system(size: 6.5, weight: .regular, design: .rounded))
                        .lineLimit(1)
                        .foregroundStyle(palette.mutedColor)
                }
                .font(.system(size: 8, weight: isNext ? .semibold : .medium, design: .rounded))
                .foregroundStyle(palette.textColor)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity, minHeight: 27, maxHeight: 27, alignment: .leading)
            .background(isNext ? palette.accentColor.opacity(0.18) : Color.white.opacity(0.3), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(isNext ? palette.accentColor.opacity(0.5) : palette.accentColor.opacity(0.1), lineWidth: 0.7))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Workout \(templateIndex + 1), \(template.name), last completed \(lastText)\(isNext ? ", next scheduled" : "")")
        .accessibilityIdentifier("training-split-workout-\(offset + 1)")
    }

    private var month: Date {
        let start = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: .now)) ?? .now
        return Calendar.current.date(byAdding: .month, value: monthOffset, to: start) ?? start
    }
    @State private var monthOffset = 0

    private var monthDays: [Date?] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: month),
              let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
        let leading = (calendar.component(.weekday, from: interval.start) - calendar.firstWeekday + 7) % 7
        let days = range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: interval.start) }
        let values = Array<Date?>(repeating: nil, count: leading) + days.map(Optional.some)
        let trailing = (7 - values.count % 7) % 7
        return values + Array<Date?>(repeating: nil, count: trailing)
    }
    private var weekdaySymbols: [String] {
        let symbols = DateFormatter().veryShortWeekdaySymbols ?? ["S", "M", "T", "W", "T", "F", "S"]
        let offset = max(0, Calendar.current.firstWeekday - 1)
        return (0..<symbols.count).map { symbols[($0 + offset) % symbols.count] }
    }
    private var monthlySessions: [WorkoutSession] {
        let calendar = Calendar.current
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: month) else { return [] }
        let startKey = LocalDay.string(month)
        let endKey = LocalDay.string(nextMonth)
        return state.training.visibleCompletedSessions.filter { $0.localDate >= startKey && $0.localDate < endKey }
    }

    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: "calendar")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(palette.accentColor)
                Text("WORKOUT CALENDAR")
                    .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                    .tracking(0.45)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Button { monthOffset -= 1 } label: { Image(systemName: "chevron.left").font(.system(size: 8, weight: .bold)).frame(width: 19, height: 20) }
                    .accessibilityLabel("Previous workout month")
                    .accessibilityIdentifier("training-calendar-previous")
                Button { monthOffset += 1 } label: { Image(systemName: "chevron.right").font(.system(size: 8, weight: .bold)).frame(width: 19, height: 20) }
                    .accessibilityLabel("Next workout month")
                    .accessibilityIdentifier("training-calendar-next")
            }
            .buttonStyle(.plain)
            .foregroundStyle(palette.mutedColor)

            HStack {
                Text(month.formatted(.dateTime.month(.wide).year()))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(palette.textColor)
                    .accessibilityIdentifier("training-calendar-month-label")
                Spacer()
                Text("\(monthlySessions.count) completed")
                    .font(.system(size: 7.5, weight: .medium, design: .rounded))
                    .foregroundStyle(palette.mutedColor)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol.uppercased())
                        .font(.system(size: 6.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(palette.mutedColor)
                        .frame(maxWidth: .infinity, minHeight: 9)
                }
                ForEach(Array(monthDays.enumerated()), id: \.offset) { _, date in
                    if let date { calendarDay(date) }
                    else { Color.clear.frame(height: 18) }
                }
            }
            .frame(maxHeight: .infinity)

            Button { selectedCalendarDate = month } label: {
                HStack {
                    Text("Tap a date to view sessions")
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right").font(.system(size: 7, weight: .bold))
                }
                .font(.system(size: 7.5, weight: .semibold, design: .rounded))
                .foregroundStyle(palette.accentColor)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("training-calendar-open")
        }
        .padding(11)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(tokens.surfaceTint.opacity(tokens.cardOpacity), in: RoundedRectangle(cornerRadius: tokens.cornerRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: tokens.cornerRadius, style: .continuous).stroke(palette.accentColor.opacity(tokens.borderOpacity), lineWidth: 0.9))
        .shadow(color: .black.opacity(tokens.shadowOpacity), radius: tokens.cardShadowRadius, x: 0, y: 7)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home-widget-workout-calendar")
    }

    private func calendarDay(_ date: Date) -> some View {
        let daySessions = monthlySessions.filter { $0.localDate == LocalDay.string(date) }
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(date)
        let isCurrentWeek = calendar.isDate(date, equalTo: .now, toGranularity: .weekOfYear)
        return Button { selectedCalendarDate = date } label: {
            VStack(spacing: 1) {
                Text(date.formatted(.dateTime.day()))
                    .font(.system(size: 7.5, weight: isToday ? .bold : .medium, design: .rounded).monospacedDigit())
                    .lineLimit(1)
                if let first = daySessions.first {
                    Text(String(first.templateName.prefix(2)).uppercased())
                        .font(.system(size: 5.8, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                } else {
                    Circle().fill(Color.clear).frame(width: 3, height: 3)
                }
                if daySessions.count > 1 {
                    Text("+\(daySessions.count - 1)")
                        .font(.system(size: 5, weight: .bold, design: .rounded))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 18, maxHeight: 18)
            .background(isCurrentWeek ? palette.accentColor.opacity(0.08) : Color.clear, in: RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(isToday ? palette.accentColor : (daySessions.isEmpty ? Color.clear : palette.accentColor.opacity(0.3)), lineWidth: isToday ? 1 : 0.6))
            .foregroundStyle(daySessions.isEmpty ? palette.textColor.opacity(0.8) : palette.accentColor)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(date.formatted(date: .complete, time: .omitted)), \(daySessions.count) workouts")
        .accessibilityIdentifier("training-calendar-day-\(LocalDay.string(date))")
    }
}
