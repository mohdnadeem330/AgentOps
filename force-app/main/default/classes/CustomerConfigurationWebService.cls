/*
* Name               : CustomerConfigurationWebService
* Description        : This class is used to get Configuration such as Date, Datetime formate and Dropdown values
*/
@RestResource (urlMapping = '/customer/configurations')
global without sharing class CustomerConfigurationWebService {
    
    @HttpPost
    global static void doPost() {
        
        RestContextHandler handler = new RestContextHandler(true);
        try {
            RestRequest req = RestContext.request;
            handler.response.data = getConfigurations();
            handler.response.success = true;
            handler.finalize();
        } catch(Exception ex){
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);
        }
    }
    
    global static ConfigurationsModel getConfigurations() {
        
        Map<String, MobileAppStatus__mdt> mobileAppMap = Utilities.getMobileAppColorCode();
        
        ConfigurationsModel response = new ConfigurationsModel();
        getFormatters(response);
        // getCurrencyConversation(response);
        getAccountPicklistValues(response);
        getCountryStatePicklistValues(response);
        getReceiptPicklistValues(response);
        getDocumentTypes(response);
        getDescriptions(response);
        getListingCharges(response);
        getCasePicklistValues(response);
        getprojectpicklistValues(response);
        getRelationshipPicklistValues(response);
        // getSRCatalog(response);
        
        return response;
    }
    global static void getRelationshipPicklistValues(ConfigurationsModel response){
        List<String> types = new List<String>{'AccountRelationship__c'};
        Schema.DescribeSobjectResult[] result = Schema.describeSObjects(types);
        Map<String, Schema.SObjectField> fieldsMap = result[0].fields.getMap();
        List<String> fieldAPIs = new List<String>{
            'RelationshipSubType__c'
        };
        for(String fieldAPI : fieldAPIs) {
            
            Schema.DescribeFieldResult fieldResult = fieldsMap.get(fieldAPI).getDescribe();
            List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
            
            List<String> entries = new List<String>();
            
            for (Integer i = 0; i < picklistEntries.size(); i++){
                Schema.PicklistEntry entry = picklistEntries[i];
                entries.add(entry.value);
            }  
            
            switch on fieldAPI {
                when 'RelationshipSubType__c'{
                    response.relartionshipSubType = entries;
                }
            }
        }    
    
    }
    global static void getprojectpicklistValues(ConfigurationsModel response){
        List<String> entries = new List<String>();
        
        Map<String,List<String>> fieldMap =Utilities.getDependentPickListValues('Lead','PropertyUsage__c','Project__c');
        for(String str : fieldMap.get('Residential Sale')){
            entries.add(str);
        }
        entries.sort();
        response.project = entries;
    }
    
    global static void getAccountPicklistValues(ConfigurationsModel response) {
        
        List<String> types = new List<String>{'Account'};
            Schema.DescribeSobjectResult[] result = Schema.describeSObjects(types);
        Map<String, Schema.SObjectField> fieldsMap = result[0].fields.getMap();
        
        List<String> fieldAPIs = new List<String>{
            'ResidentStatus__pc',
            'MobileCountryCode__c',
            'Nationality__pc',
            'EmploymentStatus__pc',
            'Gender__pc',
            'MaritalStatus__pc',
            'Salutation',
            'SourceofFunds__pc',
            'VisaType__c',   
            'ResidentialAddressSameAsPermanent__c',
            'Industry',
            'Other_Source_of_Funds__pc',
            'Number_of_Kids__pc',
            'CountryofBirth__pc',
            'Passport_type__pc',
            'Interested_in_Cryptocurrency__pc'
        };
        
        for(String fieldAPI : fieldAPIs) {
            
            Schema.DescribeFieldResult fieldResult = fieldsMap.get(fieldAPI).getDescribe();
            List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
            
            if (fieldAPI == 'MobileCountryCode__c') {
                List<Map<String,String>> entries = new List<Map<String,String>>();
                
                for (Integer i = 0; i < picklistEntries.size(); i++){
                    Schema.PicklistEntry entry = picklistEntries[i];
                    Map<String,String> picklistEntrie = new Map<String,String>();
                    picklistEntrie.put('label', entry.label);
                    picklistEntrie.put('value', entry.value);
                    entries.add(picklistEntrie);
                }
                
                response.mobileCountryCode = entries;
            } else {
                List<String> entries = new List<String>();
                
                for (Integer i = 0; i < picklistEntries.size(); i++){
                    Schema.PicklistEntry entry = picklistEntries[i];
                    if(fieldAPI =='VisaType__c' && entry.value =='Company Booking'){
                        continue;
                    }
                    entries.add(entry.value);
                }
                
                switch on fieldAPI {
                    when 'ResidentStatus__pc'{
                        response.residentStatus = entries;
                    }
                    when 'Nationality__pc'{
                        response.nationality = entries;
                    }
                    when 'EmploymentStatus__pc'{
                        response.employmentStatus = entries;
                    }
                    when 'Gender__pc'{
                        response.gender = entries;
                    }
                    when 'MaritalStatus__pc'{
                        response.maritalStatus = entries;
                    }
                    when 'Salutation'{
                        response.salutation = entries;
                    }
                    when 'SourceofFunds__pc'{
                        response.sourceofFunds = entries;
                    }
                    when 'ResidentialAddressSameAsPermanent__c'{
                        response.residentSameAsPermanent = entries;
                    }
                    when 'Industry'{
                        response.industry = entries;
                    }
                    when 'VisaType__c' {
                    	response.visaTypes = entries;
                	}
                    when 'Other_Source_of_Funds__pc' {
                        response.otherSourceOfFunds = entries;
                    }
                    when 'Number_of_Kids__pc' {
                        response.numberOfKids = entries;
                    }
                    when 'CountryofBirth__pc' {
                        response.countryofBirth = entries;
                    }
                    when 'Passport_type__pc' {
                        response.passportType = entries;
                    }
                    when 'Interested_in_Cryptocurrency__pc' {
                        response.interestedInCryptocurrency = entries;
                    }
                }

                response.newSourceofFunds = getDependentPicklistValues(Account.SourceofFunds__pc);
            }
        }               
    }
    
    global static void getCountryStatePicklistValues(ConfigurationsModel response) {
        
        Schema.DescribeFieldResult countryFieldResult = User.Countrycode.getDescribe();
        List<Schema.PicklistEntry> countryPle = countryFieldResult.getPicklistValues();
        System.debug('Country>>'+JSON.serialize(countryPle));
        
        List<String> countryEntries = new List<String>();
        for (Schema.PicklistEntry entry: countryPle) {
            countryEntries.add(entry.label);
        }
        response.country = countryEntries;

        response.state = getDependentPicklistValues(User.Statecode);
        
        // Schema.DescribeFieldResult stateFieldResult = User.Statecode.getDescribe();
        // List<Schema.PicklistEntry> statePle = stateFieldResult.getPicklistValues();
        // System.debug('State>>'+JSON.serialize(statePle));
        
        // List<Map<String,String>> stateEntries = new List<Map<String,String>>();
        // for (Schema.PicklistEntry entry: statePle) {
        //     Map<String,String> picklistEntrie = new Map<String,String>();
        //     picklistEntrie.put('label', entry.label);
        //     picklistEntrie.put('value', entry.label);
        //     picklistEntrie.put('code', entry.value);
        //     stateEntries.add(picklistEntrie);
        // }
        // response.state = stateEntries;
    }
    
    global static void getReceiptPicklistValues(ConfigurationsModel response) {
        
        List<String> types = new List<String>{'ReceiptAcknowledgement__c'};
            Schema.DescribeSobjectResult[] result = Schema.describeSObjects(types);
        Map<String, Schema.SObjectField> fieldsMap = result[0].fields.getMap();
        
        List<String> fieldAPIs = new List<String>{
            'BankName__c'
        };
        
        for(String fieldAPI : fieldAPIs) {
            
            Schema.DescribeFieldResult fieldResult = fieldsMap.get(fieldAPI).getDescribe();
            List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
            
            List<String> entries = new List<String>();
            
            for (Integer i = 0; i < picklistEntries.size(); i++){
                Schema.PicklistEntry entry = picklistEntries[i];
                entries.add(entry.value);
            }  
            
            switch on fieldAPI {
                when 'BankName__c'{
                    response.bankName = entries;
                }
            }
        }               
    }
    
    global static void getDocumentTypes(ConfigurationsModel response) {
        List<String> customerDocument = new List<String>();
        for (DocumentPlaceHolder__mdt documentPlaceHolder: DocumentPlaceHolder__mdt.getall().values()) {
            if (documentPlaceHolder.Category__c == Constants.DOCUMENT_PLACEHOLDER_CATEGORY_PERSON_ACCOUNT && documentPlaceHolder.AvailableForCustomer__c) {
                customerDocument.add(documentPlaceHolder.DocumentType__c);
            }
        }
        // response.customerDocument.size();
        customerDocument.sort();
        response.customerDocument = customerDocument;
        
        // Property Transfer
        response.propertyTransferDocument.add(CustomerAPIConstants.DOCUMENT_SUPPORTING_DOCUMENTS);
        response.propertyTransferDocument.add(CustomerAPIConstants.DOCUMENT_SELLER_PASSPORT_COPY);
        response.propertyTransferDocument.add(CustomerAPIConstants.DOCUMENT_SELLER_EMIRATES_ID_COPY);
        response.propertyTransferDocument.add(CustomerAPIConstants.DOCUMENT_BUYER_PASSPORT_COPY);
        response.propertyTransferDocument.add(CustomerAPIConstants.DOCUMENT_BUYER_EMIRATES_ID_COPY);
        //response.propertyTransferDocument.add(CustomerAPIConstants.DOCUMENT_PROVIS_NOC);  // Commented by Tajinkumar 
        response.propertyTransferDocument.add(CustomerAPIConstants.DOCUMENT_EXISTING_TITLE_DEED);
        // Property Transfer
        
        // Joint Owner
        response.jointOwnerDocument.add(CustomerAPIConstants.DOCUMENT_SUPPORTING_DOCUMENTS);
        response.jointOwnerDocument.add(CustomerAPIConstants.DOCUMENT_JOINT_OWNER_PASSPORT_COPY);
        response.jointOwnerDocument.add(CustomerAPIConstants.DOCUMENT_JOINT_OWNER_EMIRATES_ID_COPY);
        response.jointOwnerDocument.add(CustomerAPIConstants.DOCUMENT_PROVIS_DEVELOPMENT_NOC);
        response.jointOwnerDocument.add(CustomerAPIConstants.DOCUMENT_EXISTING_TITLE_DEED);
        // Joint Owner
        
        // Investor Certificate
        response.investorCertificateDocument.add(CustomerAPIConstants.DOCUMENT_SUPPORTING_DOCUMENTS);
        response.investorCertificateDocument.add(CustomerAPIConstants.DOCUMENT_EID_TRADE_LICENSE);
        // Investor Certificate

        // Investor Certificate
        response.plotDesignDocument.add(CustomerAPIConstants.DOCUMENT_SUPPORTING_DOCUMENTS);
        response.plotDesignDocument.add(CustomerAPIConstants.DOCUMENT_TITLE_DEED);
        response.plotDesignDocument.add(CustomerAPIConstants.DOCUMENT_CONSULTANT_CERTIFICATE_LETTER);
        // Investor Certificate
        
        // Other SR Type
        response.otherDocument.add(CustomerAPIConstants.DOCUMENT_SUPPORTING_DOCUMENTS);
        // Other SR Type

        Constant__mdt documentsOrder = Utilities.getConstant('Documents_Order');
        response.documentsOrder = documentsOrder.ConstantValue__c.split(',');
    }
    
    global static void getFormatters(ConfigurationsModel response) {
        
        Map<String, String> appFormats = new Map<String, String>();
        appFormats.put('defaultListDisplayDateFormat', 'dd-MMM-yyyy');
        appFormats.put('defaultListDisplayDateTimeFormat', 'dd-MMM-yyyy | HH:mm');
        response.formatters.put('app', (Object)appFormats);
        
        Map<String, String> salesforceFormats = new Map<String, String>();
        salesforceFormats.put('dateTimeFormat', 'yyyy-MM-dd\'T\'HH:mm:ss.SSSZZZ');
        salesforceFormats.put('dateFormat', 'yyyy-MM-dd');
        response.formatters.put('salesforce', (Object)salesforceFormats);
    }
    
    // global static void getCurrencyConversation(ConfigurationsModel response) {
        
    //     for (CurrencyType cType: [SELECT Id, IsoCode, ConversionRate FROM CurrencyType]) {
    //         response.currencyConversation.put(cType.IsoCode, cType.ConversionRate);
    //     }
    // }
    
    global static void getDescriptions(ConfigurationsModel response) {
        Set<String> systemMessages = new Set<String>{'CUSTOMER_FINANCIAL_EN_DESCRIPTION', 'CUSTOMER_FINANCIAL_AR_DESCRIPTION', 'CUSTOMER_DOCUMENT_EN_DESCRIPTION', 'CUSTOMER_DOCUMENT_AR_DESCRIPTION', 'CUSTOMER_SERVICE_REQUEST_EN_DESCRIPTION', 'CUSTOMER_SERVICE_REQUEST_AR_DESCRIPTION', 'CUSTOMER_REQUEST_CATALOG_EN_DESCRIPTION', 'CUSTOMER_REQUEST_CATALOG_AR_DESCRIPTION'};
            Map<String,SystemMessages__mdt> systemMessageMap = Utilities.getSystemMessages(systemMessages);
        
        response.descriptions.put('financial_EN', systemMessageMap.get('CUSTOMER_FINANCIAL_EN_DESCRIPTION').Message__c);
        response.descriptions.put('financial_AR', systemMessageMap.get('CUSTOMER_FINANCIAL_AR_DESCRIPTION').Message__c);
        
        response.descriptions.put('document_EN', systemMessageMap.get('CUSTOMER_DOCUMENT_EN_DESCRIPTION').Message__c);
        response.descriptions.put('document_AR', systemMessageMap.get('CUSTOMER_DOCUMENT_AR_DESCRIPTION').Message__c);
        
        response.descriptions.put('serviceRequestListing_EN', systemMessageMap.get('CUSTOMER_SERVICE_REQUEST_EN_DESCRIPTION').Message__c);
        response.descriptions.put('serviceRequestListing_AR', systemMessageMap.get('CUSTOMER_SERVICE_REQUEST_AR_DESCRIPTION').Message__c);
        
        response.descriptions.put('requestCatalog_EN', systemMessageMap.get('CUSTOMER_REQUEST_CATALOG_EN_DESCRIPTION').Message__c);
        response.descriptions.put('requestCatalog_AR', systemMessageMap.get('CUSTOMER_REQUEST_CATALOG_AR_DESCRIPTION').Message__c);
    }
    
    global static void getListingCharges(ConfigurationsModel response) {
        List<ListingCharges> listingFeeCharges = new List<ListingCharges>(); 
        listingFeeCharges.add(new ListingCharges('Listing Fee',1500,'Fixed'));
        listingFeeCharges.add(new ListingCharges('Service Charge',2,'Percentage'));
        system.debug('+++ listingFeeCharges'+listingFeeCharges);
        response.listingChargesList = listingFeeCharges;
    }

    global static void getCasePicklistValues(ConfigurationsModel response) {
        
        List<String> types = new List<String>{'Case'};
            Schema.DescribeSobjectResult[] result = Schema.describeSObjects(types);
        Map<String, Schema.SObjectField> fieldsMap = result[0].fields.getMap();
        
        List<String> fieldAPIs = new List<String>{'Listing_Expiry__c'};
            Map<String, List<String>> fieldsToPicklists = new Map<String, List<String>>();
        
        for(String fieldAPI : fieldAPIs) {
            Schema.DescribeFieldResult fieldResult = fieldsMap.get(fieldAPI).getDescribe();
            List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
            List<String> entries = new List<String>();
            for (Integer i = 0; i < picklistEntries.size(); i++){
                Schema.PicklistEntry entry = picklistEntries[i];
                entries.add(entry.value);
            }
            
            switch on fieldAPI {
                when 'Listing_Expiry__c'{
                    response.listingExpiry = entries;
                }
                
            }
            
        }               
    }
    
    // global static void getSRCatalog(ConfigurationsModel response) {
        
    //     String srCatalogQuery = 'SELECT Id, Label, DeveloperName, Id__c, Label__c, ARLabel__c, ParentId__c, ParentLabel__c, HasChild__c, OrderNo__c FROM SRCreationMapping__mdt ORDER BY OrderNo__c';
    //     List<SRCreationMapping__mdt> srCatalogs = Database.query(srCatalogQuery);
    //     System.debug('srCatalogs>>>' + srCatalogs);

    //     List<SRCatalogModel> srCatalogList = new List<SRCatalogModel>();
        
    //     Decimal mainStepCounter = 1;
    //     for (SRCreationMapping__mdt srStep: srCatalogs) {
    //         System.debug('srStep>>>' + srStep);
    //         if (String.isBlank(srStep.ParentLabel__c) && String.isBlank(srStep.ParentId__c)) {
    //             SRCatalogModel srCatalog = new SRCatalogModel(srStep, mainStepCounter);
    //             System.debug('srCatalog>>>' + srCatalog);

    //             srCatalog.subCategories = childDetails(srCatalogs, srStep);
                
    //             srCatalogList.add(srCatalog);
    //             System.debug('srCatalogList>>>' + srCatalogList);
    //             mainStepCounter++;
    //         }
    //     }

    //     response.srCatalog = srCatalogList;
    // }
    
    // public static List<SRCatalogModel> childDetails(List<SRCreationMapping__mdt> srCatalogs, SRCreationMapping__mdt parentSRCatalogRecord) {
    //     List<SRCatalogModel> childSteps = new List<SRCatalogModel>();
    //     Decimal childStepCounter = 1;
    //     for (SRCreationMapping__mdt srStep: srCatalogs) {
    //         if (srStep.ParentLabel__c == parentSRCatalogRecord.Label__c && srStep.ParentId__c == parentSRCatalogRecord.Id__c) {
    //             SRCatalogModel subModel = new SRCatalogModel(srStep, childStepCounter);

    //             if (srStep.HasChild__c) {
    //                 subModel.subCategories = childDetails(srCatalogs, srStep);
    //             }
    //             childSteps.add(subModel);
    //             childStepCounter++;
    //         }
    //     }
    //     return childSteps;
    // }

    public static Map<String, List<String>> getDependentPicklistValues(Schema.sObjectField dependToken) {
        Schema.DescribeFieldResult depend = dependToken.getDescribe();
        Schema.sObjectField controlToken = depend.getController();
        if (controlToken == null) {
            return new Map<String, List<String>>();
        }
     
        Schema.DescribeFieldResult control = controlToken.getDescribe();
        List<Schema.PicklistEntry> controlEntries;
        if(control.getType() != Schema.DisplayType.Boolean) {
            controlEntries = control.getPicklistValues();
        }
     
        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        Map<String,List<String>> dependentPicklistValues = new Map<String,List<String>>();
        for (Schema.PicklistEntry entry : depend.getPicklistValues()) {
            if (entry.isActive() && String.isNotEmpty(String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')))) {
                List<String> base64chars =
                        String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')).split('');
                for (Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++) {
                    Object controlValue =
                            (controlEntries == null
                                    ?   (Object) (index == 1)
                                    :   (Object) (controlEntries[index].isActive() ? controlEntries[index].getLabel() : null)
                            );
                    Integer bitIndex = index / 6;
                    if (bitIndex > base64chars.size() - 1) {
                        break;
                    }
                    Integer bitShift = 5 - Math.mod(index, 6);
                    if  (controlValue == null || (base64map.indexOf( base64chars[ bitIndex ] ) & (1 << bitShift)) == 0)
                        continue;
                    if (!dependentPicklistValues.containsKey((String) controlValue)) {
                        dependentPicklistValues.put((String) controlValue, new List<String>());
                    }
                    dependentPicklistValues.get((String) controlValue).add(entry.getLabel());
                }
            }
        }
        return dependentPicklistValues;
    }
    
    global with sharing class ConfigurationsModel { 
        
        public Map<String, Object> formatters                   {get;set;}
        public List<String> residentStatus                      {get;set;}
        public List<Map<String,String>> mobileCountryCode       {get;set;}
        public List<String> country                             {get;set;}
        public Map<String, List<String>> state                  {get;set;}
        public List<String> nationality                         {get;set;}
        public List<String> employmentStatus                    {get;set;}
        public List<String> gender                              {get;set;}
        public List<String> maritalStatus                       {get;set;}
        public List<String> salutation                          {get;set;}
        public List<String> sourceofFunds                       {get;set;}
        public Map<String, List<String>> newSourceofFunds       {get;set;}
        public List<String> residentSameAsPermanent             {get;set;}
        public List<String> industry                            {get;set;}
        public List<String> bankName                            {get;set;}
        public List<String> customerDocument                    {get;set;}
        public List<String> propertyTransferDocument            {get;set;}
        public List<String> jointOwnerDocument                  {get;set;}
        public List<String> investorCertificateDocument         {get;set;}
        public List<String> plotDesignDocument                  {get;set;}
        public List<String> otherDocument                       {get;set;}
        public Map<String, String> descriptions                 {get;set;}
        public List<String> listingExpiry                       {get;set;} 
        // public Map<String, Object> currencyConversation         {get;set;}
        public List<ListingCharges> listingChargesList          {get;set;}
        // public List<SRCatalogModel> srCatalog                   {get;set;}
        public List<String> documentsOrder                      {get;set;}
        public List<String> visaTypes                           {get; set;}
        public List<String> project                             {get;set;}
        public List<String> relartionshipSubType                {get;set;}
        public List<String> otherSourceOfFunds                  {get;set;}
        public List<String> numberOfKids                        {get;set;}
        public List<String> countryofBirth                      {get;set;}
        public List<String> passportType                        {get;set;}
        public List<String> interestedInCryptocurrency          {get;set;}
       
        
        public ConfigurationsModel() {
            this.formatters = new Map<String, Object>();
            this.residentStatus = new List<String>();
            this.mobileCountryCode = new List<Map<String,String>>();
            this.country = new List<String>();
            this.state = new Map<String, List<String>>();
            this.nationality = new List<String>();
            this.employmentStatus = new List<String>();
            this.gender = new List<String>();
            this.maritalStatus = new List<String>();
            this.salutation = new List<String>();
            this.sourceofFunds = new List<String>();
            this.newSourceofFunds = new Map<String, List<String>>();
            this.residentSameAsPermanent = new List<String>();
            this.industry = new List<String>();
            this.bankName = new List<String>();
            this.customerDocument = new List<String>();
            this.propertyTransferDocument = new List<String>();
            this.jointOwnerDocument = new List<String>();
            this.investorCertificateDocument = new List<String>();
            this.plotDesignDocument = new List<String>();
            this.otherDocument = new List<String>();
            this.descriptions = new Map<String, String>();
            // this.currencyConversation = new Map<String, Object>();
            this.listingChargesList = new  List<ListingCharges>();
            // this.srCatalog = new List<SRCatalogModel>();
            this.documentsOrder = new List<String>();
            this.visaTypes = new List<String>();
            this.project = new List<String>();
            this.relartionshipSubType = new List<String>();
            this.otherSourceOfFunds = new List<String>();
            this.numberOfKids = new List<String>();
            this.countryofBirth = new List<String>();
            this.passportType = new List<String>();
            this.interestedInCryptocurrency = new List<String>();
        }
    }
    global with sharing class ListingCharges {
        public String feeName;
        public Decimal feeAmount;
        public String feeType;
        
        public ListingCharges(String feeName,Decimal feeAmount,String feeType){
            this.feeName = feeName;
            this.feeAmount = feeAmount;
            this.feeType = feeType;
        }
    }
    // public class SRCatalogModel{
    //     public String id                                                    {get;set;}
    //     public String label                                                 {get;set;}
    //     public String arLabel                                               {get;set;}
    //     public Decimal orderNo                                              {get;set;}
    //     public List<SRCatalogModel> subCategories                           {get;set;}
        
    //     public SRCatalogModel(SRCreationMapping__mdt sr, Decimal orderNo) {
    //         this.id = sr.Id__c;
    //         this.label = sr.Label__c;
    //         this.arLabel = sr.ARLabel__c;
    //         this.orderNo = orderNo;
    //         this.subCategories = new List<SRCatalogModel>();
    //     }
    // }
}