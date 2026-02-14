public without sharing class ECSS_CaseTriggerHelper {

    public static CaseTriggerMetadata.CaseRecordTypeWrapper rtWrapper = CaseTriggerMetadata.getRTypeInstance(CaseTriggerHelper.recordTypeByNames);
    public static CaseTriggerMetadata.QueueWrapper queueWrapper = CaseTriggerMetadata.getqueueWrInstance(CaseTriggerHelper.getQueueMap());

    public static void updateSAPValues(List<Case> newList) {
        List<Id> caseIds = new List<Id>(new Map<Id, Case>(newList).keySet());
        Map<String, Sales_Organization__c> defSalesOrgMap = new Map<String, Sales_organization__c>();
        Map<String, String> recordTypeAssignment = new Map<String, String>();
       
        List<Case> casesToUpdate = [
            SELECT
            Id,
            ECSS_UnitSAPExternalId__c,CaseCategory__c,
            Asset.ExternalIdentifier,Recordtype_Name__c,
            ECSS_SAPSalesOrganization__c,
            ECSS_Contract__c,
            Owner.Name,
            Owner_Name__c,
            ECSS_Contract__r.ECSS_SalesOrganization__c,
            ECSS_Contract__r.ECSS_DistributionChannel__c,
            RecordType.developerName,
            ECSS_DistributionChannel__c,
            ECSS_Division__c,
            ECSS_Contract__r.ECSS_Division__c,
            ECSS_SalesOffice__c,
            ECSS_Contract__r.ECSS_SalesOffice__c,
            ECSS_NotificationType__c,
            ECSS_Contract__r.ECSS_NotificationType__c,
            ECSS_ContractItemSAPId__c,
            ECSS_Contract__r.ECSS_External_Id__c,
            ECSS_Contract__r.SAPSalesOrganizationId__c,
            Asset.ECSS_SalesOrganization__r.Name,
            Asset.ECSS_NotificationType__c,
            Asset.ECSS_SalesOrganization__r.SAPExternalId__c,
            Asset.ECSS_SalesOrganization__r.ECSS_DistributionChannel__c,
            Asset.ECSS_SalesOrganization__r.ECSS_Division__c,
            Asset.ECSS_SalesOrganization__c,
            ECSS_Contract__r.ECSS_SalesOrganization__r.ECSS_InActiveNotificationType__c,
            ECSS_Contract__r.ECSS_SalesOrganization__r.ECSS_ActiveNotificationType__c,
            ECSS_Contract__r.ECSS_Active__c,
            ECSS_Contract_Details_Id__r.ECSS_SAPLineExternalId__c,
            ECSS_ContractExternalId__c,MobileNumber__c,contact.MobilePhone,
            Asset.Name,
            ECSS_Unit_Name__c,ECSS_Contract__r.Account.SAPAccountId__c,
            origin
            FROM Case
            WHERE Id IN :caseIds
        ];
        //get all the organizations that have a default type and create a map with the default type, salesorganization
        List<Sales_organization__c> salesOrgList = [
            SELECT Id, ECSS_DefaultNotificationTypes__c, SAPExternalId__c
            FROM Sales_Organization__c
            WHERE
            ECSS_DefaultNotificationTypes__c != ''
            AND ECSS_DefaultNotificationTypes__c != NULL
        ];
        for (Sales_organization__c currOrg : salesOrgList) {
            List<String> defVals = currOrg.ECSS_DefaultNotificationTypes__c.split(',');
            for (String defVal : defVals) {
                defSalesOrgMap.put(defval, currOrg);
            }
        }        
        for (Case currCase : casesToUpdate) {
            currCase.ECSS_UnitSAPExternalId__c = currCase.Asset.ExternalIdentifier;
            System.debug('currCase.ECSS_UnitSAPExternalId__c:' + currCase.Asset.ECSS_SalesOrganization__r.Name);
            currCase.ECSS_Unit_Name__c = currCase.Asset.Name;
            currCase.MobileNumber__c = currCase.contact.MobilePhone;
            currCase.Owner_Name__c = currCase.Owner.Name;
            if (currCase.ECSS_Contract__c != null) {
                currCase.ECSS_Contract_Account_SAP__c = currCase.ECSS_Contract__r.Account.SAPAccountId__c;
                currCase.ECSS_DistributionChannel__c = currCase.ECSS_Contract__r.ECSS_DistributionChannel__c;
                currCase.ECSS_Division__c = currCase.ECSS_Contract__r.ECSS_Division__c;
                currCase.ECSS_SalesOffice__c = currCase.ECSS_Contract__r.ECSS_SalesOffice__c;
                if (currCase.ECSS_Contract__r.ECSS_Active__c) {
                    currCase.ECSS_NotificationType__c = currCase.ECSS_Contract__r.ECSS_SalesOrganization__r.ECSS_ActiveNotificationType__c;
                } else {
                    currCase.ECSS_NotificationType__c = currCase.ECSS_Contract__r.ECSS_SalesOrganization__r.ECSS_InActiveNotificationType__c;
                }
                if (defSalesOrgMap.get(currCase.ECSS_NotificationType__c) != null) {
                    currCase.ECSS_SAPSalesOrganization__c = defSalesOrgMap.get(currCase.ECSS_NotificationType__c).SAPExternalId__c;
                } else {
                    if (currCase.ECSS_Contract__c != null) {
                        currCase.ECSS_SAPSalesOrganization__c = currCase.ECSS_Contract__r.SAPSalesOrganizationId__c;
                    }
                }
                currCase.ECSS_ContractExternalId__c = currCase.ECSS_Contract__r.ECSS_External_Id__c;
                currCase.ECSS_ContractItemSAPId__c = currCase.ECSS_Contract_Details_Id__r.ECSS_SAPLineExternalId__c;
            } else {
                if (currCase.Asset.ECSS_SalesOrganization__c != null) {
                    System.debug('in the else:' + currCase.Asset.ECSS_SalesOrganization__r.ECSS_DistributionChannel__c);
                    currCase.ECSS_DistributionChannel__c = currCase.Asset.ECSS_SalesOrganization__r.ECSS_DistributionChannel__c;
                    currCase.ECSS_Division__c = currCase.Asset.ECSS_SalesOrganization__r.ECSS_Division__c;
                    System.debug('Sales Orf:'+currCase.Asset.ECSS_SalesOrganization__r.ECSS_DistributionChannel__c);
                    System.debug('ECSS_Division__c:'+currCase.Asset.ECSS_SalesOrganization__r.ECSS_Division__c);
                }
                currCase.ECSS_NotificationType__c = currCase.Asset.ECSS_NotificationType__c;
                currCase.ECSS_SalesOffice__c = 'COMN';
                System.debug('defSalesOrgMap:' + defSalesOrgMap);
                System.debug('defSalesOrgMap:' + defSalesOrgMap.get(currCase.ECSS_NotificationType__c));
                if (defSalesOrgMap.get(currCase.ECSS_NotificationType__c) != null) {
                    System.debug('in the default value condition: ');
                    currCase.ECSS_SAPSalesOrganization__c = defSalesOrgMap.get(currCase.ECSS_NotificationType__c).SAPExternalId__c;
                } else {
                    if (currCase.Asset.ECSS_SalesOrganization__c != null) {
                        currCase.ECSS_SAPSalesOrganization__c = currCase.Asset.ECSS_SalesOrganization__r.SAPExternalId__c;
                    }
                }
            }
        }
        System.debug('CaseToUpdate:' + casesToUpdate);
        update casesToUpdate;
    }
    
    public static void createRelatedAcc(List<Case> newList) {
        //Local Variable Declaration - Start
        List<Account> toInsertAcc = new List<Account>();
        List<Customer_Unit__c> custUnits = new List<Customer_Unit__c>();
        Map<String, Account> caseAccMap = new Map<String, Account>();
        Map<Customer_Unit__c, Account> customerUnitAccMap = new Map<Customer_Unit__c, Account>();
        List<Contact> contIds = new List<Contact>();
        Map<String, Contact> accContactMap = new Map<String, Contact>();  
        Id organizationAccRecId = Utilities.getRecordTypeId('Account',Constants.ORGANISATION_ACCOUNT_RT);
        Id personAccRecId = Utilities.getRecordTypeId('Account',Constants.PERSON_ACCOUNT_RT);
        Id contactRecId = Utilities.getRecordTypeId('Contact', 'Contact'); 
        //Local Variable Declaration - End      
        for (Case currCase : newList) {
            System.debug('currCase.Priority == label.ECSS_EmergencyPriority:' + currCase.Priority == label.ECSS_EmergencyPriority);
            if (currCase.Recordtype_Name__c.contains('Maintenance') && currCase.ECSS_CreateAccount__c && ((currCase.Priority == label.ECSS_EmergencyPriority && currCase.AccountId == null) || (currCase.AccountId == null && currCase.ECSS_isCaseApproved__c && currCase.Priority != label.ECSS_EmergencyPriority))) {
                Account acc = new Account();
                //Person
                if (currCase.ECSS_AccountCreationType__c.contains('Person')) {
                    acc.firstName = currCase.ECSS_AccountFirstName__c;
                    acc.LastName = currCase.ECSS_AccountLastName__c;
                    acc.MiddleName = currCase.ECSS_AccountMiddleName__c;
                    acc.Gender__pc = currCase.ECSS_AccountCreationGender__c;
                    acc.PersonEmail = currCase.ECSS_RequestedEmail__c;
                    acc.NationalIdNumber__pc = currCase.ECSS_RequestedEmiratesId__c;
                    acc.PassportNumber__pc = currCase.ECSS_RequestedPassportNo__c;
                    acc.MobilePhone__pc = currCase.ECSS_RequestedMobileNumber__c;
                    acc.MobileCountryCode__pc = currCase.ECSS_RequestedMobileCountryCode__c;
                    acc.PersonMobilePhone = currCase.ECSS_RequestedMobileCountryCode__c + currCase.ECSS_RequestedMobileNumber__c;
                    acc.MobileNumber__c = currCase.ECSS_RequestedMobileNumber__c;
                    acc.CountryOfResidence__pc = Label.ECSS_DefaultCountry;
                    acc.PersonMailingCity = Label.ECSS_DefaultCity;
                    acc.Nationality__pc = currCase.ECSS_AccountCreationNationality__c;
                    acc.Salutation = currCase.ECSS_AccountCreationSalutation__c;
                    acc.PersonMailingPostalCode = currCase.ECSS_ZipCode__c;
                    acc.CustomerVertical__c = Label.ECSS_DefaultCustVertical;
                    acc.RecordTypeId = personAccRecId;
                }
                //Organization
                else {
                    System.debug('In the organization part');
                    acc.RecordTypeId = organizationAccRecId;
                    acc.Name = currCase.ECSS_RequestedAccountName__c;
                    acc.Email__c = currCase.ECSS_RequestedEmail__c;
                    acc.MobileCountryCode__c = currCase.ECSS_RequestedMobileCountryCode__c;
                    acc.MobileNumber1__c = currCase.ECSS_RequestedMobileNumber__c;
                    acc.MobileNumber__c = currCase.ECSS_RequestedMobileCountryCode__c + currCase.ECSS_RequestedMobileNumber__c;
                    acc.RegistrationNumber__c = currCase.ECSS_RequestedRegistractionNumber__c;
                    acc.CustomerVertical__c = Label.ECSS_DefaultCustVertical;
                    acc.BillingCountry = currCase.ECSS_OrganizationBillingCountry__c;
                }
                //Creating Customer Unit
                if (currCase.ECSS_AccountUnit__c != null) {
                    Customer_Unit__c currUnit = new Customer_Unit__c();
                    currUnit.Unit__c = currCase.ECSS_AccountUnit__c;
                    currUnit.Customer_Type__c = currCase.CustomerType__c;
                    customerUnitAccMap.put(currUnit, acc);
                    custUnits.add(currUnit);
                }                                
                toInsertAcc.add(acc);
                caseAccMap.put(currCase.Id, acc);
            }
        }
        insert toInsertAcc;        
        for (Account acc : toInsertAcc) {
            if (acc.RecordTypeId == organizationAccRecId) {
                // Create Contact and associate with the Account
                Contact con = new Contact();
                con.LastName = acc.Name;
                con.recordtypeId = contactRecId;
                con.Email = acc.Email__c;
                con.MobilePhone = acc.MobileNumber__c;
                con.AccountId = acc.Id;
                contIds.add(con);
                accContactMap.put(acc.Id, con);
            }
        }
        if (contIds.size() > 0) {
            insert contIds;
        }
        
        for (Customer_Unit__c currUnit : custUnits) {
            if (customerUnitAccMap.get(currUnit) != null) {
                currUnit.Account__c = customerUnitAccMap.get(currUnit).Id;
            }
            System.debug('ACCcustomerunitCheck: ' + customerUnitAccMap.get(currUnit));
        }
        insert custUnits;
        List<Id> accountIds = new List<Id>(new Map<Id, Account>(toInsertAcc).keySet());
        List<Account> accList = new List<Account>();
        if(!accountIds.isEmpty()) {
            accList = [
                SELECT Id, PersoncontactId
                FROM Account
                WHERE Id IN :accountIds
            ];
        }
        Map<String, Account> accMap = new Map<String, Account>(accList);
        System.debug('MapPrint:' + caseAccMap);
        for (Case currCase : newList) {
            if (currCase.ECSS_CreateAccount__c && caseAccMap.get(currCase.Id) != null) {
                currCase.AccountId = caseAccMap.get(currCase.Id).Id;
                if (currCase.ECSS_AccountCreationType__c.contains('Organization') && accContactMap.get(currCase.AccountId) != null) {
                    System.debug('contactId:' + accContactMap.get(currCase.AccountId).Id);
                    currCase.ContactId = accContactMap.get(currCase.AccountId)?.Id;
                } else {
                    System.debug('contactId:' + accMap.get(currCase.AccountId).PersonContactId);
                    currCase.ContactId = accMap.get(currCase.AccountId)?.PersonContactId;
                }
            }
        }
    }
    /*
    *********************************************************
    @Method Name    : beforeInsertECSSRT
    @author         : 
    @description    : Method to handle before Insert logic for ECSS case
    @param          : newCaseRecords
    @return         : void
    ********************************************************
    */
    public static void beforeInsertECSSRT(List<Case> newCaseRecords) {
        //Local Variable Declaration - Start
        String ecssMapKey='';
        List<Case> ecssCases = new List<Case>();
        Set<Id> assetIds = new Set<Id>();
        Map<Id,String> caseCatSubCatMap = new Map<Id,String>();             
        //Local Variable Declaration - End
        for(Case caseRecord : newCaseRecords){  
            if(caseRecord.RecordTypeId == rtWrapper.ecssQueriesRTypeID || caseRecord.RecordTypeId == rtWrapper.ecssComplaintsRTypeID || caseRecord.RecordTypeId == rtWrapper.ecssMaintenanceRTypeID){ 
                ecssCases.add(caseRecord);   
                if(caseRecord.SubVertical__c == Constants.PROVIS && caseRecord.ECSS_CompanyOptions__c == Constants.PROVIS && (caseRecord.CaseCategory__c == Constants.PET_REGISTRATION || caseRecord.CaseCategory__c == Constants.ACCESS_CARD || caseRecord.CaseCategory__c == Constants.BOOKING ||caseRecord.CaseCategory__c == Constants.COMMUNITY_MANAGEMENT ||caseRecord.CaseCategory__c == Constants.COMMON_AREA_MAINTENANCE || caseRecord.CaseCategory__c ==Constants.NOC_FOR_UNIT_MODIFICATIONS|| caseRecord.CaseCategory__c ==Constants.OUT_OF_HOME|| caseRecord.CaseCategory__c ==Constants.COMMUNITY_MANAGEMENT_OA)){
                   assetIds.add(caseRecord.AssetId);
                } 
                //Tenant Onboarding
                if(caseRecord.RecordTypeId == rtWrapper.ecssQueriesRTypeID && caseRecord.CaseCategory__c =='Tenant Onboarding' && caseRecord.Status == Constants.CASE_IN_PROGRESS){
                   assetIds.add(caseRecord.AssetId);
                }
                if(caseRecord.RecordTypeId == rtWrapper.ecssMaintenanceRTypeID) {
                    ecssMapKey = caseRecord.SubVertical__c+'|'+caseRecord.CaseCategory__c+'|'+caseRecord.ECSS_Sub_Category_Text__c;
                    if(queueWrapper.caseHandlingQueue != null) {
                        caseRecord.ownerId = queueWrapper.caseHandlingQueue.Id;
                    }
                } else {
                    ecssMapKey = caseRecord.SubVertical__c+'|'+caseRecord.CaseCategory__c+'|'+caseRecord.ECSS_Object_Category__c+'|'+caseRecord.ECSS_Sub_Category_Text__c;
                }
                caseCatSubCatMap.put(caseRecord.Id,ecssMapKey);
                if(caseRecord.ECSS_Created_From_Component__c && (caseRecord.RecordTypeId == rtWrapper.ecssQueriesRTypeID || caseRecord.RecordTypeId == rtWrapper.ecssComplaintsRTypeID)) {
                    assetIds.add(caseRecord.AssetId);
                }                               
                //livin changes
                if(caseRecord.SubVertical__c == Constants.PROVIS && 
                   caseRecord.ECSS_CompanyOptions__c == Constants.PROVIS && 
                   (caseRecord.CaseCategory__c == Constants.COMMUNITY_MANAGEMENT_OA ||
                    caseRecord.CaseCategory__c == Constants.BOOKING ||
                    caseRecord.CaseCategory__c == Constants.PET_REGISTRATION ||
                    caseRecord.CaseCategory__c == Constants.ACCESS_CARD ||
                    caseRecord.CaseCategory__c == Constants.COMMUNITY_MANAGEMENT ||
                    caseRecord.CaseCategory__c == Constants.COMMON_AREA_MAINTENANCE || 
                    caseRecord.CaseCategory__c == Constants.NOC_FOR_UNIT_MODIFICATIONS|| 
                    caseRecord.CaseCategory__c == Constants.OUT_OF_HOME)){
                    assetIds.add(caseRecord.AssetId);
                }                
            }
        }         
        if(!assetIds.isEmpty()) {
            populateCaseTypeUnitAndSalesOrder(newCaseRecords,assetIds);
        }
        if(!caseCatSubCatMap.isEmpty()) {
            populateECSSData(caseCatSubCatMap,newCaseRecords);
        }
        if(!assetIds.isEmpty()) {
            populateOwnerIdfromProjectMetadata(assetIds,newCaseRecords);
        }
        if(!ecssCases.isEmpty()){
            createRelatedAcc(ecssCases);
        }
    }    
    /*
    *********************************************************
    @Method Name    : beforeUpdateECSSCase
    @author         : 
    @description    : Method to handle before update logic for ECSS case
    @param          : newCaseList,oldMap
    @return         : void
    ********************************************************
    */ 
    public static void beforeUpdateECSSCase(List<Case> newCaseList, Map<Id, Case> oldMap) {
        String ecssMapKey='';
        Set<Id> assetIds = new Set<Id>();
        Set<Id> assetIdsToUpdateUnit = new Set<Id>();//Tenant Onboarding
        Map<Id,Id> assetIdMappedToUnit = new Map<Id,Id>();//Tenant Onboarding
        Map<Id,Id> unitIdMappedToSalesOrder = new Map<Id,Id>();//Tenant Onboarding
        List<case> tasksToInsert = new List<case>();
        //List<Case> lstCasesToCreateContract = new List<Case>();
        Set<Id> caseIdSetToCreateContract  = new Set<Id>();
        Map<Id,String> caseCatSubCatMap = new Map<Id,String>();
        
        for(Case caseRecord : newCaseList) {
            Case oldCase = oldMap.get(caseRecord.Id);
            String recordTypeName = Utilities.getRecordTypeName('Case', caseRecord.recordTypeId);
            if(caseRecord.RecordTypeId == rtWrapper.ecssQueriesRTypeID || caseRecord.RecordTypeId == rtWrapper.ecssComplaintsRTypeID || caseRecord.RecordTypeId == rtWrapper.ecssMaintenanceRTypeID){ 
                //Tenant Onboarding
                if(caseRecord.RecordTypeId == rtWrapper.ecssQueriesRTypeID && caseRecord.CaseCategory__c == Constants.TENANT_ONBOARDING && (caseRecord.Status == Constants.CLOSED_CASE || caseRecord.Status == Constants.COMPLETED) && caseRecord.Status != oldCase.Status){
                   //lstCasesToCreateContract.add(caseRecord);
                   caseIdSetToCreateContract.add(caseRecord.Id);
                }
            }
            if(caseRecord.RecordTypeId == rtWrapper.ecssQueriesRTypeID || caseRecord.RecordTypeId == rtWrapper.ecssComplaintsRTypeID || caseRecord.RecordTypeId == rtWrapper.ecssMaintenanceRTypeID){
                //Case revamp : To populate new fields when subvertical,Case category,Sub category or record type changes.
                if(caseRecord.SubVertical__c != oldCase.SubVertical__c || caseRecord.CaseCategory__c != oldCase.CaseCategory__c || caseRecord.ECSS_Sub_Category_Text__c != oldCase.ECSS_Sub_Category_Text__c || caseRecord.RecordTypeId != oldCase.RecordTypeId ){                    
                    if(caseRecord.RecordTypeId == rtWrapper.ecssMaintenanceRTypeID) {
                        ecssMapKey = caseRecord.SubVertical__c+'|'+caseRecord.CaseCategory__c+'|'+caseRecord.ECSS_Sub_Category_Text__c;
                    } else {
                        ecssMapKey = caseRecord.SubVertical__c+'|'+caseRecord.CaseCategory__c+'|'+caseRecord.ECSS_Object_Category__c+'|'+caseRecord.ECSS_Sub_Category_Text__c;                                            
                    }    
                    caseCatSubCatMap.put(caseRecord.Id,ecssMapKey);              
                }
                //if any of the below fields change, reset SLA/entitlement and milestones
                if(caseRecord.AssetId != oldCase.AssetId || caseRecord.SubVertical__c != oldCase.SubVertical__c || caseRecord.CaseCategory__c != oldCase.CaseCategory__c || caseRecord.ECSS_Sub_Category_Text__c != oldCase.ECSS_Sub_Category_Text__c || caseRecord.ECSS_Object_Category__c != oldCase.ECSS_Object_Category__c){                    
                    if(caseRecord.ECSS_Created_From_Component__c && (caseRecord.RecordTypeId == rtWrapper.ecssQueriesRTypeID || caseRecord.RecordTypeId == rtWrapper.ecssComplaintsRTypeID)) {   
                        assetIds.add(caseRecord.AssetId);
                    }
                    
                    //Tenant Onboarding
                    if(caseRecord.RecordTypeId ==  rtWrapper.ecssQueriesRTypeID && caseRecord.CaseCategory__c == Constants.TENANT_ONBOARDING){
                        assetIdsToUpdateUnit.add(caseRecord.AssetId);
                    }
                }
                if(System.Label.GeneralCaseType.split(';').contains(caseRecord.Type) && caseRecord.Status == 'Resolved' && oldCase.Status == caseRecord.Status && oldCase.Assigned_To__c == null && caseRecord.Assigned_To__c != null && caseRecord.Sub_Status__c != 'Call Attempt 1' && (caserecord.RecordTypeId == rtWrapper.ecssQueriesRTypeID || caseRecord.RecordTypeId == rtWrapper.ecssComplaintsRTypeID)){
                    tasksToInsert.add(caseRecord);
                    caseRecord.Sub_Status__c = 'Call Attempt 1';
                }
            }
        }
        if(!caseIdSetToCreateContract.isEmpty()) {
            TenantCreateAccountWebService.createTenantContract(caseIdSetToCreateContract);
        }
        if(!caseCatSubCatMap.isEmpty()) {
            populateECSSData(caseCatSubCatMap,newCaseList);
        }
        if(!assetIds.isEmpty()) { 
            populateOwnerIdfromProjectMetadata(assetIds,newCaseList);
        }
        if(!tasksToInsert.isEmpty()){
            CaseTriggerHelper.createResolvertask(tasksToInsert);
        }
        
        //Tenant Onboarding
        if(!assetIdsToUpdateUnit.isEmpty()){
            
            List<Asset> assetList = [Select Id, Unit__c from Asset where Id IN :assetIdsToUpdateUnit];
            
            For(Asset currentAsset : assetList){
                if(currentAsset.Unit__c != null)
                    assetIdMappedToUnit.put(currentAsset.Id,currentAsset.Unit__c);
            }
        }
        
        if(assetIdMappedToUnit.values().Size()>0){
            List<SalesOrder__c> salesorderList = [Select Id,Unit__c from SalesOrder__c where Status__c  NOT IN ('Cancelled','Cancelled By User') And Unit__c IN :assetIdMappedToUnit.values()];
            
            For(SalesOrder__c salesOrder : salesorderList){
                if(salesOrder.Unit__c != null)
                    unitIdMappedToSalesOrder.put(salesOrder.Unit__c,salesOrder.Id);
            }
        }
        
        for(Case caseRecord : newCaseList){
            Case oldCase = (Case)oldmap.get(caseRecord.Id);//Tenant Onboarding
            
            //Tenant Onboarding
            if(caseRecord.AssetId != oldCase.AssetId && caseRecord.RecordTypeId == rtWrapper.ecssQueriesRTypeID && caseRecord.CaseCategory__c == Constants.TENANT_ONBOARDING){
                if(assetIdMappedToUnit.get(caseRecord.assetId) !=  null){
                    If(caseRecord.CustomerType__c != Constants.CASE_CUSTOMER_TENANT || (caseRecord.CustomerType__c == Constants.CASE_CUSTOMER_TENANT && caseRecord.CaseCategory__c == Constants.TENANT_ONBOARDING )){
                        caseRecord.Unit__c = assetIdMappedToUnit.get(caseRecord.assetId);
                        caseRecord.SalesOrder__c = unitIdMappedToSalesOrder.get(assetIdMappedToUnit.get(caseRecord.assetId));
                    }
                }
            }
        }
    }
    /*
    *********************************************************
    @Method Name    : afterInsertECSSRT
    @author         : 
    @description    : Method to handle after Insert logic for ECSS case
    @param          : newCaseRecords
    @return         : void
    ********************************************************
    */ 
    public static void afterInsertECSSRT(List<Case> newCaseRecords) {
        List<Case> ecssCases = new List<Case>();
        for(Case caseRecord : newCaseRecords){  
            if(caseRecord.RecordTypeId == rtWrapper.ecssQueriesRTypeID || caseRecord.RecordTypeId == rtWrapper.ecssComplaintsRTypeID || caseRecord.RecordTypeId == rtWrapper.ecssMaintenanceRTypeID){ 
                ecssCases.add(caseRecord);
            }
        }
        if(!ecssCases.isEmpty()) {
           updateSAPValues(ecssCases); 
        }
    }
    /*
    *********************************************************
    @Method Name    : afterUpdateECSSRT
    @author         : 
    @description    : Method to handle after update logic for ECSS case
    @param          : newCaseRecords,
    @return         : void
    ********************************************************
    */ 
    public static void afterUpdateECSSRT(List<Case> newCaseRecords, Map<Id, Case> oldMap) {
        /*Set<Id> caseIdToCreateContract = new Set<Id>();
        for(Case caseRecord : newCaseRecords){  
            Case oldCase = (Case)oldMap.get(caseRecord.Id);
            String recordTypeName = Utilities.getRecordTypeName('Case', caseRecord.recordTypeId);
            if(caseRecord.RecordTypeId == rtWrapper.ecssQueriesRTypeID || caseRecord.RecordTypeId == rtWrapper.ecssComplaintsRTypeID || caseRecord.RecordTypeId == rtWrapper.ecssMaintenanceRTypeID){ 
                //Tenant Onboarding
                if(caseRecord.RecordTypeId == rtWrapper.ecssQueriesRTypeID && caseRecord.CaseCategory__c == Constants.TENANT_ONBOARDING && (caseRecord.Status == Constants.CLOSED_CASE || caseRecord.Status == Constants.COMPLETED) && caseRecord.Status != oldCase.Status){
                   caseIdToCreateContract.add(caseRecord.Id);
                }
            }
        }
        // Tenant onboarding
        if(!caseIdToCreateContract.isEmpty()){
            TenantCreateAccountWebService.createTenantContract(caseIdToCreateContract);  
        }*/
    }    
    /* Added by Cloudzlab New method to get populate from Case Field Dependency Revised Metadata for ECSS Case records*/
    public static void populateECSSData(Map<Id, String> caseCatSubCatMap, List<SObject> newList){
        
        List<Case_Field_Dependency_Revised__mdt> caseFieldDependencyList = new List<Case_Field_Dependency_Revised__mdt>([SELECT ECSS_Is_ECSS__c,
                                                                                                                         Category__c, 
                                                                                                                         Sub_Vertical__c,
                                                                                                                         Damage_Code__c,
                                                                                                                         ECSS_ObjectCategory__c,
                                                                                                                         Category_Code__c,
                                                                                                                         Case_Owner_Queue__c,Case_Owner_User__c,
                                                                                                                         Organization__c, Department__c,
                                                                                                                         Vertical__c, Priority__c,
                                                                                                                         ECSS_Sub_Category__r.MasterLabel,Survey_Type__c 
                                                                                                                         FROM Case_Field_Dependency_Revised__mdt
                                                                                                                         WHERE ECSS_Is_ECSS__c = true]);
        Map<String,Case_Field_Dependency_Revised__mdt> caseFieldDependencyMap = new Map<String, Case_Field_Dependency_Revised__mdt>();
        String mapKey ='';
        for(Case_Field_Dependency_Revised__mdt caseDependency : caseFieldDependencyList) {   
            if(caseDependency.ECSS_ObjectCategory__c!='' && caseDependency.ECSS_ObjectCategory__c!=null)
                mapKey = caseDependency.Sub_Vertical__c+'|'+caseDependency.Category__c+'|'+caseDependency.ECSS_ObjectCategory__c+'|'+caseDependency.ECSS_Sub_Category__r.MasterLabel;
            else
                mapKey = caseDependency.Sub_Vertical__c+'|'+caseDependency.Category__c+'|'+caseDependency.ECSS_Sub_Category__r.MasterLabel;
                caseFieldDependencyMap.put(mapKey,caseDependency);            
        }
        for(Case caseRecord : (List<Case>)newList) {            
            if(caseCatSubCatMap.containsKey(caseRecord.Id)) {                
                if(caseFieldDependencyMap.containsKey(caseCatSubCatMap.get(caseRecord.Id))){   
                    Case_Field_Dependency_Revised__mdt caseFieldDependency = caseFieldDependencyMap.get(caseCatSubCatMap.get(caseRecord.Id));
                    caseRecord.ECSS_DamageCode__c = caseFieldDependency.Damage_Code__c;
                    caseRecord.ECSS_CaseCategoryCode__c = caseFieldDependency.Category_Code__c;
                    caseRecord.Organization__c = caseFieldDependency.Organization__c;
                    caseRecord.Department__c = caseFieldDependency.Department__c;
                    caseRecord.Vertical__c = caseFieldDependency.Vertical__c;                    
                    caseRecord.Priority = caseFieldDependency.Priority__c;
                    if(caseRecord.Priority != null && caseRecord.Priority != label.ECSS_EmergencyPriority && caseRecord.ECSS_Account_Contract_Request__c ){
                        caseRecord.ECSS_isCaseApproved__c = false;
                    }                    
                }
                else if(caseRecord.ECSS_Account_Contract_Request__c ){
                    caseRecord.ECSS_isCaseApproved__c = false;
                }                
            }
            else if(caseRecord.ECSS_Account_Contract_Request__c ){
                caseRecord.ECSS_isCaseApproved__c = false;
            }
        }        
    }
    /*
    *********************************************************
    @Method Name    : populateOwnerIdfromProjectMetadata
    @author         : 
    @description    : Added by Cloudzlab to assign ECSS case based on project metadata
    @param          : assetIds,newList
    @return         : void
    ********************************************************
    */    
    public static void populateOwnerIdfromProjectMetadata(Set<Id> assetIds,List<sObject> newList) {
        ECSS_CaseAssiggnmentSLAFromMtd.getProjectMetadata('Owner',assetIds,newList); 
    }
    /*
    *********************************************************
    @Method Name    : populateCaseTypeUnitAndSalesOrder
    @author         : 
    @description    : Added by Cloudzlab to populate Case Type, Unit and Sales Order for Provis cases
    @param          : newList,assetIds
    @return         : void
    ********************************************************
    */ 
    public static void populateCaseTypeUnitAndSalesOrder(List<Case> newList,Set<Id> assetIds) {
        Map<Id,Id> assetIdMappedToUnit = new Map<Id,Id>();  
        Map<Id,Id> unitIdMappedToSalesOrder = new Map<Id,Id>();
        Map<Id,Unit_Contract__c> assetIdHavingActiveContract = new Map<Id,Unit_Contract__c>(); //Tenant Contract
        
        if(!assetIds.isEmpty()){                                            
            for(Asset currentAsset : [Select Id, Unit__c from Asset where Id IN :assetIds]){
                if(currentAsset.Unit__c != null) {
                    assetIdMappedToUnit.put(currentAsset.Id,currentAsset.Unit__c);
                }
            }
            
            //Tenant Contract
            For(Unit_Contract__c currentContactDetails : [Select Id,Contract__c,ECSS_Unit__c from Unit_Contract__c where Contract__r.ECSS_ContractOrganizationType__c =: Constants.TENANCY and Contract__r.EndDate > TODAY and ECSS_Unit__c In :assetIds]){
                assetIdHavingActiveContract.put(currentContactDetails.ECSS_Unit__c,currentContactDetails);
            }
        }                
        if(assetIdMappedToUnit.values().Size()>0){                               
            for(SalesOrder__c salesOrder : [Select Id,Unit__c from SalesOrder__c where Status__c  NOT IN ('Cancelled','Cancelled By User') And Unit__c IN :assetIdMappedToUnit.values()]){
                if(salesOrder.Unit__c != null) {
                    unitIdMappedToSalesOrder.put(salesOrder.Unit__c,salesOrder.Id);
                }
            }
        }
        for(Case caseRecord : newList) {            
            if(caseRecord.RecordTypeId == rtWrapper.ecssQueriesRTypeID || caseRecord.RecordTypeId == rtWrapper.ecssComplaintsRTypeID){
                if(caseRecord.SubVertical__c == Constants.PROVIS && caseRecord.ECSS_CompanyOptions__c == Constants.PROVIS && (caseRecord.CaseCategory__c == Constants.PET_REGISTRATION || caseRecord.CaseCategory__c == Constants.ACCESS_CARD || caseRecord.CaseCategory__c == Constants.BOOKING || caseRecord.CaseCategory__c == Constants.COMMUNITY_MANAGEMENT || caseRecord.CaseCategory__c == Constants.COMMON_AREA_MAINTENANCE || caseRecord.CaseCategory__c == Constants.NOC_FOR_UNIT_MODIFICATIONS || caseRecord.CaseCategory__c == Constants.OUT_OF_HOME || caseRecord.CaseCategory__c == Constants.COMMUNITY_MANAGEMENT_OA || caseRecord.CaseCategory__c == Constants.TENANT_ONBOARDING)){                        
                    if(assetIdMappedToUnit.get(caseRecord.assetId) !=  null){
                        //If(caseRecord.CustomerType__c != Constants.CASE_CUSTOMER_TENANT || (caseRecord.CustomerType__c == Constants.CASE_CUSTOMER_TENANT && caseRecord.CaseCategory__c == Constants.TENANT_ONBOARDING )){
                            caseRecord.Unit__c = assetIdMappedToUnit.get(caseRecord.assetId);
                            caseRecord.SalesOrder__c = unitIdMappedToSalesOrder.get(assetIdMappedToUnit.get(caseRecord.assetId));
                        //}
                    }                        
                    if(caseRecord.CaseCategory__c == Constants.COMMUNITY_MANAGEMENT_OA){
                        caseRecord.Type = Constants.OTHER_REQUEST;
                    }
                    else if(caseRecord.CaseCategory__c == Constants.COMMUNITY_MANAGEMENT){
                        caseRecord.Type = Constants.Complaints;
                    }
                    else{
                        caseRecord.Type = caseRecord.CaseCategory__c;
                    }
                }
                
                 //Tenant Contract
                if(caseRecord.SubVertical__c == Constants.PROVIS && caseRecord.ECSS_CompanyOptions__c == Constants.PROVIS && (caseRecord.CaseCategory__c == Constants.PET_REGISTRATION || caseRecord.CaseCategory__c == Constants.ACCESS_CARD || caseRecord.CaseCategory__c == Constants.BOOKING || caseRecord.CaseCategory__c == Constants.COMMUNITY_MANAGEMENT || caseRecord.CaseCategory__c == Constants.COMMON_AREA_MAINTENANCE || caseRecord.CaseCategory__c == Constants.NOC_FOR_UNIT_MODIFICATIONS || caseRecord.CaseCategory__c == Constants.OUT_OF_HOME || caseRecord.CaseCategory__c == Constants.COMMUNITY_MANAGEMENT_OA) && caseRecord.CustomerType__c == 'Tenant'){
                	caseRecord.ECSS_Contract__c = assetIdHavingActiveContract.get(caseRecord.assetId)?.Contract__c;
                }
            }            
        }        
    }
}