Public class ERPSOABatch implements Database.Batchable<sObject>,Database.AllowsCallouts {
    /*
    Set<ID> ids=new Set<ID>();
    ids.add('a0Q25000005TMQMEA4');
    ids.add('a0Q25000005TMQREA4');
    ids.add('a0Q25000005TPnNEAW');
    ids.add('a0Q25000005AuLjEAK');
    database.executebatch(new ERPSOABatch(ids),1);  
   */
    public String query='';
    public Set<ID> recIds;
  
    Public ERPSOABatch (Set<ID> recIds){
        this.recIds=recIds;
        this.query='select Id,SalesOrder__c from HexaBPM__Service_Request__c  where Id IN :recIds';
    }
    
     
    Public Database.QueryLocator start(Database.BatchableContext BC){ 
        return Database.getQueryLocator(this.query);
    }
    
    Public void execute(Database.BatchableContext BC, List<HexaBPM__Service_Request__c> recordTypeList){
        String recId=recordTypeList.get(0).SalesOrder__c;
            EPRSOAController.SoaWrapperResp resps=EPRSOAController.getERPSOA(recId);
 
        HexaBPM__SR_Doc__c assRec=[Select Id,HexaBPM__Service_Request__r.Unit__r.Name from HexaBPM__SR_Doc__c where HexaBPM__Service_Request__c=:recordTypeList.get(0).Id AND DocumentMasterCode__c='ERP_SOA'];
        Blob bodyBlob=EncodingUtil.base64Decode(resps.soaPDFstr); 
            
            ContentVersion contentVersionRec = new ContentVersion(
                Title=assRec.HexaBPM__Service_Request__r.Unit__r.Name, 
                PathOnClient =assRec.HexaBPM__Service_Request__r.Unit__r.Name+'.pdf',
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
      
    }
    
    Public void finish(Database.BatchableContext BC){
     // database.executebatch(new HandoverBatch(new set<ID>(recIds),HandoverUtility.HANDOVERACTION_SEND_HP),1);  
    }
}