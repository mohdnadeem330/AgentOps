@RestResource(urlMapping = '/customer/createAccount')
global without sharing class CustomerCreateAccountWebService {
    
    @HttpPost
    global static void createAccount() {
        RestContextHandler handler = new RestContextHandler(false);
        try {
            payloadWrapper requestData = (payloadWrapper) JSON.deserialize(RestContext.request.requestBody.toString(), payloadWrapper.class);
            System.debug('Request Data: ' + requestData);
            payloadWrapper restructuredPayload = restructurePayload(requestData);
            System.debug('restructuredPayload::' + restructuredPayload);
            CreateAccountResponse responseData = createliveinAccount(restructuredPayload);
            handler.response.data = responseData;
            handler.response.success = true;
            handler.finalize();
        } catch (Exception ex) {
            System.debug('Exception at Line: ' + ex.getLineNumber() + ' Message: ' + ex.getMessage());
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = ex.getMessage();
            handler.finalize(ex);
        }
    }
    
    public static CreateAccountResponse createliveinAccount(payloadWrapper payloadRequestData) {
        CreateAccountResponse response = new CreateAccountResponse();
        List<Account> accountsToInsert = new List<Account>();
        List<Buyer> processedBuyers = new List<Buyer>();
        List<AgencyTeam__c> agencyTeamtoInsert = new List<AgencyTeam__c>();
        List<Account> allRelevantAccountsdata = new List<Account>();
        List<Communication_Preference__c> communicationPreferences = new List<Communication_Preference__c>();
        List<Communication_Preference__c> cpForExistingUser = new List<Communication_Preference__c>();
        Set<Id> accountIdSet = new Set<Id>();
        Map<String, List<UtilitiesWithoutSharing.DuplicateAccountWrapper>> accountEmailPhoneMap;
        Set<String> emailSet = new Set<String>();
        List<Account> existBuyersToSyncSFMCList = new List<Account>();
        List<Account> existingBuyeraccToUpdateSAPId = new List<Account>();
        set<Id> existingBuyeraccListToSAPId = new set<Id>();
        
        //sync_with_SFMC
        list<Account> sellerAcc = [SELECT Id,Sync_with_SFMC__pc FROM Account WHERE (Sync_with_SFMC__c= false OR Sync_with_SFMC__pc =false) and Id =:payloadRequestData.customerId ];
        if(!sellerAcc.isEmpty()){
        sellerAcc[0].Sync_with_SFMC__c = true;
            sellerAcc[0].Sync_with_SFMC__pc = true;
        Update sellerAcc;
        }
        
         for (Buyer buyer : payloadRequestData.BuyerList) {
              emailSet.add(buyer.email);
                Set<String> phoneNoSet = new Set<String>{buyer.mobilePhone};
                
         }
        if (!emailSet.isEmpty()) {
            accountEmailPhoneMap = UtilitiesWithoutSharing.findDuplicateAccountsByEmail(emailSet);
        }

        system.debug('Buyerlist'+payloadRequestData.BuyerList);
        if (payloadRequestData.BuyerList.size() > 0) {
            for (Buyer buyer : payloadRequestData.BuyerList) {
                boolean doesAccountExist = accountEmailPhoneMap != null && accountEmailPhoneMap.containsKey(buyer.email) && accountEmailPhoneMap.get(buyer.email) != null;
                if (!doesAccountExist) {
                    Account newAccount = new Account();
                    newAccount.PersonEmail = buyer.email;
                    newAccount.PersonMobilePhone = buyer.mobileCountryCode+buyer.mobilePhone;
                    newAccount.FirstName = buyer.firstname;
                    newAccount.LastName = buyer.lastname;
                    newAccount.AllowLiveAldarRegistration__c = true;
                    newAccount.MobileCountryCode__pc = buyer.mobileCountryCode;
                    newAccount.Nationality__pc ='';
					newAccount.CountryOfResidence__pc ='';
                    newAccount.MobileNumberEnc__pc = buyer.mobileCountryCode+buyer.mobilePhone;
                    newAccount.EmailAddress__pc = buyer.email;
                    newAccount.MobilePhone__pc = buyer.mobilePhone;
                    newAccount.Sync_with_SFMC__c = true;
                    newAccount.Sync_with_SFMC__pc = true;
					newAccount.CustomerVertical__c = 'Aldar Estates';
                    accountsToInsert.add(newAccount);
                    processedBuyers.add(buyer);
                } else {
                    List<UtilitiesWithoutSharing.DuplicateAccountWrapper> matchingAccounts = accountEmailPhoneMap.get(buyer.email);
                    if (!matchingAccounts.isEmpty()) {
                        Account existingAccount = matchingAccounts[0].account;
                        Account acc = new Account();
                        acc.Id =matchingAccounts[0].account.Id;
                        acc.Sync_with_SFMC__pc= true;
                        acc.Sync_with_SFMC__c= true;
                        
                        existingAccount.Sync_with_SFMC__c = true;
                        if(existingAccount.CustomerAppWebUser__c == false){
                            if ( existingAccount.Opportunity_Units__r.isEmpty() ){
                                //create CP for existing Acc with cutsomer web app user False and dont have any active SO 
                                Communication_Preference__c preference = new Communication_Preference__c();
                                preference.Status__c = 'Link Sent';
                                preference.Account__c = existingAccount.Id;
                                preference.Active__c = true;
                                preference.Category__c = 'NOC-FastTrack';
                                cpForExistingUser.add(preference);
                            }
                        }
                        existBuyersToSyncSFMCList.add(acc);
                        allRelevantAccountsdata.add(existingAccount);
                    }
                    processedBuyers.add(buyer);
                }
            }
        }
        if( !existBuyersToSyncSFMCList.isEmpty() && !Test.isRunningTest()){
            update existBuyersToSyncSFMCList;
        }
        //CALL SAP API EXISTING BUYER || START
        list<Account> existingBuyerAcc = [SELECT Id,SapAccountID__c,CustomerVertical__c FROM Account WHERE ID IN : existingBuyeraccListToSAPId LIMIT 1];
        if(!existingBuyerAcc.isEmpty() ){callSAPAPI(existingBuyerAcc[0]); }
        
        if (!accountsToInsert.isEmpty()) {
            insert accountsToInsert;
            for (Account insertedAccount : accountsToInsert) {
                if (!accountIdSet.contains(insertedAccount.Id)) { 
                    accountIdSet.add(insertedAccount.Id);
                    allRelevantAccountsdata.add(insertedAccount);
                }
            }
        }
        //Insert CP for existing users
		 if (!cpForExistingUser.isEmpty()) {
            insert cpForExistingUser;
        }
        
        for (Account insertedAccount : accountsToInsert) {
            Communication_Preference__c preference = new Communication_Preference__c();
            preference.Status__c = 'Link Sent';
            preference.Account__c = insertedAccount.Id;
            preference.Active__c = true;
            preference.Category__c = 'NOC-FastTrack';
            communicationPreferences.add(preference);
        }
        
        if (!communicationPreferences.isEmpty()) {
            insert communicationPreferences;
        }
        
        if (payloadRequestData.BuyerList.size() == processedBuyers.size()) {
            if (!allRelevantAccountsdata.isEmpty()) {
                response = createServiceRequest(payloadRequestData, allRelevantAccountsdata);
            }
        }
        //CALL SAP API SELLER || START
        list<Account> sellerAccToSyncSAP = [SELECT Id,SapAccountID__c,CustomerVertical__c FROM Account WHERE Id=:payloadRequestData.customerId];
        if( !sellerAccToSyncSAP.isEmpty() ){callSAPAPI(sellerAccToSyncSAP[0]);}
        //CALL SAP API SELLER|| END
        return response;
        
    }
    
    public static CreateAccountResponse createServiceRequest(payloadWrapper payloadRequestData, List<Account> BuyerAccounts) {
        CreateAccountResponse response = new CreateAccountResponse();
        String srType = 'Property Transfer NOC';
        Group queue = Utilities.getQueueInformation(CustomerAPIConstants.CCA_ONLINE_QUEUE);
        String caseOwnerId = queue.Id != null ? queue.Id : UserInfo.getUserId();
        Account primaryBuyerAccount = null;
        Map<String, Account> emailToAccountMap = new Map<String, Account>();
        List<Account> secondaryBuyerAccounts = new List<Account>();

        for (Account account : BuyerAccounts) {
            if (account.PersonEmail != null) {
                emailToAccountMap.put(account.PersonEmail, account);
            }
        }
        
        for (Buyer buyer : payloadRequestData.BuyerList) {
            if (emailToAccountMap.containsKey(buyer.email)) {
                Account matchedAccount = emailToAccountMap.get(buyer.email);
                if (!buyer.isPrimary) {
                    secondaryBuyerAccounts.add(matchedAccount);
                }else
                 {
                    primaryBuyerAccount = matchedAccount;
                    //break;
                }
            }
        }
        
        response.buyerId = primaryBuyerAccount.Id;
        response.secondaryBuyerList = secondaryBuyerAccounts;

        List<HexaBPM__Service_Request__c> existingSRs = [SELECT Id, Case__c FROM HexaBPM__Service_Request__c WHERE Unit__c = :payloadRequestData.unitId AND HexaBPM__Customer__c = :payloadRequestData.customerId AND SRType__c = :srType AND HexaBPM__External_Status_Name__c NOT IN ('Draft', 'Cancelled') AND Origin__c IN ('Customer Portal','Customer App') ORDER BY CreatedDate Desc Limit 1];
        if (existingSRs.isEmpty()) {
            Case newCase = new Case();
            newCase.RecordTypeId = Utilities.getRecordTypeId('Case', Constants.STANDARD_CASE_RT);
            newCase.Origin = 'Customer Portal';
            newCase.AccountId = payloadRequestData.customerId;
            newCase.Unit__c = payloadRequestData.unitId;
            newCase.SalesOrder__c = payloadRequestData.salesOrderId;
            newCase.SubVertical__c = 'Customer Management';
            newCase.CaseCategory__c = srType;
            newCase.Subject = srType;
            newCase.OwnerId = caseOwnerId;
            newCase.Status = Constants.CLOSED_CASE;
            newCase.StatusReason__c = Constants.WITH_RESOLUTION_CASE;
            newCase.Email_Not_Triggered__c = true;
            newCase.Assigned_To__c = UserInfo.getUserId();
            if (!Test.isRunningTest()) {
            	insert newCase;
            }
            
            HexaBPM__Service_Request__c newSR = new HexaBPM__Service_Request__c();
            newSR.RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', srType);
            newSR.Origin__c = 'Customer Portal';
            newSR.HexaBPM__Customer__c = payloadRequestData.customerId;
            newSR.Unit__c = payloadRequestData.unitId;
            newSR.SalesOrder__c = payloadRequestData.salesOrderId;
            newSR.SRType__c = srType;
            newSR.ChargeType__c ='Transfer Normal';
            newSR.BuyerName__c = primaryBuyerAccount != null ? primaryBuyerAccount.Id : null;
            newSR.BuyerEmail__c =  primaryBuyerAccount.personEmail;
            newSR.Case__c = newCase.Id;
            if(payloadRequestData.transferSellingPrice != null){
            newSR.TransferSellingPrice__c = Decimal.valueOf(payloadRequestData.transferSellingPrice);
            }
            newSR.Unused_Service_Charge__c = payloadRequestData.unusedServiceCharge;
            newSR.Has_OA_NOC__c = payloadRequestData.hasOwnerNOCExist;
            newSR.Retrive_Buyer_Acc_Docs__c = true;
            newSR.MOUSigned__c ='Yes';
            
            if (!Test.isRunningTest()) {
                insert newSR;
                System.enqueueJob(new FastTRackSRDOC(newSR));
            }
          	 List<AgencyTeam__c> agencyTeamtoInsert = new List<AgencyTeam__c>();
            if(payloadRequestData.BuyerList.size() >1 ){
            for (Buyer buyer : payloadRequestData.BuyerList) {
                if (!buyer.isPrimary && emailToAccountMap.containsKey(buyer.email)) {
                    Account matchedJoAccount = emailToAccountMap.get(buyer.email);
                    AgencyTeam__c agencyRecord = new AgencyTeam__c();
                    agencyRecord.Account__c = matchedJoAccount.Id;
                        agencyRecord.Name = buyer.firstName + ' ' + buyer.lastName;
                    agencyRecord.ServiceRequest__c = newSR.Id;
                        agencyRecord.EmailAddress__c = matchedJoAccount.PersonEmail != null ? matchedJoAccount.PersonEmail : buyer.email;
                    agencyRecord.RelationshipType__c = 'Joint Owner P-P';
                    agencyRecord.PrimaryOwner__c = buyer.isPrimary;
                        agencyRecord.RecordTypeId = Schema.SObjectType.AgencyTeam__c.getRecordTypeInfosByDeveloperName().get('JointOwner').getRecordTypeId();
                        //agencyRecord.ShareHoldingPercentage__c = integer.Valueof('1');
                    agencyTeamtoInsert.add(agencyRecord);
                }
            }   
            if (!agencyTeamtoInsert.isEmpty()) {
                insert agencyTeamtoInsert;
            }
            }
            response.SRId = newSR.Id;
            response.CaseId = newCase.Id;
            return response;
        }
        response.SRId = existingSRs[0].Id;
            response.CaseId = existingSRs[0].Id;
        return response;
    }
    
    public static payloadWrapper restructurePayload(payloadWrapper request) {
        
        Buyer primaryBuyer = new Buyer();
        primaryBuyer.firstName = request.firstName;
        primaryBuyer.lastName = request.lastName;
        primaryBuyer.email = request.email;
        primaryBuyer.mobileCountryCode = request.mobileCountryCode;
        primaryBuyer.mobilePhone = request.mobilePhone;
        primaryBuyer.isPrimary = true;
        
        if (request.BuyerList == null) {
            request.BuyerList = new List<Buyer>();
        }
        
        request.BuyerList.add(primaryBuyer);
        
        request.firstName = null;
        request.lastName = null;
        request.email = null;
        request.mobileCountryCode = null;
        request.mobilePhone = null;
        
        system.debug('RestructuredResponse'+request);
        return request;
        
    }
    
    public static void callSAPAPI (Account accRecord){

        if (accRecord.SapAccountID__c == null || accRecord.SapAccountID__c == '' ) {
            Set<String> verticals = new Set<String>();

            if (accRecord.CustomerVertical__c != null) {
                verticals.addAll(accRecord.CustomerVertical__c.split(';'));
            }else{
                accRecord.CustomerVertical__c = 'Aldar Estates';
            }
            if (!verticals.contains('Aldar Estates')) {
                accRecord.CustomerVertical__c =  accRecord.CustomerVertical__c + ';Aldar Estates';
            }else{
                //Already contaiins Aldar Estates As CusVertical
                accRecord.ECSS_LastModifiedByIntegration__c= false;
            }
            update accRecord;
        
    }
    }
    
    public class CreateAccountResponse {
    public Id buyerId;
    public List<Account> secondaryBuyerList;
    public Id CaseId;
    public Id SRId;
    }

    public class payloadWrapper {
    public String firstName;
    public String lastName;
    public String email;
    public String mobileCountryCode;
    public String mobilePhone;
    public List<Buyer> BuyerList;
    public String customerId;
        public String unitId;
        public String salesOrderId;
        public String transferSellingPrice;
        public String unusedServiceCharge;
        public Boolean hasOwnerNOCExist;
        public String referenceId;

    }

    public class Buyer {
    public String firstname;
    public String lastname;
    public String email;
    public String mobileCountryCode;
    public String mobilePhone;
    public Boolean isPrimary;
    }
    
}