@isTest(seeAlldata=false)
public class com_AmenityCreationCntrlTest {
    
    @testSetup
    public static void testDataCreation(){
        String amentiyRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Amenity').getRecordTypeId();
        
        Project__c projectObj = new Project__c();
        projectObj.name = 'Test Project';
        projectObj.BrokerSale__c = false;
        projectObj.BusinessUnitId__c = '1234';
        projectObj.City__c = 'Dubai';
        projectObj.CommunityName__c = 'Al Marjan';
        projectObj.Country__c = 'United Arab Emirates';
        projectObj.CurrencyIsoCode = 'AED';
        projectObj.ProjectCode__c = '12345';
        
        insert projectObj;
        
        BuildingSection__c buildingObj = new BuildingSection__c();
        buildingObj.Name = 'Test Building';
        buildingObj.ApprovalStatus__c = 'Draft';
        buildingObj.CurrencyIsoCode = 'AED';
        buildingObj.RecordTypeId = Schema.SObjectType.BuildingSection__c.getRecordTypeInfosByDeveloperName().get('Building').getRecordTypeId();
        buildingObj.ECSS_Building_Type__c = 'Building';
        buildingObj.BuildingSectionCode__c = '12345';
        buildingObj.Project__c = projectObj.id;
        
        insert buildingObj;
        
        Zone__c zoneObj = new Zone__c();
        zoneObj.name = 'Test Zone';
        zoneObj.Project__c = projectObj.Id;
        zoneObj.Zone_External_Id__c = '123456';
        
        insert zoneObj;
        
        Asset assetObj = new Asset();
        assetObj.RecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Amenity').getRecordTypeId();
        assetObj.Name= 'Test Asset';
        assetObj.ECSS_Zone__c = zoneObj.Id;
        assetObj.Project__c = projectObj.Id;
        assetObj.Building__c = buildingObj.Id;
        assetObj.Com_Amenity_Features__c = 'WIFI';
        assetObj.Com_Status__c = 'Active';
        assetObj.Com_No_of_Minutes_Duration__c = 90;
        assetObj.Com_Maximum_members_per_Amenity__c = 5;
        assetObj.Com_Start_DateTime__c = System.Now();
        assetObj.Com_End_Time__c = System.Now().addDays(10);
        assetObj.Com_Time_Interval_In_Minutes__c = 15;
        assetObj.Block_Time_Before_Minutes__c = 5;
        assetObj.Block_Time_After_Minutes__c = 5;
        assetObj.Com_Description__c = 'Test Description';
        assetObj.Com_Terms_and_conditions__c = 'Test T&A';
        assetObj.Weekdays_Amount__c = 1000;
        assetObj.Weekend_Amount__c = 1500;
        assetObj.List_Price__c = 900;
        assetObj.Com_Amenity_Deposit_AED__c = 500;
        assetObj.Include_VAT__c = true;
        assetObj.Com_VAT_Percentage__c = 5;
        assetObj.Country = 'United Arab Emirates';
        assetObj.City = 'Dubai';
        
        insert assetObj;
                
        Product2 classObj = new Product2();
        classObj.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Com_Class').getRecordTypeId();
        classObj.Name = 'Test Class';
        classObj.Com_Community__c = projectObj.Id;
        classObj.Com_Status__c = 'Active';
        classObj.Com_Start_Date__c = Date.today();
        classObj.Com_End_Date__c = Date.today().addDays(30);
        classObj.Com_Category__c = 'Fitness';
        classObj.Com_Trial_Class__c = 'Yes';
        classObj.Description = 'Test Description';
        classObj.Com_District__c = zoneObj.Id;
        classObj.Com_Building__c = buildingObj.Id;
        classObj.Com_Business_Area__c = 'Z024';
        classObj.Com_Is_VAT_Included__c = 'No';
        classObj.Com_Refundable__c = 'No';
        classObj.Com_Terms_and_Conditions__c = 'Test T&C';
        classObj.Com_Commission_Type__c = 'Amount';
        
        insert classObj;
        
        Product2 classPackage = new Product2();
        classPackage.name = 'Test Package';
        classPackage.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Com_Class_Package').getRecordTypeId();
        classPackage.Com_Class__c = classObj.Id;
        classPackage.Com_Group__c = 'Male';
        classPackage.Com_Total_No_of_Sessions__c = 5;
        classPackage.Description = 'Package Description';
        classPackage.Com_Package_Type__c = 'Private Session';
        classPackage.Com_Fees_AED__c = 1500;
        classPackage.Com_Age_Range__c = 30;
        classPackage.Com_Maximum_No_of_Applicants__c = 5;
        insert classPackage;
        
        
        Asset scheduleObj = new Asset();
        scheduleObj.RecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Com_Class_Schedule').getRecordTypeId();
        scheduleObj.Name= 'Test Class Schedule';
        scheduleObj.Com_Class__c = classObj.Id;
        scheduleObj.Com_Package__c = classPackage.Id;
        scheduleObj.Com_Time_Interval_In_Minutes__c = 60;
        scheduleObj.Com_Day__c = 'Monday';
        scheduleObj.Time_Slot_Start_Time__c = Time.newInstance(0, 0, 0, 0);
        scheduleObj.Time_Slot_End_Time__c = Time.newInstance(0, 30, 0, 0);
        
        insert scheduleObj;
        
        // Create Work Type
        WorkType wt = new WorkType(Name = assetObj.Name, DurationType = 'Minutes', EstimatedDuration = 60);
        insert wt;
        
        // Create WorkTypeGroup
        WorkTypeGroup wtg = new WorkTypeGroup(
            Name = assetObj.Name,
            Description = 'Test WorkType Group for Installations'
        );
        insert wtg;
        
        WorkTypeGroupMember wtgm = new WorkTypeGroupMember(WorkTypeId = wt.Id, WorkTypeGroupId = wtg.Id);
        insert wtgm;
        
        OperatingHours hoursObj = new OperatingHours(Name = assetObj.Name, TimeZone = 'Asia/Dubai');
        insert hoursObj;
        
        // Create Service Territory
        ServiceTerritory st = new ServiceTerritory(Name = assetObj.Name, OperatingHoursId = hoursObj.Id, IsActive = true);
        insert st;
        
        // Create Service Resource
        ServiceResource sr = new ServiceResource(Name = assetObj.Name, IsActive = true, AssetId = assetObj.Id, ResourceType = 'S');
        insert sr;
        
        // Link Service Resource to Territory
        ServiceTerritoryMember stm = new ServiceTerritoryMember(
            ServiceTerritoryId = st.Id,
            ServiceResourceId = sr.Id,
            EffectiveStartDate = Date.today()
        );
                                                 
        insert stm;
        
        ServiceTerritoryWorkType setwt = new ServiceTerritoryWorkType(WorkTypeId = wt.Id, ServiceTerritoryId = st.Id);
        insert setwt;
    }
    
    @isTest
    public static void createOperatingHourForAmenitytest(){
        Asset assetObj = [Select Id from Asset where Name = 'Test Asset' LIMIT 1];
        
        test.startTest();
        com_AmenityCreationCntrl.createOperatingHourForAmenity(assetObj.Id);
        test.stopTest();
    }
    
    @isTest
    public static void getFilesTest(){
        Asset assetObj = [Select Id from Asset where Name = 'Test Asset' LIMIT 1];
        
        String fileContent = 'This is the content of the test file.';
        String fileName = 'TestDocument.txt';
        
        ContentVersion cv = new ContentVersion();
        cv.PathOnClient = fileName;
        cv.VersionData = Blob.valueOf(fileContent);
        cv.Title = fileName;
        cv.ContentLocation = 'S';
        insert cv;
        
        ContentVersion insertedCv = [SELECT Id, Title, PathOnClient, VersionData, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        ContentDocumentLink testContDocLink = new ContentDocumentLink(); 
        testContDocLink.LinkedEntityId = assetObj.Id;
        testContDocLink.ContentDocumentId = insertedCv.ContentDocumentId;
        insert testContDocLink;
        
        test.startTest();
        com_AmenityCreationCntrl.getFiles(assetObj.Id);
        
        ContentDocument documentObj = [Select Id from ContentDocument where Id =: insertedCv.ContentDocumentId LIMIT 1];
        
        com_AmenityCreationCntrl.createDocuments(assetObj.Id, new List<String>{documentObj.Id});
        
        com_AmenityCreationCntrl.deleteFiles(documentObj.Id);
        
        com_AmenityCreationCntrl.getPickListValues();        
        test.stopTest();
        
    }
    
    @isTest
    public static void createTimeSlotsTest(){
        
        Project__c projectObj = [Select Id from Project__c LIMIT 1];
        BuildingSection__c buildingObj = [Select Id from BuildingSection__c LIMIT 1];
        Zone__c zoneObj = [Select Id from Zone__c LIMIT 1];
        
        Asset assetObj = new Asset();
        assetObj.RecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Amenity').getRecordTypeId();
        assetObj.Name= 'Test Asset 2';
        assetObj.ECSS_Zone__c = zoneObj.Id;
        assetObj.Project__c = projectObj.Id;
        assetObj.Building__c = buildingObj.Id;
        assetObj.Com_Amenity_Features__c = 'WIFI';
        assetObj.Com_Status__c = 'Active';
        assetObj.Com_No_of_Minutes_Duration__c = 90;
        assetObj.Com_Maximum_members_per_Amenity__c = 5;
        assetObj.Com_Start_DateTime__c = System.Now();
        assetObj.Com_End_Time__c = System.Now().addDays(10);
        assetObj.Com_Time_Interval_In_Minutes__c = 15;
        assetObj.Block_Time_Before_Minutes__c = 5;
        assetObj.Block_Time_After_Minutes__c = 5;
        assetObj.Com_Description__c = 'Test Description';
        assetObj.Com_Terms_and_conditions__c = 'Test T&A';
        assetObj.Weekdays_Amount__c = 1000;
        assetObj.Weekend_Amount__c = 1500;
        assetObj.List_Price__c = 900;
        assetObj.Com_Amenity_Deposit_AED__c = 500;
        assetObj.Include_VAT__c = true;
        assetObj.Com_VAT_Percentage__c = 5;
        assetObj.Country = 'United Arab Emirates';
        assetObj.City = 'Dubai';
        
        insert assetObj;
        
		OperatingHours hoursObj = [Select Id from OperatingHours where Name = 'Test Asset' LIMIT 1];
        WorkTypeGroup workGroupObj = [Select Id from WorkTypeGroup where Name = 'Test Asset' LIMIT 1];
        
        test.startTest();
        com_AmenityCreationCntrl.createTimeSlots(hoursObj.Id, new List<String>{'Monday'}, new List<String>{'00:00:00.000'}, new List<String>{'00:30:00.000'}, assetObj.Id, workGroupObj.Id);
        test.stopTest();        
    }
    
    @isTest
    public static void getClassPackagesTest(){
        Product2 clasObj = [Select Id from Product2 where Name = 'Test Class' LIMIT 1];
        Product2 classPackageObj = [Select Id from Product2 where Name = 'Test Package' LIMIT 1];
        Asset classSchedule = [Select Id, Name from Asset where Name = 'Test Class Schedule' LIMIT 1];
        
        String fileContent = 'This is the content of the test file.';
        String fileName = 'TestDocument.txt';
        
        ContentVersion cv = new ContentVersion();
        cv.PathOnClient = fileName;
        cv.VersionData = Blob.valueOf(fileContent);
        cv.Title = fileName;
        cv.ContentLocation = 'S';
        insert cv;
        
        ContentVersion insertedCv = [SELECT Id, Title, PathOnClient, VersionData, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        ContentDocumentLink testContDocLink = new ContentDocumentLink(); 
        testContDocLink.LinkedEntityId = clasObj.Id;
        testContDocLink.ContentDocumentId = insertedCv.ContentDocumentId;
        insert testContDocLink;
        
        test.startTest();
        com_AmenityCreationCntrl.getClassPackages(clasObj.Id);
        
        com_AmenityCreationCntrl.updateClassPackageOnSchedule(clasObj.Id, new List<String>{classPackageObj.Id}, new List<String>{classSchedule.Name}, classSchedule.Id);
                
        ContentDocument documentObj = [Select Id from ContentDocument where Id =: insertedCv.ContentDocumentId LIMIT 1];
        com_AmenityCreationCntrl.createDocumentsForClass(clasObj.Id, new List<String>{documentObj.Id});
        test.stopTest();  
        
    }
    
    @isTest
    public static void getClassScheduleTest(){
        Product2 clasObj = [Select Id from Product2 where Name = 'Test Class' LIMIT 1];
        Product2 classPackageObj = [Select Id from Product2 where Name = 'Test Package' LIMIT 1];
        Asset classSchedule = [Select Id, Name from Asset where Name = 'Test Class Schedule' LIMIT 1];
        
        String fileContent = 'This is the content of the test file.';
        String fileName = 'TestDocument.txt';
        
        ContentVersion cv = new ContentVersion();
        cv.PathOnClient = fileName;
        cv.VersionData = Blob.valueOf(fileContent);
        cv.Title = fileName;
        cv.ContentLocation = 'S';
        insert cv;
        
        ContentVersion insertedCv = [SELECT Id, Title, PathOnClient, VersionData, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        ContentDocumentLink testContDocLink = new ContentDocumentLink(); 
        testContDocLink.LinkedEntityId = clasObj.Id;
        testContDocLink.ContentDocumentId = insertedCv.ContentDocumentId;
        insert testContDocLink;
        
        test.startTest();
        com_AmenityCreationCntrl.getClassPackages(clasObj.Id);
        
        com_AmenityCreationCntrl.getParentClass(classPackageObj.Id);
        
        com_AmenityCreationCntrl.updateClassSchedule(clasObj.Id, new List<String>{classSchedule.Name}, classSchedule.Id);
                
        ContentDocument documentObj = [Select Id from ContentDocument where Id =: insertedCv.ContentDocumentId LIMIT 1];
        com_AmenityCreationCntrl.createDocumentsForClass(clasObj.Id, new List<String>{documentObj.Id});
        test.stopTest();  
        
    }
    
    @isTest
    public static void getAccountRecordsTest(){
        List<Account> accList = new List<Account>();
        Account spAccount = new Account();
        spAccount.Name = 'Service Provider Test';
        spAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Service_Provider').getRecordTypeId();
        spAccount.SapAccountID__c = '11111';
        
        accList.add(spAccount);
        
        Account rpAccount = new Account();
        rpAccount.Name = 'Related Party Test';
        rpAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Related_Party').getRecordTypeId();
        rpAccount.SapAccountID__c = '22222'; 
        accList.add(rpAccount);
        
        Account pcAccount = new Account();
        pcAccount.Name = 'Profit Center Test';
        pcAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Profit_Center').getRecordTypeId();
        pcAccount.SapAccountID__c = '33333';
        pcAccount.Com_Cost_Center_SAP_Code__c = '44444';
        accList.add(pcAccount);
        
        insert accList;
        
        test.startTest();
        com_AmenityCreationCntrl.getAccountRecords();
        test.stopTest();

    }
    
    
    @isTest
    public static void createParentServiceAppointmentsTest(){
        
        Account accObj = new Account();
        accObj.name = 'Test Account';
        insert accObj;
        
        List<ServiceAppointment> appointmentList = new List<ServiceAppointment>();
        
        ServiceAppointment appointmentObj = new ServiceAppointment();
        appointmentObj.ParentRecordId = accObj.Id;
        appointmentObj.Status = 'New';
        appointmentObj.Subject = 'Test Appointment';
        appointmentObj.RecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByDeveloperName().get('Community_Appointments').getRecordTypeId();
        
        appointmentList.add(appointmentObj);
        
        ServiceAppointment appointmentObj1 = new ServiceAppointment();
        appointmentObj1.ParentRecordId = accObj.Id;
        appointmentObj1.Status = 'New';
        appointmentObj1.Subject = 'Test Appointment 1';
        appointmentObj1.RecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByDeveloperName().get('Community_Appointments').getRecordTypeId();
        
        appointmentList.add(appointmentObj1);
                
        List<List<ServiceAppointment>> invocableList = new List<List<ServiceAppointment>>();
        invocableList.add(appointmentList);
        
        test.startTest();
        com_AmenityCreationCntrl.createParentServiceAppointments(invocableList);
        test.stopTest();
        
    }
    
    @isTest
    public static void createPlatformEventTest(){
        
        Account accObj = new Account();
        accObj.name = 'Test Account';
        insert accObj;
        
        List<ServiceAppointment> appointmentList = new List<ServiceAppointment>();
        
        ServiceAppointment appointmentObj = new ServiceAppointment();
        appointmentObj.ParentRecordId = accObj.Id;
        appointmentObj.Status = 'New';
        appointmentObj.Subject = 'Test Appointment';
        appointmentObj.RecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByDeveloperName().get('Community_Appointments').getRecordTypeId();
        
        appointmentList.add(appointmentObj);
        
        ServiceAppointment appointmentObj1 = new ServiceAppointment();
        appointmentObj1.ParentRecordId = accObj.Id;
        appointmentObj1.Status = 'New';
        appointmentObj1.Subject = 'Test Appointment 1';
        appointmentObj1.RecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByDeveloperName().get('Community_Appointments').getRecordTypeId();
        
        appointmentList.add(appointmentObj1);
        
        insert appointmentList;
        
        List<String> appIdList = new List<String>();
        for(ServiceAppointment appObj : appointmentList){
            appIdList.add(appObj.Id);
        }
                
        List<List<String>> invocableList = new List<List<String>>();
        invocableList.add(appIdList);
        
        test.startTest();
        com_ServiceAppointmentEventCntrl.createPlatformEvent(invocableList);
        test.stopTest();
        
    }
    
    @isTest
    public static void createPackagesTest(){
        Product2 classObj = [Select Id from Product2 where RecordType.DeveloperName = 'Com_Class' LIMIT 1];
        Product2 packageObj = [Select Id, Name, Com_Group__c, Com_Commission_Type__c, Com_Package_Type__c, Com_Total_No_of_Sessions__c, Description, Com_Service_Provider_Commission__c,
                               Com_Related_Party_Commission__c, Com_Aldar_ECSS_Commission__c, Com_Service_Provider_Commission_Amount__c, Com_Related_Party_Commission_Amount__c, 
                               Com_Aldar_ECSS_Commission_Amount__c, Com_Fees_AED__c, Com_Age_Range__c, Com_Maximum_No_of_Applicants__c from Product2 where RecordType.DeveloperName = 'Com_Class_Package' LIMIT 1];
        
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;
        
        Pricebook2 customPb = new Pricebook2();
        customPb.Name = 'Community Price Book';
        customPb.IsActive = true;
        insert customPb;
        
        test.startTest();
        com_AmenityCreationCntrl.createPackages(classObj.Id, new List<Product2>{packageObj});
        com_AmenityCreationCntrl.getcommissionTypes();
        com_AmenityCreationCntrl.getGroupOptions();
        com_AmenityCreationCntrl.getpackageTypes();
        test.stopTest();
    }
}