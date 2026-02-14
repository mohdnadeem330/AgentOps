public with sharing class InvoiceBundleTriggerHandler extends TriggerHandler {
    static Id checklistRTId = Schema.SObjectType.Checklist__c.getRecordTypeInfosByDeveloperName().get('InvoiceBundle').getRecordTypeId();
    //*** Before Insert Action***//
    public override void beforeInsertMethod(List<SObject> newList, Map<Id, SObject> newMap){
        for(InvoiceBundle__c eachInvoiceBundle : (List<InvoiceBundle__c>) newList){
            
        }
    }
    
    //*** After Insert Action***//
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap){
        
        Set<Id> brokerAgencyIdSet = new Set<Id>();
        for(InvoiceBundle__c eachInvoiceBundle : (List<InvoiceBundle__c>) newList){
            if(eachInvoiceBundle.BrokerAgency__c != null){
                brokerAgencyIdSet.add(eachInvoiceBundle.BrokerAgency__c);
            }
        }
        
        //Added by KP for VFS Sharing
        if(!brokerAgencyIdSet.isEmpty() && !Test.isRunningTest()){
            VFSSharingHelper.shareInvoicesAndCommisionsWithVFSTeam(brokerAgencyIdSet);
        }
    }

    public override void beforeUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) {
        
        for(InvoiceBundle__c newRecord  : (list<InvoiceBundle__c >) newList){
            InvoiceBundle__c oldRecord = (InvoiceBundle__c) oldMap.get(newRecord.ID);
            
            if(newRecord.Status__c != oldRecord.Status__c ){
                if(newRecord.Status__c == 'Ready for Submission'){   
                    newRecord.InvoiceDate__c = System.Today();
                }else if(newRecord.Status__c == 'Sent to Finance'){ 
                    newRecord.SenttoFinanceDate__c = System.Today();
                }else if(newRecord.Status__c == 'Paid'){ 
                    newRecord.PaidDate__c = System.Today();
                }
            }
            
            //Invoice Comments Trails
            if((oldRecord.InvoiceApproverComments__c != newRecord.InvoiceApproverComments__c && newRecord.InvoiceApproverComments__c!='' && newRecord.InvoiceApproverComments__c!=null) ||
                (oldRecord.InvoiceApproverName__c != newRecord.InvoiceApproverName__c && newRecord.InvoiceApproverName__c!='' && newRecord.InvoiceApproverName__c!=null)||
                (oldRecord.InvoiceApprovedDate__c != newRecord.InvoiceApprovedDate__c && newRecord.InvoiceApprovedDate__c!=null) ){
                    if(newRecord.InvoiceTrails__c != null){
                        newRecord.InvoiceTrails__c += '\n'+newRecord.InvoiceApproverName__c + ', '+newRecord.InvoiceResponse__c+', '+newRecord.InvoiceApprovedDate__c.format()+'\n' +newRecord.InvoiceApproverComments__c != null ? newRecord.InvoiceApproverComments__c : '' +'\n----------------\n';
                    }else{
                        newRecord.InvoiceTrails__c = '\n'+newRecord.InvoiceApproverName__c +', '+newRecord.InvoiceResponse__c+', '+newRecord.InvoiceApprovedDate__c.format()+'\n' +newRecord.InvoiceApproverComments__c != null ? newRecord.InvoiceApproverComments__c : '' +'\n----------------\n';
                    }
            }
            //Payment Comments Trails
            if((oldRecord.PaymentApproverComments__c != newRecord.PaymentApproverComments__c && newRecord.PaymentApproverComments__c!='' && newRecord.PaymentApproverComments__c!=null) ||
                (oldRecord.PaymentApproverName__c != newRecord.PaymentApproverName__c && newRecord.PaymentApproverName__c!='' && newRecord.PaymentApproverName__c!=null)||
                (oldRecord.PaymentApprovedDate__c != newRecord.PaymentApprovedDate__c && newRecord.PaymentApprovedDate__c!=null)){
                if(newRecord.PaymentApprovalTrails__c != null){
                    newRecord.PaymentApprovalTrails__c += '\n'+newRecord.PaymentApproverName__c +', '+newRecord.PaymentResponse__c+', '+newRecord.PaymentApprovedDate__c.format()+'\n' +newRecord.PaymentApproverComments__c != null ? newRecord.PaymentApproverComments__c : '' +'\n----------------\n';
                }else{
                    newRecord.PaymentApprovalTrails__c = '\n'+newRecord.PaymentApproverName__c +', '+newRecord.PaymentResponse__c+' '+newRecord.PaymentApprovedDate__c.format()+'\n' +newRecord.PaymentApproverComments__c != null ? newRecord.PaymentApproverComments__c : '' +'\n----------------\n';
                }
            }
            //Bank Comments Trails
            if((oldRecord.BankComments__c != newRecord.BankComments__c && newRecord.BankComments__c!='' && newRecord.BankComments__c!=null)||
                (oldRecord.BankApprovedDate__c != newRecord.BankApprovedDate__c && newRecord.BankApprovedDate__c!=null)){
                if(newRecord.BankApprovalTrails__c != null){
                    newRecord.BankApprovalTrails__c += '\n'+newRecord.BankApprovedDate__c.format()+', '+newRecord.BankResponse__c+', '+newRecord.BankComments__c != null ? newRecord.BankComments__c : '' +'\n----------------\n';
                }else{
                    newRecord.BankApprovalTrails__c = '\n'+newRecord.BankApprovedDate__c.format()+', '+newRecord.BankResponse__c+', '+newRecord.BankComments__c != null ? newRecord.BankComments__c : '' +'\n----------------\n';
                }
            }            
        }
    }
    
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        Set<String> rejectionReasons = new Set<String>{'VAT Registration Certificate is required','VAT undertaking letter is required',
                                                      'The brokers bank account and supplier name not matching','The bank account not matching with invoice, or the SWIFT code is not update',
                                                       'Branch city of the bank account is not mentioned','The invoice without VAT and system calculates the VAT or opposite'};
                                                           
        List<InvoiceBundle__c> invoiceBundleList = new List<InvoiceBundle__c>();
        List<InvoiceBundle__c> invoiceBundleListForCallout = new List<InvoiceBundle__c>();
        List<InvoiceBundle__c> rejectedInvoiceBundles = new List<InvoiceBundle__c>();
        Set<Id> setInvoiceIdToCreateChecklist = new Set<Id>();
        Set<Id> brokerAgencyIdSet = new Set<Id>();
        
        system.debug('newList::'+newList);
        for(InvoiceBundle__c newRecord  : (list<InvoiceBundle__c >) newList){
            InvoiceBundle__c oldRecord = (InvoiceBundle__c) oldMap.get(newRecord.ID);
            
            if(newRecord.Status__c != oldRecord.Status__c && newRecord.Status__c != null){  invoiceBundleList.add(newRecord); }
            if(newRecord.ApprovalStatus__c != oldRecord.ApprovalStatus__c && newRecord.ApprovalStatus__c == 'Approved'){
                invoiceBundleListForCallout.add(newRecord);
            }
            if(newRecord.Status__c != oldRecord.Status__c && newRecord.Status__c == 'Rejected' && rejectionReasons.contains(newRecord.RejectionReasonPicklist__c)){ rejectedInvoiceBundles.add(newRecord);}
        
            // Added by Moh Sarfaraj for BPM-672
            if(newRecord.Status__c != oldRecord.Status__c && newRecord.Status__c == 'Pending Invoice Verification'){
                setInvoiceIdToCreateChecklist.add(newRecord.Id);
            }
            
            //Added by KP for VFS Sharing
            if(newRecord.BrokerAgency__c != null){
                brokerAgencyIdSet.add(newRecord.BrokerAgency__c);
            }
        }
        if(!invoiceBundleList.isEmpty()){ updateAllCLIStatuses(invoiceBundleList);
        }
        if(!invoiceBundleListForCallout.isEmpty()){
           // prepareCallout(invoiceBundleListForCallout);
        }
        if(!rejectedInvoiceBundles.isEmpty()){ InvoiceBundleService.deReferenceCommissionLinesOnRejection(rejectedInvoiceBundles);}
    
        // Added by Moh Sarfaraj for BPM-672
    	if(!setInvoiceIdToCreateChecklist.isEmpty()){
            createChecklist(setInvoiceIdToCreateChecklist);
        }
        
        if(!brokerAgencyIdSet.isEmpty() && !Test.isRunningTest()){
            VFSSharingHelper.shareInvoicesAndCommisionsWithVFSTeam(brokerAgencyIdSet);
        }
    }
    
    public static void updateAllCLIStatuses(List<InvoiceBundle__c> invoiceBundleList){
        List<CommissionLineItem__c> commissionLineItemListToUpdate = new List<CommissionLineItem__c>();
        List<CommissionLineItem__c> commissionLineItemList = [SELECT Id, Status__c, AgencyAdmin__c, OwnerID, Comments__c,InvoiceBundle__r.Status__c,InvoiceBundle__r.AgencyAdmin__c, InvoiceBundle__r.OwnerID, InvoiceBundle__r.Comments__c  FROM CommissionLineItem__c WHERE InvoiceBundle__c IN: invoiceBundleList];
        for(CommissionLineItem__c cli : commissionLineItemList){
            commissionLineItemListToUpdate.add(new CommissionLineItem__c(Id=cli.Id, status__c=cli.InvoiceBundle__r.Status__c, AgencyAdmin__c=cli.InvoiceBundle__r.AgencyAdmin__c ,OwnerID= userInfo.getUserId(), Comments__c =  cli.InvoiceBundle__r.Comments__c));
        }
        if(!commissionLineItemListToUpdate.isEmpty()){
            update commissionLineItemListToUpdate;
        } 
    }
    public class InputVariables{
        @InvocableVariable
        Public list<InvoiceBundle__c> invoiceBundleList;
    }
    @Invocablemethod
    public static void prepareCallout(List<InputVariables> inputVariables){
        list<InvoiceBundle__c> invoiceBundleList = inputVariables.get(0).invoiceBundleList;
        List<Id> relatedIds                           = new List<Id>();
        Map<Id, Id> invoiceBundleDocMap               = new Map<Id, Id>();
        Map<Id, Map<String, String>> publicIdURLMap   = new Map<Id, Map<String, String>>();
        Map<Id, Map<String, String>> newMap           = new Map<Id, Map<String, String>>();
        List<Object> invoiceBundleObjectList          = new List<Object>();
        Map<String, Object> finalMap                  = new Map<String, Object>();
        Map<Id, List<CommissionLineItem__c>> invCliMap= new Map<Id, List<CommissionLineItem__c>>();
        List<Id> recordIds                            = new List<Id>();
        List<Id> invoiceClaimDocIds                   = new List<Id>();
        Map<Id, Map<String, String>> invoiceClaimDocMap           = new Map<Id, Map<String, String>>();
        Map<Id, Id> invoiceClaimFormDocMap            = new Map<Id, Id>();
        Map<Id, Map<String, String>> publicIdURLMapForClaim   = new Map<Id, Map<String, String>>();
        
        List<InvoiceBundle__c> alliInvoiceBundleList= [SELECT 
                                                       AgencyAdmin__c,
                                                       ApprovalStatus__c,
                                                       BrokerAgency__c,
                                                       BundleName__c,
                                                       BundleNumber__c,
                                                       Comments__c,
                                                       Id,
                                                       Name,
                                                       Status__c,
                                                       ERPID__c,
                                                       TotalCommissionAmount__c,
                                                       TotalCommissionLineItemCount__c,
                                                       Createddate,
                                                       lastmodifiedDate
                                                       FROM InvoiceBundle__c WHERE Id in:invoiceBundleList
                                                      AND ApprovalStatus__c = 'Approved'];
        
        
      List<CommissionLineItem__c> CommissionLineItems = [SELECT 
                                                         Id,
                                                         InvoiceBundle__c,
                                                         BrokerAgency__c,
                                                         BrokerAgent__c,
                                                         CommissionAmount__c,
                                                         CommissionPercentage__c,
                                                         CommissionType__c,
                                                         InstallmentLine__c,
                                                         InstalmentNumber__c,
                                                         SalesOrder__c,
                                                         ERPID__c,
                                                         Unit_Number__c,
                                                         Createddate, 
                                                         lastmodifiedDate
                                                         FROM CommissionLineItem__c
                                                         WHERE InvoiceBundle__c IN:invoiceBundleList];
        
        for(CommissionLineItem__c cli: CommissionLineItems){
            List<CommissionLineItem__c> cliList = invCliMap.get(cli.InvoiceBundle__c) != null ? invCliMap.get(cli.InvoiceBundle__c) : new List<CommissionLineItem__c>();
            cliList.add(cli);
            invCliMap.put(cli.InvoiceBundle__c, cliList);
        }
        for(Document__c doc: [SELECT Id, InvoiceBundle__c, DocumentType__c, AvailableForExternalUsers__c FROM Document__c WHERE InvoiceBundle__c IN: invoiceBundleList AND (DocumentType__c =: Constants.DOCUMENT_PLACEHOLDER_CATEGORY_COMMISSION_INVOICE OR DocumentType__c = 'Invoice Claim Form')]) {
            relatedIds.add(doc.Id);
            invoiceBundleDocMap.put(doc.Id, doc.InvoiceBundle__c);  
            if(doc.DocumentType__c == 'Invoice Claim Form'){
                invoiceClaimDocIds.add(doc.Id);//hodling Invoice Claim Document Ids
                invoiceClaimFormDocMap.put(doc.Id, doc.InvoiceBundle__c);
            } 
        }
        newMap = ContentDocumentLinkService.getIdUSLMap(relatedIds);
        for (Id docId: newMap.keySet()) {
            if (invoiceBundleDocMap.containsKey(docId)) {
                publicIdURLMap.put(invoiceBundleDocMap.get(docId), newMap.get(docId));
            }
        }
        
        //Invoice Claim Form - Public URL        
        invoiceClaimDocMap = ContentDocumentLinkService.getIdUSLMap(invoiceClaimDocIds);
        for(Id docId : invoiceClaimDocMap.keySet()){
            if(invoiceClaimFormDocMap.containsKey(docId)){
                publicIdURLMapForClaim.put(invoiceClaimFormDocMap.get(docId), invoiceClaimDocMap.get(docId));
            }
        }
        
        for(InvoiceBundle__c inv: alliInvoiceBundleList){
            if((invCliMap.containsKey(inv.Id) && invCliMap.get(inv.Id).size()>0) || (Test.isRunningTest())){
                Map<String, Object> invMap = new Map<String, Object>();
                Map<String, String> idURLMap = publicIdURLMap.containsKey(inv.Id) ? publicIdURLMap.get(inv.Id) : new Map<String, String>();
                Map<String, String> idURLMapForClaimForm = publicIdURLMapForClaim.containsKey(inv.Id) ? publicIdURLMapForClaim.get(inv.Id) : new Map<String, String>();
                
                inv.ERPID__c = inv.ERPID__c != null ? inv.ERPID__c : '';
                
                invMap.put('Invoice', inv);
                invMap.put('CommissionLineItems', invCliMap.get(inv.Id)); 
                invMap.put('doc1Id', !idURLMap.isEmpty() && idURLMap.containsKey('Id') ? idURLMap.get('Id') : '');
                invMap.put('doc1Url', !idURLMap.isEmpty() && idURLMap.containsKey('URL') ? idURLMap.get('URL') : '');
                invMap.put('invoiceClaimFormDocId', !idURLMapForClaimForm.isEmpty() && idURLMapForClaimForm.containsKey('Id') ? idURLMapForClaimForm.get('Id') : '');
                invMap.put('invoiceClaimFormDocURL', !idURLMapForClaimForm.isEmpty() && idURLMapForClaimForm.containsKey('URL') ? idURLMapForClaimForm.get('URL') : '');
                invoiceBundleObjectList.add(invMap); recordIds.add(inv.Id);
            }
        }
        
        finalMap.put('InvoiceBundleDetails',invoiceBundleObjectList);
        system.debug('finalMap::'+finalMap);
        String requestBody = JSON.serialize(finalMap);
        system.debug('requestBody::'+requestBody);
        if(recordIds.size()>0){
            try{
                if(System.isBatch()){
                    CalloutToMuleSoft.calloutService(requestBody,true,'InvoiceBundle',recordIds);
                }
                else{
                    CalloutToMuleSoft.calloutFutureService(requestBody,true,'InvoiceBundle',recordIds);
                }
            }catch(Exception ex){
                Logger__c lgs = LoggerService.saveAndReturnLogger(LoggerService.createApexLog(ex,'InvoiceBundle','InvoiceBundleTriggerHandler','prepareCallOut')); }           
        }
    }
    
    public static void updateERPResponse(String json){
        system.debug('json::'+json);
        InvoiceBundleWrapper wrapper = parseResponse(json);
        system.debug('wrapper::'+wrapper);
        List<InvoiceBundle__c> invoiceBundleList = new List<InvoiceBundle__c>(); 
        system.debug(wrapper.results);
        List<Object> objlist = (List<Object>)wrapper.results;
        system.debug('objlist::'+objlist); 
        
        for(Object obj: objlist){
            InvoiceBundleWrapper.cls_results result = (InvoiceBundleWrapper.cls_results)obj;
            invoiceBundleList.add(new InvoiceBundle__c(Id = result.sfBundleId, SyncStatus__c = (result.errorMsg != null && result.errorMsg != '') ? 'Failed': 'Synced', ErrorReason__c   = (result.errorMsg != null && result.errorMsg != '') ? result.errorMsg: '') );
        }
        if(!invoiceBundleList.isEmpty()){
            update invoiceBundleList;
        }
    }
    
    public static InvoiceBundleWrapper parseResponse(String json){
        return (InvoiceBundleWrapper)System.JSON.deserialize(json, InvoiceBundleWrapper.class);
    }
    
    // Added by Moh Sarfaraj for BPM-672
    private static void createChecklist(Set<Id> setInvoiceIdToCreateChecklist){
        List<Checklist__c> listChecklistToInsert = new List<Checklist__c>();
        for(InvoiceBundle__c eachIB : [SELECT Id,(SELECT Id FROM Checklists__r) FROM InvoiceBundle__c 
                                       WHERE Id IN :setInvoiceIdToCreateChecklist]){
                                           
            if(eachIB.Checklists__r.isEmpty()){
                
                listChecklistToInsert.add(
                new Checklist__c(
                    InvoiceBundle__c = eachIB.Id,
                    RecordTypeId = checklistRTId,
                    Is_Active__c = true
                ));
            }
        }
        if(!listChecklistToInsert.isEmpty()){
            insert listChecklistToInsert;
        }
    }
}