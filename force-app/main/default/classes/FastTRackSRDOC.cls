public class FastTRackSRDOC implements Queueable {
    
    private HexaBPM__Service_Request__c serviceRequest;
    
    public FastTRackSRDOC(HexaBPM__Service_Request__c serviceRequest) {
        this.serviceRequest = serviceRequest;
    }
    
    public void execute(QueueableContext context) {
        List<Account> accList = [SELECT Id, FastTrackedAccount__c, FasttrackCompletionDate__c,FastTrack_Account__c FROM Account WHERE Id = :serviceRequest.BuyerName__c];
        try{
            Id SRrecordType = Schema.SObjectType.HexaBPM__Service_Request__c.getRecordTypeInfosByName().get('Property Transfer NOC').getRecordTypeId();
            if (!accList.isEmpty() && serviceRequest.Retrive_Buyer_Acc_Docs__c == true) {
                Account acc = accList[0];
                Document__c nationalIdBack= new Document__c();
                System.debug('FastTRackSRDOC line 12');
                Document__c nationalLink = [SELECT Id, DocumentType__c FROM Document__c WHERE Account__c = :acc.Id AND DocumentType__c = 'National ID Front Copy' LIMIT 1];
                Document__c passportLink = [SELECT Id, DocumentType__c FROM Document__c WHERE Account__c = :acc.Id AND DocumentType__c = 'Passport Copy' LIMIT 1];
                System.debug('Test'+serviceRequest);
                if(serviceRequest.RecordTypeId ==SRrecordType){
                    nationalIdBack = [SELECT Id, DocumentType__c FROM Document__c WHERE Account__c = :acc.Id AND DocumentType__c = 'National ID Back Copy' LIMIT 1];
                    
                }
                System.debug('FastTRackSRDOC nationalLink' +nationalLink.Id );
                if (nationalLink != null) {
                    List<ContentDocumentLink> national = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :nationalLink.Id LIMIT 1];
                    //   System.debug('FastTRackSRDOC nationalLink doc id ' + national[0].ContentDocumentId );
                    HexaBPM__SR_Doc__c SRDOCnational = [SELECT Id, HexaBPM__Doc_ID__c FROM HexaBPM__SR_Doc__c WHERE HexaBPM__Service_Request__c = :serviceRequest.Id AND Name = 'Buyer Emirates ID Copy' LIMIT 1];
                    
                    if (SRDOCnational != null && SRDOCnational.HexaBPM__Doc_ID__c == null && national.size() >0) {SRDOCnational.HexaBPM__Doc_ID__c = national[0].ContentDocumentId;SRDOCnational.HexaBPM__Status__c = 'Uploaded';update SRDOCnational;
                        
                        ContentDocumentLink cDocLink1 = new ContentDocumentLink();cDocLink1.ContentDocumentId = national[0].ContentDocumentId;cDocLink1.LinkedEntityId = SRDOCnational.ID;cDocLink1.ShareType = 'V';cDocLink1.Visibility = 'AllUsers';Insert cDocLink1;
                    }
                }
                
                if (passportLink != null) {
                    List<ContentDocumentLink> passport = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :passportLink.Id LIMIT 1];
                    
                    HexaBPM__SR_Doc__c SRDOCPass = [SELECT Id, HexaBPM__Doc_ID__c FROM HexaBPM__SR_Doc__c WHERE HexaBPM__Service_Request__c = :serviceRequest.Id AND Name = 'Buyer Passport Copy' LIMIT 1];
                    
                    if (SRDOCPass != null && SRDOCPass.HexaBPM__Doc_ID__c == null && passport.size() >0) {SRDOCPass.HexaBPM__Doc_ID__c = passport[0].ContentDocumentId;SRDOCPass.HexaBPM__Status__c = 'Uploaded';update SRDOCPass;
                        
                        ContentDocumentLink cDocLink1 = new ContentDocumentLink();cDocLink1.ContentDocumentId = passport[0].ContentDocumentId;cDocLink1.LinkedEntityId = SRDOCPass.ID;cDocLink1.ShareType = 'V';cDocLink1.Visibility = 'AllUsers';Insert cDocLink1;
                    }
                }
                if (nationalIdBack != null){
                    List<ContentDocumentLink> national = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :nationalIdBack.Id LIMIT 1];
                  List<HexaBPM__SR_Doc__c> nationalIdBackSRDoc = [SELECT Id, HexaBPM__Doc_ID__c FROM HexaBPM__SR_Doc__c WHERE HexaBPM__Service_Request__c = :serviceRequest.Id AND Name = 'Buyer Emirates ID BackSideCopy' LIMIT 1];
                    
                    if (nationalIdBackSRDoc.size() >0 && nationalIdBackSRDoc[0].HexaBPM__Doc_ID__c == null && !Test.isRunningTest() && national.size()>0 ) {nationalIdBackSRDoc[0].HexaBPM__Doc_ID__c = national[0].ContentDocumentId;nationalIdBackSRDoc[0].HexaBPM__Status__c = 'Uploaded';update nationalIdBackSRDoc[0];
                        ContentDocumentLink cDocLink1 = new ContentDocumentLink();cDocLink1.ContentDocumentId = national[0].ContentDocumentId;cDocLink1.LinkedEntityId = nationalIdBackSRDoc[0].ID;cDocLink1.ShareType = 'V';cDocLink1.Visibility = 'AllUsers';Insert cDocLink1;
                    }
                }
                
            }
            if(serviceRequest.RecordTypeId ==SRrecordType){
                List<Account> accListSeller = [SELECT Id, FastTrackedAccount__c, FasttrackCompletionDate__c,FastTrack_Account__c FROM Account WHERE Id = :serviceRequest.HexaBPM__Customer__c];
                
                
                if (!accList.isEmpty() && serviceRequest.Retrive_Buyer_Acc_Docs__c == true) {
                    Account acc = accListSeller[0];
                    System.debug('FastTRackSRDOC line 12');
                    Document__c nationalLink = [SELECT Id, DocumentType__c FROM Document__c WHERE Account__c = :acc.Id AND DocumentType__c = 'National ID Front Copy' LIMIT 1];
                    Document__c passportLink = [SELECT Id, DocumentType__c FROM Document__c WHERE Account__c = :acc.Id AND DocumentType__c = 'Passport Copy' LIMIT 1];
                    Document__c   nationalIdBackCustomer = [SELECT Id, DocumentType__c FROM Document__c WHERE Account__c = :acc.Id AND DocumentType__c = 'National ID Back Copy' LIMIT 1];
                    
                    System.debug('FastTRackSRDOC nationalLink' +nationalLink.Id );
                    if (nationalLink != null) {
                        List<ContentDocumentLink> national = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :nationalLink.Id LIMIT 1];
                        //   System.debug('FastTRackSRDOC nationalLink doc id ' + national[0].ContentDocumentId );
                        HexaBPM__SR_Doc__c SRDOCnational = [SELECT Id, HexaBPM__Doc_ID__c FROM HexaBPM__SR_Doc__c WHERE HexaBPM__Service_Request__c = :serviceRequest.Id AND Name = 'Seller Emirates ID Copy' LIMIT 1];
                        
                        if (SRDOCnational != null && SRDOCnational.HexaBPM__Doc_ID__c == null && national.size() >0) {SRDOCnational.HexaBPM__Doc_ID__c = national[0].ContentDocumentId;SRDOCnational.HexaBPM__Status__c = 'Uploaded';update SRDOCnational;
						 ContentDocumentLink cDocLink1 = new ContentDocumentLink();cDocLink1.ContentDocumentId = national[0].ContentDocumentId;cDocLink1.LinkedEntityId = SRDOCnational.ID;cDocLink1.ShareType = 'V';cDocLink1.Visibility = 'AllUsers';Insert cDocLink1;
                        }
                    }
                    
                    if (passportLink != null) {
                        List<ContentDocumentLink> passport = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :passportLink.Id LIMIT 1];
                        
                        HexaBPM__SR_Doc__c SRDOCPass = [SELECT Id, HexaBPM__Doc_ID__c FROM HexaBPM__SR_Doc__c WHERE HexaBPM__Service_Request__c = :serviceRequest.Id AND Name = 'Seller Passport Copy' LIMIT 1];
                        
                        if (SRDOCPass != null && SRDOCPass.HexaBPM__Doc_ID__c == null && passport.size() >0) {SRDOCPass.HexaBPM__Doc_ID__c = passport[0].ContentDocumentId;SRDOCPass.HexaBPM__Status__c = 'Uploaded';update SRDOCPass;
                                                 ContentDocumentLink cDocLink1 = new ContentDocumentLink();cDocLink1.ContentDocumentId = passport[0].ContentDocumentId;cDocLink1.LinkedEntityId = SRDOCPass.ID;cDocLink1.ShareType = 'V';cDocLink1.Visibility = 'AllUsers';Insert cDocLink1;
                        }
                    }
                    if (nationalIdBackCustomer != null){
                        List<ContentDocumentLink> nationalIdBackCustomercd = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :nationalIdBackCustomer.Id LIMIT 1];
                       List<HexaBPM__SR_Doc__c> nationalIdBackCustomerSRDoc = [SELECT Id, HexaBPM__Doc_ID__c FROM HexaBPM__SR_Doc__c WHERE HexaBPM__Service_Request__c = :serviceRequest.Id AND Name = 'Seller Emirates ID BackSideCopy' LIMIT 1];
                        
                        if (nationalIdBackCustomerSRDoc.size() >0 && nationalIdBackCustomercd.size() >0 && nationalIdBackCustomerSRDoc[0].HexaBPM__Doc_ID__c == null ) {
                            nationalIdBackCustomerSRDoc[0].HexaBPM__Doc_ID__c = nationalIdBackCustomercd[0].ContentDocumentId;nationalIdBackCustomerSRDoc[0].HexaBPM__Status__c = 'Uploaded';update nationalIdBackCustomerSRDoc[0];ContentDocumentLink cDocLink1 = new ContentDocumentLink();
							cDocLink1.ContentDocumentId = nationalIdBackCustomercd[0].ContentDocumentId;cDocLink1.LinkedEntityId = nationalIdBackCustomerSRDoc[0].ID;cDocLink1.ShareType = 'V';cDocLink1.Visibility = 'AllUsers';Insert cDocLink1;
                        }
                    }
                }
            }
        }Catch(Exception e){
            System.debug ('Error FastTRackSRDOC'+e.getmessage());
			Logger__c lgs = LoggerService.createApexLog(e,'FasttrackSRDOC','FastTRackSRDOC','execute');
            
        }
    }
}