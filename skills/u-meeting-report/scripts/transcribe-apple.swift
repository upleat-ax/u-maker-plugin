#!/usr/bin/env swift

// Apple Speech Framework 기반 m4a 전사 스크립트
// 의존성: 없음 (macOS 내장 Speech.framework 사용)
// 사용법: swift transcribe-apple.swift <m4a파일경로> [언어코드]
// 예시: swift transcribe-apple.swift meeting.m4a ko-KR

import Foundation
import Speech
import AVFoundation

// MARK: - Arguments

guard CommandLine.arguments.count >= 2 else {
    fputs("Usage: swift transcribe-apple.swift <audio_file> [locale] [--json]\n", stderr)
    fputs("  locale: ko-KR (default), en-US, ja-JP, etc.\n", stderr)
    fputs("  --json: output as JSON with timestamps\n", stderr)
    exit(1)
}

let audioPath = CommandLine.arguments[1]
let localeId = CommandLine.arguments.count >= 3 && !CommandLine.arguments[2].hasPrefix("--")
    ? CommandLine.arguments[2]
    : "ko-KR"
let jsonOutput = CommandLine.arguments.contains("--json")

let audioURL = URL(fileURLWithPath: audioPath)

guard FileManager.default.fileExists(atPath: audioPath) else {
    fputs("Error: File not found: \(audioPath)\n", stderr)
    exit(1)
}

// MARK: - Helpers

struct Segment {
    let text: String
    let start: Double
    let duration: Double
    let confidence: Float
}

func formatTime(_ seconds: Double) -> String {
    let mins = Int(seconds) / 60
    let secs = Int(seconds) % 60
    return String(format: "%02d:%02d", mins, secs)
}

// MARK: - Speech Recognition (async on main RunLoop)

var finished = false

func runRecognition() {
    SFSpeechRecognizer.requestAuthorization { status in
        DispatchQueue.main.async {
            guard status == .authorized else {
                fputs("Error: Speech recognition not authorized (status: \(status.rawValue))\n", stderr)
                fputs("Go to System Settings > Privacy & Security > Speech Recognition and enable access.\n", stderr)
                exit(1)
            }
            startTranscription()
        }
    }
}

func startTranscription() {
    guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeId)) else {
        fputs("Error: Speech recognizer not available for locale: \(localeId)\n", stderr)
        exit(1)
    }

    guard recognizer.isAvailable else {
        fputs("Error: Speech recognizer is not available. Check network and system settings.\n", stderr)
        exit(1)
    }

    let request = SFSpeechURLRecognitionRequest(url: audioURL)
    request.shouldReportPartialResults = false
    request.addsPunctuation = true

    if #available(macOS 13, *) {
        request.requiresOnDeviceRecognition = false
    }

    fputs("Transcribing: \(audioPath)\n", stderr)
    fputs("Language: \(localeId)\n", stderr)

    recognizer.recognitionTask(with: request) { result, error in
        DispatchQueue.main.async {
            if let error = error {
                fputs("Error during recognition: \(error.localizedDescription)\n", stderr)
                exit(1)
            }

            guard let result = result else { return }

            if result.isFinal {
                var allSegments: [Segment] = []
                let fullTranscript = result.bestTranscription.formattedString

                for segment in result.bestTranscription.segments {
                    allSegments.append(Segment(
                        text: segment.substring,
                        start: segment.timestamp,
                        duration: segment.duration,
                        confidence: segment.confidence
                    ))
                }

                outputResult(fullTranscript: fullTranscript, segments: allSegments)
                exit(0)
            }
        }
    }
}

func outputResult(fullTranscript: String, segments: [Segment]) {
    if jsonOutput {
        var jsonSegments: [[String: Any]] = []
        for seg in segments {
            jsonSegments.append([
                "text": seg.text,
                "start": round(seg.start * 100) / 100,
                "duration": round(seg.duration * 100) / 100,
                "confidence": round(Double(seg.confidence) * 1000) / 1000
            ])
        }

        var lines: [[String: Any]] = []
        var currentText = ""
        var lineStart: Double = 0
        var lineEnd: Double = 0

        for (i, seg) in segments.enumerated() {
            if currentText.isEmpty {
                lineStart = seg.start
            }
            currentText += seg.text
            lineEnd = seg.start + seg.duration

            let isEndOfSentence = seg.text.hasSuffix(".") || seg.text.hasSuffix("?") ||
                seg.text.hasSuffix("!") || seg.text.hasSuffix("。") ||
                i == segments.count - 1

            if isEndOfSentence {
                lines.append([
                    "text": currentText.trimmingCharacters(in: .whitespaces),
                    "start": round(lineStart * 100) / 100,
                    "end": round(lineEnd * 100) / 100
                ])
                currentText = ""
            }
        }

        let output: [String: Any] = [
            "file": audioPath,
            "locale": localeId,
            "transcript": fullTranscript,
            "lines": lines,
            "segments": jsonSegments
        ]

        if let data = try? JSONSerialization.data(withJSONObject: output, options: [.prettyPrinted, .sortedKeys]),
           let str = String(data: data, encoding: .utf8) {
            print(str)
        }
    } else {
        var currentLine = ""
        var lineStart: Double = 0

        for (i, seg) in segments.enumerated() {
            if currentLine.isEmpty {
                lineStart = seg.start
            }
            currentLine += seg.text

            let isEndOfSentence = seg.text.hasSuffix(".") || seg.text.hasSuffix("?") ||
                seg.text.hasSuffix("!") || seg.text.hasSuffix("。") ||
                i == segments.count - 1

            if isEndOfSentence {
                print("[\(formatTime(lineStart))] \(currentLine.trimmingCharacters(in: .whitespaces))")
                currentLine = ""
            }
        }
    }

    fputs("\nDone. Total segments: \(segments.count)\n", stderr)
}

// Kick off on main queue, then run the RunLoop
DispatchQueue.main.async {
    runRecognition()
}

RunLoop.main.run()
