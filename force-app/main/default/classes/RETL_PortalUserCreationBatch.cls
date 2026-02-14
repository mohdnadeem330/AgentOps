public class RETL_PortalUserCreationBatch implements Database.Batchable<SObject>, Database.Stateful {
	public List<Id> contactIds = new List<Id>();
    public List<Id> newUserIds = new List<Id>();
    public Boolean sendWelcomeEmail = false;

    public RETL_PortalUserCreationBatch(List<Id> conIds, Boolean sendWelcomeEmail) {
        this.contactIds = conIds;
        this.sendWelcomeEmail = sendWelcomeEmail;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Email, FirstName, LastName, AccountId, MobilePhone
            FROM Contact
            WHERE Id IN :contactIds AND Email != null
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Contact> scope) {
        if(!scope.isEmpty()){
            List<User> usersToCreate = new List<User>();
            List<PermissionSetAssignment> perSetAssignments = new List<PermissionSetAssignment>();
            String profileName = Label.Retail_Tenant_Portal_Profile;
            String permSetName = Label.Retail_Tenant_Portal_Permission_Set;//'Retail_Tenant_Permissions';
            List<PermissionSet> retailTenantPermission = [SELECT Id FROM PermissionSet WHERE Name = :permSetName LIMIT 1];
            Profile portalProfile = [SELECT Id, name FROM Profile WHERE Name  =: profileName];
            Organization org = Utilities.getOrganizationDetails();
            Boolean isSandbox  = org.IsSandbox;
            List<String> userNames = new List<String>();
            Map<Id,String> conIdnewUserNameMap = new Map<Id,String>();
            for(Contact con : scope){
                List<String> emailSplit = con.Email.split('@');
                String emailFirstThree = emailSplit[0].left(3);
                String uName = emailFirstThree + con.Id + '@aldar.retail.tenant';
                userNames.add(uName);
                conIdnewUserNameMap.put(con.Id,uName);
            }
            list<User> userList = [Select Id, ContactId from User where Username IN :userNames AND ContactId IN :scope];
            system.debug('userList'+userList + ' userNames'+userNames);
            Map<Id,User> contactIdUserMap = new Map<Id,User>();
            Map<Id,Id> userIdContactIdMap = new Map<Id,Id>();
            Map<Id,PermissionSetAssignment> contactIdPermessionAssignmentMap = new Map<Id,PermissionSetAssignment>();
            if(!userList.isEmpty()){
                for(User u : userList){
                    contactIdUserMap.put(u.ContactId,u);
                    userIdContactIdMap.put(u.Id,u.ContactId);
                }
                List<PermissionSetAssignment> permissionsAssigned = [Select Id, AssigneeId from PermissionSetAssignment where PermissionSet.Name =: permSetName and  AssigneeId IN :userList];
                if(!permissionsAssigned.isEmpty()){
                    for(PermissionSetAssignment psa: permissionsAssigned){
                       String contactId =  userIdContactIdMap.get(psa.AssigneeId);
                        contactIdPermessionAssignmentMap.put(contactId,psa);
                    }
                }
            }


            for(Contact con : scope){
                if(!contactIdUserMap.ContainsKey(con.Id)){
                    String email = isSandbox? con.Email + '.invalid' : con.Email;
                    String alias;
                    if (con.LastName != null && con.LastName.length() >= 3) {
                         alias = con.LastName.substring(0, 3)+Integer.valueof((Math.random() * 10000));
                        System.debug('Alias: ' + Alias);
                    } else {
                        System.debug('LastName is too short or null');
                        alias = con.LastName+Integer.valueof((Math.random() * 10000));
                    }

                    User portalUser = new User(
                        Username = conIdnewUserNameMap.get(con.Id),
                        ContactId = con.Id,
                        ProfileId = portalProfile.Id,
                        Alias = alias,
                        Email = email,
                        MobilePhone = con.MobilePhone,
                        EmailEncodingKey = 'UTF-8',
                        FirstName = con.FirstName,
                        LastName = con.LastName,
                        CommunityNickname = con.LastName+string.valueOf(math.random()).substring(0,6),
                        TimeZoneSidKey = 'Asia/Dubai',
                        LocaleSidKey = 'en_US',
                        LanguageLocaleKey = 'en_US',
                        UserPreferencesDisableAllFeedsEmail = true
                    );
                    usersToCreate.add(portalUser);
                }
                else{
                    if(!contactIdPermessionAssignmentMap.ContainsKey(con.Id)){
                        if (!retailTenantPermission.isEmpty()) {
                            PermissionSetAssignment psa = new PermissionSetAssignment(
                                AssigneeId = contactIdUserMap.get(con.Id).Id,
                                PermissionSetId = retailTenantPermission[0].Id
                            );
                            perSetAssignments.add(psa);
                        }
                    }
                }
            }

            if(!usersToCreate.isEmpty()){
                try{
                    Database.DMLOptions dlo = new Database.DMLOptions();
                    dlo.EmailHeader.triggerUserEmail= false;
                    List<Database.SaveResult> results = Database.insert(usersToCreate,dlo);
                    for (Database.SaveResult sr : results) {
                        if (sr.isSuccess()) {
                            System.debug('Successfully inserted record with ID: ' + sr.getId());
                            if(sr.getId() != null){
                                Id userId = sr.getId();
                                newUserIds.add(userId);
                                // Fetch Permission Set Id
                                if (!retailTenantPermission.isEmpty()) {
                                    PermissionSetAssignment psa = new PermissionSetAssignment(
                                        AssigneeId = userId,
                                        PermissionSetId = retailTenantPermission[0].Id
                                    );
                                    perSetAssignments.add(psa);
                                }
                            }
                        }
                    }
                }
                catch (DmlException e) {
                    System.debug('Error creating portal user: ' + e.getMessage());
                    LoggerService.save(LoggerService.addApexLog(e,'RetailPortalUserCreationFailed','RETL_PortalContactCreation','createPortalUser'));
                }
            }
            if(!perSetAssignments.isEmpty()){
                try{
                    System.debug('Permission Set assigned successfully!');
                    Database.Insert(perSetAssignments,false);
                }
                catch (DmlException e) {
                    System.debug('Error assigning Permission Set: ' + e.getMessage());
                    LoggerService.save(LoggerService.addApexLog(e,'RetailPortalUserPermissionAssignmentFailed','RETL_PortalContactCreation','createPortalUser'));
                }
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('PortalUserCreationBatch finished successfully.');

        if (!newUserIds.isEmpty()) {
            List<Id> newuserContactIds = new List<Id>();
            for( user newUser : [SELECT Id, ContactId FROM User WHERE Id IN : newUserIds]){
                newuserContactIds.add(newUser.ContactId);
            }
            if(!newuserContactIds.isEmpty()){
                List<Contact> contactsToUpdate = [SELECT Id, Email FROM Contact WHERE Id IN: newuserContactIds];
                system.debug('contactsToUpdate'+contactsToUpdate);

                for(Contact con : contactsToUpdate){
                    con.Is_User_Created__c = true;
                }

                try {
                    update contactsToUpdate;
                }
                catch (DmlException e) {
                    System.debug('Error updating contact record: ' + e.getMessage());
                    LoggerService.save(LoggerService.addApexLog(e,'RetailPortalUserContactUpdateFailed','RETL_PortalContactCreation','createPortalUser'));
                }

                // Send welcome email to newly created portal users
                if(sendWelcomeEmail) {
                    sendWelcomeEmails(contactsToUpdate);
                }
            }
        }
    }

    public static void sendWelcomeEmails(List<Contact> contacts) {
        // Email template API Name (change this to your actual one)
        String templateDeveloperName = 'RETL_Welcome_to_Live_Aldar';

        List<EmailTemplate> et = [
            SELECT Id
            FROM EmailTemplate
            WHERE DeveloperName = :templateDeveloperName
            LIMIT 1
        ];
        /*ID org =[ Select Id FROM OrgWideEmailAddress Where Address = 'noreply@aldar.com'].ID; */
		List<OrgWideEmailAddress> owea = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address='noreply@aldar.com'];
        if (et == null || et.isEmpty()) {
            System.debug('Email Template not found: ' + templateDeveloperName);
            return;
        }

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Contact c : contacts) {
            if (String.isNotBlank(c.Email)) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTargetObjectId(c.Id);
                mail.setWhatId(c.Id);
                mail.setTemplateId(et[0].Id);
                mail.setToAddresses(new List<String>{ c.Email });
                mail.setSaveAsActivity(false);
                if(!owea.isEmpty()){
                    mail.setOrgWideEmailAddressId(owea[0].Id);
                }
                emails.add(mail);
            }
        }

        if (!emails.isEmpty()) {
            try {
                Messaging.sendEmail(emails);
                System.debug('Welcome emails sent successfully for ' + emails.size() + ' users.');
            } catch (Exception e) {
                LoggerService.save(LoggerService.addApexLog(
                    e, 'RetailPortalWelcomeEmailFailed', 'RETL_PortalContactCreation', 'sendWelcomeEmails'
                ));
            }
        }
    }
}