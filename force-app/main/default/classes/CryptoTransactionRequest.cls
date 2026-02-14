public class CryptoTransactionRequest {
    
    @AuraEnabled
    public static String postTransaction(Id recordId){
        System.debug('print recordId '+ recordId);
        
        if(recordId == null){
            return '';
        }
        
        ReceiptAcknowledgement__c ack = [SELECT id,SalesOrder__r.Unit__r.name,Amount__c,SalesOrder__r.Unit__r.VirtualAccountNumber__r.VirtualIBANAccountNumber__c,SalesOrder__r.Account__r.name,name FROM ReceiptAcknowledgement__c
                                         WHERE Id =: recordId Limit 1];
        
        System.debug('amount'+ ack.Amount__c);
        
        //if (String.isEmpty(ack.SalesOrder__r.Unit__r.VirtualAccountNumber__r.VirtualIBANAccountNumber__c)) {
        //    return 'VA is missing'; // Return the message if the Virtual IBAN Account Number is empty
        //}
        
        
        //Query Metadata for API settings
        APISetting__mdt  midChainAPIMeta = [SELECT DeveloperName, Method__c, APIKey__c, SandboxURL__c, 
                                            ProductionURL__c, Headers__c,MidChains_MerchantUUID__c,MidChains_SettlementCurrency__c
                                            ,MidChains_BaseCurrency__c,MidChains_Expiry__c,MidChains_CallbackURL__c
                                            FROM APISetting__mdt
                                            WHERE DeveloperName = 'MidChainPayment'];
        
        System.debug('midChainAPIMeta '+midChainAPIMeta);
        
        Organization org = Utilities.getOrganizationDetails();
        String endpointURL = org.IsSandbox ? midChainAPIMeta.SandboxURL__c : midChainAPIMeta.ProductionURL__c;
        
        Map<String,String> headers = midChainAPIMeta.Headers__c == null ? null : (Map<String,String>)JSON.deserialize(midChainAPIMeta.Headers__c, Map<String,String>.class);
        
        Map<String,Object> data = new Map<String,Object>();
        data.put('MerchantUUID', midChainAPIMeta.MidChains_MerchantUUID__c);
        data.put('Amount',ack.Amount__c);
        data.put('SettlementCurrency', midChainAPIMeta.MidChains_SettlementCurrency__c);
        data.put('BaseCurrency', midChainAPIMeta.MidChains_BaseCurrency__c);
        data.put('Expiry', midChainAPIMeta.MidChains_Expiry__c);
        data.put('CallbackURL', midChainAPIMeta.MidChains_CallbackURL__c);
        data.put('UnitVAIBANNumber', ack.SalesOrder__r.Unit__r.VirtualAccountNumber__r.VirtualIBANAccountNumber__c);
        data.put('InvoiceID', ack.name);
        data.put('CustomerName', ack.SalesOrder__r.Account__r.name);
        system.debug('data++' + data);
        
        try{
            HttpRequest request = new HttpRequest();
            
            System.debug('Print headers from metadata '+headers);
            for(String headerName : headers.keySet()){
                request.setHeader(headerName, headers.get(headerName));
            }            
            request.setEndpoint(endpointURL);
            request.setMethod(midChainAPIMeta.Method__c);
            request.setBody(JSON.Serialize(data));
            
            Http http = new Http();
            HttpResponse response = http.send(request);
            
            Map<String, Object> result = new Map<String,Object>();
            
            System.debug('res status'+ response.getStatusCode());
            System.debug('response from mule'+ response.getStatusCode() +'===\n'+response.getBody());
            if (response.getStatusCode() == 200 || response.getStatusCode() == 304){
                String jsonResponse = response.getBody();
                System.debug('jsonResponse' +  jsonResponse);
                
                TransactionResponse res = (TransactionResponse) JSON.deserialize(jsonResponse, TransactionResponse.class);
                System.debug('res '+ res.TransactionID);
                System.debug('res '+ res.url);
                
                ReceiptAcknowledgement__c ackR = new ReceiptAcknowledgement__c(id=recordId, 
                                                                               CryptoPaymentLink__c = res.url,
                                                                               CryptoTransactionId__c = res.TransactionID);
                update ackR;
                sendCryptoPaymentLink(ackR);
                return 'SUCCESS';
            }            	
            else{
                String retmessage = response.getBody();
                return retmessage;
            } 
        }
        catch(Exception e){
            LoggerService.save(LoggerService.addApexLog(e,'CryptoTransactionRequest','postTransaction',''));
            String htmlEmailBody = 'Hello,</br></br> CryptoTransactionRequest has failed because of below error.</br></br>';
            htmlEmailBody += ' <b> Instance: ' + org.Name + ' </b> </br> ' ;
            htmlEmailBody += ' <b> ' + e.getMessage() + ' </b> </br> ' ;
            htmlEmailBody +=  ' <b> ' + e.getStackTraceString() + ' </b> ' ;
            List<String> recipientList = Label.SysAdminEmailAddress.split(';');
            Utilities.sendEmail(new list<Messaging.SingleEmailMessage>{Utilities.getEmailInstance('','','',recipientList, new List<String>(), new List<String>(), 'CryptoTransactionRequest Failure', '',htmlEmailBody,new List<Messaging.EmailFileAttachment>(), '')});
            return e.getMessage();
        }
    }
    
    public static void sendCryptoPaymentLink(ReceiptAcknowledgement__c receipt){
        String ccEmailAddresses = Label.midChainsEmailAddressForAccountOpening;
        String[] ccEmails = ccEmailAddresses.split(',');
        
        ReceiptAcknowledgement__c ack = [SELECT Id, CryptoPaymentLink__c, Contact__c, Account__c, Account__r.PersonEmail FROM ReceiptAcknowledgement__c
                                         WHERE Id=: receipt.Id];
        
        EmailTemplate emailTemplate = [Select Id,Subject,Description,DeveloperName,Body from EmailTemplate where DeveloperName = 'Crypto_Payment_Template'];
        string orgWideEmailAddress = '';
        for(OrgWideEmailAddress tempRec: [select id,Address from OrgWideEmailAddress where DisplayName= 'Aldar Properties' limit 1]){
            orgWideEmailAddress=tempRec.Id;
        }
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTemplateID(emailTemplate.Id); 
        mail.setTargetObjectId(ack.Contact__c);
        mail.setWhatId(ack.Id);
        mail.toAddresses = new String[] {ack.Account__r.PersonEmail};
		mail.setCcAddresses(ccEmails);
        mail.setSaveAsActivity(false);
        mail.setOrgWideEmailAddressId(orgWideEmailAddress);
        system.debug('mail++'+ mail);
        
        if(!Test.isRunningTest())
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        
    }
    
    public class TransactionResponse {
        public String message;
        public String TransactionID;
        public String url;
    }
    public class Data {
        public String Merchant;
        public String TransactionID;
        public String Asset;
        public Decimal RequestedAmount;
        public String Address;
        public Integer Expiry;
        public String Note;
        public String MerchantUUID;
        public String Name;
        public String Network;
        public String Protocol;
        public String url;
    }
    
}