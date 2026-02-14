/*Class     : DMCaseSendDocToCustomer
Author      : Smaartt
Description : This class contains methods related to vf pages,creation and sending documents to the customer
TestClass   : DMCaseSendDocToCustomerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.        V1.0              23/02/24           Initial Version 
****************************************************************************************************************/
public class DMCaseSendDocToCustomer {
    @AuraEnabled
    public static void sendEvacutionchklst(String caseId) {
        Map<String, Object> flowInputs = new Map<String, Object>();
        flowInputs.put('caseId', caseId);
        Flow.Interview.Case_DM_SendEvacuationChecklist flowInterview = new Flow.Interview.Case_DM_SendEvacuationChecklist(flowInputs);
        flowInterview.start();
        updateCaseStatus(caseId, Label.DM_TLACaseEvacuation, Label.DM_CaseWorkInProgress);
        
    }
    private static void updateCaseStatus(String caseId, String subStatus, String statuses) {
        try {
            Case caseRecord = new Case();
            caseRecord.Id=caseId;
            caseRecord.Sub_Status__c = subStatus;
            caseRecord.Status = statuses;
            update caseRecord;
        } catch (Exception e) {
            System.debug('Error in updateCaseStatus: ' + e.getMessage());
        }
    }    
    @AuraEnabled  
    public static void SendOverstayDetails(String caseId) {  
        try {
            Case caseRecord = [SELECT Id, AccountId, Licensee_Email__c, Sub_Status__c, Status, ContactId, Total_Overstay_Amount__c 
                               FROM Case WHERE Id = :caseId LIMIT 1];
            
            EmailTemplate templates = [SELECT Id, Body, HtmlValue, Markup, Subject, DeveloperName
                                   FROM EmailTemplate
                                   WHERE DeveloperName =:Label.Case_DM_CaseTLA_OverstayEmailTemplate];
        Id orgWideEmailAddressId = [SELECT Id, Address FROM OrgWideEmailAddress
                                    WHERE DisplayName =: Label.DM_orgWideEmailAdress LIMIT 1].Id;
            List<String> ccAddresses = new List<String>();
        if (!String.isBlank(Label.DM_TLA_CCAdresses)) {
            ccAddresses = Label.DM_TLA_CCAdresses.split(','); 
        }
        Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(templates.Id, null, caseId);
        email.setToAddresses(new String[] {caseRecord.Licensee_Email__c });
        email.setCcAddresses(ccAddresses); 
        email.setOrgWideEmailAddressId(orgWideEmailAddressId);
        email.setSubject(templates.Subject);
        email.setTemplateId(templates.Id);
        email.setSaveAsActivity(false);       
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});    
        } 
        catch (Exception e) {
            System.debug('Error in PaymentReqforGenerationOfOverStayInvoice: ' + e.getMessage());
        }
    } 
    
    public static void generateDocument(String ddpId, String deliveryOptionId, String recordId) {
        loop.RunDocGenAsync.DdpParams parms = new loop.RunDocGenAsync.DdpParams();
        parms.ddpId = ddpId;
        parms.deliveryOptionId = deliveryOptionId;
        parms.recordId = recordId;
        
        List<String> output = loop.RunDocGenAsync.run(new List<loop.RunDocGenAsync.DdpParams>{parms});
        System.debug('Output='+output);
        
    }    
    public class DocumentWrapper {
        @AuraEnabled
        public String LoopDDPId { get; set; }
        @AuraEnabled
        public String LoopDDPRecordId { get; set; }
        @AuraEnabled
        public String DocumentId { get; set; }
        
        public DocumentWrapper(String loopDDPId, String loopDDPRecordId, String documentId) {
            this.LoopDDPId = loopDDPId;
            this.LoopDDPRecordId = loopDDPRecordId;
            this.DocumentId = documentId;
        }
    }   
    
    @AuraEnabled
   public static DocumentWrapper createAndLinkDocument(String caseId, String docType) {
        DocumentWrapper result;
        try {
             Map<string,string> CaseRecTypeNames = DM_UtilityController.getCaseRecTypeName(new list<string>{caseId});
            Id tempDocId;
            List<Document__c> existingDocs = [SELECT Id FROM Document__c WHERE Case__c = :caseId AND DocumentType__c =: docType LIMIT 1];
            List<Payment_Request__c> paymentReqs = [SELECT Id, Amount__c, Payment_Type__c, Instalment_Date__c FROM Payment_Request__c WHERE Case__c = :caseId];       
            if (!paymentReqs.isEmpty()) {
                integer pdcCount = 0;
                for(Payment_Request__c py : paymentReqs){
                    if(py.Payment_Type__c== Label.DM_PaymentTypePDC)
                        pdcCount= pdcCount+1;
                }
                String paymentStr = '';                
                if (paymentReqs.size() == 1) {                    
                    if (paymentReqs[0].Payment_Type__c == Label.DM_PaymentTypeWireTransfer) {
                        paymentStr =  'in a bank transfer before executing enclosed license agreement.';
                    } else if (paymentReqs[0].Payment_Type__c == Label.DM_PaymentTypeCDC) {
                        paymentStr =  ' in a Current dated cheque to be cashed before executing enclosed license agreement. ';
                    }                        
                } else if (paymentReqs.size() > 1) {
                    Integer pdcCC = 0;
                    for(Payment_Request__c pr : paymentReqs){
                        if(pr.Payment_Type__c== Label.DM_PaymentTypeCDC){
                            Decimal rA = pr.Amount__c;
                            String payAmount = CommaseparatedValues(rA);
                            paymentStr += 'in a current dated cheque for AED' +' '+ payAmount+'.00'+' '+ '+ VAT to be cashed immediately before executing enclosed License Agreement.';
                        }else if(pr.Payment_Type__c=='PDC'){  
                            DateTime dt = Date.valueOf(pr.Instalment_Date__c);
                            string installementDate = string.valueof(dt.format('d MMMM yyyy'));
                            Decimal rA1 = pr.Amount__c;
                            String payAmount = CommaseparatedValues(rA1);
                            pdcCC= pdcCC+1;
                            if(pdcCC==1)
                            paymentStr +=' Followed by payment installments as per ';  
                            paymentStr += 'post-dated cheque amount of AED'+ ' ' + payAmount+' ' + '+ VAT dated'+ ' ' +installementDate;
                            if(pdcCC<pdcCount){
                                paymentStr +=' and ';                               
                            }else{
                                paymentStr +='.'; 
                            }
                        }                        
                    }
                }              
                Case cas = new Case();  
                cas.Id=caseId;
                cas.CommentsForCustomer__c = paymentStr;
                update cas;     
            }
                 
            
            if (!existingDocs.isEmpty()) {
                tempDocId = existingDocs[0].Id;
                if(docType == Label.DM_DraftTLA){
                    Loop__DDP_Integration_Option__c LoopdRec= [select id,Name,Loop__DDP__c,Loop__DDP__r.Name from Loop__DDP_Integration_Option__c where Name =: Label.DM_Nintex_TLA];
                    result = new DocumentWrapper(LoopdRec.Loop__DDP__c, LoopdRec.Id, tempDocId);
                    updateCaseStatus(caseId, Label.DM_Draft_License_Agreement_In_Progress, Label.DM_CaseWorkInProgress);
                }else if(docType == Label.DM_DraftCAS){
                    Loop__DDP_Integration_Option__c LoopdRec= [select id,Name,Loop__DDP__c,Loop__DDP__r.Name from Loop__DDP_Integration_Option__c where Name =:Label.DM_Nintex_CAS];
                    result = new DocumentWrapper(LoopdRec.Loop__DDP__c, LoopdRec.Id, tempDocId);
                    updateCaseStatus(caseId, Label.DM_CAS_In_Progress, Label.DM_CaseWorkInProgress);
                }
            } else {
                Document__c document = new Document__c();
                document.RecordTypeId = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(Label.DM_CustomerDocumentRecordType).getRecordTypeId();
                document.Status__c = Label.DM_DocumentUploaded;
                document.Case_Recordtype__c=CaseRecTypeNames.get(caseId);
                document.Case__c = caseId;
                document.DocumentType__c = docType;
                insert document;
                tempDocId = document.Id;               
                if(docType == Label.DM_DraftTLA){
                    Loop__DDP_Integration_Option__c LoopdRec= [select id,Name,Loop__DDP__c,Loop__DDP__r.Name from Loop__DDP_Integration_Option__c where Name =: Label.DM_Nintex_TLA];
                    result = new DocumentWrapper(LoopdRec.Loop__DDP__c, LoopdRec.Id, tempDocId);
                    updateCaseStatus(caseId, Label.DM_Draft_License_Agreement_In_Progress, Label.DM_CaseWorkInProgress);
                }else if(docType == Label.DM_DraftCAS){
                    Loop__DDP_Integration_Option__c LoopdRec= [select id,Name,Loop__DDP__c,Loop__DDP__r.Name from Loop__DDP_Integration_Option__c where Name =:Label.DM_Nintex_CAS];
                    result = new DocumentWrapper(LoopdRec.Loop__DDP__c, LoopdRec.Id, tempDocId);
                    updateCaseStatus(caseId, Label.DM_CAS_In_Progress, Label.DM_CaseWorkInProgress);
                }
            } 
            
        }catch (Exception e) {
            System.debug('Error in createAndLinkDocument: ' + e.getMessage());
            throw new AuraHandledException( e.getMessage());
        }
        return result;
    }      
    
     @AuraEnabled  
    public static void caseCloseRequest(String caseId) {
    List<Document__c> evacuationDocuments = [SELECT Id FROM Document__c WHERE Case__c = :caseId AND DocumentType__c =:label.DM_EvacuationChecklist];

        if (evacuationDocuments.size() > 0) {
            // If an evacuation document exists, update the case
            Case caseToUpdate = new Case();
            caseToUpdate.Id=caseId;
            caseToUpdate.Status = Label.DM_ClosedStatus; 
            caseToUpdate.Sub_Status__c = Label.DM_CompletedSubStatus; 

            update caseToUpdate;
        } else {
            // If no evacuation document, throw an error
            throw new AuraHandledException('No evacuation document found. Case cannot be closed at this stage.');
        }
    }
     public static String CommaseparatedValues(Decimal amount) {
       
        List<String> args = new List<String>{'0', 'number','###,###,##0.00'};
        String updatedAmount = String.format(amount.format(), args)+'.00';  
         return updatedAmount; 
     }
    
}