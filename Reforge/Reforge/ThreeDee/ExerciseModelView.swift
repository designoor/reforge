import SwiftUI
import SceneKit

struct ExerciseModelView: UIViewRepresentable {
    let modelId: String
    let isPlaying: Bool
    var allowsRotation: Bool = true

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = UIColor(white: 0.08, alpha: 1.0)
        scnView.allowsCameraControl = allowsRotation
        scnView.autoenablesDefaultLighting = true
        scnView.antialiasingMode = .multisampling4X

        let scene = buildScene(for: modelId)
        scnView.scene = scene

        if isPlaying {
            scnView.isPlaying = true
        }

        context.coordinator.currentModelId = modelId
        return scnView
    }

    func updateUIView(_ scnView: SCNView, context: Context) {
        // Swap scene if exercise changed
        if context.coordinator.currentModelId != modelId {
            let scene = buildScene(for: modelId)
            scnView.scene = scene
            context.coordinator.currentModelId = modelId
        }

        scnView.isPlaying = isPlaying

        // Pause or resume all animations
        scnView.scene?.rootNode.isPaused = !isPlaying
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var currentModelId: String = ""
    }

    // MARK: - Scene Building

    private func buildScene(for modelId: String) -> SCNScene {
        // Try loading a USDZ file first
        if let url = ModelCatalog.url(for: modelId) {
            if let scene = try? SCNScene(url: url, options: nil) {
                return scene
            }
        }

        // Fallback: programmatic placeholder
        return buildPlaceholderScene(for: modelId)
    }

    private func buildPlaceholderScene(for modelId: String) -> SCNScene {
        let scene = SCNScene()

        let color = exerciseColor(for: modelId)
        let info = ModelCatalog.models[modelId]
        let duration = info?.animationDuration ?? 2.0

        // Body node — a capsule representing a person
        let bodyGeometry = SCNCapsule(capRadius: 0.15, height: 0.8)
        bodyGeometry.firstMaterial?.diffuse.contents = color
        bodyGeometry.firstMaterial?.specular.contents = UIColor.white
        let bodyNode = SCNNode(geometry: bodyGeometry)
        bodyNode.name = "body"

        // Accent node — a sphere or box representing movement focus
        let accentNode = buildAccentNode(for: modelId, color: color)
        accentNode.position = SCNVector3(0, -0.5, 0)
        accentNode.name = "accent"

        // Group
        let groupNode = SCNNode()
        groupNode.addChildNode(bodyNode)
        groupNode.addChildNode(accentNode)
        scene.rootNode.addChildNode(groupNode)

        // Looping up-down animation on the body
        let moveUp = SCNAction.moveBy(x: 0, y: 0.15, z: 0, duration: duration / 2)
        moveUp.timingMode = .easeInEaseOut
        let moveDown = moveUp.reversed()
        let bounce = SCNAction.sequence([moveUp, moveDown])
        bodyNode.runAction(.repeatForever(bounce))

        // Accent pulse animation
        let scaleUp = SCNAction.scale(to: 1.15, duration: duration / 2)
        scaleUp.timingMode = .easeInEaseOut
        let scaleDown = SCNAction.scale(to: 1.0, duration: duration / 2)
        scaleDown.timingMode = .easeInEaseOut
        let pulse = SCNAction.sequence([scaleUp, scaleDown])
        accentNode.runAction(.repeatForever(pulse))

        // Floor reference
        let floorGeometry = SCNFloor()
        floorGeometry.reflectivity = 0.1
        floorGeometry.firstMaterial?.diffuse.contents = UIColor(white: 0.12, alpha: 1.0)
        let floorNode = SCNNode(geometry: floorGeometry)
        floorNode.position = SCNVector3(0, -1.0, 0)
        scene.rootNode.addChildNode(floorNode)

        // Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0.3, 2.5)
        cameraNode.look(at: SCNVector3(0, -0.1, 0))
        scene.rootNode.addChildNode(cameraNode)

        // Ambient light
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 400
        ambientLight.light?.color = UIColor(white: 0.6, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLight)

        return scene
    }

    private func buildAccentNode(for modelId: String, color: UIColor) -> SCNNode {
        let geometry: SCNGeometry

        switch modelId {
        case "pushup", "diamond_pushup", "pike_pushup", "tricep_dip", "inverted_row":
            // Upper body — flat box representing ground contact
            geometry = SCNBox(width: 0.6, height: 0.05, length: 0.4, chamferRadius: 0.02)
        case "squat", "split_squat", "jump_squat", "calf_raise":
            // Lower body — sphere representing force through feet
            geometry = SCNSphere(radius: 0.12)
        case "plank", "dead_bug", "superman":
            // Core — torus representing midsection engagement
            geometry = SCNTorus(ringRadius: 0.25, pipeRadius: 0.06)
        case "burpee", "mountain_climber", "high_knees":
            // HIIT — pyramid for explosive energy
            geometry = SCNPyramid(width: 0.3, height: 0.25, length: 0.3)
        default:
            geometry = SCNSphere(radius: 0.1)
        }

        geometry.firstMaterial?.diffuse.contents = color.withAlphaComponent(0.6)
        geometry.firstMaterial?.specular.contents = UIColor.white
        return SCNNode(geometry: geometry)
    }

    private func exerciseColor(for modelId: String) -> UIColor {
        switch modelId {
        case "pushup", "diamond_pushup", "pike_pushup", "tricep_dip", "inverted_row":
            return UIColor.systemBlue
        case "squat", "split_squat", "glute_bridge", "calf_raise":
            return UIColor.systemGreen
        case "plank", "dead_bug", "superman":
            return UIColor.systemOrange
        case "burpee", "mountain_climber", "jump_squat", "high_knees":
            return UIColor.systemRed
        default:
            return UIColor.systemPurple
        }
    }
}
