import SwiftUI

/// The PlayMatch color system. One brand accent (the vivid orange
/// from RJ's website, #e8590c) for primary buttons and the tab bar,
/// plus one distinct color per sport for pins, chips and sections.
/// The rest of the UI stays light and simple.
enum PlayMatchColors {
    /// Brand orange, from RJ's website (#e8590c).
    static let brand = rgb(232, 89, 12)
    static let basketball = brand
    static let soccer = rgb(47, 158, 68)
    static let football = rgb(141, 90, 43)
    static let tennis = rgb(130, 201, 30)
    static let pickleball = rgb(18, 184, 134)
    static let tableTennis = rgb(230, 73, 128)
    /// Golf is not open yet (phase 4) but is mapped so it is ready.
    static let golf = rgb(250, 176, 5)
    static let multi = rgb(112, 72, 232)

    private static func rgb(_ r: Int, _ g: Int, _ b: Int) -> Color {
        Color(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}

/// The sport tab bar shared by the Location and Events tabs, and the
/// pure helpers that decide which courts and games a sport tab shows.
///
/// Sport tags are the Court.sport values ("basketball", "soccer",
/// "football" for American football, "tennis", "pickleball",
/// "table_tennis", "multi"). They are NOT the OSM query tags: the
/// Overpass query uses "american_football" where Court.sport uses
/// "football". Display names come from UserProfile.allSports.
enum SportTabs {
    static let allTag = "all"

    /// One launch sport: its Court.sport tag and its display label.
    struct SportOption: Identifiable {
        var tag: String
        var label: String
        var id: String { tag }
    }

    /// The six launch sports, in tab order.
    static let sports: [SportOption] = [
        SportOption(tag: "basketball", label: "Basketball"),
        SportOption(tag: "soccer", label: "Soccer"),
        SportOption(tag: "football", label: "American Football"),
        SportOption(tag: "tennis", label: "Tennis"),
        SportOption(tag: "pickleball", label: "Pickleball"),
        SportOption(tag: "table_tennis", label: "Table Tennis"),
    ]

    /// The six real sport tags. "multi" (a pitch serving several
    /// sports) and "all" are not real sports.
    static let realSports: Set<String> = Set(sports.map(\.tag))

    /// Display label for a sport tag, or "All" for the All tab.
    /// Unknown tags fall back to Basketball, like Court.defaultName.
    static func label(forTag tag: String) -> String {
        if tag == allTag { return "All" }
        return sports.first { $0.tag == tag }?.label ?? "Basketball"
    }

    /// Court.sport tag for a profile display name ("American Football"
    /// -> "football"). Nil for names that are not a launch sport.
    static func tag(forDisplayName name: String) -> String? {
        switch name {
        case "Basketball": return "basketball"
        case "Soccer": return "soccer"
        case "American Football": return "football"
        case "Tennis": return "tennis"
        case "Pickleball": return "pickleball"
        case "Table Tennis": return "table_tennis"
        default: return nil
        }
    }

    /// A court shows on a sport tab when the tab is All, the court is
    /// that sport, or the court is a multi-sport pitch (it can host any
    /// sport). Pure so it is unit-testable.
    static func courtMatches(_ court: Court, filter: String) -> Bool {
        if filter == allTag { return true }
        return court.sport == filter || court.sport == "multi"
    }

    /// A game shows on a sport tab when the tab is All or the game is
    /// that sport. Games always carry a real sport (the create form
    /// picks one), so there is no multi-sport case here.
    static func eventMatches(_ event: GameEvent, filter: String) -> Bool {
        if filter == allTag { return true }
        return event.sport == filter
    }

    /// The sport tab a court opens on: the court's sport when it is one
    /// of the six real sports, otherwise All (a multi-sport pitch hosts
    /// games of any sport, so no single tab fits it).
    static func filterForCourt(_ court: Court?) -> String {
        guard let court, realSports.contains(court.sport) else { return allTag }
        return court.sport
    }

    /// The default sport for a new game: the court's sport when it is
    /// one of the six real sports, else the signed-in user's primary
    /// sport, else basketball. A multi-sport pitch has no single sport,
    /// so it falls through to the player's primary sport.
    static func defaultSport(court: Court?, primarySportDisplayName: String?) -> String {
        if let court, realSports.contains(court.sport) { return court.sport }
        if let primarySportDisplayName, let tag = tag(forDisplayName: primarySportDisplayName) {
            return tag
        }
        return "basketball"
    }

    /// The icons shown together on the All chip, one per launch
    /// sport in tab order: the same symbol each sport's own chip
    /// shows, so the cluster always stays in sync with the chips
    /// (including the soccer symbol below). Never the
    /// basketball-court icon: the All chip shows all six sports,
    /// not one court. Pure so it is unit-testable.
    static var allChipSymbols: [String] {
        sports.map { pinStyle(forTag: $0.tag).symbol }
    }

    /// The map pin for a sport: the white SF Symbol drawn in the pin
    /// and the pin's color. The ball sports use their ball
    /// symbol; pickleball, table tennis and golf use their figure
    /// symbol, because Apple ships no ball-only symbol for them.
    /// Golf is not open yet (phase 4) but is mapped so it is ready.
    /// "multi" is a pitch serving several sports, shown with a
    /// runner. Unknown tags fall back to basketball. Pure so it is
    /// unit-testable.
    /// NOTE: soccer uses the base "soccerball", NOT
    /// "soccerball.fill": that .fill variant does not ship on the
    /// deployment target, and SwiftUI renders an unknown
    /// systemName as nothing (no error, no placeholder), which is
    /// why the Soccer chip used to show its label with no ball
    /// at all. The base name is long-established and renders
    /// everywhere the app runs.
    /// NOTE: map pins only. The loading indicator must NOT use this
    /// mapping — it uses loadingBallStyle(forTag:) below, which is
    /// ball-only (no figure.* symbols, which can render blank on
    /// iOS versions that do not ship them).
    static func pinStyle(forTag tag: String) -> (symbol: String, color: Color) {
        switch tag {
        case "basketball": return ("basketball.fill", PlayMatchColors.basketball)
        case "soccer": return ("soccerball", PlayMatchColors.soccer)
        case "football": return ("football.fill", PlayMatchColors.football)
        case "tennis": return ("tennisball.fill", PlayMatchColors.tennis)
        case "pickleball": return ("figure.pickleball", PlayMatchColors.pickleball)
        case "table_tennis": return ("figure.table.tennis", PlayMatchColors.tableTennis)
        case "golf": return ("figure.golf", PlayMatchColors.golf)
        case "multi": return ("figure.run", PlayMatchColors.multi)
        default: return ("basketball.fill", PlayMatchColors.basketball)
        }
    }

    /// The loading-indicator icon for a sport: a sports BALL only,
    /// never a person. The four ball sports use their own ball
    /// symbol; pickleball, table tennis and golf have no ball-only
    /// SF Symbol, so they use the generic ball "circle.fill" in
    /// their own sport color (the color is what tells them apart
    /// while loading). Only long-established symbols are used, so
    /// the icon renders on every iOS version — a symbol the OS
    /// does not ship renders as nothing, which is how the loading
    /// indicator used to show no icon at all on some steps.
    /// Soccer uses the base "soccerball" for that reason (see
    /// pinStyle above): "soccerball.fill" does not ship, so the
    /// soccer step of the loading cycle used to render blank.
    /// "multi" is not in the loading cycle; it falls back to
    /// basketball like any unknown tag. The symbol is never empty.
    /// Pure so it is unit-testable.
    static func loadingBallStyle(forTag tag: String) -> (symbol: String, color: Color) {
        switch tag {
        case "basketball": return ("basketball.fill", PlayMatchColors.basketball)
        case "soccer": return ("soccerball", PlayMatchColors.soccer)
        case "football": return ("football.fill", PlayMatchColors.football)
        case "tennis": return ("tennisball.fill", PlayMatchColors.tennis)
        case "pickleball": return ("circle.fill", PlayMatchColors.pickleball)
        case "table_tennis": return ("circle.fill", PlayMatchColors.tableTennis)
        case "golf": return ("circle.fill", PlayMatchColors.golf)
        default: return ("basketball.fill", PlayMatchColors.basketball)
        }
    }

    /// The color for a sport tab or chip: the sport's color, or the
    /// brand orange for the All tab.
    static func color(forTag tag: String) -> Color {
        if tag == allTag { return PlayMatchColors.brand }
        return pinStyle(forTag: tag).color
    }
}

/// Bright, glamorous background wash for every screen: a soft
/// sunrise gradient (warm white -> peach -> pale sky) that reads
/// noticeably brighter and more polished than plain white, while
/// staying light so text stays readable. In dark mode it falls
/// back to a faint brand-orange tint over the system background
/// so it never goes muddy.
struct AppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    /// The bright sunrise gradient in light mode: warm white ->
    /// peach -> pale sky. Pure data, so the unit tests pin the
    /// colours down.
    static let lightGradientColors: [Color] = [
        Color(red: 1.00, green: 0.99, blue: 0.96),
        Color(red: 1.00, green: 0.93, blue: 0.85),
        Color(red: 0.97, green: 0.95, blue: 1.00),
    ]

    /// Dark mode: a faint brand-orange tint over the system
    /// background, so it never goes muddy.
    static let darkGradientColors: [Color] = [
        PlayMatchColors.brand.opacity(0.18),
        PlayMatchColors.brand.opacity(0.06),
        Color(.systemBackground),
    ]

    var body: some View {
        LinearGradient(
            colors: colorScheme == .dark ? Self.darkGradientColors : Self.lightGradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }
}

extension View {
    /// The shared bright PlayMatch background. Put it on the root
    /// of a screen; for Lists also add `.scrollContentBackground(.hidden)`
    /// so the gradient shows through behind the rows.
    func appBackground() -> some View {
        background { AppBackground() }
    }
}

/// Horizontal scrollable sport chips: All + the six launch sports.
/// The selected chip is filled; the rest are quiet. Used at the top
/// of the Location and Events tabs so each sport has its own view.
/// With `vertical` (Events tab only) each chip is bigger, with the
/// sport icon on top and the label underneath it.
struct SportTabBar: View {
    @Binding var selected: String
    var vertical: Bool = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(tag: SportTabs.allTag, label: "All")
                ForEach(SportTabs.sports) { sport in
                    chip(tag: sport.tag, label: sport.label)
                }
            }
            .padding(.horizontal)
        }
    }

    /// The six sport icons for the All chip, as a small cluster.
    /// `perRow` icons per row at `iconSize` points: the vertical
    /// (Events) chip uses 3 per row so the cluster is two rows of
    /// three at roughly the same height as the other chips' single
    /// 30pt icon; the horizontal (Location) chip uses all 6 in one
    /// row at the small size its icons already are. The icons
    /// inherit the chip's foreground color (white when selected,
    /// primary when not), like the single icons they replace.
    private func allSportsCluster(iconSize: CGFloat, perRow: Int, spacing: CGFloat) -> some View {
        let symbols = SportTabs.allChipSymbols
        let rows: [[String]] = stride(from: 0, to: symbols.count, by: perRow).map {
            Array(symbols[$0..<min($0 + perRow, symbols.count)])
        }
        return VStack(spacing: spacing) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(row, id: \.self) { symbol in
                        Image(systemName: symbol)
                            .font(.system(size: iconSize))
                    }
                }
            }
        }
    }

    private func chip(tag: String, label: String) -> some View {
        Button {
            selected = tag
        } label: {
            if vertical {
                // Events tab: big icon on top, label underneath.
                // The All chip shows all six sport icons together
                // as a small cluster instead of the basketball
                // court icon; the other chips keep their single
                // 30pt ball icon.
                VStack(spacing: 4) {
                    if tag == SportTabs.allTag {
                        allSportsCluster(iconSize: 14, perRow: 3, spacing: 3)
                    } else {
                        Image(systemName: SportTabs.pinStyle(forTag: tag).symbol)
                            .font(.system(size: 30))
                    }
                    Text(label)
                        .font(.caption.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(minWidth: 72)
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .background(selected == tag ? SportTabs.color(forTag: tag) : Color(.systemGray5))
                .foregroundColor(selected == tag ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                // Location tab: compact horizontal chip. The All
                // chip shows the same six-icon cluster in one small
                // row instead of the basketball court icon.
                HStack(spacing: 6) {
                    if tag == SportTabs.allTag {
                        allSportsCluster(iconSize: 11, perRow: 6, spacing: 2)
                    } else {
                        Image(systemName: SportTabs.pinStyle(forTag: tag).symbol)
                    }
                    Text(label)
                }
                    .font(.subheadline.bold())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(selected == tag ? SportTabs.color(forTag: tag) : Color(.systemGray5))
                    .foregroundColor(selected == tag ? .white : .primary)
                    .clipShape(Capsule())
            }
        }
        .buttonStyle(.plain)
    }
}
