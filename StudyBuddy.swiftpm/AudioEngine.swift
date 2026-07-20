import Foundation
import AVFoundation

enum FocusSoundType: String, CaseIterable, Identifiable {
    case brownNoise = "Deep Focus"
    case pinkNoise = "Memory Mode"
    case whiteNoise = "Noise Shield"
    case lofi = "Chill Study"
    case rain = "Calm Study"
    case cafe = "Coffee Shop"
    
    var id: String { rawValue }
    
    var isProcedural: Bool {
        return self == .brownNoise || self == .pinkNoise || self == .whiteNoise
    }
}

final class AudioEngine: ObservableObject, @unchecked Sendable {
    static let shared = AudioEngine()
    
    private let engine = AVAudioEngine()
    private var proceduralNode: AVAudioSourceNode?
    private var filePlayerNode = AVAudioPlayerNode()
    
    @Published var isPlaying = false
    @Published var volume: Float = 0.5 {
        didSet {
            engine.mainMixerNode.outputVolume = volume
        }
    }
    
    private var currentSound: FocusSoundType?
    
    // Noise state for procedural generation
    private var brownState: Float = 0.0
    private var pinkState: [Float] = [0, 0, 0, 0, 0, 0, 0]
    
    private init() {
        setupAudioSession()
        setupEngine()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func setupEngine() {
        engine.attach(filePlayerNode)
        engine.connect(filePlayerNode, to: engine.mainMixerNode, format: nil)
        engine.mainMixerNode.outputVolume = volume
    }
    
    func play(sound: FocusSoundType) {
        stop()
        currentSound = sound
        
        if sound.isProcedural {
            setupProceduralNode(for: sound)
        } else {
            setupFilePlayer(for: sound)
        }
        
        do {
            try engine.start()
            if !sound.isProcedural {
                filePlayerNode.play()
            }
            isPlaying = true
        } catch {
            print("Could not start engine: \(error)")
        }
    }
    
    func stop() {
        if let proceduralNode = proceduralNode {
            engine.detach(proceduralNode)
            self.proceduralNode = nil
        }
        
        filePlayerNode.stop()
        engine.stop()
        isPlaying = false
    }
    
    private func setupProceduralNode(for sound: FocusSoundType) {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        
        let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            
            for frame in 0..<Int(frameCount) {
                let sample = self.generateNoise(for: sound)
                for buffer in ablPointer {
                    let buf = UnsafeMutableBufferPointer<Float>(buffer)
                    buf[frame] = sample
                }
            }
            return noErr
        }
        
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        self.proceduralNode = node
    }
    
    private func generateNoise(for type: FocusSoundType) -> Float {
        let white = Float.random(in: -1...1)
        
        switch type {
        case .whiteNoise:
            return white * 0.1
            
        case .brownNoise:
            // Brownian noise algorithm
            var brown = brownState + (0.02 * white)
            if brown > 1.0 { brown = 1.0 }
            if brown < -1.0 { brown = -1.0 }
            brownState = brown
            // high pass filter to prevent DC offset
            brownState -= brownState * 0.001
            return brownState * 0.2
            
        case .pinkNoise:
            // Paul Kellet's refined method
            pinkState[0] = 0.99886 * pinkState[0] + white * 0.0555179
            pinkState[1] = 0.99332 * pinkState[1] + white * 0.0750759
            pinkState[2] = 0.96900 * pinkState[2] + white * 0.1538520
            pinkState[3] = 0.86650 * pinkState[3] + white * 0.3104856
            pinkState[4] = 0.55000 * pinkState[4] + white * 0.5329522
            pinkState[5] = -0.7616 * pinkState[5] - white * 0.0168980
            
            let pink = pinkState[0] + pinkState[1] + pinkState[2] + pinkState[3] + pinkState[4] + pinkState[5] + pinkState[6] + white * 0.5362
            pinkState[6] = white * 0.115926
            
            return pink * 0.05
            
        default:
            return 0
        }
    }
    
    private func setupFilePlayer(for sound: FocusSoundType) {
        let fileName: String
        switch sound {
        case .lofi: fileName = "lofi_study"
        case .rain: fileName = "rain_nature"
        case .cafe: fileName = "cafe_ambient"
        default: return
        }
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "wav") ??
                        Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
            print("Audio file not found: \(fileName)")
            return
        }
        
        do {
            let file = try AVAudioFile(forReading: url)
            
            // Connect the node to the mixer using the file's specific format
            engine.disconnectNodeOutput(filePlayerNode)
            engine.connect(filePlayerNode, to: engine.mainMixerNode, format: file.processingFormat)
            
            // Loop the audio
            let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))!
            try file.read(into: buffer)
            
            filePlayerNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        } catch {
            print("Failed to load audio file: \(error)")
        }
    }
}
