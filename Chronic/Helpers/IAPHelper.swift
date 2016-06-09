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
import CNPPopupController
import Crashlytics
import Parse

class IAPHelper: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver, SKRequestDelegate {
    
    static let sharedInstance = IAPHelper()

    var completionHandler:((Bool) -> Void)?
    
    var request: SKProductsRequest!
    var list = [SKProduct]()
    var p = SKProduct()
    
    var inAppPurchasePopupController: CNPPopupController!
    var sweetAlertLoadingPurchase = SweetAlert()
    var sweetAlertProcessingPurchase = SweetAlert()
    var sweetAlertRestorePurchases = SweetAlert()
    
    override init() {
        
        super.init()
        _ = SKPaymentQueue.defaultQueue().addTransactionObserver(self)
    }
    
    func requestProductsWithCompletionHandler(handler:((Bool) -> Void)) {
        
        self.completionHandler = handler
        if SKPaymentQueue.canMakePayments() {
            
            print("IAP is enabled, loading")
            
            let productIDs: NSSet = NSSet(objects: iapUltimatePackageKey, proVersionKey, removeAdsKey, donate99Key)
            
            request = SKProductsRequest(productIdentifiers: productIDs as! Set<String>)
            request.delegate = self
            request.start()
            
        } else {
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                SweetAlert().showAlert(NSLocalizedString("Alert: In-App Purchases Disabled Title Text", comment: ""), subTitle: NSLocalizedString("Alert: In-App Purchases Disabled Subtitle Text", comment: ""), style: AlertStyle.Error)
            })
        }
    }
    
    // MARK: - Payment Processing
    
    func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        
        print("Product Request")
        let myProducts = response.products
        
        for product in myProducts {
            
            print("Product added")
            print(product.productIdentifier)
            print(product.localizedTitle)
            print(product.localizedDescription)
            print(product.price)
            
            list.append(product as SKProduct)
        }
        
        self.completionHandler?(true)
        completionHandler = nil
    }
    
    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
        if inAppPurchasePopupController != nil {
            
            inAppPurchasePopupController.dismissPopupControllerAnimated(true)
        }
        
        for transaction:SKPaymentTransaction in transactions {
            
            let productID = transaction.payment.productIdentifier
            let productPrice = p.price
            let formatter = NSNumberFormatter()
            formatter.locale = p.priceLocale
            let productCurrency = formatter.currencyCode
            
            switch transaction.transactionState {
                
            case .Purchasing:
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.sweetAlertProcessingPurchase.showAlert(NSLocalizedString("Alert: Processing Purchase Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Processing Purchase Subtitle Text", comment: ""), style: AlertStyle.ActivityIndicator, dismissTime: nil)
                })
                
            case .Purchased, .Restored:
                
                verifyReceipt({ (receiptTransactionsArray, environment) -> Void in
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.sweetAlertProcessingPurchase.closeAlertDismissButton()
                    })
                    
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

                                case iapUltimatePackageKey:
                                    
                                    print("\(transaction.transactionState) - ultimate")
                                    self.proVersionPurchased()
                                    self.removeAdsPurchased()
                                    
                                    if transactionID.string  == transactionTransactionID && environment != "Sandbox" {
                                        
                                        // log Ultimate Package purchase
                                        Answers.logPurchaseWithPrice(productPrice,
                                            currency: productCurrency,
                                            success: true,
                                            itemName: "Ultimate Package",
                                            itemType: "In-App Purchase",
                                            itemId: "\(transaction.transactionIdentifier!)",
                                            customAttributes: ["Installation ID":PFInstallation.currentInstallation().installationId, "App Version": AppVersion, "Transaction Date": transaction.transactionDate!])
                                    }
                                    
                                    break
                                    
                                case proVersionKey:
                                    
                                    print("\(transaction.transactionState) - pro version")
                                    self.proVersionPurchased()
                                    
                                    if transactionID.string  == transactionTransactionID && environment != "Sandbox" {
                                        
                                        // log pro purchase
                                        Answers.logPurchaseWithPrice(productPrice,
                                            currency: productCurrency,
                                            success: true,
                                            itemName: "Pro Version",
                                            itemType: "In-App Purchase",
                                            itemId: "\(transaction.transactionIdentifier!)",
                                            customAttributes: ["Installation ID":PFInstallation.currentInstallation().installationId, "App Version": AppVersion, "Transaction Date": transaction.transactionDate!])
                                    }
                                    
                                    break
                                    
                                case removeAdsKey:
                                    
                                    print("\(transaction.transactionState) - remove ads")
                                    self.removeAdsPurchased()
                                    
                                    if transactionID.string == transactionTransactionID && environment != "Sandbox" {
                                        
                                        // log remove ads purchase
                                        Answers.logPurchaseWithPrice(productPrice,
                                            currency: productCurrency,
                                            success: true,
                                            itemName: "Remove Ads",
                                            itemType: "In-App Purchase",
                                            itemId: "\(transaction.transactionIdentifier!)",
                                            customAttributes: ["Installation ID":PFInstallation.currentInstallation().installationId, "App Version": AppVersion, "Transaction Date": transaction.transactionDate!])
                                    }
                                    
                                    break
                                    
                                case donate99Key:
                                    
                                    print("\(transaction.transactionState) - donate")
                                    
                                    if transactionID.string  == transactionTransactionID && environment != "Sandbox" {
                                        
                                        // log donation purchase
                                        Answers.logPurchaseWithPrice(productPrice,
                                            currency: productCurrency,
                                            success: true,
                                            itemName: "Donation",
                                            itemType: "In-App Purchase (Consumable)",
                                            itemId: "\(transaction.transactionIdentifier!)",
                                            customAttributes: ["Installation ID":PFInstallation.currentInstallation().installationId, "App Version": AppVersion, "Transaction Date": transaction.transactionDate!])
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
                
            case .Failed:
                
                var errorMessage = ""
                
                switch (transaction.error!.code) {
                case SKErrorCode.Unknown.rawValue:
                    errorMessage = "Unknown error"
                    break;
                case SKErrorCode.ClientInvalid.rawValue:
                    errorMessage = "Client Not Allowed To issue Request"
                    break;
                case SKErrorCode.PaymentCancelled.rawValue:
                    errorMessage = "User Cancelled Request"
                    break;
                case SKErrorCode.PaymentInvalid.rawValue:
                    errorMessage = "Purchase Identifier Invalid"
                    break;
                case SKErrorCode.PaymentNotAllowed.rawValue:
                    errorMessage = "Device Not Allowed To Make Payment"
                    break;
                default:
                    break;
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.sweetAlertProcessingPurchase.closeAlertDismissButton()
                    SweetAlert().showAlert(NSLocalizedString("Failed", comment: ""), subTitle: errorMessage, style: AlertStyle.Error)
                })
                
                Answers.logPurchaseWithPrice(nil,
                    currency: nil,
                    success: false,
                    itemName: nil,
                    itemType: nil,
                    itemId: nil,
                    customAttributes: ["Installation ID":PFInstallation.currentInstallation().installationId, "Error": errorMessage, "App Version": AppVersion])
                
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
    
    func paymentQueue(queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        
        print("removed transactions")
        
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(queue: SKPaymentQueue) {
        
        print("transactions restored")
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.sweetAlertRestorePurchases.closeAlertDismissButton()
            SweetAlert().showAlert(NSLocalizedString("Success", comment: ""), subTitle: NSLocalizedString("Alert: Restore Success Subtitle Text", comment: ""), style: AlertStyle.Success)
        })
    }
    
    func paymentQueue(queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: NSError) {
        
        print("restore transactions failed")
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.sweetAlertRestorePurchases.closeAlertDismissButton()
            SweetAlert().showAlert(NSLocalizedString("Failed", comment: ""), subTitle: error.localizedDescription, style: AlertStyle.Error)
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
    
    func requestDidFinish(request: SKRequest) {
        
        print("request did finish")
        let fileExists = NSFileManager.defaultManager().fileExistsAtPath(receiptURL!.path!)
        
        if fileExists {
            print("Appstore Receipt now exists")
            return
        }
        
        print("something went wrong while obtaining the receipt, maybe the user did not successfully enter it's credentials")
    }
    
    func request(request: SKRequest, didFailWithError error: NSError) {
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            SweetAlert().showAlert(NSLocalizedString("Alert: Purchase Request Failed Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Purchase Request Failed Subtitle Text", comment: ""), style: AlertStyle.Warning)
        })
        
        print("request did fail with error: \(error.code)")
    }
    
    func selectProduct(productID: String) {
        
        guard isConnectedToNetwork() else {
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                SweetAlert().showAlert(NSLocalizedString("Alert: Requires Upgrade Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Requires Upgrade Subtitle Text", comment: ""), style: AlertStyle.Warning)
            })
            return
        }
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.sweetAlertLoadingPurchase.showAlert(NSLocalizedString("Alert: Loading Purchase Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Loading Purchase Subtitle Text", comment: ""), style: AlertStyle.ActivityIndicator, dismissTime: nil)
        })
        
        self.requestProductsWithCompletionHandler { (success) -> Void in
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.sweetAlertLoadingPurchase.closeAlertDismissButton()
            })
            
            if success {
                
                for product in self.list {
                    
                    if product.productIdentifier == productID {
                        
                        self.p = product
                        self.displayCustomAlert(self.p.localizedTitle, lineTwo: self.p.localizedPrice(), lineThree: "\(self.p.localizedDescription)", image: nil, popupStyle: CNPPopupStyle.Centered)
                        break
                    }
                }
            }
        }
    }
    
    func buyProduct() {
        
        print("buy " + p.productIdentifier)
        
        let pay = SKPayment(product: p)
        _ = SKPaymentQueue.defaultQueue().addPayment(pay as SKPayment)
        
    }
    
    func finishTransaction(trans: SKPaymentTransaction) {
        
        print("finish transaction")
        
    }
    
    func removeAdsPurchased() {
        
        // Set KeyChain Value
        do {
            try keychain
                .synchronizable(true)
                .set(removeAdsKeyValue, key: removeAdsKey)
        } catch let error {
            print("error: \(error)")
        }
        
        keychainRemoveAdsString  = keychain[removeAdsKey]
    }
    
    func proVersionPurchased() {
        
        // send context to Watch if iOS9
        if wcSession != nil {
            
            sendContextToAppleWatch(["contextType":"PurchasedProVersion"])
        }
        
        // Set KeyChain Value
        do {
            try keychain
                .accessibility(.Always)
                .synchronizable(true)
                .set(proVersionKeyValue, key: proVersionKey)
        } catch let error {
            print("error: \(error)")
        }
        
        keychainProVersionString = keychain[proVersionKey]
    }
    
    func restorePurchases() {
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.sweetAlertRestorePurchases.showAlert(NSLocalizedString("Alert: Restoring Purchase Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Restoring Purchase Subtitle Text", comment: ""), style: AlertStyle.ActivityIndicator, dismissTime: nil)
        })
        
        _ = SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
    }
    
    // Custom Alert Functions
    
    func displayCustomAlert (lineOne: String, lineTwo: String, lineThree:String, image: UIImage?, popupStyle: CNPPopupStyle) {
        
        var contents:[AnyObject] = []
        
        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.ByWordWrapping
        paragraphStyle.alignment = NSTextAlignment.Center
        
        let attributedLineOne: NSAttributedString = NSAttributedString(string: lineOne, attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(24), NSParagraphStyleAttributeName: paragraphStyle])
        
        let attributedLineTwo: NSAttributedString = NSAttributedString(string: lineTwo, attributes: [NSFontAttributeName: UIFont.systemFontOfSize(20), NSParagraphStyleAttributeName: paragraphStyle])
        
        let attributedLineThree: NSAttributedString = NSAttributedString(string: lineThree, attributes: [NSFontAttributeName: UIFont.systemFontOfSize(18), NSParagraphStyleAttributeName: paragraphStyle])
        
        let lineOneLabel: UILabel = UILabel()
        lineOneLabel.numberOfLines = 0
        lineOneLabel.attributedText = attributedLineOne
        contents.append(lineOneLabel)
        
        let lineTwoLabel: UILabel = UILabel()
        lineTwoLabel.numberOfLines = 0
        lineTwoLabel.attributedText = attributedLineTwo
        contents.append(lineTwoLabel)
        
        let lineThreeLabel: UILabel = UILabel()
        lineThreeLabel.numberOfLines = 0
        lineThreeLabel.attributedText = attributedLineThree
        contents.append(lineThreeLabel)
        
        if image != nil {
            
            let imageView: UIImageView = UIImageView(image: image)
            contents.append(imageView)
        }
        
        let purchaseButton: CNPPopupButton = CNPPopupButton(type: UIButtonType.System)
        purchaseButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        purchaseButton.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Highlighted)
        purchaseButton.titleLabel?.font =  UIFont.boldSystemFontOfSize(20)
        purchaseButton.setTitle("Purchase", forState: UIControlState.Normal)
        purchaseButton.backgroundColor = UIColor.greenColor()
        purchaseButton.layer.cornerRadius = 4
        purchaseButton.addTarget(self, action: #selector(IAPHelper.buyProduct), forControlEvents: UIControlEvents.TouchUpInside)
        contents.append(purchaseButton)
        
        inAppPurchasePopupController = CNPPopupController(contents: contents)
        inAppPurchasePopupController.theme.popupStyle = popupStyle
        inAppPurchasePopupController.theme.contentVerticalPadding = 5
        inAppPurchasePopupController.presentPopupControllerAnimated(true)
        
    }
    
    //MARK: Receipt methods
    
    func obtainReceipt() {
        
        let fileExists = NSFileManager.defaultManager().fileExistsAtPath(receiptURL!.path!)
        
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
    
    func verifyReceipt(completionHandler:(receiptTransactionsArray: [JSON]?, environment: String?) -> Void) {
        
        print("Validating Receipt")
        
        #if DEBUG
            let serverURL = "https://sandbox.itunes.apple.com/verifyReceipt"
        #else
            let serverURL = "https://buy.itunes.apple.com/verifyReceipt"
        #endif
        
        guard let receipt: NSData = NSData(contentsOfURL: receiptURL!) else {
            print("no receipt content")
            return
        }
        
        let receiptData: NSString = receipt.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        //print("\(receiptData)")
        
        let payload: NSString = "{\"receipt-data\" : \"\(receiptData)\"}"
        let payloadData = payload.dataUsingEncoding(NSUTF8StringEncoding)
        //print("\(payloadData)")
        
        let request = NSMutableURLRequest(URL: NSURL(string: serverURL)!, cachePolicy: NSURLRequestCachePolicy.UseProtocolCachePolicy, timeoutInterval: 10)
        
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        request.HTTPBody = payloadData
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            
            guard error == nil else {
                
                print(error!.localizedDescription)
                let jsonString = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print(")Error could not parse JSON: \(jsonString)")
                
                return completionHandler(receiptTransactionsArray: nil, environment: nil)
            }

            let json = JSON(data: data!)
            let receiptStatus = json["status"]
            let receiptEnvironment = json["environment"]
            
            guard json != nil else {
                return completionHandler(receiptTransactionsArray: nil, environment: receiptEnvironment.string)
            }
            
            print("Receipt \(json)")
            
            guard receiptStatus.int == 0  else {
                
                return completionHandler(receiptTransactionsArray: nil, environment: receiptEnvironment.string)
            }
                
            print("Sucessfully returned purchased receipt data")
            
            let receiptContent = json["receipt"]
            
            if let inAppPurchases = receiptContent["in_app"].array {
                
                completionHandler(receiptTransactionsArray: inAppPurchases, environment: receiptEnvironment.string)
                
            } else {
                
                completionHandler(receiptTransactionsArray: nil, environment: receiptEnvironment.string)
                
            }
        }
        task.resume()
    }
    
    func validateTransaction(transaction: SKPaymentTransaction, receiptTransactionsArray: [JSON], completionHandler:(success:Bool, receiptTransactionArray: JSON?) -> Void) {
        
        let transactionProductID = transaction.payment.productIdentifier as String
        
        for (index,inAppPurchase) in receiptTransactionsArray.enumerate() {
            
            print(index)
            print(receiptTransactionsArray.count)
            
            let product_id = inAppPurchase["product_id"]
            
            if product_id.string == transactionProductID {
                
                completionHandler(success: true, receiptTransactionArray: inAppPurchase)
                
                break
                
            } else if index == receiptTransactionsArray.count - 1 {
                
                completionHandler(success: false, receiptTransactionArray: nil)
                
            }
        }
    }
    
    func displayValidationError() {
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            SweetAlert().showAlert(NSLocalizedString("Alert: Validation Error Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Validation Error Subtitle Text", comment: ""), style: AlertStyle.Error, dismissTime: nil)
            
        })
    }
}
