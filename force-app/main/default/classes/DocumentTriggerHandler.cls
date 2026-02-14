/**********************************************************************************************************************
* Name               : DocumentTriggerHandler                                                        
* Description        : This class contains all the helper methods for the Document__c Trigger
* Usage              : DocumentTriggerHandler
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     21 May 2022      Initial Draft       
******************************************************************************************************************/
public without sharing class DocumentTriggerHandler extends TriggerHandler{
    
    //*** Before Insert Action***// 
    public override void beforeInsertMethod(List<SObject> newList, Map<Id, SObject> newMap){
        populateDocGenCode(newList);
        //Added by Charan Vuyyuru - protivityGlobal
        populateCongaTemplate(newList);
        // shareDocumentwithAccountTeamMember((List<Document__c>)newList);
    }
    
    //*** Before Update Action***//
    public override void beforeUpdateMethod(list<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){
        //Added by Charan Vuyyuru - protivityGlobal
        populateCongaTemplate(newList);
    }
    
    //*** After Insert Action***//
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        list<Document__c> GTCDOcumentList = new list<Document__c>();
        for(Document__c newRecord : (List<Document__c>) newList){
            if( newRecord.SalesOrder__c !=null  && newRecord.DocumentType__c.equalsIgnoreCase(Constants.DOCUMENT_TYPE_GTC) ){
                GTCDOcumentList.add(newRecord);
            }
            // *RTO* Document Added
            else if( newRecord.SalesOrder__c !=null  && newRecord.DocumentType__c.equalsIgnoreCase(Constants.RTO_DOCUMENT_TYPE_GTC) ){
                GTCDOcumentList.add(newRecord);
            }
        }
        if(!GTCDOcumentList.isEmpty()){
            linkGTCDOcument(GTCDOcumentList);
        }
        
        //---- to share Document record with Sales Order SM and Opportunity EOI.
        if (!Test.isRunningTest()){
            ShareHelper.shareDocument(newList, Constants.EDIT_ACCESS);
        }
        
        //---- to share Document record with Account Team Member.
        ShareHelper.shareDocumentWithAccountTeamMember(newList, Constants.EDIT_ACCESS);
    }
    
    //*** After Update Action***//
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        // Added By Moh Sarfaraj for BPM-536
        Set<String> brokerSuspensionDocumentType = new Set<String>{'Suspension Letter Draft', 'Warning Letter Draft'};
            Map<Id,Id> mapDocumentToSuspension = new Map<Id,Id>();
        
        // Added by Moh Sarfaraj ASF-1413
        sentEmailToAdha(newList, oldMap);
        
        //ADDED BY CLOUDZLAB START  
        System.debug('DocumentTriggerHandler.afterUpdate fired');
        
        //ECSS_DocumentTriggerHelper.DocumentPlatformEvent(newList,oldMap);
        
        //ADDED BY CLOUDZLAB END        
        //Added by Karunakar ASF-1190
        validateGenerateDocument(newList, oldMap);
        
        //Create Payment records
        set<Id> salesOrderIds = new set<Id>();
        set<Id> EOIIds = new set<Id>();
        set<Id> casesIds = new set<Id>();
        set<Id> spaSrToCreate = new set<Id>();
        Set<Id> caseIdsForResaleListingUnit = new Set<Id>();
        Set<Id> oppIdsForResaleSignedMOU = new Set<Id>();
        
        //Added by Harsh@ALD 17/01/2025 Premium Parking Quote Id
        Set<Id> premPark_QuoteIdSet = new Set<Id>();
        
        for(Document__c newRecord : (List<Document__c>) newList){
            Document__c oldRecord = (Document__c) oldMap.get(newRecord.ID);
            
            //added by Charan Vuyyuru - Protivity Global
            if(newRecord.GenerateDocument__c && newRecord.GenerateDocument__c != oldRecord.GenerateDocument__c && newRecord.Conga_template__c != null){
                CONGAServicesFactory.asyncCongaRequest(newRecord.Id);
            }
            
            if( newRecord.SalesOrder__c !=null  && newRecord.Status__c != oldRecord.Status__c && newRecord.Status__c == Constants.DOCUMENT_STATUS_COMPLETED ){
                salesOrderIds.add(newRecord.SalesOrder__c);
            }
            if( newRecord.ExpressionofInterest__c !=null  && newRecord.Status__c != oldRecord.Status__c && newRecord.Status__c == Constants.DOCUMENT_STATUS_COMPLETED ){
                EOIIds.add(newRecord.ExpressionofInterest__c);
            }
            if( newRecord.Case__c !=null  && newRecord.Status__c != oldRecord.Status__c && newRecord.Status__c == Constants.DOCUMENT_STATUS_UPLOADED && newRecord.DocumentType__c == Constants.DOCUMENT_TYPE_SIGNED_CIS){
                casesIds.add(newRecord.Case__c);
            }
            if( newRecord.SalesOrder__c !=null  && newRecord.Status__c != oldRecord.Status__c && newRecord.Status__c == Constants.DOCUMENT_STATUS_UPLOADED && newRecord.DocumentType__c == Constants.DOCUMENT_TYPE_ALDAR_SIGNED_SPA){
                spaSrToCreate.add(newRecord.SalesOrder__c);
            }
            if( newRecord.Opportunity__c != null && newRecord.DocumentType__c == 'Signed Listing MOU' && newRecord.Status__c != oldRecord.Status__c & newRecord.Status__c == Constants.DOCUMENT_STATUS_UPLOADED){
                oppIdsForResaleSignedMOU.add(newRecord.Opportunity__c); 
            }
            if( newRecord.Case__c != null && newRecord.DocumentType__c == ResaleConstants.CASE_SIGNED_LISTING_AGREEMENT_DOCUMENT_TYPE 
               && newRecord.ProcessResaleCase__c && newRecord.ProcessResaleCase__c != oldRecord.ProcessResaleCase__c ){
                   caseIdsForResaleListingUnit.add(newRecord.Case__c); 
               }
            //Added by Harsh@ALD Premium Parking Quote Automations on Signed Document Upload 17/01/2025
            /*if( newRecord.Quote__c != null && newRecord.DocumentType__c == 'Signed Premium Parking Quote Doc' && newRecord.Status__c != oldRecord.Status__c & newRecord.Status__c == Constants.DOCUMENT_STATUS_UPLOADED){
premPark_QuoteIdSet.add(newRecord.Quote__c); 
}*/
            
            //Added by Harsh@ALD Premium Parking Quote Automations on Signed Document Upload 17/01/2025
            /*if( !premPark_QuoteIdSet.isEmpty()){
PremPark_Service.handleQuote_PostSign(premPark_QuoteIdSet);
}*/
            
            // Added By Moh Sarfaraj for BPM-536
            if(String.isNotBlank(newRecord.Suspensions_Warning__c) && 
               brokerSuspensionDocumentType.contains(newRecord.DocumentType__c) && 
               newRecord.Status__c != oldRecord.Status__c && 
               (newRecord.Status__c == Constants.DOCUMENT_STATUS_GENERATED ||
                newRecord.Status__c == Constants.DOCUMENT_STATUS_UPLOADED)){
                    
                    mapDocumentToSuspension.put(newRecord.Id, newRecord.Suspensions_Warning__c);
                }
        }
        if(!salesOrderIds.isEmpty()){
            verifyandCreatePayment(salesOrderIds);
        }
        if(!EOIIds.isEmpty()){
            verifyandCreatePaymentEOI(EOIIds);
        }
        if(!casesIds.isEmpty()){
            updateAccountFromCase(casesIds);
        }
        if(!spaSrToCreate.isEmpty()){
            createSPAServiceRequest(spaSrToCreate);
        }
        if(!caseIdsForResaleListingUnit.isEmpty()){
            ResaleService.listUnitsAfterAgreementSignature(caseIdsForResaleListingUnit);
        }
        if(!oppIdsForResaleSignedMOU.isEmpty()){
            ResaleUnitService.handleUploadedResaleMOUDocAction(oppIdsForResaleSignedMOU);
        }
        
        // Added by Moh Sarfaraj for BPM-536
        if(!mapDocumentToSuspension.isEmpty()){
            updateDocumentURLToSuspensionWarning(mapDocumentToSuspension);
        }
        
    }
    
    
    
    public static void createSPAServiceRequest(set<Id> spaSrToCreate) {
        
        Map<Id,SalesOrder__c> salesOrdersMap = new Map<Id,SalesOrder__c>([Select Id, Unit__c, SPARegistrationStatus__c, Unit__r.BuildingSectionName__r.CompletionCertificateDate__c From SalesOrder__c Where Id in: spaSrToCreate]);
        //HexaBPM__SR_Status__c objSRStatus = [SELECT Id, Name FROM HexaBPM__SR_Status__c WHERE Name =: Constants.SUBMITTED LIMIT 1];
        Map<Id,boolean> isExistingSPAMap = new Map<Id,boolean>();
        //Monika: 20.02.24: Changes added to stop multiple Srs creation
        //Commented due to error :List<HexaBPM__Service_Request__c> OpenSRs = [select id from HexaBPM__Service_Request__c WHERE RecordTypeName__c = 'SPA Registration For Off Plan' AND HexaBPM__External_Status_Name__c != 'Cancelled' AND SalesOrder__c in: spaSrToCreate];
        for(HexaBPM__Service_Request__c srOBJ: [select id,SalesOrder__c from HexaBPM__Service_Request__c WHERE RecordTypeName__c = 'SPA Registration For Off Plan' AND HexaBPM__External_Status_Name__c != 'Cancelled' AND SalesOrder__c in: spaSrToCreate]){
            isExistingSPAMap.put(srOBJ.SalesOrder__c,true);
        }
        
        List<HexaBPM__Service_Request__c> srToCreate = new List<HexaBPM__Service_Request__c>();
        for (Id salesOrderId : salesOrdersMap.keySet()) {
            if(!isExistingSPAMap.containsKey(salesOrderId)){
                SalesOrder__c so = salesOrdersMap.get(salesOrderId);
                
                if(so.SPARegistrationStatus__c != 'Registered' && (so.Unit__r.BuildingSectionName__r.CompletionCertificateDate__c > system.today() || so.Unit__r.BuildingSectionName__r.CompletionCertificateDate__c == null )){
                    HexaBPM__Service_Request__c newSR = new HexaBPM__Service_Request__c();
                    String recordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.SPA_REGISTRATION_RT);
                    newSR.RecordTypeId = recordTypeId;
                    newSR.SalesOrder__c = so.Id;
                    newSR.Unit__c = so.Unit__c;
                    srToCreate.add(newSR);
                }
            }
        }   
        if(!srToCreate.isEmpty()){
            insert srToCreate;
        }
        for (HexaBPM__Service_Request__c srRecord : srToCreate) {
            ServiceRequestDocumentService.getExistingUploadedFiles(srRecord.SalesOrder__c, srRecord.Id, 'Aldar Signed SPA', 'Aldar Signed SPA');
        }
        
    }
    
    /*
* used to update account details and close the case.
*/
    public static void updateAccountFromCase(set<Id> casesIds){
        List<Case> casesList = CaseService.queryAllFieldsWithExtraFields(new List<Id>(casesIds));
        List<SObject> accountsAndCasesToUpdate = new List<SObject>();
        Set<Id> accIds=new Set<Id>();
        for(Case caseRec:casesList){
            if(caseRec.RecordTypeId != ResaleConstants.Resale_Case_RecordTypeId && caseRec.AccountId != null)
                accIds.add(caseRec.AccountId); 
        }
        Map<Id, Account> accountMap=new Map<Id, Account>([select Id, isValidationBypass__c,RecordTypeName__c from Account where Id IN:accIds]);
        for (Case caseRecord : casesList) {
            //changed condition by Dharnesh for CIS Sheet Issue
            /*if (caseRecord.Origin != Constants.CASE_ORIGIN_CUSTOMER_PORTAL && caseRecord.Origin != Constants.CASE_ORIGIN_CUSTOMER_APP 
&& caseRecord.RecordTypeId != ResaleConstants.Resale_Case_RecordTypeId)*/ 
            if (caseRecord.RecordTypeId != ResaleConstants.Resale_Case_RecordTypeId && caseRecord.AccountId != null)
            {
                Account accRecord = new Account();
                if (accountMap.get(caseRecord.AccountId).RecordTypeName__c == 'Person Account'){
                    accRecord.Id = caseRecord.AccountId;
                    if (caseRecord.PassportNumber__c!=null)accRecord.PassportNumber__pc = caseRecord.PassportNumber__c;
                    if (caseRecord.ResidentStatus__c!=null)accRecord.ResidentStatus__pc = caseRecord.ResidentStatus__c;
                    if (caseRecord.MaritalStatus__c!=null)accRecord.MaritalStatus__pc = caseRecord.MaritalStatus__c;
                    if (caseRecord.EmploymentStatus__c!=null)accRecord.EmploymentStatus__pc = caseRecord.EmploymentStatus__c;
                    if (caseRecord.Email__c!=null)accRecord.PersonEmail = caseRecord.Email__c;
                    if (caseRecord.Email__c!=null)accRecord.EmailAddress__pc = caseRecord.Email__c;
                    if (caseRecord.MobileCountryCode__c!=null)accRecord.MobileCountryCode__pc = caseRecord.MobileCountryCode__c;
                    if (caseRecord.MobileNumber__c!=null)accRecord.MobilePhone__pc = caseRecord.MobileNumber__c;
                    if (caseRecord.MobileCountryCode__c!=null && caseRecord.MobileNumber__c !=null)accRecord.PersonMobilePhone = caseRecord.MobileCountryCode__c + caseRecord.MobileNumber__c;
                    if (caseRecord.MobileCountryCode__c!=null && caseRecord.MobileNumber__c !=null)accRecord.MobileNumberEnc__pc = caseRecord.MobileCountryCode__c + caseRecord.MobileNumber__c;
                    if (caseRecord.Company__c!=null)accRecord.Company__pc = caseRecord.Company__c;
                    if (caseRecord.Position__c!=null) accRecord.Position__pc = caseRecord.Position__c;
                    if (caseRecord.CompanyAddress__c!=null)accRecord.Workplace_Street__pc  = caseRecord.CompanyAddress__c;
                    if (caseRecord.AnnualIncome__c!=null)accRecord.AnnualIncome__pc = caseRecord.AnnualIncome__c;
                    if (caseRecord.NumberOfYearsWithCompany__c!=null)accRecord.NoofYearswithCompany__pc = caseRecord.NumberOfYearsWithCompany__c;
                    if (caseRecord.Industry__c!=null)accRecord.Industry = caseRecord.Industry__c;
                }else {
                    accRecord.Id = caseRecord.AccountId;
                    if (caseRecord.Email__c!=null)accRecord.Email__c = caseRecord.Email__c;
                    if (caseRecord.Email__c!=null)accRecord.EmailAddress__c = caseRecord.Email__c;
                    if (caseRecord.MobileNumber__c!=null)accRecord.MobileNumber1__c = caseRecord.MobileNumber__c;
                    if (caseRecord.MobileCountryCode__c!=null && caseRecord.MobileNumber__c !=null)accRecord.MobileNumber__c = caseRecord.MobileCountryCode__c + caseRecord.MobileNumber__c;
                    if (caseRecord.MobileNumber__c!=null)accRecord.MobileNumberEnc__c = caseRecord.MobileNumber__c;    
                }
                
                
                Account accRecordMatched = accountMap.get(caseRecord.AccountId);
                if(accRecordMatched!=null){ accRecord.isValidationBypass__c=!accRecordMatched.isValidationBypass__c;}
                caseRecord.Status = Constants.CLOSED_CASE;
                accountsAndCasesToUpdate.add(caseRecord);
                accountsAndCasesToUpdate.add(accRecord);
            }
            
            /* Commenting for BAG deployment - Rohit
List<String> ccAddress = new List<String>();
map<id,set<String>> soToJointOwnerMap = getOwnerEmailList(new set<ID>{caseRecord.SalesOrder__c});
if(soToJointOwnerMap.containsKey(caseRecord.SalesOrder__c) && !soToJointOwnerMap.get(caseRecord.SalesOrder__c).isEmpty()){
ccAddress.addAll(soToJointOwnerMap.get(caseRecord.SalesOrder__c));
}
system.debug('ccAddress: '+ccAddress);

String orgWideEmailAddress='';
for(OrgWideEmailAddress tempRec: [select id,Address from OrgWideEmailAddress where DisplayName= :Constants.ALDAR_PROPERTIES_ORGWIDEEMAIL_Post_Sales limit 1 ]){
orgWideEmailAddress=tempRec.id;
}

String emailTempName = caseRecord.CustomerType__c != 'Tenant' && caseRecord.CustomerType__c != 'Visitor' ? 'CaseClosedEmail' : 'CaseClosedEmailForTenantVisitor';
string emailTemplateId ='';
for(Emailtemplate tempRec:  [select id, DeveloperName from emailtemplate where DeveloperName =: emailTempName limit 1]){
emailTemplateId=tempRec.Id;
}

List<String> toAddress = new List<String>();
String customerEmail = caseRecord.CustomerType__c != 'Tenant' && caseRecord.CustomerType__c != 'Visitor' ? caseRecord.Contact.Email : caseRecord.SuppliedEmail;
toAddress.add(customerEmail);

system.debug('toAddress: '+toAddress);

if(!toAddress.contains(caseRecord.SalesOrder__r.Contact__r.Email)){
ccAddress.add(caseRecord.SalesOrder__r.Contact__r.Email);
}

if(ccAddress.contains(customerEmail)){
for(integer i = 0; i<ccAddress.size(); i++){
if(ccAddress.get(i) == customerEmail){
ccAddress.remove(i);
}
}
}
system.debug('toAddress: '+toAddress);
system.debug('ccAddress: '+ccAddress);

list<Messaging.SingleEmailMessage> emailsToSend = new list<Messaging.SingleEmailMessage>();
Messaging.SingleEmailMessage tempEmailInstance = new Messaging.SingleEmailMessage();
tempEmailInstance = Utilities.getEmailInstance(caseRecord.ContactId,emailTemplateId,caseRecord.Id,toAddress,null,ccAddress,null,null,null,null,orgWideEmailAddress);
tempEmailInstance.setSaveAsActivity(true);
emailsToSend.add(tempEmailInstance);
list<Messaging.SendEmailResult> emailResult  = Utilities.sendEmail(emailsToSend);*/
        }
        if(accountsAndCasesToUpdate.size() > 0){
            update accountsAndCasesToUpdate;
        }
    }
    
    //get Jointowner list for communication
    /* commenting for BAG deployment - Rohit
public static map<id,set<String>> getOwnerEmailList(set<ID> soIds){
map<id,set<String>> returnMap = new  map<id,set<String>>();
for(JointOwner__c jo : [select id,SalesOrder__c,Email__c from JointOwner__c where SalesOrder__c in : soIds]){
if(!returnMap.containsKey(jo.SalesOrder__c)){
returnMap.put(jo.SalesOrder__c, new set<String>());
}
returnMap.get(jo.SalesOrder__c).add(jo.Email__c);
}
return returnMap;
}*/
    
    //EOI PROCESS CHANGE not to create the RA -- ONly Update the status as COmplaice in Progresss
    //This method verify all the signed palceholders are marked as completed to create payment records for SalesOrder
    public static void verifyandCreatePaymentEOI(set<Id> expressionofInterestIds){
        map<Id,list<Document__c>> expressionofInterestToNonSignedDocs = new map<Id,list<Document__c>>();
        //get non signed docs
        String likedSignedString = Constants.DOCUMENT_TYPE_PREFIX_SIGNED+'%';
        for(Document__c tempDoc : [select id,ExpressionofInterest__c from Document__c where ExpressionofInterest__c in : expressionofInterestIds and DocumentType__c like :likedSignedString and Status__c!= :Constants.DOCUMENT_STATUS_COMPLETED ]){
            if(!expressionofInterestToNonSignedDocs.containsKey(tempDoc.ExpressionofInterest__c)){
                expressionofInterestToNonSignedDocs.put(tempDoc.ExpressionofInterest__c,new list<Document__c>());
            }
            expressionofInterestToNonSignedDocs.get(tempDoc.ExpressionofInterest__c).add(tempDoc);
        }
        //create payment records
        map<id,ReceiptAcknowledgement__c> expressionofInterestToProcess = new  map<id,ReceiptAcknowledgement__c>();
        for(Id tempEOIId : expressionofInterestIds){
            if(!expressionofInterestToNonSignedDocs.containsKey(tempEOIId) || expressionofInterestToNonSignedDocs.get(tempEOIId).isEmpty()){
                expressionofInterestToProcess.put(tempEOIId,null);
            }
        }
        //Do not create payment record if already created
        for(ReceiptAcknowledgement__c tempPayment : [select id,OpportunityEOI__c from ReceiptAcknowledgement__c where OpportunityEOI__c in :expressionofInterestToProcess.keySet()]){
            expressionofInterestToProcess.remove(tempPayment.OpportunityEOI__c);
        } 
        //Updatethe ExpressionofInterest sub status to Documents Signed
        list<OpportunityEOI__c> recordsToUpdate = new list<OpportunityEOI__c>();
        //Create payment record
        for(OpportunityEOI__c tempRecord : [select id,PaymentMode__c,InterestFee__c,opportunity__r.Contact__c,Opportunity__c,opportunity__r.AccountId from OpportunityEOI__c where id in :expressionofInterestToProcess.keySet() ]){
            recordsToUpdate.add(new OpportunityEOI__c(id=tempRecord.id,ComplianceStatus__c = Constants.STATUS_IN_PROGRESS ));
        }
        if(!recordsToUpdate.isEmpty()){
            update recordsToUpdate;
        }
        
    }
    
    //This method verify all the signed palceholders are marked as completed to create payment records for SalesOrder
    public static void verifyandCreatePayment(set<Id> salesOrderIds){
        map<Id,list<Document__c>> salesOrderToNonSignedDocs = new map<Id,list<Document__c>>();
        //get non signed docs
        String likedSignedString = Constants.DOCUMENT_TYPE_PREFIX_SIGNED+'%';
        for(Document__c tempDoc : [select id,SalesOrder__c from Document__c where SalesOrder__c in : salesOrderIds and DocumentType__c like :likedSignedString and Status__c!= :Constants.DOCUMENT_STATUS_COMPLETED ]){
            if(!salesOrderToNonSignedDocs.containsKey(tempDoc.SalesOrder__c)) {
                salesOrderToNonSignedDocs.put(tempDoc.SalesOrder__c,new list<Document__c>());
            }
            salesOrderToNonSignedDocs.get(tempDoc.SalesOrder__c).add(tempDoc);
        }
        //create payment records
        map<id,ReceiptAcknowledgement__c> salesOrderToProcess = new  map<id,ReceiptAcknowledgement__c>();
        for(Id tempSOId : salesOrderIds){
            if(!salesOrderToNonSignedDocs.containsKey(tempSOId) || salesOrderToNonSignedDocs.get(tempSOId).isEmpty()){
                salesOrderToProcess.put(tempSOId,null);
            }
        }
        //Do not create payment record if already created
        for(ReceiptAcknowledgement__c tempPayment : [select id,SalesOrder__c from ReceiptAcknowledgement__c where SalesOrder__c in :salesOrderToProcess.keySet()]){
            salesOrderToProcess.remove(tempPayment.SalesOrder__c);
        } 
        //Updatethe Salesorder sub status to Documents Signed
        list<SalesOrder__c> recordsToUpdate = new list<SalesOrder__c>();
        //Create payment record
        for(SalesOrder__c tempRecord : [select id,SalesManager__c ,ReceiptAcknowledgementPaymentMethod__c,RAcknowledgementReservationAmount__c,opportunity__r.Contact__c,Opportunity__c,opportunity__r.AccountId, ProjectName__c from SalesOrder__c where id in :salesOrderToProcess.keySet() ]){
            //update the below to also change the status to reserved in case of balghailam, for others the below to continue
            System.debug('Project:'+tempRecord.ProjectName__c);
            System.debug('Custom Label:'+String.valueof(System.Label.ADHAProject));
            if(tempRecord.ProjectName__c == String.valueof(System.Label.ADHAProject)){
                System.debug('inside if');
                //recordsToUpdateList()
                recordsToUpdate.add(new SalesOrder__c(id=tempRecord.id,SubStatus__c = Constants.SUB_STATUS_DOCS_SIGNED)); //, Status__c = Constants.STATUS_RESERVED ));
                salesOrderToProcess.remove(tempRecord.id); //remove existing record from map to remove receipt creation
            } else {
                recordsToUpdate.add(new SalesOrder__c(id=tempRecord.id,SubStatus__c = Constants.SUB_STATUS_DOCS_SIGNED ));
                salesOrderToProcess.put(tempRecord.id, new ReceiptAcknowledgement__c(SalesOrder__c=tempRecord.Id,
                                                                                     Account__c=tempRecord.Opportunity__r.AccountId,
                                                                                     Contact__c=tempRecord.Opportunity__r.Contact__c,
                                                                                     Opportunity__c=tempRecord.opportunity__c,
                                                                                     OwnerID = (tempRecord.SalesManager__c!=NULL)? tempRecord.SalesManager__c : UserInfo.getUserId() ,
                                                                                     Amount__c=tempRecord.RAcknowledgementReservationAmount__c,
                                                                                     PaymentType__c=tempRecord.ReceiptAcknowledgementPaymentMethod__c ));
            }
        }
        if(!salesOrderToProcess.isEmpty()){
            insert salesOrderToProcess.values();
        }
        if(!recordsToUpdate.isEmpty()){
            update recordsToUpdate;
        }
        
    }
    
    //Automate Esign flow once the Place holder document is generated
    public static void validateAndProcessEsign(set<Id> docsToProcessForESign){
        map<Id,Document__c> documentMap= new map<Id,Document__c>([select id from Document__c where id in :docsToProcessForESign and SendForESign__c=true]);
        if(!documentMap.isEmpty()){
            processEsign(documentMap.keySet());
        }
        
    }
    
    //Future callout to automate the sending for Esign flow for uploaded documents
    @future(callout=true)
    public static void processEsign(set<Id> docsToProcessForESign){
        map<String,Document__c> documentMap= new map<String,Document__c>([select id,DocumentType__c,SendForESign__c,DocuSignEnvelopeID__c,ExpressionofInterest__c,ExpressionofInterest__r.Account__c,ExpressionofInterest__r.Account__r.isPersonAccount,SalesOrder__c,SalesOrder__r.Account__c,SalesOrder__r.Account__r.isPersonAccount from Document__c where id in :docsToProcessForESign]);
        map<id,id> documentToContentVersionID = new map<id,id>();
        
        for(ContentDocumentLink conDocLink : [select id,ContentDocumentId,ContentDocument.LatestPublishedVersionId,LinkedEntityId from ContentDocumentLink where LinkedEntityId in :documentMap.keySet() ]){
            documentToContentVersionID.put(conDocLink.LinkedEntityId,conDocLink.ContentDocument.LatestPublishedVersionId);
        }
        
        map<id,Account> accountMap =  new map<id,Account>();
        map<string,Document__c> relatedSignDocument = new map<string,Document__c>();
        set<ID> relatedSalesOrders = new set<Id>();
        set<ID> relatedEOI = new set<Id>();
        
        for(Id tempDocId : documentMap.keySet()){
            if(documentMap.get(tempDocId).SalesOrder__r.Account__c!=null){
                accountMap.put(documentMap.get(tempDocId).SalesOrder__r.Account__c,null);
                relatedSalesOrders.add(documentMap.get(tempDocId).SalesOrder__c);
            }
            if(documentMap.get(tempDocId).ExpressionofInterest__r.Account__c!=null){
                accountMap.put(documentMap.get(tempDocId).ExpressionofInterest__r.Account__c,null);
                relatedEOI.add(documentMap.get(tempDocId).ExpressionofInterest__c);
            }
            //collect related Opportunity 
            //reset the flags
            documentMap.get(tempDocId).DocuSignEnvelopeID__c='';
            documentMap.get(tempDocId).SendForESign__c =false;
            
        }
        //get all the related records
        String likedSignedString = Constants.DOCUMENT_TYPE_PREFIX_SIGNED+'%';
        for(Document__c docRecords : [select id,DocumentType__c,SendForESign__c,DocuSignEnvelopeID__c,ExpressionofInterest__c,ExpressionofInterest__r.Account__c,ExpressionofInterest__r.Account__r.isPersonAccount,SalesOrder__c,SalesOrder__r.Account__c,SalesOrder__r.Account__r.isPersonAccount from Document__c where (SalesOrder__c in :relatedSalesOrders OR ExpressionofInterest__c in :relatedEOI) and DocumentType__c like :likedSignedString]){
            relatedSignDocument.put((docRecords.SalesOrder__c != null ? docRecords.SalesOrder__c : docRecords.ExpressionofInterest__c ) + docRecords.DocumentType__c.replace(Constants.DOCUMENT_TYPE_PREFIX_SIGNED+' ',''),docRecords);
        }
        accountMap = new map<id,Account>([select id,isPersonAccount, FirstName,LastName, PersonEmail,(select id,FirstName,LastName, Email from Contacts where PrimaryContact__c =true) from account where id in :accountMap.keySet()]);
        //List<dfsle.Recipient> recipientList = new List<dfsle.Recipient>();
        for(Id tempDocId : documentMap.keySet()){
            //Send all documents one by one
            // Create an empty envelope. with the DocID
            dfsle.Envelope myEnvelope = dfsle.EnvelopeService.getEmptyEnvelope( new dfsle.Entity(tempDocId));
            
            //Create placeholders
            dfsle.Tab signatureTab;
            dfsle.Tab dateTab;
            dfsle.Tab initialHereTab;
            String recipitName;
            String recipitEmail;
            dfsle.Recipient myRecipient;
            if (documentMap.get(tempDocId).SalesOrder__c != null) {
                signatureTab = DownloadSODocsController.createEnvTab( documentMap.get(tempDocId).SalesOrder__c + 'SignatureHolder');
                dateTab = DownloadSODocsController.createEnvTab( documentMap.get(tempDocId).SalesOrder__c + 'DateHolder');
                initialHereTab = DownloadSODocsController.createEnvTab( documentMap.get(tempDocId).SalesOrder__c + 'InitialsHolder');
                // Add Recipient Salesorder's Account or Account's Primary Contact (must be present)
                
                recipitName = accountMap.get(documentMap.get(tempDocId).SalesOrder__r.Account__c).isPersonAccount ? (accountMap.get(documentMap.get(tempDocId).SalesOrder__r.Account__c).FirstName + ' '+ accountMap.get(documentMap.get(tempDocId).SalesOrder__r.Account__c).LastName) : (accountMap.get(documentMap.get(tempDocId).SalesOrder__r.Account__c).Contacts[0].FirstName + ' '+ accountMap.get(documentMap.get(tempDocId).SalesOrder__r.Account__c).Contacts[0].LastName); // Recipient name
                    recipitEmail = accountMap.get(documentMap.get(tempDocId).SalesOrder__r.Account__c).isPersonAccount ? (accountMap.get(documentMap.get(tempDocId).SalesOrder__r.Account__c).PersonEmail ) : (accountMap.get(documentMap.get(tempDocId).SalesOrder__r.Account__c).Contacts[0].Email ); // Recipient email
                        myRecipient = dfsle.Recipient.fromSource(recipitName,recipitEmail,
                                                                 null, // Optional phone number
                                                                 null, // Role Name. Specify the exact role name from template
                                                                 new dfsle.Entity(accountMap.get(documentMap.get(tempDocId).SalesOrder__r.Account__c).isPersonAccount ? (accountMap.get(documentMap.get(tempDocId).SalesOrder__r.Account__c).Id ) : (accountMap.get(documentMap.get(tempDocId).SalesOrder__r.Account__c).Contacts[0].Id )))
                        .withTabs(new List<dfsle.Tab> {signatureTab,dateTab,initialHereTab}); // Source object for the Recipient
                
            }else if (documentMap.get(tempDocId).ExpressionofInterest__c != null) {
                signatureTab = DownloadSODocsController.createEnvTab( documentMap.get(tempDocId).ExpressionofInterest__c + 'SignatureHolder');
                dateTab = DownloadSODocsController.createEnvTab( documentMap.get(tempDocId).ExpressionofInterest__c + 'DateHolder');
                initialHereTab = DownloadSODocsController.createEnvTab( documentMap.get(tempDocId).ExpressionofInterest__c + 'InitialsHolder');
                
                recipitName = accountMap.get(documentMap.get(tempDocId).ExpressionofInterest__r.Account__c).isPersonAccount ? (accountMap.get(documentMap.get(tempDocId).ExpressionofInterest__r.Account__c).FirstName + ' '+ accountMap.get(documentMap.get(tempDocId).ExpressionofInterest__r.Account__c).LastName) : (accountMap.get(documentMap.get(tempDocId).ExpressionofInterest__r.Account__c).Contacts[0].FirstName + ' '+ accountMap.get(documentMap.get(tempDocId).ExpressionofInterest__r.Account__c).Contacts[0].LastName); // Recipient name
                    recipitEmail = accountMap.get(documentMap.get(tempDocId).ExpressionofInterest__r.Account__c).isPersonAccount ?     (accountMap.get(documentMap.get(tempDocId).ExpressionofInterest__r.Account__c).PersonEmail ) : (accountMap.get(documentMap.get    (tempDocId).ExpressionofInterest__r.Account__c).Contacts[0].Email ); // Recipient email
                        myRecipient = dfsle.Recipient.fromSource(recipitName,recipitEmail,
                                                                 null, // Optional phone number
                                                                 null, // Role Name. Specify the exact role name from template
                                                                 new dfsle.Entity(accountMap.get(documentMap.get(tempDocId).ExpressionofInterest__r.Account__c).isPersonAccount ? (accountMap.get(documentMap.get(tempDocId).ExpressionofInterest__r.Account__c).Id ) : (accountMap.get(documentMap.get(tempDocId).ExpressionofInterest__r.Account__c).Contacts[0].Id )))
                        .withTabs(new List<dfsle.Tab> {signatureTab,dateTab,initialHereTab}); // Source object for the Recipient
            }
            
            // Add Recipient Salesorder's Account or Account's Primary Contact (must be present)
            
            
            
            // Add Recipient to the Envelope
            myEnvelope = myEnvelope.withRecipients(new List<dfsle.Recipient> { myRecipient });
            
            // Add Recipient to the Envelope
            myEnvelope = myEnvelope.withDocuments(dfsle.DocumentService.getDocuments(ContentVersion.getSObjectType(),new Set<id>{documentToContentVersionID.get(tempDocId)} ));
            
            // Add document to the Envelope
            myEnvelope = test.isRunningTest()?null: dfsle.EnvelopeService.sendEnvelope( myEnvelope,true);
            
            //Docusign Envelop ID
            string DocuSignID = test.isRunningTest()?'Test':String.valueOf(myEnvelope.docuSignId);
            
            if (documentMap.get(tempDocId).SalesOrder__c != null) {
                documentMap.put(documentMap.get(tempDocId).SalesOrder__c + documentMap.get(tempDocId).DocumentType__c , new Document__c(id = relatedSignDocument.get(documentMap.get(tempDocId).SalesOrder__c + documentMap.get(tempDocId).DocumentType__c).Id,DocuSignEnvelopeID__c=DocuSignID) );
            }else if (documentMap.get(tempDocId).ExpressionofInterest__c != null) {
                documentMap.put(documentMap.get(tempDocId).ExpressionofInterest__c + documentMap.get(tempDocId).DocumentType__c , new Document__c(id = relatedSignDocument.get(documentMap.get(tempDocId).ExpressionofInterest__c + documentMap.get(tempDocId).DocumentType__c).Id,DocuSignEnvelopeID__c=DocuSignID) );
            }
            
            
        }
        //Processing complete
        //update the record
        update documentMap.values();
    }
    
    
    //Automatically populate the DocGen code based on the DocumentPlaceHolder__mdt defination
    public static void populateDocGenCode(list<Document__c> newDocuments){
        map<string, DocumentPlaceHolder__mdt > mappingRecords = new map<string, DocumentPlaceHolder__mdt >();
        map<string,Loop__DDP_Integration_Option__c > docgenPackage = new map<string, Loop__DDP_Integration_Option__c >();
        set<string> packageNames = new set<string>();
        set<string> deliveryOptionNames = new set<string>();
        
        map<Id,String> soToProjectMap = new map<id,String>();
        //Modified by CloudzLab
        //Start of CloudzLab Changes
        Map<String,DocumentPlaceHolder__mdt> ecssMappingRecords = new Map<String,DocumentPlaceHolder__mdt>();
        Set<Id> accountIds = new Set<Id>();
        Map<Id,Account> ecssAccounts;
        //End of CloudzLab Changes        
        for(Document__c tempDocRec: newDocuments){
            if(tempDocRec.Salesorder__c!=null){
                soToProjectMap.put(tempDocRec.Salesorder__c,'');
            }
            //Start of CloudzLab Changes
            accountIds.add(tempDocRec.Account__c);
            //End of CloudzLab Changes
        }
        System.debug('AccountIds: '+accountIds);
        if(accountIds.size()>0){
            ecssAccounts = new Map<Id, Account>(
                [SELECT Id, Name, ECSS_BrokerCompany__r.ECSS_Company_External_Id__c,ECSS_BrokerCompany__c FROM Account WHERE Id IN :accountIds]
            );
        }
        if (!test.isRunningTest()){
            for(Salesorder__c so : [select id,ProjectName__c from Salesorder__c where id in :soToProjectMap.keySet() ]){
                soToProjectMap.put(so.Id,so.ProjectName__c);
            }
        }
        for(DocumentPlaceHolder__mdt tempRec: [select id,DeveloperName,DocumentType__c,eSignRequired__c,ProjectName__c, DeliveryOption__c, DocgenPackageName__c,GeneratedManually__c,Is_ECSS__c,ECSSCompany__c from DocumentPlaceHolder__mdt where DocgenPackageName__c!=null]){
            if(tempRec.ProjectName__c!=null){
                mappingRecords.put(tempRec.DeveloperName.tolowerCase()+tempRec.DocumentType__c.tolowerCase()+tempRec.ProjectName__c.tolowerCase(),tempRec);
            }
            //Start of Changes by CloudzLab
            else if (tempRec.Is_ECSS__c){
                ecssMappingRecords.put(tempRec.ECSSCompany__c.tolowerCase()+tempRec.DocumentType__c.tolowerCase(),tempRec);
            }
            //End of Changes by CloudzLab
            else{
                mappingRecords.put(tempRec.DeveloperName.tolowerCase()+tempRec.DocumentType__c.tolowerCase(),tempRec);
            }
            mappingRecords.put(tempRec.DocumentType__c.tolowerCase(),tempRec);
            
            //docgenPackage.put(tempRec.DocgenPackageName__c,null);
            packageNames.add(tempRec.DocgenPackageName__c);
            deliveryOptionNames.add(tempRec.DeliveryOption__c);
        }
        System.debug('ECSS Mapping: '+ecssMappingRecords);
        system.debug('Normal Mapping: '+mappingRecords);
        System.debug('Package Names: '+packageNames);
        System.debug('Delivery Option Names: '+deliveryOptionNames);
        
        for(Loop__DDP_Integration_Option__c tempRec : [select id,Name,Loop__DDP__c,Loop__DDP__r.Name from Loop__DDP_Integration_Option__c where name in :deliveryOptionNames and Loop__DDP__r.Name in :packageNames ]){
            docgenPackage.put(tempRec.Loop__DDP__r.Name.toLowerCase() + tempRec.Name.toLowerCase() ,tempRec);    
        }
        System.debug('docgenPackage: '+docgenPackage);
        for(Document__c tempDocRec: newDocuments){
            string documentPlaceHolderId = tempDocRec.DocumentPlaceHolderId__c!=null? tempDocRec.DocumentPlaceHolderId__c:'';
            string templaterecordToFetch=tempDocRec.DocumentType__c;
            string noProj=tempDocRec.DocumentType__c;
            
            if(tempDocRec.Salesorder__c!=null && soToProjectMap.containsKey(tempDocRec.Salesorder__c)){
                templaterecordToFetch =tempDocRec.DocumentType__c + soToProjectMap.get(tempDocRec.Salesorder__c);
            }
            
            if(tempDocRec.DocumentType__c!=null && (mappingRecords.containsKey(documentPlaceHolderId.tolowerCase() + templaterecordToFetch.tolowerCase()) ||  mappingRecords.containsKey(documentPlaceHolderId.tolowerCase() + noProj.tolowerCase())  || mappingRecords.containsKey(noProj.tolowerCase()) )){
                
                DocumentPlaceHolder__mdt tempRec = mappingRecords.containsKey(documentPlaceHolderId.tolowerCase() + templaterecordToFetch.tolowerCase()) ? mappingRecords.get(documentPlaceHolderId.tolowerCase() + templaterecordToFetch.tolowerCase()) : (mappingRecords.containsKey(documentPlaceHolderId.tolowerCase() + noProj.tolowerCase()) ? mappingRecords.get(documentPlaceHolderId.tolowerCase() + noProj.tolowerCase()) : mappingRecords.get(noProj.tolowerCase()) );
                    
                    if(docgenPackage.containsKey(tempRec.DocgenPackageName__c.tolowerCase() + tempRec.DeliveryOption__c.tolowerCase() ) ){
                        Loop__DDP_Integration_Option__c tempDeliveryRec = docgenPackage.get(tempRec.DocgenPackageName__c.tolowerCase() + tempRec.DeliveryOption__c.tolowerCase() );
                        tempDocRec.DocgenPackageId__c = tempDeliveryRec.Loop__DDP__c;
                        tempDocRec.DeliveryOptionId__c=tempDeliveryRec.Id;
                        //if batch is executing donot generate documents
                        tempDocRec.GenerateDocument__c= (System.isBatch() || newDocuments.size()>50)?false: (tempRec.GeneratedManually__c != true);
                            tempDocRec.GenerateDocumentAsync__c = (newDocuments.size()>50) ? (tempRec.GeneratedManually__c != true):false;
                        tempDocRec.SendForESign__c= tempDocRec.SendForESign__c? tempDocRec.SendForESign__c : tempRec.eSignRequired__c;
                    }
                //Start of Changes by CloudzLab
                //if(tempDocRec.Account__r.ECSS_BrokerCompany__r.ECSS_Company_External_Id__c!=null && ecssMappingRecords.containsKey(tempDocRec.Account__r.ECSS_BrokerCompany__r.ECSS_Company_External_Id__c.toLowerCase()+tempDocRec.DocumentType__c.toLowerCase())){
                Account tempAccount = ecssAccounts.get(tempDocRec.Account__c);
                if(tempAccount != null && tempAccount.ECSS_BrokerCompany__c != null && tempAccount.ECSS_BrokerCompany__r.ECSS_Company_External_Id__c!=null && ecssMappingRecords.containsKey(tempAccount.ECSS_BrokerCompany__r.ECSS_Company_External_Id__c.toLowerCase()+tempDocRec.DocumentType__c.toLowerCase())){
                    DocumentPlaceHolder__mdt ecssTempRec = ecssMappingRecords.get(tempAccount.ECSS_BrokerCompany__r.ECSS_Company_External_Id__c.toLowerCase()+tempDocRec.DocumentType__c.toLowerCase());
                    if(docgenPackage.containsKey(ecssTempRec.DocgenPackageName__c.tolowerCase() + ecssTempRec.DeliveryOption__c.tolowerCase() ) ){
                        Loop__DDP_Integration_Option__c tempDeliveryRec = docgenPackage.get(ecssTempRec.DocgenPackageName__c.tolowerCase() + ecssTempRec.DeliveryOption__c.tolowerCase() );
                        tempDocRec.ECSS_DocgenPackageId__c = tempDeliveryRec.Loop__DDP__c;
                        tempDocRec.ECSS_DeliveryOptionId__c = tempDeliveryRec.Id;
                    }
                }
                
                //End of Changes by CloudzLab
            }
            
        }
        
    }
    
    // Link the General Terms Document from project levelt o respective SO records
    public static void linkGTCDOcument(list<Document__c> newDocuments){
        //getall the Project's GTC documentLink
        map<id,ID> projectToDocumentMap = new map<Id,Id>();
        //(DocumentType__c =:Constants.DOCUMENT_TYPE_GTC OR DocumentType__c =:Constants.RTO_DOCUMENT_TYPE_GTC)
        for(Document__c tempProjectDocs : [select id,Project__c from Document__c where DocumentType__c =:Constants.DOCUMENT_TYPE_GTC and Project__c !=null ]){
            projectToDocumentMap.put(tempProjectDocs.Project__c, tempProjectDocs.Id );
        }
        // *RTO* Document Added
        for(Document__c tempProjectDocs : [select id,Project__c from Document__c where DocumentType__c =:Constants.RTO_DOCUMENT_TYPE_GTC and Project__c !=null ]){
            projectToDocumentMap.put(tempProjectDocs.Project__c, tempProjectDocs.Id );
        }
        map<ID,contentDocumentLink> documentToCDLLink = new map<id,contentDocumentLink>();
        for(contentDocumentLink cdl : [ select id, ContentDocumentId,linkedEntityId from contentDocumentLink where linkedEntityId in :projectToDocumentMap.values() ]){
            documentToCDLLink.put(cdl.linkedEntityId,cdl);
        }
        
        //Get Project associated with inserted Document
        map<Id,Id> soToProjectMap = new map<id,Id>();
        for(Document__c tempDocRec: newDocuments){
            soToProjectMap.put(tempDocRec.Salesorder__c,null);
        }
        for(Salesorder__c so : [select id,Unit__r.Project__c,ProjectName__c from Salesorder__c where id in :soToProjectMap.keySet() ]){
            soToProjectMap.put(so.Id,so.Unit__r.Project__c);
        }
        
        //Try to create CDL
        //update Document__c records
        list<Document__c> docStatusToUpdate = new list<Document__c>();
        list<contentDocumentLink> cdlToInsert = new list<contentDocumentLink>();
        for(Document__c tempDocRec: newDocuments){
            if(soToProjectMap.get(tempDocRec.Salesorder__c)!=null && projectToDocumentMap.containsKey(soToProjectMap.get(tempDocRec.Salesorder__c)) && documentToCDLLink.containsKey(projectToDocumentMap.get(soToProjectMap.get(tempDocRec.Salesorder__c))) ){
                cdlToInsert.add(new contentDocumentLink(ContentDocumentId = documentToCDLLink.get(projectToDocumentMap.get(soToProjectMap.get(tempDocRec.Salesorder__c))).ContentDocumentId,
                                                        LinkedEntityId= tempDocRec.id,ShareType='V',Visibility='InternalUsers'));
                docStatusToUpdate.add(new Document__c(id= tempDocRec.Id, Status__c = Constants.DOCUMENT_STATUS_GENERATED));
            }
        }
        
        if(!cdlToInsert.isEmpty()){
            insert cdlToInsert;
        }
        if(!docStatusToUpdate.isEmpty()){
            update docStatusToUpdate;
        }
        
    }
    
    /*Commenting for BAG deployment - Rohit
public static void shareDocumentwithAccountTeamMember(List<Document__c> newList){
Set<Id> accountIdSet = new Set<Id>();
Map<Id, Id> documentAccountOwnerMap = new Map<Id, Id>();
List<Document__Share> documentShareList = new List<Document__Share>();
for(Document__c document: newList){
if(document.Account__c != null ){
accountIdSet.add(document.Account__c);
}
}

if(!accountIdSet.isEmpty()){
List<AccountTeamMember> accountTeamMember = [SELECT
AccountAccessLevel,
AccountId,
CaseAccessLevel,
ContactAccessLevel,
OpportunityAccessLevel,
TeamMemberRole,
UserId 
FROM AccountTeamMember
WHERE AccountId IN: accountIdSet];

if(!accountTeamMember.isEmpty()){
for(Document__c document: [SELECT Id,Account__r.OwnerId, Account__c  FROM  Document__c WHERE Id IN:newList  AND Account__c In:accountIdSet]){
for(AccountTeamMember atm : accountTeamMember){
if(atm.UserId !=  document.Account__r.OwnerId ){
Document__Share docShare = new Document__Share();
docShare.AccessLevel = 'Read';
docShare.ParentId = document.Id;
docShare.UserOrGroupId = atm.UserId;
docShare.RowCause = 'Manual';
documentShareList.add(docShare);
}
}
}
}
if(!documentShareList.isEmpty()){
insert documentShareList;
}
}
}*/
    
    // Added by Moh Sarfaraj ASF-1413
    public static void sentEmailToAdha(List<Sobject> newList, Map<Id, Sobject> oldMap){
        String needToSentEmail = System.Label.BAGIsSentEmailToADHA;
        if(needToSentEmail.equalsIgnoreCase('YES')){
            List<Document__c> newDocuList = (List<Document__c>) newList;
            Map<Id,Id> mapDocIdToAccountId = new Map<Id,Id>();
            Set<String> setDocumentType = new Set<String>(Label.BAGEmailDocumentType.split(','));
            
            Set<Id> setDocumentIds = new Set<Id>();
            for(Document__c objDoc : newDocuList){
                Document__c oldRecord = (Document__c) oldMap.get(objDoc.Id);
                
                system.debug('Condition  objDoc.ProjectName__c::'+ objDoc.ProjectName__c+'objDoc.DocumentType__c::'+objDoc.DocumentType__c);
                if(!objDoc.IsEmailSenttoADHA__c && objDoc.ProjectName__c != null && objDoc.ProjectName__c.equalsIgnoreCase('Balghaiylam') && 
                   setDocumentType.contains(objDoc.DocumentType__c) && 
                   (//(objDoc.IsEmailSenttoADHA__c != oldRecord.IsEmailSenttoADHA__c) ||
                       (objDoc.Status__c != oldRecord.Status__c)) && 
                   (objDoc.Status__c == 'Uploaded' || objDoc.Status__c == 'Completed')){
                       
                       setDocumentIds.add(objDoc.Id);
                   }
            }
            for(Document__c eachDocu : [SELECT Id,SalesOrder__c,SalesOrder__r.Account__c FROM Document__c WHERE Id IN :setDocumentIds]){
                if(String.isNotBlank(eachDocu.SalesOrder__c) && String.isNotBlank(eachDocu.SalesOrder__r.Account__c)){
                    mapDocIdToAccountId.put(eachDocu.Id, eachDocu.SalesOrder__r.Account__c);
                }
            }
            Map<Id,Id> mapCDLIdToDocuId = new Map<Id,Id>();
            if(!setDocumentIds.isEmpty()){
                for(ContentDocumentLink objCDL : [SELECT Id,ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :setDocumentIds]) {
                    mapCDLIdToDocuId.put(objCDL.ContentDocumentId, objCDL.LinkedEntityId);
                }
            }
            if(!mapCDLIdToDocuId.isEmpty()){
                // Get Email Template 
                Id templateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :(Label.BAGSignedEmailTemplate)]?.Id; 
                
                // Set OrgWideEmailAddress Id 
                Id orgWideEmailAddressId = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = :(Label.BAGSignedEmailOrgWideAddress) LIMIT 1]?.Id; 
                
                Map<Id,List<Messaging.EmailFileAttachment>> mapDocuIdToAttachments = new Map<Id,List<Messaging.EmailFileAttachment>>();
                
                for(ContentVersion cv : [SELECT VersionData, Title, FileType, ContentDocumentId FROM ContentVersion WHERE 
                                         ContentDocumentId IN :mapCDLIdToDocuId.keySet() AND IsLatest = true]) { 
                                             
                                             Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment(); 
                                             efa.setFileName(cv.Title + '.' + cv.FileType); 
                                             efa.setBody(cv.VersionData); 
                                             
                                             if(mapDocuIdToAttachments.containsKey(mapCDLIdToDocuId.get(cv.ContentDocumentId))){
                                                 mapDocuIdToAttachments.get(mapCDLIdToDocuId.get(cv.ContentDocumentId)).add(efa);
                                             }else{
                                                 mapDocuIdToAttachments.put(mapCDLIdToDocuId.get(cv.ContentDocumentId), new List<Messaging.EmailFileAttachment>{efa});
                                             }
                                         } 
                List<Messaging.SingleEmailMessage> listEmails = new List<Messaging.SingleEmailMessage>();
                List<Document__c> listDocumentToUpdate = new List<Document__c>();
                if(!mapDocuIdToAttachments.isEmpty()){
                    String contactId = [SELECT Id, Email FROM Contact WHERE Email != null LIMIT 1]?.Id;
                    if(String.isNotBlank(contactId)){
                        for(Id key : mapDocuIdToAttachments.keySet()){
                            // New email message 
                            Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(templateId, userInfo.getUserId(), key); 
                            
                            mail.toAddresses = new List<String>(Label.BAGSignedEmailRecipients.split(',')); mail.setTargetObjectId(contactId); 
                            if(mapDocIdToAccountId.containsKey(key)){ mail.setWhatId(mapDocIdToAccountId.get(key));  }
                            mail.setTreatTargetObjectAsRecipient(false); mail.setTreatBodiesAsTemplate(true);  mail.setFileAttachments(mapDocuIdToAttachments.get(key));mail.setOrgWideEmailAddressId(orgWideEmailAddressId);  
                            listEmails.add(mail);
                            
                            listDocumentToUpdate.add(new Document__c(Id = key, IsEmailSenttoADHA__c = true)
                                                    );
                        }
                    }
                }
                if(!Test.isRunningTest() && !listEmails.isEmpty()){ 
                    Messaging.SendEmailResult[] results = Messaging.sendEmail(listEmails); 
                    if (results[0].success) { 
                        update listDocumentToUpdate;
                        System.debug('The email was sent successfully.'); 
                    } else { 
                        System.debug('The email failed to send: ' + results[0].errors[0].message); 
                    } 
                } 
            }
        }
    }
    
    public static void validateGenerateDocument(List<Sobject> newList, Map<Id, Sobject> oldMap){
        
        String errorMessage = '';
        
        Set<Id> setAccountIds = new Set<Id>();
        Set<Id> setDebitRequestIds = new Set<Id>();
        for(Document__c doc : (List<Document__c>) newList){
            Document__c oldRecord = (Document__c) oldMap.get(doc.Id);
            
            if(doc.GenerateDocument__c && !oldRecord.GenerateDocument__c && doc.DocumentType__c =='KYC Form' && doc.Account__c != null){
                setAccountIds.add(doc.Account__c);
            }
            if(doc.GenerateDocument__c && !oldRecord.GenerateDocument__c && doc.DocumentType__c =='Direct Debit registration form' && doc.DirectDebitRequest__c != null){
                setDebitRequestIds.add(doc.DirectDebitRequest__c);
            }
        }
        if(!setAccountIds.isEmpty()){
            errorMessage = DocumentValidationService.validateDocumentAccount(setAccountIds);
        }
        if(!setDebitRequestIds.isEmpty()){
            errorMessage = DocumentValidationService.validateDocumentDebitRequest(setDebitRequestIds);
        }
        
        if(errorMessage != ''){
            for(Document__c doc : (List<Document__c>) newList){
                if(errorMessage.contains('No Primary Contact')){
                    doc.addError(errorMessage);
                }else{
                    doc.addError('Please make sure the following fields populated:\n'+errorMessage);
                }
                
            }
        }
    }
    
    // Added by Moh Sarfaraj for BPM-536
    public static void updateDocumentURLToSuspensionWarning(Map<Id,Id> mapDocumentToSuspension){
        String baseURL = URL.getOrgDomainURL().toExternalForm() + '/lightning/r/ContentDocument/';
        Set<Id> setSuspensionIdToGetOnlyOneRecord = new Set<Id>();
        
        List<Suspensions_Warning__c> listSuspensionWarnToUpdateURL = new List<Suspensions_Warning__c>();
        for(ContentDocumentLink CDLink : [SELECT LinkedEntityId,ContentDocument.LatestPublishedVersionId,
                                          ContentDocumentId FROM ContentDocumentLink WHERE 
                                          LinkedEntityId IN :mapDocumentToSuspension.keySet() 
                                          ORDER BY SystemModstamp DESC]){
                                              
                                              if(!setSuspensionIdToGetOnlyOneRecord.contains(mapDocumentToSuspension?.get(CDLink?.LinkedEntityId))){
                                                  setSuspensionIdToGetOnlyOneRecord.add(mapDocumentToSuspension?.get(CDLink?.LinkedEntityId));
                                                  listSuspensionWarnToUpdateURL.add(new Suspensions_Warning__c(
                                                      Id = mapDocumentToSuspension?.get(CDLink?.LinkedEntityId),
                                                      DocumentURL__c = baseURL + CDLink.ContentDocumentId+'/view'
                                                  ));
                                              }
                                          } 
        if(!listSuspensionWarnToUpdateURL.isEmpty()){
            Database.update(listSuspensionWarnToUpdateURL, false);
        }
    }
    
    public static void populateCongaTemplate(list<Document__c> newDocuments){
        map<string, list<DocumentPlaceHolder__mdt> > mappingRecords = new map<string, list<DocumentPlaceHolder__mdt> >();
        map<Id,Salesorder__c> soToProjectMap = new map<id,Salesorder__c>();
        set<Id> projectIds = new set<Id>();
        set<string> templateNames = new set<string>();
        list<Document__c> docs2Process = new list<Document__c>();
        for(Document__c tempDocRec: newDocuments){
            if(tempDocRec.Conga_template__c == null){
                docs2Process.add(tempDocRec);
                if(tempDocRec.Salesorder__c!=null && tempDocRec.Conga_template__c == null){
                    projectIds.add(tempDocRec.Salesorder__c);
                }
            }
        }
        
        if(!projectIds.isEmpty()){
            for(Salesorder__c so : [select id, ProjectName__c, Unit__c from Salesorder__c where id in :projectIds]){
                soToProjectMap.put(so.Id,so);
            }
        }
        
        if(!docs2Process.isEmpty()){
            
            for(DocumentPlaceHolder__mdt tempRec: [select id,DeveloperName,DocumentType__c,eSignRequired__c,
                                                   ProjectName__c, DeliveryOption__c, DocgenPackageName__c,
                                                   GeneratedManually__c,Template_ID__c, Query_Filter__c 
                                                   from DocumentPlaceHolder__mdt 
                                                   where Template_ID__c != null]){
                                                       string key = tempRec.DeveloperName.tolowerCase()+tempRec.DocumentType__c.tolowerCase();
                                                       if(tempRec.ProjectName__c!=null)
                                                           key = tempRec.DeveloperName.tolowerCase()+tempRec.DocumentType__c.tolowerCase()+tempRec.ProjectName__c.tolowerCase();
                                                       
                                                       if(!mappingRecords.containsKey(key)){
                                                           mappingRecords.put(key, new list<DocumentPlaceHolder__mdt>{tempRec});
                                                       }
                                                       else{
                                                           list<DocumentPlaceHolder__mdt> existing = mappingRecords.get(key);
                                                           existing.add(tempRec);
                                                           mappingRecords.put(key,existing);
                                                       }
                                                       
                                                       if(!mappingRecords.containsKey(tempRec.DocumentType__c.tolowerCase())){
                                                           mappingRecords.put(tempRec.DocumentType__c.tolowerCase(), new list<DocumentPlaceHolder__mdt>{tempRec});
                                                       }
                                                       else{
                                                           list<DocumentPlaceHolder__mdt> existing = mappingRecords.get(tempRec.DocumentType__c.tolowerCase());
                                                           existing.add(tempRec);
                                                           mappingRecords.put(key,existing);
                                                       }
                                                       templateNames.add(tempRec.Template_ID__c);
                                                   }
            
            map<string, APXTConga4__Conga_Template__c> mpTemplates = new map<string, APXTConga4__Conga_Template__c>();
            for(APXTConga4__Conga_Template__c temp : [Select id, APXTConga4__Name__c from APXTConga4__Conga_Template__c where APXTConga4__Name__c in : templateNames]){
                mpTemplates.put(temp.APXTConga4__Name__c, temp);
            }
            system.debug('>>>>templateNames>>>>'+templateNames);
            for(Document__c tempDocRec: newDocuments){
                string documentPlaceHolderId = tempDocRec.DocumentPlaceHolderId__c!=null? tempDocRec.DocumentPlaceHolderId__c:'';
                string templaterecordToFetch = tempDocRec.DocumentType__c;
                string noProj = tempDocRec.DocumentType__c;
                string unitId = '';
                if(tempDocRec.Salesorder__c!=null){
                    if(soToProjectMap.containsKey(tempDocRec.Salesorder__c)){
                        templaterecordToFetch = tempDocRec.DocumentType__c + soToProjectMap.get(tempDocRec.Salesorder__c).ProjectName__c;
                        unitId = soToProjectMap.get(tempDocRec.Salesorder__c).Unit__c;
                    }
                }
                system.debug('>>>>documentPlaceHolderId>>>>>'+documentPlaceHolderId);
                system.debug('>>>>templaterecordToFetch>>>>>'+templaterecordToFetch);
                system.debug('>>>>noProj>>>>>'+noProj);
                if(tempDocRec.DocumentType__c!=null && (mappingRecords.containsKey(documentPlaceHolderId.tolowerCase() + templaterecordToFetch.tolowerCase()) ||  mappingRecords.containsKey(documentPlaceHolderId.tolowerCase() + noProj.tolowerCase())  || mappingRecords.containsKey(noProj.tolowerCase()) )){
                    list<DocumentPlaceHolder__mdt> docs2Check = mappingRecords.containsKey(documentPlaceHolderId.tolowerCase() + templaterecordToFetch.tolowerCase()) ? mappingRecords.get(documentPlaceHolderId.tolowerCase() + templaterecordToFetch.tolowerCase()) : (mappingRecords.containsKey(documentPlaceHolderId.tolowerCase() + noProj.tolowerCase()) ? mappingRecords.get(documentPlaceHolderId.tolowerCase() + noProj.tolowerCase()) : mappingRecords.get(noProj.tolowerCase()) );
                        System.debug('>>>>>docs2Check>>>>'+docs2Check);
                    for(DocumentPlaceHolder__mdt tempRec : docs2Check){
                        if(tempDocRec.Salesorder__c != null && tempRec.Query_filter__c != null){
                            if(checkQuery(tempRec, tempDocRec.Salesorder__c))
                                tempDocRec.Conga_Template__c = mpTemplates.get(tempRec.Template_ID__c).Id;
                        }
                        else
                            tempDocRec.Conga_Template__c = mpTemplates.get(tempRec.Template_ID__c).Id;
                    }
                }
            }
        }
        
    }
    
    public static boolean checkQuery(DocumentPlaceHolder__mdt temp, id recordId){
        list<sobject> lstObjects = database.query(temp.Query_filter__c+' and Id =: recordId');
        return !lstObjects.isEmpty();
    }
}