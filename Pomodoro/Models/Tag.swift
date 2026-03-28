import Foundation
import SwiftData

struct TagPreset {
    let id: UUID
    let name: String
    let colorHex: String
    let focusDurationMinutes: Int
    let isDefault: Bool

    init(id: UUID = UUID(), name: String, colorHex: String, focusDurationMinutes: Int, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.focusDurationMinutes = focusDurationMinutes
        self.isDefault = isDefault
    }
}

@Model
final class Tag {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: String
    var focusDurationMinutes: Int
    var isDefault: Bool
    @Relationship(deleteRule: .nullify, inverse: \PomodoroSession.tag) var sessions: [PomodoroSession]

    init(id: UUID = UUID(), name: String, colorHex: String, focusDurationMinutes: Int = 25, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.focusDurationMinutes = focusDurationMinutes
        self.isDefault = isDefault
        self.sessions = []
    }
}

extension Tag {
    static let defaultID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    /// Maps each preset's colorHex to its localization key.
    /// colorHex is unique per preset and unchanged by users, making it a reliable identity.
    static let presetLocalizationKeyByColor: [String: String] = [
        AppTheme.paperShadowHex:        "tag.default.focus",
        AppTheme.TagPalette.reviewHex:  "tag.default.review",
        AppTheme.TagPalette.writingHex: "tag.default.writing",
        AppTheme.TagPalette.readingHex: "tag.default.reading",
        AppTheme.TagPalette.designHex:  "tag.default.design",
        AppTheme.TagPalette.codingHex:  "tag.default.coding",
    ]

    /// All known preset names across every supported language.
    /// If a tag's name is in this set, the user has not customized it.
    static let allKnownPresetNames: Set<String> = [
        "Focus", "专注", "專注", "集中",
        "Review", "复盘", "複盤", "振り返り",
        "Writing", "写作", "寫作", "ライティング",
        "Reading", "阅读", "閱讀", "読書",
        "Design", "设计", "設計", "デザイン",
        "Coding", "编码", "編碼", "コーディング",
    ]

    static let presets: [TagPreset] = [
        TagPreset(id: defaultID, name: String(localized: "tag.default.focus"), colorHex: AppTheme.paperShadowHex, focusDurationMinutes: 25, isDefault: true),
        TagPreset(name: String(localized: "tag.default.review"),  colorHex: AppTheme.TagPalette.reviewHex,  focusDurationMinutes: 15),
        TagPreset(name: String(localized: "tag.default.writing"), colorHex: AppTheme.TagPalette.writingHex,  focusDurationMinutes: 25),
        TagPreset(name: String(localized: "tag.default.reading"), colorHex: AppTheme.TagPalette.readingHex,  focusDurationMinutes: 30),
        TagPreset(name: String(localized: "tag.default.design"),  colorHex: AppTheme.TagPalette.designHex,   focusDurationMinutes: 45),
        TagPreset(name: String(localized: "tag.default.coding"),  colorHex: AppTheme.TagPalette.codingHex,   focusDurationMinutes: 45),
    ]
}
