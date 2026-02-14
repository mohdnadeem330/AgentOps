/**********************************************************************************************************************
* Name               : SendWhatsAppLinkWithBitly                                                        
* Description        : 
* Created By         :                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0                                                Initial Draft     
* 1.1           harsh@aldar           27/02/2024     Added the Sendgrid callout logic to send fasttrack emails  
******************************************************************************************************************/
global class SendWhatsAppLinkWithBitly implements Database.Batchable<sObject>,Database.Stateful,Database.AllowsCallouts{
    public set<Id> accToSend{get;set;}   
    public String Category{get;set;}     
    global SendWhatsAppLinkWithBitly(set<Id> accIds,String Category){
        this.Category = Category;
        accToSend = new set<Id>();
        if(accIds!=null)
            this.accToSend = accIds;
        else
            this.accToSend = null;
    }
   
    global Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id, Name,CustomerPortalURL__c,PersonMobilePhone,(SELECT Id,Name,Unit__r.Name,Category__c FROM Communication_Preferences__r WHERE Active__c=true ORDER BY CreatedDate DESC LIMIT 1) FROM Account WHERE Id IN: accToSend';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> soList){
        try{
            String UnitName ='';
            Account acc = soList[0];
            if(Category =='DigitalSales' && acc.Communication_Preferences__r != null && acc.Communication_Preferences__r.size() >0 && acc.Communication_Preferences__r[0].Category__c =='Booking'){
             UnitName = acc.Communication_Preferences__r[0].Unit__r.Name;
            }
        Map<String, Object> notificationBodyMap = new Map<String, Object>();
        WatsAppLinkGenesys__mdt whatsappgen = WatsAppLinkGenesys__mdt.getInstance(Category);
       Map<String, Object> notificationDataMap = new Map<String, Object>();
       notificationDataMap.put('Flow.CustomerName','Test Customer Name');
           notificationDataMap.put('Flow.ProjectName','5UT_project_5bed');
           notificationDataMap.put('Flow.HSMTemplateId',whatsappgen.HSMTemplateId__c);
           notificationDataMap.put('Flow.MobileNumber',acc.PersonMobilePhone);
           notificationDataMap.put('Flow.SalesManager','Test');
           notificationDataMap.put('Flow.LeadNumber','1234567');
           notificationDataMap.put('Flow.MessageType','MarketingComms');
           if(UnitName != '' && UnitName != null){
            notificationDataMap.put('Flow.AttributeName1',whatsappgen.AttributeName1__c);
            notificationDataMap.put('Flow.AttributeValue1',UnitName);
           }else{
            notificationDataMap.put('Flow.AttributeName1','DynamicURL');
            notificationDataMap.put('Flow.AttributeValue1','https://www.aldar.com/live/registration');
           }
           notificationDataMap.put('Flow.AttributeName2','any-attribute-2');
           notificationDataMap.put('Flow.AttributeValue2',acc.PersonMobilePhone);
           notificationDataMap.put('Flow.AttributeName3','any-attribute-3');
           notificationDataMap.put('Flow.AttributeValue3',acc.PersonMobilePhone);
           notificationDataMap.put('Flow.AttributeName4','any-attribute-4');
           notificationDataMap.put('Flow.AttributeValue4',acc.PersonMobilePhone);
           notificationDataMap.put('Flow.AttributeName5','any-attribute-5');
           notificationDataMap.put('Flow.AttributeValue5',acc.PersonMobilePhone);
            
           notificationBodyMap.put('flowId', whatsappgen.flowId__c);
           notificationBodyMap.put('name', whatsappgen.name__c); 
           
           notificationBodyMap.put('inputData', notificationDataMap);
   
           String requestBody = JSON.serialize(notificationBodyMap);
           String muleRes = '';
           MuleSoftSetting__mdt  mulesoftAPI = Utilities.getMuleSoftDetails(CustomerAPIConstants.WHATSAPP_LINK_GENESYS);
          
            Organization org = Utilities.getOrganizationDetails();
            
            String endPointURL = mulesoftAPI.SandboxURL__c ;
            if (!org.IsSandbox) {
                endPointURL = mulesoftAPI.ProductionURL__c ; 
            }

            Http http = new Http();
            HttpRequest request = new HttpRequest();

            request.setHeader('Content-Type', 'application/json');
            request.setHeader('client_secret', mulesoftAPI.APIKey__c);
            request.setHeader('client_id', mulesoftAPI.APIId__c);
            request.setTimeout(120000);
            request.setEndpoint(endPointURL);
            request.setMethod(mulesoftAPI.Method__c);
            System.debug('**Request Body**' + requestBody);
            request.setBody(requestBody);

            HttpResponse response = http.send(request);
            muleRes = response.getBody();
           
            System.debug('**Response Body**' + muleRes);
            //System.enqueueJob(new SendfastTrackWhatsappLinkQueueable(acc.CustomerPortalURL__c,acc.Id));

            //Harsh@ALdar 28/02/2024 Send Fasttrack Email via Sendgrid
            //SendGridIntegrationController.sendFasttrackOnboardingEmail(acc.Id);
        }catch(Exception e){
            String UserId = UserInfo.getUserId();
            LoggerService.save(LoggerService.addApexLog(e,'SendWhatsAppLinkWithBitly','Execute batch',''));
            String htmlEmailBody = 'Hello,</br></br> SendWhatsAppLinkWithBitly Execute has failed because of below error.</br></br>';
            htmlEmailBody += ' <b> ' + e.getMessage() + ' </b> </br> ' ;
            htmlEmailBody +=  ' <b> ' + e.getStackTraceString() + ' </b> ' ;
            htmlEmailBody +=  ' <b> ' +soList  +'for this User'+ UserId+' </b> ' ;
            List<String> recipientList = Label.SysAdminEmailAddress.split(';');
            Utilities.sendEmail(new list<Messaging.SingleEmailMessage>{Utilities.getEmailInstance('','','',recipientList, new List<String>(), new List<String>(), 'SendWhatsAppLinkWithBitly Batch', '',htmlEmailBody,new List<Messaging.EmailFileAttachment>(), '')});
            
        }
          
    }
    
    
    global void finish(Database.BatchableContext BC){
        
    }
}