import SwiftUI
import RealityKit

typealias Scene = SwiftUI.Scene

@main
struct MultiWindowTestApp: App {
    var body: some Scene {
        MainScene()
        VolumetricScene()
        ImmersiveScene()
    }
}

struct MainScene: Scene {

    @Environment(\.scenePhase)
    var scenePhase

    @Environment(\.dismissWindow)
    var dismissWindow

    @Environment(\.dismissImmersiveSpace)
    var dismissImmersiveSpace


    var body: some Scene {
        WindowGroup(id: "id-main") {
            GroupBox("MainScene") {
                SceneToggle(title: "Toggle Volumetric Window", id: "id.volumetric", value: VolumetricScene.value)
                SceneToggle(title: "Toggle Immersive Space", id: "id.immersive", value: ImmersiveScene.value, isImmersive: true)
                Button("Close") {
                    dismissWindow(id: "id-main")
                }
            }
            .fixedSize()
            .padding()

        }
        .defaultSize(CGSize(width: 240, height: 160))
        .onChange(of: scenePhase, initial: true) { oldValue, newValue in
            switch newValue {
            case .background:
                guard oldValue != newValue else {
                    return
                }
                dismissWindow(id: "id.volumetric")
                Task {
                    await dismissImmersiveSpace()
                }
            default:
                break
            }
        }
    }
}


struct VolumetricScene: Scene {
    @Environment(\.scenePhase)
    var scenePhase

    struct Value: Codable, Hashable {
    }

    static let value = Value()

    var body: some Scene {
        WindowGroup(id: "id.volumetric", for: VolumetricScene.Value.self) { _ in
            GroupBox("VolumetricScene") {
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .glassBackgroundEffect()
        }
        .defaultSize(width: 0.5, height: 0.5, depth: 0.5)
        .windowStyle(.volumetric)
        .onChange(of: scenePhase, initial: true) { oldValue, newValue in
//            print("# VOLUMETRIC SCENE: \(oldValue), \(newValue)")
        }
    }
}

struct ImmersiveScene: Scene {
    struct Value: Codable, Hashable {
    }

    static let value = Value()

    var body: some Scene {
        ImmersiveSpace(id: "id.immersive") {
            RealityView { content in
                let panorama = ModelEntity(mesh: .generateSphere(radius: 1000))
                panorama.scale.x *= -1
                print("#", panorama.scale)
                content.add(panorama)

                let bubble = ModelEntity(mesh: .generateSphere(radius: 0.25))
                bubble.position = [0, 1, -5]
                content.add(bubble)
            }
        }
        .immersionStyle(selection: .constant(.mixed))
    }
}

// MARK: -

struct SceneToggle <Value>: View where Value: Hashable & Codable {

    let title: String
    let id: String
    let value: Value
    let isImmersive: Bool

    init(title: String, id: String, value: Value, isImmersive: Bool = false) {
        self.title = title
        self.id = id
        self.value = value
        self.isImmersive = isImmersive
    }

    @State
    var isWindowOpen = false

    @Environment(\.openWindow)
    var openWindow
    @Environment(\.dismissWindow)
    var dismissWindow
    @Environment(\.openImmersiveSpace)
    var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace)
    var dismissImmersiveSpace

    var body: some View {
        Toggle(title, isOn: $isWindowOpen)
            .onChange(of: isWindowOpen) { oldValue, newValue in
                guard oldValue != newValue else {
                    return
                }
                if newValue {
                    if !isImmersive {
                        openWindow(id: id, value: value)
                    }
                    else {
                        Task {
                            await openImmersiveSpace(id: id)
                        }
                    }
                }
                else {
                    if !isImmersive {
                        dismissWindow(id: id, value: value)
                    }
                    else {
                        Task {
                            await dismissImmersiveSpace()
                        }
                    }
                }
            }
    }
}
