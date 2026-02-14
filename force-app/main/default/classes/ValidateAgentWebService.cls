/*
* Purpose : To validate the agent an share the respective details in resposne
* Created by : Ajay Thakur
*/
@Restresource(urlMapping='/AgentDetails')
global class ValidateAgentWebService {
    
    @httppost
    global static void doPostMethod(String agentId) {     
        
        RestContextHandler handler = new RestContextHandler(true);
        List<Contact> conList = new List<Contact>();
        List<Lead> leadList = new List<Lead>();
        
        try
        {   

            AgentDetailModel agentDetailResponse = new AgentDetailModel();
            AgentDetail agentDetail = new AgentDetail();
            List<Projects> projectsList = new List<Projects>();

            conList = [SELECT id, Account.Name, Name, agentid__c,EmailAddress__c,PhoneNumberEnc__c,MobileNumberEnc__c,MobilePhone__c,MobilePhone,Account.BrokerClassification__r.Name,(SELECT id, Subject,Priority, Status,ActivityDate, Description, AgentEmailId__c FROM Tasks WHERE AgentActivityHistory__c = TRUE) 
                       FROM Contact WHERE agentid__c =: agentID];
            
            Schema.DescribeFieldResult fieldResult = Task.EventName__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            List<String> eventNameList = new List<String>();
            
            for( Schema.PicklistEntry pickListVal : ple){
                eventNameList.add(pickListVal.getLabel());
            }
            
            AgentDetail.EventDetails = eventNameList;

            //----- Get contact record
            if(conList!=null && conList.size()>0){
                Contact contactRec = conList[0];

                agentDetail.agencyName = String.isNotBlank(contactRec.Account.Name) ? contactRec.Account.Name : '';
                agentDetail.agentName = String.isNotBlank(contactRec.Name) ? contactRec.Name : '';
                agentDetail.uniqueId = String.isNotBlank(contactRec.agentId__c) ? contactRec.agentId__c : '';
                agentDetail.emailId = String.isNotBlank(contactRec.EmailAddress__c) ? contactRec.EmailAddress__c : ''; 
                agentDetail.phoneNumber = String.isNotBlank(contactRec.MobilePhone) ? contactRec.MobilePhone : '';
                agentDetail.brokerClassification = String.isNotBlank(contactRec.Account.BrokerClassification__r.Name) ? contactRec.Account.BrokerClassification__r.Name : '';
                
                //----Fetch all active projects
                list<Project__c> projectList= ProjectService.getAllActiveProjects();                
                Set<String> projectSet = new Set<String>();

                for(Project__c pr : projectList)
                {
                    projectSet.add(pr.name);
                }
                //agentDetail.projects = projectSet ;

                //------ Fetch Lead Details for the project and Broker agent                
                Map<String,List<String>> projectLeadNumberMap = new Map<String,List<String>>();

                for(Lead l : [select id,Project__c,LeadNumber__c,(select id, Subject,ActivityDate from Tasks) from Lead where Project__c IN: projectSet AND BrokerAgent__r.agentid__c =: agentID])
                {
                    System.debug('l.project__c '+l.project__c);
                    System.debug('l.LeadNumber__c '+l.LeadNumber__c);
                    Projects projects = new projects();
                                        
                    projects.Name = l.project__c;
                    projects.Id = l.LeadNumber__c;
                    projectsList .add(projects);
                }
                agentDetail.projectDetails = projectsList ;
                
                List<Task> taskList = contactRec.tasks;
                System.debug('taskList '+taskList);
                List<visitedHistory> vhList = new List<visitedHistory>();
                
                for(Task tk : taskList)
                {                    
                    VisitedHistory vh = new VisitedHistory();
                    vh.eventName = tk.Subject;
                    vh.activityDate = tk.ActivityDate;
                    vh.leadNumber = '';
                    vh.Comments = tk.Description;
                    vh.CreatedBy = tk.AgentEmailId__c;
                    vhList.add(vh);
                }
                
                agentDetail.visitedHistory = vhList; 

                //----- Fetch all the tasks created for a contact/agent Id
                agentDetailResponse.statusCode = Constants.STATUS_CODE_SUCCESS ;
                agentDetailResponse.status = Constants.SUCCESS_MESSAGE ;
                agentDetailResponse.details = agentDetail ;

                handler.response.success = true;
                handler.response.data = agentDetailResponse;
                handler.finalize();

            }
            //---- throw exception else
            else{                 
                handler.response.success = false;
                handler.response.statusCode = Constants.STATUS_CODE_NOT_FOUND;
                handler.response.message = Constants.INVALID_AGENT_ID;
                handler.finalize();
            }                
        }
        Catch(Exception e)
        {
            System.debug('line no '+e.getLineNumber());
            System.debug('msg '+e.getMessage());            
        }                
    }
    
    
    public class AgentDetailModel{
        public String status {get;set;}
        public Integer statusCode {get;set;}
        public AgentDetail details {get;set;}
        
    }
        
    public class AgentDetail {
            public String agencyName {get;set;}    
            public String agentName {get;set;}   
            public String uniqueId {get;set;}    
            public String emailId {get;set;}    
            public String phoneNumber {get;set;}
            public String brokerClassification  {get;set;}  
           // public Set<String> projects {get;set;}
            public List<Projects> projectDetails {get;set;}
            public List<VisitedHistory> visitedHistory {get;set;}
        	public List<String> EventDetails {get;set;}
    }
    
    public class VisitedHistory {
            public String eventName {get;set;}    
            public Date activityDate {get;set;}
            public String leadNumber {get;set;} 
        	public String Comments {get;set;} 
        	public String CreatedBy {get;set;} 
    }

    public class Projects{
        public String Name {get;set;}
        public String Id {get;set;}
    }
}