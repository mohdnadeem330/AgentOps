public class RETL_ContactYardiSyncQueueable implements Queueable, Database.AllowsCallouts {

    // private Id contactId;
    private List<Id> contactIds;
    private Id relatedAccountId;

    /* public RETL_ContactYardiSyncQueueable(Id cId) {
        this.contactId = cId;
    } 

    public RETL_ContactYardiSyncQueueable(List<Id> cIds) {
        this.contactIds = cIds;
    } */

    public RETL_ContactYardiSyncQueueable(List<Id> cIds, Id accId) {
        this.contactIds = cIds;
        this.relatedAccountId = accId;
    }

    public void execute(QueueableContext qc) {

        String className = 'RETL_ContactYardiSyncQueueable';
        String methodName = 'execute';

        //String yardiContactCode;
        Boolean syncContactRoles = false;

        try {
            // if (contactId == null) {
            //     throw new CustomException('Contact Id cannot be null.');
            // }
            if (contactIds == null || contactIds.isEmpty()) {
                throw new CustomException('Contact Ids cannot be null or empty.');
            }
            /*
             ======================================================
                BUILD CONTACT PAYLOAD
             ======================================================
            */
           /*  Contact c = [
                SELECT Id, FirstName, LastName, Email, Phone,
                       MailingCountry, Description,RETL_Yardi_Id__c
                FROM Contact
                WHERE Id = :contactId
                LIMIT 1
            ]; */

            List<Contact> conList = [
                SELECT Id, FirstName, LastName, Email, Phone,
                       MailingCountry, Description,RETL_Yardi_Id__c
                FROM Contact
                WHERE Id IN :contactIds
            ];

            if(conList == null || conList.isEmpty()){
                throw new CustomException('No Contact found for Ids: ' + contactIds);
            }

            for(Contact c : conList){
            
                if(c.RETL_Yardi_Id__c != null){
                    //Contact already has Yardi Id, no need to sync again
                    System.debug('Contact already synced with Yardi. Yardi Contact Code: ' + c.RETL_Yardi_Id__c);
                    syncContactRoles = true;
                    //yardiContactCode = c.RETL_Yardi_Id__c;
                }
                else{
                    //Contact does not have Yardi Id, need to sync
                    /*  String leasingManagerYardiEmpCode = c.RETL_Yardi_Id__c != null? c.RETL_Yardi_Id__c : '';
                    user LeasingManager = [SELECT Id, Name,RETL_Yardi_Leasing_Manager_Code__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
                    if( LeasingManager != null && LeasingManager.RETL_Yardi_Leasing_Manager_Code__c != null){
                        leasingManagerYardiEmpCode = LeasingManager.RETL_Yardi_Leasing_Manager_Code__c;
                    } */

                    RETL_ContactYardiWrapper.YardiContactWrapper payload =
                        new RETL_ContactYardiWrapper.YardiContactWrapper();

                    payload.Contacts = new List<RETL_ContactYardiWrapper.YardiContact>();

                    RETL_ContactYardiWrapper.YardiContact yc = new RETL_ContactYardiWrapper.YardiContact();
                    yc.First_Name = c.FirstName;
                    yc.Last_Name = c.LastName;
                    yc.Email = c.Email;
                    yc.PhoneNumber_1 = c.Phone;
                    yc.Country = c.MailingCountry;
                    yc.SF_Ref_Contact_Id = c.Id;
                    yc.Contact_Notes = c.Description;
                    //yc.Yardi_Contact_Code = leasingManagerYardiEmpCode;
                    yc.Yardi_Contact_Code = '';
                    payload.Contacts.add(yc);

                    /*
                    ======================================================
                        ENDPOINT CONFIG (FROM METADATA)
                    ======================================================
                    */
                    MuleSoftSetting__mdt api = Utilities.getMuleSoftDetails('RETL_ContactYardiSyncQueueable');
                    /*
                    ======================================================
                        CALLOUT TO SEND CONTACT
                    ======================================================
                    */
                    payload.normalize(); // Replace Null with ""
                    HttpResponse response = CalloutToMuleSoft.makeCallout(
                        api.DeveloperName,
                        JSON.serialize(payload)
                    );

                    if (response == null) {
                        throw new CustomException('No response received from Yardi system.');
                    }

                    Integer statusCode = response.getStatusCode();
                    String resBody = response.getBody();

                    System.debug('YARDI CONTACT RESPONSE: ' + resBody);

                    if (statusCode >= 200 && statusCode < 300 && !String.isBlank(resBody)) {

                        RETL_ContactYardiWrapper.YardiContactResponseWrapper res =
                            (RETL_ContactYardiWrapper.YardiContactResponseWrapper)
                            JSON.deserialize(resBody, RETL_ContactYardiWrapper.YardiContactResponseWrapper.class);

                        /*
                        ======================================================
                            UPDATE CONTACT WITH YARDI CODE
                        ======================================================
                        */
                        if (!String.isBlank(res.Yardi_Contact_Code)) {
                            update new Contact(
                                Id = c.Id,
                                RETL_Yardi_Id__c = res.Yardi_Contact_Code
                            );
                            //yardiContactCode = res.Yardi_Contact_Code;
                            syncContactRoles = true;
                        }

                    } else {
                        throw new CustomException(
                            'Contact Sync Failed. Code: ' + statusCode + ' Body: ' + resBody
                        );
                    }
                }
            }

            if(syncContactRoles){
                /*
                ======================================================
                    QUEUE EACH CONTACT ASSOCIATION (ONE AT A TIME) in RETL_ContactAssociationSyncQueueable
                ======================================================
                */
                List<RETL_Contact_role__c> roles = [
                    SELECT Id, RETL_Contact__c, RETL_Contact__r.RETL_Yardi_Id__c
                    FROM RETL_Contact_role__c
                    WHERE RETL_Contact__c IN :contactIds 
                        AND RETL_Contact__r.RETL_Yardi_Id__c != null 
                        AND RETL_Yardi_Id__c = null
                        AND (RETL_Account_Name__c = :relatedAccountId OR RETL_Opportunity__r.AccountId = :relatedAccountId)
                ];

                List<Id> roleIdsToSync = new List<Id>();
                for (RETL_Contact_role__c roleRec : roles) {
                    roleIdsToSync.add(roleRec.Id);
                }
                if (roleIdsToSync.size() > 0 ){
                    
                    System.enqueueJob(
                        new RETL_ContactAssociationSyncQueueable(
                            roleIdsToSync
                            /*, yardiContactCode*/
                        )
                    );
                }
            }

        } catch (Exception e) {
            LoggerService.save(
                LoggerService.addApexLog(e, 'Contact Sync to Yardi', className, methodName)
            );
            throw e;
        }
    }
}