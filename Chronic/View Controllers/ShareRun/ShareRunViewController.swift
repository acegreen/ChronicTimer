//
//  ShareRunUI.swift
//  OMRunApp
//
//  Created by Ace Green on 2017-01-09.
//  Copyright © 2017 OMsignal. All rights reserved.
//

import Foundation
import UIKit

class ShareRunViewController:
    UIViewController,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate {
    
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet var shareCardView: ShareCardView!
    @IBOutlet var shareButton: UIButton!
    
    enum ShareMethod {
        case WithPhoto
        case WithPie
    }
    
    var removePhotoButtton: UIButton!
    
    var selfieImageView: UIImageView!
    let placeholderImage = UIImage(named: "share_placeholder")
    
    var takePhotoButtton: UIButton!
    var photoLibraryButtton: UIButton!
    
    var shareCardGradientView: UIView!
    var topShaderView: UIView!
    var bottomShaderView: UIView!
    
    var didApplyShades = false
    
    let picker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initRemovePhotoButton()
        initWorkoutPie()
        initSelfiePhoto()
    }
    
    func refreshWithl(workout: Workout) {
        
//        self.shareCard.distanceValueLabel.text = distanceViewModel.distanceValue
//        self.shareCard.distanceUnitLabel.text = distanceViewModel.distanceUnit
//        
//        self.shareCard.avgPaceValueLabel.text = paceViewModel.paceValue
//        self.shareCard.avgPaceUnitLabel.text = paceViewModel.paceUnit
//        
//        self.shareCard.totalTimeValueLabel.text = durationViewModel.duration
//        
//        self.updateSmartZonePie(smartZoneDistribution)
//        
//        self.shareCard.rhythmicValueLabel.text = "\(breathingRhythmViewModal.rhytmicPercent)"
//        self.shareCard.rhythmicUnitLabel.text = "%"
//        
//        self.shareCard.hrValueLabel.text = "\(heartRate)"
//
//        self.shareCard.caloriesValueLabel.text = "\(numberOfCalories)"
    }
    
    func initRemovePhotoButton() {
        
        removePhotoButtton = UIButton(type: .custom)
        removePhotoButtton.setTitle("Remove Photo", for: .normal)
        removePhotoButtton.setTitleColor(Constants.chronicColor, for: .normal)
        removePhotoButtton.setImage(UIImage(named: "Share_Remove"), for: .normal)
        removePhotoButtton.titleLabel!.font = Constants.ChronicFonts.regular
        removePhotoButtton.contentEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 10)
        removePhotoButtton.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0)
        removePhotoButtton.layer.cornerRadius = 5
        removePhotoButtton.layer.borderColor = Constants.chronicColor.cgColor
        removePhotoButtton.layer.borderWidth = 1
        removePhotoButtton.addTarget(self, action: #selector(removePhotoButtonPressed(sender:)), for: .touchUpInside)
        removePhotoButtton.isHidden = true
        self.view.addSubview(removePhotoButtton)
        removePhotoButtton.autoSetDimension(.width, toSize: 110)
        removePhotoButtton.autoPinEdge(.top, to: .bottom, of: self.segmentedControl, withOffset: 20)
        removePhotoButtton.autoPinEdge(toSuperviewEdge: .right, withInset: 20)
    }
    
    func initSelfiePhoto() {
        
        selfieImageView = UIImageView(forAutoLayout: ())
        selfieImageView.image = placeholderImage
        selfieImageView.isHidden = true
        selfieImageView.clipsToBounds = true
        selfieImageView.contentMode = .scaleAspectFill
        shareCardView.addSubview(selfieImageView)
        shareCardView.sendSubview(toBack: selfieImageView)
        selfieImageView.autoPinEdge(toSuperviewEdge: .left)
        selfieImageView.autoPinEdge(toSuperviewEdge: .right)
        selfieImageView.autoPinEdge(.top, to: .bottom, of: self.removePhotoButtton, withOffset: 10)
        selfieImageView.autoMatch(.height, to: .width, of: view)
    }
    
    func initImageSelectorButtons() {
        
        photoLibraryButtton = UIButton(forAutoLayout: ())
        photoLibraryButtton.setTitle("Photo Library", for: .normal)
        photoLibraryButtton.setImage(UIImage(named: "Library_Share"), for: .normal)
        photoLibraryButtton.titleLabel!.font = Constants.ChronicFonts.regular
        photoLibraryButtton.titleLabel!.minimumScaleFactor = 0.5
        photoLibraryButtton.contentHorizontalAlignment = .left
        photoLibraryButtton.contentEdgeInsets = UIEdgeInsetsMake(10, 20, 10, 20)
        photoLibraryButtton.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0)
        photoLibraryButtton.layer.cornerRadius = 5
        photoLibraryButtton.layer.borderColor = UIColor.white.cgColor
        photoLibraryButtton.layer.borderWidth = 1
        photoLibraryButtton.addTarget(self, action: #selector(photofromLibraryButtonPressed(sender:)), for: .touchUpInside)
        view.addSubview(photoLibraryButtton)
        photoLibraryButtton.autoSetDimension(.width, toSize: 200)
        photoLibraryButtton.autoAlignAxis(.horizontal, toSameAxisOf: shareCardView, withOffset: -60)
        photoLibraryButtton.autoAlignAxis(.vertical, toSameAxisOf: shareCardView, withOffset: 0)
        
        takePhotoButtton = UIButton(forAutoLayout: ())
        takePhotoButtton.setTitle("Take Photo", for: .normal)
        takePhotoButtton.setImage(UIImage(named: "Photo_Share"), for: .normal)
        takePhotoButtton.titleLabel!.font = Constants.ChronicFonts.regular
        takePhotoButtton.titleLabel!.minimumScaleFactor = 0.5
        takePhotoButtton.contentHorizontalAlignment = .left
        takePhotoButtton.contentEdgeInsets = UIEdgeInsetsMake(10, 20, 10, 20)
        takePhotoButtton.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0)
        takePhotoButtton.layer.cornerRadius = 5
        takePhotoButtton.layer.borderColor = UIColor.white.cgColor
        takePhotoButtton.layer.borderWidth = 1
        takePhotoButtton.addTarget(self, action: #selector(takePhotoButtonPressed(sender:)), for: .touchUpInside)
        view.addSubview(takePhotoButtton)
        takePhotoButtton.autoSetDimension(.width, toSize: 200)
        takePhotoButtton.autoAlignAxis(.horizontal, toSameAxisOf: shareCardView, withOffset: 20)
        takePhotoButtton.autoAlignAxis(.vertical, toSameAxisOf: shareCardView, withOffset: 0)
    }
    
    func initWorkoutPie() {
        
//        let offsetAdjustmentTopBottom: CGFloat = -15
//        
//        let pieChartWidget = pieChartVC.smartZoneWidget
//        pieChartWidgetView = pieChartWidget.view
//        
//        shareCard.addSubview(pieChartWidgetView)
//        pieChartWidgetView.autoPinEdge(.Left, toEdge: .Left, ofView: shareCard)
//        pieChartWidgetView.autoPinEdge(.Right, toEdge: .Right, ofView: shareCard)
//        pieChartWidgetView.autoPinEdge(.Top, toEdge: .Top, ofView: shareCard, withOffset: offsetAdjustmentTopBottom)
//        pieChartWidgetView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: shareCard)
    }
    
    func removeImageSelectorButtons() {
        
        if takePhotoButtton != nil && takePhotoButtton.isDescendant(of: view) {
            takePhotoButtton.removeFromSuperview()
        }
        
        if photoLibraryButtton != nil && photoLibraryButtton.isDescendant(of: view) {
            photoLibraryButtton.removeFromSuperview()
        }
    }
    
    func setupPieUI() {
        
        pieChartWidgetView.isHidden = false
        selfieImageView.isHidden = true
        removeShades()
        shareButton.isEnabled = true
        
        removeImageSelectorButtons()
        removePhotoButtton.isHidden = true
    }
    
    func setupPhotoUI() {
        
        pieChartWidgetView.isHidden = true
        selfieImageView.isHidden = false
        
        if selfieImageView.image == nil || selfieImageView.image == placeholderImage {
            initImageSelectorButtons()
            shareButton.isEnabled = false
        } else {
            removeBackgroundGradient()
            applyshades()
            removePhotoButtton.isHidden = false
            shareButton.isEnabled = true
        }
    }
    
    func selectedMethod() -> ShareMethod {
        
        let smartZonesSegmentedControlIndex = 0
        let photoSegmentedControlIndex = 1
        
        switch(self.segmentedControl.selectedSegmentIndex) {
        case smartZonesSegmentedControlIndex:
            return .WithPie
        case photoSegmentedControlIndex:
            return .WithPhoto
        default:
            return .WithPie
        }
    }
    
    func segmentedControlValueDidChange(sender: UISegmentedControl) {
        
        switch(self.selectedMethod()) {
        case .WithPie: setupPieUI()
        case .WithPhoto: setupPhotoUI()
        }
    }
    
    func removePhotoButtonPressed(sender: UIButton) {
        
        guard selfieImageView.image != nil || selfieImageView.image != placeholderImage else {
            return
        }
        
        selfieImageView.image = placeholderImage
        removeShades()
        initImageSelectorButtons()
        removePhotoButtton.isHidden = true
        shareButton.isEnabled = false
    }
    
    //MARK: Image Picker Functions
    
    func takePhotoButtonPressed(sender: UIButton) {
        
        // assign image picker delegate
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = UIImagePickerControllerSourceType.camera
        picker.cameraCaptureMode = .photo
        picker.modalPresentationStyle = .fullScreen
        present(picker, animated: true, completion: nil)
    }
    
    func photofromLibraryButtonPressed(sender: UIButton) {
    
        // assign image picker delegate
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }
    
    func shareButtonPressed(sender: UIButton) {
        guard let imageToShare = shareCardView.takeSnapshot() else { return }
        let textToShare = ""
        
        presentActivityViewController(with: textToShare, and: imageToShare)
    }
    
    func presentActivityViewController(with text: String, and image: UIImage) {
        
        var objectsToShare = [AnyObject]()
        objectsToShare.append(text as AnyObject)
        objectsToShare.append(image)

        
//        let excludedActivityTypesArray = [
//            UIActivityType.PostToWeibo,
//            UIActivityType.AssignToContact,
//            UIActivityType.AirDrop,
//            ]
        
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
//        activityVC.excludedActivityTypes = excludedActivityTypesArray
        
//        activityVC.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.Up
//        activityVC.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
        
        present(activityVC, animated: true, completion: nil)
        
        activityVC.completionWithItemsHandler = { (activity, success, items, error) in
            if success {
                print("activityName: activity")
            }
        }
    }

    //MARK: Image Picker Delegates
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        selfieImageView.contentMode = .scaleAspectFill
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            applyImageToView(image: image)
        } else if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            applyImageToView(image: image)
        } else {
            print("Something went wrong with image picker")
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: View Mods
    
    func applyImageToView(image: UIImage) {
        selfieImageView.image = image
        removeBackgroundGradient()
        applyshades()
        removeImageSelectorButtons()
        removePhotoButtton.isHidden = false
        shareButton.isEnabled = true
    }
    
    func removeBackgroundGradient() {
        shareCardGradientView.removeFromSuperview()
    }
    
    func applyshades() {
        
        if !didApplyShades {
            topShaderView = shareCardView.applyGradient(Gradients.shareCardTopShader,
                                                        height: shareCardView.topStackView.frame.maxY + 20,
                                                        shouldOffsetStatusbar: false)
            bottomShaderView = shareCardView.applyGradient(Gradients.shareCardBottomShader,
                                                        height: shareCardView.frame.maxY - shareCardView.bottomStackViewSeparatorView.frame.minY + 20,
                                                        withOffset: shareCardView.bottomStackViewSeparatorView.frame.minY - 20,
                                                        shouldOffsetStatusbar: false)
            didApplyShades = true
        }
    }
    
    func removeShades() {
        
        if topShaderView != nil && topShaderView.isDescendant(of: shareCardView) {
            topShaderView.removeFromSuperview()
        }
        
        if bottomShaderView != nil && bottomShaderView.isDescendant(of: shareCardView) {
            bottomShaderView.removeFromSuperview()
        }
        
        didApplyShades = false
    }
}
