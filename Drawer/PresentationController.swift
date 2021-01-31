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

func statusBarHeight(from view: UIView?) -> CGFloat {
    
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
    
    lazy var presenter = previousScrollableViewController(from: presentingViewController) ?? root
    lazy var grandPresenter = (previousScrollableViewController(from: presenter?.presentingViewController) ?? root).value(if: { $0 != presenter })
    
    lazy var newOrigin = statusBarHeight + 10
    var grandParentYTranslation = 10 as CGFloat
    
    lazy var statusBarHeight: CGFloat = Drawer.statusBarHeight(from: containerView)
    
    override var frameOfPresentedViewInContainerView: CGRect {
        
        var frame: CGRect = .zero
        frame.size = size(forChildContentContainer: presentedViewController, withParentContainerSize: containerView?.bounds.size ?? UIScreen.main.bounds.size)
        frame.origin.y = UIScreen.main.bounds.height - frame.size.height + 20
        
        return frame
    }
    
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        
        presentingViewController.dismiss(animated: true)
    }
    
    override func presentationTransitionWillBegin() {
        
        guard let presenter = presenter else { return }
        
        containerView?.insertSubview(dimmingView, at: 0)
        presentedView?.round([.topLeft, .topRight], radius: cornerRadius)

        if let vc = presenter as? ViewController {
            
            vc.useLightStatusBar = true
        }
        
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:|[dimmingView]|", options: [], metrics: nil, views: ["dimmingView": dimmingView]) + NSLayoutConstraint.constraints(withVisualFormat: "H:|[dimmingView]|",
            options: [], metrics: nil, views: ["dimmingView": dimmingView]))
        
        guard let coordinator = presentedViewController.transitionCoordinator else {
            
            dimmingView.alpha = 1.0
            
            return
        }
        
        if #available(iOS 11, *) { } else {
        
            if presenter is ViewController {
            
                presenter.view.layer.animate(#keyPath(CALayer.cornerRadius), from: 0, to: cornerRadius, duration: coordinator.transitionDuration, timingFunctionName: .linear)
            }
        }
        
        if #available(iOS 11, *) { } else {
            
            coordinator.animateAlongsideTransition(in: presenter.view, animation: { _ in
                
                if useFrames {
                    
                    presenter.view.frame = self.frame(for: presenter, completed: true)
                    
                } else {
                
                    presenter.view.transform = self.transform(for: presenter, completed: true)
                }
                
            }, completion: nil)
            
            coordinator.animateAlongsideTransition(in: grandPresenter?.view, animation: { _ in
                
                if useFrames {
                    
                    self.grandPresenter?.view.frame = self.frame(for: self.grandPresenter, completed: true).modifiedBy(x: 0, y: 10)
                    
                } else {
                
                    self.grandPresenter?.view.transform = self.transform(for: self.grandPresenter, completed: true).translatedBy(x: 0, y: self.grandParentYTranslation)
                }
                
            }, completion: nil)
        }
        
        coordinator.animate(alongsideTransition: { _ in
            
            self.dimmingView.alpha = 1.0
            
            if #available(iOS 11, *) {
                
                presenter.view.layer.cornerRadius = cornerRadius
                
                if useFrames {
                
                    presenter.view.frame = self.frame(for: presenter, completed: true)
                    self.grandPresenter?.view.frame = self.frame(for: self.grandPresenter, completed: true).modifiedBy(x: 0, y: 10)
                
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
        
        if useFrames {
        
            presenter.view.frame = completed ? frame(for: presenter, completed: true) : frameOfPresentedViewInContainerView
            grandPresenter?.view.frame = frame(for: grandPresenter, completed: true).modifiedBy(x: 0, y: completed ? 10 : 0)
            
        } else {
            
            presenter.view.transform = transform(for: presenter, completed: completed)
            grandPresenter?.view.transform = transform(for: grandPresenter, completed: true).translatedBy(x: 0, y: completed ? grandParentYTranslation : 0)
        }
        
        if presenter is ViewController {
        
            presenter.view.layer.cornerRadius = radius(for: .presentation, completed: completed)
            
            if #available(iOS 11, *) { } else { presenter.view.layer.removeAllAnimations() }
        }
    }
    
    override func dismissalTransitionWillBegin() {
        
        guard let coordinator = presentedViewController.transitionCoordinator else {
            
            dimmingView.alpha = 0.0
            
            return
        }
        
        if !coordinator.isInteractive {
            
            if let vc = presenter as? ViewController {
                
                vc.useLightStatusBar = false
            }
        
            if #available(iOS 11, *) { } else {

                if presenter is ViewController {
                                
                    presenter?.view.layer.animate(#keyPath(CALayer.cornerRadius), from: cornerRadius, to: 0, duration: coordinator.transitionDuration, timingFunctionName: .linear)
                }
            }
        }
        
        if #available(iOS 11, *) { } else {
            
            coordinator.animateAlongsideTransition(in: presenter?.view, animation: { _ in
                
                if useFrames {
                
                    self.presenter?.view.frame = self.presenter is ViewController ? UIScreen.main.bounds : self.frameOfPresentedViewInContainerView
                
                } else {
                    
                    self.presenter?.view.transform = .identity
                }
                
            }, completion: nil)
            
            coordinator.animateAlongsideTransition(in: grandPresenter?.view, animation: { _ in
                
                if useFrames {
                
                    self.grandPresenter?.view.frame = self.frame(for: self.grandPresenter, completed: true)
                
                } else {
                    
                    self.grandPresenter?.view.transform = self.transform(for: self.grandPresenter, completed: true)
                }
                
            }, completion: nil)
        }
        
        coordinator.animate(alongsideTransition: { _ in
            
            self.dimmingView.alpha = 0.0
            
            if #available(iOS 11, *) {
                
                self.presenter?.view.layer.cornerRadius = 0
                
                if useFrames {
                    
                    self.presenter?.view.frame = self.presenter is ViewController ? UIScreen.main.bounds : self.frameOfPresentedViewInContainerView
                    self.grandPresenter?.view.frame = self.frame(for: self.grandPresenter, completed: true)
                
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
        
        if useFrames {
            
            presenter.view.frame = presenter is ViewController ? (completed ? UIScreen.main.bounds : frame(for: presenter, completed: true)) : (completed ? frameOfPresentedViewInContainerView : frame(for: presenter, completed: true))
            grandPresenter?.view.frame = frame(for: grandPresenter, completed: true).modifiedBy(x: 0, y: completed ? 0 : 10)
            
        } else {
            
            presenter.view.transform = completed ? .identity : transform(for: presenter, completed: true)
            grandPresenter?.view.transform = transform(for: grandPresenter, completed: true).translatedBy(x: 0, y: completed ? 0 : grandParentYTranslation)
        }
        
        if presenter is ViewController {
        
            presenter.view.layer.cornerRadius = completed ? 0 : cornerRadius
            
            if #available(iOS 11, *) { } else { presenter.view.layer.removeAllAnimations() }
        }
        
        if let coordinator = presentedViewController.transitionCoordinator, !coordinator.isInteractive, let vc = presenter as? ViewController {

            vc.useLightStatusBar = !completed
        }
    }
    
    override func containerViewWillLayoutSubviews() {
        
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
    
    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        
        return .init(width: parentSize.width, height: parentSize.height - statusBarHeight - 20 + 20) // added 20 takes care of swiping up instead of down during dismissal
    }
}

extension PresentationController {
    
    func transform(for vc: UIViewController?, completed: Bool) -> CGAffineTransform {
        
        guard completed else { return .identity }
        
        if !(vc is ViewController) {
            
            let ratio = (UIScreen.main.bounds.width - 32) / UIScreen.main.bounds.width
            let height = frameOfPresentedViewInContainerView.height
            let newHeight = height * ratio
            let translation = (height - newHeight) / 2
            
            return CGAffineTransform.init(scaleX: ratio, y: ratio).concatenating(.init(translationX: 0, y: -translation - 10))
            
        } else {
            
            return .init(scaleX: (UIScreen.main.bounds.width - 32) / UIScreen.main.bounds.width, y: (UIScreen.main.bounds.height - (newOrigin * 2)) / UIScreen.main.bounds.height)
        }
    }
    
    func frame(for vc: UIViewController?, completed: Bool) -> CGRect {
        
        let ratio = (UIScreen.main.bounds.width - 32) / UIScreen.main.bounds.width
        let height = frameOfPresentedViewInContainerView.height
        let newHeight = height * ratio
        
        return .init(x: 16, y: statusBarHeight + 10, width: UIScreen.main.bounds.width - 32, height: newHeight)
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
