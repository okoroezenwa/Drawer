//
//  NavigationAnimationController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 25/09/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

enum AnimationDirection { case forward, reverse }

class NavigationAnimator: NSObject, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate {
    
    var direction: AnimationDirection
    @objc var interactor: NavigationInteractor
    var animationInProgress: Bool
    var disregardViewLayoutDuringKeyboardPresentation = false

    override init() {
        
        direction = .forward
        interactor = NavigationInteractor()
        animationInProgress = false
        
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        animationInProgress = true
        
        guard let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
            let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else { return }
        
        let containerView = transitionContext.containerView
        let duration = transitionDuration(using: transitionContext)
        
        UIView.setAnimationsEnabled(false)
        
        toVC.view.frame.origin.x += direction == .forward ? 40 : -40
        toVC.view.alpha = 0
        
        containerView.addSubview(fromVC.view)
        containerView.addSubview(toVC.view)
        
        toVC.view.layoutIfNeeded()
        
        UIView.setAnimationsEnabled(true)
        
        UIView.animateKeyframes(withDuration: duration, delay: 0, options: .calculationModeCubic, animations: {
            
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 3/5, animations: {
            
                fromVC.view.frame.origin.x += (self.direction == .forward ? -40 : 40)
                fromVC.view.alpha = 0
            })
            
            UIView.addKeyframe(withRelativeStartTime: 2.8/5, relativeDuration: 2.2/5, animations: {
            
                toVC.view.frame.origin.x += (self.direction == .forward ? -40 : 40)
                
                if self.direction == .forward, fromVC.view.frame.origin.x < 0 {
                    
                    fromVC.view.frame.origin.x = 0
                }
                
                toVC.view.alpha = 1
            })
            
        }, completion: { [weak self] _ in
            
            let completed = !transitionContext.transitionWasCancelled
            transitionContext.completeTransition(completed)
            
            self?.animationInProgress = false
                        
            if completed {
                
                toVC.view.alpha = 1
                
                if self?.direction == .reverse {
                    
                    fromVC.view.removeFromSuperview()
                }
                
            } else {
                
                self?.disregardViewLayoutDuringKeyboardPresentation = true
                UIView.setAnimationsEnabled(false)
                
                fromVC.view.alpha = 1
                
                self?.disregardViewLayoutDuringKeyboardPresentation = false
                UIView.setAnimationsEnabled(true)
            }
        })
    }
}

extension NavigationAnimator: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        
        return interactor.interactionInProgress ? interactor : nil
    }
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        switch operation {
            
            case .pop:
            
                direction = .reverse
                return self
            
            case .push:
            
                direction = .forward
                return self
            
            case .none: return nil
            
            @unknown default: return nil
        }
    }
}
