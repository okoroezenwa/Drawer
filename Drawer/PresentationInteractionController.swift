//
//  InteractionController.swift
//  Drawer
//
//  Created by Ezenwa Okoro on 10/07/2020.
//  Copyright © 2020 Ezenwa Okoro. All rights reserved.
//

import UIKit

class PresentationInteractionController: UIPercentDrivenInteractiveTransition {

    @objc var interactionInProgress = false
    fileprivate var shouldCompleteTransition = false
    fileprivate weak var viewController: UIViewController?
    weak var presenter: UIViewController?
    var hasBegunDismissal = false
    var scrollBeganFromScroller = false
    var startPoint = 0 as CGFloat
    
    @objc func addToVC(_ vc: UIViewController) {
        
        viewController = vc
        presenter = previousScrollableViewController(from: viewController?.presentingViewController) ?? root
        
        let leftEdge = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleGesture))
        leftEdge.edges = .left
        leftEdge.delegate = self
        viewController?.view.addGestureRecognizer(leftEdge)
        
        let rightEdge = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleGesture))
        rightEdge.edges = .right
        rightEdge.delegate = self
        viewController?.view.addGestureRecognizer(rightEdge)
        
        let pan = UIPanGestureRecognizer.init(target: self, action: #selector(handleGesture))
        pan.delegate = self
        viewController?.view.addGestureRecognizer(pan)
    }
    
    @objc func handleGesture(_ gr: UIPanGestureRecognizer) {
        
        guard let viewController = viewController else { return }
        
        let translation = gr.translation(in: gr.view)
        let velocity = gr.velocity(in: gr.view)
        let initialProgress = translation.y / (viewController.view.bounds.height - 20)
        let progress: CGFloat = {
            
            if !(gr is UIScreenEdgePanGestureRecognizer), let vc = viewController as? Scrollable, let _ = vc.scroller, vc.scrollDirectionMatchesDismissal(via: gr), vc.refreshControl != nil { return 0 }
            
            return min(max(initialProgress, 0), 1)
        }()
        
        switch gr.state {
            
            case .began:
                
                interactionInProgress = true
                hasBegunDismissal = canBeginDismissal(via: gr)
                
                if hasBegunDismissal {
                
                    viewController.dismiss(animated: true, completion: nil)
                }
            
                startPoint = gr.location(in: appDelegate.window).y
                
            case .changed:
                
                guard hasBegunDismissal else {
                    
                    if canBeginDismissal(via: gr) {
                        
                        if !(gr is UIScreenEdgePanGestureRecognizer), let vc = viewController as? Scrollable, let offset = vc.scroller?.contentOffset.y {
                            
                            vc.currentOffset = max(offset, -84)
                            vc.scroller?.contentOffset.y = vc.currentOffset
                        }
                        
                        if translation.y > 0 {
                            
                            gr.setTranslation(.zero, in: gr.view)
                        }
                    
                        viewController.dismiss(animated: true, completion: nil)
                        
                        hasBegunDismissal = true
                    }
                    
                    return
                }
                
                shouldCompleteTransition = (velocity.y >= 0 && progress > 0.5) || (translation.y > 0 && velocity.y > 650)
                update(progress)
                
                if initialProgress < 0 {
                    
                    if !(gr is UIScreenEdgePanGestureRecognizer), scrollBeganFromScroller { } else {
                        
                        let location = gr.location(in: appDelegate.window).y
                        let progress = (startPoint - location) / startPoint
                        viewController.view.transform = .init(translationX: 0, y: -progress * (progress - 2) * -20)
                    }
                    
                } else {
                
                    if let vc = presenter as? ViewController {
                        
                        if #available(iOS 11, *) { } else {
                            
                            let value = cornerRadius - (progress * cornerRadius)
                            vc.view.layer.cornerRadius = value
                        }
                        
                        vc.useLightStatusBar = progress < 0.75
                    }
                }
            
                if !(gr is UIScreenEdgePanGestureRecognizer), let vc = viewController as? Scrollable, let scroller = vc.scroller {
                    
                    if vc.scrollDirectionMatchesDismissal(via: gr) {
                        
                        if scroller.bounces, vc.refreshControl == nil {
                            
                            scroller.bounces = false
                        }
                        
//                        vc.scroller?.contentOffset.y = vc.currentOffset
                    
                    } else {
                        
                        if !scroller.bounces {
                            
                            scroller.bounces = true
                        }
                    }
                }
                
            case .cancelled:
                
                interactionInProgress = false
                
                returnBounce(via: gr)
                unstretch(from: initialProgress)
                if #available(iOS 11, *) { } else { animateRadius(shouldCompleteTransition: false) }
                updateStatusBar(shouldCompleteTransition: false)
                
                cancel()
                
            case .ended:
                
                interactionInProgress = false
                
                if !(gr is UIScreenEdgePanGestureRecognizer), let vc = viewController as? Scrollable, let _ = vc.refreshControl, vc.canBeginDismissal(with: gr) {
                    
                    shouldCompleteTransition = translation.y > 0 && velocity.y > 1750
                    
                    if shouldCompleteTransition {
                        
                        viewController.dismiss(animated: true, completion: nil)
                    }
                }
                
                if shouldCompleteTransition {
                    
                    completionSpeed = 1 - max(0.01, percentComplete)
                    finish()
                    
                } else {
                    
                    if velocity.y <= 700, !(gr is UIScreenEdgePanGestureRecognizer), let scroller = (viewController as? Scrollable)?.scroller {
                        
                        scroller.isScrollEnabled = false
                        scroller.isScrollEnabled = true
                    }
                    
                    returnBounce(via: gr)
                    unstretch(from: initialProgress)
                    
                    completionSpeed = percentComplete
                    cancel()
                }
                
                if #available(iOS 11, *) { } else { animateRadius(shouldCompleteTransition: shouldCompleteTransition) }
                updateStatusBar(shouldCompleteTransition: shouldCompleteTransition)
                
            default: break
        }
    }
    
    func returnBounce(via gr: UIPanGestureRecognizer) {
        
        guard !(gr is UIScreenEdgePanGestureRecognizer), let scroller = (viewController as? Scrollable)?.scroller else { return }
            
        scroller.bounces = true
    }
    
    func unstretch(from initialProgress: CGFloat) {
        
        guard initialProgress < 0 else { return }
            
        UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.curveLinear, .allowUserInteraction], animations: { self.viewController?.view.transform = .identity })
    }
    
    func animateRadius(shouldCompleteTransition: Bool) {
        
        guard let controller = presenter, controller is ViewController else { return }
            
        controller.view.layer.animate(#keyPath(CALayer.cornerRadius), from: controller.view.layer.cornerRadius, to: shouldCompleteTransition ? 0 : cornerRadius, duration: TimeInterval((percentComplete * duration) / completionSpeed), timingFunctionName: .linear)
    }
    
    func updateStatusBar(shouldCompleteTransition: Bool) {
        
        if let vc = presenter as? ViewController {
            
            vc.useLightStatusBar = !shouldCompleteTransition
        }
    }
}

extension PresentationInteractionController: UIGestureRecognizerDelegate {
    
    func canBeginDismissal(via gr: UIPanGestureRecognizer) -> Bool {
        
        let isVertical = abs(gr.velocity(in: gr.view).y) > abs(gr.velocity(in: gr.view).x)
        
        if let _ = gr as? UIScreenEdgePanGestureRecognizer {
            
            return isVertical
        }
        
        let isAtTop: Bool = {
            
            if let vc = viewController as? Scrollable {
                
                return vc.canBeginDismissal(with: gr)
            }
            
            return true
        }()
        
        let interactsWithRefreshControl: Bool = {
            
            if let vc = viewController as? Scrollable {
                
                return vc.refreshControl != nil && !vc.scrollerDoesNotContainTouch(from: gr)
            }
            
            return false
        }()
        
        return isVertical && isAtTop && !interactsWithRefreshControl
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if gestureRecognizer is UIScreenEdgePanGestureRecognizer { return otherGestureRecognizer is UIScreenEdgePanGestureRecognizer }
        
        return gestureRecognizer is UIPanGestureRecognizer && otherGestureRecognizer == (viewController as? Scrollable)?.gestureRecogniser
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if let gr = gestureRecognizer as? UIPanGestureRecognizer, !(gr is UIScreenEdgePanGestureRecognizer), let vc = viewController as? Scrollable {
            
            scrollBeganFromScroller = !vc.scrollerDoesNotContainTouch(from: gr)
            
            if vc.refreshControl == nil {
            
                vc.scroller?.bounces = false
            }
            
            if vc.scrollerDoesNotContainTouch(from: gr), let offset = vc.scroller?.contentOffset.y {
                
                vc.currentOffset = max(offset, -84)
                vc.scroller?.contentOffset.y = vc.currentOffset
            }
            
            return true
        }
        
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if gestureRecognizer is UIScreenEdgePanGestureRecognizer { return false }
        
        return otherGestureRecognizer is UIScreenEdgePanGestureRecognizer
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if gestureRecognizer is UIScreenEdgePanGestureRecognizer, let vc = viewController as? Scrollable { return vc.scroller?.panGestureRecognizer == otherGestureRecognizer }
        
        return false
    }
}
