public with sharing class ALDAD_Validator {
    
    public static Boolean isAutoDialerAssigneeLead(Lead leadRecord) {
            System.debug('**** Inside ALDAD_Validator isAutoDialerAssigneeLead *****');
            System.debug('*** Lead Record ****'+leadRecord);
        List<ALDAD_Project_Config__mdt> projConfig=  [select Id,ProjectName__c, (select Id,Active__c,ALDAD_Project_Config__c,Field__c,Field_Value__c,Operator__c from ALDAD_Project_Skipping_Configs__r where Active__c=true) from ALDAD_Project_Config__mdt where ProjectName__c=:leadRecord.Project__c];
        if(projConfig==null || projConfig.IsEmpty() ){
           System.debug('****ALDAD_Validator isAutoDialerAssigneeLead ***** Eligibility Failed');
          return false;
        }
        System.debug('projConfig ****'+projConfig);
        List<ALDAD_Project_Skipping_Config__mdt>  projectSkippingConfigs= projConfig.get(0).ALDAD_Project_Skipping_Configs__r;
          
         System.debug('projectSkippingConfigs ****'+projectSkippingConfigs);
        if(projectSkippingConfigs!=null && !projectSkippingConfigs.IsEmpty()){
            for(ALDAD_Project_Skipping_Config__mdt skippingConfig:projectSkippingConfigs) {
              String leadFieldValue=String.valueOf(leadRecord.get(skippingConfig.Field__c));
               System.debug('Meta Field ****'+skippingConfig.Field__c + 'leadFieldValue ****'+leadFieldValue);
                if(skippingConfig.Field__c=='LanguagePreference__c' && leadFieldValue==null){
                    leadFieldValue='English';
                }
              if(leadFieldValue==null){
                 System.debug('****ALDAD_Validator isAutoDialerAssigneeLead ***** Eligibility Failed');
                return false;
              }
               //TODO
               String operatorValue= skippingConfig.Operator__c;
               List<String> fieldValueList=skippingConfig.Field_Value__c.split(',');
                if(!fieldValueList.contains(leadFieldValue)) {
                     System.debug('****ALDAD_Validator isAutoDialerAssigneeLead ***** Eligibility Failed');
                    return false;
                }     
              
            } 
        }  
         System.debug('****ALDAD_Validator isAutoDialerAssigneeLead ***** Eligibility Success');
        return true;
      }
    
    @InvocableMethod
    public static List<Boolean> autoDialerAssigneeLeadCheck(List<Id> leadIds) {
        Id leadId=leadIds.get(0);
        List<Boolean> result=new List<Boolean>();
        Lead  leadRecord=[select Id,Project__c,Genesis_Auto_Dialer_Status__c,OwnerId,LeadSource from Lead where Id=:leadId];
        Group leadAutoDialerQueue = Utilities.getQueueInformation(Constants.LEAD_AUTO_DIALER_QUEUE);
        // TODO Group leadAgentQueue = Utilities.getQueueInformation(Constants.LEAD_AGENT_QUEUE);  leadRecord.OwnerId==leadAgentQueue.Id
        if(leadRecord.Genesis_Auto_Dialer_Status__c=='Synced' && leadRecord.LeadSource!='Online'){
            result.add(false);
            return result;
        }
        
        List<ALDAD_Project_Config__mdt> projConfig=  [select Id,ProjectName__c, (select Id,Active__c,ALDAD_Project_Config__c,Field__c,Field_Value__c from ALDAD_Project_Skipping_Configs__r where Active__c=true) from ALDAD_Project_Config__mdt where ProjectName__c=:leadRecord.Project__c];
        if(projConfig==null || projConfig.IsEmpty() ){
            result.add(false);
            return result;
          }
        
        System.debug('projConfig ****'+projConfig);
        List<ALDAD_Project_Skipping_Config__mdt>  projectSkippingConfigs= projConfig.get(0).ALDAD_Project_Skipping_Configs__r; 
         System.debug('projectSkippingConfigs ****'+projectSkippingConfigs);
        Map<String,String> fieldValueMap=new Map<String,String>();
        if(projectSkippingConfigs!=null && !projectSkippingConfigs.IsEmpty()){
            for(ALDAD_Project_Skipping_Config__mdt skippingConfig:projectSkippingConfigs) {
               fieldValueMap.put(skippingConfig.Field__c, skippingConfig.Field_Value__c);
            } 
        } 
        
       if(!fieldValueMap.isEmpty()){
        String  queryFieldsStr=' select ID, '+String.join(new List<String>(fieldValueMap.keySet()), ', ') +' from Lead where Id =:leadId';
        System.debug('queryFieldsStr *****'+queryFieldsStr);
        List<Lead> matchedLead=Database.query(queryFieldsStr);
        for(String fieldKey:fieldValueMap.keySet()) {
              String leadFieldValue=String.valueOf(matchedLead.get(0).get(fieldKey));
               System.debug('leadFieldValue ****'+leadFieldValue);
              if(leadFieldValue==null){
                 result.add(false);
                 return result;
              }
              if(!leadFieldValue.equals(fieldValueMap.get(fieldKey))){
                   result.add(false);
                   return result;
              }
            } 
        }    
       
         Set<Id> leadTosendGenesis=new Set<Id>();
         leadTosendGenesis.add(leadId);
         GenesisAutoDialerBatch genesisBatchObj=new GenesisAutoDialerBatch(leadTosendGenesis);
         ID batchprocessid = Database.executeBatch(genesisBatchObj,1);
         leadRecord.OwnerId =leadAutoDialerQueue.Id;
         update leadRecord;
         result.add(true); 
         return result;
    }
    
}