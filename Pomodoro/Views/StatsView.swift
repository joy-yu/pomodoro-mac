import Charts
import SwiftUI

struct StatsView: View {
    let store: PomodoroStore

    @State private var stats: PomodoroStats?

    init(store: PomodoroStore) {
        self.store = store
        _stats = State(initialValue: store.loadStats())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let stats {
                summaryCards(stats)
                DailyChartView(data: stats.dailyFocus)
                TrendChartView(data: stats.trend)
                HeatmapView(data: stats.heatmap)
                TagChartView(data: stats.tagBreakdown)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .task { loadStats() }
        .onChange(of: store.sessionVersion) { loadStats() }
    }

    private func loadStats() {
        stats = store.loadStats()
    }

    // MARK: - Summary cards

    private func summaryCards(_ stats: PomodoroStats) -> some View {
        HStack(spacing: 12) {
            summaryCard(
                title: String(localized: "stats.todayPomodoros"),
                number: "\(stats.pomodorosToday)",
                unit: nil,
                subtitle: String(localized: "stats.completedSessions")
            )
            summaryCard(
                title: String(localized: "stats.todayFocus"),
                number: "\(stats.minutesToday)",
                unit: String(localized: "unit.min"),
                subtitle: String(localized: "stats.effectiveDuration")
            )
            summaryCard(
                title: String(localized: "stats.longestStreak"),
                number: "\(stats.longestStreak)",
                unit: String(localized: "unit.days"),
                subtitle: String(localized: "stats.streakMaintenance")
            )
        }
    }

    private func summaryCard(title: String, number: String, unit: String?, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.muted)
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(number)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                if let unit {
                    Text(unit)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                }
            }
            Text(subtitle)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.ring.opacity(0.85))
        )
    }
}

// MARK: - Chart subviews

private struct DailyChartView: View {
    let data: [FocusBucket]
    @State private var hoveredDate: Date?
    @State private var hoveredItem: FocusBucket?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("stats.last14Days")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
            Chart(data) { item in
                BarMark(
                    x: .value("stats.date", item.date, unit: .day),
                    y: .value("stats.minutes", item.minutes)
                )
                .foregroundStyle(AppTheme.tomato.gradient)
                .opacity(hoveredItem == nil || hoveredItem?.id == item.id ? 1.0 : 0.45)
                .cornerRadius(5)
            }
            .chartXSelection(value: $hoveredDate)
            .animation(.easeInOut(duration: 0.15), value: hoveredItem?.id)
            .onChange(of: hoveredDate) { _, date in
                hoveredItem = date.flatMap { d in
                    data.first(where: { Calendar.current.isDate($0.date, inSameDayAs: d) })
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    if let hovered = hoveredItem,
                       let plotFrame = proxy.plotFrame,
                       let barCenter = Calendar.current.date(byAdding: .hour, value: 12, to: hovered.date),
                       let xPos: CGFloat = proxy.position(forX: barCenter) {
                        let plotRect = geo[plotFrame]
                        let absX = plotRect.origin.x + xPos
                        Rectangle()
                            .fill(AppTheme.ink.opacity(0.12))
                            .frame(width: 1, height: plotRect.height)
                            .position(x: absX, y: plotRect.midY)
                            .allowsHitTesting(false)
                        chartTooltip(hovered.date, minutes: Int(hovered.minutes))
                            .fixedSize()
                            .position(
                                x: absX.clamped(to: 52...(geo.size.width - 52)),
                                y: plotRect.minY - 14
                            )
                            .allowsHitTesting(false)
                    }
                }
            }
            .frame(height: 160)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(AppTheme.ring.opacity(0.85)))
    }
}

private struct TrendChartView: View {
    let data: [FocusBucket]
    @State private var hoveredDate: Date?
    @State private var hoveredItem: FocusBucket?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("stats.trend30")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
            Chart(data) { item in
                LineMark(
                    x: .value("stats.date", item.date),
                    y: .value("stats.minutes", item.minutes)
                )
                .foregroundStyle(AppTheme.olive)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                AreaMark(
                    x: .value("stats.date", item.date),
                    y: .value("stats.minutes", item.minutes)
                )
                .foregroundStyle(AppTheme.olive.opacity(0.18))
            }
            .chartXSelection(value: $hoveredDate)
            .animation(nil, value: hoveredDate)
            .onChange(of: hoveredDate) { _, date in
                hoveredItem = date.flatMap { d in
                    data.min(by: { abs($0.date.timeIntervalSince(d)) < abs($1.date.timeIntervalSince(d)) })
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    if let hovered = hoveredItem,
                       let plotFrame = proxy.plotFrame,
                       let xPos: CGFloat = proxy.position(forX: hovered.date),
                       let yPos: CGFloat = proxy.position(forY: hovered.minutes) {
                        let plotRect = geo[plotFrame]
                        let absX = plotRect.origin.x + xPos
                        let absY = plotRect.origin.y + yPos
                        Rectangle()
                            .fill(AppTheme.ink.opacity(0.12))
                            .frame(width: 1, height: plotRect.height)
                            .position(x: absX, y: plotRect.midY)
                            .allowsHitTesting(false)
                        Circle()
                            .fill(AppTheme.olive)
                            .frame(width: 9, height: 9)
                            .position(x: absX, y: absY)
                            .allowsHitTesting(false)
                        chartTooltip(hovered.date, minutes: Int(hovered.minutes))
                            .fixedSize()
                            .position(
                                x: absX.clamped(to: 52...(geo.size.width - 52)),
                                y: plotRect.minY - 14
                            )
                            .allowsHitTesting(false)
                    }
                }
            }
            .frame(height: 180)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(AppTheme.ring.opacity(0.85)))
    }
}

private struct HeatmapView: View {
    let data: [HeatmapBucket]
    @State private var hoveredItem: HeatmapBucket?

    /// Derive column count from data length assuming 7-row display (one row per day-of-week).
    private var columns: Int { max(1, data.count / 7) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("stats.heatmap")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Spacer()
                if let item = hoveredItem {
                    Text(
                        "\(item.date.formatted(.dateTime.month(.abbreviated).day())) · \(item.minutes) \(String(localized: "unit.min"))"
                    )
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.muted)
                    .transition(.opacity.animation(.easeInOut(duration: 0.1)))
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(14), spacing: 6), count: columns), spacing: 6) {
                ForEach(data) { entry in
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(heatColor(for: entry.minutes))
                        .frame(width: 14, height: 14)
                        .scaleEffect(hoveredItem?.id == entry.id ? 1.4 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: hoveredItem?.id)
                        .onHover { hovering in
                            hoveredItem = hovering ? entry : nil
                        }
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(AppTheme.ring.opacity(0.85)))
    }

    private func heatColor(for minutes: Int) -> Color {
        switch minutes {
        case 0:           return AppTheme.paperShadow.opacity(0.25)
        case 1..<25:      return AppTheme.tomato.opacity(0.35)
        case 25..<50:     return AppTheme.tomato.opacity(0.55)
        case 50..<90:     return AppTheme.tomato.opacity(0.75)
        default:          return AppTheme.tomatoDark
        }
    }
}

private struct TagChartView: View {
    let data: [TagBreakdown]
    @State private var hoveredTag: TagBreakdown?
    @State private var hoveredTagAngle: Double?

    var body: some View {
        let totalMinutes = data.reduce(0.0) { $0 + $1.minutes }
        return VStack(alignment: .leading, spacing: 10) {
            Text("stats.tagBreakdown")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
            ZStack {
                Chart(data) { item in
                    SectorMark(
                        angle: .value("stats.minutes", item.minutes),
                        innerRadius: .ratio(0.55),
                        angularInset: 2
                    )
                    .foregroundStyle(AppTheme.tagColor(for: item.colorHex))
                    .opacity(hoveredTag == nil || hoveredTag?.id == item.id ? 1.0 : 0.35)
                }
                // chartAngleSelection returns the cumulative data value (minutes) at the
                // hover position — not a raw angle. The loop below relies on this Charts behavior.
                .chartAngleSelection(value: $hoveredTagAngle)
                .onChange(of: hoveredTagAngle) { _, angle in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        hoveredTag = angle.flatMap { a in
                            var cumulative = 0.0
                            for item in data {
                                cumulative += item.minutes
                                if a <= cumulative { return item }
                            }
                            return nil
                        }
                    }
                }
                .frame(height: 220)
                .animation(.easeInOut(duration: 0.15), value: hoveredTag?.id)

                if let tag = hoveredTag {
                    let pct = totalMinutes > 0 ? Int((tag.minutes / totalMinutes) * 100) : 0
                    VStack(spacing: 3) {
                        Text(tag.name)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.ink)
                        Text("\(Int(tag.minutes)) \(String(localized: "unit.min"))")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.muted)
                        Text("\(pct)%")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.muted)
                    }
                    .transition(.opacity.animation(.easeInOut(duration: 0.15)))
                }
            }
            .frame(height: 220)

            // spacing: 0 + vertical padding per row eliminates hover gaps between items
            VStack(spacing: 0) {
                ForEach(data) { item in
                    HStack {
                        Circle().fill(AppTheme.tagColor(for: item.colorHex)).frame(width: 8, height: 8)
                        Text(item.name)
                        Spacer()
                        Text("\(Int(item.minutes)) \(String(localized: "unit.min"))")
                            .foregroundStyle(hoveredTag?.id == item.id ? AppTheme.ink : AppTheme.muted)
                    }
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .padding(.vertical, 5)
                    .opacity(hoveredTag == nil || hoveredTag?.id == item.id ? 1.0 : 0.5)
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            hoveredTag = hovering ? item : nil
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(AppTheme.ring.opacity(0.85)))
    }
}

// MARK: - Shared tooltip (used by DailyChartView and TrendChartView)

private func chartTooltip(_ date: Date, minutes: Int) -> some View {
    Text("\(date.formatted(.dateTime.month(.abbreviated).day())) · \(minutes) \(String(localized: "unit.min"))")
        .font(.system(size: 11, weight: .medium, design: .rounded))
        .foregroundStyle(AppTheme.ring)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(AppTheme.ink.opacity(0.82))
        )
}
