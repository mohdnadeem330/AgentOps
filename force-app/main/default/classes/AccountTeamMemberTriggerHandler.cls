public without sharing class AccountTeamMemberTriggerHandler extends TriggerHandler{

    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        documentSharewithTeamMember( (List<AccountTeamMember>) newList);
    }
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        List<AccountTeamMember> amtToBeUpdated = new List<AccountTeamMember>();
        for(AccountTeamMember atm: (List<AccountTeamMember>) newList){
            AccountTeamMember oldatm = (AccountTeamMember) oldMap.get(atm.Id);
            if(atm.AccountAccessLevel !=  oldatm.AccountAccessLevel || atm.AccountId !=  oldatm.AccountId  ){
                amtToBeUpdated.add(atm);
            }
        }
        if(!amtToBeUpdated.isEmpty()){
            documentSharewithTeamMember(amtToBeUpdated);
        }
    }
    public override void beforeDeleteMethod(List<SObject> oldList, Map<Id, SObject> oldMap){
        documentShareDeletewithTeamMember( (List<AccountTeamMember>) oldList);
    }
    public static void documentShareDeletewithTeamMember(List<AccountTeamMember> oldList){
        Set<Id> accountIdset = new Set<Id>();
        Set<Id> userIdset = new Set<Id>();
        Map<Id, List<Document__c>> accountDocumentMap = new Map<Id, List<Document__c>>();
        List<Document__Share> documentShareListToBedeleted = new List<Document__Share>();
        
        for(AccountTeamMember accountTeamMember: oldList){
            accountIdset.add(accountTeamMember.AccountId);
            userIdset.add(accountTeamMember.UserId);
        } 
        system.debug('accountIdset::'+accountIdset);
        system.debug('userIdset::'+userIdset);
        List<Document__Share> documentShare = [SELECT
                                               Id 
                                               FROM Document__Share 
                                               WHERE ParentId IN (SELECT
                                                                  Id
                                                                  FROM 
                                                                  Document__c
                                                                  WHERE Account__c IN:accountIdset )
                                               AND UserOrGroupId IN:userIdset]; 
        
        system.debug('documentShare::'+documentShare);
        
        if(!documentShare.isEmpty()){
            delete documentShare;
        }  
    }
   
    public static void documentSharewithTeamMember(List<AccountTeamMember> newList){
        try{
        Set<Id> accountIdset = new Set<Id>();
        Map<Id,Id> accountTeamMap = new Map <Id,Id>();
        Map<Id, List<Document__c>> accountDocumentMap = new Map<Id, List<Document__c>>();
        List<Document__Share> documentShareList = new List<Document__Share>();
        for(AccountTeamMember accountTeamMember: newList){
            accountIdset.add(accountTeamMember.AccountId);
        }  
        system.debug('accountIdset::'+accountIdset);
        for(Document__c document: [SELECT
                                   Id,
                                   Account__r.OwnerId,
                                   Account__c,
                                   OwnerId
                                   FROM 
                                   Document__c
                                   WHERE Account__c IN:accountIdset]){
                                       List<Document__c> doclist = accountDocumentMap.get(document.Account__c)  != null ?   accountDocumentMap.get(document.Account__c) : new List<Document__c>();
                                       doclist.add(document)  ;  
                                       accountDocumentMap.put(document.Account__c, doclist);
                                   }
        system.debug('accountDocumentMap::'+accountDocumentMap);
        system.debug('accountDocumentMap size::'+accountDocumentMap.values().size());
        
        system.debug('newList::'+newList);
        system.debug('newList size::'+newList.size());
        
        for(AccountTeamMember accountTeamMember: newList){
            if(accountDocumentMap.containsKey(accountTeamMember.AccountId)){
                List<Document__c> doculist = accountDocumentMap.get(accountTeamMember.AccountId);
                system.debug('doculist::'+doculist);
                system.debug('doculist size::'+doculist.size());
                
                for(Document__c document: doculist){
                    if(document.OwnerId !=  accountTeamMember.UserId){
                        Document__Share docShare = new Document__Share();
                        docShare.AccessLevel = accountTeamMember.AccountAccessLevel;
                        docShare.ParentId = document.Id;
                        docShare.UserOrGroupId = accountTeamMember.UserId;
                        docShare.RowCause = 'Manual';
                        documentShareList.add(docShare);
                    }
                } 
            }
        }
        system.debug('documentShareList::'+documentShareList);
        system.debug('documentShareList size::'+documentShareList.size());
        if(!documentShareList.isEmpty()){
            insert documentShareList;
        }
        }catch(Exception e){
            LoggerService.save(LoggerService.addApexLog(e,'AccountTeamMemberTriggerHandler','insert DocumentShare',''));
            String htmlEmailBody = 'Hello,</br></br> AccountTeamMemberTriggerHandler documentSharewithTeamMember has failed because of below error.</br></br>';
            htmlEmailBody += ' <b> ' + e.getMessage() + ' </b> </br> ' ;
            htmlEmailBody +=  ' <b> ' + e.getStackTraceString() + ' </b> ' ;
            htmlEmailBody +=  ' <b> parameters : New List = ' + newList+' </b> ' ;
            List<String> recipientList = Label.SysAdminEmailAddress.split(';');
            Utilities.sendEmail(new list<Messaging.SingleEmailMessage>{Utilities.getEmailInstance('','','',recipientList, new List<String>(), new List<String>(), 'documentShareList insert Failure', '',htmlEmailBody,new List<Messaging.EmailFileAttachment>(), '')});
            
        }
    }
}