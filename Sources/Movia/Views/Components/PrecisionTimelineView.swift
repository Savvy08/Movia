import SwiftUI

public struct PrecisionTimelineView: View {
    @ObservedObject var appState: AppState
    let item: VideoItem
    @State private var dragSegmentInitialStart: Double? = nil
    
    public init(appState: AppState, item: VideoItem) {
        self.appState = appState
        self.item = item
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            // 1. Header Toolbar: Controls, Precision Timecodes, Zoom
            headerToolbar
                .frame(height: 28)
            
            // 2. Interactive Precision Timeline (Ruler + Filmstrip + Handles + Playhead)
            timelineTrack
            
            // 3. Bottom Row: Motion Blur & Segment Export Toggle
            bottomSettingsRow
                .frame(height: 22)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(height: 154)
        .fixedSize(horizontal: false, vertical: true)
        .background(
            RoundedRectangle(cornerRadius: FCPTheme.cardRadius(for: appState.uiTheme))
                .fill(appState.uiTheme == .liquidGlass ? FCPTheme.liquidCardBackground : FCPTheme.cardBackground.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: FCPTheme.cardRadius(for: appState.uiTheme))
                        .stroke(FCPTheme.borderColor(for: appState.uiTheme), lineWidth: 1)
                )
        )
    }
    
    // MARK: - 1. Header Toolbar
    private var headerToolbar: some View {
        HStack(spacing: 12) {
            // Quick In / Out / Cut / Reset Buttons
            HStack(spacing: 6) {
                // In-Point Button (Icon only)
                Button(action: {
                    appState.setInAtCurrentTime()
                }) {
                    Image(systemName: "arrow.right.to.line")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(FCPTheme.textPrimary)
                        .frame(width: 26, height: 26)
                        .themedCard(theme: appState.uiTheme, cornerRadius: 6)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("i", modifiers: [])
                .help("Установить точку In (I или [ / Х)")
                
                // Out-Point Button (Icon only)
                Button(action: {
                    appState.setOutAtCurrentTime()
                }) {
                    Image(systemName: "arrow.left.to.line")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(FCPTheme.textPrimary)
                        .frame(width: 26, height: 26)
                        .themedCard(theme: appState.uiTheme, cornerRadius: 6)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("o", modifiers: [])
                .help("Установить точку Out (O или ] / Ъ)")
                
                // Secondary hidden buttons to register [ and ] shortcuts with SwiftUI
                Button("") { appState.setInAtCurrentTime() }
                    .keyboardShortcut("[", modifiers: [])
                    .frame(width: 0, height: 0)
                    .opacity(0)
                Button("") { appState.setOutAtCurrentTime() }
                    .keyboardShortcut("]", modifiers: [])
                    .frame(width: 0, height: 0)
                    .opacity(0)
                
                // Scissors / Split Button (Icon only)
                Button(action: {
                    appState.splitAtCurrentTime()
                }) {
                    Image(systemName: "scissors")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(FCPTheme.textPrimary)
                        .frame(width: 26, height: 26)
                        .themedCard(theme: appState.uiTheme, cornerRadius: 6)
                }
                .buttonStyle(.plain)
                .help("Обрезать по плейхеду (B / ⌘B)")
                
                // Reset Button
                Button(action: {
                    appState.resetTrim()
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 10))
                        .foregroundColor(FCPTheme.textMuted)
                        .frame(width: 26, height: 26)
                        .themedCard(theme: appState.uiTheme, cornerRadius: 6)
                }
                .buttonStyle(.plain)
                .help("Сбросить диапазон на всю длину (⌥X)")
            }
            
            Spacer()
            
            // Editable Precision Millisecond Fields (In, Out, Duration)
            HStack(spacing: 8) {
                PrecisionTimecodeField(
                    label: "In:",
                    seconds: appState.trimStart,
                    theme: appState.uiTheme,
                    onCommit: { newSec in
                        let clamped = max(0.0, min(appState.trimEnd - 0.05, newSec))
                        appState.trimStart = clamped
                        appState.seek(to: clamped)
                    },
                    onStep: { delta in
                        let clamped = max(0.0, min(appState.trimEnd - 0.05, appState.trimStart + delta))
                        appState.trimStart = clamped
                        appState.seek(to: clamped)
                    }
                )
                
                PrecisionTimecodeField(
                    label: "Out:",
                    seconds: appState.trimEnd,
                    theme: appState.uiTheme,
                    onCommit: { newSec in
                        let clamped = max(appState.trimStart + 0.05, min(item.duration, newSec))
                        appState.trimEnd = clamped
                        appState.seek(to: clamped)
                    },
                    onStep: { delta in
                        let clamped = max(appState.trimStart + 0.05, min(item.duration, appState.trimEnd + delta))
                        appState.trimEnd = clamped
                        appState.seek(to: clamped)
                    }
                )
                
                PrecisionTimecodeField(
                    label: "Длит:",
                    seconds: max(0.0, appState.trimEnd - appState.trimStart),
                    theme: appState.uiTheme,
                    onCommit: { newDur in
                        guard newDur > 0.02 else { return }
                        let targetEnd = appState.trimStart + newDur
                        if targetEnd <= item.duration {
                            appState.trimEnd = targetEnd
                        } else {
                            appState.trimStart = max(0.0, item.duration - newDur)
                            appState.trimEnd = item.duration
                        }
                        appState.seek(to: appState.trimStart)
                    },
                    onStep: { delta in
                        let curDur = max(0.05, appState.trimEnd - appState.trimStart)
                        let newDur = max(0.05, curDur + delta)
                        let targetEnd = appState.trimStart + newDur
                        if targetEnd <= item.duration {
                            appState.trimEnd = targetEnd
                        } else {
                            appState.trimStart = max(0.0, item.duration - newDur)
                            appState.trimEnd = item.duration
                        }
                    }
                )
            }
            
            Spacer()
            
            // Zoom Slider & Controls (1.0x to 8.0x)
            HStack(spacing: 6) {
                Button(action: {
                    appState.timelineZoom = max(1.0, appState.timelineZoom - 0.5)
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(FCPTheme.textSecondary)
                }
                .buttonStyle(.plain)
                
                Slider(value: $appState.timelineZoom, in: 1.0...8.0, step: 0.5)
                    .accentColor(FCPTheme.accent(for: appState.uiTheme))
                    .frame(width: 80)
                
                Button(action: {
                    appState.timelineZoom = min(8.0, appState.timelineZoom + 0.5)
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(FCPTheme.textSecondary)
                }
                .buttonStyle(.plain)
                
                Text(String(format: "%.1fx", appState.timelineZoom))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(FCPTheme.textMuted)
                    .frame(width: 28, alignment: .leading)
            }
            .frame(height: 26)
            .fixedSize()
        }
    }
    
    // MARK: - 2. Precision Timeline Track (Ruler + Filmstrip + Handles + Playhead)
    private var timelineTrack: some View {
        GeometryReader { outerGeo in
            let baseWidth = outerGeo.size.width
            let trackWidth = baseWidth * CGFloat(appState.timelineZoom)
            let duration = max(0.1, item.duration)
            
            ScrollView(.horizontal, showsIndicators: appState.timelineZoom > 1.0) {
                ZStack(alignment: .topLeading) {
                    VStack(spacing: 0) {
                        // A. Detailed Ruler with Dynamically-Spaced Sub-Second Ticks
                        rulerView(width: trackWidth, duration: duration)
                            .frame(height: 18)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0, coordinateSpace: .named("timelineSpace"))
                                    .onChanged { val in
                                        let ratio = max(0.0, min(1.0, val.location.x / trackWidth))
                                        appState.seek(to: Double(ratio) * duration)
                                    }
                            )
                        
                        // B. Amber Clip Track (Reference Style: Warm Golden-Amber Pill with Dividers & Center Label)
                        ZStack(alignment: .leading) {
                            clipTrackBackground(width: trackWidth, duration: duration)
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture(minimumDistance: 0, coordinateSpace: .named("timelineSpace"))
                                        .onChanged { val in
                                            let ratio = max(0.0, min(1.0, val.location.x / trackWidth))
                                            appState.seek(to: Double(ratio) * duration)
                                        }
                                )
                            
                            // Dimmed Outside Mask (Before In-point)
                            let inX = trackWidth * CGFloat(appState.trimStart / duration)
                            let outX = trackWidth * CGFloat(appState.trimEnd / duration)
                            
                            if inX > 2 {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.black.opacity(0.65))
                                    .frame(width: max(0, inX), height: 42)
                                    .allowsHitTesting(false)
                            }
                            
                            // Dimmed Outside Mask (After Out-point)
                            if outX < trackWidth - 2 {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.black.opacity(0.65))
                                    .frame(width: max(0, trackWidth - outX), height: 42)
                                    .offset(x: outX)
                                    .allowsHitTesting(false)
                            }
                            
                            // Highlighted Slow Motion Segment Border
                            let segAccent = (appState.uiTheme == .liquidGlass) ? FCPTheme.liquidCyan : Color.white
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [segAccent.opacity(0.95), segAccent.opacity(0.5)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                                .frame(width: max(16, outX - inX), height: 42)
                                .offset(x: inX)
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture(coordinateSpace: .named("timelineSpace"))
                                        .onChanged { val in
                                            let segDuration = appState.trimEnd - appState.trimStart
                                            let deltaSec = Double(val.translation.width / trackWidth) * duration
                                            if dragSegmentInitialStart == nil {
                                                dragSegmentInitialStart = appState.trimStart
                                            }
                                            if let initStart = dragSegmentInitialStart {
                                                let newStart = max(0.0, min(duration - segDuration, initStart + deltaSec))
                                                appState.trimStart = newStart
                                                appState.trimEnd = newStart + segDuration
                                            }
                                        }
                                        .onEnded { _ in
                                            dragSegmentInitialStart = nil
                                        }
                                )
                            
                            // In-Point Handle (Left)
                            inHandleView
                                .offset(x: inX - 11)
                                .gesture(
                                    DragGesture(coordinateSpace: .named("timelineSpace"))
                                        .onChanged { val in
                                            let targetSec = Double(max(0.0, min(trackWidth, val.location.x)) / trackWidth) * duration
                                            let clamped = max(0.0, min(appState.trimEnd - 0.05, targetSec))
                                            appState.trimStart = clamped
                                            appState.seek(to: clamped)
                                        }
                                )
                            
                            // Out-Point Handle (Right)
                            outHandleView
                                .offset(x: outX - 11)
                                .gesture(
                                    DragGesture(coordinateSpace: .named("timelineSpace"))
                                        .onChanged { val in
                                            let targetSec = Double(max(0.0, min(trackWidth, val.location.x)) / trackWidth) * duration
                                            let clamped = max(appState.trimStart + 0.05, min(duration, targetSec))
                                            appState.trimEnd = clamped
                                            appState.seek(to: clamped)
                                        }
                                )
                        }
                        .frame(width: trackWidth, height: 42)
                    }
                    
                    // C. Playhead Needle (Modern circular pin & precision line)
                    let playheadX = trackWidth * CGFloat(min(1.0, max(0.0, appState.currentTime / duration)))
                    playheadNeedle
                        .offset(x: playheadX - 10)
                        .gesture(
                            DragGesture(minimumDistance: 0, coordinateSpace: .named("timelineSpace"))
                                .onChanged { val in
                                    let targetSec = Double(max(0.0, min(trackWidth, val.location.x)) / trackWidth) * duration
                                    appState.seek(to: targetSec)
                                }
                        )
                }
                .frame(width: trackWidth, height: 62)
                .coordinateSpace(name: "timelineSpace")
            }
        }
        .frame(height: 64)
    }
    
    // MARK: - Ruler View with Smart Spaced Ticks (No overlapping text)
    private func rulerView(width: CGFloat, duration: Double) -> some View {
        Canvas { context, size in
            let totalSeconds = duration
            let pxPerSec = width / CGFloat(totalSeconds)
            let minLabelSpacing: CGFloat = 70.0
            let minIntervalSec = Double(minLabelSpacing / max(1.0, pxPerSec))
            
            // Standard nice intervals
            let standardIntervals: [Double] = [0.1, 0.2, 0.5, 1.0, 2.0, 5.0, 10.0, 15.0, 30.0, 60.0, 120.0, 300.0, 600.0]
            let labelInterval = standardIntervals.first(where: { $0 >= minIntervalSec }) ?? max(1.0, minIntervalSec)
            
            // Sub-divisions for tick marks
            let tickInterval: Double
            if labelInterval <= 0.2 {
                tickInterval = labelInterval / 2.0
            } else if labelInterval <= 1.0 {
                tickInterval = labelInterval / 5.0
            } else if labelInterval <= 5.0 {
                tickInterval = 1.0
            } else {
                tickInterval = labelInterval / 5.0
            }
            
            var curSec: Double = 0.0
            while curSec <= totalSeconds + 0.001 {
                let x = width * CGFloat(curSec / totalSeconds)
                
                // Determine if this tick matches a label interval
                let rem = curSec.truncatingRemainder(dividingBy: labelInterval)
                let isMajor = rem < 0.0001 || abs(rem - labelInterval) < 0.0001
                
                if isMajor {
                    // Major tick line
                    let path = Path { p in
                        p.move(to: CGPoint(x: x, y: 7))
                        p.addLine(to: CGPoint(x: x, y: 18))
                    }
                    context.stroke(path, with: .color(FCPTheme.textSecondary), lineWidth: 1)
                    
                    // Time label anchored top-leading so it starts next to tick and never collides
                    let labelText = formatRulerLabel(curSec, step: labelInterval)
                    let text = Text(labelText)
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundColor(FCPTheme.textSecondary)
                    context.draw(text, at: CGPoint(x: x + 3, y: 5), anchor: .topLeading)
                } else {
                    // Minor tick line
                    let path = Path { p in
                        p.move(to: CGPoint(x: x, y: 12))
                        p.addLine(to: CGPoint(x: x, y: 18))
                    }
                    context.stroke(path, with: .color(FCPTheme.textMuted.opacity(0.35)), lineWidth: 0.8)
                }
                
                curSec += tickInterval
            }
        }
    }
    
    private func formatRulerLabel(_ sec: Double, step: Double) -> String {
        let rounded = (sec * 1000).rounded() / 1000
        let mins = Int(rounded) / 60
        let s = Int(rounded) % 60
        if step < 1.0 {
            let frac = Int((rounded.truncatingRemainder(dividingBy: 1.0)) * 10)
            return String(format: "%02d:%02d.%d", mins, s, frac)
        }
        return String(format: "%02d:%02d", mins, s)
    }
    
    // MARK: - Reference Clip Track View (Warm Golden-Amber Pill with subtle dividers & center label)
    private func clipTrackBackground(width: CGFloat, duration: Double) -> some View {
        ZStack {
            // Warm golden-amber gradient matching reference image
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.85, green: 0.52, blue: 0.05),
                            Color(red: 0.68, green: 0.38, blue: 0.02)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
            
            // Subtle vertical tick dividers across the clip
            HStack(spacing: 0) {
                ForEach(0..<10, id: \.self) { _ in
                    Spacer()
                    Rectangle()
                        .fill(Color.black.opacity(0.12))
                        .frame(width: 1, height: 36)
                }
                Spacer()
            }
            
            // Centered clip text: "Clip" and "\(duration)s ⎈ 1x"
            VStack(spacing: 2) {
                Text("Clip")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.92))
                
                HStack(spacing: 4) {
                    Text(String(format: "%.0fs", duration))
                        .font(.system(size: 9, weight: .medium))
                    Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                        .font(.system(size: 8))
                    Text(String(format: "%.0fx", appState.currentEffectiveSpeed))
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundColor(Color.white.opacity(0.85))
            }
        }
        .frame(width: width, height: 42)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - In & Out Handles
    private var inHandleView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white)
                .frame(width: 12, height: 42)
                .shadow(color: .black.opacity(0.5), radius: 2)
            
            Image(systemName: "chevron.compact.right")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.black)
        }
        .frame(width: 22, height: 42)
        .contentShape(Rectangle())
    }
    
    private var outHandleView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white)
                .frame(width: 12, height: 42)
                .shadow(color: .black.opacity(0.5), radius: 2)
            
            Image(systemName: "chevron.compact.left")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.black)
        }
        .frame(width: 22, height: 42)
        .contentShape(Rectangle())
    }
    
    // MARK: - Playhead Needle (Modern circular pin matching reference)
    private var playheadNeedle: some View {
        let needleColor = (appState.uiTheme == .liquidGlass) ? FCPTheme.liquidCyan : Color(red: 0.45, green: 0.42, blue: 1.0)
        return VStack(spacing: 0) {
            Circle()
                .fill(needleColor)
                .frame(width: 12, height: 12)
                .shadow(color: needleColor.opacity(0.8), radius: 3)
                .frame(width: 20, height: 18)
                .contentShape(Rectangle())
            
            Rectangle()
                .fill(needleColor)
                .frame(width: 2, height: 44)
                .shadow(color: needleColor.opacity(0.4), radius: 2)
                .allowsHitTesting(false)
        }
        .frame(width: 20)
    }
    
    // MARK: - 3. Bottom Settings Row
    private var bottomSettingsRow: some View {
        HStack(spacing: 16) {
            // Motion Blur Checkbox & Slider
            HStack(spacing: 8) {
                Toggle(isOn: $appState.isMotionBlurEnabled) {
                    Text("Motion Blur:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(FCPTheme.textSecondary)
                }
                .toggleStyle(.checkbox)
                
                if appState.isMotionBlurEnabled {
                    Slider(value: $appState.motionBlur, in: 0.0...1.0)
                        .accentColor(FCPTheme.accent(for: appState.uiTheme))
                        .frame(width: 90)
                    
                    Text(String(format: "%.0f%%", appState.motionBlur * 100))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(FCPTheme.textPrimary)
                        .frame(width: 32, alignment: .trailing)
                } else {
                    Text("Выкл")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(FCPTheme.textMuted)
                }
            }
            
            Spacer()
            
            // Export Selected Segment Only Toggle
            Toggle(isOn: $appState.isSegmentOnlyExport) {
                Text("Экспортировать только выделенный отрезок")
                    .font(.system(size: 11))
                    .foregroundColor(appState.isSegmentOnlyExport ? FCPTheme.textPrimary : FCPTheme.textSecondary)
            }
            .toggleStyle(.checkbox)
        }
    }
}

// MARK: - Precision Timecode Field Component
public struct PrecisionTimecodeField: View {
    let label: String
    let seconds: Double
    var theme: AppUITheme = .classic
    let onCommit: (Double) -> Void
    let onStep: (Double) -> Void
    
    @State private var text: String = ""
    @FocusState private var isFocused: Bool
    
    public init(label: String, seconds: Double, theme: AppUITheme = .classic, onCommit: @escaping (Double) -> Void, onStep: @escaping (Double) -> Void) {
        self.label = label
        self.seconds = seconds
        self.theme = theme
        self.onCommit = onCommit
        self.onStep = onStep
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(FCPTheme.textMuted)
                .lineLimit(1)
            
            TextField("", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(FCPTheme.textPrimary)
                .frame(width: 72)
                .lineLimit(1)
                .focused($isFocused)
                .onSubmit {
                    commitInput()
                }
                .onChange(of: isFocused) { _, focused in
                    if !focused {
                        commitInput()
                    }
                }
                .onAppear {
                    text = formatPrecise(seconds)
                }
                .onChange(of: seconds) { _, newSec in
                    if !isFocused {
                        text = formatPrecise(newSec)
                    }
                }
            
            VStack(spacing: 0) {
                Button(action: { onStep(0.1) }) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(FCPTheme.textSecondary)
                        .frame(width: 16, height: 11)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Button(action: { onStep(-0.1) }) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(FCPTheme.textSecondary)
                        .frame(width: 16, height: 11)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 6)
        .frame(height: 26)
        .fixedSize(horizontal: true, vertical: true)
        .themedCard(theme: theme, cornerRadius: 4, isHighlighted: isFocused)
    }
    
    private func commitInput() {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        if let parsed = parseSeconds(clean) {
            onCommit(parsed)
        } else {
            text = formatPrecise(seconds)
        }
    }
    
    private func parseSeconds(_ str: String) -> Double? {
        if let direct = Double(str) {
            return direct
        }
        let parts = str.components(separatedBy: ":")
        if parts.count == 2 {
            guard let mins = Double(parts[0]), let secs = Double(parts[1]) else { return nil }
            return mins * 60.0 + secs
        } else if parts.count == 3 {
            guard let hrs = Double(parts[0]), let mins = Double(parts[1]), let secs = Double(parts[2]) else { return nil }
            return hrs * 3600.0 + mins * 60.0 + secs
        }
        return nil
    }
    
    private func formatPrecise(_ sec: Double) -> String {
        let totalMs = Int(sec * 1000)
        let mins = totalMs / 60000
        let secs = (totalMs % 60000) / 1000
        let ms = totalMs % 1000
        return String(format: "%02d:%02d.%03d", mins, secs, ms)
    }
}
