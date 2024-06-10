//
//  Flip3D.swift
//  Swift3D
//
//  Created by 张训 on 2024/6/10.
//

import Foundation
import SwiftUI
import SceneKit

enum SceneOptions{
    case setCamera
}


struct Flip3D: UIViewRepresentable {
    var scene: SCNScene
    var options : [SceneOptions]?
    
    static var boxScene : SCNScene {
        // 颜色
        let frontMaterial = SCNMaterial()
        frontMaterial.diffuse.contents = UIColor.green
        let backMaterial = SCNMaterial()
        backMaterial.diffuse.contents = UIColor.red
        // 创建box
        let box = SCNBox(width: 1, height: 1, length: 0.1, chamferRadius: 0)
        box.materials = [frontMaterial, SCNMaterial(), backMaterial, SCNMaterial(), SCNMaterial(), SCNMaterial()]
        let node = SCNNode(geometry: box)
        node.name = "node"
        let scene = SCNScene()
        scene.rootNode.addChildNode(node)
        return scene
    }
    
    init(scene: SCNScene , options: [SceneOptions]? = nil ) {
        self.scene = scene
        // 添加相机
        if let options{
            if options.contains(.setCamera){
                let camera = SCNCamera()
                let cameraNode = SCNNode()
                cameraNode.camera = camera
                cameraNode.position = SCNVector3(x:0, y: 0, z: 3)
                self.scene.rootNode.addChildNode(cameraNode)
            }
        }
    }
    
    
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.scene = self.scene
        sceneView.allowsCameraControl = false
        sceneView.autoenablesDefaultLighting = true
        // 设置颜色
        sceneView.backgroundColor = UIColor.clear
        
        // 添加自定义的手势识别器
        let panGestureRecognizer = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        sceneView.addGestureRecognizer(panGestureRecognizer)
        return sceneView
    }
    
    
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        
    }
    
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    

    func quickFlip(){
        let coordinator = makeCoordinator()
        coordinator.currentVelocity = 1000
        coordinator.applyInertia()
    }
    
    class Coordinator: NSObject {
        var parent: Flip3D
        var lastPanLocation: CGPoint = .zero
        var currentVelocity: CGFloat = 0.0
        var frontAngle: Float = 0
        var backAngle: Float = Float.pi
        var node : SCNNode
        
        init(_ parent: Flip3D) {
            self.parent = parent
            self.node = parent.scene.rootNode.childNode(withName: "node", recursively: true)!
        }
        
        @objc func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
            let translation = gestureRecognizer.translation(in: gestureRecognizer.view)
            let horizontalRotation = Float(translation.x) * (Float.pi / 180.0)
            print("horizontalRotation:\(horizontalRotation)")
            
            switch gestureRecognizer.state {
            case .began:
                node.removeAllActions()
            case .changed:
                node.eulerAngles.y += horizontalRotation
                gestureRecognizer.setTranslation(.zero, in: gestureRecognizer.view)
            case .ended:
                let velocity = gestureRecognizer.velocity(in: gestureRecognizer.view)
                currentVelocity = velocity.x
                applyInertia()
            default:
                break
            }
        }
        
        func applyInertia() {
            guard currentVelocity !=  0 else {
                snapToClosestFace()
                return
            }
            let decelerationRate: CGFloat = 0.95
            currentVelocity *= decelerationRate
            
            
            let horizontalRotation = Float(currentVelocity / 1000.0)
            node.eulerAngles.y += horizontalRotation
            
            if abs(currentVelocity) > 2 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.016) {
                    self.applyInertia()
                }
            } else {
                currentVelocity = 0.0
                snapToClosestFace()
            }
        }
        
        func snapToClosestFace() {
            let currentAngle = node.eulerAngles.y
            print("currentAngle:\(currentAngle)")
            let normalizedAngle = currentAngle.truncatingRemainder(dividingBy: Float.pi*2)
            print("normalizedAngle:\(normalizedAngle)")
            
            
            
            var targetAngle = Float(0)
            if -Float.pi / 2 < normalizedAngle && normalizedAngle < Float.pi / 2  {
                targetAngle = currentAngle - normalizedAngle
                
            } else if Float.pi / 2  <  normalizedAngle && normalizedAngle < Float.pi {
                targetAngle = currentAngle + (Float.pi - normalizedAngle)
            } else if Float.pi   < normalizedAngle && normalizedAngle < (Float.pi/2) * 3{
                targetAngle = currentAngle - (normalizedAngle - Float.pi)
            } else if (Float.pi/2) * 3   < normalizedAngle && normalizedAngle < Float.pi * 2{
                targetAngle = currentAngle + (Float.pi*2 - normalizedAngle)
            } else if -Float.pi   < normalizedAngle && normalizedAngle < -Float.pi / 2 {
                targetAngle = currentAngle - (Float.pi + normalizedAngle)
            } else if -Float.pi*3/2   < normalizedAngle && normalizedAngle < -Float.pi {
                targetAngle = currentAngle - (Float.pi + normalizedAngle)
            } else if -Float.pi*2   < normalizedAngle && normalizedAngle < -Float.pi*3/2 {
                targetAngle = currentAngle - (Float.pi*2 + normalizedAngle)
            }
            performOscillation(to: targetAngle)
            
        }
        
        func performOscillation(to targetAngle: Float) {
            print("targetAngle:\(targetAngle)")
            let currentAngle = node.eulerAngles.y
            let difference = targetAngle - currentAngle
            let duration = 2.0
            let oscillationAction = SCNAction.customAction(duration: duration) { node, elapsedTime in
                let t = Float(elapsedTime / duration)
                // 阻尼 数字越小 阻尼越小
                let damping = exp(-6 * t)
                // 增加频率因子以增加摆动频率
                let frequency: Float = 6
                let angle = targetAngle - difference * cos(frequency * .pi * t) * damping
                node.eulerAngles.y = angle
            }
            node.runAction(oscillationAction)
        }
        
        
        
        
    }
    
    
}




