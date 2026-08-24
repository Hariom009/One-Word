//
//  WordDetail.swift
//  OneWord
//
//  One word, editorial layout: optional date line, serif headword + italic part
//  of speech, a Devanagari meaning with an accent rule, the definition, and a
//  "Used as" example footer. Shared by WordView (today, showDate) and the list detail.
//

import SwiftUI
import AVFoundation

// ponytail: one shared synth — a local would deallocate mid-utterance.
@MainActor private let speaker = AVSpeechSynthesizer()

struct WordDetail: View {
    let word: Word
    var showDate: Bool = false
    var dictionaryName: String? = nil
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = Theme.of(scheme)
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                //if showDate { dateLine(t) }

                HStack(alignment: .lastTextBaseline, spacing: 16) {
                    Text(word.term)
                        .font(.serif(64))
                        .foregroundStyle(t.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                    Text(word.partOfSpeech)
                        .font(.serif(22).italic())
                        .foregroundStyle(t.muted)
                }

                if !word.hindi.isEmpty {
                    Text(word.hindi)
                        .font(.system(size: 25))
                        .foregroundStyle(t.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.leading, 18)
                        .overlay(alignment: .leading) {
                            Rectangle().fill(t.rule).frame(width: 2)
                        }
                        .padding(.top, 26)
                }

                Text(word.definition)
                    .font(.serif(22))
                    .foregroundStyle(t.definition)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 26)

                footer(t)
            }
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 56)
            .padding(.vertical, 44)
        }
        .scrollContentBackground(.hidden)
        .background(t.background)
        // in WordDetail, not WordView, so the list's detail screen gets it too
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    speaker.stopSpeaking(at: .immediate)   // rapid clicks replace, don't queue
                    let utterance = AVSpeechUtterance(string: word.term)
                    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                    speaker.speak(utterance)
                } label: {
                    Label("Pronounce", systemImage: "speaker.wave.2")
                }
                .help("Pronounce \(word.term)")
            }
        }
    }

//    private func dateLine(_ t: Theme) -> some View {
//        let date = Date.now.formatted(.dateTime.month(.wide).day())
//        let text = dictionaryName.map { "\($0) · Word for \(date)" } ?? "Word for \(date)"
//        return HStack(spacing: 12) {
//            Text(text)
//                .font(.system(size: 11, weight: .semibold))
//                .textCase(.uppercase)
//                .tracking(2)
//                .foregroundStyle(t.accent)
//        }
//        .padding(.bottom, 14)
//    }

    @ViewBuilder
    private func footer(_ t: Theme) -> some View {
        if !word.example.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Used as")
                    .font(.system(size: 10, weight: .bold))
                    .textCase(.uppercase).tracking(1.6)
                    .foregroundStyle(t.muted)
                Text("\u{201C}\(word.example)\u{201D}")
                    .font(.serif(20).italic())
                    .foregroundStyle(t.example)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 24)
            .overlay(alignment: .top) { Rectangle().fill(t.hairline).frame(height: 1) }
            .padding(.top, 34)
        } else {
            Label("No example on file", systemImage: "book.closed")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(t.muted)
                .padding(.top, 40)
        }
    }
}
