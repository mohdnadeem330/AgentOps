public class SendFasttrackWhatsaAppLink {
    @InvocableMethod(label='Create Digital Experience Record for Whatsapp link')
    public static List<FlowOutputs> createDigitalExpRecord(List<FlowInputs> request) {
        List<FlowOutputs> outputs = new List<FlowOutputs>();
        try{
            if(request != null){
                FlowOutputs output								= new FlowOutputs();
                List<Account> accountToUpdate					= new List<Account>();
                List<Communication_Preference__c> preferences 	= new List<Communication_Preference__c>();
                List<Communication_Preference__c> newPreferences= new List<Communication_Preference__c>();
                Set<Id> accountIds								= new Set<Id>();
                Set<String> projectIds							= new Set<String>();
                Set<Id> brokerAccs								= new Set<Id>();
				boolean isLSQProject = False;
                Boolean isBrokerPortal = false;
                
                List<String> projectNames = new List<String>();
                string lsqProjectNames =  System.Label.LSQ_Projects_names_Starts_with;	
                projectNames  = lsqProjectNames.split(',');
                
                for(FlowInputs input : request){
                    for(String str : projectNames){
                        if(input.Project.contains(str)){ 
                        	isLSQProject = True;
                        }
                        
                    }
                    if(input.sourceType == 'Broker Portal'){
                        isBrokerPortal = True;
                    }
                }
                
                for(FlowInputs input : request){
                    for(String str :projectNames){
                        if(!input.Project.contains(str)){
                           	accountIds.add(input.accountId);
                    		projectIds.add(input.project); 
                        }
                    }
                    
                }
                // Fetch preferences only if valid number of days and not broker portal
                if (System.label.NumberofDaysCP != '0' && !isBrokerPortal) {
                    Integer cpDays = Integer.valueOf(System.label.NumberofDaysCP);
                    Date cutoffDate = System.today().addDays(-cpDays);
                    
                    preferences = [
                        SELECT Id, Category__c, Project__c, Active__c, Status__c
                        FROM Communication_Preference__c
                        WHERE Category__c = 'FastTrack'
                        AND Account__c IN :accountIds
                        AND Project__c IN :projectIds
                        AND CreatedDate >= :cutoffDate
                        ORDER BY CreatedDate DESC
                        LIMIT 1
                    ];
                }
                
                if (!preferences.isEmpty()) {
                    Communication_Preference__c pref = preferences[0];                    
                    if (pref.Active__c && pref.Status__c == 'Link Sent') {
                        newPreferences.add(pref); output.digitalExperiences = newPreferences; outputs.add(output); return outputs;
                     } else if (!pref.Active__c || pref.Status__c == 'Fasttrack Completed') { newPreferences.add(returnRecord(pref, request[0]));}
                    
                } else if (!isLSQProject) {
                    newPreferences.add(returnRecord(null, request[0]));
                }
                
                system.debug('newPreferences >> '+newPreferences);
                upsert newPreferences;
                output.digitalExperiences = newPreferences; outputs.add(output);
            }
        }catch(Exception e){
            System.debug(e.getLineNumber() + '>>>EXCEPTION>>>'+e.getMessage());
           /* String htmlEmailBody = 'Hello,</br></br> SendFasttrackWhatsaAppLink createDigitalExpRecord has failed because of below error.</br></br>   <b> ' + e.getMessage() + ' </b> </br>   <b> ' + e.getStackTraceString() + ' </b>  ';
            Utilities.sendExceptionEmail('SendFasttrackWhatsaAppLink','createDigitalExpRecord',htmlEmailBody,'SendFasttrackWhatsaAppLink createDigitalExpRecord',e); */
            LoggerService.save(LoggerService.addApexLog(e,'Communication Preference Record Creation Failed','SendFasttrackWhatsaAppLink','createDigitalExpRecord')); // Added by Tajinkumar
        }
        return outputs;
    }
    
    public static Communication_Preference__c returnRecord(Communication_Preference__c preference, FlowInputs input) {
        Communication_Preference__c pref 	= preference != null ? preference : new Communication_Preference__c();
        pref.Category__c					= input.category;
        pref.Account__c						= (input.accountId == null || input.accountId == '') ? null : Id.valueOf(input.accountId);
        if(input.sourceType == 'Broker Portal'){
            pref.Broker_Agency__c				= (input.brokerAccountId == null || input.brokerAccountId == '') ? null : Id.valueOf(input.brokerAccountId);
            pref.Broker_Agent__c				= (input.brokerContactId == null || input.brokerContactId == '') ? null : Id.valueOf(input.brokerContactId);
        }
        pref.Source_Type__c					= input.sourceType;
        pref.Project__c						= input.project;
        //pref.Sales_Order__c					= (input.salesOrderId == null || input.salesOrderId == '') ? null : Id.valueOf(input.salesOrderId);
        pref.Status__c						= input.status;
        pref.Lead__c                        = input.LeadId; ////DIGITAL SALES CHIRAG
        pref.Unit__c                        = input.UnitId;//DIGITAL SALES CHIRAG
        pref.Active__c						= true;
        system.debug('returnRecord >>> '+pref);
        return pref;
    }
    
    public class FlowInputs{
        @InvocableVariable
        public String category;
        
        @InvocableVariable
        public String accountId;
        
        @InvocableVariable
        public String sourceType;
        
        @InvocableVariable
        public String brokerAccountId;
        
        @InvocableVariable
        public String brokerContactId;
        
        @InvocableVariable
        public String project;
        
        @InvocableVariable
        public String salesOrderId;
        
        @InvocableVariable
        public String status;

        @InvocableVariable
        public String UnitId;//DIGITAL SALES CHIRAG

        @InvocableVariable
        public String LeadId;//DIGITAL SALES CHIRAG
        
    }
    
    public class FlowOutputs{
        
        @InvocableVariable
        public List<Communication_Preference__c> digitalExperiences;
    }
}