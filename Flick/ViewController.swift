//
//  ViewController.swift
//  SwipeKit
//
//  Created by Cem Olcay on 14/08/2017.
//  Copyright © 2017 cemolcay. All rights reserved.
//

import UIKit
import SceneKit

class ViewController: UIViewController {
  @IBOutlet weak var sceneView: SCNView?
  let scene = SCNScene(named: "scene.scn")
  let coinScene = SCNScene(named: "coin.scn")
  var coin: SCNNode?
  var coinPosition: SCNNode?

  override func viewDidLoad() {
    super.viewDidLoad()

    // Setup scene
    sceneView?.scene = scene
    coin = coinScene?.rootNode.childNode(withName: "coin", recursively: true)
    coinPosition = scene?.rootNode.childNode(withName: "coinPosition", recursively: true)
    scene?.rootNode.addChildNode(coin!)
    coin?.physicsBody?.addObserver(self, forKeyPath: "isResting", options: .new, context: nil)

    // Flick gesture
    let flick = FlickGestureRecognizer(target: self, action: #selector(didFlick(flick:)))
    view.addGestureRecognizer(flick)
  }

  @objc func didFlick(flick: FlickGestureRecognizer) {
    print(flick)
    switch flick.state {
    case .ended, .cancelled:
      guard let coin = self.coin, let coinPosition = self.coinPosition else { return }
      coin.position = coinPosition.position
      coin.physicsBody?.applyForce(SCNVector3(flick.direction.dx, flick.direction.dy, 0), asImpulse: true)
      coin.physicsBody?.applyTorque(SCNVector4(1, 0, 0, flick.velocity), asImpulse: true)
    default:
      return
    }
  }

  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    if let physicsBody = object as? SCNPhysicsBody, physicsBody == coin?.physicsBody, keyPath == "isResting" {
      if physicsBody.isResting {
        print(coin?.eulerAngles)
      }
    }
  }
}

