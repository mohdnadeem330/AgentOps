public class ContentDocCLIBatch implements Database.Batchable<sObject>,Database.AllowsCallouts{
     
    public String queryStr;
    Set<Id> Ids=new  Set<Id>();
    
    
      public ContentDocCLIBatch(Set<Id> Ids){
        this.Ids=Ids;
        this.queryStr='SELECT id,Name,InvoiceNumber__c,SalesOrder__r.Name,InstalmentNumber__c  from CommissionLineItem__c where Id IN :Ids';
    }
    
    public ContentDocCLIBatch( String queryStr){
        this.queryStr=queryStr;
    }
    
     public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.queryStr);
    }

    public void execute(Database.BatchableContext bc, List<CommissionLineItem__c>  commissionLinesList){
        map<ID,CommissionLineItem__c> commissionLinesToProcess=new map<id,CommissionLineItem__c>();
        for(CommissionLineItem__c item:commissionLinesList){
          commissionLinesToProcess.put(item.Id,item) ;
        }
                                                                                                                                                                                                            
        map<id,ContentVersion > contentVersionMap = new map<id,ContentVersion >();
        map<id,id > commissionToDoc = new map<id,id >();
        
        List<Document__c> placeholderList = new List<Document__c>();
        List<document__c> doclist = new List<Document__c>();
        doclist = [Select id, CommissionLineItem__c from document__c where commissionlineitem__c in :commissionLinesToProcess.keyset()];
        placeholderList.addall(doclist);
        
        //Tharun Added
        Map<Id, String> publicURLMap = new Map<Id, String>();
        List<ContentDistribution> allCdIds = new List<ContentDistribution>();
        Set<Id> allSetCDInserted = new Set<Id>();
        
        for(Document__c tempDoc : placeholderList)
        {
            //Tharun Commented
            //commissionToDoc.put(tempDoc.CommissionLineItem__c,tempDoc.id);
            commissionToDoc.put(tempDoc.id, tempDoc.CommissionLineItem__c);
            PageReference pdf = Page.BrokerInvoicePDF;
            pdf.getParameters().put('invoiceId',tempDoc.CommissionLineItem__c);
            contentVersionMap.put(tempDoc.Id, new ContentVersion(Title= commissionLinesToProcess.get(tempDoc.CommissionLineItem__c).SalesOrder__r.Name+'_'+commissionLinesToProcess.get(tempDoc.CommissionLineItem__c).InstalmentNumber__c+'_'+commissionLinesToProcess.get(tempDoc.CommissionLineItem__c).InvoiceNumber__c+'.pdf',PathOnClient =commissionLinesToProcess.get(tempDoc.CommissionLineItem__c).SalesOrder__r.Name+'_'+commissionLinesToProcess.get(tempDoc.CommissionLineItem__c).InvoiceNumber__c+'.pdf',VersionData = Test.isRunningTest()? blob.valueOf('Methods defined as TestMethod do not support getContent call') :pdf.getContentAsPDF(),origin = 'H'));
        }
        
        
        if(!contentVersionMap.isEmpty()){
            insert contentVersionMap.values();
            list<ContentDistribution> cdistribution = new list<ContentDistribution>();
            for(Id ccR : contentVersionMap.keySet()){
                cdistribution.add(ContentDocumentLinkTriggerHandler.createContentDistribution(contentVersionMap.get(ccR).Id,ccR));
            }
            insert cdistribution;
            
            for(ContentDistribution cds: cdistribution){
                allSetCDInserted.add(cds.Id);
            }
            
            
            map<id,id> reverseMap = new map<id,id>();
            for(Id docId : contentVersionMap.keySet()){
                reverseMap.put(contentVersionMap.get(docId).id,docId);
            }
            list<ContentDocumentLink> documentLinksToCreate = new list<ContentDocumentLink>();
            
            list<ContentVersion> cvsNewIds = [SELECT Id,ContentDocumentId    FROM ContentVersion WHERE Id IN : contentVersionMap.values()];
            for(ContentVersion tempCV : cvsNewIds){
                documentLinksToCreate.add(new ContentDocumentLink(contentdocumentid = tempCV.ContentDocumentId,LinkedEntityId = reverseMap.get(tempCV.Id),ShareType ='V'));
            }
            if(!documentLinksToCreate.isEmpty()){
                Insert documentLinksToCreate;
            }
        }
        
        
        list<ContentDistribution> cdsCreatedOnes = [SELECT Id, RelatedRecordId,DistributionPublicUrl FROM  ContentDistribution WHERE ID IN : allSetCDInserted];
        for (ContentDistribution cdSingle: cdsCreatedOnes){
            publicURLMap.put(commissionToDoc.get(cdSingle.RelatedRecordId), cdSingle.DistributionPublicUrl);
            Logger__c newLog 				= new Logger__c();
            newLog.LogType__c 				= 'CLI-INFO';
            newLog.Message__c 				= 'CLI-INFO' ;
            newLog.ExecutingProcessName__c 	= 'CLI-INFO' ;
            newLog.StackTrace__c 			= commissionToDoc.get(cdSingle.RelatedRecordId)+'='+cdSingle.DistributionPublicUrl;
            LoggerService.save(newLog);
        }
        
        for(id t1: publicURLMap.keyset()){
            System.Debug('publicURLMapCommANDpublicURL----->id:'+t1+'--'+publicURLMap.get(t1));
        }
       

    }
    
    

    public void finish(Database.BatchableContext bc){
       
    }
}