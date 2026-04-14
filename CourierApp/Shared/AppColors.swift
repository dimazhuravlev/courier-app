import SwiftUI

extension Color {

    // Surface

    /// #0F1215
    static let surface0 = Color(red: 15 / 255, green: 18 / 255, blue: 21 / 255)
    /// #22262B
    static let surface1 = Color(red: 34 / 255, green: 38 / 255, blue: 43 / 255)
    /// #34373C
    static let surface2 = Color(red: 52 / 255, green: 55 / 255, blue: 60 / 255)
    /// rgba(155, 165, 176, 0.1)
    static let surface3 = Color(red: 155 / 255, green: 165 / 255, blue: 176 / 255, opacity: 0.1)

    // Fill

    /// #FFFFFF0A
    static let fill1 = Color(red: 1, green: 1, blue: 1, opacity: 10 / 255)
    /// #FFFFFF0F
    static let fill2 = Color(red: 1, green: 1, blue: 1, opacity: 15 / 255)
    /// #FFFFFF14
    static let fill3 = Color(red: 1, green: 1, blue: 1, opacity: 20 / 255)
    /// #FFFFFF1A
    static let fill4 = Color(red: 1, green: 1, blue: 1, opacity: 26 / 255)
    /// #FFFFFF33
    static let fill5 = Color(red: 1, green: 1, blue: 1, opacity: 51 / 255)
    /// #FFFFFF66
    static let fill6 = Color(red: 1, green: 1, blue: 1, opacity: 102 / 255)
    /// #FFFFFF
    static let fillInverted = Color.white
    /// #0000001F
    static let overlayHover = Color(red: 0, green: 0, blue: 0, opacity: 31 / 255)

    // Text

    /// #FFFFFF
    static let text1 = Color.white
    /// rgba(255, 255, 255, 0.40)
    static let text2 = Color(red: 1, green: 1, blue: 1, opacity: 0.4)
    /// rgba(255, 255, 255, 0.20)
    static let text3 = Color(red: 1, green: 1, blue: 1, opacity: 0.2)
    /// #0F1215
    static let textInverted = Color(red: 15 / 255, green: 18 / 255, blue: 21 / 255)

    // Stroke

    /// rgba(255, 255, 255, 0.04)
    static let stroke1 = Color(red: 1, green: 1, blue: 1, opacity: 0.04)
    /// rgba(255, 255, 255, 0.06)
    static let stroke2 = Color(red: 1, green: 1, blue: 1, opacity: 0.06)
    /// rgba(255, 255, 255, 0.10)
    static let stroke3 = Color(red: 1, green: 1, blue: 1, opacity: 0.1)

    // Accent

    /// #03AB00
    static let success = Color(red: 3 / 255, green: 171 / 255, blue: 0 / 255)
    /// #B21AFF
    static let accent = Color(red: 178 / 255, green: 26 / 255, blue: 255 / 255)
    /// #E8306E
    static let danger = Color(red: 232 / 255, green: 48 / 255, blue: 110 / 255)
    /// #03AB0033
    static let successSurface = Color(red: 3 / 255, green: 171 / 255, blue: 0 / 255, opacity: 51 / 255)
    /// #570F27
    static let dangerSurfaceStrong = Color(red: 87 / 255, green: 15 / 255, blue: 39 / 255)
    /// #E8306E33
    static let dangerSurface = Color(red: 232 / 255, green: 48 / 255, blue: 110 / 255, opacity: 51 / 255)
    /// #F16D00
    static let warning = Color(red: 241 / 255, green: 109 / 255, blue: 0)
    /// rgba(241, 109, 0, 0.1)
    static let warningSurface = Color(red: 241 / 255, green: 109 / 255, blue: 0, opacity: 0.1)
}
