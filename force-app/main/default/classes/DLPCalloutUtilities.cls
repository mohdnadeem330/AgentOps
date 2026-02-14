public with sharing class DLPCalloutUtilities {//utilities
    
    public static Map<String, String> priorityMapping = new Map<String, String>{'P1' => '1-Priority', 'P2' => '2-Priority', 'P3' => '3-Priority', 'P4' => '4-Priority', 'P5' => '5-Priority', 'P6' => '6-Priority'};

    public class BookingSystemIntegration implements Queueable,Database.AllowsCallouts {
        set<ID> sObjectIDsToProcess = new set<ID>();
        Map<Id,String> idsToProcessMap=new Map<Id,String>();
        public BookingSystemIntegration(Set<Id> idsToProcess){
            sObjectIDsToProcess = idsToProcess;
        }
        
         public BookingSystemIntegration(Map<Id,String> idsToProcessMap){
            this.idsToProcessMap = idsToProcessMap;
        }
        
        public void execute(QueueableContext context) {
            try{
                if(!sObjectIDsToProcess.isEmpty()){
                    processBookingSystemCallout(sObjectIDsToProcess,null);
                }else if(!idsToProcessMap.isEmpty()){
                     processBookingSystemCallout(idsToProcessMap.keySet(),idsToProcessMap);
                }
           }catch(Exception e){ 
            LoggerService.save(LoggerService.addApexLog(e,'BookingSystemIntegration','BookingSystemIntegration',''));
           }
            
        }
    }

    public class AsiteIntegration implements Queueable,Database.AllowsCallouts {
        set<ID> sObjectIDsToProcess = new set<ID>();
        public AsiteIntegration(Set<Id> idsToProcess){
            sObjectIDsToProcess = idsToProcess;
        }
        public void execute(QueueableContext context) {
            try{
                if(!sObjectIDsToProcess.isEmpty()){
                    processAsiteCallout(sObjectIDsToProcess);
                }
           }catch(Exception e){ 
            LoggerService.save(LoggerService.addApexLog(e,'AsiteIntegration','AsiteIntegration',''));
           }
            
        }
    }

    /**
    * processBookingSystemCallout 
    *
    * This method is used to query the required DLP field and trigger Appointments System
    *
    * @param idsToProcess Record IDs to be processed (Support Appointment__c)
    * @return    map<String,object>  list of select options
    * 
    */
    public static void processBookingSystemCallout(set<ID> idsToProcess, Map<ID,String> idsToProcessMap){
        Map<Id,Appointment__c> appointmentRecordMap = new Map<Id,Appointment__c>(AppointmentService.queryAllFieldsWithExtraFields(new List<Id>(idsToProcess)));
        
        MuleSoftSetting__mdt  appointmentsSystemAPIConfiguration = Utilities.getMuleSoftDetails(Constants.APPOINTMENT_SYSTEM);
        Organization orgDetails = Utilities.getOrganizationDetails();

        String endPointURL = appointmentsSystemAPIConfiguration.SandboxURL__c ;

        if(!orgDetails.IsSandbox){
            endPointURL = appointmentsSystemAPIConfiguration.ProductionURL__c ; 
        }

        list<sObject> sObjectRecordToUpdate = new list<sObject>();

        for(Appointment__c appointmentRecord : appointmentRecordMap.values()){
            String JSONBody='';

            //Process individual record
            AppointmentsSystemRequestWrapper requestRecord = new AppointmentsSystemRequestWrapper(appointmentRecord,idsToProcessMap);
            JSONBody = JSON.serialize(requestRecord);
            JSONBody = JSONBody.replace(':null', ':""');
            JSONBody = JSONBody.replace(':"null"', ':""');
           
            

            appointmentRecord = callAppointmentsSystem(endPointURL, appointmentsSystemAPIConfiguration, JSONBody, appointmentRecord);
            sObjectRecordToUpdate.add(appointmentRecord);
        }

        if(!sObjectRecordToUpdate.isEmpty() ){
            update sObjectRecordToUpdate;
        }
    }

    public static Appointment__c callAppointmentsSystem(String endPointURL, MuleSoftSetting__mdt appointmentsSystemAPIConfiguration, String JSONBody, Appointment__c recordToUpdate) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        request.setEndpoint(endPointURL);
        request.setMethod(appointmentsSystemAPIConfiguration.Method__c);
        request.setBody(JSONBody);
        request.setHeader('Content-Type','application/json');
        request.setHeader('client_secret',appointmentsSystemAPIConfiguration.APIKey__c);
        request.setHeader('client_id',appointmentsSystemAPIConfiguration.APIId__c);

        System.debug('JSONBody *******'+JSONBody);
        request.setTimeout(120000);
        
        HttpResponse response = http.send(request);
        System.debug('response.getBody()*******'+response.getBody());
        //TODO Update Survey Sent details
        //Parse response
        boolean success = (response!=null && response.getStatusCode() == 201);
        
        System.debug('recordToUpdate>>>' + recordToUpdate);
        if(success){
            JSONParser parser = JSON.createParser(response.getBody());

            recordToUpdate.put('AsiteSyncStatus__c', Constants.STATUS_SYNCED);

            while(parser.nextToken() != null){

                if('projectId'.equalsIgnoreCase(parser.getText())){
                    parser.nextToken();
                    recordToUpdate.put('AsiteProjectId__c', parser.getText());
    
                } else if('instanceGroupID'.equalsIgnoreCase(parser.getText())){
                    parser.nextToken();
                    recordToUpdate.put('AsiteInstanceGroupId__c', parser.getText());
            
                } else if('formId'.equalsIgnoreCase(parser.getText())){
                    parser.nextToken();
                    recordToUpdate.put('AsiteFormId__c', parser.getText());
            
                } else if('msgId'.equalsIgnoreCase(parser.getText())){
                    parser.nextToken();
                    recordToUpdate.put('AsiteMsgId__c', parser.getText());
                }
            }

            LoggerService.save(LoggerService.addApexServiceCalls('DLPCalloutUtilities - Success', 'callAppointmentsSystem - Success', Constants.APPOINTMENT_SYSTEM, JSONBody, response.getBody(), null));

        }else{
            recordToUpdate.put('AsiteSyncStatus__c', Constants.STATUS_FAILED);
            LoggerService.save(LoggerService.addApexServiceCalls('DLPCalloutUtilities', 'callAppointmentsSystem', Constants.APPOINTMENT_SYSTEM, JSONBody, response.getBody(), null));
        }
        System.debug('recordToUpdate>>>' + recordToUpdate);
        return recordToUpdate;
    }

    /**
    * processAsiteCallout 
    *
    * This method is used to query the required DLP field and trigger Asite
    *
    * @param idsToProcess Record IDs to be processed (Support Case)
    * @return    map<String,object>  list of select options
    * 
    */
    public static void processAsiteCallout(set<ID> idsToProcess){
        Map<Id,Case> caseRecordMap = new Map<Id,Case>(CaseService.queryAllFieldsWithExtraFields(new List<Id>(idsToProcess)));
        
        MuleSoftSetting__mdt  asiteAPIConfiguration = Utilities.getMuleSoftDetails(Constants.ASITE);

        Organization orgDetails = Utilities.getOrganizationDetails();

        String endPointURL = asiteAPIConfiguration.SandboxURL__c ;

        if(!orgDetails.IsSandbox){
            endPointURL = asiteAPIConfiguration.ProductionURL__c ; 
        }

        list<sObject> sObjectRecordToUpdate = new list<sObject>();

        for(Case caseRecord : caseRecordMap.values()){
            String JSONBody='';
            //Process individual record
            AsiteRequestWrapper requestRecord = new AsiteRequestWrapper(caseRecord);
            JSONBody = JSON.serialize(requestRecord);
            JSONBody = JSONBody.replace(':null', ':""');
            JSONBody = JSONBody.replace(':"null"', ':""');
            JSONBody = JSONBody.replace('date_c', 'date');

            caseRecord = callAsite(endPointURL, asiteAPIConfiguration, JSONBody, caseRecord);
            sObjectRecordToUpdate.add(caseRecord);
        }

        if(!sObjectRecordToUpdate.isEmpty() ){
            update sObjectRecordToUpdate;
        }
    }

    public static Case callAsite(String endPointURL, MuleSoftSetting__mdt asiteAPIConfiguration, String JSONBody, Case recordToUpdate) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        request.setEndpoint(endPointURL);
        request.setMethod(asiteAPIConfiguration.Method__c);
        request.setBody(JSONBody);
        request.setHeader('Content-Type','application/json');
        request.setHeader('client_secret',asiteAPIConfiguration.APIKey__c);
        request.setHeader('client_id',asiteAPIConfiguration.APIId__c);

        System.debug('JSONBody *******'+JSONBody);
        request.setTimeout(120000);
        
        HttpResponse response = http.send(request);
        System.debug('response.getBody()*******'+response.getBody());
        //TODO Update Survey Sent details
        //Parse response
        boolean success = (response!=null && response.getStatusCode() == 201);
        
        System.debug('recordToUpdate>>>' + recordToUpdate);
        if(success){

            JSONParser parser = JSON.createParser(response.getBody());

            recordToUpdate.put('AsiteSyncStatus__c', Constants.STATUS_SYNCED);

            while(parser.nextToken() != null){

                if('projectId'.equalsIgnoreCase(parser.getText())){
                    parser.nextToken();
                    recordToUpdate.put('AsiteProjectId__c', parser.getText());
    
                } else if('instanceGroupID'.equalsIgnoreCase(parser.getText())){
                    parser.nextToken();
                    recordToUpdate.put('AsiteInstanceGroupId__c', parser.getText());
            
                } else if('formId'.equalsIgnoreCase(parser.getText())){
                    parser.nextToken();
                    recordToUpdate.put('AsiteFormId__c', parser.getText());
            
                } else if('msgId'.equalsIgnoreCase(parser.getText())){
                    parser.nextToken();
                    recordToUpdate.put('AsiteMsgId__c', parser.getText());
                }
            }

            LoggerService.save(LoggerService.addApexServiceCalls('callAsite - Success', 'callAsite - Success', Constants.ASITE, JSONBody, response.getBody(), null));

        } else{
            recordToUpdate.put('AsiteSyncStatus__c', Constants.STATUS_FAILED);
            LoggerService.save(LoggerService.addApexServiceCalls('callAsite', 'callAsite', Constants.ASITE, JSONBody, response.getBody(), null));
        }
        System.debug('recordToUpdate>>>' + recordToUpdate);
        return recordToUpdate;
    }

    /**
    * AppointmentsSystemRequestWrapper 
    * Case input structure for Appointments System
    */
    class AppointmentsSystemRequestWrapper{
        public String projectName;
	    public String operator;
	    public String unit;
	    public String proposedTime;
	    public String reason;
	    public String resolutionPriority;
	    public String escalationPriority;
	    public String proposedDate;
	    public String project;
	    public String assignedToDlp;
	    public String oriUserRef;
	    public String location;
	    public String incidentNumber;
        public set<String> escalationPrioritylIST = new set<String>{'P1','P2','P3','P4','P5'};
        public String isUpdate ='';
        public String isCancelled='';
        public String lastUpdatedDateTime='';
        

        
        public AppointmentsSystemRequestWrapper(Appointment__c appointmentRecord, Map<ID,String> idsToProcessMap){
            projectName = appointmentRecord.Case__r.Unit__r.Project__r.AsiteProjectName__c;
            operator = '2';
            unit = appointmentRecord.Case__r.Unit__r.Name;
            proposedTime = '';
            reason = appointmentRecord.AppointmentType__c;
            resolutionPriority = ''; //appointmentRecord.Case__r.EscalationPriority__c != null ? resolutionPriorityMapping(appointmentRecord.Case__r.EscalationPriority__c) : '';
            escalationPriority = ''; //escalationPrioritylIST.contains(appointmentRecord.Case__r.Priority) ? appointmentRecord.Case__r.Priority : appointmentRecord.Case__r.Priority == null ? '' : 'PE';
            proposedDate = appointmentRecord.Date__c != null ? DateTime.newInstance(appointmentRecord.Date__c.year(), appointmentRecord.Date__c.month(), appointmentRecord.Date__c.day()).format('yyyy-MM-dd') : '';
            project = ''; //appointmentRecord.Project__c;
            assignedToDlp = appointmentRecord.Owner.Name + '|' + appointmentRecord.Owner.Email;
            System.debug('*** assignedToDlp ***'+assignedToDlp);
            oriUserRef = appointmentRecord.Case__r.Unit__r.Name;
            location = appointmentRecord.Location__c;
            incidentNumber = appointmentRecord.Case__r.CaseNumber;
            isCancelled='';
            isUpdate='';
            lastUpdatedDateTime='';
            if(idsToProcessMap!=null && idsToProcessMap.get(appointmentRecord.Id)==Constants.APPOINMENT_CANCELLED){
              isCancelled='Yes';
            }else if(idsToProcessMap!=null && idsToProcessMap.get(appointmentRecord.Id)==Constants.APPOINMENT_UPDATED){
              isUpdate='Yes';  
            }

            if(isUpdate=='Yes' || isCancelled=='Yes'){
                Datetime lastUpdatedTimeDate = System.now();
                List<String> values=new List<String>();
                values.add(lastUpdatedTimeDate.format('yyyy-MM-dd'));
                values.add(lastUpdatedTimeDate.format('hh:mm a'));
                lastUpdatedDateTime=String.join( values, '|' );
            }
            // to get proposedTime AM/PM
            if(appointmentRecord.StartTime__c != null && appointmentRecord.EndTime__c != null){
                Datetime startTimeDate = Datetime.newInstance(Date.today(), appointmentRecord.StartTime__c);
                Datetime endTimeDate = Datetime.newInstance(Date.today(), appointmentRecord.EndTime__c);
                proposedTime = startTimeDate.format('hh:mm a') + ' - ' + endTimeDate.format('hh:mm a');
            }
        }
    }
    
   public Static String getFromattedString(String oneStr,String twoStr){     
       return oneStr+'|'+twoStr;
    }

    /**
    * AsiteRequestWrapper 
    * Case input structure for Appointments System
    */
    class AsiteRequestWrapper{
        public String projectName;
        public String operator;
	    public String resolutionPriority;
	    public String createdBy;
	    public String subCategory;
	    public String assignedTo;
	    public String resolutionTypology;
	    public String incidentDescription;
	    public String category;
	    public String escalationPriority;
	    public String problemCode;
	    public String admUnitCode;
	    public String erpUnitCode;
	    public String rootCause;
	    public String unitNo;
	    public String oriUserRef;
        public set<String> escalationPrioritylIST = new set<String>{'P1','P2','P3','P4','P5'};
        public String incidentNumber;
        public String location;
        public String date_c;
        public String srTypologyCode;
        public String isUpdate='';

        public AsiteRequestWrapper(Case caseRecord){
            projectName = caseRecord.Unit__r.Project__r.AsiteProjectName__c;
            operator = '2';
            resolutionPriority = '';

            if(caseRecord.Priority != null){
                resolutionPriority = priorityMapping.containsKey(caseRecord.Priority) ? priorityMapping.get(caseRecord.Priority) : 'E-Priority';
            }

            createdBy = ''; //caseRecord.CreatedById;
            subCategory = caseRecord.SubCategory__c;
            assignedTo = caseRecord.Owner.Name + '|' + caseRecord.Owner.Email;
            resolutionTypology = caseRecord.ResolutionType__c;
            incidentDescription = caseRecord.IncidentDescription__c;
            category = caseRecord.CaseCategory__c;
            escalationPriority = priorityMapping.containsKey(caseRecord.EscalationPriority__c) ? caseRecord.EscalationPriority__c : caseRecord.EscalationPriority__c == null ? '' : 'PE';
            admUnitCode = ''; //caseRecord.Unit__r.ADMUnitNumber__c;
            erpUnitCode = caseRecord.Unit__r.Name;
            rootCause = caseRecord.AsiteRootCauses__c;
            unitNo = caseRecord.Unit__r.Name;
            oriUserRef = caseRecord.Unit__r.Name;
            problemCode = caseRecord.ProblemCode__c;
            incidentNumber = caseRecord.CaseNumber;
            location = '';
            date_c = DateTime.newInstance(Date.today().year(), Date.today().month(), Date.today().day()).format('yyyy-MM-dd');
            srTypologyCode = caseRecord.IncidentType__c;
        }
    }
}