public with sharing class ContactTriggerHandler extends TriggerHandler{
    
    //*** Before Insert Action***//
    public override void beforeInsertMethod(List<SObject> newList, Map<Id, SObject> newMap){
      //  checkEmail(newList);
        
            //BPM-473 check duplicate contacts
            if(foundDuplicateContactsforAgency(newList)){
                for(Contact con : (List<Contact>) newList){
                    if(con.RecordTypeId == ALD_Constants.BROKER_AGENT_RT){
                        con.addError('Active Contact already present with same email/mobile and broker type under the agency.');
                    }
                }
            }
    }

    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap){
        // Added By Moh Sarfaraj for BPE-10
        createBrokerAgentDocuments(newList);   
        // Added by Sai Kumar for Account sync issues - Handle ERP sync for new contacts if enabled
        if(System.Label.Enable_Contact_ERP_Sync.equalsIgnoreCase('true')) {
            handleERPSync(newList, null);
        }     
    }

    public override void afterUpdateMethod(list<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){
            Set<Id> setContactIdToBeSuspended = new Set<Id>(); 
            Set<Id> setContactIdToUpdateEmailMobOnUser = new Set<Id>(); // Added By Moh Sarfaraj for BPM-554
    List<Id> callAppSystemAgentIdSet = new List<Id>(); // Added by dines for BPM-6062
    //Set<Id> setActiveSuspendedAgentIds = new Set<Id>(); // Added by dines for BPM-6062
    //Set<Id> setSuspendedAgentIds = new Set<Id>(); // Added by dines for BPM-6062
            List<Approval.ProcessSubmitRequest> listProcessRequests = new List<Approval.ProcessSubmitRequest>();

            for(Contact eachContact : (List<Contact>) newList){
                Contact oldContact  = (Contact) oldMap.get(eachContact.Id);

                // Added By Moh Sarfaraj for BPM-391
                if(eachContact.RecordTypeId == ALD_Constants.BROKER_AGENT_RT && 
                   String.isNotBlank(eachContact.AgentStatus__c) && 
                   eachContact.AgentStatus__c != oldContact.AgentStatus__c){
                    
                    if(eachContact.AgentStatus__c == 'Suspended'){
                        setContactIdToBeSuspended.add(eachContact.Id);
                    }
                }

                // Added By Moh Sarfaraj for BPM-440
                if(eachContact.RecordTypeId == ALD_Constants.BROKER_AGENT_RT && 
                   ((eachContact.NationalIdNumber__c != oldContact.NationalIdNumber__c) ||
                    (eachContact.NationalIdExpiryDate__c != oldContact.NationalIdExpiryDate__c) ||
                    (eachContact.ResidentStatus__c != oldContact.ResidentStatus__c) ||
                    (eachContact.Position__c != oldContact.Position__c) ||
                    (eachContact.PassportExpiryDate__c != oldContact.PassportExpiryDate__c) ||
                    (eachContact.PassportNumber__c != oldContact.PassportNumber__c) ||
                    (eachContact.Name != oldContact.Name) || 
                    ((eachContact.MobilePhone__c != oldContact.MobilePhone__c ||
                      eachContact.MobilePhone != oldContact.MobilePhone) && eachContact.MobileCountryCode__c != '971'
                    ))){

                    Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                    req.setObjectId(eachContact.Id);
                    listProcessRequests.add(req);
                }
                
                // Added By Moh Sarfaraj for BPM-554
                if(eachContact.RecordTypeId == ALD_Constants.BROKER_AGENT_RT && 
                   ((String.isNotBlank(eachContact.Email) && eachContact.Email != oldContact.Email) || 
                   (String.isNotBlank(eachContact.MobilePhone__c) && eachContact.MobilePhone__c != oldContact.MobilePhone__c))){

                    setContactIdToUpdateEmailMobOnUser.add(eachContact.Id);
                }

        // Added by dinesh for BPM-6062
        if(eachContact.RecordTypeId == ALD_Constants.BROKER_AGENT_RT){
            if( eachContact.AgentStatus__c == 'Active'  && eachContact.AllowAdditionalAppointmentSlots__c && 
                eachContact.AllowAdditionalAppointmentSlots__c != oldContact.AllowAdditionalAppointmentSlots__c){
                callAppSystemAgentIdSet.add(eachContact.Id);
            }
        }
            }

            // Added By Moh Sarfaraj for BPE-10
            createBrokerAgentDocuments((List<Contact>) newList, oldMap);

            // KYCValidityController.populateKycStatusIfKycMandatoryFieldsUpdatedOnContact(newMap, oldMap);

            // Added By Moh Sarfaraj for BPE-110
            updatePrimaryOwner(newList, oldMap);
            updatePrimaryAgencyAdmin(newList, oldMap);

            // Added By Moh Sarfaraj for BPM-355
            freezeUnfreezePortalUser(newList, oldMap); 

            // Added By Moh Sarfaraj for BPM-391
            if(!setContactIdToBeSuspended.isEmpty()){
                suspendAgencyUsersToBlocked(setContactIdToBeSuspended);
            }
            
            // Added by Sai Kumar for Account sync issues - Handle ERP sync for updated contacts if enabled
            if(System.Label.Enable_Contact_ERP_Sync.equalsIgnoreCase('true')) {
                handleERPSync(newList, oldMap);
            }
            // Added By Moh Sarfaraj for BPM-440
            if(!listProcessRequests.isEmpty()){
                try{
                    // Submit the approval request
                    Approval.ProcessResult [] processResults = Approval.process(listProcessRequests, true);
                }catch(Exception ex){
                    System.System.debug('Exception is '+ex.getMessage());
                }
            }
            
            // Added By Moh Sarfaraj for BPM-554
            if(!setContactIdToUpdateEmailMobOnUser.isEmpty()){
                updateEmailMobileOnRelatedUser(setContactIdToUpdateEmailMobOnUser);
        }

    // Added by dinesh for BPM-6062
    if(!callAppSystemAgentIdSet.isEmpty()){
       AppointmentController.processContactFuture(callAppSystemAgentIdSet);
    }
}


    //*** Before Update Action***//
    public override void beforeUpdateMethod(list<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){
        //checkEmail(newList);
        // Added By Moh Sarfaraj for BPM-355
        unblockContact(newList, oldMap);

        for(Contact eachContact : (List<Contact>) newList){
            Contact oldContact  = (Contact) oldMap.get(eachContact.Id);

            // Added By Moh Sarfaraj for BPM-440
            if(eachContact.RecordTypeId == ALD_Constants.BROKER_AGENT_RT && 
               ((eachContact.NationalIdNumber__c != oldContact.NationalIdNumber__c) ||
                (eachContact.NationalIdExpiryDate__c != oldContact.NationalIdExpiryDate__c) ||
                (eachContact.ResidentStatus__c != oldContact.ResidentStatus__c) ||
                (eachContact.Position__c != oldContact.Position__c) ||
                (eachContact.PassportExpiryDate__c != oldContact.PassportExpiryDate__c) ||
                (eachContact.PassportNumber__c != oldContact.PassportNumber__c) ||
                (eachContact.Name != oldContact.Name) || 
                ((eachContact.MobilePhone__c != oldContact.MobilePhone__c ||
                  eachContact.MobilePhone != oldContact.MobilePhone) && eachContact.MobileCountryCode__c != '971'
                ))){
                
                eachContact.AgentStatus__c = Constants.PENDING_VERIFICATION;
            }
        }
        
        //BPM-473 check duplicate contacts
        if(foundDuplicateContactsforAgency(newList)){
            for(Contact con : (List<Contact>) newList){
                Contact oldContact  = (Contact) oldMap.get(con.Id);
                if(con.RecordTypeId == ALD_Constants.BROKER_AGENT_RT && (oldContact.Email != con.Email || oldContact.MobilePhone__c != con.MobilePhone__c || oldContact.BrokerType__c != con.BrokerType__c)){
                    con.addError('Active Contact already present with same email/mobile and broker type under the agency.');
                }
            }
        }
    }

    // Method to handle ERP sync for contacts
    // Added by Sai Kumar for Account sync issues - Handle ERP sync for updated contacts if enabled
    private static void handleERPSync(List<Contact> newContacts, Map<Id,SObject> oldMap) {
        Set<Id> accountIdsToSync = new Set<Id>();
        
        for(Contact contact : newContacts) {
            if(contact.BrokerType__c == Constants.AGENCY_ADMIN) {
                if(oldMap == null) { // Insert case
                    accountIdsToSync.add(contact.AccountId);
                } else { // Update case
                    Contact oldContact = (Contact)oldMap.get(contact.Id);
                    Boolean hasChanged = false;
                    
                    // Check if any sync fields changed
                    for(Contact_Integration_Fields__c contactIntegrationField : Contact_Integration_Fields__c.getAll().values()) {
                        if(contact.get(contactIntegrationField.API__c) != oldContact.get(contactIntegrationField.API__c)) {
                            hasChanged = true;
                            break;
                        }
                    }
                    
                    if(hasChanged) {
                        accountIdsToSync.add(contact.AccountId);
                    }
                }
            }
        }
        
        if(!accountIdsToSync.isEmpty()) {
            AccountCalloutHelper.PrepareDataForCallout(new List<Id>(accountIdsToSync));
        }
    }

    public static void checkEmail(List<Contact> contactList) {
        Set<String> emailList = new Set<String>();
        Boolean isError = false;
        for(Contact con : contactList){
            if (emailList.contains(con.Email)) {
                isError = true;
                if(!Test.isRunningTest()){
                     con.addError('Please add unique Email for added User');
                }
                break;
            } else {
                emailList.add(con.Email);
            }
        }
        List<Contact> conList = [SELECT Id, Email FROM Contact WHERE Email IN : emailList AND RecordType.Name=:Constants.BROKER_AGENT];
        if (!isError && !conList.isEmpty() && !Test.isRunningTest()) {
            contactList[0].addError('There Are Already User With This Email in the System');
        }
    }
    // Added By Moh Sarfaraj for BPE-10 (Overloaded Method)
    public static void createBrokerAgentDocuments(List<Contact> newContactList, Map<Id,SObject> oldContactMap){
        final Set<String> setAgentStatuses = new Set<String>(Label.BrokerAgentStatus.split(','));
        List<Contact> listContact = new List<Contact>();
        for(Contact eachContact : newContactList){
            Contact oldContact = new Contact();
            oldContact = (Contact) oldContactMap.get(eachContact.Id);
            if(eachContact.AgentStatus__c != oldContact.AgentStatus__c && setAgentStatuses.contains(eachContact.AgentStatus__c)){
                listContact.add(eachContact);
            }
        }
        if(!listContact.isEmpty()){
            createBrokerAgentDocuments(listContact);
        }
    }

    // Added By Moh Sarfaraj for BPE-10 (Overloaded Method)
    public static void createBrokerAgentDocuments(List<Contact> contactList){
        String DOCUMENT_PLACEHOLDER_CATEGORY_BROKER = 'Broker Document';
        Map<Id,Contact> mapContactIdToContact = new Map<Id,Contact>();
        Set<Id> setAccountIds = new Set<Id>();
        for(Contact eachContact : contactList){
            if(String.isNotBlank(ALD_Constants.BROKER_AGENT_RT) && String.isNotBlank(eachContact.AccountId) && 
               String.isNotBlank(eachContact.RecordTypeId) && eachContact.RecordTypeId == ALD_Constants.BROKER_AGENT_RT){

                mapContactIdToContact.put(eachContact.Id, eachContact);
                setAccountIds.add(eachContact.AccountId);
            }
        }
        if(!mapContactIdToContact.isEmpty()){
            Map<Id,Account> mapContactIdToAccount = new Map<Id,Account>();
            for(Account eachAccount : [SELECT Id,BillingState,AgencyRegion__c,(SELECT Id FROM Contacts) FROM Account WHERE Id IN : setAccountIds]){
                for(Contact eachCon : eachAccount.Contacts){
                    mapContactIdToAccount.put(eachCon.Id, eachAccount);
                }
            }
            Map<String,List<DocumentPlaceHolder__mdt>> documentMap = DocumentService.getDocumentMetaDataByCategory(new set<String>{DOCUMENT_PLACEHOLDER_CATEGORY_BROKER});
            
            if(!documentMap.isEmpty()){
                List<Document__c> documentListToInsert = new List<Document__c>();
                Map<String,Id> documentRecordTypeMap = new Map<String,Id>();
                //get Existing Documents
                Map<String, Document__c> existingDocMap = new Map<String, Document__c>();
                for(Document__c tempDoc : [SELECT Id,DocumentType__c,Contact__c FROM Document__c WHERE Contact__c IN :mapContactIdToContact.keySet()]){
                    existingDocMap.put(tempDoc.Contact__c+tempDoc.DocumentType__c,tempDoc);
                }
                for(Contact con : mapContactIdToContact.values()){
                    for(DocumentPlaceHolder__mdt tempMetaRec : documentMap.get(DOCUMENT_PLACEHOLDER_CATEGORY_BROKER)){
                        String recordTypeID = null;
                        if(tempMetaRec.RecordTypeDeveloperName__c != null){
                            if(!documentRecordTypeMap.containsKey(tempMetaRec.RecordTypeDeveloperName__c)){
                                documentRecordTypeMap.put(tempMetaRec.RecordTypeDeveloperName__c,Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(tempMetaRec.RecordTypeDeveloperName__c).getRecordTypeId());
                            }
                            recordTypeID = documentRecordTypeMap.get(tempMetaRec.RecordTypeDeveloperName__c);
                        }
                        if(!existingDocMap.containsKey(con.Id + tempMetaRec.DocumentType__c)){
                            Set<String> setRegions = new Set<String>(tempMetaRec.Region__c.split(','));
                            if(setRegions.contains(mapContactIdToAccount.get(con.Id).AgencyRegion__c)){
                                Document__c documentRecord = DocumentService.createDocumentRecord('','','',tempMetaRec.DocumentType__c,'','',recordTypeID);
                                documentRecord.Contact__c   = con.Id;
                                documentRecord.SendForESign__c          = tempMetaRec.eSignRequired__c;
                                documentRecord.DocumentPlaceHolderId__c = tempMetaRec.DeveloperName;
                                documentRecord.EligibleForeSign__c      = tempMetaRec.EligibleForeSign__c;
                                
                                if(tempMetaRec.DocumentType__c.equalsIgnoreCase('RERA Broker Card')){
                                    // Updated By Moh Sarfaraj for BPM-331
                                    if(mapContactIdToAccount.get(con.Id).BillingState.containsIgnoreCase('Dubai') && mapContactIdToContact.get(con.Id).BrokerType__c == 'Agent'){
                                        documentListToInsert.add(documentRecord); 
                                    }
                                }
                                // Added By Moh Sarfaraj for BPE-143 starts
                                else if(tempMetaRec.DocumentType__c.equalsIgnoreCase('ADM Card')){
                                    // Updated By Moh Sarfaraj for BPM-331
                                    if(mapContactIdToAccount.get(con.Id).BillingState.containsIgnoreCase('Abu Dhabi') && mapContactIdToContact.get(con.Id).BrokerType__c == 'Agent'){
                                        documentListToInsert.add(documentRecord); 
                                    }
                                }// Added By Moh Sarfaraj for BPE-143 end
                                else{
                                    documentListToInsert.add(documentRecord); 
                                }
                            }
                        }
                    }
                }
                if(!documentListToInsert.isEmpty()){
                    insert documentListToInsert;  
                }
            }
        }
    }

    // Added By Moh Sarfaraj for BPE-110
    public static void updatePrimaryOwner(List<Contact> contactList, Map<Id,SObject> oldContactMap){
        Map<Id,Id> mapContactIdToAccountId = new Map<Id,Id>();
        for(Contact eachContact : contactList){
            Contact oldContact = new Contact();
            oldContact = (Contact) oldContactMap.get(eachContact.Id);
            if(eachContact.RecordTypeId == ALD_Constants.BROKER_AGENT_RT && eachContact.AgentStatus__c != oldContact.AgentStatus__c &&
               eachContact.AgentStatus__c == 'Active' && eachContact.PrimaryOwner__c){
               
                mapContactIdToAccountId.put(eachContact.Id, eachContact.AccountId);
            }
        }
        if(!mapContactIdToAccountId.isEmpty()){
            List<Contact> listContactToUpdatePrimaryOwner = new List<Contact>();
            for(Account eachAccount : [SELECT Id, (SELECT Id,PrimaryOwner__c FROM Contacts WHERE PrimaryOwner__c = true 
                                     AND Id NOT IN : mapContactIdToAccountId.keySet()) FROM Account WHERE 
                                     Id IN : mapContactIdToAccountId.values()]){

                if(!eachAccount.Contacts.isEmpty()){
                    for(Contact innerContact : eachAccount.Contacts){
                        innerContact.PrimaryOwner__c = false;
                        listContactToUpdatePrimaryOwner.add(innerContact);
                    }
                }
            }
            if(!listContactToUpdatePrimaryOwner.isEmpty()){
                Database.update(listContactToUpdatePrimaryOwner);
            }
        }
    }

    // Added By Moh Sarfaraj for BPE-110
    public static void updatePrimaryAgencyAdmin(List<Contact> contactList, Map<Id,SObject> oldContactMap){
        Map<Id,Id> mapContactIdToAccountId = new Map<Id,Id>();
        for(Contact eachContact : contactList){
            Contact oldContact = new Contact();
            oldContact = (Contact) oldContactMap.get(eachContact.Id);
            if(eachContact.RecordTypeId == ALD_Constants.BROKER_AGENT_RT && eachContact.AgentStatus__c != oldContact.AgentStatus__c &&
               eachContact.AgentStatus__c == 'Active' && eachContact.PrimaryAgencyAdmin__c){
               
                mapContactIdToAccountId.put(eachContact.Id, eachContact.AccountId);
            }
        }
        if(!mapContactIdToAccountId.isEmpty()){
            List<Contact> listContactToUpdatePrimaryAgencyAdmin = new List<Contact>();
            for(Account eachAccount : [SELECT Id, (SELECT Id,PrimaryAgencyAdmin__c FROM Contacts WHERE PrimaryAgencyAdmin__c = true 
                                     AND Id NOT IN : mapContactIdToAccountId.keySet()) FROM Account WHERE 
                                     Id IN : mapContactIdToAccountId.values()]){

                if(!eachAccount.Contacts.isEmpty()){
                    for(Contact innerContact : eachAccount.Contacts){
                        innerContact.PrimaryAgencyAdmin__c = false;
                        listContactToUpdatePrimaryAgencyAdmin.add(innerContact);
                    }
                }
            }
            if(!listContactToUpdatePrimaryAgencyAdmin.isEmpty()){
                Database.update(listContactToUpdatePrimaryAgencyAdmin);
            }
        }
    }

    // Added By Moh Sarfaraj for BPM-355 before Update
    public static void unblockContact(List<Contact> contactList, Map<Id,SObject> oldContactMap){
        Map<Id, Boolean> mapPortalContactToStatus = new Map<Id,Boolean>();
        for(Contact eachContact : contactList){
            Contact oldContact = new Contact();
            oldContact = (Contact) oldContactMap.get(eachContact.Id);
            if(eachContact.RecordTypeId == ALD_Constants.BROKER_AGENT_RT && 
               eachContact.AgentStatus__c != oldContact.AgentStatus__c && 
               eachContact.AgentStatus__c == 'Active' && eachContact.BlockedFromBackend__c){
                    
                eachContact.BlockedFromBackend__c = false;
            }
        }
    } 

    // Added By Moh Sarfaraj for BPM-355 after Update
    public static void freezeUnfreezePortalUser(List<Contact> contactList, Map<Id,SObject> oldContactMap){
        Map<Id,Boolean> mapPortalContactToStatus = new Map<Id,Boolean>();
        for(Contact eachContact : contactList){
            Contact oldContact = new Contact();
            oldContact = (Contact) oldContactMap.get(eachContact.Id);
            if(eachContact.RecordTypeId == ALD_Constants.BROKER_AGENT_RT && 
               String.isNotBlank(eachContact.AgentStatus__c) && 
               eachContact.AgentStatus__c != oldContact.AgentStatus__c){
                
                if(eachContact.AgentStatus__c == 'Blocked'){
                    mapPortalContactToStatus.put(eachContact.Id, true);
                }else if(eachContact.AgentStatus__c == 'Active'){
                    mapPortalContactToStatus.put(eachContact.Id, false);
                }
            }
        }
        if(!mapPortalContactToStatus.isEmpty() && !System.isBatch() && !System.isFuture()){
            Map<Id,User> mapUserRecords = new Map<Id,User>([SELECT Id,ContactId FROM User WHERE ContactId IN : mapPortalContactToStatus.keySet()]);
            freezeUnfreezeUsers(JSON.serialize(mapUserRecords), mapPortalContactToStatus);
        } 
    }
    
    @future // Added By Moh Sarfaraj for BPM-355 after Update
    public static void freezeUnfreezeUsers(String userRecordStr, Map<Id,Boolean> mapPortalContactToStatus){
        Map<Id,User> mapUserRecords = (Map<Id,User>) JSON.deserialize(userRecordStr, Map<Id,User>.class);

        List<UserLogin> listUsersToUpdate = new List<UserLogin>();
        for(UserLogin eachUser : [SELECT Id,UserId,isFrozen FROM UserLogin WHERE UserId IN : mapUserRecords.keySet()]){
            eachUser.isFrozen = mapPortalContactToStatus.get(mapUserRecords.get(eachUser.UserId).ContactId);
            listUsersToUpdate.add(eachUser);
        }
        if(!listUsersToUpdate.isEmpty() && !Test.isRunningTest()){
            Database.update(listUsersToUpdate, false);
        }
    }

    // Added By Moh Sarfaraj for BPM-391
    public static void suspendAgencyUsersToBlocked(Set<Id> setContactIdForSuspendedUsers){
        System.enqueueJob(new UserBlockHelper(setContactIdForSuspendedUsers));
    }
    // Added By Moh Sarfaraj for BPM-391
    class UserBlockHelper implements Queueable,Database.AllowsCallouts {
        Set<Id> setContactIds = new Set<Id>(); 
        
        public UserBlockHelper(set<Id> contactIds){
            setContactIds = contactIds;
        }
        
        public void execute(QueueableContext context){
            List<User> listUsesToUpdate = new List<User>();
            for(User eachUser : [SELECT Id,isActive FROM User WHERE ContactId IN :setContactIds AND isActive = true]){
                eachUser.IsActive = false;
                listUsesToUpdate.add(eachUser);
            }
            if(!listUsesToUpdate.isEmpty()){
                update listUsesToUpdate;
            }
        }
    }    
    
    //BPM-473 - calling from ContactTriggerHandler
    public static Boolean foundDuplicateContactsforAgency(List<Contact> newContacts){
        
        Set<String> contactEmailKeys = new Set<String>();
        Set<String> contactMobileKeys = new Set<String>();
        Set<String> keysToCheck = new Set<String>();
        Set<Id> accountIdSet = new Set<Id>();
        Set<Id> currentContactIdSet = new Set<Id>();
        
        //Switch for duplicate check
        if(System.Label.BPM_PartnerOwnersDuplicateEnable.trim().toUpperCase() == 'FALSE'){
            return false;
        }
        
        for (Contact contact : newContacts) {
            if(contact.RecordTypeId == ALD_Constants.BROKER_AGENT_RT){
                if (contact.Email != null && contact.MobilePhone__c != null && contact.BrokerType__c != null && contact.AccountId != null) {
                    //String key = contact.AccountId + '-' + contact.Email + '-' + contact.MobilePhone + '-' + contact.BrokerType__c;
                    
                    String emailKey = contact.AccountId + '-' + contact.Email + '-' + contact.BrokerType__c;
                    String mobileKey = contact.AccountId + '-' + contact.MobilePhone__c + '-' + contact.BrokerType__c;
                    System.debug('Key for new Cons '+ emailKey);
                    System.debug('Key for new Cons '+ mobileKey);

                    //duplicates.add(key);
                    keysToCheck.add(emailKey); keysToCheck.add(mobileKey);
                    contactEmailKeys.add(emailKey);
                    contactMobileKeys.add(mobileKey);
                    accountIdSet.add(contact.AccountId);
                    currentContactIdSet.add(contact.Id);
                }
            }            
        }
        // Query existing contacts to find duplicates
        Map<String, Contact> existingContacts = new Map<String, Contact>();
        if(!accountIdSet.isEmpty()){
            for (Contact contact : [SELECT Id, AccountId, Email, MobilePhone__c, BrokerType__c
                                    FROM Contact
                                    WHERE AccountId IN : accountIdSet
                                    AND Id NOT IN : currentContactIdSet
                                    AND Email != null
                                    AND MobilePhone__c != null
                                    AND BrokerType__c != null AND AgentStatus__c = 'Active']) 
            {
                //String key = contact.AccountId + '-' + contact.Email + '-' + contact.MobilePhone__c + '-' + contact.BrokerType__c;
                String emailKey = contact.AccountId + '-' + contact.Email + '-' + contact.BrokerType__c;
                String mobileKey = contact.AccountId + '-' + contact.MobilePhone__c + '-' + contact.BrokerType__c;
                System.debug('Key for ex Cons '+ emailKey);
                System.debug('Key for ex Cons '+ mobileKey);
                if (contactEmailKeys.contains(emailKey)) {
                    existingContacts.put(emailKey, contact);
                }
                if(contactMobileKeys.contains(mobileKey)){
                    existingContacts.put(mobileKey, contact);
                }
            }
        }
        
        if(existingContacts != null){
            for (String key : existingContacts.keySet()) {
                if (keysToCheck.contains(key)) {
                    return true;
                }
            }
        }
        return false;
    }

    // Added By Moh Sarfaraj for BPM-554 start
    public static void updateEmailMobileOnRelatedUser(Set<Id> setContactIdToUpdateEmailMobOnUser){
        if(System.isBatch() || System.isFuture() || Test.isRunningTest()){
            System.enqueueJob(new updateEmailMobileOnRelatedUserQueue(setContactIdToUpdateEmailMobOnUser));
        }else{
            updateEmailMobileOnRelatedUserFuture(setContactIdToUpdateEmailMobOnUser);
        }
    }

    @future 
    public static void updateEmailMobileOnRelatedUserFuture(Set<Id> setContactIdToUpdateEmailMobOnUser){
        execute(setContactIdToUpdateEmailMobOnUser);
    }

    public class updateEmailMobileOnRelatedUserQueue implements Queueable{
        Set<Id> setContactIdToUpdateEmailMobOnUser = new Set<Id>();
        public updateEmailMobileOnRelatedUserQueue(Set<Id> setContactIdToUpdateEmailMobOnUser){
            this.setContactIdToUpdateEmailMobOnUser = setContactIdToUpdateEmailMobOnUser;
        }

        public void execute(QueueableContext qc){
            execute(setContactIdToUpdateEmailMobOnUser);
        }
    }

    private static void execute(Set<Id> setContactIdToUpdateEmailMobOnUser){
        List<User> listUsersToUpdate = new List<User>();
        for(User eachUser : [SELECT Id,Email,MobilePhone,Contact.Email,Contact.MobileCountryCode__c,Contact.MobilePhone__c FROM User WHERE ContactId IN :setContactIdToUpdateEmailMobOnUser]){
            eachUser.Email = eachUser?.Contact?.Email;
            eachUser.MobilePhone = String.isNotBlank(eachUser?.Contact?.MobileCountryCode__c) ? '+' + eachUser?.Contact?.MobileCountryCode__c + ' '+eachUser?.Contact?.MobilePhone__c : eachUser?.MobilePhone;
            listUsersToUpdate.add(eachUser);
        }
        if(!listUsersToUpdate.isEmpty() && !Test.isRunningTest()){
            Database.update(listUsersToUpdate, false);
        }
    }
    // Added By Moh Sarfaraj for BPM-554 end
}