@IsTest
private class Com_MultipleSPCreationCntrl_Test {

    private class TestData {
        Id operatingHoursId;
        Id territoryId;
        Id workTypeId;
        Id workTypeGroupId;
        Id workTypeGroupMemberId;
    }

    private static TestData createSchedulingTestData() {
        TestData t = new TestData();

        OperatingHours oh = new OperatingHours(Name='Test OH', TimeZone='Asia/Dubai');
        insert oh;
        t.operatingHoursId = oh.Id;

        ServiceTerritory terr = new ServiceTerritory(
            Name='Test Territory',
            IsActive=true,
            OperatingHoursId=oh.Id
        );
        insert terr;
        t.territoryId = terr.Id;

        WorkType wt = new WorkType(Name='Test WorkType', EstimatedDuration=60);
        insert wt;
        t.workTypeId = wt.Id;

        WorkTypeGroup wtg = new WorkTypeGroup(Name='WT Group');
        insert wtg;
        t.workTypeGroupId = wtg.Id;

        WorkTypeGroupMember wtgm = new WorkTypeGroupMember(
            WorkTypeGroupId=wtg.Id,
            WorkTypeId=wt.Id
        );
        insert wtgm;
        t.workTypeGroupMemberId = wtgm.Id;

        // Also link Territory <-> WorkType (your controller queries this)
        ServiceTerritoryWorkType stwt = new ServiceTerritoryWorkType(
            ServiceTerritoryId = t.territoryId,
            WorkTypeId         = t.workTypeId
        );
        insert stwt;

        return t;
    }

    private static Asset createClassAsset(Account owner) {
        Product2 p = new Product2(Name='Class Product', IsActive=true);
        insert p;
        Asset a = new Asset(
            Name='Class Schedule Asset',
            AccountId=owner.Id,
            Product2Id=p.Id,
            Com_End_Time__c=System.now().addDays(3),   // controller formats this
            Com_No_of_Minutes_Duration__c=60
        );
        insert a;
        return a;
    }

    // ServiceResource tied to the Asset (controller queries ServiceResource where AssetId = Asset.Id)
    private static ServiceResource createResourceOnAsset(Asset a) {
        ServiceResource sr = new ServiceResource(Name='Coach John', IsActive=true, AssetId=a.Id, ResourceType='S');
        insert sr;
        return sr;
    }

    // Minimal Territory membership (some orgs don’t expose extra fields on STM; keep it minimal)
    private static void linkResourceToTerritory(ServiceResource sr, Id territoryId) {
        ServiceTerritoryMember stm = new ServiceTerritoryMember(
            ServiceResourceId = sr.Id,
            ServiceTerritoryId = territoryId,
            EffectiveStartDate = DateTime.newInstance(System.today(), Time.newInstance(9, 0, 0, 0))
        );
        insert stm;
    }

    // Build attendees (Leads) and return Ids as strings
    /* // commented out because we don't use leads anymore as it switched to account/contact and the service appointments are being created in the flow
     * private static List<String> makeDummyAttendees(Integer n) {
        Id leadRT = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
                       .get('Community_Attendee').getRecordTypeId();
        List<Lead> leads = new List<Lead>();
        for (Integer i=0; i<n; i++) {
            leads.add(new Lead(FirstName='Att'+i, LastName='Test', RecordTypeId=leadRT));
        }
        insert leads;
        List<String> ids = new List<String>();
        for (Lead l : leads) ids.add((String)l.Id);
        return ids;
    }
    */
    
    //replacing lead attendees by contact attendees
    private static List<String> makeDummyAttendees(Integer attendeesNumber) {
        
        Account acc = new Account(
            Name = 'Test Vendor',
            RecordTypeId = Constants.ORGANIZATION_RECORD_TYPE_ID,
            ERPID__c = '',
            UAEVATRegisterNumber__c = '123456789',
            CurrencyIsoCode = 'AED',
            DateOfRegistration__c = Date.today(),
            RegistrationNumber__c = '987654321',
            BillingCountry = 'United Arab Emirates',
            BillingStreet = '123 Test St',
            BillingCity = 'Abu Dhabi',
            BillingState = 'Abu Dhabi',
            BillingPostalCode = '00000',
            Email__c = 'test@test.com',
            Website = 'www.test.com',
            AMLFlag__c = true,
            RegistrationExpiryDate__c = Date.today().addYears(1),
            PreviousAgencyStatus__c = 'Active',
            CurrentAgencyStatus__c = 'Verified',
            IsBrokerChange__c = true,
            IsAgentChange__c = false,
            OtherERPID__c = '{"oracleSupplierId":"123","oracleSiteId":"456"}'
        );
        insert acc;
        
        
        //create contacts
        Id contactRT = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
        List<Contact> contactList = new List<Contact>();
        for (Integer i = 0; i < attendeesNumber; i++) {
            contactList.add(new Contact(FirstName = 'Test',
                                         LastName = 'User',
                                         AccountId = acc.Id,
                                         RecordTypeId = contactRT,
                                         BrokerType__c = 'Agent'));
        }
        insert contactList;
        
        List<String> contactIds = new List<String>();
        for (Contact contRecord : contactList) {
            contactIds.add((String)contRecord.Id);  
        } 
        return contactIds;
    }

    private static String buildSlotsJson(Integer n, Id territoryId, Id resourceId) {
        List<String> items = new List<String>();
        Datetime base = DateTime.newInstance(Date.today(), Time.newInstance(9,0,0,0));
        for (Integer i = 0; i < n; i++) {
            Datetime s = base.addHours(i);
            Datetime e = base.addHours(i+1);
            String sf = s.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
            String ef = e.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');

            String one =
            '{' +
            '  "startTime": "' + sf + '",' +
            '  "endTime": "' + ef + '",' +
            '  "resources": ["' + String.valueOf(resourceId) + '"],' +
            '  "territoryId": "' + String.valueOf(territoryId) + '",' +
            '  "remainingAppointments": 5' +
            '}';
            items.add(one);
        }
        return '[' + String.join(items, ',') + ']';
    }

    private static void setLXSlotsMock(String json) {
    lxscheduler.SchedulerResources.setAppointmentSlotsMock(json);
}
       
    @IsTest
    static void test_createMultipleAppointments_happyPath() {
        Account acc = new Account(Name='Parent');
        insert acc;

        TestData t = createSchedulingTestData();
        Asset classAsset = createClassAsset(acc);
        ServiceResource sr = createResourceOnAsset(classAsset);
        linkResourceToTerritory(sr, t.territoryId);

        List<String> attendees = makeDummyAttendees(2);

        // Feed 10 slots to the scheduler via package hook (no HttpCalloutMock needed)
        String mockJson = buildSlotsJson(10, t.territoryId, sr.Id);
        setLXSlotsMock(mockJson);

        Test.startTest();
        Com_MultipleSPCreationCntrl.spResponsePayload resp =
            Com_MultipleSPCreationCntrl.createMultipleAppointments(
                acc.Id, classAsset.Id, attendees
            );
        Test.stopTest();

        System.assertNotEquals(null, resp, 'Response should not be null');
        System.assertEquals(false, resp.insufficientSlots, 'Should have enough slots');
        System.assertEquals(10, resp.appointmentList.size(), 'Should create 10 parent SAs');
        System.assertEquals(sr.Id, resp.serviceResourceId, 'Service resource echoed');
        System.assertEquals(10, resp.remainingSlots.size(), 'Remaining slots parallel count');

        // Spot-check a couple fields
        ServiceAppointment sa0 = resp.appointmentList[0];
        System.assertEquals('Approved', sa0.Status);
        System.assertEquals('Minutes', sa0.DurationType);
        System.assertEquals(classAsset.Id, sa0.Asset__c);
        System.assertEquals(acc.Id, sa0.ParentRecordId);
    }

    // 2) Insufficient slots: package returns < loopLimit (e.g., 3)
    @IsTest
    static void test_createMultipleAppointments_insufficient() {
        Account acc = new Account(Name='Parent 2');
        insert acc;

        TestData t = createSchedulingTestData();
        Asset classAsset = createClassAsset(acc);
        ServiceResource sr = createResourceOnAsset(classAsset);
        linkResourceToTerritory(sr, t.territoryId);

        List<String> attendees = makeDummyAttendees(1);

        // Only 3 slots → triggers insufficient branch
        String mockJson = buildSlotsJson(3, t.territoryId, sr.Id);
        setLXSlotsMock(mockJson);

        Test.startTest();
        Com_MultipleSPCreationCntrl.spResponsePayload resp =
            Com_MultipleSPCreationCntrl.createMultipleAppointments(
                acc.Id, classAsset.Id, attendees
            );
        Test.stopTest();

        System.assertEquals(true, resp.insufficientSlots, 'Should flag insufficient slots');
        System.assertEquals(null, resp.appointmentList, 'Should early-return without building list');
    }

    // 3) Your existing test for createAppointments (insert parents, clone children, update parent)
    // commented out because we don't use leads anymore as it switched to account/contact and the service appointments are being created in the flow
    /*@IsTest
    static void test_createAppointments_inserts_children_and_updates_parents() {
        TestData setup = CreateSchedulingTestData();

        Account acc = new Account(Name = 'Parent Account');
        insert acc;

        Id LeadRT= Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
                     .get('Community_Attendee').getRecordTypeId();

        Lead attendeeA = new Lead(FirstName = 'A', LastName = 'Attendee',  RecordTypeId= LeadRT);
        Lead attendeeB = new Lead(FirstName = 'B', LastName = 'Attendee', RecordTypeId= LeadRT);
        insert new List<Lead>{ attendeeA, attendeeB };

        Datetime startT = DateTime.newInstance(System.today(), Time.newInstance(9, 0, 0, 0));
        Datetime endT   = startT.addHours(1);

        ServiceAppointment parent = new ServiceAppointment(
            ParentRecordId     = acc.Id,
            ServiceTerritoryId = setup.territoryId,
            WorkTypeId         = setup.workTypeId,
            SchedStartTime     = startT,
            SchedEndTime       = endT,
            Duration           = 60,
            DurationType       = 'Minutes',
            Status             = 'Scheduled'
        );

        List<ServiceAppointment> parents = new List<ServiceAppointment>{ parent };
        List<String> optionalAttendees  = new List<String>{ attendeeA.Id, attendeeB.Id };
        String subject = 'Yoga Session';
        String description = 'Bring your mat';

        Test.startTest();
        Com_MultipleSPCreationCntrl.createAppointments(parents, optionalAttendees, subject, description);
        Test.stopTest();

        ServiceAppointment parentReloaded = [
            SELECT Id, Subject, Description
            FROM ServiceAppointment
            WHERE Id = :parent.Id
        ];
        System.assertEquals(subject, parentReloaded.Subject);
        System.assertEquals(description, parentReloaded.Description);

        List<ServiceAppointment> children = [
            SELECT Id, ParentRecordId, Service_Appointment__c, Subject, Description
            FROM ServiceAppointment
            WHERE Service_Appointment__c = :parent.Id
        ];
        System.assertEquals(2, children.size());

        Set<Id> childParentRecordIds = new Set<Id>();
        for (ServiceAppointment c : children) {
            childParentRecordIds.add(c.ParentRecordId);
            System.assertEquals(parent.Id, c.Service_Appointment__c);
            System.assertEquals(subject, c.Subject);
            System.assertEquals(description, c.Description);
        }
        System.assertEquals(new Set<Id>{ attendeeA.Id, attendeeB.Id }, childParentRecordIds);
    }
*/
    

}