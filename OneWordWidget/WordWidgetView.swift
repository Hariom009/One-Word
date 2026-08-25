//
//  WordWidgetView.swift
//  OneWordWidget
//
//  Word-of-the-day card, monochrome: a pure white (light) / pure black (dark)
//  container with the system label hierarchy for everything on it — no palette,
//  no accent. Content grows with the family:
//    small  — headword · pos · hindi
//    medium — + accent rule + definition (3 lines)
//    large  — + bigger type + example under a hairline
//  Both appearances follow the system color scheme.
//
//  ponytail: headword/example use the system serif (New York) and pos/definition
//  the system sans — stand-ins for Newsreader / Instrument Sans. Hindi uses the
//  platform Devanagari face for Tiro Devanagari Hindi. Bundle those three .ttf +
//  register UIAppFonts (widget target) to reach the pixel-exact spec.
//

import SwiftUI
import WidgetKit
import AppIntents

private extension AnyTransition {
    /// One line of the card arriving. `rank` 0 is the headword, and each line below it
    /// starts a little later and travels a little less, so the card uncovers downward:
    /// headword → part of speech → meaning → definition → example.
    ///
    /// ponytail: a stagger rather than anything fancier, and that is a platform limit.
    /// WidgetKit renders out of process and animates only what DIFFERS between two
    /// consecutive entry snapshots — so a covering/uncovering element, invisible in
    /// both snapshots, is never interpolated and its transition is dropped in full.
    /// A built-in transition on the text DOES animate, because the text genuinely
    /// differs between snapshots — which is what this uses.
    static func line(_ rank: Int) -> AnyTransition {
        let lift = 15 - CGFloat(rank) * 2.2
        return .asymmetric(
            insertion: .offset(y: -lift).combined(with: .opacity)
                .animation(.easeOut(duration: 0.42).delay(Double(rank) * 0.07)),
            removal: .opacity.animation(.easeIn(duration: 0.16))
        )
    }
}

// MARK: - View

struct WordWidgetView: View {
    let entry: WordEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let w = entry.word
        ZStack(alignment: .topTrailing) {
            // No .id/.transition on the container: each line carries its own, so they
            // arrive in sequence rather than the whole card swapping at once.
            Group {
                switch family {
                case .systemSmall: small(w)
                case .systemLarge: large(w)
                default:           medium(w)   // .systemMedium
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            refresh()                        // drawn last, never moves
        }
        .containerBackground(scheme == .dark ? .black : .white, for: .widget)
    }

    // MARK: Refresh — outside the reveal, so it never moves

    /// Refresh glyph size / tap frame / card inset.
    private var metrics: (glyph: CGFloat, hit: CGFloat, pad: CGFloat) {
        switch family {
        case .systemSmall: return (14, 20, 16)
        case .systemLarge: return (17, 26, 26)
        default:           return (15, 22, 17)
        }
    }

    private func refresh() -> some View {
        let m = metrics
        return Button(intent: RefreshWordIntent()) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: m.glyph, weight: .regular))
                .foregroundStyle(.tertiary)
                .frame(width: m.hit, height: m.hit)
                .contentShape(Rectangle())   // ponytail: tap area = glyph frame; 44pt would overlap headword
        }
        .buttonStyle(.plain)
        .padding(.top, m.pad)
        .padding(.trailing, m.pad)
    }

    // MARK: Shared header — headword + part of speech

    @ViewBuilder
    private func header(_ w: Word,
                        headword: CGFloat, hwWeight: Font.Weight, hwTracking: CGFloat,
                        posGap: CGFloat, pos: CGFloat, posTracking: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: posGap) {
            Text(w.term)
                .font(.serif(headword, hwWeight))
                .tracking(hwTracking)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.4)   // long headwords (e.g. "hypercalcaemia") shrink to fit, never truncate
                .id("hw-\(w.term)")
                .transition(.line(0))
            Text(w.partOfSpeech.uppercased())
                .font(.system(size: pos, weight: .medium))
                .tracking(posTracking)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .id("pos-\(w.term)")
                .transition(.line(1))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.trailing, metrics.hit + 6)   // reserve room for the refresh glyph
    }

    // MARK: Rule + Hindi (medium & large)

    @ViewBuilder
    private func ruledHindi(_ w: Word, size: CGFloat, gap: CGFloat, lines: Int) -> some View {
        if AppGroup.showHindi {
            HStack(alignment: .top, spacing: gap) {
                RoundedRectangle(cornerRadius: 1).fill(.tertiary).frame(width: 2)
                Text(w.hindi)
                    .font(.system(size: size))
                    .lineSpacing(2)
                    .foregroundStyle(.primary)
                    .lineLimit(lines)
                    .minimumScaleFactor(0.55)   // Hindi is sentence-length; shrink to fill its lines rather than truncate
            }
            .fixedSize(horizontal: false, vertical: true)   // rule matches the Hindi's height
            .id("hi-\(w.term)")
            .transition(.line(2))
        }
    }

    // MARK: Small — headword · pos · hindi (no definition/rule/example)

    private func small(_ w: Word) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            header(w, headword: 23, hwWeight: .medium, hwTracking: -0.2,
                   posGap: 5, pos: 9.5, posTracking: 1.1)
            Spacer(minLength: 8)
            if AppGroup.showHindi {
                Text(w.hindi)
                    .font(.system(size: 15))
                    .lineSpacing(2)
                    .foregroundStyle(.primary)
                    .lineLimit(5)
                    .minimumScaleFactor(0.55)
                    .id("hi-\(w.term)")
                    .transition(.line(2))
            }
        }
        .padding(16)
    }

    // MARK: Medium — + rule + definition

    private func medium(_ w: Word) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            header(w, headword: 26, hwWeight: .medium, hwTracking: -0.3,
                   posGap: 6, pos: 10, posTracking: 1.2)
            Spacer(minLength: 6)
            VStack(alignment: .leading, spacing: 8) {
                ruledHindi(w, size: 15, gap: 12, lines: 2)
                if !w.definition.isEmpty {
                    Text(w.definition)
                        .font(.system(size: 12))
                        .lineSpacing(2)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .minimumScaleFactor(0.7)
                        .id("def-\(w.term)")
                        .transition(.line(3))
                }
            }
        }
        .padding(17)
    }

    // MARK: Large — + bigger type + example under a hairline

    private func large(_ w: Word) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 18) {
                header(w, headword: 40, hwWeight: .regular, hwTracking: -0.6,
                       posGap: 9, pos: 10.5, posTracking: 1.4)
                ruledHindi(w, size: 20, gap: 16, lines: 4)
                if !w.definition.isEmpty {
                    Text(w.definition)
                        .font(.system(size: 14))
                        .lineSpacing(3)
                        .foregroundStyle(.secondary)
                        .lineLimit(5)
                        .minimumScaleFactor(0.7)
                        .id("def-\(w.term)")
                        .transition(.line(3))
                }
            }
            Spacer(minLength: 12)
            if AppGroup.showExample, !w.example.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Rectangle().fill(.quaternary).frame(height: 1)
                    Text("“\(w.example)”")
                        .font(.serif(14).italic())
                        .lineSpacing(2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .id("ex-\(w.term)")
                        .transition(.line(4))
                }
            }
        }
        .padding(26)
    }
}
