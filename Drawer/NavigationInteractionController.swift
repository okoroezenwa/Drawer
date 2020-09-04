//
//  PresentationInteractionController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 09/07/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

class NavigationInteractionController: UIPercentDrivenInteractiveTransition {

    @objc var interactionInProgress = false
    fileprivate var shouldCompleteTransition = false
    fileprivate weak var viewController: UIViewController?
    @objc var presenting = false
    
    override var completionSpeed: CGFloat {
        
        get { return 1 }
        
        set { }
    }
    
    @objc func add(to vc: UIViewController?) {
        
        viewController = vc
        
        let gesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        gesture.edges = .left
        gesture.delegate = self
        vc?.view.addGestureRecognizer(gesture)
    }
    
    @objc func add(to view: UIView, in vc: UIViewController?) {
        
        viewController = vc
        
        let gesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        gesture.edges = .left
        gesture.delegate = self
        view.addGestureRecognizer(gesture)
    }
    
    @objc func handleGesture(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        
        let isNavigationController = viewController is UINavigationController
        
        // 1
        let translation = gestureRecognizer.translation(in: gestureRecognizer.view)
        let velocity = gestureRecognizer.velocity(in: gestureRecognizer.view?.superview)
        var progress: CGFloat = {
            
            if presenting {
                
                return translation.x / -UIScreen.main.bounds.width
            }
            
            return translation.x / (isNavigationController ? 200 : UIScreen.main.bounds.width)
        }()
        
        progress = min(max(progress, 0), 1)
        
        switch gestureRecognizer.state {
            
            case .began:
                
                interactionInProgress = true
                
                guard let nVC = viewController as? UINavigationController, nVC.topViewController != nVC.viewControllers.first else { return }
            
                nVC.popViewController(animated: true)
            
            case .changed:
                
                shouldCompleteTransition = progress > 0.5 || (translation.x > 0 && velocity.x > 500)
                update(progress)
                
            case .cancelled:
                
                interactionInProgress = false
                cancel()
                
            case .ended:
                
                interactionInProgress = false
                
                if !shouldCompleteTransition {
                    
                    cancel()
                    
                } else {
                    
                    finish()
                }
                
            default: print("Unsupported")
        }
    }
}

extension NavigationInteractionController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if gestureRecognizer is UIScreenEdgePanGestureRecognizer { return otherGestureRecognizer is UIScreenEdgePanGestureRecognizer }
        
        return false
    }
}
