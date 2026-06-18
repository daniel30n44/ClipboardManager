import Foundation

extension Date {
    /// 相对时间描述（刚刚 / x分钟前 / x小时前 / x天前 / 具体日期）
    var relativeDescription: String {
        let now = Date()
        let interval = now.timeIntervalSince(self)

        if interval < 60 {
            return "刚刚"
        } else if interval < 3600 {
            return "\(Int(interval / 60)) 分钟前"
        } else if interval < 86400 {
            return "\(Int(interval / 3600)) 小时前"
        } else if interval < 172800 {
            return "昨天"
        } else if interval < 604800 {
            return "\(Int(interval / 86400)) 天前"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM/dd HH:mm"
            return formatter.string(from: self)
        }
    }

    /// 简短时间格式 (HH:mm)
    var shortTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }

    /// 完整日期格式
    var fullDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        return formatter.string(from: self)
    }
}
