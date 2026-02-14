/**********************************************************************************************************************
* Name               : KioskFormController                                                        
* Description        : This class is used as controller for all kiosk form lightning components
* Usage              :                                                           
* Created By         : Muzammil                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           Muzammil     		10 Feb 2022      Initial Draft       
******************************************************************************************************************/

public with sharing class KioskFormController {
    
    final public static String  agentLocaiton = Label.KioskAgentLocation;
    final public static String  salesAgent = Label.KioskSalesAgent;
    
    public static Map<String,List<PicklistValuesOptions>> salesAgentByLocaitonId = new Map<String,List<PicklistValuesOptions>>();
		public static Map<Id,AllocationGroup__c> agentLocationMap = new Map<Id,AllocationGroup__c>();
        //'Aldar Sales Agent';
    public static Map<String,Map<String,List<DisplayFieldDataWrapper>>> dependentFieldsMap  = new Map<String,Map<String,List<DisplayFieldDataWrapper>>>();
    public static Map<String,Map<String,Map<String,List<PicklistValuesOptions>>>> dependentPicklistValuesMap  = new  Map<String,Map<String,Map<String,List<PicklistValuesOptions>>>>();// controllingfield->controllingfieldvalue->dependentfield->List<dependentfieldvalue>
    
    /**
* @Method Name: validateEmailAddress 
* @Description : Method called from lightnig component to validate email address(Callout)
* @param emailValue
* @return   Boolean
*/ 
    @AuraEnabled(cacheable=true)
    public static Boolean validateEmailAddress(String emailValue){
        //        Boolean isValidPhone = false;
        List<boolean> isValidList = EmailValidation.validateEmail( new List<String>{emailValue});
        system.debug('isValidList[0] '+isValidList[0]);
        return isValidList[0];
    }
    
    /**
* @Method Name: validatePhoneNumber 
* @Description : Method called from lightnig component to validate phone number(Callout)
* @param phoneNumber
* @return   Boolean
*/ 
    @AuraEnabled(cacheable=true)
    public static Boolean validatePhoneNumber(String phoneNumber){
        //        Boolean isValidPhone = false;
        List<boolean> isValidList = PhoneNoValidation.validatePhoneNo( new List<String>{phoneNumber});
        system.debug('isValidList[0] '+isValidList[0]);
        return isValidList[0];
    }
        
    /**
* @Method Name: getInitData 
* @Description : Method called from lightnig component to get section and field data
* @param campaignName
* @return   list<DisplaySectionWrapper>
*/
    @AuraEnabled
    public static List<DisplaySectionWrapper> getInitData(String campaignName){
        List<DisplaySectionWrapper> toReturn = new List<DisplaySectionWrapper>();
        try{
            toReturn = getCustomMetadataRecords(campaignName);
        }catch(Exception e){
            system.debug('EXCEPTION '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
        return toReturn;
    }
    
    /**
* @Method Name: saveData 
* @Description : Method called from lightnig component to save data
* @param saveData
* @return   Boolean
*/
    @AuraEnabled
    public static String saveData(String fieldData, String captchaResponse,String sectionId,String campaignId,String queueName){
        system.debug('fieldData '+fieldData);
        try{

            List<DisplayFieldDataWrapper> fieldList = (List<DisplayFieldDataWrapper>) JSON.deserialize(fieldData,List<DisplayFieldDataWrapper>.class); 
            Map<String,List<KioskDefaultFields__c>> fieldsByControllingField = new Map<String,List<KioskDefaultFields__c>>();
            List<KioskDefaultFields__c> dependentFields = new List<KioskDefaultFields__c>();
            List<KioskDefaultFields__c> dependentFieldsSection = new List<KioskDefaultFields__c>();
            dependentFields = KioskHelperWithoutSharing.getDependentFieldsByCampaign(campaignId);
                /*[SELECT Id,ControllingField__c,DependentFieldCheckbox__c,ControllingFieldValue__c,DependentField__c,KioskPageSection__r.Name,
                               DependentFieldValue__c,KioskPageSection__c,KioskPageSection__r.Kiosk_Page_Campaign__r.Name 
                               FROM KioskDefaultFields__c WHERE KioskPageCampaign__c =: campaignId AND isActive__c = TRUE];*/
            
            dependentFieldsSection  = KioskHelperWithoutSharing.getDependentFieldsBySection(sectionId);
            /*[SELECT Id,ControllingField__c,DependentFieldCheckbox__c,ControllingFieldValue__c,DependentField__c,KioskPageSection__r.Name,
                                        DependentFieldValue__c,KioskPageSection__c,KioskPageSection__r.Kiosk_Page_Campaign__r.Name 
                                        FROM KioskDefaultFields__c WHERE KioskPageSection__c = :sectionId AND isActive__c = TRUE ];*/
            dependentFields.addAll(dependentFieldsSection);
            system.debug('+++dependentFields '+dependentFields);
            system.debug('fieldList '+JSON.serialize(fieldList));
            Lead leadRecord = new Lead();
            boolean hasOwner = false;
            for(DisplayFieldDataWrapper fieldRec : fieldList){
                if(fieldRec.skipSave != null && !fieldRec.skipSave){
                    system.debug('fieldRec '+fieldRec);
                    if(fieldRec.value != null && fieldRec.fieldApiName != null ){
                        if(fieldRec.fieldType == 'Phone' && fieldRec.countryCode!= null){
                            leadRecord.put('MobileNumber1__c', fieldRec.value);
                            fieldRec.value = fieldRec.countryCode + ''+ fieldRec.value;
                            leadRecord.put('MobileCountryCode__c', fieldRec.countryCode);
                        }
                        system.debug('+++ fieldRec.fieldApiName '+fieldRec.fieldApiName);
                        leadRecord.put(fieldRec.fieldApiName, fieldRec.value);
                        String fieldApiName = fieldRec.fieldApiName;
                        if(fieldApiName.equalsIgnoreCase('OwnerId')){
                            hasOwner = true;
                        }
                    }
                    system.debug('leadRecord '+leadRecord);
                }
            }
           // leadRecord.put('leadSource','Kiosk');
            for(KioskDefaultFields__c field : dependentFields){
                system.debug(' field '+field);
                if(field.DependentFieldCheckbox__c){
                    if(field.ControllingField__c != null && leadRecord.get(field.ControllingField__c) != null && field.ControllingFieldValue__c != null){
                        if(leadRecord.get(field.ControllingField__c) == field.ControllingFieldValue__c){
                            system.debug('++++ field '+field);
                            leadRecord.put(field.DependentField__c,field.DependentFieldValue__c);
                            system.debug('+++ fieldRec.DependentField__c '+field.DependentField__c);

                            if(field.DependentField__c.equalsIgnoreCase('ownerId')){
                                hasOwner = true;
                            }
                        }
                    }
                }else{
                    if(field.isBoolean__c){
                        leadRecord.put(field.DependentField__c,Boolean.valueOf(field.DependentFieldValue__c) );
                    } else {
                        leadRecord.put(field.DependentField__c,field.DependentFieldValue__c);
                    }
                    
                    system.debug('+++ fieldRec.DependentField__c '+field.DependentField__c);
                    if(field.DependentField__c.equalsIgnoreCase('ownerId')){
                        hasOwner = true;
                    }
                }
            }
            system.debug('++ hasOwner '+hasOwner);
            system.debug('++queueName '+queueName);
            if(leadRecord.OwnerId != null){
                leadRecord.ExemptFromAssignment__c = true; 
            }
            if(queueName != '' && !hasOwner){
                List<Group> queueList = new List<Group>();
                
                queueList = KioskHelperWithoutSharing.getQueueByName(queueName);
                    //[select Id,DeveloperName  from Group where Type = 'Queue' AND DeveloperName = : queueName];
                system.debug('++queueList '+queueList);
                if(queueList.size() > 0){
                    leadRecord.put('ownerId',queueList[0].Id);
                }else{
                    throw new AuraHandledException('Lead queue does not exist.');
                }
            }
			
            system.debug('++ leadRecord '+leadRecord);
            if(leadRecord != null){
//                leadRecord.put('rrde__Do_not_Apply_Round_Robin__c',true);
                String insertlist = RecaptchaController.insertRecord(leadRecord, captchaResponse);
                if(insertlist == 'Success - v3' || insertlist == 'Success - v2'){
                    String leadNumber = KioskHelperWithoutSharing.getLeadNumber(leadRecord.Id);
                    return leadNumber;
                } 
                else {
                    throw new AuraHandledException(insertlist);
                }
            }
            return null;
            
        }catch(RecaptchaController.CustomException ce){
            throw new AuraHandledException(ce.getMessage());
        }catch(Exception e){
            system.debug('EXCEPTION '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public static void queryDependentPicklistValuesMetadata(String campaignId){
        /*
[SELECT Id,Controlling_Field_Value__c,
                                                           DependentFieldValueTextArea__c,
                                                           ControllingFieldText__c,DependentFieldText__c
                                                           FROM KioskDependentPicklistValue__c
                                                          WHERE isActive__c = TRUE]
*/
        for(KioskDependentPicklistValue__c pickValue : KioskHelperWithoutSharing.getDependentPicklistValues() ){
            List<PicklistValuesOptions> valueList = convertCommaSeparatedToMap(pickValue.DependentFieldValueTextArea__c,'');
            if(dependentPicklistValuesMap.containsKey(pickValue.ControllingFieldText__c)){
                if(dependentPicklistValuesMap.get(pickValue.ControllingFieldText__c)
                   .containsKey(pickValue.DependentFieldText__c)){
                       if(dependentPicklistValuesMap.get(pickValue.ControllingFieldText__c)
                          .get(pickValue.DependentFieldText__c).containsKey(pickValue.Controlling_Field_Value__c)){
                              dependentPicklistValuesMap.get(pickValue.ControllingFieldText__c).get(pickValue.DependentFieldText__c).get(pickValue.Controlling_Field_Value__c).addAll(valueList);
                          }else{
                              dependentPicklistValuesMap.get(pickValue.ControllingFieldText__c)
                                  .get(pickValue.DependentFieldText__c).put(pickValue.Controlling_Field_Value__c,valueList);
                          }
                   }else{
                       dependentPicklistValuesMap.get(pickValue.ControllingFieldText__c)
                           .put(pickValue.DependentFieldText__c,new Map<String,List<PicklistValuesOptions>>{pickValue.Controlling_Field_Value__c =>valueList});
                   }    
            }else{
                Map<String,Map<String,List<PicklistValuesOptions>>> tempMap = new Map<String,Map<String,List<PicklistValuesOptions>>>{pickValue.DependentFieldText__c=>new Map<String,List<PicklistValuesOptions>>{pickValue.Controlling_Field_Value__c =>valueList}};
                    dependentPicklistValuesMap.put(pickValue.ControllingFieldText__c,tempMap );
            }
        }
        system.debug('&&& dependentPicklistValuesMap '+dependentPicklistValuesMap);
    } 
    
    public static Map<String,List<PicklistValuesOptions>> getAgentAllocationRecords(){
    //    Map<String,List<PicklistValuesOptions>> salesAgentByLocaitonId = new Map<String,List<PicklistValuesOptions>>();
        agentLocationMap = new Map<Id,AllocationGroup__c>(KioskHelperWithoutSharing.getAllocationGroups());
        for(AllocationGroup__c ag : agentLocationMap.values()){
            for(AllocationGroupUser__c agu : ag.AllocationGroupUsersAllocationGroup__r){
                PicklistValuesOptions pvalue = new PicklistValuesOptions(agu.UserName__c,agu.User__c,false);
               /* pvalue.label = agu.UserName__c;
                pvalue.id = agu.Id;*/
                if(salesAgentByLocaitonId.containsKey(ag.Id)){
                    salesAgentByLocaitonId.get(ag.Id).add(pvalue);
                }else{
                    salesAgentByLocaitonId.put(ag.Id,new List<PicklistValuesOptions>{pvalue});
                }
            }
        }
        system.debug('+++ salesAgentByLocaitonId '+salesAgentByLocaitonId);
        return salesAgentByLocaitonId;
    }
    
    /**
* @Method Name: getCustomMetadataRecords 
* @Description : Method used to get section and field data from custom metadata based on campaignName
* @param campaignName
* @return   list<DisplaySectionWrapper>
*/
    @testVisible
    public static List<DisplaySectionWrapper> getCustomMetadataRecords(String campaignName){
        system.debug('campaignName '+campaignName);
        List<KioskPageCampaign__c> kioskCampaignMetadataList = new List<KioskPageCampaign__c>();
        List<DisplaySectionWrapper> sectionDataList = new List<DisplaySectionWrapper>();
        kioskCampaignMetadataList = KioskHelperWithoutSharing.getCampaignByName(campaignName);
            //[SELECT Id,Name FROM KioskPageCampaign__c WHERE Name=:campaignName];
        system.debug('kioskCampaignMetadataList '+kioskCampaignMetadataList);
        if(kioskCampaignMetadataList.size() > 0){
            //Map<Id,AllocationGroup__c> agentLocationMap = new Map<Id,AllocationGroup__c>([SELECT Id,Name,(SELECT Id,UserName__c,User__c FROM AllocationGroupUsersAllocationGroup__r) FROM AllocationGroup__c WHERE ShowOnKiosk__c = TRUE]);
            List<KioskPageSection__c> sectionList = new List<KioskPageSection__c>();
            sectionList = KioskHelperWithoutSharing.getSectionDetails(kioskCampaignMetadataList[0].Id );
            salesAgentByLocaitonId = getAgentAllocationRecords();
            queryDependentPicklistValuesMetadata(kioskCampaignMetadataList[0].Id);
            // Loop to check if campaign has broker tab. 
            Boolean hasBrokerTab = false;
            for(KioskPageSection__c sectionRec : sectionList){
                for(KioskPageField__c fieldRec : sectionRec.Kiosk_Page_Fields__r){
                    if(fieldRec.Field_API_Name__c == 'BrokerAgency__c'){
                        hasBrokerTab = true;
                    }  
                }
            }
            List<Account> brokerAccountRecords = new List<Account>();
            if(hasBrokerTab){
                brokerAccountRecords = KioskHelperWithoutSharing.getBrokerAccounts();
            }
          
            for(KioskPageSection__c sectionRec : sectionList){
                                                          DisplaySectionWrapper sectionWrapperRec = new DisplaySectionWrapper();
                                                          system.debug('sectionRec.Name '+sectionRec.Name);
                                                          sectionWrapperRec.sectionName = sectionRec.Name;
                                                          sectionWrapperRec.sectionId = sectionRec.Id;
                                                          sectionWrapperRec.campaignId = sectionRec.Kiosk_Page_Campaign__c ;
                                                          sectionWrapperRec.leadQueue =  sectionRec.LeadQueue__c;
                                                          List<DisplayFieldDataWrapper> fieldDataList = new List<DisplayFieldDataWrapper>();
                                                          for(KioskPageField__c fieldRec : sectionRec.Kiosk_Page_Fields__r){
                                                              DisplayFieldDataWrapper fieldWrapperRec = new DisplayFieldDataWrapper(fieldRec.Field_Order__c,false);
                                                              if(fieldRec.Controlling_Field__c != null){
                                                                  prepareDependentMap(fieldRec,sectionRec.Name);
                                                                  continue;                        
                                                              }
                                                              fieldWrapperRec.fieldLabel = fieldRec.Name;
                                                              fieldWrapperRec.fieldApiName = fieldRec.Field_API_Name__c;
                                                              fieldWrapperRec.fieldType = fieldRec.Field_Type__c;
                                                              fieldWrapperRec.required = fieldRec.Required__c;
                                                              fieldWrapperRec.fieldOrder = fieldRec.Field_Order__c;
                                                              if(fieldRec.SkipSave__c){
                                                                  fieldWrapperRec.skipSave = true;
                                                              }
                                                              
                                                              if(fieldRec.Field_API_Name__c == 'BrokerAgency__c'){
                                                                  sectionWrapperRec.brokerAccounts = brokerAccountRecords;
                                                              }  
                                                              if(fieldRec.Field_Type__c == 'Picklist' ){
                                                                  if(fieldRec.Query_from_object__c){
                                                                      system.debug('fieldRec.Query_from_object__c '+fieldRec.Query_from_object__c);
                                                                      fieldWrapperRec.picklistValues = preparePicklistValuesFromObj(fieldRec.Field_API_Name__c);
                                                                  }else{
                                                                      if(fieldRec.Get_picklist_values_from_schema__c){
                                                                          if(fieldRec.Picklist_schema_name__c != null){
                                                                              String schemaName = fieldRec.Picklist_schema_name__c;
                                                                              if(schemaName.contains('.')){
                                                                                  system.debug('schemaName '+schemaName );
                                                                                  List<String> schemaNameList = new List<String>();
                                                                                  schemaNameList = schemaName.split('\\.');
                                                                                  system.debug('schemaNameList '+schemaNameList );
                                                                                  fieldWrapperRec.picklistValues = getPicklistValuesFromObject(schemaNameList[0],schemaNameList[1],'');
                                                                                  //fieldRec.DefaultValue__c
                                                                              }
                                                                          }
                                                                      }else{
                                                                          if(fieldRec.Picklist_Values__c != null)
                                                                              fieldWrapperRec.picklistValues = convertCommaSeparatedToMap(fieldRec.Picklist_Values__c,'');
                                                                          //fieldRec.DefaultValue__c
                                                                      } 
                                                                  }
                                                              }
                                                              fieldDataList.add(fieldWrapperRec);
                                                          }
                                                          if(fieldDataList.size() > 0){
                                                              fieldDataList.sort();
                                                              sectionWrapperRec.fieldData = fieldDataList;
                                                              
                                                          }
                                                          sectionWrapperRec.dependentFieldsMapToReturn = dependentFieldsMap;
                                                          sectionWrapperRec.dependentPicklistValuesMapToReturn = dependentPicklistValuesMap;
               
                                                          dependentFieldsMap =  new Map<String,Map<String,List<DisplayFieldDataWrapper>>>();
                                                          sectionDataList.add(sectionWrapperRec);
                                                      }
        }else{
            // return error message with no campaign - Handled in lightning component.
        }
        system.debug('sectionDataList '+sectionDataList);
        system.debug('dependentFieldsMap '+dependentFieldsMap);
        return sectionDataList;
    }
    
    @AuraEnabled
    public static List<Contact> getBrokerAgentList(Id brokerId,String value){
        system.debug('brokerId '+brokerId);
        return KioskHelperWithoutSharing.getBrokerAgents(brokerId);
    }
    
    public static List<PicklistValuesOptions> preparePicklistValuesFromObj(String fieldName ){
        List<PicklistValuesOptions> picklistValuelist = new List<PicklistValuesOptions>(); 
        if(fieldName == agentLocaiton){
            for(AllocationGroup__c agent : agentLocationMap.values()){
                PicklistValuesOptions pvalue = new PicklistValuesOptions(agent.Name,agent.Id,false);
              /*  pvalue.label = agent.Name;
                pvalue.id = agent.Id;*/
                picklistValuelist.add(pvalue);
            }
            //  return picklistValuelist;
        }
        if(fieldName == salesAgent){
            //                public static Map<String,Map<String,Map<String,List<PicklistValuesOptions>>>> dependentPicklistValuesMap  = new  Map<String,Map<String,Map<String,List<PicklistValuesOptions>>>>();// controllingfield->dependentfield->controllingfieldvalue->List<dependentfieldvalue>
            dependentPicklistValuesMap.put(agentLocaiton,new Map<String,Map<String,List<PicklistValuesOptions>>>{salesAgent => salesAgentByLocaitonId});
            system.debug('+++dependentPicklistValuesMap '+dependentPicklistValuesMap);
 
        }
        system.debug('+++picklistValuelist '+picklistValuelist);
        return picklistValuelist;
    }
    
    public static void prepareDependentMap(KioskPageField__c fieldRec,String sectionName){
        DisplayFieldDataWrapper fieldWrapperRec = new DisplayFieldDataWrapper(fieldRec.Field_Order__c,false);
        fieldWrapperRec.fieldLabel = fieldRec.Name;
        fieldWrapperRec.fieldApiName = fieldRec.Field_API_Name__c;
        fieldWrapperRec.fieldType = fieldRec.Field_Type__c;
        fieldWrapperRec.required = fieldRec.Required__c;
        fieldWrapperRec.fieldOrder = fieldRec.Field_Order__c;
        if(fieldRec.SkipSave__c){
            fieldWrapperRec.skipSave = true;
        }
        system.debug('-- fieldWrapperRec '+fieldWrapperRec);
        String controolingField = fieldRec.Controlling_FIeld__c;
        String controllingfieldvalue1 = fieldRec.Controlling_Field_Value__c;
        List<String> controllingfieldvalueList = new List<String>();
        if(controllingfieldvalue1.contains(';')){
            for(String value : controllingfieldvalue1.split(';')){
                controllingfieldvalueList.add(value);
            }
        }else{
            controllingfieldvalueList.add(controllingfieldvalue1);
        }
        
        fieldWrapperRec.controllingField = controolingField; 
        if(fieldRec.Get_picklist_values_from_schema__c){
            if(fieldRec.Picklist_schema_name__c != null){
                String schemaName = fieldRec.Picklist_schema_name__c;
                if(schemaName.contains('.')){
                    system.debug('schemaName '+schemaName );
                    List<String> schemaNameList = new List<String>();
                    schemaNameList = schemaName.split('\\.');
                    system.debug('schemaNameList '+schemaNameList );
                    system.debug('schemaNameList[1] '+schemaNameList[1]);
                    fieldWrapperRec.picklistValues = getPicklistValuesFromObject(schemaNameList[0],schemaNameList[1],'');
                    //fieldRec.DefaultValue__c
                }
            }
        }else if(fieldRec.Query_from_object__c){
            fieldWrapperRec.picklistValues = preparePicklistValuesFromObj(fieldRec.Field_API_Name__c);
        }else{
            if(fieldRec.Picklist_Values__c != null){
                fieldWrapperRec.picklistValues = convertCommaSeparatedToMap(fieldRec.Picklist_Values__c,'');
                //fieldRec.DefaultValue__c
            }
        }
        if(dependentFieldsMap.containsKey(controolingField)){// Controlling field API Name
            for(String controllingfieldvalue  : controllingfieldvalueList){
                if(dependentFieldsMap.get(controolingField).containsKey(controllingfieldvalue)){ // Controlling field Name
                    Boolean isPresent = false;
                    for(DisplayFieldDataWrapper existingField : dependentFieldsMap.get(controolingField).get(controllingfieldvalue)){
                        if(existingField.fieldLabel == fieldRec.Name){
                            isPresent = true;
                            break;
                        } 
                    }
                    if(!isPresent){
                        dependentFieldsMap.get(controolingField).get(controllingfieldvalue).add(fieldWrapperRec);
                    }
                }else{
                    dependentFieldsMap.get(controolingField).put(controllingfieldvalue, new List<DisplayFieldDataWrapper>{fieldWrapperRec});
                }
            }
        }else{
            Map<String,List<DisplayFieldDataWrapper>> tempMap = new Map<String,List<DisplayFieldDataWrapper>>();
            for(String controllingfieldvalue  : controllingfieldvalueList){
                tempMap.put(controllingfieldvalue, new List<DisplayFieldDataWrapper>{fieldWrapperRec});
            }
            dependentFieldsMap.put(controolingField,tempMap);
        }
        system.debug('dependentFieldsMap '+dependentFieldsMap);
 
    }
    
    /**
* @Method Name: convertCommaSeparatedToMap 
* @Description : Method to convert semicolon separated string to picklist values.
* @param picklistString
* @return   list<PicklistValuesOptions>
*/
    public static List<PicklistValuesOptions> convertCommaSeparatedToMap(String picklistString,String defaultValue){
        Map<String,String> picklistValues = new Map<String,String>();
        List<PicklistValuesOptions> values = new List<PicklistValuesOptions>();
        system.debug('picklistString '+picklistString);
        if(picklistString.contains(';')){
            for(String value : picklistString.split(';')){
                if(value.contains('=>')){
                    List<String> valueLst =  value.split('=>');
                    Boolean defaultFlag = false;
                    if(defaultValue != null && defaultValue == valueLst[0].trim()){
                        defaultFlag = true;
                    }
                    PicklistValuesOptions option = new PicklistValuesOptions(valueLst[0].trim(),valueLst[1].trim(),defaultFlag);
                  /*  option.label = valueLst[0].trim();
                    option.id = valueLst[1].trim();
                    option.defaultValue = defaulVaue;*/
                    values.add(option);
                }
                //                picklistValues.put(value.trim(),value.trim());
            }
        }else{// single value
            if(picklistString.contains('=>')){
                List<String> valueLst =  picklistString.split('=>');
                Boolean defauleFlag = false;
                if(defaultValue == valueLst[0].trim()){
                    defauleFlag = true;
                }
                PicklistValuesOptions option = new PicklistValuesOptions(valueLst[0].trim(),valueLst[1].trim(),defauleFlag);
        /*        option.label = valueLst[0].trim();
                option.id = valueLst[1].trim();
                option.defaultValue = defaulVaue;*/
                values.add(option);
            }
            // picklistValues.put(picklistString,picklistString);
        }
        return values;
    }

    public static List<PicklistValuesOptions> getPicklistValuesFromObject( String objectName,String fieldName,String defaultValue){
        List<PicklistValuesOptions> values = new List<PicklistValuesOptions>();
        Schema.SObjectType s = Schema.getGlobalDescribe().get(objectName) ;
        Schema.DescribeSObjectResult r = s.getDescribe() ;
        Map<String,Schema.SObjectField> fields = r.fields.getMap() ;
        system.debug('fieldName '+fieldName);
        system.debug('fields '+fields);
        Schema.SObjectField field = fields.get(fieldName);
        system.debug('+field '+field);
        Schema.DescribeFieldResult fieldResult = field.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            Boolean defauleFlag = false;
            if(defaultValue == pickListVal.getLabel()){
                defauleFlag = true;
            }
            PicklistValuesOptions option = new PicklistValuesOptions(pickListVal.getLabel(),pickListVal.getValue(),defauleFlag);
/*            option.label = pickListVal.getLabel();
            option.id = pickListVal.getValue();
            option.defaultValue = defaulVaue;*/
            values.add(option);
        }    
        return values;
    }
    
    @InvocableMethod (label='Clone kiosk campaign')
    public static List<cloneCampaign> cloneFromCampaign(List<cloneCampaign> cloneCampaignLst){
        system.debug('cloneCampaignLst '+cloneCampaignLst);
        String cloneFrom = cloneCampaignLst[0].cloneFromId;
        String campaignName = cloneCampaignLst[0].campaignName;
        KioskPageCampaign__c oldCampaign = [SELECT Id,Name,isActive__c FROM KioskPageCampaign__c WHERE Id=:cloneFrom];
        KioskPageCampaign__c newCampaign  = oldCampaign.clone(false, false, false, false);
        newCampaign.Name = campaignName;
        Insert newCampaign;
        Map<String,List<KioskPageField__c>> fieldsBySection = new Map<String,List<KioskPageField__c>>();
        List<KioskPageSection__c> sectionsToInsert = new List<KioskPageSection__c>();
        for(KioskPageSection__c s :  KioskHelperWithoutSharing.getExistingCampaign(cloneFrom)){
                                          KioskPageSection__c newSection  = s.clone(false,false, false, false);
                                          newSection.Id = null;
                                          newSection.Kiosk_Page_Campaign__c = newCampaign.Id;
                                          sectionsToInsert.add(newSection);
                                          fieldsBySection.put(s.Name,s.Kiosk_Page_Fields__r);
                                      }
        Insert sectionsToInsert;
        Map<String,KioskPageSection__c> sectionByName = new  Map<String,KioskPageSection__c>();
        for(KioskPageSection__c s : sectionsToInsert){
            sectionByName.put(s.Name, s);
        }
        List<KioskPageField__c> fieldList = new List<KioskPageField__c>();
        for(String sectionName : fieldsBySection.keySet()){
            for(KioskPageField__c field : fieldsBySection.get(sectionName)){
                KioskPageField__c newField = field.clone(false,false, false, false);
                newField.Kiosk_Page_Section__c = sectionByName.get(sectionName).Id;
                fieldList.add(newField);
            }
        }
        Insert fieldList;
        cloneCampaign ret = new cloneCampaign();
        ret.message=newCampaign.Id;
        return new List<cloneCampaign>{ret};
            }
    public class cloneCampaign {
        @InvocableVariable
        public String cloneFromId;
        
        @InvocableVariable
        public String campaignName;
        
        @InvocableVariable
        public String message;
    }
   
  
    
    public class DisplaySectionWrapper{
        @AuraEnabled public String sectionName{get;set;}	// Tab Name
        @AuraEnabled public String sectionId{get;set;}	//Section id for backend
        @AuraEnabled public String campaignId{get;set;} // campaign id for backend
        @AuraEnabled public String leadQueue{get;set;} // Assign lead to queue, if blank then owner from form will be updated.
        @AuraEnabled public List<DisplayFieldDataWrapper> fieldData{get;set;}	
        @AuraEnabled public Map<String,Map<String,List<DisplayFieldDataWrapper>>> dependentFieldsMapToReturn{get;set;}
        @AuraEnabled public Map<String,Map<String,Map<String,List<PicklistValuesOptions>>>> dependentPicklistValuesMapToReturn{get;set;}
        @AuraEnabled public List<Account> brokerAccounts{get;set;}	
        
        public DisplaySectionWrapper(){
            dependentPicklistValuesMapToReturn = new Map<String,Map<String,Map<String,List<PicklistValuesOptions>>>>();
            dependentFieldsMapToReturn = new Map<String,Map<String,List<DisplayFieldDataWrapper>>>();
            this.leadQueue = '';
                        brokerAccounts = new  List<Account>();

        }
    }
    
    public class DisplayFieldDataWrapper implements Comparable{
        @AuraEnabled public String fieldLabel{get;set;}	// Label of field to show on form
        @AuraEnabled public String fieldApiName{get;set;} // API name of field to save data
        @AuraEnabled public String fieldType{get;set;} // type of field
        @AuraEnabled public String value{get;set;} // store value of field
        @AuraEnabled public Boolean skipSave{get;set;} // store value of field
        @AuraEnabled public List<PicklistValuesOptions> picklistValues{get;set;} // picklist values for field
        @AuraEnabled public String defaultValue{get;set;} // default value for field
        @AuraEnabled public Boolean required{get;set;} // Check if field is required on form
        @AuraEnabled public Decimal fieldOrder{get;set;} // order of field to display
        @AuraEnabled public String controllingField{get;set;} 
        //        @AuraEnabled public Boolean hiddenField{get;set;} 
        @AuraEnabled public String countryCode{get;set;} // applicable only for phone fields. 
        //        @AuraEnabled public List<ControllingFieldClass> controlingFieldAttribute {get;set;} 

        public DisplayFieldDataWrapper(Decimal fieldOrder,Boolean skipSave){
            this.fieldOrder = fieldOrder;
            this.skipSave = skipSave;

        }
        // Implemented comparable because we cannot sort fields in inner query        
        public Integer compareTo(Object compareTo) {
            DisplayFieldDataWrapper compareToField = (DisplayFieldDataWrapper)compareTo;
            // The return value of 0 indicates that both elements are equal.
            if (fieldOrder == compareToField.fieldOrder) return 0;
            if (fieldOrder > compareToField.fieldOrder) return 1;
            return -1;
        }
    }

    public class PicklistValuesOptions{
        @AuraEnabled public String label{get;set;}	// Label of field to show on form
        @AuraEnabled public String id{get;set;}	// Label of field to show on form
        @AuraEnabled public Boolean defaultValue{get;set;}	// Label of field to show on form
        
        PicklistValuesOptions(String label,String id,Boolean defaultValue){
            this.label = label;
            this.id = id;
            this.defaultValue = defaultValue;
        }
    }
}