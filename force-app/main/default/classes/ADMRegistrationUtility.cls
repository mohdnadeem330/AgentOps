public with Sharing class ADMRegistrationUtility{
    public static boolean hasScheduled = false; 
    //--- Checka ll required fields on SR and related objects 
    public static List<String> validateRegistrationAttributes(Id srId){

        List<String> errorMessages = new List<String>();
        HexaBPM__Service_Request__c srRecord = getSRRecord(srId);
        SalesOrder__c so = SalesOrderService.queryAllFieldsWithExtraFields(new List<Id>{srRecord.SalesOrder__c})[0];

        if(String.isBlank(so.Unit__r.ADMSectorName__c)){
            errorMessages.add('Unit ADM Sector Name is not populated.');
        }
        if(String.isBlank(so.Unit__r.ADMPlotNumber__c)){
            errorMessages.add('Unit ADM Plot Number is not populated.');
        }

        String recordTypeName = Utilities.getRecordTypeName('Unit__c', so.Unit__r.recordTypeId);

        List<String> plotRecordTypes = Label.PlotRecordTypes.split(',');

        if(!plotRecordTypes.contains(recordTypeName)){
            if(String.isBlank(so.Unit__r.ADMBuildingNumber__c)){
                errorMessages.add('Unit ADM Building Number is not populated.');
            }
            if(String.isBlank(so.Unit__r.ADMUnitNumber__c)){
                errorMessages.add('Unit ADM Unit Number is not populated.');
            }
        }

        Set<Id> orgAccountsIds = new Set<Id>();

        if(so.Account__r.RecordType.Name == Constants.PERSON_ACCOUNT_RT){
            if(String.isBlank(so.Account__r.NationalIdNumber__pc )){
                if(so.Account__r.Nationality__pc == 'United Arab Emirates'){
                    errorMessages.add('Main Owner National Id Number is not populated.');
                } else if (so.Account__r.PersonEmail == null && so.Account__r.Nationality__pc != 'United Arab Emirates'){
                    errorMessages.add('Main Owner Email is not populated.');
                }
            }
        } else {
            orgAccountsIds.add(so.Account__c);
            Contact primaryContactRecord = getPrimaryContactsForAccount(orgAccountsIds).get(so.Account__c);
            
            if(primaryContactRecord == null){
                errorMessages.add('Main Owner does not have primary contact.');
            } else {

                if(String.isBlank(primaryContactRecord.NationalIdNumber__c )){
                    if(primaryContactRecord.Nationality__c == 'United Arab Emirates'){
                        errorMessages.add('The primary contact of Main Owner National Id Number is not populated.');
                    } else if (primaryContactRecord.Email == null && primaryContactRecord.Nationality__c != 'United Arab Emirates'){
                        errorMessages.add('The primary contact of Main Owner Email is not populated.');
                    }
                }

                if(String.isBlank(so.Account__r.UnifiedNumber__c)){
                    errorMessages.add('Main Owner ('+so.Account__r.Name+') Unified Number is not populated.');
                }

                if(String.isBlank(so.Account__r.RegistrationNumber__c)){
                    errorMessages.add('Main Owner ('+so.Account__r.Name+') Registration Number is not populated.');
                }
            }
        }


        /**** Aggregate Result issue fixed***   List<JointOwner__c> jointOwners = so.Joint_OwnersSalesOrder__r;*/

        for (JointOwner__c jointOwnerRecord : so.Joint_OwnersSalesOrder__r) {
            if(jointOwnerRecord.Account__r.RecordType.Name == Constants.PERSON_ACCOUNT_RT){
                if(String.isBlank(jointOwnerRecord.Account__r.NationalIdNumber__pc )){
                    if(jointOwnerRecord.Account__r.Nationality__pc == 'United Arab Emirates'){
                        errorMessages.add('Joint Owner ('+jointOwnerRecord.Account__r.Name+') National Id Number is not populated.');
                    } else if (jointOwnerRecord.Account__r.PersonEmail == null && jointOwnerRecord.Account__r.Nationality__pc != 'United Arab Emirates'){
                        errorMessages.add('Joint Owner ('+jointOwnerRecord.Account__r.Name+') Email is not populated.');
                    }
                }
            } else {
                orgAccountsIds.add(jointOwnerRecord.Account__c);
            }
        }

        Map<Id,Contact> primaryContact = new Map<Id,Contact>();
        if(orgAccountsIds.size() > 0 ){
            primaryContact = getPrimaryContactsForAccount(orgAccountsIds);
        }
        for (JointOwner__c jointOwnerRecord : so.Joint_OwnersSalesOrder__r) {
            if(jointOwnerRecord.Account__r.RecordType.Name != Constants.PERSON_ACCOUNT_RT){
                Contact primaryContactRecord = primaryContact.get(jointOwnerRecord.Account__c);

                if(primaryContactRecord == null){
                    errorMessages.add('Joint Owner ('+jointOwnerRecord.Account__r.Name+') does not have primary contact.');
                } else {

                    if(String.isBlank(jointOwnerRecord.Account__r.UnifiedNumber__c)){
                        errorMessages.add('Joint Owner ('+jointOwnerRecord.Account__r.Name+') Unified Number is not populated.');
                    }

                    if(String.isBlank(jointOwnerRecord.Account__r.RegistrationNumber__c)){
                        errorMessages.add('Joint Owner ('+jointOwnerRecord.Account__r.Name+') Registration Number is not populated.');
                    }
                }
            }
        }

        if(so.BookingDate__c == null){
            errorMessages.add('Sales Order Booking Date is not populated.');
        }
        if(srRecord.SalesOrder__r.Unit__r.CompletionDate__c == null){
            errorMessages.add('Unit Completion Date is not populated.');
        }
        if(so.NetAmount__c == null){
            errorMessages.add('Sales Order Net Amount is not populated.');
        }

        List<InstallmentLines__c> installmentsRecords = new List<InstallmentLines__c>();

        for(InstallmentLines__c ilRecord : so.InstallmentLines__r){
            installmentsRecords.add(ilRecord);
        }
        Set<String> installmentsCheck = new Set<String>();

        Decimal sumOfInstallmentsAmount = 0;
        
        for (InstallmentLines__c ilRecord : installmentsRecords) {

            if(ilRecord.InstallmentDate__c == null && ilRecord.InstallmentNumber__c != installmentsRecords.size()){
                errorMessages.add('Some installments does not have Installment Date.');
            }

            sumOfInstallmentsAmount = sumOfInstallmentsAmount + ilRecord.InstallmentAmount__c;
           //*** For Fixing the final installment fix***** installmentsCheck.add(ilRecord.InstallmentNumber__c == 1 ? 'DOWN_INSTALMENT' : ilRecord.InstallmentNumber__c == installmentsRecords.size() ? 'FINAL_INSTALMENT' : 'INSTALMENT');
			installmentsCheck.add(ilRecord.InstallmentNumber__c == 1 && installmentsRecords.size() == 1 ? 'FINAL_INSTALMENT' : ilRecord.InstallmentNumber__c == 1 ? 'DOWN_INSTALMENT' : ilRecord.InstallmentNumber__c == installmentsRecords.size() ? 'FINAL_INSTALMENT' : 'INSTALMENT');
        }

        /*if(sumOfInstallmentsAmount != srRecord.SalesOrder__r.NetAmount__c){
            errorMessages.add('Sum of installments amount does not equal sales order net amount.');
        }*/
        if(!installmentsCheck.contains('DOWN_INSTALMENT') && !installmentsCheck.contains('FINAL_INSTALMENT')){
            errorMessages.add('DOWN_INSTALMENT not found.');
        }
        if(!installmentsCheck.contains('FINAL_INSTALMENT')){
            errorMessages.add('FINAL_INSTALMENT not found.');
        }

        //return error message if anything is missing
        return errorMessages;
    }
    
    public static string validateRegistrationDocuemnts(Id srId){

        //HexaBPM__Service_Request__c srRecord = getSRRecord(srId);
        //Checka all required documents are available under placeholder
        //return error message if anything is missing
        return '';
    }
    
    //--- method to prepare Draft Application API request and handle the response
    public static string createApplication(Id srId){

        User userDetail = [SELECT Id, EmirateId__c FROM USER WHERE Id =: UserInfo.getUserId()];

        /*if(userDetail.EmirateId__c == null || userDetail.EmirateId__c == ''){
            return '';
        }*/

        HexaBPM__Service_Request__c srRecord = getSRRecord(srId);
        ADMRegistrationModel.CreateApplication createApp = new ADMRegistrationModel.CreateApplication();
        createApp.key = 'selling-details';
        createApp.priority = true;
        createApp.isDraft = false;

        String tradelicense = srRecord.Unit__r.Project__r.Trade_License_No__c == null ? System.Label.TradeLicenseNumber : srRecord.Unit__r.Project__r.Trade_License_No__c;

        SalesOrder__c so = SalesOrderService.queryAllFieldsWithExtraFields(new List<Id>{srRecord.SalesOrder__c})[0];

        String recordTypeName = Utilities.getRecordTypeName('Unit__c', so.Unit__r.recordTypeId);

        List<String> plotRecordTypes = Label.PlotRecordTypes.split(',');
        // check the record type
        if(plotRecordTypes.contains(recordTypeName)){
            createApp.dmtNumber = 'AbuDhabi.'+so.Unit__r.ADMSectorName__c+'.'+so.Unit__r.ADMPlotNumber__c;
            createApp.applicationType = 'OFF_PLAN_FIRST_SELL_LAND';

        } else {
            //AbuDhabi
            createApp.dmtNumber = 'AbuDhabi.' + so.Unit__r.ADMSectorName__c + '.' + so.Unit__r.ADMPlotNumber__c + '.' + so.Unit__r.ADMBuildingNumber__c + '.' + so.Unit__r.ADMUnitNumber__c;
            createApp.applicationType = 'OFF_PLAN_FIRST_SELL_UNIT';
        }
        /***createApp.dmtNumber = 'AbuDhabi.W39.33';
        createApp.applicationType = 'OFF_PLAN_FIRST_SELL_LAND';*** TESTING IN DARI SANDBOX ****/ 
       /** List<JointOwner__c> jointOwners = new List<JointOwner__c>();
        for(JointOwner__c jo:so.Joint_OwnersSalesOrder__r) {
            jointOwners.add(jo);
        }**/
        createApp.buyers = new List<ADMRegistrationModel.Buyers>();

        Set<Id> orgAccountsIds = new Set<Id>();

        if(so.Account__r.RecordType.Name == Constants.PERSON_ACCOUNT_RT){
            ADMRegistrationModel.Buyers buyerObj = new ADMRegistrationModel.Buyers();
            buyerObj.eidNumberOrUnified = so.Account__r.NationalIdNumber__pc;
            buyerObj.email = so.Account__r.NationalIdNumber__pc == null ? so.Account__r.PersonEmail : null;
            buyerObj.tradeLicenseNo = so.Account__r.RegistrationNumber__c != null ? so.Account__r.RegistrationNumber__c : '';
            buyerObj.transactionShare = so.OwnerSharePercentage__c;
            buyerObj.representatives = new List<ADMRegistrationModel.Representatives>();

            createApp.buyers.add(buyerObj);
        } else {
            orgAccountsIds.add(so.Account__c);
            Contact primaryContactRecord = getPrimaryContactsForAccount(orgAccountsIds).get(so.Account__c);
            
            if(primaryContactRecord != null){
                ADMRegistrationModel.Buyers buyerObj = new ADMRegistrationModel.Buyers();
                buyerObj.eidNumberOrUnified = primaryContactRecord.NationalIdNumber__c;
                buyerObj.email = primaryContactRecord.Email;
                buyerObj.representatives = new List<ADMRegistrationModel.Representatives>();

                ADMRegistrationModel.Representatives rep = new ADMRegistrationModel.Representatives();
                rep.eidNumberOrUnified = so.Account__r.UnifiedNumber__c;

                buyerObj.representatives.add(rep);

                buyerObj.tradeLicenseNo = so.Account__r.RegistrationNumber__c;
                buyerObj.transactionShare = so.OwnerSharePercentage__c;
                createApp.buyers.add(buyerObj);
            }
        }
        for (JointOwner__c jointOwnerRecord : so.Joint_OwnersSalesOrder__r) {

            if(jointOwnerRecord.Account__r.RecordType.Name == Constants.PERSON_ACCOUNT_RT){
                ADMRegistrationModel.Buyers buyerObj = new ADMRegistrationModel.Buyers();
                buyerObj.eidNumberOrUnified = jointOwnerRecord.Account__r.NationalIdNumber__pc;
                buyerObj.email = jointOwnerRecord.Account__r.NationalIdNumber__pc == null ? jointOwnerRecord.Account__r.PersonEmail : null;
                buyerObj.tradeLicenseNo = jointOwnerRecord.Account__r.RegistrationNumber__c != null ? jointOwnerRecord.Account__r.RegistrationNumber__c : '';
                buyerObj.transactionShare = jointOwnerRecord.SharePercentage__c;
                buyerObj.representatives = new List<ADMRegistrationModel.Representatives>();

                createApp.buyers.add(buyerObj);
            } else {
                orgAccountsIds.add(jointOwnerRecord.Account__c);
            }
        }

        Map<Id,Contact> primaryContact = new Map<Id,Contact>();
        if(orgAccountsIds.size() > 0 ){
            primaryContact = getPrimaryContactsForAccount(orgAccountsIds);
        }
        for (JointOwner__c jointOwnerRecord : so.Joint_OwnersSalesOrder__r) {
            if(jointOwnerRecord.Account__r.RecordType.Name != Constants.PERSON_ACCOUNT_RT){
                Contact primaryContactRecord = primaryContact.get(jointOwnerRecord.Account__c);
                if(primaryContactRecord != null){
                    ADMRegistrationModel.Buyers buyerObj = new ADMRegistrationModel.Buyers();
                    buyerObj.eidNumberOrUnified = primaryContactRecord.NationalIdNumber__c;
                    buyerObj.email = primaryContactRecord.Email;
                    buyerObj.representatives = new List<ADMRegistrationModel.Representatives>();

                    ADMRegistrationModel.Representatives rep = new ADMRegistrationModel.Representatives();
                    rep.eidNumberOrUnified = jointOwnerRecord.Account__r.UnifiedNumber__c;

                    buyerObj.representatives.add(rep);

                    buyerObj.tradeLicenseNo = jointOwnerRecord.Account__r.RegistrationNumber__c;
                    buyerObj.transactionShare = jointOwnerRecord.SharePercentage__c;
                    createApp.buyers.add(buyerObj);
                }
            }
        }

        List<InstallmentLines__c> installmentsRecords = new List<InstallmentLines__c>();

        Decimal sumOfInstallmentsAmount = 0;

        for(InstallmentLines__c ilRecord : so.InstallmentLines__r){
            installmentsRecords.add(ilRecord);
            sumOfInstallmentsAmount = sumOfInstallmentsAmount + ilRecord.InstallmentAmount__c;
        }

        ADMRegistrationModel.ContractDetails contractDetailsObj= new ADMRegistrationModel.ContractDetails();
        contractDetailsObj.dateOfSale = srRecord.SPACounterSignedDate__c;
        contractDetailsObj.paidBy = 'BUYER_ONLY';
        contractDetailsObj.projectCompletionDate = srRecord.SalesOrder__r.Unit__r.CompletionDate__c;
        contractDetailsObj.salePrice = sumOfInstallmentsAmount;

        createApp.contractDetails = contractDetailsObj;
        createApp.paymentPlanType = 'INSTALLMENT';

        createApp.instalmentPlanList = new List<ADMRegistrationModel.InstalmentPlanList>();
        
        for (InstallmentLines__c ilRecord : installmentsRecords) {
            ADMRegistrationModel.InstalmentPlanList ilPlanObj = new ADMRegistrationModel.InstalmentPlanList();
            ilPlanObj.categoryType = ilRecord.InstallmentNumber__c == 1 ? 'DOWN_INSTALMENT' : ilRecord.InstallmentNumber__c == installmentsRecords.size() ? 'FINAL_INSTALMENT' : 'INSTALMENT';
            ilPlanObj.displayOrder = ilRecord.InstallmentNumber__c - 1;
            ilPlanObj.instalmentType = 'PERCENTAGE';
            ilPlanObj.frequency = ilRecord.InstallmentNumber__c == 1 ? 'CUSTOM' : '';
            ilPlanObj.value = ilRecord.InstallmentAmount__c;
            ilPlanObj.percentage = ilRecord.InstallmentPercentage__c;
            ilPlanObj.date_Z = ilRecord.InstallmentDate__c;

            createApp.instalmentPlanList.add(ilPlanObj);
        }

        createApp.brokers = new List<ADMRegistrationModel.Brokers>();
        /*ADMRegistrationModel.Brokers brokerObj = new ADMRegistrationModel.Brokers();
        brokerObj.eidNumberOrUnified = so.Opportunity__r.BrokerAgentContact__r.NationalIdNumber__c;
        
        createApp.brokers.add(brokerObj);*/

        String reqBody = json.serialize(createApp);

        reqBody = reqBody.replaceAll('date_Z', 'date').replaceAll('"frequency":"",','');
        System.debug('createApplicationRequestbody: ' + reqBody);
        Map<String,String> headerConfiguration = new Map<String,String>();
        headerConfiguration.put('Content-Type', 'application/json');
        headerConfiguration.put('Accept', 'application/json');
        /***tradelicense = 'CN-1052050';**** TESTING DARI SANDBOX ******/
        ADMCalloutHelperForCreateApplication(headerConfiguration, reqBody, 'admCreateApplication', '?tradeLicenseNo=' + tradelicense + '&emiratesID=' + userDetail.EmirateId__c, srId);

        return '';
    }

    @future(callout = true)
    public static void uploadDocumentFuture(Id srId, String applicationId, List<String> srDocumentsNames){
        uploadDocument(srId, applicationId, srDocumentsNames);
    }

    //--- method used with upload document API to prepare the request and handle the response
    public static string uploadDocument(Id srId, String applicationId, List<String> srDocumentsNames){
        User userDetail = [SELECT Id, EmirateId__c FROM USER WHERE Id =: UserInfo.getUserId()];
        HexaBPM__Service_Request__c sRRecord = [SELECT Id, ADMApplicationNumber__c,Unit__r.RecordType.Name, Unit__r.Project__r.Trade_License_No__c, ServiceRequestComments__c, HexaBPM__External_Status_Name__c FROM HexaBPM__Service_Request__c WHERE id =: srId];

        String tradelicense = srRecord.Unit__r.Project__r.Trade_License_No__c == null ? System.Label.TradeLicenseNumber : srRecord.Unit__r.Project__r.Trade_License_No__c;
        String applicationType = 'OFF_PLAN_FIRST_SELL_UNIT';

        List<String> plotRecordTypes = Label.PlotRecordTypes.split(',');

        if(plotRecordTypes.contains(sRRecord.Unit__r.RecordType.Name)){
            applicationType = 'OFF_PLAN_FIRST_SELL_LAND';
        }

        Map<String, List<ADMRegistrationModel.UploadDocumentRequest>> documentToUpload = getUploadedFiles(srId, srDocumentsNames);
        List<HexaBPM__SR_Doc__c> srDocsMap = [SELECT Id, HexaBPM__Service_Request__c, Name, HexaBPM__Comments__c FROM HexaBPM__SR_Doc__c WHERE HexaBPM__Service_Request__c =: srId AND Name in : documentToUpload.keySet()];
        Map<String, HexaBPM__SR_Doc__c> docNameWithSRRecord = new Map<String, HexaBPM__SR_Doc__c>();
        for (HexaBPM__SR_Doc__c srDoc : srDocsMap) {
            docNameWithSRRecord.put(srDoc.Name, srDoc); 
        }

        Map<String,String> srDocIdWithMessage = new Map<String,String>();
        Map<String,String> unifiedSPADocIdWithMessage = new Map<String,String>();
        for(String documentName : documentToUpload.keySet()){
            HexaBPM__SR_Doc__c srDocRecord = docNameWithSRRecord.get(documentName);

            Integer count = 1;
            for (ADMRegistrationModel.UploadDocumentRequest uploadDocRequest : documentToUpload.get(documentName)) {
                Map<String, String> mapName = new Map<String, String>();
                mapName.put('contentVersionId', uploadDocRequest.contentVersionId);
                mapName.put('applicationId', uploadDocRequest.applicationId);
                if(plotRecordTypes.contains(sRRecord.Unit__r.RecordType.Name)){
            		applicationType = 'OFF_PLAN_FIRST_SELL_LAND';
                }
                mapName.put('fileName', uploadDocRequest.fileName);
                mapName.put('applicationType', applicationType);
                mapName.put('documentType', 'DEVELOPER_SELL_CONTRACT');
                mapName.put('subType', 'APPLICATION_' + applicationId + '.DEVELOPER_SELL_CONTRACT'+count);
                mapName.put('emiratesID', userDetail.EmirateId__c);
                //mapName.put('unifiedNumber', uploadDocRequest.fileData);
                mapName.put('tradeLicenseNo',tradelicense);
                String reqBody = json.serialize(mapName);

                Map<String,String> headerConfiguration = new Map<String,String>();
                headerConfiguration.put('Content-Type', 'application/json');
                headerConfiguration.put('Accept', 'application/json');
                srDocIdWithMessage.put(uploadDocRequest.srDocId, ADMCalloutHelperForUploadDocuments(headerConfiguration, reqBody, 'admUploadDocument','', srId, applicationId));
                //Added for Unified SPA API call
               //new requirement for new placeholder from Dari
                mapName.put('documentType', 'UNIFIED_SPA');
                mapName.put('subType', 'APPLICATION_' + applicationId + '.UNIFIED_SPA'+count);
                String unifiedSpaReqBody = json.serialize(mapName);
			    unifiedSPADocIdWithMessage.put(uploadDocRequest.srDocId, ADMCalloutHelperForUploadDocuments(headerConfiguration, unifiedSpaReqBody, 'admUploadDocument','', srId, applicationId));

                count++;
            }
        }

        List<HexaBPM__SR_Doc__c> srDocToUpdate = new List<HexaBPM__SR_Doc__c>();

        for (String srDocId : srDocIdWithMessage.keySet()) {
            HexaBPM__SR_Doc__c srDocRecord = new HexaBPM__SR_Doc__c(Id=srDocId);

            Datetime now = Datetime.now();
            Integer offset = UserInfo.getTimezone().getOffset(now);
            Datetime local = now.addSeconds(offset/1000);

            if(srDocIdWithMessage.get(srDocId) == 'Uploaded'){
                srDocRecord.SyncStatus__c = Constants.STATUS_SYNCED;
                srDocRecord.HexaBPM__Comments__c = local + ': '+ srDocIdWithMessage.get(srDocId);
            } else {
                srDocRecord.SyncStatus__c = Constants.STATUS_FAILED;
                srDocRecord.HexaBPM__Comments__c = local + ': '+ srDocIdWithMessage.get(srDocId);
            }
           //Added for Unified SPA API call 
            if(srDocRecord.SyncStatus__c != Constants.STATUS_FAILED &&
               unifiedSPADocIdWithMessage.containsKey(srDocId)){
                
                if(unifiedSPADocIdWithMessage.get(srDocId) == 'Uploaded'){
                    srDocRecord.SyncStatus__c = Constants.STATUS_SYNCED;
                    srDocRecord.HexaBPM__Comments__c = local + ': '+ unifiedSPADocIdWithMessage.get(srDocId);
                } else {
                    srDocRecord.SyncStatus__c = Constants.STATUS_FAILED;
                    srDocRecord.HexaBPM__Comments__c = local + ': '+ unifiedSPADocIdWithMessage.get(srDocId);
                }
                
            }
            
            srDocToUpdate.add(srDocRecord);
        }
        if(!Test.isRunningTest()){
            update srDocToUpdate;
        }

        //Prepare required structure and perform callout
        //Call below calloutHelper Method
        //return error message if anything is failed
        return '';
    }

    @future(callout = true)
    public static void submitApplicationFuture(Id srId){
        submitApplication(srId);
    }

    //--- method used with Submit Application API to prepare the request and handle the response    
    public static void submitApplication(Id srId){
        
        try{
            User userDetail = [SELECT Id, EmirateId__c FROM USER WHERE Id =: UserInfo.getUserId()];
            HexaBPM__Service_Request__c srRecord = getSRRecord(srId);
            
            String tradelicense = srRecord.Unit__r.Project__r.Trade_License_No__c == null ? System.Label.TradeLicenseNumber : srRecord.Unit__r.Project__r.Trade_License_No__c;
            /*Map<String, String> mapName = new Map<String, String>();
            mapName.put('approved', approved);
            mapName.put('applicationId', srRecord.ADMApplicationNumber__c);
            String reqBody = json.serialize(mapName);
            System.debug(reqBody);*/
			
            String reqBody = '?tradeLicenseNo=' + tradelicense + '&emiratesID=' + userDetail.EmirateId__c + '&applicationId=' + srRecord.ADMApplicationNumber__c;
            
            Map<String,String> headerConfiguration = new Map<String,String>();
            headerConfiguration.put('Accept', 'application/json');
            
            HttpResponse response = ADMCalloutHelper(headerConfiguration, '', 'admSubmitApplication', reqBody);
            System.debug('#$#$# response.getBody() >> '+response.getBody());
            String success = '';
            String applicationId = '';
            String error = '';
            String description = '';
            String StepNotes = '';
            String result = '';
            JSONParser parser = JSON.createParser(response.getBody());
            
            while(parser.nextToken() != null){
                
                if('success'.equalsIgnoreCase(parser.getText())){
                    parser.nextToken();
                    success = parser.getText();
                    
                } else if('error'.equalsIgnoreCase(parser.getText())){
                    parser.nextToken();
                    result += parser.getText();
                    
                } else if('description'.equalsIgnoreCase(parser.getText())){
                    parser.nextToken();
                    result += parser.getText();
                    
                }  else if('errorMessgae'.equalsIgnoreCase(parser.getText())){
                    parser.nextToken();
                    result += parser.getText();
                    
                }  else if('result'.equalsIgnoreCase(parser.getText())){
                    parser.nextToken();
                    result += parser.getText();
                }
            }
            
            if(success == 'true'){
                if(!Test.isRunningTest()){
                    SRUtility.updateServiceRequestStep(srId, 'Submit Registration', Constants.COMPLETED_STATUS, result);
                }
            } else {
                if(!Test.isRunningTest()){
                	SRUtility.updateServiceRequestStep(srId, 'Submit Registration', Constants.PENDING_STATUS, result + ' - ' + response.getStatusCode());
                    LoggerService.save(LoggerService.addApexServiceCalls('Submit Registration','ADMRegistrationUtility','submitApplication',reqBody,response.getBody(),null));
                }
            }
            
        } catch(Exception e){
            if(!Test.isRunningTest()){
                SRUtility.updateServiceRequestStep(srId, 'Submit Registration', Constants.PENDING_STATUS, e.getMessage());
            }
        }
        //Prepare required structure and perform callout
        //Call below calloutHelper Method
        //return error message if anything is failed
    }
    
    @future(callout = true)
    public static void sendApprovalStatusFuture(Id srId, String approved){
        sendApprovalStatus(srId, approved);
    }

    //--- method used with Send Approval API to prepare the request and handle the response    
    public static string sendApprovalStatus(Id srId, String approved){

        try{
            User userDetail = [SELECT Id, EmirateId__c FROM USER WHERE Id =: UserInfo.getUserId()];
            HexaBPM__Service_Request__c srRecord = getSRRecord(srId);
            
            String tradelicense = srRecord.Unit__r.Project__r.Trade_License_No__c == null ? System.Label.TradeLicenseNumber : srRecord.Unit__r.Project__r.Trade_License_No__c;
            Map<String, String> mapName = new Map<String, String>();
            mapName.put('approved', approved);
            mapName.put('applicationId', srRecord.ADMApplicationNumber__c);
            String reqBody = json.serialize(mapName);
            System.debug(reqBody);
    
            Map<String,String> headerConfiguration = new Map<String,String>();
            headerConfiguration.put('Accept', 'application/json');
            headerConfiguration.put('Content-Type', 'application/json');

            HttpResponse response = ADMCalloutHelper(headerConfiguration, reqBody, 'admApproval', '?tradeLicenseNo=' + tradelicense + '&emiratesID=' + userDetail.EmirateId__c);
            System.debug('response:'+response.getBody());
            String success = '';
            String applicationId = '';
            String error = '';
            String description = '';
            String StepNotes = '';
            String result = '';
            JSONParser parser = JSON.createParser(response.getBody());
    
            while(parser.nextToken() != null){
    
                if('success'.equalsIgnoreCase(parser.getText())){
                    parser.nextToken();
                    success = parser.getText();
    
                } else if('error'.equalsIgnoreCase(parser.getText())){
                    parser.nextToken();
                    result += parser.getText();
    
                } else if('description'.equalsIgnoreCase(parser.getText())){
                    parser.nextToken();
                    result += parser.getText();
    
                }  else if('errorMessgae'.equalsIgnoreCase(parser.getText())){
                    parser.nextToken();
                    result += parser.getText();
    
                }  else if('result'.equalsIgnoreCase(parser.getText())){
                    parser.nextToken();
                    result += parser.getText();
                }
            }
    
            if(success == 'true'){
                if(!Test.isRunningTest()){
                    SRUtility.updateServiceRequestStep(srId, 'Salesforce - Approval', Constants.STEP_APPROVED_STATUS, result);
                }
            } else {
                if(!Test.isRunningTest()){
                	SRUtility.updateServiceRequestStep(srId, 'Salesforce - Approval', Constants.PENDING_STATUS, result + ' - ' + response.getStatusCode());
                }
                LoggerService.save(LoggerService.addApexServiceCalls('Draft Application','ADMRegistrationUtility','sendApprovalStatus',(reqBody.length() < 131072 ? reqBody : ''),response.getBody(),null));
                
            }
    
            } catch(Exception e){
                if(!Test.isRunningTest()){
                    SRUtility.updateServiceRequestStep(srId, 'Salesforce - Approval', Constants.PENDING_STATUS, e.getMessage());
                }
                LoggerService.save(LoggerService.createApexLog(e,'Submit Approval','ADMRegistrationUtility','sendApprovalStatus'));
            }
        //Prepare required structure and perform callout
        //Call below calloutHelper Method
        //return error message if anything is failed
        return '';
    }

    @future(callout = true)
    public static void cancelApplicationFuture(Id srId){
        cancelApplication(srId);
    }

    //--- method used with Cancel Application API to prepare the request and handle the response    
    public static string cancelApplication(Id srId){

        try{
            User userDetail = [SELECT Id, EmirateId__c FROM USER WHERE Id =: UserInfo.getUserId()];
            HexaBPM__Service_Request__c srRecord = getSRRecord(srId);
            
            String tradelincense = srRecord.Unit__r.Project__r.Trade_License_No__c == null ? System.Label.TradeLicenseNumber : srRecord.Unit__r.Project__r.Trade_License_No__c;

            String reqBody = '?tradeLicenseNo=' + tradelincense + '&emiratesID=' + userDetail.EmirateId__c  + '&applicationId=' + srRecord.ADMApplicationNumber__c + '&status=DISCARD';
    
            Map<String,String> headerConfiguration = new Map<String,String>();
            headerConfiguration.put('Accept', 'application/json');
            headerConfiguration.put('Content-Type', 'application/json');

            HttpResponse response = ADMCalloutHelper(headerConfiguration, '', 'admCancelApplication', reqBody);
    
            String success = '';
            String applicationId = '';
            String error = '';
            String description = '';
            String StepNotes = '';
            String result = '';
            JSONParser parser = JSON.createParser(response.getBody());
    
            while(parser.nextToken() != null){
    
                if('success'.equalsIgnoreCase(parser.getText())){
                    parser.nextToken();
                    success = parser.getText();
    
                } else if('error'.equalsIgnoreCase(parser.getText())){
                    parser.nextToken();
                    result += parser.getText();
    
                } else if('description'.equalsIgnoreCase(parser.getText())){
                    parser.nextToken();
                    result += parser.getText();
    
                }  else if('errorMessgae'.equalsIgnoreCase(parser.getText())){
                    parser.nextToken();
                    result += parser.getText();
    
                }  else if('result'.equalsIgnoreCase(parser.getText())){
                    parser.nextToken();
                    result += parser.getText();
                }
            }

            sRRecord.ADMApplicationNumber__c = '';
            if(!Test.isRunningTest()){
                update sRRecord;
            }
    
            if(success != 'true') {
                LoggerService.save(LoggerService.addApexServiceCalls('Cancel Application','ADMRegistrationUtility','cancelApplication',(reqBody.length() < 131072 ? reqBody : ''),response.getBody(),null));
            }
    
            } catch(Exception e){
                LoggerService.save(LoggerService.createApexLog(e,'Cancel Approval','ADMRegistrationUtility','cancelApplication'));
            }
        //Prepare required structure and perform callout
        //Call below calloutHelper Method
        //return error message if anything is failed
        return '';
    }
    
    public static String closeADMApproval(string applicationId, String status){ //, String comments){ //Monika: parameter Comments added
        
        try{
            HexaBPM__Service_Request__c srRecord = [Select Id, ADMApplicationNumber__c From HexaBPM__Service_Request__c WHERE ADMApplicationNumber__c =: applicationId ORDER BY CreatedDate Desc Limit 1];
            String stepStatus = status.equalsIgnoreCase('Approved') ? Constants.STEP_APPROVED_STATUS : Constants.STEP_REJECTED_STATUS;
            if(!Test.isRunningTest()){
                SRUtility.updateServiceRequestStep(srRecord.Id, 'ADM Team Approval', stepStatus, 'Status Received: '+status);
            }
           //SRUtility.updateServiceRequestStep(srRecord.Id, 'ADM Team Approval', stepStatus, comments); //Monika: 20/02/24 comments from mulesoft added to be stored in stepnotes

            String srStatus = status.equalsIgnoreCase('Approved') ? Constants.STEP_ACCEPTED_STATUS : Constants.STEP_REJECTED_STATUS;
            HexaBPM__SR_Status__c objSRStatus = [SELECT Id, Name FROM HexaBPM__SR_Status__c WHERE Name =: srStatus LIMIT 1];
            sRRecord.HexaBPM__External_SR_Status__c = objSRStatus.Id;
            sRRecord.HexaBPM__Internal_SR_Status__c = objSRStatus.Id;
            if(!Test.isRunningTest()){
            	update sRRecord;
            }
            return 'success';
            
        } catch(Exception e){
            LoggerService.save(LoggerService.createApexLog(e,'Update Status','ADMRegistrationUtility','closeADMApproval(applicationId: ' + applicationId + ', status: ' + status));// + ', comments: ' + comments));//onika: Addes comments parameter
            return e.getMessage();
        }

        //ADM Team Approval
        // TODO Fetch the SR With application number
        // Fetch the ADM Step
        // Close the ADM Step based on status value
    }

    @future(callout = true)
    public static void paymentFuture(Id srId){
        payment(srId);
    }

    //--- method used with Payment API to prepare the request and handle the response    
    public static string payment(Id srId){

        try{
            User userDetail = [SELECT Id, EmirateId__c FROM USER WHERE Id =: UserInfo.getUserId()];
            HexaBPM__Service_Request__c srRecord = getSRRecord(srId);
    
            String recordTypeName = Utilities.getRecordTypeName('Unit__c', srRecord.Unit__r.recordTypeId);
            String applicationType = '';
            String tradelicense = srRecord.Unit__r.Project__r.Trade_License_No__c == null ? System.Label.TradeLicenseNumber : srRecord.Unit__r.Project__r.Trade_License_No__c;

            List<String> plotRecordTypes = Label.PlotRecordTypes.split(',');
            if(plotRecordTypes.contains(recordTypeName)){
                applicationType = 'OFF_PLAN_FIRST_SELL_LAND';
            } else {
                applicationType = 'OFF_PLAN_FIRST_SELL_UNIT';
            }
			
            String reqBody = '?tradeLicenseNo=' + tradelicense + '&emiratesID=' + userDetail.EmirateId__c + '&applicationId=' + srRecord.ADMApplicationNumber__c + '&applicationType=' + applicationType + '&feeType=DMT_SERVICE_FEE';
    
            Map<String,String> headerConfiguration = new Map<String,String>();
            headerConfiguration.put('Accept', 'application/json');
            headerConfiguration.put('Content-Type', 'application/json');

            HttpResponse response = ADMCalloutHelper(headerConfiguration, '', 'admPayment', reqBody);
    
            String success = '';
            String applicationId = '';
            String error = '';
            String description = '';
            String StepNotes = '';
            String result = '';
            JSONParser parser = JSON.createParser(response.getBody());
    
            while(parser.nextToken() != null){
    
                if('success'.equalsIgnoreCase(parser.getText())){
                    parser.nextToken();
                    success = parser.getText();
    
                } else if('error'.equalsIgnoreCase(parser.getText())){
                    parser.nextToken();
                    result += parser.getText();
    
                } else if('description'.equalsIgnoreCase(parser.getText())){
                    parser.nextToken();
                    result += parser.getText();
    
                }  else if('errorMessgae'.equalsIgnoreCase(parser.getText())){
                    parser.nextToken();
                    result += parser.getText();
    
                }  else if('result'.equalsIgnoreCase(parser.getText())){
                    parser.nextToken();
                    result += parser.getText();
                }
            }
    
            if(success == 'true') {
                if(!Test.isRunningTest()){
                    SRUtility.updateServiceRequestStep(srId, 'Payment Step', Constants.COMPLETED_STATUS, result);
                }
            } else {
                LoggerService.save(LoggerService.addApexServiceCalls('Payment','ADMRegistrationUtility','payment',(reqBody.length() < 131072 ? reqBody : ''),response.getBody(),null));
                if(!Test.isRunningTest()){
                    SRUtility.updateServiceRequestStep(srId, 'Payment Step', Constants.PENDING_STATUS, result + ' - ' + response.getStatusCode());
                }
            }
    
            } catch(Exception e){
                if(!Test.isRunningTest()){
                	SRUtility.updateServiceRequestStep(srId, 'Payment Step', Constants.PENDING_STATUS, e.getMessage());
                }
                LoggerService.save(LoggerService.createApexLog(e,'Payment','ADMRegistrationUtility','payment'));
            }
        //Prepare required structure and perform callout
        //Call below calloutHelper Method
        //return error message if anything is failed
        return '';
    }
    
    public static string validateRegistrationDocs(Id srId){
        //Checka documents are rpesent under ADM Registration Documents placeholder
        //return error message if anything is missing
        return '';
    }
    
    //--- Callout method used with Draft Application API
    @future(callout = true)
    public static void ADMCalloutHelperForCreateApplication(Map<String,String> headerConfiguration, String JSONBody, String muleConfig, String extraParam, Id srId) {
        //Just make the callout, if error code log in logger object

        HexaBPM__Service_Request__c srRecord = getSRRecord(srId);
        String stepName = srRecord.HexaBPM__External_Status_Name__c == Constants.STEP_REJECTED_STATUS ? 'ReVerify Details' : 'Verify Details';

        try{
        MuleSoftSetting__mdt  mulesoftAPI = Utilities.getMuleSoftDetails(muleConfig);
        Organization org = Utilities.getOrganizationDetails();
        String endPointURL = mulesoftAPI.SandboxURL__c ;
        if(!org.IsSandbox){
            endPointURL = mulesoftAPI.ProductionURL__c ; 
        }

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        request.setBody(JSONBody);
        System.debug('CreateApplicationResquestbodyPoint: '+JSONBody);

        for(String headerName : headerConfiguration.keySet()){
            request.setHeader(headerName, headerConfiguration.get(headerName));
        }

        request.setHeader('client_secret', mulesoftAPI.APIKey__c);
        request.setHeader('client_id', mulesoftAPI.APIId__c);
        request.setEndpoint(endPointURL + extraParam);
        request.setMethod(mulesoftAPI.Method__c);
        request.setTimeout(120000);
        
        HttpResponse response = http.send(request);
            System.debug('CreateApplicationResponsebodyPoint: '+JSONBody);
        //response.setBody('{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "006c0ad0-47fe-11ee-ae50-06b96bda3fa1", "results": { "success": true, "elapsed": 12232, "result": { "ACTIVE_APPLICATION": [ { "failureCode": "VAL116", "days": null, "results": [ "2023/496101" ], "details": { } } ], "CONCURRENT_APPLICATION": [ { "failureCode": "VAL061", "days": null, "results": [ "20230000091300" ], "details": { } } ] } } }');  
        system.debug(response.getBody());
        system.debug(response.getStatusCode());

        String success = '';
        String applicationId = '';
        String error = '';
        String description = '';
        String StepNotes = '';
        String failureCode = '';
            System.debug('#$#$# > response.getBody() > > '+response.getBody());
        LoggerService.save(LoggerService.addApexServiceCalls('Upload Document','ADMRegistrationUtility','ADMCalloutHelperForCreateApplication',(JSONBody.length() < 131072 ? JSONBody : ''), (response.getBody() + '-' + srId),null));
        CreateApplicationResponseModel createApplicationResponse = (CreateApplicationResponseModel)JSON.deserialize(response.getBody(), CreateApplicationResponseModel.class);
        CreateApplicationResponseModel.results noderesult = createApplicationResponse.results;
        CreateApplicationResponseModel.Result result = noderesult.result;

        //Monika:15/02/2024: If any application id in response is captured
        
        
        System.debug('noderesult'+noderesult.success+result);
        if(noderesult.success == true && result!=null)
        {
        List<CreateApplicationResponseModel.CONCURRENT_APPLICATION> applicationIdval = result.CONCURRENT_APPLICATION;
                if(applicationIdval!=null && (sRRecord.ADMApplicationNumber__c==null || sRRecord.ADMContractNumber__c==null))
                {
                    String appId = applicationIdval[0].results[0];
                   // sRRecord.ADMApplicationNumber__c = appId.Substring(appId.length() - 5);
                    sRRecord.ADMContractNumber__c = appId;
                    String substring = appId.substring(4);
                    while (substring.startsWith('0')) {
                    substring = substring.removeStart('0');
                    }

                    sRRecord.ADMApplicationNumber__c = substring;
                    if(!Test.isRunningTest()){
                        update sRRecord;
                    }
                }
                if(result.ACTIVE_APPLICATION != null && (result.ACTIVE_APPLICATION[0].failureCode != null || result.ACTIVE_APPLICATION[0].failureCode != '')){
                    StepNotes = getErrorDescription(result.ACTIVE_APPLICATION[0].failureCode);
                    if(sRRecord.ADMApplicationNumber__c <> null){
						failureCode = result.ACTIVE_APPLICATION[0].failureCode;
					}
                }
                
        }
        if(noderesult.success == true && result==null){
            //schedule callout agin after two minutes
        if (!hasScheduled) {
            String jobId = scheduleMethodtoADM(headerConfiguration, JSONBody, muleConfig, extraParam, srId);
            System.debug('Job ID: ' + jobId);
            StepNotes = 'Ready for Retrigger after 2 minutes';
            hasScheduled = true; 
        }
        }

        if(noderesult.success == false)
        {
            // if(result.error != null && result.error != ''){
            //     error = result.error;
            // } 
            if(result.errorMessgae != null && result.errorMessgae != ''){
                error += result.errorMessgae;
            }
            if(result.errorDetails != null && result.errorDetails != ''){
                error += result.errorDetails;
            }
            if(result.description != null && result.description != ''){
                description = result.description;
            }
            StepNotes += 'Error: '+ error + ' ' + description + ' - ' + result.statusCode;
            //StepNotes += 'Error: '+ error + ' ' + description + ' - ' + response.getStatusCode();
                
        }    //getErrorDescription
            // if(result.failureCode != null && result.failureCode != ''){
            //     StepNotes = getErrorDescription(result.failureCode);
            // } else 
            // if(result.ACTIVE_APPLICATION != null && (result.ACTIVE_APPLICATION[0].failureCode != null || result.ACTIVE_APPLICATION[0].failureCode != '')){
            //     StepNotes = getErrorDescription(result.ACTIVE_APPLICATION[0].failureCode);
            // }
     
            // if(result.applicationId == '' || result.applicationId == null){
            //     StepNotes += 'Error: '+ error + ' ' + description + ' - ' + response.getStatusCode();
            // }
            //  if(result == null){
            //      StepNotes += 'Error! Occured';
            //  }
        
        /*************************************/
           
            
            
        
        if((sRRecord.ADMApplicationNumber__c == null || sRRecord.ADMContractNumber__c== null) || (StepNotes != '' && failureCode !='' && !System.Label.DARI_Skip_Error_Codes.contains(failureCode)) || (StepNotes != '' && (failureCode == '' || failureCode == null))){
            if(!Test.isRunningTest()){
                SRUtility.updateServiceRequestStep(srId, stepName, Constants.PENDING_STATUS, StepNotes);
            }
            LoggerService.save(LoggerService.addApexServiceCalls('Draft Application','ADMRegistrationUtility','ADMCalloutHelperForCreateApplication',(JSONBody.length() < 131072 ? JSONBody : ''),response.getBody(),null));

        } else {
            uploadDocument(srId, result.applicationId, new List<String>{'Aldar Signed SPA'});
            if(!Test.isRunningTest()){
                SRUtility.updateServiceRequestStep(srId, stepName, Constants.COMPLETED_STATUS, StepNotes <> null ? StepNotes : 'Draft Application Completed');
            }

            HexaBPM__SR_Status__c objSRStatus = [SELECT Id, Name FROM HexaBPM__SR_Status__c WHERE Name =: Constants.COMPLETED_STATUS LIMIT 1];
            sRRecord.HexaBPM__External_SR_Status__c = objSRStatus.Id;
            sRRecord.HexaBPM__Internal_SR_Status__c = objSRStatus.Id;
           // sRRecord.ADMApplicationNumber__c = result.applicationId;Monika: 16/02/2024: handled above
           // sRRecord.ADMContractNumber__c = result.contractNo;
           if(!Test.isRunningTest()){
               update sRRecord;
           }
        } 
        
        } catch(Exception e){
            if(!Test.isRunningTest()){
                SRUtility.updateServiceRequestStep(srId, stepName, Constants.PENDING_STATUS, e.getMessage());
            }
            LoggerService.save(LoggerService.createApexLog(e,'Draft Application','ADMRegistrationUtility','ADMCalloutHelperForCreateApplication'));
        }

    }

    //--- Callout method used with all ADM callouts
    public static HttpResponse ADMCalloutHelper(Map<String,String> headerConfiguration, String JSONBody, String muleConfig, String extraParam) {
        //Just make the callout, if error code log in logger object

        MuleSoftSetting__mdt  mulesoftAPI = Utilities.getMuleSoftDetails(muleConfig);
        Organization org = Utilities.getOrganizationDetails();
        String endPointURL = mulesoftAPI.SandboxURL__c ;
        if(!org.IsSandbox){
            endPointURL = mulesoftAPI.ProductionURL__c ; 
        }

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        request.setBody(JSONBody);

        for(String headerName : headerConfiguration.keySet()){
            request.setHeader(headerName, headerConfiguration.get(headerName));
        }

        request.setHeader('client_secret',mulesoftAPI.APIKey__c);
        request.setHeader('client_id',mulesoftAPI.APIId__c);
        request.setEndpoint(endPointURL + extraParam);
        request.setMethod(mulesoftAPI.Method__c);
        request.setTimeout(120000);
        
        HttpResponse response = http.send(request);
        system.debug(response.getBody());
        system.debug(response.getStatusCode());
        return response;
    }

    //--- Callout method used with upload document
    public static String ADMCalloutHelperForUploadDocuments(Map<String,String> headerConfiguration, String JSONBody, String muleConfig, String extraParam, Id srId, String applicationId) {
        //Just make the callout, if error code log in logger object
        try{
        MuleSoftSetting__mdt  mulesoftAPI = Utilities.getMuleSoftDetails(muleConfig);
        Organization org = Utilities.getOrganizationDetails();
        String endPointURL = mulesoftAPI.SandboxURL__c ;
        if(!org.IsSandbox){
            endPointURL = mulesoftAPI.ProductionURL__c ; 
        }

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        request.setBody(JSONBody);
        system.debug('PointRequestUpload: '+JSONBody);
		system.debug(muleConfig+' Endpoint:: '+endPointURL);
        system.debug('headerConfiguration KeySet:: '+headerConfiguration.keySet());
        for(String headerName : headerConfiguration.keySet()){
            if(headerName <> null)
            request.setHeader(headerName, headerConfiguration.get(headerName));
        }

        request.setHeader('client_secret',mulesoftAPI.APIKey__c);
        request.setHeader('client_id',mulesoftAPI.APIId__c);
        request.setEndpoint(endPointURL);
        request.setMethod(mulesoftAPI.Method__c);
        request.setTimeout(120000);
       // HttpResponse response;
        HttpResponse response = http.send(request);
        system.debug('Point: '+response.getBody());
        system.debug('Point: '+response);

        system.debug(response.getStatusCode());

        JSONParser parser = JSON.createParser(response.getBody());
        String success = '';
        String error = '';
       //LoggerService.save(LoggerService.addApexServiceCalls('Upload Document','ADMRegistrationUtility','ADMCalloutHelperForUploadDocuments',(JSONBody.length() < 131072 ? JSONBody : ''),response.getBody(),null));
        while(parser.nextToken() != null){

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

        if(success.equalsIgnoreCase('true')){
            return 'Uploaded';
        } else {
           // LoggerService.save(LoggerService.addApexServiceCalls('Upload Document','ADMRegistrationUtility','ADMCalloutHelperForUploadDocuments',(JSONBody.length() < 131072 ? JSONBody : ''),response.getBody(),null));
            return 'Fail - '+ error;
        }

        } catch(Exception e){
            LoggerService.save(LoggerService.createApexLog(e,'Upload Document','ADMRegistrationUtility','ADMCalloutHelperForUploadDocuments'));
            return 'Error: '+e.getMessage();
        }
    }

    //--- Get Service Request Record Details
    public static HexaBPM__Service_Request__c getSRRecord(Id srId){
        HexaBPM__Service_Request__c srRecord = [Select Id, Unit__r.recordTypeId, SalesOrder__c, SalesOrder__r.NetAmount__c, SalesOrder__r.BookingDate__c,SPACounterSignedDate__c, 
        SalesOrder__r.Unit__r.CompletionDate__c, SalesOrder__r.SellingPrice__c, ADMContractNumber__c,ADMApplicationNumber__c, HexaBPM__External_Status_Name__c, Unit__r.ADMSectorName__c,
        Unit__r.ADMPlotNumber__c, Unit__r.Project__r.Trade_License_No__c 
         From HexaBPM__Service_Request__c Where Id =: srId];
        return srRecord;
    }

    //--- Get the primary contact of organization account
    public static Map<Id,Contact> getPrimaryContactsForAccount(Set<Id> accountsIds) {   

        Map<Id,Contact> contactMap = new Map<Id,Contact>();                  
        for(Contact contactRecord : [SELECT AccountId, Id, NationalIdNumber__c, Email, Nationality__c FROM Contact WHERE AccountId In : accountsIds AND PrimaryContact__c = true]){
            contactMap.put(contactRecord.AccountId,contactRecord);
        }
        return contactMap;
    }

    //--- Return a map contains SR Doc name with List of upload document model thats contains the file data
    public static Map<String, List<ADMRegistrationModel.UploadDocumentRequest>> getUploadedFiles(String serviceRequestId, List<String> srDocumentName){

        try{
            
            Map <String, HexaBPM__SR_Doc__c> srDocMap = new Map<String, HexaBPM__SR_Doc__c>();
            Map <String, ContentDocumentLink> contentDocMap = new Map<String, ContentDocumentLink>();
            Map<String, List<ADMRegistrationModel.UploadDocumentRequest>> documentsRequestsMap = new Map<String, List<ADMRegistrationModel.UploadDocumentRequest>>();

            for(HexaBPM__SR_Doc__c srDocRecord : [SELECT HexaBPM__Service_Request__c, HexaBPM__Service_Request__r.ADMApplicationNumber__c, Name, Id FROM HexaBPM__SR_Doc__c WHERE HexaBPM__Service_Request__c =: serviceRequestId AND Name in : srDocumentName]){
                srDocMap.put(srDocRecord.Id,srDocRecord);
            }

            for(ContentDocumentLink contentDocumentRecord : [SELECT ContentDocumentId, Id, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId in : srDocMap.keySet()]){
                contentDocMap.put(contentDocumentRecord.ContentDocumentId,contentDocumentRecord);
            }

            for(ContentVersion contentVersionRecord : [SELECT Id, ContentDocumentId, VersionData, Title,ContentDocument.Title FROM ContentVersion WHERE ContentDocumentId in : contentDocMap.keySet() ORDER BY CreatedDate DESC]){

                Blob file = contentVersionRecord.VersionData;
                String srDocName = srDocMap.get(contentDocMap.get(contentVersionRecord.ContentDocumentId).LinkedEntityId).Name;
                
                ADMRegistrationModel.UploadDocumentRequest documentObj = new ADMRegistrationModel.UploadDocumentRequest();
                documentObj.fileName = contentVersionRecord.ContentDocument.Title;
                //documentObj.fileData = EncodingUtil.base64Encode(file);
                documentObj.applicationId = srDocMap.get(contentDocMap.get(contentVersionRecord.ContentDocumentId).LinkedEntityId).HexaBPM__Service_Request__r.ADMApplicationNumber__c;
                documentObj.srDocId = srDocMap.get(contentDocMap.get(contentVersionRecord.ContentDocumentId).LinkedEntityId).Id;
				documentObj.contentVersionId = contentVersionRecord.Id;
                if(documentsRequestsMap.containsKey(srDocName)){
                   documentsRequestsMap.get(srDocName).add(documentObj);

                } else{
                    documentsRequestsMap.put(srDocName, new List<ADMRegistrationModel.UploadDocumentRequest>{documentObj});
                }
                System.debug('documentsRequestsMap'+documentsRequestsMap);
            }
            return documentsRequestsMap;

        } catch(exception e) {
            system.debug(e);
            return null;
        }
    }

    //Monika: 16/02/2024: New method created to Schedule ADMCallout after 2 minutes
    public static String scheduleMethodtoADM(Map<String,String> headerConfiguration, String JSONBody, String muleConfig, String extraParam, Id srId) {
        Datetime currentTimePlusTwoMinutes = System.now().addMinutes(2);
        String chronExpression = '' + currentTimePlusTwoMinutes.second() + ' ' + currentTimePlusTwoMinutes.minute() + ' ' + currentTimePlusTwoMinutes.hour() + ' ' + currentTimePlusTwoMinutes.day() + ' ' + currentTimePlusTwoMinutes.month() + ' ? ' + currentTimePlusTwoMinutes.year();  
        // Schedule a job to run the method again after two minutes
        String jobId = System.schedule('ADMCalloutScheduler', chronExpression, new ScheduleADMCreateAppCall(headerConfiguration, JSONBody, muleConfig, extraParam, srId));
        return jobId;
    }
    /*******************************************/
    public static String getErrorDescription(String errorCode){
            
        Map <String, String> errorCodesWithDescription = new Map<String, String>();
        errorCodesWithDescription.put('VAL033', 'Owner does not exist, you cannot complete the transaction. Please contact customer support if you have any inquiries.');
        errorCodesWithDescription.put('VAL053', 'The transaction cannot be completed. If the issue persists, please contact customer support.');
        errorCodesWithDescription.put('VAL074', 'Unable to proceed with application. Please contact customer support if you have any inquiries.');
        errorCodesWithDescription.put('VAL002', 'The transaction cannot be completed as there is another active application for this property. Please contact customer support if you have any inquiries.');
        errorCodesWithDescription.put('VAL126', 'The transaction cannot be completed. The property owners for the developer were not found. Please contact customer support.');
        errorCodesWithDescription.put('VAL127', 'The transaction cannot be completed. The property owner for the developer has no details. Please contact customer support.');
        errorCodesWithDescription.put('VAL128', 'The transaction cannot be completed. The owner does not have a developer license. Please contact customer support.');
        errorCodesWithDescription.put('VAL129', 'The transaction cannot be completed. This property is already sold. Please contact customer support.');
        errorCodesWithDescription.put('VAL025', 'Owner is blocked in the system and cannot complete the transaction. Please contact customer support if you have any inquiries.');
        errorCodesWithDescription.put('VAL044', 'Owner has financial obligations to the DMT, you cannot complete the transaction. Please contact customer support if you have any inquiries.');
        errorCodesWithDescription.put('VAL055', 'The transaction cannot be completed. Plot ID is empty. Please contact customer support if you have any inquiries.');
        errorCodesWithDescription.put('VAL116', 'The transaction cannot be completed. The company (owner/tenant) does not exist in the system, please contact customer support.');
        errorCodesWithDescription.put('VAL117', 'The transaction cannot be completed. The company (owner/tenant) users does not exist in the system, please contact customer support.');
        errorCodesWithDescription.put('VAL006', 'Property is blocked in the system and you cannot complete the transaction. Please contact customer support if you have any inquiries.');
        errorCodesWithDescription.put('VAL131', 'Property is not off-plan, you cannot complete the transaction. Please contact customer support if you have any inquiries.');
        errorCodesWithDescription.put('VAL125', 'The transaction cannot be completed. This property is already sold. Please contact customer support.');
        errorCodesWithDescription.put('VAL138', 'This property has been previously sold.');

        return errorCodesWithDescription.containsKey(errorCode) ? errorCodesWithDescription.get(errorCode) : '';
    }
}