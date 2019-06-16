//
//  ShareWorkoutViewController.swift
//  Chronic
//
//  Created by Ace Green on 5/22/16.
//  Copyright © 2016 Ace Green. All rights reserved.
//

import Foundation
import UIKit
import Charts

class ShareWorkoutViewController:
    UIViewController,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate {
    
    @IBAction func segementedControlChangedValue(_ sender: UISegmentedControl) {
        selectedMethod()
        segmentedControlValueDidChange()
    }
    
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet var shareCardView: UIView!
    @IBOutlet var shareButton: UIButton!
    
    enum ShareMethod {
        case WithPhoto
        case WithPie
    }
    
    var shareRoutineReuseableView: ShareRoutineReusableView?
    var shareRunReuseableView: ShareRunReusableView?
    
    var workout: Workout!
    
    var removePhotoButtton: UIButton!
    
    var selfieImageView: UIImageView!
    let placeholderImage = UIImage(named: "share_placeholder")
    
    var takePhotoButtton: UIButton!
    var photoLibraryButtton: UIButton!
    
    var topShaderView: UIView!
    var bottomShaderView: UIView!
    
    var didApplyShades = false
    
    let picker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initRemovePhotoButton()
        initSelfiePhoto()
        
        setupWith(workout: workout)
    }
    
    func setupWith(workout: Workout) {
        
        switch workout.workoutType {
        case .routine, .quickTimer:
            setupRoutineUI()
        case .run:
            setupRunUI()
        }
    }
    
    func initRemovePhotoButton() {
        
        removePhotoButtton = UIButton(type: .custom)
        removePhotoButtton.setTitle("Remove Photo", for: .normal)
        removePhotoButtton.setTitleColor(Constants.CTColors.grey, for: .normal)
        removePhotoButtton.setImage(UIImage(named: "Share_Remove"), for: .normal)
        removePhotoButtton.titleLabel!.font = Constants.CTFonts.regular
        removePhotoButtton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 10)
        removePhotoButtton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        removePhotoButtton.layer.cornerRadius = 5
        removePhotoButtton.layer.borderColor = Constants.CTColors.grey.cgColor
        removePhotoButtton.layer.borderWidth = 1
        removePhotoButtton.addTarget(self, action: #selector(removePhotoButtonPressed(sender:)), for: .touchUpInside)
        removePhotoButtton.isHidden = true
        self.view.addSubview(removePhotoButtton)
        removePhotoButtton.autoSetDimension(.width, toSize: 110)
        removePhotoButtton.autoPinEdge(.top, to: .bottom, of: self.view, withOffset: 20)
        removePhotoButtton.autoPinEdge(toSuperviewEdge: .right, withInset: 20)
    }
    
    func initSelfiePhoto() {
        
        selfieImageView = UIImageView(forAutoLayout: ())
        selfieImageView.image = placeholderImage
        selfieImageView.isHidden = true
        selfieImageView.clipsToBounds = true
        selfieImageView.contentMode = .scaleAspectFill
        shareCardView.addSubview(selfieImageView)
        shareCardView.sendSubviewToBack(selfieImageView)
        selfieImageView.autoPinEdge(toSuperviewEdge: .left)
        selfieImageView.autoPinEdge(toSuperviewEdge: .right)
        selfieImageView.autoPinEdge(.top, to: .bottom, of: self.removePhotoButtton, withOffset: 10)
        selfieImageView.autoMatch(.height, to: .width, of: view)
    }
    
    func initImageSelectorButtons() {
        
        photoLibraryButtton = UIButton(forAutoLayout: ())
        photoLibraryButtton.setTitle("Photo Library", for: .normal)
        photoLibraryButtton.setImage(UIImage(named: "Library_Share"), for: .normal)
        photoLibraryButtton.titleLabel!.font = Constants.CTFonts.regular
        photoLibraryButtton.titleLabel!.minimumScaleFactor = 0.5
        photoLibraryButtton.contentHorizontalAlignment = .left
        photoLibraryButtton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        photoLibraryButtton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
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
        takePhotoButtton.titleLabel!.font = Constants.CTFonts.regular
        takePhotoButtton.titleLabel!.minimumScaleFactor = 0.5
        takePhotoButtton.contentHorizontalAlignment = .left
        takePhotoButtton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        takePhotoButtton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        takePhotoButtton.layer.cornerRadius = 5
        takePhotoButtton.layer.borderColor = UIColor.white.cgColor
        takePhotoButtton.layer.borderWidth = 1
        takePhotoButtton.addTarget(self, action: #selector(takePhotoButtonPressed(sender:)), for: .touchUpInside)
        view.addSubview(takePhotoButtton)
        takePhotoButtton.autoSetDimension(.width, toSize: 200)
        takePhotoButtton.autoAlignAxis(.horizontal, toSameAxisOf: shareCardView, withOffset: 20)
        takePhotoButtton.autoAlignAxis(.vertical, toSameAxisOf: shareCardView, withOffset: 0)
    }
    
    func removeImageSelectorButtons() {
        
        if takePhotoButtton != nil && takePhotoButtton.isDescendant(of: view) {
            takePhotoButtton.removeFromSuperview()
        }
        
        if photoLibraryButtton != nil && photoLibraryButtton.isDescendant(of: view) {
            photoLibraryButtton.removeFromSuperview()
        }
    }
    
    func setupRoutineUI() {
        shareRoutineReuseableView = ShareRoutineReusableView.loadViewFromNib() as? ShareRoutineReusableView
        self.shareCardView.addSubview(shareRoutineReuseableView!)
        shareRoutineReuseableView!.autoPinEdgesToSuperviewEdges()
        
        guard let routineModel = workout.routineModel else { return }
        shareRoutineReuseableView!.configure(with: routineModel)
    }
    
    func setupRunUI() {
        shareRunReuseableView = ShareRunReusableView.loadViewFromNib() as? ShareRunReusableView
        self.shareCardView.addSubview(shareRunReuseableView!)
        shareRunReuseableView!.autoPinEdgesToSuperviewEdges()
        
        shareRunReuseableView!.configure(with: workout)
    }
    
    func setupPieUI() {
        showWorkoutView(hidden: false)
        selfieImageView.isHidden = true
        
        shareCardView.backgroundColor = Constants.CTColors.grey
        removeShades()
        shareButton.isEnabled = true
        
        removeImageSelectorButtons()
        removePhotoButtton.isHidden = true
    }
    
    func setupPhotoUI() {
        showWorkoutView(hidden: true)
        selfieImageView.isHidden = false
        
        shareCardView.backgroundColor = UIColor.clear
        
        if selfieImageView.image == nil || selfieImageView.image == placeholderImage {
            initImageSelectorButtons()
            shareButton.isEnabled = false
        } else {
            applyshades()
            removePhotoButtton.isHidden = false
            shareButton.isEnabled = true
        }
    }
    
    func showWorkoutView(hidden: Bool) {
        
    }
    
    func selectedMethod() -> ShareMethod {
        
        switch(self.segmentedControl.selectedSegmentIndex) {
        case 0:
            return .WithPie
        case 1:
            return .WithPhoto
        default:
            return .WithPie
        }
    }
    
    func segmentedControlValueDidChange() {
        
        switch(self.selectedMethod()) {
        case .WithPie: setupPieUI()
        case .WithPhoto: setupPhotoUI()
        }
    }
    
    @objc func removePhotoButtonPressed(sender: UIButton) {
        
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
    
    @objc func takePhotoButtonPressed(sender: UIButton) {
        
        // assign image picker delegate
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = UIImagePickerController.SourceType.camera
        picker.cameraCaptureMode = .photo
        picker.modalPresentationStyle = .fullScreen
        present(picker, animated: true, completion: nil)
    }
    
    @objc func photofromLibraryButtonPressed(sender: UIButton) {
    
        // assign image picker delegate
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }
    
    func shareButtonPressed(sender: UIButton) {
        guard let imageToShare = UIImage(named: "ASS") else { return }
            //shareCardView.takeSnapshot() else { return }
        let textToShare = ""
        
        presentActivityViewController(with: textToShare, and: imageToShare)
    }
    
    func presentActivityViewController(with text: String, and image: UIImage) {
        
        var objectsToShare = [AnyObject]()
        objectsToShare.append(text as AnyObject)
        objectsToShare.append(image)

        
//        let excludedActivityTypesArray = [
//            UIActivity.ActivityType.PostToWeibo,
//            UIActivity.ActivityType.AssignToContact,
//            UIActivity.ActivityType.AirDrop,
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
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        selfieImageView.contentMode = .scaleAspectFill
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            applyImageToView(image: image)
        } else if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
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
        applyshades()
        removeImageSelectorButtons()
        removePhotoButtton.isHidden = false
        shareButton.isEnabled = true
    }
    
    func applyshades() {
        
        if !didApplyShades {
//            topShaderView = shareCardView.applyGradient(Gradients.shareCardTopShader,
//                                                        height: shareCardView.topStackView.frame.maxY + 20,
//                                                        shouldOffsetStatusbar: false)
//            bottomShaderView = shareCardView.applyGradient(Gradients.shareCardBottomShader,
//                                                        height: shareCardView.frame.maxY - shareCardView.bottomStackViewSeparatorView.frame.minY + 20,
//                                                        withOffset: shareCardView.bottomStackViewSeparatorView.frame.minY - 20,
//                                                        shouldOffsetStatusbar: false)
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
