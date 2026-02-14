/*
* Name               : TestObjectsFactory

* Description        : Test class for getting test data.
* Version			 : V1.1 Added by Protiviti when retail contact logic added.
*/
@isTest
public class TestObjectsFactory {
    
    public static Logger__c createWebServiceLog() {
        
        Logger__c log = new Logger__c();
        insert log;
        return log;
    }
    
    
    public static Account getPersonAccountRecord(){
        Account newAccount = getPersonAccountRecord(181, 'United Arab Emirates', 'V1', 'P1');
        return newAccount ; 
    }
    
    
    public static Account getPersonAccountRecord(Integer eid,String nationality,String visaNo,String passportNo){
        Account newAccount = getAccountRecord(Constants.PERSON_ACCOUNT_RT,true,null);
        newAccount.Nationality__pc = nationality;
        newAccount.PassportNumber__pc = passportNo;
        newAccount.VisaUIDNo__pc = visaNo;
        newAccount.NationalIdNumber__pc = '111111111111111';
        newAccount.Passport_type__pc = 'Ordinary';
        newAccount.CustomerType__c = 'Existing Customer';
        newAccount.BillingStreet = 'Street';
        newAccount.BillingCity = 'Abu Dhabi';
        newAccount.BillingCountry = 'United Arab Emirates';
        newAccount.PassportIssueDate__pc = Date.Today().addDays(-100);
        newAccount.MaritalStatus__pc = 'Single';
        newAccount.PlaceofIssue__pc = 'United Arab Emirates';
        newAccount.PersonEmail = 'test@pwc.com';
        newAccount.PassportExpiryDate__pc = Date.Today().addDays(100);
        newAccount.FirstName = 'Test';
        newAccount.LastName = 'Account';
        newAccount.EmploymentStatus__pc = 'Employed';
        newAccount.Company__pc = 'PWC';
        newAccount.Position__pc = 'Developer';
        newAccount.CompanyAddress__pc = 'Dubai';
        newAccount.AnnualIncome__pc = 1200000;
        newAccount.NoofYearswithCompany__pc = 4;
        newAccount.UAEPassExists__pc = false;
        newAccount.Gender__pc = 'Male';
        newAccount.Nationality__pc = 'United Arab Emirates';
        newAccount.PersonBirthdate = Date.today().addDays(-100);
        newAccount.MobileCountryCode__c = '971';
        newAccount.MobilePhone__pc = '0545127085';
        newAccount.PersonMobilePhone = '0545127085';
        newAccount.MobileNumber__c = '0545127085';
        newAccount.MobileNumber1__c = '0545127085';
        newAccount.BillingState = 'Abu Dhabi';
        newAccount.Industry = 'Technology'; 
        newAccount.SourceofFunds__pc = 'Employment Income'; 
        newAccount.Position__pc = 'CEO';    
        newAccount.Company__pc = 'Company'; 
        newAccount.AnnualIncome__pc = 123.56;   
        newAccount.BankName__c = 'Abu Dhabi Commercial Bank';
        newAccount.BankCountry__c = 'United Arab Emirates';
        newAccount.CustomerBankName__c = 'Bank Name';
        newAccount.CustomerBankCountry__c = 'United Arab Emirates';
        newAccount.NoofYearswithCompany__pc = 1.4;
        newAccount.Workplace_Country__pc    = 'United Arab Emirates';
        newAccount.Workplace_Street__pc	    = 'United Arab Emirates';
        newAccount.Workplace_Postalcode__pc = '00000';
        newAccount.NationalIDIssueDate__c = Date.today().addDays(-10);

        return newAccount ; 
    }
    
    public static Account getOrganisationAccountRecord(String companyName,String registrationNo){
        Account newAccount = getAccountRecord(Constants.ORGANISATION_ACCOUNT_RT,false,null);
        newAccount.Name = companyName;
        newAccount.RegistrationNumber__c = registrationNo;
        return newAccount ; 
    }
    
    public static Account getAgencyAccountRecord(String agencyName,String registrationNo){
        Account newAccount = getAccountRecord(Constants.BROKER_AGENCY_ACCOUNT_RT,false,null);
        newAccount.Name = agencyName;
        newAccount.RegistrationNumber__c = registrationNo;
        return newAccount ; 
    }
    
    public static Account getAccountRecord(String recTypeName, boolean isPersonAccount, String companyID){
        Account newAccount  = new Account();
        newAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(recTypeName).getRecordTypeId();
        if(isPersonAccount){
            newAccount.FirstName = 'Dexter';
            newAccount.LastName = 'Morgan';
            newAccount.Salutation = 'Mr.';
            newAccount.PersonMobilePhone = '4567890';
            newAccount.PersonEmail = 'dexterm@gmail.com';
            newAccount.RecordTypeId='0128d0000015tKBAAY';
        }else{
            newAccount.Name = 'Dexter Laboratory';
            newAccount.Email__c = 'test@aldar.com.invalid';
        }
        newAccount.BillingStreet = 'Kormangala';
        newAccount.BillingCity = 'Bangalore';
        newAccount.BillingState = 'Karnataka';
        newAccount.BillingCountry = 'India';
        newAccount.BillingPostalCode = '526108';
        newAccount.ResidentialAddressSameAsPermanent__c = 'Yes';
        return newAccount;
    }
    
    public static BrokerRequest__c getMarketingReimbursementRecord(Account acc){
        BrokerRequest__c newBrokerRequest = new BrokerRequest__c();
        newBrokerRequest.RecordTypeId = Constants.MARKETING_REIMBURSEMENT_RECORD_TYPE_ID;
        newBrokerRequest.ApprovalStatus__c = Constants.APPROVED_STATUS;
        newBrokerRequest.SyncStatus__c = Constants.STATUS_FAILED;
        newBrokerRequest.AgencyName__c = acc.Id;
        newBrokerRequest.Invoice__c = '12345';
        newBrokerRequest.InvoiceDate__c = Date.today();
        newBrokerRequest.InvoiceAmount__c = 1000;
        newBrokerRequest.TaxAmount__c = 10;
        newBrokerRequest.Comments__c = 'Test Comment';
        
        return newBrokerRequest;
    }
    
    public static BrokerClassification__c getBrokerClassificationRecord() {
        BrokerClassification__c newBrokerClassification = new BrokerClassification__c();
        newBrokerClassification.Name = 'Test';
        newBrokerClassification.AnnualSalesTargetTo__c = 0;
        newBrokerClassification.AnnualSalesTargetFrom__c = 1000000;
        newBrokerClassification.MonthlyMarketingBudget__c = 100000;
        newBrokerClassification.MonthlyMarketingBudgetInternational__c = 100000;
        
        return newBrokerClassification;
    }
    
    public static ContentDocumentLink createContentDocumentLink(String parentId) {
        ContentVersion content = new ContentVersion(); 
        content.Title = 'Test Content';
        content.PathOnClient = '/' + content.Title + '.jpg';
        content.VersionData = Blob.valueOf('Unit Test ContentVersion Body');
        content.Origin = 'H';
        insert content;
        
        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = parentId;
        contentlink.ContentDocumentId = [SELECT ContentDocumentId FROM contentversion WHERE Id =: content.id].ContentDocumentId;
        contentlink.ShareType = 'I';
        contentlink.Visibility = 'AllUsers';
        insert contentlink;
        return contentlink;
    }
    
    public static Lead getLeadToYardiRecord(Integer i,String recTypeName){
        Lead newLead = new Lead();
        newLead.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get(recTypeName).getRecordTypeId();
        newLead.Salutation = 'Dr';
        newLead.FirstName = 'Henry';
        newLead.LastName = 'Wong';
        newLead.Email = 'Henry.Wong@mail.com'+i ;
        
        newLead.MobileCountryCode__c = '971' ;
        newLead.MobileNumber1__c = '52887687' ;
        newLead.MobilePhone = '97152887687' ;
        newLead.SalesOrigin__c = 'Domestic' ;
        newLead.LeadOrigin__c = 'United Arab Emirates' ;
        newLead.LeadSource = '800-Aldar' ;
        newLead.EnquiryCategory__c = 'Kiosk' ;
        newLead.EnquiryTrigger__c = 'Aljimi Mall Kiosk' ;
        newLead.BuyRent__c = 'Rent' ;
        newLead.SalesType__c = 'Asset Management' ;
        newLead.PropertyReadiness__c = 'Ready' ;
        newLead.ResidentStatus__c = 'Resident' ;
        newLead.Project__c = 'Al Bateen Park' ;
        newLead.CustomerLocation__c = 'Abu Dhabi' ;
        newLead.LanguagePreference__c = 'English' ;
        newLead.PurposeOfUse__c= 'Investor';
        newLead.PropertyUsage__c = 'Retail';
        newLead.Financing__c = 'Yes';
        newLead.Mortgage__c = 'Abu Dhabi Commercial Bank';
        newLead.UnitType__c = 'Data Tower';
        newLead.CustomerBudget__c = '75K-AED 100K';
        newLead.NumberOfBedrooms__c = '1BHK';
        newLead.AreaSqmt__c = '10,000-25,000 SQM';
        
        
        newLead.Phone = '97152887687';
        newLead.Status = 'New Lead';
        
        return newLead ; 
    }
    
    public static Lead getLeadRecord(Integer i,String recTypeName){
        Lead newLead = new Lead();
        newLead.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get(recTypeName).getRecordTypeId();
        newLead.Salutation = '';
        newLead.FirstName = 'Henry';
        newLead.LastName = 'Wong';
        newLead.Email = 'Henry.Wong'+i+'@gmail.com' ;
        
        newLead.MobileCountryCode__c = '971' ;
        newLead.MobileNumber1__c = '52887687' ;
        newLead.MobilePhone = '97152887687' ;
        newLead.SalesOrigin__c = 'Domestic' ;
        newLead.LeadOrigin__c = 'United Arab Emirates' ;
        newLead.LeadSource = 'Online' ;
        newLead.EnquiryCategory__c = 'Aldar Websites' ;
        newLead.EnquiryTrigger__c = 'Aldar SMS Campaign' ;
        newLead.BuyRent__c = 'Buy' ;
        newLead.SalesType__c = 'Residential Sale' ;
        newLead.PropertyReadiness__c = '0-3 months' ;
        newLead.ResidentStatus__c = 'Resident' ;
        newLead.Project__c = 'Mamsha Al Saadiyat' ;
        newLead.PropertyUsage__c = 'Residential Sale' ;
        newLead.CustomerLocation__c = 'Abu Dhabi' ;
        newLead.LanguagePreference__c = 'English' ;
        
        newLead.CustomerBudget__c = '300,000 - 499,000';
        newLead.Financing__c = 'No';
        newLead.UnitType__c = 'Apartment';
        newLead.NumberOfBedrooms__c = '1BHK';
        newLead.CustomerType__c = 'New Customer';
        newLead.CustomerSubType__c = 'DOMESTIC';
        newLead.AreaSqmt__c = '2,500-5,000 SQM';
        
        newLead.Phone = '97152887687';
        newLead.Status = 'New Lead';
        newLead.PurposeOfUse__c = 'End User';
        
        return newLead ; 
    }
    /*ECSS*/
      public static Lead getLeadRecordNoRR(Integer i,String recTypeName){
        Lead newLead = new Lead();
        newLead.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get(recTypeName).getRecordTypeId();
        newLead.Salutation = '';
        newLead.FirstName = 'Henry';
        newLead.LastName = 'Wong';
        newLead.Email = 'Henry.Wong'+i+'@gmail.com' ;
        
        newLead.MobileCountryCode__c = '971' ;
        newLead.MobileNumber1__c = '52887687' ;
        newLead.SalesOrigin__c = 'Domestic' ;
        newLead.LeadOrigin__c = 'United Arab Emirates' ;
        newLead.LeadSource = 'Online' ;
        newLead.BuyRent__c = 'Buy' ;
        newLead.SalesType__c = 'Residential Sale' ;
        newLead.PropertyReadiness__c = '0-3 months' ;
        newLead.ResidentStatus__c = 'Resident' ;
        newLead.Project__c = 'Mamsha Al Saadiyat' ;
        newLead.PropertyUsage__c = 'Residential Sale' ;
        newLead.CustomerLocation__c = 'Abu Dhabi' ;
        newLead.LanguagePreference__c = 'English' ;
        newLead.LeadSource = '';
        newLead.CustomerBudget__c = '300,000 - 499,000';
        newLead.Financing__c = 'No';
        newLead.UnitType__c = 'Apartment';
        newLead.NumberOfBedrooms__c = '1BHK';
        newLead.CustomerType__c = 'New Customer';
        newLead.CustomerSubType__c = 'DOMESTIC';
        newLead.AreaSqmt__c = '2,500-5,000 SQM';
        
        newLead.Phone = '97152887687';
        newLead.Status = 'New Lead';
        newLead.PurposeOfUse__c = 'End User';
        
        return newLead ; 
    }
    
    public static Lead getBrokerLeadRecord(Integer i,String recTypeName, String projectName, String BrokerId){
        Lead newLead = new Lead();
        newLead.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get(recTypeName).getRecordTypeId();
        newLead.Salutation = 'Dr';
        newLead.FirstName = 'Henry';
        newLead.LastName = 'Wong';
        newLead.Email = 'Henry.Wong@mail.com'+i ;
        newLead.Phone = '97152887687'+i;
        newLead.Status = Constants.WORKING_LEAD;
        newLead.LeadSource = 'Website';
        newLead.PurposeOfUse__c = 'End User';
        newLead.CustomerBudget__c = 'Not Applicable';
        newLead.PropertyReadiness__c = 'Ready';
        newLead.Financing__c = 'Yes';
        newLead.NumberOfBedrooms__c = 'Studio';
        newLead.LanguagePreference__c = 'English';
        newLead.Project__c = projectName;
        newLead.BrokerAgent__c = BrokerId;
        return newLead ; 
    }
    
    public static Opportunity getOpportunityRecord(Id accountId){
        Opportunity newOppty = new Opportunity();
        newOppty.Name = 'Test Opportunity' ;
        newOppty.Lead_Type__c ='AM Sale';
        //newOppty.Buyerservicecharge__c =1;
        // newOppty.Sellerservicecharge__c =1;
        newOppty.AccountId = accountId ; 
        newOppty.CloseDate = system.today().adddays(10);
        newOppty.StageName = 'New';
        newOppty.ExpectedEndDate__c=System.Today();
        newOppty.EnquiryCategory__c = 'Aldar Employees';
        newOppty.EnquiryTrigger__c = 'Aldar';
        newOppty.SalesTypefromLead__c = 'Commercial Land';
        newOppty.PropertyUsage__c = 'Land';
        newOppty.Project__c = 'Al Falah';
        newOppty.LeadSource = 'Direct Call';
        return newOppty ;
    }
     public static Quote getQuoteRecord(Id opportunityId) {
        Id quoteRecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName()
            .get(System.Label.ECSS_QuoteRecordType)
            .getRecordTypeId();

        Quote newQuote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opportunityId,
            Status = 'Draft', // Make sure this status exists in your org
            ExpirationDate = System.today().addDays(15),
            RecordTypeId = quoteRecordTypeId
        );
        return newQuote;
    }
    
    public static User getUserRecord(String profileName,String userName){
        Profile profileDetail = [SELECT Id FROM Profile WHERE Name=:profileName];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = userName+orgId + dateString + randomInt;
        
        User userRecord = new User(Alias = 'new123', Email=userName+'@'+orgId+'.com', 
                                   EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = profileDetail.Id, ResourceId__c = uniqueName,
                                   TimeZoneSidKey='Asia/Dubai', UserName= uniqueName+'@mail.com');
        return userRecord ; 
    }
    
    public static Project__c getProjectRecord(String projectId){
        Project__c newProject = new Project__c();
        newProject.Name = 'Mayan';
        newProject.ProjectCode__c = 'MAYAN';
        newProject.CommunityName__c = 'Mayan';
        newProject.CommunityNameArabic__c = 'المايا';
        newProject.BusinessUnitId__c = '749';
        //newProject.ProjectID__c = projectId;
        newProject.Country__c = 'United Arab Emirates';
        newProject.City__c = 'Dubai';
        newProject.CurrencyIsoCode = 'AED';
        newProject.StartDate__c = Date.today().addDays(-1);
        newProject.EndDate__c = Date.today().addMonths(5);
        newProject.ReservationAmount__c = 25000;
        newProject.BankNameEscrow__c = 'Abu Dhabi Commercial Bank';
        return newProject ; 
    }
    
    
    public static BuildingSection__c getBuildingDetailRecord(Id projectId){
        BuildingSection__c buildingRecord = new BuildingSection__c();
        buildingRecord.Name = 'Building 1';
        buildingRecord.BuildingSectionCode__c = 'Building 1';
        buildingRecord.Name = 'Building 1';
        buildingRecord.Project__c = projectId ;
        buildingRecord.StartDate__c = Date.today();
        buildingRecord.EndDate__c = Date.today().addMonths(6);
        buildingRecord.CompletionCertificateDate__c =  Date.today().addMonths(8);
        buildingRecord.EligibileforMultiPurposeRoom__c = true ;
        buildingRecord.PropertyManagementFee__c = 10; //added/updated on 26Dec
        
        buildingRecord.EligibleforUnitFinishes__c = true ;
        buildingRecord.RecordTypeId = Schema.SObjectType.BuildingSection__c.getRecordTypeInfosByName().get('Building').getRecordTypeId();
        return buildingRecord ;
    }
    
    public static Unit__c getUnitDetail(Id projectId,Id buildingId){
        Unit__c unitRecord = new Unit__c();
        unitRecord.RecordTypeId = Schema.SObjectType.Unit__c.getRecordTypeInfosByName().get('Unit').getRecordTypeId();
        unitRecord.CurrencyIsoCode = 'AED';
        unitRecord.Name = projectId +'MAYAN-B1-1001';
        unitRecord.ShortNumber__c = '1001';
        unitRecord.Project__c = projectId;
        unitRecord.BuildingSectionName__c = buildingId;
        unitRecord.Status__c = Constants.UNIT_STATUS_AVAILABLE;
        unitRecord.UnitModel__c = '1BHK';
        unitRecord.SellingPrice__c = 52600000;
        unitRecord.FloorNumber__c = '01';
        unitRecord.Unit_Feature_for_Payment_Plan__c = 'Sea View';
        
        unitRecord.UnitType__c = 'Apartment';
        unitRecord.NumberOfBedrooms__c = '1';
        unitRecord.StartDate__c = Date.today();
        unitRecord.Mandatory_Premium__c = True; 
        unitRecord.Mandatory_POD__c = False;    
        unitRecord.PODMultiPurposeRoomPrice__c = 100;   
        unitRecord.PODkitchenPrice__c = 100;
        unitRecord.EndDate__c = Date.today().addMonths(6);
        unitRecord.MultiPurposeAmount__c = 1000;
        unitRecord.PropertyStatus__c = 'Sale';
        unitRecord.AnticipatedServiceCharges__c = 1;
        
        unitRecord.DarcomUnitFolder__c = 'http://darcom/sales/residential/YAS/MAYN/documents/Mayan-B1-1001';
        return unitRecord ; 
    }
    
    public static BookingMemo__c getBookingMemoRecord(String opportunityId)
    {
        BookingMemo__c bookingMemo = new BookingMemo__c();
        bookingMemo.RelatedOpportunity__c = opportunityId;
        bookingMemo.MemoSubject__c = 'Subject';
        bookingMemo.MemoHeader__c = 'Header';
        return bookingMemo;
        
    }
    
    public static MemoLines__c getMemoLineRecord(Id bookingMemoId, Id unitId)
    {
        MemoLines__c memoLine = new MemoLines__c();
        memoLine.BookingMemo__c = bookingMemoId;
        memoLine.Unit__c = unitId;
        memoLine.DiscountPercentage__c = 1;
        memoLine.RebatePercentage__c = 1;
        memoLine.SCWaiverYears__c = 1;
        memoLine.PMFeeYears__c = 1;
        memoLine.HomeMaintenanceYears__c = 1;
        memoLine.ADMFeePercentage__c = 1;
        memoLine.IntCommissionPercentage__c = 1;
        memoLine.BrokerCommissionPercentage__c = 1;
        memoLine.SubsidyPercentage__c = 1;
        memoLine.AdditionalDiscountPercentage__c = 1;
        return memoLine;
    }
    
    public static List<InstallmentLineChanges__c> getInstallmentLineChanges(Id bookingMemoId, Id unitId, Decimal count)
    {
        List<InstallmentLineChanges__c> ilcList = new List<InstallmentLineChanges__c>();
        for (Integer i = 0; i < count; i++) {
            InstallmentLineChanges__c installmentChangesRecord = new InstallmentLineChanges__c();
            installmentChangesRecord.InstallmentNumber__c = i+1;
            installmentChangesRecord.ProposedInstallmentPercentage__c = i;
            installmentChangesRecord.InstallmentAmount__c = 100;
            installmentChangesRecord.ProposedInstallmentDate__c = Date.today();
            installmentChangesRecord.BookingMemo__c = bookingMemoId;
            installmentChangesRecord.Unit__c = unitId;
            installmentChangesRecord.Description__c='Description Added';
            ilcList.add(installmentChangesRecord);
        }
        return ilcList;
    }
    
    public static OpportunityEOI__c getOpportunityEOIRecord(String opportunityId, String paymentMode)
    {
        OpportunityEOI__c opportunityEOI = new OpportunityEOI__c();
        opportunityEOI.InterestFee__c = 1000;
        opportunityEOI.Opportunity__c = opportunityId;
        opportunityEOI.PaymentMode__c = paymentMode;
        opportunityEOI.Status__c = 'Paid';
        
        return opportunityEOI;
    }
    
    public static Unit__c unitDataSetup(String projectId){ 
        Project__c newProject = getProjectRecord(projectId); 
        insert newProject ;
        BuildingSection__c newBuilding = getBuildingDetailRecord(newProject.Id);
        insert newBuilding ;
        Unit__c newUnit = getUnitDetail(newProject.Id,newBuilding.Id);
        return newUnit;
    }
    
    public static Contact contactDataSetup(String accountId){ 
        Contact newcon = new Contact();
        newcon.Lastname='Alice';
        newcon.AccountId=accountId;
        newcon.Email = 'test13@aldar.com';  
        newcon.phone = '527583669'; 
        newcon.MobilePhone = '527583669';
        insert newcon;
        return newcon;
    }
    
    public static EmailTemplate getEmailTemplate(String emailTemplateName, String emailTemplateType) {
        EmailTemplate newEmailTemplate = new EmailTemplate();
        newEmailTemplate.isActive = true;
        newEmailTemplate.Name = emailTemplateName;
        newEmailTemplate.DeveloperName = emailTemplateName;
        newEmailTemplate.TemplateType = emailTemplateType;
        newEmailTemplate.FolderId = UserInfo.getUserId();
        newEmailTemplate.Subject = 'Test Subject';
        newEmailTemplate.HtmlValue = '<p>Test Body</p>';
        newEmailTemplate.Body = 'Test Body';
        return newEmailTemplate;
    }
    
    public static void initializeRestContext(String body, String resourcePath) {
        
        RestContext.request = initializeRestRequest(body, resourcePath, '1.0', 'ios', '13', 'iphone');
        RestContext.response = initializeRestResponse();        
    }
    
    public static void initializeRestContext(String body, String resourcePath, String appVersion, String deviceOS, String deviceOSVersion, String deviceModel) {
        
        RestContext.request = initializeRestRequest(body, resourcePath, appVersion, deviceOS, deviceOSVersion, deviceModel);
        RestContext.response = initializeRestResponse();        
    }
    
    public static RestRequest initializeRestRequest(String body, String resourcePath, String appVersion, String deviceOS, String deviceOSVersion, String deviceModel) {
        
        RestRequest request = new RestRequest();
        
        request.resourcePath = resourcePath;
        
        if (body != null)
            request.requestBody = Blob.valueOf(body);
        
        Map<String, String> headers = new Map<String, String> {
            'App-Version' => appVersion,
                'Device-OS' => deviceOS,
                'Device-OS-Version' => deviceOSVersion,
                'Device-Model' => deviceModel,
                'Build-Number' => '2',
                'Device-Id' => '101010',
                'Device-Brand' => 'Apple'
                };
                    
                    request.headers.putAll(headers);
        
        return request;
    }
    
    
    public static RestResponse initializeRestResponse() {
        
        RestResponse response = new RestResponse();
        return response;
    }
    
    public static MonthlySalesTarget__c getMonthlySalesTargetRecord(String userId, String Team){
        MonthlySalesTarget__c newMonthlySalesTarget = new MonthlySalesTarget__c();
        newMonthlySalesTarget.ResourceName__c = userId;
        newMonthlySalesTarget.Team__c = team;
        newMonthlySalesTarget.TargetMonth__c = String.valueOf(date.today().month());
        newMonthlySalesTarget.TargetYear__c = String.valueOf(date.today().year());
        newMonthlySalesTarget.TargetAmount__c = 100000;
        newMonthlySalesTarget.InventoryTargetAmount__c = 100000;
        newMonthlySalesTarget.LaunchTargetAmount__c = 100000;
        newMonthlySalesTarget.AcceleratorTargetAmount__c = 100000;
        return  newMonthlySalesTarget;
    }
    
    public static ProjectTargets__c getProjectTargetRecord(String projectId){
        ProjectTargets__c newProjectTarget = new ProjectTargets__c();
        newProjectTarget.Project__c = projectId;
        newProjectTarget.BudgetMonth__c = String.valueOf(date.today().month());
        newProjectTarget.BudgetYear__c = String.valueOf(date.today().year());
        newProjectTarget.BudgetAmount__c = 100000;
        newProjectTarget.NumberOfUnits__c = 10;
        return newProjectTarget;
    }
    
    public static ShipmentRequest__c getShipmentRequestRecord(String salesOrderId, String accountId){
        ShipmentRequest__c newShipmentRequest = new ShipmentRequest__c();
        newShipmentRequest.SalesOrder__c = salesOrderId;
        newShipmentRequest.Account__c = accountId;
        newShipmentRequest.Street__c = 'Test';
        newShipmentRequest.City__c = 'Dubai';
        newShipmentRequest.State__c = 'Dubai';
        newShipmentRequest.PostalCode__c = '';
        newShipmentRequest.Country__c = 'United Arab Emirates';
        return newShipmentRequest;
    }
    
    public static SalesOrderCancellation__c getSalesOrderCancellationRecord(String salesCancellationId, String unitId){
        SalesOrderCancellation__c newSalesCancellation = new  SalesOrderCancellation__c();
        newSalesCancellation.SalesOrder__c = salesCancellationId;
        newSalesCancellation.Unit__c = unitId;
        newSalesCancellation.ReasonforCancellation__c = 'Other reason';
        newSalesCancellation.OtherReason__c = 'other reason';
        return  newSalesCancellation;
    }
    
    public static PaymentPlan__c getPaymentPlan() {
        PaymentPlan__c paymentPlan = new PaymentPlan__c();
        paymentPlan.Name = 'Test';
        paymentPlan.Description__c = 'Test';
        paymentPlan.BrokerPortalFlag__c = True;
        paymentPlan.Classification__c = Constants.PAYMENT_PLAN_TYPE_STANDARD;
        return paymentPlan;
    }
    
    public static List<PaymentInstallments__c> getPaymentInstallments(String paymentPlanId, Decimal count) {
        List<PaymentInstallments__c> paymentInstallmentList = new List<PaymentInstallments__c>();
        for (Integer i = 0; i < count; i++) {
            PaymentInstallments__c paymentInstallment = new PaymentInstallments__c();
            paymentInstallment.InstallmentNumber__c = i;
            paymentInstallment.InstallmentPercentage__c = i + 2;
            paymentInstallment.BrokerPayoutPercentage__c = i;
            paymentInstallment.PaymentPlan__c = paymentPlanId;
            paymentInstallment.Description__c = 'Installment Description';
            paymentInstallment.IsHandoverPayment__c = false;
            paymentInstallment.ApprovalStatus__c = 'Approved';
            paymentInstallmentList.add(paymentInstallment);
        }
        return paymentInstallmentList;
    }
    
    public static List<InstallmentLines__c> createInstallmentLines(String salesOrderId, Decimal count) {
        PaymentPlan__c paymentPlan = getPaymentPlan();
        insert paymentPlan;
        
        List<PaymentInstallments__c> paymentInstallmentList = getPaymentInstallments(paymentPlan.Id, count);
        insert paymentInstallmentList;
        
        List<InstallmentLines__c> installmentLineList = new List<InstallmentLines__c>();
        for (PaymentInstallments__c paymentInstallment: paymentInstallmentList) {
            InstallmentLines__c installmentLine = new InstallmentLines__c();
            installmentLine.SalesOrder__c = salesOrderId;
            installmentLine.PaymentPlan__c = paymentPlan.Id;
            installmentLine.InstallmentNumber__c = count--;
            installmentLine.PaymentInstallments__c = paymentInstallment.Id;
            installmentLine.InstallmentNumber__c = paymentInstallment.InstallmentNumber__c;
            installmentLine.InstallmentPercentage__c = paymentInstallment.InstallmentPercentage__c;
            installmentLine.InstallmentAmount__c = 10000;
            installmentLine.InstallmentDate__c = Date.today();
            installmentLine.Description__c = 'Test';
            installmentLineList.add(installmentLine);
        }
        insert installmentLineList;
        return installmentLineList;
    }
    
    public static SalesOrderOtherCharges__c createSalesOrderOtherCharges(String salesOrderId, String accountId) {
        SalesOrderOtherCharges__c salesOrderOtherCharges = new SalesOrderOtherCharges__c();
        salesOrderOtherCharges.SalesOrder__c = salesOrderId;
        salesOrderOtherCharges.Account__c = accountId;
        salesOrderOtherCharges.Amount__c = 10000;
        salesOrderOtherCharges.TypeOfCharge__c = Constants.BUDGET_LINE_ADMFEE;
        
        insert salesOrderOtherCharges;
        return salesOrderOtherCharges;
    }
    
    public static List<OpportunityOfferLine__c> createOpportunityOfferLines(String salesOrderId, Decimal count) {
        List<OpportunityOfferLine__c> opportunityOfferLineList = new List<OpportunityOfferLine__c>();
        for (Integer i = 0; i < count; i++) {
            OpportunityOfferLine__c opportunityOfferLine = new OpportunityOfferLine__c();
            opportunityOfferLine.SalesOrder__c = salesOrderId;
            opportunityOfferLine.OfferValue__c = 10000;
            opportunityOfferLineList.add(opportunityOfferLine);
        }
        insert opportunityOfferLineList;
        return opportunityOfferLineList;
    }
    
    public static CommissionLineItem__c createCommissionLineItems(String salesOrderId, String installmentLineId) {
        CommissionLineItem__c commissionLineItem = new CommissionLineItem__c();
        commissionLineItem.SalesOrder__c = salesOrderId;
        commissionLineItem.CommissionType__c = Constants.COMMISSION_LINE_INTERNAL_COMMISSION;
        commissionLineItem.CommissionPercentage__c = 10;
        commissionLineItem.CommissionAmount__c = 1000;
        commissionLineItem.SalesManager__c = UserInfo.getUserId();
        commissionLineItem.InstallmentLine__c = installmentLineId;
        
        insert commissionLineItem;
        return commissionLineItem;
    }
    
    public static JointOwner__c getJointOwnerRecord(String SalesOrderId, String accountId, String relationshipType){
        JointOwner__c newJointOwner = new JointOwner__c();
        newJointOwner.SalesOrder__c = SalesOrderId;
        newJointOwner.Account__c = accountId;
        newJointOwner.RelationshipType__c = relationshipType;
        newJointOwner.SharePercentage__c = 10;
        return newJointOwner;
    }
    
    public static ReceiptAcknowledgement__c getReceiptAcknowledgementRecord(String salesOrderId, String accountId, String opportunityId, String paymentType){
        ReceiptAcknowledgement__c newReceiptAcknowledgement = new ReceiptAcknowledgement__c();
        newReceiptAcknowledgement.PaymentType__c = paymentType;
        newReceiptAcknowledgement.Amount__c = 100000;
        newReceiptAcknowledgement.SalesOrder__c = salesOrderId;
        newReceiptAcknowledgement.Opportunity__c = opportunityId;
        newReceiptAcknowledgement.Account__c = accountId;
        newReceiptAcknowledgement.Remarks__c = 'Test Remark';
        newReceiptAcknowledgement.CustomerBankAccount__c = '1234567890';
        newReceiptAcknowledgement.ReferenceNumber__c = '1234567890';
        newReceiptAcknowledgement.MortgageCheque__c = true;
        newReceiptAcknowledgement.MaturityDate__c = Date.today();
        return newReceiptAcknowledgement;
    }
    
    public static ReceiptAllocation__c getReceiptAllocationRecord(String receiptAcknowledgementId, String salesOrderId, String accountId, Id parentRecordId){
        ReceiptAllocation__c newReceiptAllocation = new ReceiptAllocation__c();
        newReceiptAllocation.ReceiptAcknowledgement__c = receiptAcknowledgementId;
        newReceiptAllocation.AmountApplied__c = 10000;
        newReceiptAllocation.SalesOrder__c = salesOrderId;
        newReceiptAllocation.Account__c = accountId;
        newReceiptAllocation.DateOfApplication__c = Date.today();
        if (parentRecordId.getSObjectType() == InstallmentLines__c.SObjectType) {
            newReceiptAllocation.TypeOfInvoice__c = Constants.INVOICE_TYPE_INSTALLMENT;
            newReceiptAllocation.InstallmentLine__c = parentRecordId;
        } else {
            newReceiptAllocation.TypeOfInvoice__c = Constants.INVOICE_TYPE_ADM;
            newReceiptAllocation.SalesOrderOtherCharges__c = parentRecordId;
        }
        return newReceiptAllocation;
    }
    
    public static EOIRange__c getEOIRangeRecord(id projectId, id buildingId){
        EOIRange__c newEOIRange =new  EOIRange__c();
        newEOIRange.Project__c = projectId;
        newEOIRange.BuildingSectionName__c= buildingId;
        newEOIRange.UnitFeatures__c= 'P.Sea';
        newEOIRange.UnitModel__c= '1BHK';
        newEOIRange.UnitType__c= 'Pent House';
        newEOIRange.MaxPriceRange__c= 10000;
        newEOIRange.MinPriceRange__c = 5000;
        return  newEOIRange;
    }
    
    public static PriceUpdateRequest__c getPriceUpdateRequestRecord() {
        PriceUpdateRequest__c newPriceUpdateRequest = new PriceUpdateRequest__c();
        newPriceUpdateRequest.RequestedBy__c = UserInfo.getUserId();
        newPriceUpdateRequest.RequestDate__c = Date.today();
        newPriceUpdateRequest.RequestorComments__c = 'Test Requestor Comment';
        return newPriceUpdateRequest;
    }
    
    public static PriceUpdateUnit__c getPriceUpdateUnitRecord(String priceUpdateRequestId, String projectId, String buildingId, String unitId) {
        PriceUpdateUnit__c newPriceUpdateUnit = new PriceUpdateUnit__c();
        newPriceUpdateUnit.RequestNumber__c = priceUpdateRequestId;
        newPriceUpdateUnit.Project__c = projectId;
        newPriceUpdateUnit.Building__c = buildingId;
        newPriceUpdateUnit.Unit__c = unitId;
        newPriceUpdateUnit.CurrentPrice__c = 50000;
        newPriceUpdateUnit.NewPrice__c = 60000;
        newPriceUpdateUnit.UnitStatus__c = Constants.UNIT_STATUS_AVAILABLE;
        return newPriceUpdateUnit;
    }
    public static Case getStandardCase(Id accountId, Id contactId, String category) {
        Case newCase = new Case();
        newCase.RecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('StandardCase').getRecordTypeId();
        newCase.Subject = 'Test Subject';
        newCase.Description = 'Test Description';
        newCase.Status = 'New';
        newCase.AccountId = accountId;
        newCase.ContactId = contactId;
        newCase.Category__c = category;
        newCase.CaseCategory__c = 'Unit Swap';
        newCase.SubVertical__c = 'Defaults & Collection';
        return newCase;
    }
    public static Case getCase(Id accountId, Id contactId, String category) {
        Case newCase = new Case();
        newCase.RecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('BrokerCase').getRecordTypeId();
        newCase.Subject = 'Test Subject';
        newCase.Description = 'Test Description';
        newCase.Status = 'New';
        newCase.AccountId = accountId;
        newCase.ContactId = contactId;
        newCase.Category__c = category;
        return newCase;
    }
    
    public static CaseComment getCaseComment(Id caseId, String comment) {
        CaseComment newCaseComment = new CaseComment();
        newCaseComment.ParentId = caseId;
        newCaseComment.CommentBody = comment;
        return newCaseComment;
    }
    
    public static AccountTeamMember getAccountTeamMember(Id accountId, String accessLevel) {
        AccountTeamMember accountMember = new AccountTeamMember();
        accountMember.AccountId = accountId;
        accountMember.UserId = UserInfo.getUserId();
        accountMember.CaseAccessLevel = Constants.NONE_ACCESS;
        accountMember.OpportunityAccessLevel = Constants.NONE_ACCESS;
        accountMember.AccountAccessLevel = accessLevel;
        accountMember.TeamMemberRole = Constants.TEAM_ROLE_SALES_MANAGER;
        return accountMember;
    }
    
    public static SalesOrder__c getSalesOrderRecord(Id opportunityId,Id accountId){
        SalesOrder__c newSalesOrder=new  SalesOrder__c();
        newSalesOrder.Opportunity__c =opportunityId;
        newSalesOrder.Account__c=accountId;
        newSalesOrder.Status__c = Constants.SALES_STATUS;
        newSalesOrder.Discount__c = 2000;
        newSalesOrder.ADMFeeWaivedAmount__c = 2000;
        newSalesOrder.DARNAAmount__c = 2000;
        newSalesOrder.ExternalCommissionAmount__c = 2000;
        newSalesOrder.HomeMaintenanceWaivedAmount__c = 2000;
        newSalesOrder.InternalCommissionAmount__c = 2000;
        newSalesOrder.ServiceChargeWaivedAmount__c = 2000;
        newSalesOrder.SubsidyAmount__c = 2000;
        newSalesOrder.OtherRebateAmount__c = 2000;
        newSalesOrder.OtherSalesSupportAmount__c = 2000;
        return  newSalesOrder;
    }
    
    public static Task getAgentActivity(Id contactId){
        Task task = new Task();
        task.Subject = 'Task Subject';
        task.whoId = contactId;
        task.ActivityDate = Date.today();
        task.Priority = 'Normal';
        task.Status = 'Open';
        task.AgentActivityHistory__c = true;
        //insert task;
        return task; 
    }
    
    public static Task getLeadActivity(Id leadId){
        Task task = new Task();
        task.Subject = 'Task Subject';
        task.whoId = leadId;
        task.ActivityDate = Date.today();
        task.Priority = 'Normal';
        task.Status = 'Open';
        task.AgentActivityHistory__c = true;
        insert task;
        return task; 
    }
    
    public static Task getAccountActivity(Id accountId){
        Task task = new Task();
        task.Subject = 'Task Subject';
        task.whatId = accountId;
        task.ActivityDate = Date.today();
        task.Priority = 'Normal';
        task.Status = 'Open';
        task.AgentActivityHistory__c = true;
        insert task;
        return task; 
    }
    
    public static Task getOpportunityActivity(Id OpportunityId){
        Task task = new Task();
        task.Subject = 'Task Subject';
        task.whatId = OpportunityId;
        task.ActivityDate = Date.today();
        task.Priority = 'Normal';
        task.Status = 'Open';
        task.AgentActivityHistory__c = true;
        insert task;
        return task; 
    }
    
    public static Document__c getSalesOrderDocument(Id opportunityId, Id orderId)
    {
        Document__c document = new Document__c();
        document.Opportunity__c = opportunityId;
        document.SalesOrder__c = orderId;    
        document.DocumentType__c = 'Sales Offer';
        return document;
        
    }
    
    public static Document__c getProjectDocument(Id projectId)
    {
        Document__c document = new Document__c();
        document.Project__c = projectId;
        //document.SalesOrder__c = orderId;    
        document.DocumentType__c = Constants.DOCUMENT_TYPE_GTC;
        return document;
        
    }
    
    public static AccountRelationship__c getAccountRelationship(Id accountId, Id relatedAccountId, String relationshipType)
    {
        AccountRelationship__c accountRelationship = new AccountRelationship__c();
        accountRelationship.Account__c = accountId;
        accountRelationship.RelatedAccount__c = relatedAccountId;
        accountRelationship.RelationshipType__c = relationshipType;
        
        return accountRelationship;
    }
    
    public static JointOwner__c getJointOwner(Id relatedAccountId, Decimal sharePercentage,  String relationshipType)
    {
        JointOwner__c jointOwner = new JointOwner__c();
        jointOwner.Account__c = relatedAccountId;
        jointOwner.SharePercentage__c = 40;
        jointOwner.RelationshipType__c = relationshipType;
        
        return jointOwner;
    }
    
    public static PaymentPlan__c getPaymentPlanRecord(){
        PaymentPlan__c paymentPlan=new  PaymentPlan__c();
        paymentPlan.Name ='Test';
        paymentPlan.PaymentPlanType__c= PaymentPlan__c.PaymentPlanType__c.getDescribe().getPicklistValues()[0].getValue();
        paymentPlan.Description__c='Test';
        paymentPlan.StandardFlag__c = Constants.YES;
        //paymentPlan.IsActive__c =Constants.YES;
        paymentPlan.Premium__c = 20;
        paymentPlan.PaymentPlanDiscount__c = 2;
        paymentPlan.Classification__c = PaymentPlan__c.Classification__c.getDescribe().getPicklistValues()[0].getValue();
        return  paymentPlan;
    }
    
    public static list<PaymentInstallments__c> getPaymentInstallment(String paymentPlanID){
        list<PaymentInstallments__c> installments=new  list<PaymentInstallments__c>();
        installments.add(new PaymentInstallments__c(Description__c= '1' ,InstallmentNumber__c=1 , InstallmentPercentage__c=10 , BrokerPayoutPercentage__c=50, PaymentPlan__c =paymentPlanID,InstallmentDate__c =System.today()));
        installments.add(new PaymentInstallments__c(Description__c= '2' ,InstallmentNumber__c=2 , InstallmentPercentage__c=40 , BrokerPayoutPercentage__c=50, PaymentPlan__c =paymentPlanID,InstallmentDate__c =System.today()));
        installments.add(new PaymentInstallments__c(Description__c= '3' ,InstallmentNumber__c=3 , InstallmentPercentage__c=25 ,  PaymentPlan__c =paymentPlanID,InstallmentDate__c =System.today()));
        installments.add(new PaymentInstallments__c(Description__c= '4' ,InstallmentNumber__c=4 , InstallmentPercentage__c=25 ,  PaymentPlan__c =paymentPlanID,InstallmentDate__c =System.today(),IsHandoverPayment__c=true));
        return  installments;
    }
    
    public static List<InstallmentLines__c> getInstallmentLines(String soId, String paymentPlanID, list<PaymentInstallments__c> paymentInstallmentList)
    {
        List<InstallmentLines__c> installmentLineList = new List<InstallmentLines__c>();
        Integer installmentNo = 0;
        for(PaymentInstallments__c paymentInstallments : paymentInstallmentList)
        {
            installmentNo++;
            InstallmentLines__c installmentLines = new InstallmentLines__c();
            installmentLines.PaymentPlan__c = paymentPlanID;
            installmentLines.PaymentInstallments__c = paymentInstallments.Id;
            installmentLines.InstallmentNumber__c = installmentNo;
            installmentLines.SalesOrder__c = soId;
            installmentLines.InstallmentAmount__c = 100000;
            installmentLines.InstallmentPercentage__c = 25;
            installmentLines.BrokerPayoutPercentage__c = 20;
            installmentLines.Description__c = 'Description';
            
            installmentLineList.add(installmentLines);
            
        }
        
        return installmentLineList;
        
    }
    
    public static BuildingSectionMapping__c getBuildingSectionMapping(string paymentPlanId, String buildingID){
        BuildingSectionMapping__c mappingRecord = new BuildingSectionMapping__c();
        mappingRecord.BuildingSectionName__c = buildingID;
        mappingRecord.PaymentPlan__c = paymentPlanId;
        return mappingRecord;
    }
    
    public static OffersPromotions__c getOfferPromotion(String building,string project){
        OffersPromotions__c offerRecord = new OffersPromotions__c();
        offerRecord.BuildingSectionName__c=building;
        offerRecord.Project__c=project;
        offerRecord.EndDate__c=System.Today().addDays(5);
        offerRecord.StartDate__c=System.Today().addDays(-5);
        offerRecord.ExtendOffer__c=true;
        offerRecord.OfferName__c='Test Offer';
        offerRecord.SalesEventCampaignName__c='Test Offer';
        return offerRecord;
    }
    
    public static OfferLines__c getOfferLine(String OfferId){
        OfferLines__c offerLinesRecord = new OfferLines__c();
        offerLinesRecord.OfferName__c = OfferId;
        offerLinesRecord.OfferType__c = 'Additional Discount';
        offerLinesRecord.DiscountType__c = 'Additional Discount';
        offerLinesRecord.OfferOn__c = 'Selling Price';
        offerLinesRecord.OfferValue__c = 10;
        offerLinesRecord.OfferValueType__c = '%';
        offerLinesRecord.Nationality__c=null;
        offerLinesRecord.BudgetTaskName__c = Constants.BUDGET_LINE_DISCOUNT;
        return offerLinesRecord;
    }
    
    public static RoundRobinAssignmentMatrix__c getAssignmentRecord(string userId){
        RoundRobinAssignmentMatrix__c rrRecord = new RoundRobinAssignmentMatrix__c();
        rrRecord.AgentThreshold__c=100;
        rrRecord.CurrentLoad__c=0;
        rrRecord.LastAssignmentTime__c =System.now().addDays(-4);
        rrRecord.Status__c=Constants.STATUS_AVAILABLE;
        rrRecord.User__c=userId;
        return rrRecord;
    }
    
    public static AllocationGroup__c getAllocationGroup(String groupName, String groupCode){
        AllocationGroup__c newGroup = new AllocationGroup__c();
        newGroup.Name = groupName;
        newGroup.StartDate__c = Date.today().addDays(-1);
        newGroup.EndDate__c = Date.today().addDays(30);
        newGroup.AllocationGroupCode__c = groupCode;
        return newGroup ; 
    }
    
    public static AllocationGroupUser__c getAllocationGroupUser(User userDetail,AllocationGroup__c allocationGroup){
        AllocationGroupUser__c newGroupUser = new AllocationGroupUser__c();
        newGroupUser.AllocationGroup__c = allocationGroup.Id;
        newGroupUser.StartDate__c = allocationGroup.StartDate__c;
        newGroupUser.EndDate__c = allocationGroup.EndDate__c;
        newGroupUser.User__c = userDetail.Id ;
        return newGroupUser ; 
    }
    
    public static ProjectBudget__c getProjectBudget(){
        ProjectBudget__c projectBudget = new ProjectBudget__c();
        projectBudget.ProjectCode__c = 'A439020';
        projectBudget.ProjectId__c = '28486';
        projectBudget.ProjectNameProjectCosting__c = 'Waters Edge Precinct A';
        projectBudget.Name = 'Waters Edge Precinct A';
        return projectBudget ; 
    }
    
    public static BudgetLines__c getProjectBudgetLines(String budgetLineName,String taskNumber,Id projectId,String budgetCategory){
        BudgetLines__c budgetLine = new BudgetLines__c();
        budgetLine.Name = budgetLineName;
        budgetLine.TaskNumber__c = taskNumber;
        budgetLine.TotalBudget__c = 200000000 ;
        budgetLine.ERPBudgetActual__c = 100000000;
        budgetLine.ERPBudgetAvailable__c = 100000000;
        budgetLine.ERPBudgetCommitment__c = 100000000;
        budgetLine.ERPBudgetUtilized__c = 100000000;
        budgetLine.OriginalBudget__c = 200000000;
        budgetLine.ProjectName__c = projectId;
        budgetLine.TaskName__c = budgetLineName;
        budgetLine.BudgetCategory__c = budgetCategory;
        budgetLine.BudgetConsumptionType__c = 'Actual';
        return budgetLine ; 
    }
    
    public static SalesOrder__c getSalesOrderData(Boolean isSaleCancellation,String unitCode) {
        
        Account newAccount = getPersonAccountRecord();
        insert newAccount ; 
        
        Opportunity opp = getOpportunityRecord(newAccount.Id);
        insert opp;
        
        Unit__c unit = unitDataSetup(unitCode);
        unit.Name = unitCode ;
        insert unit;
        
        SalesOrder__c salesOrder = getSalesOrderRecord(opp.Id, newAccount.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.IsBookingCompleted__c = true;
        insert salesOrder;
        
        List<InstallmentLines__c> installmentLineList = createInstallmentLines(salesOrder.Id, 5);
        createSalesOrderOtherCharges(salesOrder.Id, newAccount.Id);
        createOpportunityOfferLines(salesOrder.Id, 5);
        createCommissionLineItems(salesOrder.Id, installmentLineList[0].Id);
        
        if (isSaleCancellation) {
            SalesOrderCancellation__c salesCancellation = getSalesOrderCancellationRecord(salesOrder.Id, unit.Id);
            insert salesCancellation;
        }
        
        return salesOrder;
    }
    
    public static InternalCommission__c getInternalCommission() {
        InternalCommission__c internalCommission = new InternalCommission__c();
        internalCommission.DirectCommission__c = 2.5;
        internalCommission.IndirectCommission__c = 1.5;
        internalCommission.LandDirectCommission__c = 2.0;
        internalCommission.LandIndirectCommission__c = 1.0;
        internalCommission.StaffReferral__c = 2.5;
        internalCommission.VIPDirectCommission__c = 1.5;
        internalCommission.VIPIndirectCommission__c = 0.5;
        internalCommission.UserRole__c = 'Sales Manager';
        internalCommission.InventoryLaunchCategory__c = 'Launch';
        internalCommission.StartDate__c = Date.today();
        internalCommission.EndDate__c = Date.today().addDays(30);
        internalCommission.SalesValueFrom__c = 0;
        internalCommission.SaleValueTo__c = 1000000000;
        return internalCommission;
    }
    
    public static BrokerCommission__c getBrokerCommission(Id projectId) {
        BrokerCommission__c brokerCommission = new BrokerCommission__c();
        brokerCommission.BrokerType__c = 'Domestic';
        brokerCommission.Project__c = projectId;
        brokerCommission.CommissionPercentage__c = 2.5;
        brokerCommission.SaleType__c = 'New Sale';
        brokerCommission.UnitView__c = 'Sea View';
        brokerCommission.UnitType__c = 'Studio';
        brokerCommission.UnitCategory__c = 'S-4';
        brokerCommission.StartDate__c = Date.today();
        brokerCommission.EndDate__c = Date.today().addDays(30);
        return brokerCommission;
    }
    
    public static BookingDetailModel getBookingModel(Unit__c unitRecord){
        
        BookingDetailModel bookingdetail = new BookingDetailModel();
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity oppRecord = TestObjectsFactory.getOpportunityRecord(acc.Id);
        oppRecord.DeliveryMethod__c = 'Email';
        oppRecord.SaleType__c = 'New Sale';
        oppRecord.AgentType__c = 'Direct';
        oppRecord.BookingType__c = 'Online';
        oppRecord.DealType__c = 'Standard';
        insert oppRecord;
        
        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        insert paymentPlanRecord;
        List<PaymentInstallments__c> installmentLines = TestObjectsFactory.getPaymentInstallment(paymentPlanRecord.Id);
        insert installmentLines;
        paymentPlanRecord.IsActive__c = Constants.YES;
        update paymentPlanRecord;
        
        BuildingSectionMapping__c buldingPaymentMapping = TestObjectsFactory.getBuildingSectionMapping(paymentPlanRecord.Id,unitRecord.BuildingSectionName__c);
        insert buldingPaymentMapping;    
        
        OffersPromotions__c offerRecord= TestObjectsFactory.getOfferPromotion(unitRecord.BuildingSectionName__c,unitRecord.Project__c);
        insert offerRecord;
        OfferLines__c offerLine = TestObjectsFactory.getOfferLine(offerRecord.Id);
        insert offerLine;
        
        List<SalesOfferUtility.SaleOfferInputParam> salesOfferInputList = new List<SalesOfferUtility.SaleOfferInputParam>();
        SalesOfferUtility.SaleOfferInputParam unitInput = new SalesOfferUtility.SaleOfferInputParam();
        unitInput.unitId = unitRecord.Id;
        unitInput.offerId = offerRecord.Id;
        unitInput.multiPurposeAmountApplicable =true;
        unitInput.paymentMethod ='';
        unitInput.amount =0;
        unitInput.amountType ='';
        unitInput.unitFinishes ='Cool';
        unitInput.selectedPayments = new List<ID>{paymentPlanRecord.Id};
            salesOfferInputList.add(unitInput);
        
        bookingdetail = new BookingDetailModel();
        bookingdetail.accountId = acc.Id ;
        bookingdetail.opportunityId = oppRecord.Id ;
        bookingdetail.inputWrapperList = salesOfferInputList ;
        bookingdetail.unitIds = new Set<Id>{unitRecord.Id};
            bookingdetail.affectionPlan = true ;
        bookingdetail.marketingPlan = true ;
        return bookingdetail ;
        
    }
    
    // Cretae Pricing
    public static HexaBPM__Pricing_Line__c createSRPriceItem(){
        HexaBPM__Pricing_Line__c pricing = new HexaBPM__Pricing_Line__c();
        pricing.HexaBPM__Priority__c = 1;
        return pricing;
    }
    
    // Create Product
    public static List<Product2> createProduct(List<String> productCodes){
        List<Product2> products = new List<Product2>();
        for(String eachCode : productCodes)
        {
            Product2 pro2 = new Product2(Name='BXCD',ProductCode=eachCode, isActive=true);
            products.add(pro2);
        }
        return products;
    }
    
    // Create HexaBPM__SR_Price_Item__c    
    public static List<HexaBPM__SR_Price_Item__c> createSRPriceItem(List<Product2> products,String srId, String pricingId) {
        List<HexaBPM__SR_Price_Item__c> listSRPriceItem = new List<HexaBPM__SR_Price_Item__c>();
        for(Product2 prod : products){
            HexaBPM__SR_Price_Item__c createdSRPriceItem = new HexaBPM__SR_Price_Item__c();
            createdSRPriceItem.HexaBPM__ServiceRequest__c = srId;
            createdSRPriceItem.HexaBPM__Price__c = 40;
            createdSRPriceItem.HexaBPM__Pricing_Line__c = pricingId;
            createdSRPriceItem.HexaBPM__Product__c = prod.id;
            createdSRPriceItem.HexaBPM__Status__c = 'Added';
            listSRPriceItem.add(createdSRPriceItem);        
        }
        return listSRPriceItem;
    }
    
    public class ResponseWrapper {
        
        public String errorMessage;
        public Account acc;
        public Contact con;
        public Case caseObj;
        public Opportunity opp;
        public Lead leadObj;
        public User user;
        public HexaBPM__Service_Request__c srObj;
        public HexaBPM__Document_Master__c srDocMaster;
        public HexaBPM__SR_Doc__c srDoc;
        public HexaBPM__Step_Template__c steptemp;
        public HexaBPM__SR_Template__c srTemp;
        public HexaBPM__Step__c stpObj;
        public HexaBPM__Page_Flow__c pgFlowObj;
        public HexaBPM__Page__c pgObj;
        public HexaBPM__Section__c secObj;
        public HexaBPM__Section_Detail__c secDetObj;
        public HexaBPM__Step_Template__c stptemp;
        public ContentDocumentLink CDL;
        public HexaBPM__SR_Steps__c srSteps;
        public HexaBPM__SR_Status__c srStatus;
        
        public ResponseWrapper() {
        }
    }
    
    static Map<String, Id> accRecordTypes = new Map<String, Id>();
    
    //create a map for SR recordtypes
    public static void accRecordtypesMap(){
        for(Recordtype rt : [Select Id, DeveloperName FROM RecordType
                             WHERE SObjectType = 'Account']){
                                 accRecordTypes.put(rt.DeveloperName, rt.Id);
                             }
    }
    
    public static ResponseWrapper createInitialData(String recordTypeName , String FSRADivition,String FSRAFormType){
        
        accRecordtypesMap();
        
        ResponseWrapper respWrap = new ResponseWrapper();
        
        Map<String, Set<String>> sectorDep = getFieldDependencies('Account','CustomerType__c','CustomerSubType__c');
        
        Account newAccount = getOrganisationAccountRecord('Test Org', 'G123456');
        for (string sector : sectorDep.keySet()) {
            Set<String> validDivisions = sectorDep.get(sector);
            for (string division : validDivisions) {
                if (division.toLowerCase() == FSRADivition.toLowerCase()) {
                    break;
                }
            }
        }
        
        insert newAccount;
        respWrap.acc = newAccount;
        
        Contact newContact = new Contact();
        newContact.AccountId = newAccount.id  ;
        newContact.FirstName = 'FirstName';
        newContact.LastName = 'LastName';
        newContact.Email = 'testemail@test.com';
        insert newContact;
        respWrap.con = newContact;
        
        Id p = [select id from profile where name='Agency Admin'].id;      
        
        
        User user = new User(alias = 'tsoe123', email='test123112233@noemail.com',
                             emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                             localesidkey='en_US', profileid = p, country='United States',IsActive =true,
                             ContactId = newContact.Id,
                             timezonesidkey='America/Los_Angeles', username='tester11223344@112233noemail.com');
        
        insert user;
        respWrap.user = user;
        
        return respWrap;
        
    }
    
    public class MyPickListInfo{
        public String validFor;
    }
    
    public static Map<String, Set<String>> getFieldDependencies(String objectName, String controllingField, String dependentField){
        Map<String, Set<String>> controllingInfo = new Map<String, Set<String>>();
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult describeResult = objType.getDescribe();
        Schema.DescribeFieldResult controllingFieldInfo = describeResult.fields.getMap().get(controllingField).getDescribe();
        Schema.DescribeFieldResult dependentFieldInfo = describeResult.fields.getMap().get(dependentField).getDescribe();
        List<Schema.PicklistEntry> controllingValues = controllingFieldInfo.getPicklistValues();
        List<Schema.PicklistEntry> dependentValues = dependentFieldInfo.getPicklistValues();
        for(Schema.PicklistEntry currControllingValue : controllingValues){
            controllingInfo.put(currControllingValue.getValue(), new Set<String>());
        }
        for(Schema.PicklistEntry currDependentValue : dependentValues){
            String jsonString = JSON.serialize(currDependentValue);
            MyPickListInfo info = (MyPickListInfo) JSON.deserialize(jsonString, MyPickListInfo.class);
            String hexString = EncodingUtil.convertToHex(EncodingUtil.base64Decode(info.validFor)).toUpperCase();
            Integer baseCount = 0;
            for(Integer curr : hexString.getChars()){
                Integer val = (curr >= 65)?(curr - 65 + 10):(curr - 48);
                    if((val & 8) == 8){
                        controllingInfo.get(controllingValues[baseCount + 0].getValue()).add(currDependentValue.getLabel());
                    }
                if((val & 4) == 4){
                    controllingInfo.get(controllingValues[baseCount + 1].getValue()).add(currDependentValue.getLabel());
                }
                if((val & 2) == 2){
                    controllingInfo.get(controllingValues[baseCount + 2].getValue()).add(currDependentValue.getLabel());
                }
                if((val & 1) == 1){
                    controllingInfo.get(controllingValues[baseCount + 3].getValue()).add(currDependentValue.getLabel());
                }
                baseCount += 4;
            }            
        }
        return controllingInfo;
    }
    
    static Map<String, Id> srRecordTypes = new Map<String, Id>();
    
    public static void srRecordtypesMap(){
        for(Recordtype rt : [Select Id, DeveloperName FROM RecordType
                             WHERE SObjectType = 'HexaBPM__Service_Request__c']){
                                 srRecordTypes.put(rt.DeveloperName, rt.Id);
                             }
    }
    
    // create document Master
    public static ResponseWrapper createSrData(String srRecordType,string FSRAFormType ,string accountId, string docCode) {
        
        
        ResponseWrapper respWrap = new ResponseWrapper();
        srRecordtypesMap();  
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = new HexaBPM__SR_Template__c();
        SRTemplateDetailRecord.HexaBPM__Active__c = true;
        SRTemplateDetailRecord.HexaBPM__SR_RecordType_API_Name__c = srRecordType;
        insert SRTemplateDetailRecord;
        respWrap.srTemp = SRTemplateDetailRecord;
        
        //pages
        HexaBPM__Page_Flow__c pf = new HexaBPM__Page_Flow__c();
        pf.Name = 'New Page Flow ';
        pf.HexaBPM__Flow_Description__c   = pf.Name + '_Description';
        pf.HexaBPM__Master_Object__c  = 'HexaBPM__Service_Request__c';
        pf.HexaBPM__Record_Type_API_Name__c   = srRecordType;
        insert pf;
        respWrap.pgFlowObj = pf;
        
        HexaBPM__Page__c page = new HexaBPM__Page__c();
        page.HexaBPM__No_Quick_navigation__c = true;
        page.HexaBPM__Is_Custom_Component__c = false;
        page.HexaBPM__Page_Description__c = 'Test Page Description';
        page.HexaBPM__Page_Flow__c = pf.id;
        page.HexaBPM__Page_Order__c = 1;
        page.HexaBPM__Render_By_Default__c = true;
        page.HexaBPM__VF_Page_API_Name__c = 'PageFlow';
        page.HexaBPM__What_Id__c = '';
        insert page;
        respWrap.pgObj = page;
        
        HexaBPM__Section__c section = new HexaBPM__Section__c(HexaBPM__Page__c = page.Id);
        section.HexaBPM__Section_Type__c = 'CommandButtonSection';
        insert section;
        respWrap.secObj = section;
        
        HexaBPM__Section_Detail__c sectionDetail = new HexaBPM__Section_Detail__c(HexaBPM__Section__c = section.Id);
        insert sectionDetail;
        respWrap.secDetObj = sectionDetail;
        
        
        HexaBPM__SR_Status__c objSRStatus = new HexaBPM__SR_Status__c();
        objSRStatus.Name = 'Draft';
        objSRStatus.HexaBPM__Code__c = 'Draft';
        //objSRStatus.HexaBPM__Type__c = '' ;
        
        insert objSRStatus;
        respWrap.srStatus = objSRStatus;
        
        //steps
        
        HexaBPM__Step_Template__c objStepTemplate = new HexaBPM__Step_Template__c();
        objStepTemplate.Name = srRecordType;
        objStepTemplate.HexaBPM__Code__c = srRecordType;
        objStepTemplate.HexaBPM__Step_RecordType_API_Name__c = srRecordType;
        objStepTemplate.HexaBPM__Summary__c = 'test';
        insert objStepTemplate;
        respWrap.stptemp =  objStepTemplate;
        
        HexaBPM__SR_Steps__c objSRSteps = new HexaBPM__SR_Steps__c();
        objSRSteps.HexaBPM__SR_Template__c = SRTemplateDetailRecord.Id;
        objSRSteps.HexaBPM__Step_Template__c = objStepTemplate.Id;
        //objSRSteps.HexaBPM__Start_Status__c = listStatus.size() >= i ? listStatus[i-1].id : listStatus[0].id;
        objSRSteps.HexaBPM__Active__c=true;
        insert objSRSteps;
        respWrap.srSteps = objSRSteps;
        
        
        HexaBPM__Service_Request__c newSR = new HexaBPM__Service_Request__c();
        newSR.HexaBPM__Customer__c = accountId;
        newSR.HexaBPM__External_SR_Status__c =  objSRStatus.Id;
        newSR.HexaBPM__Internal_SR_Status__c =  objSRStatus.Id;
        newSR.HexaBPM__SR_Template__c = SRTemplateDetailRecord.Id;
        newSR.SRType__c = '';
        insert newSR;
        respWrap.srObj = newSR;
        
        Case caseObj = new Case();
        caseObj.AccountId = accountId;
        insert caseObj;
        respWrap.caseObj = caseObj;
        
        
        /* Supplementary_Application__c supp = new Supplementary_Application__c();
insert supp;
respWrap.suppObj = supp; */
        
        HexaBPM__Step__c newStep = new HexaBPM__Step__c();
        newStep.HexaBPM__SR__c = newSR.id;
        newStep.HexaBPM__Due_Date__c = System.Now().addDays(2);
        newStep.HexaBPM__Step_No__c = 10;
        newStep.HexaBPM__SR_Step__c = objSRSteps.Id;
        newStep.HexaBPM__Step_Template__c = objStepTemplate.id;
        newStep.HexaBPM__Step_Notes__c = 'test';
        insert newStep;
        respWrap.stpObj =  newStep;
        
        
        
        HexaBPM__Document_Master__c objDocMaster = new HexaBPM__Document_Master__c();
        objDocMaster.HexaBPM__Code__c = DocCode;
        objDocMaster.HexaBPM__Available_to_client__c = true;
        insert objDocMaster;
        respWrap.srDocMaster = objDocMaster;
        
        HexaBPM__SR_Template_Docs__c docTemp = new HexaBPM__SR_Template_Docs__c();
        docTemp.HexaBPM__Document_Master__c = objDocMaster.id ;
        insert docTemp;
        
        
        HexaBPM__SR_Doc__c objSRDoc = new HexaBPM__SR_Doc__c();
        objSRDoc.HexaBPM__Document_Master__c = objDocMaster.id  ;
        objSRDoc.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDoc.HexaBPM__Service_Request__c = newSR.id  ;
        insert objSRDoc;
        respWrap.srDoc = objSRDoc;
        
        ContentVersion contentVersionInsert = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.pdf',
            VersionData = Blob.valueOf('Test Content Data'),
            IsMajorVersion = true
        );
        insert contentVersionInsert;
        List<ContentDocument> documents = [SELECT Id, Title,
                                           LatestPublishedVersionId FROM ContentDocument];
        objSRDoc.HexaBPM__Doc_ID__c = documents[0].Id;
        update objSRDoc;
        //create ContentDocumentLink  record
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = objSRDoc.id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'V';
        insert cdl;
        respWrap.CDL = cdl;
        
        
        
        return respWrap;
    }
    
    public static Document__c getAccountDocument(Id accountId)
    {
        Document__c document = new Document__c();
        document.Account__c = accountId;
        document.DocumentType__c = 'KYC Form';
        return document;
    }
    public static HexaBPM__SR_Template__c getSRTemplate(String recordTypeAPI){
        HexaBPM__SR_Template__c SRTemplateDetailRecord = new HexaBPM__SR_Template__c();
        SRTemplateDetailRecord.HexaBPM__Active__c = true;
        SRTemplateDetailRecord.HexaBPM__SR_RecordType_API_Name__c = recordTypeAPI;
        return SRTemplateDetailRecord;
    }
    public static BankVirtualAccounts__c getBankVirtualAccounts(){
        BankVirtualAccounts__c va = new BankVirtualAccounts__c();
        Integer randomNumber = Integer.valueOf(math.rint(math.random()*1000000));
        String name = 'AE'+randomNumber;
        va.VirtualAccountNumber__c = name;
        va.BankName__c = 'ADCB';
        return va;
    }
    
    public static HexaBPM__Step_Template__c getStepTemplate(String Name, String recordTypeAPI){
        HexaBPM__Step_Template__c objStepTemplate = new HexaBPM__Step_Template__c();
        objStepTemplate.Name = Name;
        objStepTemplate.HexaBPM__Code__c = Name;
        objStepTemplate.HexaBPM__Step_RecordType_API_Name__c = recordTypeAPI;
        objStepTemplate.HexaBPM__Summary__c = 'test';
        return objStepTemplate;
    }
    
    public static HexaBPM__SR_Steps__c getSRStep(String srTemplateId, String stepTemplateId){
        HexaBPM__SR_Steps__c objSRSteps = new HexaBPM__SR_Steps__c();
        objSRSteps.HexaBPM__SR_Template__c = srTemplateId;
        objSRSteps.HexaBPM__Step_Template__c = stepTemplateId;
        objSRSteps.HexaBPM__Active__c=true;
        return objSRSteps;
    }
    
    public static HexaBPM__SR_Status__c getSRStatus(String name){
        HexaBPM__SR_Status__c draft = new HexaBPM__SR_Status__c();
        draft.Name = name;
        draft.HexaBPM__Code__c = name;
        return draft;
    }
    
    public static HexaBPM__Service_Request__c getServiceRequest(String srStatus, String unitId, String srType, String recordTypeId, String srTemplateId){
        HexaBPM__Service_Request__c newSR = new HexaBPM__Service_Request__c();
        newSR.HexaBPM__External_SR_Status__c =  srStatus;
        newSR.HexaBPM__Internal_SR_Status__c =  srStatus;
        newSR.Unit__c = unitId;
        newSR.SRType__c = srType;
        newSR.recordTypeId = recordTypeId;
        newSR.HexaBPM__SR_Template__c = srTemplateId;
        return newSR;
    }
    
    public static HexaBPM__Step__c getServiceRequestStep(String serviceRequestId, String srStepId, String srTemplateId){
        HexaBPM__Step__c newStep = new HexaBPM__Step__c();
        newStep.HexaBPM__SR__c = serviceRequestId;
        newStep.HexaBPM__Due_Date__c = System.Now().addDays(2);
        newStep.HexaBPM__Step_No__c = 10;
        newStep.HexaBPM__SR_Step__c = srStepId;
        newStep.HexaBPM__Step_Template__c = srTemplateId;
        newStep.HexaBPM__Step_Notes__c = 'test';
        return newStep;
    }
    
    public static Case getCaseRecord(Id recordTypeId, String caseType, Id unitId, String caseOrigin){
        Case newCase = new Case();
        newCase.recordTypeId = recordTypeId;
        newCase.Type = caseType;
        newCase.Unit__c = unitId;
        newCase.Origin = caseOrigin;
        
        return newCase;
    }
    
    public static ChargeRule__c getChargeRuleRecord(String srtype, String chargeType){
        ChargeRule__c cr = new ChargeRule__c();
        cr.ChargeAmount__c = 2000;
        cr.ChargeType__c = chargeType;
        cr.EndDate__c = Date.Today().addDays(100);
        cr.IsActive__c = TRUE;
        cr.SRType__c = srtype;
        cr.StartDate__c = Date.Today().addDays(-100);
        
        return cr;
    }
    
    public static SRUnitSelected__c getSRUnitSelected(String unitNo, String srId, String soId, String unitId){
        SRUnitSelected__c srUnitSelected = new SRUnitSelected__c();
        srUnitSelected.Name = unitNo;
        srUnitSelected.ServiceRequest__c = srId;
        srUnitSelected.SalesOrder__c = soId;
        srUnitSelected.Unit__c = unitId;
        srUnitSelected.OptionSelected__c = Constants.REFUND_OPTION_2;
        srUnitSelected.ServiceCharge__c = 1000;
        srUnitSelected.DistrictCooling__c = 1000;
        srUnitSelected.ADDCAssumption__c = 1000;
        srUnitSelected.LegalfeesVAT__c = 1000;
        srUnitSelected.ADMWaiverPercentage__c = 2;
        srUnitSelected.RebatePercentage__c = 3;
        srUnitSelected.DarnaPercentage__c = 0.5;
        srUnitSelected.SalesSupportCostAED__c = 1000;
        srUnitSelected.VoucherAED__c = 1000;
        srUnitSelected.SCWaiverYears__c = 2;
        srUnitSelected.SCWaivedAmount__c = 1000;
        srUnitSelected.ExternalCommission__c = 3;
        srUnitSelected.InternalCommission__c = 0.5;
        
        return srUnitSelected;
    }
    
    public static DirectDebitRequest__c createDirectDebitRecords(String salesOrderId){
        
        DirectDebitRequest__c ddr = new DirectDebitRequest__c();
        ddr.CustomerIdType__c = 'Passport';
        ddr.CustomerIDNumber__c = '1234567890';
        ddr.CustomerBankAccountType__c = 'Savings';
        ddr.CustomerAccountName__c = 'Test';
        ddr.CustomerBankName__c = 'Abu Dhabi Commercial Bank';
        ddr.CustomerIBANNumber__c = 'AE123456789012345678901';
        ddr.Status__c = 'Approved by Bank';
        ddr.SalesOrder__c = salesOrderId;
        return ddr;
    }
    
    public static DDTransaction__c createDDTransactions(String directDebitRequestId, String bankName){
        DDTransaction__c DDtransaction  = new DDTransaction__c();   
        DDtransaction.DirectDebitRequest__c = directDebitRequestId;
        DDtransaction.DDBank__c = bankName;
        DDtransaction.Requesttype__c = 'New Registration';
        DDtransaction.TransactionStatus__c = 'Unprocessed';
        DDtransaction.DDResponse__c = 'Test';
        return DDtransaction;
    }
    public static Document__c getDDRDocument(Id ddrId) {
        Document__c document = new Document__c();
        document.DirectDebitRequest__c = ddrId;
        document.DocumentType__c = 'Signed direct debit registration form';
        return document;
    }
    
    public static DDResponseFiles__c getDDResponseFile(){
        DDResponseFiles__c file = new DDResponseFiles__c();
        file.Status__c = 'Unprocessed';
        return file ; 
    }
    
    public static ContentVersion getContentVersion() {
        ContentVersion content = new ContentVersion(); 
        content.Title = 'Test Content';
        content.PathOnClient = '/' + content.Title + '.jpg';
        content.VersionData = Blob.valueOf('Date Processed|Request Type|OIC|Payer Identification|DDA Reference|Customer Type|Customer ID Type|Customer ID Number|Bank Name|Title of Account|Account Type|IBAN / Card Number|Mobile Number|Email|Issued For|Commences On|Expires On|Amount Type|Payment Frequency|Minimum Amount|Maximum Amount|Currency Code|First Initiation Date|Frequency Parameter|Image File Name| |  |   |RCMS|ACK / NAK|Action|Accept / Reject|Reason of Rejection + Additional Comments of rejection reason NAKHR25-JAN-2023|ADD|365000507|Mayan-B2-06-07-DD-00111||Individual|NID|784197551973585|First Abu Dhabi Bank|Shridhar Mahesh Murdeshwar|Savings|AE880351001001197052363|+971525445897|mbajaria@aldar.com|Contribution|24/01/2023|30/06/2026|Variable|D|1.00|10.00|AED|25/01/2023||C30000300010523012422.pdf||||NA|ACK|INITIATED||Invalid data 25-JAN-2023|ADD|365000507|Mayan-B2-06-07-DD-00112||Individual|NID|784197551973585|Abu Dhabi Commercial Bank|Shridhar Mahesh Murdeshwar|Savings|AE720030000701057132001|+971525445897|mbajaria@aldar.com|Contribution|24/01/2023|30/06/2026|Variable|D|1.00|10.00|AED|25/01/2023||DMS DOC :0912eb47800293f1||||NA|ACK|INITIATED|| 25-JAN-2023|ADD|365000507|Mayan-B2-06-07-DD-00113||Individual|NID|784197551973585|Mashreqbank|Shridhar Mahesh Murdeshwar|Savings|AE260330000010490732726|+971525445897|mbajaria@aldar.com|Contribution|24/01/2023|30/06/2026|Variable|D|1.00|10.00|AED|25/01/2023||DMS DOC :0912eb478002993a||||NA|ACK|INITIATED|| 25-JAN-2023|ADD|365000507|Mayan-B2-06-07-DD-00114||Individual|NID|784197551973585|First Abu Dhabi Bank|Shridhar Mahesh Murdeshwar|Savings|AE190351011221018122141|+971525445897|mbajaria@aldar.com|Contribution|24/01/2023|30/06/2026|Variable|D|1.00|10.00|AED|25/01/2023||DMS DOC :0912eb47800293f3||||NA|ACK|INITIATED||');
        content.Origin = 'H';
        return content;
    }
    
    public static ContentDocumentLink insertContentDocumentLink(String ParentId, String contentId) {
        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = parentId;
        contentlink.ContentDocumentId = [SELECT ContentDocumentId FROM contentversion WHERE Id =: contentId].ContentDocumentId;
        contentlink.ShareType = 'I';
        contentlink.Visibility = 'AllUsers';
        insert contentlink;
        return contentlink;
    }
    
    public static FSL__Scheduling_Policy__c fslpolicy() {
        FSL__Scheduling_Policy__c fslschpolcy = new FSL__Scheduling_Policy__c();
        fslschpolcy.FSL__Daily_Optimization__c = true;
        fslschpolcy.FSL__Fix_Overlaps__c = true;
        fslschpolcy.FSL__Travel_Mode__c = false;
        fslschpolcy.Name = 'Aldar Scheduling Policy';
        fslschpolcy.FSL__Service_Clustering_Weight__c = 2;
        fslschpolcy.FSL__Service_Priority_Weight__c = 3;   
        insert fslschpolcy;
        return fslschpolcy;
    }
    public static WorkOrder getWorkOrder(Id accountId, Id contactId, Id caseId) {
        WorkOrder WO = new WorkOrder();
        WO.AccountId = accountId;
        WO.contactId = contactId;
        WO.caseId = caseId;
        WO.Status = 'New';
        // WO.WorkTypeId = worktypeId;
        return WO;
    }
    public static  ServiceAppointment getSA(Boolean doInsert,Id workOrderId) {
        ServiceAppointment SA = new ServiceAppointment();
        SA.ParentRecordId = workOrderId;
        SA.Status = 'New';
        SA.EarliestStartTime = system.today();
        SA.DueDate = system.today()+10 ;
        FSL__Scheduling_Policy__c policy=  fslpolicy();
        SA.FSL__Scheduling_Policy_Used__c = policy.Id;
        Id recordtypid = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Assessment').getRecordTypeId();
        SA.RecordTypeId = recordtypid;
        if(doInsert){
            insert SA;
        }
        return SA;
    }
    
    /* Added by Cloudzlab to handle ECSS test classes*/
    public static Account getECSSCompany()
    {
        Account company = new Account();
        company.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('ECSS Company').getRecordTypeId();
        company.Name ='Test Company';
        return company;
    }
    public static Asset getECSSUnitDetail(Id projectId, Id buildingId)
    {
        Asset unitRecord = new Asset();
        unitRecord.RecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Ecss Unit').getRecordTypeId();
        unitRecord.CurrencyIsoCode = 'AED';
        unitRecord.Name = projectId +'MAYAN-B1-1001';
        unitRecord.ECSS_Project__c = projectId;
        unitRecord.ECSS_Building_Section__c = buildingId;
        unitRecord.ECSS_Unit_Code__c='TEST';
        return unitRecord;
        
    }
    public static Asset getFunctionalLocationUnitDetail(Id projectId, Id buildingId)
    {
        Asset unitRecord = new Asset();
        unitRecord.RecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Functional Location').getRecordTypeId();
        unitRecord.CurrencyIsoCode = 'AED';
        unitRecord.Name = projectId +'MAYAN-B1-1001';
        unitRecord.ECSS_Project__c = projectId;
        unitRecord.ECSS_Building_Section__c = buildingId;
        unitRecord.ECSS_Unit_Code__c='TEST';
        return unitRecord;
        
    }
    public static FM_Companies__c getFMCompany(Id ecssUnitId, Id accountId)
    {
        FM_Companies__c fm = new FM_Companies__c();
        fm.ECSS_Company__c = accountId;
        fm.Unit__c = ecssUnitId;
        return fm;
    }
    public static Customer_Unit__c getCustomerUnit (Id accountId,Id ecssUnitId)
    {
        Customer_Unit__c customerUnitRecord = new Customer_Unit__c();
        customerUnitRecord.Account__c = accountId;
        customerUnitRecord.Unit__c = ecssUnitId;
        insert customerUnitRecord;
        return customerUnitRecord;
        
    }
    public static Document__c getCaseDocument(Id caseId)
    {
        Document__c document = new Document__c();
        document.Case__c = caseId;    
        document.Status__c ='Pending';
        document.DocumentType__c='Renewed Document';
        return document;
        
    }
    public static Case getEltizamCase(Account newAccount)
    {
        Unit__c newUnit = TestObjectsFactory.unitDataSetup('Aldar');
        
        Asset ecssUnit = TestObjectsFactory.getECSSUnitDetail(newUnit.Project__c,newUnit.BuildingSectionName__c);
        insert ecssUnit;
        newUnit.ECSS_Unit__c = ecssUnit.Id;
        insert newUnit;
        
        Case caseRecord = new Case();
        caseRecord.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ECSS_Inquiry').getRecordTypeId();
        caseRecord.CaseCategory__c = 'Request';
        caseRecord.AssetId = ecssUnit.Id;
        caseRecord.ECSS_Object_Category__c ='Tawtheeq';
        caseRecord.CaseComments__c = 'Tawtheeq Renew';
        caseRecord.Status = 'New';
        caseRecord.ECSS_CompanyOptions__c='Provis';
        caseRecord.SubVertical__c = 'Provis';
        caseRecord.AccountId = newAccount.Id;
        caseRecord.ContactId = newAccount.PersonContactId;
        caseRecord.ECSS_Created_From_Component__c = true;
        return caseRecord;
    }
    public static Case getProvisCase(Account newAccount)
    {
        Unit__c newUnit = TestObjectsFactory.unitDataSetup('Aldar');
        
        Asset ecssUnit = TestObjectsFactory.getECSSUnitDetail(newUnit.Project__c,newUnit.BuildingSectionName__c);
        insert ecssUnit;
        Asset funcLoc = TestObjectsFactory.getFunctionalLocationUnitDetail(newUnit.Project__c,newUnit.BuildingSectionName__c);
        insert funcLoc;
        
        newUnit.ECSS_Unit__c = ecssUnit.Id;
        insert newUnit;
        User testUser = [SELECT id FROM User where Email = 'testuser@example.com'];
        Case caseRecord = new Case();
        caseRecord.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ECSS_Inquiry').getRecordTypeId();
        caseRecord.CaseCategory__c = 'Property Management';
        caseRecord.AssetId = ecssUnit.Id;
        caseRecord.ECSS_Object_Category__c ='Property Management';
        caseRecord.CaseComments__c = 'RunningTest';
        caseRecord.Status = 'New';
        caseRecord.Origin = 'Phone';
        caseRecord.ECSS_CompanyOptions__c='Provis';
        caseRecord.ECSS_Sub_Category_Text__c = 'Other PM Issues';
        caseRecord.SubVertical__c = 'Provis';
        caseRecord.AccountId = newAccount.Id;
        caseRecord.ContactId = newAccount.PersonContactId;
        caseRecord.ECSS_Created_From_Component__c = true;
        caseRecord.ownerId = testUser.Id;
        return caseRecord;
    }
    public static Case getProvisCaseNoAccount()
    {
        Unit__c newUnit = TestObjectsFactory.unitDataSetup('Aldar');
        
        Asset ecssUnit = TestObjectsFactory.getECSSUnitDetail(newUnit.Project__c,newUnit.BuildingSectionName__c);
        insert ecssUnit;
        Asset funcLoc = TestObjectsFactory.getFunctionalLocationUnitDetail(newUnit.Project__c,newUnit.BuildingSectionName__c);
        insert funcLoc;
        
        newUnit.ECSS_Unit__c = ecssUnit.Id;
        insert newUnit;
        
        Case caseRecord = new Case();
        caseRecord.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ECSS_Inquiry').getRecordTypeId();
        caseRecord.CaseCategory__c = 'Property Management';
        caseRecord.AssetId = ecssUnit.Id;
        caseRecord.ECSS_Object_Category__c ='Property Management';
        caseRecord.CaseComments__c = 'RunningTest';
        caseRecord.Status = 'New';
        caseRecord.ECSS_CompanyOptions__c='Provis';
        caseRecord.ECSS_Sub_Category_Text__c = 'Other PM Issues';
        caseRecord.SubVertical__c = 'Provis';
        caseRecord.ECSS_CreateAccount__c = true;
        caseRecord.ECSS_Account_Contract_Request__c = false;
        caseRecord.ECSS_Created_From_Component__c = true;
        caseRecord.ECSS_AccountLastName__c = 'Test';
        caseRecord.ECSS_RequestedEmail__c = 'Test@testNoAcc.com';
        
        return caseRecord;
    }
    public static Case getProvisComplaintCase(Account newAccount)
    {
        Unit__c newUnit = TestObjectsFactory.unitDataSetup('Aldar');
        
        Asset ecssUnit = TestObjectsFactory.getECSSUnitDetail(newUnit.Project__c,newUnit.BuildingSectionName__c);
        insert ecssUnit;
        
        newUnit.ECSS_Unit__c = ecssUnit.Id;
        insert newUnit;
        
        Case caseRecord = new Case();
        caseRecord.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ECSS_Complaints').getRecordTypeId();
        caseRecord.CaseCategory__c = 'Property Management';
        caseRecord.AssetId = ecssUnit.Id;
        caseRecord.ECSS_Object_Category__c ='Security Deposit';
        caseRecord.CaseComments__c = 'RunningTest';
        caseRecord.Status = 'New';
        caseRecord.Unit__c = newUnit.Id;
        caseRecord.ECSS_CompanyOptions__c='Provis';
        caseRecord.ECSS_Sub_Category_Text__c = 'Parking Other';
        caseRecord.SubVertical__c = 'Provis';
        caseRecord.AccountId = newAccount.Id;
        caseRecord.ContactId = newAccount.PersonContactId;
        caseRecord.ECSS_Created_From_Component__c = true;
        return caseRecord;
    }
    public static Customer_unit__c getCustomerUnit (String asstId, String accId ){
        Customer_unit__c csUnit = new Customer_unit__c();
        csUnit.Account__c = accId;
        csUnit.Unit__c = asstId;
        return csUnit;
    }
    public static Case getProvisComplaintCaseNew(Account newAccount)
    {
        Unit__c newUnit = TestObjectsFactory.unitDataSetup('Aldar');
        
        Asset ecssUnit = TestObjectsFactory.getECSSUnitDetail(newUnit.Project__c,newUnit.BuildingSectionName__c);
        insert ecssUnit;
        
        newUnit.ECSS_Unit__c = ecssUnit.Id;
        insert newUnit;
        Case caseRecord = new Case();
        caseRecord.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ECSS_Complaints').getRecordTypeId();
        caseRecord.CaseCategory__c = 'Community and Lifestyle';
        caseRecord.AssetId = ecssUnit.Id;
        caseRecord.ECSS_Object_Category__c ='Community and Lifestyle';
        caseRecord.CaseComments__c = 'RunningTest';
        caseRecord.Status = 'New';
        caseRecord.Origin = 'Phone';
        caseRecord.Unit__c = newUnit.Id;
        caseRecord.ECSS_CompanyOptions__c='Provis';
        caseRecord.ECSS_Sub_Category_Text__c = 'Technical Issues';
        caseRecord.SubVertical__c = 'Provis';
        caseRecord.AccountId = newAccount.Id;
        caseRecord.ContactId = newAccount.PersonContactId;
        caseRecord.ECSS_Created_From_Component__c = true;
        return caseRecord;
    }
    public static ECSS_Case_Assignment_SLA__c getSiteAndObjectSLA ()
    {
        ECSS_Case_Assignment_SLA__c cSLA = new ECSS_Case_Assignment_SLA__c();
        //cSLA.Category__c = 'Property Management';
        cSLA.Object_Category__c = 'Property Management';
        cSLA.Sub_Vertical__c = 'Provis';
        cSLA.Escalation_Level_1__c = 'test@test.com';
        cSLA.SLA_Level_1__c = 'SLA-4-HOURS';
        cSLA.Site__c = 'TEST';
        cSLA.Owner_Queue_Name__c = 'TEST';
        String userName = 'test';
        cSLA.Sub_Category__c = 'Other PM Issues';
        String profileName = 'Standard User';   
        User uObject = TestObjectsFactory.getUserRecord(profileName,userName);
        insert uObject;
        cSLA.Response_Team__c = uObject.Email;
        return cSLA;
    }
    public static ECSS_Case_Assignment_SLA__c getSiteAndCategorySLA ()
    {
        ECSS_Case_Assignment_SLA__c cSLA = new ECSS_Case_Assignment_SLA__c();
        cSLA.Category__c = 'CRM';
        //cSLA.Object_Category__c = 'Property Management';
        cSLA.Sub_Vertical__c = 'Provis';
        cSLA.Escalation_Level_1__c = 'test@test.com';
        cSLA.SLA_Level_1__c = 'SLA-4-HOURS';
        cSLA.Site__c = 'TEST';
        cSLA.Owner_Queue_Name__c = 'CRM_TEST';
        String userName = 'test';
        String profileName = 'Standard User';   
        User uObject = TestObjectsFactory.getUserRecord(profileName,userName);
        system.debug('USERNAME'+uObject.Email);
        insert uObject;
        cSLA.Response_Team__c = uObject.Email;
        return cSLA;
    }
    public static ECSS_Case_Assignment_SLA__c getCategorySLA ()
    {
        ECSS_Case_Assignment_SLA__c cSLA = new ECSS_Case_Assignment_SLA__c();
        cSLA.Category__c = 'OAM';
        //cSLA.Object_Category__c = 'Property Management';
        cSLA.Sub_Vertical__c = 'Provis';
        cSLA.Escalation_Level_1__c = 'test@test.com';
        cSLA.SLA_Level_1__c = 'SLA-4-HOURS';
        cSLA.Owner_Queue_Name__c = 'OAM';
        //cSLA.Site__c = '';
        String userName = 'test';
        String profileName = 'Standard User';   
        User uObject = TestObjectsFactory.getUserRecord(profileName,userName);
        insert uObject;
        cSLA.Response_Team__c = uObject.Email;
        return cSLA;
    }
    public static Group getECSS_Group ()
    {
        Group grp = new Group();
        grp.type ='Queue';
        grp.DoesSendEmailToMembers = true;
        grp.DeveloperName = 'TEST';
        grp.Name ='TEST';
        return grp;
        
    }
    public static Contract getKhidmahContracts (Id accountId)
    {
        
        Contract c = new Contract();
        c.StartDate = System.Today();
        //c.EndDate = System.Today().AddYears(1);
        c.AccountId = accountId;
        c.ECSS_Number_of_Call_Outs__c = 10;
        c.ECSS_Contract_Type__c ='Silver';
        return c;
    }
    
    public static Unit_Contract__c getKhidmahContractDetail (Id unitId,Id contractId)
    {
        Unit_Contract__c  unitCont =new Unit_Contract__c();
        unitCont.RecordTypeId = Schema.SObjectType.Unit_Contract__c.getRecordTypeInfosByDeveloperName().get('Contract_Unit').getRecordTypeId();
        unitCont.ECSS_Unit__c = unitId;
        unitCont.Contract__c = contractId;
        return unitCont;
    }
    public static Trigger_Enabler__c getTriggerEnablerInventoryReq()
    {
        Trigger_Enabler__c triggerEnabler = new Trigger_Enabler__c();
        triggerEnabler.Name = 'Inventory Request Details';
        triggerEnabler.Is_After_Update__c =true;
        triggerEnabler.Is_After_Insert__c =true;
        triggerEnabler.Is_After_Delete__c = true;
        triggerEnabler.Is_Before_Delete__c = true;
        triggerEnabler.Is_Before_Insert__c = true;
        triggerEnabler.Is_Before_Update__c = true;
        return triggerEnabler;
    }
    public static void CreateUser(){
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = adminProfile.Id
        );
        insert testUser;
        Group g = [select Id from Group where DeveloperName='CaseHandling_Queue' AND Type = 'Queue'];
        GroupMember member = new GroupMember();
        member.UserOrGroupId = testUser.id;
        member.GroupId = g.Id;
        insert member;
    }
    
    //V1.1 Added by Protiviti for Login API update done for retail Contact
    //Create Data for Test Business Contact
    public static Contact getBusinessContact(String email, String eId, String nationality, String yardiId){
        Contact newContact = getContactRecord(Constants.ORGANISATION_CONTACT_RT);
        newContact.Nationality__c = nationality;
        newContact.Email = email;
        newContact.NationalIdNumber__c = eId;
        newContact.PassportIssueDate__c = Date.valueOf('2005-05-25');
        newContact.RETL_Profile_Image__c = '';
        newContact.Title = 'Manager';
        newContact.RETL_Yardi_Id__c = yardiId;
        return newContact;
    }

    //create data for test contact
    public static Contact getContactRecord(String contactRTName){
        Contact newContact = new Contact();
        newContact.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(contactRTName).getRecordTypeId();
        newContact.FirstName = 'test';
        newContact.LastName = 'Last';
        newContact.Birthdate = Date.valueOf('2000-05-25');
        newContact.MobileCountryCode__c = '971';
        newContact.MobilePhone = '456788099';
        newContact.MailingCity = 'Testa';
        newContact.MailingCountry = 'United Arab Emirates';
        newContact.MailingState = 'Dubai';
        newContact.MailingPostalCode = '23345';
        return newContact;
    }
    //Create data for Test Brand Account
    public static Account getBrandAccountRecord(String brandName){
        Account newAccount = getAccountRecord(Constants.BRAND_Account_RT,false,null);
        newAccount.Name = brandName;
        newAccount.CurrencyIsoCode = 'AED';
        return newAccount ;
    }
    //Create Data for Test AccountCOntactRelation
    public static AccountContactRelation getACR(Id contactId, Id accountId){
        AccountContactRelation acr = new AccountContactRelation(
            AccountId = accountId,
            ContactId = contactId
        );

        return acr;
    }
    //Create Data for Test Contact
    public static Contract getContract(Id accountId){
        Contract newContract = new Contract(
        	StartDate = Date.valueOf('2025-06-15'),
            ContractTerm = 10,
            AccountId = accountId,
            Status = 'Draft',
            CurrencyIsoCode = 'AED'
        );
        return newContract;
    }
    //Create Data for Test Order
    public static Order getOrder(Id accountId, Id brandId, Id contractId){
        Id standardPricebookId = Test.getStandardPricebookId();
        Order newOrder = new Order(
        	RETL_Name__c = 'Test Order',
            RETL_Yardi_Id__c = '4566',
            AccountId = accountId,
            Pricebook2Id = standardPricebookId,
            RETL_Brand__c = brandId,
            ContractId = contractId,
            EffectiveDate = Date.Valueof('2025-07-15'),
            RETL_Contracted_Area__c = 455.50,
            RETL_Location__c = 'first floor',
			RETL_Property_Name__c = 'Yas Mall',
            Status = 'Draft',
            RETL_Status__c = 'Current'
        );
        return newOrder;
    }
    //Create Data for Test ContactRole
    public static RETL_Contact_role__c getContactRole(Id contactId, Id leaseId, String role){
        RETL_Contact_role__c newcontactRole = new RETL_Contact_role__c(
        	RETL_Contact__c = contactId,
            RETL_Lease__c = leaseId,
            Name = role
        );
        return newcontactRole;
    }
    //Create Data for Test Product
    public static Product2 getProduct(){
        Product2 newProduct = new Product2(
            Name = 'Test Product'
        );
        return newProduct;
    }
    //Create Data for Test LeaseUnits
    public static OrderItem getLeaseUnits(Id productId, Id orderId, Id pricebookEntryId){
        OrderItem newOrderItem = new OrderItem(
        	Product2Id = productId,
            pricebookEntryId = pricebookEntryId,
            OrderId = orderId,
            UnitPrice = 15020,
            Quantity = 50,
            RETL_Building__c = 'Yas mall',
            RETL_Floor__c = 'firstfloor',
            RETL_Area__c = 45.25,
            RETL_MoveInDate__c = Date.valueOf('2025-06-20'),
            RETL_MoveOutDate__c = Date.valueOf('2026-02-20'),
            RETL_UnitType__c = 'lineShop'
        );
        return newOrderItem;
    }
    //Create Data for Test PriceBookEntry.
    public static PricebookEntry getPricebookEntry(Id productId) {
        // Get standard price book ID
        Id pricebookId = Test.getStandardPricebookId();
		PricebookEntry standardPriceEntry = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = productId,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false
        );
        return standardPriceEntry;
    }
    //Create Data for Test Document
    public static Document__c getDocument(Id orderId, Id accountId){
        Document__c newDoc = new Document__c(
            Order__c = orderId,
            Account__c = accountId,
            DocumentType__c = 'Commercial Trade License'

        );
        return newDoc;
    }
    //V1.1 Added by Protivity end
    
}