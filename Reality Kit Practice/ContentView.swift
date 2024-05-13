//
//  ContentView.swift
//  Reality Kit Practice
//
//  Created by Ayush Singhal on 13/05/24.
//

import Combine
import RealityKit
import SwiftUI

struct ContentView: View {
    var body: some View {
        MyUIView()
            .ignoresSafeArea()
    }
}

struct MyUIView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        return GameViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}

class GameViewController: UIViewController {
    var sceneEventsUpdateSubscription: Cancellable!

    override func viewDidLoad() {
        super.viewDidLoad()

        let arView = ARView(frame: view.frame,
                            cameraMode: .nonAR,
                            automaticallyConfigureSession: false)
        view.addSubview(arView)

        let skyboxName = "aerodynamics_workshop_4k"
        let skyboxResource = try! EnvironmentResource.load(named: skyboxName)
        arView.environment.lighting.resource = skyboxResource
        arView.environment.background = .skybox(skyboxResource)

        var sphereMaterial = SimpleMaterial()
        sphereMaterial.metallic = MaterialScalarParameter(floatLiteral: 1)
        sphereMaterial.roughness = MaterialScalarParameter(floatLiteral: 0)

        let sphereEntity = ModelEntity(mesh: .generateSphere(radius: 1), materials: [sphereMaterial])
        let sphereAnchor = AnchorEntity(world: .zero)
        sphereAnchor.addChild(sphereEntity)
        arView.scene.anchors.append(sphereAnchor)

        let camera = PerspectiveCamera()
        camera.camera.fieldOfViewInDegrees = 60

        let cameraAnchor = AnchorEntity(world: .zero)
        cameraAnchor.addChild(camera)

        arView.scene.addAnchor(cameraAnchor)

        let cameraDistance: Float = 5
        var currentCameraRotation: Float = 0
        let cameraRotationSpeed: Float = 0.01

        sceneEventsUpdateSubscription = arView.scene.subscribe(to: SceneEvents.Update.self) { _ in
            let x = sin(currentCameraRotation) * cameraDistance
            let z = cos(currentCameraRotation) * cameraDistance

            let cameraTranslation = SIMD3<Float>(x, 0, z)
            let cameraTransform = Transform(scale: .one,
                                            rotation: simd_quatf(),
                                            translation: cameraTranslation)

            camera.transform = cameraTransform
            camera.look(at: .zero, from: cameraTranslation, relativeTo: nil)

            currentCameraRotation += cameraRotationSpeed
        }
    }
}

#Preview {
    ContentView()
//    GameViewController()
}
