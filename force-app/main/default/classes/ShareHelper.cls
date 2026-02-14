public without sharing class ShareHelper {
   
    
    public static void shareLeadRecord(List<Lead> newList, String accessLevel){

        List<LeadShare> sharing = new List<LeadShare>();
        Set<Id> leadIds = new Set<Id>();

        for (Lead leadRec : newList) {
            if(leadRec.BrokerAgency__c != null){
                leadIds.add(leadRec.Id);
            }
        }

        List<Lead> leadList = [SELECT Id, Name, BrokerAgency__c, BrokerAgency__r.OwnerId FROM Lead WHERE Id IN : leadIds 
                                AND BrokerAgency__c != null];

        for (Lead leadRec : leadList) {
            LeadShare leadShare  = new LeadShare();
            leadShare.LeadId = leadRec.Id;
            leadShare.UserOrGroupId = leadRec.BrokerAgency__r.OwnerId;
            leadShare.LeadAccessLevel = accessLevel;
            leadShare.RowCause = Schema.LeadShare.RowCause.Manual;
            sharing.add(leadShare);
        }

        System.debug('point: sharing: '+sharing);
        Database.insert(sharing,false);
    }
    /* Commenting for BAG deployment - Rohit
    public static void shareSaleOrderRecord(List<String> saleOrderIds, String accessLevel,String UserOrGroupId){
        List<SalesOrder__Share> sharing = new List<SalesOrder__Share>();
        for (String saleOrderId : saleOrderIds) {
            SalesOrder__Share saleOrderShare  = new SalesOrder__Share();
            saleOrderShare.ParentId = saleOrderId;
            saleOrderShare.UserOrGroupId = UserOrGroupId;
            saleOrderShare.AccessLevel = accessLevel;
            saleOrderShare.RowCause = Schema.SalesOrder__Share.RowCause.Manual;
            sharing.add(saleOrderShare);
        }
        System.debug('point: sharing: '+sharing);
        Database.insert(sharing,false);
    }
    
     public static void shareCaseOppRecord(List<String> oppIds, String accessLevel,String UserOrGroupId){
        List<OpportunityShare> sharing = new List<OpportunityShare>();
        for (String oppId : oppIds) {
            OpportunityShare oppShare  = new OpportunityShare();
            oppShare.OpportunityId = oppId;
            oppShare.UserOrGroupId = UserOrGroupId;
            oppShare.OpportunityAccessLevel = accessLevel;
            oppShare.RowCause = Schema.OpportunityShare.RowCause.Manual;
            sharing.add(oppShare);
        }
        System.debug('point: sharing: '+sharing);
        Database.insert(sharing);
    }
    
     public static void shareCaseAccRecord(List<String> accIds, String accessLevel,String UserOrGroupId){
        List<AccountShare> sharing = new List<AccountShare>();
        for (String accId : accIds) {
            AccountShare accShare  = new AccountShare();
            accShare.AccountId = accId;
            accShare.UserOrGroupId = UserOrGroupId;
            accShare.AccountAccessLevel = accessLevel;
            accShare.RowCause = Schema.AccountShare.RowCause.Manual;
            sharing.add(accShare);
        }
        System.debug('point: sharing: '+sharing);
        Database.insert(sharing,false);
    }*/


    public static void shareOpportunityRecord(List<Opportunity> newList, String accessLevel){

        List<OpportunityShare> sharing = new List<OpportunityShare>();

        List<Id> oppIds = new List<Id>();
        for (Opportunity record : newList) {
            if(record.BrokerAgencyAccount__c != null){
                oppIds.add(record.Id);
            }
        }

        List<Opportunity> opportunityList = [SELECT Id, Name, BrokerAgencyAccount__c, BrokerAgencyAccount__r.OwnerId FROM Opportunity 
                                                WHERE Id IN : oppIds AND BrokerAgencyAccount__c != null];

        for (Opportunity oppRec : opportunityList) {
            OpportunityShare opportunityShare  = new OpportunityShare();
            opportunityShare.OpportunityId = oppRec.Id;
            opportunityShare.UserOrGroupId = oppRec.BrokerAgencyAccount__r.OwnerId;
            opportunityShare.OpportunityAccessLevel = accessLevel;
            opportunityShare.RowCause = Schema.OpportunityShare.RowCause.Manual;
            sharing.add(opportunityShare);
        }

        System.debug('point: sharing: '+sharing);
        Database.insert(sharing, false);
    }

    public static void shareAccountRelatedToOpportunity(List<Opportunity> newList, String accessLevel){
        Map<Id, Id> newAccountTemaMemberMap = new Map<Id, Id>();

        
        List<AccountTeamMember> accountMemberList = new List<AccountTeamMember>();
        for (Opportunity oppRec : newList) {
            if (oppRec.AccountId != null) {
                AccountTeamMember accountMember = new AccountTeamMember();
                accountMember.AccountId = oppRec.AccountId;
                accountMember.UserId = oppRec.OwnerId;
                accountMember.CaseAccessLevel = Constants.NONE_ACCESS;
                accountMember.OpportunityAccessLevel = Constants.NONE_ACCESS;
                accountMember.AccountAccessLevel = accessLevel;
                // ADDED BY CLOUDZLAB START
                accountMember.TeamMemberRole = 'Leasing Agent';
                // ADDED BY CLOUDZLAB END

                accountMemberList.add(accountMember);

                newAccountTemaMemberMap.put(oppRec.AccountId, oppRec.OwnerId);
            }
        }
        System.debug('point: sharing: ' + accountMemberList);
        Database.insert(accountMemberList, false);

        if (!newAccountTemaMemberMap.isEmpty()) {
            shareDocumentWithNewAccountTeamMember(newAccountTemaMemberMap, Constants.EDIT_ACCESS);
        }
    }

    public static void shareAccountRecordWhenBrokerAgentChanged(Map<Id, Id> agentsChangedAccountIds, String accessLevel){
        //Record to be created
        List<AccountShare> sharingToInsert = new List<AccountShare>();
        //Man map that stores the account ID and Expected users to be shared with
        Map<Id,set<Id>> accountWithExpectedUsers = new Map<Id,set<Id>>();

        map<id,User> mapOfContactToUser = new map<id,User>();
        map<id,set<ID>> mapPartnerAccountToAgencyAdmins = new map<id,set<ID>>();
        //get the user record for the Broker 
        for(User tempU : [select id,ContactId,AccountID,isActive from user where  ContactId IN : agentsChangedAccountIds.values() ]){
            mapOfContactToUser.put(tempU.ContactId,tempU);
            mapPartnerAccountToAgencyAdmins.put(tempU.AccountID,new set<ID>() );
        }

        System.debug('point: mapOfContactToUser: '+mapOfContactToUser);
        System.debug('point: mapOfContactToUserSize: '+mapOfContactToUser.size());

        //With the broker account fetched above, get all the agency Users for those accounts
        for(User tempU : [select id,ContactId,AccountID from user where  AccountID IN : mapPartnerAccountToAgencyAdmins.keySet() and isActive=true and ProfileName__c in (:Constants.AGENCY_ADMIN_PROFILE,:Constants.AGENCY_ADMIN_PROFILE_LOGIN)]){
            mapPartnerAccountToAgencyAdmins.get(tempU.AccountID).add(tempU.Id);
        }
        
        System.debug('point: mapPartnerAccountToAgencyAdmins: '+mapPartnerAccountToAgencyAdmins);
        System.debug('point: mapPartnerAccountToAgencyAdminsSize: '+mapPartnerAccountToAgencyAdmins.size());

        //Start preparing expected user's set
        set<id> usersToBeUsed = new set<ID>();
        for(Id tempAccountID : agentsChangedAccountIds.Keyset()){

            if(!mapPartnerAccountToAgencyAdmins.containsKey(tempAccountID)){
                accountWithExpectedUsers.put(tempAccountID, new set<Id>());
                //Adding the broker user record
                if(mapOfContactToUser.containskey(agentsChangedAccountIds.get(tempAccountID)) && mapOfContactToUser.get(agentsChangedAccountIds.get(tempAccountID)).isActive){
                    accountWithExpectedUsers.get(tempAccountID).add(mapOfContactToUser.get(agentsChangedAccountIds.get(tempAccountID)).Id );
                }
                //adding the broker's account related Agency Users
                if(mapOfContactToUser.containskey(agentsChangedAccountIds.get(tempAccountID)) && mapPartnerAccountToAgencyAdmins.containsKey(mapOfContactToUser.get(agentsChangedAccountIds.get(tempAccountID)).AccountId) && !mapPartnerAccountToAgencyAdmins.get(mapOfContactToUser.get(agentsChangedAccountIds.get(tempAccountID)).AccountId).isEmpty() ){
                    accountWithExpectedUsers.get(tempAccountID).addAll(mapPartnerAccountToAgencyAdmins.get(mapOfContactToUser.get(agentsChangedAccountIds.get(tempAccountID)).AccountId));
                }
                usersToBeUsed.addAll(accountWithExpectedUsers.get(tempAccountID));
            }
        }

        System.debug('point: usersToBeUsed: '+usersToBeUsed);
        System.debug('point: usersToBeUsedSize: '+usersToBeUsed.size());

        //getching the existing records so that we don't end up creating duplicate records
        map<string,AccountShare> existingRecords = new  map<string,AccountShare>();
        for(AccountShare asRecord : [select id,AccountId,UserOrGroupId from AccountShare where accountID in :accountWithExpectedUsers.keySet() and UserOrGroupId in :usersToBeUsed ]){
            existingRecords.put(asRecord.AccountId+'_'+asRecord.UserOrGroupId, asRecord);
        }

        System.debug('point: accountWithExpectedUsers: '+accountWithExpectedUsers);
        System.debug('point: accountWithExpectedUsersSize: '+accountWithExpectedUsers.size());

        //Create sharing records
        for(Id accountID : accountWithExpectedUsers.keySet()){
            for(ID uId : accountWithExpectedUsers.get(accountID)){
                //do not create share record is its already exists
                if(!existingRecords.containsKey(accountID+'_'+uId) ){
                    AccountShare accountShare  = new AccountShare();
                    accountShare.AccountId = accountId;
                    accountShare.UserOrGroupId = uId;
                    accountShare.AccountAccessLevel = accessLevel;
                    accountShare.CaseAccessLevel = accessLevel;
                    accountShare.OpportunityAccessLevel = accessLevel;
                    accountShare.RowCause = Schema.AccountShare.RowCause.Manual;
                    sharingToInsert.add(accountShare);
                }
            }
        }

        System.debug('point: sharingToInsert: '+sharingToInsert);
        System.debug('point: sharingToInsertSize: '+sharingToInsert.size());

        //insert the share record
        if(!sharingToInsert.isEmpty()){
            insert sharingToInsert;
        }
    }


    @future
    public static void shareAccountRecordWithNewAgentCreated(Map<Id, Id> AccountIdWithagencyAdmin, String accessLevel){

        List<AccountShare> sharingToInsert = new List<AccountShare>();

        Map<Id,User> relatedAgencyAdminList = new Map<ID, User>([SELECT Id, AccountId FROM User WHERE AccountId IN : AccountIdWithagencyAdmin.keySet() 
        AND Id NOT IN : AccountIdWithagencyAdmin.values() AND ProfileName__c in (:Constants.AGENCY_ADMIN_PROFILE,:Constants.AGENCY_ADMIN_PROFILE_LOGIN) AND IsActive = true]);

        List<AccountShare> accountShareList = [SELECT UserOrGroupId, Account.Name, AccountId FROM AccountShare WHERE UserOrGroupId IN : relatedAgencyAdminList.keySet()];

        System.debug('point: accountShareList: '+accountShareList);
        System.debug('point: accountShareListSize: '+accountShareList.size());

        Map<Id,Id> accountIdFromShareWithUserId = new Map<Id,Id>();

        for(AccountShare accShare : accountShareList){

            User relatedUser = relatedAgencyAdminList.get(accShare.UserOrGroupId);
            Id newUserId = AccountIdWithagencyAdmin.get(relatedUser.AccountId);

            accountIdFromShareWithUserId.put(accShare.AccountId, newUserId);
        }
        
        System.debug('point: accountIdFromShareWithUserId: '+accountIdFromShareWithUserId);
        System.debug('point: accountIdFromShareWithUserIdSize: '+accountIdFromShareWithUserId.size());

        for (Id accountId : accountIdFromShareWithUserId.keySet()) {
            if(AccountIdWithagencyAdmin.get(accountId) == null){
                AccountShare accountShare  = new AccountShare();
                accountShare.AccountId = accountId;
                accountShare.UserOrGroupId = accountIdFromShareWithUserId.get(accountId);
                accountShare.AccountAccessLevel = accessLevel;
                accountShare.CaseAccessLevel = accessLevel;
                accountShare.OpportunityAccessLevel = accessLevel;
                accountShare.RowCause = Schema.AccountShare.RowCause.Manual;
                sharingToInsert.add(accountShare);
            }
        }

        System.debug('point: sharing: '+sharingToInsert);
        System.debug('point: sharingSize: '+sharingToInsert.size());

        insert sharingToInsert;
    }

    public static void shareSalesOrderSalesManager(List<SalesOrder__c> newList, String accessLevel){

        List<SalesOrder__Share> sharing = new List<SalesOrder__Share>();
        for (SalesOrder__c soRec: newList) {
            if (soRec.SalesManager__c != null) {
                SalesOrder__Share salesOrderShare  = new SalesOrder__Share();
                salesOrderShare.ParentId = soRec.Id;
                salesOrderShare.UserOrGroupId = soRec.SalesManager__c;
                salesOrderShare.AccessLevel = accessLevel;
                salesOrderShare.RowCause = Schema.SalesOrder__Share.RowCause.Manual;
                sharing.add(salesOrderShare);
            }
        }
        System.debug('point: sharing: ' + sharing);
        Database.insert(sharing, false);
    }

    public static void shareSalesOrderBrokerManager(List<SalesOrder__c> newList, String accessLevel){
        try{
            List<Id> soIds = new List<Id>();
            for (SalesOrder__c so: newList) {
                soIds.add(so.Id);
            }
            List<SalesOrder__c> salesOrderList = [SELECT Id, Name, Opportunity__c, Opportunity__r.BrokerAgencyAccount__c, 
                                                  Opportunity__r.BrokerAgencyAccount__r.OwnerId FROM SalesOrder__c WHERE Id IN : soIds 
                                                  AND Opportunity__c != null AND Opportunity__r.BrokerAgencyAccount__c != null];
            
            List<SalesOrder__Share> sharing = new List<SalesOrder__Share>();
            for (SalesOrder__c soRec: salesOrderList) {
                SalesOrder__Share salesOrderShare  = new SalesOrder__Share();
                salesOrderShare.ParentId = soRec.Id;
                salesOrderShare.UserOrGroupId = soRec.Opportunity__r.BrokerAgencyAccount__r.OwnerId;
                salesOrderShare.AccessLevel = accessLevel;
                salesOrderShare.RowCause = Schema.SalesOrder__Share.RowCause.Manual;
                sharing.add(salesOrderShare);
            }
            System.debug('point: sharing: ' + sharing);
            Database.insert(sharing, false);
        }catch(Exception ex){}
    }
    
    //added to share with FAB Team for Balghailam
    public static void shareSalesOrderFABGroup(List<SalesOrder__c> newList, String accessLevel){
        List<SalesOrder__Share> sharing = new List<SalesOrder__Share>();
        List<Id> soIds = new List<Id>();
        for (SalesOrder__c so: newList) {
            soIds.add(so.Id);
        }
        List<SalesOrder__c> salesOrderList = [SELECT Id, ProjectName__c, Name, Opportunity__c, Opportunity__r.RMVerified__c, 
                                                Opportunity__r.FABPrincipalApproved__c, Opportunity__r.Top_Up_Bank__c FROM SalesOrder__c WHERE Id IN : soIds 
                                                AND Opportunity__c != null AND (Opportunity__r.RMVerified__c = true or Opportunity__r.FABPrincipalApproved__c=true)];

        id FABNHLGroupID = [select id,name from group where type='Regular' and name='FAB Bank Group NHL'].id;
        id FABISLGroupID = [select id,name from group where type='Regular' and name='FAB Bank Group Islamic'].id;
        System.debug('SOrec-->>'+salesOrderList);
        for (SalesOrder__c soRec: salesOrderList) {
            if (soRec.ProjectName__c == String.valueof(System.Label.ADHAProject) && soRec.Opportunity__r.RMVerified__c ==true) {
                SalesOrder__Share salesOrderShare  = new SalesOrder__Share();
                salesOrderShare.ParentId = soRec.Id;
                salesOrderShare.UserOrGroupId = FABNHLGroupID;//'00G25000008vvwp'; //adding for FAB Principal Public Group
                salesOrderShare.AccessLevel = accessLevel;
                salesOrderShare.RowCause = Schema.SalesOrder__Share.RowCause.Manual;
                sharing.add(salesOrderShare);
            }

            if (soRec.ProjectName__c == String.valueof(System.Label.ADHAProject) && soRec.Opportunity__r.FABPrincipalApproved__c ==true && soRec.Opportunity__r.Top_Up_Bank__c =='FAB Islamic') {
                SalesOrder__Share salesOrderShare  = new SalesOrder__Share();
                salesOrderShare.ParentId = soRec.Id;
                salesOrderShare.UserOrGroupId = FABISLGroupID;//'00G25000008vvwp'; //adding for FAB Islamic Public Group
                salesOrderShare.AccessLevel = accessLevel;
                salesOrderShare.RowCause = Schema.SalesOrder__Share.RowCause.Manual;
                sharing.add(salesOrderShare);
            }
        }
        System.debug('point: sharing: ' + sharing);
        if(!sharing.IsEmpty()){
            Database.insert(sharing, false);
        }
        
    }

    public static void shareCommissionLineBrokerManager(List<CommissionLineItem__c> newList, String accessLevel){
        List<Id> clIds = new List<Id>();
        Set<Id> brokerSubManagerIdSet = new Set<Id>();
        for (CommissionLineItem__c cl: newList) {
            clIds.add(cl.Id);
        }
        String commissionLineType = Constants.COMMISSION_LINE_EXTERNAL_COMMISSION;
        List<CommissionLineItem__c> commissionLineList = [SELECT Id, Name, BrokerAgency__c, BrokerAgency__r.OwnerId, BrokerAgency__r.SubAccountManager__c FROM CommissionLineItem__c 
                                                            WHERE Id IN : clIds AND BrokerAgency__c != null AND 
                                                            CommissionType__c =:commissionLineType];
        
        for (CommissionLineItem__c cliRec: commissionLineList) {
            if(cliRec.BrokerAgency__r.SubAccountManager__c != null){
                brokerSubManagerIdSet.add(cliRec.BrokerAgency__r.SubAccountManager__c);
            }
        }
        Map<Id,Boolean> subManagerStatusMap = VFSSharingHelper.isUserActive(brokerSubManagerIdSet);

        List<CommissionLineItem__Share> sharing = new List<CommissionLineItem__Share>();
        for (CommissionLineItem__c cliRec: commissionLineList) {
            CommissionLineItem__Share salesOrderShare  = new CommissionLineItem__Share();
            salesOrderShare.ParentId = cliRec.Id;
            salesOrderShare.UserOrGroupId = cliRec.BrokerAgency__r.OwnerId;
            salesOrderShare.AccessLevel = accessLevel;
            salesOrderShare.RowCause = Schema.CommissionLineItem__Share.RowCause.Manual;
            sharing.add(salesOrderShare);
            
            if(cliRec.BrokerAgency__r.SubAccountManager__c != null && subManagerStatusMap.get(cliRec.BrokerAgency__r.SubAccountManager__c)){
                CommissionLineItem__Share commissionShare  = new CommissionLineItem__Share();
                commissionShare.ParentId = cliRec.Id;
                commissionShare.UserOrGroupId = cliRec.BrokerAgency__r.SubAccountManager__c;
                commissionShare.AccessLevel = accessLevel;
                commissionShare.RowCause = Schema.CommissionLineItem__Share.RowCause.Manual;
                sharing.add(commissionShare);
            }
        }
        System.debug('point: sharing: ' + sharing);
        Database.insert(sharing, false);
    }

    public static void shareDocument(List<Document__c> newList, String accessLevel){
        List<Id> docIds = new List<Id>();
        for (Document__c doc: newList) {
            docIds.add(doc.Id);
        }

        List<Document__c> documentList = [SELECT Id, Name, SalesOrder__c, SalesOrder__r.SalesManager__c, ExpressionofInterest__c, 
                                            ExpressionofInterest__r.Opportunity__c, ExpressionofInterest__r.Opportunity__r.OwnerId 
                                            FROM Document__c WHERE Id IN : docIds];

        List<Document__Share> sharing = new List<Document__Share>();
        for (Document__c docRec: documentList) {
            Document__Share documentShare  = new Document__Share();
            if (docRec.SalesOrder__c != null && docRec.SalesOrder__r.SalesManager__c != null) {
                documentShare.ParentId = docRec.Id;
                documentShare.UserOrGroupId = docRec.SalesOrder__r.SalesManager__c;
                documentShare.AccessLevel = accessLevel;
                documentShare.RowCause = Schema.Document__Share.RowCause.Manual;
                sharing.add(documentShare);
            } else if (docRec.ExpressionofInterest__c != null && docRec.ExpressionofInterest__r.Opportunity__c != null) {
                documentShare.ParentId = docRec.Id;
                documentShare.UserOrGroupId = docRec.ExpressionofInterest__r.Opportunity__r.OwnerId;
                documentShare.AccessLevel = accessLevel;
                documentShare.RowCause = Schema.Document__Share.RowCause.Manual;
                sharing.add(documentShare);
            }
        }
        System.debug('point: sharing: ' + sharing);
        Database.insert(sharing, false);
    }

    public static void shareDocumentWithAccountTeamMember(List<Document__c> newList, String accessLevel){
        List<Id> accIds = new List<Id>();
        List<Document__c> docList = new List<Document__c>();
        for (Document__c doc: newList) {
            if (doc.Account__c != null) {
                accIds.add(doc.Account__c);
                docList.add(doc);
            }
        }

        Map<Id, List<Id>> accountUserIdMap = getAccountTeamMember(accIds);

        List<Document__Share> sharing = new List<Document__Share>();
        for (Document__c docRec: docList) {
            if (accountUserIdMap.containsKey(docRec.Account__c)) {
                List<Id> userList = accountUserIdMap.get(docRec.Account__c);
                for (Id usrId: userList) {
                    Document__Share documentShare  = new Document__Share();
                    documentShare.ParentId = docRec.Id;
                    documentShare.UserOrGroupId = usrId;
                    documentShare.AccessLevel = accessLevel;
                    documentShare.RowCause = Schema.Document__Share.RowCause.Manual;
                    sharing.add(documentShare);
                }
            }
        }
        System.debug('point: sharing: ' + sharing);
        Database.insert(sharing, false);
    }

    public static void shareDocumentWithNewAccountTeamMember(Map<Id, Id> newUserMap, String accessLevel){

        List<Document__c> documentList = [SELECT Id, Account__c FROM Document__c WHERE Account__c IN : newUserMap.keyset()];
        
        List<Document__Share> sharing = new List<Document__Share>();
        for (Document__c docRec: documentList) {
            Document__Share documentShare  = new Document__Share();
            documentShare.ParentId = docRec.Id;
            documentShare.UserOrGroupId = newUserMap.get(docRec.Account__c);
            documentShare.AccessLevel = accessLevel;
            documentShare.RowCause = Schema.Document__Share.RowCause.Manual;
            sharing.add(documentShare);
        }
        System.debug('point: sharing: ' + sharing);
        Database.insert(sharing, false);
    }

    /*public static void shareReceiptAcknowledgement(List<ReceiptAcknowledgement__c> newList, String accessLevel){
        List<Id> receiptIds = new List<Id>();
        for (ReceiptAcknowledgement__c receipt: newList) {
            receiptIds.add(receipt.Id);
        }

        List<ReceiptAcknowledgement__c> receiptList = [SELECT Id, Name, SalesOrder__c, SalesOrder__r.SalesManager__c, OpportunityEOI__c, 
                                                        OpportunityEOI__r.Opportunity__c, OpportunityEOI__r.Opportunity__r.OwnerId 
                                                        FROM ReceiptAcknowledgement__c WHERE Id IN : receiptIds];

        /*List<ReceiptAcknowledgement__Share> sharing = new List<ReceiptAcknowledgement__Share>();
        for (ReceiptAcknowledgement__c receiptRec: receiptList) {
            ReceiptAcknowledgement__Share receiptShare  = new ReceiptAcknowledgement__Share();
            if (receiptRec.SalesOrder__c != null && receiptRec.SalesOrder__r.SalesManager__c != null) {
                receiptShare.ParentId = receiptRec.Id;
                receiptShare.UserOrGroupId = receiptRec.SalesOrder__r.SalesManager__c;
                receiptShare.AccessLevel = accessLevel;
                receiptShare.RowCause = Schema.ReceiptAcknowledgement__Share.RowCause.Manual;
                sharing.add(receiptShare);
            } else if (receiptRec.OpportunityEOI__c != null && receiptRec.OpportunityEOI__r.Opportunity__c != null) {
                receiptShare.ParentId = receiptRec.Id;
                receiptShare.UserOrGroupId = receiptRec.OpportunityEOI__r.Opportunity__r.OwnerId;
                receiptShare.AccessLevel = accessLevel;
                receiptShare.RowCause = Schema.ReceiptAcknowledgement__Share.RowCause.Manual;
                sharing.add(receiptShare);
            }
        }
        System.debug('point: sharing: ' + sharing);
        Database.insert(sharing, false);
    }*/

    /*public static void shareServiceRequestBrokerManager(List<HexaBPM__Service_Request__c> newList, String accessLevel){

        List<Id> serviceRequestIds = new List<Id>();
        for (HexaBPM__Service_Request__c serviceRequest: newList) {
            if (serviceRequest.HexaBPM__Customer__c != null) {
                serviceRequestIds.add(serviceRequest.HexaBPM__Customer__c);
            }
        }
        List<HexaBPM__Service_Request__c> serviceRequestList = [SELECT Id, Name, HexaBPM__Customer__c, HexaBPM__Customer__r.OwnerId 
                                                                    FROM HexaBPM__Service_Request__c WHERE Id IN : serviceRequestIds 
                                                                    AND HexaBPM__Customer__c != null];

        List<HexaBPM__Service_Request__Share> sharing = new List<HexaBPM__Service_Request__Share>();
        for (HexaBPM__Service_Request__c serviceRequestRec: serviceRequestList) {
            HexaBPM__Service_Request__Share serviceRequestShare = new HexaBPM__Service_Request__Share();
            serviceRequestShare.ParentId = serviceRequestRec.Id;
            serviceRequestShare.UserOrGroupId = serviceRequestRec.HexaBPM__Customer__r.OwnerId;
            serviceRequestShare.AccessLevel = accessLevel;
            serviceRequestShare.RowCause = Schema.HexaBPM__Service_Request__Share.RowCause.Manual;
            sharing.add(serviceRequestShare);
        }
        System.debug('point: sharing: ' + sharing);
        Database.insert(sharing, false);
    }*/

    public static Map<Id, List<Id>> getAccountTeamMember(List<Id> accIds) {
        List<AccountTeamMember> accountTeamMemberList = [SELECT Id, AccountId, UserId FROM AccountTeamMember WHERE AccountId IN : accIds];
        Map<Id, List<Id>> accountUserIdMap = new Map<Id, List<Id>>();
        for (AccountTeamMember accTeam: accountTeamMemberList) {
            if (accountUserIdMap.containsKey(accTeam.AccountId)) {
                List<Id> userList = accountUserIdMap.get(accTeam.AccountId);
                userList.add(accTeam.UserId);
                accountUserIdMap.put(accTeam.AccountId, userList);
            } else {
                List<Id> userList = new List<Id>();
                userList.add(accTeam.UserId);
                accountUserIdMap.put(accTeam.AccountId, userList);
            }
        }
        return accountUserIdMap;
    }

    public static void shareServiceRequestBrokerManager(List<HexaBPM__Service_Request__c> newList, String accessLevel){

        List<HexaBPM__Service_Request__Share> sharing = new List<HexaBPM__Service_Request__Share>();
        for (HexaBPM__Service_Request__c srRec: newList) {
            if (srRec.BrokerManager__c != null) {
                HexaBPM__Service_Request__Share serviceRequestShare  = new HexaBPM__Service_Request__Share();
                serviceRequestShare.ParentId = srRec.Id;
                serviceRequestShare.UserOrGroupId = srRec.BrokerManager__c;
                serviceRequestShare.AccessLevel = accessLevel;
                serviceRequestShare.RowCause = Schema.HexaBPM__Service_Request__Share.RowCause.Manual;
                sharing.add(serviceRequestShare);
            }
        }
        System.debug('point: sharing: ' + sharing);
        Database.insert(sharing, false);
    }
    public static void shareServiceRequest(List<HexaBPM__Service_Request__c> newList, String accessLevel){

        List<HexaBPM__Service_Request__Share> sharing = new List<HexaBPM__Service_Request__Share>();
        for (HexaBPM__Service_Request__c srRec: newList) {
                HexaBPM__Service_Request__Share serviceRequestShare  = new HexaBPM__Service_Request__Share();
                serviceRequestShare.ParentId = srRec.Id;
                serviceRequestShare.UserOrGroupId = UserInfo.getUserId();
                serviceRequestShare.AccessLevel = accessLevel;
                serviceRequestShare.RowCause = Schema.HexaBPM__Service_Request__Share.RowCause.Manual;
                sharing.add(serviceRequestShare);
          
        }
        System.debug('point: sharing: ' + sharing);
        Database.insert(sharing, false);
    }
    public static void shareReceipt(Map<Id,Id> receiptAckOwnerShareMap,String accessLevel){
        List<ReceiptAcknowledgement__Share> updateReceiptList = new List<ReceiptAcknowledgement__Share>();
        for(Id receipt: receiptAckOwnerShareMap.keySet()){
        				ReceiptAcknowledgement__Share shareObj  = new ReceiptAcknowledgement__Share();
						shareObj.ParentId = receipt;
                        shareObj.UserOrGroupId = receiptAckOwnerShareMap.get(receipt);
                        shareObj.AccessLevel = accessLevel;
                        shareObj.RowCause = Schema.ReceiptAcknowledgement__Share.RowCause.Manual;
                        updateReceiptList.add(shareObj);
        }
        if(!updateReceiptList.isEmpty())
        Database.SaveResult[] jobShareInsertResult = Database.insert(updateReceiptList,false);
    }
}