public class ECSS_CaseCreationController {
    
    @AuraEnabled(cacheable=true)
    public static List<String> getCountryValues() {
        List<String> countryCodes = new List<String>();
        Schema.DescribeFieldResult fieldResult = User.Countrycode.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        System.debug('Picklist::' + ple);
        for (Schema.PicklistEntry f : ple) {
            countryCodes.add(f.getLabel());
        }
        return countryCodes;
    }
    @AuraEnabled(cacheable=true)
    public static accountWrapper getRelatedAccount(String assetId) {
        accountWrapper acWr = new accountWrapper();
        Account acc = new Account();
        System.debug('AssetId:' + assetId);
        List<Customer_Unit__c> custUnits =  [
            SELECT Id, Account__c, Unit__c,Unit__r.ParentId,Account__r.IsPersonAccount,active__c
            FROM Customer_Unit__c
            WHERE Unit__c = :assetId  and active__c=true ORDER BY CreatedDate ASC/*limit 1*/ ];
        Customer_Unit__c custUnit = new Customer_Unit__c();
        if(custUnits.size()>0){
            if(custUnits.size()==1)
                custUnit  = custUnits[0];
            else if(custUnits.size()>1)
            {for(Customer_Unit__c cu : custUnits){ custUnit = cu;break;
                }
            }
        }
        System.debug('after the query');
        Asset assRec = [SELECT Id,ParentId FROM Asset WHERE Id =: assetId];
        System.debug('Parent:'+assRec.ParentId);
        if(custUnits.size()==0 && assRec.ParentId != null ){
            System.debug('in the custUnit:');
            custUnits = [
                SELECT Id, Account__c, Unit__c,Unit__r.ParentId,Account__r.IsPersonAccount
                FROM Customer_Unit__c
                WHERE Unit__c =:assRec.ParentId /*limit 1*/ 
            ];
            if(custUnits.size()>0){if(custUnits.size()==1)custUnit  = custUnits[0];
                else if(custUnits.size()>1)
                {for(Customer_Unit__c cu : custUnits) {if(cu.Account__r.IsPersonAccount){custUnit = cu;break;
                        }
                        
                    }
                }
            }
            
            
            System.debug('Found the custUnit value:'+custUnit);
        }
        if (custUnit.Account__c != null && assetId != '' && assetId!=null) {
            acc = [
                SELECT Id, Name
                FROM Account
                WHERE Id = :custUnit.Account__c
            ];
            System.debug('in the acc condition');
            
            acWr.accountId = acc.Id;
            acWr.accountRec = acc;
            return acWr;
        }
        Asset asRec = [SELECT Id,Parent.Unit__c,Unit__c FROM Asset WHERE Id=:assetId];
        String unitId = '';if(asRec.Unit__c != null){unitId = asRec.Unit__c;
        }
        else{unitId = asRec.Parent.Unit__c;
        }
        System.debug('UnitId:'+unitId);
        if(unitId != ''){
        List<SalesOrder__c> salesOrderList = [Select id, Account__c,Unit__c,Account__r.name from SalesOrder__c  where unit__c =: unitId and status__c  = 'sold'];
            if(salesOrderList.size()>0){acc = [Select Id,Name from Account where Id =: salesOrderList[0].Account__c ];acWr.accountId = salesOrderList[0].Account__c;acWr.accountRec = acc; return acWr;
                
            }
        } System.debug('Output acc' + acc);
        return null;
    }
    @AuraEnabled(cacheable=true)
    public static List<String> getSalutationValues() {
        List<String> salutationValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = Schema.SObjectType.Account.fields.Salutation;
        System.debug('salutatoins:' + fieldResult);
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            salutationValues.add(entry.getLabel());
        }
        return salutationValues;
    }
    @AuraEnabled(cacheable=true)
    public static List<String> getNationalityValues() {
        List<String> nationalityValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = Schema.SObjectType.Account.fields.Nationality__pc;
        System.debug('nationalities:' + fieldResult);
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            nationalityValues.add(entry.getLabel());
        }
        return nationalityValues;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccRecord(Contract contractVal) {
        System.debug('in the getAccMethod: ' + contractVal);
        List<Account> acc = new List<Account>();
        if (contractVal != null) {
            acc = [
                SELECT Id, Name
                FROM Account
                WHERE Id = :contractVal.accountId
                LIMIT 1
            ];
        }
        return acc;
    }
    @AuraEnabled(cacheable=true)
    public static List<PickValsWrapper> ecssCaseRecordTypes() {
        List<PickValsWrapper> outpList = new List<PickValsWrapper>();
        String ecssRecLabel = '%';
        ecssRecLabel += Label.ECSS_Label;
        ecssRecLabel += '%';
        List<RecordType> recTyps = [
            SELECT id, name, isActive
            FROM recordtype
            WHERE SobjectType = 'case' AND name LIKE :ecssRecLabel AND isActive = TRUE
        ];
        for (RecordType currTyp : recTyps) {
            PickValsWrapper pckVal = new PickValsWrapper(currTyp.name, currTyp.Id);
            outpList.add(pckVal);
        }
        System.debug('outpList:' + outpList);
        return outpList;
    }
    @AuraEnabled(cacheable=true)
    public static List<PickValsWrapper> ecssAccountRecordTypes() {
        List<PickValsWrapper> outpList = new List<PickValsWrapper>();
        String ecssRecLabel = '%';
        ecssRecLabel += Label.ECSS_Label;
        ecssRecLabel += '%';
        List<RecordType> recTyps = [
            SELECT id, name
            FROM recordtype
            WHERE
            SobjectType = 'account'
            AND (name LIKE '%Person%'
                 OR name LIKE '%Organization%')
        ];
        for (RecordType currTyp : recTyps) {
            PickValsWrapper pckVal = new PickValsWrapper(currTyp.name, currTyp.Id);
            outpList.add(pckVal);
        }
        System.debug('outpList:' + outpList);
        return outpList;
    }
    
    @AuraEnabled(cacheable=true)
    public static CompanysWrapper companyLinked(
        String selectedCategory,
        String selectedSubCategory
    ) {
        CompanysWrapper newCompWr;
        String ECSSComRTName = Label.ECSS_CompanyRecordType;
        
        List<Case_Field_Dependency_Revised__mdt> dependcyList = [
            SELECT Id, Category__c, Organization__c, Sub_Category__c
            FROM Case_Field_Dependency_Revised__mdt
            WHERE
            Category__c = :selectedCategory
            AND Sub_Category__c = :selectedSubCategory
        ];
        Id ECSS_recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get(ECSSComRTName)
            .getRecordTypeId();
        
        if (dependcyList.size() > 0) {
            Account ECSS_Organizations = [
                SELECT Id, Name, RecordTypeId
                FROM Account
                WHERE
                RecordTypeId = :ECSS_recordTypeId
                AND Name = :dependcyList[0].Organization__c
            ];
            newCompWr = new CompanysWrapper(
                ECSS_Organizations.Name,
                ECSS_Organizations.Id
            );
            System.debug('Ooutpout: ' + newCompWr);
        }
        return newCompWr;
    }
    @AuraEnabled(cacheable=true)
    public static Contact contactDuplicateRetrieval(
        String mobilePhone,
        String firstName,
        String lastName,
        Boolean isPerson,
        String accountId,
        String email
    ) {
        String query = 'SELECT Id, Name, FirstName, LastName, MobilePhone__c, Email';
        if (!isPerson) {
            query += ', AccountId';
        }
        query += ' FROM Contact WHERE ';
        
        List<String> conditions = new List<String>();
        
        
        if (lastName != null && lastName != '' && mobilePhone != null && mobilePhone != '') {
            conditions.add('LastName = :lastName');
            conditions.add('MobilePhone__c = :mobilePhone');
            if(email != '' && email != null)
                conditions.add('Email = :email');
            
            if (!isPerson && accountId != null && accountId != '') {
                conditions.add('AccountId = :accountId');
            }
        }
        
        
        if (isPerson) {
            if ((Firstname == null || Firstname == '') &&
                (lastName == null || lastName == '') &&
                (mobilePhone == null || mobilePhone == '')) {
                    return null;
                }
        } else {
            if (conditions.isEmpty()) {
                return null;
            }
        }
        
        query += String.join(conditions, ' AND ');
        System.debug(query);
        List<Contact> matchingContacts = Database.query(query);
        if(matchingContacts.size()>0)
            return matchingContacts[0];
        return null;
    }

    @AuraEnabled(cacheable=true)
    public static boolean contactDuplicateCheck(
        String mobilePhone,
        String Firstname,
        String lastName,
        Boolean isPerson,
        String accountId
    ) {
        List<Contact> NameContact = new List<Contact>();
        List<Contact> PhoneContact = new List<Contact>();
        Boolean duplicateName = false;
        Boolean duplicatePhone = false;
        System.debug('Fistname: ' + Firstname);
        System.debug('lastName: ' + lastName);
        System.debug('mobilePhone:' + mobilePhone);
        if (isPerson) {
            if (FirstName != '' && LastName != '') {
                NameContact = [
                    SELECT Id, FirstName, LastName, MobilePhone__c
                    FROM Contact
                    WHERE FirstName = :Firstname AND LastName = :lastName
                ];
                System.debug('NameContact:' + (NameContact.size() > 0));
                duplicateName = (NameContact.size() > 0);
            }
            if (mobilePhone != '' && mobilePhone != null) {
                PhoneContact = [
                    SELECT Id, FirstName, LastName, MobilePhone__c
                    FROM Contact
                    WHERE MobilePhone__c = :mobilePhone
                ];
                duplicatePhone = (PhoneContact.size() > 0);
            }
            
            //System.debug('In Person:'+ (contList.size()>0));
            return duplicateName || duplicatePhone;
        } else {
            if (
                (FirstName != '' || FirstName != null) &&
                (LastName != '' ||
                 lastname != null)
            ) {
                NameContact = [
                    SELECT Id, FirstName, LastName, MobilePhone__c, AccountId
                    FROM Contact
                    WHERE
                    FirstName = :Firstname
                    AND LastName = :lastName
                    AND AccountId = :accountId
                ];
                duplicateName = (NameContact.size() > 0);
            }
            if (mobilePhone != '') {
                PhoneContact = [
                    SELECT Id, FirstName, LastName, MobilePhone__c
                    FROM Contact
                    WHERE MobilePhone__c = :mobilePhone AND AccountId = :accountId
                ];
                duplicatePhone = (PhoneContact.size() > 0);
            }
            return duplicateName || duplicatePhone;
        }
    }
    @AuraEnabled(cacheable=true)
    public static boolean accDuplicateCheck(
        String email,
        String emiratesNo,
        String passportNo,
        String mobilePhone,
        String accType,
        String registrationNo
    ) {
        if (accType.contains('Person')) {
            List<Account> accEmail = new List<Account>();
            List<Account> accEmiratesNo = new List<Account>();
            List<Account> accPassportNumber = new List<Account>();
            List<Account> accMobileNumber = new List<Account>();
            if (email != '' && email != null)
                accEmail = new List<Account>(
                    [
                        SELECT
                        Id,
                        Email__c,
                        NationalIdNumber__pc,
                        PassportNumber__pc,
                        MobileNumber__c,
                        PersonEmail
                        FROM Account
                        WHERE Email__c = :email OR PersonEmail = :email
                        LIMIT 1
                    ]
                );
            if (emiratesNo != '' && emiratesNo != null)
                accEmiratesNo = new List<Account>(
                    [
                        SELECT
                        Id,
                        Email__c,
                        NationalIdNumber__pc,
                        PassportNumber__pc,
                        MobileNumber__c
                        FROM Account
                        WHERE NationalIdNumber__pc = :emiratesNo
                        LIMIT 1
                    ]
                );
            if (passportNo != '' && passportNo != null)
                accPassportNumber = new List<Account>(
                    [
                        SELECT
                        Id,
                        Email__c,
                        NationalIdNumber__pc,
                        PassportNumber__pc,
                        MobileNumber__c
                        FROM Account
                        WHERE PassportNumber__pc = :passportNo
                        LIMIT 1
                    ]
                );
            if (mobilePhone != '' && mobilePhone != null)
                accMobileNumber = new List<Account>(
                    [
                        SELECT
                        Id,
                        Email__c,
                        NationalIdNumber__pc,
                        PassportNumber__pc,
                        MobileNumber__c
                        FROM Account
                        WHERE MobileNumber__c = :mobilePhone
                        LIMIT 1
                    ]
                );
            
            return (accEmail.size() > 0 || (accMobileNumber.size() > 0)) ||
                (accEmiratesNo.size() > 0) ||
                (accPassportNumber.size() > 0);
            // return (acc.size()>0 );
        } else {
            List<Account> accRegistrationNo = new List<Account>();
            System.debug('RegistrationNo:' + registrationNo);
            if (registrationNo != '' && registrationNo != null)
                accRegistrationNo = new List<Account>(
                    [
                        SELECT Id, Email__c, RegistrationNumber__c, MobileNumber__c
                        FROM Account
                        WHERE RegistrationNumber__c = :registrationNo
                        LIMIT 1
                    ]
                );
            return ((accRegistrationNo.size() > 0));
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static boolean phoneValidaty(String countryCode, String mobileNumber) {
        return (ECSS_PhoneNumberValidity.Validate(mobileNumber, countryCode));
    }
    @AuraEnabled(cacheable=true)
    public static Map<Id, CompanyWrapper> getCompanyFromManagedBy(
        string ecssUnitId
    ) {
        //String ECSSComRTName = Label.ECSS_CompanyRecordType;
        //Id ECSS_recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(ECSSComRTName).getRecordTypeId();
        system.debug('ECSSCOMPANYMANAGED:' + ecssUnitId);
        Map<Id, CompanyWrapper> companyWrapperMap = new Map<Id, CompanyWrapper>();
        List<FM_Companies__c> managedByCompaniesList;
        if (ecssUnitId != '') {
            managedByCompaniesList = new List<FM_Companies__c>(
                [
                    SELECT
                    ECSS_Company__c,
                    ECSS_Company__r.Name,
                    ECSS_Company__r.ECSS_Eltizam_Company__c
                    FROM FM_Companies__c
                    WHERE Unit__c = :ecssUnitId
                ]
            );
        } else {
            managedByCompaniesList = new List<FM_Companies__c>(
                [
                    SELECT
                    ECSS_Company__c,
                    ECSS_Company__r.Name,
                    ECSS_Company__r.ECSS_Eltizam_Company__c
                    FROM FM_Companies__c
                ]
            );
        }
        for (FM_Companies__c fc : managedByCompaniesList) {
            CompanyWrapper cw = new CompanyWrapper();
            cw.companyId = fc.ECSS_Company__c;
            cw.companyName = fc.ECSS_Company__r.Name;
            cw.isEltizamCompany = fc.ECSS_Company__r.ECSS_Eltizam_Company__c;
            companyWrapperMap.put(fc.ECSS_Company__c, cw);
        }
        return companyWrapperMap;
    }
    
    @AuraEnabled(cacheable=true)
    public static ContractWrapper getKhidmahContracts(
        string ecssUnitId,
        string accountId,
        String caseCategory,
        String compName,
        String subVertical
    ) {
        // system.debug('ecssUni'+ecssUnitId+'acc'+accountId);
        List<Contract> activeContractWORem = new List<Contract>();
        List<Contract> activeContractRem = new List<Contract>();
        String ECSSContractUnitRTName = Label.ECSS_Contract_Unit_RT;
        String ECSSContractItemRTName = Label.ECSS_Contract_Item_RT;
        String ECSSKhidmahContractRTName = Label.ECSS_Khidmah_Contract_RT;
        Id ContractUnitrecordTypeId = Schema.SObjectType.Unit_Contract__c.getRecordTypeInfosByName()
            .get(ECSSContractUnitRTName)
            .getRecordTypeId();
        Id ContractItemrecordTypeId = Schema.SObjectType.Unit_Contract__c.getRecordTypeInfosByName()
            .get(ECSSContractItemRTName)
            .getRecordTypeId();
        System.debug('ECSSKhidmahContractRTName:' + ECSSKhidmahContractRTName);
        Id KhidmahContractrecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName()
            .get(ECSSKhidmahContractRTName)
            .getRecordTypeId();
        ContractWrapper cw = new ContractWrapper();
        String catCode = '%' + '%';
        // String type = 'IFM';
        System.debug('compName:' + compName);
        if (compName != null && compName.toLowerCase().contains('khidmah')) {
                if (caseCategory != '') {
                    Case_Field_Dependency_Revised__mdt currMdt = [
                        SELECT id, Category__c, Category_Code__c
                        FROM Case_Field_Dependency_Revised__mdt
                        WHERE
                        ECSS_Is_ECSS__c = TRUE
                        AND Category_Code__c != ''
                        AND Category__c = :caseCategory
                        LIMIT 1
                    ];
                    if (currMdt != null) {
                        catCode = '%' + currMdt.Category_Code__c + '%';
                    }
                }
               
                if (ecssUnitId != '' && accountId != '') {
                    activeContractRem = new List<Contract>(
                        [
                            SELECT
                            Id,
                            ECSS_ContractOrganizationType__c,
                            ContractNumber,
                            AccountId,
                            Account.Name,
                            StartDate,
                            EndDate,
                            ECSS_Package__c,
                            ECSS_Remaining_Call_Outs__c,
                            Callouts_Available__c,
                            ECSS_Material_Spares__c,
                            (
                                SELECT
                                Id,
                                Initial__c,
                                Consumed__c,
                                Remaining__c,
                                Item_Type__c,
                                Category_Code__c,
                                Description__c,
                                Service_Material__c,
                                ECSS_SAPLineExternalId__c
                                FROM Unit_Contracts__r
                                WHERE
                                RecordTypeId = :ContractItemrecordTypeId
                                AND (Category_Code__c LIKE :catCode
                                     OR Category_Code__c = ''
                                     OR Category_Code__c = ';')
                            )
                            FROM Contract
                            WHERE
                            /*AccountId = :accountId
                            AND*/ ECSS_Active__c = TRUE
                            AND (ECSS_ContractOrganizationType__c = 'Khidmah'
                                 OR ECSS_ContractOrganizationType__c = 'IFM')
                            AND Callouts_Available__c = TRUE
                            AND Id IN (
                                SELECT Contract__c
                                FROM Unit_Contract__c
                                WHERE
                                ECSS_Unit__c = :ecssUnitId
                                AND RecordTypeId = :ContractUnitrecordTypeId
                            )
                            Order by ECSS_ContractOrganizationType__c desc
                        ]
                    );
                    activeContractWORem = new List<Contract>(
                        [
                            SELECT
                            Id,
                            ECSS_ContractOrganizationType__c,
                            ContractNumber,
                            AccountId,
                            Account.Name,
                            StartDate,
                            EndDate,
                            ECSS_Package__c,
                            ECSS_Remaining_Call_Outs__c,
                            Callouts_Available__c,
                            ECSS_Material_Spares__c,
                            (
                                SELECT
                                Id,
                                Initial__c,
                                Consumed__c,
                                Remaining__c,
                                Item_Type__c,
                                Category_Code__c,
                                Description__c,
                                Service_Material__c,
                                ECSS_SAPLineExternalId__c
                                FROM Unit_Contracts__r
                                WHERE
                                RecordTypeId = :ContractItemrecordTypeId
                                AND (Category_Code__c LIKE :catCode
                                     OR Category_Code__c = ''
                                     OR Category_Code__c = ';')
                            )
                            FROM Contract
                            WHERE
                            /*AccountId = :accountId
                            AND*/ ECSS_Active__c = TRUE
                            AND (ECSS_ContractOrganizationType__c = 'Khidmah'
                                 OR ECSS_ContractOrganizationType__c = 'IFM')
                            AND Callouts_Available__c = FALSE
                            AND Id IN (
                                SELECT Contract__c
                                FROM Unit_Contract__c
                                WHERE
                                ECSS_Unit__c = :ecssUnitId
                                AND RecordTypeId = :ContractUnitrecordTypeId
                            )
                            Order by ECSS_ContractOrganizationType__c desc
                        ]
                    );
                    System.debug('activeContractRem:' + activeContractRem);
                    System.debug('activeContractWORem:' + activeContractWORem);
                } else if (ecssUnitId != '' && accountId == '') {
                    activeContractRem = new List<Contract>(
                        [
                            SELECT
                            Id,
                            ECSS_ContractOrganizationType__c,
                            ContractNumber,
                            AccountId,
                            Account.Name,
                            StartDate,
                            EndDate,
                            ECSS_Package__c,
                            ECSS_Remaining_Call_Outs__c,
                            Callouts_Available__c,
                            ECSS_Material_Spares__c,
                            (
                                SELECT
                                Id,
                                Initial__c,
                                Consumed__c,
                                Remaining__c,
                                Item_Type__c,
                                Category_Code__c,
                                Description__c,
                                Service_Material__c,
                                ECSS_SAPLineExternalId__c
                                FROM Unit_Contracts__r
                                WHERE
                                RecordTypeId = :ContractItemrecordTypeId
                                AND (Category_Code__c LIKE :catCode
                                     OR Category_Code__c = ''
                                     OR Category_Code__c = ';')
                            )
                            FROM Contract
                            WHERE
                            RecordTypeId = :KhidmahContractrecordTypeId
                            AND ECSS_Active__c = TRUE
                            AND (ECSS_ContractOrganizationType__c = 'Khidmah'
                                 OR ECSS_ContractOrganizationType__c = 'IFM')
                            AND Callouts_Available__c = TRUE
                            AND Id IN (
                                SELECT Contract__c
                                FROM Unit_Contract__c
                                WHERE
                                ECSS_Unit__c = :ecssUnitId
                                AND RecordTypeId = :ContractUnitrecordTypeId
                            )
                            Order by ECSS_ContractOrganizationType__c desc
                        ]
                    );
                    activeContractWORem = new List<Contract>(
                        [
                            SELECT
                            Id,
                            ECSS_ContractOrganizationType__c,
                            ContractNumber,
                            AccountId,
                            Account.Name,
                            StartDate,
                            EndDate,
                            ECSS_Package__c,
                            ECSS_Remaining_Call_Outs__c,
                            Callouts_Available__c,
                            ECSS_Material_Spares__c,
                            (
                                SELECT
                                Id,
                                Initial__c,
                                Consumed__c,
                                Remaining__c,
                                Item_Type__c,
                                Category_Code__c,
                                Description__c,
                                Service_Material__c,
                                ECSS_SAPLineExternalId__c
                                FROM Unit_Contracts__r
                                WHERE
                                RecordTypeId = :ContractItemrecordTypeId
                                AND (Category_Code__c LIKE :catCode
                                     OR Category_Code__c = ''
                                     OR Category_Code__c = ';')
                            )
                            FROM Contract
                            WHERE
                            RecordTypeId = :KhidmahContractrecordTypeId
                            AND ECSS_Active__c = TRUE
                            AND (ECSS_ContractOrganizationType__c = 'Khidmah'
                                 OR ECSS_ContractOrganizationType__c = 'IFM')
                            AND Callouts_Available__c = FALSE
                            AND Id IN (
                                SELECT Contract__c
                                FROM Unit_Contract__c
                                WHERE
                                ECSS_Unit__c = :ecssUnitId
                                AND RecordTypeId = :ContractUnitrecordTypeId
                            ) 
                            Order by ECSS_ContractOrganizationType__c desc
                        ]
                    );
                } else if (ecssUnitId == '' && accountId != '') {
                    activeContractRem = new List<Contract>(
                        [
                            SELECT
                            Id,
                            ECSS_ContractOrganizationType__c,
                            ECSS_Remaining_Call_Outs__c,
                            Callouts_Available__c,
                            ContractNumber,
                            AccountId,
                            Account.Name,
                            StartDate,
                            EndDate,
                            ECSS_Package__c,
                            ECSS_Material_Spares__c,
                            (
                                SELECT
                                Id,
                                Initial__c,
                                Consumed__c,
                                Remaining__c,
                                Item_Type__c,
                                Category_Code__c,
                                Description__c,
                                Service_Material__c,
                                ECSS_SAPLineExternalId__c
                                FROM Unit_Contracts__r
                                WHERE
                                RecordTypeId = :ContractItemrecordTypeId
                                AND (Category_Code__c LIKE :catCode
                                     OR Category_Code__c = ''
                                     OR Category_Code__c = ';')
                            )
                            FROM Contract
                            WHERE
                            RecordTypeId = :KhidmahContractrecordTypeId
                            AND AccountId = :accountId
                            AND ECSS_Active__c = TRUE
                            AND (ECSS_ContractOrganizationType__c = 'Khidmah'
                                 OR ECSS_ContractOrganizationType__c = 'IFM')
                            AND Callouts_Available__c = TRUE
                            Order by ECSS_ContractOrganizationType__c desc
                        ]
                    );
                    activeContractWORem = new List<Contract>(
                        [
                            SELECT
                            Id,
                            ECSS_ContractOrganizationType__c,
                            ECSS_Remaining_Call_Outs__c,
                            Callouts_Available__c,
                            ContractNumber,
                            AccountId,
                            Account.Name,
                            StartDate,
                            EndDate,
                            ECSS_Package__c,
                            ECSS_Material_Spares__c,
                            (
                                SELECT
                                Id,
                                Initial__c,
                                Consumed__c,
                                Remaining__c,
                                Item_Type__c,
                                Category_Code__c,
                                Description__c,
                                Service_Material__c,
                                ECSS_SAPLineExternalId__c 
                                FROM Unit_Contracts__r
                                WHERE
                                RecordTypeId = :ContractItemrecordTypeId
                                AND (Category_Code__c LIKE :catCode
                                     OR Category_Code__c = ''
                                     OR Category_Code__c = ';')
                            )
                            FROM Contract
                            WHERE
                            RecordTypeId = :KhidmahContractrecordTypeId
                            AND AccountId = :accountId
                            AND ECSS_Active__c = TRUE
                            AND (ECSS_ContractOrganizationType__c = 'Khidmah'
                                 OR ECSS_ContractOrganizationType__c = 'IFM')
                            AND Callouts_Available__c = FALSE
                            Order by ECSS_ContractOrganizationType__c desc
                        ]
                    );
                }
        }
        System.debug('reached here');
        cw.activeContractsNoDetails = new List<Contract>();
        cw.activeContractsWithRemaining = new List<Contract>();
        for (Contract cont : activeContractRem) { if (cont.Unit_Contracts__r.size() > 0) {cw.activeContractsWithRemaining.add(cont);
            } else {  cw.activeContractsNoDetails.add(cont);
            }
        }
        cw.activeContractsNoDetails = new List<Contract>();
        cw.activeContractsWORemaining = new List<Contract>();
        for (Contract cont : activeContractWORem) {
            if (cont.Unit_Contracts__r.size() > 0) { cw.activeContractsWORemaining.add(cont);} else { cw.activeContractsNoDetails.add(cont);
            }
        }
        system.debug(cw);
        return cw;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<ContactWrapper> relatedContacts(String accId , String assetId) {
        System.debug('entered here:');
        List<ContactWrapper> contactList = new List<ContactWrapper>();
        Account inpAcc = [
            SELECT
            Id,
            isPersonAccount,
            PersonContactId,
            PersonContact.Name,
            PersonContact.MobilePhoneValue__c
            FROM Account
            WHERE Id = :accId
        ];
        if (inpAcc.IsPersonAccount) {
            System.debug('in the person');
            ContactWrapper newContactWr = new ContactWrapper(
                inpAcc.PersonContact.Name +
                ' - ' +
                inpAcc.PersonContact.MobilePhoneValue__c,
                inpAcc.PersonContactId,
                inpAcc.isPersonAccount
            );
            contactList.add(newContactWr);
            /*List<AccountContactRelation> contRel = [
                SELECT
                Id,
                AccountId,
                Contact.Name,
                contactId,
                Contact.MobilePhoneValue__c
                FROM AccountContactRelation
                WHERE AccountId = :accId
            ];*/
            List<Contact_Account_Unit__c> contRel = [
               SELECT
                Id,
                Account__c,
                Contact__r.Name,
                Contact__c,
                Contact__r.MobilePhoneValue__c,Asset__c
                FROM Contact_Account_Unit__c
                WHERE Account__c = :accId and Asset__c =: assetId
            ];
            for (Contact_Account_Unit__c cuuAccC : contRel) {
                ContactWrapper newContactWrCont = new ContactWrapper(
                    cuuAccC.Contact__r.Name + ' - ' + cuuAccC.Contact__r.MobilePhoneValue__c,
                    cuuAccC.Contact__c,
                    inpAcc.isPersonAccount
                );
                contactList.add(newContactWrCont);
            }
            return contactList;
        }
        System.debug('accId' + accId);
       /* List<Contact> contcsList = [
            SELECT Id, AccountId, Name, MobilePhone, MobilePhoneValue__c
            FROM contact
            WHERE AccountId = :accId
        ];*/
		 List<Contact_Account_Unit__c> contcsList = [
               SELECT
                Id,
                Account__c,
                Contact__r.Name,
                Contact__c,
                Contact__r.MobilePhoneValue__c,Asset__c
                FROM Contact_Account_Unit__c
                WHERE Account__c = :accId and Asset__c =: assetId
            ]; 
        System.debug('Asset__c:'+assetId);
        System.debug('Account: '+accId);
            System.debug('contRel:'+contcsList);
        for (Contact_Account_Unit__c currContact : contcsList) {
            ContactWrapper newContactWr = new ContactWrapper(currContact.contact__r.Name + ' - ' + currContact.contact__r.MobilePhoneValue__c,currContact.Contact__c,inpAcc.isPersonAccount
            );contactList.add(newContactWr);
        }
        System.debug('output contact list' + contactList);
        return contactList;
    }
    
    /*   @AuraEnabled(cacheable=true)
public static derivedValues derivedValues (String chosenType, String SubVertical , String subCategory){
System.debug('in thr derivedValues');
List<Case_Field_Dependency_Revised__mdt> dependantValue =  new List<Case_Field_Dependency_Revised__mdt>([SELECT Id,Category__c,Organization__c,ECSS_Sub_Category__c,Sub_vertical__c,ECSS_Is_ECSS__c,ECSS_Sub_Category__r.MasterLabel,
ECSS_Sub_Category__r.Inquiry__c,ECSS_Sub_Category__r.Maintenance__c,ECSS_Sub_Category__r.Complaints__c,ECSS_ObjectCategory__c
FROM Case_Field_Dependency_Revised__mdt 
WHERE ECSS_Sub_Category__r.MasterLabel=:subCategory and Sub_vertical__c=:SubVertical]);
System.debug('dependantValue'+dependantValue);
system.debug('ChosenType'+chosenType);
List<derivedValues> filteredList = new List<derivedValues>();
if(dependantValue.size() == 1){
Case_Field_Dependency_Revised__mdt currItem = dependantValue[0];
if(chosenType.contains('Inquiry')){
if(currItem.ECSS_Sub_Category__r.Inquiry__c){
derivedValues dv = new derivedValues();
dv.objectCatName = currItem.ECSS_ObjectCategory__c;
dv.categoryName = currItem.Category__c;
if(!filteredList.contains(dv))
filteredList.add(dv);
}
}
if(chosenType.contains('Complaint')){
if(currItem.ECSS_Sub_Category__r.Complaints__c){
derivedValues dv = new derivedValues();
dv.objectCatName = currItem.ECSS_ObjectCategory__c;
dv.categoryName = currItem.Category__c;
if(!filteredList.contains(dv))
filteredList.add(dv);
}
}
return filteredList[0];
}

return null;
}*/
    @AuraEnabled(cacheable=true)
    public static List<ListWrapper> subCategoryReturnValue(
        String Category,
        String SubVertical,
        String chosenType,
        String ObjectCateogry
    ) {
        Set<ListWrapper> outputSubCategory = new Set<ListWrapper>();
        if (
            (SubVertical == null ||
             SubVertical == '') &&
            (Category == null ||
             Category == '') &&
            (ObjectCateogry == null ||
             ObjectCateogry == '')
        ) {
            return null;
        }
        if ((SubVertical == null || SubVertical == '')) {
            return null;
        }
        System.debug('SubVertical:' + SubVertical);
        
        String complintLabel = Label.ECSS_Complaint_Check;
        String maintenanceLable = Label.ECSS_Maintenance_Check;
        String inquiryLabel = Label.ECSS_Inquiry_Name_Check;
        List<String> catNames = new List<String>();
        // Initialize base query
        String baseQuery =
            'SELECT Id, Category__c, Organization__c, ECSS_Sub_Category__c, Sub_vertical__c, ECSS_Is_ECSS__c, ' +
            'ECSS_Sub_Category__r.MasterLabel, ECSS_Sub_Category__r.Inquiry__c, ECSS_Sub_Category__r.Maintenance__c, ' +
            'ECSS_Sub_Category__r.Complaints__c ' +
            'FROM Case_Field_Dependency_Revised__mdt WHERE ';
        
        // Initialize a list to hold conditions
        List<String> conditions = new List<String>();
        
        // Add conditions dynamically
        if (Category != null && Category != '') {
            conditions.add('Category__c = :Category');
        }
        if (SubVertical != null && SubVertical != '') {
            conditions.add('Sub_vertical__c = :SubVertical');
        }
        if (
            ObjectCateogry != null &&
            ObjectCateogry != '' &&
            !(chosenType.contains('Request'))
        ) {
            conditions.add('ECSS_ObjectCategory__c = :ObjectCateogry');
        }
        conditions.add('ECSS_Is_ECSS__c = true');
        System.debug('Case category:' + Category);
        System.debug('SubVertical:' + SubVertical);
        
        // Combine conditions into a single WHERE clause or handle no filters case
        if (!conditions.isEmpty()) {
            baseQuery += String.join(conditions, ' AND ');
        } else {
            baseQuery = baseQuery.removeEnd(' WHERE '); // Remove trailing 'WHERE' if no conditions exist
        }
        System.debug('baseQuery' + baseQuery);
        // Query the database
        List<Case_Field_Dependency_Revised__mdt> caseDependencyList = Database.query(
            baseQuery
        );
        System.debug('depdSize:' + caseDependencyList.size());
        for (Case_Field_Dependency_Revised__mdt currMdt : caseDependencyList) {
            ListWrapper currItem = new ListWrapper();
            if (chosenType.contains(maintenanceLable)) {
                if (currMdt.ECSS_Sub_Category__r.Maintenance__c) {
                    currItem.valName = currMdt.ECSS_Sub_Category__r.MasterLabel;
                    if (!catNames.contains(currMdt.ECSS_Sub_Category__r.MasterLabel)) {
                        catNames.add(currMdt.ECSS_Sub_Category__r.MasterLabel);
                        outputSubCategory.add(currItem);
                    }
                }
            } else if (chosenType.contains(inquiryLabel)) {
                if (currMdt.ECSS_Sub_Category__r.Inquiry__c) {
                    currItem.valName = currMdt.ECSS_Sub_Category__r.MasterLabel;
                    if (!catNames.contains(currMdt.ECSS_Sub_Category__r.MasterLabel)) {
                        catNames.add(currMdt.ECSS_Sub_Category__r.MasterLabel);
                        outputSubCategory.add(currItem);
                    }
                }
            } else if (chosenType.contains(complintLabel)) {
                if (currMdt.ECSS_Sub_Category__r.Complaints__c) {
                    currItem.valName = currMdt.ECSS_Sub_Category__r.MasterLabel;
                    if (!catNames.contains(currMdt.ECSS_Sub_Category__r.MasterLabel)) {
                        catNames.add(currMdt.ECSS_Sub_Category__r.MasterLabel);
                        outputSubCategory.add(currItem);
                    }
                }
            }
        }
        List<ListWrapper> outWrapper = new List<ListWrapper>(outputSubCategory);
        System.debug('outputSubCategory:' + outputSubCategory.size());
        return outWrapper;
    }
    @AuraEnabled(cacheable=true)
    public static List<ListWrapper> categoryReturnValue(
        String chosenType,
        String objectCategory,
        String SubVertical,
        String subCategory,
        String categoryOpstionsLst
    ) {
        List<ListWrapper> outputObjectCategory = new List<ListWrapper>();
        // Deserialize JSON string to List of PickValsWrapper
        System.debug('categoryOpstionsLst:' + categoryOpstionsLst);
        List<PickValsWrapper> categoryOptionsList = new List<PickValsWrapper>();
        if (categoryOpstionsLst != '' && categoryOpstionsLst != '[{}]') {
            categoryOptionsList = (List<PickValsWrapper>) JSON.deserialize(
                categoryOpstionsLst,
                List<PickValsWrapper>.class
            );
        }
        if (chosenType.contains('Request')) {
            objectCategory = '';
        }
        if (
            (SubVertical == null ||
             SubVertical == '' ||
             objectCategory == null ||
             objectCategory == '') &&
            !(chosenType.contains('Request') &&
              subCategory != '' &&
              SubVertical != '')
        ) {
            return null;
        }
        if (
            (objectCategory == null || objectCategory == '') &&
            (subCategory == null ||
             subCategory == '')
        ) {
            return null;
        }
        System.debug('Obejct Category:' + objectCategory);
        
        String complintLabel = Label.ECSS_Complaint_Check;
        String maintenanceLable = Label.ECSS_Maintenance_Check;
        String inquiryLabel = Label.ECSS_Inquiry_Name_Check;
        List<String> categoryOptions = new List<String>();
        for (PickValsWrapper currVlu : categoryOptionsList) {
            categoryOptions.add(currVlu.label);
        }
        System.debug('categoryOptions:' + categoryOptions);
        // Initialize base query
        String baseQuery =
            'SELECT Id, ECSS_ObjectCategory__c, Category__c, Organization__c, ECSS_Sub_Category__c, Sub_vertical__c, ECSS_Is_ECSS__c, ' +
            'ECSS_Sub_Category__r.MasterLabel, ECSS_Sub_Category__r.Inquiry__c, ECSS_Sub_Category__r.Maintenance__c, ' +
            'ECSS_Sub_Category__r.Complaints__c ' +
            'FROM Case_Field_Dependency_Revised__mdt WHERE ';
        
        // Initialize a list to hold conditions
        List<String> conditions = new List<String>();
        List<String> objCatName = new List<String>();
        if (categoryOptions.size() > 0) {
            conditions.add('Category__c in:categoryOptions');
        }
        // Add conditions dynamically
        if (
            objectCategory != null &&
            objectCategory != '' &&
            !(chosenType.contains('Request'))
        ) {
            conditions.add('ECSS_ObjectCategory__c = :objectCategory');
            System.debug('in the object categry:');
        }
        if (SubVertical != null && SubVertical != '') {
            conditions.add('Sub_vertical__c = :SubVertical');
        }
        if (subCategory != null && subCategory != '') {
            conditions.add('ECSS_Sub_Category__r.MasterLabel = :subCategory');
        }
        conditions.add('ECSS_Is_ECSS__c = true');
        
        if (chosenType.contains(complintLabel)) {
            conditions.add('ECSS_Sub_Category__r.Complaints__c = true');
        }
        
        if (chosenType.contains(inquiryLabel)) {
            conditions.add('ECSS_Sub_Category__r.Inquiry__c = true');
        }
        if (chosenType.contains(maintenanceLable)) {
            conditions.add('ECSS_Sub_Category__r.Maintenance__c = true');
        }
        // Combine conditions into a single WHERE clause
        if (!conditions.isEmpty()) {
            baseQuery += String.join(conditions, ' AND ');
        } else {
            throw new IllegalArgumentException(
                'At least one filter must be provided.'
            );
        }
        
        System.debug('query: ' + baseQuery);
        
        // Query the database
        List<Case_Field_Dependency_Revised__mdt> caseDependencyList = Database.query(
            baseQuery
        );
        
        for (Case_Field_Dependency_Revised__mdt currMdt : caseDependencyList) {
            ListWrapper currItem = new ListWrapper();
            currItem.valName = currMdt.Category__c;
            
            if (!objCatName.contains(currMdt.Category__c)) {
                objCatName.add(currMdt.Category__c);
                
                if (!outputObjectCategory.contains(currItem)) {
                    outputObjectCategory.add(currItem);
                }
            }
        }
        return outputObjectCategory;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<ListWrapper> objectCategoryReturnValue(
        String chosenType,
        String Category,
        String SubVertical,
        String subCategory
    ) {
        List<ListWrapper> outputObjectCategory = new List<ListWrapper>();
        String complintLabel = Label.ECSS_Complaint_Check;
        String maintenanceLable = Label.ECSS_Maintenance_Check;
        String inquiryLabel = Label.ECSS_Inquiry_Name_Check;
        
        if (chosenType.contains(maintenanceLable)) {
            System.debug('Maintenance');
            // Get the SObjectType for Case
            Schema.SObjectType objType = Schema.getGlobalDescribe().get('Case');
            Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
            // Get the describe information for the field
            Schema.SObjectField field = objDescribe.fields.getMap()
                .get('ECSS_Object_Category__c');
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            for (Schema.PicklistEntry pickItem : fieldDescribe.getPicklistValues()) {
                String currString = pickItem.getLabel();
                ListWrapper currItem = new ListWrapper();
                currItem.valName = currString;
                currItem.labelName = currString;
                System.debug('currString' + currString);
                if (
                    !outputObjectCategory.contains(currItem) &&
                    (currString == 'Bathroom' ||
                     currString == 'Garage' ||
                     currString == 'Kids room' ||
                     currString == 'Kitchen' ||
                     currString == 'Living Room' ||
                     currString == 'Master bedroom' ||
                     currString == 'Others')
                )
                    outputObjectCategory.add(currItem);
            }
            
            return outputObjectCategory;
        }
        if (
            (chosenType == null ||
             chosenType == '') &&
            (SubVertical == null ||
             SubVertical == '') &&
            (subCategory == null ||
             subCategory == '')
        ) {
            return null;
        }
        if (
            (chosenType == null || chosenType == '') ||
            (SubVertical == null ||
             SubVertical == '')
        ) {
            return null;
        }
        System.debug('Category' + Category);
        // Initialize base query
        String baseQuery =
            'SELECT Id, Category__c, Organization__c, ECSS_Sub_Category__c, Sub_vertical__c, ECSS_Is_ECSS__c, ' +
            'ECSS_Sub_Category__r.MasterLabel, ECSS_Sub_Category__r.Inquiry__c, ECSS_Sub_Category__r.Maintenance__c, ' +
            'ECSS_Sub_Category__r.Complaints__c, ECSS_ObjectCategory__c ' +
            'FROM Case_Field_Dependency_Revised__mdt WHERE ';
        
        // Initialize a list to hold conditions
        List<String> conditions = new List<String>();
        List<String> objCatName = new List<String>();
        // Add conditions dynamically
        if (category != null && category != '') {
            conditions.add('Category__c = :category');
        }
        if (SubVertical != null && SubVertical != '') {
            conditions.add('Sub_vertical__c = :SubVertical');
        }
        if (subCategory != null && subCategory != '') {
            conditions.add('ECSS_Sub_Category__r.MasterLabel = :subCategory');
        }
        conditions.add('ECSS_Is_ECSS__c = true');
        
        if (chosenType.contains(complintLabel)) {
            conditions.add('ECSS_Sub_Category__r.Complaints__c = true');
        }
        if (chosenType.contains(inquiryLabel)) {
            conditions.add('ECSS_Sub_Category__r.Inquiry__c = true');
        }
        // Combine conditions into a single WHERE clause
        if (!conditions.isEmpty()) {
            baseQuery += String.join(conditions, ' AND ');
        } else {
            throw new IllegalArgumentException(
                'At least one filter must be provided.'
            );
        }
        System.debug('query:' + baseQuery);
        // Query the database
        List<Case_Field_Dependency_Revised__mdt> caseDependencyList = Database.query(
            baseQuery
        );
        
        for (Case_Field_Dependency_Revised__mdt currMdt : caseDependencyList) {
            ListWrapper currItem = new ListWrapper();
            currItem.valName = currMdt.ECSS_ObjectCategory__c;
            if(currItem.valName == 'Khidmah Home')
                currItem.labelName = 'Inspire Home';
            else
               currItem.labelName = currMdt.ECSS_ObjectCategory__c;

            if (!objCatName.contains(currMdt.ECSS_ObjectCategory__c)) {
                objCatName.add(currMdt.ECSS_ObjectCategory__c);
                
                if (!outputObjectCategory.contains(currItem))
                    outputObjectCategory.add(currItem);
            }
        }
        return outputObjectCategory;
    }
    @AuraEnabled(cacheable=true)
    public static inventoryWrapper getInvData(){
        inventoryWrapper invWr = new inventoryWrapper();
        
        //Building
        List<BuildingSection__c> buildings= [select id,name,ECSS_Zone__c,Project__c from BuildingSection__c where id in( select ECSS_Building_Section__c from asset)];
        List<PickValsWrapper> buildingsWr = new List<PickValsWrapper>();
        for(BuildingSection__c currBuildsec : buildings){
            PickValsWrapper pckWrp = new PickValsWrapper();
            pckWrp.label = currBuildsec.Name;
            pckWrp.value = currBuildsec.Id;
            pckWrp.projectId = currBuildsec.Project__c;
            pckWrp.zoneId = currBuildsec.ECSS_Zone__c;
            buildingsWr.add(pckWrp);            
        }        
        invWr.buildingVals = buildingsWr;
        
        //Project
        List<Project__c> projects= [select id,name from Project__c  where id in( select ECSS_Project__c from asset )];
        List<PickValsWrapper> projectsWr = new List<PickValsWrapper>();
        for(Project__c currProjectsec : projects){
            PickValsWrapper pckWrp = new PickValsWrapper();
            pckWrp.label = currProjectsec.Name;
            pckWrp.value = currProjectsec.Id;
            projectsWr.add(pckWrp);            
        }        
        invWr.projectVals = projectsWr;
        
        //Zone
        List<Zone__c> zones= [select id,name,Project__c from Zone__c   where id in( select ECSS_Zone__c from asset )];
        List<PickValsWrapper> zonesWr = new List<PickValsWrapper>();
        for(Zone__c currZonesec : zones){
            PickValsWrapper pckWrp = new PickValsWrapper();
            pckWrp.label = currZonesec.Name;
            pckWrp.value = currZonesec.Id;
            pckWrp.projectId = currZonesec.Project__c;
            zonesWr.add(pckWrp);            
        }        
        invWr.zoneVals = zonesWr;
        
        
        return invWr;
    }
    public static List<CustomerUnitWrapper>  getRelatedCustomerUnitsHelper(string accountId,
                                                                           String searchTerm,
                                                                           String assetSearchKey,
                                                                           String buildingValue,
                                                                           String projectValue,
                                                                           String zoneValue,
                                                                           String UCCrecordtypeName
                                                                          )
    {
        
         String recordTypeName;
         System.debug('UCCrecordtypeName'+UCCrecordtypeName);
        if(UCCrecordtypeName == 'Functional Location') {
            recordTypeName = 'Functional Location';  
        } else if(UCCrecordtypeName == 'Ecss Unit') {
            recordTypeName = 'Ecss Unit';  
        } 
        System.debug('Entered in the helper');
        List<CustomerUnitWrapper> outputList = new  List<CustomerUnitWrapper>();
        Set<String> unitCodes = new Set<String>();
        Set<String> unitsDisplayed = new Set<String>();
        Set<String> parentUnitExcluded = new Set<String>();
        Set<String> accContracts = new Set<String>();
        Map<String,String> accountUnitMap = new Map<String,String>();
        Map<String,Customer_Unit__c> custUnitTenant = new Map<String,Customer_Unit__c>();
        //Get Related Tenant CustomerUnit child FL
        List<Asset> tenantUnitChildren = [
            SELECT Id, ParentId,Name,ECSS_Unit_Type__c,ECSS_Project__c,
            Parent.ECSS_Project__c,ECSS_Project__r.Name,
            Parent.ECSS_Project__r.Name,
            Parent.ECSS_Building_Section__c,
            Parent.ECSS_Building_Section__r.Name,
            ECSS_Building_Section__r.Name,
            ECSS_Zone__c,
            Parent.ECSS_Zone__c,
            ECSS_Zone__r.Name,
            Parent.ECSS_Zone__r.Name,
            ECSS_Unit_Code__c,
            Description,
            RecordTypeName__c
            FROM Asset
            WHERE Is_PropEzzy__c = False and ParentId in(SELECT Unit__c
                              FROM Customer_Unit__c where
                              account__c = :accountId and Customer_Type__c='Tenant' ) and RecordType.Name =: recordTypeName
            limit 20000
        ];
        //Get child FL related IFM Contracts
        Map<Id,Asset> tenantassMap = new Map<Id,Asset>(tenantUnitChildren);
        Set<Id> childAssetIds = new Map<Id, Asset>(tenantUnitChildren).keySet();
        List<Unit_Contract__c> ifmContracts = [SELECT Id,Contract__c,Contract__r.AccountId,ECSS_Unit__c,ECSS_Unit__r.ECSS_Project__r.Name,
                                               ECSS_Unit__r.Parent.ECSS_Project__r.Name,ECSS_Unit__r.ECSS_Unit_Code__c,ECSS_Unit__r.Name,ECSS_Unit__r.ECSS_Unit_Type__c,
                                               ECSS_Unit__r.ECSS_Project__c,ECSS_Unit__r.Parent.ECSS_Project__c,ECSS_Unit__r.ECSS_Building_Section__r.Name,
                                               ECSS_Unit__r.Parent.ECSS_Building_Section__r.Name,ECSS_Unit__r.ECSS_Building_Section__c,ECSS_Unit__r.Parent.ECSS_Building_Section__c,
                                               ECSS_Unit__r.ECSS_Zone__r.Name,ECSS_Unit__r.Parent.ECSS_Zone__r.Name,ECSS_Unit__r.ECSS_Zone__c,ECSS_Unit__r.Parent.ECSS_Zone__c,
                                               ECSS_Unit__r.Description,ECSS_Unit__r.Is_PropEzzy__c
                                               FROM Unit_Contract__c
                                               WHERE ECSS_Unit__c IN :childAssetIds and ECSS_Unit__r.Is_PropEzzy__c=false];
        for(Unit_Contract__c contr : ifmContracts){
            accContracts.add(contr.Contract__r.AccountId);
            accountUnitMap.put(contr.ECSS_Unit__c,contr.Contract__r.AccountId);
        }
        List<Customer_Unit__c> custumerUnitTenant = [SELECT Id,Unit__c,Account__c,Customer_Type__c,Unit__r.Is_PropEzzy__c FROM Customer_Unit__c WHERE Unit__c in:(childAssetIds) AND Account__c in: (accContracts) AND Unit__r.Is_PropEzzy__c= false];
        for(Customer_Unit__c customerUnit: custumerUnitTenant){
            String key = customerUnit.Unit__c;
            if(accountUnitMap.get(key) != null && customerUnit.account__c ==accountUnitMap.get(key) )
                custUnitTenant.put(key,customerUnit);
        }
        //Add the FL to the outputList 
        for(Unit_Contract__c currItem : ifmContracts){
            if(!unitCodes.contains(currItem.ECSS_Unit__r.ECSS_Unit_Code__c) ){
                unitCodes.add(currItem.ECSS_Unit__r.ECSS_Unit_Code__c);
                if(!unitsDisplayed.contains(currItem.Ecss_Unit__c))
                    unitsDisplayed.add(currItem.Ecss_Unit__c);
                if(!parentUnitExcluded.contains(currItem.Ecss_Unit__r.ParentId))
                    parentUnitExcluded.add(currItem.Ecss_Unit__r.ParentId);
                CustomerUnitWrapper cuw = new CustomerUnitWrapper();
                cuw.unitId = currItem.ECSS_Unit__c;
                cuw.unitName = currItem.ECSS_Unit__r.Name;
                String key = currItem.ECSS_Unit__c;
                if(custUnitTenant.get(key) != null){
                    cuw.customerUnitId = custUnitTenant.get(key).Id;
                    cuw.customerType = custUnitTenant.get(key).Customer_Type__c;
                    if (
                        currItem.ECSS_Unit__r.ECSS_Project__r.Name != '' &&
                        currItem.ECSS_Unit__r.ECSS_Project__r.Name != null
                    )
                        cuw.projectName = currItem.ECSS_Unit__r.ECSS_Project__r.Name;
                    else
                        cuw.projectName = currItem.ECSS_Unit__r.Parent.ECSS_Project__r.Name;
                    
                    cuw.unitType = currItem.ECSS_Unit__r.ECSS_Unit_Type__c;
                    if (currItem.ECSS_Unit__r.ECSS_Project__c != null)
                        cuw.projectId = currItem.ECSS_Unit__r.ECSS_Project__c;
                    else
                        cuw.projectId = currItem.ECSS_Unit__r.Parent.ECSS_Project__c;
                    
                    if (
                        currItem.ECSS_Unit__r.ECSS_Building_Section__r.Name != '' &&
                        currItem.ECSS_Unit__r.ECSS_Building_Section__r.Name != null
                    )
                        cuw.buildingName = currItem.ECSS_Unit__r.ECSS_Building_Section__r.Name;
                    else
                        cuw.buildingName = currItem.ECSS_Unit__r.Parent.ECSS_Building_Section__r.Name;
                    if (currItem.ECSS_Unit__r.ECSS_Building_Section__c != null)
                        cuW.buildingId = currItem.ECSS_Unit__r.ECSS_Building_Section__c;
                    else
                        cuW.buildingId = currItem.ECSS_Unit__r.Parent.ECSS_Building_Section__c;
                    if (
                        currItem.ECSS_Unit__r.ECSS_Zone__r.Name != '' &&
                        currItem.ECSS_Unit__r.ECSS_Zone__r.Name != null
                    )
                        cuw.zoneName = currItem.ECSS_Unit__r.ECSS_Zone__r.Name;
                    else
                        cuw.zoneName = currItem.ECSS_Unit__r.Parent.ECSS_Zone__r.Name;
                    if (
                        currItem.ECSS_Unit__r.ECSS_Zone__c != '' &&
                        currItem.ECSS_Unit__r.ECSS_Zone__c != null
                    )
                        cuW.zoneId = currItem.ECSS_Unit__r.ECSS_Zone__c;
                    else
                        cuW.zoneId = currItem.ECSS_Unit__r.Parent.ECSS_Zone__c;
                    cuW.unitCode = currItem.ECSS_Unit__r.ECSS_Unit_Code__c;
                    cuW.description = currItem.ECSS_Unit__r.Description;
                    //System.debug('Unit Code:' + currItem.ECSS_Unit__r.ECSS_Unit_Code__c);
                    outputList.add(cuw);
                }
            }
            
        }
        System.debug('parentUnitExcluded:'+parentUnitExcluded);
        //get the fls not in the unitsDisplayed and the units whose children are not in unitsDisplayed
        List<Customer_Unit__c> remainingCU = [ SELECT
                                              Id,
                                              Name,
                                              Unit__r.Name,
                                              unit__c,
                                              Unit__r.ParentId,
                                              Unit__r.ECSS_Unit_Type__c,
                                              Unit__r.ECSS_Project__c,
                                              Unit__r.Parent.ECSS_Project__c,
                                              Unit__r.ECSS_Project__r.Name,
                                              Unit__r.Parent.ECSS_Project__r.Name,
                                              Unit__r.ECSS_Building_Section__c,
                                              Unit__r.Parent.ECSS_Building_Section__c,
                                              Unit__r.Parent.ECSS_Building_Section__r.Name,
                                              Unit__r.ECSS_Building_Section__r.Name,
                                              Unit__r.ECSS_Zone__c,
                                              Unit__r.Parent.ECSS_Zone__c,
                                              Unit__r.ECSS_Zone__r.Name,
                                              Unit__r.Parent.ECSS_Zone__r.Name,
                                              Unit__r.ECSS_Unit_Code__c,
                                              Unit__r.Description,
                                              unit__r.RecordTypeName__c,
                                              Customer_Type__c,Unit__r.Is_PropEzzy__c
                                              FROM Customer_Unit__c
                                              WHERE
                                              account__c = :accountId  and Unit__c not in:(parentUnitExcluded) and Unit__c not in:(unitsDisplayed) and Unit__r.Is_PropEzzy__c = false Order by unit__r.RecordTypeName__c desc limit 20000
                                             ];
        
        for (Customer_Unit__c cUnit : remainingCU) {
            if(!unitCodes.contains(cUnit.Unit__r.ECSS_Unit_Code__c) ){
                unitCodes.add(cUnit.Unit__r.ECSS_Unit_Code__c);
                CustomerUnitWrapper cuw = new CustomerUnitWrapper();
                cuw.unitId = cUnit.unit__c;
                cuw.unitName = cUnit.unit__r.Name;
                cuw.customerUnitId = cUnit.Id;
                cuw.customerType = cUnit.Customer_Type__c;
                if (
                    cUnit.Unit__r.ECSS_Project__r.Name != '' &&
                    cUnit.Unit__r.ECSS_Project__r.Name != null
                )
                    cuw.projectName = cUnit.Unit__r.ECSS_Project__r.Name;
                else
                    cuw.projectName = cUnit.Unit__r.Parent.ECSS_Project__r.Name;
                
                cuw.unitType = cUnit.Unit__r.ECSS_Unit_Type__c;
                if (cUnit.Unit__r.ECSS_Project__c != null)
                    cuw.projectId = cUnit.Unit__r.ECSS_Project__c;
                else
                    cuw.projectId = cUnit.Unit__r.Parent.ECSS_Project__c;
                
                if (
                    cUnit.Unit__r.ECSS_Building_Section__r.Name != '' &&
                    cUnit.Unit__r.ECSS_Building_Section__r.Name != null
                )
                    cuw.buildingName = cUnit.Unit__r.ECSS_Building_Section__r.Name;
                else
                    cuw.buildingName = cUnit.Unit__r.Parent.ECSS_Building_Section__r.Name;
                if (cUnit.Unit__r.ECSS_Building_Section__c != null)
                    cuW.buildingId = cUnit.Unit__r.ECSS_Building_Section__c;
                else
                    cuW.buildingId = cUnit.Unit__r.Parent.ECSS_Building_Section__c;
                if (
                    cUnit.Unit__r.ECSS_Zone__r.Name != '' &&
                    cUnit.Unit__r.ECSS_Zone__r.Name != null
                )
                    cuw.zoneName = cUnit.Unit__r.ECSS_Zone__r.Name;
                else
                    cuw.zoneName = cUnit.Unit__r.Parent.ECSS_Zone__r.Name;
                if (
                    cUnit.Unit__r.ECSS_Zone__c != '' &&
                    cUnit.Unit__r.ECSS_Zone__c != null
                )
                    cuW.zoneId = cUnit.Unit__r.ECSS_Zone__c;
                else
                    cuW.zoneId = cUnit.Unit__r.Parent.ECSS_Zone__c;
                cuW.unitCode = cUnit.Unit__r.ECSS_Unit_Code__c;
                cuW.description = cUnit.Unit__r.Description;
                // System.debug('Unit Code:' + cUnit.Unit__r.ECSS_Unit_Code__c);
                outputList.add(cuw);
            }
        }        
        return outputList;
    }
    @AuraEnabled(cacheable=true)
    public static List<CustomerUnitWrapper> getRelatedUnits(
        string accountId,
        String searchTerm,
        String assetSearchKey,
        String buildingValue,
        String projectValue,
        String zoneValue,
        String UCCrecordtypeName
    ) {
        
         String recordTypeName;
        
        if(UCCrecordtypeName == 'Functional Location') {
            recordTypeName = 'Functional Location';  
        } else if(UCCrecordtypeName == 'Ecss Unit') {
            recordTypeName = 'Ecss Unit';  
        } 
        
        if (assetSearchKey != '') {
            searchTerm = assetSearchKey;
        }
        List<CustomerUnitWrapper> customerUnitWrapperList = new List<CustomerUnitWrapper>();
        try {
            List<String> unitCodes = new List<String>();
            if (accountId != null && accountId != '') {
                customerUnitWrapperList = getRelatedCustomerUnitsHelper( accountId, searchTerm,assetSearchKey, buildingValue, projectValue, zoneValue,recordTypeName);
            } else {
                List<Asset> loopAsset; 
                Set<String> parentIdsExcluded = new Set<String>();
                Set<String> flToCheck = new Set<String>();
                Map<String,CustomerUnitWrapper> custWrapperMap = new Map<String,CustomerUnitWrapper>();
                // Default search pattern as LIKE in SOQL
                String likePattern = '';
                if (searchTerm != null && searchTerm != '') {
                    searchTerm = searchTerm.trim();
                    likePattern = '%' + searchTerm.replace('*', '%') + '%'; // Convert * to % for LIKE operator
                    loopAsset = [
                        SELECT
                        Id,
                        Name,
                        ParentId,
                        ECSS_Unit_Type__c,
                        ECSS_Project__c,
                        Parent.ECSS_Project__c,
                        ECSS_Project__r.Name,
                        Parent.ECSS_Project__r.Name,
                        Description,
                        Parent.ECSS_Building_Section__c,
                        ECSS_Building_Section__c,
                        Parent.ECSS_Building_Section__r.Name,
                        ECSS_Building_Section__r.Name,
                        ECSS_Unit_Code__c,
                        Parent.ECSS_Zone__c,RecordTypeName__c,
                        Parent.ECSS_Zone__r.Name,
                        ECSS_Zone__c,
                        ECSS_Zone__r.Name,Is_PropEzzy__c
                        FROM Asset
                        WHERE
                        Is_PropEzzy__c = False AND 
                        (ECSS_Unit_Code__c LIKE :likePattern
                         OR Name LIKE :likePattern) and RecordType.Name =: recordTypeName
                        Order by RecordTypeName__c desc
                        LIMIT 10000
                    ];
                }
                else{
                    if(buildingValue !='0' || projectValue !='0' || buildingValue != '0'){
                        String baseQuery = 'SELECT Id, Name, ParentId, ECSS_Unit_Type__c, ECSS_Project__c, Parent.ECSS_Project__c, ' +
                            'ECSS_Project__r.Name, Parent.ECSS_Project__r.Name, Description, Parent.ECSS_Building_Section__c, ' +
                            'ECSS_Building_Section__c, Parent.ECSS_Building_Section__r.Name, ECSS_Building_Section__r.Name, ' +
                            'ECSS_Unit_Code__c, Parent.ECSS_Zone__c, Parent.ECSS_Zone__r.Name, ECSS_Zone__c, ' +
                            'RecordTypeName__c, ECSS_Zone__r.Name,Is_PropEzzy__c FROM Asset WHERE Is_PropEzzy__c = False AND RecordType.Name =\''+recordTypeName+ '\' ';
                        
                        List<String> conditions = new List<String>();
                        //baseQuery += 'and '+ fieldName+'=: '+fieldaSearch;
                        if(buildingValue != '0'){
                            String tmp = '(Parent.ECSS_Building_Section__c =\''+ buildingValue+ '\' OR ECSS_Building_Section__c =\'' +buildingValue +'\')' ;
                            conditions.add(tmp);
                        }
                        if(projectValue != '0'){
                            String tmp = '(Parent.ECSS_Project__c =\''+ projectValue+ '\' OR ECSS_Project__c =\'' +projectValue +'\')' ;
                            conditions.add(tmp);
                        } 
                        if(zoneValue != '0'){
                            String tmp = '(Parent.ECSS_Project__c =\''+ zoneValue+ '\' OR ECSS_Project__c =\'' +zoneValue +'\')' ;
                            conditions.add(tmp);
                        }                        
                        
                        
                        if (!conditions.isEmpty()) {
                            //baseQuery += ' WHERE ' + String.join(conditions, ' AND ');
                            baseQuery += ' AND ' + String.join(conditions, ' AND ');
                        } 
                        
                        baseQuery += ' ORDER BY RecordTypeName__c DESC ';
                        System.debug('baseQuery:'+baseQuery);
                        
                        loopAsset = Database.query(baseQuery);
                        System.debug('results:'+loopAsset);
                    }
                    else{
                        System.debug('in the elsee');
                        loopAsset = [
                            SELECT
                            Id,
                            Name,
                            ParentId,
                            ECSS_Unit_Type__c,
                            ECSS_Project__c,
                            Parent.ECSS_Project__c,
                            ECSS_Project__r.Name,
                            Parent.ECSS_Project__r.Name,
                            Description,
                            Parent.ECSS_Building_Section__c,
                            ECSS_Building_Section__c,
                            Parent.ECSS_Building_Section__r.Name,
                            ECSS_Building_Section__r.Name,
                            ECSS_Unit_Code__c,
                            Parent.ECSS_Zone__c,
                            Parent.ECSS_Zone__r.Name,
                            ECSS_Zone__c,RecordTypeName__c,
                            ECSS_Zone__r.Name
                            FROM Asset
                            WHERE
                            Is_PropEzzy__c = False AND 
                            (Parent.ECSS_Building_Section__c != NULL
                             OR ECSS_Building_Section__c != NULL
                             OR Parent.ECSS_Project__c != NULL
                             OR ECSS_Project__c != NULL) and RecordType.Name =: recordTypeName Order by RecordTypeName__c desc limit 20000
                        ];
                    }
                }
                Map<Id, Asset> assetMap = new Map<Id, Asset>(loopAsset);
                Set<Id> assetIds = assetMap.keySet();
				List<FM_Companies__c> compList = [select id,Unit__c,Company_Name__c from FM_Companies__c where Unit__c in: assetIds]; 
                Map<String,String> assetCompMap = new Map<String,String>();
                for(FM_Companies__c currComp : compList){
                    String tmp;
                    if(assetCompMap.get(currComp.Unit__c) != null){
                        tmp = assetCompMap.get(currComp.Unit__c) ;
                        tmp+= ';'+currComp.Company_Name__c;
                        assetCompMap.put(currComp.Unit__c,tmp);
                    }
                    else{
                        tmp = currComp.Company_Name__c;
                        assetCompMap.put(currComp.Unit__c,tmp);
                    }
                }
                Set<String> unitsDisplayed = new Set<String>();
                for (Asset cUnit : loopAsset) {
                    if(!(parentIdsExcluded.size()>0 && parentIdsExcluded.contains(cUnit.Id))){
                        if(cUnit.ParentId !=null){
                            //parentIdsExcluded.add(cUnit.ParentId);
                            flToCheck.add(cUnit.Id);
                            /* if(unitsDisplayed.size()>0 && unitsDisplayed.contains(cUnit.ParentId) &&  custWrapperMap.get(cUnit.ParentId)!= null){
custWrapperMap.remove(cUnit.ParentId);
System.debug('in inner conditon');
}*/
                            
                        }
                        System.debug('after the conditiond for parent');
                        unitsDisplayed.add(cUnit.Id);
                        if(!unitCodes.contains(cUnit.ECSS_Unit_Code__c) ){
                            unitCodes.add(cUnit.ECSS_Unit_Code__c);
                            CustomerUnitWrapper cuw = new CustomerUnitWrapper();
                            cuw.unitId = cUnit.Id;
                            cuw.unitName = cUnit.Name;
                            cuw.projectName = cUnit.ECSS_Project__r.Name;
                            cuw.unitType = cUnit.ECSS_Unit_Type__c;
                            cuw.compoptions = assetCompMap.get(cUnit.Id);
                            if (cUnit.ECSS_Project__c != null) {
                                System.debug('in the if');
                                cuw.projectId = cUnit.ECSS_Project__c;
                            } else {
                                cuw.projectId = cUnit.Parent.ECSS_Project__c;
                            }
                            if (
                                cUnit.ECSS_Building_Section__r.Name != '' &&
                                cUnit.ECSS_Building_Section__r.Name != null
                            )
                                cuw.buildingName = cUnit.ECSS_Building_Section__r.Name;
                            else
                                cuw.buildingName = cUnit.Parent.ECSS_Building_Section__r.Name;
                            if (cUnit.ECSS_Building_Section__c != null)
                                cuW.buildingId = cUnit.ECSS_Building_Section__c;
                            else
                                cuW.buildingId = cUnit.Parent.ECSS_Building_Section__c;
                            if (cUnit.ECSS_Zone__r.Name != '' && cUnit.ECSS_Zone__r.Name != null)
                                cuw.zoneName = cUnit.ECSS_Zone__r.Name;
                            else
                                cuw.zoneName = cUnit.Parent.ECSS_Zone__r.Name;
                            if (cUnit.ECSS_Zone__c != null)
                                cuW.zoneId = cUnit.ECSS_Zone__c;
                            else
                                cuW.zoneId = cUnit.Parent.ECSS_Zone__c;
                            
                            cuW.unitCode = cUnit.ECSS_Unit_Code__c;
                            cuW.description = cUnit.Description;
                            System.debug('Desc:' + cuW.description);
                            customerUnitWrapperList.add(cuw);
                            custWrapperMap.put(cUnit.Id,cuw);
                        }
                    }
                }
                Integer unitconLimit =Integer.valueOf(System.label.Unit_Contract_Limit);
                List<Unit_Contract__c> contrUnitList = [SELECT Id,ECSS_Unit__c,ECSS_Unit__r.ParentId FROM Unit_Contract__c where ECSS_Unit__c in: flToCheck LIMIT :unitconLimit];
                for(Unit_Contract__c currUnitContract : contrUnitList){
                    if(custWrapperMap.get(currUnitContract.ECSS_Unit__r.ParentId) != null){
                        custWrapperMap.remove(currUnitContract.ECSS_Unit__r.ParentId);
                        parentIdsExcluded.add(currUnitContract.ECSS_Unit__r.ParentId);
                    }
                    
                }
                
                System.debug('finalMap:'+custWrapperMap);
                customerUnitWrapperList = custWrapperMap.values();
            }
        } catch (exception e) {
            return customerUnitWrapperList;
        }
        return customerUnitWrapperList;
    }
    public class CustomerUnitWrapper {
        @AuraEnabled
        public string unitId;
        
        @AuraEnabled
        public string unitName;
        
        @AuraEnabled
        public string unitType;
        
        @AuraEnabled
        public string projectName;
        
        @AuraEnabled
        public string projectId;
        
        @AuraEnabled
        public string buildingName;
        
        @AuraEnabled
        public string buildingId;
        
        @AuraEnabled
        public string zoneName;
        
        @AuraEnabled
        public string zoneId;
        
        @AuraEnabled
        public string customerUnitId;
        
        @AuraEnabled
        public string unitCode;
        
        @AuraEnabled
        public string description;
        
        @AuraEnabled
        public string customerType;
        
        @AuraEnabled
        public String compoptions;
    }
    public class inventoryWrapper {
        @AuraEnabled
        public List<PickValsWrapper> buildingVals {get;set;}
        @AuraEnabled
        public List<PickValsWrapper> projectVals {get;set;}
        @AuraEnabled
        public List<PickValsWrapper> zoneVals {get;set;}
        
    }
    public class PickValsWrapper {
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public String value { get; set; }
        @AuraEnabled
        public String projectId {get; set;}
        @AuraEnabled
        public String zoneId {get; set;}
        
        
        public PickValsWrapper(String label, String value) {
            this.label = label;
            this.value = value;
        }
        public PickValsWrapper() {
        }
    }
    
    public class CompanysWrapper {
        @AuraEnabled
        public String Name { get; set; }
        @AuraEnabled
        public String Idval { get; set; }
        
        public CompanysWrapper(String Name, String Idval) {
            this.Name = Name;
            this.Idval = Idval;
        }
    }
    public class ContactWrapper {
        @AuraEnabled
        public String Name { get; set; }
        @AuraEnabled
        public String Idval { get; set; }
        @AuraEnabled
        public Boolean isPerson { get; set; }
        
        public ContactWrapper(String Name, String Idval, Boolean isPerson) {
            this.Name = Name;
            this.Idval = Idval;
            this.isPerson = isPerson;
        }
    }
    public class CompanyWrapper {
        @AuraEnabled
        public string companyId;
        
        @AuraEnabled
        public string companyName;
        
        @AuraEnabled
        public boolean isEltizamCompany;
    }
    public class accountWrapper {
        @AuraEnabled
        public string accountId;
        @AuraEnabled
        public Account accountRec;
    }
    public class ListWrapper {
        @AuraEnabled
        public string valName;
        @AuraEnabled
        public string labelName;
    }
    public class derivedValues {
        @AuraEnabled
        public string categoryName;
        @AuraEnabled
        public string objectCatName;
    }
    public class ContractWrapper {
        @AuraEnabled
        public List<Contract> activeContractsWithRemaining;
        
        @AuraEnabled
        public List<Contract> activeContractsWORemaining;
        @AuraEnabled
        public List<Contract> activeContractsNoDetails;
    }
   
    


}