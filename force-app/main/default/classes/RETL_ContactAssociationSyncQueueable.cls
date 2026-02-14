public class RETL_ContactAssociationSyncQueueable implements Queueable, Database.AllowsCallouts {

    private List<Id> roleIds; 
    //private String yardiContactCode;

    public RETL_ContactAssociationSyncQueueable(List<Id> rIds) {
        this.roleIds = rIds;
        //this.yardiContactCode = yCode;
    }

    public void execute(QueueableContext qc) {

        String className = 'RETL_ContactAssociationSyncQueueable';
        String methodName = 'execute';
        List<RETL_Contact_role__c> rolesToUpdate = new List<RETL_Contact_role__c>();
        Map<String, String> valueToLabel = new Map<String, String>();
        try {
            /*
             ======================================================
                LOAD ROLE RECORD
             ======================================================
            */
            List<RETL_Contact_role__c> roles = [
                SELECT Id, RETL_Contact_role__c,RETL_Account_Name__r.RETL_Yardi_Id__c, RETL_Contact__r.RETL_Yardi_Id__c,
                       RETL_Primary__c, RETL_Contact__c,RETL_Opportunity__r.RETL_Yardi_Id__c,RETL_Role_Type__c
                FROM RETL_Contact_role__c
                WHERE Id IN :roleIds 
            ];
            //System.debug('contact code-->'+yardiContactCode);

            for (Schema.PicklistEntry pe :
                RETL_Contact_role__c.RETL_Role_Type__c.getDescribe().getPicklistValues()) {
                valueToLabel.put(pe.getValue(), pe.getLabel());
            }

            /*
             ======================================================
                BUILD ASSOCIATION PAYLOAD
             ======================================================
            */
            for (RETL_Contact_role__c currentRole : roles) {

                String label = valueToLabel.get(currentRole.RETL_Role_Type__c);
                string isPrimaryLeasingAgent = '0';
                string recordCode ='';                
                if (label == 'Customer') {
                    recordCode = currentRole.RETL_Account_Name__r.RETL_Yardi_Id__c;
                }else if(label == 'Commercial Prospect'){
                    recordCode = currentRole.RETL_Opportunity__r.RETL_Yardi_Id__c;
                    //isPrimaryLeasingAgent = '-1';
                }
                if(currentRole.RETL_Contact_role__c == 'Leasing Manager'){
                    isPrimaryLeasingAgent = '-1';
                }

                RETL_ContactYardiWrapper.YardiAssociationWrapper wrapper =
                    new RETL_ContactYardiWrapper.YardiAssociationWrapper();

                wrapper.ContactAssociation =
                    new List<RETL_ContactYardiWrapper.YardiContactAssociation>();

                RETL_ContactYardiWrapper.YardiContactAssociation assoc =
                    new RETL_ContactYardiWrapper.YardiContactAssociation();
                
                assoc.Role_Description = currentRole.RETL_Contact_role__c;
                assoc.Record_code = recordCode;
                assoc.Is_Primary = currentRole.RETL_Primary__c ? '-1' : '0';
                assoc.Object_Type = currentRole.RETL_Role_Type__c;//'1783';
                assoc.Yardi_Contact_Code = currentRole.RETL_Contact__r.RETL_Yardi_Id__c;
                assoc.SF_Ref_Contact_Id = currentRole.id;
                assoc.PrimaryLeasingAgent = isPrimaryLeasingAgent;
                
                if (recordCode != null && recordCode.trim() != '') {
                    wrapper.ContactAssociation.add(assoc);
                }

                if (wrapper.ContactAssociation.isEmpty()) {
                    System.debug('No ContactAssociation records. Skipping callout.');
                    continue; // skip this loop item but continue queueable
                }

                MuleSoftSetting__mdt api =
                    Utilities.getMuleSoftDetails('RETL_ContactAssociationSyncQueueable');

                /*
                ======================================================
                    CALLOUT TO SEND ASSOCIATION
                ======================================================
                */
                System.debug('payload== ' + JSON.serialize(wrapper));
                HttpResponse response = CalloutToMuleSoft.makeCallout(
                    api.DeveloperName,
                    JSON.serialize(wrapper)
                );

                Integer statusCode = response.getStatusCode();
                String resBody = response.getBody();

                System.debug('YARDI ASSOCIATION RESPONSE: ' + resBody);

                if (statusCode >= 200 && statusCode < 300 && !String.isBlank(resBody)) {
                    RETL_ContactYardiWrapper.YardiContactAssociationResponse responseObj =
                        (RETL_ContactYardiWrapper.YardiContactAssociationResponse)
                            JSON.deserialize(resBody, RETL_ContactYardiWrapper.YardiContactAssociationResponse.class);

                    System.debug('Parsed Association Response: ' + responseObj);

                    // Extract Yardi ID
                    if (!String.isBlank(responseObj.Y_ContactAssociation_Id)) {
                        currentRole.RETL_Yardi_Id__c = responseObj.Y_ContactAssociation_Id;
                        rolesToUpdate.add(currentRole);
                    }
                }
                else {
                    throw new CustomException(
                        'Association Sync Failed. Code: ' + statusCode + ' Body: ' + resBody
                    );
                }
            }
            if (!rolesToUpdate.isEmpty()) {
                update rolesToUpdate;
            }

        } catch (Exception e) {
            LoggerService.save(
                LoggerService.addApexLog(e, 'Association Sync to Yardi', className, methodName)
            );
            throw e;
        }
    }
}