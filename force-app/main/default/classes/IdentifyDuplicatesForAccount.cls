public class IdentifyDuplicatesForAccount {
    
  /*    public static List<AccountTeamMember>  addAccountTeamsForChild(List<Account> accountList){
        List<AccountTeamMember> accountTeamsToInsert = new List<AccountTeamMember>();
        for(Account acc : accountList){
//            if(acc.Owner.IsActive){
                Boolean accessFound = false;
                for(AccountTeamMember atm : acc.AccountTeamMembers){
                    if(atm.accountID == acc.Id && acc.OwnerId == atm.userId){
                        accessFound = true;
                        break;
                    }
                }
                if(!accessFound){
                    AccountTeamMember atm = new AccountTeamMember(AccountId = acc.Id,UserId = acc.OwnerId,AccountAccessLevel='Edit',CaseAccessLevel='None',OpportunityAccessLevel='None',TeamMemberRole='Sales Manager');
                    accountTeamsToInsert.add(atm);
                }
//            }
        }
        system.debug('accountTeamsToInsert '+accountTeamsToInsert);
        return accountTeamsToInsert;
    }
    
  public static void removeSpecialCharacter(){
        List<Account> accList = new List<Account>();
        for(Account acc : [Select Id,NationalIdNumber__pc  FROM Account WHERE NationalIdNumber__pc like '%-%' order by NationalIdNumber__pc ]){
            system.debug('acc '+acc);
            String s1 = acc.NationalIdNumber__pc;
            acc.NationalIdNumber__pc = s1.replace('-','');
            //            acc.NationalIdNumber__pc = s1;
            accList.add(acc);
        }
        system.debug('++ '+accList);
        Update accList;
    }
    
    public static void accountTeamAccessForDUplicates(List<Account> accList){
        List<AccountTeamMember> memberList = new List<AccountTeamMember>();
        for(Account acc : accList){
            AccountTeamMember member = new AccountTeamMember();
            if(acc.AccountTeamMembers == null || acc.AccountTeamMembers.size() == 0){
                member.AccountId = acc.Id;
                member.AccountAccessLevel = 'Edit';
                member.OpportunityAccessLevel = 'Read';
                member.CaseAccessLevel = 'None';
                member.UserId = acc.OwnerId;
                memberList.add(member);
            }else{
                Boolean skipATM = false;
                for(AccountTeamMember atm : acc.AccountTeamMembers){
                    if(atm.userId == acc.OwnerId){
                        skipATM = true;
                    }
                }
                if(skipATM){
                    member.AccountId = acc.Id;
                    member.AccountAccessLevel = 'Edit';
                    member.OpportunityAccessLevel = 'Read';
                    member.CaseAccessLevel = 'None';
                    member.UserId = acc.OwnerId;
                    memberList.add(member);
                }
            }
        }
        system.debug('++ '+accList);
        Insert memberList;
    }*/
    
    public static List<Account> identifyDuplicates(List<Account> accountList,boolean forPassport){
        Set<String> phoneNumbers = new Set<String>();
        Set<String> emails = new Set<String>();
        Set<String> nationalIds = new Set<String>();
        List<Account> accToUpdate = new List<Account>();
        // Map to store the number of sales orders for each account
        Map<Id, Integer> salesOrderCountMap = new Map<Id, Integer>();
        // Map to store the number of opportunities for each account
        Map<Id, Integer> opportunityCountMap = new Map<Id, Integer>();
        // Populate the salesOrderCountMap and opportunityCountMap
      
        for(Account acc : accountList){
            phoneNumbers.add(acc.MobilePhone__pc); 
            emails.add(acc.PersonEmail);
            if(forPassport){
                nationalIds.add(acc.PassportNumber__pc); 
            }else{
                nationalIds.add(acc.NationalIdNumber__pc); 
            }
        }   
        //
        Map<String,List<Account>> accountsByUniqueKey = new Map<String,List<Account>>();
        for(Account acc : [SELECT Id,MobilePhone__pc,createddate,PersonEmail,NationalIdNumber__pc,(SELECT ID FROM Opportunity_Units__r),(SELECT Id FROM Opportunities) FROM Account WHERE MobilePhone__pc IN: phoneNumbers AND 
                           PersonEmail IN: emails AND
                           NationalIdNumber__pc IN: nationalIds AND MasterAccount__c =null AND MergedAccount__c = false 
                           ORDER BY CreatedDate DESC]){
                               // OR PassportNumber__pc IN: nationalIds
                               String uniqueKey = '';
                               if(forPassport){
                                   uniqueKey = acc.MobilePhone__pc + acc.PersonEmail + acc.PassportNumber__pc ;
                               }else{
                                   uniqueKey = acc.MobilePhone__pc + acc.PersonEmail + acc.NationalIdNumber__pc ;
                               }
                               if(accountsByUniqueKey.containsKey(uniqueKey)){
                                   accountsByUniqueKey.get(uniqueKey).add(acc);
                               }else{
                                   accountsByUniqueKey.put(uniqueKey,new List<Account>{acc});
                               }
                               if(acc.Opportunity_Units__r != null){
                                   salesOrderCountMap.put(acc.Id, acc.Opportunity_Units__r.size());
                               }else{
                                   salesOrderCountMap.put(acc.Id, 0);
                               }
                               if(acc.Opportunities != null){
                                   opportunityCountMap.put(acc.Id, acc.Opportunities.size());
                               }else{
                                   opportunityCountMap.put(acc.Id, 0);
                               }
                           }
        
/*        // Query to get the number of sales orders for each account
        List<AggregateResult> salesOrderCountResults = [
            SELECT Account__c, COUNT(Id) salesOrderCount
            FROM SalesOrder__c
            WHERE Account__c IN :accountsByUniqueKey.keySet()
            GROUP BY Account__c
        ];
        
        // Update the salesOrderCountMap with the count of sales orders
        for (AggregateResult result : salesOrderCountResults) {
            Id accountId = (Id)result.get('Account__c');
            Integer count = (Integer)result.get('salesOrderCount');
            salesOrderCountMap.put(accountId, count);
        }
        
        // Query to get the number of opportunities for each account
        List<AggregateResult> opportunityCountResults = [
            SELECT AccountId, COUNT(Id) opportunityCount
            FROM Opportunity
            WHERE AccountId IN :accountsByUniqueKey.keySet()
            GROUP BY AccountId
        ];
        
        // Update the opportunityCountMap with the count of opportunities
        for (AggregateResult result : opportunityCountResults) {
            Id accountId = (Id)result.get('AccountId');
            Integer count = (Integer)result.get('opportunityCount');
            opportunityCountMap.put(accountId, count);
        }*/
        
        Map<String,Account> mastersByUniqueKey = new Map<String,Account>(); 
        for(String uniqueKey : accountsByUniqueKey.keySet()){
            if(accountsByUniqueKey.get(uniqueKey).size() > 1){
                //                Integer highestSoCount = 0;
                Account masterAccount;
                for(Account acc : accountsByUniqueKey.get(uniqueKey)){
                    if(masterAccount != null){
                        if(salesOrderCountMap.get(acc.Id) > salesOrderCountMap.get(masterAccount.Id) ){
                            masterAccount = acc;
                        }else if(salesOrderCountMap.get(acc.Id) == salesOrderCountMap.get(masterAccount.Id)){
                            if(opportunityCountMap.get(acc.Id) > opportunityCountMap.get(masterAccount.Id)){
                                masterAccount = acc;
                            }else if(opportunityCountMap.get(acc.Id) == opportunityCountMap.get(masterAccount.Id)){
                                if(acc.CreatedDate > masterAccount.CreatedDate){
                                    masterAccount = acc;
                                }
                            }
                        }
                    }else{
                        masterAccount = acc;
                    }
                    
                    //=======
                    
                    /*if(masterAccount != null){
                        if(acc.CreatedDate > masterAccount.CreatedDate){
                            //     highestSoCount = acc.Opportunity_Units__r.size();
                            masterAccount = acc;
                        }
                    }else{
                        masterAccount = acc;
                    }*/
                    
                    
                    /*if(masterAccount !=null){
                        if(acc.Opportunity_Units__r != null){
                            if(highestSoCount < acc.Opportunity_Units__r.size() ){
                                highestSoCount = acc.Opportunity_Units__r.size();
                                masterAccount = acc;
                            }else if(highestSoCount == acc.Opportunity_Units__r.size() && masterAccount != null){
                                if(acc.CreatedDate > masterAccount.CreatedDate){
                                    highestSoCount = acc.Opportunity_Units__r.size();
                                    masterAccount = acc;
                                }
                            }
                        }
                    }else{
                        masterAccount = acc;
                        if(acc.Opportunity_Units__r != null){
                            highestSoCount = acc.Opportunity_Units__r.size();
                        }else{
                            highestSoCount = 0;
                        }
                    }*/
                }
                if(masterAccount != null){
                    mastersByUniqueKey.put(uniqueKey, masterAccount);
                }
            }
        }
        for(String uniqueKey : accountsByUniqueKey.keySet()){
            if(mastersByUniqueKey.containsKey(uniqueKey)){
                for(Account acc : accountsByUniqueKey.get(uniqueKey)){
                    if(mastersByUniqueKey.get(uniqueKey).Id != acc.Id){
                        acc.MasterAccount__c = mastersByUniqueKey.get(uniqueKey).Id;
                        accToUpdate.add(acc);
                    }
                }
            }
        }
        system.debug('accToUpdate '+accToUpdate);
        return accToUpdate;
    }
}