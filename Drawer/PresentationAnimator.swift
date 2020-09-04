//
//  PresentationAnimator.swift
//  Drawer
//
//  Created by Ezenwa Okoro on 09/07/2020.
//  Copyright © 2020 Ezenwa Okoro. All rights reserved.
//

import UIKit

class PresentationAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    enum State { case presentation, dismissal }
    
    let state: State
    
    init(state: State) {
        
        self.state = state
        
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        
        state == .presentation || transitionContext?.isInteractive ?? false ? 0.45 : 0.55
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        let isPresentation = state == .presentation
        let presentedKey: UITransitionContextViewControllerKey = isPresentation ? .to : .from
        
        guard let controller = transitionContext.viewController(forKey: presentedKey) else { return }
        
        if isPresentation {
            
          transitionContext.containerView.addSubview(controller.view)
        }
        
        let presentedFrame = transitionContext.finalFrame(for: controller)
        var dismissedFrame = presentedFrame
        dismissedFrame.origin.y = UIScreen.main.bounds.height
        
        let initialFrame = isPresentation ? dismissedFrame : presentedFrame
        let finalFrame = isPresentation ? presentedFrame : dismissedFrame
        
        let duration = transitionDuration(using: transitionContext)
        controller.view.frame = initialFrame
        
        let animations = { controller.view.frame = finalFrame }
        let completion: (Bool) -> Void = { finished in
            
            if !isPresentation, !transitionContext.transitionWasCancelled {
                    
                controller.view.removeFromSuperview()
            }
            
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        
        if transitionContext.isInteractive {
            
            UIView.animate(withDuration: duration, delay: 0, options: [.curveLinear, .allowUserInteraction], animations: animations, completion: completion)
        
        } else {
            
            UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.curveLinear], animations: animations, completion: completion)
        }
    }
    
//    func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
//
//
//    }
}
