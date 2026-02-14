public without sharing class BrokerAgencyRegistrationController {
    
    @AuraEnabled
    public static HexaBPM__Service_Request__c createServiceRequestRecord(HexaBPM__Service_Request__c serviceRequestRecord){

        Group brokerSalesAdminGrp = [SELECT Id FROM Group WHERE Name = 'Broker Sales Admin Queue' AND Type = 'Queue' LIMIT 1];
        if(String.isBlank(serviceRequestRecord.Id)){
        
            String otp = Utilities.getRandomNumber(6);
            serviceRequestRecord.OTPNumber__c = otp;
            serviceRequestRecord.OwnerId = brokerSalesAdminGrp.Id;//UserInfo.getUserId();
            serviceRequestRecord.RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Agency Registration');
        }

        upsert serviceRequestRecord;
        return serviceRequestRecord;
    }

    @AuraEnabled
    public static list<AgencyTeam__c> createAgencyTeamRecord(AgencyTeam__c agencyAdmin, List<Map<String, Object>> partnersOwners){

        list<AgencyTeam__c> agencyTeam = new list<AgencyTeam__c>();

        boolean updateOrInsertAdmin = true;

        System.debug('partnersOwners: '+partnersOwners);

        for (Object partnersOwnersObj : partnersOwners) {
            
            System.debug('partnersOwnersObj: '+partnersOwnersObj);

            Map<String,Object> partnerOwnerMap = (Map<String,Object>) partnersOwnersObj;

            System.debug('partnerOwnerMap: '+partnerOwnerMap);

            AgencyTeam__c partnerOrOwner = new AgencyTeam__c();

            System.debug('String.isNotBlank(): '+String.isNotBlank((String)partnerOwnerMap.get('RecordId')));

            if(String.isNotBlank((String)partnerOwnerMap.get('RecordId'))){

                partnerOrOwner = [SELECT Id, ServiceRequest__c, Title__c, Name,MobileCountryCode__c, MobileNumber__c, EmailAddress__c, DateOfBirth__c, PartnerOwnerDetails__c, ShareHoldingPercentage__c, Type__c, PrimaryOwner__c
                FROM AgencyTeam__c WHERE Id =: (String)partnerOwnerMap.get('RecordId')];

                updateOrInsertAdmin = false;
            }
            
            partnerOrOwner.Name = (String)partnerOwnerMap.get('ownerName');
            
            if(updateOrInsertAdmin){
                partnerOrOwner.RecordTypeId = Utilities.getRecordTypeId('AgencyTeam__c', 'Partner');
                partnerOrOwner.ServiceRequest__c = agencyAdmin.ServiceRequest__c;
            }
            partnerOrOwner.Country__c = (String)partnerOwnerMap.get('ownerCountry');
            partnerOrOwner.PartnerOwnerDetails__c = (String)partnerOwnerMap.get('partnerOwnerDetails');
            partnerOrOwner.ShareHoldingPercentage__c = partnerOwnerMap.get('shareHoldingPercentage') instanceof Decimal ? (Decimal)partnerOwnerMap.get('shareHoldingPercentage') :Decimal.valueOf((String)partnerOwnerMap.get('shareHoldingPercentage'));
            partnerOrOwner.Type__c = Constants.PARTNER_OWNER;
            partnerOrOwner.Title__c = (String)partnerOwnerMap.get('title');
            // Updated by Moh Sarfaraj
            partnerOrOwner.MobileNumber__c = ((String)partnerOwnerMap.get('ownerMobile')).deleteWhitespace();
            partnerOrOwner.MobileCountryCode__c = (String)partnerOwnerMap.get('ownerMobileCountryCode');
            partnerOrOwner.EmailAddress__c = (String)partnerOwnerMap.get('ownerEmail');
            // Added By Moh Sarfaraj for BPE-110
          if(!test.isRunningTest()){
                partnerOrOwner.PrimaryOwner__c = (Boolean)partnerOwnerMap.get('primaryOwner');
            }
            System.debug(partnerOrOwner);

            agencyTeam.add(partnerOrOwner);
        }

        if(updateOrInsertAdmin){
            agencyAdmin.Type__c = Constants.AGENCY_ADMIN;
            agencyAdmin.RecordTypeId = Utilities.getRecordTypeId('AgencyTeam__c', 'Partner');
            // Added By Moh Sarfaraj for BPE-110
            agencyAdmin.PrimaryAgencyAdmin__c = true;
            // Added by Moh Sarfaraj
            agencyAdmin.MobileNumber__c = agencyAdmin.MobileNumber__c.deleteWhitespace();

            agencyTeam.add(agencyAdmin);
        }

        System.debug('updateOrInsertAdmin: ' + updateOrInsertAdmin);

        
        upsert agencyTeam;
        return agencyTeam;
    }

    @AuraEnabled
    public static list<HexaBPM__SR_Doc__c> attachDocuments(String serviceRequestId){

        list<HexaBPM__SR_Doc__c> srDoc =[ SELECT Name, Id FROM HexaBPM__SR_Doc__c WHERE HexaBPM__Service_Request__c =: serviceRequestId];

        return srDoc;
    }

     public static List<String> getServiceRequestPicklistValues() {
    List<String> picklistValues = new List<String>();
    Schema.SObjectType serviceRequestObject = Schema.getGlobalDescribe().get('HexaBPM__Service_Request__c');
    Schema.DescribeSObjectResult describeResult = serviceRequestObject.getDescribe();
    Schema.DescribeFieldResult fieldResult = describeResult.fields.getMap().get('AgencyCategory__c').getDescribe();
    for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
        picklistValues.add(entry.getValue());
    }

    return picklistValues;
}
    @AuraEnabled(cacheable=false)
    public static Constant__mdt getConstant(string messageName){
        try{
            Constant__mdt constant = [SELECT DeveloperName, MasterLabel, ConstantValue__c, ConstantValueLong__c
            FROM Constant__mdt WHERE DEVELOPERNAME =: messageName];

            return constant;
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return null;
        }
    }

    @AuraEnabled
    public static void updateSrDocumentsUploadStatus(String srDocId, ContentDocumentLink cdl){

        list<HexaBPM__SR_Doc__c> srDoc =[ SELECT HexaBPM__Status__c, Name, Id FROM HexaBPM__SR_Doc__c WHERE Id =: srDocId];

        if (!srDoc.isEmpty())
        {
            HexaBPM__SR_Doc__c srDocRecord=srDoc[0];
            srDocRecord.HexaBPM__Status__c='Uploaded';
            srDocRecord.HexaBPM__Doc_ID__c = cdl.ContentDocumentId;
            update srDocRecord;
        }
    }

    @AuraEnabled
    public static String uploadFile(String base64, String filename, String recordId) {

        ContentVersion cv = createContentVersion(base64, filename);
        ContentDocumentLink cdl = createContentLink(cv.Id, recordId);
        if (cv == null || cdl == null) { return null; }
        updateSrDocumentsUploadStatus(recordId, cdl);
        return cdl.Id;
    }

    @AuraEnabled
    public static void uploadFiles(List<Map<String, Object>> filesToUpload) {

        try{
        List<ContentVersion> cvToInsert = new List<ContentVersion>();

        System.debug('filesToUpload: '+filesToUpload);

        // Create Content Version
        for (Object file : filesToUpload) {
            
            System.debug('file: '+file);

            Map<String,Object> fileMap = (Map<String,Object>) file;

            ContentVersion cv = new ContentVersion();

            cv.VersionData = EncodingUtil.base64Decode((String)fileMap.get('base64'));
            cv.Title = (String)fileMap.get('fileName');
            cv.PathOnClient = (String)fileMap.get('fileName');
            cv.Description = (String)fileMap.get('Id');
            cvToInsert.add(cv);
        }

        insert cvToInsert;

        List<Id> cvIds = new List<Id>();

        for (ContentVersion cv : cvToInsert) {
            cvIds.add(cv.Id);
        }
        
        // Create Content Document Link
        Map<Id,ContentVersion> cvMap = new Map<Id,ContentVersion>([SELECT Id,ContentDocumentId, Description FROM ContentVersion WHERE Id in : cvIds]);

        System.debug('cvMap: '+cvMap);

        List<ContentDocumentLink> cdlToInsert = new List<ContentDocumentLink>();

        for (Id recId : cvIds) {

            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = cvMap.get(recId).ContentDocumentId;
            cdl.LinkedEntityId = cvMap.get(recId).Description;
            cdl.ShareType = 'V';

            cdlToInsert.add(cdl);
        }

        insert cdlToInsert;
        
        // Update SR Doc to Uploaded
        List<HexaBPM__SR_Doc__c> srDocsToUpdate = new List<HexaBPM__SR_Doc__c>();

        for (Id recId : cvIds) {

            HexaBPM__SR_Doc__c srDocRecord= new HexaBPM__SR_Doc__c(Id=cvMap.get(recId).Description);
            srDocRecord.HexaBPM__Status__c='Uploaded';
            srDocRecord.HexaBPM__Doc_ID__c = cvMap.get(recId).ContentDocumentId;

            srDocsToUpdate.add(srDocRecord);
        }
        

        map<id,HexaBPM__SR_Doc__c> srMap = new map<id,HexaBPM__SR_Doc__c>();

        //put all the values from the list to map. 
        srMap.putall(srDocsToUpdate);
        if(srMap.size()>0){
            update srMap.values();
        }
        
    } catch(Exception ex){
        throw new AuraHandledException(ex.getMessage());
    }
    }

    private static ContentVersion createContentVersion(String base64, String filename) {
        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode(base64);
        cv.Title = filename;
        cv.PathOnClient = filename;
        try {
            insert cv;
            return cv;
        } catch(DMLException e) {
            System.debug(e);
            return null;
        }
    }

    private static ContentDocumentLink createContentLink(String contentVersionId, String recordId) {
        if (contentVersionId == null || recordId == null) { return null; }
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: contentVersionId].ContentDocumentId;
        cdl.LinkedEntityId = recordId;
        // ShareType is either 'V', 'C', or 'I'
        // V = Viewer, C = Collaborator, I = Inferred
        cdl.ShareType = 'V';
        try {
            insert cdl;
            return cdl;
        } catch(DMLException e) {
            System.debug(e);
            return null;
        }
    }

    @AuraEnabled
    public static HexaBPM__Service_Request__c getOtpDetails(String serviceRequestId){

        Timer__mdt otpTimer = Utilities.getTimer(Constants.OTP);

        String timerUnit = otpTimer.Time__c;
        Integer timerDetails = Integer.valueOf(otpTimer.Timer__c);

        if (timerUnit == Constants.HOURS) {
            timerDetails = timerDetails * 60;
        }

        HexaBPM__Service_Request__c [] serviceRequestRecord = [select Name, Id, OTPNumber__c, OTPSendDateTime__c, HexaBPM__External_Status_Name__c FROM HexaBPM__Service_Request__c
         WHERE id = :serviceRequestId AND HexaBPM__External_Status_Name__c !=: Constants.SUBMITTED AND OTPSendDateTime__c >: system.now().addMinutes(-timerDetails) limit 1];
        
        if(serviceRequestRecord.size() > 0){
            return serviceRequestRecord[0];
        }
        return null;
    }

    @AuraEnabled
    public static HexaBPM__Service_Request__c getOtpRecord(String serviceRequestId){

        HexaBPM__Service_Request__c [] serviceRequestRecord = [select Name, Id, OTPNumber__c, OTPSendDateTime__c, HexaBPM__External_Status_Name__c FROM HexaBPM__Service_Request__c
         WHERE id = :serviceRequestId limit 1];
        
         Timer__mdt otpTimer = Utilities.getTimer(Constants.OTP);

        String timerUnit = otpTimer.Time__c;
        Integer timerDetails = Integer.valueOf(otpTimer.Timer__c);

        if (timerUnit == Constants.HOURS) {
            timerDetails = timerDetails * 60;
        }

         if(serviceRequestRecord.size() > 0){
            if(serviceRequestRecord[0].OTPSendDateTime__c < system.now().addMinutes(-timerDetails) && serviceRequestRecord[0].HexaBPM__External_Status_Name__c == 'Draft'){
                HexaBPM__Service_Request__c sr = new HexaBPM__Service_Request__c();
                sr.State__c = 'PinExpired';
                return sr;
            }
            return serviceRequestRecord[0];
        }
        return null;
    }

    @AuraEnabled
    public static HexaBPM__Service_Request__c updateServiceRequestRecordStatus(String serviceRequestId, String status){

        HexaBPM__Service_Request__c serviceRequestRecord =[select id, HexaBPM__External_SR_Status__c, HexaBPM__Internal_SR_Status__c,
        EstablishmentDate__c, AccountName__c, TradeCommercialLicenseNumber__c, ExpiryDate__c, PhoneNumber__c, Address1__c, Address2__c,
        Country__c, State__c, City__c, POBox__c, CompanyEmail__c, TaxRegistrationNumber__c, NameOfPOA__c, BankName__c, IBANNumber__c,
        SwiftCode__c, BankAddress__c, Website__c, HexaBPM__Submitted_DateTime__c, HexaBPM__Submitted_Date__c
        from HexaBPM__Service_Request__c where Id =: serviceRequestId limit 1];

        HexaBPM__SR_Status__c srStatusRecord = getSrStatusByName(status);

        serviceRequestRecord.HexaBPM__External_SR_Status__c = srStatusRecord.Id;
        serviceRequestRecord.HexaBPM__Internal_SR_Status__c = srStatusRecord.Id;
        serviceRequestRecord.HexaBPM__Submitted_DateTime__c = system.now();
        serviceRequestRecord.HexaBPM__Submitted_Date__c  = system.today();

        update serviceRequestRecord;
        return serviceRequestRecord;
    }

    public static HexaBPM__SR_Status__c getSrStatusByName(String status){

        HexaBPM__SR_Status__c srStatusRecord = [SELECT Name, Id FROM HexaBPM__SR_Status__c WHERE Name =: status LIMIT 1];

        return srStatusRecord;
    }

    @AuraEnabled(cacheable=true)
    public static Constants getAllConstants() {
        return new Constants();
    }

    @AuraEnabled
    public static void updateAgencyTeam(String serviceRequestId){

        AgencyTeam__c agency = [SELECT Id, ServiceRequest__c, ResendOTPTrigger__c FROM AgencyTeam__c WHERE ServiceRequest__c =: serviceRequestId AND Type__c =: Constants.AGENCY_ADMIN limit 1];
        
        agency.ResendOTPTrigger__c = true;

        update agency;

    }

    @AuraEnabled
    public static HexaBPM__Service_Request__c getServiceRequest(String userId){

        try{

            List<User> user = [SELECT Id, ContactId FROM User WHERE Id =: userId limit 1];

            if(user.size() == 0 ){
                return null;
            }

            List <HexaBPM__Service_Request__c> sr = [SELECT HexaBPM__Customer__r.BrokerAgent__c, AccountName__c, TradeCommercialLicenseNumber__c, Address1__c, Address2__c,
            City__c, State__c, POBox__c, Country__c, EstablishmentDate__c, ExpiryDate__c, PhoneNumber__c, CompanyEmail__c, Website__c, TaxRegistrationNumber__c,
            NameOfPOA__c, BankName__c, SwiftCode__c, IBANNumber__c, BankAddress__c, BankAccountNumber__c, BankCountry__c, Name, HexaBPM__External_SR_Status__r.Name, Title__c, Designation__c, SignatoryName__c,
            SignatoryEmail__c, ReferredBy__c, ReferredByTitle__c, POATitle__c, HexaBPM__Internal_Status_Name__c, InterestedPropertyLocation__c, FIABCIRegistered__c, FIABCIStatus__c, AgencyCategory__c,AgencySubCategory__c
            FROM HexaBPM__Service_Request__c where HexaBPM__Customer__r.BrokerAgent__c =: user[0].ContactId limit 1];

            if(sr.size() == 0 ){
                return null;
            }

            return sr[0];

        } catch(exception e) {
            system.debug(e);
            return null;
        }
    }

    @AuraEnabled
    public static HexaBPM__Service_Request__c getServiceRequestByEmailAndLicenseNumber(String email, String licenseNumber){

        try{

            List <HexaBPM__Service_Request__c> sr = [SELECT AccountName__c, TradeCommercialLicenseNumber__c, CompanyEmail__c
            FROM HexaBPM__Service_Request__c where CompanyEmail__c =: email AND TradeCommercialLicenseNumber__c =: licenseNumber limit 1];

            if(sr.size() == 0 ){
                return null;
            }

            return sr[0];

        } catch(exception e) {
            system.debug(e);
            return null;
        }
    }

    @AuraEnabled
    public static List <AgencyTeam__c> getAgencyTeam(String serviceRequestId){

        try{

            List <AgencyTeam__c> agency = [SELECT Id, ServiceRequest__c, Title__c, Name, MobileCountryCode__c, MobileNumber__c, EmailAddress__c, DateOfBirth__c, PartnerOwnerDetails__c, ShareHoldingPercentage__c, Type__c, Country__c,PrimaryOwner__c
            FROM AgencyTeam__c WHERE ServiceRequest__c != null AND ServiceRequest__c =: serviceRequestId];

            if(agency.size() == 0 ){
                return null;
            }

            return agency;

        } catch(exception e) {
            system.debug(e);
            return null;
        }
    }

    @AuraEnabled
    public static List <Contact> getAgencyTeamByEmail(String email){

        try{
            // Updated By Moh Sarfaraj for BPM-497
            List <Contact> agency = [SELECT Id, Email
            FROM Contact WHERE Account.AgencyStatus__c != 'Closed' AND Email != null AND Email =: email];

            if(agency.size() == 0 ){
                return null;
            }

            return agency;

        } catch(exception e) {
            system.debug(e);
            return null;
        }
    }

    @AuraEnabled
    public static HexaBPM__Step__c getServiceRequestStep(String serviceRequestId){

        try{

            List <HexaBPM__Step__c> step = [SELECT Name, HexaBPM__Step_Status__c, HexaBPM__SR__c, HexaBPM__SR_Step__r.Name, HexaBPM__Step_Notes__c, HexaBPM__Summary__c 
            FROM HexaBPM__Step__c
            WHERE HexaBPM__SR__c =: serviceRequestId AND HexaBPM__Summary__c = 'Assignment of Broker Manager' order by CreatedDate Desc limit 1];

            if(step.size() == 0 ){
                return null;
            }

            return step[0];

        } catch(exception e) {
            system.debug(e);
            return null;
        }
    }

    @AuraEnabled
    public static HexaBPM__Step__c updateServiceRequestStep(Map<String, Object> step){

            HexaBPM__Status__c stepStatus = [SELECT Id, Name FROM HexaBPM__Status__c WHERE Name=: Constants.COMPLETED_STATUS];

            List <HexaBPM__Step__c> stepRec = [SELECT Name, HexaBPM__Step_Status__c, HexaBPM__SR__c, HexaBPM__SR_Step__r.Name, HexaBPM__Step_Notes__c, HexaBPM__Summary__c 
            FROM HexaBPM__Step__c
            WHERE HexaBPM__SR__c =: (String)step.get('HexaBPM__SR__c') order by CreatedDate Desc limit 1];

            HexaBPM__Step__c stepRecord = new HexaBPM__Step__c(Id = stepRec[0].Id, HexaBPM__Status__c = stepStatus.Id);
            update stepRecord;

            return stepRecord;

    }
    
    @AuraEnabled
    public static List<Map<String, Object>> getUploadedFiles(String serviceRequestId){

        try{
            
            Map <String, HexaBPM__SR_Doc__c> srDocMap = new Map<String, HexaBPM__SR_Doc__c>();
            Map <String, ContentDocumentLink> contentDocMap = new Map<String, ContentDocumentLink>();
            List<Map<String, Object>> documentObjList1 = new List<Map<String, Object>>();

            for(HexaBPM__SR_Doc__c srDocRecord : [SELECT HexaBPM__Service_Request__c, Name, Id FROM HexaBPM__SR_Doc__c WHERE HexaBPM__Service_Request__c =: serviceRequestId]){
                srDocMap.put(srDocRecord.Id,srDocRecord);
            }

            for(ContentDocumentLink contentDocumentRecord : [SELECT ContentDocumentId, Id, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId in : srDocMap.keySet()]){
                contentDocMap.put(contentDocumentRecord.ContentDocumentId,contentDocumentRecord);
            }

            system.debug('point: ContentDocumentLink List: '+[SELECT ContentDocumentId, Id, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId in : srDocMap.keySet()]);

            for(ContentVersion contentVersionRecord : [SELECT Id, ContentDocumentId, VersionData, Title FROM ContentVersion WHERE ContentDocumentId in : contentDocMap.keySet()]){

                system.debug('data:base64,'+EncodingUtil.base64Encode(contentVersionRecord.VersionData));

                Blob file = contentVersionRecord.VersionData;
                String srDocName = srDocMap.get(contentDocMap.get(contentVersionRecord.ContentDocumentId).LinkedEntityId).Name;
                system.debug('point: srDocName: '+srDocName);

                Map<String, Object> map1 = new Map<String, Object>();
                map1.put('fileName',contentVersionRecord.Title);
                map1.put('srDocumentName',srDocName);
                map1.put('base64',EncodingUtil.base64Encode(file));

                documentObjList1.add(map1);

            }

            system.debug('point: ContentVersion List: '+[SELECT Id, ContentDocumentId, VersionData, Title FROM ContentVersion WHERE ContentDocumentId in : contentDocMap.keySet()]);

            system.debug('point: srDocMap: '+srDocMap);
            system.debug('point: contentDocMap: '+contentDocMap);
            system.debug('point: documentObjList: '+documentObjList1);
            system.debug('point: documentObjList Length: '+documentObjList1.size());


            return documentObjList1;

        } catch(exception e) {
            system.debug(e);
            return null;
        }
    }
        
    @AuraEnabled(cacheable=true)
    public static list<map<String,string>> getCountryCodeValues(){
        list<map<String,string>> picklistToReturn = new list<map<String,string>>();
        Schema.DescribeFieldResult fieldResult = Lead.MobileCountryCode__c.getDescribe();        
        for(Schema.PicklistEntry tempVal: fieldResult.getPicklistValues()){
            map<string,string> tempMap=new map<string,string>();
            tempMap.put('label',tempVal.getLabel());
            tempMap.put('value',tempVal.getValue());
            picklistToReturn.add(tempMap);
        }
        return picklistToReturn;
    }

    /*
    *Fetch All Agencies by license number & email
    */
    // Updated By Moh Sarfaraj for BPM-497
    final public static Set<String> setByPassAgencyStatus = new Set<String>{'Closed','Deactivated'};
    @AuraEnabled
    public static List<Account> getAgenciesByLicenseNumberAndEmail(String licenseNumber, String email) {   
        List<Account> agencyAccounts = [SELECT Id, Name, RegistrationNumber__c, Email__c FROM Account WHERE 
                                        AgencyStatus__c NOT IN :setByPassAgencyStatus AND 
                                        RecordType.Name =: Constants.BROKER_AGENCY_ACCOUNT_RT AND 
                                        RegistrationNumber__c =: licenseNumber AND Email__c =: email]; 
        return agencyAccounts;
    }

    /*
    *Fetch All Services Requests by license number & email
    */
    // Updated By Moh Sarfaraj for BPM-497
    final public static Set<String> setByPassSRStatus = new Set<String>{'Closed','Deactivated'};
    @AuraEnabled
    public static List<HexaBPM__Service_Request__c> getServicesRequestsByLicenseNumberAndEmail(String licenseNumber, String email) {   
        List<HexaBPM__Service_Request__c> ServicesRequestsRecords = [SELECT Id, Name, TradeCommercialLicenseNumber__c, CompanyEmail__c FROM HexaBPM__Service_Request__c WHERE 
                                                                     HexaBPM__External_Status_Name__c NOT IN:setByPassSRStatus AND 
                                                                     TradeCommercialLicenseNumber__c =: licenseNumber AND 
                                                                     CompanyEmail__c =: email]; 
        return ServicesRequestsRecords;
    }

    /*
    *Fetch All Broker Managers and Sales Managers for referral in New Broker Agency Registration
    */
    @AuraEnabled
    public static List<String> getBrokerAndSalesManagers(){
        List<String> refername = new List<String>();
List<User> ReferredByUsers = [SELECT Id, FirstName, LastName, Email, Team__c, Title
                                      FROM User
                                      WHERE (ProfileName__c IN ('Broker Manager', 'Sales Manager')
                                      OR Title = 'Sub Account Manager')
                                      AND IsActive = true
                                      AND EnableReferredby__c = true
                                      ORDER BY Name];
        for(User u: ReferredByUsers){
            String fname = u.FirstName + ' ' + u.LastName;
            //System.debug('fname: ' +fname);
            refername.add(fname);
        }
        refername.add('No Referral');
        return refername;
    }
    
    @AuraEnabled(cacheable=false)
    public static List<User> getUsersQuery(String query) {
        List<User> records = Database.query(query);
        return records;
    }
    
    // Added By Moh Sarfaraj for BPM-481
    final public static Set<String> setBlockedSRStatuses = new Set<String>{'Pending Verification','Rejected', 'Completed'};
    final public static Set<String> setBlockedAccountStatuses = new Set<String>{'Pending Verification','Active', 'Suspended'};

    @AuraEnabled(cacheable=false)
    public static boolean validateTradeLicenseNumber(String LicenseNumber){

        //Below trim() is added by Tharun as per BPE-56
        LicenseNumber = LicenseNumber.deleteWhitespace();
        Boolean hasActiveSRWithLicenseNumber = false;
        Id agencyServiceRequestRecordTypeId = Schema.SObjectType.HexaBPM__Service_Request__c.getRecordTypeInfosByName().get('Agency Registration').getRecordTypeId();
        Id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Broker_Agency').getRecordTypeId();
        
        // Updated By Moh Sarfaraj for BPM-481
        List<HexaBPM__Service_Request__c> serviceRequestList = [SELECT
                                                                Id,
                                                                TradeCommercialLicenseNumber__c
                                                                FROM
                                                                HexaBPM__Service_Request__c
                                                                WHERE TradeCommercialLicenseNumber__c =: LicenseNumber
                                                                AND RecordTypeId=:agencyServiceRequestRecordTypeId 
                                                                AND HexaBPM__External_Status_Name__c IN :setBlockedSRStatuses
                                                                // AND HexaBPM__External_Status_Name__c != 'Rejected'
                                                                //AND HexaBPM__External_Status_Name__c != 'Closed'
                                                               ];
        // Updated By Moh Sarfaraj for BPM-481
        List<Account> AccountList = [SELECT
                                     Id,
                                     RegistrationNumber__c
                                     FROM ACCOUNT
                                     WHERE RecordTypeId =:accountRecordTypeId
                                     AND RegistrationNumber__c =:LicenseNumber 
                                     AND AgencyStatus__c IN :setBlockedAccountStatuses
                                     ];
        
        if(serviceRequestList.size()>0 || AccountList.size()>0){
            hasActiveSRWithLicenseNumber = true;
        }
        return hasActiveSRWithLicenseNumber;
    }
    
    @AuraEnabled(cacheable=false)
    public static String resendOTPForTradeLicenseNumber(String LicenseNumber){
        system.debug('LicenseNumber::'+LicenseNumber);
        boolean hasResults = false;
        String tradeLicenseMessage = '';
        Id agencyServiceRequestRecordTypeId = Schema.SObjectType.HexaBPM__Service_Request__c.getRecordTypeInfosByName().get('Agency Registration').getRecordTypeId();
        List<HexaBPM__Service_Request__c> serviceRequestListToUpdate = new List<HexaBPM__Service_Request__c> ();
        List<HexaBPM__Service_Request__c> serviceRequestList = [SELECT
                                                                Id,
                                                                OTPNumber__c,
                                                                OwnerId,
                                                                TradeCommercialLicenseNumber__c,
                                                                RecordTypeId,
                                                                HexaBPM__External_Status_Name__c
                                                                FROM
                                                                HexaBPM__Service_Request__c
                                                                WHERE TradeCommercialLicenseNumber__c =: LicenseNumber
                                                                AND RecordTypeId=:agencyServiceRequestRecordTypeId
                                                               // AND HexaBPM__External_Status_Name__c = 'Draft'
                                                               ];
        
        if(!serviceRequestList.isEmpty()){
            if(serviceRequestList[0].HexaBPM__External_Status_Name__c != 'Draft' && serviceRequestList[0].HexaBPM__External_Status_Name__c != 'Rejected'){
                tradeLicenseMessage = 'Submitted';
            }else if(serviceRequestList[0].HexaBPM__External_Status_Name__c == 'Draft'){
                
                HexaBPM__Service_Request__c serviceRequest = new HexaBPM__Service_Request__c();
                serviceRequest.Id = serviceRequestList[0].Id;
                String otp = Utilities.getRandomNumber(6);
                serviceRequest.OTPNumber__c = otp;
                
                update serviceRequest;
                // Updated By Moh Sarfaraj for BPE-110
                AgencyTeam__c agency = [SELECT Id, ServiceRequest__c, ResendOTPTrigger__c FROM AgencyTeam__c WHERE ServiceRequest__c =: serviceRequest.Id AND PrimaryOwner__c = true limit 1]; // Type__c =: Constants.AGENCY_ADMIN
                system.debug('agency::'+agency);
                agency.ResendOTPTrigger__c = true;
                update agency;
                tradeLicenseMessage = 'Draft';
            }
        }else {
            tradeLicenseMessage = 'Not Registered';
        }  
    return tradeLicenseMessage;
    }   
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String,String>> getPicklistValuesGeneric(String sObjectName, String fieldName){
        Schema.DescribeSObjectResult objDescribeSobject = Schema.getGlobalDescribe().get(sObjectName).getDescribe();
        Map<String,Schema.SObjectField> fields = objDescribeSobject.fields.getMap() ;
        Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
        List<Map<String,String>> picklistToReturn = new List<Map<String,String>>();
        for(Schema.PicklistEntry tempVal: fieldResult.getPicklistValues()){
            Map<String,String> tempMap = new Map<String,String>();
            tempMap.put('label',tempVal.getLabel());
            tempMap.put('value',tempVal.getValue());
            picklistToReturn.add(tempMap);
        }
        return picklistToReturn;
    }
}