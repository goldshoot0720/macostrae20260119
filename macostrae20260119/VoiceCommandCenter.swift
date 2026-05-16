import AVFoundation
import Combine
import Foundation
import Speech
import SwiftUI

extension Notification.Name {
    static let voiceRefreshSubscriptions = Notification.Name("voiceRefreshSubscriptions")
}

@MainActor
final class VoiceCommandCenter: NSObject, ObservableObject {
    @Published private(set) var isListening = false
    @Published private(set) var transcript = ""
    @Published private(set) var lastCommand = "語音待命"
    @Published private(set) var permissionMessage = ""
    @Published private(set) var recentCommands: [String] = []

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh_TW")) ?? SFSpeechRecognizer(locale: Locale(identifier: "en_US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var navigationState: AppNavigationState?
    private var crudeOilMonitor: CrudeOilMonitor?
    private var openOilWindow: (() -> Void)?
    private var lastHandledText = ""
    private var lastHandledAt = Date.distantPast

    var commandMenu: [String] {
        [
            "訂閱 / subscription",
            "首頁 / home",
            "儀表 / dashboard",
            "食品 / food",
            "筆記 / notes",
            "常用 / accounts",
            "圖片 / images",
            "影片 / videos",
            "音樂 / music",
            "文件 / documents",
            "播客 / podcasts",
            "銀行 / bank",
            "例行 / routines",
            "工具 / tools",
            "比價 / price",
            "手機比價 / phone",
            "Tube / YouTube",
            "金融 / finance",
            "原油 / oil / OQD",
            "第一個 / 最後一個",
            "上一個選單 / 下一個選單",
            "第 1 到第 21 個選單",
            "刷新訂閱",
            "檢查通知",
            "抓取油價",
            "打開原油視窗",
            "開原油來源網站",
            "設定 / 關於",
            "顯示視窗",
            "隱藏視窗",
            "命令列表",
            "停止語音",
            "退出 App"
        ]
    }

    func configure(navigationState: AppNavigationState, crudeOilMonitor: CrudeOilMonitor, openOilWindow: @escaping () -> Void) {
        self.navigationState = navigationState
        self.crudeOilMonitor = crudeOilMonitor
        self.openOilWindow = openOilWindow
    }

    func toggleListening() {
        isListening ? stopListening() : startListening()
    }

    func startListening() {
        Task {
            guard await requestPermissions() else { return }
            beginRecognition()
        }
    }

    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
        setCommand("語音已停止")
    }

    private func requestPermissions() async -> Bool {
        let speechAllowed = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }

        guard speechAllowed else {
            permissionMessage = "需要允許語音辨識"
            setCommand(permissionMessage)
            return false
        }

        let microphoneAllowed = await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }

        guard microphoneAllowed else {
            permissionMessage = "需要允許麥克風"
            setCommand(permissionMessage)
            return false
        }

        permissionMessage = ""
        return true
    }

    private func beginRecognition() {
        if audioEngine.isRunning {
            stopListening()
        }

        recognitionTask?.cancel()
        recognitionTask = nil
        transcript = ""

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak request] buffer, _ in
            request?.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
            isListening = true
            setCommand("正在聽")
        } catch {
            setCommand("無法開始語音: \(error.localizedDescription)")
            return
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }

                if let result {
                    let text = result.bestTranscription.formattedString
                    self.transcript = text
                    self.handle(text)
                }

                if error != nil {
                    self.stopListening()
                }
            }
        }
    }

    private func handle(_ text: String) {
        let normalized = normalize(text)
        guard shouldHandle(normalized) else { return }

        if normalized.hasSuffix("停止語音") || normalized.contains("stopvoice") || normalized.contains("停止聽") {
            stopListening()
            return
        }

        if normalized.contains("退出") || normalized.contains("quit") || normalized.contains("關閉app") {
            setCommand("退出 App")
            NSApplication.shared.terminate(nil)
            return
        }

        if normalized.contains("隱藏") || normalized.contains("hide") || normalized.contains("最小化") {
            setCommand("隱藏視窗")
            NSApp.hide(nil)
            return
        }

        if normalized.contains("顯示") || normalized.contains("show") || normalized.contains("打開app") {
            setCommand("顯示視窗")
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
            return
        }

        if normalized.contains("命令") || normalized.contains("help") || normalized.contains("列表") {
            setCommand("顯示語音命令")
            return
        }

        if normalized.contains("上一個") || normalized.contains("前一個") || normalized.contains("previous") || normalized.contains("back") {
            moveSection(by: -1)
            return
        }

        if normalized.contains("下一個") || normalized.contains("下個") || normalized.contains("next") || normalized.contains("forward") {
            moveSection(by: 1)
            return
        }

        if normalized.contains("第一個") || normalized.contains("首頁") || normalized.contains("first") {
            show(AppSection.allCases.first ?? .subscriptions)
            return
        }

        if normalized.contains("最後") || normalized.contains("last") {
            show(AppSection.allCases.last ?? .fengCommon)
            return
        }

        if let numberedSection = numberedSection(from: normalized) {
            show(numberedSection)
            return
        }

        if normalized.contains("通知") || normalized.contains("提醒") || normalized.contains("到期") {
            setCommand("檢查到期通知")
            Task {
                await NotificationManager.shared.refreshSubscriptionNotifications()
            }
            return
        }

        if normalized.contains("刷新") || normalized.contains("更新") || normalized.contains("refresh") || normalized.contains("reload") {
            if normalized.contains("油") || normalized.contains("oil") || normalized.contains("oqd") {
                fetchOilPrice()
            } else {
                refreshSubscriptions()
            }
            return
        }

        if normalized.contains("抓取油") || normalized.contains("油價") || normalized.contains("oqd") || normalized.contains("crude") {
            show(.oilMonitor)
            if normalized.contains("抓") || normalized.contains("fetch") || normalized.contains("更新") {
                fetchOilPrice()
            }
            return
        }

        if normalized.contains("原油視窗") || normalized.contains("oilwindow") {
            setCommand("打開原油視窗")
            openOilWindow?()
            return
        }

        if normalized.contains("來源網站") || normalized.contains("原油網站") || normalized.contains("gulf") || normalized.contains("source") {
            openCrudeOilSource()
            return
        }

        if let section = section(from: normalized) {
            show(section)
        }
    }

    private func show(_ section: AppSection) {
        navigationState?.show(section)
        setCommand("切換到 \(section.title)")
    }

    private func refreshSubscriptions() {
        setCommand("刷新訂閱")
        NotificationCenter.default.post(name: .voiceRefreshSubscriptions, object: nil)
        Task {
            await NotificationManager.shared.refreshSubscriptionNotifications()
        }
    }

    private func fetchOilPrice() {
        setCommand("抓取 OQD 油價")
        Task {
            await crudeOilMonitor?.fetchLatestPrice(reason: .manual)
        }
    }

    private func openCrudeOilSource() {
        guard let source = crudeOilMonitor?.sourceLinkText, let url = URL(string: source) else {
            setCommand("沒有可開啟的來源網站")
            return
        }

        setCommand("開啟原油來源網站")
        NSWorkspace.shared.open(url)
    }

    private func moveSection(by offset: Int) {
        let sections = AppSection.allCases
        let current = navigationState?.selectedSection ?? .subscriptions
        guard let index = sections.firstIndex(of: current) else {
            show(.subscriptions)
            return
        }

        let nextIndex = max(0, min(sections.count - 1, index + offset))
        show(sections[nextIndex])
    }

    private func numberedSection(from text: String) -> AppSection? {
        let numberWords: [(String, Int)] = [
            ("1", 1), ("一", 1), ("one", 1),
            ("2", 2), ("二", 2), ("兩", 2), ("two", 2),
            ("3", 3), ("三", 3), ("three", 3),
            ("4", 4), ("四", 4), ("four", 4),
            ("5", 5), ("五", 5), ("five", 5),
            ("6", 6), ("六", 6), ("six", 6),
            ("7", 7), ("七", 7), ("seven", 7),
            ("8", 8), ("八", 8), ("eight", 8),
            ("9", 9), ("九", 9), ("nine", 9),
            ("10", 10), ("十", 10), ("ten", 10),
            ("11", 11), ("十一", 11), ("eleven", 11),
            ("12", 12), ("十二", 12), ("twelve", 12),
            ("13", 13), ("十三", 13), ("thirteen", 13),
            ("14", 14), ("十四", 14), ("fourteen", 14),
            ("15", 15), ("十五", 15), ("fifteen", 15),
            ("16", 16), ("十六", 16), ("sixteen", 16),
            ("17", 17), ("十七", 17), ("seventeen", 17),
            ("18", 18), ("十八", 18), ("eighteen", 18),
            ("19", 19), ("十九", 19), ("nineteen", 19),
            ("20", 20), ("二十", 20), ("twenty", 20),
            ("21", 21), ("二十一", 21), ("twentyone", 21)
        ]

        guard text.contains("第") || text.contains("menu") || text.contains("選單") else { return nil }
        guard let match = numberWords.first(where: { text.contains($0.0) }) else { return nil }
        let index = match.1 - 1
        guard AppSection.allCases.indices.contains(index) else { return nil }
        return AppSection.allCases[index]
    }

    private func section(from text: String) -> AppSection? {
        let aliases: [(AppSection, [String])] = [
            (.home, ["首頁", "home", "鋒兄首頁"]),
            (.dashboard, ["儀表", "dashboard", "總覽", "鋒兄儀表"]),
            (.subscriptions, ["訂閱", "subscription", "subscriptions", "續費", "到期", "鋒兄訂閱"]),
            (.foodManagement, ["食品", "食物", "food", "庫存", "商品", "鋒兄食品"]),
            (.fengNotes, ["筆記", "notes", "note", "記事", "鋒兄筆記"]),
            (.fengCommon, ["常用", "帳號", "accounts", "account", "密碼", "鋒兄常用"]),
            (.images, ["圖片", "image", "images", "圖庫", "鋒兄圖片"]),
            (.videos, ["影片", "video", "videos", "bilibili", "鋒兄影片"]),
            (.music, ["音樂", "music", "歌曲", "鋒兄音樂"]),
            (.documents, ["文件", "document", "documents", "docs", "鋒兄文件"]),
            (.podcasts, ["播客", "podcast", "podcasts", "鋒兄播客"]),
            (.bankStats, ["銀行", "bank", "存款", "帳戶", "資產", "電子票證", "鋒兄銀行"]),
            (.routines, ["例行", "routine", "routines", "流程", "鋒兄例行"]),
            (.fengTools, ["工具", "tools", "鋒兄工具", "tool"]),
            (.priceCompare, ["比價", "price", "biggo", "鋒兄比價"]),
            (.phoneCompare, ["手機比價", "手機", "phone", "地標", "傑昇"]),
            (.fengTube, ["tube", "youtube", "鋒兄tube", "新影片"]),
            (.finance, ["金融", "finance", "cnbc", "市場", "報價", "鋒兄金融"]),
            (.oilMonitor, ["原油", "油價", "oqd", "oil", "crude", "石油", "監控"]),
            (.settings, ["設定", "settings", "setting", "鋒兄設定"]),
            (.about, ["關於", "about", "版本", "鋒兄關於"])
        ]

        return aliases.first { _, words in
            words.contains { text.contains(normalize($0)) }
        }?.0
    }

    private func shouldHandle(_ normalized: String) -> Bool {
        guard !normalized.isEmpty else { return false }
        let now = Date()

        if normalized == lastHandledText {
            return false
        }

        if normalized.hasPrefix(lastHandledText), now.timeIntervalSince(lastHandledAt) < 0.8 {
            return false
        }

        lastHandledText = normalized
        lastHandledAt = now
        return true
    }

    private func setCommand(_ command: String) {
        lastCommand = command
        if recentCommands.first != command {
            recentCommands.insert(command, at: 0)
        }
        recentCommands = Array(recentCommands.prefix(6))
    }

    private func normalize(_ text: String) -> String {
        text
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "，", with: "")
            .replacingOccurrences(of: "。", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: ".", with: "")
    }
}

struct VoiceCommandOverlay: View {
    @EnvironmentObject private var voiceCommandCenter: VoiceCommandCenter

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack(spacing: 8) {
                Button {
                    voiceCommandCenter.toggleListening()
                } label: {
                    Image(systemName: voiceCommandCenter.isListening ? "mic.fill" : "mic")
                        .font(.system(size: 15, weight: .bold))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.borderedProminent)
                .tint(voiceCommandCenter.isListening ? .red : .blue)
                .help(voiceCommandCenter.isListening ? "停止語音輸入" : "開始語音輸入")

                Menu {
                    ForEach(voiceCommandCenter.commandMenu, id: \.self) { command in
                        Text(command)
                    }
                } label: {
                    Image(systemName: "list.bullet")
                        .frame(width: 28, height: 28)
                }
                .help("語音命令")
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(voiceCommandCenter.lastCommand)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .lineLimit(1)

                if !voiceCommandCenter.transcript.isEmpty {
                    Text(voiceCommandCenter.transcript)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if let previous = voiceCommandCenter.recentCommands.dropFirst().first {
                    Text(previous)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(width: 260, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.white.opacity(0.16), lineWidth: 1)
            )
        }
        .padding(18)
    }
}

struct VoiceCommandMenuBarView: View {
    @EnvironmentObject private var voiceCommandCenter: VoiceCommandCenter

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(voiceCommandCenter.lastCommand)
                .font(.headline)

            if !voiceCommandCenter.transcript.isEmpty {
                Text(voiceCommandCenter.transcript)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            Button(voiceCommandCenter.isListening ? "停止語音輸入" : "開始語音輸入") {
                voiceCommandCenter.toggleListening()
            }

            Divider()

            ForEach(voiceCommandCenter.commandMenu, id: \.self) { command in
                Text(command)
                    .font(.caption)
            }

            if !voiceCommandCenter.recentCommands.isEmpty {
                Divider()

                ForEach(voiceCommandCenter.recentCommands, id: \.self) { command in
                    Text(command)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(6)
        .frame(width: 280)
    }
}
