public without sharing class ALDAD_CalloutHelper {

    public static HTTPResponse doGenesisAutoDialerCall(List<Lead> leasdList,  Organization org) {
      ALDWA_API_Config__mdt genesisAppConfig = ALDWA_API_Config__mdt.getInstance(ALD_Constants.AD_WORKFLOWS); //DML_ACTION
      Map<String, Object> headerMapObj = (Map<String, Object>) JSON.deserializeUntyped(genesisAppConfig.Headers__c);
      String endPointURL = genesisAppConfig.Sandbox_Base_Url__c+genesisAppConfig.whatsAppWrkFlows__c;
      if(!org.IsSandbox) {
        endPointURL = genesisAppConfig.Production_Base_Url__c+genesisAppConfig.whatsAppWrkFlows__c;
      }
      
      Map<String, String> headerMap= new Map<String, String>();
      for(String strKey: HeaderMapObj.keyset())
      {
        headerMap.put(strKey, String.valueof(headerMapObj.get(strKey)));
      }

     String rquestBody= getGenesisAutoDialerRequest(leasdList,org);
     System.debug('Genesis Request Body***'+rquestBody);
     return Utilities.makeHHTTPCallout(genesisAppConfig.Request_Method__c, endPointURL, rquestBody, headerMap );  
    }
    
     
    public static String getGenesisAutoDialerRequest(List<Lead> leasdList,Organization org){
      Lead genesis0=leasdList.get(0);
      map<string,string> requestInnerMap = new map<string,string>();
      requestInnerMap.put('Flow.IsProd',!org.IsSandbox+'');
      requestInnerMap.put('Flow.UniqueColumn', getUniqueKey(genesis0.MobilePhone));
      requestInnerMap.put('Flow.Title',genesis0.Title!=null?genesis0.Title:''); 
      requestInnerMap.put('Flow.Name', genesis0.Name);
      requestInnerMap.put('Flow.Email',genesis0.Email);
      requestInnerMap.put('Flow.Phone','+'+genesis0.MobilePhone);
      requestInnerMap.put('Flow.LeadId',genesis0.Id);
      requestInnerMap.put('Flow.Project',genesis0.Project__c);
      requestInnerMap.put('Flow.UnitType',genesis0.UnitType__c!=null?genesis0.UnitType__c:''); 
      requestInnerMap.put('Flow.Bedroom',genesis0.NumberOfBedrooms__c!=null?genesis0.NumberOfBedrooms__c:'');  
      requestInnerMap.put('Flow.Purpose',genesis0.PurposeOfUse__c!=null ?genesis0.PurposeOfUse__c:'');
      requestInnerMap.put('Flow.Finance',genesis0.Financing__c!=null?genesis0.Financing__c:'');
      requestInnerMap.put('Flow.AttemptCount','0');
      requestInnerMap.put('Flow.Language',genesis0.LanguagePreference__c);
      requestInnerMap.put('Flow.Country',genesis0.Country!=null ? genesis0.Country:''); 
      requestInnerMap.put('Flow.CreateTask_IncorrectNum',Label.ALDAD_CreateTask_IncorrectNum);
      requestInnerMap.put('Flow.CreateTask_NotReachable', Label.ALDAD_CreateTask_NotReachable);
      requestInnerMap.put('Flow.CreateTask_Reached', 'Customer Reached');
      requestInnerMap.put('Flow.ChangeQueue_IncorrectNum',Label.ALDAD_ChangeQueue_IncorrectNum);
      requestInnerMap.put('Flow.ChangeQueue_3TimesNotReachable',Label.ALDAD_ChangeQueue_3TimesNotReachable);
      requestInnerMap.put('Flow.ChangeQueue_AgentQueue',Label.ALDAD_ChangeQueue_AgentQueue);
      requestInnerMap.put('Flow.AttributeName1','');
      requestInnerMap.put('Flow.AttributeValue1','');
      requestInnerMap.put('Flow.AttributeName2','');
      requestInnerMap.put('Flow.AttributeValue2','');
      requestInnerMap.put('Flow.AttributeName3','');
      requestInnerMap.put('Flow.AttributeValue3','');
      requestInnerMap.put('Flow.AttributeName4','');
      requestInnerMap.put('Flow.AttributeValue4','');
      requestInnerMap.put('Flow.AttributeValue5','');
      requestInnerMap.put('Flow.Timestamp_NoAnswer','');
      requestInnerMap.put('Flow.Timestamp_Busy','');
      requestInnerMap.put('Flow.Timestamp_Machine','');
      requestInnerMap.put('Flow.Timezone','');
      requestInnerMap.put('Flow.AttributeName5','');
      //"Flow.CreateTask_Reached": "Customer Reached", TODO Label Creation
      //requestInnerMap.put('Flow.Timezone',genesis0);
      map<string,object> requestMap = new map<string,object>();
      requestMap.put('flowId',Label.ALDAD_flowId);
      requestMap.put('inputData',requestInnerMap);
      return JSON.serialize(requestMap);

    }
    
    public static String getUniqueKey(String mobilePhone){
      String hashString =Datetime.now().formatGMT('dd/MM/YYYY')
          .replaceAll('(\\s+)', '').
          replace('.','').
          replace('-','').
          replace(':','')
         .replace('/','');
      //return hashString+'_'+mobilePhone.replaceAll('\\D','');
      return hashString+'_'+mobilePhone.trim();
    }
    
    /* TODO Needs to enable below code once Muleservice Ready
     public static HTTPResponse doGenesisAutoDialerSyncStatusCall(String syncId,  Organization org) {
      ALDWA_API_Config__mdt genesisAppConfig = ALDWA_API_Config__mdt.getInstance('whatsAppWrkFlowsGenesisSync'); //DML_ACTION
      Map<String, Object> headerMapObj = (Map<String, Object>) JSON.deserializeUntyped(genesisAppConfig.Headers__c);
      String endPointURL = genesisAppConfig.Sandbox_Base_Url__c+genesisAppConfig.whatsAppWrkFlows__c;
      if(!org.IsSandbox) {
        endPointURL = genesisAppConfig.Production_Base_Url__c+genesisAppConfig.whatsAppWrkFlows__c;
      }
      String finalEndPointURL =endPointURL+EncodingUtil.urlEncode(syncId,'utf-8');
      
      Map<String, String> headerMap= new Map<String, String>();
      for(String strKey: HeaderMapObj.keyset())
      {
        headerMap.put(strKey, String.valueof(headerMapObj.get(strKey)));
      }  
     return Utilities.makeHHTTPCallout(genesisAppConfig.Request_Method__c, endPointURL, null, headerMap );  
    }
  */


    

}