@RestResource(urlMapping = '/LiveAldar/GetAppointmentCandidates')
global without sharing class AppointmentCandidatesWebService {
    
    @HttpPost
    global static void doPost() {
        RestContextHandler handler = new RestContextHandler(true);
        try {
            String startDateTime = null;
            String endDateTime = null;
            DateTime actualStartDateTime;
            DateTime actualEndDateTime;
            RestRequest req = RestContext.request;
            CandidatesRequestWrapper requestData = (CandidatesRequestWrapper) JSON.deserialize(req.requestBody.toString(), CandidatesRequestWrapper.class);           
            System.debug('requestData: ' + requestData);
            if (requestData == null || String.isBlank(requestData.projectName) || String.isBlank(requestData.appointmentType) ) {
                throw new CustomException('Invalid input');
            }
            List<AppointmentSchedulingPolicy> schedulingPolicyRec = [SELECT Id, DeveloperName FROM AppointmentSchedulingPolicy WHERE DeveloperName = :System.Label.Handover_Appointment_Scheduling_Policy LIMIT 1];
            List<WorkTypeGroup> workTypegroupRec = [SELECT Id, Name FROM WorkTypeGroup WHERE Name = :requestData.appointmentType AND IsActive = true LIMIT 1];
            List<ServiceTerritory > serviceTerritoryRec  = [SELECT Id, Name, Type__c, Project_Name__c FROM ServiceTerritory WHERE Type__c = 'Scheduler' AND Project_Name__c = :requestData.projectName AND IsActive = true LIMIT 1];         
            if(workTypegroupRec.isEmpty() || serviceTerritoryRec.isEmpty()){
                throw new CustomException('Invalid projectName or appointmentType');
            }
            //String appType = requestData.appointmentType + ' - Scheduled';
            String OrientationType = String.isNotBlank(requestData.OrientationType) && requestData.OrientationType.equalsIgnoreCase('Virtual') ? 'Virtual': requestData.OrientationType.equalsIgnoreCase('Third Party') ? 'Third Party' : 'In-person';
            String appType = requestData.appointmentType + ' - '+OrientationType;
            //List<WorkType> workTypeRec = [SELECT Id, Name FROM WorkType WHERE Name = :appType ];
            List<ServiceTerritoryWorkType> SrTerritoryWorkTypeRec = [SELECT Id, WorkTypeId FROM ServiceTerritoryWorkType where ServiceTerritoryId =:serviceTerritoryRec[0].Id and  WorkType.Type__c =: OrientationType ];
            if(SrTerritoryWorkTypeRec.isEmpty()){
                throw new CustomException('Work Type not found');
            }
            if(!String.isBlank(requestData.startDate)){
                Date startDateFormatted = Date.valueOf(requestData.startDate);
                actualStartDateTime = DateTime.newInstance(startDateFormatted.year(), startDateFormatted.month(), startDateFormatted.day(), 0, 0, 0);
                startDateTime = actualStartDateTime.format('yyyy-MM-dd\'T\'HH:mm:ssZ', 'Asia/Dubai');
            } else if(String.isBlank(requestData.startDate)){
                actualStartDateTime = System.now();
                startDateTime = actualStartDateTime.format('yyyy-MM-dd\'T\'HH:mm:ssZ','Asia/Dubai');
            }
            if(!String.isBlank(requestData.endDate)){
                Date endDateFormatted = Date.valueOf(requestData.endDate);
                actualEndDateTime = DateTime.newInstance(endDateFormatted.year(), endDateFormatted.month(), endDateFormatted.day(), 28, 59, 0);
                endDateTime = actualEndDateTime.format('yyyy-MM-dd\'T\'HH:mm:ssZ', 'Asia/Dubai');
            } else if(String.isBlank(requestData.endDate)){
                actualEndDateTime = actualStartDateTime.addDays(10);
                endDateTime = actualEndDateTime.format('yyyy-MM-dd\'T\'HH:mm:ssZ','Asia/Dubai');
            }                                        
            AppointmentCandidateService appointmentCandidates = AppointmentCandidateService.getAppointmentCandidates(SrTerritoryWorkTypeRec[0].WorkTypeId, workTypegroupRec[0].Id, serviceTerritoryRec[0].Id, schedulingPolicyRec[0].Id, startDateTime, endDateTime);          
            
            handler.response.data = appointmentCandidates;
            handler.response.success = true;
            handler.finalize();           
        } catch (CustomException ex) {
            handler.response.success = false;
            handler.response.statusCode = 400;
            handler.response.message = ex.getMessage();
            handler.finalize(ex);            
        } catch (Exception ex) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);
        }
    }
    
    public class CandidatesRequestWrapper {
        public String projectName { get; set; }
        public String appointmentType { get; set; }
        public String startDate { get; set; }
        public String endDate { get; set; }
        public String OrientationType; 

    }
    
}