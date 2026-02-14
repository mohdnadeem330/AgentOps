public class InitiateResaleController {
    
    @AuraEnabled
    public static Map<String, Object> getRecordDetails(Id recordId) {
        Map<String, Object> mapReturnValue = new Map<String, Object>();
        System.debug('recordId : '+recordId);
        if(recordId != null){
            String objectApiName = recordId.getSObjectType().getDescribe().getName();
            System.debug('objectApiName : '+objectApiName);
            switch on objectApiName {
                when 'SalesOrder__c' {
                    mapReturnValue = getSalesOrderDetails(recordId);
                }
                // when 'Case' {
                //     mapReturnValue = getCaseDetails(recordId);
                // }
            }
            if(mapReturnValue != null && !mapReturnValue.isEmpty()){
                mapReturnValue.put('type',objectApiName);
                Id devRecordTypeId = ResaleConstants.Resale_Case_RecordTypeId;
                mapReturnValue.put('recordTypeId',devRecordTypeId);
            }
        }
        return mapReturnValue;
    }

    public static Map<String, Object> getSalesOrderDetails(Id recordId){
        Map<String, Object> mapReturnValue = new Map<String, Object>();

        SalesOrder__c sc = ResaleService.getSalesOrder(recordId);System.debug(JSON.serializePretty( sc ));
        if(sc == null){
            throw new AuraHandledException('Record does not exist.');
        }
        String unitValidationError = ResaleService.checkIfCaseExistForSelectedUnit(sc.Unit__c);
        if(unitValidationError != null){
            throw new AuraHandledException(unitValidationError); // ResaleConstants.OPEN_RESALE_CASE_PER_UNIT_VALIDATION);
        }
        mapReturnValue.put('salesOrder',sc);
        
        mapReturnValue.put('accountEmail',sc.Account__r.PersonEmail);
        
        String pName = [SELECT Id, Name FROM Profile WHERE Id =: UserInfo.getProfileId() LIMIT 1][0].Name;
        mapReturnValue.put('profile', pName);
        switch on pName {
            when 'Contact Centre Agent' {
                mapReturnValue.put('origin', '800-Aldar');
                mapReturnValue.put('status', 'In Progress');
            }
            when 'Resale Relationship Manager' {
                mapReturnValue.put('origin', 'Direct Call');
                mapReturnValue.put('status', 'In Progress');
            }
            when 'Sales Manager' {
                mapReturnValue.put('salesManagerId', UserInfo.getUserId());
            }
        }
        if(!mapReturnValue.containsKey('origin')){
            mapReturnValue.put('origin', 'Direct Email');
        }
        if(!mapReturnValue.containsKey('status')){
            mapReturnValue.put('status', 'New');
        }
        return mapReturnValue;
    }

    // @AuraEnabled
    // public static Id updateVerifiedCase(Id recordId){
    //     try {
    //         update new Case(
    //                     Id = recordId,
    //                     IsOTPVerified__c = true
    //                 );
    //         return recordId;
    //     } catch (Exception e) {
    //         throw new AuraHandledException(e.getMessage());
    //     }
    // }

    // public static Map<String, Object> getCaseDetails(Id recordId){
    //     Map<String, Object> mapReturnValue = new Map<String, Object>();

    //     Case cs = ResaleService.getCase(recordId);System.debug(JSON.serializePretty( cs ));
    //     if(cs == null){
    //         throw new AuraHandledException('Invalid Record Id.');
    //     }
    //     if(cs.RecordType.DeveloperName != ResaleConstants.RESALE_CASE_RecordTypeDeveloperName){
    //         throw new AuraHandledException('Invalid Case Type '+cs.RecordType.Name +' for this action.');
    //     }
    //     // if(cs.IsOTPVerified__c){
    //     //     throw new AuraHandledException('OTP has been already Verified');
    //     // }
    //     mapReturnValue.put('case',cs);
        
    //     mapReturnValue.put('accountEmail',cs.Account.PersonEmail);
        
    //     return mapReturnValue;
    // }

    // @AuraEnabled
    // public static String sendOtpSingleEmail(String emailAddr){
    //     try {
    //         if(emailAddr != null){
    //             String otp = Utilities.getRandomNumber(6);
    //             return sendOtp(new String[] {emailAddr}, otp);
    //         }else{
    //             throw new AuraHandledException('Email is undefined');
    //         }
    //     } catch (Exception e) {
    //         throw new AuraHandledException(e.getMessage());
    //     }
    // }

    // private static String sendOtp(List<String> emailAddrs, String otp) {
    //     System.debug(otp);
    //     System.debug(emailAddrs);

    //     OrgWideEmailAddress[] owea = [  SELECT Id 
    //                                     FROM OrgWideEmailAddress 
    //                                     WHERE Address = 'noreply@aldar.com'];
    //     System.debug(owea);
    //     Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    //     String[] toAddresses = emailAddrs;

    //     mail.setToAddresses(toAddresses);
    //     mail.setOrgWideEmailAddressId(owea.get(0).Id);

    //     mail.setSubject('OTP for Resale Listing, Do not share.');
        
    //     mail.setPlainTextBody('Please share this OTP with the Agent: '+ otp +'.');
    //     mail.setHtmlBody('Please share this OTP with the Agent: \n </b>'+ otp +'</b>. \n Thanks.');
        
    //     Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

    //     return otp;
    // }

    // @AuraEnabled
    // public static Case getCaseRecord(Id recordId, List<String> fields){
    //     try {
    //         if(recordId != null){
    //             String query = 'SELECT Id, RecordTypeId ';
    //             for(String f: fields){
    //                 query += ', '+f;
    //             }
    //             query += 'FROM Case WHERE Id =: recordId';
    //             return Database.query(query);
    //         }
    //         throw new AuraHandledException('Invalid Case Id');
    //     } catch (Exception e) {
    //         throw new AuraHandledException(e.getMessage());
    //     }
    // }
}