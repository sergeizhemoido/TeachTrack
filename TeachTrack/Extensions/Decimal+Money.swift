import Foundation

extension Decimal {
    /// Shows money in the device's currency, without unnecessary trailing cents.
    var moneyFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = .current
        formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: self))
            ?? "\(Locale.current.currencySymbol ?? "$")\(formatted())"
    }
}
