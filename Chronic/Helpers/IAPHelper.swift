//
//  IAPHelper.swift
//  Chronic
//
//  Created by Ace Green on 2015-11-13.
//  Copyright © 2015 Ace Green. All rights reserved.
//

import Foundation
import UIKit
import StoreKit
//import CNPPopupController
import Crashlytics
import Parse
import SwiftyJSON

class IAPHelper: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver, SKRequestDelegate {
    
    static let sharedInstance = IAPHelper()

    var completionHandler:((Bool) -> Void)?
    
    var request: SKProductsRequest!
    var list = [SKProduct]()
    var p = SKProduct()
    var productsArray = [Constants.iapUltimatePackageKey, Constants.proVersionKey, Constants.removeAdsKey, Constants.donate99Key]
    
    //var inAppPurchasePopupController: CNPPopupController!
    var sweetAlertRestorePurchases = SweetAlert()
    
    override init() {
        
        super.init()
        _ = SKPaymentQueue.default().add(self)
    }
    
    func requestProductsWithCompletionHandler(_ handler:((Bool) -> Void)) {
        
        guard Functions.isConnectedToNetwork() else {
            
            DispatchQueue.main.async(execute: { () -> Void in
                SweetAlert().showAlert(NSLocalizedString("Alert: Requires Upgrade Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Requires Upgrade Subtitle Text", comment: ""), style: AlertStyle.warning)
            })
            return
        }
        
        self.completionHandler = handler
        if SKPaymentQueue.canMakePayments() {
            
            print("IAP is enabled, loading")
            
            let productIDs: Set = Set(productsArray)
            
            request = SKProductsRequest(productIdentifiers: productIDs)
            request.delegate = self
            request.start()
            
        } else {
            
            DispatchQueue.main.async(execute: { () -> Void in
                SweetAlert().showAlert(NSLocalizedString("Alert: In-App Purchases Disabled Title Text", comment: ""), subTitle: NSLocalizedString("Alert: In-App Purchases Disabled Subtitle Text", comment: ""), style: AlertStyle.error)
            })
        }
    }
    
    // MARK: - Payment Processing
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        
        print("Product Request")
        let myProducts = response.products
        
        list.removeAll()
        
        for product in productsArray {
            for myProduct in myProducts {
                if myProduct.productIdentifier == product {
                    list.append(myProduct)
                }
            }
        }
        
        self.completionHandler?(true)
        completionHandler = nil
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
//        if inAppPurchasePopupController != nil {
//            
//            inAppPurchasePopupController.dismiss(animated: true)
//        }
        
        for transaction:SKPaymentTransaction in transactions {
            
            let productID = transaction.payment.productIdentifier
            let productPrice = p.price
            let formatter = NumberFormatter()
            formatter.locale = p.priceLocale
            let productCurrency = formatter.currencyCode
            
            switch transaction.transactionState {
                
            case .purchasing:
                
                print("purchasing")
                
            case .purchased, .restored:
                
                verifyReceipt({ (receiptTransactionsArray, environment) -> Void in
                    
                    if let receiptTransactionsArray = receiptTransactionsArray {
                        
                        self.validateTransaction(transaction, receiptTransactionsArray: receiptTransactionsArray, completionHandler: { (success, receiptTransactionArray) -> Void in
                            
                            if success {
                                
                                //                        let product_id = receiptTransactionArray!["product_id"]
                                //                        let quantity = receiptTransactionArray!["quantity"]
                                let transactionID = receiptTransactionArray!["transaction_id"]
                                //                        let originalTransactionID = receiptTransactionArray!["original_transaction_id"]
                                //                        let purchaseDate = receiptTransactionArray!["purchase_date"]
                                //                        let originalPurchaseDate = receiptTransactionArray!["purchase_date"]
                                
                                let transactionTransactionID = transaction.transactionIdentifier! as String
                                let transactionProductID = transaction.payment.productIdentifier as String
                                
                                switch transactionProductID {

                                case Constants.iapUltimatePackageKey:
                                    
                                    print("\(transaction.transactionState) - ultimate")
                                    self.proVersionPurchased()
                                    self.removeAdsPurchased()
                                    
                                    if transactionID.string  == transactionTransactionID && environment != "Sandbox" {
                                        
                                        // log Ultimate Package purchase
                                        Answers.logPurchase(withPrice: productPrice,
                                            currency: productCurrency,
                                            success: true,
                                            itemName: "Ultimate Package",
                                            itemType: "In-App Purchase",
                                            itemId: "\(transaction.transactionIdentifier!)",
                                            customAttributes: ["Installation ID":PFInstallation.current()?.installationId ?? "", "App Version": Constants.AppVersion, "Transaction Date": transaction.transactionDate!])
                                    }
                                    
                                    break
                                    
                                case Constants.proVersionKey:
                                    
                                    print("\(transaction.transactionState) - pro version")
                                    self.proVersionPurchased()
                                    
                                    if transactionID.string  == transactionTransactionID && environment != "Sandbox" {
                                        
                                        // log pro purchase
                                        Answers.logPurchase(withPrice: productPrice,
                                            currency: productCurrency,
                                            success: true,
                                            itemName: "Pro Version",
                                            itemType: "In-App Purchase",
                                            itemId: "\(transaction.transactionIdentifier!)",
                                            customAttributes: ["Installation ID":PFInstallation.current()?.installationId ?? "", "App Version": Constants.AppVersion, "Transaction Date": transaction.transactionDate!])
                                    }
                                    
                                    break
                                    
                                case Constants.removeAdsKey:
                                    
                                    print("\(transaction.transactionState) - remove ads")
                                    self.removeAdsPurchased()
                                    
                                    if transactionID.string == transactionTransactionID && environment != "Sandbox" {
                                        
                                        // log remove ads purchase
                                        Answers.logPurchase(withPrice: productPrice,
                                            currency: productCurrency,
                                            success: true,
                                            itemName: "Remove Ads",
                                            itemType: "In-App Purchase",
                                            itemId: "\(transaction.transactionIdentifier!)",
                                            customAttributes: ["Installation ID":PFInstallation.current()?.installationId ?? "", "App Version": Constants.AppVersion, "Transaction Date": transaction.transactionDate!])
                                    }
                                    
                                    break
                                    
                                case Constants.donate99Key:
                                    
                                    print("\(transaction.transactionState) - donate")
                                    
                                    if transactionID.string  == transactionTransactionID && environment != "Sandbox" {
                                        
                                        // log donation purchase
                                        Answers.logPurchase(withPrice: productPrice,
                                            currency: productCurrency,
                                            success: true,
                                            itemName: "Donation",
                                            itemType: "In-App Purchase (Consumable)",
                                            itemId: "\(transaction.transactionIdentifier!)",
                                            customAttributes: ["Installation ID":PFInstallation.current()?.installationId ?? "", "App Version": Constants.AppVersion, "Transaction Date": transaction.transactionDate!])
                                    }
                                    
                                    break
                                    
                                default:
                                    
                                    print("productID not found")
                                    
                                }
                                
                            } else {
                                
                                self.displayValidationError()
                            }
                            
                        })

                    } else {
                        
                        self.displayValidationError()
                    }
                    
                    queue.finishTransaction(transaction)
                })
                break
                
            case .failed:
                
                var errorMessage = ""
                
                switch (transaction.error as? SKError)!.code {
                case .unknown:
                    errorMessage = "Unknown error"
                    break
                case .clientInvalid:
                    errorMessage = "Client Not Allowed To issue Request"
                    break
                case .paymentCancelled:
                    errorMessage = "User Cancelled Request"
                    break
                case .paymentInvalid:
                    errorMessage = "Purchase Identifier Invalid"
                    break
                case .paymentNotAllowed:
                    errorMessage = "Device Not Allowed To Make Payment"
                    break
                default:
                    break
                }
                
                DispatchQueue.main.async(execute: { () -> Void in
                    SweetAlert().showAlert(NSLocalizedString("Failed", comment: ""), subTitle: errorMessage, style: AlertStyle.error)
                })
                
                Answers.logPurchase(withPrice: nil,
                    currency: nil,
                    success: false,
                    itemName: nil,
                    itemType: nil,
                    itemId: nil,
                    customAttributes: ["Installation ID":PFInstallation.current()?.installationId ?? "", "Error": errorMessage, "App Version": Constants.AppVersion])
                
                print(errorMessage)
                
                queue.finishTransaction(transaction)
                break
                
            default:
                
                queue.finishTransaction(transaction)
                print("default")
                break
                
            }
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        
        print("removed transactions")
        
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        
        print("transactions restored")
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.sweetAlertRestorePurchases.closeAlertDismissButton()
            SweetAlert().showAlert(NSLocalizedString("Success", comment: ""), subTitle: NSLocalizedString("Alert: Restore Success Subtitle Text", comment: ""), style: AlertStyle.success)
        })
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: NSError) {
        
        print("restore transactions failed")
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.sweetAlertRestorePurchases.closeAlertDismissButton()
            SweetAlert().showAlert(NSLocalizedString("Failed", comment: ""), subTitle: error.localizedDescription, style: AlertStyle.error)
        })
        
//        // log restore failed
//        Answers.logPurchaseWithPrice(nil,
//            currency: nil,
//            success: false,
//            itemName: "Restore Failed",
//            itemType: "Restore",
//            itemId: nil,
//            customAttributes: ["Installation ID":PFInstallation.currentInstallation().installationId])
    }
    
    //MARK: SKRequestDelegate methods
    
    func requestDidFinish(_ request: SKRequest) {
        
        print("request did finish")
        let fileExists = FileManager.default.fileExists(atPath: Constants.receiptURL!.path)
        
        if fileExists {
            print("Appstore Receipt now exists")
            return
        }
        
        print("something went wrong while obtaining the receipt, maybe the user did not successfully enter it's credentials")
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        
        DispatchQueue.main.async(execute: { () -> Void in
            SweetAlert().showAlert(NSLocalizedString("Alert: Purchase Request Failed Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Purchase Request Failed Subtitle Text", comment: ""), style: AlertStyle.warning)
        })
        
        print("request did fail with error: \(error.localizedDescription)")
    }
    
//    func selectProduct(_ productID: String) {
//        
//        guard Functions.isConnectedToNetwork() else {
//            
//            DispatchQueue.main.async(execute: { () -> Void in
//                SweetAlert().showAlert(NSLocalizedString("Alert: Requires Upgrade Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Requires Upgrade Subtitle Text", comment: ""), style: AlertStyle.warning)
//            })
//            return
//        }
//        
//        DispatchQueue.main.async(execute: { () -> Void in
//            self.sweetAlertLoadingPurchase.showAlert(NSLocalizedString("Alert: Loading Purchase Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Loading Purchase Subtitle Text", comment: ""), style: AlertStyle.activityIndicator, dismissTime: nil)
//        })
//        
//        self.requestProductsWithCompletionHandler { (success) -> Void in
//            
//            DispatchQueue.main.async(execute: { () -> Void in
//                self.sweetAlertLoadingPurchase.closeAlertDismissButton()
//            })
//            
//            if success {
//                
//                for product in self.list {
//                    
//                    if product.productIdentifier == productID {
//                        
//                        self.p = product
//                        self.displayCustomAlert(self.p.localizedTitle, lineTwo: self.p.localizedPrice(), lineThree: "\(self.p.localizedDescription)", image: nil, popupStyle: CNPPopupStyle.centered)
//                        break
//                    }
//                }
//            }
//        }
//    }
    
    func buyProduct(product: SKProduct) {
        
        print("buy " + product.productIdentifier)
        
        self.p = product
        
        let pay = SKPayment(product: product)
        _ = SKPaymentQueue.default().add(pay as SKPayment)
        
    }
    
    func finishTransaction(_ trans: SKPaymentTransaction) {
        
        print("finish transaction")
        
    }
    
    func removeAdsPurchased() {
        
        // Set KeyChain Value
        do {
            try Constants.keychain
                .accessibility(.always)
                .synchronizable(true)
                .set(value: Constants.removeAdsKeyValue, key: Constants.removeAdsKey)
        } catch let error {
            print("error: \(error)")
        }
        
        Constants.keychainRemoveAdsString  = Constants.keychain[Constants.removeAdsKey]
    }
    
    func proVersionPurchased() {
        
        // send context to Watch if iOS9
        if Constants.wcSession != nil {
            Functions.sendContextToAppleWatch(["contextType":"PurchasedProVersion"])
        }
        
        // Set KeyChain Value
        do {
            try Constants.keychain
                .accessibility(.always)
                .synchronizable(true)
                .set(value: Constants.proVersionKeyValue, key: Constants.proVersionKey)
        } catch let error {
            print("error: \(error)")
        }
        
        Constants.keychainProVersionString = Constants.keychain[Constants.proVersionKey]
    }
    
    func restorePurchases() {
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.sweetAlertRestorePurchases.showAlert(NSLocalizedString("Alert: Restoring Purchase Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Restoring Purchase Subtitle Text", comment: ""), style: AlertStyle.activityIndicator, dismissTime: nil)
        })
        
        _ = SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    // Custom Alert Functions
    
//    func displayCustomAlert (_ lineOne: String, lineTwo: String, lineThree:String, image: UIImage?, popupStyle: CNPPopupStyle) {
//        
//        var contents:[AnyObject] = []
//        
//        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
//        paragraphStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
//        paragraphStyle.alignment = NSTextAlignment.center
//        
//        let attributedLineOne: NSAttributedString = NSAttributedString(string: lineOne, attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 24), NSParagraphStyleAttributeName: paragraphStyle])
//        
//        let attributedLineTwo: NSAttributedString = NSAttributedString(string: lineTwo, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 20), NSParagraphStyleAttributeName: paragraphStyle])
//        
//        let attributedLineThree: NSAttributedString = NSAttributedString(string: lineThree, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 18), NSParagraphStyleAttributeName: paragraphStyle])
//        
//        let lineOneLabel: UILabel = UILabel()
//        lineOneLabel.numberOfLines = 0
//        lineOneLabel.attributedText = attributedLineOne
//        contents.append(lineOneLabel)
//        
//        let lineTwoLabel: UILabel = UILabel()
//        lineTwoLabel.numberOfLines = 0
//        lineTwoLabel.attributedText = attributedLineTwo
//        contents.append(lineTwoLabel)
//        
//        let lineThreeLabel: UILabel = UILabel()
//        lineThreeLabel.numberOfLines = 0
//        lineThreeLabel.attributedText = attributedLineThree
//        contents.append(lineThreeLabel)
//        
//        if image != nil {
//            
//            let imageView: UIImageView = UIImageView(image: image)
//            contents.append(imageView)
//        }
//        
//        let purchaseButton: CNPPopupButton = CNPPopupButton(type: UIButtonType.system)
//        purchaseButton.setTitleColor(UIColor.white, for: UIControlState.normal)
//        purchaseButton.setTitleColor(UIColor.lightGray, for: UIControlState.highlighted)
//        purchaseButton.titleLabel?.font =  UIFont.boldSystemFont(ofSize: 20)
//        purchaseButton.setTitle("Purchase", for: UIControlState.normal)
//        purchaseButton.backgroundColor = UIColor.green
//        purchaseButton.layer.cornerRadius = 4
//        purchaseButton.addTarget(self, action: #selector(IAPHelper.buyProduct), for: UIControlEvents.touchUpInside)
//        contents.append(purchaseButton)
//        
//        inAppPurchasePopupController = CNPPopupController(contents: contents)
//        inAppPurchasePopupController.theme.popupStyle = popupStyle
//        inAppPurchasePopupController.theme.contentVerticalPadding = 5
//        inAppPurchasePopupController.present(animated: true)
//    }
    
    //MARK: Receipt methods
    
    func obtainReceipt() {
        
        let fileExists = FileManager.default.fileExists(atPath: Constants.receiptURL!.path)
        
        if fileExists {
            print("Appstore Receipt already exists")
            return;
        }
        
        requestReceipt()
    }
    
    func requestReceipt() {
        print("request a receipt")
        let request = SKReceiptRefreshRequest(receiptProperties: nil)
        request.delegate = self
        request.start()
    }
    
    func verifyReceipt(_ completionHandler: @escaping (_ receiptTransactionsArray: [JSON]?, _ environment: String?) -> Void) {
        
        print("Validating Receipt")
        
        #if DEBUG
            let serverURL = "https://sandbox.itunes.apple.com/verifyReceipt"
        #else
            let serverURL = "https://buy.itunes.apple.com/verifyReceipt"
        #endif
        
        guard let receipt: Data = try? Data(contentsOf: Constants.receiptURL!) else {
            print("no receipt content")
            return
        }
        
        let receiptData: NSString = NSString(string: receipt.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)))
        //print("\(receiptData)")
        
        let payload: NSString = NSString(string: "{\"receipt-data\" : \"\(receiptData)\"}")
        let payloadData = payload.data(using: String.Encoding.utf8.rawValue)
        //print("\(payloadData)")
        
        var request = URLRequest(url: URL(string: serverURL)!, cachePolicy: NSURLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: 10)
        
        let session = URLSession.shared
        request.httpMethod = "POST"
        request.httpBody = payloadData
        
        let task = session.dataTask(with: request) { (data, response, error) in
            
            guard error == nil else {
                
                print(error!.localizedDescription)
                let jsonString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                print(")Error could not parse JSON: \(jsonString)")
                
                return completionHandler(nil, nil)
            }
            
            let json = JSON(data: data!)
            let receiptStatus = json["status"]
            let receiptEnvironment = json["environment"]
            
            guard json != nil else {
                return completionHandler(nil, receiptEnvironment.string)
            }
            
            print("Receipt \(json)")
            
            guard receiptStatus.int == 0  else {
                
                return completionHandler(nil, receiptEnvironment.string)
            }
            
            print("Sucessfully returned purchased receipt data")
            
            let receiptContent = json["receipt"]
            
            if let inAppPurchases = receiptContent["in_app"].array {
                
                completionHandler(inAppPurchases, receiptEnvironment.string)
                
            } else {
                
                completionHandler(nil, receiptEnvironment.string)
                
            }
        }
        task.resume()
    }
    
    func validateTransaction(_ transaction: SKPaymentTransaction, receiptTransactionsArray: [JSON], completionHandler:(_ success:Bool, _ receiptTransactionArray: JSON?) -> Void) {
        
        let transactionProductID = transaction.payment.productIdentifier as String
        
        for (index,inAppPurchase) in receiptTransactionsArray.enumerated() {
            
            print(index)
            print(receiptTransactionsArray.count)
            
            let product_id = inAppPurchase["product_id"]
            
            if product_id.string == transactionProductID {
                
                completionHandler(true, inAppPurchase)
                
                break
                
            } else if index == receiptTransactionsArray.count - 1 {
                
                completionHandler(false, nil)
                
            }
        }
    }
    
    func displayValidationError() {
        
        DispatchQueue.main.async(execute: { () -> Void in
            SweetAlert().showAlert(NSLocalizedString("Alert: Validation Error Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Validation Error Subtitle Text", comment: ""), style: AlertStyle.error, dismissTime: nil)
            
        })
    }
}
