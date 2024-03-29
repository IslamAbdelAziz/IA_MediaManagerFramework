//
//  MediaManager.swift
//  IA_MediaManagerFramework
//
//  Created by iSlam on 10/16/19.
//  Copyright © 2019 iSlamAbdel-Aziz. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices
import AVFoundation
import Photos


enum iA_MediaType: String{
    case camera, video, photoLibrary
}


enum MM_Strings: String {
    case MM_actionSheetTitle = "Add Media?"
    case MM_actionSheetDescription = "Choose Media Resource"
    case camera = "Camera"
    case photoLibrary = "Phote Library"
    case video = "Video"
    case file = "File"
    
    
    case MM_accessDenied = "Doesn't have access to resource, Go to Settings and enable permission"
    
    case settingsBtnTitle = "Open Settings"
    case cancelBtnTitle = "Cancel"
    
}


public class IAMediaManager: NSObject{
    
    static public let shared = IAMediaManager()
    var currentVC: UIViewController?
    
    var imageHandlerBlock: ((UIImage) -> Void)?
    var videoHandlerBlock: ((NSURL) -> Void)?
    var fileHandlerBlock: ((URL) -> Void)?
    
    var AppName = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String
    
    
    public func addMedia(vc: UIViewController, getPhotos: Bool = true, getVideos: Bool = true, getFiles: Bool = true, getCamera: Bool = true){
        
        currentVC = vc
        
        let alert = UIAlertController(title: MM_Strings.MM_actionSheetTitle.rawValue, message: MM_Strings.MM_actionSheetDescription.rawValue, preferredStyle: .actionSheet)
        let actionCamera = UIAlertAction(title: MM_Strings.camera.rawValue, style: .default) { (_) in
            self.checkAuthorizationState(iA_MediaTypeEnum: .camera)
        }
        let actionPhotoLibrary = UIAlertAction(title: MM_Strings.photoLibrary.rawValue, style: .default) { (_) in
            self.checkAuthorizationState(iA_MediaTypeEnum: .photoLibrary)
        }
        let actionVideo = UIAlertAction(title: MM_Strings.video.rawValue, style: .default) { (_) in
            self.checkAuthorizationState(iA_MediaTypeEnum: .video)
        }

        let actionFile = UIAlertAction(title: MM_Strings.file.rawValue, style: .default) { (_) in
            self.files()
            
        }
        let actionCancel = UIAlertAction(title: MM_Strings.cancelBtnTitle.rawValue, style: .cancel) { (_) in
            
        }
        if getCamera{ alert.addAction(actionCamera) }
        if getPhotos{ alert.addAction(actionPhotoLibrary) }
        if getVideos{ alert.addAction(actionVideo) }
        if getFiles{ alert.addAction(actionFile) }
        alert.addAction(actionCancel)
        currentVC?.present(alert, animated: true, completion: nil)
        
    }
    
    
    func checkAuthorizationState(iA_MediaTypeEnum: iA_MediaType){
        if iA_MediaTypeEnum ==  iA_MediaType.camera{
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            switch status{
            case .authorized: // The user has previously granted access to the camera.
                openCamera()
                
            case .notDetermined: // The user has not yet been asked for camera access.
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        self.openCamera()
                    }
                }
                //denied - The user has previously denied access.
            //restricted - The user can't grant access due to restrictions.
            case .denied, .restricted:
                showAccessDeniedAlert()
                return
                
            default:
                break
            }
        }else if iA_MediaTypeEnum == iA_MediaType.photoLibrary || iA_MediaTypeEnum == iA_MediaType.video{
            let status = PHPhotoLibrary.authorizationStatus()
            switch status{
            case .authorized:
                if iA_MediaTypeEnum == iA_MediaType.photoLibrary{
                    photoLibrary()
                }
                if iA_MediaTypeEnum == iA_MediaType.video{
                    videoLibrary()
                }

            case .denied, .restricted:
                showAccessDeniedAlert()
                
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization({ (status) in
                    if status == PHAuthorizationStatus.authorized{
                        // photo library access given
                        
                        if iA_MediaTypeEnum == iA_MediaType.photoLibrary{
                            self.photoLibrary()
                        }
                        if iA_MediaTypeEnum == iA_MediaType.video{
                            self.videoLibrary()
                        }
                    }
                })
            default:
                break
            }
        }
    }
    
    
    
    func openCamera(){
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            let myPickerController = UIImagePickerController()
                myPickerController.delegate = self
                myPickerController.sourceType = .camera
                currentVC?.present(myPickerController, animated: true, completion: nil)
        }
    }
    
    
    func photoLibrary(){
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            let myPickerController = UIImagePickerController()
                myPickerController.delegate = self
                myPickerController.sourceType = .photoLibrary
                currentVC?.present(myPickerController, animated: true, completion: nil)
        }
    }

    func videoLibrary(){
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            let myPickerController = UIImagePickerController()
            myPickerController.delegate = self
            myPickerController.sourceType = .photoLibrary
            myPickerController.mediaTypes = [kUTTypeMovie as String, kUTTypeVideo as String]
            currentVC?.present(myPickerController, animated: true, completion: nil)
        }
    }
    
    func files(){
        let importMenu = UIDocumentPickerViewController(documentTypes: [String(kUTTypePDF)], in: .import)
        importMenu.delegate = self
        importMenu.modalPresentationStyle = .formSheet
        currentVC?.present(importMenu, animated: true, completion: nil)
    }
    
    
    func showAccessDeniedAlert(){
        let alertVC = UIAlertController(title:  "Access Denied", message: "\(AppName ?? "App") \(MM_Strings.MM_accessDenied.rawValue)", preferredStyle: .alert)
        let ok = UIAlertAction(title: MM_Strings.settingsBtnTitle.rawValue, style: .default, handler: { (alertAction) in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                })
            }
        })
        let cancel = UIAlertAction(title: MM_Strings.cancelBtnTitle.rawValue, style: .cancel, handler: nil)
        alertVC.addAction(ok)
        alertVC.addAction(cancel)
        currentVC?.present(alertVC, animated: true, completion: nil)
        
    }

}


extension IAMediaManager: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        currentVC?.dismiss(animated: true, completion: nil)
    }
    
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            self.imageHandlerBlock?(image)
        } else{
            print("Something went wrong in  image")
        }
        
        if let videoUrl = info[.mediaURL] as? NSURL{
            print("videourl: ", videoUrl)
            //trying compression of video
            let data = NSData(contentsOf: videoUrl as URL)!
            print("File size before compression: \(Double(data.length / 1048576)) mb")
            self.videoHandlerBlock?(videoUrl)
        }
        else{
            print("Something went wrong in  video")
        }
        currentVC?.dismiss(animated: true, completion: nil)
    }
    
    
    
}


extension IAMediaManager: UIDocumentPickerDelegate{
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first{
            self.fileHandlerBlock?(url)
        }
    }
}

