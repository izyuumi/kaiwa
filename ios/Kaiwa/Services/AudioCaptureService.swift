import AVFoundation

protocol AudioCaptureDelegate: AnyObject, Sendable {
    func audioCaptureDidReceive(buffer: Data)
}

class AudioCaptureService {
    private let engine = AVAudioEngine()
    private var isCapturing = false
    private var hasInstalledTap = false
    weak var delegate: AudioCaptureDelegate?

    func start() throws {
        guard !isCapturing else { return }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setPreferredSampleRate(16000)
        try? session.setPreferredInputNumberOfChannels(1)
        try session.setActive(true)

        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        guard Self.isValid(format: inputFormat) else {
            throw AudioError.invalidInputFormat(
                sampleRate: inputFormat.sampleRate,
                channels: inputFormat.channelCount
            )
        }

        // Target: 16kHz mono PCM s16le
        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 16000,
            channels: 1,
            interleaved: true
        ) else {
            throw AudioError.formatError
        }

        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            throw AudioError.converterError
        }

        if hasInstalledTap {
            inputNode.removeTap(onBus: 0)
            hasInstalledTap = false
        }

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            guard let self = self else { return }

            let frameCount = AVAudioFrameCount(
                Double(buffer.frameLength) * 16000.0 / inputFormat.sampleRate
            )
            guard frameCount > 0 else { return }

            guard let convertedBuffer = AVAudioPCMBuffer(
                pcmFormat: targetFormat,
                frameCapacity: frameCount
            ) else { return }

            var error: NSError?
            let status = converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }

            guard status != .error, error == nil else { return }

            if let channelData = convertedBuffer.int16ChannelData {
                let data = Data(
                    bytes: channelData[0],
                    count: Int(convertedBuffer.frameLength) * MemoryLayout<Int16>.size
                )
                self.delegate?.audioCaptureDidReceive(buffer: data)
            }
        }
        hasInstalledTap = true

        try engine.start()
        isCapturing = true
    }

    func stop() {
        if hasInstalledTap {
            engine.inputNode.removeTap(onBus: 0)
            hasInstalledTap = false
        }
        if isCapturing {
            engine.stop()
            isCapturing = false
        }

        try? AVAudioSession.sharedInstance().setActive(false)
    }
}

enum AudioError: Error, LocalizedError {
    case formatError
    case converterError
    case invalidInputFormat(sampleRate: Double, channels: AVAudioChannelCount)

    var errorDescription: String? {
        switch self {
        case .formatError: return "Failed to create audio format"
        case .converterError: return "Failed to create audio converter"
        case .invalidInputFormat(let sampleRate, let channels):
            return "Invalid input audio format (sampleRate: \(sampleRate), channels: \(channels))"
        }
    }
}

private extension AudioCaptureService {
    static func isValid(format: AVAudioFormat) -> Bool {
        format.sampleRate > 0 && format.channelCount > 0
    }
}
