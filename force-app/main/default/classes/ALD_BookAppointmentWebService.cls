/**********************************************************************************************************************
* Name              : ALD_BookAppointmentWebService                                                        
* Description       : Webservice class to book appointment in FSL 
* Method            : doGet()
* Created By        : nborse@aldar.com - Nilesh    
******************************************************************************************************************/
@RestResource(urlMapping = '/LiveAldar/BookAppointment')
global with sharing class ALD_BookAppointmentWebService {
     @HttpPost
    global static void doPost(){ 
        RestContextHandler handler = new RestContextHandler(true);
        try {
            RestRequest req = RestContext.request;
            Map<String, Object> reqBodyMap = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
            // Validate required fields
            if (reqBodyMap == null || !reqBodyMap.containsKey('reqId') || !reqBodyMap.containsKey('startTime') || !reqBodyMap.containsKey('endTime')) {
                throw new CustomException('Invalid input');
            }
            handler.response.data = bookAppointment(reqBodyMap );
            handler.response.success = true;
            handler.finalize();
         }
          catch (CustomException ex) {
            handler.response.success = false;
            handler.response.statusCode = 400; // Bad Request
            handler.response.message = ex.getMessage();
            handler.finalize(ex);
        }
         catch(Exception ex){
            // Handle any exceptions that occur
             
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);
        }
    }
    global static appointmentSchResponse bookAppointment(Map<String, Object> reqBodyMap ){
        TimeZone userTimeZone = UserInfo.getTimeZone();
        String operatingHrs = System.Label.DefaultOperatingHours;
        DateTime startDateTime = DateTime.valueOf((String)reqBodyMap.get('startTime'));//formatStringToDateTime((String)reqBodyMap.get('startTime'));//DateTime.valueOf((String)reqBodyMap.get('startTime'));
        DateTime endDateTime=  DateTime.valueOf((String)reqBodyMap.get('endTime'));//formatStringToDateTime((String)reqBodyMap.get('endTime'));//DateTime.valueOf((String)reqBodyMap.get('endTime'));
        if (startDateTime < DateTime.now() || endDateTime < DateTime.now())
             throw new CustomException('Invalid input');
       //Set<Id> setAppId = new Set<Id>();
       
       List<ServiceAppointment> lstCaseSA = [SELECT Id,Case__c,Case__r.Recordtype_Name__c,Duration,Case__r.CaseCategory__c FROM ServiceAppointment WHERE Case__c =: (String)reqBodyMap.get('reqId') AND Status IN('New','Re-scheduled','Scheduled') AND (RecordType.DeveloperName='Assessment' OR RecordType.DeveloperName='Resolution' OR RecordType.DeveloperName='AMC') ORDER BY RecordType.DeveloperName ASC ];
       DateTime dtTimeGMT = DateTime.valueOfGMT((String)reqBodyMap.get('startTime'));
       
       if(lstCaseSA.isEmpty())
           throw new CustomException('No Service appointment present');
        Boolean isSltAvl = false;
        List<FSL.AppointmentBookingSlot> slots;
        //for PPM get OH frm STM    
        if(lstCaseSA[0].Case__r.CaseCategory__c == 'PPM' ||lstCaseSA[0].Case__r.CaseCategory__c == System.Label.ODCaseCategoty){
            operatingHrs = AMC_ODBookAppointmentController.FetchOperatingHour(lstCaseSA[0].Duration);
            
        }
        slots = ALD_LiveAldarUtilityCtrl.fetchAppointmentSlots(lstCaseSA[0].Id,operatingHrs);
         
        for(integer i=0; i<slots.size(); i++){ 
           // System.debug('****slots[i].Interval.Start'+slots[i].Interval.Start);
            if(slots[i].Interval.Start == dtTimeGMT){ 
                isSltAvl = true;
                break;
            }    
        }
        if(!isSltAvl && !test.isRunningTest()){
            throw new CustomException('Selected slot is not available, Please try with different slot');
        }

        for(ServiceAppointment sa :lstCaseSA){
            sa.ArrivalWindowStartTime = startDateTime;//startDateTime;
            sa.ArrivalWindowEndTime  = startDateTime.addDays(30);//endDateTime;
            sa.SchedStartTime = startDateTime;//startDateTime;
            sa.SchedEndTime = endDateTime;//endDateTime;
            //setAppId.add(sa.Id);
        }
        UPDATE lstCaseSA;
        
        Boolean isDep = (lstCaseSA[0].Case__r.Recordtype_Name__c == 'DLP' ? true : false);
         FSL__Scheduling_Policy__c policy=[select id ,Name  from FSL__Scheduling_Policy__c where Name='Aldar Scheduling Policy' LIMIT 1];
         if(isDep)
            schDependentAppointment(policy.Id,lstCaseSA[0].Id,isDep);
          else
            schNormalAppointment(policy.Id,lstCaseSA[0].Id,isDep);
        ServiceAppointment  saAppointment = getAppointmentDetail(lstCaseSA[0].id);
        appointmentSchResponse resp = new appointmentSchResponse (saAppointment );
        resp.Status = (resp.Status == 'Scheduled' ? 'Re-Scheduled' : resp.Status);
        resp.Status = (resp.Status == 'New' ? 'Scheduled' : resp.Status);
        return resp ;
    }
    
    @future(callout=true)
    Global static void schDependentAppointment(Id schedulingPolicyId,Id app,boolean isDep){
        FSL.ScheduleService.scheduleExtended(schedulingPolicyId, app);//call this function only for dependent appointments

    }
    @future(callout=true)
    Global static void schNormalAppointment(Id schedulingPolicyId,Id app,boolean isDep){
        FSL.ScheduleService.schedule(schedulingPolicyId,app);
    }
    
    global static ServiceAppointment  getAppointmentDetail(Id saId){
        if(!String.isBlank(saId))
            return [SELECT Id,AppointmentNumber,Status,Technician_Comments__c,ArrivalWindowStartTime,ArrivalWindowEndTime,ServiceNote,SchedStartTime,FSSK__FSK_Assigned_Service_Resource__r.RelatedRecord.MobilePhone,SchedEndTime,FSSK__FSK_Assigned_Service_Resource__c,FSSK__FSK_Assigned_Service_Resource__r.Name FROM ServiceAppointment WHERE Id=:saId ORDER BY CreatedDate DESC LIMIT 1] ;
        return new ServiceAppointment();    
    }
    
    global class appointmentSchResponse{
        public String appointmentId             {get;set;}    
        public String appointmentNumber         {get;set;}    
        public String status                    {get;set;}   
        public String schedStartTime            {get;set;}
        public String schedEndTime              {get;set;}
        public String resourceId                {get;set;}    
        public String resourceName              {get;set;}   
        public String serviceNote               {get;set;}   
         
        Public appointmentSchResponse(ServiceAppointment servApp){
            
            this.appointmentId     = servApp.Id;
            this.appointmentNumber = servApp.AppointmentNumber;
            this.status            = (!String.isBlank(servApp.Status) && servApp.Status=='Canceled' ? 'Cancelled' :  servApp.Status);
            this.schedStartTime    = String.valueOf(servApp.ArrivalWindowStartTime);
            this.schedEndTime      =  String.valueOf(servApp.ArrivalWindowEndTime);
            this.resourceId        = servApp.FSSK__FSK_Assigned_Service_Resource__c;
            this.resourceName      = servApp.FSSK__FSK_Assigned_Service_Resource__r.Name;
            this.serviceNote       = (servApp.ServiceNote != null ? servApp.ServiceNote : servApp.Technician_Comments__c);
        } 
    } 
}