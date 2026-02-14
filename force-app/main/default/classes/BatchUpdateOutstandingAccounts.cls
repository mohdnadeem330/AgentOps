global class BatchUpdateOutstandingAccounts  implements Database.Batchable<sObject>, Database.AllowsCallouts{
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        Set<String> activeProjects = new Set<String>();
        for (OutstandingBalanceProjectEligibility__mdt proj : [SELECT Project_Name__c FROM OutstandingBalanceProjectEligibility__mdt WHERE Is_Active__c = true]) {
            activeProjects.add(proj.Project_Name__c);
        }
        String query = 'SELECT Id,Account__c FROM SalesOrder__c WHERE Status__c = \'sold\' AND Project_Name__c IN :activeProjects';
        
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<SalesOrder__c> scope)
    {
        set<Id> accIds= new set<Id>();
        for(SalesOrder__c so : scope ){
            if(so.Account__c !=  null ){
                accIds.add(so.Account__c);
            }
            
        }
        list<Account> accountList= new list<Account>();
        accountList = [SELECT id,ERPID__c  FROM Account WHERE Id IN :accIds ];
        System.debug('accountList '+accountList);
        APISetting__mdt ERPOutstandingCalloutDetails = [SELECT APIKey__c, SecretKey__c, APIId__c, Headers__c, SandboxURL__c, ProductionURL__c   FROM APISetting__mdt  WHERE MasterLabel = 'ERPOutstanding' ];
       
        Organization org = Utilities.getOrganizationDetails();
        String endPointURL = org.IsSandbox ? ERPOutstandingCalloutDetails.SandboxURL__c : ERPOutstandingCalloutDetails.ProductionURL__c;
        List<Account> accountsToUpdate = new List<Account>();
        for (Account acc : accountList){
            //CALLING ORACLE API and based on response DML on Account
            if(acc.ERPID__c != null){
                try{
                    Http http = new Http();
                    HttpRequest request = new HttpRequest();
                    request.setEndpoint(endPointURL);
                    request.setMethod('POST');
                    request.setHeader('Content-Type', 'application/json');
                    if (!org.IsSandbox) {
                        request.setHeader('client_secret', ERPOutstandingCalloutDetails.SecretKey__c);
                        request.setHeader('client_id', ERPOutstandingCalloutDetails.APIKey__c);
                    } else {
                        request.setHeader('client_secret', 'test');
                        request.setHeader('client_id', 'test');
                    }  
                    Map<String, Object> requestBody = new Map<String, Object>{
                        'oracle_party_id' => acc.ERPID__c
                            };
                                system.debug('requestBody::'+JSON.serialize(requestBody));
                    request.setBody(JSON.serialize(requestBody));
                    request.setTimeout(120000);
                    
                    HttpResponse response = http.send(request);
                    if (response.getStatusCode() == 200) {
                        
                        RestContextHandler handler = new RestContextHandler(false);
                        Map<String,String> responseKeyValues = handler.getRequestBodyMap();
                        String responseBody = response.getBody();
                        Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                        
                        //Check for Outstanding Amount
                        if( parsedResponse.containsKey('outStandingAmount') &&  Decimal.valueOf(String.valueOf(parsedResponse.get('outStandingAmount'))) > 0 ){
                            //update in account as this Acc have OS Amount
                            acc.HasOutstandingBalance__c = true ;
                            accountsToUpdate.add(acc);
                        }
                        
                    }  
                }
                catch (exception ex){
                    System.debug ('Error BatchupdateOsAcc'+ex.getmessage());
                    Logger__c lgs = LoggerService.createApexLog(ex,'BatchupdateOsAcc','BatchupdateOsAcc','Failed');
                }
            }
        }
        
        if (!accountsToUpdate.isEmpty()){
            update accountsToUpdate;
        }
        
    }
    global void finish(Database.BatchableContext BC) {
    }
    
    ///
    
}