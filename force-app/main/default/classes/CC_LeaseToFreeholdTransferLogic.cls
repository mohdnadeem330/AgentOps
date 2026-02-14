global without sharing class CC_LeaseToFreeholdTransferLogic implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{

            if(stp == null || stp.HexaBPM__SR__c == null){
                result='cc_LeaseToFreeholdTransferLogic: Invalid SR or SR Step';
            }else{

                HexaBPM__Service_Request__c sRRecord = [SELECT Id, HexaBPM__Contact__c, HexaBPM__Contact__r.Email FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];
                
                if(stp.HexaBPM__Summary__c == 'Issue NOC to Customer'){
                    issueNOCToCustomerLogic(sRRecord);
                }
            } 
        } catch(Exception e){
            result = e.getMessage()+' :cc_LeaseToFreeholdTransferLogic';
        }
        return result;
    }

    /*
    *  To send NOC customer Email
    * 
    */
    public static void issueNOCToCustomerLogic(HexaBPM__Service_Request__c sRRecord) {

        HexaBPM__SR_Doc__c nocDocument = [SELECT Name, Id, HexaBPM__Customer__c FROM HexaBPM__SR_Doc__c WHERE HexaBPM__Service_Request__c =: sRRecord.Id AND Name =: Constants.NOC_DOCUMENT];
        Map <String, ContentDocumentLink> contentDocMap = new Map<String, ContentDocumentLink>();

        for(ContentDocumentLink contentDocumentRecord : [SELECT ContentDocumentId, Id, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId =: nocDocument.Id]){
            contentDocMap.put(contentDocumentRecord.ContentDocumentId,contentDocumentRecord);
        }
                
        if(contentDocMap != null && !contentDocMap.isEmpty()){
            List<ContentVersion> contentVersionRecords = [SELECT Id, ContentDocumentId, VersionData, Title FROM ContentVersion WHERE ContentDocumentId in : contentDocMap.keySet()];
            
            List<Messaging.EmailFileAttachment> emailAttachList = new List<Messaging.EmailFileAttachment>();
            
            for(ContentVersion cvObj : contentVersionRecords) {
                emailAttachList.add(Utilities.setEmailFileAtt(cvObj));            
            }

            String orgWideEmailAddress='';
        for(OrgWideEmailAddress tempRec: [select id,Address from OrgWideEmailAddress where DisplayName= :Constants.ALDAR_PROPERTIES_ORGWIDEEMAIL_CUSTOMER_CARE limit 1 ]){
            orgWideEmailAddress=tempRec.id;
        }

            String emailTemplateId = Utilities.getEmailtemplateIdByName(Constants.FREEHOLD_NOC_TO_CUSTOMER);
            List<String> toAddress = new List<String>();
            toAddress.add(sRRecord.HexaBPM__Contact__r.Email);
            Messaging.SingleEmailMessage mail = Utilities.getEmailInstance(sRRecord.HexaBPM__Contact__c, emailTemplateId, sRRecord.Id, toAddress, null, null, null, null, null, emailAttachList, orgWideEmailAddress);
            Utilities.sendEmail(new list<Messaging.SingleEmailMessage>{mail});
        }
    }
}