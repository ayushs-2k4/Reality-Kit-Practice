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
        VStack {
            MyNSView()
        }
        .ignoresSafeArea()
    }
}

struct MyNSView: NSViewControllerRepresentable {
    func makeNSViewController(context: Context) -> some NSViewController {
        return GameViewController()
    }

    func updateNSViewController(_ uiViewController: NSViewControllerType, context: Context) {}
}

class GameViewController: NSViewController {
    var sceneEventsUpdateSubscription: Cancellable!
    var cameraDistanceSlider: NSSlider!
    var cameraDistanceSliderLabel: NSTextField!
    var cameraRotationSpeedSlider: NSSlider!
    var cameraRotationSpeedSliderLabel: NSTextField!

    var cameraDistance: Float = 40
//    var cameraRotationSpeed: Float = 0.001
    var cameraRotationSpeed: Float = 0
    var degreesToRotate: (Float, Float) = (0, 0)

    let sphereAnchor = AnchorEntity(world: .zero)

    override func viewDidLoad() {
        super.viewDidLoad()

        let arView = ARView(frame: view.frame)
        view.addSubview(arView)
        arView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            arView.topAnchor.constraint(equalTo: view.topAnchor),
            arView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            arView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            arView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let tapGestureRecognizer = NSClickGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tapGestureRecognizer)

        let panGestureRecognizer = NSPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        arView.addGestureRecognizer(panGestureRecognizer)

        // Add Camera Distance Slider
        cameraDistanceSlider = NSSlider(value: Double(self.cameraDistance), minValue: 1, maxValue: 100, target: self, action: #selector(cameraDistanceChanged(_:)))
        cameraDistanceSlider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cameraDistanceSlider)
        NSLayoutConstraint.activate([
            cameraDistanceSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cameraDistanceSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cameraDistanceSlider.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50)
        ])

        // Add Camera Distance Label
        cameraDistanceSliderLabel = NSTextField(labelWithString: "Camera Distance: \(10)")
        cameraDistanceSliderLabel.translatesAutoresizingMaskIntoConstraints = false
        cameraDistanceSliderLabel.textColor = .white
        view.addSubview(cameraDistanceSliderLabel)
        NSLayoutConstraint.activate([
            cameraDistanceSliderLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cameraDistanceSliderLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cameraDistanceSliderLabel.bottomAnchor.constraint(equalTo: cameraDistanceSlider.topAnchor, constant: -10)
        ])

        // Add Camera Rotation Speed Slider
        cameraRotationSpeedSlider = NSSlider(value: 0.01, minValue: -1, maxValue: 1, target: self, action: #selector(cameraRotationSpeedChanged(_:)))
        cameraRotationSpeedSlider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cameraRotationSpeedSlider)
        NSLayoutConstraint.activate([
            cameraRotationSpeedSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cameraRotationSpeedSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cameraRotationSpeedSlider.bottomAnchor.constraint(equalTo: cameraDistanceSlider.bottomAnchor, constant: -50)
        ])

        // Add Camera Rotation Speed Label
        cameraRotationSpeedSliderLabel = NSTextField(labelWithString: "Camera Rot. Speed: \(cameraRotationSpeedSlider.floatValue)")
        cameraRotationSpeedSliderLabel.textColor = .white
        cameraRotationSpeedSliderLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cameraRotationSpeedSliderLabel)
        NSLayoutConstraint.activate([
            cameraRotationSpeedSliderLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cameraRotationSpeedSliderLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cameraRotationSpeedSliderLabel.bottomAnchor.constraint(equalTo: cameraRotationSpeedSlider.topAnchor, constant: -10)
        ])

        let skyboxName = "aerodynamics_workshop_4k"
        let skyboxResource = try! EnvironmentResource.load(named: skyboxName)
        arView.environment.lighting.resource = skyboxResource
        arView.environment.background = .skybox(skyboxResource)

        do {
            let cgImage = NSImage(resource: ._8KMoon).cgImage(forProposedRect: nil, context: nil, hints: nil)!
            
            let texture = try TextureResource.generate(from: cgImage, options: .init(semantic: .normal))
            print("texture: \(texture)")

            var sphereMaterial = SimpleMaterial()
            sphereMaterial.color = .init(texture: .init(texture))
            sphereMaterial.metallic = MaterialScalarParameter(floatLiteral: 0.2)
            sphereMaterial.roughness = MaterialScalarParameter(floatLiteral: 0.5)

            let mesh = MeshResource.generateSphere(radius: 10)

            let sphereEntity = ModelEntity(mesh: mesh, materials: [sphereMaterial])

            sphereAnchor.addChild(sphereEntity)
            arView.scene.anchors.append(sphereAnchor)
//        // Convert degrees to radians
//        let radiansToRotate = degreesToRotate * .pi / 180
//
//        // Create rotation transform
//        let rotation = simd_quatf(angle: radiansToRotate, axis: SIMD3<Float>(0, 1, 0))
//
//        // Apply rotation transform to the anchor entity
//        sphereAnchor.transform.rotation = rotation

            let camera = PerspectiveCamera()
            camera.camera.fieldOfViewInDegrees = 60

            let cameraAnchor = AnchorEntity(world: .zero)
            cameraAnchor.addChild(camera)

            arView.scene.addAnchor(cameraAnchor)

            var currentCameraRotation: Float = 0

            sceneEventsUpdateSubscription = arView.scene.subscribe(to: SceneEvents.Update.self) { _ in
                let x = sin(currentCameraRotation) * self.cameraDistance
                let z = cos(currentCameraRotation) * self.cameraDistance

                let cameraTranslation = SIMD3<Float>(x, 0, z)
                let cameraTransform = Transform(scale: .one,
                                                rotation: simd_quatf(),
                                                translation: cameraTranslation)

                camera.transform = cameraTransform
                camera.look(at: .zero, from: cameraTranslation, relativeTo: nil)

                currentCameraRotation += self.cameraRotationSpeed
            }
        } catch {
            print("Error: \(error)")
        }
    }

    @objc func cameraDistanceChanged(_ sender: NSSlider) {
        // Implement camera distance change handling here
        self.cameraDistance = sender.floatValue
        self.cameraDistanceSliderLabel.stringValue = "Camera Distance: \(sender.floatValue)"
    }

    @objc func cameraRotationSpeedChanged(_ sender: NSSlider) {
        self.cameraRotationSpeed = sender.floatValue
        self.cameraRotationSpeedSliderLabel.stringValue = "Camera Rot. Speed: \(sender.floatValue)"
    }

    @objc func handleTap(_ sender: NSClickGestureRecognizer) {
        print("Clciked")
    }

    @objc func handlePan(_ sender: NSPanGestureRecognizer) {
        print("Panned")
        print("velocity: \(sender.velocity(in: nil))")
        print("translation: \(sender.translation(in: nil))")
        print()

        self.degreesToRotate.0 += Float(sender.translation(in: nil).x)
        self.degreesToRotate.1 += Float(sender.translation(in: nil).y)

        // Convert degrees to radians
        let radiansToRotateX = self.degreesToRotate.0 * .pi / 180 * 0.01
        let radiansToRotateY = self.degreesToRotate.1 * .pi / 180 * 0.01

        // Create rotation transforms for X and Y axes
        let rotationX = simd_quatf(angle: radiansToRotateX, axis: SIMD3<Float>(0, 1, 0)) // Rotate around X-axis
        let rotationY = simd_quatf(angle: radiansToRotateY, axis: SIMD3<Float>(1, 0, 0)) // Rotate around Y-axis

        // Combine the rotations
        let combinedRotation = rotationX * rotationY

        // Apply combined rotation transform to the sphere anchor entity
        sphereAnchor.transform.rotation = combinedRotation
    }
}

// struct MyUIView: UIViewControllerRepresentable {
//    func makeUIViewController(context: Context) -> some UIViewController {
//        return GameViewController()
//    }
//
//    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
//
//    }
// }
//
// class GameViewController: UIViewController {
//    var sceneEventsUpdateSubscription: Cancellable!
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        let arView = ARView(frame: view.frame,
//                            cameraMode: .nonAR,
//                            automaticallyConfigureSession: false)
//        view.addSubview(arView)
//
//        let skyboxName = "aerodynamics_workshop_4k"
//        let skyboxResource = try! EnvironmentResource.load(named: skyboxName)
//        arView.environment.lighting.resource = skyboxResource
//        arView.environment.background = .skybox(skyboxResource)
//
//        var sphereMaterial = SimpleMaterial()
//        sphereMaterial.metallic = MaterialScalarParameter(floatLiteral: 1)
//        sphereMaterial.roughness = MaterialScalarParameter(floatLiteral: 0)
//
//        let sphereEntity = ModelEntity(mesh: .generateSphere(radius: 1), materials: [sphereMaterial])
//        let sphereAnchor = AnchorEntity(world: .zero)
//        sphereAnchor.addChild(sphereEntity)
//        arView.scene.anchors.append(sphereAnchor)
//
//        let camera = PerspectiveCamera()
//        camera.camera.fieldOfViewInDegrees = 60
//
//        let cameraAnchor = AnchorEntity(world: .zero)
//        cameraAnchor.addChild(camera)
//
//        arView.scene.addAnchor(cameraAnchor)
//
//        let cameraDistance: Float = 5
//        var currentCameraRotation: Float = 0
//        let cameraRotationSpeed: Float = 0.01
//
//        sceneEventsUpdateSubscription = arView.scene.subscribe(to: SceneEvents.Update.self) { _ in
//            let x = sin(currentCameraRotation) * cameraDistance
//            let z = cos(currentCameraRotation) * cameraDistance
//
//            let cameraTranslation = SIMD3<Float>(x, 0, z)
//            let cameraTransform = Transform(scale: .one,
//                                            rotation: simd_quatf(),
//                                            translation: cameraTranslation)
//
//            camera.transform = cameraTransform
//            camera.look(at: .zero, from: cameraTranslation, relativeTo: nil)
//
//            currentCameraRotation += cameraRotationSpeed
//        }
//    }
// }

#Preview {
    ContentView()
//    GameViewController()
}
