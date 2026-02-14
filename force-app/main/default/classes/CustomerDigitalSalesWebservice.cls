/*
* Name               : CustomerDigitalSalesWebservice
* Description        : This class is used to Create a Booking CP Record when Customer Clicks on Reserve Now in Live Aldar app
*/

@RestResource (urlMapping = '/customer/digitalSales')
global class CustomerDigitalSalesWebservice {
    
    @HTTPPost
    global static void doPost(String customerId, String projectName, String unitId) {
        RestContextHandler handler = new RestContextHandler(true);
        Savepoint sp;
        try {
            sp = Database.setSavepoint();
            RestRequest req = RestContext.request;
            handler.response.data = customerDigitalSales(customerId,projectName,unitId);
            handler.response.message = Constants.SUCCESS_MESSAGE;
            handler.response.statusCode = Constants.SUCCESS_CODE_200;
            handler.response.success = true;
            handler.finalize();
            
        } catch (Exception ex) {
            Database.rollback(sp);
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = ex.getMessage();
            handler.finalize(ex);
        }
    }
    
    global static Map<String,Object> customerDigitalSales(String customerId,String projectName, String unitId) {
        
        Account account;
        Set<Id> leadIds = new Set<Id>();
        Boolean cpRecordFound = false;
        Boolean isValidProject = false;
        String leadprojName = '';
        
        if(String.isBlank(customerId) || String.isBlank(projectName) || String.isBlank(unitId)) {
            throw new customException ('Missing or invalid input parameters : customerId , ProjectName , UnitId are required fields');
        }
        
        String accWhrClause = ' (Id = \'' + customerId + '\') ';
        List<Account> accountList = CustomerServiceUtility.getAccountDetail(accWhrClause);
        
        if(accountList.isEmpty()) {
            throw new customException ('Account Id not found with provided customerId.');
        }
        
        if(String.isNotBlank(projectName)){
            Map<String,String> leadProjectMapping =  LeadRestServices.mapPicklistValueFromProject(projectName);
            System.debug('leadProjectMapping>>>> : ' + leadProjectMapping);
            
            for(String key : leadProjectMapping.keySet()){
                if(String.isNotBlank(key) && key.equalsIgnoreCase(projectName) && String.isNotBlank(leadProjectMapping.get(key))){
                    leadprojName = leadProjectMapping.get(key);
                    isValidProject = true;
                    break;
                }
            }
            
            if(!isValidProject){ 
                throw new customException('Invalid project name. Please provide a valid project name.');
            } 
        }
        
        account = accountList[0];
        System.debug(' account>>>>' +  account);
        
        //CP Record found
        if(account.Communication_Preferences__r != null){
            for(Communication_Preference__c cp : account.Communication_Preferences__r){
                System.debug('cpRecordFound>>>>');
                if(cp.Category__c == 'Booking' && cp.Active__c && cp.Unit__c == unitId && String.isNotBlank(cp.Project__c) && String.isNotBlank(leadprojName) && cp.Project__c.equalsIgnoreCase(leadprojName) && cp.Status__c == 'Fasttrack Completed' && cp.Source_Type__c == 'Live Aldar' && cp.Lead__c != null && cp.Opportunity__c != null){
                    cpRecordFound = true;
                    return createResult(cp.Id,cp.Opportunity__c,'DigitalSales record already exists.');
                } 
            }
        }
        
        //CP Record not Found
        if(!cpRecordFound && accountList.size() > 0){
            System.debug('cpRecordNotFound>>>>');
            Lead ld = createLeadRecord(account,leadprojName,unitId);
            System.debug('lead>>>>' + ld);
            if(ld == null) throw new customException('Lead creation failed.');
            
            leadIds.add(ld.Id);
            if(!Test.isRunningTest()){
                String opportunityId = convertLead(leadIds);
                if(String.isBlank(opportunityId)) throw new customException('Lead conversion failed.');
                Communication_Preference__c newCp = createCPRecord(account, ld, opportunityId, leadprojName, unitId);
                System.debug('newCp>>>>' + newCp);
                if(newCp == null) throw new customException('CP creation failed.');
                return createResult(newCp.Id,newCp.Opportunity__c,'DigitalSales record Created Successfully!');
            }
        }
        return createResult(null, null, 'No DigitalSales action was taken.');
    }
    
    public static Lead createLeadRecord(Account acc,String projectName,String unitId){
        List<Lead> ldLIst = new List<Lead>();
        Lead ld = new Lead(
            FirstName = acc.FirstName,
            LastName = acc.LastName,
            Project__c = projectName,
            Unit__c = unitId,
            Email = acc.PersonEmail,
            MobileNumber1__c = acc.MobileNumber1__c != null ? acc.MobileNumber1__c : acc.PersonMobilePhone,
            MobileCountryCode__c = acc.MobileCountryCode__c,
            CountryOfResidence__c = acc.CountryOfResidence__pc,
            Nationality__c = acc.Nationality__pc,
            PropertyUsage__c = 'Residential Sale',
            LeadSource = 'Online',
            EnquiryCategory__c = 'Aldar Apps',
            EnquiryTrigger__c = 'Aldar APP',
            SalesType__c = 'Residential Sale',
            MobilePhone = acc.PersonMobilePhone,
            ResidentStatus__c = acc.ResidentStatus__pc,
            SalesOrigin__c = 'Domestic',
            ExistingAccount__c = acc.Id
        );
        insert ld;
        
        ld.OwnerId = System.Label.Digital_SalesManager;
        LeadFirstMethodOfContactService.skipLeadTrigger = true;
        update ld;
        LeadFirstMethodOfContactService.skipLeadTrigger = false;
        return ld;
    } 
    
    public static Communication_Preference__c createCPRecord(Account acc, Lead ld, String oppoId, String projectName, String unitId){
        
        Communication_Preference__c newCp = new Communication_Preference__c(
            Account__c = acc.Id,
            Category__c = 'Booking',
            Source_Type__c = 'Live Aldar',
            Status__c = 'Fasttrack Completed',
            Active__c = true,
            Contact__c = acc.PersonContactId,
            Project__c = projectName, 
            Unit__c = unitId,
            FastTrack_Completion_Date_Time__c = System.now(),
            Lead__c = ld.Id,
            Opportunity__c = oppoId 
        );
        insert newCp;
        return newCp;
    } 
    
    public static string convertLead(Set<Id> leadIds){
        
        List<Database.LeadConvertResult> leadConversionResult = UtilitiesWithoutSharing.convertLeads(leadIds);
        System.debug('leadConversionResult>>>>' + leadConversionResult);
        if(leadConversionResult == null || leadConversionResult.isEmpty() || !leadConversionResult[0].isSuccess()){
            return null;
        }
        String opportunityId = leadConversionResult[0].getOpportunityId();
        if(String.isBlank(opportunityId)) return null;
        
        Opportunity oppo = new Opportunity(Id = opportunityId,isDigitalSales__c = true,OwnerId = System.Label.Digital_SalesManager); 
        update oppo;
        
        return opportunityId;
    } 
    
    public static Map<String,Object> createResult(Id cpRecordId,Id opportunityId,String message){
        Map<String,Object> result = new Map<String,Object>();
        result.put('recordId', cpRecordId);
        result.put('opportunityId', opportunityId);
        result.put('message', message);
        return result;
    }
}