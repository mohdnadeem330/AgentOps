/**********************************************************************************************************************
* Name               : CommissionsReportController                                                        
* Description        : Class to fetch and subkit the commission records for brokers
* Usage              : Commission Report LWC (Used in Portal)                                                     
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     06/06/2022      Initial Draft       
******************************************************************************************************************/
public with sharing class CommissionsReportController{
    /**
    * getAllComissions
    *
    * This method used to retrive all the commission records relevent to the account
    * With sharing will control record access
    *
    * @param  none
    * @return list of CommissionLineItem__c records
    */
    @AuraEnabled
    public static list<CommissionLineItem__c> getAllComissions(Date startDate, Date endDate){
        String dateFilter='';
        String NotReadyStatus = 'Not Ready';
        String ReadyForSubmissionStatus = 'Ready for Submission';
        String FixedStatus = 'Fixed';
        String StatusFilter = '';
        if(startDate!=null){
            dateFilter= ' and ( (OriginalCreationDate__c != null and OriginalCreationDate__c >= :startDate) or (OriginalCreationDate__c = null and createdDate >= :startDate) or ( OrderDate__c >= :startDate) )';
            //dateFilter= ' and createdDate >= :startDate';
        }
        if(endDate!=null){
            endDate = endDate.addDays(1);
            dateFilter+= ' and ( (OriginalCreationDate__c != null and OriginalCreationDate__c <= :endDate ) or (OriginalCreationDate__c = null and createdDate <= :endDate) or  (OrderDate__c <= :endDate) )';
            //dateFilter+= ' and createdDate <= :endDate';
        }
        StatusFilter = ' And Status__c != '+'\'' + ReadyForSubmissionStatus+'\''  + 'And Status__c != '+'\'' + FixedStatus+'\'';
        string finalSOQL = 'select id,TotalExternalCommissionPercentage__c,CustomerName__c,InvoiceNumber__c,SalesOrder__c,BrokerAgency__c,BrokerAgency__r.Name,BrokerAgent__c,BrokerAgent__r.Name ,SalesOrder__r.SubStatus__c,SalesOrder__r.Status__c, SalesOrder__r.ProjectName__c,SalesOrder__r.Unit__c ,SalesOrder__r.Unit__r.Name, SalesOrder__r.Unit__r.TotalRooms__c,SalesOrder__r.NetAmount__c, OrderDate__c, CommissionAmount__c,CommissionPercentage__c, CommissionType__c, InstallmentLine__c,Status__c,InvoiceDate__c,PaymentDueDate__c,ClearedDate__c,InstalmentNumber__c,SalesOrder__r.Opportunity__c,SalesOrder__r.Opportunity__r.Contact__c,SalesOrder__r.Opportunity__r.Contact__r.Name,SalesOrder__r.Opportunity__r.AccountId,SalesOrder__r.Opportunity__r.Account.Name,CommissionAmountWithVAT__c,  InstallmentLine__r.OutstandingAmount__c,InstallmentLine__r.InstallmentAmount__c,InstallmentLine__r.InvoicedAmount__c from CommissionLineItem__c where InvoiceBundle__c = null' + StatusFilter +' AND CommissionType__c = \''+ Constants.COMMISSION_LINE_EXTERNAL_COMMISSION + '\' ' + dateFilter +'  WITH SECURITY_ENFORCED  order by OriginalCreationDate__c desc, createdDate desc';
        system.debug('final data::'+database.Query(finalSOQL));
        return database.Query(finalSOQL);
        //return [select id,InvoiceNumber__c,SalesOrder__c,BrokerAgency__c,BrokerAgency__r.Name,BrokerAgent__c,BrokerAgent__r.Name ,SalesOrder__r.SubStatus__c, SalesOrder__r.ProjectName__c,SalesOrder__r.Unit__c ,SalesOrder__r.Unit__r.Name, SalesOrder__r.Unit__r.TotalRooms__c,SalesOrder__r.NetAmount__c, OrderDate__c, CommissionAmount__c,CommissionPercentage__c, CommissionType__c, InstallmentLine__c,Status__c,InvoiceDate__c,PaymentDueDate__c,ClearedDate__c,InstalmentNumber__c,SalesOrder__r.Opportunity__c,SalesOrder__r.Opportunity__r.Contact__c,SalesOrder__r.Opportunity__r.Contact__r.Name,CommissionAmountWithVAT__c,  InstallmentLine__r.OutstandingAmount__c,InstallmentLine__r.InstallmentAmount__c,InstallmentLine__r.InvoicedAmount__c from CommissionLineItem__c where CommissionType__c = :Constants.COMMISSION_LINE_EXTERNAL_COMMISSION WITH SECURITY_ENFORCED order by createdDate desc,OriginalCreationDate__c desc];
    }
    @AuraEnabled
    public static String getCommissionTrail(String recordId){
        list<CommissionLineItem__c> records = [select CommentTrail__c from CommissionLineItem__c where id = :recordId];
        return records.isEmpty()?'':records[0].CommentTrail__c;
    }
    /**
    * updateStatus
    *
    * This method used accept or reject the commission record
    *
    * @param  recordId CommissionLineItem__c record ID
    * @param  statusValue Accepted/rejected status values
    * @param  comment Additinal comments
    * @return none
    */
    @AuraEnabled
    public static void updateStatus (Id recordId, String statusValue ,string comment ){
        CommissionLineItem__c commissionRecord = new CommissionLineItem__c(id=recordId,status__c=statusValue,AgencyAdmin__c=userInfo.getUserId() ,OwnerID= userInfo.getUserId(),Comments__c= comment );
        if(!Schema.sObjectType.CommissionLineItem__c.isUpdateable() ){ throw new CustomException(Constants.SOQL_DML_OBJECT_ACCESS_MESSAGE); }
        update commissionRecord;
        if( statusValue == Constants.STATUS_REJECTED || statusValue == Constants.COMMISSION_LINE_STATUS_ACCEPTED){
            map<id,CommissionLineItem__c> documentmap = new map<id,CommissionLineItem__c>();
            documentmap.put(commissionRecord.Id,commissionRecord);
            generateInvoiceDocumentFromVF(documentmap);
        }
    }
    
   
    /**
    * generateInvoiceDocumentFromVF
    *
    * On acceptance generate the Invoice attachment and store it under placeholder
    *
    * @param  commissionLinesToProcess CommissionLineItem__c record to be processed
    * @return none
    */
    public static void generateInvoiceDocumentFromVF(map<ID,CommissionLineItem__c> commissionLinesToProcess){
        commissionLinesToProcess = new map<id,CommissionLineItem__c>([select id,InvoiceNumber__c,SalesOrder__r.Name,InstalmentNumber__c from CommissionLineItem__c where id in :commissionLinesToProcess.keySet() WITH SECURITY_ENFORCED]); 
        map<id,ContentVersion > contentVersionMap = new map<id,ContentVersion >();
        map<id,id > commissionToDoc = new map<id,id >();
        list<Document__c> placeholderList = [select id,CommissionLineItem__c  from Document__c where CommissionLineItem__c in :commissionLinesToProcess.keySet() WITH SECURITY_ENFORCED];
        if(placeholderList.isEmpty()){
            for(CommissionLineItem__c cr: commissionLinesToProcess.values()){
                placeholderList.add(new Document__c(DocumentType__c = 'Commission Invoice',
                                            CommissionLineItem__c = cr.Id,
                                            AvailableForExternalUsers__c=true,
                                            RecordtypeId= Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get('SalesOrderDocument').getRecordTypeId() ));
            }
           
            insert placeholderList;
        }
        for(Document__c tempDoc : placeholderList){
            commissionToDoc.put(tempDoc.CommissionLineItem__c,tempDoc.id);
            PageReference pdf = Page.BrokerInvoicePDF;
            pdf.getParameters().put('invoiceId',tempDoc.CommissionLineItem__c);
            contentVersionMap.put(tempDoc.Id, new ContentVersion(Title= commissionLinesToProcess.get(tempDoc.CommissionLineItem__c).SalesOrder__r.Name+'_'+commissionLinesToProcess.get(tempDoc.CommissionLineItem__c).InstalmentNumber__c+'_'+commissionLinesToProcess.get(tempDoc.CommissionLineItem__c).InvoiceNumber__c+'.pdf', 
                                                                        PathOnClient =commissionLinesToProcess.get(tempDoc.CommissionLineItem__c).SalesOrder__r.Name+'_'+commissionLinesToProcess.get(tempDoc.CommissionLineItem__c).InvoiceNumber__c+'.pdf',
                                                                        VersionData = Test.isRunningTest()? blob.valueOf('Methods defined as TestMethod do not support getContent call') :pdf.getContentAsPDF(), 
                                                                        origin = 'H'));
        }
        if(!contentVersionMap.isEmpty()){
            insert contentVersionMap.values();
            list<ContentDistribution> cdistribution = new list<ContentDistribution>();
            for(Id ccR : contentVersionMap.keySet()){
                cdistribution.add(ContentDocumentLinkTriggerHandler.createContentDistribution(contentVersionMap.get(ccR).Id,ccR));
            }
            insert cdistribution;

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
    }  
}