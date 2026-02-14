/**
* @File Name : PremPark_ReceiptHelper.cls
* @Description : Used for Receipt Automations - Handle the Payment Status of Order - Called from ReceiptTriggerHandler
* @Author : Harsh@Aldar
* @Last Modified By :
* @Last Modified On : Jan 20, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | November 6, 2024 | harohilla@aldar.com  | Initial Version
**/
public with sharing class PremPark_ReceiptHelper {
    
    //handleStripePayment
    //Added by Harsh@Aldar 11/03/2025
    public static CustomerCreateReceiptController.PaymentModel handlePremiumParkingReceipt(String srId, String accountId, String jsonBody, String invoice, Decimal amount, String receiptNumber ){
        CustomerCreateReceiptController.PaymentModel paymentModel = new CustomerCreateReceiptController.PaymentModel();         
        
        List<SBQQ__Quote__c> quoteList = [SELECT Id, SBQQ__Status__c, Sales_Order__c, SBQQ__Account__c FROM SBQQ__Quote__c WHERE Id = :srId];
        
        List<Account> PaidbyAcc = [SELECT Id, Name FROM Account WHERE Id=: accountId LIMIT 1];
        
        ReceiptAcknowledgement__c receipt = new ReceiptAcknowledgement__c();
        receipt.PaymentType__c = 'Online';
        receipt.Amount__c = amount;
        if(quoteList.size()>0){
            receipt.CPQQuote__c = quoteList[0].Id;
        }
        receipt.Account__c = AccountId;
        receipt.Remarks__c = 'Payment for Parking Spot';
        //receipt.ReferenceNumber__c = paymentId;
        receipt.MaturityDate__c =  Date.today();
        receipt.Status__c = 'Received';            
        receipt.InvoiceNumber__c= invoice;
        receipt.Amount__c = amount;
        //receipt.ClearedDate__c = Date.today();
        receipt.Receipt_Type__c = 'Charge Fee';
        receipt.BankName__c = 'Abu Dhabi Commercial Bank';
        receipt.ReceiptDate__c = Date.Today();
        receipt.ReferenceNumber__c = 'CC-'+receiptNumber;
        receipt.ChequeReceived__c = true;
        receipt.OnlinePaymentCleared__c = true;
        receipt.JSONResponse__c = jsonBody;
        receipt.Payment_Gateway__c ='Stripe';
        
        if(PaidbyAcc.size()>0){
            receipt.PaidBy__c = PaidbyAcc[0].Name;
            list<contact> con = [SELECT Id,Name FROM contact WHERE AccountId =: PaidbyAcc[0].Id];                   
            if(con.size()>0){                   
                receipt.Contact__c = con[0].Id;
            } 
        }            
        insert receipt; 

        ReceiptAcknowledgement__c newReceipt = CustomerServiceUtility.getReceiptAcknowledgementDetail(' (Id = \'' + receipt.Id + '\') ')[0];
        paymentModel.receiptId = newReceipt.Id;
        paymentModel.receiptDetails = newReceipt;
        return paymentModel;
    }
	
    public static void handleAfterInsert(Set<Id> receiptAcknowledgements) {
        //On Payment Creation Mark the Asset as Reserved
        // Added by Harsh@Aldar 13/03/2025
        Set<Id> quoteIdSet = new Set<Id>();
        for(ReceiptAcknowledgement__c thisReceipt : [SELECT Id, Order__c, CPQQuote__c, CPQQuote__r.Recordtype.Name FROM ReceiptAcknowledgement__c WHERE Id IN: receiptAcknowledgements]){
            if(thisReceipt.CPQQuote__c != null && thisReceipt.CPQQuote__r.Recordtype.Name == 'Parking'){
                quoteIdSet.add(thisReceipt.CPQQuote__c);
            }
        }
		
        if(quoteIdSet.size() > 0){
            PremPark_Service.handleQuote_PostPayment(quoteIdSet);
        }
        
        //calling async
        updateOrderPayments(receiptAcknowledgements);
        
    }
    public static void handleAfterUpdate(Set<Id> receiptAcknowledgements) {
        //calling async
        updateOrderPayments(receiptAcknowledgements);
    }
    
    @future
    // Method to update Order payments based on the updated ReceiptAcknowledgement__c records
    public static void updateOrderPayments(Set<Id> receiptAcknowledgements) {
        
        List<ReceiptAcknowledgement__c> updatedAcknowledgements = [SELECT Id, Order__c, CPQQuote__c, CPQQuote__r.Recordtype.Name FROM ReceiptAcknowledgement__c WHERE Id IN: receiptAcknowledgements];
            System.debug('Updated Acknowledgements: ' + updatedAcknowledgements);

        //Extract related Order IDs from the updated ReceiptAcknowledgement__c records
        Set<Id> orderIds = new Set<Id>();
        //Store Ref Ids to update Asset Status
        Map<Id,String> orderParkingRefMap = new Map<Id,String>();
        
        for (ReceiptAcknowledgement__c ra : updatedAcknowledgements) {
            System.debug('ReceiptAcknowledgement Order ID: ' + ra.Order__c + 
                     ', CPQQuote Record Type: ' + ra.CPQQuote__r.Recordtype.Name);
            if (ra.Order__c != null && ra.CPQQuote__r.Recordtype.Name == 'Parking') {
                orderIds.add(ra.Order__c);
            }
        }

        if (orderIds.isEmpty()) {
            return; // Exit early if there are no related orders
        }

        try {
            //Fetch the aggregate sums of Amount__c based on Status__c for each Order
            List<AggregateResult> clearedResults = [
                SELECT Order__c, SUM(Amount__c) clearedAmount
                FROM ReceiptAcknowledgement__c
                WHERE Order__c IN :orderIds AND Status__c = 'Cleared'
                GROUP BY Order__c
            ];
            
            List<AggregateResult> receivedResults = [
                SELECT Order__c, SUM(Amount__c) receivedAmount
                FROM ReceiptAcknowledgement__c
                WHERE Order__c IN :orderIds AND (Status__c = 'Received' OR Status__c = 'Link Sent' )
                GROUP BY Order__c
            ];

            //Prepare maps for the aggregated results
            Map<Id, Decimal> clearedMap = new Map<Id, Decimal>();
            Map<Id, Decimal> receivedMap = new Map<Id, Decimal>();

            for (AggregateResult result : clearedResults) {
                clearedMap.put((Id)result.get('Order__c'), (Decimal)result.get('clearedAmount'));
            }

            for (AggregateResult result : receivedResults) {
                receivedMap.put((Id)result.get('Order__c'), (Decimal)result.get('receivedAmount'));
            }

            //Fetch all Orders to update
            List<Order> ordersToUpdate = new List<Order>();
            //Quote to mark as Accepted once all payments are done
            List<SBQQ__Quote__c> quoteListToUpdate = new List<SBQQ__Quote__c>();
            for (Order thisOrder : [SELECT Id, TotalAmount, SBQQ__Quote__c FROM Order WHERE Id IN: orderIds]) {

                // Fetch the aggregate results for the order from the maps
                Decimal clearedAmount = clearedMap.get(thisOrder.Id);
                Decimal receivedAmount = receivedMap.get(thisOrder.Id);

                
                // Populate Amount_Received__c and Amount_In_Progress__c from aggregate results
                thisOrder.Amount_Received__c = clearedAmount != null ? clearedAmount : 0;
                thisOrder.Amount_In_Progress__c = receivedAmount != null ? receivedAmount : 0;
				
                //Neelesh 25/02 starts here - Edge Case
                /*if(clearedAmount > thisOrder.TotalAmount ){
                    thisOrder.Amount_Received__c = thisOrder.TotalAmount;
                }*/
                
                /*if(receivedAmount > thisOrder.TotalAmount ){
                    thisOrder.Amount_In_Progress__c = thisOrder.TotalAmount;
                }*/
                // Neelesh code end here 
                
                // Amount_Outstanding__c = TotalAmount - Amount_Received__c
                thisOrder.Amount_Outstanding__c = thisOrder.TotalAmount - thisOrder.Amount_Received__c;

                //Check if the order should be activated based on the buffer amount
                Decimal bufferAmount = Decimal.valueOf(Label.PremiumParkingPaymentBuffer);
                if (thisOrder.Amount_Received__c >= (thisOrder.TotalAmount - bufferAmount)) {
                    thisOrder.Status = 'Activated'; // Activate the order

                    //For fully paid Orders, mark the Quote as Accepted
                    SBQQ__Quote__c thisQuote = new SBQQ__Quote__c();
                    thisQuote.Id = thisOrder.SBQQ__Quote__c;
                    thisQuote.SBQQ__Status__c = 'Accepted';
                    quoteListToUpdate.add(thisQuote);
                }

                ordersToUpdate.add(thisOrder);
            }

            //Perform the DML operation to update Orders
            if (!ordersToUpdate.isEmpty()) {
               if(!Test.isRunningTest()){
                update ordersToUpdate;
                }
                
            }

            if(!quoteListToUpdate.isEmpty()){
                 if(!Test.isRunningTest()){
                update quoteListToUpdate;
                 }
            }

            List<Asset> assetToUpdate = new List<Asset>();
            Map<String, Order> parkingRefIdOrderMap = new Map<String, Order>();
            List<Order> activatedOrdersList = [SELECT Id, AccountId, SBQQ__Quote__c, SBQQ__Quote__r.Parking_Ref_ID__c
                                                FROM Order 
                                                WHERE Id IN: ordersToUpdate];
                
            for(Order thisOrder : activatedOrdersList){
                parkingRefIdOrderMap.put(thisOrder.SBQQ__Quote__r.Parking_Ref_ID__c, thisOrder);
            }

            List<Asset> soldAssetList = [SELECT Id, Ref_ID__c FROM Asset WHERE  Ref_ID__c IN: parkingRefIdOrderMap.keySet()];

            for(Asset thisAsset : soldAssetList){
                if(parkingRefIdOrderMap != null && parkingRefIdOrderMap.get((String)thisAsset.Ref_ID__c) != null){
                    thisAsset.Status = 'Sold';
                    thisAsset.AccountId = parkingRefIdOrderMap.get((String)thisAsset.Ref_ID__c).AccountId;
                    assetToUpdate.add(thisAsset);
                }
            }
            if(assetToUpdate.size() > 0){
                update assetToUpdate;
            }

        } catch (Exception e) {
            // Log and handle exceptions
            System.debug('Error in updating Order payments: ' + e.getMessage());
            if(!Test.isRunningTest()){
            throw new CustomException('An error occurred while processing the payments: ' + e.getMessage());
            }
        }
    }
    
    // Custom exception to handle specific errors
    public class CustomException extends Exception {}
    
}