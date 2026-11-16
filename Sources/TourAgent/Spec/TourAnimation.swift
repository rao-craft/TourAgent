//  WHAT: An animation as a tuning line writes it, and as the views write it: `spring(0.4, 0.8)` or
//        `.spring(response: 0.4, dampingFraction: 0.8)` is `.spring(response: 0.4, dampingFraction: 0.8)`;
//        `easeOut(0.2)` or `.easeOut(duration: 0.2)` is `.easeOut(duration: 0.2)`.

import Foundation

struct TourAnimation: Equatable, Sendable {
    enum Curve: String, Sendable, CaseIterable {
        case spring, easeOut, easeIn, easeInOut, linear
    }

    let curve: Curve
    /// A spring's response, or a curve's duration, in seconds.
    let seconds: Double
    /// A spring's damping fraction; nil for a curve.
    let damping: Double?

    /// The Swift the views write.
    var swift: String {
        if curve == .spring, let damping {
            return ".spring(response: \(SwiftLiteral.number(seconds)), dampingFraction: \(SwiftLiteral.number(damping)))"
        }
        return ".\(curve.rawValue)(duration: \(SwiftLiteral.number(seconds)))"
    }

    static let forms = "spring(response, damping) like `spring(0.4, 0.8)`, or easeOut, easeIn, easeInOut or linear with seconds, like `easeOut(0.2)`"

    /// `text` read as an animation, or why it is not one.
    static func parse(_ text: String) -> Result<TourAnimation, LineError> {
        var value = text.trimmingCharacters(in: .whitespaces)
        if value.hasPrefix("Animation.") { value.removeFirst("Animation.".count) }
        if value.hasPrefix(".") { value.removeFirst() }
        guard let open = value.firstIndex(of: "("), value.hasSuffix(")") else {
            return .failure(LineError("`\(text)` is not an animation: write \(forms)"))
        }
        let name = String(value[..<open]).trimmingCharacters(in: .whitespaces)
        guard let curve = Curve(rawValue: name) else {
            return .failure(LineError("`\(name)` is not an animation this kit writes: write \(forms)"))
        }
        let inside = value[value.index(after: open)..<value.index(before: value.endIndex)]
        var numbers: [Double] = []
        for piece in inside.split(separator: ",", omittingEmptySubsequences: false) {
            var word = piece.trimmingCharacters(in: .whitespaces)
            // A label is taken where it is the one that curve has: `response:`, `dampingFraction:`, `duration:`.
            if let colon = word.firstIndex(of: ":") {
                let label = word[..<colon].trimmingCharacters(in: .whitespaces)
                let allowed = curve == .spring ? ["response", "dampingFraction", "damping"] : ["duration"]
                guard allowed.contains(label) else {
                    return .failure(LineError("`\(text)`: \(curve.rawValue) takes \(allowed.prefix(2).joined(separator: " and ")), not `\(label)`"))
                }
                word = word[word.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            }
            guard let number = Double(word), number.isFinite else {
                return .failure(LineError("`\(text)`: `\(word)` is not a number"))
            }
            numbers.append(number)
        }
        switch curve {
        case .spring:
            guard numbers.count == 2 else { return .failure(LineError("`\(text)`: a spring takes a response and a damping fraction, like `spring(0.4, 0.8)`")) }
            guard (0.01...10).contains(numbers[0]) else { return .failure(LineError("`\(text)`: a spring's response is 0.01 to 10 seconds")) }
            guard (0.01...2).contains(numbers[1]) else { return .failure(LineError("`\(text)`: a spring's damping fraction is 0.01 to 2")) }
            return .success(TourAnimation(curve: .spring, seconds: numbers[0], damping: numbers[1]))
        default:
            guard numbers.count == 1 else { return .failure(LineError("`\(text)`: \(curve.rawValue) takes its seconds, like `\(curve.rawValue)(0.2)`")) }
            guard (0...60).contains(numbers[0]) else { return .failure(LineError("`\(text)`: \(curve.rawValue) lasts 0 to 60 seconds")) }
            return .success(TourAnimation(curve: curve, seconds: numbers[0], damping: nil))
        }
    }
}
