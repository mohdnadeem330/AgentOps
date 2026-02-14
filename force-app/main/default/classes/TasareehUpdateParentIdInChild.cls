/***************************************************
*Date: 11 June 2024 
*Author: NB
*Description: Batch Class to update child records with parent(parcel or permit)
***************************************************/
global class TasareehUpdateParentIdInChild implements Database.Batchable<SObject> {
    private Set<Id> parentIds;
    private String parentObj;
    private Set<String> childObj;
    
    Public TasareehUpdateParentIdInChild(Set<Id> parentIds,String parentObj,set<String> childObj){
        
        this.parentIds=parentIds;
        this.parentObj=parentObj;
        this.childObj=childObj;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query;
        if(parentObj=='Permit__c'){
            query='select id,RecordId__c from '+ parentObj+' where id IN:parentIds';
        }
        if(parentObj=='Parcel__c'){
            query='select id,GsId__c from '+ parentObj+' where id IN:parentIds';
        }
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        //system.debug('parentIds '+parentIds);
        //system.debug('Size '+parentIds.size());
        Map<String,Id> recMap = new Map<String,Id>();
        Set<string> recidname = new Set<string>();
        for (SObject s : scope) {
            
            String objectApiName = s.getSObjectType().getDescribe().getName();
            
            If(parentObj== 'Permit__c'){
              recMap.put((String)s.get('RecordId__c'),s.Id);
              recidname.add((String)s.get('RecordId__c'));
            }
            else if(parentObj== 'Parcel__c'){
              recMap.put((String)s.get('GsId__c'),s.Id);
              recidname.add((String)s.get('GsId__c'));   
            }
            
        }
        List<sObject> lstSobToUpdate = new List<sObject>();
        
        /*Permit as parent*/
        if(parentObj== 'Permit__c'){
        for(String apiname : childObj){
            String query='SELECT id,ParentId__c,permit__c FROM '+ apiname+' WHERE ParentId__c IN :recidname and permit__c=null';
            //System.debug('query: '+query);
            List<sObject> records = Database.query(query);
            
            
            for (sObject obj:records){
                obj.put('Permit__c',recMap.get((String)obj.get('ParentId__c')));
            }
            lstSobToUpdate.addall(records);
        }
        }
        /*Parcel as Parent*/
        else if(parentObj== 'Parcel__c'){
            String query='SELECT id,ParentId__c,Parcel_Plot__c FROM Permit__c WHERE ParentId__c IN :recidname and Parcel_Plot__c=null';
            //System.debug('query: '+query);
            List<sObject> records = Database.query(query);
            
            
            for (sObject obj:records){
                obj.put('Parcel_Plot__c',recMap.get((String)obj.get('ParentId__c')));
            }
            lstSobToUpdate.addall(records);
        }

        try{
            UPDATE lstSobToUpdate;
        }Catch(DMLException ex){
            LoggerService.save(LoggerService.createApexLog(ex,'TasareehUpdateParentIdInChild','TasareehUpdateParentIdInChild','batchClass'));
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        //send email maintain in custom labels
    }
    
    /* Testing: 
       	List<Id> parentIds= new List<Id>{'a4sKH000000Ld1DYAS', 'a4sKH000000LdYdYAK'};
        String parentObj='Permit__c';
        set<String>childObj=new set<String>{'Professional__c','WorkflowTask__c'};   
        TasareehUpdateParentIdInChild batch= new TasareehUpdateParentIdInChild(parentIds,parentObj,childObj);
        Database.executeBatch(batch, 200);
		*/
    
}