//
//  InteractionController.swift
//  Drawer
//
//  Created by Ezenwa Okoro on 10/07/2020.
//  Copyright © 2020 Ezenwa Okoro. All rights reserved.
//

import UIKit

class PresentationInteractor: UIPercentDrivenInteractiveTransition {

    @objc var interactionInProgress = false
    fileprivate var shouldCompleteTransition = false
    fileprivate weak var viewController: UIViewController?
    weak var presenter: UIViewController?
    var hasBegunDismissal = false
    var scrollBeganFromScroller = false
    var startPoint = 0 as CGFloat
    
    @objc func addToVC(_ vc: UIViewController) {
        
        viewController = vc
        presenter = previousDismissableViewController(from: viewController?.presentingViewController) ?? root
        
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
        let initialProgress = translation.y / (viewController.view.bounds.height - 20 - cornerRadius)
        let progress: CGFloat = {
            
            if !(gr is UIScreenEdgePanGestureRecognizer), let vc = viewController as? ScrollViewDismissable, let _ = vc.scroller, vc.scrollDirectionMatchesDismissal(via: gr), vc.refreshControl != nil, scrollBeganFromScroller { return 0 }
            
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
                        
                        if !(gr is UIScreenEdgePanGestureRecognizer), let vc = viewController as? ScrollViewDismissable, let offset = vc.scroller?.contentOffset.y {
                            
                            vc.currentOffset = max(offset, -vc.preferredOffset)
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
                        
                        if let vc = viewController as? ScrollViewDismissable, !vc.isPresentedFullScreen, let scroller = vc.scroller {
                            
                            scroller.contentOffset.y = scroller.contentOffset.y
                            
                            let location = gr.location(in: appDelegate.window).y
                            let progress = (startPoint - location) / startPoint
                            
                            viewController.view.transform = .init(translationX: 0, y: -progress * (progress - 2) * -20)
                        }
                    }
                    
                } else {
                    
                    if #available(iOS 11, *) { } else if let vc = presenter as? ViewController {
                        
                        let value = cornerRadius - (progress * cornerRadius)
                        vc.view.layer.cornerRadius = value
                    }
                
                    if let vc = viewController as? StatusBarControlling, let previous = presenter as? StatusBarControlling {
                        
                        vc.useLightStatusBar = {
                            
                            let point = 14 / (viewController.view.bounds.height - 20 - cornerRadius)
                            
                            switch progress {
                                
                                case 0..<point: return (vc as? ScrollViewDismissable)?.isPresentedFullScreen == false

                                case point...0.75: return true
                                    
                                default: return !(previous is ViewController || (previous as? ScrollViewDismissable)?.isPresentedFullScreen == true)
                            }
                        }()
                    }
                }
            
                if !(gr is UIScreenEdgePanGestureRecognizer), let vc = viewController as? ScrollViewDismissable, let scroller = vc.scroller, !translation.y.isZero { // checking non-zero translation added 4/2/21
                    
                    if vc.scrollDirectionMatchesDismissal(via: gr) {
                        
                        if scroller.bounces, vc.refreshControl == nil {
                            
                            scroller.bounces = false
                        }
                    
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
                
                if !(gr is UIScreenEdgePanGestureRecognizer), let vc = viewController as? ScrollViewDismissable, let _ = vc.refreshControl, vc.canBeginDismissal(with: gr), scrollBeganFromScroller {
                    
                    shouldCompleteTransition = translation.y > 0 && velocity.y > 1750
                    
                    if shouldCompleteTransition {
                        
                        viewController.dismiss(animated: true, completion: nil)
                    }
                }
                
                if shouldCompleteTransition {
                    
                    completionSpeed = 1 - max(0.01, percentComplete)
                    finish()
                    
                } else {
                    
                    if velocity.y <= 700, !(gr is UIScreenEdgePanGestureRecognizer), let scroller = (viewController as? ScrollViewDismissable)?.scroller {
                        
                        scroller.isScrollEnabled = false
                        scroller.isScrollEnabled = true
                    }
                    
                    returnBounce(via: gr)
                    unstretch(from: initialProgress)
                    
                    completionSpeed = percentComplete
                    cancel()
                }
                
                if let vc = viewController as? ScrollViewDismissable { vc.scroller?.isScrollEnabled = true } // seems to take care of issue where scrolling up at some in-between point of the header and scroll view causes both to perform their respective actions at once. Issue also seemed to have an effect on the offset that results in a dismissal later on
                
                if #available(iOS 11, *) { } else { animateRadius(shouldCompleteTransition: shouldCompleteTransition) }
                updateStatusBar(shouldCompleteTransition: shouldCompleteTransition)
                
            default: break
        }
    }
    
    func returnBounce(via gr: UIPanGestureRecognizer) {
        
        guard !(gr is UIScreenEdgePanGestureRecognizer), let scroller = (viewController as? ScrollViewDismissable)?.scroller else { return }
            
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
        
        if let vc = viewController as? StatusBarControlling, let previous = presenter as? StatusBarControlling {
            
            vc.useLightStatusBar = shouldCompleteTransition ? previous.useLightStatusBar : !(vc is ViewController || (vc as? ScrollViewDismissable)?.isPresentedFullScreen == true)
        }
    }
}

extension PresentationInteractor: UIGestureRecognizerDelegate {
    
    func canBeginDismissal(via gr: UIPanGestureRecognizer) -> Bool {
        
        let isVertical = abs(gr.velocity(in: gr.view).y) > abs(gr.velocity(in: gr.view).x)
        
        if let _ = gr as? UIScreenEdgePanGestureRecognizer {
            
            return isVertical
        }
        
        let isAtTop: Bool = {
            
            if let vc = viewController as? ScrollViewDismissable {
                
                return vc.canBeginDismissal(with: gr)
            }
            
            return true
        }()
        
        let interactsWithRefreshControl: Bool = {
            
            if let vc = viewController as? ScrollViewDismissable {
                
                return vc.refreshControl != nil && !vc.scrollerDoesNotContainTouch(from: gr)
            }
            
            return false
        }()
        
        return isVertical && isAtTop && !interactsWithRefreshControl
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if gestureRecognizer is UIScreenEdgePanGestureRecognizer { return otherGestureRecognizer is UIScreenEdgePanGestureRecognizer }
        
        return gestureRecognizer is UIPanGestureRecognizer && otherGestureRecognizer == (viewController as? ScrollViewDismissable)?.gestureRecogniser
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if let gr = gestureRecognizer as? UIPanGestureRecognizer, !(gr is UIScreenEdgePanGestureRecognizer), let vc = viewController as? ScrollViewDismissable {
            
            scrollBeganFromScroller = !vc.scrollerDoesNotContainTouch(from: gr)
            
            if vc.refreshControl == nil, gr.translation(in: gr.view).y > 0 {
                
                vc.scroller?.bounces = false
            }
            
            if vc.scrollerDoesNotContainTouch(from: gr), let offset = vc.scroller?.contentOffset.y {
                vc.scroller?.isScrollEnabled = false
                vc.currentOffset = max(offset, -vc.preferredOffset)
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
        
        if gestureRecognizer is UIScreenEdgePanGestureRecognizer, let vc = viewController as? ScrollViewDismissable { return vc.scroller?.panGestureRecognizer == otherGestureRecognizer }
        
        return false
    }
}
