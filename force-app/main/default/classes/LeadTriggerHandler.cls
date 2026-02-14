public without sharing class LeadTriggerHandler extends TriggerHandler {
    
    public static User userDetail = Utilities.getLoggedInUserDetail();
    public static Map<String,Lead> existingLeadUniquekeyMap ;
    public static Map<String,Account> allAccountRecMap ;
    public static String Resale_Relationship_Manager = 'Resale Relationship Manager';
    public static Map<Id,Id> pers;
    
    public static Boolean isLeadInvolve = false;
    //Group leadAutoDialerQueue = Utilities.getQueueInformation(Constants.LEAD_AUTO_DIALER_QUEUE);
    //Group leadOptionsUpgradeQueue = Utilities.getQueueInformation(Constants.LEAD_OU_QUEUE);
    //Group leadLogisticsQueue = Test.isRunningTest() ? null:Utilities.getQueueInformation('Logistics Queue');
    
    //*** Before Insert Action***//
    public override void beforeInsertMethod(list<SObject> newList,map<ID,SObject> newMap){
        
        isLeadInvolve = true;
        List<Lead> newLeadList = (List<Lead>)newList;
        Set<Id> accountIds = new Set<Id>();
        Set<Id> resaleUnitIds = new Set<Id>();
        Map<Id, SalesOrder__c> salesOrderByUnit = new Map<Id, SalesOrder__c>();
        Map<String, Lead> existingLeadsByUniqueKey = new Map<String, Lead>();
        LeadTriggerHelper leadHelper = new LeadTriggerHelper();
        List<Lead> resaleLeadsForAssignment = new List<Lead>();
        String userProfileName = LeadTriggerHelper.userDetail.ProfileName__c;
        List<String> profilesNamesWithoutAssignment = System.label.AssignmentBasedOnProfileName.split(';');
        List<String> sourcesWithoutAssignemnt = System.label.NoAssignmentLeadSources.split(';');
        List<Lead> leadsForAssignment = new List<Lead>();
        Set<String> emailSet = new Set<String>();
        Set<String> phoneSet = new Set<String>();
        Map<Id, Lead> oldLeadDataMap = new Map<Id, Lead>();
        Map<String, ID> oldLeadMap = new Map<String, ID>();
        Map<String, Lead> leadMap = new Map<String, Lead>();
        List<String> bypassProfile = System.label.LeadTriggerBypassProfiles.split(',');
		Map<Id, Id> permissionSetMap = new Map<Id, Id>();
        Map<Id, Account> accountMap = new Map<Id, Account>();
        Set<String> uniqueKeys = new Set<String>();
        
        List<Lead> ECSS_newList = new List<Lead>();
        List<Lead> updatedNewList = new List<Lead>();
        Map<Id,Lead> ECSS_newMap = new Map<Id,Lead>();
        Set<String> ECSS_uniqueKeys = new Set<String>();
        String ECSSLabelRecordType = System.Label.ECSS_LeadRecordType_AlDarEstate;
        Id recordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(ECSSLabelRecordType).getRecordTypeId();  
        List<String> existingAccountUniqueKey = Utilities.getUniqueKeyMapping(Constants.LEAD_ACCOUNT_UNIQUE_KEYS).Values__c.split(';');
        List<String> existinLeadUniqueKey = Utilities.getUniqueKeyMapping(Constants.LEAD_UNIQUE_KEYS).Values__c.split(';');
        
        for (Lead newLead : (List<Lead>)newList) {
             //Added by Tajinkumar for Skipping Digital Sales Lead
            /* if(newLead.InitiateDigitalBooking__c){
                continue;
            }*/
            
            if (newLead.recordtypeId == recordTypeId) {
                ECSS_newList.add(newLead);
                newLead.UniqueKey1__c = UniqueKeyUtility.getUniqueKey(newLead, existingAccountUniqueKey);
                newLead.UniqueKey__c = UniqueKeyUtility.getUniqueKey(newLead, existinLeadUniqueKey);// Unique key with project not applicable for resale - Email;Project__c;MobilePhone  
                ECSS_uniqueKeys.add(newLead.UniqueKey1__c);
                ECSS_uniqueKeys.add(newLead.UniqueKey__c);
            } else {
                updatedNewList.add(newLead);
            }
        }
        
        if (ECSS_uniqueKeys != null && ! ECSS_uniqueKeys.isEmpty()){
            //Check for existing Account based on the unique key
            allAccountRecMap = AccountService.getAllAccounts(ECSS_uniqueKeys);
            LeadTriggerHelper.duplicateAndParenLead(ECSS_newList,ECSS_uniqueKeys);
        }
        
        newList = updatedNewList;
        //--------ECSS call the before insert methods -------       
        if(ECSS_newList != null){
            ECSS_LeadTriggerHelper.verifyPhoneNumbers((List<Lead>)ECSS_newList, null);
        }
        //--------------------------------------------------------------------------------------------------------//
        
        for(Lead newLead : (List<Lead>)newList) {
            //Added for exclude P & I Leads 
            if(newLead.recordtypeId == PI_Services.p_IRecordTypeId) {
                continue;
            }
            
             //Added by Tajinkumar for Skipping Digital Sales Lead
             /*if(newLead.InitiateDigitalBooking__c){
                continue;
            }*/
            
            // Make New sale lead type default
            if(String.isBlank(newLead.Lead_Type__c)) {
                newLead.Lead_Type__c = Constants.LEAD_TYPE_NEW_SALE;
            }
            
            if (String.isNotBlank(newLead.ExistingAccount__c) && newLead.IsCreateFromExistingAccount__c) {
                accountIds.add(newLead.ExistingAccount__c);
                newLead.EmailAddress__c = newLead.Email;
                newLead.MobileNumber__c = newLead.MobileNumber1__c;
            }
            
            if(String.isNotBlank(newLead.Unit__c)) {
                // Collecting unit ids for pre-populating sales order
                resaleUnitIds.add(newLead.Unit__c);
            }
            
            if(leadHelper.leadLogisticsQueue != null && newLead.Lead_Type__c == Constants.LEAD_TYPE_LOGISTICS) {
                newLead.OwnerId = leadHelper.leadLogisticsQueue.Id;
            }
        }
        
        if(!accountIds.isEmpty()) {
        	accountMap = LeadTriggerHelper.fetchNonMergedAccounts(accountIds);
        }
        
        //fast field updates
        LeadTriggerHelper.populateBeforeCommit(newLeadList);
        
        if(!resaleUnitIds.isEmpty()) {
            // Fetching sales orders to default sales order on lead based on unit.
            salesOrderByUnit = LeadTriggerHelper.getSalesOrdersForUnits(resaleUnitIds);
            // Fetching existing leads for duplicate
            DateTime duplicateLeadHours = Datetime.now().addHours(-integer.valueof(System.label.DuplicateLeadHours));
            for(Lead existingLead : [SELECT ID, Email, MobilePhone, Unit__c, CreatedDate, IsConverted, ResaleLeadUniqueKey__c FROM Lead WHERE Unit__c IN :resaleUnitIds AND Status !=: Constants.RETIRED AND Status !=: Constants.DUPLICATE_LEAD AND IsConverted = FALSE AND CreatedDate >: duplicateLeadHours ORDER BY Createddate DESC]) {
                existingLeadsByUniqueKey.put(existingLead.ResaleLeadUniqueKey__c, existingLead);
            }
        }
        
        SystemMessages__mdt salesOrderErrorMessage = Utilities.getSystemMessages(Constants.NO_SALES_ORDER_ERROR);
        
        for(Lead newLead : newLeadList) {
            //added a check by Himanshu@Aldar to exclude P & I leads 
            if(newLead.recordtypeId == PI_Services.p_IRecordTypeId) {
                continue;
            }
            
             //Added by Tajinkumar for Skipping Digital Sales Lead
            /* if(newLead.InitiateDigitalBooking__c){
                continue;
            }*/
            
            if (String.isNotBlank(newLead.ExistingAccount__c) && newLead.IsCreateFromExistingAccount__c && accountMap.containsKey(newLead.ExistingAccount__c)) {
                Account acc = accountMap.get(newLead.ExistingAccount__c);
                if(Constants.PERSON_LEAD_RECORD_TYPE_NAME == Schema.getGlobalDescribe().get(Constants.LEAD_OBJECT).getDescribe().getRecordTypeInfosById().get(newLead.RecordTypeId).getName()) { 
                    newLead.EmailAddress__c = acc.PersonEmail;
                    newLead.MobileNumber__c = acc.MobilePhone__pc;                    
                } else { 
                    newLead.EmailAddress__c = acc.Email__c;
                    newLead.MobileNumber__c = acc.MobileNumber1__c;                   
                }
            }
            
            if(newLead.Unit__c != NULL && newLead.Lead_Type__c == Constants.LEAD_TYPE_RESALE) {
                if(salesOrderByUnit.containsKey(newLead.Unit__c)) {
                    newLead.Sales_Order__c = salesOrderByUnit.get(newLead.Unit__c).Id;
                } else {
                    newLead.addError(salesOrderErrorMessage.Message__c);
                }
                
                newLead =  LeadTriggerHelper.populateUniqueKeyForResale(newLead); 
                
                if(!newLead.InitiateDigitalBooking__c && leadHelper.leadDuplicateQueue != NULL && existingLeadsByUniqueKey.containsKey(newLead.ResaleLeadUniqueKey__c)) {
                    newLead.OwnerId = leadHelper.leadDuplicateQueue.Id ;
                    newLead.Status = Constants.DUPLICATE_LEAD;
                }
            }
            
            if(leadHelper.leadOptionsUpgradeQueue != NULL && newLead.Lead_Type__c == Constants.LEAD_TYPE_OPTIONS_AND_UPGRADES) {
                newLead.OwnerId = leadHelper.leadOptionsUpgradeQueue.Id;
            }
            //Modified by CloudzLab
            //To exclude the ECSS Lead Record Type
            if(newLead.PropertyUsage__c != NULL && newLead.PropertyUsage__c.equals(Constants.RESIDENTIAL_LEASE) && newLead.RecordTypeId !=recordTypeId) {
                newLead.OwnerId = leadHelper.leadAssetsManagementQueue.Id;
                newLead.Status = Constants.CLOSED;
            } else {
                // Added by Arvind for resale
                if(userProfileName.equals(Constants.SALES_MANAGER) || userProfileName.equals(Constants.RESALE_RELATIONSHIP_MANAGER)) {
                    newLead.CustomerContactedBySM__c = TRUE ;
                }

                Id retailLeadRecordTypeId = LeadTriggerHelper.getRetailLeadRecordTypeId();
                //Check if lead assignment is applicable
                if((newLead.Lead_Type__c == Constants.LEAD_TYPE_NEW_SALE || newLead.Lead_Type__c == Constants.LEAD_TYPE_AM_SALE) 
                    && !profilesNamesWithoutAssignment.contains(userProfileName) 
                    && !newLead.ExemptFromAssignment__c && !sourcesWithoutAssignemnt.contains(newLead.LeadSource) 
                    && newLead.OwnerId != leadHelper.leadBrokerQueue?.Id && newLead.AssignToRoundRobin__c == FALSE 
                    && newLead.RecordTypeId != retailLeadRecordTypeId){
                    leadsForAssignment.add(newLead);
                } else if(newLead.Lead_Type__c == Constants.LEAD_TYPE_RESALE && !profilesNamesWithoutAssignment.contains(userProfileName) && !newLead.ExemptFromAssignment__c && !sourcesWithoutAssignemnt.contains(newLead.LeadSource) && newLead.OwnerId != leadHelper.leadBrokerQueue?.Id && newLead.AssignToRoundRobin__c == FALSE){
                    resaleLeadsForAssignment.add(newLead);
                } else {
                    newLead.NotForAssignment__c = TRUE ;
                }
            }
            
            if(newLead.Lead_Type__c == Constants.LEAD_TYPE_NEW_SALE) {
                if(String.isNotBlank(newLead.Email)) {
                    emailSet.add(newLead.Email);
                }
                
                if(String.isNotBlank(newLead.MobilePhone)) {
                    phoneSet.add(newLead.MobilePhone);
                }
            }
            
            uniqueKeys.add(newLead.UniqueKey1__c);
            // Added by Muzammil for resale
            if(newLead.Lead_Type__c != LeadService.RESALE_LEADTYPE){
                uniqueKeys.add(newLead.UniqueKey__c);
            }
        }
        
        //uniqueKeys not empty
        if (!uniqueKeys.isEmpty()) {
            //Check for Duplicate and Existing Leads 
            LeadTriggerHelper.duplicateAndParenLead(newList, uniqueKeys);
        }
        
        if(leadsForAssignment != null && leadsForAssignment.size() > 0 ) {
            System.debug('**leadsForAssignment**'+leadsForAssignment);
            LeadTriggerHelper.assignNewLeads(leadsForAssignment,uniqueKeys);
        }
        
        if(resaleLeadsForAssignment != null && !resaleLeadsForAssignment.isEmpty()) {
            LeadTriggerHelper.assignResaleLeads(resaleLeadsForAssignment);
        }
        
        if(!emailSet.isEmpty() || !phoneSet.isEmpty()) {   
       		oldLeadDataMap = LeadTriggerHelper.fetchOldLeadData(emailSet, phoneSet);
        }
        
        if(!oldLeadDataMap.isEmpty()) { 
            for(Lead l : oldLeadDataMap.values()) {
                if(!oldLeadMap.containsKey(l.email)) {
                    oldLeadMap.put(l.email, l.id);
                }
                
                if(!oldLeadMap.containsKey(l.MobilePhone)) {
                    oldLeadMap.put(l.MobilePhone, l.id);
                }
            }
        }
        
        for(Lead leadRec : newLeadList) {
        	 //Added by Tajinkumar for Skipping Digital Sales Lead
             if(leadRec.InitiateDigitalBooking__c){
                continue;
            }
            
            if(!oldLeadMap.isEmpty()) {
            	if(oldLeadMap.containsKey(leadRec.email) || oldLeadMap.containsKey(leadRec.MobilePhone)) {
                    leadRec.Duplicate_Lead__c = true;
                    leadRec.ExistingLead__c = oldLeadMap.containsKey(leadRec.email) ? oldLeadMap.get(leadRec.email) : oldLeadMap.get(leadRec.MobilePhone);
                    Lead oldLead = oldLeadMap.containsKey(leadRec.email) ? oldLeadDataMap.get(oldLeadMap.get(leadRec.Email)) : oldLeadDataMap.get(oldLeadMap.get(leadRec.MobilePhone));
                    String ownerId = oldLead.Owner.Id;
                    
                    if(ownerId!= NULL && ownerId.startsWithIgnoreCase(Constants.USER_START_THREE_ID_DIGIT)) {
                        leadRec.ExistingLeadOwner__c = oldLead.Owner.Id;                    
                    }
                    // Stopped the Existing Lead Assignment 
                  /* if(leadRec.Sodic_Lead_1__c == FALSE && leadRec.Lead_Project_Group__c != Constants.LEAD_GROUP_TYPE_LSQ && leadRec.EnquiryCategory__c != Constants.LEAD_ENQUIRY_CATEGORY_ALDAR_SELECT && !userProfileName.equals(Constants.SALES_MANAGER) && leadRec.SalesType__c != Constants.ASSET_MANAGEMENT && leadRec.RecycledLead__c != TRUE && !userProfileName.equals(Constants.RESALE_RELATIONSHIP_MANAGER) && !userProfileName.equals(Constants.CONTACT_CENTER_MANAGER) && !userProfileName.equals(Constants.CONTACT_CENTER_AGENT) && leadRec.LeadSource!= Constants.WALK_IN && leadRec.LeadSource != Constants.BROKER_PORTAL && oldLead.LeadSource != Constants.BROKER_PORTAL && oldLead.OwnerID != NULL && oldLead.Owner.Profile != NULL && oldLead.Owner.Profile.Name == Constants.SALES_MANAGER && oldLead.Owner.IsActive == TRUE)
                     {
                       leadRec.OwnerID = oldLead.OwnerId;
                    }*/
                }
            }
        }

        if(!bypassProfile.contains(userProfileName)) {
            permissionSetMap = LeadTriggerHelper.permissionSetCMHOMEMap;
        }
        
        for(Lead l : (List<Lead>)newList) {
            if(l.Lead_Type__c == Constants.LEAD_TYPE_NEW_SALE && l.Email != NULL && !leadMap.containsKey(l.Email) && l.MobilePhone != NULL && !leadMap.containsKey(l.MobilePhone)) {
                leadMap.put(l.Email, l);
                leadMap.put(l.MobilePhone, l);
            }
            
            if(leadHelper.leadDefaultQueue != NULL && permissionSetMap != NULL && permissionSetMap.get(LeadTriggerHelper.userDetail.Id) != NULL && l.Lead_Type__c == Constants.LEAD_TYPE_RESALE) { //InitiateResaleListingProfilesList.contains(userDetail.Profile.Name) 
                l.ownerID = leadHelper.leadDefaultQueue.Id;
            }
        }
        
        if(!leadMap.isEmpty()) {
            List<Opportunity> queriedAccounts = LeadTriggerHelper.fetchOpportunityData(leadMap);
            
            if(!queriedAccounts.isEmpty()) {
                Map<String, Id> matchingAccounts = new Map<String, Id>();
                
                for(Opportunity con : queriedAccounts) {
                    if(!matchingAccounts.containsKey(con.Account.PersonEmail)) {
                        matchingAccounts.put(con.Account.PersonEmail, con.AccountId);
                    }
                    
                    if(!matchingAccounts.containsKey(con.Account.PersonMobilePhone)) {
                        matchingAccounts.put(con.Account.PersonMobilePhone, con.AccountId);
                    }
                    
                    if(!matchingAccounts.containsKey(con.Account.MobileNumber__c)) {
                        matchingAccounts.put(con.Account.MobileNumber__c, con.AccountId);
                    }
                    
                    if(!matchingAccounts.containsKey(con.Account.Email__c)) {
                        matchingAccounts.put(con.Account.Email__c, con.AccountId);
                    }
                }
                
                if(!matchingAccounts.isEmpty()) {
                    for(Lead l2 : newLeadList) {
                        //Added by Tajinkumar for Skipping Digital Sales Lead
                        if(l2.InitiateDigitalBooking__c){
                            continue;
                        }
                        
                        if(matchingAccounts.containsKey(l2.Email) || matchingAccounts.containsKey(l2.MobilePhone)) {
                            l2.NewExisAccount__c = matchingAccounts.containsKey(l2.Email) ? matchingAccounts.get(l2.Email) : matchingAccounts.get(l2.MobilePhone);
                            l2.Duplicate_Lead__c = TRUE;
                            l2.Duplicate_from_Account__c = TRUE;
                        }
                    }
                }
            }
        }
    }
    
    //*** After Insert Action***//
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap){
        isLeadInvolve = true;
        LeadTriggerHelper leadHelper = new LeadTriggerHelper();
        List<Lead> PILeadList = new List<Lead>();//added by Himanshu@Aldar to collect P & I leads
        Map<Id,Lead> leadToBeAssignedThroughRR = new Map<Id,Lead>();
        //Harsh@Aldar if resale case is populated on insert, make sure related unit and related data is populated
        //List<Lead> leadWithResaleUnitCaseList = new List<Lead>();
        //dialer Queue
        Set<Id> leadTosendGenesis=new Set<Id>();
        Set<Id> leadIdFacebook = new Set<Id>();
        List<Lead> FastTrackLeadList = new List<Lead>();
        List<LeadShare> leadShareList = new List<LeadShare>();
        //----Check if there lead need to be assigned via RR
        List<Campaign_member_Custom__c> newCampaignMembers = new List<Campaign_member_Custom__c>();
        Map<String, String> mapAccountWithContact = new Map<String, String>();
        Set<Id> accountIds = new Set<Id>();
        Set<String> ProjectNames = new Set<String>();
        Map<String,Id> ProjectNameMap = new Map<String,Id>();
        Map<String,Id>AccMap = new Map<String,Id>();
        
        // -------ECSS Variables --------------
        List<Lead> ECSS_newList = new List<Lead>();
        List<Lead> updatedNewList = new List<Lead>();
        Map<Id,Lead> ECSS_newMap = new Map<Id,Lead>();
        String ECSSLabelRecordType = System.Label.ECSS_LeadRecordType_AlDarEstate;
        Id recordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(ECSSLabelRecordType).getRecordTypeId();  
        
        //--------ECSS Loop to separate ECSS Records from the remaining records -------       
        System.debug('new List Before: '+(List<Lead>)newList);
        for (Lead newLead : (List<Lead>)newList) {
            if (newLead.recordtypeId == recordTypeId) {
                ECSS_newList.add(newLead);
            }
            else{
                updatedNewList.add(newLead);
            }
        }	
        newList = updatedNewList;
        System.debug('new List After: '+(List<Lead>)newList);
        //--------ECSS call the after insert methods -------       
        if(ECSS_newList != null){
            ECSS_newMap = new Map<Id,Lead>(ECSS_newList);
            ECSS_LeadTriggerHelper.LeadRotation (ECSS_newList,false);
        }
        //--------------------------------------------------------------------------------------------------------//
        
        //Added by Chirag Digital Booking
        List<SendFasttrackWhatsaAppLink.FlowInputs> inputs 	= new List<SendFasttrackWhatsaAppLink.FlowInputs>();
        List<SendFasttrackWhatsaAppLink.FlowOutputs> output;
        
        
        // ASF - 3152
        list<string> BypassProfile = System.label.LeadTriggerBypassProfiles.split(',');
        if(!BypassProfile.contains(userDetail.profile.Name)) {
            pers = ResaleService.getPermissionAssignedMap('CM_Home_PermissionSet');
        }
        
        for(Lead leadRec : (list<Lead>) newList){
            //added a check by Himanshu@Aldar to exclude P & I leads 
            if(leadRec.recordtypeId == PI_Services.p_IRecordTypeId){
                PILeadList.add(leadRec);
                continue;
            }
            //ASF - 3152
            
            
            if(pers != null && pers.get(userDetail.Id) != null && leadRec.Lead_Type__c == 'Resale'){ //InitiateResaleListingProfilesList.contains(userDetail.Profile.Name) 
                LeadShare  shareLead = new LeadShare();shareLead.LeadId = leadRec.Id;shareLead.UserOrGroupId = userDetail.Id;shareLead.LeadAccessLevel = 'read';shareLead.RowCause = Schema.LeadShare.RowCause.Manual;leadShareList.add(shareLead);
                
            }
            if(leadRec.AssignToRoundRobin__c && leadRec.Lead_Type__c !='Logistics')
            {
                leadToBeAssignedThroughRR.put(leadRec.Id,leadRec);
            }
            //Harsh@Aldar When Lead is populated with Resale Unit case, update the corresponding Unit and Account on the Lead
            //Done to make sure Case number can be used as Unit Id thus ensuring unit has internal access only
            /*if(leadRec.Resale_Unit_Case__c != null){
leadWithResaleUnitCaseList.add(leadRec);
}*/
            //dialer Queue
            if(leadRec.OwnerId ==leadHelper.leadAutoDialerQueue.Id)
            {
                leadTosendGenesis.add(leadRec.Id);
                System.debug('Auto Dialer Batch Input Preparing :: '+leadRec.OwnerId);
                
            }
            
            // Arvind ASF-1264
            if(leadRec.LeadSource != null && leadRec.LeadSource == 'Online' &&  (leadRec.MobileCountryCode__c != '+7' || leadRec.MobileCountryCode__c != '7') )
            { 
                leadIdFacebook.add(leadRec.Id);
                system.debug('leadIdFacebookInsidethelpp---'+leadIdFacebook);
            }
            
            //Karunakar - Fasttrack Leads
            if(leadRec.LeadSource != null && leadRec.LeadSource == Constants.BROKER_PORTAL && leadRec.recordtypeId == Constants.PERSON_LEAD_RT_ID){
                FastTrackLeadList.add(leadRec);
            }
        }
        if(!leadShareList.isEmpty()){
            insert leadShareList;
        }
        //Harsh@Aldar When Lead is populated with Resale Unit case, update the corresponding Unit and Account on the Lead
        //Done to make sure Case number can be used as Unit Id thus ensuring unit has internal access only
        /*if(leadWithResaleUnitCaseList.size() > 0){
ResaleUnitService.handleCasePopulationOnResaleLead(leadWithResaleUnitCaseList);
}*/
        leadToBeAssignedThroughRR = new map<id,Lead>([Select Id, OwnerId, AssignToRoundRobin__c, LeadNumber__c From Lead Where Id in : leadToBeAssignedThroughRR.keySet()]);
        
        if(!leadToBeAssignedThroughRR.isEmpty())
        {
            leadToBeAssignedThroughRR = RoundRobinAssignmentUtility.getAgentAssignment(leadToBeAssignedThroughRR);
            
        }
        update leadToBeAssignedThroughRR.values();
        
        
        
        //---- to share lead record with Broker Agency Account Owner.
        ShareHelper.shareLeadRecord(newList, Constants.EDIT_ACCESS);
        if(!leadTosendGenesis.isEmpty()){
            //dialer Queue
            GenesisAutoDialerBatch genesisBatchObj=new GenesisAutoDialerBatch(leadTosendGenesis);
            ID batchprocessid = Database.executeBatch(genesisBatchObj,1);
            System.debug('GenesisAutoDialerBatch batchprocessid'+batchprocessid);
        }
        // Arvind ASF-1264
        if(!leadIdFacebook.isEmpty()){
            LeadPhoneValidationBatch batch = new LeadPhoneValidationBatch(leadIdFacebook);
            Database.executeBatch(batch, 1); // The batch size is set to 1 here.
        }
        
        //Document generation on lead update aded by Himanshu@Aldar
        if(!PILeadList.isEmpty()){
            PI_Services.createDocumentForPandILead(PILeadList);
        }
        
        //Update Lead Account for Fatstrack - added by Karunakar
        if(!FastTrackLeadList.isEmpty()){
            LeadFastTrackAccountService.updateBrokerLeads(FastTrackLeadList);
        }
        if(!Test.isRunningTest()){
            if(System.label.StopCampaignMember=='false')            {
                CampaignMemberController.createCampaignMember(newList);
            }
            
        }
        
        //Digital Sales By Chirag
        for(Lead leadRec : [SELECT Id,Name,RecordType.Name,ExistingAccount__c,Project__c,Sales_Order__c,Unit__c,InitiateDigitalBooking__c
                            FROM Lead WHERE Id=:newList AND Lead_Project_Group__c != 'LSQ']){
                                //Added by Chirag Digital Booking
                                if(leadRec.InitiateDigitalBooking__c == true || Test.isRunningTest()){
                                    SendFasttrackWhatsaAppLink.FlowInputs input = new SendFasttrackWhatsaAppLink.FlowInputs();
                                    
                                    input.category								= 'Booking';
                                    input.accountId								= leadRec.ExistingAccount__c;
                                    input.brokerAccountId						= null;
                                    input.brokerContactId						= null;
                                    input.project								= leadRec.Project__c;
                                    input.salesOrderId							= leadRec.Sales_Order__c;
                                    input.sourceType							= 'Sales Manager';
                                    input.status								= 'Link Sent';
                                    input.sourceType							= 'Damascus';
                                    input.UnitId                                  = leadRec.Unit__c;
                                    input.LeadId                                  = leadRec.Id;
                                    inputs.add(input);
                                }
                            }
        //Added by Chirag Digital Booking
        if(inputs != null && !inputs.isEmpty() && !Test.isRunningTest()) {
            System.debug('TestCHirag'+inputs);
            output = SendFasttrackWhatsaAppLink.createDigitalExpRecord(inputs);
        }
    }
    
    
    //*** Before Update Action***//
    public override void beforeUpdateMethod(list<SObject> newList,map<Id,SObject> newmap,list<SObject> oldlist,map<Id,SObject> oldmap) {
        isLeadInvolve = true;
        boolean runTrigger = true;
        Set<Id> updatedUnitIds = new Set<Id>();
        Map<Id,SalesOrder__c> salesOrderByUnit = new Map<Id,SalesOrder__c>();
        
        // -------ECSS Variables --------------
        List<Lead> ECSS_newList = new List<Lead>();
        List<Lead> updatedNewList = new List<Lead>();
        Map<Id,Lead> ECSS_newMap = new Map<Id,Lead>();
        Set<String> ECSS_uniqueKeys = new Set<String>();
        List<Lead> beforeComit = new List<Lead>();
        String ECSSLabelRecordType = System.Label.ECSS_LeadRecordType_AlDarEstate;
        Id recordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(ECSSLabelRecordType).getRecordTypeId();  
        List<String> existinLeadUniqueKey = Utilities.getUniqueKeyMapping(Constants.LEAD_UNIQUE_KEYS).Values__c.split(';');
        List<String> existingAccountUniqueKey = Utilities.getUniqueKeyMapping(Constants.LEAD_ACCOUNT_UNIQUE_KEYS).Values__c.split(';');
        
        //--------ECSS Loop to separate ECSS Records from the remaining records -------       
        System.debug('new List Before: '+(List<Lead>)newList);
        for (Lead newLead : (List<Lead>)newList) {
            if (newLead.recordtypeId == recordTypeId) {
                ECSS_newList.add(newLead);
                String oldEmail = ((Lead) oldMap.get(newLead.Id)).Email;
                System.debug('oldEmail:'+oldMap.get(newLead.Id));
                if(newLead.Email != oldEmail ){
                    newLead.UniqueKey1__c = UniqueKeyUtility.getUniqueKey(newLead,existingAccountUniqueKey);
                    newLead.UniqueKey__c = UniqueKeyUtility.getUniqueKey(newLead,existinLeadUniqueKey);// Unique key with project not applicable for resale - Email;Project__c;MobilePhone  
                    ECSS_uniqueKeys.add(newLead.UniqueKey1__c);
                    ECSS_uniqueKeys.add(newLead.UniqueKey__c);
                    newLead.ParentLead__c = null;
                    System.debug('in the before commit');
                    beforeComit.add(newLead);
                }
            }
            else{
                updatedNewList.add(newLead);
            }
        }
        if (ECSS_uniqueKeys != null && ! ECSS_uniqueKeys.isEmpty()){
            //----- Check for existing Account based on the unique key
            System.debug('In the unique key check');
            allAccountRecMap = AccountService.getAllAccounts(ECSS_uniqueKeys);
            //---- Check for Duplicate and Existing Leads 
            LeadTriggerHelper.duplicateAndParenLead(ECSS_newList,ECSS_uniqueKeys);
        }
        
        newList = updatedNewList;
        System.debug('new List After: '+(List<Lead>)newList);
        //--------ECSS call the before update methods -------       
        if(ECSS_newList != null){
            ECSS_newMap = new Map<Id,Lead>((List<Lead>)oldlist);
            ECSS_LeadTriggerHelper.verifyPhoneNumbers((List<Lead>)ECSS_newList, ECSS_newMap);
        }
        //--------------------------------------------------------------------------------------------------------//
        
        for(Lead leadRec : (List<Lead>)newList){
            //added a check by Himanshu@Aldar to exclude P & I leads 
            if(leadRec.recordtypeId == PI_Services.p_IRecordTypeId){
                continue;
            }
            Lead oldRecord = (Lead)oldmap.get(leadRec.Id);
            if(leadRec.SkipDuplicateApprovalStatus__c =='Approved' && oldRecord.SkipDuplicateApprovalStatus__c !=leadRec.SkipDuplicateApprovalStatus__c){
                leadRec.ExistingAccount__c =null;
            }
            
            System.debug('before AssignmentSLATime__c---'+leadRec.AssignmentSLATime__c);
            if(leadRec.UpdateTasks__c != oldRecord.UpdateTasks__c && leadRec.UpdateTasks__c == false){
                runTrigger = false;
            } else{
                runTrigger = true;
                Break;
            }
            // Update unique key for resale sif firstname, email, mobilephone, unit is updated.
            // Added by Muzammil for resale
            if(leadRec.Lead_Type__c == LeadService.RESALE_LEADTYPE){
                if( leadRec.FirstName != oldRecord.FirstName || leadRec.Email != oldRecord.Email || leadRec.MobilePhone != oldRecord.MobilePhone || leadRec.Unit__c != oldRecord.Unit__c){
                    leadRec = LeadTriggerHelper.populateUniqueKeyForResale(leadRec);
                }
                if(leadRec.Unit__c != oldRecord.Unit__c){
                    updatedUnitIds.add(leadRec.Unit__c);
                }
            }
        }
        // Added by Muzammil for resale
        if(!updatedUnitIds.isEmpty()){
            salesOrderByUnit = LeadTriggerHelper.getSalesOrdersForUnits(updatedUnitIds);
        }
        if(runTrigger){
            //---- Populate fields before update
            LeadTriggerHelper.populateBeforeCommit(newList);
            
            Map<Id,Lead> qualifiedLeads = new Map<Id,Lead>();
            Map<Id,Lead> retiredLeads = new Map<Id,Lead>();
            Map<Id,Lead> leadToBeAssignedThroughRR = new Map<Id,Lead>();
            
            //Retired reasons for Qualtircs
            set<String> retiredReasons =  new set<String>{Constants.LEAD_LOST_NO_REAL_POTENTIAL,Constants.LEAD_LOST_NOT_QUALIFIED,Constants.LEAD_LOST_FUTURE_POTENTIAL,Constants.LEAD_LOST_INTEREST_LOST,Constants.LEAD_LOST_NO_ANSWER,Constants.LEAD_LOST_NO_PURCHASE_INTEREST};
                for(Lead leadRec : (List<Lead>)newList){
                    //added a check by Himanshu@Aldar to exclude P & I leads 
                    if(leadRec.recordtypeId == PI_Services.p_IRecordTypeId){
                        continue;
                    }
                    Lead oldRecord = (Lead)oldmap.get(leadRec.Id);
                    
                    if(oldRecord.Status != leadRec.Status){
                        if(leadRec.Status.equals(Constants.QUALIFIED)){
                            qualifiedLeads.put(leadRec.Id,leadRec);
                        }
                        if(leadRec.Status.equals(Constants.RETIRED)){
                            retiredLeads.put(leadRec.Id,leadRec);
                            //If Lead Status is Retired and matched one of the reasons then update the QualtricsIntegrationStatus__c
                            if(leadRec.RetiredReason__c!=null && retiredReasons.contains(leadRec.RetiredReason__c)){
                                leadRec.QualtricsIntegrationStatus__c=Constants.QUALTRICS_IN_PROGRESS;
                            }
                        }  
                    }
                    // Populating slaes order from unit when unit is updated in lead for resale
                    if(leadRec.Unit__c != oldRecord.Unit__c && leadRec.Unit__c != null && leadRec.Lead_Type__c == LeadService.RESALE_LEADTYPE ){
                        if(salesOrderByUnit.containsKey(leadRec.Unit__c)){
                            leadRec.Sales_Order__c = salesOrderByUnit.get(leadRec.Unit__c).Id;
                        }else{
                            //                    leadRec.addError('There is no sales order present for this unit.');
                        }
                    }
                }
            
            if(qualifiedLeads!=null && qualifiedLeads.size()>0)
                qualifiedLeadsProcessing(qualifiedLeads);
            
            if(retiredLeads!=null && retiredLeads.size()>0)
                retiredLeadsProcessing(retiredLeads);
            
            for(Lead leadRec : (List<Lead>)newList){
                //added a check by Himanshu@Aldar to exclude P & I leads 
                if(leadRec.recordtypeId == PI_Services.p_IRecordTypeId){
                    continue;
                }
                Lead oldRecord = (Lead)oldmap.get(leadRec.Id);
                
                if(leadRec.AssignToRoundRobin__c && oldRecord.AssignToRoundRobin__c != leadRec.AssignToRoundRobin__c){
                    leadToBeAssignedThroughRR.put(leadRec.Id,leadRec);
                }
            }
            
            if(!leadToBeAssignedThroughRR.isEmpty()){
                leadToBeAssignedThroughRR = RoundRobinAssignmentUtility.getAgentAssignment(leadToBeAssignedThroughRR);
            }
        }
    }
    
    //*** After Update Action***//
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){
        isLeadInvolve = true;
        List<Lead> newLeadList = new List<Lead>();
        boolean runTrigger = true;
        List<Lead> leadWithResaleUnitCaseList = new List<Lead>();
        //-----Moved the initialization of leadIdsToCovert here-------//
        Set<ID> leadIdsToCovert = new Set<id>();
        
        // -------ECSS Variables --------------
        List<Lead> ECSS_newList = new List<Lead>();
        List<Lead> updatedNewList = new List<Lead>();
        Map<Id,Lead> ECSS_newMap = new Map<Id,Lead>();
        List<Lead> leadIds = new List<Lead>();
        String ECSSLabelRecordType = System.Label.ECSS_LeadRecordType_AlDarEstate;
        Id recordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(ECSSLabelRecordType).getRecordTypeId();  
        
        List<Lead> brokerDigitalSaleLeads = new List<Lead>();
        
        //--------ECSS Loop to separate ECSS Records from the remaining records -------       
        System.debug('new List Before: '+(List<Lead>)newList);
        for (Lead newLead : (List<Lead>)newList) {
            if (newLead.recordtypeId == recordTypeId) {
                ECSS_newList.add(newLead);
                if(newLead.ECSS_Re_Assign__c == true && ((Lead)oldMap.get(newLead.Id)).ECSS_Re_Assign__c == false && newLead.RecordTypeId == recordTypeId)
                    leadIds.add(newLead);
                if(((Lead)oldMap.get(newLead.Id)).Status != newLead.Status && newLead.Status.equals(Constants.QUALIFIED)){
                    leadIdsToCovert.add(newLead.Id);
                }
            }
            else{
                updatedNewList.add(newLead);
            }
            
            //Broker Initiate Digital Sales 
            if(newLead.LeadSource == Constants.BROKER_PORTAL && 
               newLead.InitiateDigitalBooking__c == true && ((Lead)oldMap.get(newLead.Id)).InitiateDigitalBooking__c == false){
                   brokerDigitalSaleLeads.add(newLead);
               }
        }	
        newList = updatedNewList;
        System.debug('new List After: '+(List<Lead>)newList);
        //--------ECSS call the after update methods -------       
        if(ECSS_newList != null && leadIds.size()>0){
            ECSS_LeadTriggerHelper.LeadRotation(leadIds,true);
        }
        //--------------------------------------------------------------------------------------------------------//
        
        //this is added by himanshu@Aldar
        List<Lead> pILeads = new List<Lead>();
        List<SendFasttrackWhatsaAppLink.FlowInputs> inputs 	= new List<SendFasttrackWhatsaAppLink.FlowInputs>();//Added by Sarah on Apr 08, 2024
        List<SendFasttrackWhatsaAppLink.FlowOutputs> output;//Added by Sarah on Apr 08, 2024
        
        for(Lead leadRec : (List<Lead>)newList){
            Lead oldRecord = (Lead)oldmap.get(leadRec.Id);
            
            
            
            //added a check by Himanshu@Aldar to exclude P & I leads 
            if(leadRec.recordtypeId == PI_Services.p_IRecordTypeId){
                if(leadRec.Lead_Approved__c == true && oldRecord.Lead_Approved__c != leadRec.Lead_Approved__c){
                    pILeads.add(leadRec);
                }
                continue;
            }
            
            //Added by Sarah on Apr 08, 2024 for ASF-2594 - From here
            // System.debug(leadRec.Project__c+'>>PROJ>>'+System.Label.LeadFasttrackProjects.containsIgnoreCase(leadRec.Project__c));
            System.debug('>>SOURCE>>'+leadRec.LeadSource);
            System.debug('>>ISCONVERTED>>'+leadRec.IsConverted);
            System.debug('>>ACC ID>>'+leadRec.ConvertedAccountId);
            Map<ID, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Lead.getRecordTypeInfosById();
            String rectypeName = rtMap.get(leadRec.RecordTypeId).getDeveloperName();
            System.debug('>>NAME>>'+rectypeName);
            
            if(leadRec.IsConverted && leadRec.LeadSource != 'Broker Portal' && leadRec.ConvertedAccountId != null  && rectypeName == Constants.PERSON_LEAD_RECORD_TYPE_NAME && (leadRec.Lead_Type__c =='New Sale' || leadRec.Lead_Type__c =='Resale'||leadRec.Lead_Type__c =='AM Sale') && leadRec.InitiateDigitalBooking__c == false  ) {//&& System.Label.LeadFasttrackProjects.containsIgnoreCase(leadRec.Project__c)
                SendFasttrackWhatsaAppLink.FlowInputs input = new SendFasttrackWhatsaAppLink.FlowInputs();
                System.debug('>>>>'+leadRec.ConvertedAccountId);
                input.category								= 'FastTrack';input.accountId								= leadRec.ConvertedAccountId;input.brokerAccountId						= null;input.brokerContactId						= null;input.project								= leadRec.Project__c;input.salesOrderId							= leadRec.Sales_Order__c;input.sourceType							= 'Sales Manager';input.status								= 'Link Sent';
                inputs.add(input);
            }
            
            System.debug('after AssignmentSLATime__c---'+leadRec.AssignmentSLATime__c);
            //Harsh@Aldar When Lead is populated with Resale Unit case, update the corresponding Unit and Account on the Lead
            //Done to make sure Case number can be used as Unit Id thus ensuring unit has internal access only
            /*if(leadRec.Resale_Unit_Case__c != null && oldRecord.Resale_Unit_Case__c != leadRec.Resale_Unit_Case__c){
leadWithResaleUnitCaseList.add(leadRec);
}*/
            if(leadRec.IsConverted){
                newLeadList.add(leadRec);
            }
            
            if(leadRec.UpdateTasks__c != oldRecord.UpdateTasks__c && leadRec.UpdateTasks__c == false){
                runTrigger = false;
            } else{
                runTrigger = true;
                Break;
            }
        }
        if(inputs != null && !inputs.isEmpty()) {
            output = SendFasttrackWhatsaAppLink.createDigitalExpRecord(inputs);
        }
        //Harsh@Aldar When Lead is populated with Resale Unit case, update the corresponding Unit and Account on the Lead
        //Done to make sure Case number can be used as Unit Id thus ensuring unit has internal access only
        /*if(leadWithResaleUnitCaseList.size() > 0){
ResaleUnitService.handleCasePopulationOnResaleLead(leadWithResaleUnitCaseList);
}*/
        
        if(!newLeadList.isEmpty()){
            updateExistingAccounts(newLeadList);
        }
        if(runTrigger){
            //Set<ID> leadIdsToCovert= new Set<id>();
            set<ID> qualtircsIDsToProcess = new set<ID>();
            set<ID> convertedLeadContactIds = new set<ID>();
            set<ID> convertedLeadAccountsIds = new set<ID>();
            
            String userProfileName = userDetail.ProfileName__c ;
            //If record is assigned manually from RR Queue then create task
            map<id,Lead> manualOwnershipCheck = new map<id,Lead>();
            List<Group> defaultQueue = [select id,name,developerName from group where type='Queue' and developerName=:Constants.DEFAULT_RR_QUEUE];
            
            for(Lead leadRec : (list<Lead>) newList){
                //added a check by Himanshu@Aldar to exclude P & I leads 
                if(leadRec.recordtypeId == PI_Services.p_IRecordTypeId){
                    continue;
                }
                Lead oldRecord = (Lead)oldmap.get(leadRec.Id);
                
                if(oldRecord.Status != leadRec.Status && leadRec.Status.equals(Constants.QUALIFIED) && (userProfileName.equals(Constants.SALES_MANAGER) || userProfileName.equals(Resale_Relationship_Manager) || userProfileName.equals(System.label.Logistics_Profile)) ){//
                    leadIdsToCovert.add(leadRec.Id);
                }
                if(leadRec.QualtricsIntegrationStatus__c==Constants.QUALTRICS_IN_PROGRESS){
                    qualtircsIDsToProcess.add(leadRec.Id);
                }
                if(!defaultQueue.isEMpty() && oldRecord.OwnerId != leadRec.OwnerId && oldRecord.OwnerId == defaultQueue[0].id && leadRec.OwnerId.getSObjectType() == User.getSObjectType()){
                    manualOwnershipCheck.put(leadRec.Id,leadRec);
                    
                } else if(leadRec.AssignToRoundRobin__c && oldRecord.AssignToRoundRobin__c != leadRec.AssignToRoundRobin__c && leadRec.OwnerId.getSObjectType() == User.getSObjectType()){
                    manualOwnershipCheck.put(leadRec.Id,leadRec);    
                }else if(RoundRobinAssignmentUtility.roundRobinAssignmentFlow && oldRecord.OwnerId != leadRec.OwnerId && leadRec.OwnerId.getSObjectType() == User.getSObjectType()){
                    manualOwnershipCheck.put(leadRec.Id,leadRec);
                }
            }
            if(RoundRobinAssignmentUtility.roundRobinAssignmentFlow){
                RoundRobinAssignmentUtility.roundRobinAssignmentFlow=false;
            }
            if(!leadIdsToCovert.isEmpty()){
                UtilitiesWithoutSharing.convertLeads(leadIdsToCovert);
            }
            if(!qualtircsIDsToProcess.isEmpty()){
                System.enqueueJob(new Qualtrics.QualtricsIntegration(qualtircsIDsToProcess));
            }
            if(!manualOwnershipCheck.isEmpty()){
                checkAndCreateTask(manualOwnershipCheck);
            }
        }
        //p and i lead conversion Added by Himanshu@aldar
        if(!pILeads.isEmpty()){
            PI_Services.convertPandILeads(pILeads);
        }
        
        //Broker Digital Sale
        if(!brokerDigitalSaleLeads.isEmpty()){
            //LeadDigitalBookingHelper.prepareFlowInputs(brokerDigitalSaleLeads, 'Broker Portal');
        }
    }
    
    /*
* When a lead is updated as qualified check if there is atleast one task with Customer Reached
* When a lead qualified is eligible to be sent to Yardi then callout to Yardi
* When a lead is qualified by non SM user, then assign leads to SM through sound robin
* When a lead is qualified then updated Qualified By & Date Time
*/
    public void qualifiedLeadsProcessing(Map<Id,Lead> qualifiedLeadsMap){
        LeadTriggerHelper leadHelper = new LeadTriggerHelper();
        Set<Id> leadsWithCustomerReached = new Set<Id>();
        List<Lead> assetsManagementLeads = new List<Lead>();
        Set<Id> leadOwnersIds = new Set<Id>();
        Set<String> leadMobileNumbers = new Set<String>();
        Set<String> leadEmails = new Set<String>();
        
        // Added By Moh Sarfaraj for ASF-1782 starts
        Map<String,Integer> mapLeadIdToHasAppointments = new Map<String, Integer>();
        Set<String> setProfileName = new Set<String>(System.Label.LaunceProfileName.split(','));
        Set<String> setMethodofContact = new Set<String>();
        if(setProfileName.contains([SELECT Name FROM Profile WHERE Id = :Userinfo.getProfileId()].Name) || Test.isRunningTest()){
            for(AggregateResult agg : [SELECT COUNT(Id) appts,Lead__c FROM Appointment__c WHERE Lead__c IN :qualifiedLeadsMap.keySet() AND Date__c >= :System.Today() GROUP BY Lead__c]){
                mapLeadIdToHasAppointments.put(String.valueOf(agg.get('Lead__c')), Integer.valueOf(agg.get('appts')));
            }
        }
        Group launchQueue;
        if(!mapLeadIdToHasAppointments.isEmpty()){
            setMethodofContact = new Set<String>(System.Label.LaunchMethodofContact.split(','));            launchQueue = new Group();
            
            // Get launch Queue
            launchQueue = leadHelper.launchQueue;
        }
        // Added By Moh Sarfaraj for ASF-1782 end
        // Added by Arvind LSQ Leads 
        set<string> LSQProject = new set<string>();
        if(setProfileName.contains([SELECT Name FROM Profile WHERE Id = :Userinfo.getProfileId()].Name))
        {
            for(Lead leadRec : qualifiedLeadsMap.values()) 
            {
                if(leadRec.Lead_Project_Group__c == 'LSQ'){ LSQProject.add(leadRec.Lead_Project_Group__c);
                                                           
                                                          }
                
            }
        }
        
        Group LSQQueue;
        if(!LSQProject.isEmpty())
        {
            setMethodofContact = new Set<String>(System.Label.LaunchMethodofContact.split(','));
            LSQQueue = new Group();
            LSQQueue = LeadTriggerHelper.getGroupIdByName(System.Label.LSQ_Queue);
            
        }
        
        
        //----- Get Assets Management Queue.
        Group leadAssetsManagementQueue = LeadTriggerHelper.getGroupIdByName(Constants.ASSETS_MANAGEMENT_QUEUE);
        
        //----- Get Agent Queue.
        Group leadAgentQueue = LeadTriggerHelper.getGroupIdByName(Constants.LEAD_AGENT_QUEUE);
        
        //----- Get all tasks Have Customer Response equal 'Customer Reached'.
        for(Task taskRec : TaskService.getCustomerReachedTasks(qualifiedLeadsMap.keySet())){
            leadsWithCustomerReached.add(taskRec.WhoId);
        }
        
        for(Lead leadRec : qualifiedLeadsMap.values()){
            leadOwnersIds.add(leadRec.OwnerId);
            // Arvind Bypassing account duplicate check for organization type leads
                        if(leadRec.ExistingAccount__c == null && leadRec.RecordTypeId != Schema.getGlobalDescribe().get('Lead').getDescribe().getRecordTypeInfosByDeveloperName().get('Organization').getRecordTypeId()) {
                leadEmails.add(leadRec.Email);
                leadMobileNumbers.add(leadRec.MobilePhone);
            }
        }
        
        Map<Id, User> leadOwnersDetails = Utilities.getOwnersDetail(leadOwnersIds);
        
        //Added By Karunakar - Get Duplicate Accounts
        Map<String, List<UtilitiesWithoutSharing.DuplicateAccountWrapper>> dupeAccountMap = new Map<String, List<UtilitiesWithoutSharing.DuplicateAccountWrapper>>();
        List<UtilitiesWithoutSharing.DuplicateAccountWrapper> dupeAccountMapEmailAndMobileNumber = new List<UtilitiesWithoutSharing.DuplicateAccountWrapper>();
        if((!leadEmails.isEmpty() && userDetail.ProfileName__c==CONSTANTS.SALES_MANAGER) || Test.isRunningTest()){
            // SSC-697, Duplicate Account check based on Email or Mobile Number: Bashim
            // Created a new method with email or mobile number as input to check the existing accounts
            dupeAccountMapEmailAndMobileNumber = UseExistingAccount.findDuplicateAccountsByEmailAndMobileNumber(leadEmails, leadMobileNumbers);
        }
        
        for(Lead leadRec : qualifiedLeadsMap.values()){
            
            String duplicateCheckApprovalStatus = leadRec.SkipDuplicateApprovalStatus__c;
            
           // SSC-697, Duplicate Account check based on Email or Mobile Number: Bashim
            // Before converting the lead, verify whether an account already exists with the same email address or mobile number.
            if(dupeAccountMapEmailAndMobileNumber != NULL && !dupeAccountMapEmailAndMobileNumber.isEmpty()){
                if(leadRec.ExistingAccount__c == NULL && duplicateCheckApprovalStatus != Constants.SKIPDUPLICATEAPPROVAL_STATUS && leadRec.Lead_Type__c != Constants.LEAD_TYPE_LOGISTICS){//
                    leadRec.addError(System.Label.DuplicateAccountErrorMessage);
                }
            }
            
            //---- Error message to the user if there is no task with customer response equal 'Customer Reached'.
            if(!leadsWithCustomerReached.contains(leadRec.Id) && leadRec.Lead_Type__c != 'Logistics'){// 
                SystemMessages__mdt messageDetails = Utilities.getSystemMessages(Constants.QUALIFICATION_MESSAGE);
                leadRec.addError(messageDetails.Message__c);
            }
            //----if there is a task with customer response equal 'Customer Reached' populate QualifiedBy__c and QualificationDateAndTime__c
            else {
                leadRec.QualifiedBy__c = userDetail.Id;
                leadRec.QualificationDateAndTime__c = DateTime.now();
                //----- Check if Lead details have to be sent to Yardi
                if(Constants.PROPERTY_USAGE_YARDI.contains(leadRec.PropertyUsage__c) && Constants.ASSET_MANAGEMENT.equals(leadRec.SalesType__c) && Constants.RENT.equals(leadRec.BuyRent__c)){
                    leadRec.OwnerId = leadAssetsManagementQueue.Id;                    assetsManagementLeads.add(leadRec);                     leadRec.Status = Constants.CLOSED;
                    
                    
                } // Added By Moh Sarfaraj for ASF-1782
                else if(launchQueue != null && mapLeadIdToHasAppointments.containsKey(leadRec.Id) && mapLeadIdToHasAppointments.get(leadRec.Id) > 0  && 
                        setMethodofContact.contains(leadRec.LeadSource) && !leadRec.ExemptFromAssignment__c){
                            
                            leadRec.OwnerId = launchQueue.Id;
                        }
                else if(LSQProject != null && setMethodofContact.contains(leadRec.LeadSource) && !leadRec.ExemptFromAssignment__c )
                {
                    leadRec.OwnerId = LSQQueue.Id;
                }
                //----- Assign to SM through Round Robin if not qualified by SM.
                // 
                //Added by Muzammil for resale
                else if(leadRec.OwnerId == leadAgentQueue.Id || leadRec.OwnerId == leadHelper.leadAutoDialerQueue.Id ||
                        (leadOwnersDetails.containsKey(leadRec.OwnerId)  && 
                         (!leadOwnersDetails.get(leadRec.OwnerId).ProfileName__c.equals(Constants.SALES_MANAGER) && leadRec.Lead_Type__c == 'New Sale' ) ||
                         (!leadOwnersDetails.get(leadRec.OwnerId).ProfileName__c.equals(Resale_Relationship_Manager)  && leadRec.Lead_Type__c == 'Resale')||
                         (!leadOwnersDetails.get(leadRec.OwnerId).ProfileName__c.equals(Resale_Relationship_Manager)  && leadRec.Lead_Type__c == 'AM Sale') ||
                         (!leadOwnersDetails.get(leadRec.OwnerId).ProfileName__c.equals(System.label.Logistics_Profile)  && leadRec.Lead_Type__c == 'Logistics')
                         
                        )
                       )
                {
                    leadRec.AssignToRoundRobin__c = true;
                }
                /*else if(leadRec.OwnerId == leadAgentQueue.Id || (leadOwnersDetails.containsKey(leadRec.OwnerId) && !leadOwnersDetails.get(leadRec.OwnerId).ProfileName__c.equals(Constants.SALES_MANAGER))){
leadRec.AssignToRoundRobin__c = true;
}*/
            }
        }
        
        //----- Send Leads to Yardi API 
        if(assetsManagementLeads!=null && assetsManagementLeads.size()>0){
            APISetting__mdt leadImportAPI = APISetting__mdt.getInstance(Constants.LEAD_IMPORT); // 1 Dec 2025 Protiviti- Added Deactivte Functionality to Trun off once Lead to Lease go live
            if(!leadImportAPI.Deactivate__c){
            YardiCreateLead.LeadImport(assetsManagementLeads);
        }
    }
    }
    
    /*
* When a lead is updated as retired check if there is atleast one task with Customer Reached
* When a lead is retired then updated Retired By & Date Time
*/
    public void retiredLeadsProcessing(Map<Id,Lead> retiredLeadsMap){  
        Set<Id> leadsWithCustomerResponse = new Set<Id>();
        //Set<Id> reachedAndInvalidContactTasks = new Set<Id>();
        
        for(Task taskRec : TaskService.getTasksHaveCustomerResponse(retiredLeadsMap.keySet())){
            leadsWithCustomerResponse.add(taskRec.WhoId);
            /*if(taskRec.CustomerResponse__c != Constants.CUSTOMER_NOT_REACHABLE){
reachedAndInvalidContactTasks.add(taskRec.WhoId);
}*/
        }
        
        for(Lead leadRec : retiredLeadsMap.values()){
            if(!leadsWithCustomerResponse.contains(leadRec.Id)){
                SystemMessages__mdt messageDetails = Utilities.getSystemMessages(Constants.RETIRED_MESSAGE);
                leadRec.addError(messageDetails.Message__c);
                
            } /*else if(leadsWithCustomerResponse.contains(leadRec.Id) && !reachedAndInvalidContactTasks.contains(leadRec.Id)){
SystemMessages__mdt messageDetails = Utilities.getSystemMessages(Constants.RETIRED_MESSAGE);
leadRec.addError(messageDetails.Message__c);

}*/ else{ //---- updating the mandatory fields if its blank
    leadRec.RetiredBy__c = userDetail.Id;
    leadRec.RetiredDate__c = DateTime.now();
    leadRec.AssignmentStatus__c = Constants.TRANSFERRED;
}
        }
    }
    
    public static void checkAndCreateTask(map<id,lead> leadRecords){
        //get all existing open task records
        map<id,set<id>> leadToOpenOwnerTasks = new map<id,set<id>>();
        list<Task> taskToInsert = new list<Task>();
        list<Lead> leadToUpdate = new list<Lead>();
        DateTime actionSLATimeDefault = RoundRobinAssignmentUtility.getActionSLA(Integer.ValueOf(System.label.ROUNDROBIN_SM_SLA ));
        DateTime actionSLATimeDirect = RoundRobinAssignmentUtility.getActionSLA(Integer.ValueOf(System.label.DIRECTASSIGENMENT_SM_SLA));
        // Added by Moh Sarfaraj for ASF-1469 for BAG
        DateTime actionSLAManualBAG = RoundRobinAssignmentUtility.getActionSLA(Integer.valueOf(System.label.BAG_DIRECTASSIGENMENT_SM_SLA));
        DateTime actionSLATimeAPIBAG = RoundRobinAssignmentUtility.getActionSLA(Integer.valueOf(System.label.BAG_API_DIRECTASSIGENMENT_SM_SLA));
        
        /*for(Task tempTask : [select id,OwnerId,WhoId from task where Subject :Constants.TASK_DAY1 and WhoId in leadRecords.keySet() and isClosed= false]){
if(!leadToOpenOwnerTasks.containsKey(tempTask.WhoId)){
leadToOpenOwnerTasks.put(tempTask.WhoId,set<id>)
}
leadToOpenOwnerTasks.get(tempTask.WhoId).add(tempTask.OwnerId);
}*/
        //If no open task then create new based on status
        for(Id leadId : leadRecords.keySet()){
            // Added and Updated by Moh Sarfaraj for ASF-1469 for BAG start
            Lead leadRecord = leadRecords.get(leadId);
            //DateTime actionSLATime = leadRecord.Status.equalsIgnoreCase(Constants.QUALIFIED) ? actionSLATimeDefault : (leadRecord.Project__c.equalsIgnoreCase(Label.ADHAProject) && (leadRecord.BAGIsRegisterFromWeb__c || leadRecord.CCA_assigned__c)) ? actionSLATimeAPIBAG : (leadRecord.Project__c.equalsIgnoreCase(Label.ADHAProject) && leadRecord.Bag_Lead_Assigned_Manually_TO_RM__c) ? actionSLAManualBAG : actionSLATimeDirect;
            DateTime actionSLATime;
            actionSLATime = actionSLATimeDefault;
            if(!leadRecord.Status.equalsIgnoreCase(Constants.QUALIFIED)){
                if(leadRecord.Project__c.equalsIgnoreCase(Label.ADHAProject)){
                    if(leadRecord.BAGIsRegisterFromWeb__c || leadRecord.CCA_assigned__c){actionSLATime = actionSLATimeAPIBAG;
                                                                                        }else if(leadRecord.Bag_Lead_Assigned_Manually_TO_RM__c){actionSLATime = actionSLAManualBAG;}
                }else{ actionSLATime = actionSLATimeDirect;}
            }else{actionSLATime = actionSLATimeDefault;}
            // Added and Updated by Moh Sarfaraj for ASF-1469 for BAG end
            //if(!leadToOpenOwnerTasks.containsKey(leadId) || !leadToOpenOwnerTasks.get(leadId).contains(leadRecords.get(leadId).ownerID) ){
            taskToInsert.add(new Task(Subject=Constants.TASK_DAY1,
                                      WhoId=leadId,
                                      TaskNumber__c = 9,
                                      ReminderDateTime= actionSLATime, 
                                      IsReminderSet=true,
                                      TaskType__c=Constants.TASK_TYPE_DAY1,
                                      ActivityDate=date.newinstance(actionSLATime.year(), actionSLATime.month(), actionSLATime.day()),
                                      OwnerId=leadRecords.get(leadId).OwnerId));
            leadToUpdate.add(new lead(id=leadId , AssignmentSLATime__c=actionSLATime, TaskType__c = Constants.TASK_TYPE_DAY1));
            //}
        }
        if(!taskToInsert.isEmpty()){
            insert taskToInsert;
        }
        if(!leadToUpdate.isEmpty()){
            update leadToUpdate;
        }
    }
    
    @InvocableMethod(label='Update Tasks Field on Lead' description='To Update Tasks Field on Lead.' category='Lead')
    public static void leadUpdateTasks(List<Id> leads) {
        
        List<Lead> leadsList = [Select Status, Id From Lead Where Id in : leads];
        
        for (Lead leadRec : leadsList) {
            if(leadRec.Status == Constants.WORKING_LEAD || leadRec.Status == Constants.NEW_LEAD){
                leadUpdateTasksFuture(leadRec.Id);
            }
        }
    }
    
    public static void updateExistingAccounts(List<Lead> newList){
        Map<Id, Account> accountMapToUpdate = new Map<Id, Account>();
        Set<Id> accountIdSet = new Set<Id>();
        Map<Id, List<Document__c>> AccountDocumentMap = new Map<Id, List<Document__c>>();
        Map<Id, Account> actListToUpdate = new Map<Id, Account>();
        Map<Id, Account> ExistingaccountMap = new Map<Id, Account>();
        Account acct = new Account();
        Set<Id> existingAccountIdSet = new Set<Id>();
        
        for(Lead leadRec : newList){
            if(leadRec.ExistingAccount__c != null){
                existingAccountIdSet.add(leadRec.ExistingAccount__c);
            }
        }
        ExistingaccountMap = new Map<Id, account>([Select
                                                   Id,
                                                   OwnerId,
                                                   Owner.name,
                                                   RecordtypeId
                                                   from account 
                                                   where Id in: existingAccountIdSet]);
        
        
        for(Lead leadRec : newList){
            //  if(allAccountRecMap!=null && allAccountRecMap.containsKey(leadRec.UniqueKey1__c.toLowerCase())){
            Account existAccount = ExistingaccountMap.get(leadRec.ExistingAccount__c);
            
            //acctId = existAccount.id;
            acct = existAccount;
            if((Test.isRunningTest()&& existAccount != null) || (leadRec.IsConverted && existAccount != null)) {
                if(existAccount.Owner.Name == 'Data Migration') {
                    existAccount.OwnerId = leadRec.OwnerId;
                    accountMapToUpdate.put(existAccount.Id, existAccount);
                }
                
                if(existAccount != null){
                    accountIdSet.add(existAccount.id);
                }
                //Added by Arvind
                if(existAccount != null)
                {  if(leadRec.CustomerType__c != null){
                    existAccount.CustomerType__c = leadRec.CustomerType__c;
                }
                 if(leadRec.CustomerSubType__c != null){
                     existAccount.CustomerSubType__c = leadRec.CustomerSubType__c;
                 }
                 if(leadRec.CorporateWealthName__c != null){
                     existAccount.CorporateWealthName__c= leadRec.CorporateWealthName__c;
                 }
                 accountMapToUpdate.put(existAccount.Id, existAccount);
                }
            }
            //} 
            
        }
        if(!accountMapToUpdate.values().isEmpty()){
            update accountMapToUpdate.values();
        }
        if(!accountIdSet.isEmpty()){
            List<Document__c> documentList = [SELECT
                                              Id,
                                              DocumentType__c,
                                              Account__c
                                              FROM Document__c 
                                              WHERE Account__c in: accountIdSet];
            
            if(documentList.size()>0){
                for(Document__c document: documentList){
                    List<Document__c> alldocumentList = AccountDocumentMap.get(document.Account__c) != null ?  AccountDocumentMap.get(document.Account__c) : new List<Document__c>();
                    alldocumentList.add(document);
                    AccountDocumentMap.put(document.Account__c, alldocumentList);
                }
            }else{
                AccountDocumentMap.put(acct.id, new List<Document__c>());
            }
        }
        for(Id accountId: accountMapToUpdate.keySet()){
            if(AccountDocumentMap.get(accountId).size()==0){
                Account accounts = new Account(id=accountId, RecordTypeId=accountMapToUpdate.get(accountId).RecordTypeId);
                actListToUpdate.put(accountId, accounts);
                // actListToUpdate.add(new Account(Id=accountId, RecordTypeId=accountMapToUpdate.get(accountId).RecordTypeId));
                
            }
        }
        if(acct != null && acct.Id != null){
            if(AccountDocumentMap.containsKey(acct.id) && AccountDocumentMap.get(acct.id).size()==0){
                Account accounts = new Account(id=acct.Id, RecordTypeId=acct.RecordTypeId);
                actListToUpdate.put(acct.Id, accounts);
                // actListToUpdate.add(new Account(Id=acct.Id, RecordTypeId=acct.RecordTypeId));  
            }
        }
        
        if(!actListToUpdate.isEmpty()){
            AccountTriggerHandler.createAccountDocuments(actListToUpdate.values());
        }
    }
    
    @future
    public static void leadUpdateTasksFuture(Id leadId) {
        Lead leadRec = new Lead();
        leadRec.Id = leadId;
        leadRec.UpdateTasks__c = true;
        update leadRec;
    }
}