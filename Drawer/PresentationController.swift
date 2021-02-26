//
//  PresentationController.swift
//  Drawer
//
//  Created by Ezenwa Okoro on 09/07/2020.
//  Copyright © 2020 Ezenwa Okoro. All rights reserved.
//

import UIKit

let cornerRadius = 12 as CGFloat
var numberOfControllers = 0

func statusBarHeightValue(from view: UIView?) -> CGFloat {
    
    if #available(iOS 13, *) {
        
        return (view?.window ?? appDelegate.window)?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
    
    } else {
        
        return UIApplication.shared.statusBarFrame.height
    }
}

class PresentationController: UIPresentationController {
    
    private lazy var dimmingView: UIView = {
        
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        view.alpha = 0.0
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        view.addGestureRecognizer(recognizer)
        
        return view
    }()
    
    lazy var presenter = previousDismissableViewController(from: presentingViewController) ?? root
    lazy var grandPresenter = (previousDismissableViewController(from: presenter?.presentingViewController) ?? root).value(if: { $0 != presenter })
    
    var newOrigin: CGFloat { statusBarHeight + 10 }
    var grandParentYTranslation = 10 as CGFloat
    var statusBarHeight: CGFloat { statusBarHeightValue(from: containerView) }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        
        var frame: CGRect = .zero
        frame.size = size(forChildContentContainer: presentedViewController, withParentContainerSize: containerView?.bounds.size ?? UIScreen.main.bounds.size)
        
        if let vc = presentedViewController as? ScrollViewDismissable, !vc.isPresentedFullScreen {
            
            frame.origin.y = UIScreen.main.bounds.height - frame.size.height + 20 + cornerRadius
        }
        
        return frame
    }
    
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        
        presentingViewController.dismiss(animated: true)
    }
    
    override func presentationTransitionWillBegin() {
        
        guard let presenter = presenter else { return }
        
        containerView?.insertSubview(dimmingView, at: 0)
        presentedView?.clipsToBounds = true
        
        if let vc = presentedViewController as? ScrollViewDismissable, !vc.isPresentedFullScreen {
            
            presentedView?.layer.cornerRadius = cornerRadius
        }

        if let vc = presentedViewController as? StatusBarControlling {
            
            vc.useLightStatusBar = (vc as? ScrollViewDismissable)?.isPresentedFullScreen == false
        }
        
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:|[dimmingView]|", options: [], metrics: nil, views: ["dimmingView": dimmingView]) + NSLayoutConstraint.constraints(withVisualFormat: "H:|[dimmingView]|",
            options: [], metrics: nil, views: ["dimmingView": dimmingView]))
        
        guard let coordinator = presentedViewController.transitionCoordinator else {
            
            dimmingView.alpha = 1.0
            
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { // risky, but it gives me what I want
            
            if animateWithPresentation, let dismissable = self.presentedViewController as? ScrollViewDismissable, let animation = dismissable.presentationAnimation {

                UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [.allowUserInteraction, .curveEaseOut], animations: animation, completion: nil)
            }
        })
        
        if #available(iOS 11, *) { } else {
            
            presenter.view.layer.animate(#keyPath(CALayer.cornerRadius), from: 0, to: cornerRadius, duration: coordinator.transitionDuration, timingFunctionName: .linear)
        }
        
        if #available(iOS 11, *) { } else {
            
            coordinator.animateAlongsideTransition(in: presenter.view, animation: { _ in
                
                if use3DTransforms {
                    
                    presenter.view.layer.transform = self.transform3D(for: presenter, completed: true)
                    
                } else {
                
                    presenter.view.transform = self.transform(for: presenter, completed: true)
                }
                
            }, completion: nil)
            
            coordinator.animateAlongsideTransition(in: grandPresenter?.view, animation: { _ in
                
                if use3DTransforms {
                    
                    self.grandPresenter?.view.layer.transform = self.transform3D(for: self.grandPresenter, completed: true).concatenating(.translation(x: 0, y: self.grandParentYTranslation, z: 1))
                    
                } else {
                
                    self.grandPresenter?.view.transform = self.transform(for: self.grandPresenter, completed: true).translatedBy(x: 0, y: self.grandParentYTranslation)
                }
                
            }, completion: nil)
        }
        
        coordinator.animate(alongsideTransition: { _ in
            
            self.dimmingView.alpha = 1.0
            
            if #available(iOS 11, *) {
                
                presenter.view.layer.cornerRadius = cornerRadius
                
                if use3DTransforms {
                    
                    presenter.view.layer.transform = self.transform3D(for: presenter, completed: true)
                    self.grandPresenter?.view.layer.transform = self.transform3D(for: self.grandPresenter, completed: true).concatenating(.translation(x: 0, y: self.grandParentYTranslation, z: 1))
                
                } else {
                    
                    presenter.view.transform = self.transform(for: presenter, completed: true)
                    self.grandPresenter?.view.transform = self.transform(for: self.grandPresenter, completed: true).translatedBy(x: 0, y: self.grandParentYTranslation)
                }
            }
        })
    }
    
    override func presentationTransitionDidEnd(_ completed: Bool) {
        
        guard let presenter = presenter else { return }
        
        if completed {
            
            numberOfControllers += 1
        }
        
        if use3DTransforms {
        
            presenter.view.layer.transform = transform3D(for: presenter, completed: true)
            grandPresenter?.view.layer.transform = transform3D(for: grandPresenter, completed: true).concatenating(.translation(x: 0, y: completed ? grandParentYTranslation : 0, z: 1))
            
        } else {
            
            presenter.view.transform = transform(for: presenter, completed: completed)
            grandPresenter?.view.transform = transform(for: grandPresenter, completed: true).translatedBy(x: 0, y: completed ? grandParentYTranslation : 0)
        }
        
        if presenter is ViewController {
        
            presenter.view.layer.cornerRadius = radius(for: .presentation, completed: completed)
            
            if #available(iOS 11, *) { } else { presenter.view.layer.removeAllAnimations() }
        }
        
        (presentedViewController as? ScrollViewDismissable)?.presentationCompletion(completed)
    }
    
    override func dismissalTransitionWillBegin() {
        
        guard let coordinator = presentedViewController.transitionCoordinator else {
            
            dimmingView.alpha = 0.0
            
            return
        }
        
        if !coordinator.isInteractive {
            
            if let vc = presentingViewController as? StatusBarControlling, let previous = presenter as? StatusBarControlling {
                
                vc.useLightStatusBar = previous.useLightStatusBar
            }
        
            if #available(iOS 11, *) { } else {

                if presenter is ViewController || (presenter as? ScrollViewDismissable)?.isPresentedFullScreen == true {
                                
                    presenter?.view.layer.animate(#keyPath(CALayer.cornerRadius), from: cornerRadius, to: 0, duration: coordinator.transitionDuration, timingFunctionName: .linear)
                }
            }
        }
        
        if #available(iOS 11, *) { } else {
            
            coordinator.animateAlongsideTransition(in: presenter?.view, animation: { _ in
                
                if use3DTransforms {
                
                    self.presenter?.view.layer.transform = .identity
                
                } else {
                    
                    self.presenter?.view.transform = .identity
                }
                
            }, completion: nil)
            
            coordinator.animateAlongsideTransition(in: grandPresenter?.view, animation: { _ in
                
                if use3DTransforms {
                
                    self.grandPresenter?.view.layer.transform = self.transform3D(for: self.grandPresenter, completed: true)
                
                } else {
                    
                    self.grandPresenter?.view.transform = self.transform(for: self.grandPresenter, completed: true)
                }
                
            }, completion: nil)
        }
        
        coordinator.animate(alongsideTransition: { _ in
            
            self.dimmingView.alpha = 0.0
            
            if #available(iOS 11, *) {
                
                if self.presenter is ViewController || (self.presenter as? ScrollViewDismissable)?.isPresentedFullScreen == true {
                    
                    self.presenter?.view.layer.cornerRadius = 0
                }
                
                if use3DTransforms {
                    
                    self.presenter?.view.layer.transform = .identity
                    self.grandPresenter?.view.layer.transform = self.transform3D(for: self.grandPresenter, completed: true)
                
                } else {
                    
                    self.presenter?.view.transform = .identity
                    self.grandPresenter?.view.transform = self.transform(for: self.grandPresenter, completed: true)
                }
            }
        })
    }
    
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        
        guard let presenter = presenter else { return }
        
        if completed {
            
            numberOfControllers -= 1
        }
        
        if use3DTransforms {
            
            presenter.view.layer.transform = completed ? .identity : transform3D(for: presenter, completed: true)
            grandPresenter?.view.layer.transform = transform3D(for: grandPresenter, completed: true).concatenating(.translation(x: 0, y: completed ? 0 : grandParentYTranslation, z: 1))
            
        } else {
            
            presenter.view.transform = completed ? .identity : transform(for: presenter, completed: true)
            grandPresenter?.view.transform = transform(for: grandPresenter, completed: true).translatedBy(x: 0, y: completed ? 0 : grandParentYTranslation)
        }
        
        if presenter is ViewController || (presenter as? ScrollViewDismissable)?.isPresentedFullScreen == true {
        
            presenter.view.layer.cornerRadius = completed ? 0 : cornerRadius
            
            if #available(iOS 11, *) { } else { presenter.view.layer.removeAllAnimations() }
        }
        
        if !completed, let coordinator = presentedViewController.transitionCoordinator, !coordinator.isInteractive, let vc = presentingViewController as? StatusBarControlling {

            vc.useLightStatusBar = (vc as? ScrollViewDismissable)?.isPresentedFullScreen == false
        }
        
        (presentedViewController as? ScrollViewDismissable)?.presentationCompletion(completed)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        super.viewWillTransition(to: size, with: coordinator)
        
        guard presentedViewController.transitionCoordinator == nil else { return }
        #warning("Still some issues during rotation")
        coordinator.animate(alongsideTransition: { _ in }, completion: { _ in
            
            if self.grandPresenter == nil {
                
                if use3DTransforms {

                    self.presenter?.view.layer.transform = .identity
                    
                } else {
                    
                    self.presenter?.view.transform = .identity
                }
                
                self.presenter?.view.frame = .init(origin: .zero, size: size)
                
                if use3DTransforms {

                    self.presenter?.view.layer.transform = self.transform3D(for: self.presenter, completed: true)
                    
                } else {
                    
                    self.presenter?.view.transform = self.transform(for: self.presenter, completed: true)
                }

            } else if self.grandPresenter is ViewController {
                
                if use3DTransforms {

                    self.grandPresenter?.view.layer.transform = .identity
                    
                } else {
                    
                    self.grandPresenter?.view.transform = .identity
                }
                
                self.grandPresenter?.view.frame = .init(origin: .zero, size: size)
                
                if use3DTransforms {

                    self.grandPresenter?.view.layer.transform = self.transform3D(for: self.grandPresenter, completed: true).concatenating(.translation(x: 0, y: self.grandParentYTranslation, z: 1))
                    self.presenter?.view.layer.transform = self.transform3D(for: self.presenter, completed: true)
                    
                } else {
                    
                    self.presenter?.view.transform = self.transform(for: self.presenter, completed: true)
                    self.grandPresenter?.view.transform = self.transform(for: self.grandPresenter, completed: true).translatedBy(x: 0, y: self.grandParentYTranslation)
                }
            }
        })
    }

    override func containerViewWillLayoutSubviews() {
        
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
    
    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        
        var difference: CGFloat {
            
            guard let vc = presentedViewController as? ScrollViewDismissable, !vc.isPresentedFullScreen else { return 0 }
            
            return statusBarHeight + 20
        }
        
        return .init(width: parentSize.width, height: parentSize.height - difference + 20 + cornerRadius) // `20 + cornerRadius` takes care of swiping up instead of down during dismissal
    }
    
    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        
        guard presentedViewController.transitionCoordinator == nil else { return }
        
        if #available(iOS 11, *) { } else {
        
            if let dismissable = presentedViewController as? ScrollViewDismissable & UIViewController {
            
                dismissable.view.layer.animate(#keyPath(CALayer.cornerRadius), from: dismissable.isPresentedFullScreen ? cornerRadius : 0, to: dismissable.isPresentedFullScreen ? 0 : cornerRadius, duration: 0.3, timingFunctionName: .linear)
            }
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            
            self.containerView?.setNeedsLayout()
            self.containerView?.layoutIfNeeded()
            
            if #available(iOS 11, *), let dismissable = self.presentedViewController as? ScrollViewDismissable & UIViewController {
                
                dismissable.view.layer.cornerRadius = dismissable.isPresentedFullScreen ? 0 : cornerRadius
            }
        
        }, completion: { _ in
            
            if let dismissable = self.presentedViewController as? ScrollViewDismissable & UIViewController {
                
                dismissable.view.layer.cornerRadius = dismissable.isPresentedFullScreen ? 0 : cornerRadius
            }
        })
    }
}

extension PresentationController {
    
    func transform(for vc: UIViewController?, completed: Bool) -> CGAffineTransform {
        
        guard completed else { return .identity }
        
        if let vc = vc as? ScrollViewDismissable, !vc.isPresentedFullScreen {
            
            let ratio = (UIScreen.main.bounds.width - 32) / UIScreen.main.bounds.width
            let height = frameOfPresentedViewInContainerView.height
            let newHeight = height * ratio
            let translation = (height - newHeight) / 2
            
            return CGAffineTransform.init(scaleX: ratio, y: ratio).concatenating(.init(translationX: 0, y: -translation - 10))
            
        } else {
            
            let fullScreenPresentationExtraHeight: CGFloat = vc is ViewController ? 0 : (20 + 16)
            
            return .init(scaleX: (UIScreen.main.bounds.width - 32) / UIScreen.main.bounds.width, y: (UIScreen.main.bounds.height + fullScreenPresentationExtraHeight - (newOrigin * 2)) / (UIScreen.main.bounds.height + fullScreenPresentationExtraHeight))
        }
    }
    
    func transform3D(for vc: UIViewController?, completed: Bool) -> CATransform3D {
        
        guard completed else { return .identity }
        
        if let vc = vc as? ScrollViewDismissable, !vc.isPresentedFullScreen {
        
            let ratio = (UIScreen.main.bounds.width - 32) / UIScreen.main.bounds.width
            let height = frameOfPresentedViewInContainerView.height
            let newHeight = height * ratio
            let translation = (height - newHeight) / 2
            
            return CATransform3D.scale(x: ratio, y: ratio, z: 1.00001).concatenating(.translation(x: 0, y: -translation - 10, z: 1))
            
        } else {
            
            let fullScreenPresentationExtraHeight: CGFloat = vc is ViewController ? 0 : (20 + 16)
            
            return .scale(x: (UIScreen.main.bounds.width - 32) / UIScreen.main.bounds.width, y: (UIScreen.main.bounds.height + fullScreenPresentationExtraHeight - (newOrigin * 2)) / (UIScreen.main.bounds.height + fullScreenPresentationExtraHeight), z: 1.00001)
        }
    }
    
    func radius(for state: PresentationAnimator.State, completed: Bool) -> CGFloat {
        
        switch state {
                
            case .presentation: return completed ? cornerRadius : 0
            
            case .dismissal: return completed ? 0 : cornerRadius
        }
    }
}

extension UIView {
    
   func round(_ corners: UIRectCorner, radius: CGFloat) {
    
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}

extension CALayer {
    
    func animate(_ value: String, from start: Any?, to end: Any?, duration: TimeInterval, timingFunctionName: CAMediaTimingFunctionName) {
        
        let animation = CABasicAnimation(keyPath: value)
        animation.duration = duration
        animation.fromValue = start
        animation.toValue = end
        animation.timingFunction = .init(name: timingFunctionName)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        add(animation, forKey: value)
    }
}

extension CATransform3D {
    
    static var identity: CATransform3D { CATransform3DIdentity }
    
    func concatenating(_ transform: CATransform3D) -> CATransform3D { CATransform3DConcat(self, transform) }
    
    static func scale(x: CGFloat, y: CGFloat, z: CGFloat) -> CATransform3D { CATransform3DMakeScale(x, y, z) }
    
    static func translation(x: CGFloat, y: CGFloat, z: CGFloat) -> Self { CATransform3DMakeTranslation(x, y, z) }
}

extension Optional {
    
    func value(if condition: (Wrapped?) -> Bool) -> Wrapped? {
        
        condition(self) ? self : nil
    }
}

extension CGRect {
    
    func modifiedBy(width: CGFloat, height: CGFloat) -> CGRect {
        
        return CGRect.init(x: origin.x, y: origin.y, width: self.width + width, height: self.height + height)
    }
    
    func modifiedBy(newOrigin: CGPoint = .zero, size: CGSize) -> CGRect {
        
        return CGRect.init(x: origin.x + newOrigin.x, y: origin.y + newOrigin.y, width: self.width + size.width, height: self.height + size.height)
    }
    
    func modifiedBy(x: CGFloat, y: CGFloat) -> CGRect {
        
        return CGRect.init(x: origin.x + x, y: origin.y + y, width: width, height: height)
    }
    
    var centre: CGPoint { return .init(x: (width / 2) + origin.x, y: (height / 2) + origin.y) }
}
