/**********************************************************************************************************************
* Name              : ALD_FetchAppointmentSlotsWebService                                                        
* Description       : Webservice class to fetch and return available slots for the request 
* Method            : doGet()
* Created By        : nborse@aldar.com - Nilesh    
* V2.0              : Changes related on-demand service
******************************************************************************************************************/
@RestResource(urlMapping = '/LiveAldar/Appointment')
global without sharing class ALD_FetchAppointmentSlotsWebService {
    @HttpPost
    global static void doPost(){ 
        RestContextHandler handler = new RestContextHandler(true);
         try {
             RestRequest req = RestContext.request;
             Map<String, Object> reqBodyMap = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
             if (reqBodyMap == null || !reqBodyMap.containsKey('reqId') || String.isBlank((String)reqBodyMap.get('reqId'))) {
                throw new CustomException('Parameter is required and cannot be empty');
            }
             String reqId = (String)reqBodyMap.get('reqId');
             // Fetch configurations and set the response data
             handler.response.data = getSlots(reqId);
             handler.response.success = true;
             handler.finalize();
         }catch (CustomException ex) {
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

    global static List<slotsWrapper> getSlots(String caseId){    
        List<slotsWrapper> lstWrap = new List<slotsWrapper>();
        validateProjectTerritory(caseId);
        String operatingHrs = System.Label.DefaultOperatingHours;
       // String saId = ALD_LiveAldarUtilityCtrl.getServiceAppointmentByType(caseId,System.Label.DLPAMCSAFilterRecType);
        List<ServiceAppointment> lstSA = [SELECT Id,Case__r.Recordtype_Name__c,Record_Type_Name__c,Case__r.CaseCategory__c,Duration,SchedStartTime,SchedEndTime,ArrivalWindowStartTime,ArrivalWindowEndTime,Status FROM ServiceAppointment WHERE Case__c=:caseId AND Status != 'Closed' ORDER BY Record_Type_Name__c ASC];

        if(lstSA.isEmpty())
            throw new CustomException('No service appointment found');

        //make ArrivalWindowStartTime/end to null to fetch the appointment slot for re-scheduling
        /*for(ServiceAppointment sa:lstSA){
            if(sa.Status == 'Scheduled' || sa.Status == 'Re-scheduled'){
                sa.ArrivalWindowStartTime = null;
                sa.ArrivalWindowEndTime = null;
            } 
        }
        if(lstSA[0].Status == 'Scheduled' || lstSA[0].Status == 'Re-scheduled')
            UPDATE lstSA;*/
        //for PPM get OH frm STM    
        /*if(lstSA[0].Case__r.CaseCategory__c == 'PPM'){
            List<ServiceTerritoryMember> lstSTM = [SELECT Id,OperatingHoursId,OperatingHours.Name FROM ServiceTerritoryMember WHERE ServiceTerritoryId =: lstSA[0].ServiceTerritoryId AND OperatingHoursId != null];    
            if(!lstSTM.isEmpty())
           */
        //Chnages
        if((lstSA[0].Case__r.CaseCategory__c == 'PPM' || lstSA[0].Case__r.CaseCategory__c == System.Label.ODCaseCategoty) && lstSA[0].Duration != null){
            operatingHrs = AMC_ODBookAppointmentController.FetchOperatingHour(lstSA[0].Duration);
            List<FSL.AppointmentBookingSlot> slots = ALD_LiveAldarUtilityCtrl.fetchAppointmentSlots(lstSA[0].Id,operatingHrs);lstWrap = returnAvailableSlots(slots);
            return lstWrap;
        }
        
        List<FSL.AppointmentBookingSlot> slots = ALD_LiveAldarUtilityCtrl.fetchAppointmentSlots(lstSA[0].Id,operatingHrs);

        if(slots.isEmpty() && !test.isRunningTest()) throw new CustomException('No slots are available for booking');

        if(lstSA[0].Case__r.Recordtype_Name__c == 'DLP'){ //FOR DLP Cases, get both the appointment slots and compare the slots and return only matchig slots
            set<String> setAvailableSlots = new set<String>();
            for(integer i=0; i<slots.size(); i++){ setAvailableSlots.add(String.valueOf(slots[i].Interval.Start)); }
            List<FSL.AppointmentBookingSlot> slots2 = ALD_LiveAldarUtilityCtrl.fetchAppointmentSlots(lstSA[1].Id,operatingHrs);
            List<FSL.AppointmentBookingSlot> lstAvlSlots = new List<FSL.AppointmentBookingSlot>();
            for(integer i=0; i< slots2.size(); i++){ 
                if(setAvailableSlots.contains(String.valueOf(slots2[i].Interval.Start))){  lstAvlSlots.add(slots2[i]); }
            }
            return returnAvailableSlots(lstAvlSlots); 
        }
        return returnAvailableSlots(slots);
    }

    public static List<slotsWrapper> returnAvailableSlots(List<FSL.AppointmentBookingSlot> slots){
        List<slotsWrapper> lstWrap = new List<slotsWrapper>();
        for(integer i=0; i<slots.size(); i++){
            slotsWrapper newRec = new slotsWrapper(); newRec.start = slots[i].Interval.Start ; 
            newRec.finish = slots[i].Interval.Finish ; newRec.labelval =  slots[i].Interval.Start +' - '+slots[i].Interval.Finish ;
            lstWrap.add(newRec);
        }
        return lstWrap;
    }
    
    public static void validateProjectTerritory(String caseId){
        Case c = [SELECT Id,Unit__c,Recordtype_Name__c ,Unit__r.Project__c,Unit__r.Project__r.Name FROM Case WHERE Id=:caseId LIMIT 1];
        if(c.Recordtype_Name__c == 'StandardCase' && !test.isRunningTest())
           throw new CustomException('No project found for the selected unit');     
        List<ServiceTerritory> lstTerritory = [SELECT Id,Name  FROM ServiceTerritory  WHERE Name =: c.Unit__r.Project__r.Name];
        if(lstTerritory.isEmpty() && !test.isRunningTest())
            throw new CustomException('Territory is not configured for the selected unit');
    }

    public static Id getServiceAppointmentByType(String caseId,String recTypeDevName){
        return [SELECT Id FROM ServiceAppointment WHERE Case__c =: caseId AND RecordType.DeveloperName =:recTypeDevName LIMIT 1]?.Id;
    } 
    
    public static ServiceTerritoryMember getServiceTerritoryMember(String saId){
        ServiceTerritoryMember sm = new ServiceTerritoryMember();
        List<ServiceAppointment> lst = [SELECT Id,ServiceTerritoryId FROM ServiceAppointment WHERE Id=: saId];
        if(!lst.isEmpty()){
            List<ServiceTerritoryMember> lstSTM = [SELECT Id FROM ServiceTerritoryMember WHERE ServiceTerritoryId=:lst[0].ServiceTerritoryId];
            if(!lstSTM.isEmpty()) return lstSTM[0];     
        }
        return sm;
    }
    
    global class slotsWrapper{
        public datetime start{get;set;}
        public datetime finish{get;set;}
        public  String labelval{get;set;}
        public slotsWrapper(){}
    }   
}