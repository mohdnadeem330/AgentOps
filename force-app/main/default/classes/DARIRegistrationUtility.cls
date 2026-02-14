/**
 * @description       : This class used for.
 * @coverage          : DARIRegistrationUtilityTest.cls | @CC100%
 * @author            : rmohmmed@aldar.com
 * @group             : Aldar
 * @last modified on  : 02-01-2024
 * @last modified by  : rmohmmed@aldar.com
 * Modifications Log
 * Ver   Date         Author                        Modification
 * 1.0   02-01-2024   rmohmmed@aldar.com            Initial Version | Story Number | @CC100%
 **/
public class DARIRegistrationUtility {
    /**
     * @description create Application as a draft in Dari
     * @author rmohmmed@aldar.com | 02-01-2024 | Story Number
     * @param srId
     * @return void
     **/
    @future(callout = true)
    public static void createApplicationFuture(Id srId) {
        createApplication(srId);
    }
    
    public static void createApplication(Id srId) {
        try {
            HexaBPM__Service_Request__c srRecord = getSRRecord(srId);
            SalesOrder__c so = SalesOrderService.queryAllFieldsWithExtraFields(new List<Id>{srRecord.SalesOrder__c})[0];
            User userDetail = [SELECT Id, EmirateId__c FROM USER WHERE Id =: UserInfo.getUserId()];
            String tradelincense = srRecord.Unit__r.Project__r.Trade_License_No__c == null ? System.Label.TradeLicenseNumber : srRecord.Unit__r.Project__r.Trade_License_No__c;
            String endpointParameter = '?tradeLicenseNo=' + tradelincense + '&emiratesID=' + userDetail.EmirateId__c  + '&unifiedNumber';
            
            DARIRegistrationModel.createapplication createapp = new DARIRegistrationModel.createapplication();
            String recordTypeName = Utilities.getRecordTypeName('Unit__c', so.Unit__r.recordTypeId);
            List<String> plotRecordTypes = Label.PlotRecordTypes.split(',');
            
            // check the record type
            if(plotRecordTypes.contains(recordTypeName)) {
                createApp.dmtNumber = 'AbuDhabi.' + so.Unit__r.ADMSectorName__c + '.' + so.Unit__r.ADMPlotNumber__c;
                createApp.applicationType = 'OFFPLAN_TO_COMPLETE_LAND';
            } else {
                //AbuDhabi
                createApp.dmtNumber = 'AbuDhabi.' + so.Unit__r.ADMSectorName__c + '.' + so.Unit__r.ADMPlotNumber__c + '.' + so.Unit__r.ADMBuildingNumber__c + '.' + so.Unit__r.ADMUnitNumber__c;
                createApp.applicationType = 'OFFPLAN_TO_COMPLETE_UNIT';
            }
            
            if(srRecord.MortgageApplicable__c == 'Yes') {
                createapp.withMortgage = true; 
            } else if(srRecord.MortgageApplicable__c == 'No') {
                createapp.withMortgage = false; 
            }
            
            String reqBody = json.serialize(createapp);
            
            Map<String,String> headerConfiguration = new Map<String,String>();
            headerConfiguration.put('Content-Type', 'application/json');
            headerConfiguration.put('Accept', 'application/json');
            HttpResponse response = DRACalloutHelper(headerConfiguration, reqBody, 'dariCreateApplication', endpointParameter);
            DARIRegistrationModel.createApplicationResponse createApplicationResponse = (DARIRegistrationModel.createApplicationResponse)JSON.deserialize(response.getBody(), DARIRegistrationModel.createApplicationResponse.class);
            DARIRegistrationModel.Result result = createApplicationResponse.results.result;
            System.debug(result);
            Boolean success = createApplicationResponse.results.success;
            String stepNotes = '';
            
            LoggerService.save(LoggerService.addApexServiceCalls('Draft Application', 'DARIRegistrationUtility', 'createApplication', (reqBody.length() < 131072 ? reqBody : ''), response.getBody(), null));
      
            if(!success) {
                stepNotes = result.description;
                SRUtility.updateServiceRequestStep(srId, 'Initiate Registration', Constants.PENDING_STATUS, stepNotes);
            } else {
                SRUtility.updateServiceRequestStep(srId, 'Initiate Registration', Constants.COMPLETED_STATUS, 'Draft Application Completed');
                
                HexaBPM__SR_Status__c objSRStatus = [SELECT Id, Name FROM HexaBPM__SR_Status__c WHERE Name =: Constants.COMPLETED_STATUS LIMIT 1];
                sRRecord.HexaBPM__External_SR_Status__c = objSRStatus.Id;
                sRRecord.HexaBPM__Internal_SR_Status__c = objSRStatus.Id;
                srRecord.ApplicationId__c = result.id;
                srRecord.Application_Type__c = result.applicationType;
                srRecord.ApplicationNumber__c = result.applicationNumber;
                srRecord.ApplicationDate__c = System.today();
                srRecord.InProgressDate__c = System.today();
                srRecord.PremiseRequired__c = result.isPremiseIdRequired;
                update srRecord;
            }
            
        } catch(Exception e) {
            SRUtility.updateServiceRequestStep(srId, 'Initiate Registration', Constants.PENDING_STATUS, e.getMessage());
            LoggerService.save(LoggerService.createApexLog(e, 'Draft Application', 'DARIRegistrationUtility', 'createApplication'));
        }
    }
    
    /**
     * @description fetch Application Data and update SR
     * @author rmohmmed@aldar.com | 02-01-2024 | Story Number
     * @param srId
     * @return void
     **/
    public static void fetchApplicationFuture(Id srId) {
        fetchApplication(srId);
    }
    public static void fetchApplication(Id srId) {
        try {
            Map<String, Id> recordTypeSR = new Map<String, Id>();
            for(Recordtype rtype : [SELECT Id, DeveloperName FROM Recordtype WHERE SObjectType = 'AgencyTeam__c' AND DeveloperName = 'Partner']){
                recordTypeSR.put(rtype.DeveloperName, rtype.Id);
            }
            
            HexaBPM__Service_Request__c srRecord = getSRRecord(srId);
            User userDetail = [SELECT Id, EmirateId__c FROM USER WHERE Id =: UserInfo.getUserId()];
            String tradelincense = srRecord.Unit__r.Project__r.Trade_License_No__c == null ? System.Label.TradeLicenseNumber : srRecord.Unit__r.Project__r.Trade_License_No__c;
            String reqBody = '?tradeLicenseNo=' + tradelincense + '&emiratesID=' + userDetail.EmirateId__c  + '&unifiedNumber&applicationId=' + srRecord.ApplicationId__c;
            
            Map<String,String> headerConfiguration = new Map<String,String>();
            headerConfiguration.put('Content-Type', 'application/json');
            headerConfiguration.put('Accept', 'application/json');
            
            HttpResponse response = DRACalloutHelper(headerConfiguration, '', 'dariFetchApplication', reqBody);
            
            DARIRegistrationModel.fetchApplicationResponse fetch = (DARIRegistrationModel.fetchApplicationResponse) System.JSON.deserialize(response.getBody(), DARIRegistrationModel.fetchApplicationResponse.class);
            DARIRegistrationModel.AppResult appResult = fetch.results.result;
            LoggerService.save(LoggerService.addApexServiceCalls('Fetch Application', 'DARIRegistrationUtility', 'fetchApplication', (reqBody.length() < 131072 ? reqBody : ''), response.getBody(), null));
            if(fetch.results.success) {
                DARIRegistrationModel.ApplicationDetails appData = appResult.applicationDetails;
                //srRecord.ApplicationId__c = appData.applicationId;
                srRecord.Application_Type__c = appData.applicationType;
                //srRecord.ApplicationNumber__c = appData.applicationNumber;
                update srRecord;
                System.debug(appResult.buyers);
                List<DARIRegistrationModel.Buyers> buyerList = (List<DARIRegistrationModel.Buyers>)appResult.buyers;
                List<AgencyTeam__c> agencyTeamList = new List<AgencyTeam__c>();
                
                if(!buyerList.isEmpty()) {
                    for(DARIRegistrationModel.Buyers buyer : buyerList) {
                        AgencyTeam__c team = new AgencyTeam__c();
                        team.Name = buyer.ownerNameEn;
                        team.EmailAddress__c = buyer <> null && buyer.email <> null ? buyer.email.contains('@') ? buyer.email : '':'';
                        team.MobileNumber__c = buyer.phoneNumber;
                        team.ServiceRequest__c = srRecord.Id;
                        team.RecordTypeId = recordTypeSR.get('Partner');                        
                        team.Passport_No__c = buyer.passportNumber != null ? buyer.passportNumber : ''; //passportNumber
                        team.National_Id__c = buyer.eidOrUnified != null ? buyer.eidOrUnified : '';
                        team.Owner_Id__c = buyer.ownerId != null ? buyer.ownerId : '';
                        agencyTeamList.add(team);
                    }
                    
                    insert agencyTeamList;
                }
                
                SRUtility.updateServiceRequestStep(srId, 'Fetch Application', Constants.COMPLETED_STATUS, 'Fetch Application Step Completed');
            } else {
                LoggerService.save(LoggerService.addApexServiceCalls('Fetch Application', 'DARIRegistrationUtility', 'fetchApplication', (reqBody.length() < 131072 ? reqBody : ''), response.getBody(), null));
            }   
        } catch(Exception e) {
            LoggerService.save(LoggerService.createApexLog(e, 'Fetch Application','DARIRegistrationUtility','fetchApplication'));
        }
    }
    
    /**
     * @description Push Mortgage Details to DARI
     * @author rmohmmed@aldar.com | 02-01-2024 | Story Number
     * @param srId
     * @return void
     **/
    @future(callout = true)
    public static void postMortgageDetailsFuture(Id srId) {
        postMortgageDetails(srId);
    }
    
    public static void postMortgageDetails(Id srId) {
        HexaBPM__Service_Request__c srRecord = getSRRecord(srId);
        User userDetail = [SELECT Id, EmirateId__c FROM USER WHERE Id =: UserInfo.getUserId()];
        String tradelincense = srRecord.Unit__r.Project__r.Trade_License_No__c == null ? System.Label.TradeLicenseNumber : srRecord.Unit__r.Project__r.Trade_License_No__c;
        String endpointParameter = '?tradeLicenseNo=' + tradelincense + '&emiratesID=' + userDetail.EmirateId__c  + '&applicationId=' + srRecord.ApplicationId__c + '&unifiedNumber';
        
        DARIRegistrationModel.MortgageDetails mortgageDetail = new DARIRegistrationModel.MortgageDetails();
        DARIRegistrationModel.Mortgage mor = new DARIRegistrationModel.Mortgage();
        DARIRegistrationModel.BankDetails bankDetail = new DARIRegistrationModel.BankDetails();
        DARIRegistrationModel.PropertyDetails propertyDetail = new DARIRegistrationModel.PropertyDetails();
        mortgageDetail.applicationId = Integer.valueOf(srRecord.ApplicationId__c);
        mortgageDetail.key = 'mortgage-details-initiator';
        propertyDetail.isSharedMortgage = false;
        bankDetail.bankCompanyId = srRecord.MortgageBank__r.BankCompanyId__c != null ? Integer.valueOf(srRecord.MortgageBank__r.BankCompanyId__c) : 0;
        
        mor.bankDetails = bankDetail;
        mor.propertyDetails = propertyDetail;
        mortgageDetail.mortgage = mor;
        String reqBody = json.serialize(mortgageDetail);
        
        Map<String,String> headerConfiguration = new Map<String,String>();
        headerConfiguration.put('Content-Type', 'application/json');
        headerConfiguration.put('Accept', 'application/json');
        HttpResponse response = DRACalloutHelper(headerConfiguration, reqBody, 'dariPostMortgageDetails', endpointParameter);
        
        DARIRegistrationModel.MortgageDetailsResponse responseDetail = (DARIRegistrationModel.MortgageDetailsResponse) System.JSON.deserialize(response.getBody(), DARIRegistrationModel.MortgageDetailsResponse.class);
        DARIRegistrationModel.Result result = responseDetail.results.result;
        Boolean success = responseDetail.results.success;
        LoggerService.save(LoggerService.addApexServiceCalls('Mortgage Registration', 'postMortgageDetails', 'fetchApplication', (reqBody.length() < 131072 ? reqBody : ''), response.getBody(), null));
        if(success == true) {
            //postPropertyDetails
            //postUploadDocument(srId, srRecord.ApplicationId__c, new List<String>{'Mortgage Agreement'});
            ID jobID = System.enqueueJob(new DARIRegistrationQueueable('postUploadDocument', sRRecord.Id));
            //update SR Steps 
            SRUtility.updateServiceRequestStep(srId, 'Mortgage Registration', Constants.COMPLETED_STATUS, 'Mortgage Registration Step Completed');
        } else {
            //update SR Steps 
            SRUtility.updateServiceRequestStep(srId, 'Mortgage Registration', Constants.PENDING_STATUS, result + ' - ' + response.getStatusCode());
            LoggerService.save(LoggerService.addApexServiceCalls('Mortgage Registration', 'DARIRegistrationUtility', 'postMortgageDetails', reqBody, response.getBody(), null));
        }
    }
    
    /**
     * @description Push Property Details to DARI
     * @author rmohmmed@aldar.com | 02-01-2024 | Story Number
     * @param srId
     * @return void
     **/
    public static void postPropertyDetails(Id srId) {
        HexaBPM__Service_Request__c srRecord = getSRRecord(srId);
        User userDetail = [SELECT Id, EmirateId__c FROM USER WHERE Id =: UserInfo.getUserId()];
        String tradelincense = srRecord.Unit__r.Project__r.Trade_License_No__c == null ? System.Label.TradeLicenseNumber : srRecord.Unit__r.Project__r.Trade_License_No__c;
        String endpointParameter = '?tradeLicenseNo=' + tradelincense + '&emiratesID=' + userDetail.EmirateId__c + '&unifiedNumber';
        
        DARIRegistrationModel.PropertyDetail propertyDetail = new DARIRegistrationModel.PropertyDetail();
        DARIRegistrationModel.PropDetails PropDetails = new DARIRegistrationModel.PropDetails();
        PropDetails.premiseNumber = srRecord.Unit__r.ADDCPremiseId1__c;
        PropDetails.premisesAddress = srRecord.Unit__r.ADDCPremiseId2__c;
        
        propertyDetail.applicationId = Integer.valueOf(srRecord.ApplicationId__c);
        propertyDetail.key = 'property-details';
        propertyDetail.propertyDetails = PropDetails;
        
        String reqBody = json.serialize(propertyDetail);
        
        Map<String,String> headerConfiguration = new Map<String,String>();
        headerConfiguration.put('Content-Type', 'application/json');
        headerConfiguration.put('Accept', 'application/json');
        HttpResponse response = DRACalloutHelper(headerConfiguration, reqBody, 'dariPostMortgageDetails', endpointParameter);
        DARIRegistrationModel.MortgageDetailsResponse responseDetail = (DARIRegistrationModel.MortgageDetailsResponse) System.JSON.deserialize(response.getBody(), DARIRegistrationModel.MortgageDetailsResponse.class);
        DARIRegistrationModel.Result result = responseDetail.results.result;
        Boolean success = responseDetail.results.success;
        LoggerService.save(LoggerService.addApexServiceCalls('Mortgage Registration', 'DARIRegistrationUtility', 'postPropertyDetails', (reqBody.length() < 131072 ? reqBody : ''), response.getBody(), null));
        if(success == true) {
            if(!Test.isRunningTest()) {
                ID jobID = System.enqueueJob(new DARIRegistrationQueueable('postRegistrationFeeDetails', sRRecord.Id));
            }
            //update SR Steps 
            //SRUtility.updateServiceRequestStep(srId, 'Mortgage Registration', Constants.COMPLETED_STATUS, 'Mortgage Registration Step Completed');
        } else {
            //update SR Steps 
            SRUtility.updateServiceRequestStep(srId, 'Registration In Progress', Constants.PENDING_STATUS, result + ' - ' + response.getStatusCode());
            LoggerService.save(LoggerService.addApexServiceCalls('Propert yDetails', 'DARIRegistrationUtility', 'postPropertyDetails', reqBody, response.getBody(), null));
        }        
    }
    
    /**
     * @description Push Registration Fee Details to DARI
     * @author rmohmmed@aldar.com | 02-01-2024 | Story Number
     * @param srId
     * @return void
     **/
    @future(callout = true)
    public static void postRegistrationFeeDetailsFuture(Id srId) {
        postRegistrationFeeDetails(srId);
    }
    
    public static void postRegistrationFeeDetails(Id srId) {
        HexaBPM__Service_Request__c srRecord = getSRRecord(srId);
        User userDetail = [SELECT Id, EmirateId__c FROM USER WHERE Id =: UserInfo.getUserId()];
        String tradelincense = srRecord.Unit__r.Project__r.Trade_License_No__c == null ? System.Label.TradeLicenseNumber : srRecord.Unit__r.Project__r.Trade_License_No__c;
        String endpointParameter = '?tradeLicenseNo=' + tradelincense + '&emiratesID=' + userDetail.EmirateId__c  + '&unifiedNumber';
        
        DARIRegistrationModel.RegistrationFeeDetail registrationFeeDetail = new DARIRegistrationModel.RegistrationFeeDetail();
        DARIRegistrationModel.RegistrationFeeDetails regDetails = new DARIRegistrationModel.RegistrationFeeDetails();
        
        DARIRegistrationModel.RegistrationFeeDetailWithoutLiability registrationFeeDetailWithoutLiability = new DARIRegistrationModel.RegistrationFeeDetailWithoutLiability();
        DARIRegistrationModel.RegistrationFeeDetailsWithoutLiability regDetailsWithoutLiability = new DARIRegistrationModel.RegistrationFeeDetailsWithoutLiability();
        String reqBody = '';
        
        if(srRecord.LiabilityAmount__c != null) {
            regDetails.paidBy = srRecord.Pay_By__c;
            regDetails.enrollPropertyInTawteeq = false;
            regDetails.payLiability = true;
            regDetails.liabilityPaidBy = 'BUYER';
            registrationFeeDetail.registrationFeeDetails = regDetails;
            registrationFeeDetail.applicationId = Integer.valueOf(srRecord.ApplicationId__c);
            registrationFeeDetail.key = 'registration-fee-details';
            reqBody = json.serialize(registrationFeeDetail);            
        } else {
            regDetailsWithoutLiability.paidBy = srRecord.Pay_By__c;
            regDetailsWithoutLiability.enrollPropertyInTawteeq = false;
            registrationFeeDetailWithoutLiability.registrationFeeDetails = regDetailsWithoutLiability;
            registrationFeeDetailWithoutLiability.applicationId = Integer.valueOf(srRecord.ApplicationId__c);
            registrationFeeDetailWithoutLiability.key = 'registration-fee-details';
            reqBody = json.serialize(registrationFeeDetailWithoutLiability);
        }
        
        
        System.debug('reqBody==> ' + reqBody);
        System.debug('endpointParameter==> ' + endpointParameter);
        
        Map<String,String> headerConfiguration = new Map<String,String>();
        headerConfiguration.put('Content-Type', 'application/json');
        headerConfiguration.put('Accept', 'application/json');
        HttpResponse response = DRACalloutHelper(headerConfiguration, reqBody, 'dariPostMortgageDetails', endpointParameter);
        
        DARIRegistrationModel.MortgageDetailsResponse responseDetail = (DARIRegistrationModel.MortgageDetailsResponse) System.JSON.deserialize(response.getBody(), DARIRegistrationModel.MortgageDetailsResponse.class);
        DARIRegistrationModel.Result result = responseDetail.results.result;
        Boolean success = responseDetail.results.success;
        LoggerService.save(LoggerService.addApexServiceCalls('Property Details', 'DARIRegistrationUtility', 'postRegistrationFeeDetails', (reqBody.length() < 131072 ? reqBody : ''), response.getBody(), null));
        if(success == true) {
            //submitApplication(srId);
            ID jobID = System.enqueueJob(new DARIRegistrationQueueable('submitApplication', sRRecord.Id));
        } else {
            //update SR Steps 
            SRUtility.updateServiceRequestStep(srId, 'Registration In Progress', Constants.PENDING_STATUS, result + ' - ' + response.getStatusCode());
            LoggerService.save(LoggerService.addApexServiceCalls('Property Details', 'DARIRegistrationUtility', 'postRegistrationFeeDetails', reqBody, response.getBody(), null));
        }
    }
    
    /**
     * @description Push Morgage Document to DARI
     * @author rmohmmed@aldar.com | 02-01-2024 | Story Number
     * @param srId Id
     * @param applicationId Decimal
     * @param srDocumentsNames List
     * @return void
     **/
    public static void postUploadDocument(Id srId, Decimal applicationId, List<String> srDocumentsNames) {
        try{
            HexaBPM__Service_Request__c srRecord = getSRRecord(srId);
            User userDetail = [SELECT Id, EmirateId__c FROM USER WHERE Id =: UserInfo.getUserId()];
            String tradelincense = srRecord.Unit__r.Project__r.Trade_License_No__c == null ? System.Label.TradeLicenseNumber : srRecord.Unit__r.Project__r.Trade_License_No__c;
            
            String endpointParameter = '?tradeLicenseNo=' + tradelincense + '&emiratesID=' + userDetail.EmirateId__c  + '&applicationId=' + applicationId;
            
            Map<String, List<DARIRegistrationModel.UploadDocumentRequest>> documentToUpload = getUploadedFiles(srId, srDocumentsNames);
            Map<String, String> mapName = new Map<String, String>();
            List<HexaBPM__SR_Doc__c> srDocsMap = [SELECT Id, HexaBPM__Service_Request__c, Name, HexaBPM__Comments__c FROM HexaBPM__SR_Doc__c WHERE HexaBPM__Service_Request__c =: srId AND Name IN : documentToUpload.keySet()];
            Map<String, HexaBPM__SR_Doc__c> docNameWithSRRecord = new Map<String, HexaBPM__SR_Doc__c>();
            DARIRegistrationModel.UploadDocumentRequest  uploadReq = new DARIRegistrationModel.UploadDocumentRequest();
            for (HexaBPM__SR_Doc__c srDoc : srDocsMap) {
                docNameWithSRRecord.put(srDoc.Name, srDoc); 
            }
            
            for(String documentName : documentToUpload.keySet()) {
                HexaBPM__SR_Doc__c srDocRecord = docNameWithSRRecord.get(documentName);
                for (DARIRegistrationModel.UploadDocumentRequest uploadDocRequest : documentToUpload.get(documentName)) {
                    mapName.put('fileData', uploadDocRequest.fileData);
                    uploadReq = uploadDocRequest;
                }
            }
            
            String reqBody = json.serialize(mapName);
            endpointParameter = endpointParameter + '&applicationType=OFFPLAN_TO_COMPLETE_LAND' + '&documentType=DEVELOPER_NOC' + '&subType=APPLICATION_' + srRecord.ApplicationId__c + '.NOC_FROM_DEVELOPER_1' + '&fileName=' + EncodingUtil.urlEncode(uploadReq.fileName, 'UTF-8');
            
            Map<String, String> headerConfiguration = new Map<String, String>();
            headerConfiguration.put('Content-Type', 'application/json');
            headerConfiguration.put('Accept', 'application/json');
            HttpResponse response = DRACalloutHelper(headerConfiguration, reqBody, 'dariUploadDocument', endpointParameter);
            
            Map<String, String> responseMap = JSONParserCtrl(response); 
            String success = responseMap.get('success');
            String error = responseMap.get('error');
            
            HexaBPM__SR_Doc__c srDocRecord = new HexaBPM__SR_Doc__c(Id=uploadReq.srDocId);
            Datetime now = Datetime.now();
            Integer offset = UserInfo.getTimezone().getOffset(now);
            Datetime local = now.addSeconds(offset/1000);
            
            LoggerService.save(LoggerService.addApexServiceCalls('Upload Document', 'DARIRegistrationUtility', 'postUploadDocument', (reqBody.length() < 131072 ? reqBody : ''), response.getBody(), null));
            if(success.equalsIgnoreCase('true')){
                //update HexaBPM__SR_Doc__c
                srDocRecord.SyncStatus__c = Constants.STATUS_SYNCED;
                srDocRecord.HexaBPM__Comments__c = local + ': Uploaded';
            } else {
                srDocRecord.SyncStatus__c = Constants.STATUS_FAILED;
                srDocRecord.HexaBPM__Comments__c = local + ':' + 'Fail - '+ error;
            }
            
            update srDocRecord;
            
        } catch(Exception e) {
            LoggerService.save(LoggerService.createApexLog(e,'Upload Document','DARIRegistrationUtility','postUploadDocument'));
        }
    }
    
    @future(callout = true)
    public static void submitApplicationFuture(Id srId) {
        submitApplication(srId);
    }
    
    /**
     * @description Submit Application to DARI
     * @author rmohmmed@aldar.com | 02-01-2024 | Story Number
     * @param srId Id
     * @return void
     **/
    public static void submitApplication(Id srId){
        try{
            HexaBPM__Service_Request__c srRecord = getSRRecord(srId);
            User userDetail = [SELECT Id, EmirateId__c FROM USER WHERE Id =: UserInfo.getUserId()];
            String tradelincense = srRecord.Unit__r.Project__r.Trade_License_No__c == null ? System.Label.TradeLicenseNumber : srRecord.Unit__r.Project__r.Trade_License_No__c;
            String endpointParameter =  '?unifiedNumber&tradeLicenseNo=' + tradelincense + '&emiratesID=' + userDetail.EmirateId__c  + '&applicationId=' + srRecord.ApplicationId__c;
            String reqBody = '';
            Map<String, String> headerConfiguration = new Map<String, String>();
            headerConfiguration.put('Content-Type', 'application/json');
            headerConfiguration.put('Accept', 'application/json');
            
            HttpResponse response = DRACalloutHelper(headerConfiguration, '', 'dariSubmitApplication', endpointParameter);
            
            Map<String, String> responseMap = JSONParserCtrl(response); 
            String success = responseMap.get('success');
            String error = responseMap.get('error');
            
            LoggerService.save(LoggerService.addApexServiceCalls('Submit Application', 'DARIRegistrationUtility', 'submitApplication', (reqBody.length() < 131072 ? reqBody : ''), response.getBody(), null));
            if(success.equalsIgnoreCase('true')) {
                SRUtility.updateServiceRequestStep(srId, 'Registration In Progress', Constants.COMPLETED_STATUS, 'Registration In Progress Step Completed');
                ID jobID = System.enqueueJob(new DARIRegistrationQueueable('getPaymentBreakdown', sRRecord.Id));
            } else {
                SRUtility.updateServiceRequestStep(srId, 'Registration In Progress', Constants.PENDING_STATUS, error + ' - ' + response.getStatusCode());
            }
            
        } catch(Exception e){
            LoggerService.save(LoggerService.createApexLog(e,'submit Application','DARIRegistrationUtility','submitApplication'));
        }
    }
    
    /**
     * @description Send Approval to DARI
     * @author rmohmmed@aldar.com | 02-01-2024 | Story Number
     * @param srId Id
     * @return void
     **/
    @future(callout = true)
    public static void postDeveloperApprovalFuture(Id srId) {
        postDeveloperApproval(srId);
    }
    
    
    public static void postDeveloperApproval(Id srId) {
        try{
            HexaBPM__Service_Request__c srRecord = getSRRecord(srId);
            User userDetail = [SELECT Id, EmirateId__c FROM USER WHERE Id =: UserInfo.getUserId()];
            String tradelincense = srRecord.Unit__r.Project__r.Trade_License_No__c == null ? System.Label.TradeLicenseNumber : srRecord.Unit__r.Project__r.Trade_License_No__c;
            String endpointParameter = '?tradeLicenseNo=' + tradelincense + '&emiratesID=' + userDetail.EmirateId__c  + '&unifiedNumber';
            
            DARIRegistrationModel.DeveloperApproval approval = new DARIRegistrationModel.DeveloperApproval();
            approval.applicationId = Integer.valueOf(srRecord.ApplicationId__c);
            approval.approved = true;
            String reqBody = json.serialize(approval);
            
            Map<String,String> headerConfiguration = new Map<String,String>();
            headerConfiguration.put('Content-Type', 'application/json');
            headerConfiguration.put('Accept', 'application/json');
            HttpResponse response = DRACalloutHelper(headerConfiguration, reqBody, 'dariDeveloperApproval', endpointParameter);
            
            DARIRegistrationModel.Response responseDetail = (DARIRegistrationModel.Response) System.JSON.deserialize(response.getBody(), DARIRegistrationModel.Response.class);
            Map<String, String> responseMap = JSONParserCtrl(response); 
            String success = responseMap.get('success');
            String error = responseMap.get('error');
            LoggerService.save(LoggerService.addApexServiceCalls('Submit Application', 'DARIRegistrationUtility', 'submitApplication', (reqBody.length() < 131072 ? reqBody : ''), response.getBody(), null));
            if(success.equalsIgnoreCase('true')) {
                SRUtility.updateServiceRequestStep(srId, 'Salesforce - Approval', Constants.STEP_APPROVED_STATUS, 'App Approved');
            } else {
                SRUtility.updateServiceRequestStep(srId, 'Salesforce - Approval', Constants.PENDING_STATUS, 'Error - ' + response.getStatusCode());
            }
        } catch(Exception e){
            LoggerService.save(LoggerService.createApexLog(e,'Salesforce - Approval','DARIRegistrationUtility','postDeveloperApproval'));
        }
    }
    
    /**
     * @description Cancell App to DARI and Update SR
     * @author rmohmmed@aldar.com | 02-01-2024 | Story Number
     * @param srId Id
     * @return void
     **/
    @future(callout = true)
    public static void cancellationAppFuture(Id srId) {
        cancellationApp(srId);
    }
    
    public static void cancellationApp(Id srId) {
        try {
            HexaBPM__Service_Request__c srRecord = getSRRecord(srId);
            User userDetail = [SELECT Id, EmirateId__c FROM USER WHERE Id =: UserInfo.getUserId()];
            String tradelincense = srRecord.Unit__r.Project__r.Trade_License_No__c == null ? System.Label.TradeLicenseNumber : srRecord.Unit__r.Project__r.Trade_License_No__c;
            String reqBody = '?tradeLicenseNo=' + tradelincense + '&emiratesID=' + userDetail.EmirateId__c  + '&applicationId=' + srRecord.ApplicationId__c + '&status=CANCEL';
            
            Map<String,String> headerConfiguration = new Map<String,String>();
            headerConfiguration.put('Content-Type', 'application/json');
            headerConfiguration.put('Accept', 'application/json');        
            HttpResponse response = DRACalloutHelper(headerConfiguration, '', 'dariCancelApplication', reqBody);
            
            DARIRegistrationModel.Response responseDetail = (DARIRegistrationModel.Response) System.JSON.deserialize(response.getBody(), DARIRegistrationModel.Response.class);
            Map<String, String> responseMap = JSONParserCtrl(response); 
            String success = responseMap.get('success');
            String error = responseMap.get('error');
            LoggerService.save(LoggerService.addApexServiceCalls('Salesforce - Approval', 'DARIRegistrationUtility', 'cancellationApp', (reqBody.length() < 131072 ? reqBody : ''), response.getBody(), null));
            
            if(success.equalsIgnoreCase('true')) {
                SRUtility.updateServiceRequestStep(srId, 'Salesforce - Approval', Constants.STEP_REJECTED_STATUS, 'App Rejected');
                sRRecord.ApplicationNumber__c = '';
                sRRecord.ApplicationId__c = null;
                update sRRecord;
            } else {
                SRUtility.updateServiceRequestStep(srId, 'Salesforce - Approval', Constants.PENDING_STATUS, error);
            }
            
        } catch(Exception e) {
            LoggerService.save(LoggerService.createApexLog(e, 'Cancel Approval', 'DARIRegistrationUtility','cancellationApp'));
        }
    }
    
    /**
     * @description Fetch Payment Info from DARI and update in SR
     * @author rmohmmed@aldar.com | 02-01-2024 | Story Number
     * @param srId Id
     * @return void
     **/
    @future(callout = true)
    public static void getPaymentBreakdownFuture(Id srId) {
        getPaymentBreakdown(srId);
    }
    
    public static void getPaymentBreakdown(Id srId) {
        try {
            HexaBPM__Service_Request__c srRecord = getSRRecord(srId);
            User userDetail = [SELECT Id, EmirateId__c FROM USER WHERE Id =: UserInfo.getUserId()];
            String tradelincense = srRecord.Unit__r.Project__r.Trade_License_No__c == null ? System.Label.TradeLicenseNumber : srRecord.Unit__r.Project__r.Trade_License_No__c;
            String endpointParam = '?tradeLicenseNo=' + tradelincense + '&emiratesID=' + userDetail.EmirateId__c  + '&unifiedNumber&applicationId=' + srRecord.ApplicationId__c;
            
            Map<String,String> headerConfiguration = new Map<String,String>();
            headerConfiguration.put('Content-Type', 'application/json');
            headerConfiguration.put('Accept', 'application/json');
            
            HttpResponse response = DRACalloutHelper(headerConfiguration, '', 'dariPaymentBreakDown', endpointParam);
            DARIRegistrationModel.MortgageDetailsResponse responseDetail = (DARIRegistrationModel.MortgageDetailsResponse) System.JSON.deserialize(response.getBody(), DARIRegistrationModel.MortgageDetailsResponse.class);
            DARIRegistrationModel.Result result = responseDetail.results.result;
            Boolean success = responseDetail.results.success;
            LoggerService.save(LoggerService.addApexServiceCalls('get Payment Breakdown', 'DARIRegistrationUtility', 'getPaymentBreakdown', endpointParam, response.getBody(), null));
            if(success == true) {
                SRUtility.updateServiceRequestStep(srId, 'Capture Fee Details', Constants.STEP_APPROVED_STATUS, 'Approved');
                //Capture Fee Details
                sRRecord.ADMFeePaid__c = 0; //adminFeeAmount
                sRRecord.TitleDeedRegistrationFee__c = null;
                sRRecord.ElectronicServiceCharge__c = null;
                sRRecord.ReceiptNumber__c = null;
                sRRecord.ReceiptRemarks__c = '';
                sRRecord.LiabilityAmount__c = result.liabilityAmount;
                if(result <> null &&  result.transactionTotalAmount > 0){
                     sRRecord.TitleDeedRegistrationFee__c = result.transactionTotalAmount;
                }
                update sRRecord;
                if(sRRecord.TitleDeedRegistrationFee__c > 0){
                     CC_TitleDeedRegistrationValidation.soOtherChargesCreation(sRRecord);
                }
            } else {
                SRUtility.updateServiceRequestStep(srId, 'Capture Fee Details', Constants.PENDING_STATUS, result.description);
            }
        } catch(Exception e) {
            LoggerService.save(LoggerService.createApexLog(e, 'get Payment Breakdown', 'DARIRegistrationUtility','getPaymentBreakdown'));
        }
    }
    
    /**
     * @description Make payment from Salesforce to DARI
     * @author rmohmmed@aldar.com | 02-01-2024 | Story Number
     * @param srId Id
     * @return void
     **/
    @future(callout = true)
    public static void dmtRegFeePaymentsFuture(Id srId) {
        dmtRegFeePayments(srId);
    }
    
    public static void dmtRegFeePayments(Id srId) {
        try {
            HexaBPM__Service_Request__c srRecord = getSRRecord(srId);
            SalesOrder__c so = SalesOrderService.queryAllFieldsWithExtraFields(new List<Id>{srRecord.SalesOrder__c})[0];
            User userDetail = [SELECT Id, EmirateId__c FROM USER WHERE Id =: UserInfo.getUserId()];
            String tradelincense = srRecord.Unit__r.Project__r.Trade_License_No__c == null ? System.Label.TradeLicenseNumber : srRecord.Unit__r.Project__r.Trade_License_No__c;
            String reqBody = '?tradeLicenseNo=' + tradelincense + '&emiratesID=' + userDetail.EmirateId__c  + '&applicationId=' + srRecord.ApplicationId__c + '&unifiedNumber&feeType=DMT_REG_FEE';
            //reqBody = reqBody + '&applicationType=OFFPLAN_TO_COMPLETE_UNIT';
            
            
            String recordTypeName = Utilities.getRecordTypeName('Unit__c', so.Unit__r.recordTypeId);
            List<String> plotRecordTypes = Label.PlotRecordTypes.split(',');
            
            // check the record type
            if(plotRecordTypes.contains(recordTypeName)) {
                reqBody = reqBody + '&applicationType=OFFPLAN_TO_COMPLETE_LAND';
            } else {
                reqBody = reqBody + '&applicationType=OFFPLAN_TO_COMPLETE_UNIT';
            }

            Map<String,String> headerConfiguration = new Map<String,String>();
            headerConfiguration.put('Content-Type', 'application/json');
            headerConfiguration.put('Accept', 'application/json');        
            HttpResponse response = DRACalloutHelper(headerConfiguration, '', 'dariPaymentRegFee', reqBody);
            
            DARIRegistrationModel.Response responseDetail = (DARIRegistrationModel.Response) System.JSON.deserialize(response.getBody(), DARIRegistrationModel.Response.class);
            DARIRegistrationModel.AppResult result = responseDetail.results.result;
            Boolean success = responseDetail.results.success;
            LoggerService.save(LoggerService.addApexServiceCalls('Payment Step', 'DARIRegistrationUtility', 'dmtRegFeePayments', (reqBody.length() < 131072 ? reqBody : ''), response.getBody(), null));
            if(success != true) {
                LoggerService.save(LoggerService.addApexServiceCalls('Payment Step', 'DARIRegistrationUtility', 'dmtRegFeePayments', (reqBody.length() < 131072 ? reqBody : ''), response.getBody(), null));
                SRUtility.updateServiceRequestStep(srId, 'Payment Step', Constants.PENDING_STATUS, result.description);
            } else {
                //update SR Steps
                SRUtility.updateServiceRequestStep(srId, 'Payment Step', Constants.COMPLETED_STATUS, 'Payment Step Completed');                
            }
            
        } catch(Exception e){
            LoggerService.save(LoggerService.createApexLog(e, 'Payment Step', 'DARIRegistrationUtility', 'dmtRegFeePayments'));
        }
    }
    
    public static void makePaymentByCard(Id srId) {
        HexaBPM__Service_Request__c srRecord = getSRRecord(srId);
        String endpointParam = String.valueOf(srRecord.ApplicationId__c) + '/OFFPLAN_TO_COMPLETE_LAND/DMT_SERVICE_FEE/CARD';
        String reqBody = '';
    }
    
    /**
     * @description Update SR Status to Approved/Reject ADM Team Approval
     * @author rmohmmed@aldar.com | 02-01-2024 | Story Number
     * @param srId Id
     * @return void
     **/
    public static String closeADMApproval(Integer applicationId, String status) {
        try{
            HexaBPM__Service_Request__c srRecord = [Select Id, ADMApplicationNumber__c From HexaBPM__Service_Request__c WHERE ApplicationId__c =: applicationId ORDER BY CreatedDate Desc Limit 1];
            String stepStatus = status.equalsIgnoreCase('Approved') ? Constants.STEP_APPROVED_STATUS : Constants.STEP_REJECTED_STATUS;
            SRUtility.updateServiceRequestStep(srRecord.Id, 'ADM Team Approval', stepStatus, 'Status Received: '+status);
            
            String srStatus = status.equalsIgnoreCase('Approved') ? Constants.STEP_ACCEPTED_STATUS : Constants.STEP_REJECTED_STATUS;
            HexaBPM__SR_Status__c objSRStatus = [SELECT Id, Name FROM HexaBPM__SR_Status__c WHERE Name =: srStatus LIMIT 1];
            sRRecord.HexaBPM__External_SR_Status__c = objSRStatus.Id;
            sRRecord.HexaBPM__Internal_SR_Status__c = objSRStatus.Id;
            update sRRecord;
            return 'success';
            
        } catch(Exception e){
            LoggerService.save(LoggerService.createApexLog(e, 'Update ADM Approval Status', 'DARIRegistrationUtility', 'closeADMApproval(applicationId: ' + applicationId + ', status: ' + status));
            return e.getMessage();
        }
    }
    
    /**
     * @description Update Payment Status to Approved/Reject
     * @author rmohmmed@aldar.com | 02-01-2024 | Story Number
     * @param srId Id
     * @return void
     **/
    public static String updatePaymentStatus(Integer applicationId, String status){
        try{
            HexaBPM__Service_Request__c srRecord = [Select Id, ADMApplicationNumber__c From HexaBPM__Service_Request__c WHERE ApplicationId__c =: applicationId ORDER BY CreatedDate Desc Limit 1];
            
            if(status.equalsIgnoreCase('Approved')) {
                SRUtility.updateServiceRequestStep(srRecord.Id, 'Payment Step', Constants.COMPLETED_STATUS, 'Updated in Salesforce by DARI');
            } else {
                SRUtility.updateServiceRequestStep(srRecord.Id, 'Payment Step', Constants.PENDING_STATUS, 'Payment Failed By ADM');
            }
            
            return 'success';
        } catch(Exception e){
            LoggerService.save(LoggerService.createApexLog(e,'Update Payment Status', 'DARIRegistrationUtility', 'updatePaymentStatus(applicationId: ' + applicationId + ', status: ' + status));
            return e.getMessage();
        }
    }
    
    /**
     * @description Fetch SR Record
     * @author rmohmmed@aldar.com | 02-01-2024 | Story Number
     * @param srId Id
     * @return HexaBPM__Service_Request__c
     **/
    public static HexaBPM__Service_Request__c getSRRecord(Id srId){
        HexaBPM__Service_Request__c srRecord = [Select Id, Unit__r.recordTypeId, SalesOrder__c, SalesOrder__r.NetAmount__c, Pay_By__c, SalesOrder__r.BookingDate__c,SPACounterSignedDate__c, MortgageBank__r.BankCompanyId__c, ApplicationId__c, LiabilityAmount__c,
                                                SalesOrder__r.Unit__r.CompletionDate__c, Application_Type__c, SalesOrder__r.SellingPrice__c, ADMApplicationNumber__c, HexaBPM__External_Status_Name__c, Unit__r.ADMSectorName__c,
                                                Unit__r.ADMPlotNumber__c, Unit__r.Project__r.Trade_License_No__c, MortgageApplicable__c, Unit__r.ADMBuildingNumber__c, Unit__r.ADMUnitNumber__c, Unit__r.ADDCPremiseId1__c, Unit__r.ADDCPremiseId2__c
                                                From HexaBPM__Service_Request__c Where Id =: srId];
        return srRecord;
    }
    
    /**
     * @description Callout method used with all ADM callouts
     * @author rmohmmed@aldar.com | 02-01-2024 | Story Number
     * @param headerConfiguration Map<String,String>
     * @param JSONBody String
     * @param muleConfig String
     * @param extraParam String
     * @return HttpResponse
     **/
    public static HttpResponse DRACalloutHelper(Map<String,String> headerConfiguration, String JSONBody, String muleConfig, String extraParam) {
        //Just make the callout, if error code log in logger object
        MuleSoftSetting__mdt  mulesoftAPI = Utilities.getMuleSoftDetails(muleConfig);
        Organization org = Utilities.getOrganizationDetails();
        String endPointURL = mulesoftAPI.SandboxURL__c ;
        
        if(!org.IsSandbox){
            endPointURL = mulesoftAPI.ProductionURL__c ; 
        }
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        if(String.isNotBlank(JSONBody)) {
            request.setBody(JSONBody);
        }
        
        for(String headerName : headerConfiguration.keySet()){
            request.setHeader(headerName, headerConfiguration.get(headerName));
        }
        
        request.setHeader('client_secret', mulesoftAPI.APIKey__c);
        request.setHeader('client_id', mulesoftAPI.APIId__c);
        request.setEndpoint(endPointURL + extraParam);
        request.setMethod(mulesoftAPI.Method__c);
        request.setTimeout(120000);
        system.debug('Request Body--->>'+request.getBody());
        HttpResponse response = http.send(request);
        system.debug(response.getBody());
        system.debug(response.getStatusCode());
        return response;
    }
    
    /**
     * @description Callout method used with all ADM callouts
     * @author rmohmmed@aldar.com | 02-01-2024 | Story Number
     * @param response HttpResponse
     * @return Map<String, String>
     **/
    public static Map<String, String> JSONParserCtrl(HttpResponse response) {
        Map<String, String> responseMap = new Map<String, String>();
        JSONParser parser = JSON.createParser(response.getBody());
        String success = '';
        String error = '';
        
        while(parser.nextToken() != null) {
            if('success'.equalsIgnoreCase(parser.getText())){
                parser.nextToken();
                success = parser.getText();
                
            } else if('errorMessgae'.equalsIgnoreCase(parser.getText())){
                parser.nextToken();
                error += parser.getText();
                
            }  else if('result'.equalsIgnoreCase(parser.getText())){
                parser.nextToken();
                error += parser.getText();
                
            }  else if('description'.equalsIgnoreCase(parser.getText())){
                parser.nextToken();
                error += parser.getText();
            } 
        }
        
        responseMap.put('success', success);
        responseMap.put('error', error);
        
        return responseMap;
    }
    
    /**
     * @description Return a map contains SR Doc name with List of upload document model thats contains the file data
     * @author rmohmmed@aldar.com | 02-01-2024 | Story Number
     * @param serviceRequestId String
     * @param srDocumentName List<String>
     * @return Map<String, List<DARIRegistrationModel.UploadDocumentRequest>>
     **/
    public static Map<String, List<DARIRegistrationModel.UploadDocumentRequest>> getUploadedFiles(String serviceRequestId, List<String> srDocumentName) {
        try {
            Map <String, HexaBPM__SR_Doc__c> srDocMap = new Map<String, HexaBPM__SR_Doc__c>();
            Map <String, ContentDocumentLink> contentDocMap = new Map<String, ContentDocumentLink>();
            Map<String, List<DARIRegistrationModel.UploadDocumentRequest>> documentsRequestsMap = new Map<String, List<DARIRegistrationModel.UploadDocumentRequest>>();
            
            for(HexaBPM__SR_Doc__c srDocRecord : [SELECT HexaBPM__Service_Request__c, HexaBPM__Service_Request__r.ADMApplicationNumber__c, Name, Id FROM HexaBPM__SR_Doc__c WHERE HexaBPM__Service_Request__c =: serviceRequestId AND Name IN : srDocumentName]) {
                srDocMap.put(srDocRecord.Id, srDocRecord);
            }
            
            for(ContentDocumentLink contentDocumentRecord : [SELECT ContentDocumentId, Id, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN : srDocMap.keySet()]) {
                contentDocMap.put(contentDocumentRecord.ContentDocumentId,contentDocumentRecord);
            }
            
            for(ContentVersion contentVersionRecord : [SELECT Id, ContentDocumentId, VersionData, Title FROM ContentVersion WHERE ContentDocumentId IN : contentDocMap.keySet() ORDER BY CreatedDate DESC]) {
                Blob file = contentVersionRecord.VersionData;
                String srDocName = srDocMap.get(contentDocMap.get(contentVersionRecord.ContentDocumentId).LinkedEntityId).Name;
                
                DARIRegistrationModel.UploadDocumentRequest documentObj = new DARIRegistrationModel.UploadDocumentRequest();
                documentObj.fileName = contentVersionRecord.Title;
                documentObj.fileData = EncodingUtil.base64Encode(file);
                documentObj.applicationId = srDocMap.get(contentDocMap.get(contentVersionRecord.ContentDocumentId).LinkedEntityId).HexaBPM__Service_Request__r.ADMApplicationNumber__c;
                documentObj.srDocId = srDocMap.get(contentDocMap.get(contentVersionRecord.ContentDocumentId).LinkedEntityId).Id;
                
                if(documentsRequestsMap.containsKey(srDocName)){
                    documentsRequestsMap.get(srDocName).add(documentObj);
                } else{
                    documentsRequestsMap.put(srDocName, new List<DARIRegistrationModel.UploadDocumentRequest>{documentObj});
                }
            }
            
            return documentsRequestsMap;
        } catch(exception e) {
            system.debug(e);
            return null;
        }
    }
}