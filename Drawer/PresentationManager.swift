//
//  PresentationManager.swift
//  Drawer
//
//  Created by Ezenwa Okoro on 09/07/2020.
//  Copyright © 2020 Ezenwa Okoro. All rights reserved.
//

import UIKit

class PresentationManager: NSObject, UIViewControllerTransitioningDelegate {
    
    let interactor: PresentationInteractionController
    
    init(interactor: PresentationInteractionController) {
        
        self.interactor = interactor
        
        super.init()
    }

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        
        PresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        PresentationAnimator.init(state: .presentation)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        PresentationAnimator.init(state: .dismissal)
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        
        interactor.interactionInProgress ? interactor : nil
    }
}
