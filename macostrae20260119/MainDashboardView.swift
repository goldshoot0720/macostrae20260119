import Combine
import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case home
    case dashboard
    case subscriptions
    case foodManagement
    case fengNotes
    case fengCommon
    case images
    case videos
    case music
    case documents
    case podcasts
    case bankStats
    case routines
    case fengTools
    case priceCompare
    case phoneCompare
    case fengTube
    case finance
    case oilMonitor
    case settings
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "鋒兄首頁"
        case .dashboard: return "鋒兄儀表"
        case .subscriptions: return "鋒兄訂閱"
        case .foodManagement: return "鋒兄食品"
        case .fengNotes: return "鋒兄筆記"
        case .fengCommon: return "鋒兄常用"
        case .images: return "鋒兄圖片"
        case .videos: return "鋒兄影片"
        case .music: return "鋒兄音樂"
        case .documents: return "鋒兄文件"
        case .podcasts: return "鋒兄播客"
        case .bankStats: return "鋒兄銀行"
        case .routines: return "鋒兄例行"
        case .fengTools: return "鋒兄工具"
        case .priceCompare: return "鋒兄比價"
        case .phoneCompare: return "手機比價"
        case .fengTube: return "鋒兄Tube"
        case .finance: return "鋒兄金融"
        case .oilMonitor: return "原油監控"
        case .settings: return "鋒兄設定"
        case .about: return "鋒兄關於"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .dashboard: return "square.grid.2x2.fill"
        case .subscriptions: return "rectangle.stack.badge.person.crop"
        case .foodManagement: return "fork.knife"
        case .fengNotes: return "note.text"
        case .fengCommon: return "person.2.badge.key.fill"
        case .images: return "photo.on.rectangle.angled"
        case .videos: return "play.rectangle.fill"
        case .music: return "music.note.list"
        case .documents: return "doc.text.fill"
        case .podcasts: return "waveform.circle.fill"
        case .bankStats: return "building.columns.fill"
        case .routines: return "repeat.circle.fill"
        case .fengTools: return "wrench.and.screwdriver.fill"
        case .priceCompare: return "tag.fill"
        case .phoneCompare: return "iphone.gen3"
        case .fengTube: return "tv.fill"
        case .finance: return "chart.line.uptrend.xyaxis"
        case .oilMonitor: return "barrel.fill"
        case .settings: return "gearshape.fill"
        case .about: return "info.circle.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .home: return "整理所有資料入口與目前工作區焦點。"
        case .dashboard: return "快速掌握訂閱、食品、媒體、銀行與資料表狀態。"
        case .subscriptions: return "Appwrite subscription data and renewal timeline."
        case .foodManagement: return "追蹤食品與商品庫存、期限、補貨優先順序。"
        case .fengNotes: return "分類、附件、置頂與工作筆記的快速整理視圖。"
        case .fengCommon: return "常用帳號、登入入口與低干擾檢索。"
        case .images: return "圖片收藏、分類、ZIP 匯入與檔案大小排序。"
        case .videos: return "YouTube、Bilibili 與影片快取管理。"
        case .music: return "歌曲、歌詞、封面與播放內容管理。"
        case .documents: return "文件中心、分類、卡片/列表與 ZIP 匯入匯出。"
        case .podcasts: return "Podcast 節目、音訊檔與素材管理。"
        case .bankStats: return "銀行帳戶、電子票證與所有資產彙總。"
        case .routines: return "例行事項、CSV 匯入匯出與日常流程追蹤。"
        case .fengTools: return "集中處理網路比價、手機價格、Tube 與金融工具。"
        case .priceCompare: return "貼上商品網址，抓 BigGo 價格區間。"
        case .phoneCompare: return "地標網通與傑昇通信價格比較。"
        case .fengTube: return "追蹤指定 YouTube 頻道最新影片。"
        case .finance: return "追蹤 CNBC 市場價格與高低標記。"
        case .oilMonitor: return "OQD daily marker price monitor."
        case .settings: return "帳號、資料表、Storage 與系統版本設定。"
        case .about: return "Nuxt / Vue / Supabase / Appwrite 參考工作台定位。"
        }
    }

    var eyebrow: String {
        switch self {
        case .home: return "Tech Editorial Workspace"
        case .dashboard: return "Console Overview"
        case .subscriptions: return "Subscription Ops"
        case .foodManagement: return "Pantry + Inventory"
        case .fengNotes: return "Knowledge Base"
        case .fengCommon: return "Common Accounts"
        case .images, .videos, .music, .documents, .podcasts: return "Media Library"
        case .bankStats: return "Asset Ledger"
        case .routines: return "Routine Flow"
        case .fengTools, .priceCompare, .phoneCompare, .fengTube, .finance: return "FengBro Toolkit"
        case .oilMonitor: return "Market Monitor"
        case .settings: return "System Setup"
        case .about: return "About"
        }
    }

    var actions: [String] {
        switch self {
        case .home: return ["打開總覽", "前往訂閱管理", "前往鋒兄食品"]
        case .dashboard: return ["新增訂閱", "新增食品(或商品)", "影片庫", "圖片庫"]
        case .subscriptions: return ["匯入 CSV", "新增訂閱", "7天內", "續訂"]
        case .foodManagement: return ["匯入 CSV", "新增食品(或商品)", "期限排序", "庫存壓力"]
        case .fengNotes: return ["匯入 ZIP", "新增筆記", "全部分類", "有附件"]
        case .fengCommon: return ["匯入 CSV", "新增常用項目", "快速搜尋", "複製入口"]
        case .images: return ["匯入 ZIP", "新增圖片", "最新在前", "檔案大小排序"]
        case .videos: return ["YouTube", "Bilibili", "匯出 ZIP", "新增影片"]
        case .music: return ["匯出 ZIP", "匯入 ZIP", "新增音樂", "快取檢查"]
        case .documents: return ["卡片式", "列表式", "匯出 ZIP", "新增文件"]
        case .podcasts: return ["匯出 ZIP", "匯入 ZIP", "新增播客", "素材檢查"]
        case .bankStats: return ["匯入 CSV", "新增銀行", "一鍵匯入預設銀行", "新增電子票證"]
        case .routines: return ["匯出 CSV", "匯入 CSV", "新增例行", "今天流程"]
        case .fengTools: return ["鋒兄比價", "手機比價", "鋒兄Tube", "鋒兄金融"]
        case .priceCompare: return ["貼上商品網址", "查詢價格", "BigGo 區間", "7天紀錄"]
        case .phoneCompare: return ["地標網通", "傑昇通信", "比較價格", "更新快照"]
        case .fengTube: return ["查看新影片", "稍後提醒", "頻道列表", "更新 YouTube"]
        case .finance: return ["查看 CNBC", "高低標記", "今天略過", "更新報價"]
        case .oilMonitor: return ["立即抓取 OQD", "打開來源", "開獨立視窗"]
        case .settings: return ["儲存並切換", "清除所有", "全表格 SQL", "重新檢查"]
        case .about: return ["系統定位", "版本資訊", "重點功能", "資料匯入設計"]
        }
    }

    var metrics: [(String, String)] {
        switch self {
        case .home: return [("核心任務", "02"), ("資料頁", "15+"), ("狀態", "24/7")]
        case .dashboard: return [("訂閱數量", "Appwrite"), ("資料表", "11"), ("Storage", "1 GB")]
        case .subscriptions: return [("來源", "TablesDB"), ("篩選", "年份/月"), ("提醒", "3 天內")]
        case .foodManagement: return [("期限", "月份"), ("庫存", "商品"), ("匯入", "CSV")]
        case .fengNotes: return [("附件", "ZIP"), ("分類", "可篩選"), ("狀態", "可置頂")]
        case .fengCommon: return [("帳號", "常用"), ("匯入", "CSV"), ("檢索", "快速")]
        case .images: return [("媒體", "Image"), ("匯入", "ZIP"), ("排序", "大小/時間")]
        case .videos: return [("來源", "YT/Bili"), ("快取", "影片"), ("匯出", "ZIP")]
        case .music: return [("歌曲", "Music"), ("歌詞", "Lyrics"), ("快取", "Audio")]
        case .documents: return [("文件", "Docs"), ("模式", "卡片/列表"), ("匯出", "ZIP")]
        case .podcasts: return [("節目", "Podcast"), ("音訊", "Audio"), ("素材", "Refs")]
        case .bankStats: return [("所有資產", "NT$"), ("銀行", "帳戶"), ("票證", "電子")]
        case .routines: return [("例行", "Flow"), ("匯入", "CSV"), ("週期", "Daily")]
        case .fengTools: return [("比價", "BigGo"), ("手機", "通路"), ("金融", "CNBC")]
        case .priceCompare: return [("價格", "區間"), ("週期", "7天"), ("來源", "BigGo")]
        case .phoneCompare: return [("地標", "通路"), ("傑昇", "通路"), ("快照", "價格")]
        case .fengTube: return [("新片", "3天內"), ("頻道", "YouTube"), ("提醒", "可略過")]
        case .finance: return [("市場", "CNBC"), ("高點", "標記"), ("低點", "標記")]
        case .oilMonitor: return [("來源", "GME/OQD"), ("狀態", "Active"), ("排程", "Daily")]
        case .settings: return [("版本", "v2.0.0"), ("表格", "11"), ("Storage", "掃描")]
        case .about: return [("Nuxt", "^4.2.2"), ("Vue", "^3.5.25"), ("部署", "Netlify")]
        }
    }

    var workflow: [String] {
        switch self {
        case .home: return ["快速掌握近期續訂、食品期限與整體管理壓力。", "讓資料入口像雜誌目錄一樣可掃讀。", "保留留白與強文字階層，降低後台疲勞。"]
        case .dashboard: return ["統計訂閱、食品、筆記、銀行、媒體資料筆數。", "提供新增訂閱、食品、影片、圖片的快速操作。", "顯示系統狀態、使用統計、安全與 Storage。"]
        case .subscriptions: return ["依年份、月份、續訂狀態與 7 天內到期篩選。", "顯示每月總計與提醒時間軸。", "支援 Appwrite TablesDB 讀取與 macOS 通知。"]
        case .foodManagement: return ["追蹤食品或商品名稱、期限、數量與庫存壓力。", "依年份/月分與無日期項目篩選。", "支援 CSV 匯入，方便批次整理。"]
        case .fengNotes: return ["以分類、附件與置頂狀態整理文章與工作筆記。", "ZIP 匯入保留附件結構。", "適合保存 Appwrite/Supabase 匯入後的資料摘要。"]
        case .fengCommon: return ["管理常用帳號、網址、備註與低干擾快速搜尋。", "CSV 匯入常用入口集合。", "桌面版先提供檢索與新增動線。"]
        case .images: return ["圖片以分類、時間與檔案大小排序。", "ZIP 匯入批次建立圖片庫。", "後續可接 Storage 引用檢查。"]
        case .videos: return ["管理 YouTube / Bilibili 影片與封面。", "顯示快取數與影片來源。", "支援 ZIP 匯出備份。"]
        case .music: return ["管理歌曲、歌詞、封面與播放檔案。", "顯示快取歌曲數與分組。", "維持和網頁版一致的匯入匯出入口。"]
        case .documents: return ["以卡片式或列表式瀏覽文件。", "支援文件 ZIP 匯出與匯入。", "可承接 Appwrite 文件 ZIP 格式。"]
        case .podcasts: return ["管理 Podcast 節目、音訊與素材引用。", "支援 ZIP 匯入匯出。", "保留節目、集數與檔案欄位架構。"]
        case .bankStats: return ["分開統計銀行帳戶與電子票證。", "支援預設銀行一鍵建立。", "顯示所有資產與分類總計。"]
        case .routines: return ["管理例行事項與重複流程。", "CSV 匯入匯出日常清單。", "可依今日流程與週期排序。"]
        case .fengTools: return ["整合 BigGo、手機通路、Tube、CNBC 工具入口。", "先看現在，再保留 7 天一次的價格快照。", "工具頁維持科技編輯式摘要。"]
        case .priceCompare: return ["貼上商品網址。", "抓取 BigGo 價格區間。", "保存每 7 天一次的歷史快照。"]
        case .phoneCompare: return ["比較地標網通與傑昇通信。", "追蹤手機型號、容量與價格。", "保留更新快照。"]
        case .fengTube: return ["追蹤指定 YouTube 頻道。", "3 天內新影片產生提醒。", "可跳轉查看或稍後提醒。"]
        case .finance: return ["追蹤 CNBC 市場報價。", "標記創新高/低。", "可按日略過或重新檢查。"]
        case .oilMonitor: return ["每日抓取 OQD Daily Marker Price。", "在選單列與獨立視窗同步顯示。", "支援語音命令立即抓取。"]
        case .settings: return ["管理 Supabase URL、Anon Key、Bucket。", "檢查資料表與 Storage Bucket 狀態。", "掃描未引用檔案。"]
        case .about: return ["定位為個人工作資料庫。", "整合筆記、媒體、文件、帳號、訂閱與工具頁。", "參考 Appwrite 與 Supabase 兩套網頁工作台。"]
        }
    }
}

@MainActor
final class AppNavigationState: ObservableObject {
    @Published var selectedSection: AppSection? = .home

    func show(_ section: AppSection) {
        selectedSection = section
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }
}

struct MainDashboardView: View {
    @EnvironmentObject private var navigationState: AppNavigationState
    @EnvironmentObject private var crudeOilMonitor: CrudeOilMonitor
    @EnvironmentObject private var voiceCommandCenter: VoiceCommandCenter
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            NavigationSplitView {
                List(AppSection.allCases, selection: $navigationState.selectedSection) { section in
                    Label(section.title, systemImage: section.systemImage)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .padding(.vertical, 4)
                        .tag(section)
                }
                .navigationTitle("Workspace")
                .frame(minWidth: 240)
            } detail: {
                Group {
                    switch navigationState.selectedSection ?? .home {
                    case .subscriptions:
                        ContentView()
                    case .oilMonitor:
                        CrudeOilMonitorView()
                            .environmentObject(crudeOilMonitor)
                    default:
                        ModuleWorkspaceView(section: navigationState.selectedSection ?? .home)
                    }
                }
            }

            VoiceCommandOverlay()
        }
        .onAppear {
            voiceCommandCenter.configure(
                navigationState: navigationState,
                crudeOilMonitor: crudeOilMonitor,
                openOilWindow: {
                    openWindow(id: "oil-monitor")
                }
            )
        }
        .onChange(of: crudeOilMonitor.latestPriceText) { _, _ in
            voiceCommandCenter.configure(
                navigationState: navigationState,
                crudeOilMonitor: crudeOilMonitor,
                openOilWindow: {
                    openWindow(id: "oil-monitor")
                }
            )
        }
    }
}

struct ModuleWorkspaceView: View {
    let section: AppSection

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.05, blue: 0.08),
                    Color(red: 0.06, green: 0.08, blue: 0.10),
                    Color(red: 0.09, green: 0.08, blue: 0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    metrics
                    actions
                    workflow
                }
                .padding(34)
                .frame(maxWidth: 1120, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(section.title)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(section.eyebrow.uppercased())
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.cyan)

            HStack(alignment: .top, spacing: 18) {
                Image(systemName: section.systemImage)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 8) {
                    Text(section.title)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(section.subtitle)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.68))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var metrics: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            ForEach(section.metrics, id: \.0) { label, value in
                VStack(alignment: .leading, spacing: 8) {
                    Text(label)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.54))
                    Text(value)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )
            }
        }
    }

    private var actions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快速操作")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(section.actions, id: \.self) { action in
                    Button {
                    } label: {
                        HStack {
                            Text(action)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .lineLimit(2)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(14)
                        .frame(minHeight: 58)
                        .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var workflow: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("工作流")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            VStack(spacing: 10) {
                ForEach(Array(section.workflow.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: 12) {
                        Text(String(format: "%02d", index + 1))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.cyan)
                            .frame(width: 36)

                        Text(item)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.76))
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()
                    }
                    .padding(14)
                    .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
    }
}
