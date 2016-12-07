//
//  ViewController.swift
//  GravityBall
//
//  Created by Alexandre Malkov on 07/12/2016.
//  Copyright © 2016 Alexandre Malkov. All rights reserved.
//

import UIKit
import CoreMotion

class ViewController: UIViewController, UICollisionBehaviorDelegate {
    
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var leftView: UIView!
    @IBOutlet weak var rightView: UIView!
    
    var animator: UIDynamicAnimator!
    var motionManager: CMMotionManager!
    var gravity: UIGravityBehavior!
    var pushBehaviour: UIPushBehavior!
    var ball: UIView!
    var ballOldLocation: CGPoint = CGPoint.zero
    var ballDragPoint: CGPoint = CGPoint.zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        animator = UIDynamicAnimator(referenceView: self.view)
        setupBall()
        setupGravity()
        setupCollisions()
        setupAcceleromiter()
        setupBallPushBehaviour()
        
        
    }
    
    func setupBall() {
        // Create ball object
        ball = UIView(frame: CGRect(x: 100, y: 100, width: 50, height: 50))
        ball.layer.cornerRadius = 25
        ball.backgroundColor = UIColor.gray
        self.view.addSubview(ball)
        
        // And add ball behavior
        let ballBehavior = UIDynamicItemBehavior(items: [ball])
        ballBehavior.elasticity = 0.90
        animator.addBehavior(ballBehavior)
    }
    
    func setupGravity() {
        gravity = UIGravityBehavior(items: [ball])
        gravity.angle = 1.2
        gravity.magnitude = 0.1
        animator.addBehavior(gravity)
    }
    
    func setupCollisions() {
        let collTop = topView.frame.origin.y + topView.frame.size.height
        let collBottom = bottomView.frame.origin.y
        let collLeft = leftView.frame.origin.x + leftView.frame.size.width
        let collRight = rightView.frame.origin.x
        
        let collLeftTop = CGPoint(x: collLeft, y: collTop)
        let collLeftBottom = CGPoint(x: collLeft, y: collBottom)
        let collRightTop = CGPoint(x: collRight, y: collTop)
        let collRightBottom = CGPoint(x: collRight, y: collBottom)
        
        let collision = UICollisionBehavior(items: [ball])
        collision.collisionDelegate = self
        collision.addBoundary(withIdentifier: "top" as NSCopying, from: collLeftTop, to: collRightTop)
        collision.addBoundary(withIdentifier: "bottom" as NSCopying, from: collLeftBottom, to: collRightBottom)
        collision.addBoundary(withIdentifier: "left" as NSCopying, from: collLeftTop, to: collLeftBottom)
        collision.addBoundary(withIdentifier: "right" as NSCopying, from: collRightTop, to: collRightBottom)
        animator.addBehavior(collision)
    }
    
    func setupAcceleromiter() {
        motionManager = CMMotionManager()
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates()
            Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(accelerometerAndDragActions), userInfo: nil, repeats: true)
        }
    }
    
    func setupBallPushBehaviour() {
        let dragBallRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleDragBallGesture(recognizer:)))
        self.view.addGestureRecognizer(dragBallRecognizer)
        
        pushBehaviour = UIPushBehavior(items: [ball], mode: .continuous)
        pushBehaviour.setTargetOffsetFromCenter(UIOffset(), for: ball)
        pushBehaviour.active = false
        animator.addBehavior(pushBehaviour)
    }
    
    func handleDragBallGesture(recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .began {
            pushBehaviour.active = true
        }
        
        ballDragPoint = recognizer.location(in: self.view)
        
        if recognizer.state == .ended {
            pushBehaviour.active = false
        }
    }
    
    func collisionBehavior(_ behavior: UICollisionBehavior, beganContactFor item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying?, at p: CGPoint) {
        if let title = identifier {
            switch title as! String {
            case "top" :
                ball.backgroundColor = topView.backgroundColor
                shakeView(topView)
            case "bottom" :
                ball.backgroundColor = bottomView.backgroundColor
                shakeView(bottomView)
            case "left" :
                ball.backgroundColor = leftView.backgroundColor
                shakeView(leftView)
            case "right" :
                ball.backgroundColor = rightView.backgroundColor
                shakeView(rightView)
            default:
                ball.backgroundColor = UIColor.black
            }
        }
    }
    
    @objc func accelerometerAndDragActions() {
        if let acceleration = motionManager.accelerometerData?.acceleration {
            let x = acceleration.x
            let y = acceleration.y
            gravity.angle = CGFloat(atan2(-y, x ))
            gravity.magnitude = abs(sqrt(CGFloat(y*y + x*x)))
        }
        
        if pushBehaviour.active {
            let ballNewLocation = ball.frame.origin
            let dragX = ballDragPoint.x - ball.frame.origin.x
            let dragY = ballDragPoint.y - ball.frame.origin.y
            var approachSpeedX = ballNewLocation.x - ballOldLocation.x
            var approachSpeedY = ballNewLocation.y - ballOldLocation.y
            approachSpeedX = ballNewLocation.x > ballDragPoint.x ? -approachSpeedX : approachSpeedX
            approachSpeedY = ballNewLocation.y > ballDragPoint.y ? -approachSpeedY : approachSpeedY
            let scaleX: CGFloat = approachSpeedX>0 ? 0.02 : 0.05
            let scaleY: CGFloat = approachSpeedY>0 ? 0.02 : 0.05
            pushBehaviour.pushDirection = CGVector(dx: dragX * scaleX, dy: dragY * scaleY)
        }
        
        ballOldLocation = ball.frame.origin
    }
    
    func shakeView(_ view: UIView) {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.04
        animation.repeatCount = 6
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: view.center.x-3, y: view.center.y-3))
        animation.toValue = NSValue(cgPoint: CGPoint(x: view.center.x+3, y: view.center.y+3))
        view.layer.add(animation, forKey: "position")
    }
    
}

