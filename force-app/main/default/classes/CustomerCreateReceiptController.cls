public class CustomerCreateReceiptController {
    public static PaymentModel createReceipt(String jsonBody){
        system.debug('Json'+jsonBody);
        PaymentModel paymentModel = new PaymentModel(); 
        Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(jsonBody);
        if (requestMap.get('statusMessage') != null && requestMap.get('statusCode') != null && requestMap.get('statusMessage').equals('success') && string.valueof(requestMap.get('statusCode')).equals('200')) {
            
            Map<String, Object> data = (Map<String, Object>) requestMap.get('data');
            System.debug('Data: ' + data);
            String resp = JSON.serialize(data);
            System.debug('Serialized Data: ' + resp);
            JSONParser parser = JSON.createParser(jsonBody);
            
            String paymentId, currency_value, status, invoice, devNocFee, ownerNocFee, serviceCharge,salesOrderId,AccountId,srId,ReceiptNumber;
            Decimal amount = 0;
            Boolean isDevAdminFee= false;
            Boolean isEnabled = false;
            String stripeId ='';
            Decimal AmountVal =0;
            while (parser.nextToken() != null) {
                
                if (parser.getText().equals('id')) {
                    parser.nextToken();
                    paymentId = parser.getText();
                } 
                else if (parser.getText().equals('currency_value')) {
                    parser.nextToken();
                    currency_value = parser.getText();
                } else if (parser.getText().equals('status')) {
                    parser.nextToken();
                    status = parser.getText();
                } else if (parser.getText().equals('invoice')) {
                    parser.nextToken();
                    invoice = parser.getText();
                }
                else if (parser.getText().equals('metadata')) {
                    parser.nextToken();
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                        while (parser.nextToken() != null && parser.getCurrentToken() != JSONToken.END_OBJECT) {
                            String fieldName = parser.getText();
                            parser.nextToken();
                            
                            if (fieldName == 'salesforceRequestId') {
                                srId = parser.getText();
                            } else if (fieldName == 'payerId') {
                                AccountId = parser.getText();
                            } else if (fieldName == 'service-charge') {
                                serviceCharge = parser.getText();
                            }
                            
                            if (fieldName =='splits') {
                                System.debug('Test3');
                                if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                                    while (parser.nextToken() != null && parser.getCurrentToken() != JSONToken.END_ARRAY) {
                                        if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                                            while (parser.nextToken() != null && parser.getCurrentToken() != JSONToken.END_OBJECT) {
                                                String fieldAttri = parser.getText();
                                                if (fieldAttri == 'accountSearchFields') {
                                                    // Skip accountSearchFields
                                                    parser.nextToken();
                                                    Integer nestedObjects = 0;
                                                    
                                                    // Handle nested objects and arrays
                                                    while (parser.nextToken() != null) {
                                                        if (parser.getCurrentToken() == JSONToken.START_OBJECT || parser.getCurrentToken() == JSONToken.START_ARRAY) {
                                                            nestedObjects++;
                                                        } else if (parser.getCurrentToken() == JSONToken.END_OBJECT || parser.getCurrentToken() == JSONToken.END_ARRAY) {
                                                            nestedObjects--;
                                                        }
                                                        
                                                        // Break out of loop when all nested structures are skipped
                                                        if (nestedObjects < 0) {
                                                            break;
                                                        }
                                                    }
                                                }else{
                                                    parser.nextToken();
                                                    System.debug('Test2'+fieldAttri);
                                                    if(fieldAttri =='amount'){
                                                        AmountVal = Decimal.valueof(parser.getText());
                                                    }
                                                    if(fieldAttri == 'stripeTransferId'){
                                                        
                                                        stripeId = parser.getText();
                                                    }
                                                    if (fieldAttri == 'chargeType') {
                                                        String chargeType = parser.getText();
                                                        System.debug('Test1');
                                                        //Modified by Harsh@Aldar 15/06/2025 - FUrniture Included in chargetype
                                                        //Modified by Harsh@Aldar 23/08/3035 - Smarthome included in chargetype
                                                        if (chargeType == 'dev-admin-fee' || chargeType == 'premium-parking'|| chargeType == 'furniture-package' || chargeType == 'smarthome-package') {
                                                           isDevAdminFee = true;
                                                        }
                                                    }
                                                    if (isDevAdminFee == true) {
                                                        ReceiptNumber = stripeId;
                                                        amount= AmountVal;
                                                        isDevAdminFee = false;
                                                        System.debug('Stripe Transfer ID Found: ' + ReceiptNumber);
                                                        
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                        }
                    }
                    
                }else if (parser.getText().equals('payment_method_options')) {
                    parser.nextToken();
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                        while (parser.nextToken() != null && parser.getCurrentToken() != JSONToken.END_OBJECT) {
                            String fieldName = parser.getText();
                            parser.nextToken();
                            if (fieldName == 'card') {
                                while (parser.nextToken() != null && parser.getCurrentToken() != JSONToken.END_OBJECT) {
                                    if (parser.getText() == 'request_three_d_secure') {
                                        parser.nextToken();
                                        String threeDSecure = parser.getText();
                                        isEnabled = (threeDSecure == 'automatic');
                                    }
                                }
                            }
                        }
                    }
                }
            }
            //START Added by harsh@Aldar 11/03/2025 - For Premium Parking Stripe Payments
            if(((Id)srId).getSObjectType() == SBQQ__Quote__c.getSObjectType()){
                //START Added by harsh@Aldar 12/06/2025 - For Furniture Payments
                // Get the record to check its RecordType
                SBQQ__Quote__c quote = [SELECT RecordType.Name FROM SBQQ__Quote__c WHERE Id = :srId LIMIT 1];
 
                // Check RecordType first
                if(quote.RecordType.Name == 'Parking') {
                    // Return existing line for Parking record type
                    return PremPark_ReceiptHelper.handlePremiumParkingReceipt(srId, AccountId, jsonBody, invoice, amount, ReceiptNumber);
                } else if(quote.RecordType.Name == 'Furniture') {
                    // Return Furniture helper for Furniture record type
                    return Furniture_ReceiptHelper.processPaymentResponse(jsonBody, srId, AccountId, invoice, ReceiptNumber);
                }else if(quote.RecordType.Name == 'Smarthome') {
                    // Using same furniture class to handle smarthome as well
                    return Furniture_ReceiptHelper.processPaymentResponse(jsonBody, srId, AccountId, invoice, ReceiptNumber);
                }
                return null;
                //END Added by harsh@Aldar 12/06/2025 - For Furniture Payments
           }
            //END Added by harsh@Aldar 11/03/2025 - For Premium Parking Stripe Payments
            
            list <Opportunity> opp = new list<Opportunity> ();
            list<HexaBPM__Service_Request__c> serviceRequest= [SELECT Id,SalesOrder__c FROM HexaBPM__Service_Request__c WHERE Id =: srId LIMIT 1];
            if(serviceRequest.size() > 0) {
                opp = [SELECT Id FROM Opportunity WHERE SalesOrder__c =: serviceRequest[0].SalesOrder__c];
            }
            list<Account> PaidbyAcc = [SELECT Id,Name FROM Account WHERE Id=: AccountId LIMIT 1];
            String reference;
            reference = 'CC-'+ReceiptNumber;
            List<ReceiptAcknowledgement__c> existingReceipt = [SELECT Id FROM ReceiptAcknowledgement__c WHERE ReferenceNumber__c=:reference ];
            ReceiptAcknowledgement__c receipt = new ReceiptAcknowledgement__c();
            if (existingReceipt.isEmpty()) {
                
                receipt.PaymentType__c = 'Online';
                receipt.Amount__c = amount;
                if(serviceRequest.size()>0){
                    receipt.SalesOrder__c = serviceRequest[0].SalesOrder__c;
                }
                if(opp.size()>0){
                    receipt.Opportunity__c = opp[0].Id;
                }
                receipt.Account__c = AccountId;
                receipt.Remarks__c = 'Payment Completed Successfully';
                //receipt.ReferenceNumber__c = paymentId;
                receipt.MaturityDate__c =  Date.today();
                receipt.ServiceRequest__c= srId;
                receipt.Status__c='Received';            
                receipt.InvoiceNumber__c= invoice;
                receipt.Amount__c= amount;
                receipt.ClearedDate__c=Date.today();
                receipt.Receipt_Type__c = 'Charge Fee';
                receipt.BankName__c = 'Abu Dhabi Commercial Bank';
                receipt.ReceiptDate__c = Date.Today();
                receipt.ReferenceNumber__c = 'CC-'+ReceiptNumber;
                receipt.ChequeReceived__c = true;
                receipt.OnlinePaymentCleared__c = true;
                receipt.JSONResponse__c = jsonBody;
                receipt.Payment_Gateway__c ='Stripe';
                receipt.SyncStatus__c = Constants.STATUS_IN_PROGRESS;
                
                if(PaidbyAcc.size()>0){
                    receipt.PaidBy__c =PaidbyAcc[0].Name;
                    list<contact> con = [SELECT Id,Name FROM contact WHERE AccountId =: PaidbyAcc[0].Id];                   
                    if(con.size()>0){                   
                        receipt.Contact__c = con[0].Id;
                    } 
                    
                }            
                insert receipt; 
            }else{
                paymentModel.receiptId = existingReceipt[0].Id;
                 paymentModel.receiptDetails = existingReceipt[0];
                return paymentModel;
            }
            if(serviceRequest.size() > 0) {
                serviceRequest[0].IsChargeReceiptCreated__c = true;
            }
            update serviceRequest;
            ReceiptAcknowledgement__c newReceipt = CustomerServiceUtility.getReceiptAcknowledgementDetail(' (Id = \'' + receipt.Id + '\') ')[0];
            paymentModel.receiptId = newReceipt.Id;
            paymentModel.receiptDetails = newReceipt;
        }
        
        return paymentModel;
    }
    public class PaymentModel{
        public Id receiptId                                     {get;set;}
        public ReceiptAcknowledgement__c receiptDetails         {get;set;}
    }
}