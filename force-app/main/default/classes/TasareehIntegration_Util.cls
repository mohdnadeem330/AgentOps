public class TasareehIntegration_Util {
    
    //function to determine if the current environment is production
    public static boolean isProduction(){
        String sandboxName = DomainParser.parse(DomainCreator.getOrgMyDomainHostname()).getSandboxName();
        boolean isProd = false;
        if(!String.isEmpty(sandboxName)){
            isProd = false;
        }
        return isProd;
    }
    //function to get permit details
    public static Map<String,Id> getPermitDetail(Set<String> setExtPermIds){
        Map<String,Id> mapPermitId = new Map<String,Id>();
        try{
            for(Permit__c perm:[SELECT Id,RecordId__c FROM Permit__c WHERE RecordId__c=: setExtPermIds]){
                mapPermitId.put(perm.RecordId__c,perm.Id);
            }
        } catch (Exception ex) {
            LoggerService.save(LoggerService.createApexLog(ex,'getPermitDetail','TasareehIntegration_Util','getPermitDetail'));
            System.debug('Error in getPermitDetail: ' + ex.getMessage());
        }
        return mapPermitId;
    }
    
    //function to map external object records with field values
    public static Map<String,Sobject> mapWithExtObjRecs(String flds,String obj, String condFld,String extId,Set<String> val){
        Map<String,SObject> mapRelRecs = new Map<String,SObject>();
        try{
            String query = 'SELECT id,'+flds+' from ' +obj+ ' WHERE '+condFld +' =: val';
            system.debug('query >>'+query);
            for(SObject rec :Database.query(query)){
                mapRelRecs.put((String)rec.get(extId),rec);
            }
        } catch (Exception ex) {
            System.debug('Error in mapWithExtObjRecs: ' + ex.getMessage());
            LoggerService.save(LoggerService.createApexLog(ex,'mapWithExtObjRecs','TasareehIntegration_Util','mapWithExtObjRecs'));
        }
        return mapRelRecs;
    }
    
    @InvocableMethod
    public static List<OutputRequest> calculateDueDate(List<DueDateRequest> requests) {
        List<OutputRequest> dueDates = new List<OutputRequest>();
        
        integer finalTotalDays;
        List<SObject> Reclist=new List<SObject>();
        OutputRequest optReq = new OutputRequest();
        sObject Record;
        string fieldname;
        for (DueDateRequest request : requests) {
            DateTime AssignedDate= request.startDate;
            system.debug('AssignedDate '+AssignedDate);
            Integer invtervalValue = Integer.valueOf(calculateIntervalinMS(request.businessHoursRecord));system.debug('Bhours'+invtervalValue);
            if(!request.isDifference){
                DateTime dueDateTime = BusinessHours.add(request.businessHoursRecord.Id, AssignedDate, invtervalValue*request.businessDays)  ;
                if (request.objapiname == 'Permit_Payment__c'){
                dueDateTime= BusinessHours.nextStartDate(request.businessHoursRecord.Id, AssignedDate);
                    if(dueDateTime.date()==AssignedDate.date()){
                        dueDateTime = BusinessHours.add(request.businessHoursRecord.Id, AssignedDate, invtervalValue*request.businessDays)  ;
                        }
                }
                
                optReq.dueDate =dueDateTime;
                 system.debug('dueDateTime '+dueDateTime);
                if (request.objapiname == 'WorkflowTask__c') {
                    record = new WorkflowTask__c();
                    record.id=request.recId;
                    record.put('Actual_Due_Date__c',dueDateTime);
                    record.put('Update_Actual_Due_Date__c',true);
                    Reclist.add(record);
                }else  if (request.objapiname == 'Permit_Payment__c') {
                    record = new Permit_Payment__c();
                    record.id=request.recId;
                    record.put('Settlement_Date__c',dueDateTime);
                    record.put('Settlement_Date_Updated__c',true);
                    Reclist.add(record);
                } }else{
                if (request.objapiname == 'WorkflowTask__c') {
                    record = new WorkflowTask__c(Id = request.recId);
                    fieldname='Task_Duration__c';
                }
                Decimal totalBusinessHours = BusinessHours.diff(request.businessHoursRecord.Id, request.startDate, request.endDate);system.debug('hours'+totalBusinessHours);
                Integer totalBusinessDays = (Integer)((totalBusinessHours) / invtervalValue );
                system.debug('totalBusinessDays'+totalBusinessDays);
                optReq.noOfDays = totalBusinessDays;
                if(totalBusinessDays>0 ){
                    finalTotalDays=totalBusinessDays-1;
                }else{
                    finalTotalDays=totalBusinessDays; 
                }               
                
                record.put(fieldname,finalTotalDays);
                Reclist.add(record);
            }
            
            dueDates.add(optReq);
        }
        if(!Reclist.isEmpty()){
            update Reclist;
        }
        return dueDates;
    }
    
    public class DueDateRequest {
        @InvocableVariable(required=true)
        public DateTime startDate;
        @InvocableVariable
        public integer businessDays;
        @InvocableVariable(required=true)
        public BusinessHours businessHoursRecord;
        @InvocableVariable
        public DateTime endDate;
        @InvocableVariable(required=true)
        public Boolean isDifference;
        @InvocableVariable(required=true)
        public String recId;
        @InvocableVariable(required=true)
        public String objapiname;
        
    }
    
    public class OutputRequest {
        @InvocableVariable
        public DateTime dueDate;
        @InvocableVariable
        public Integer noOfDays;
    }
    
    public static Decimal calculateIntervalinMS(BusinessHours req){
        
        // Convert the time to decimal hours and calculate the difference
        Decimal difference = (req.MondayEndTime.hour() + (req.MondayEndTime.minute() / 60.0)) 
            - (req.MondayStartTime.hour() + (req.MondayStartTime.minute() / 60.0));
        
        if(difference==0){
            difference=24; // if 24 hrs business hrs difference will be 0, so setting manually as 24
        }
        system.debug('Difference'+difference);
        // Convert the difference to milliseconds and return
        return difference * 3600000;
    }
     public static String getPaymentBatchQuery(String objName) {
        String query;
        String feestatus='INVOICED';
        if(objName=='Permit_Payment__c'){
            query='select id,permit__c,PaymentMatchId__c from Permit_Payment__c where createdDate=TODAY OR LastModifiedDate=TODAY';
        }
        if(objName=='Fees__c'){
            query='select id,permit__c,PaymentMatchId__c,FeeStatus__c,Payment__c from Fees__c where (createdDate=TODAY OR LastModifiedDate=TODAY) AND Payment__c=null  ';
        }
        return query;
    }
    
    public static List<Fees__c> getFeesToUpdate(Set<String> paymentMatchIds) {
        return [SELECT Id, Permit__c, PaymentMatchId__c, FeeStatus__c, Payment__c 
                FROM Fees__c 
                WHERE Payment__c = null AND PaymentMatchId__c IN :paymentMatchIds];
    }
    
    public static List<Permit_Payment__c> getPermitPaymentsToUpdate(Set<String> feeMatchIds) {
        return [SELECT Id, PaymentMatchId__c 
                FROM Permit_Payment__c 
                WHERE PaymentMatchId__c IN :feeMatchIds];
    }
            
    public static void sendLoggerEmail() {
        String htmlBody = 'Dear Team,<br/><br/>Tasareeh job run is completed, please check the details below: ';
        Boolean hasError=false;
        String sub = 'Tasareeh Job Completion Notification '+String.valueOf(Date.Today());
        String tempStr='';
        String regexPattern = '<[^>]*>';
        for(Logger__c log : [SELECT Id,ClassName__c,Name,MethodName__c,ExceptionLogId__c,ExceptionTypeName__c,Message__c,ResponseMessage__c FROM Logger__c WHERE CreatedDate = TODAY AND ClassName__c LIKE 'Tasareeh%']){
            //tempStr = '<tr><td><a href=/'+log.Id+'>' + log.Name + '</a></td>';
            tempStr = '<tr><td><a href='+URL.getSalesforceBaseUrl()+''+log.Id+' target="_blank">'+log.Name+'</a></td>';
            
            tempStr += '<td>'+log.ClassName__c+'</td>';
            tempStr += '<td>'+log.MethodName__c+'</td>';
            tempStr += '<td>'+log.Message__c+'</td>';
            // Replace all HTML tags with an empty string
            String plainTextString = !String.isBlank(log.ResponseMessage__c) ? (log.ResponseMessage__c).replaceAll(regexPattern, ''): '';
            tempStr += '<td>'+plainTextString+'</td></tr>';
            hasError = true;
        }
        if(!hasError)
            htmlBody = '<br/>There are no error records found in the last job run.';
        else{
            String body = '<table border="1" width="100%"><tr><th>Log Name</th><th>Class Name</th><th>Method Name</th><th>Message</th><th>API Response</th></tr>';
            htmlBody += body + tempStr + '</table>';
        }        
        htmlBody += '<br/><br/>Regards,<br/>Aldar';
        String[]  toAddresses = (System.Label.TasareehAPIComplNotifyEmails != '-' ? System.Label.TasareehAPIComplNotifyEmails.split(',') : null);
        if(toAddresses.size () > 0){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setOrgWideEmailAddressId(System.Label.DLPOrgWideCustomerCareId);
            // Set email parameters
            mail.setToAddresses(toAddresses);
            mail.setSubject(sub);
            // Construct HTML body
            // Set the email body with HTML content
            mail.setHtmlBody(htmlBody);
            // Send the email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }
    
     public static String TasareehEmailBatchQuery() {
        String n = 'N';
        String ald = 'ALDARPD';
        String os = 'OS01';
        String aldos1 = 'ALDAR - Tasareeh OS1';
        
        return 'SELECT ID, Name, Department__c, IsCompleted__c, Email_Alert_Sent__c, Escalation_Email_Sent__c, Actual_Due_Date__c, Due_Date_for_Email_Alert__c, DueDate__c ' +
               'FROM WorkflowTask__c ' +
               'WHERE Due_Date_for_Email_Alert__c != null ' +
               'AND IsCompleted__c = \'' + n + '\' ' +
               'AND (Department__c = \'' + ald + '\' OR Department__c = \'' + os + '\' OR Department__c = \'' + aldos1 + '\')';
    }
    
    public static List<WorkflowTask__c> getReviewerNotificationTasks() {
        return [SELECT Id, Reviewer_Email__c FROM WorkflowTask__c 
                WHERE Notification_Date__c = TODAY 
                AND Reviewer_Email__c != NULL 
                AND Department__c IN ('ALDARPD', 'OS01', 'ALDAR - Tasareeh OS1') 
                AND IsCompleted__c = 'N'];
    }

    
}