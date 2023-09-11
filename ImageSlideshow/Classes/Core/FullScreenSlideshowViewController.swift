//
//  FullScreenSlideshowViewController.swift
//  ImageSlideshow
//
//  Created by Petr Zvoníček on 31.08.15.
//

import UIKit

@objcMembers
open class FullScreenSlideshowViewController: UIViewController {

    open var slideshow: ImageSlideshow = {
        let slideshow = ImageSlideshow()
        slideshow.zoomEnabled = true
        slideshow.contentScaleMode = UIViewContentMode.scaleAspectFit
        slideshow.pageIndicatorPosition = PageIndicatorPosition(horizontal: .center, vertical: .bottom)
        // turns off the timer
        slideshow.slideshowInterval = 0
        slideshow.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]

        return slideshow
    }()

    /// Close button 
    open var closeButton = UIButton()

    /// Close button frame
    open var closeButtonFrame: CGRect?
    
    /// Download button
    open var downloadButton = UIButton()
    
    open var downloadSuccessMessage: String = ""
    
    open var showDownloadButton: Bool = true

    /// Closure called on page selection
    open var pageSelected: ((_ page: Int) -> Void)?

    /// Index of initial image
    open var initialPage: Int = 0

    /// Input sources to 
    open var inputs: [InputSource]?

    /// Background color
    open var backgroundColor = UIColor.black

    /// Enables/disable zoom
    open var zoomEnabled = true {
        didSet {
            slideshow.zoomEnabled = zoomEnabled
        }
    }

    fileprivate var isInit = true

    convenience init() {
        self.init(nibName: nil, bundle: nil)

        self.modalPresentationStyle = .custom
        if #available(iOS 13.0, *) {
            // Use KVC to set the value to preserve backwards compatiblity with Xcode < 11
            self.setValue(true, forKey: "modalInPresentation")
        }
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = backgroundColor
        slideshow.backgroundColor = backgroundColor

        if let inputs = inputs {
            slideshow.setImageInputs(inputs)
        }

        view.addSubview(slideshow)
        
        self.modalPresentationCapturesStatusBarAppearance = true

        // close button configuration
        closeButton.setImage(UIImage(named: "ic_cross_white", in: .module, compatibleWith: nil), for: UIControlState())
        closeButton.addTarget(self, action: #selector(FullScreenSlideshowViewController.close), for: UIControlEvents.touchUpInside)
        view.addSubview(closeButton)
        
        if showDownloadButton {
            downloadButton.setImage(UIImage(named: "download_white", in: .module, compatibleWith: nil), for: UIControlState())
            downloadButton.addTarget(self, action: #selector(FullScreenSlideshowViewController.download), for: UIControlEvents.touchUpInside)
            view.addSubview(downloadButton)
        }
        
        let gesture = UITapGestureRecognizer(target: self, action:  #selector (FullScreenSlideshowViewController.close))
        view.addGestureRecognizer(gesture)
    }

    override open var prefersStatusBarHidden: Bool {
        return true
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if isInit {
            isInit = false
            slideshow.setCurrentPage(initialPage, animated: false)
        }
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        slideshow.slideshowItems.forEach { $0.cancelPendingLoad() }

        // Prevents broken dismiss transition when image is zoomed in
        slideshow.currentSlideshowItem?.zoomOut()
    }

    open override func viewDidLayoutSubviews() {
        if !isBeingDismissed {
            let safeAreaInsets: UIEdgeInsets
            if #available(iOS 11.0, *) {
                safeAreaInsets = view.safeAreaInsets
            } else {
                safeAreaInsets = UIEdgeInsets.zero
            }

            closeButton.frame = closeButtonFrame ?? CGRect(x: max(15, safeAreaInsets.left), y: max(15, safeAreaInsets.top), width: 40, height: 40)
            if showDownloadButton {
                downloadButton.frame = CGRect(x: view.bounds.width - max(15, safeAreaInsets.left) - 40, y: max(15, safeAreaInsets.top), width: 40, height: 40)
            }
        }

        slideshow.frame = view.frame
    }

    func close() {
        // if pageSelected closure set, send call it with current page
        if let pageSelected = pageSelected {
            pageSelected(slideshow.currentPage)
        }

        dismiss(animated: true, completion: nil)
    }
    
    func download() {
        if showDownloadButton, let inputs = inputs, let imageSource: ImageSource = inputs[slideshow.currentPage] as? ImageSource {
            UIImageWriteToSavedPhotosAlbum(imageSource.image, self, #selector(imageSaved(image:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    func imageSaved(image: UIImage!, didFinishSavingWithError error: NSError?, contextInfo: AnyObject?) {
        if (error != nil) {
            print("error")
        } else {
            self.showToast(message: self.downloadSuccessMessage, font: .systemFont(ofSize: 16.0))
        }
    }
    
    
    func showToast(message : String, font: UIFont) {
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width / 2 - 75, y: self.view.frame.size.height, width: 150, height: 36))
        toastLabel.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        toastLabel.textColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
        toastLabel.font = font
        toastLabel.textAlignment = .center;
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        
        var showFrame: CGRect = toastLabel.frame;
        showFrame.origin.y = self.view.frame.size.height - 130;
        
        var hideFrame: CGRect = toastLabel.frame;
        hideFrame.origin.y = self.view.frame.size.height;
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
             toastLabel.frame = showFrame
        }, completion: {(isCompleted) in
            UIView.animate(withDuration: 0.3, delay: 1.5, options: .curveEaseOut, animations: {
                toastLabel.frame = hideFrame
            }, completion: {(isCompleted) in
                toastLabel.removeFromSuperview()
            })
        })
    }
}
