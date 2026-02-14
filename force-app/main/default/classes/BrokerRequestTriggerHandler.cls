public with sharing class BrokerRequestTriggerHandler extends TriggerHandler{
    //*** Before Insert Action***//
    public override void beforeInsertMethod(List<SObject> newList, Map<Id, SObject> newMap){
        User currentUser = Utilities.getLoggedInUserDetail();

        for(BrokerRequest__c br: (List<BrokerRequest__c>)newList){
            br.SyncStatus__c = Constants.STATUS_IN_PROGRESS;
            if (br.Remark__c != null) {
                br.Comment__c = currentUser.Name + ' (' + System.now().format() + ')\n-----\n' + br.Remark__c + '\n\n' + (br.Comment__c != null ? br.Comment__c : '');
                br.Remark__c = '';
            } 
        }
    }

    //*** Before Insert Action***//
    public override void beforeUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){
        User currentUser = Utilities.getLoggedInUserDetail();
        for(BrokerRequest__c br: (List<BrokerRequest__c>)newList){
            if (br.Remark__c != null) {
                br.Comment__c = currentUser.Name + ' (' + System.now().format() + ')\n-----\n' + br.Remark__c + '\n\n' + (br.Comment__c != null ? br.Comment__c : '');
                br.Remark__c = '';
            }
        }
    }

    //*** After Update Action***//
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) {
        List<id> brIds = new List<Id>();
        
        // Added By Moh Sarfaraj for BRP-6025
        Map<Id, BrokerRequest__c> mapAgencyIdToBrokerRequest = new Map<Id, BrokerRequest__c>();
        Set<String> setOfBRYears = new Set<String>();
        Set<String> setOfBRQuartes = new Set<String>();

        for(BrokerRequest__c br: (List<BrokerRequest__c>)newList){
            BrokerRequest__c oldBr = (BrokerRequest__c) oldMap.get(br.Id);

            if (br.RecordTypeId == Constants.MARKETING_REIMBURSEMENT_RECORD_TYPE_ID && 
                br.ApprovalStatus__c == Constants.APPROVED_STATUS && 
                br.SyncStatus__c == Constants.STATUS_IN_PROGRESS) {
                    
                brIds.add(br.Id);
            }

            // Added By Moh Sarfaraj for BRP-6025
            if (br.RecordTypeId == Constants.MARKETING_REIMBURSEMENT_RECORD_TYPE_ID && 
                br.InvoiceStatus__c == Constants.COMMISSION_LINE_STATUS_READY_FORE_SUBMISSION && 
                br.InvoiceStatus__c != oldBr.InvoiceStatus__c && 
                String.isNotBlank(br.Agencyname__c) &&
                String.isNotBlank(br.RequestQuarter__c) && 
                String.isNotBlank(br.RequestYear__c)) {
                    
                mapAgencyIdToBrokerRequest.put(br.Agencyname__c, br);
                setOfBRQuartes.add(br.RequestQuarter__c);
                setOfBRYears.add(br.RequestYear__c);
            }
        }

        User usr = Utilities.getLoggedInUserDetail();
        if (usr.Profile.Name != Constants.INTEGRATION_PROFILE && !brIds.isEmpty()) {
            MarketingReimbursementCalloutHelper.PrepareDataForCallout(brIds);
        }
        // Added By Moh Sarfaraj for BRP-6025
        if(!mapAgencyIdToBrokerRequest.isEmpty()){
            marketingReimbursementNotification(mapAgencyIdToBrokerRequest, setOfBRQuartes, setOfBRYears);
        }
    }
    
    //*** After Insert Action***//
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        //Added by Tharun
        List<BrokerRequest__c> brokerRequestsListToBeUpdated = new List<BrokerRequest__c>();
        List<BrokerRequest__c> listBrokrRequestForPlaceHolderCreation = new List<BrokerRequest__c>();

        List<BrokerRequest__c> brReq = [SELECT Id, Name, Invoice__c FROM BrokerRequest__c WHERE ID IN :newList];
        for(BrokerRequest__c br: brReq){
            if(br.Invoice__c != null){
                br.Invoice__c = br.Name+'-'+br.Invoice__c;
                brokerRequestsListToBeUpdated.add(br);
            }  
        }
        Database.update(brokerRequestsListToBeUpdated);

        for(BrokerRequest__c br : (List<BrokerRequest__c>) newList){
            if(br.RecordTypeId == Constants.MARKETING_REIMBURSEMENT_RECORD_TYPE_ID){
                listBrokrRequestForPlaceHolderCreation.add(br);
            } 
        }
        if(!listBrokrRequestForPlaceHolderCreation.isEmpty()){
            createBrokerRequestPlaceHolder(listBrokrRequestForPlaceHolderCreation);
        }
    }
    
    // Added By Moh Sarfaraj 
    public static void createBrokerRequestPlaceHolder(List<BrokerRequest__c> listBrokerRequest){
       
        if(listBrokerRequest != null && !listBrokerRequest.isEmpty()){
            String DOCUMENT_PLACEHOLDER_CATEGORY_MR = 'Broker Marketing Reimbursement';
            Map<String, List<DocumentPlaceHolder__mdt>> documentMap = DocumentService.getDocumentMetaDataByCategory(
                                                                      new Set<String>{
                                                                        DOCUMENT_PLACEHOLDER_CATEGORY_MR
                                                                       });
            Id docgenpackageId = [SELECT Id FROM Loop__DDP__c WHERE Name = 'Broker Marketing Reimbursement' LIMIT 1]?.Id;
            Id deliveryOptionId = [SELECT Id FROM Loop__DDP_Integration_Option__c WHERE Loop__DDP__c = :docgenpackageId]?.Id;    
           
            if(documentMap != null && !documentMap.isEmpty()){
                List<Document__c> documentListToInsert = new List<Document__c>();
                Map<String,Id> documentRecordTypeMap = new Map<String,Id>();
                //get Existing Documents
                Map<String, Document__c> existingDocMap = new Map<String, Document__c>();
                for(Document__c tempDoc : [SELECT Id,DocumentType__c,BrokerRequest__c FROM Document__c WHERE BrokerRequest__c IN :listBrokerRequest]){
                    existingDocMap.put(tempDoc.BrokerRequest__c+tempDoc.DocumentType__c,tempDoc);
                }
                for(BrokerRequest__c eachBrokerRequest : listBrokerRequest){
                    for(DocumentPlaceHolder__mdt tempMetaRec : documentMap.get(DOCUMENT_PLACEHOLDER_CATEGORY_MR)){
                        String recordTypeID = null;
                        if(tempMetaRec.RecordTypeDeveloperName__c != null){
                            if(!documentRecordTypeMap.containsKey(tempMetaRec.RecordTypeDeveloperName__c)){
                                documentRecordTypeMap.put(tempMetaRec.RecordTypeDeveloperName__c,
                                                          Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(tempMetaRec.RecordTypeDeveloperName__c).getRecordTypeId());
                            }
                            recordTypeID = documentRecordTypeMap.get(tempMetaRec.RecordTypeDeveloperName__c);
                        }
                        if(!existingDocMap.containsKey(eachBrokerRequest.Id + tempMetaRec.DocumentType__c)){
                            Document__c documentRecord = DocumentService.createDocumentRecord('','','',tempMetaRec.DocumentType__c,'','',recordTypeID);
                            documentRecord.BrokerRequest__c = eachBrokerRequest.Id;
                            documentRecord.SendForESign__c = tempMetaRec.eSignRequired__c;
                            documentRecord.DocumentPlaceHolderId__c = tempMetaRec.DeveloperName;
                            documentRecord.EligibleForeSign__c      = tempMetaRec.EligibleForeSign__c;
                            documentRecord.DocgenPackageId__c = docgenpackageId;
                            documentRecord.DeliveryOptionId__c = deliveryOptionId;
                            documentRecord.AvailableForExternalUsers__c = true;
                            documentListToInsert.add(documentRecord);  
                        }
                    }
                }
                if(!documentListToInsert.isEmpty()){
                    insert documentListToInsert;  
                }
            }
        }
    }   

    // Added By Moh Sarfaraj for BRP-6025
    public static void marketingReimbursementNotification(Map<Id, BrokerRequest__c> mapAgencyIdToBrokerRequest, Set<String> setOfBRQuartes, Set<String> setOfBRYears){
        Set<Integer> setQuarterLastMonths = new Set<Integer>();
        for(String quarter : setOfBRQuartes){
            setQuarterLastMonths.add(getQuarterLastMonth(quarter));
        }

        Map<Id, Broker_Classification_Details__c> mapAgencyIdToBrokerClassificationDetail = new Map<Id, Broker_Classification_Details__c>();
        for(Broker_Classification_Details__c eachBCD : [SELECT Id,AgencyName__c,Month__c,Year__c,Classification__r.Name FROM Broker_Classification_Details__c
                                                        WHERE Month__c = :setQuarterLastMonths AND 
                                                        Year__c = :setOfBRYears AND 
                                                        AgencyName__c IN :mapAgencyIdToBrokerRequest.keySet() AND
                                                        Classification__c != NULL]){

            if(getQuarterLastMonth(mapAgencyIdToBrokerRequest.get(eachBCD?.AgencyName__c)?.RequestQuarter__c) == eachBCD.Month__c && 
               mapAgencyIdToBrokerRequest.get(eachBCD.AgencyName__c).RequestYear__c == eachBCD.Year__c){

                mapAgencyIdToBrokerClassificationDetail.put(eachBCD.AgencyName__c, eachBCD);  
            }   
        }

        List<Contact> listContactsToUpdateSendReminder = new List<Contact> ();
        List<BrokerRequest__c> listBrokerRequestToUpdate = new List<BrokerRequest__c> ();

        for(Account eachAgency : [SELECT Id,(SELECT Id,BrokerLastQuarterClassification__c,BrokerNotificationDescription__c 
                                  FROM Contacts WHERE AgentStatus__c = :Constants.ACTIVE_AGENT_STATUS AND PrimaryAgencyAdmin__c = true AND 
                                  BrokerType__c = :Constants.AGENCY_ADMIN LIMIT 1)
                                  FROM Account WHERE Id IN :mapAgencyIdToBrokerRequest.keySet()]){

            if(!eachAgency?.Contacts?.isEmpty()){
                Contact objContact = new Contact();
                objContact.Id = eachAgency?.Contacts[0].Id;
                // Update Boolean to send Reminder via flow
                objContact.SendMarketingNotification__c = true;

                if(mapAgencyIdToBrokerClassificationDetail.containsKey(eachAgency.Id)){
                    objContact.BrokerLastQuarterClassification__c = String.isNotBlank(mapAgencyIdToBrokerClassificationDetail?.get(eachAgency?.Id)?.Classification__r?.Name) ? mapAgencyIdToBrokerClassificationDetail?.get(eachAgency?.Id)?.Classification__r?.Name : 'Standard';
                }

                BrokerRequest__c brMR = new BrokerRequest__c();
                brMR.Id = mapAgencyIdToBrokerRequest.get(eachAgency.Id).Id;
                brMr.NotificationCounter__c = 1;
                String quarter = String.isNotBlank(mapAgencyIdToBrokerRequest?.get(eachAgency.Id)?.RequestQuarter__c) ? mapAgencyIdToBrokerRequest?.get(eachAgency.Id)?.RequestQuarter__c  : '' ;
                String year = String.isNotBlank(mapAgencyIdToBrokerRequest?.get(eachAgency.Id)?.RequestYear__c) ? mapAgencyIdToBrokerRequest?.get(eachAgency.Id)?.RequestYear__c : '' ;
                
                objContact.BrokerNotificationDescription__c = quarter + ' ' + year ;
                if(String.isNotBlank(objContact?.BrokerNotificationDescription__c) && String.isNotBlank(objContact?.BrokerNotificationDescription__c.trim())){
                    listBrokerRequestToUpdate.add(brMR);
                }

                listContactsToUpdateSendReminder.add(objContact);
            }
        }
        if(!listContactsToUpdateSendReminder.isEmpty()){
            update listContactsToUpdateSendReminder;
            
            if(!listBrokerRequestToUpdate.isEmpty()){
                update listBrokerRequestToUpdate;
            }
        }
    }

    private static Integer getQuarterLastMonth(String recordProcessQuarter){
        Integer lastMonth = 0;
        switch on recordProcessQuarter {
            when 'Q1' {
                lastMonth = 3;
            }
            when 'Q2' {
                lastMonth = 6;
            }
            when 'Q3' {
                lastMonth = 9;
            }
            when 'Q4' {
                lastMonth = 12;
            }
        }
        return lastMonth;
    }
}