/**
 * @description       : This class used for handle trigger logic for Lead object.
 * @coverage          : Test.cls | @CC100%
 * @author            : rrangrej@aldar.com
 * @group             : Aldar
 * @last modified on  : 04/03/2025
 * @last modified by  : rrangrej@aldar.com
 * Modifications Log
 * Ver   Date         Author                                    Modification
 * 1.0   04/03/2025   rrangrej@aldar.com             Initial Version | Story Number | @CC100%
 * 1.1   18/09/2025   Protiviti                      Skipping Organization Record Type Mapping condition in populateBeforeCommit method if the record type is Retail Lead Record Type.
 **/

public class LeadTriggerHelper {
    private static Boolean isLoaded = false;  // Flag to ensure single execution
    public static Map<String, Account> allAccountRecMap;
    public static Map<String,Lead> existingLeadUniquekeyMap;
    
    public static Map<String, Group> queueMap {
    	get { if(queueMap == null) queueMap = LeadTriggerHelper.fetchQueueMap(); return queueMap; }
    	private set; 
    }
    
    public Group leadAutoDialerQueue {
    	get { if(leadAutoDialerQueue == null) leadAutoDialerQueue = getGroupIdByName(Constants.LEAD_AUTO_DIALER_QUEUE); return leadAutoDialerQueue; }
    	private set; 
    }
    
    public Group leadOptionsUpgradeQueue {
    	get { if(leadOptionsUpgradeQueue == null) leadOptionsUpgradeQueue = getGroupIdByName(Constants.LEAD_OU_QUEUE); return leadOptionsUpgradeQueue; }
    	private set; 
    }
    
    public Group leadLogisticsQueue {
    	get { if(leadLogisticsQueue == null) leadLogisticsQueue = Test.isRunningTest() ? null : getGroupIdByName(Constants.LEAD_LOGISTICS_QUEUE); return leadLogisticsQueue; }
    	private set; 
    }
    
    public Group leadDuplicateQueue {
    	get { if(leadDuplicateQueue == null) leadDuplicateQueue = getGroupIdByName(Constants.LEAD_DUPLICATE_QUEUE); return leadDuplicateQueue; }
    	private set; 
    }
    
    public Group leadAssetsManagementQueue {
    	get { if(leadAssetsManagementQueue == null) leadAssetsManagementQueue = Utilities.getQueueInformation(Constants.ASSETS_MANAGEMENT_QUEUE); return leadAssetsManagementQueue; }
    	private set; 
    }
    
    public Group leadBrokerQueue {
    	get { if(leadBrokerQueue == null) leadBrokerQueue = getGroupIdByName(Constants.BROKER_QUEUE); return leadBrokerQueue; }
    	private set; 
    }
    
    public Group leadDefaultQueue {
    	get { if(leadDefaultQueue == null) leadDefaultQueue = getGroupIdByName(Constants.SALES_RRQUEUE); return leadDefaultQueue; }
    	private set; 
    }
    
    public Group launchQueue  {
    	get { if(launchQueue == null) launchQueue = getGroupIdByName(System.Label.LaunchQueue); return launchQueue; }
    	private set; 
    }
    
    public static User userDetail {
    	get { if(userDetail == null) userDetail = Utilities.getLoggedInUserDetail(); return userDetail; }
    	private set; 
    }
    
    public static Map<Id, Id> permissionSetCMHOMEMap {
    	get { if(permissionSetCMHOMEMap == null) permissionSetCMHOMEMap = ResaleService.getPermissionAssignedMap(Constants.CM_HOME_PERMISSION_SET); return permissionSetCMHOMEMap; }
    	private set; 
    }
    
    public static Map<String, Group> fetchQueueMap() {
        Map<String, Group> queueMapData = new Map<String, Group>();
        
        for(Group gp : [SELECT Id, name  FROM Group WHERE Type = 'Queue']) {
            queueMapData.put(gp.Name, gp);
        }
        
        return queueMapData;
    }
    
	public LeadTriggerHelper() {}
    
    /**
* @description Method to used get Group Record Id by Name
* @author rrangrej@aldar.com | 06/03/2025 | Story Number
* @param queueName
* @return groupId
**/
    public static Group getGroupIdByName(String queueName) {
        Group groupInfo = queueMap.containsKey(queueName) ? queueMap.get(queueName) : null;
        return groupInfo;
    }
    
    /**
* @description Method to used get Organizaion Record Type Id
* @author rrangrej@aldar.com | 06/03/2025 | Story Number
* @return orgRecordTypeId
**/
    public static Id getOrganizaionRecordTypeId(){
        Id orgRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get(Constants.ORGANIZATION_LEAD_RECORD_TYPE_Name).getRecordTypeId();
        return orgRecordTypeId;
    }
    
    /**
     * @description Method to used get Retail Lead Record Type Id
     * @author vkotaprolu@aldar.com | 18/09/2025 | Story Number
     * @return orgRecordTypeId
     **/
    public static Id getRetailLeadRecordTypeId(){
        Id retailLeadRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get(Constants.RETAIL_LEAD_RECORD_TYPE_NAME).getRecordTypeId();
        return retailLeadRecordTypeId;
    }
    
    /**
     * @description Method to used fetch Non Merged Accounts by Ids
     * @author rrangrej@aldar.com | 06/03/2025 | Story Number
     * @param accountIds
     * @return accountMap
     **/
    public static Map<Id, Account> fetchNonMergedAccounts(Set<Id> accountIds) {
        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, Name, PersonEmail, MobilePhone__pc, Email__c, MobileNumber1__c FROM Account WHERE Id IN : accountIds AND MergedAccount__c = FALSE]);
        return accountMap;
    }
    
    /**
* @description Method to used fast field update
* @author rrangrej@aldar.com | 06/03/2025 | Story Number
* @param newLeadList
**/
    public static void populateBeforeCommit(List<Lead> newLeadList) {
        List<String> existinLeadUniqueKey = Utilities.getUniqueKeyMapping(Constants.LEAD_UNIQUE_KEYS).Values__c.split(';');
        List<String> existingAccountUniqueKey = Utilities.getUniqueKeyMapping(Constants.LEAD_ACCOUNT_UNIQUE_KEYS).Values__c.split(';');
        List<String> AMSalesProjects = System.Label.AMSalesProjects.split(';');
        Id organizationRecordTypeId = LeadTriggerHelper.getOrganizaionRecordTypeId();
        //Added by CloudzLab
        String ECSSLeadRecordType = System.Label.AAA_ECSSRecordTypeId;
        //String ECSSLeadRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(ECSSLeadRecordType).getRecordTypeId();
      Id retailLeadRecordTypeId = LeadTriggerHelper.getRetailLeadRecordTypeId();
        // Added by Protiviti on 18 Sept 2025
        for(Lead newLead : newLeadList) {
            //added a check by Himanshu@Aldar to exclude P & I leads 
            if(newLead.recordtypeId == PI_Services.p_IRecordTypeId){
                continue;
            }
            
            if(String.isBlank(newLead.Email) && String.isNotBlank(newLead.EmailAddress__c)){
                newLead.Email = newLead.EmailAddress__c;
            }
            
            if(newLead.Email != NULL) {
                newLead.EmailAddress__c = newLead.Email;
            }   
            
            if(newLead.MobileNumber1__c == NULL && newLead.MobileNumber__c != NULL) {
                newLead.MobileNumber1__c = newLead.MobileNumber__c;
            }  
            
            if(newLead.MobileCountryCode__c != NULL && newLead.MobileNumber1__c != NULL) {
                newLead.MobilePhone = newLead.MobileCountryCode__c + newLead.MobileNumber1__c;
            }
            
            if(newLead.MobilePhone != NULL) {
                newLead.MobileNumber__c = newLead.MobilePhone;
            }
            
            newLead.PhoneNumber__c = newLead.Phone;
            // Added by Muzammil for Resale
            if(newLead.Lead_Type__c != LeadService.RESALE_LEADTYPE){    
                newLead.UniqueKey__c = UniqueKeyUtility.getUniqueKey(newLead,existinLeadUniqueKey);// Unique key with project not applicable for resale - Email;Project__c;MobilePhone  
            }
            
            newLead.UniqueKey1__c = UniqueKeyUtility.getUniqueKey(newLead,existingAccountUniqueKey);
            
            //Added by CloudzLab
            //Start of Changes
            if(String.isNotBlank(newLead.Company) && newLead.RecordTypeId!=ECSSLeadRecordType && newLead.RecordtypeId != retailLeadRecordTypeId){ // Skipping Organization Record Type Mapping condition for Retail Leads Added by Protiviti on 18 Sept 2025
                newLead.RecordTypeId = organizationRecordTypeId;
            }
            //End of Changes
            if(String.isBlank(newLead.CustomerType__c)){
                newLead.CustomerType__c = Constants.NEW_CUSTOMER;
            }
            //AM Sales Lead from Broker Portal - added by Karunakar
            //Arvind added the LeadSource as Online
            if(newLead.LeadSource != null && (newLead.LeadSource == Constants.BROKER_PORTAL || newLead.LeadSource == Constants.ONLINE_LEAD) && AMSalesProjects.contains(newLead.Project__c)) {
                newLead.Lead_Type__c = Constants.LEAD_TYPE_AM_SALE;              
            }
        }
        
        LeadService.populateAgencyAccount(newLeadList);
        LeadService.populateAgentContact(newLeadList);
        //LeadService.populateOfferRecord(newLeadList);
    }
    
    /**
* @description Method to used fetch Sales Order Unit by Ids
* @author rrangrej@aldar.com | 06/03/2025 | Story Number
* @param resaleUnitIds
* @return salesOrderByUnit
**/
    public Static Map<Id,SalesOrder__c> getSalesOrdersForUnits(Set<Id> resaleUnitIds) {
        Map<Id, SalesOrder__c> salesOrderByUnit = new Map<Id, SalesOrder__c>();
        for(SalesOrder__c so : [SELECT Id, Unit__c, Account__c FROM SalesOrder__c WHERE Unit__c IN : resaleUnitIds AND Status__c =: Constants.SO_STATUS_SOLD]){
            salesOrderByUnit.put(so.Unit__c, so);
        }
        return salesOrderByUnit;
    }
    
    /**
* @description Method to used set unique key
* @author rrangrej@aldar.com | 06/03/2025 | Story Number
* @param newLead
* @return newLead
**/
    public static Lead populateUniqueKeyForResale(Lead newLead){
        String resaleUniqueKey = '';
        resaleUniqueKey = newLead.FirstName != null ? (resaleUniqueKey + newLead.FirstName ) : resaleUniqueKey;
        resaleUniqueKey = newLead.Email != null ? (resaleUniqueKey + newLead.Email ) : resaleUniqueKey;
        resaleUniqueKey = newLead.MobilePhone != null ? (resaleUniqueKey + newLead.MobilePhone ) : resaleUniqueKey;
        resaleUniqueKey = newLead.Unit__c != null ? (resaleUniqueKey + newLead.Unit__c ) : resaleUniqueKey;
        newLead.ResaleLeadUniqueKey__c = resaleUniqueKey;
        return newLead;
    }
    
    /**
* @description Method to used for fetch existing lead by UniqueKey
* @author rrangrej@aldar.com | 06/03/2025 | Story Number
* @param uniqueKeys
* @return allLeadRecMap
**/
    public static Map<String, Lead> getExistingLeadByUniqueKey(Set<String> uniqueKeys) {
        Map<String, Lead> allLeadRecMap = new Map<String, Lead>();
        
        List<Lead> leadDetails = [SELECT firstName, MiddleName, lastName, Email, Phone, OwnerId, Status, Id, CreatedDate, UniqueKey__c, ParentLead__c, UniqueKey1__c, MobileCountryCode__c, MobileNumber1__c,Owner.IsActive,IsConverted
                                  FROM Lead WHERE (UniqueKey1__c IN : uniqueKeys OR  UniqueKey__c IN : uniqueKeys) ORDER BY createdDate ASC];
        
        for(Lead leadRec : leadDetails) {   
            if(leadRec.UniqueKey1__c != NULL) {
                allLeadRecMap.put(leadRec.UniqueKey1__c.toLowercase(), leadRec);
            }	
            
            if(leadRec.UniqueKey__c != NULL) {
                allLeadRecMap.put(leadRec.UniqueKey__c.toLowercase(), leadRec);
            }
        }
        
        return allLeadRecMap ;
    }
    /**
* @description When a lead has an existing account assign to latest Opportunity owner if available else through RR.
* When a lead has an existing lead assign to lead owner if within SLA, else to new CCA
* When a lead is new with no existin account or lead assign through Omni-Channel  
* @author rrangrej@aldar.com | 06/03/2025 | Story Number
* @param leadsForAssignment
* @param uniqueKeys
**/
    public static void assignNewLeads(List<Lead> leadsForAssignment, Set<String> uniqueKeys){
        Map<Id, Opportunity> accountOpportunityMap = new Map<Id, Opportunity>();
        Set<Id> leadsWithTask1NoCustomerResponse = new Set<Id>();
        Set<Id> opportunityOwnerIds = new Set<Id>();
        Group leadAutoDialerQueue = getGroupIdByName(Constants.LEAD_AUTO_DIALER_QUEUE);
        Group leadAgentQueue = getGroupIdByName(Constants.LEAD_AGENT_QUEUE);
        Group ADIAQUEUE = getGroupIdByName(Constants.ADIAQUEUE);
        Set<Id> leadIdsForTask = new Set<Id>();
        Map<Id, Lead> ownerWithLeadMap = new Map<Id, Lead>();
        Id brokerQueueId  = getGroupIdByName(Constants.ADIAQUEUE)?.id;
        
        //Check for existing Account based on the unique key
        if(allAccountRecMap != null && !allAccountRecMap.keySet().isEmpty()) {
            //Fetch the latest opportunity of the accounts
            Map<Id, Account> accountMap = new Map<Id, Account>(allAccountRecMap.values());
            //REF: getAllOpportunitys is rewritten with getOpportunityForAccount
            accountOpportunityMap = OpportunityService.getOpportunityForAccount(accountMap);
            if(accountOpportunityMap != NULL){
                for(Opportunity opportunityRec : accountOpportunityMap.values()){
                    opportunityOwnerIds.add(opportunityRec.OwnerId);
                }
            }
        }
        
        Map<Id, Boolean> agentsStatusMap = (!opportunityOwnerIds.isEmpty() ? RoundRobinAssignmentUtility.getAgentAvailibility(opportunityOwnerIds) : new Map<Id, Boolean>());
        
        //Check for existing Lead based on the unique key
        if(existingLeadUniquekeyMap != NULL && !existingLeadUniquekeyMap.keySet().isEmpty()) {
            for(Lead existingLead : existingLeadUniquekeyMap.values()){
                leadIdsForTask.add(existingLead.Id);
            }
            //existingLeadMap = new Map<Id,Lead>(existingLeadUniquekeyMap.values());
            //REF: Logic of existing task to be verified
            for(Task taskRec : TaskService.getTasksNumberOneRecords(leadIdsForTask)) {
                leadsWithTask1NoCustomerResponse.add(taskRec.WhoId);
            }
        }
        
        /*
* Check if the lead has existing account, else lead else Assign to Agent Queue for Omni-channel assignement
*/
        for(Lead leadRec : leadsForAssignment) {
            
            //---- If a Lead is identified as duplicate do not check for assignment
            if(leadRec.Status != Constants.DUPLICATE_LEAD) {
                
                //--- Check for existing lead and assign to current owner of the lead
                if(existingLeadUniquekeyMap != NULL && existingLeadUniquekeyMap.containsKey(leadRec.UniqueKey1__c.toLowerCase())) {
                    Lead oldLead = existingLeadUniquekeyMap.get(leadRec.UniqueKey1__c.toLowerCase());
                    
                    if (leadAutoDialerQueue != NULL && ALDAD_Validator.isAutoDialerAssigneeLead(leadRec)) {
                        leadRec.OwnerId = leadAutoDialerQueue.Id;
                        leadRec.Genesis_Auto_Dialer_Status__c = ALD_Constants.AUTO_DIALER_STATUS_INPROGRESS;
                    } else if (leadRec.LeadSource == Constants.ONLINE_LEAD && leadRec.EnquiryTrigger__c == Constants.ENQUIRY_TRIGGER && System.label.StopADIALeadQueueAssighnment=='false') {
                        if(ADIAQUEUE != NULL) {
                            leadRec.OwnerId = ADIAQUEUE.Id;
                        }
                    } else {
                        if(leadAgentQueue != NULL)
                            leadRec.OwnerId = leadAgentQueue.Id;
                    }
                }
                //dialer Queue
                if(leadAutoDialerQueue != NULL && ALDAD_Validator.isAutoDialerAssigneeLead(leadRec)) {
                    leadRec.OwnerId = leadAutoDialerQueue.Id;
                    leadRec.Genesis_Auto_Dialer_Status__c = ALD_Constants.AUTO_DIALER_STATUS_INPROGRESS;
                } else if(ADIAQUEUE != NULL && leadRec.LeadSource == Constants.ONLINE_LEAD && leadRec.EnquiryTrigger__c == Constants.ENQUIRY_TRIGGER && System.label.StopADIALeadQueueAssighnment == Constants.FALSE_STRING) {
                    leadRec.OwnerId = ADIAQUEUE.Id;
                } else {
                    if(leadAgentQueue != NULL) {
                        leadRec.OwnerId = leadAgentQueue.Id;
                    }   
                }  
            }
        }
        
        if(ownerWithLeadMap != NULL && !ownerWithLeadMap.isEmpty()) {
            Map<Id, Boolean> availableUsersMap = Utilities.isAgentAvailable(ownerWithLeadMap.keySet());
            
            for (Lead leadRec : leadsForAssignment) {
                if(ownerWithLeadMap.containsKey(leadRec.OwnerId) && !availableUsersMap.containsKey(leadRec.OwnerId) && leadRec.OwnerId.getsobjecttype() == User.sobjecttype){
                    //dialer Queue
                    if(leadAutoDialerQueue != NULL && ALDAD_Validator.isAutoDialerAssigneeLead(leadRec)) {
                        leadRec.OwnerId = leadAutoDialerQueue.Id;
                        leadRec.Genesis_Auto_Dialer_Status__c = ALD_Constants.AUTO_DIALER_STATUS_INPROGRESS;
                    } else if (ADIAQUEUE != NULL && leadRec.LeadSource == Constants.ONLINE_LEAD && leadRec.EnquiryTrigger__c == Constants.ENQUIRY_TRIGGER && System.label.StopADIALeadQueueAssighnment == Constants.FALSE_STRING) {
                        leadRec.OwnerId = ADIAQUEUE.Id;
                    } else {
                        if(leadAgentQueue != NULL) {
                            leadRec.OwnerId = leadAgentQueue.Id;
                        }  
                    }
                }
            }
        }
    }
    
    /**
* @description Method to used for Lead assignment
* @author rrangrej@aldar.com | 06/03/2025 | Story Number
* @param leadsForAssignment List<Lead>
**/
    public static void assignResaleLeads(List<Lead> leadsForAssignment){
        Set<Id> unitIds = new Set<Id>();
        
        for(Lead leadRec : leadsForAssignment) {
            if(leadRec.Unit__c != NULL) {
                unitIds.add(leadRec.Unit__c);
            } else {
                leadRec.AssignToRoundRobin__c = TRUE;
            }
        }
        
        if(!unitIds.isEmpty()) {
            Map<Id, Case> CaseByUnitId = new Map<Id, Case>();
            
            for(Case resaleCase : [SELECT Id,OwnerId,Unit__c FROM Case WHERE RecordType.DeveloperName =: Constants.CASE_RECORD_TYPE_RESALE AND Unit__c IN: unitIds AND Owner.isActive = TRUE ORDER BY CreatedDate DESC ]) {
                if(!CaseByUnitId.containsKey(resaleCase.Unit__c)) {
                    CaseByUnitId.put(resaleCase.Unit__c, resaleCase);
                }
            }
            
            for(Lead leadRec : leadsForAssignment) {
                if(CaseByUnitId.containsKey(leadRec.Unit__c)) {
                    leadRec.OwnerId = CaseByUnitId.get(leadRec.Unit__c).OwnerId;
                } else {
                    leadRec.AssignToRoundRobin__c = TRUE;
                }
            }
        }
    }
    
    /**
* @description Method to used for fetch leads by phone number and Email
* @author rrangrej@aldar.com | 06/03/2025 | Story Number
* @param emailSet Set<String>
* @param phoneSet Set<String>
* @return List<Lead>
**/
    public static Map<Id, Lead> fetchOldLeadData(Set<String> emailSet, Set<String> phoneSet) {
        Map<Id, Lead> leadData = new Map<Id, Lead>([SELECT Id, Email, Owner.Email, DuplicateLeadOwner__c, ExistingLeadOwner__c, MobilePhone, LeadSource, Referral_Customer_Unit__c, Owner.IsActive, Owner.Profile.Name, LeadNumber__c FROM Lead WHERE 
                                                    ((CreatedDate = LAST_N_days:90) AND (Email IN :emailSet OR MobilePhone IN :phoneSet)) AND Lead_Type__c =: LeadService.NEWSALE_LEADTYPE ORDER BY CreatedDate DESC]);
        return leadData;
    }
    
    /**
* @description Method to used for fetch Opportunity records
* @author rrangrej@aldar.com | 06/03/2025 | Story Number
* @param emailSet Set<String>
* @param phoneSet Set<String>
* @return List<Lead>
**/
    public static List<Opportunity> fetchOpportunityData(Map<String, Lead> leadMap) {
       List<Opportunity> queriedAccounts = new List<Opportunity>([SELECT Id, AccountId, Account.Email__c, Account.MobileNumber__c, Account.PersonEmail, Account.PersonMobilePhone FROM Opportunity 
                                                                       Where ((CreatedDate = LAST_N_days:90 AND CreatedDate > 2022-08-09T00:00:00.000+00:00) 
                                                                              AND (Account.PersonEmail IN :leadMap.keySet() OR 
                                                                                   Account.PersonMobilePhone IN :leadMap.keySet() OR 
                                                                                   Account.MobileNumber__c IN :leadMap.keySet() OR 
                                                                                   Account.Email__c IN :leadMap.keySet())) ORDER BY CreatedDate DESC]);
        return queriedAccounts;
    }
    
    
    /**
* @description Method to used Check for Duplicate and populate parent Lead
* @author rrangrej@aldar.com | 06/03/2025 | Story Number
* @param List<Lead> newList
* @param Set<String> uniqueKeys
**/
    public static void duplicateAndParenLead(List<Lead> newList, Set<String> uniqueKeys) {
        existingLeadUniquekeyMap = LeadTriggerHelper.getExistingLeadByUniqueKey(uniqueKeys);
        Group leadDuplicateQueue = getGroupIdByName(Constants.LEAD_DUPLICATE_QUEUE);
        //*Added by cloudzlab*//
         String ECSSLabelRecordType = System.Label.ECSS_LeadRecordType_AlDarEstate;
         Id ECSSrecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(ECSSLabelRecordType).getRecordTypeId();  
        //End by Cloudzlab//
        
        //Check for Duplicate Lead
        for(Lead leadRec : newList) {
            //added a check by Himanshu@Aldar to exclude P & I leads 
            if(leadRec.recordtypeId == PI_Services.p_IRecordTypeId){
                continue;
            }
            
            if(leadRec.Lead_Type__c != LeadService.RESALE_LEADTYPE && existingLeadUniquekeyMap != NULL && (existingLeadUniquekeyMap.containsKey(leadRec.UniqueKey__c.toLowerCase()) || existingLeadUniquekeyMap.containsKey(leadRec.UniqueKey1__c.toLowerCase()))){
                //Get the existing Lead and populate parent lead
                Lead existingLead = (existingLeadUniquekeyMap.containsKey(leadRec.UniqueKey__c.toLowerCase()) ? existingLeadUniquekeyMap.get(leadRec.UniqueKey__c.toLowerCase()) : existingLeadUniquekeyMap.get(leadRec.UniqueKey1__c.toLowerCase()));
                
                if(existingLead.ParentLead__c == NULL){
                    leadRec.ParentLead__c = existingLead.Id;
                } else if(existingLead.ParentLead__c != NULL) {
                    leadRec.ParentLead__c = existingLead.ParentLead__c ;
                }
                
                if(!leadRec.InitiateDigitalBooking__c && leadRec.recordtypeId != ECSSrecordTypeId && leadDuplicateQueue!= NULL && leadRec.NotForAssignment__c == FALSE && existingLead.CreatedDate > Datetime.now().addHours(-integer.valueof(System.label.DuplicateLeadHours)) && !existingLead.IsConverted && existingLeadUniquekeyMap.containsKey(leadRec.UniqueKey__c.toLowerCase())){
                    leadRec.OwnerId = leadDuplicateQueue.Id ;
                    leadRec.Status = Constants.DUPLICATE_LEAD;
                }    
            }
            
            //Populate if there is an existing account so during conversion the opportunity can be associated to the same lead
            /*if(allAccountRecMap!=null && allAccountRecMap.containsKey(leadRec.UniqueKey1__c.toLowerCase())) {
Account existAccount = allAccountRecMap.get(leadRec.UniqueKey1__c.toLowerCase());
Id accountId = existAccount.Id;
                
//Bypassing the logic for organization lead
//Org Account - Skip Duplicate/Existing Accout  
if(leadRec.RecordTypeId != Schema.getGlobalDescribe().get(Constants.LEAD_OBJECT).getDescribe().getRecordTypeInfosByDeveloperName().get(Constants.ORGANIZATION_LEAD_RECORD_TYPE_Name).getRecordTypeId()) {
leadRec.ExistingAccount__c = accountId;
}
                
leadRec.CustomerType__c = Constants.EXISTING_CUSTOMER;
                
if(leadRec.SalesOrigin__c == Constants.SALES_ORIGIN_DOMESTIC && leadRec.EnquiryCategory__c != Constants.LEAD_ENQUIRY_CATEGORY_WEALTH && leadRec.EnquiryCategory__c != Constants.LEAD_ENQUIRY_CATEGORY_CORPORATE) {
leadRec.CustomerSubType__c = Constants.CUSTOMER_SUB_TYPE_DOMESTIC;
} else {
leadRec.CustomerSubType__c = Constants.CUSTOMER_SUB_TYPE_INTERNATIONAL;
}
} */
        }
    }
}