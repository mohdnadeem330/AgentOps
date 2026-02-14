/**********************************************************************************************************************
* Name               : CommissionLineItemTriggerHandler                                                        
* Description        : This class contains all the helper methods for the CommissionLineItem__c Trigger
* Usage              : CommissionLineItemTrigger
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     21 May 2022      Initial Draft       
******************************************************************************************************************/
public with sharing class CommissionLineItemTriggerHandler extends TriggerHandler {
    //*** After Insert Action***//
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        //---- to share Commission Line Item with Broker Manager.
        ShareHelper.shareCommissionLineBrokerManager(newList, Constants.READ_ACCESS);
        
        List<Id> invoiceIdList = new List<Id>();
        for(CommissionLineItem__c newRecord  : (list<CommissionLineItem__c >) newList){
            if(newRecord.InvoiceBundle__c != null){
                invoiceIdList.add(newRecord.InvoiceBundle__c);
            }
        }
        if(!invoiceIdList.isEmpty()){
            getCountOnInvoiceBunlde(invoiceIdList);
        }
    }

    public override void beforeUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) {
        System.debug('Inside beforeUpdateMethod---');
        User currentUser = Utilities.getLoggedInUserDetail();
        set<ID> commissionIds = new set<ID>(); 
        for(CommissionLineItem__c newRecord  : (list<CommissionLineItem__c >) newList){
             
            CommissionLineItem__c oldRecord = (CommissionLineItem__c) oldMap.get(newRecord.ID);
            System.debug('Inside newRecord---'+newRecord.Status__c);
            if( newRecord.Status__c != oldRecord.Status__c && newRecord.Status__c==Constants.COMMISSION_LINE_STATUS_FIXED ){
                newRecord.InvoiceNumber__c = (newRecord.InvoiceNumber__c!=null ? String.ValueOf(Integer.ValueOf(newRecord.InvoiceNumber__c) +1) : '1') ;
                newRecord.InvoiceDate__c = system.today();
            }
            if(oldRecord.Comments__c != newRecord.Comments__c && newRecord.Comments__c!='' && newRecord.Comments__c!=null){newRecord.CommentTrail__c=currentUser.Name +' ('+currentUser.Profile.Name+') '+System.now().format()+'\n ----- \n' +newRecord.Comments__c +'\n\n'+ (newRecord.CommentTrail__c==null?'':newRecord.CommentTrail__c);
                newRecord.Comments__c='';
            }
            /*
            if(newRecord.ApprovalStatus__c=='Approved' && oldRecord.GenerateClaimForm__c!=newRecord.GenerateClaimForm__c && newRecord.GenerateClaimForm__c==true){
                System.debug('inside');
                generateClaimForm(newRecord.id);
            }*/
            if(newRecord.ApprovalStatus__c=='In Progress' && newRecord.ApprovalStatus__c!=oldRecord.ApprovalStatus__c){commissionIds.add(newRecord.Id);
            }
        }
        if(!commissionIds.isEmpty()){checkandCreatePublicLink(commissionIds);
        }
    }
    /* moving the logic from Commission Line Item flow to Trigger, due to integration issues - Sanath H M 8th May 2023*/
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
     
      //  List<SalesOrder__c> salesOrderListToUpdate = new List<SalesOrder__c>(); 
        List<Id> invoiceIdList = new List<Id>();
        List<Id> invoiceListToUpdateSubmitForReview = new List<Id>();
        Set<Id> brokerAgencyIdSet = new Set<Id>();
        for(CommissionLineItem__c newRecord  : (list<CommissionLineItem__c >) newList){
          CommissionLineItem__c oldRecord = (CommissionLineItem__c) oldMap.get(newRecord.ID);
            system.debug('oldRecord.InvoiceBundle__c::'+oldRecord.InvoiceBundle__c);
            system.debug('newRecord.InvoiceBundle__c::'+newRecord.InvoiceBundle__c);
            if((oldRecord.InvoiceBundle__c != null && newRecord.InvoiceBundle__c == null) || (oldRecord.InvoiceBundle__c != null && newRecord.VATAmount__c != oldRecord.VATAmount__c)){
                invoiceIdList.add(oldRecord.InvoiceBundle__c);
                invoiceListToUpdateSubmitForReview.add(oldRecord.InvoiceBundle__c);
            }if( (newRecord.InvoiceBundle__c != null && oldRecord.InvoiceBundle__c == null) || (newRecord.InvoiceBundle__c != null && newRecord.VATAmount__c != oldRecord.VATAmount__c)){
                 invoiceIdList.add(newRecord.InvoiceBundle__c);
            }
            if((newRecord.SubmitforReview__c && !oldRecord.SubmitforReview__c) || (!newRecord.SubmitforReview__c && oldRecord.SubmitforReview__c)){
                invoiceListToUpdateSubmitForReview.add(newRecord.InvoiceBundle__c);
            }
            
            //Added by KP for VFS Sharing
            if(newRecord.BrokerAgency__c != null){
                brokerAgencyIdSet.add(newRecord.BrokerAgency__c);
            }
        }
        Map <Id, SalesOrder__c> salesOrderListToUpdate = new Map <Id, SalesOrder__c>(); 
        List<CommissionLineItem__c> commissionLineItems = [SELECT
                                                           Id,
                                                           SalesOrder__c,
                                                           SalesOrder__r.ERPID__c,
                                                           ERPID__c,
                                                           LastModifiedby.Profile.Name,
                                                           SalesOrder__r.IsSalesConsultantsChange__c
                                                           FROM 
                                                           CommissionLineItem__c 
                                                           WHERE SalesOrder__r.ERPID__c != null
                                                           AND LastModifiedby.Profile.Name != 'Integration Profile'
                                                           AND Id in: (List<CommissionLineItem__c>) newList 
                                                           AND CommissionType__c != 'Bonus Commission'];
        
       
       system.debug('commissionLineItems:::'+commissionLineItems); 
        if(!commissionLineItems.isEmpty()){
            Set<Id> soIds = new Set<Id>();
            for(CommissionLineItem__c commissionLineItem : commissionLineItems){
                CommissionLineItem__c oldCLI = (CommissionLineItem__c) oldMap.get(commissionLineItem.Id);
                if(commissionLineItem.ERPID__c == oldCLI.ERPID__c){
                    SalesOrder__c salesOrder = new SalesOrder__c();
                    soIds.add(commissionLineItem.SalesOrder__c);
                    salesOrder.Id = commissionLineItem.SalesOrder__c;
                    salesOrder.IsSalesConsultantsChange__c = true;
                    salesOrder.SyncStatus__c = 'In Progress';
                    salesOrderListToUpdate.put(salesOrder.Id, salesOrder);
                }
            }
            if(soIds.size() > 0 ){
                system.debug('++++Callout COMMISSION SYNC FROM TRIGGER');
         //       if(system.isFuture() || system.isBatch()){ WithoutSharingClass.updatesalesOrderSyncStatuses(salesOrderListToUpdate.values());}else{Database.executeBatch(new SalesOrderIntegrationBatch(soIds), 5);}
            }
        }
        system.debug(invoiceIdList);
        if(!invoiceIdList.isEmpty()){
            getCountOnInvoiceBunlde(invoiceIdList);
        }
        if(!invoiceListToUpdateSubmitForReview.isEmpty()){
            updateInvoiceBundle(invoiceListToUpdateSubmitForReview);
        }
        
        if(!brokerAgencyIdSet.isEmpty()){
            VFSSharingHelper.shareInvoicesAndCommisionsWithVFSTeam(brokerAgencyIdSet);
        }
    }
    public override void beforeDeleteMethod(List<SObject> oldList, Map<Id, SObject> oldMap){
     /*
        List<CommissionLineItem__c> commissionLineItemsToUpdateInv = new List<CommissionLineItem__c>();
        List<Id> invoiceIdList = new List<Id>();
        for(CommissionLineItem__c oldRecord  : (list<CommissionLineItem__c >) oldList){
            if(oldRecord.InvoiceBundle__c != null){
                invoiceIdList.add(oldRecord.InvoiceBundle__c);
            }
        }
        if(!invoiceIdList.isEmpty()){
            getCountOnInvoiceBunlde( invoiceIdList);
        } */
    }
    
    public override void afterDeleteMethod(List<SObject> oldList, Map<Id, SObject> oldMap) {
        List<Id> invoiceIdList = new List<Id>();
        for(CommissionLineItem__c oldRecord  : (list<CommissionLineItem__c >) oldList){
            if(oldRecord.InvoiceBundle__c != null){
                invoiceIdList.add(oldRecord.InvoiceBundle__c);
            }
        }
        if(!invoiceIdList.isEmpty()){
            getCountOnInvoiceBunlde( invoiceIdList);
        }
    }
    
    public static void checkandCreatePublicLink(set<ID> commissionIds){
        map<ID,ID> commissionTODOcumentId = new map<ID,ID>();
        set<id> docIDs = new set<ID>();
        for(Document__c docRec :[select id,CommissionLineItem__c from Document__c where CommissionLineItem__c in :commissionIds and DocumentType__c = :constants.DOCUMENT_PLACEHOLDER_CATEGORY_COMMISSION_INVOICE]){commissionTODOcumentId.put(docRec.CommissionLineItem__c,docRec.id);
            docIDs.add(docRec.id);
        }
        //Create Distribution
        
        map<ID,ContentDistribution> cdistribution = new map<ID,ContentDistribution>();
        try{
        for(ContentDocumentLink cdl :[select id, ContentDocumentId,ContentDocument.LatestPublishedVersionId,LinkedEntityId from ContentDocumentLink where LinkedEntityId in :docIDs order by SystemModstamp Desc ]){
            if(!cdistribution.containsKey(cdl.LinkedEntityId)){cdistribution.put(cdl.LinkedEntityId,ContentDocumentLinkTriggerHandler.createContentDistribution(cdl.ContentDocument.LatestPublishedVersionId,cdl.LinkedEntityId));
            }
        }}catch(Exception e){}
        //delete old links
        for(ContentDistribution cd :  [select id,RelatedRecordId from ContentDistribution where RelatedRecordId in :commissionTODOcumentId.values() ] ){
            if(cdistribution.containsKey(cd.RelatedRecordId)){ cdistribution.remove(cd.RelatedRecordId);
            }
        }
        if(!cdistribution.isEmpty()){insert cdistribution.values();}
        
    
    }
    /*@future(callout=true)
    public static void generateClaimForm(Id newRecordid){
        Map<id, CommissionLineItem__c> commissionMap = new Map<id, CommissionLineItem__c>([Select id, InvoiceNumber__c, SalesOrder__r.Name, InstalmentNumber__c, ApprovalStatus__c, GenerateClaimForm__c from CommissionLineItem__c where id =:newRecordid with SECURITY_ENFORCED]);
        CommissionLineItem__c commrecord = [Select id, InvoiceNumber__c, SalesOrder__r.Name, InstalmentNumber__c, ApprovalStatus__c, GenerateClaimForm__c from CommissionLineItem__c where id = :newRecordid with SECURITY_ENFORCED];
        map<id,ContentVersion > contentVersionMap = new map<id,ContentVersion >();
        map<id,id > commissionToDoc = new map<id,id >();
        list<Document__c> placeholderList = [select id,CommissionLineItem__c  from Document__c where CommissionLineItem__c =:commrecord.id and DocumentType__c = 'Commission Claim Form' WITH SECURITY_ENFORCED];
        if(placeholderList.isEmpty()){
            placeholderList.add(new Document__c(DocumentType__c = 'Commission Claim Form',
                                               CommissionLineItem__c = commrecord.Id,
                                               AvailableForExternalUsers__c=false,
                                               RecordtypeId= Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get('SalesOrderDocument').getRecordTypeId() ));
            insert placeholderList;
        }
        for(Document__c tempDoc : placeholderList){
            commissionToDoc.put(tempDoc.CommissionLineItem__c,tempDoc.id);
            PageReference pdf = Page.AgencyClaimForm;
            pdf.getParameters().put('id',tempDoc.CommissionLineItem__c);
            contentVersionMap.put(tempDoc.Id, new ContentVersion(Title= commissionMap.get(tempDoc.CommissionLineItem__c).SalesOrder__r.Name+'_'+commissionMap.get(tempDoc.CommissionLineItem__c).InstalmentNumber__c+'_AgencyClaimForm.pdf', 
                                                                 PathOnClient =commissionMap.get(tempDoc.CommissionLineItem__c).SalesOrder__r.Name+'_'+commissionMap.get(tempDoc.CommissionLineItem__c).InstalmentNumber__c+'_AgencyClaimForm.pdf',
                                                                 VersionData = Test.isRunningTest()? blob.valueOf('Methods defined as TestMethod do not support getContent call') :pdf.getContentAsPDF(), 
                                                                 origin = 'H'));
        }
        if(!contentVersionMap.isEmpty()){
            insert contentVersionMap.values();
            map<id,id> reverseMap = new map<id,id>();
            for(Id docId : contentVersionMap.keySet()){
                reverseMap.put(contentVersionMap.get(docId).id,docId);
            }
            list<ContentDocumentLink> documentLinksToCreate = new list<ContentDocumentLink>();
            for(ContentVersion tempCV : [select id, ContentDocumentId  from ContentVersion where id in :contentVersionMap.values()]){
                documentLinksToCreate.add(new ContentDocumentLink(contentdocumentid = tempCV.ContentDocumentId,
                                                                  LinkedEntityId = reverseMap.get(tempCV.Id),
                                                                  ShareType ='V'));
            }
            if(!documentLinksToCreate.isEmpty()){
                insert documentLinksToCreate;
            }
        }

        map<id,Document__c> docRecord = new map<id,Document__c>([select id,CommissionLineItem__c from Document__c where CommissionLineItem__r.id =:commrecord.id and DocumentType__c = 'Commission Claim Form']);
        list<ContentDistribution> cdistribution = new list<ContentDistribution>();
        for(ContentDocumentLink iterator : [SELECT ContentDocumentId,ContentDocument.LatestPublishedVersionId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId =:docRecord.keyset() order by SystemModstamp desc ]) {
            cdistribution.add(ContentDocumentLinkTriggerHandler.createContentDistribution(iterator.ContentDocument.LatestPublishedVersionId,iterator.LinkedEntityId));
        }
        if(!cdistribution.isEmpty()){
            insert cdistribution;
        }
    }*/
    
    public static void getCountOnInvoiceBunlde( List<Id> invoiceIdList){
        system.debug('invoiceIdList::'+invoiceIdList);
        system.debug('invoiceIdList::'+invoiceIdList.size());
        Map<String, Integer> invCliCountMap = new Map<String, Integer>();
        Map<String, Decimal> invCliCommissionAmtMap = new Map<String, Decimal>();
        Map<String, Decimal> invCliCommissionAmtWithVatMap = new Map<String, Decimal>();
        Map<String, Decimal> invVATAmMap = new Map<String, Decimal>();
        List<InvoiceBundle__c> invoiceBundleListToUpdate = new List<InvoiceBundle__c>();
        AggregateResult[] groupResults = [SELECT COUNT(Id) cliCount, SUM(CommissionAmount__c) commissionAmount, SUM(CommissionAmountWithVAT__c) commissionAmountWithVAT, SUM (VATAmount__c) vatAmount, InvoiceBundle__c inv FROM CommissionLineItem__c WHERE InvoiceBundle__c IN:invoiceIdList GROUP BY InvoiceBundle__c];
        System.debug('groupResults::'+groupResults);
        for(AggregateResult ar: groupResults){
            if(!invCliCountMap.containsKey(String.valueOf(ar.get('inv')))){
                invCliCountMap.put(String.valueOf(ar.get('inv')), Integer.valueOf(ar.get('cliCount')));
                invCliCommissionAmtMap.put(String.valueOf(ar.get('inv')),  (Decimal)(ar.get('commissionAmount')));
                invCliCommissionAmtWithVatMap.put(String.valueOf(ar.get('inv')), (Decimal)(ar.get('commissionAmountWithVAT')));
                invVATAmMap.put(String.valueOf(ar.get('inv')), (Decimal)(ar.get('vatAmount')));
            }
            
        }
        
        List<InvoiceBundle__c> invoiceBundleList = [SELECT
                                                    Id,
                                                    TotalCommissionLineItemCount__c
                                                    FROM InvoiceBundle__c
                                                    WHERE Id IN: invoiceIdList];
        
        for(InvoiceBundle__c inv: invoiceBundleList){
            InvoiceBundle__c invoiceBundle = new  InvoiceBundle__c();
            invoiceBundle.Id = inv.Id;
            invoiceBundle.TotalCommissionLineItemCount__c = invCliCountMap.containsKey(inv.Id) ? invCliCountMap.get(inv.Id) : 0;
            invoiceBundle.TotalCommissionAmount__c = invCliCommissionAmtMap.containsKey(inv.Id) ? invCliCommissionAmtMap.get(inv.Id) : 0;
            invoiceBundle.TotalCommissionAmountWithVAT__c = invCliCommissionAmtWithVatMap.containsKey(inv.Id) ? invCliCommissionAmtWithVatMap.get(inv.Id) : 0;
            invoiceBundle.TotalVATAmount__c = invVATAmMap.containsKey(inv.Id) ? invVATAmMap.get(inv.Id) : 0;
            invoiceBundleListToUpdate.add(invoiceBundle);
        }
        if(!invoiceBundleListToUpdate.isEmpty()){
            update invoiceBundleListToUpdate;
        }
    }
    
    public static void updateInvoiceBundle(List<Id> invoiceListToUpdateSubmitForReview){
        Map<Id, List<CommissionLineItem__c>> invoiceCLISubmitForReviewMap = new Map<Id, List<CommissionLineItem__c>>();
        Map<Id, List<CommissionLineItem__c>> invoiceCLINonSubmitForReviewMap = new Map<Id, List<CommissionLineItem__c>>();
        List<InvoiceBundle__c> invoiceBundleList = new List<InvoiceBundle__c>();
        List<CommissionLineItem__c> commissionLineItemList = [SELECT 
                                                              Id,
                                                              InvoiceBundle__c,
                                                              SubmitforReview__c
                                                              FROM CommissionLineItem__c
                                                              WHERE InvoiceBundle__c IN:invoiceListToUpdateSubmitForReview];
        
        
        for(CommissionLineItem__c cli: commissionLineItemList){
            if(cli.SubmitforReview__c){
                List<CommissionLineItem__c> cliList = invoiceCLISubmitForReviewMap.get(cli.InvoiceBundle__c) != null ? invoiceCLISubmitForReviewMap.get(cli.InvoiceBundle__c) : new List<CommissionLineItem__c>();
                cliList.add(cli);
                invoiceCLISubmitForReviewMap.put(cli.InvoiceBundle__c, cliList);
            }else if(!cli.SubmitforReview__c){
                List<CommissionLineItem__c> cliList = invoiceCLINonSubmitForReviewMap.get(cli.InvoiceBundle__c) != null ? invoiceCLINonSubmitForReviewMap.get(cli.InvoiceBundle__c) : new List<CommissionLineItem__c>();
                cliList.add(cli);
                invoiceCLINonSubmitForReviewMap.put(cli.InvoiceBundle__c, cliList);
                
            }
        }
        for(Id invoiceId: invoiceListToUpdateSubmitForReview){
            InvoiceBundle__c invoiceBundle = new InvoiceBundle__c();
            invoiceBundle.id = invoiceId;
            if(invoiceCLISubmitForReviewMap.containsKey(invoiceId) && invoiceCLISubmitForReviewMap.get(invoiceId).size()>0){
                invoiceBundle.SubmitforReview__c = true;
            }else if(invoiceCLINonSubmitForReviewMap.containsKey(invoiceId) && invoiceCLINonSubmitForReviewMap.get(invoiceId).size()>0 && !invoiceCLISubmitForReviewMap.containsKey(invoiceId)){
                invoiceBundle.SubmitforReview__c = false;
            }
            invoiceBundleList.add(invoiceBundle);
        }
        if(!invoiceBundleList.isEmpty()){
            update invoiceBundleList;
        }
    }
}