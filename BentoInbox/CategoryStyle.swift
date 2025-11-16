import SwiftUI

// Centralized helpers for category visuals used across views.

func categoryIconName(for category: CategoryDTO) -> String {
    let name = category.name.lowercased()
    
    // Handle P1-P4 priority categories
    if name.contains("p1") || name.contains("needs attention") {
        return "exclamationmark.circle.fill"
    }
    if name.contains("p2") || name.contains("can wait") {
        return "clock.fill"
    }
    if name.contains("p3") || name.contains("newsletter") || name.contains("automated") {
        return "newspaper.fill"
    }
    if name.contains("p4") || name.contains("junk") {
        return "trash.fill"
    }
    
    // Original category matching
    switch name {
    case "uncategorized", "none", "other": return "tray"
    case "work", "office": return "briefcase.fill"
    case "personal", "home": return "person.fill"
    case "family": return "person.2.fill"
    case "friends": return "person.3.fill"
    case "finance", "bills", "receipts": return "dollarsign.circle.fill"
    case "shopping", "purchases": return "bag.fill"
    case "travel", "flights", "trips": return "airplane"
    case "news": return "newspaper.fill"
    case "social": return "at"
    case "updates", "alerts": return "bell.badge.fill"
    case "promotions", "ads", "marketing": return "sparkles"
    case "github", "dev", "code", "engineering": return "chevron.left.slash.chevron.right"
    case "health", "medical": return "heart.fill"
    case "fitness", "exercise": return "figure.run"
    case "food", "restaurants": return "fork.knife"
    case "music": return "music.note"
    case "events", "calendar": return "calendar"
    case "education", "school": return "book.fill"
    case "utilities": return "wrench.and.screwdriver.fill"
    case "support", "tickets": return "lifepreserver"
    case "photos", "images": return "photo.fill.on.rectangle.fill"
    case "videos", "media": return "film.fill"
    case "security": return "lock.shield.fill"
    case "travel docs", "boarding": return "doc.plaintext.fill"
    default:
        let curated = [
            "bolt.fill","leaf.fill","globe","cloud.fill","sun.max.fill","moon.stars.fill","flame.fill",
            "paperplane.fill","envelope.fill","bookmark.fill","flag.fill","map.fill","pin.fill",
            "mappin.and.ellipse","location.fill","car.fill","tram.fill","bicycle","scooter","bus.fill",
            "train.side.front.car","ferry.fill","airpods.gen3","headphones","book.closed.fill",
            "doc.richtext.fill","doc.text.image","tray.full.fill","archivebox.fill","shippingbox.fill",
            "shippingbox.circle.fill","creditcard.fill","gift.fill","bag.badge.plus","cart.fill",
            "tag.fill","ticket.fill","theatermasks.fill","gamecontroller.fill","puzzlepiece.fill",
            "cpu.fill","antenna.radiowaves.left.and.right","network","wifi","bolt.horizontal.fill",
            "printer.fill","scanner.fill","signature","wand.and.stars","list.bullet.rectangle.fill",
            "chart.bar.fill","chart.pie.fill","chart.xyaxis.line","gauge.with.dots.needle.bottom.50percent",
            "speedometer","checkmark.seal.fill","star.circle.fill","medal.fill","rosette","trophy.fill",
            "sparkle.magnifyingglass","magnifyingglass","paperclip","link","shield.checkered",
            "hand.thumbsup.fill","hand.raised.fill","hands.sparkles.fill","message.fill","bubble.left.fill",
            "bubbles.and.sparkles.fill","bell.fill","bell.badge","bell.circle.fill","megaphone.fill",
            "mail.stack","calendar.badge.clock","clock.fill","alarm.fill","hourglass","tray.and.arrow.down.fill",
            "arrow.up.doc.fill","externaldrive.fill","internaldrive.fill","server.rack","folder.fill",
            "folder.badge.person.crop","folder.badge.gearshape","building.columns.fill","house.fill",
            "house.and.flag.fill","sparkles.square.fill","square.grid.2x2.fill","square.grid.3x1.below.rectangle.fill"
        ]
        let idx = abs(category.id.hashValue) % curated.count
        return curated[idx]
    }
}

func categoryColor(for category: CategoryDTO) -> Color {
    if let hex = category.colorHex, let c = Color(hex: hex) {
        return c
    }
    let palette: [Color] = [
        Color(red: 0.93, green: 0.33, blue: 0.31),
        Color(red: 0.98, green: 0.62, blue: 0.20),
        Color(red: 1.00, green: 0.80, blue: 0.20),
        Color(red: 0.40, green: 0.76, blue: 0.65),
        Color(red: 0.20, green: 0.60, blue: 0.86),
        Color(red: 0.56, green: 0.47, blue: 0.80),
        Color(red: 0.55, green: 0.76, blue: 0.29),
        Color(red: 0.90, green: 0.49, blue: 0.13),
        Color(red: 0.67, green: 0.33, blue: 0.33),
        Color(red: 0.76, green: 0.21, blue: 0.48),
        Color(red: 0.35, green: 0.35, blue: 0.35),
        Color(red: 0.23, green: 0.50, blue: 0.43),
        Color(red: 0.12, green: 0.47, blue: 0.71),
        Color(red: 0.68, green: 0.78, blue: 0.28),
        Color(red: 0.40, green: 0.60, blue: 0.90),
        Color(red: 0.80, green: 0.70, blue: 0.90),
        Color(red: 1.00, green: 0.60, blue: 0.60),
        Color(red: 0.50, green: 0.80, blue: 0.80),
        Color(red: 0.90, green: 0.80, blue: 0.50),
        Color(red: 0.80, green: 0.50, blue: 0.60),
        Color(red: 0.70, green: 0.50, blue: 0.40),
        Color(red: 0.50, green: 0.70, blue: 0.50),
        Color(red: 0.60, green: 0.50, blue: 0.70),
        Color(red: 0.50, green: 0.60, blue: 0.80)
    ]
    let idx = abs(category.id.hashValue) % palette.count
    return palette[idx]
}

// Local-only Color hex init reused by the helper
private extension Color {
    init?(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexString.hasPrefix("#") { hexString.removeFirst() }
        guard hexString.count == 6,
              let value = UInt64(hexString, radix: 16) else { return nil }
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        self = Color(red: r, green: g, blue: b)
    }
}
