public class ECSS_LeadTriggerHelper { 
    public static void LeadRotation(List <Lead> inputList, Boolean checkManager){
        
        List<String> leadIds = new List<String>();
        List<String> CompIds = new List<String>();
        List<String> combinedCompIds = new List<String>();
        List<Lead> UpdatedLeads = new List<Lead>();
        
        for(Lead currLead: inputList){
            String ECSSLabelRecordType = System.Label.ECSS_LeadRecordType_AlDarEstate;
            Id recordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
                .get(ECSSLabelRecordType)
                .getRecordTypeId();
            
            // Get the current user's ID
            String currentUserId = UserInfo.getUserId();
            
            // Query the User object
            User currentUser = [SELECT Id, Name, Email, Profile.Name, ManagerId , ECSS_SalesAgent__c,RoleName__c
                                FROM User 
                                WHERE Id = :currentUserId];
            
            if(currentUser.RoleName__c!='Leasing Executive' &&  currLead.LeadSource!='' && currLead.LeadSource!='Referrals'  && currLead.LeadSource!= 'Direct/ Self-generated' && currLead.RecordTypeId == recordTypeId && currentUser.RoleName__c!='Sales Agents' ){
                leadIds.add(currLead.Id);
                if(currLead.ECSS_Company__c	 != null && !CompIds.contains(currLead.ECSS_Company__c	))
                    CompIds.add(currLead.ECSS_Company__c);
                combinedCompIds.add(currLead.ECSS_Company__c);
                System.debug('ECSS_LeadTriggerHelper: Inside If Condition');
                System.debug('CompIds: '+CompIds);
                System.debug('combinedCompIds: '+combinedCompIds);
                System.debug('Lead Rec: '+currLead);
                System.debug('Leasing Manager/ Team Lead:'+checkManager);
            }
            else{
                Lead updLead = new Lead();
                updLead.Id = currLead.Id;
                updLead.OwnerId=currentUserId;
                updLead.ECSS_Assigned_Date_Time__c = System.now();
                updLead.ECSS_SLA_Date__c = System.now();
                updLead.ECSS_SLA_Entry__c = true;
                updLead.ECSS_Re_Assign__c = false;
                updLead.ECSS_Assigned__c = true;
                updLead.Status = 'Assigned';
                UpdatedLeads.add(updLead);
            }
            if(currentUser.RoleName__c == 'Leasing Manager/Team Lead'){
                checkManager = true;
                System.debug('Checkmanager:'+checkManager);
            }
            
            System.debug('CompIds: '+compIds);
        }
        if(!System.isQueueable() && !System.isFuture()){
            if(leadIds.size()>0){
                List <Assignment_Engine__c> EngList = [SELECT Id,Criteria__c,Object_Name__c,No_Criteria__c FROM Assignment_Engine__c  WHERE Object_Name__c = 'Lead' ];
                system.enqueueJob(new ECSS_RoundRobinQueueable('Lead',leadIds,EngList,CompIds,combinedCompIds,checkManager));
            }
        }
        if(UpdatedLeads.size()>0){
            update UpdatedLeads;
        }
    }
    
    public static void verifyPhoneNumbers(List<Lead> newList, Map<Id,Lead> oldMap)
    {
        String phoneNumberStr;
        
        //String phoneNumberStr;
        List<Schema.PicklistEntry> values = Lead.MobileCountryCode__c.getDescribe().getPicklistValues();
        Map<String,String> mobileCountryApiToLabelMap = new Map<String,String>();
        For(Schema.PicklistEntry sp : values){
            //Map to hold Picklist API as Key and Picklist Label as Value
            mobileCountryApiToLabelMap.put(sp.getValue(), sp.getLabel());
        }
        
        String ECSSLabelRecordType = System.Label.ECSS_LeadRecordType_AlDarEstate;
        Id recordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
            .get(ECSSLabelRecordType)
            .getRecordTypeId();
        
        for(Lead leadObj : newList)
        {
            if(leadObj.RecordTypeId == recordTypeId){
                if(oldMap == null || leadObj.MobilePhone != oldMap.get(leadObj.Id).MobilePhone){
                    phoneNumberStr = leadObj.MobilePhone;
                }
                
                
                try
                {
                    if(phoneNumberStr != null)
                    {
                        Boolean isValidPhoneNumber = ECSS_PhoneNumberValidity.Validate(phoneNumberStr,leadObj.MobileCountryCode__c);
                        if(!isValidPhoneNumber)
                        {
                            leadObj.MobilePhone.addError('Invalid phone number format for '+mobileCountryApiToLabelMap.get(leadObj.MobileCountryCode__c));
                        }else{
                            system.debug('NG:leadObj.MobileCountryCode__c'+ leadObj.MobileCountryCode__c);
                            leadObj.MobilePhone = ECSS_PhoneNumberValidity.Format(phoneNumberStr, leadObj.MobileCountryCode__c );
                        }
                    }
                    
                }
                
                
                catch (Exception e)
                {
                    System.debug('e.getMessage(): ' + e.getMessage());
                    if(e.getMessage().Contains('MobileCountry is required.')){
                        leadObj.MobileCountryCode__c.addError('Missing or invalid International Country');
                    }else{
                        leadObj.addError(e);
                    }
                    System.debug('NumberParseException was thrown: ' + e);
                }
            }
        }
    }
    
    
}