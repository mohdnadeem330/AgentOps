public without sharing class GenesisAutoDialerBatch implements Database.Batchable<sObject>,Database.AllowsCallouts {
    
    Organization org = Utilities.getOrganizationDetails();
    Set<Id> leadIds=new  Set<Id>();
    String queryStr='';

    public GenesisAutoDialerBatch(){
        this.queryStr='select Id,Title,Name,Email,Phone,MobilePhone,Project__c,UnitType__c,NumberOfBedrooms__c,PurposeOfUse__c,Financing__c,LanguagePreference__c,CountryOfResidence__c,Country from Lead where Genesis_Auto_Dialer_Status__c=\'Failed\'';
    }

    public GenesisAutoDialerBatch(String queryStr){
        this.queryStr=queryStr;
    }

    public GenesisAutoDialerBatch(Set<Id> leadIds){
        this.leadIds=leadIds;
        this.queryStr='select Id,Title,Name,Email,Phone,MobilePhone,Project__c,UnitType__c,NumberOfBedrooms__c,PurposeOfUse__c,Financing__c,LanguagePreference__c,CountryOfResidence__c,Country  from Lead where  Id IN :leadIds';
    }

   
    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('Batch started -> ');
        List<String> statusList=new List<String>();
        statusList.add(ALD_Constants.AUTO_DIALER_STATUS_INPROGRESS);
        System.debug('Batch started query -> '+this.queryStr);
        return Database.getQueryLocator(this.queryStr);
    }

    public void execute(Database.BatchableContext bc, List<Lead> leadList){
        try{
            System.debug('Entering GenesisAutoDialerBatch***'+leadList);
            HTTPResponse response=ALDAD_CalloutHelper.doGenesisAutoDialerCall(leadList, org);
            String respBody=response.getBody(); 
            //Genesis_Integration_ID__c
            System.debug('Genesis Success Response****'+respBody);
            if(response!=null && (response.getStatusCode() == 200 || response.getStatusCode() == 201)){
                System.debug('Genesis Call Success ****');
               map<string,object> responseMap = (map<String,object>) JSON.deserializeUntyped(response.getBody());
               System.debug('Genesis Call Success responseMap****'+responseMap);
               object resultObj =responseMap.get('results');
               Map<String, Object> resultMap = (Map<String, Object>)resultObj;
               String genesisId=String.valueOf(resultMap.get('id'));
               String correlationId =String.valueOf(responseMap.get('correlationId'));
               System.debug('Genesis Call Success correlationId ****'+genesisId);
               System.debug('Genesis Call Success genesisId****'+correlationId);
              // Group leadAutoDialerQueue = Utilities.getQueueInformation(Constants.LEAD_AUTO_DIALER_QUEUE);
               
                for(Lead syncedLead:leadList){  
                    syncedLead.Genesis_Integration_ID__c=genesisId;
                    syncedLead.Genesis_Auto_Dialer_Status__c=ALD_Constants.AUTO_DIALER_STATUS_SYNCED; 
                   // syncedLead.OwnerId =leadAutoDialerQueue.Id;
                    /* TODO Needs to enable once Mule service ready
                    if(false){
                        HTTPResponse syncStatusResponse=ALDAD_CalloutHelper.doGenesisAutoDialerSyncStatusCall(correlationId,org); 
                         map<string,object>  syncStatusResponseMap = (map<String,object>) JSON.deserializeUntyped(response.getBody());
                         object syncStatusResultObj =syncStatusResponseMap.get('outputData');
                         Map<String, Object> syncStatusResultMap = (Map<String, Object>)resultObj;
                         Boolean isContactInserted=Boolean.valueOf(syncStatusResultMap.get('contactInserted'));
                         if(isContactInserted){
                              syncedLead.Genesis_Auto_Dialer_Status__c=ALD_Constants.AUTO_DIALER_STATUS_SYNCED;  
                         }else{
                             syncedLead.Genesis_Auto_Dialer_Status__c=ALD_Constants.AUTO_DIALER_STATUS_FAILED;
                         }
                    }  
                  */
                    
                }
                System.debug('Updating Genesis Call Success Status****');
                update leadList;
        
            } else {
                System.debug('doGenesisAutoDialerCall Sync Failed *** '+response.getStatusCode());
                // Group leadAutoDialerQueue = Utilities.getQueueInformation(Constants.LEAD_AUTO_DIALER_QUEUE);
                for(Lead unSyncedLead:leadList){
                    unSyncedLead.Genesis_Auto_Dialer_Status__c=ALD_Constants.AUTO_DIALER_STATUS_FAILED;
                   // unSyncedLead.OwnerId =leadAutoDialerQueue.Id;
                }
                update leadList;
            }         
        }catch(Exception ex){
            System.debug('Exception While Calling doGenesisAutoDialerCall '+ex);
            LoggerService.Save( LoggerService.addApexLog(ex,'doGenesisAutoDialerCall','doGenesisAutoDialerCall','GenesisAutoDialerBatch') );
        }
    

    }

    public void finish(Database.BatchableContext bc){
        System.debug('Batch finish -> ');
    }
}