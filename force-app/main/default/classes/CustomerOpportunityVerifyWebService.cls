/*
* Name               : CustomerOpportunityVerifyWebService
* Description        : This class is used to verify Opportunity for Fast Track Process
*/
@RestResource (urlMapping = '/customer/opportunityverify')
global without sharing class CustomerOpportunityVerifyWebService {
    
    @HTTPPost
    global static void doPost(String recordId, String email){
        
        RestContextHandler handler = new RestContextHandler(true);
        try {
            RestRequest req = RestContext.request;
            handler.response.data = opportunityVerify(recordId, email);
            handler.response.success = true;
            handler.finalize();
        } catch(Exception ex){
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);
        }
    }
    
    public static OpportunityVerifyModel opportunityVerify(String recordId, String email) {
        OpportunityVerifyModel opportunityVerifyModel = new OpportunityVerifyModel();

        String decodeRecordId = EncodingUtil.urlDecode(recordId, 'UTF-8');
        String decodeRecordIdWithoutSpace = decodeRecordId.replace(' ', '+');
        String whereClause =' PersonEmail = \'' + email + '\' ';
		whereClause += ' AND MergedAccount__c = false AND Blacklisted__c = false AND SkipCustomerLogin__c = false AND SkipLiveAldarReason__c = null ';
        List<Account> accountList = CustomerServiceUtility.getAccountDetail(whereClause);
        List<Communication_Preference__c> Commp = new List<Communication_Preference__c>();
        Commp = [SELECT Id,Name,Status__c FROM Communication_Preference__c WHERE Id=:recordId];
        if(Commp.isEmpty()){
            opportunityVerifyModel.isValid = false; 
            opportunityVerifyModel.status = CustomerAPIConstants.STATUS_FAST_TRACK_VALID;
            opportunityVerifyModel.message = CustomerAPIConstants.MESSAGE_FAST_TRACK_INVALID;
            return opportunityVerifyModel;
        }
        if(accountList.isEmpty()){
            opportunityVerifyModel.isValid = false;
            opportunityVerifyModel.status = CustomerAPIConstants.STATUS_FAST_TRACK_VALID;
            opportunityVerifyModel.message = CustomerAPIConstants.MESSAGE_FAST_TRACK_INVALID;
            return opportunityVerifyModel;
        }else{
            Account acc = new Account();
            acc = accountList[0];
            if(acc.Communication_Preferences__r.size() >0){
                for(Communication_Preference__c cp : acc.Communication_Preferences__r){
                    if(cp.Category__c =='Booking' && recordId == cp.Id){
                        opportunityVerifyModel.digitalSales = cp;
                    }else{
                        if(opportunityVerifyModel.fasttrackRecord == null){
                            opportunityVerifyModel.fasttrackRecord	=cp;
                        }
                    }
                }
            
            }
            
            List<Id> soIds = CustomerServiceUtility.getSalesOrderIdsFromJointOwner(new List<Id>{acc.Id});
            
            String soIdsStr = String.join(soIds, '\',\'');
            String cancelledWhereCaluse = ' (Status__c != \'' + Constants.SO_STATUS_CANCELLED + '\' AND Status__c != \'' + Constants.SO_STATUS_CANCELLED_BY_USER + '\') ';
            String salesOrderWhrClause = '';
            if (!soIds.isEmpty()) {
                salesOrderWhrClause = ' ((Account__c = \'' + acc.Id + '\' OR Id IN (\'' + soIdsStr + '\')) AND ' + cancelledWhereCaluse + ') ';
            } else {
                salesOrderWhrClause = ' ((Account__c = \'' + acc.Id + '\') AND ' + cancelledWhereCaluse + ') ';
            }
            List<SalesOrder__c> salesOrderList = Database.query('SELECT Id FROM SalesOrder__c WHERE ' + salesOrderWhrClause + ' LIMIT 1');
            
            opportunityVerifyModel.isNameEditable = !salesOrderList.isEmpty() && salesOrderList.size() > 0 ? false : true;
            opportunityVerifyModel.recordDetails = acc;
            opportunityVerifyModel.accountId = acc.Id;
            //opportunityVerifyModel.opportunityDetails = oppList[0];//appointments[0].Opportunity__r;
            //opportunityVerifyModel.opportunityId = oppList[0].Id;//appointments[0].Opportunity__c;
            //opportunityVerifyModel.appointmentId = appointments[0].AppointmentId__c;
          
            if (Commp[0].Status__c != 'Link Sent') {
                opportunityVerifyModel.isValid = false;
                opportunityVerifyModel.status = CustomerAPIConstants.STATUS_FAST_TRACK_COMPLETED;
                opportunityVerifyModel.message = CustomerAPIConstants.MESSAGE_FAST_TRACK_ALREADY_COMPLETED;
            } else {
                opportunityVerifyModel.isValid = true;
                opportunityVerifyModel.status = CustomerAPIConstants.STATUS_FAST_TRACK_VALID;
                opportunityVerifyModel.message = CustomerAPIConstants.MESSAGE_FAST_TRACK_VALID;
                
                //Opportunity opp = new Opportunity();
                //opp.Id = opportunityVerifyModel.opportunityId;
                //opp.FastTrackedAppointmentId__c = opportunityVerifyModel.appointmentId;
                //update opp;

                // Document__c doc = new Document__c();
                // for (Document__c accDoc: acc.Documents__r) {
                //     if (acc.ResidentStatus__pc == Constants.RESIDENTSTATUS_RESIDENT && accDoc.DocumentType__c == CustomerAPIConstants.DOCUMENT_NATIONAL_ID_FRONT_COPY) {
                //         doc = accDoc;
                //         break;
                //     } else if (acc.ResidentStatus__pc == Constants.RESIDENTTYPE_NON_RESIDENT && accDoc.DocumentType__c == CustomerAPIConstants.DOCUMENT_PASSPORT_COPY) {
                //         doc = accDoc;
                //         break;
                //     }
                // }
                
                // System.debug('doc>>>1>>>' + doc);
                // if (doc.Id != null && doc.Status__c != Constants.DOCUMENT_STATUS_UPLOADED && doc.Status__c != Constants.DOCUMENT_STATUS_GENERATED) {
                //     opportunityVerifyModel.step = CustomerAPIConstants.STEP_UPLOAD_DOCUMENTS;
                // } else {
                //     for (Document__c accDoc: acc.Documents__r) {
                //         if (accDoc.DocumentType__c == CustomerAPIConstants.DOCUMENT_SIGNED_KYC) {
                //             doc = accDoc;
                //             break;
                //         }
                //     }

                //     System.debug('doc>>>2>>>' + doc);
                //     if (doc.Id != null && doc.Status__c != Constants.DOCUMENT_STATUS_UPLOADED && doc.Status__c != Constants.DOCUMENT_STATUS_GENERATED) {
                //         opportunityVerifyModel.step = CustomerAPIConstants.STEP_SIGN_DOCUMENTS;
                //     } else {
                //         System.debug('else>>>');
                //         opportunityVerifyModel.isValid = false;
                //         opportunityVerifyModel.status = CustomerAPIConstants.STATUS_FAST_TRACK_COMPLETED;
                //         opportunityVerifyModel.message = CustomerAPIConstants.MESSAGE_FAST_TRACK_ALREADY_COMPLETED;
                //     }
                // }
                
                // START | sent KYC and Wealth form for customer signature
                List<DocumentQueryModel> documents = new List<DocumentQueryModel>();
                Boolean isKYCPlaceholder = false; 
                Boolean isSignedKYCPlaceholder = false;
                for (Document__c accDoc: acc.Documents__r) {
                    if (accDoc.DocumentType__c == Constants.DOCUMENT_TYPE_KYC) {
                        isKYCPlaceholder = true;
                        DocumentQueryModel docModel = new DocumentQueryModel(accDoc);
                        ContentVersion content = CustomerServiceUtility.getContentVersion(accDoc.Id);
                        if (content != null && content.Id != null && Datetime.now().addMinutes(-1) <= content.LastModifiedDate) {
                            docModel.title = content.Title;
                        } else {
                            docModel.title = '';
                        }
                        documents.add(docModel);
                    } else if (accDoc.DocumentType__c == Constants.DOCUMENT_TYPE_SIGNED_KYC) {
                        isSignedKYCPlaceholder = true;
                    }
                }
                
                List<Document__c> docList = new List<Document__c>();
                if (isKYCPlaceholder == false) {
                    Document__c doc = new Document__c();
                    doc.Account__c = acc.Id;
                    doc.DocumentType__c = Constants.DOCUMENT_TYPE_KYC;
                    docList.add(doc);
                }
                if (isSignedKYCPlaceholder == false) {
                    Document__c doc = new Document__c();
                    doc.Account__c = acc.Id;
                    doc.DocumentType__c = Constants.DOCUMENT_TYPE_SIGNED_KYC;
                    docList.add(doc);
                }
                if (!docList.isEmpty()) {
                    insert docList;
                    if (isKYCPlaceholder == false) { 
                        for (Document__c accDoc: docList) {
                            if (accDoc.DocumentType__c == Constants.DOCUMENT_TYPE_KYC) {
                                DocumentQueryModel docModel = new DocumentQueryModel(accDoc);
                                documents.add(docModel);
                                break;
                            }
                        }
                    }
                }
                opportunityVerifyModel.documents = documents;
                // END | sent KYC and Wealth form for customer signature
            }
        }

        return opportunityVerifyModel;
    }

    global class OpportunityVerifyModel {
        public Boolean isNameEditable                           {get;set;}
        public String accountId                                 {get;set;}
        public String opportunityId                             {get;set;}
        public String appointmentId                             {get;set;}
        public String step                                      {get;set;}
        public Boolean isValid                                  {get;set;}
        public String status                                    {get;set;}
        public String message                                   {get;set;}
        public Account recordDetails                            {get;set;}
        public Opportunity opportunityDetails                   {get;set;}
        public Communication_Preference__c fasttrackRecord      {get;set;}
        public Communication_Preference__c digitalSales         {get;set;}
        public List<DocumentQueryModel> documents               {get;set;}
    }
}