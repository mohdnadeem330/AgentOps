/*
* Purpose: SRDocTriggerHandler to populate static documents from Project documents to SR Docs Based on project.
*/
public without sharing class SRDocTriggerHandler extends TriggerHandler{
    Id AGENCY_REGISTRATION_RECORDTYPEID = Schema.SObjectType.HexaBPM__Service_Request__c.getRecordTypeInfosByName().get('Agency Registration').getRecordTypeId();
 
     //*** Before Insert Action***//
    public override void beforeInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        Set<Id> setAgencyIds = new Set<Id>();
        Map<Id,HexaBPM__Service_Request__c> srMap = new Map<Id,HexaBPM__Service_Request__c>();
 
        for(HexaBPM__SR_Doc__c newRecord : (List<HexaBPM__SR_Doc__c>) newList){
            if(newRecord.HexaBPM__Service_Request__c != null && newRecord.Name.equalsIgnoreCase('Memorandum of Association/Power of Attorney')) {
                setAgencyIds.add(newRecord.HexaBPM__Service_Request__c);
            }
        }
 
        if(!setAgencyIds.isEmpty()){
            srMap = new Map<Id,HexaBPM__Service_Request__c>([SELECT Id FROM HexaBPM__Service_Request__c WHERE Id IN :setAgencyIds AND Country__c != 'United Arab Emirates' AND RecordTypeId = :AGENCY_REGISTRATION_RECORDTYPEID ]);
        }
 
        if(!srMap.isEmpty()){
            for(HexaBPM__SR_Doc__c newRecord : (List<HexaBPM__SR_Doc__c>) newList){
                if(srMap.containsKey(newRecord.HexaBPM__Service_Request__c)) {
                    newRecord.HexaBPM__Is_Not_Required__c = true;
                }
            }
        }
    }
    
    //*** After Insert Action***//
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        Map<String, String> srMapWithSrDoc = new Map<String, String>();
        Set<Id> moveInPermitSRIds = new Set<Id>();
        list<HexaBPM__SR_Doc__c> MCDDOcumentList = new list<HexaBPM__SR_Doc__c>();
        Map<String, List<String>> srMapWithSrDocType = new Map<String, List<String>>();
        for(HexaBPM__SR_Doc__c newRecord : (List<HexaBPM__SR_Doc__c>) newList){
            if( newRecord.HexaBPM__Service_Request__c !=null  && ( newRecord.Name.equalsIgnoreCase(Constants.DOCUMENT_TYPE_MCD) || newRecord.Name.equalsIgnoreCase(Constants.DOCUMENT_TYPE_SCHEDULE_A) || newRecord.Name.equalsIgnoreCase(Constants.DOCUMENT_TYPE_Bank_Letter) || newRecord.Name.equalsIgnoreCase(Constants.DOCUMENT_TYPE_Commercial_Trade_License)) ){
                MCDDOcumentList.add(newRecord);
            }
            
            if(newRecord.HexaBPM__Service_Request__c !=null) {
                if(!srMapWithSrDocType.containsKey(newRecord.HexaBPM__Service_Request__c)) {
                    srMapWithSrDocType.put(newRecord.HexaBPM__Service_Request__c, new List<String>());
                }
                
                List<String> docs = srMapWithSrDocType.get(newRecord.HexaBPM__Service_Request__c);
                docs.add(newRecord.Name);
                srMapWithSrDocType.put(newRecord.HexaBPM__Service_Request__c, docs);
            }

            //Added by tejaswini for sr 1110
            if (
                newRecord.HexaBPM__Service_Request__c !=null  &&
                newRecord.Name == 'Move In Permit' &&
                newRecord.HexaBPM__Status__c == 'Generated'                 
            ) 
            { 
                moveInPermitSRIds.add(newRecord.HexaBPM__Service_Request__c);
            }
            
            //End SR1110

            
            /*  if(newRecord.HexaBPM__Service_Request__c !=null && newRecord.Name == Constants.DOCUMENT_TYPE_SDDC) {
srMapWithSrDoc.put(newRecord.HexaBPM__Service_Request__c, newRecord.Id); 
}   */         
        }
        System.debug('afterInsertMethod');
        if(!MCDDOcumentList.isEmpty()){
            linkMCDDOcument(MCDDOcumentList);
        }
        
        if(!srMapWithSrDoc.isEmpty()) {
            //updateDocumentInSrDoc(srMapWithSrDoc);
        }
        
        if(!srMapWithSrDocType.isEmpty()){
            uploadDocumentFromAccount(srMapWithSrDocType);
        }
        
        
        //Tejaswini sr1110 
        if (!moveInPermitSRIds.isEmpty()) {    
            createMoveInPermitCases(moveInPermitSRIds);
        }           
        
        //End

        
        
    }
    
    /*public static void updateDocumentInSrDoc(Map<String, String> srMapWithSrDoc) {
Id propertyTransferRecordTypeId = Schema.SObjectType.HexaBPM__Service_Request__c.getRecordTypeInfosByName().get('Property Transfer').getRecordTypeId();
List<ContentDocumentLink> contentDocumentLinkList = new List<ContentDocumentLink>();
Map<Id, Id> salesOrderMapWithSrDoc = new Map<Id, Id>();
List<HexaBPM__SR_Doc__c> srDocList = [SELECT Id, HexaBPM__Service_Request__c, HexaBPM__Service_Request__r.SalesOrder__c FROM HexaBPM__SR_Doc__c WHERE Id IN :srMapWithSrDoc.KeySet() AND HexaBPM__Service_Request__r.RecordTypeId =:propertyTransferRecordTypeId];
 
for(HexaBPM__SR_Doc__c srDoc : srDocList) {
salesOrderMapWithSrDoc.put(srDoc.HexaBPM__Service_Request__r.SalesOrder__c, srDoc.Id);
}
 
List<Document__c> docuemntList = [SELECT Id, DocumentType__c, DirectDebitRequest__c, DirectDebitRequest__r.SalesOrder__c, (SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLinks LIMIT 1) FROM Document__c WHERE DirectDebitRequest__r.SalesOrder__c IN : salesOrderMapWithSrDoc.keySet() AND DocumentType__c =:Constants.DOCUMENT_TYPE_DDCF];
 
for(Document__c doc : docuemntList) {
for(ContentDocumentLink cdl : doc.ContentDocumentLinks){
//add file to SRDoc
Id srDocId = salesOrderMapWithSrDoc.get(doc.DirectDebitRequest__r.SalesOrder__c);
ContentDocumentLink cde = new ContentDocumentLink();
cde.ContentDocumentId = cdl.ContentDocumentId;
cde.LinkedEntityId = srDocId; // you can use objectId,GroupId etc
cde.ShareType = 'I'; // Inferred permission, checkout description of ContentDocumentLink object for more details
cde.Visibility = 'AllUsers';
contentDocumentLinkList.add(cde);
}
}
 
if(!contentDocumentLinkList.isEmpty()) {
insert contentDocumentLinkList;
}
}*/
    
    // sr 1110 added by Tejaswini for case creation after move in permit doc genration
    public static void createMoveInPermitCases(Set<Id> moveInPermitSRIds) {
        system.debug('in createMoveInPermitCases method');
        List<HexaBPM__Service_Request__c> srListCase = new List<HexaBPM__Service_Request__c>(
            [  SELECT Id,SRType__c, HexaBPM__Customer__c,HexaBPM__Contact__c,HexaBPM__Customer__r.Name,Unit__c,Move_In_Date__c,SalesOrder__c FROM HexaBPM__Service_Request__c WHERE Id IN :moveInPermitSRIds
            ]
        );
        
        Group onboardingQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Move_In_Onboarding'  LIMIT 1];
        List<Case> caseList = new List<Case>();
        for (HexaBPM__Service_Request__c sr : srListCase) {
            if(sr.SRType__c == 'Aldar Estates Move-In'){
                Case caseRec = new Case();
                caseRec.Status = 'New';
                caseRec.Subject = 'Move In Onboarding Case';
                caseRec.Priority = 'Medium';
                caseRec.OwnerId = onboardingQueue.Id;
                caseRec.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('FeedbackCase').getRecordTypeId();
                caseRec.CaseComments__c = 'Move In Feedback';
                caseRec.CustomerType__c = 'Owner';
                caseRec.Origin = 'Phone';
                caseRec.SubVertical__c = 'Customer Onboarding Move-in';
                caseRec.SubCategory__c = 'Customer Onboarding Move-in';
                caseRec.CaseCategory__c = 'Customer Onboarding';
                caseRec.ServiceRequest__c = sr.Id;
                caseRec.Vertical__c = 'Customer Management';
                caseRec.Unit__c = sr.Unit__c;
                caseRec.Move_In_Date__c = sr.Move_In_Date__c;
                caseRec.SalesOrder__c = sr.SalesOrder__c;
                caseRec.AccountId = sr.HexaBPM__Customer__c;
                caseRec.ContactId = sr.HexaBPM__Contact__c;
                caseList.add(caseRec);
                
            }
            
        }
             
        if (!caseList.isEmpty()) {
            try {
                insert caseList;
                
            } catch (Exception ex) {
                System.debug('Error inserting cases: ' + ex.getMessage());
            }
        }
    }
    
    //End SR1110

    
    
    
    public static void mapLpcDetilsToHandoverSR(List<Id> srIds){
        System.debug('*** mapLpcDetilsToHandoverSR ***'+srIds);
        List<HexaBPM__Service_Request__c> sRRecordList=[select Id,SalesOrder__c from HexaBPM__Service_Request__c where Id IN:srIds];       
        for(HexaBPM__Service_Request__c sr:sRRecordList){
            LPCModel lpcDetail = LPCService.getOutstandingLPCforSalesOrder(sr.SalesOrder__c);
            sr.TotalLPCDue__c = lpcDetail.totalLPCDue!=null?lpcDetail.totalLPCDue.setScale(2):0;
            sr.LPCCalculatedDate__c = Date.today();
        }
        
        update sRRecordList;
    }
    
    //*** After Update Action***//
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        
        //HexaBPM__Service_Request__c
        list<HexaBPM__Step__c> stepsRelatedToSPA = new list<HexaBPM__Step__c>();
        list<HexaBPM__Service_Request__c> srRelatedToSPA = new list<HexaBPM__Service_Request__c>();
        Set<Id> srIdset = new Set<Id>();
        Set<Id> provisSRIdset = new Set<Id>();
        List<String> srDocNames = System.Label.ProvisNOCRequiredDocs.contains(',')?System.Label.ProvisNOCRequiredDocs.split(','):new List<String> {System.Label.ProvisNOCRequiredDocs};
 
       // Map<HexaBPM__SR__c,HexaBPM__Step__c>    
      //  List<HexaBPM__Step__c> provisDocRejected =[SELECT Id,HexaBPM__SR__c,HexaBPM__Status__r.Name FROM HexaBPM__Step__c WHERE  HexaBPM__SR__r.SRType__c = 'Property Transfer NOC' AND HexaBPM__Summary__c ='Pending upload Provis Docs by Customer' and HexaBPM__Status__r.Name ='Completed'];
        Set<Id> poaVerifiedDocSRId = new Set<Id>();    
        list<Id> allSRsIds = new list<Id>();
        List<Id> handOverSrIds = new list<Id>();
        for(HexaBPM__SR_Doc__c newRecord : (List<HexaBPM__SR_Doc__c>) newList){
            if( newRecord.HexaBPM__Service_Request__c !=null){
                allSRsIds.add(newRecord.HexaBPM__Service_Request__c);
                if(newRecord.DocumentMasterCode__c.equalsIgnoreCase('Handover NOC Letter') && newRecord.HexaBPM__Generate_Document__c==true){
                    handOverSrIds.add(newRecord.HexaBPM__Service_Request__c); 
                }
                if(newRecord.HexaBPM__Status__c =='Uploaded' && newRecord.HexaBPM__Status__c != oldMap.get(newRecord.Id).get('HexaBPM__Status__c') && newRecord.Name == 'CCA Form'){
                    srIdset.add(newRecord.HexaBPM__Service_Request__c);
                }
                if(newRecord.HexaBPM__Status__c =='Uploaded' && newRecord.HexaBPM__Status__c != oldMap.get(newRecord.Id).get('HexaBPM__Status__c')){
                    provisSRIdset.add(newRecord.HexaBPM__Service_Request__c);
                }
                if(newRecord.DocumentMasterCode__c.equalsIgnoreCase('POA_Document') && newRecord.HexaBPM__Status__c =='Uploaded'){
                    poaVerifiedDocSRId.add(newRecord.HexaBPM__Service_Request__c);
                }
            }
        }
        If(!poaVerifiedDocSRId.isEmpty()){
            CC_PropertyTransferOffplanValidation.poaVerifiedStepStatusCheck(poaVerifiedDocSRId);
        }
 
        //Added by Rajat Jain For JIRA ticket 566
        set<Id> serviceReqIdset = new set<Id>();
        for(HexaBPM__SR_Doc__c newRecord : (List<HexaBPM__SR_Doc__c>) newList){
            HexaBPM__SR_Doc__c oldRecord = (HexaBPM__SR_Doc__c)oldMap.get(newRecord.Id);
           if(newRecord.HexaBPM__Status__c !=oldRecord.HexaBPM__Status__c && newRecord.Is_Provis_Document_Accepted__c==true)
           {
               serviceReqIdset.add(newRecord.HexaBPM__Service_Request__c);
           }
        }
        if(!serviceReqIdset.IsEmpty())
        {
            CC_ProvisNOCValidationCtrl.provisDocCloseStp(serviceReqIdset);
        }
        
        // End Code JIRA 566
        
        
        
        
        
        
        
        System.debug('srIdset:'+srIdset);
        Map<Id, HexaBPM__Service_Request__c> srMap = new Map<Id, HexaBPM__Service_Request__c>();
        
        if(allSRsIds.size() > 0){
            srMap = new Map<Id, HexaBPM__Service_Request__c>(ServiceRequestService.queryAllFieldsWithExtraFields(allSRsIds));
        }
        // SPA Payment Step logic: to close the step if the payment is cone from DARI.
        String stepNotes = Utilities.getSystemMessages(Constants.SPA_PAYMENT_STEP_FROM_DARI).Message__c;
        set<String> snagCommsDoc = new set<String>{Constants.HO_DOC_CUST_SNAG, Constants.HO_DOC_CUST_DESNAG};
            map<id,String> SRIDsForSnagComs = new  map<id,string>();
        map<id,String> homeOrientationComms = new  map<id,string>();
        for(HexaBPM__SR_Doc__c newRecord : (List<HexaBPM__SR_Doc__c>) newList){
            HexaBPM__SR_Doc__c oldRecord = (HexaBPM__SR_Doc__c)oldMap.get(newRecord.Id);
            //get Handover detail
            if(snagCommsDoc.contains(newRecord.DocumentMasterCode__c) && snagCommsDoc.contains(newRecord.Name) && newRecord.HexaBPM__Doc_ID__c != oldRecord.HexaBPM__Doc_ID__c){
                SRIDsForSnagComs.put(newRecord.HexaBPM__Service_Request__c, newRecord.DocumentMasterCode__c);
            }
            
            /*
if(newRecord.HexaBPM__Doc_ID__c !=null && newRecord.DocumentMasterCode__c=='Home Orientation Letter'&& newRecord.HexaBPM__Doc_ID__c != oldRecord.HexaBPM__Doc_ID__c){
homeOrientationComms.put(newRecord.ID, newRecord.DocumentMasterCode__c);
}
*/
            
            if( newRecord.HexaBPM__Service_Request__c !=null  && newRecord.HexaBPM__Status__c != oldRecord.HexaBPM__Status__c && newRecord.HexaBPM__Status__c == Constants.DOCUMENT_STATUS_UPLOADED &&
               (newRecord.Name.equalsIgnoreCase(Constants.ADM_RECEIPT_SRDOC) || newRecord.Name.equalsIgnoreCase(Constants.SPA_REGISTRATION_SRDOC))){
                   if(srMap.containsKey(newRecord.HexaBPM__Service_Request__c) && srMap.get(newRecord.HexaBPM__Service_Request__c).HexaBPM__Record_Type_Name__c == Constants.SPA_REGISTRATION_DEV_RT){
                       
                       HexaBPM__Service_Request__c sr = new HexaBPM__Service_Request__c(Id=newRecord.HexaBPM__Service_Request__c);
                       if(newRecord.Name.equalsIgnoreCase(Constants.ADM_RECEIPT_SRDOC)){
                           if(!srMap.get(newRecord.HexaBPM__Service_Request__c).Proceed_with_Offline__c){
                               sr.PaymentDate__c = Date.today();
                           }
                           HexaBPM__SR_Status__c objSRStatus = [SELECT Id, Name FROM HexaBPM__SR_Status__c WHERE Name =: Constants.SR_STATUS_CLOSED LIMIT 1];
                           sr.HexaBPM__External_SR_Status__c = objSRStatus.Id;
                           sr.HexaBPM__Internal_SR_Status__c = objSRStatus.Id;
                       } else {
                           if(!srMap.get(newRecord.HexaBPM__Service_Request__c).Proceed_with_Offline__c){
                               sr.RegistrationDate__c = Date.today();
                           }
                       }
                       srRelatedToSPA.add(sr);
                       
                       HexaBPM__Step__c stp = SRUtility.updateMultipleServiceRequestStep(newRecord.HexaBPM__Service_Request__c, Constants.SPA_PAYMENT_STEP, Constants.COMPLETED_STATUS, stepNotes, Constants.STEP_STATUS_PENDING);
                       if(stp != null){
                           stepsRelatedToSPA.add(stp);
                       }
                   }
               }
        }
        if(!stepsRelatedToSPA.isEmpty()){
            update stepsRelatedToSPA;
        }
        if(!srRelatedToSPA.isEmpty()){
            update srRelatedToSPA;
        }
        if(!SRIDsForSnagComs.isEmpty()){ sendSnagComms(SRIDsForSnagComs);
                                       }
        /*
if(!homeOrientationComms.isEmpty()){
System.debug('*** Send Grid Call'+homeOrientationComms.KeySet());
SendGridIntegrationController.sendHandoverPhasingLetter(new List<ID>(homeOrientationComms.KeySet()), 'tpl_ho2');
}
*/
        if(!handOverSrIds.isEmpty()){
            mapLpcDetilsToHandoverSR(handOverSrIds);
        }
        if(!srIdset.isEmpty()){
           // DefaultAndTerminationUtility.updateCCAFormUploadDate(srIdset);
        }
        if(!provisSRIdset.isEmpty()){
            CC_ProvisNOCValidationCtrl.provisDocCloseStp(provisSRIdset);
        }
        
        map<string, HexaBPM__Status__c> stepStatusMap = new map<string, HexaBPM__Status__c>();
        for (HexaBPM__Status__c srStepStatus : [SELECT Id, Name FROM HexaBPM__Status__c WHERE Name IN ('Completed')]) {
            stepStatusMap.put(srStepStatus.Name, srStepStatus);
        }
        for (HexaBPM__SR_Doc__c newRecord : (List<HexaBPM__SR_Doc__c>) newList) {
            if (newRecord.SRTemplateName__c == 'Property Transfer NOC' ) {
                system.debug('Invoked SR Step Automation method');
                handleSRStepAutomation(newRecord, stepStatusMap);
            }
        }
    }
    
    public static void sendSnagComms (map<ID,String> srIdToCommsMap){
        set<ID> snagComs = new set<id>();
        set<ID> desnagComs = new set<id>();
        map<id,HandoverDetails__c> hoToDesnag = new map<id,HandoverDetails__c>();
        for(HexaBPM__Service_Request__c sr : [select id,HandoverDetail__c,HandoverDetail__r.CustomerDesnaggingDate__c from HexaBPM__Service_Request__c where id in :srIdToCommsMap.KeySet() and HandoverDetail__c !=null]){
            if(srIdToCommsMap.get(sr.Id) == Constants.HO_DOC_CUST_SNAG ){ snagComs.add(sr.HandoverDetail__c);
                                                                        }else if(srIdToCommsMap.get(sr.Id) == Constants.HO_DOC_CUST_DESNAG ){  desnagComs.add(sr.HandoverDetail__c);
                                                                                                                                            }
            if(srIdToCommsMap.get(sr.Id) == Constants.HO_DOC_CUST_DESNAG && sr.HandoverDetail__r.CustomerDesnaggingDate__c ==null){ hoToDesnag.put(sr.HandoverDetail__c , new HandoverDetails__c(id=sr.HandoverDetail__c,CustomerDesnaggingDate__c=system.today()));
                                                                                                                                  }
        }
        if(!snagComs.isEmpty()){ HandoverUtility.sendSnags(snagComs);
                               }
        if(!desnagComs.isEmpty()){ HandoverUtility.sendDesnags(desnagComs);
                                 }
        if(!hoToDesnag.isEmpty()){update hoToDesnag.values();}
    }
    // Link the MCD Document from project levelt to respective Service Request records
    public static void linkMCDDOcument(list<HexaBPM__SR_Doc__c> newDocuments){
        //getall the Project's GTC documentLink
        map<String,ID> projectToDocumentMap = new map<String,Id>();
        
        map<String,ID> projectToGenericDocumentMap = new map<String,Id>();     
        
        //Prepare Project & ( MCD Document / Schedule A) map
        for(Document__c tempProjectDocs : [select id,DocumentType__c, Project__c from Document__c where (DocumentType__c =:Constants.DOCUMENT_TYPE_MCD  OR DocumentType__c =:Constants.DOCUMENT_TYPE_Schedule_A) and Project__c !=null ]){
            projectToDocumentMap.put(tempProjectDocs.Project__c+'_'+tempProjectDocs.DocumentType__c, tempProjectDocs.Id );
        }
        
        //Prepare Document Type & ( Aldar Commercial Trade License / Bank Letter) Document Map
        for(Document__c tempProjectDocs : [select id,Project__c, DocumentType__c from Document__c where ( DocumentType__c =:Constants.DOCUMENT_TYPE_Commercial_Trade_License OR DocumentType__c =:Constants.DOCUMENT_TYPE_Bank_Letter ) and Project__c =null ]){
            projectToGenericDocumentMap.put(tempProjectDocs.DocumentType__c, tempProjectDocs.Id );
        }
        
        map<ID,contentDocumentLink> documentToCDLLink = new map<id,contentDocumentLink>();
        if(projectToDocumentMap.size() > 0){
            for(contentDocumentLink cdl : [ select id, ContentDocumentId,linkedEntityId from contentDocumentLink where linkedEntityId in :projectToDocumentMap.values() ]){
                documentToCDLLink.put(cdl.linkedEntityId,cdl);
            }
        }
        map<ID,contentDocumentLink> genericDocumentToCDLLink = new map<id,contentDocumentLink>();
        if(projectToGenericDocumentMap.size() > 0){
            for(contentDocumentLink cdl : [ select id, ContentDocumentId,linkedEntityId from contentDocumentLink where linkedEntityId in :projectToGenericDocumentMap.values() ]){
                genericDocumentToCDLLink.put(cdl.linkedEntityId,cdl);
            }            
        }
        
        //Get Project associated with inserted Document
        map<Id,Id> soToProjectMap = new map<id,Id>();
        for(HexaBPM__SR_Doc__c tempDocRec: newDocuments){
            soToProjectMap.put(tempDocRec.HexaBPM__Service_Request__c,null);
        }
        for(HexaBPM__Service_Request__c sr : [select id,Unit__r.Project__c from HexaBPM__Service_Request__c where id in :soToProjectMap.keySet() ]){
            soToProjectMap.put(sr.Id,sr.Unit__r.Project__c);
        }
        
        //create CDL
        //update HexaBPM__SR_Doc__c records
        list<HexaBPM__SR_Doc__c> docStatusToUpdate = new list<HexaBPM__SR_Doc__c>();
        list<contentDocumentLink> cdlToInsert = new list<contentDocumentLink>();
        for(HexaBPM__SR_Doc__c tempDocRec: newDocuments){
            if(soToProjectMap.get(tempDocRec.HexaBPM__Service_Request__c)!=null && projectToDocumentMap.containsKey(soToProjectMap.get(tempDocRec.HexaBPM__Service_Request__c)+'_'+tempDocRec.Name) && documentToCDLLink.containsKey(projectToDocumentMap.get(soToProjectMap.get(tempDocRec.HexaBPM__Service_Request__c)+'_'+tempDocRec.Name)) ){
                System.debug('ContentDocumentId ');                
                cdlToInsert.add(new contentDocumentLink(ContentDocumentId = documentToCDLLink.get(projectToDocumentMap.get(soToProjectMap.get(tempDocRec.HexaBPM__Service_Request__c)+'_'+tempDocRec.Name)).ContentDocumentId,
                                                        LinkedEntityId= tempDocRec.id,ShareType='V',Visibility='InternalUsers'));
                docStatusToUpdate.add(new HexaBPM__SR_Doc__c(id= tempDocRec.Id, HexaBPM__Status__c = Constants.DOCUMENT_STATUS_GENERATED));
            }
            
            if(projectToGenericDocumentMap.get(tempDocRec.Name) != null && genericDocumentToCDLLink.containsKey(projectToGenericDocumentMap.get(tempDocRec.Name)) && projectToGenericDocumentMap.containsKey(tempDocRec.Name)) {
                
                cdlToInsert.add(new contentDocumentLink(ContentDocumentId = genericDocumentToCDLLink.get(projectToGenericDocumentMap.get(tempDocRec.Name)).ContentDocumentId, LinkedEntityId= tempDocRec.id,ShareType='V',Visibility='InternalUsers'));
                docStatusToUpdate.add(new HexaBPM__SR_Doc__c(id= tempDocRec.Id, HexaBPM__Status__c = Constants.DOCUMENT_STATUS_GENERATED));
            }
        }
        if(!cdlToInsert.isEmpty()){
            insert cdlToInsert;
        }
        if(!docStatusToUpdate.isEmpty()){
            update docStatusToUpdate;
        }
        
    }
    
    //upload document from Account to SR
    public static void uploadDocumentFromAccount(Map<String, List<String>> srMapWithSrDocType) {
        Id propertyTransferRecordTypeId = Schema.SObjectType.HexaBPM__Service_Request__c.getRecordTypeInfosByName().get('Property Transfer').getRecordTypeId();
        Set<Id> accList = new Set<Id>();
        Map<Id, HexaBPM__Service_Request__c> srMap = new Map<Id, HexaBPM__Service_Request__c>([SELECT Id, BuyerName__c, HexaBPM__Customer__c FROM HexaBPM__Service_Request__c WHERE Id IN:srMapWithSrDocType.keySet() AND RecordTypeId =:propertyTransferRecordTypeId]);
        List<ContentDocumentLink> contentDocumentLinkList = new List<ContentDocumentLink>();
        //fetch account documents
        List<String> docType = new List<String>{'Passport Copy', 'Emirates ID Copy'};
            List<String> srDocType = new List<String>{'Buyer Passport Copy', 'Buyer Emirates ID Copy', 'Seller Passport Copy', 'Seller Emirates ID Copy'};
                for(HexaBPM__Service_Request__c sr : srMap.values()){
                    if(sr.BuyerName__c != null) {
                        accList.add(sr.BuyerName__c);
                    }
                    
                    if(sr.HexaBPM__Customer__c != null) {
                        accList.add(sr.HexaBPM__Customer__c);
                    }
                }
        List<Document__c> docList = [SELECT Id, DocumentType__c, Account__c, (SELECT Id, ContentDocumentId FROM ContentDocumentLinks) FROM Document__c WHERE DocumentType__c IN :docType AND Account__c IN :accList]; 
        
        List<HexaBPM__SR_Doc__c> srDocList = [SELECT Id, Name, HexaBPM__Service_Request__c, (SELECT Id, ContentDocumentId FROM ContentDocumentLinks) FROM HexaBPM__SR_Doc__c WHERE Name IN :srDocType AND HexaBPM__Service_Request__c IN:srMap.keySet()];
        //can be nested because it always be 2
        String prefix = '';
        List<HexaBPM__SR_Doc__c> srDocUpdatedList = new List<HexaBPM__SR_Doc__c>();
        
        for(Document__c doc : docList) {
            for(HexaBPM__SR_Doc__c srDoc : srDocList) {
                HexaBPM__Service_Request__c sr = srMap.get(srDoc.HexaBPM__Service_Request__c);
                prefix = doc.Account__c == sr.BuyerName__c ? 'Buyer' : 'Seller';
                
                if(srDoc.Name == (prefix + ' ' + doc.DocumentType__c) && (doc.Account__c == sr.BuyerName__c || doc.Account__c == sr.HexaBPM__Customer__c)) {
                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.LinkedEntityId = srDoc.Id;
                    cdl.ContentDocumentId = doc.ContentDocumentLinks[0].ContentDocumentId;
                    cdl.ShareType = 'V';
                    cdl.Visibility = 'AllUsers';
                    contentDocumentLinkList.add(cdl);
                    
                    srDoc.HexaBPM__Status__c = 'Uploaded';
                    srDocUpdatedList.add(srDoc);
                }
            }
        }
        
        if(!contentDocumentLinkList.isEmpty()) {
            insert contentDocumentLinkList;
            update srDocUpdatedList;
        }
    }
    
    public static void closeDubaRAKDocStep(){
        
    }    
    
     //Start || SR Step automation || Added by Agniwesh
   public static void handleSRStepAutomation(HexaBPM__SR_Doc__c newRecord, map<string, HexaBPM__Status__c> stepStatusMap){
    List<HexaBPM__Step__c> srStepsToUpdateList = new List<HexaBPM__Step__c>();
    List<Id> srIdList = new List<Id>();
    
       if (Test.isRunningTest() || newRecord.SRTemplateName__c == 'Property Transfer NOC') {
        srIdList.add(newRecord.HexaBPM__Service_Request__c);
    }
    
    List<HexaBPM__Service_Request__c> relatedSR = [SELECT ID, Has_OA_NOC__c FROM HexaBPM__Service_Request__c WHERE Id IN :srIdList AND origin__c='Customer Portal' AND srtype__c='Property Transfer NOC'];
    
    if (!srIdList.isEmpty()) {
        String srIdStr = String.join(srIdList, '\',\'');
        String whrClause = 'HexaBPM__Service_Request__c IN (\'' + srIdStr + '\') AND (Name=\'Signed Owner Association Letter\' OR Name=\'Signed Document of Adherence\' OR Name=\'Signed Assignment of Service Charge\') AND HexaBPM__Status__c=\'Uploaded\'';
        List<HexaBPM__SR_Doc__c> srDocList = CustomerServiceUtility.getSRDocDetail(whrClause);
        
        Boolean hasSignedOwnerAssocLetter = false;
        Boolean hasSignedDocumentAdherence = false;
        Boolean hasSignedAssignmentOfServiceCharge = false;
 
        for (HexaBPM__SR_Doc__c doc : srDocList) {
            if (doc.Name == 'Signed Owner Association Letter') {  hasSignedOwnerAssocLetter = true;}
            if (doc.Name == 'Signed Document of Adherence') { hasSignedDocumentAdherence = true;}
            if (doc.Name == 'Signed Assignment of Service Charge') {hasSignedAssignmentOfServiceCharge = true;}
        }
 
        if ( !srDocList.Isempty() && hasSignedOwnerAssocLetter && hasSignedDocumentAdherence && relatedSR[0].Has_OA_NOC__c == true) {
            List<HexaBPM__Step__c> srStepsToProcess = [SELECT Id, HexaBPM__Status__c, HexaBPM__SR__c FROM HexaBPM__Step__c WHERE HexaBPM__SR__c IN :srIdList AND HexaBPM__Summary__c IN ('Signing of the Transfer Documents & Collecting the Transfer Charges') AND HexaBPM__Step_Status__c = 'Pending'];
            system.debug('srStepsToProcess ::' + srStepsToProcess);
            for (HexaBPM__Step__c srStep : srStepsToProcess) {
                if (stepStatusMap.containsKey('Completed')) {srStep.HexaBPM__Status__c = stepStatusMap.get('Completed').Id;srStepsToUpdateList.add(srStep);}
            }
        }
       
       // This condition is Commented as business need to complete "Verify the Customer Documents" manuual close.
        /*else if (hasSignedAssignmentOfServiceCharge && relatedSR[0].Has_OA_NOC__c == false) {
            List<HexaBPM__Step__c> srStepsToProcess = [SELECT Id, HexaBPM__Status__c, HexaBPM__SR__c FROM HexaBPM__Step__c WHERE HexaBPM__SR__c IN :srIdList AND HexaBPM__Summary__c IN ('Verify the Customer Documents') AND HexaBPM__Step_Status__c = 'Pending'];
            
            for (HexaBPM__Step__c srStep : srStepsToProcess) {
                if (stepStatusMap.containsKey('Completed')) {srStep.HexaBPM__Status__c = stepStatusMap.get('Completed').Id;srStepsToUpdateList.add(srStep); }
            }
        }*/
        
        
        if (!srStepsToUpdateList.isEmpty()) {update srStepsToUpdateList;
            //system.debug('updated successfully::' + srStepsToUpdateList[0].Name + '::status::' + srStepsToUpdateList[0].HexaBPM__Status__r.Name);
        }
    }
}
 
    //End || SR Step automation || Added by Agniwesh
}