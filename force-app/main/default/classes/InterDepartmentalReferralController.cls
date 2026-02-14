public without sharing class InterDepartmentalReferralController {
    
    @AuraEnabled 
    public static Map<String, List<String>> getDependentMap(string contrfieldApiName,string depfieldApiName) {
        String controllingField = contrfieldApiName.toLowerCase();
        String dependentField = depfieldApiName.toLowerCase();
        
        Map<String,List<String>> objResults = new Map<String,List<String>>();
        
        Schema.sObjectType objType = Lead.getSObjectType();
        if (objType==null){
            return objResults;
        }
        
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
        if (!objFieldMap.containsKey(controllingField) || !objFieldMap.containsKey(dependentField)){
            return objResults;     
        }
        
        Schema.SObjectField theField = objFieldMap.get(dependentField);
        Schema.SObjectField ctrlField = objFieldMap.get(controllingField);
        List<Schema.PicklistEntry> contrEntries = ctrlField.getDescribe().getPicklistValues();
        List<PicklistEntryWrapper> depEntries = wrapPicklistEntries(theField.getDescribe().getPicklistValues());
        List<String> controllingValues = new List<String>();
        
        for (Schema.PicklistEntry ple : contrEntries) {
            String label = ple.getLabel();
            objResults.put(label, new List<String>());
            controllingValues.add(label);
        }
        
        for (PicklistEntryWrapper plew : depEntries) {
            String label = plew.label;
            String validForBits = base64ToBits(plew.validFor);
            for (Integer i = 0; i < validForBits.length(); i++) {
                String bit = validForBits.mid(i, 1);
                if (bit == '1') {
                    objResults.get(controllingValues.get(i)).add(label);
                }
            }
        }
        system.debug('objResults:::'+objResults);
        return objResults;
    }
    
    public static String decimalToBinary(Integer val) {
        String bits = '';
        while (val > 0) {
            Integer remainder = Math.mod(val, 2);
            val = Integer.valueOf(Math.floor(val / 2));
            bits = String.valueOf(remainder) + bits;
        }
        return bits;
    }
    
    public static String base64ToBits(String validFor) {
        if (String.isEmpty(validFor)) return '';
        
        String validForBits = '';
        
        for (Integer i = 0; i < validFor.length(); i++) {
            String thisChar = validFor.mid(i, 1);
            Integer val = base64Chars.indexOf(thisChar);
            String bits = decimalToBinary(val).leftPad(6, '0');
            validForBits += bits;
        }
        
        return validForBits;
    }
    
    private static final String base64Chars = '' +
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
        'abcdefghijklmnopqrstuvwxyz' +
        '0123456789+/';
    
    
    private static List<PicklistEntryWrapper> wrapPicklistEntries(List<Schema.PicklistEntry> PLEs) {
        return (List<PicklistEntryWrapper>)
            JSON.deserialize(JSON.serialize(PLEs), List<PicklistEntryWrapper>.class);
    }
    
    public class PicklistEntryWrapper{
        public String active {get;set;}
        public String defaultValue {get;set;}
        public String label {get;set;}
        public String value {get;set;}
        public String validFor {get;set;}
        public PicklistEntryWrapper(){            
        }
        
    }
    
    @AuraEnabled
    public static Lead getCurrentRecord(Id recordId){
        String objectName = recordId.getSObjectType().getDescribe().getName();
        system.debug('objectName::'+objectName);
        Lead lead;
        if(objectName == 'Lead'){
            lead = getLeadQuery(objectName, 'Id', recordId);
            
        }else if(objectName == 'Opportunity'){
            Opportunity opportunity = [SELECT LeadNumber__c FROM Opportunity WHERE Id=:recordId];
            
            if(opportunity.LeadNumber__c != null){
                system.debug('opportunity.LeadNumber__c::'+opportunity.LeadNumber__c);
                lead = getLeadQuery('Lead','LeadNumber__c', opportunity.LeadNumber__c);
                system.debug('+++ lead '+lead);

            }
        }
        return lead;
    }
    
    @AuraEnabled
    public static String checkCurrentUsersTeam(){
        return [SELECT Id, Team__c FROM USER WHERE Id =: UserInfo.getUserId()].Team__c;
    }
    
    @AuraEnabled
    public static String referLead(Id recordId, String Team, String SalesType, String PropertyUsage, String Project){
        String returnMsg = '';
        Lead lead = getCurrentRecord(recordId);
        String objectName = recordId.getSObjectType().getDescribe().getName();
        Lead leadClone = lead.clone(false, false, false, false);
        leadClone.OwnerId = [SELECT DeveloperName,Email,Id,Name,Type FROM Group WHERE Type = 'Queue' AND developerName =: Constants.DEFAULT_RR_QUEUE].Id;
        SavePoint sp = Database.SetSavePoint();
        if(Team == 'ReSales'){
            leadClone.Lead_Type__c = 'Resale'; 
        } else {
            leadClone.SalesType__c =  SalesType;
            leadClone.PropertyUsage__c = PropertyUsage;
            leadClone.Project__c = Project;
        }
        leadClone.ReferredTo__c = Team;
        leadClone.IsConverted = false;
        leadClone.ConvertedDate = null;
        leadClone.Status = 'In Progress Lead';
        leadClone.ConvertedAccountId = null;
        leadClone.ConvertedContactId = null;
        leadClone.ConvertedOpportunityId = null;
        leadClone.ReferredBy__c = UserInfo.getUserId();
        leadClone.ReferralLead__c = lead.Id;
        leadClone.CustomerBudget__c = lead.CustomerBudget__c;
        leadClone.PurposeOfUse__c = lead.PurposeOfUse__c;
        leadClone.PropertyReadiness__c = lead.PropertyReadiness__c;
        leadClone.BuyRent__c = lead.BuyRent__c;
        leadClone.UnitType__c = lead.UnitType__c;
        leadClone.UnitNumber__c = lead.UnitNumber__c;
        leadClone.NumberOfBedrooms__c = lead.NumberOfBedrooms__c;
        leadClone.NumberOfEmployees = lead.NumberOfEmployees;
        leadClone.LeadSource = 'Direct Call';
        leadClone.EnquiryCategory__c = 'Internal Referral';
        leadClone.EnquiryTrigger__c = 'Intra Department Referral';
        leadClone.isValidationBypass__c = true;
        try {
            system.debug('+++ leadClone '+leadClone);
            insert leadClone;
            returnMsg = 'Success_'+leadClone.Id;
            
            //update Opportunity
            if(leadClone.Id != null){
                //updateOpportunityStage(recordId);
                shareLeadRecord(leadClone.Id);
            }
            
            if(objectName == 'Lead'){
                lead.Status = 'Retired Lead';
                lead.RetiredReason__c = 'Inter Departmental Referral';
                update lead;
            }
           
        } catch(Exception ex) {
            returnMsg = ex.getMessage();
            database.RollBack(sp);
        }
        return returnMsg;
    } 
    
    public static lead getLeadQuery(String ObjectName, String conditionField, String whereString){
       //List<String> fields = new List<String>(Schema.getGlobalDescribe().get(ObjectName).getDescribe().fields.getMap().keySet()); 
        String query  = 'SELECT Id,FirstName,LastName,Email,MobileNumber1__c,MobileCountryCode__c,Nationality__c,Gender__c,Marital_Status__c,CustomerSubType__c,'+
            'Referral_Relationship__c,EmployeeName__c,EmployeeEmail__c,EmployeeId__c,EmployeeDepartment__c,Project__c,CorporateWealthName__c,'+
            'PropertyUsage__c,ResidentStatus__c,Financing__c,CustomerType__c,SalesType__c,LeadSource,SalesOrigin__c,CustomerBudget__c,PurposeOfUse__c,PropertyReadiness__c,BuyRent__c,UnitType__c,UnitNumber__c,NumberOfBedrooms__c,NumberOfEmployees,'+
            'EnquiryCategory__c,EnquiryTrigger__c,CountryOfResidence__c,LeadAge__c,ReferredTo__c,ReferredBy__c,(SELECT  Id FROM Leads1__r) ' +' FROM '+ObjectName + ' WHERE '+ conditionField + ' = ' +'\''+ whereString+ '\'';
        system.debug('query::'+query);
        return Database.query(query);
    }
    
    /*public static void updateOpportunityStage(Id recordId){
        String objectName = recordId.getSObjectType().getDescribe().getName();
        if(objectName == 'Opportunity'){
            Opportunity opportunity = [SELECT Id,LeadNumber__c,StageName,LossReason__c FROM Opportunity WHERE Id=:recordId];
            opportunity.StageName = opportunity.StageName != 'Closed Won' ? 'Closed Lost' : opportunity.StageName;
            opportunity.LossReason__c  = opportunity.StageName != 'Closed Won' ? 'Lost - Inter Department Referral' : opportunity.LossReason__c;
            opportunity.LossComments__c = 'Lost - Inter Department Referral' ;
            try{
                update opportunity;
            }catch(Exception ex){}
            
        }
    }*/
    
    public static void shareLeadRecord(Id leadId){
        LeadShare shareLead = new LeadShare();
        shareLead.LeadId = leadId;
        shareLead.UserOrGroupId = UserInfo.getUserId();
        shareLead.LeadAccessLevel = 'edit';
        shareLead.RowCause = Schema.LeadShare.RowCause.Manual;
        insert shareLead;
    }
}