public with sharing class ChecklistRecordPageController {
    
    @AuraEnabled
    public static ChecklistDetail getChecklistDetails(String recordId){
        try {
            //recordId = 'a3VFW0000000vW92AI';
            
            ChecklistDetail checklist = new ChecklistDetail();
            List<Checklists__mdt> listInvoiceMetadata = [SELECT DeveloperName,FieldAPIName__c,Description__c,
                                                         RejectionReasonFieldAPIName__c FROM Checklists__mdt WHERE 
                                                         Category__c = 'Invoice Bundle' AND IsActive__c = true];
            
            if(listInvoiceMetadata != null && !listInvoiceMetadata.isEmpty()){
                Set<String> setFieldsToQuery = new Set<String>();
                for(Checklists__mdt eachMDT : listInvoiceMetadata){
                    setFieldsToQuery.add(eachMDT.FieldAPIName__c);
                    setFieldsToQuery.add(eachMDT.RejectionReasonFieldAPIName__c);
                }
                
                String query = 'SELECT InvoiceBundle__c, InvoiceBundle__r.BrokerAgency__r.AgencySubCategory__c, InvoiceBundle__r.Name, InvoiceBundle__r.InvoiceDate__c, '+
                    		   'InvoiceBundle__r.BrokerManager__r.Name,' + String.join(setFieldsToQuery, ', ') + 
                               ' FROM Checklist__c '+ 'WHERE Id = :recordId';
                
                List<Checklist__c> listChecklist = Database.query(query);
               
                if(listChecklist != null && !listChecklist.isEmpty()){ 
                    checklist.brokerManagerName = listChecklist[0].InvoiceBundle__r?.BrokerManager__r?.Name;
                    checklist.invoiceNumber = listChecklist[0].InvoiceBundle__r?.Name;
                    checklist.brokerType = listChecklist[0].InvoiceBundle__r?.BrokerAgency__r?.AgencySubCategory__c;
                    
                    List<CommissionLineItem__c> listCLI = [SELECT Id,InvoiceBundle__c,Name,Unit_Number__c,NetAmount__c,Total_External_Commission__c, 
                                                           CurrencyIsoCode FROM CommissionLineItem__c WHERE InvoiceBundle__c = :listChecklist[0].InvoiceBundle__c];
                    
                    List<InnerChecklistDetail> listInnerDetail = new List<InnerChecklistDetail>();
                    for(Checklists__mdt  eachMDT : listInvoiceMetadata){
                        InnerChecklistDetail detail = new InnerChecklistDetail();
                        detail.fieldName = eachMDT.FieldAPIName__c;
                        detail.fieldValue = (String) listChecklist[0].get(eachMDT?.FieldAPIName__c);
                        detail.description = eachMDT?.Description__c;
                        detail.fieldNameRejectionReason = eachMDT?.RejectionReasonFieldAPIName__c;
                        detail.fieldValueRejectionReason = (String) listChecklist[0].get(eachMDT?.RejectionReasonFieldAPIName__c);
                        listInnerDetail.add(detail);
                    }
                    checklist.checklistId = listChecklist[0]?.Id;
                    checklist.listInnerChecklist = listInnerDetail;
                    checklist.listCommissionLineItems = listCLI != null ? listCLI : new List<CommissionLineItem__c>();
                }
            }
            return checklist;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string updateChecklist(String jsonString){
        try {
            Checklist__c checklist = (Checklist__c) JSON.deserialize(jsonString, Checklist__c.class);
            checklist.SubmissionDate__c = System.today();
            update checklist;
            List<Document__c> documentPlaceHolder = [SELECT Id, GenerateDocument__c FROM Document__c WHERE Checklist__c = :checklist.Id];
            Id docgenpackageId =[SELECT Id FROM Loop__DDP__c WHERE Name = 'Commission Invoices Validation Check List updated' LIMIT 1]?.Id;
            Id deliveryOptionId = [SELECT Id FROM Loop__DDP_Integration_Option__c WHERE Loop__DDP__c = :docgenpackageId]?.Id;    
            if(documentPlaceHolder[0].Id != null && checklist.OverallStatus__c != 'Pending'){
                Document__c doc = new document__c();
                doc.Id = documentPlaceHolder[0].Id;
                doc.DocgenPackageId__c = docgenpackageId;
				doc.DeliveryOptionId__c = deliveryOptionId;
                doc.GenerateDocument__c = true;
                update doc;
            }
            
            if(String.isNotBlank(checklist.Id)){
                Id invoiceBundleId = [SELECT InvoiceBundle__c FROM Checklist__c WHERE Id = :checklist.Id]?.InvoiceBundle__c;
                if(invoiceBundleId != null){
                    InvoiceBundle__c invBunlde = new InvoiceBundle__c(
                        Id = invoiceBundleId,
                        Remarks__c = checklist.Remarks__c
                    );
                    invBunlde.ChecklistValidation__c = checklist.OverallStatus__c == 'Approved' ? 'Approved' : checklist.OverallStatus__c == 'Rejected' ? 'Not Approved' : 'Pending';
                    //invBunlde.Status__c = checklist.OverallStatus__c == 'Approved' ? 'Ready for Submission' : 'Not Ready';
                    update invBunlde;
                }
            }
            return 'success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public class ChecklistDetail{
        @AuraEnabled
        public String checklistId {set; get;}
        
        @AuraEnabled
        public String brokerManagerName {set; get;}
                
        @AuraEnabled
        public String invoiceNumber {set; get;}
        
        @AuraEnabled
        public String brokerType {set; get;}

        @AuraEnabled
        public List<InnerChecklistDetail> listInnerChecklist {set; get;}
        
        @AuraEnabled
        public List<CommissionLineItem__c> listCommissionLineItems {set; get;}
    }
    
    public class InnerChecklistDetail{
        @AuraEnabled
        public String fieldName {set; get;}

        @AuraEnabled
        public String fieldValue {set; get;}
        
        @AuraEnabled
        public String description {set; get;}
        
        @AuraEnabled
        public String fieldNameRejectionReason {set; get;}
        
        @AuraEnabled
        public String fieldValueRejectionReason {set; get;}
    }
}