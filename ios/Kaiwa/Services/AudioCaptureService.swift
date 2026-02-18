import AVFoundation

protocol AudioCaptureDelegate: AnyObject, Sendable {
    func audioCaptureDidReceive(buffer: Data)
}

class AudioCaptureService {
    private let engine = AVAudioEngine()
    private var isCapturing = false
    weak var delegate: AudioCaptureDelegate?

    func start() throws {
        guard !isCapturing else { return }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)

        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

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

        try engine.start()
        isCapturing = true
    }

    func stop() {
        guard isCapturing else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isCapturing = false

        try? AVAudioSession.sharedInstance().setActive(false)
    }
}

enum AudioError: Error, LocalizedError {
    case formatError
    case converterError

    var errorDescription: String? {
        switch self {
        case .formatError: return "Failed to create audio format"
        case .converterError: return "Failed to create audio converter"
        }
    }
}
