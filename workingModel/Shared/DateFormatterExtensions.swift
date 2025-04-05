import Foundation

extension DateFormatter {
    /// Formatter for message timestamps (HH:mm)
    static var messageTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    /// Formatter for short dates (MM/dd/yyyy)
    static var shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter
    }()
    
    /// Formatter for medium dates with time (MMM d, yyyy HH:mm)
    static var mediumDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy HH:mm"
        return formatter
    }()
    
    /// Relative date formatter (Today, Yesterday, etc.)
    static var relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()
    
    /// Format a date with smart relative time
    static func smartDate(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today at " + messageTime.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday at " + messageTime.string(from: date)
        } else {
            // For older dates, check if it's in the current year
            let now = Date()
            if calendar.component(.year, from: now) == calendar.component(.year, from: date) {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d 'at' HH:mm"
                return formatter.string(from: date)
            } else {
                // If different year, include the year
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d, yyyy 'at' HH:mm"
                return formatter.string(from: date)
            }
        }
    }
}
