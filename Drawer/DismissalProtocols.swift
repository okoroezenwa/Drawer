//
//  File.swift
//  Drawer
//
//  Created by Ezenwa Okoro on 14/02/2021.
//  Copyright © 2021 Ezenwa Okoro. All rights reserved.
//

import UIKit

protocol ScrollViewDismissable: class {
    
    var gestureRecogniser: UIPanGestureRecognizer? { get }
    var preferredOffset: CGFloat { get }
    var currentOffset: CGFloat { get set }
    var scroller: UIScrollView? { get }
    var refreshControl: UIRefreshControl? { get }
    var isAtTop: Bool { get }
    var presentationAnimation: (() -> ())? { get }
    var isPresentedFullScreen: Bool { get }
    func scrollerDoesNotContainTouch(from gr: UIPanGestureRecognizer) -> Bool
    func canBeginDismissal(with gr: UIPanGestureRecognizer) -> Bool
    func scrollDirectionMatchesDismissal(via gr: UIPanGestureRecognizer) -> Bool
}

protocol StatusBarControlling: class {
    
    var useLightStatusBar: Bool { get set }
}
