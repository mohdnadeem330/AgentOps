@RestResource (urlMapping = '/configurations')
global with sharing class ConfigurationsWebService { 

    @HttpPost
    global static void doPost(DateTime latestDate) {

        RestContextHandler handler = new RestContextHandler(false);

        //try {
            
            ConfigurationsResponse response = getConfigurations(latestDate);

            handler.response.data = response;
            handler.response.success = true;
            handler.finalize();
        //}
        /*catch (Exception exc) {
            system.debug('xqwerty =='+exc.get);
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(exc);
        }*/
    }

    global static ConfigurationsResponse getConfigurations(DateTime latestDate) {

        Map<String,MobileAppStatus__mdt> mobileAppMap = Utilities.getMobileAppColorCode();

        ConfigurationsResponse response = new ConfigurationsResponse();
        getOrderPicklistValues(response, mobileAppMap);
        getFormatters(response);
        getLeadPicklistValues(response, mobileAppMap);
        getOpportunityPicklistValues(response, mobileAppMap);
        getAccountPicklistValues(response);
        //getAgencyDetails(response);
        getDocumentTypes(response);
        getActivityFilters(response);
        getAccountRelationships(response);
        getpaymentType (response);
        getSalesOrderPicklistValues(response);
        //getPriority(response);
        //---- Set restricted values for Mobile 
        List<String> methodOfContactForCreation = System.label.MethodOfContactSM.split(';');
        response.methodOfContactForCreation = methodOfContactForCreation ;
        return response;
    }

    
/*
RTO Approve Pending
Text: #704DFF
Background: #E7E2FF
*/

    global static void getOrderPicklistValues(ConfigurationsResponse response, Map<String,MobileAppStatus__mdt> mobileAppMap) {
        
        Map<String, List<String>> statusSubStatusMap = Utilities.getDependentPickListValues('SalesOrder__c','Status__c','SubStatus__c');
        
        //response.orderStatusSubStatus = statusSubStatusMap ;
        for(String status : statusSubStatusMap.keySet()){
            if(mobileAppMap.containsKey(status)){
                if(status == Constants.STATUS_RESERVATION_IN_PROGRESS)
                response.orderStatuses.add(new Statuses(mobileAppMap.get(status).MasterLabel,mobileAppMap.get(status).TextColor__c,mobileAppMap.get(status).BackgroundColor__c,statusSubStatusMap.get(status)));
            if(status == Constants.STATUS_RESERVED)
                response.orderStatuses.add(new Statuses(mobileAppMap.get(status).MasterLabel,mobileAppMap.get(status).TextColor__c,mobileAppMap.get(status).BackgroundColor__c,statusSubStatusMap.get(status)));
            if(status == Constants.OPPO_UNIT_STATUS_PENDING)
                response.orderStatuses.add(new Statuses(mobileAppMap.get(status).MasterLabel,mobileAppMap.get(status).TextColor__c,mobileAppMap.get(status).BackgroundColor__c,statusSubStatusMap.get(status)));
            if(status == Constants.STATUS_APPROVAL_PENDING)
                response.orderStatuses.add(new Statuses(mobileAppMap.get(status).MasterLabel,mobileAppMap.get(status).TextColor__c,mobileAppMap.get(status).BackgroundColor__c,statusSubStatusMap.get(status)));
            if(status == Constants.SO_STATUS_SOLD)
                response.orderStatuses.add(new Statuses(mobileAppMap.get(status).MasterLabel,mobileAppMap.get(status).TextColor__c,mobileAppMap.get(status).BackgroundColor__c,statusSubStatusMap.get(status)));
            if(status == Constants.SO_STATUS_CANCELLED)
                response.orderStatuses.add(new Statuses(mobileAppMap.get(status).MasterLabel,mobileAppMap.get(status).TextColor__c,mobileAppMap.get(status).BackgroundColor__c,statusSubStatusMap.get(status)));
            if(status == Constants.SO_STATUS_CANCELLED_BY_USER)
                response.orderStatuses.add(new Statuses(mobileAppMap.get(status).MasterLabel,mobileAppMap.get(status).TextColor__c,mobileAppMap.get(status).BackgroundColor__c,statusSubStatusMap.get(status)));
            if(status == Constants.SO_STATUS_RTO_SOLD)
                response.orderStatuses.add(new Statuses(mobileAppMap.get(status).MasterLabel,mobileAppMap.get(status).TextColor__c,mobileAppMap.get(status).BackgroundColor__c,statusSubStatusMap.get(status)));
            if(status == Constants.SO_STATUS_RTO_PENDING)
                response.orderStatuses.add(new Statuses(mobileAppMap.get(status).MasterLabel,mobileAppMap.get(status).TextColor__c,mobileAppMap.get(status).BackgroundColor__c,statusSubStatusMap.get(status)));
            if(status == Constants.SO_STATUS_RTO_CONVERTED)
                response.orderStatuses.add(new Statuses(mobileAppMap.get(status).MasterLabel,mobileAppMap.get(status).TextColor__c,mobileAppMap.get(status).BackgroundColor__c,statusSubStatusMap.get(status)));
            if(status == Constants.SO_STATUS_RTO_TERMINATED)
                response.orderStatuses.add(new Statuses(mobileAppMap.get(status).MasterLabel,mobileAppMap.get(status).TextColor__c,mobileAppMap.get(status).BackgroundColor__c,statusSubStatusMap.get(status)));
            if(status == Constants.SO_STATUS_RTO_EXPIRED)
                response.orderStatuses.add(new Statuses(mobileAppMap.get(status).MasterLabel,mobileAppMap.get(status).TextColor__c,mobileAppMap.get(status).BackgroundColor__c,statusSubStatusMap.get(status)));
            } 
        }
    }

    global static void getLeadPicklistValues(ConfigurationsResponse response, Map<String,MobileAppStatus__mdt> mobileAppMap) {
        
        List<String> types = new List<String>{'Lead'};
        Schema.DescribeSobjectResult[] result = Schema.describeSObjects(types);
        Map<String, Schema.SObjectField> fieldsMap = result[0].fields.getMap();
        
        List<String> fieldAPIs = new List<String>{
            'LeadSource',
            'Status',
            'LanguagePreference__c',
            'OwnedBy__c',
            'PurposeOfUse__c',
            'PropertyReadiness__c',
            'NumberOfBedrooms__c',
            'Bulk__c',
            'Mortgage__c',
            'Emirate__c',
            'EmailApprovalsReason__c'
        };
        
        response.customerTypeSubType = Utilities.getDependentPickListValues(fieldsMap.get('CustomerType__c').getDescribe(),fieldsMap.get('CustomerSubType__c').getDescribe());
        
        response.residentStatusLocation = Utilities.getDependentPickListValues(fieldsMap.get('ResidentStatus__c').getDescribe(),fieldsMap.get('CustomerLocation__c').getDescribe());

        response.subTypeWealthName = Utilities.getDependentPickListValues(fieldsMap.get('CustomerSubType__c').getDescribe(),fieldsMap.get('CorporateWealthName__c').getDescribe());

        response.saleTypePropertyUsage = Utilities.getDependentPickListValues(fieldsMap.get('SalesType__c').getDescribe(),fieldsMap.get('PropertyUsage__c').getDescribe());

        response.propertyUsagebuyRent = Utilities.getDependentPickListValues(fieldsMap.get('PropertyUsage__c').getDescribe(),fieldsMap.get('BuyRent__c').getDescribe());

        response.propertyUsageCustomerBudget = Utilities.getDependentPickListValues(fieldsMap.get('PropertyUsage__c').getDescribe(),fieldsMap.get('CustomerBudget__c').getDescribe());

        response.propertyUsageProject = Utilities.getDependentPickListValues(fieldsMap.get('PropertyUsage__c').getDescribe(),fieldsMap.get('Project__c').getDescribe());

        response.propertyUsageUnitType = Utilities.getDependentPickListValues(fieldsMap.get('PropertyUsage__c').getDescribe(),fieldsMap.get('UnitType__c').getDescribe());

        response.methodOfContactEnquiryCategory = Utilities.getDependentPickListValues(fieldsMap.get('LeadSource').getDescribe(),fieldsMap.get('EnquiryCategory__c').getDescribe());

        response.enquiryCategoryTrigger = Utilities.getDependentPickListValues(fieldsMap.get('EnquiryCategory__c').getDescribe(),fieldsMap.get('EnquiryTrigger__c').getDescribe());

        response.enquiryTriggerMediaSource = Utilities.getDependentPickListValues(fieldsMap.get('EnquiryTrigger__c').getDescribe(),fieldsMap.get('MediaSource__c').getDescribe());

        response.financingMortage = Utilities.getDependentPickListValues(fieldsMap.get('Financing__c').getDescribe(),fieldsMap.get('Mortgage__c').getDescribe());
        
        response.leadStatusRetiredReason = Utilities.getDependentPickListValues(fieldsMap.get('Status').getDescribe(),fieldsMap.get('RetiredReason__c').getDescribe());

        response.saleTypeArea = Utilities.getDependentPickListValues(fieldsMap.get('SalesType__c').getDescribe(),fieldsMap.get('AreaSqmt__c').getDescribe());

        response.saleOriginLeadOrigin = Utilities.getDependentPickListValues(fieldsMap.get('SalesOrigin__c').getDescribe(),fieldsMap.get('LeadOrigin__c').getDescribe());
        
        
        
        Map<String, List<String>> fieldsToPicklists = new Map<String, List<String>>();
        List<String> leadStatus = new List<String>();
        
        for(String fieldAPI : fieldAPIs) {
            
            Schema.DescribeFieldResult fieldResult = fieldsMap.get(fieldAPI).getDescribe();
            List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
            
            List<String> entries = new List<String>();
            
            for (Integer i = 0; i < picklistEntries.size(); i++){           
                Schema.PicklistEntry entry = picklistEntries[i];
                entries.add(entry.value);
            }  
            
            switch on fieldAPI {
                when 'LeadSource'{
                    response.methodOfContact = entries;
                    response.methodOfContact.sort();
                }
                when 'Status'{
                    leadStatus = entries;
                }
                when 'LanguagePreference__c' {
                    response.preferredLanguages = entries;
                }
                when 'OwnedBy__c'{
                    response.ownedBy = entries;
                }
                when 'PurposeOfUse__c'{
                    response.purposeOfUse = entries;
                }
                when 'PropertyReadiness__c'{
                    response.propertyReadiness = entries;
                }
                when 'NumberOfBedrooms__c'{
                    response.bedrooms = entries;
                }
                when 'Bulk__c'{
                    response.bulkProperty = entries;
                }
                when 'Mortgage__c'{
                    response.bankName = entries;
                }
                when 'Emirate__c'{
                    response.emirates = entries;
                }
                when 'EmailApprovalsReason__c'{
                    response.exceptionReasons = entries;
                }
                
            }
        }
        
        for(String status : leadStatus){
            if(mobileAppMap.containsKey(status)){
                response.leadStatuses.add(new Statuses(mobileAppMap.get(status).MasterLabel,mobileAppMap.get(status).TextColor__c,mobileAppMap.get(status).BackgroundColor__c,null));
                /*
                if(status == Constants.NEW_LEAD)
                    response.leadStatuses.add(new Statuses(mobileAppMap.get(status).MasterLabel,mobileAppMap.get(status).TextColor__c,mobileAppMap.get(status).BackgroundColor__c,null));
                if(status == Constants.WORKING_LEAD)
                    response.leadStatuses.add(new Statuses(mobileAppMap.get(status).MasterLabel,mobileAppMap.get(status).TextColor__c,mobileAppMap.get(status).BackgroundColor__c,null));
                if(status == Constants.QUALIFIED)
                    response.leadStatuses.add(new Statuses(mobileAppMap.get(status).MasterLabel,mobileAppMap.get(status).TextColor__c,mobileAppMap.get(status).BackgroundColor__c,null));
                if(status == Constants.RETIRED)
                    response.leadStatuses.add(new Statuses(mobileAppMap.get(status).MasterLabel,mobileAppMap.get(status).TextColor__c,mobileAppMap.get(status).BackgroundColor__c,null));
                */
            }
        }
    }

    global static void getOpportunityPicklistValues(ConfigurationsResponse response, Map<String,MobileAppStatus__mdt> mobileAppMap) {
        
        List<String> types = new List<String>{'Opportunity'};
       List<String> interDeptTeams = System.Label.InterDeptTeams.split(',');
        Schema.DescribeSobjectResult[] result = Schema.describeSObjects(types);
        Map<String, Schema.SObjectField> fieldsMap = result[0].fields.getMap();
        
        Map<String, List<String>> teamToSaleTypesMap = new Map<String, List<String>>();
        
        teamToSaleTypesMap.put('AUH/DXB', new List<String>{'Institutional','Residential Sale','Asset Management'});
        teamToSaleTypesMap.put('LAND', new List<String>{'Commercial Land'});
        teamToSaleTypesMap.put('ReSales', new List<String>{});
        response.teams = interDeptTeams;
        response.teamToSalesTypes = teamToSaleTypesMap;
        response.saleTypeToPropertyUsage = Utilities.getDependentPickListValues(fieldsMap.get('SalesTypefromLead__c').getDescribe(),fieldsMap.get('PropertyUsage__c').getDescribe());
        response.propertyUsageToProject = Utilities.getDependentPickListValues(fieldsMap.get('PropertyUsage__c').getDescribe(),fieldsMap.get('Project__c').getDescribe());
        
        List<String> fieldAPIs = new List<String>{
            'StageName',
            'SaleType__c',
            'DealType__c',
            'BookingType__c',
            'AgentType__c',
            'ReferralType__c',
            'DeliveryMethod__c',    
            'SubsidyYears__c',
            'EmployeeName__c',
            'WinReason__c',
            'LossReason__c'
        };
        
        Map<String, List<String>> fieldsToPicklists = new Map<String, List<String>>();

        List<String> opportunityStage = new List<String>();
        
        for(String fieldAPI : fieldAPIs) {
            
            Schema.DescribeFieldResult fieldResult = fieldsMap.get(fieldAPI).getDescribe();
            List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
            
            List<String> entries = new List<String>();
            
            for (Integer i = 0; i < picklistEntries.size(); i++){           
                Schema.PicklistEntry entry = picklistEntries[i];
                entries.add(entry.value);
            }  

            response.stageLossReason = Utilities.getDependentPickListValues(fieldsMap.get('stageName').getDescribe(),fieldsMap.get('LossReason__c').getDescribe());
            
            switch on fieldAPI {
                when 'StageName'{
                    opportunityStage = entries;
                    response.stageName = entries;
                }
                when 'SaleType__c'{
                    response.saleType = entries;
                }
                when 'DealType__c'{
                    response.dealType = entries;
                }
                when 'BookingType__c'{
                    response.bookingType = entries;
                }
                when 'AgentType__c'{
                    response.agentType = entries;
                }
                when 'ReferralType__c'{
                    response.referralType = entries;
                }
                when 'DeliveryMethod__c'{
                    response.deliveryMethod = entries;
                }
                when 'SubsidyYears__c'{
                    response.subsidyYears = entries;
                }
                when 'EmployeeName__c'{
                    response.employeeName = entries;
                }
                when 'LossReason__c'
                {
                    response.lossReason = entries;
                }
            }
        }  
        
        for(String status : opportunityStage){
            if(mobileAppMap.containsKey(status)){
                response.opportunityStages.add(new Statuses(mobileAppMap.get(status).MasterLabel,mobileAppMap.get(status).TextColor__c,mobileAppMap.get(status).BackgroundColor__c,null));
                /*
                if(status == Constants.STAGE_NEW)
                    response.opportunityStages.add(new Statuses(mobileAppMap.get(status).MasterLabel,mobileAppMap.get(status).TextColor__c,mobileAppMap.get(status).BackgroundColor__c,null));
                if(status == Constants.STAGE_IN_PROGRESS)
                    response.opportunityStages.add(new Statuses(mobileAppMap.get(status).MasterLabel,mobileAppMap.get(status).TextColor__c,mobileAppMap.get(status).BackgroundColor__c,null));
                if(status == Constants.STAGE_PROPOSAL)
                    response.opportunityStages.add(new Statuses(Constants.QUALIFIED,mobileAppMap.get(status).TextColor__c,mobileAppMap.get(status).BackgroundColor__c,null));
                if(status == Constants.STAGE_MEETING)
                    response.opportunityStages.add(new Statuses(mobileAppMap.get(status).MasterLabel,mobileAppMap.get(status).TextColor__c,mobileAppMap.get(status).BackgroundColor__c,null));
                if(status == Constants.STAGE_CLOSEDWON)
                    response.opportunityStages.add(new Statuses(mobileAppMap.get(status).MasterLabel,mobileAppMap.get(status).TextColor__c,mobileAppMap.get(status).BackgroundColor__c,null));
                if(status == Constants.STAGE_CLOSED_LOST)
                    response.opportunityStages.add(new Statuses(mobileAppMap.get(status).MasterLabel,mobileAppMap.get(status).TextColor__c,mobileAppMap.get(status).BackgroundColor__c,null));
                */
            }
        }
    }

    global static void getAccountPicklistValues(ConfigurationsResponse response) {
        
        List<String> types = new List<String>{'Account'};
        Schema.DescribeSobjectResult[] result = Schema.describeSObjects(types);
        Map<String, Schema.SObjectField> fieldsMap = result[0].fields.getMap();
        
        response.employmentStatusSourceOfFunds = Utilities.getDependentPickListValues(fieldsMap.get('EmploymentStatus__pc').getDescribe(),fieldsMap.get('SourceofFunds__pc').getDescribe());
        
        List<String> fieldAPIs = new List<String>{
            'CustomerType__c',
            'ResidentStatus__pc',
            'MobileCountryCode__c',
            'Nationality__pc',
            'EmploymentStatus__pc',
            'Gender__pc',
            'MaritalStatus__pc',
            'Salutation',
            'SourceofFunds__pc',
            'ResidentialAddressSameAsPermanent__c',
            'Industry',
            'VisaType__c',
            'CustomerBankName__c',
            'CustomerBankCountry__c',
            'VIPClass__c',
            'EmailApprovalsReason__c',
            'EIDPlaceofissuance__c',
            //Added by SAURABH
            'Passport_type__pc',
            //'Number_of_Kids__c',
            'Other_Source_of_Funds__pc'

        };
       
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
                when 'ResidentStatus__pc'{
                    response.residentStatus = entries;
                }
                when 'CustomerType__c'{
                    response.customerType = entries;
                }
                when 'MobileCountryCode__c'{
                    response.mobileCountryCode = entries;
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
                when 'CustomerBankName__c' {
                    response.customerBankName = entries;
                }
                when 'CustomerBankCountry__c' {
                    response.customerBankCountry = entries;
                }
                when 'VIPClass__c'{
                   response.VIPClass = entries; 
                }
                when 'EmailApprovalsReason__c'{
                    response.exceptionReasons = entries;
                }
                when 'EIDPlaceofissuance__c'{
                    response.eidPlaceofIssuance = entries;
                }
                when 'Passport_type__pc'{
                    response.passportType = entries;
                }
                /*when 'Number_of_Kids__c'{
                    response.numberOfKids = entries;
                }*/
                when 'Other_Source_of_Funds__pc'{
                    response.otherSourceOfFunds = entries;
                }
            }
        }               
    }

    global static void getAgencyDetails(ConfigurationsResponse response){
        response.brokerAgencies = AccountService.getAllActiveAgencies();
    }

    global static void getDocumentTypes(ConfigurationsResponse response){
        Map<String,List<DocumentPlaceHolder__mdt>> documentPlaceholderMap = DocumentService.getDocumentMetaDataByCategory(new Set<String>{Constants.DOCUMENT_PLACEHOLDER_CATEGORY_PERSON_ACCOUNT,Constants.DOCUMENT_PLACEHOLDER_CATEGORY_ORGANIZATION});

        for(DocumentPlaceHolder__mdt documentPlaceHolder : documentPlaceholderMap.get(Constants.DOCUMENT_PLACEHOLDER_CATEGORY_PERSON_ACCOUNT)){
            response.personOrCompanyRepDocuments.add(documentPlaceHolder.DocumentType__c);
        }
        
        for(DocumentPlaceHolder__mdt documentPlaceHolder : documentPlaceholderMap.get(Constants.DOCUMENT_PLACEHOLDER_CATEGORY_ORGANIZATION)){
            response.organisationDocuments.add(documentPlaceHolder.DocumentType__c);
        }
    
    }

    global static void getFormatters( ConfigurationsResponse response) {
        
        Map<String, String> appFormats = new Map<String, String>();
        appFormats.put('defaultListDisplayDateFormat', 'dd-MMM-yyyy');
        appFormats.put('defaultListDisplayDateTimeFormat', 'dd-MMM-yyyy | HH:mm');
        response.formatters.put('app', (Object)appFormats);

        Map<String, String> salesforceFormats = new Map<String, String>();
        salesforceFormats.put('dateTimeFormat', 'yyyy-MM-dd\'T\'HH:mm:ss.SSSZZZ');
        salesforceFormats.put('dateFormat', 'yyyy-MM-dd');
        response.formatters.put('salesforce', (Object)salesforceFormats);
    }

    global static void getActivityFilters (ConfigurationsResponse response) {

        response.activityFilters.add(new ActivityFilters('Open Activities', 'Open', 'Status'));
        response.activityFilters.add(new ActivityFilters('This Week', 'THIS_WEEK', 'dateFilter'));
        response.activityFilters.add(new ActivityFilters('This Month', 'THIS_MONTH', 'dateFilter'));
        response.activityFilters.add(new ActivityFilters('Today', 'TODAY', 'dateFilter'));
        
    }
    
    global static void getAccountRelationships (ConfigurationsResponse response){
        Schema.DescribeFieldResult fieldResult = AccountRelationship__c.RelationshipType__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<String> relationshipList = new List<String>();
        
        Schema.DescribeFieldResult fieldResult1 = AccountRelationship__c.RelationshipSubType__c.getDescribe();
        List<Schema.PicklistEntry> subTypeValues = fieldResult1.getPicklistValues();
        List<String> subTypeValuesList = new List<String>();
        
        for( Schema.PicklistEntry pickListVal : ple){
            relationshipList.add(pickListVal.getLabel());
        }
        for( Schema.PicklistEntry pickListVal : subTypeValues){
            subTypeValuesList.add(pickListVal.getLabel());
        }
        response.accountRelationship = relationshipList;
        response.accountRelationshipSubType = subTypeValuesList;
        
    }

    global static List<String> getpaymentType (ConfigurationsResponse response){
        Schema.DescribeFieldResult fieldResult = ReceiptAcknowledgement__c.PaymentType__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<String> relationshipList = new List<String>();
        
        for( Schema.PicklistEntry pickListVal : ple){
            relationshipList.add(pickListVal.getLabel());
        }   
        response.paymentType = relationshipList;
        
        return relationshipList;
        
    }
	// Added by Sanath H M,  Date: 13.12.2022	
    global static List<String> getDDRCustomerBankNames (ConfigurationsResponse response){	
        Schema.DescribeFieldResult fieldResult = DirectDebitRequest__c.CustomerBankName__c.getDescribe();	
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();	
        List<String> ddrCustomerBankNameList = new List<String>();	
        	
        for( Schema.PicklistEntry pickListVal : ple){	
			ddrCustomerBankNameList.add(pickListVal.getLabel());	
		}   	
        response.ddr_CustomerBankNames = ddrCustomerBankNameList;	
        return ddrCustomerBankNameList;   	
    }	
    global static List<String> getDDRCustomerIdTypes (ConfigurationsResponse response){	
        Schema.DescribeFieldResult fieldResult = DirectDebitRequest__c.CustomerIdType__c.getDescribe();	
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();	
        List<String> ddrCustomerIdTypeList = new List<String>();	
        	
        for( Schema.PicklistEntry pickListVal : ple){	
            ddrCustomerIdTypeList.add(pickListVal.getLabel());	
        }   	
        response.ddr_CustomerIdTypes = ddrCustomerIdTypeList;	
        return ddrCustomerIdTypeList;   	
    }	
    	
    global static List<String> getDDRCustomerBankActTypes (ConfigurationsResponse response){	
        Schema.DescribeFieldResult fieldResult = DirectDebitRequest__c.CustomerBankAccountType__c.getDescribe();	
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();	
        List<String> ddrCustomerBankActTypeList = new List<String>();	
        	
        for( Schema.PicklistEntry pickListVal : ple){	
            ddrCustomerBankActTypeList.add(pickListVal.getLabel());	
        }   	
        response.ddr_CustomerBankAccountTypes = ddrCustomerBankActTypeList;	
        return ddrCustomerBankActTypeList;   	
    }
    
    global static List<String> getCurrencyValues (ConfigurationsResponse response){
        Schema.DescribeFieldResult fieldResult = SalesOrder__c.CurrencyIsoCode.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<String> currencyList = new List<String>();
        
        for( Schema.PicklistEntry pickListVal : ple){
            currencyList.add(pickListVal.getValue());
        }   
        response.paymentType = currencyList;
        
        return currencyList;
        
    }

    global static void getSalesOrderPicklistValues (ConfigurationsResponse response){

        List<String> types = new List<String>{'SalesOrder__c'};
        Schema.DescribeSobjectResult[] result = Schema.describeSObjects(types);
        Map<String, Schema.SObjectField> fieldsMap = result[0].fields.getMap();
        
        List<String> fieldAPIs = new List<String>{
            'SpecialConditionApplicable__c',
            'SpecialConditionReason__c',
            'MortgageApplicable__c',
            'MortgageBank__c'
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
                when 'SpecialConditionApplicable__c'{
                    response.specialConditionApplicable = entries;
                }
                when 'SpecialConditionReason__c'{
                    response.specialConditionReason = entries;
                }
                when 'MortgageApplicable__c'{
                    response.mortgageApplicable = entries;
                }
                when 'MortgageBank__c'{
                    response.mortgageBank = entries;
                }
            }
        } 
        
        Schema.DescribeFieldResult fieldResult = BookingMemo__c.MemoType__c.getDescribe();
        for(Schema.PicklistEntry tempVal: fieldResult.getPicklistValues()){
            response.memoTypes.add(tempVal.getValue());
        }  
        
    }

    

    global with sharing class ConfigurationsResponse { 
        
        //public Map<String,List<String>> orderStatusSubStatus    {get; set; }
        public List<String> errorEmailRecipients                {get; set;}
        public Map<String, Object> formatters                   {get;set;}
        public List<String> preferredLanguages                  {get; set; }
        public List<String> methodOfContact                     {get; set; }
        public List<String> methodOfContactForCreation          {get; set; }
        public List<String> leadProjects                        {get; set; }
        public List<String> residentStatus                      {get; set; }
        public List<String> customerType                        {get; set; }
        public List<Statuses> leadStatuses                      {get; set; }
        public List<Statuses> orderStatuses                     {get; set; }
        public List<Statuses> opportunityStages                 {get; set; }
        public List<String> mobileCountryCode                   {get; set; }
        public List<String> nationality                         {get; set; }
        public List<String> employmentStatus                    {get; set; }
        public List<String> gender                              {get; set; }
        public List<String> maritalStatus                       {get; set; }
        public List<String> salutation                          {get; set; }
        public List<String> saleType                            {get; set; }
        public List<String> dealType                            {get; set; }
        public List<String> bookingType                         {get; set; }
        public List<String> agentType                           {get; set; }
        public List<String> referralType                        {get; set; }
        public List<String> deliveryMethod                      {get; set; }
        public List<String> subsidyYears                        {get; set; }
        public List<String> ownedBy                             {get; set; }
        public List<String> purposeOfUse                        {get; set; }
        public List<String> propertyReadiness                   {get; set; }
        public List<String> employeeName                        {get; set; }
        public List<String> stageName                           {get; set; }
        public List<String> lossReason                          {get; set; }
        public List<String> bedrooms                            {get; set; }
        public List<String> bulkProperty                        {get; set;}
        public List<String> sourceofFunds                       {get; set;}
        public List<String> bankName                            {get; set;}
        public List<String> emirates                            {get; set;}
        public List<String> exceptionReasons                    {get; set;}
        public List<String> visaTypes                           {get; set;}
        public List<String> customerBankCountry                 {get; set;}
        public List<String> customerBankName                    {get; set;}
        public Map<String,List<String>> customerTypeSubType             {get; set; }
        public Map<String,List<String>> residentStatusLocation          {get; set; }
        public Map<String,List<String>> subTypeWealthName               {get; set; }
        public Map<String,List<String>> saleTypePropertyUsage           {get; set; }
        public Map<String,List<String>> propertyUsagebuyRent            {get; set; }
        public Map<String,List<String>> propertyUsageCustomerBudget     {get; set; }
        public Map<String,List<String>> propertyUsageProject            {get; set; }
        public Map<String,List<String>> propertyUsageUnitType           {get; set; }
        public Map<String,List<String>> methodOfContactEnquiryCategory  {get; set; }
        public Map<String,List<String>> enquiryCategoryTrigger          {get; set; }
        public Map<String,List<String>> enquiryTriggerMediaSource       {get; set; }
        public Map<String,List<String>> financingMortage                {get; set; }
        public Map<String,List<String>> saleTypeArea                    {get; set; }
        public Map<String,List<String>> saleOriginLeadOrigin            {get; set; }
        public Map<String,List<String>> leadStatusRetiredReason         {get; set; }
        public Map<String,List<String>> stageLossReason                 {get; set; }
        public List<Account> brokerAgencies                             {get; set; }
        public List<String> personOrCompanyRepDocuments                 {get; set;}
        public List<String> organisationDocuments                       {get; set;}
        public List<String> residentSameAsPermanent                     {get; set;}
        public List<String> industry                                    {get; set;}
        public List<ActivityFilters> activityFilters                    {get; set;}
        public List<String> accountRelationship                         {get; set;}
        public List<String> accountRelationshipSubType                  {get; set;}
        public List<String> specialConditionApplicable                  {get; set;}
        public List<String> paymentType                                 {get; set;}
		public List<String> ddr_CustomerBankNames                       {get; set;} // Added by Sanath H M,  Date: 13.12.2022	
        public List<String> ddr_CustomerIdTypes                         {get;set;}	
        public List<String> ddr_CustomerBankAccountTypes                {get;set;}
        //public List<String> specialConditionApprovalStatus              {get; set;}
        public List<String> specialConditionReason                      {get; set;}
        public List<String> mortgageApplicable                          {get; set;}
        public List<String> mortgageBank                                {get; set;}
        public List<String> memoTypes                                {get; set;}
        //public List<String> priority                                    {get; set;}
        public Map<String,List<String>> employmentStatusSourceOfFunds             {get; set; }
         public List<String> teams                                {get; set;}
        public Map<String, List<String>> teamToSalesTypes {get; set;}
        public Map<String, List<String>> saleTypeToPropertyUsage {get; set;}
        public Map<String, List<String>> propertyUsageToProject {get; set;}
        public List<String> VIPClass                               {get; set;}
        public List<String> eidPlaceofIssuance 	{get;set;}
        public List<String> passportType {get;set;}
        //public List<String> numberOfKids {get;set;}
        public List<String> otherSourceOfFunds {get;set;}

        public ConfigurationsResponse() {
            
           // this.orderStatusSubStatus = new Map<String,List<String>>();
            this.errorEmailRecipients = new List<String>();
            this.formatters = new Map<String, Object>();
            this.methodOfContactForCreation = new List<String>();
            this.preferredLanguages = new List<String>();
            this.methodOfContact = new List<String>();
            this.leadProjects = new List<String>();
            this.residentStatus = new List<String>();
            this.customerType = new List<String>();
            this.leadStatuses = new List<Statuses>();
            this.orderStatuses = new List<Statuses>();
            this.opportunityStages = new List<Statuses>();
            this.customerTypeSubType = new Map<String,List<String>>();
            this.subTypeWealthName = new Map<String,List<String>>();
            this.saleTypePropertyUsage = new Map<String,List<String>>();
            this.propertyUsagebuyRent = new Map<String,List<String>>();
            this.propertyUsageCustomerBudget = new Map<String,List<String>>();
            this.propertyUsageProject = new Map<String,List<String>>();
            this.propertyUsageUnitType = new Map<String,List<String>>();
            this.methodOfContactEnquiryCategory = new Map<String,List<String>>();
            this.enquiryCategoryTrigger = new Map<String,List<String>>();
            this.enquiryTriggerMediaSource = new Map<String,List<String>>();
            this.financingMortage = new Map<String,List<String>>();
            this.leadStatusRetiredReason = new Map<String,List<String>>();
            this.stageLossReason = new Map<String,List<String>>();  
            this.saleTypeArea = new Map<String,List<String>>();
            this.saleOriginLeadOrigin = new Map<String,List<String>>();
            this.mobileCountryCode = new List<String>();
            this.nationality = new List<String>();
            this.employmentStatus = new List<String>();
            this.gender = new List<String>();
            this.maritalStatus = new List<String>();
            this.salutation = new List<String>();
            this.saleType = new List<String>();
            this.dealType = new List<String>();
            this.bookingType = new List<String>();
            this.agentType = new List<String>();
            this.referralType = new List<String>();
            this.deliveryMethod = new List<String>(); 
            this.subsidyYears = new List<String>();
            this.ownedBy  = new List<String>();
            this.purposeOfUse = new List<String>();
            this.employeeName = new List<String>();
            this.lossReason = new List<String>();    
            this.stageName = new List<String>();    
            this.bedrooms = new List<String>();
            this.bulkProperty = new List<String>();
            this.sourceofFunds = new List<String>();
            this.bankName = new List<String>();
            this.emirates = new List<String>();
            this.exceptionReasons = new List<String>();
            this.brokerAgencies = new List<Account>();
            this.personOrCompanyRepDocuments = new List<String>();
            this.organisationDocuments = new List<String>();
            this.residentSameAsPermanent = new List<String>();
            this.industry = new List<String>();
            this.activityFilters = new List<ActivityFilters>();
            this.accountRelationship = new List<String>();
            this.accountRelationshipSubType = new List<String>(); 
            this.paymentType = new List<String>();
            this.specialConditionApplicable = new List<String>();
            //this.specialConditionApprovalStatus = new List<String>();
            this.specialConditionReason = new List<String>();
            this.mortgageApplicable = new List<String>();
            this.mortgageBank = new List<String>();
			this.ddr_CustomerBankNames = new List<String>();// Added by Sanath H M,  Date: 13.12.2022
            this.memoTypes = new List<String>();
            //this.priority = new List<String>();
            this.employmentStatusSourceOfFunds = new Map<String,List<String>>();
            this.customerBankCountry = new List<String>();
            this.customerBankName = new List<String>();
            this.teams = new List<String>();
            this.teamToSalesTypes = new Map<String, List<String>>();
            this.saleTypeToPropertyUsage = new Map<String, List<String>>();
            this.propertyUsageToProject = new Map<String, List<String>>();
            this.VIPClass = new List<String>();
            this.eidPlaceofIssuance = new List<String>();
            this.passportType = new List<String>();
            //this.numberOfKids = new List<String>();
            this.otherSourceOfFunds = new List<String>();
        }
    }
    
    global class Statuses{
        public String status            {get; set; }
        public String textColor         {get; set; }
        public String backGroundColor   {get; set; }
        public List<String> subStatus   {get; set; }

        public Statuses(String status, String textColor, String backGroundColor,List<String> subStatus){
            this.status = status ;
            this.textColor = textColor ;
            this.backGroundColor = backGroundColor ;
            this.subStatus = subStatus ;
        }
    }

    public class ActivityFilters
    {
        public String label {get;set;}
        public String value {get;set;}
        public String key {get;set;}
        public ActivityFilters(String label, String value, String key)
        {
            this.label = label;
            this.value = value;
            this.key = key;
        }
    }

}