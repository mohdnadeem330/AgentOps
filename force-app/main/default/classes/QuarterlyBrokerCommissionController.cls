public with sharing class QuarterlyBrokerCommissionController {
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
    public static list<QuarterlyBonusCommission__c> getAllComissions(){
        String brokerAgencyId;
        String draftStatus = 'Draft';
        List<User> currentuser = [SELECT Name, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
        if(!currentuser.isEmpty() && currentuser[0].AccountId != null) {
            brokerAgencyId = currentuser[0].AccountId;
            
            system.debug('brokerAgencyId -- '+brokerAgencyId);
            String subQuery = '(select id,CustomerName__c,InvoiceNumber__c,SalesOrder__c,BrokerAgency__c,BrokerAgency__r.Name,BrokerAgent__c,BrokerAgent__r.Name ,SalesOrder__r.SubStatus__c,SalesOrder__r.Status__c, SalesOrder__r.ProjectName__c,SalesOrder__r.Unit__c ,SalesOrder__r.Unit__r.Name, SalesOrder__r.Unit__r.TotalRooms__c,SalesOrder__r.NetAmount__c, OrderDate__c, CommissionAmount__c,CommissionPercentage__c, CommissionType__c, InstallmentLine__c,Status__c,InvoiceDate__c,PaymentDueDate__c,ClearedDate__c,InstalmentNumber__c,SalesOrder__r.Opportunity__c,SalesOrder__r.Opportunity__r.Contact__c,SalesOrder__r.Opportunity__r.Contact__r.Name,SalesOrder__r.Opportunity__r.AccountId,SalesOrder__r.Opportunity__r.Account.Name,CommissionAmountWithVAT__c,  InstallmentLine__r.OutstandingAmount__c,InstallmentLine__r.InstallmentAmount__c,InstallmentLine__r.InvoicedAmount__c from Commission_Line_Items__r)';
            string finalSOQL = 'select Id, Name, CurrencyIsoCode, Quarter__c, Year__c, Status__c,'+ subQuery+', Approval_Status__c, BrokerAgency__c, BrokerAgency__r.Name from QuarterlyBonusCommission__c where BrokerAgency__c=:brokerAgencyId AND Status__c !=: draftStatus';
            return database.Query(finalSOQL);
        }
        String subQuery = '(select id,CustomerName__c,InvoiceNumber__c,SalesOrder__c,BrokerAgency__c,BrokerAgency__r.Name,BrokerAgent__c,BrokerAgent__r.Name ,SalesOrder__r.SubStatus__c,SalesOrder__r.Status__c, SalesOrder__r.ProjectName__c,SalesOrder__r.Unit__c ,SalesOrder__r.Unit__r.Name, SalesOrder__r.Unit__r.TotalRooms__c,SalesOrder__r.NetAmount__c, OrderDate__c, CommissionAmount__c,CommissionPercentage__c, CommissionType__c, InstallmentLine__c,Status__c,InvoiceDate__c,PaymentDueDate__c,ClearedDate__c,InstalmentNumber__c,SalesOrder__r.Opportunity__c,SalesOrder__r.Opportunity__r.Contact__c,SalesOrder__r.Opportunity__r.Contact__r.Name,SalesOrder__r.Opportunity__r.AccountId,SalesOrder__r.Opportunity__r.Account.Name,CommissionAmountWithVAT__c,  InstallmentLine__r.OutstandingAmount__c,InstallmentLine__r.InstallmentAmount__c,InstallmentLine__r.InvoicedAmount__c from Commission_Line_Items__r)';
        string finalSOQL = 'select Id, Name, CurrencyIsoCode, Quarter__c, Year__c, Status__c,'+ subQuery+', Approval_Status__c, BrokerAgency__c, BrokerAgency__r.Name from QuarterlyBonusCommission__c WHERE Status__c !=: draftStatus';
        return database.Query(finalSOQL);
    }

    @AuraEnabled
    public static String getCommissionTrail(String recordId){
        list<QuarterlyBonusCommission__c> records = [select CommentTrail__c from QuarterlyBonusCommission__c where id = :recordId];
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
    public static void updateStatus(Id recordId, String statusValue ,string comment ){
        system.debug('recordId '+recordId);
        system.debug('statusValue '+statusValue);
        system.debug('comment '+comment);
        QuarterlyBonusCommission__c bonus = new QuarterlyBonusCommission__c(id=recordId,status__c=statusValue,Comments__c= comment);
        //CommissionLineItem__c commissionRecord = new CommissionLineItem__c(id=recordId,status__c=statusValue,AgencyAdmin__c=userInfo.getUserId() ,OwnerID= userInfo.getUserId(),Comments__c= comment );
        if(!Schema.sObjectType.QuarterlyBonusCommission__c.isUpdateable() ){ throw new CustomException(Constants.SOQL_DML_OBJECT_ACCESS_MESSAGE); }
        update bonus;
        system.Debug('updated bonus '+bonus);
        /*if(statusValue == Constants.COMMISSION_LINE_STATUS_ACCEPTED){
            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments(comment);
            req1.setObjectId(recordId);
            
            // Submit on behalf of a specific submitter
            req1.setSubmitterId(userInfo.getUserId()); 
            
            // Submit the record to specific process and skip the criteria evaluation
            req1.setProcessDefinitionNameOrId('QuarterlyBonusCommissionApproval');
            
            // Submit the approval request for the account
            Approval.ProcessResult result = Approval.process(req1);
        }*/
        if( statusValue == Constants.STATUS_REJECTED || statusValue == Constants.COMMISSION_LINE_STATUS_ACCEPTED){
            map<id,QuarterlyBonusCommission__c> documentmap = new map<id,QuarterlyBonusCommission__c>();
            documentmap.put(bonus.Id,bonus);
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
    public static void generateInvoiceDocumentFromVF(map<ID,QuarterlyBonusCommission__c> commissionLinesToProcess){
        commissionLinesToProcess = new map<id,QuarterlyBonusCommission__c>([select id, BrokerAgency__r.Name, Quarter__c, Year__c from QuarterlyBonusCommission__c where id in :commissionLinesToProcess.keySet()]); 
        map<id,ContentVersion > contentVersionMap = new map<id,ContentVersion >();
        map<id,id > commissionToDoc = new map<id,id >();
        Network network =  [SELECT Name, UrlPathPrefix, Id FROM Network WHERE Name = :Constants.URL_PREFIX];
        list<Document__c> placeholderList = [select id,QuarterlyBonusCommission__c  from Document__c where QuarterlyBonusCommission__c in :commissionLinesToProcess.keySet()];
        if(placeholderList.isEmpty()){
            for(QuarterlyBonusCommission__c cr: commissionLinesToProcess.values()){
                placeholderList.add(new Document__c(DocumentType__c = 'Bonus Commission',
                                            QuarterlyBonusCommission__c = cr.Id,
                                            AvailableForExternalUsers__c=true,
                                            RecordtypeId= Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get('SalesOrderDocument').getRecordTypeId() ));
            }
           
            insert placeholderList;
        }
        for(Document__c tempDoc : placeholderList){
            commissionToDoc.put(tempDoc.QuarterlyBonusCommission__c,tempDoc.id);
            PageReference pdf = Page.QuarterlyInvoicePDF;
            pdf.getParameters().put('invoiceId',tempDoc.QuarterlyBonusCommission__c);
            contentVersionMap.put(tempDoc.Id, new ContentVersion(Title= commissionLinesToProcess.get(tempDoc.QuarterlyBonusCommission__c).BrokerAgency__r.Name+'_'+commissionLinesToProcess.get(tempDoc.QuarterlyBonusCommission__c).Quarter__c+'_'+commissionLinesToProcess.get(tempDoc.QuarterlyBonusCommission__c).Year__c+'.pdf', 
                                                                        PathOnClient =commissionLinesToProcess.get(tempDoc.QuarterlyBonusCommission__c).BrokerAgency__r.Name+'_'+commissionLinesToProcess.get(tempDoc.QuarterlyBonusCommission__c).Quarter__c+'_'+commissionLinesToProcess.get(tempDoc.QuarterlyBonusCommission__c).Year__c+'.pdf',
                                                                        VersionData = Test.isRunningTest()? blob.valueOf('Methods defined as TestMethod do not support getContent call') :pdf.getContentAsPDF(), 
                                                                        origin = 'H',
                                                                		NetworkId = network.Id));
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
@AuraEnabled
    public static string generateInvoiceDocument(String recordId){
        Map<id,QuarterlyBonusCommission__c> documentmap = new Map<id,QuarterlyBonusCommission__c>();
        
        List<QuarterlyBonusCommission__c> qbcList = [select id, BrokerAgency__r.Name, Quarter__c, Year__c from QuarterlyBonusCommission__c where id =: recordId];
        
        for(QuarterlyBonusCommission__c qbc: qbcList){
            documentmap.put(qbc.Id,qbc);
        }
        if(documentmap.keySet().size()>0){
            generateInvoiceDocumentFromVF(documentmap);
        }
        return Constants.SUCCESS_MESSAGE;
    }
}