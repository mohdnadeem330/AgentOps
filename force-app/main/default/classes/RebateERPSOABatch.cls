public class RebateERPSOABatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    public String query='';
    public Set<ID> recIds;
    public string srId;
    public String triggerpoint;
  
    Public RebateERPSOABatch (Set<ID> recIds, string srId){
        this.recIds=recIds;
        system.debug('recIds' + recIds);
        this.srId = srId;
        //this.query='select Id, name from SalesOrder__c where Id IN :recIds';
        this.query = 'Select id,Name, Status__c,UnitNumber__c, Unit__c from SalesOrder__c where Id IN :recIds';
    }
    Public RebateERPSOABatch (Set<ID> recIds, string srId, String triggerpoint){
        this.recIds=recIds;
        this.srId = srId;
        this.triggerpoint = triggerpoint;
        //this.query='select Id, name from SalesOrder__c where Id IN :recIds';
        this.query = 'Select id,Name, Status__c,UnitNumber__c, Unit__c from SalesOrder__c where Id IN :recIds';
    }
    
     
    public Database.QueryLocator start(Database.BatchableContext BC){ 
        return Database.getQueryLocator(this.query);
    }
    
    public void execute(Database.BatchableContext BC, List<SalesOrder__c> recordTypeList){
        system.debug('recordTypeList' + recordTypeList);

        for(SalesOrder__c so :recordTypeList)
        {
        String recId= so.id;

        EPRSOAController.SoaWrapperResp resps;
        try {
            resps = EPRSOAController.getERPSOA(recId);
            String DocMasterCode = this.triggerpoint == 'Revised SOA' ? 'Revised_ERP_SOA' : 'ERP_SOA';
            HexaBPM__SR_Doc__c assRec = [Select Id,HexaBPM__Service_Request__r.Unit__r.Name from HexaBPM__SR_Doc__c where HexaBPM__Service_Request__c=:srId AND DocumentMasterCode__c =: DocMasterCode];
            Blob bodyBlob=EncodingUtil.base64Decode(resps.soaPDFstr); 
                
            ContentVersion contentVersionRec = new ContentVersion(
                Title= 'ERPSOA-' + recordTypeList.get(0).UnitNumber__c, 
                PathOnClient ='ERPSOA-' + recordTypeList.get(0).UnitNumber__c+'.pdf',
                VersionData = bodyBlob, 
                origin = 'H'
            );
            insert contentVersionRec;
            
            ContentVersion contentVersionCreated = [SELECT Id, Title, ContentDocumentId 
                            FROM ContentVersion WHERE Id = :contentVersionRec.Id LIMIT 1];
            
            ContentDocumentLink contentlink = new ContentDocumentLink();
            contentlink.LinkedEntityId =assRec.Id;
            contentlink.contentdocumentid = contentVersionCreated.contentdocumentid;
            contentlink.ShareType = 'V';
            contentlink.Visibility='AllUsers';
            insert contentlink;
          
        } catch (Exception e) {
            insert LoggerService.addApexServiceCalls('SOA Sync Failure', 'RebateERPSOABatch', 'execute', srId, e.getMessage(), srId);
        }
    }
    }
    
    Public void finish(Database.BatchableContext BC){
     // database.executebatch(new HandoverBatch(new set<ID>(recIds),HandoverUtility.HANDOVERACTION_SEND_HP),1);  
    }
}