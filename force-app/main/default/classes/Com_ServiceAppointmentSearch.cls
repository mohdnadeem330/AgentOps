public class Com_ServiceAppointmentSearch {
    
    @AuraEnabled
    public static List<ServiceAppointment> fetchServiceAppointments(
        List<Project__c> projectList,
        List<BuildingSection__c> buildingList,
        List<Unit__c> unitList,
        List<Account> accountList,
        List<Asset> amenityList,
        List<Product2> classList,
        String email,
        String bookingNumber,
        String status,
        String startDate,
        String endDate,
        String selectedDateRange,
        String selectedAppointmentType
    ){
        Set<Id> projectIdSet = new Set<Id>();
        Set<Id> buildingIdSet = new Set<Id>();
        Set<Id> unitIdSet = new Set<Id>();
        Set<Id> accountIdSet = new Set<Id>();
        Set<Id> assetIdSet = new Set<Id>();
        Set<Id> productIdSet = new Set<Id>();
        
        if (projectList != null) {
            for (Project__c projectObj : projectList) projectIdSet.add(projectObj.Id);
        }
        if (buildingList != null) {
            for (BuildingSection__c buildingObj : buildingList) buildingIdSet.add(buildingObj.Id);
        }
        if (unitList != null) {
            for (Unit__c unitObj : unitList) unitIdSet.add(unitObj.Id);
        }
        if (accountList != null) {
            for (Account accObj : accountList) accountIdSet.add(accObj.Id);
        }
        if (amenityList != null) {
            for (Asset assetObj : amenityList) assetIdSet.add(assetObj.Id);
        }
        if (classList != null) {
            for (Product2 productObj : classList) productIdSet.add(productObj.Id);
        }
        
        // Step 1: Query all ServiceAppointments with ParentRecordId (possibly Asset)
        String baseQuery = 'SELECT Id, AppointmentNumber, Status, Email, Phone, Com_Attended__c, SchedStartTime,  SchedEndTime, AttendeeCount, Asset__c, Subject,  ' +
            'ParentRecordId, ContactId, Contact.Name, ' +
            'AccountId, Account.Name, Account.SapAccountID__c, ' +
            'OwnerId, Owner.Name, ' +
            'ServiceTerritoryId, ServiceTerritory.Name, ' +
            'Community__c, Community__r.Name, ' +
            'Unit_Number__c, Unit_Number__r.Name, ' +
            'Precinct__c, Precinct__r.Name, ' +
            'Service_Appointment__c, Service_Appointment__r.AppointmentNumber, Service_Appointment__r.Master_Service_Appointment__c, Service_Appointment__r.Master_Service_Appointment__r.AppointmentNumber , Master_Service_Appointment__c, Master_Service_Appointment__r.AppointmentNumber, '+
            'CreatedById, CreatedBy.Name, ParentRecord.Name, Asset__r.Name, Asset__r.Recordtype.DeveloperName , Recordtype.DeveloperName, FSSK__FSK_Assigned_Service_Resource__c, Asset__r.RecordTypeId, FSSK__FSK_Assigned_Service_Resource__r.AssetId, FSSK__FSK_Assigned_Service_Resource__r.Asset.Name , FSSK__FSK_Assigned_Service_Resource__r.Asset.RecordType.DeveloperName, FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__c, FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__r.Name ' +
            'FROM ServiceAppointment WHERE ParentRecordId != null ';
        
        if(selectedAppointmentType != null && selectedAppointmentType != '' && selectedAppointmentType != 'Choose Appointment Type...'){
            if(selectedAppointmentType == 'Amenity Appointment'){
                baseQuery += 'AND FSSK__FSK_Assigned_Service_Resource__r.Asset.RecordType.DeveloperName = \'Amenity\'';
            }else{
                baseQuery += 'AND FSSK__FSK_Assigned_Service_Resource__r.Asset.RecordType.DeveloperName = \'Com_Class_Schedule\'';
            }
        }else{
            baseQuery += 'AND (FSSK__FSK_Assigned_Service_Resource__r.Asset.RecordType.DeveloperName = \'Amenity\' OR FSSK__FSK_Assigned_Service_Resource__r.Asset.RecordType.DeveloperName = \'Com_Class_Schedule\')';
        }
        
        if (email != null && email != '') {
            baseQuery += ' AND Email = :email';
        }
        if (bookingNumber != null && bookingNumber != '') {
            baseQuery += ' AND AppointmentNumber = :bookingNumber';
        }
        if (!projectIdSet.isEmpty()) {
            baseQuery += ' AND Community__c IN :projectIdSet';
        }
        if (!unitIdSet.isEmpty()) {
            baseQuery += ' AND Asset__c IN :unitIdSet';
        }
        if (!accountIdSet.isEmpty()) {
            baseQuery += ' AND ParentRecordId IN :accountIdSet';
        }
        if(!assetIdSet.isEmpty()){
            baseQuery += ' AND FSSK__FSK_Assigned_Service_Resource__r.AssetId IN :assetIdSet';
        }
        if(!productIdSet.isEmpty()){
            baseQuery += ' AND FSSK__FSK_Assigned_Service_Resource__r.Asset.Com_Class__c IN :productIdSet';
        }
        if(status != null && status != '' && status != 'None'){
            baseQuery += ' AND Status = :status';
        }
        
        if(selectedDateRange != null && selectedDateRange != '' && selectedDateRange != 'Choose Range...'){
            switch on selectedDateRange {
                when 'Custom' {
                    if(startDate != null && startDate != ''){
                        Date startDt = Date.valueOf(startDate);
                        baseQuery += ' AND SchedStartTime >= :startDt';
                    }
                    if(endDate != null && endDate != ''){
                        Date endDt = Date.valueOf(endDate);
                        baseQuery += ' AND SchedEndTime <= :endDt';
                    }
                }	
                when 'Current Week' {
                    baseQuery += ' AND SchedStartTime = THIS_WEEK AND SchedEndTime = THIS_WEEK';
                }
                when 'Next Week' {
                    baseQuery += ' AND SchedStartTime = NEXT_WEEK AND SchedEndTime = NEXT_WEEK';
                }
                when 'Last Week' {
                    baseQuery += ' AND SchedStartTime = LAST_WEEK AND SchedEndTime = LAST_WEEK';
                }
                when 'Current Month' {
                    baseQuery += ' AND SchedStartTime = THIS_MONTH AND SchedEndTime = THIS_MONTH';
                }
                when 'Last Month' {
                    baseQuery += ' AND SchedStartTime = LAST_MONTH AND SchedEndTime = LAST_MONTH';
                }
                when 'Next Month' {
                    baseQuery += ' AND SchedStartTime = NEXT_MONTH AND SchedEndTime = NEXT_MONTH';
                }
                when else {
                    // code block 4
                }
            }
        }
        
        baseQuery += ' ORDER BY CreatedDate DESC';
        system.debug('accountIdSet'+accountIdSet);
        system.debug('baseQuery'+baseQuery);
        List<ServiceAppointment> allAppointments = Database.query(baseQuery);
        
        return allAppointments;
    }
    
    @AuraEnabled
    public static void updateAppointmentsList(List<ServiceAppointment> appointmentList, String selectedAttendance){
        
        Set<Id> contactIdSet = new Set<Id>();
        for(ServiceAppointment appoinment : appointmentList){
            if(appoinment.ContactId != null){
                contactIdSet.add(appoinment.ContactId);
            }
        }
        
        Map<String, Contact> contactMap = new Map<String, Contact>();
        for(Contact contactObj : [Select Id from Contact where Id IN : contactIdSet]){
            contactMap.put(contactObj.Id, contactObj);
        }
        
        List<Service_Appointment_Attendance__e> attendeeEventList = new List<Service_Appointment_Attendance__e>();
        
        if(selectedAttendance != null && selectedAttendance != ''){
            
            Service_Appointment_Attendance__e attendeeEvent;
            
            for(ServiceAppointment appointmentObj : appointmentList){
                appointmentObj.Com_Attended__c = selectedAttendance;
                if (appointmentObj.FSSK__FSK_Assigned_Service_Resource__r.Asset.RecordType.DeveloperName != 'Com_Class_Schedule') {
                    continue;
                }
                
                attendeeEvent = new Service_Appointment_Attendance__e();
                attendeeEvent.Bukrs__c = '1500';
                attendeeEvent.ProcessType__c = 'A';
                attendeeEvent.SesId__c = appointmentObj.AppointmentNumber;
                
                if(appointmentObj.Service_Appointment__c != null && appointmentObj.Service_Appointment__r.Master_service_appointment__c != null){
                    attendeeEvent.Regno__c = appointmentObj.Service_Appointment__r.Master_service_appointment__r.AppointmentNumber;
                }else if(appointmentObj.Service_Appointment__c != null){
                    attendeeEvent.Regno__c = appointmentObj.Service_Appointment__r.AppointmentNumber;
                }else if(appointmentObj.Master_Service_Appointment__c != null){
                    attendeeEvent.Regno__c = appointmentObj.Master_service_appointment__r.AppointmentNumber;
                }else{
                    attendeeEvent.Regno__c = appointmentObj.AppointmentNumber;
                }
                
                attendeeEvent.SesDate__c = appointmentObj.SchedStartTime;
                attendeeEvent.AttenStats__c = selectedAttendance == 'Present' ? 'P' : 'A';
                
                String applicantId = appointmentObj.ContactId != null ?  appointmentObj.ContactId : appointmentObj.AccountId;
                attendeeEvent.ApplicantId__c = applicantId;
                attendeeEvent.Appointment_Id__c = appointmentObj.Id;                    
                attendeeEventList.add(attendeeEvent);
                
            }
        }else{
            for(ServiceAppointment appointmentObj : appointmentList){
                appointmentObj.Status = 'Canceled ';
            }
        }
        
        if(!attendeeEventList.isEmpty()){
            List<Database.SaveResult> results = EventBus.publish(attendeeEventList);
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) {
                    System.debug('Successfully published event.');
                } else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('Error returned: ' + err.getStatusCode() );
                        ErrorLoggingController.logErrors('Com_ServiceAppointmentSearch', 'updateAppointmentsList', err.getMessage(), null, 'High');
                    }
                }
            }
        }
        
        update appointmentList;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getStatusOptions() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        Schema.DescribeFieldResult fieldResult = ServiceAppointment.Status.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry entry : ple) {
            options.add(new Map<String, String>{'label' => entry.getLabel(), 'value' => entry.getValue()});
        }
        return options;
    }
    
}