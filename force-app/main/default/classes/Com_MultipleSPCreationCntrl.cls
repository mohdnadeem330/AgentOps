public class Com_MultipleSPCreationCntrl {
    
    @AuraEnabled
    public static spResponsePayload createMultipleAppointments(String accountId, String classScheduleId, List<String> optionalAttendee){
        
        spResponsePayload wrapperObj = new spResponsePayload();
        TimeZone timeZoneObj = Timezone.getTimeZone('Asia/Dubai');
        
        Asset assetObj = [Select Id, Name, Project__c, Building__c, ECSS_Zone__c, Com_Start_DateTime__c, Com_End_Time__c, Com_No_of_Minutes_Duration__c, Country, CountryCode, Street, City, PostalCode, State, StateCode, Com_Operating_Hour_Id__c, Com_Package__c, Com_Package__r.Com_Total_No_of_Sessions__c from Asset where Id =: classScheduleId];
        
        Account accountObj = [Select Id, Name from Account where Id =: accountId];
        
        List<ServiceResource> serviceResourceList = [Select Id, Name from ServiceResource where AssetId = :assetObj.Id];
        
        if(serviceResourceList.isEmpty()) throw new AuraHandledException('No Service Resource found for this Asset '+assetObj.Name);
        ServiceResource serviceResource = [Select Id, Name from ServiceResource where AssetId = :assetObj.Id];
        ServiceTerritoryMember serviceTerrMember = [Select ServiceTerritoryId, ServiceTerritory.Name from ServiceTerritoryMember where ServiceResourceId =: serviceResource.Id];
        
        ServiceTerritoryWorkType serviceTerrWorkType = [Select WorkTypeId, WorkType.Name from ServiceTerritoryWorkType where ServiceTerritoryId =: serviceTerrMember.ServiceTerritoryId LIMIT 1];
        
        WorkTypeGroupMember groupMember = [SELECT WorkTypeId, WorkTypeGroupId, Id FROM WorkTypeGroupMember where WorkTypeId =: serviceTerrWorkType.WorkTypeId];
        
        /*lxscheduler.GetAppointmentCandidatesInput input = new lxscheduler.GetAppointmentCandidatesInputBuilder()
.setWorkTypeGroupId(groupMember.WorkTypeGroupId)
.setTerritoryIds(new List<String>{serviceTerrMember.ServiceTerritoryId})
.setStartTime(System.now().format('yyyy-MM-dd\'T\'HH:mm:ssZ'))
.setEndTime(assetObj.Com_End_Time__c.format('yyyy-MM-dd\'T\'HH:mm:ssZ'))
.setAccountId(accountId)
.setSchedulingPolicyId('0VrJ7000000XZAH')
.setApiVersion(Double.valueOf('64.0'))
.build();

String response = lxscheduler.SchedulerResources.getAppointmentCandidates(input);


lxscheduler.WorkType workType = new lxscheduler.WorkTypeBuilder()
.setId(serviceTerrWorkType.WorkTypeId)
.build();*/
        
        AppointmentSchedulingPolicy defaultPolicy = [SELECT Id, DeveloperName, IsOrgDefault FROM AppointmentSchedulingPolicy where IsOrgDefault= true LIMIT 1];
        
        lxscheduler.GetAppointmentSlotsInput input1 = new lxscheduler.GetAppointmentSlotsInputBuilder()
            .setWorkTypeGroupId(groupMember.WorkTypeGroupId)
            .setTerritoryIds(new List<String>{serviceTerrMember.ServiceTerritoryId})
            .setStartTime(System.now().format('yyyy-MM-dd\'T\'HH:mm:ssZ'))
            .setEndTime(assetObj.Com_End_Time__c.format('yyyy-MM-dd\'T\'HH:mm:ssZ'))
            .setAccountId(accountId)
            .setRequiredResourceIds(new List<String>{serviceResourceList[0].Id})
            .setSchedulingPolicyId(defaultPolicy.Id)
            .setApiVersion(Double.valueOf('64.0'))
            .setAllowConcurrentScheduling(true)
            .build();
        
        String response1 = lxscheduler.SchedulerResources.getAppointmentSlots(input1);
        
        system.debug('response1=>'+response1);
        
        List<SchedulerAppointments> allslots = SchedulerAppointments.parse(response1);
        
        List<ServiceAppointment> spList = new List<ServiceAppointment>();
        ServiceAppointment appointmentObj;
        
        Integer index = 1;
        Integer loopLimit = assetObj.Com_Package__c != null && assetObj.Com_Package__r.Com_Total_No_of_Sessions__c != null ?  (Integer)assetObj.Com_Package__r.Com_Total_No_of_Sessions__c : 10; 
        List<Integer> remainingSlots = new List<Integer>();
        system.debug('vakue from package'+assetObj.Com_Package__r.Com_Total_No_of_Sessions__c);
        system.debug('loopLimit'+loopLimit);
        
        if(allslots.size() < loopLimit){
            wrapperObj.insufficientSlots = true;
            return wrapperObj;
        }else{
            wrapperObj.insufficientSlots = false;
            for(SchedulerAppointments wrapperRecord : allslots){
                if(index <= loopLimit){
                    
                    remainingSlots.add(wrapperRecord.remainingAppointments);
                    
                    system.debug('wrapperRecord=>'+wrapperRecord);
                    appointmentObj = new ServiceAppointment();
                    appointmentObj.Asset__c = assetObj.Id;
                    appointmentObj.WorkTypeId = serviceTerrWorkType.WorkTypeId;
                    appointmentObj.ServiceTerritoryId = serviceTerrMember.ServiceTerritoryId;
                    appointmentObj.ParentRecordId = accountId;
                    appointmentObj.SchedStartTime = wrapperRecord.startTime;
                    appointmentObj.SchedEndTime = wrapperRecord.endTime;
                    appointmentObj.Duration = assetObj.Com_No_of_Minutes_Duration__c;
                    appointmentObj.Status = 'Approved';
                    appointmentObj.Country = assetObj.Country;
                    appointmentObj.City = assetObj.City;
                    appointmentObj.State = assetObj.State;
                    appointmentObj.StateCode = assetObj.StateCode;
                    appointmentObj.PostalCode = assetObj.PostalCode;
                    appointmentObj.DurationType = 'Minutes';
                    appointmentObj.FSSK__FSK_Assigned_Service_Resource__c = serviceResource.Id;
                 //   appointmentObj.Status__c = 'Approved';
                    appointmentObj.Zone__c = assetObj.ECSS_Zone__c;
                    appointmentObj.Community__c = assetObj.Project__c;
                    appointmentObj.Precinct__c = assetObj.Building__c;
                    appointmentObj.WorkTypeId = groupMember.WorkTypeId;
                    appointmentObj.RecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByDeveloperName().get('Community_Appointments').getRecordTypeId();
                    
                    spList.add(appointmentObj);
                    
                    index++;
                }
            }
        }
        
        
        wrapperObj.appointmentList = spList;
        wrapperObj.resourceObj = serviceResource;
        wrapperObj.serviceResourceId = serviceResource.Id; 
        wrapperObj.territoryTypeObj = serviceTerrWorkType;
        wrapperObj.territoryMemberObj = serviceTerrMember;
        wrapperObj.accObj = accountObj;
        wrapperObj.optionalAttendee = optionalAttendee;
        wrapperObj.workTypeGroup = groupMember.WorkTypeGroupId;
        wrapperObj.remainingSlots = remainingSlots;
        return wrapperObj;
        
        /*Http http = new Http();
HttpRequest req = new HttpRequest();
req.setEndpoint('https://aldarproperties--community.sandbox.my.salesforce.com/services/data/v64.0/scheduling/getAppointmentSlots');
req.setMethod('POST');
req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
req.setHeader('Content-Type', 'application/json');

String body = JSON.serialize(new Map<String, Object>{
'requiredResourceIds' => new List<String>{serviceResourceList[0].Id},
'territoryIds' => new List<String>{serviceTerrMember.ServiceTerritoryId},
'workTypeGroupId' => groupMember.WorkTypeGroupId,
'startTime' => System.now().format('yyyy-MM-dd\'T\'HH:mm:ssZ'),
'endTime' => System.now().addDays(10).format('yyyy-MM-dd\'T\'HH:mm:ssZ'),
'appointmentMode' => 'Group',
'allowConcurrentScheduling' => true    
});

req.setBody(body);
HttpResponse res = http.send(req);
System.debug('Response Status: ' + res.getStatus());
System.debug('Response Body: ' + res.getBody());

Map<String, Object> timeSlotWrapper = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());

List<responseWrapper> wrapperList = (List<responseWrapper>) JSON.deserialize(JSON.serialize(timeSlotWrapper.get('timeSlots')), List<responseWrapper>.class);


List<ServiceAppointment> spList = new List<ServiceAppointment>();
ServiceAppointment appointmentObj;
Integer index = 1;
for(responseWrapper wrapperRecord : wrapperList){
if(index <= 10){
appointmentObj = new ServiceAppointment();
appointmentObj.WorkTypeId = serviceTerrWorkType.WorkTypeId;
appointmentObj.ServiceTerritoryId = serviceTerrMember.ServiceTerritoryId;

Integer offset = timeZoneObj.getOffset(wrapperRecord.startTime);
appointmentObj.SchedStartTime = wrapperRecord.startTime.addSeconds(offset / 1000);
appointmentObj.SchedEndTime = wrapperRecord.endTime.addSeconds(offset / 1000);
appointmentObj.Duration = assetObj.Com_No_of_Minutes_Duration__c;
appointmentObj.Status = 'Scheduled';
appointmentObj.Country = assetObj.Country;
appointmentObj.City = assetObj.City;
appointmentObj.State = assetObj.State;
appointmentObj.StateCode = assetObj.StateCode;
appointmentObj.PostalCode = assetObj.PostalCode;
appointmentObj.DurationType = 'Minutes';

spList.add(appointmentObj);

index++;
}

}

wrapperObj.appointmentList = spList;
wrapperObj.resourceObj = serviceResourceList[0];
wrapperObj.territoryTypeObj = serviceTerrWorkType;
wrapperObj.territoryMemberObj = serviceTerrMember;
wrapperObj.accObj = accountObj;
return wrapperObj;
*/
        
    }
    
    /*
     * commented out because we don't use leads anymore as it switched to account/contact and the service appointments are being created in the flow
    @AuraEnabled
    public static void createAppointments(List<ServiceAppointment> appointmentList, List<String> optionalAttendees, String appointmentSubject, String appointmentDescription){
        insert appointmentList;
        
        List<ServiceAppointment> spList = new List<ServiceAppointment>();
        ServiceAppointment childAppointmentObj;
        
        for(ServiceAppointment appoinmentObj : appointmentList){
            
            appoinmentObj.Subject = appointmentSubject;
            appoinmentObj.Description = appointmentDescription;
            
            for(String leadObjId : optionalAttendees){
                childAppointmentObj = appoinmentObj.clone(false, true, false, false);
                childAppointmentObj.ParentRecordId = leadObjId;
                childAppointmentObj.Service_Appointment__c = appoinmentObj.Id;
                childAppointmentObj.Subject = appointmentSubject;
                childAppointmentObj.Description = appointmentDescription;
                
                spList.add(childAppointmentObj);
            }
        }
        
        if(!spList.isEmpty()) insert spList;
        
        if(!appointmentList.isEmpty()) update appointmentList;
    }
    */
    
    public class responseWrapper{
        public Integer attendeeLimit;
        
        public DateTime startTime;
        
        public DateTime endTime;
        
        public Integer remainingAppointments;
        
        Public Id territoryId;
    }
    
    
    public class spPayload{
        @AuraEnabled
        public String accountId;
        
        @AuraEnabled
        public String classScheduleId;
        
        @AuraEnabled
        public List<String> optionalAttendee;
        
        @AuraEnabled
        public Date appointmentDate;
    }
    
    public class spResponsePayload{
        @AuraEnabled
        public List<ServiceAppointment> appointmentList;
        
        @AuraEnabled
        public List<ServiceAppointmentAttendee> appointmentAttendeeList;
        
        @AuraEnabled
        public ServiceResource resourceObj;
        
        @AuraEnabled
        public ServiceTerritory territotyObj;
        
        @AuraEnabled
        public ServiceTerritoryMember territoryMemberObj;
        
        @AuraEnabled
        public ServiceTerritoryWorkType territoryTypeObj;
        
        @AuraEnabled
        public Account accObj;
        
        @AuraEnabled
        public List<String> optionalAttendee;
        
        @AuraEnabled
        public Id workTypeGroup;
        
        @AuraEnabled 
        public Id serviceResourceId;
        
        @AuraEnabled 
        public Boolean insufficientSlots;
        
        @AuraEnabled 
        public List<Integer> remainingSlots;
        
    }
    
    
    public class AppointmentSlot {
        public Datetime startTime;
        public Datetime endTime;
        public List<Id> availableResourceIds;
        
        public AppointmentSlot(Datetime startTime, Datetime endTime) {
            this.startTime = startTime;
            this.endTime = endTime;
            this.availableResourceIds = new List<Id>();
        }
    }
}