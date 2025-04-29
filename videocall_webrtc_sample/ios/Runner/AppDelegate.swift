import UIKit
import CallKit
import AVFAudio
import PushKit
import Flutter
import flutter_callkit_incoming
import quickblox_sdk

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate, CallkitIncomingAppDelegate {
    private var hasVideo: Bool = false
    private let qbAudioSession = QBRTCAudioSession.instance()

    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        let mainQueue = DispatchQueue.main
        let voipRegistry: PKPushRegistry = PKPushRegistry(queue: mainQueue)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [PKPushType.voIP]

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func application(_ application: UIApplication, continue userActivity: NSUserActivity,restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {

        guard let handleObj = userActivity.handle else {
            return false
        }

        guard let isVideo = userActivity.isVideo else {
            return false
        }
        let objData = handleObj.getDecryptHandle()
        let nameCaller = objData["nameCaller"] as? String ?? ""
        let handle = objData["handle"] as? String ?? ""
        let data = flutter_callkit_incoming.Data(id: UUID().uuidString, nameCaller: nameCaller, handle: handle, type: isVideo ? 1 : 0)
        
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.startCall(data, fromPushKit: true)

        return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
    }
    
    private func updateAudioSessionConfiguration(_ hasVideo: Bool) {
        let configuration = QBRTCAudioSessionConfiguration()
        configuration.categoryOptions.insert(.duckOthers)
        configuration.categoryOptions.insert(.allowBluetooth)
        configuration.categoryOptions.insert(.allowBluetoothA2DP)
        configuration.categoryOptions.insert(.allowAirPlay)
        
        if hasVideo == true {
          configuration.mode = AVAudioSession.Mode.videoChat.rawValue
        }
        qbAudioSession.setConfiguration(configuration)
      }

    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        print(credentials.token)
        let deviceToken = credentials.token.map { String(format: "%02x", $0) }.joined()
        print(deviceToken)
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(deviceToken)
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        print("didInvalidatePushTokenFor")
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        print("didReceiveIncomingPushWith")
        guard type == .voIP else { return }
 
        let payloadData = payload.dictionaryPayload

        let body = payloadData["body"] as? String ?? ""
        let conferenceType = payloadData["conferenceType"] as? String ?? ""
        let iosVoip = payloadData["ios_voip"] as? String ?? ""
        let opponents = payloadData["opponents"] as? String ?? ""
        let sessionId = payloadData["sessionId"] as? String ?? ""
        let timestamp = payloadData["timestamp"] as? String ?? ""
        let senderId = payloadData["senderId"] as? Int ?? 0
        let senderName = payloadData["senderName"] as? String ?? ""
        let recipientIds = payloadData["recipientIds"] as? String ?? ""
    
        let jsonDictionary: [String: Any] = [
                "body": body,
                "conferenceType": conferenceType,
                "ios_voip": iosVoip,
                "opponents": opponents,
                "sessionId": sessionId,
                "timestamp": timestamp,
                "senderId": senderId,
                "senderName": senderName,
                "recipientIds": recipientIds
            ]
        
        hasVideo = conferenceType == "2"
        
        let data = flutter_callkit_incoming.Data(id: sessionId, nameCaller: body, handle: body, type: hasVideo ? 1 : 0)
        data.extra = ["message": jsonDictionary]
        data.configureAudioSession = false
        data.uuid = sessionId
      
        qbAudioSession.useManualAudio = true
        
        var bgTask: UIBackgroundTaskIdentifier = .invalid
            bgTask = UIApplication.shared.beginBackgroundTask {
                UIApplication.shared.endBackgroundTask(bgTask)
                bgTask = .invalid
            }
        
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(data, fromPushKit: true)
       }
    
    private func closeCall() {
        qbAudioSession.isAudioEnabled = false
        qbAudioSession.useManualAudio = false
        hasVideo = false
    }

    func onAccept(_ call: Call, _ action: CXAnswerCallAction) {
        updateAudioSessionConfiguration(hasVideo)
        
        action.fulfill()
    }

    func onDecline(_ call: Call, _ action: CXEndCallAction) {
        closeCall()
        action.fulfill()
    }

    func onEnd(_ call: Call, _ action: CXEndCallAction) {
        closeCall()
        action.fulfill()
    }

    func onTimeOut(_ call: Call) {
       closeCall()
    }

    func didActivateAudioSession(_ audioSession: AVAudioSession) {
        qbAudioSession.audioSessionDidActivate(audioSession)
        qbAudioSession.isAudioEnabled = true
    }

    func didDeactivateAudioSession(_ audioSession: AVAudioSession) {
        qbAudioSession.audioSessionDidDeactivate(audioSession)
    }
}
