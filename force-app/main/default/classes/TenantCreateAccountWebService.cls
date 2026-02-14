@RestResource(urlMapping = '/customer/createTenantAccount')
global without sharing class TenantCreateAccountWebService {
    public static string caseCloseErrorMsg = 'This unit is already having active contract';
    @HttpPost
    global static void createTenantAccount() {
        RestContextHandler handler = new RestContextHandler(false);
        TenantCaseCreationResponse responseData ;
        try {
            //payloadWrapper requestData = (payloadWrapper) JSON.deserialize(RestContext.request.requestBody.toString(), payloadWrapper.class);
            Map<String,String> requestData = handler.getRequestBodyMap();
            
            if(requestData.get('unitId') == ''){
                requestData = reBuildRequestData(requestData);
            }
            
            If(requestData.get('operation') == 'create'){
                responseData = createliveinTenantAccount(requestData);
            }
            else if(requestData.get('operation') == 'get'){
                responseData = getExistingCaseDetails(requestData);
            }
            
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
    
    public static Map<String,String> reBuildRequestData(Map<String,String> payloadRequestData){
        
        List<SalesOrder__c> salesOrderList = new List<SalesOrder__c>();
        
        If(!String.isBlank(payloadRequestData.get('ADMBuildingNumber')) || !String.isBlank(payloadRequestData.get('ADMPlotNumber')) || !String.isBlank(payloadRequestData.get('ADMUnitNumber'))){
            
            salesOrderList = [SELECT Id,Unit__c,Account__c From SalesOrder__c where Unit__c In (SELECT Id FROM Unit__c where ADMBuildingNumber__c =: payloadRequestData.get('ADMBuildingNumber') And ADMPlotNumber__c =: payloadRequestData.get('ADMPlotNumber') And ADMUnitNumber__c =: payloadRequestData.get('ADMUnitNumber')) limit 1];
            
            if(!salesOrderList.isEmpty()){
                payloadRequestData.put('salesOrderId',salesOrderList[0].Id);
                //payloadRequestData.put('customerId',salesOrderList[0].Account__c);
                payloadRequestData.put('unitId',salesOrderList[0].Unit__c);
            }
        }
        
        If(salesOrderList.isEmpty()){
            payloadRequestData.put('ownerId',getOwnerId(payloadRequestData));
        }
        
        return payloadRequestData;
    }
    
    public static Id getOwnerId(Map<String,String> payloadRequestData){
        
        List<ECSS_Case_Assignment_SLA__c> slaRecordList = [SELECT Id,Owner_Queue_Name__c from ECSS_Case_Assignment_SLA__c where Site__c =: payloadRequestData.get('projectCode') And Category__c = 'Tenant Onboarding' limit 1];
        
        List<Group> queueList = new List<Group>([SELECT Id, DeveloperName from Group where Type = 'Queue' and DeveloperName =: slaRecordList.isEmpty() ? null : slaRecordList[0].Owner_Queue_Name__c]);
        
        return queueList.isEmpty() ? null : queueList[0].Id;
    }
    
    
    public static TenantCaseCreationResponse getExistingCaseDetails(Map<String,String> payloadRequestData){
        
        TenantCaseCreationResponse response = new TenantCaseCreationResponse();
        String whereClause = '';
        
        if(payloadRequestData.get('unitId') == '' && payloadRequestData.get('AccountId') == ''){
            return response;
        }
        if(!String.isBlank(payloadRequestData.get('UnitId'))){
        whereClause = 'Unit__c = \'' + String.escapeSingleQuotes(payloadRequestData.get('unitId')) + '\'' +
            ' AND CaseCategory__c = \'Tenant Onboarding\'' +
            ' AND Status NOT IN (\'Closed\', \'Cancelled\', \'Completed\')';
        }  
        else {
            whereClause = 'AccountId = \'' + String.escapeSingleQuotes(payloadRequestData.get('AccountId')) + '\'' +
                ' AND CaseCategory__c = \'Tenant Onboarding\'' +
                ' AND Status NOT IN (\'Closed\', \'Cancelled\', \'Completed\')';
        }
        System.debug('whereClause-->'+whereClause);
        List<Case> caseList = returnCaseDetails(whereClause);
        return getTenantCaseResponse(caseList); 
    }
    
    public static TenantCaseCreationResponse createliveinTenantAccount(Map<String,String> payloadRequestData) {
        
        TenantCaseCreationResponse response = new TenantCaseCreationResponse();
        String accountId = '';
        String contractAccountId;
        String activeContractIdAndAccountId = '';
        
        //Create Account //check duplicate also
        Map<String, List<UtilitiesWithoutSharing.DuplicateAccountWrapper>> accountEmailPhoneMap =  UtilitiesWithoutSharing.findDuplicateAccountsByEmail(new set<string>{payloadRequestData.get('email')});
        boolean doesAccountExist = accountEmailPhoneMap != null && accountEmailPhoneMap.containsKey(payloadRequestData.get('email'));
        List<Asset> relatedAsset = new List<Asset>();
        If(!String.isBlank(payloadRequestData.get('unitId'))){
            relatedAsset = [Select Id,Unit__c from asset where Unit__c =:payloadRequestData.get('unitId') and RecordType.Name = 'ECSS Unit' limit 1];
        }
        
        if(!doesAccountExist){
            Account newAccount = new Account();
            newAccount.PersonEmail = payloadRequestData.get('email');
            newAccount.PersonMobilePhone = payloadRequestData.get('mobileCountryCode')+payloadRequestData.get('mobilePhone');
            newAccount.FirstName = payloadRequestData.get('firstName');
            newAccount.LastName = payloadRequestData.get('lastName');
            newAccount.AllowLiveAldarRegistration__c = true;
            newAccount.MobileCountryCode__pc = payloadRequestData.get('mobileCountryCode');
            newAccount.Nationality__pc ='';
            newAccount.CountryOfResidence__pc ='';
            newAccount.MobileNumberEnc__pc = payloadRequestData.get('mobileCountryCode')+payloadRequestData.get('mobilePhone');
            newAccount.EmailAddress__pc = payloadRequestData.get('email');
            newAccount.MobilePhone__pc = payloadRequestData.get('mobilePhone');
            newAccount.Sync_with_SFMC__c = true;
            newAccount.Sync_with_SFMC__pc = true;
            newAccount.CustomerVertical__c = 'Aldar Estates;Aldar Properties';
            newAccount.ECSS_Customer_Type__c =  'Tenant';
            insert newAccount;
            accountId = newAccount.Id;
        }else{
            List<UtilitiesWithoutSharing.DuplicateAccountWrapper> matchingAccounts = accountEmailPhoneMap.get(payloadRequestData.get('email'));
            Set<String> existingValues = new Set<String>();
            
            if (!matchingAccounts.isEmpty()) {
                Account existingAccount = matchingAccounts[0].account;
                Account acc = new Account();
                acc.Id =matchingAccounts[0].account.Id;
                
                if (String.isNotBlank(acc.ECSS_Customer_Type__c)) {
                    existingValues.addAll(acc.ECSS_Customer_Type__c.split(';'));
                }
                if(!existingValues.contains('Tenant')) {
                    existingValues.add('Tenant');
                    acc.ECSS_Customer_Type__c = String.join(new List<String>(existingValues), ';');                    
                    update acc;
                }               
                
                accountId = matchingAccounts[0].account.Id;
            }
        }
        
        //List<Account> tenantAccount = [Select Id,PersonContactId,PersonEmail From Account where Id =:accountId];
        //List<Account> ownerAccount = [Select Id,PersonContactId,PersonEmail From Account where Id =:payloadRequestData.customerId];
        Account tenantAccount;
        Account ownerAccount = new Account();
        Set<String> accountIds = new Set<String>{accountId,payloadRequestData.get('customerId')};
            System.debug('customerId-->'+ payloadRequestData.get('customerId'));
        for(Account objAcc : [SELECT Id, PersonContactId, PersonEmail FROM Account WHERE Id IN : accountIds limit 2]) {
            if(objAcc.Id == accountId){
                tenantAccount = objAcc;
            }
            if( !String.isBlank(payloadRequestData.get('customerId')) && objAcc.Id == payloadRequestData.get('customerId')){
                ownerAccount = objAcc;
            }
        }
        
        Case newCase = new Case();
        
        If(payloadRequestData.get('isDariVerified') == 'True'){
            
            activeContractIdAndAccountId = returnContractActive(relatedAsset.isEmpty() ? null : relatedAsset[0].Id);
            
            system.debug('activeContractIdAndAccountId-->'+activeContractIdAndAccountId);
            
            if(relatedAsset.size() > 0 && activeContractIdAndAccountId == '')
            {
                //contract is created 
                Contract newContract = createContract(payloadRequestData,relatedAsset[0].Id,accountId);
            
                contractAccountId = newContract?.AccountId;
                
            //Activate contract Id
            activateContract(newContract.Id);
            
            //Create Customer_Unit__c
                //Customer_Unit__c customerUnit = createCustomerUnit(accountId,relatedAsset[0].Id);
                
                //contract details
                Unit_Contract__c newContractDetail = createContractDetails(newContract.Id,relatedAsset[0].Id);
                
                newCase = createCase(payloadRequestData,newContract.Id,relatedAsset[0].Id,tenantAccount,ownerAccount);
            }
            
            if(relatedAsset.size() > 0 && activeContractIdAndAccountId != ''){
                String activeContractId = activeContractIdAndAccountId.split(';')[0];
                contractAccountId = activeContractIdAndAccountId.split(';')[1];
                //Activate contract Id
                //activateContract(activeContractId);
                //Create Case and autoclosed
                newCase = createCase(payloadRequestData,activeContractId,relatedAsset[0].Id,tenantAccount,ownerAccount);
                system.debug('activeContractId != null ');
            }
            if(contractAccountId!=null && contractAccountId == tenantAccount.Id){
                //throw new Exceptions.WebServiceException(caseCloseErrorMsg);
            //Closed Case
           autoCloseCase(newCase.Id);
            }  
        }
        else{
            newCase = createCase(payloadRequestData,'',relatedAsset.isEmpty() ? null : relatedAsset[0].Id,tenantAccount,ownerAccount);
            //Contract will be auto created once Closed by Community Manager
            //update case owner as per community selected
        }
        
        If(payloadRequestData.get('tawtheeqDoc') !=  ''){
            createTawtheeqDocument(newCase,payloadRequestData.get('tawtheeqDoc'));
        }
        
        return getCaseDetails(new List<Case>{newCase});
    }
    
    public static void createTawtheeqDocument(Case newCase, string body){
        
        Document__c doc = new Document__c();
        doc.RecordTypeId = Schema.SObjectType.Document__c.getRecordTypeInfosByName().get(String.valueOf('Case Document')).getRecordTypeId();
        doc.DocumentType__c = 'Tawtheeq';
        doc.Status__c = 'Pending';
        doc.Case__c = newCase.Id;
        
        if(!Test.isRunningTest()){
            insert doc;
        }
        
        Blob bodyBlob = EncodingUtil.base64Decode(body);
        
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Tawtheeq Document For ' + newCase.Id;
        cv.PathOnClient = 'Tawtheeq_Document.pdf';
        cv.VersionData = bodyBlob;
        
        insert cv;
        
        ContentVersion newCV = [ SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = newCV.ContentDocumentId;
        cdl.LinkedEntityId = doc?.Id; 
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        
        insert cdl;
        
    }
    
    public static String returnContractActive(String relatedAssetId){
        
        String activeContractIdAndAccountId = '';
        //List<Contract> contractList = [Select Id,Asset__c,EndDate from Contract where ECSS_ContractOrganizationType__c = 'Tenancy' and EndDate > TODAY and Asset__c =:relatedAssetId];
        List<Unit_Contract__c> contractDetailsList = [Select Id,Contract__c, Contract__r.AccountId from Unit_Contract__c where Contract__r.ECSS_ContractOrganizationType__c = 'Tenancy' and Contract__r.EndDate > TODAY and ECSS_Unit__c =:relatedAssetId];
        
        If(contractDetailsList.size() > 0 && contractDetailsList[0].Contract__c!=null){
            activeContractIdAndAccountId = contractDetailsList[0].Contract__c+';'+contractDetailsList[0].Contract__r.AccountId;
        }
        
        return activeContractIdAndAccountId; 
    }
    
    public static Case createCase(Map<String,String> payloadRequestData,String contractId,String relatedAssetId,Account tenantAccount,Account ownerAccount){
        
        Case newCase = new Case();
        newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(String.valueOf('ECSS Query')).getRecordTypeId();
        newCase.CustomerType__c = 'Tenant';
        newCase.ECSS_CompanyOptions__C = 'Provis';
        newCase.SubVertical__c = 'Provis';
        newCase.CaseCategory__c = 'Tenant Onboarding';
        newCase.Origin = 'Customer Portal';
        newCase.AccountId = String.isBlank(payloadRequestData.get('customerId')) ? tenantAccount.Id : payloadRequestData.get('customerId');
        newCase.Tenant_Contact__c = tenantAccount.PersonContactId;
        newCase.ContactId = ownerAccount.PersonContactId;
        //newCase.ContactEmail = ownerAccount.personEmail;
        newCase.NewContactEmail__c = tenantAccount.personEmail;
        newCase.Unit__c = String.isBlank(payloadRequestData.get('unitId')) ? null : payloadRequestData.get('unitId');
        newCase.SalesOrder__c = String.isBlank(payloadRequestData.get('salesOrderId')) ? null : payloadRequestData.get('salesOrderId');
        newCase.SalesOrder__c = null;
        newCase.Status = Constants.CASE_IN_PROGRESS;
        //newCase.StatusReason__c = payloadRequestData.isDariVerified ? Constants.WITH_RESOLUTION_CASE : null;
        newCase.Email_Not_Triggered__c = true;
        newCase.Assigned_To__c = UserInfo.getUserId();
        newCase.ECSS_Contract__c = contractId != '' ? contractId : null;
        newCase.AssetId = relatedAssetId != '' ? relatedAssetId : null;
        If(payloadRequestData.get('ownerId') != null){
            newCase.ownerId = payloadRequestData.get('ownerId');
        }
        insert newCase;
        
        return newCase;
    }
    
    public static void activateContract(string contractId){
        Contract  newContract  = new Contract(id = contractId, status = 'Activated');
        
        update newContract;
    }
    
    public static void autoCloseCase(string caseId){
        Case  newCase  = new case(id = caseId, status = 'Closed');
        
        update newCase;
    }
    
    public static Unit_Contract__c createContractDetails(String newContractId,String relatedAssetId){
        
        Unit_Contract__c newContractDetail = new Unit_Contract__c();
        newContractDetail.Contract__c = newContractId;
        newContractDetail.RecordTypeId = Schema.SObjectType.Unit_Contract__c.getRecordTypeInfosByName().get(String.valueOf('Contract Unit')).getRecordTypeId();
        //newContractDetail.ECSS_CustomerUnit__c = customerUnitId;
        newContractDetail.ECSS_Unit__c = relatedAssetId; //asset
        insert newContractDetail;
        
        return newContractDetail;
    }
    
    public static void createTenantContract(Set<Id> caseIds){
        
        Map<String, Case> caseIdToRecord = new Map<String, Case>();
        List<Contract> newContractToInsert = new List<Contract>();
        List<Contract> contractToUpdate = new List<Contract>();
        List<Case> caseToUpdate = new List<Case>();
        
        Map<Id,Unit_Contract__c> assetIdHavingActiveContract = new Map<Id,Unit_Contract__c>();
        Map<Id,Case> assetIdCorrespondingCase = new Map<Id,Case>();
        Map<Id,Case> caseIdCorrespondingCase = new Map<Id,Case>();
        
        for(Case objCase :[Select Id, AssetId, AccountId,Tenant_Contact__c, ECSS_Contract_Start_Date__c,ECSS_Contract_End_Date__c,Contract_Tawtheeq_Number__c,Tenant_Contact__r.AccountId,Tenant_Contact__r.Email from Case where Id In :caseIds])
        {
            assetIdCorrespondingCase.put(objCase.AssetId, objCase);
            caseIdCorrespondingCase.put(objCase.Id, objCase);
        }
        
        For(Unit_Contract__c currentContactDetails : [Select Id,Contract__c, Contract__r.AccountId,ECSS_Unit__c from Unit_Contract__c where Contract__r.ECSS_ContractOrganizationType__c = 'Tenancy' and Contract__r.EndDate > TODAY and ECSS_Unit__c In :assetIdCorrespondingCase.keySet()]){
            assetIdHavingActiveContract.put(currentContactDetails.ECSS_Unit__c,currentContactDetails);
        }
        
        For(Case caseTriggered : [Select Id, AssetId, AccountId,Tenant_Contact__c, ECSS_Contract_Start_Date__c,ECSS_Contract_End_Date__c,Contract_Tawtheeq_Number__c,Tenant_Contact__r.AccountId,Tenant_Contact__r.Email from Case where Id In :caseIds]){
            Case currentCase = Test.isRunningTest() ? caseTriggered : (case)Trigger.NewMap.get(caseTriggered.Id);
            if(assetIdHavingActiveContract.containsKey(currentCase.AssetId)){
                // added by Vinay
                Case objCase = caseIdCorrespondingCase.get(currentCase.Id);
                if(objCase!=null && objCase.Tenant_Contact__c!=null && objCase.Tenant_Contact__r.AccountId != assetIdHavingActiveContract.get(currentCase.AssetId).Contract__r.AccountId){
                    currentCase.addError(caseCloseErrorMsg);
                }
                contractToUpdate.add(new contract(id = assetIdHavingActiveContract.get(currentCase.AssetId).Contract__c, status = 'Activated',Asset__c = currentCase.AssetId ));
            }
            else{  
                Contract  newContract  = new Contract();
                newContract.Asset__c  = caseTriggered.AssetId;
                newContract.ECSS_TawtheeqContractNo__c = caseTriggered.Contract_Tawtheeq_Number__c; 
                newContract.ECSS_LeaseCategory__c = 'INDIVIDUAL';
                newContract.Status = 'Draft';// How to activate
                newContract.AccountId = caseTriggered.Tenant_Contact__r.AccountId; // Mandate
                newContract.ECSS_ContractOrganizationType__c = 'Tenancy';
                //newContract.ECSS_AnnualRent__c = payloadRequestData.annualRent;
                newContract.StartDate = caseTriggered.ECSS_Contract_Start_Date__c;
                newContract.EndDate = caseTriggered.ECSS_Contract_End_Date__c;
                //newContract.AccountSAPId__c= '';
                //newContract.ECSS_DepositAmount__c = Integer.valueOf(payloadRequestData.depositAmount);
                //newContract.ECSS_NumberofChequesPerYear__c = Integer.valueOf(payloadRequestData.numberofChequesPerYear);
                newContract.ECSS_LeaseApprovalStatus__c= 'Draft';
                newContractToInsert.add(newContract);        
            }
            caseIdToRecord.put(currentCase.Id, currentCase);
            assetIdCorrespondingCase.put(caseTriggered.AssetId,caseTriggered);
        }
        
        if(!contractToUpdate.isEmpty()){
            //Update contractToUpdate;
            
              For(Contract con : contractToUpdate){
                Case objCase = caseIdToRecord.get(assetIdCorrespondingCase.get(con.Asset__c).Id);
                if(objCase!=null){
                    objCase.ECSS_Contract__c =con.id;
                    objCase.NewContactEmail__c = assetIdCorrespondingCase.get(con.Asset__c).Tenant_Contact__r.Email;
                }
              }
            
        }
        
        if(!newContractToInsert.isEmpty()){
            insert newContractToInsert;
            
            List<Contract> newcontractToUpdate = new List<Contract>();
            
            For(Contract currentContract : newContractToInsert){
                newcontractToUpdate.add( new Contract(id = currentContract.Id,status = 'Activated'));
            }
            
            system.debug('newcontractToUpdate-->'+newcontractToUpdate);
            
            if(!newcontractToUpdate.isEmpty()){
            update newcontractToUpdate;
            }
            
            List<Unit_Contract__c> contractDetailsToInsert = new List<Unit_Contract__c>();
            //List<Case> caseToUpdate = new List<Case>();
            //create contract Details
            For(Contract con : newContractToInsert){
                Unit_Contract__c newContractDetail = new Unit_Contract__c();
                newContractDetail.Contract__c = con.Id;
                newContractDetail.RecordTypeId = Schema.SObjectType.Unit_Contract__c.getRecordTypeInfosByName().get(String.valueOf('Contract Unit')).getRecordTypeId();
                //newContractDetail.ECSS_CustomerUnit__c = con.AccountId;
                newContractDetail.ECSS_Unit__c = con.Asset__c; //asset
                contractDetailsToInsert.add(newContractDetail);
                Case objCase = caseIdToRecord.get(assetIdCorrespondingCase.get(con.Asset__c).Id);
                if(objCase!=null){
                    objCase.ECSS_Contract__c =con.id;
                    objCase.NewContactEmail__c = assetIdCorrespondingCase.get(con.Asset__c).Tenant_Contact__r.Email;
                }
            }
            
            If(!contractDetailsToInsert.isEmpty()){
                insert contractDetailsToInsert;
            }
            
        }
    }
    
    public static Contract createContract(Map<String,String> payloadRequestData,String relatedAssetId, String tenantAccountId){
        
        Contract  newContract  = new Contract();
        newContract.Asset__c  = relatedAssetId;
        //newContract.ECSS_TawtheeqContractNo__c = 'asd'; 
        newContract.ECSS_LeaseCategory__c = 'INDIVIDUAL';
        newContract.Status = 'Draft';// How to activate
        newContract.AccountId = tenantAccountId; // Mandate
        newContract.ECSS_ContractOrganizationType__c = 'Tenancy';
        newContract.ECSS_AnnualRent__c = payloadRequestData.get('annualRent');
        newContract.StartDate =String.isBlank(payloadRequestData.get('startDate')) ? null : Date.valueOf(payloadRequestData.get('startDate'));
        newContract.EndDate = String.isBlank(payloadRequestData.get('endDate')) ? null : Date.valueOf(payloadRequestData.get('endDate'));
        //newContract.AccountSAPId__c= '';
        newContract.ECSS_DepositAmount__c = String.isBlank(payloadRequestData.get('depositAmount')) ? 0 : Decimal.valueOf(payloadRequestData.get('depositAmount'));
        newContract.ECSS_NumberofChequesPerYear__c = String.isBlank(payloadRequestData.get('numberofChequesPerYear')) ? 0 : Decimal.valueOf(payloadRequestData.get('numberofChequesPerYear'));
        newContract.ECSS_LeaseApprovalStatus__c= 'Draft';
        insert newContract;
        
        
        return newContract;
        
    }
    
    public static TenantCaseCreationResponse getCaseDetails(List<Case> newCase){
        
        String whereClause = '';
        List<Case> caseList = new List<Case>();
        
        if(!newCase.isEmpty() && newCase[0]?.Id != null){
            whereClause = 'Id = \'' + newCase[0]?.Id + '\' ';
            caseList = returnCaseDetails(whereClause);
        }
        
        return getTenantCaseResponse(caseList);
    }
    
    public static List<Case> returnCaseDetails(String whereClause){ 
        
        String query= 'SELECT Id,Status,CaseNumber,OwnerName__c,Owner.Name,OwnerId ,CaseComments__c ,Unit__c,Unit__r.Project__r.OA_Community_Name__c,Unit__r.BuildingSectionName__r.Precint_Name__c,LastModifiedDate,Unit__r.Name,Type,Description,CreatedDate,CommentsForCustomer__c';
        query += ' FROM Case ' + (String.isNotBlank(whereClause) ? ' WHERE ' + whereClause : '');
        
        System.debug('query-->'+query);
        
        return Database.query(query); 
    }
    
    public static TenantCaseCreationResponse getTenantCaseResponse(List<Case> caseList){
        
        TenantCaseCreationResponse tenantCaseCreationResponse = new TenantCaseCreationResponse();
        
        if (!caseList.isEmpty()) {
            
            tenantCaseCreationResponse.caseId = caseList[0].Id;
            tenantCaseCreationResponse.referenceNumber = caseList[0].CaseNumber;
            tenantCaseCreationResponse.description = caseList[0].Description;
            tenantCaseCreationResponse.ownerName = caseList[0].Owner.Name ;
            tenantCaseCreationResponse.status = caseList[0].status;
            tenantCaseCreationResponse.createdDate = string.valueof(caseList[0].CreatedDate);
            tenantCaseCreationResponse.caseNumber = caseList[0].CaseNumber;
            tenantCaseCreationResponse.type = caseList[0].Type;
            tenantCaseCreationResponse.commentsForCustomer = caseList[0].CommentsForCustomer__c;
            tenantCaseCreationResponse.modifiedDate = string.valueof(caseList[0].LastModifiedDate);
            tenantCaseCreationResponse.precinctName = caseList[0].Unit__r.BuildingSectionName__r.Precint_Name__c;
            tenantCaseCreationResponse.unitName = caseList[0].Unit__r.Name;
            tenantCaseCreationResponse.communityName = caseList[0].Unit__r.Project__r.OA_Community_Name__c;
            tenantCaseCreationResponse.CommunityManager = GenericCaseCreationWebService.getCommunityManagerNames(caseList[0].OwnerId);
        }
        
        return tenantCaseCreationResponse;
    }
    
    public class TenantCaseCreationResponse{
        public string caseId;
        public string referenceNumber;
        public string description;
        public string ownerName;
        public string status;
        public string createdDate;
        public string caseNumber;
        public string type;
        public string precinctName;
        public string unitName;
        public string communityName;
        public string commentsForCustomer;
        public string modifiedDate;
        public list<string> CommunityManager = new list<string>();
    }
    
}