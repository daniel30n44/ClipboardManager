import Foundation
import SwiftUI

// MARK: - 支持的语言 · Supported Languages

enum AppLanguage: String, CaseIterable {
    case chinese
    case english
    case japanese
    case korean
    case spanish
    case portuguese

    var displayName: String {
        switch self {
        case .chinese:    return "中文"
        case .english:    return "English"
        case .japanese:   return "日本語"
        case .korean:     return "한국어"
        case .spanish:    return "Español"
        case .portuguese: return "Português"
        }
    }

    var shortName: String {
        switch self {
        case .chinese:    return "中文"
        case .english:    return "EN"
        case .japanese:   return "日本語"
        case .korean:     return "한국어"
        case .spanish:    return "ES"
        case .portuguese: return "PT"
        }
    }
}

// MARK: - 本地化管理器 · Localization Service

class LocalizationService: ObservableObject {
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
        }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "appLanguage") ?? ""
        currentLanguage = AppLanguage(rawValue: saved) ?? .chinese
    }

    // MARK: - 简单查词

    func loc(_ key: String) -> String {
        let dict: [String: String]
        switch currentLanguage {
        case .chinese:    dict = chineseStrings
        case .english:    dict = englishStrings
        case .japanese:   dict = japaneseStrings
        case .korean:     dict = koreanStrings
        case .spanish:    dict = spanishStrings
        case .portuguese: dict = portugueseStrings
        }
        return dict[key] ?? key
    }

    /// 支持 String(format:) 占位符的格式化查词
    func loc(_ key: String, _ args: CVarArg...) -> String {
        let format = loc(key)
        return String(format: format, arguments: args)
    }

    // MARK: - 中文字典 · Chinese

    private let chineseStrings: [String: String] = [
        // ---- Settings ----
        "settings.title": "设置",
        "settings.retention.title": "历史保留时长",
        "settings.retention.description": "超过设定天数的记录会自动清理，置顶条目不受影响",
        "settings.retention.1day": "1 天",
        "settings.retention.3day": "3 天",
        "settings.retention.5day": "5 天",
        "settings.launch.title": "开机自动启动",
        "settings.launch.description": "登录系统时自动在菜单栏运行",
        "settings.launch.enabled": "已开启",
        "settings.launch.disabled": "已关闭",
        "settings.language.title": "语言",
        "settings.language.description": "更改应用显示语言",
        "settings.storage.title": "存储信息",
        "settings.storage.total": "总记录数",
        "settings.storage.text": "文字记录",
        "settings.storage.image": "图片记录",
        "settings.storage.pinned": "置顶条目",
        "settings.storage.unit": "%d 条",

        // ---- Navigation ----
        "nav.home": "历史粘贴板",
        "nav.search_placeholder": "搜索历史记录...",
        "nav.recent_3days": "· 3 天内",

        // ---- Main window ----
        "main.title": "历史记录",
        "main.subtitle": "最近 3 天的复制历史",
        "main.empty.title": "暂无复制记录",
        "main.empty.subtitle": "⌘C 复制的文字和图片会自动出现在这里",
        "main.empty.search_title": "未找到匹配结果",
        "main.empty.search_subtitle": "换个关键词试试",
        "main.search_results": "找到 %d 条匹配",
        "main.delete_alert.title": "确认删除",
        "main.delete_alert.message": "确定要删除这条记录吗？此操作不可撤销。",
        "main.delete_alert.cancel": "取消",
        "main.delete_alert.confirm": "删除",

        // ---- Card / Row ----
        "card.pinned": "置顶",
        "card.unpin": "取消置顶",
        "card.pin": "置顶",
        "card.delete": "删除",
        "card.image_lost": "图片已丢失",
        "card.tap_to_paste": "点击粘贴",

        // ---- Footer ----
        "footer.retention": "%d 天保留",
        "footer.total": "%d 条",

        // ---- Menu bar empty state ----
        "empty.no_records": "暂无复制记录",
        "empty.no_matches": "无匹配结果",
        "empty.hint": "⌘C 复制的文字和图片会自动出现在这里",
        "empty.try_other": "尝试其他关键词搜索",
    ]

    // MARK: - 英文字典 · English

    private let englishStrings: [String: String] = [
        // ---- Settings ----
        "settings.title": "Settings",
        "settings.retention.title": "History Retention",
        "settings.retention.description": "Records past the retention period are auto-cleaned. Pinned items are kept forever.",
        "settings.retention.1day": "1 Day",
        "settings.retention.3day": "3 Days",
        "settings.retention.5day": "5 Days",
        "settings.launch.title": "Launch at Login",
        "settings.launch.description": "Start silently in the menu bar when you log in",
        "settings.launch.enabled": "Enabled",
        "settings.launch.disabled": "Disabled",
        "settings.language.title": "Language",
        "settings.language.description": "Change the display language of this app",
        "settings.storage.title": "Storage Info",
        "settings.storage.total": "Total Records",
        "settings.storage.text": "Text Records",
        "settings.storage.image": "Image Records",
        "settings.storage.pinned": "Pinned Items",
        "settings.storage.unit": "%d items",

        // ---- Navigation ----
        "nav.home": "Clipboard History",
        "nav.search_placeholder": "Search history...",
        "nav.recent_3days": "· 3 days",

        // ---- Main window ----
        "main.title": "History",
        "main.subtitle": "Last 3 days of clipboard history",
        "main.empty.title": "No clipboard records",
        "main.empty.subtitle": "Text & images you ⌘C will show up here",
        "main.empty.search_title": "No matches",
        "main.empty.search_subtitle": "Try another keyword",
        "main.search_results": "Found %d matches",
        "main.delete_alert.title": "Delete Record",
        "main.delete_alert.message": "Delete this record? This cannot be undone.",
        "main.delete_alert.cancel": "Cancel",
        "main.delete_alert.confirm": "Delete",

        // ---- Card / Row ----
        "card.pinned": "Pinned",
        "card.unpin": "Unpin",
        "card.pin": "Pin",
        "card.delete": "Delete",
        "card.image_lost": "Image lost",
        "card.tap_to_paste": "Click to paste",

        // ---- Footer ----
        "footer.retention": "%d-day retention",
        "footer.total": "%d items",

        // ---- Menu bar empty state ----
        "empty.no_records": "No clipboard records",
        "empty.no_matches": "No matches",
        "empty.hint": "Text & images you ⌘C will show up here",
        "empty.try_other": "Try another keyword",
    ]

    // MARK: - 日文字典 · Japanese

    private let japaneseStrings: [String: String] = [
        // ---- Settings ----
        "settings.title": "設定",
        "settings.retention.title": "履歴保持期間",
        "settings.retention.description": "保持期間を過ぎた記録は自動削除されます。ピン留めした項目は永久に保持されます。",
        "settings.retention.1day": "1日",
        "settings.retention.3day": "3日",
        "settings.retention.5day": "5日",
        "settings.launch.title": "ログイン時に起動",
        "settings.launch.description": "ログイン時にメニューバーで自動起動します",
        "settings.launch.enabled": "有効",
        "settings.launch.disabled": "無効",
        "settings.language.title": "言語",
        "settings.language.description": "アプリの表示言語を変更",
        "settings.storage.title": "ストレージ情報",
        "settings.storage.total": "総記録数",
        "settings.storage.text": "テキスト記録",
        "settings.storage.image": "画像記録",
        "settings.storage.pinned": "ピン留め",
        "settings.storage.unit": "%d件",

        // ---- Navigation ----
        "nav.home": "クリップボード履歴",
        "nav.search_placeholder": "履歴を検索...",
        "nav.recent_3days": "· 3日間",

        // ---- Main window ----
        "main.title": "履歴",
        "main.subtitle": "最近3日間のクリップボード履歴",
        "main.empty.title": "記録なし",
        "main.empty.subtitle": "⌘Cでコピーしたテキストと画像がここに表示されます",
        "main.empty.search_title": "一致なし",
        "main.empty.search_subtitle": "別のキーワードをお試しください",
        "main.search_results": "%d件の一致",
        "main.delete_alert.title": "記録を削除",
        "main.delete_alert.message": "この記録を削除しますか？この操作は元に戻せません。",
        "main.delete_alert.cancel": "キャンセル",
        "main.delete_alert.confirm": "削除",

        // ---- Card / Row ----
        "card.pinned": "ピン留め",
        "card.unpin": "ピン解除",
        "card.pin": "ピン留め",
        "card.delete": "削除",
        "card.image_lost": "画像なし",
        "card.tap_to_paste": "クリックで貼り付け",

        // ---- Footer ----
        "footer.retention": "%d日間保持",
        "footer.total": "%d件",

        // ---- Menu bar empty state ----
        "empty.no_records": "記録なし",
        "empty.no_matches": "一致なし",
        "empty.hint": "⌘Cでコピーしたテキストと画像がここに表示されます",
        "empty.try_other": "別のキーワードをお試しください",
    ]

    // MARK: - 韩文字典 · Korean

    private let koreanStrings: [String: String] = [
        // ---- Settings ----
        "settings.title": "설정",
        "settings.retention.title": "기록 보관 기간",
        "settings.retention.description": "보관 기간이 지난 기록은 자동 삭제됩니다. 고정된 항목은 영구 보관됩니다.",
        "settings.retention.1day": "1일",
        "settings.retention.3day": "3일",
        "settings.retention.5day": "5일",
        "settings.launch.title": "로그인 시 시작",
        "settings.launch.description": "로그인 시 메뉴 바에서 자동으로 실행됩니다",
        "settings.launch.enabled": "켜짐",
        "settings.launch.disabled": "꺼짐",
        "settings.language.title": "언어",
        "settings.language.description": "앱 표시 언어 변경",
        "settings.storage.title": "저장 정보",
        "settings.storage.total": "총 기록",
        "settings.storage.text": "텍스트 기록",
        "settings.storage.image": "이미지 기록",
        "settings.storage.pinned": "고정 항목",
        "settings.storage.unit": "%d개",

        // ---- Navigation ----
        "nav.home": "클립보드 기록",
        "nav.search_placeholder": "기록 검색...",
        "nav.recent_3days": "· 3일",

        // ---- Main window ----
        "main.title": "기록",
        "main.subtitle": "최근 3일간 클립보드 기록",
        "main.empty.title": "기록 없음",
        "main.empty.subtitle": "⌘C로 복사한 텍스트와 이미지가 여기에 표시됩니다",
        "main.empty.search_title": "일치하는 결과 없음",
        "main.empty.search_subtitle": "다른 키워드를 입력해보세요",
        "main.search_results": "%d개 일치",
        "main.delete_alert.title": "기록 삭제",
        "main.delete_alert.message": "이 기록을 삭제하시겠습니까? 이 작업은 취소할 수 없습니다.",
        "main.delete_alert.cancel": "취소",
        "main.delete_alert.confirm": "삭제",

        // ---- Card / Row ----
        "card.pinned": "고정됨",
        "card.unpin": "고정 해제",
        "card.pin": "고정",
        "card.delete": "삭제",
        "card.image_lost": "이미지 손실",
        "card.tap_to_paste": "클릭하여 붙여넣기",

        // ---- Footer ----
        "footer.retention": "%d일 보관",
        "footer.total": "%d개",

        // ---- Menu bar empty state ----
        "empty.no_records": "기록 없음",
        "empty.no_matches": "일치 없음",
        "empty.hint": "⌘C로 복사한 텍스트와 이미지가 여기에 표시됩니다",
        "empty.try_other": "다른 키워드로 검색해보세요",
    ]

    // MARK: - 西班牙语字典 · Spanish

    private let spanishStrings: [String: String] = [
        // ---- Settings ----
        "settings.title": "Configuración",
        "settings.retention.title": "Retención del historial",
        "settings.retention.description": "Los registros que superen el período se eliminan automáticamente. Los elementos fijados se conservan siempre.",
        "settings.retention.1day": "1 día",
        "settings.retention.3day": "3 días",
        "settings.retention.5day": "5 días",
        "settings.launch.title": "Iniciar al iniciar sesión",
        "settings.launch.description": "Iniciar silenciosamente en la barra de menú al iniciar sesión",
        "settings.launch.enabled": "Activado",
        "settings.launch.disabled": "Desactivado",
        "settings.language.title": "Idioma",
        "settings.language.description": "Cambiar el idioma de la aplicación",
        "settings.storage.title": "Información de almacenamiento",
        "settings.storage.total": "Registros totales",
        "settings.storage.text": "Registros de texto",
        "settings.storage.image": "Registros de imagen",
        "settings.storage.pinned": "Elementos fijados",
        "settings.storage.unit": "%d elementos",

        // ---- Navigation ----
        "nav.home": "Historial del portapapeles",
        "nav.search_placeholder": "Buscar historial...",
        "nav.recent_3days": "· 3 días",

        // ---- Main window ----
        "main.title": "Historial",
        "main.subtitle": "Últimos 3 días del historial",
        "main.empty.title": "Sin registros",
        "main.empty.subtitle": "El texto e imágenes que copies con ⌘C aparecerán aquí",
        "main.empty.search_title": "Sin resultados",
        "main.empty.search_subtitle": "Prueba con otra palabra clave",
        "main.search_results": "%d coincidencias",
        "main.delete_alert.title": "Eliminar registro",
        "main.delete_alert.message": "¿Eliminar este registro? No se puede deshacer.",
        "main.delete_alert.cancel": "Cancelar",
        "main.delete_alert.confirm": "Eliminar",

        // ---- Card / Row ----
        "card.pinned": "Fijado",
        "card.unpin": "Desfijar",
        "card.pin": "Fijar",
        "card.delete": "Eliminar",
        "card.image_lost": "Imagen perdida",
        "card.tap_to_paste": "Clic para pegar",

        // ---- Footer ----
        "footer.retention": "Retención de %d días",
        "footer.total": "%d elementos",

        // ---- Menu bar empty state ----
        "empty.no_records": "Sin registros",
        "empty.no_matches": "Sin coincidencias",
        "empty.hint": "El texto e imágenes que copies con ⌘C aparecerán aquí",
        "empty.try_other": "Prueba con otra palabra clave",
    ]

    // MARK: - 葡萄牙语字典 · Portuguese

    private let portugueseStrings: [String: String] = [
        // ---- Settings ----
        "settings.title": "Configurações",
        "settings.retention.title": "Retenção do histórico",
        "settings.retention.description": "Registros além do período são removidos automaticamente. Itens fixados são mantidos para sempre.",
        "settings.retention.1day": "1 dia",
        "settings.retention.3day": "3 dias",
        "settings.retention.5day": "5 dias",
        "settings.launch.title": "Iniciar ao fazer login",
        "settings.launch.description": "Iniciar silenciosamente na barra de menu ao fazer login",
        "settings.launch.enabled": "Ativado",
        "settings.launch.disabled": "Desativado",
        "settings.language.title": "Idioma",
        "settings.language.description": "Alterar o idioma do aplicativo",
        "settings.storage.title": "Informações de armazenamento",
        "settings.storage.total": "Total de registros",
        "settings.storage.text": "Registros de texto",
        "settings.storage.image": "Registros de imagem",
        "settings.storage.pinned": "Itens fixados",
        "settings.storage.unit": "%d itens",

        // ---- Navigation ----
        "nav.home": "Histórico da área de transferência",
        "nav.search_placeholder": "Pesquisar histórico...",
        "nav.recent_3days": "· 3 dias",

        // ---- Main window ----
        "main.title": "Histórico",
        "main.subtitle": "Últimos 3 dias do histórico",
        "main.empty.title": "Nenhum registro",
        "main.empty.subtitle": "Textos e imagens copiados com ⌘C aparecerão aqui",
        "main.empty.search_title": "Nenhum resultado",
        "main.empty.search_subtitle": "Tente outra palavra-chave",
        "main.search_results": "%d resultados",
        "main.delete_alert.title": "Excluir registro",
        "main.delete_alert.message": "Excluir este registro? Esta ação não pode ser desfeita.",
        "main.delete_alert.cancel": "Cancelar",
        "main.delete_alert.confirm": "Excluir",

        // ---- Card / Row ----
        "card.pinned": "Fixado",
        "card.unpin": "Desafixar",
        "card.pin": "Fixar",
        "card.delete": "Excluir",
        "card.image_lost": "Imagem perdida",
        "card.tap_to_paste": "Clique para colar",

        // ---- Footer ----
        "footer.retention": "Retenção de %d dias",
        "footer.total": "%d itens",

        // ---- Menu bar empty state ----
        "empty.no_records": "Nenhum registro",
        "empty.no_matches": "Nenhum resultado",
        "empty.hint": "Textos e imagens copiados com ⌘C aparecerão aqui",
        "empty.try_other": "Tente outra palavra-chave",
    ]
}
