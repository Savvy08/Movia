import SwiftUI

public struct PrecisionTimelineView: View {
    @ObservedObject var appState: AppState
    let item: VideoItem
    
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
            RoundedRectangle(cornerRadius: FCPTheme.radiusCard)
                .fill(FCPTheme.cardBackground.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: FCPTheme.radiusCard)
                        .stroke(FCPTheme.border, lineWidth: 1)
                )
        )
    }
    
    // MARK: - 1. Header Toolbar
    private var headerToolbar: some View {
        HStack(spacing: 12) {
            // Quick In / Out / Cut Buttons
            HStack(spacing: 6) {
                Button(action: {
                    appState.setInAtCurrentTime()
                }) {
                    Text("[ In")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(FCPTheme.textPrimary)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .frame(height: 26)
                        .background(FCPTheme.panelBackground)
                        .cornerRadius(5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(FCPTheme.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .fixedSize()
                .help("Установить точку In по положению плейхеда")
                
                Button(action: {
                    appState.setOutAtCurrentTime()
                }) {
                    Text("Out ]")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(FCPTheme.textPrimary)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .frame(height: 26)
                        .background(FCPTheme.panelBackground)
                        .cornerRadius(5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(FCPTheme.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .fixedSize()
                .help("Установить точку Out по положению плейхеда")
                
                // Scissors / Split Button
                Button(action: {
                    appState.splitAtCurrentTime()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "scissors")
                            .font(.system(size: 10))
                        Text("Обрезать")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(FCPTheme.textPrimary)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .frame(height: 26)
                    .background(FCPTheme.panelBackground)
                    .cornerRadius(5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(FCPTheme.border, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .fixedSize()
                .help("Обрезать по плейхеду")
                
                // Reset Button
                Button(action: {
                    appState.resetTrim()
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 10))
                        .foregroundColor(FCPTheme.textMuted)
                        .frame(width: 26, height: 26)
                        .background(FCPTheme.panelBackground)
                        .cornerRadius(5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(FCPTheme.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .fixedSize()
                .help("Сбросить диапазон на всю длину")
            }
            
            Spacer()
            
            // Editable Precision Millisecond Fields (In, Out, Duration)
            HStack(spacing: 8) {
                PrecisionTimecodeField(
                    label: "In:",
                    seconds: appState.trimStart,
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
                    .accentColor(FCPTheme.accentBlue)
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
                        
                        // B. Filmstrip Track
                        ZStack(alignment: .leading) {
                            // Filmstrip Image Background
                            filmstripBackground(width: trackWidth)
                                .frame(height: 44)
                            
                            // Dimmed Outside Mask (Before In-point)
                            let inX = trackWidth * CGFloat(appState.trimStart / duration)
                            let outX = trackWidth * CGFloat(appState.trimEnd / duration)
                            
                            Rectangle()
                                .fill(Color.black.opacity(0.65))
                                .frame(width: max(0, inX), height: 44)
                            
                            // Dimmed Outside Mask (After Out-point)
                            Rectangle()
                                .fill(Color.black.opacity(0.65))
                                .frame(width: max(0, trackWidth - outX), height: 44)
                                .offset(x: outX)
                            
                            // Active Slow Motion Segment (Draggable block)
                            RoundedRectangle(cornerRadius: 3)
                                .strokeBorder(FCPTheme.accentBlue, lineWidth: 2)
                                .background(FCPTheme.accentBlue.opacity(0.22))
                                .frame(width: max(16, outX - inX), height: 44)
                                .offset(x: inX)
                                .overlay(
                                    HStack {
                                        Text(String(format: "SlowMo %.1fx (%.1f сек)", appState.currentEffectiveSpeed, appState.trimEnd - appState.trimStart))
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                            .shadow(color: .black, radius: 2)
                                            .padding(.horizontal, 6)
                                        Spacer()
                                    }
                                    .offset(x: inX)
                                )
                                .gesture(
                                    DragGesture()
                                        .onChanged { val in
                                            let segDuration = appState.trimEnd - appState.trimStart
                                            let deltaSec = Double(val.translation.width / trackWidth) * duration
                                            let newStart = max(0.0, min(duration - segDuration, appState.trimStart + deltaSec))
                                            appState.trimStart = newStart
                                            appState.trimEnd = newStart + segDuration
                                        }
                                )
                            
                            // In-Point Handle (Left)
                            inHandleView
                                .offset(x: inX - 6)
                                .gesture(
                                    DragGesture()
                                        .onChanged { val in
                                            let newRatio = max(0.0, min(CGFloat((appState.trimEnd - 0.05) / duration), val.location.x / trackWidth))
                                            appState.trimStart = Double(newRatio) * duration
                                            appState.seek(to: appState.trimStart)
                                        }
                                )
                            
                            // Out-Point Handle (Right)
                            outHandleView
                                .offset(x: outX - 6)
                                .gesture(
                                    DragGesture()
                                        .onChanged { val in
                                            let newRatio = max(CGFloat((appState.trimStart + 0.05) / duration), min(1.0, val.location.x / trackWidth))
                                            appState.trimEnd = Double(newRatio) * duration
                                            appState.seek(to: appState.trimEnd)
                                        }
                                )
                        }
                        .frame(width: trackWidth, height: 44)
                        .cornerRadius(4)
                    }
                    
                    // C. Red Playhead Needle across Ruler and Filmstrip
                    let playheadX = trackWidth * CGFloat(min(1.0, max(0.0, appState.currentTime / duration)))
                    playheadNeedle
                        .offset(x: playheadX - 6)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { val in
                                    let ratio = max(0.0, min(1.0, val.location.x / trackWidth))
                                    appState.seek(to: Double(ratio) * duration)
                                }
                        )
                }
                .frame(width: trackWidth, height: 62)
                .contentShape(Rectangle())
                .onTapGesture { location in
                    let ratio = max(0.0, min(1.0, location.x / trackWidth))
                    appState.seek(to: Double(ratio) * duration)
                }
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
    
    // MARK: - Filmstrip Background View
    private func filmstripBackground(width: CGFloat) -> some View {
        HStack(spacing: 1) {
            if appState.filmstripImages.isEmpty {
                ForEach(0..<12, id: \.self) { _ in
                    Rectangle()
                        .fill(FCPTheme.cardBackground)
                        .overlay(
                            Image(systemName: "film")
                                .font(.system(size: 10))
                                .foregroundColor(FCPTheme.textMuted.opacity(0.4))
                        )
                }
            } else {
                ForEach(appState.filmstripImages.indices, id: \.self) { idx in
                    Image(nsImage: appState.filmstripImages[idx])
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                }
            }
        }
        .frame(width: width)
        .background(Color.black)
    }
    
    // MARK: - In & Out Handles
    private var inHandleView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white)
                .frame(width: 12, height: 44)
                .shadow(color: .black.opacity(0.5), radius: 2)
            
            Image(systemName: "chevron.compact.right")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.black)
        }
    }
    
    private var outHandleView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white)
                .frame(width: 12, height: 44)
                .shadow(color: .black.opacity(0.5), radius: 2)
            
            Image(systemName: "chevron.compact.left")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.black)
        }
    }
    
    // MARK: - Playhead Needle
    private var playheadNeedle: some View {
        VStack(spacing: 0) {
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 11))
                .foregroundColor(FCPTheme.alertRed)
            
            Rectangle()
                .fill(FCPTheme.alertRed)
                .frame(width: 1.5, height: 50)
        }
        .frame(width: 12)
    }
    
    // MARK: - 3. Bottom Settings Row
    private var bottomSettingsRow: some View {
        HStack(spacing: 16) {
            // Motion Blur Slider
            HStack(spacing: 8) {
                Text("Motion Blur:")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(FCPTheme.textSecondary)
                
                Text("Off")
                    .font(.system(size: 10))
                    .foregroundColor(FCPTheme.textMuted)
                
                Slider(value: $appState.motionBlur, in: 0.0...1.0)
                    .accentColor(FCPTheme.accentBlue)
                    .frame(width: 110)
                
                Text("High")
                    .font(.system(size: 10))
                    .foregroundColor(FCPTheme.textMuted)
                
                Text(appState.motionBlur < 0.05 ? "Выкл" : String(format: "%.0f%%", appState.motionBlur * 100))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(FCPTheme.textPrimary)
                    .frame(width: 36, alignment: .trailing)
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
    let onCommit: (Double) -> Void
    let onStep: (Double) -> Void
    
    @State private var text: String = ""
    @FocusState private var isFocused: Bool
    
    public init(label: String, seconds: Double, onCommit: @escaping (Double) -> Void, onStep: @escaping (Double) -> Void) {
        self.label = label
        self.seconds = seconds
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
            
            VStack(spacing: 1) {
                Button(action: { onStep(0.1) }) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(FCPTheme.textSecondary)
                }
                .buttonStyle(.plain)
                
                Button(action: { onStep(-0.1) }) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(FCPTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 6)
        .frame(height: 26)
        .fixedSize(horizontal: true, vertical: true)
        .background(FCPTheme.panelBackground)
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isFocused ? FCPTheme.accentBlue : FCPTheme.border, lineWidth: 1)
        )
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
