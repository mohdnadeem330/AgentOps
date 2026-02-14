public class EDDSService {

    public enum JOURNEY_TYPE { NewSale, OffPlanTransfer, NewLeasing, Retail, Education }
    public enum TRANSACTION_TYPE { NewRegistration,Cancellation }

    public static Map<String,ParamsWrapper> getDDParams(String relatedRecordId, List<String> accountIds, String journeyType) {
        Map<String,ParamsWrapper> responseMap = new Map<String,ParamsWrapper>();
        if(journeyType == JOURNEY_TYPE.NewSale.name() || journeyType == JOURNEY_TYPE.OffPlanTransfer.name()) {
            List<SalesOrder__c> salesOrderList = [SELECT Id, Name, Unit__r.Project__r.DirectDebitApplied__c,Unit__r.ExpectedCustomerHandoverDate__c,Unit__r.Name,Unit__r.Project__r.BankNameEscrow__c,Unit__r.BuildingSectionName__r.BankNameEscrow__c,
                                                    Unit__r.Project__r.DirectDebitOIC__c,Unit__r.Project__r.EDirectDebitOIC__c,
                                                                        (SELECT ID,InstallmentNumber__c, 
                                                                        InstallmentAmount__c,InstallmentDate__c 
                                                                        FROM InstallmentLines__r 
                                                                        ORDER BY InstallmentNumber__c ASC )
                                                    FROM SalesOrder__c 
                                                    WHERE Id =: relatedRecordId 
                                                    LIMIT 1];
            List<Account> payerAccounts = [SELECT IsPersonAccount,Name,PersonEmail,Email__c,PersonMobilePhone,PersonContact.MobilePhone__c,MobileNumber1__c,MobileCountryCode__c,
                                                    NationalIdNumber__pc, PassportNumber__pc, RegistrationNumber__c
                                                    FROM Account
                                                    WHERE Id IN :accountIds];

            
            Map<String, DirectdebitDefaultvalues__mdt> allDDValues 	= new Map<String, DirectdebitDefaultvalues__mdt>();
            allDDValues = DirectDebitService.getDirectDebitDefaultValues();

            if(!salesOrderList.isEmpty()) {
                ParamsWrapper params = null;
                String EscrowDirectDebitBank    =   salesOrderList[0].Unit__r.BuildingSectionName__r.BankNameEscrow__c!=null?salesOrderList[0].Unit__r.BuildingSectionName__r.BankNameEscrow__c:salesOrderList[0].Unit__r.Project__r.BankNameEscrow__c;
                Date expiresOnDate = salesOrderList[0].Unit__r.ExpectedCustomerHandoverDate__c!=null?salesOrderList[0].Unit__r.ExpectedCustomerHandoverDate__c.addYears(1):null;
                String expiresOnStr = expiresOnDate!=null?DateTime.newInstance(expiresOnDate.year(), expiresOnDate.month(), expiresOnDate.day()).format('dd/MM/yyyy'):'';
                String ddaReferenceNumberStr = (String.valueOf(Datetime.now().getTime())+salesOrderList[0].Name.remove('#')).right(26);
                String commencesOnStr = System.now().format('dd/MM/yyyy');
                String amountTypeStr = allDDValues.containsKey(EscrowDirectDebitBank)?allDDValues.get(EscrowDirectDebitBank).AmountType__c:'Variable';
                String paymentFrequencyStr = allDDValues.containsKey(EscrowDirectDebitBank)?allDDValues.get(EscrowDirectDebitBank).PaymentFrequency__c:'Monthly';
                Decimal min = allDDValues.containsKey(EscrowDirectDebitBank)?allDDValues.get(EscrowDirectDebitBank).MinimumAmount__c:0;
                Decimal max = salesOrderList[0].InstallmentLines__r.size()>1?getMaximumAmount(salesOrderList[0].InstallmentLines__r):10;
                String mobileNumber = '';
                for(Account payer : payerAccounts) {
                    mobileNumber = payer.IsPersonAccount?payer.PersonContact.MobilePhone__c:payer.MobileNumber1__c;
                    if(mobileNumber?.length() == 10 && mobileNumber?.startsWith('0')){
                        mobileNumber = mobileNumber;
                    } else if(mobileNumber?.length() == 9){
                        mobileNumber = '0' + mobileNumber;
                    }
                    params = new ParamsWrapper();
                    params.ddaReferenceNumber = ddaReferenceNumberStr;
                    params.amountType = amountTypeStr;
                    params.paymentFrequency = paymentFrequencyStr;
                    params.commencesOn = commencesOnStr;
                    params.expiresOn = expiresOnStr;
                    params.minAmount = min;
                    params.maxAmount = max;
                    params.customerType = payer.IsPersonAccount?'Individual':'Non-Individual';
                    params.customerIdType = payer.IsPersonAccount?(payer.NationalIdNumber__pc!=null?'UAE Emirates Identity Card':(payer.PassportNumber__pc!=null?'Passport':'')):'Trade Licence Number';
                    params.customerIdNumber = payer.IsPersonAccount?(payer.NationalIdNumber__pc!=null?payer.NationalIdNumber__pc:(payer.PassportNumber__pc!=null?payer.PassportNumber__pc:'')):payer.RegistrationNumber__c;
                    params.customerEmail = payer.IsPersonAccount?payer.PersonEmail:payer.Email__c;
                    params.customerMobileNumber = mobileNumber;
                    params.OICCode = salesOrderList[0]?.Unit__r?.Project__r?.EDirectDebitOIC__c;
                    responseMap.put(payer.Id,params);
                }
            }
        }else if(journeyType == JOURNEY_TYPE.NewLeasing.name()) {
            //TODO
        }else if(journeyType == JOURNEY_TYPE.Retail.name()) {
            //TODO
        }
        return responseMap;
    }

    public static Double getMaximumAmount(List<InstallmentLines__c> installmentLinesList){
        try{
            Double finalAmount = 0;
            if(installmentLinesList.size() > 1){
                installmentLinesList.remove(0);
                
                if(Label.DDPaymentConsiderHandover == 'false' ){
                    installmentLinesList.remove(installmentLinesList.size() -1);
                }
                
                for (InstallmentLines__c singleIL : installmentLinesList){
                    if(finalAmount < singleIL.InstallmentAmount__c){
                        finalAmount = singleIL.InstallmentAmount__c;
                    }
                }
            }
            return finalAmount;
        }
        catch(exception ex){
            LoggerService.save(LoggerService.createApexLog(ex,'EDDSGetDDParamsWebService','EDDSService','getMaximumAmount'));
            return null;
        }
    }

    public static EligibilityAndAccountWrapper getEligibilityAndAccount(String relatedRecordId, String customerAccountId, String journeyType) {
        EligibilityAndAccountWrapper responseWrapper = new EligibilityAndAccountWrapper();
        
        String queryString = '';
        
        if(journeyType == JOURNEY_TYPE.NewSale.name() || journeyType == JOURNEY_TYPE.OffPlanTransfer.name()) {
            queryString = 'SELECT Id, Name, Unit__r.Project__r.DirectDebitApplied__c,Unit__r.Project__r.DirectDebitOIC__c,Unit__r.Project__r.EDirectDebitApplied__c,Unit__r.Project__r.EDirectDebitOIC__c,Account__r.IsPersonAccount,Account__r.Name,'+
                            'Account__r.NationalIdNumber__pc, Account__r.PassportNumber__pc, Account__r.RegistrationNumber__c '+ 
                            ',(SELECT Id, Status__c FROM Direct_Debit_Request__r WHERE Status__c NOT IN (\'Cancellation in progress\',\'Cancelled\',\'Cancellation Sent to Bank\',\'Rejected by Bank\'))'+
                            ' FROM SalesOrder__c WHERE Id =: relatedRecordId';
            queryString +=  journeyType == JOURNEY_TYPE.NewSale.name()?' AND Account__c =: customerAccountId LIMIT 1':' LIMIT 1'; 
            
            List<SalesOrder__c> eligibilityList = Database.query(queryString);
            //1. Get Eligibility
            if(!eligibilityList.isEmpty()) {
                responseWrapper.EligibleForDD = (eligibilityList[0].Unit__r.Project__r.EDirectDebitApplied__c && eligibilityList[0].Unit__r.Project__r.EDirectDebitOIC__c!=null) && (eligibilityList[0].Direct_Debit_Request__r == null || eligibilityList[0].Direct_Debit_Request__r.isEmpty());
                if(!responseWrapper.EligibleForDD){
                    responseWrapper.ReasonCode = (!eligibilityList[0].Unit__r.Project__r.EDirectDebitApplied__c || eligibilityList[0].Unit__r.Project__r.EDirectDebitOIC__c==null)?'NotEligible':'ExistingDirectDebit';
                }
                responseWrapper.OICCode = eligibilityList[0]?.Unit__r?.Project__r?.EDirectDebitOIC__c;
            }
            //2. Get Payer Accounts
            //Add Primary Account details to wrapper
            List<Account> primaryAccount = [SELECT Id,Name,IsPersonAccount,NationalIdNumber__pc,PassportNumber__pc,RegistrationNumber__c,KYC_Validity_Status__c,KYC_ValidityDate__c,KYC_Expired_Date__c FROM Account WHERE ID =:customerAccountId LIMIT 1];
            if(!primaryAccount.isEmpty()) {
                //Add Primary Account details to wrapper
                PayerAccount pa = new PayerAccount();
                pa.Id = primaryAccount[0].Id;
                pa.Name = primaryAccount[0].Name;
                pa.customerIDType = primaryAccount[0].IsPersonAccount?(primaryAccount[0].NationalIdNumber__pc!=null?'UAE Emirates Identity Card':(primaryAccount[0].PassportNumber__pc != null ? 'Passport' :'')):'Trade Licence Number';
                pa.customerID = primaryAccount[0].IsPersonAccount?(primaryAccount[0].NationalIdNumber__pc!=null?primaryAccount[0].NationalIdNumber__pc:(primaryAccount[0].PassportNumber__pc!=null?primaryAccount[0].PassportNumber__pc:'')):primaryAccount[0].RegistrationNumber__c;
                pa.isPrimaryBuyer = true;
                pa.kycValidityStatus = primaryAccount[0].KYC_Validity_Status__c;
                pa.kycValidatedDate = primaryAccount[0].KYC_ValidityDate__c!=null?DateTime.newInstance(primaryAccount[0].KYC_ValidityDate__c?.year(), primaryAccount[0].KYC_ValidityDate__c?.month(), primaryAccount[0].KYC_ValidityDate__c?.day(), 0, 0, 0).format('dd/MM/yyyy'):null;
                pa.kycExpiryDate = primaryAccount[0].KYC_Expired_Date__c!=null?DateTime.newInstance(primaryAccount[0].KYC_Expired_Date__c?.year(), primaryAccount[0].KYC_Expired_Date__c?.month(), primaryAccount[0].KYC_Expired_Date__c?.day(), 0, 0, 0).format('dd/MM/yyyy'):null;
                responseWrapper.PayerAccounts.add(pa);
            }
            
            //Query Related Accounts
            List<AccountRelationship__c> accRelationships = [SELECT Id ,RelatedAccount__c,RelatedAccount__r.Name,RelatedAccount__r.NationalIdNumber__pc, 
                                                            RelatedAccount__r.IsPersonAccount, RelatedAccount__r.PassportNumber__pc, RelatedAccount__r.RegistrationNumber__c,
                                                            RelatedAccount__r.KYC_Validity_Status__c,RelatedAccount__r.KYC_ValidityDate__c,RelatedAccount__r.KYC_Expired_Date__c 
                                                            FROM AccountRelationship__c WHERE Account__c =: customerAccountId];

            if(!accRelationships.isEmpty()) {
                for(AccountRelationship__c ar : accRelationships) {
                    PayerAccount paWrapper = new PayerAccount();
                    paWrapper.Id = ar.RelatedAccount__c;
                    paWrapper.Name = ar.RelatedAccount__r.Name;
                    paWrapper.customerIDType = ar.RelatedAccount__r.IsPersonAccount?(ar.RelatedAccount__r.NationalIdNumber__pc!=null?'UAE Emirates Identity Card':(ar.RelatedAccount__r.PassportNumber__pc != null ? 'Passport' :'')):'Trade Licence Number';
                    paWrapper.customerID = ar.RelatedAccount__r.IsPersonAccount?(ar.RelatedAccount__r.NationalIdNumber__pc!=null?ar.RelatedAccount__r.NationalIdNumber__pc:(ar.RelatedAccount__r.PassportNumber__pc!=null?ar.RelatedAccount__r.PassportNumber__pc:'')):ar.RelatedAccount__r.RegistrationNumber__c;
                    paWrapper.isPrimaryBuyer = false;
                    paWrapper.kycValidityStatus = ar.RelatedAccount__r.KYC_Validity_Status__c;
                    paWrapper.kycValidatedDate = ar.RelatedAccount__r.KYC_ValidityDate__c!=null?DateTime.newInstance(ar.RelatedAccount__r.KYC_ValidityDate__c?.year(), ar.RelatedAccount__r.KYC_ValidityDate__c?.month(), ar.RelatedAccount__r.KYC_ValidityDate__c?.day(), 0, 0, 0).format('dd/MM/yyyy'):null;
                    paWrapper.kycExpiryDate = ar.RelatedAccount__r.KYC_Expired_Date__c!=null?DateTime.newInstance(ar.RelatedAccount__r.KYC_Expired_Date__c?.year(), ar.RelatedAccount__r.KYC_Expired_Date__c?.month(), ar.RelatedAccount__r.KYC_Expired_Date__c?.day(), 0, 0, 0).format('dd/MM/yyyy'):null;
                    responseWrapper.PayerAccounts.add(paWrapper);
                }
            }
        }else if(journeyType == JOURNEY_TYPE.NewLeasing.name()) {
            //TODO
        }else if(journeyType == JOURNEY_TYPE.Retail.name()) {
            //TODO
        }

        return responseWrapper;
    }


    public static List<DirectDebitRequest__c> getDirectDebits(String relatedRecordId, String customerAccountId, String journeyType) {        
        String queryString = '';
        
        if(journeyType == JOURNEY_TYPE.NewSale.name() || journeyType == JOURNEY_TYPE.OffPlanTransfer.name()) {
            queryString = 'SELECT Id, Name, Status__c,PayerIdentification__c,UnitNumber__c,DDAreferencenumber__c,EDDS_DDAID__c,EDDS_DDARID__c,EDDS_DDA_Reference_Number__c,CustomerIBANNumber__c,CancellationReason__c,CommencesOn__c,CreatedDate'+
                            ',Account__r.Name,PayerAccount__r.Name,ExpiresOn__c,MinimumAmount__c,MaximumAmount__c,Rejection_Reason__c,Remarks__c,SalesOrder__c,Account__c,PayerAccount__c,Is_EDDS__c,CustomerAccountName__c,CustomerBankAccountType__c,CustomerBankName__c,CustomerIDNumber__c,CustomerIDTypeandNumber__c '+
                            ',SalesOrder__r.Unit__r.Project__r.DirectDebitOIC__c,SalesOrder__r.Unit__r.Project__r.EDirectDebitOIC__c,OIC__c '+
                            ' FROM DirectDebitRequest__c WHERE SalesOrder__c =: relatedRecordId AND Is_EDDS__c = TRUE AND Account__c =: customerAccountId'; 
        }else if(journeyType == JOURNEY_TYPE.NewLeasing.name()) {
            //TODO
        }else if(journeyType == JOURNEY_TYPE.Retail.name()) {
            //TODO
        }

        List<DirectDebitRequest__c> ddList = Database.query(queryString);
        
        return ddList;
    }

    public static Boolean isValidSalesforceId(String idValue, String sObjectAPIName) {
        if (idValue == null || idValue.trim()=='') {
            return false;
        }
        try {
            Id sObjectRecordId = (Id)idValue;
            if(sObjectRecordId.getSObjectType().getDescribe().getName()!=sObjectAPIName) {
                return false;
            }else{
                String queryStr = 'SELECT Id FROM ' + sObjectAPIName + ' WHERE Id = :sObjectRecordId LIMIT 1';
                List<SObject> records = Database.query(queryStr);
                if(records.isEmpty()) {
                    return false;
                }
            }
            return true;
        } catch (System.StringException e) {
            System.debug('Invalid Salesforce ID format: ' + idValue + ' - ' + e.getMessage());
            return false;
        } catch (Exception e) {
            System.debug('An unexpected error occurred during ID validation: ' + e.getMessage());
            return false;
        }
    }

    public static Boolean isValidSalesforceIds(List<String> idValues, String sObjectAPIName) {
        if (idValues == null || idValues.isEmpty()) {
            return false;
        }
        Set<Id> validIdSet = new Set<Id>();
        List<String> invalidIdList = new List<String>();

        for(String idValue : idValues) {
            try {
                validIdSet.add((Id)idValue);
            } catch (System.StringException e) {
                System.debug('Invalid Salesforce ID format: ' + idValue + ' - ' + e.getMessage());
                invalidIdList.add(idValue);
            } catch (Exception e) {
                System.debug('An unexpected error occurred during ID validation: ' + e.getMessage());
                invalidIdList.add(idValue);
            } 
        }
        if(!invalidIdList.isEmpty()) {
            return false;
        }else{
            String queryStr = 'SELECT Id FROM ' + sObjectAPIName + ' WHERE Id IN :validIdSet';
            Map<Id,SObject> sobjectMap = new Map<Id,SObject>(Database.query(queryStr));
            if(sobjectMap.size() != validIdSet.size()) {
                return false;
            }
        }
        return true;
    }

    public static Boolean isValueInPicklist(String objectApiName, String fieldApiName, String valueToCheck) {
        if(valueToCheck==null || valueToCheck.trim()==''){
            return false;
        }
        // Get the SObject type
        Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objectApiName);
        if (sObjType == null) {
            System.debug('Object ' + objectApiName + ' not found.');
            return false;
        }

        // Get the SObject field
        Schema.DescribeSObjectResult sObjDescribe = sObjType.getDescribe();
        Schema.SObjectField field = sObjDescribe.fields.getMap().get(fieldApiName);
        if (field == null) {
            System.debug('Field ' + fieldApiName + ' not found on object ' + objectApiName + '.');
            return false;
        }

        // Describe the picklist field
        Schema.DescribeFieldResult fieldDetail = field.getDescribe();

        // Check if it's actually a picklist or multi-select picklist
        if (!fieldDetail.getType().equals(Schema.DisplayType.Picklist) && !fieldDetail.getType().equals(Schema.DisplayType.MultiPicklist)) {
            System.debug(fieldApiName + ' is not a picklist field.');
            return false;
        }

        // Get all picklist values
        List<Schema.PicklistEntry> picklistEntries = fieldDetail.getPicklistValues();

        // Create a Set of picklist values for efficient lookup
        Set<String> validValues = new Set<String>();
        for (Schema.PicklistEntry entry : picklistEntries) {
            if (entry.isActive()) {
                validValues.add(entry.getValue());
            }
        }

        // Check if the value exists in the set of valid picklist values
        return validValues.contains(valueToCheck);
    }

    public static Boolean isValidJourneyType(String enumValue){
        Set<String> enumNameSet = new Set<String>();
        for(JOURNEY_TYPE v : JOURNEY_TYPE.values()){
            enumNameSet.add(v.name());
        }
        return enumNameSet.contains(enumValue);
    }

    public static Boolean isValidTransactionType(String enumValue){
        Set<String> enumNameSet = new Set<String>();
        for(TRANSACTION_TYPE v : TRANSACTION_TYPE.values()){
            enumNameSet.add(v.name());
        }
        return enumNameSet.contains(enumValue);
    }

    public static List<DirectDebitRequest__c> getDirectDebitByIdSet(Set<Id> directDebitIds){
        List<DirectDebitRequest__c> ddRecords;
        try{
            ddRecords = [SELECT Id, Name, Status__c,PayerIdentification__c,UnitNumber__c,DDAreferencenumber__c,EDDS_DDAID__c,EDDS_DDARID__c,EDDS_DDA_Reference_Number__c,CustomerIBANNumber__c,CancellationReason__c,CommencesOn__c,CreatedDate,
                            Account__r.Name,PayerAccount__r.Name,ExpiresOn__c,MinimumAmount__c,MaximumAmount__c,Rejection_Reason__c,Remarks__c,SalesOrder__c,Account__c,PayerAccount__c,OIC__c,CustomerAccountName__c,CustomerBankAccountType__c,CustomerBankName__c,CustomerIDNumber__c,CustomerIDTypeandNumber__c 
                            FROM DirectDebitRequest__c WHERE Id IN: directDebitIds ];
        }
        catch(Exception ex){
            LoggerService.save(LoggerService.createApexLog(ex,'EDDSGetDDParamsWebService','EDDSService','getDirectDebitById'));
            ddRecords = null;
        }
        return ddRecords;
    }

    /*Wrappers*/
    public class EligibilityAndAccountWrapper {
        public Boolean EligibleForDD {get; set;}
        public String ReasonCode {get; set;}
        public String OICCode {get; set;}
        public List<PayerAccount>  PayerAccounts {get; set;}
        
        public EligibilityAndAccountWrapper() {
            this.EligibleForDD = false;
            this.ReasonCode = null;
            this.OICCode = null;
            this.PayerAccounts = new List<PayerAccount>();
        }
    }
    
    public class PayerAccount {
        public String Id {get; set;}
        public String Name {get; set;}
        public String customerIDType {get; set;}
        public String customerID {get; set;}
        public Boolean isPrimaryBuyer {get; set;}
        public String kycValidityStatus {get; set;}
        public String kycValidatedDate {get; set;}
        public String kycExpiryDate {get; set;}
    }

    public class ParamsWrapper {
        public String customerType {get; set;}
        public String customerIdType {get; set;}
        public String customerIdNumber {get; set;}
        public String customerMobileNumber {get; set;}
        public String customerEmail {get; set;}
        public String ddaReferenceNumber {get; set;}
        public String commencesOn {get; set;}
        public String expiresOn {get; set;}
        public String amountType {get; set;}
        public String paymentFrequency {get; set;}
        public Decimal minAmount {get; set;}
        public Decimal maxAmount {get; set;}
        public String OICCode {get; set;}
    }


}