public class reUsableSubStatusController {
    
    @AuraEnabled(cacheable=false)
    public static List<Generic_Sub_Status_Config__mdt> getSubStatusValues(Id recordId) {
       
        List<Generic_Sub_Status_Config__mdt> subStatusValues = new List<Generic_Sub_Status_Config__mdt>();
        String sObjectName = recordId.getSObjectType().getDescribe().getName();
        
        List<Sub_Status_Object_Fields_Config__mdt> fields = [SELECT Id, MasterLabel, Remarks_API_Name__c, Sub_Status_API_Name__c FROM Sub_Status_Object_Fields_Config__mdt WHERE MasterLabel = :sObjectName];
        
        if (fields.size() > 0 && fields[0].Sub_Status_API_Name__c != null && fields[0].Remarks_API_Name__c != null) {
            String query = 'SELECT Id,' + fields[0].Sub_Status_API_Name__c + ',' + fields[0].Remarks_API_Name__c + ' FROM ' + sObjectName + ' WHERE Id = :recordId';
            sobject result = Database.query(query);
            system.debug('result=='+result);
            String currentRecordStatus = String.valueOf(result.get(fields[0].Sub_Status_API_Name__c));
             system.debug('currentRecordStatus=='+currentRecordStatus);
            try {
                subStatusValues = getSubStatusDetails(currentRecordStatus, sObjectName);
                System.debug('subStatusValues'+subStatusValues);
            } catch (Exception e) {
                throw new AuraHandledException('Error in getSubStatusValues: ' + e.getMessage());
            }
        }
        
        return subStatusValues;
    }
    
    public static List<Generic_Sub_Status_Config__mdt> getSubStatusDetails(String currentRecStatus, String sObjectName) {
        system.debug('currentRecStatus=='+currentRecStatus);
        system.debug('sObjectName=='+sObjectName);
        String profileId = UserInfo.getProfileId();
        system.debug('profileId=='+profileId);
        List<Map<String, String>> subStatusDetails = new List<Map<String, String>>();
        String currentUserId = UserInfo.getUserId();
        User currentUser = [SELECT Profile.Name FROM User WHERE Id = :currentUserId];
         system.debug('currentUser=='+currentUser);
        String profileName = currentUser.Profile.Name;
         system.debug('profileName=='+profileName);
        
        List<Generic_Sub_Status_Config__mdt> nextStatusValues = [SELECT NextApplicableStatus__c, Reject_Reasons__c FROM Generic_Sub_Status_Config__mdt WHERE MasterLabel = :currentRecStatus AND Sobject__c = :sObjectName AND User_Identifier__c LIKE :('%' + profileName + '%')];
        system.debug('nextStatusValues=='+nextStatusValues);
       
        
        return nextStatusValues;
    }
    
    
    
    @AuraEnabled(cacheable=true)
    public static list<Sub_Status_Object_Fields_Config__mdt> getSobjectFieldInfo(string recordId){
        
        String sObjectName = Id.valueOf(recordId).getSObjectType().getDescribe().getName();        
        list<Sub_Status_Object_Fields_Config__mdt> data = [SELECT Id, MasterLabel, Remarks_API_Name__c,Sub_Status_API_Name__c,Backup_Remarks_API_Name__c,Reject_Reason_Api_Name__c FROM Sub_Status_Object_Fields_Config__mdt WHERE MasterLabel =:sObjectName];
        return data;
    }
    
   
    
    
    @AuraEnabled
    public static void updateSobjectRec(sObject record,list<Sub_Status_Object_Fields_Config__mdt> sobjectConfigInfo){
      System.debug(record);
         System.debug(sobjectConfigInfo);
        string backUpApiName = sobjectConfigInfo[0].Backup_Remarks_API_Name__c;
        string sobjectName = sobjectConfigInfo[0].MasterLabel;
        String subStatusApiName = sobjectConfigInfo[0].Sub_Status_API_Name__c;
        String subStatusValue = (String)record.get(subStatusApiName);
        String rejectreason=sobjectConfigInfo[0].Reject_Reason_Api_Name__c;
        system.debug('backUpApiName'+backUpApiName);
          system.debug('rejectreason---'+rejectreason);
         system.debug('subStatusApiName---'+subStatusApiName);
        string userName = [select Name from user where Id=:userinfo.getuserId()].Name;
        //Sobject oldRec = database.query('Select '+backUpApiName+','+rejectreason+ 'From '+sobjectName+' Where Id IN (\'' + record.Id + '\')');
       SObject oldRec = Database.query('SELECT ' + backUpApiName + ', ' + rejectreason + ' FROM ' + sobjectName + ' WHERE Id = \'' + record.Id + '\'');
        
        if(record.get(backUpApiName)!=null){
           
            if(record.get(subStatusApiName)=='Rejected'){
                string rejreason=(String)record.get(backUpApiName);
                  system.debug('rejectreason--rejreason-'+rejreason);
                record.put(rejectreason,oldRec.get(rejectreason) == null?rejreason:oldRec.get(rejectreason)+'\n'+rejreason);
            }
            
            //string newCmnt = userName+': '+record.get(backUpApiName);
            string newCmnt = (String)record.get(backUpApiName);
            System.debug(newCmnt);
            
            record.put(backUpApiName,oldRec.get(backUpApiName) == null?newCmnt:oldRec.get(backUpApiName)+'\n'+newCmnt);
            System.debug('rec---'+record);
            CaseComment cmnt=new CaseComment ();
            cmnt.ParentId= record.Id;
            cmnt.CommentBody  =newCmnt;
            insert cmnt;
             System.debug('cmnt---'+cmnt);
            
        }
       
        /*List<DynamicSobjectAction__mdt> dynamicActionList =[Select id,Sequence__c,ActionSobjectName__c,ActionType__c,UpdateApiName__c,Update_Value__c From DynamicSobjectAction__mdt Where CondtionApiName__c=:subStatusApiName AND ConditionValue__c=:subStatusValue AND CondtionSobject__c=:sobjectName Order By Sequence__c ASC ];
        System.debug('dynamicActionList'+dynamicActionList);
        
        if(dynamicActionList.size()>0){
            for(DynamicSobjectAction__mdt  act:dynamicActionList ){
                if(act.ActionType__c=='Update' && act.ActionSobjectName__c==sobjectName   ){
                    record.put(act.UpdateApiName__c,act.Update_Value__c);
                    System.debug(record);
                    
                }
            }
        }*/
      
       
        
         update record;
        
    }
    
    
    
}