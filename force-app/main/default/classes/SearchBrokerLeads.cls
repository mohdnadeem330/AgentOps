public without sharing class SearchBrokerLeads {
   public static Boolean byPassDuplicateLogic = false;
    @AuraEnabled
    public static Opportunity getExistingOpportunity(String LeadNumber){
        List<Lead> ld = UtilitiesWithoutSharing.getleadbyLeadNumber(LeadNumber);
        if(ld.size() >0 ){
            if( ld[0].ExistingAccount__c != null){
            List<Opportunity> Opp = [SELECT Id,Name,BrokerAgencyAccount__c,OwnerId,CreatedDate,Owner.FirstName,Owner.LastName,BrokerAgencyAccount__r.Name FROM Opportunity WHERE AccountId =:ld[0].ExistingAccount__c AND IsClosed= false ORDER BY CreatedDate DESC  LIMIT 1];
            if(Opp.size() > 0){
                return Opp[0];
            }
            }
            return null;
        }else{
            return null;
        }
    }
    @AuraEnabled
    public static List<Lead> getLeadDetails(String LeadNumber){
        User us = [SELECT Id,Name,Profile.Name,RoleName__c,ProfileName__c,ByPassBrokerLeadSearch__c FROM User WHERE Id =:UserInfo.getUserId() LIMIT 1];
        String errorString = UtilitiesWithoutSharing.checkPrivileges(us);
        if(errorString == ''){
        return UtilitiesWithoutSharing.getleadbyLeadNumber(LeadNumber);
        }else{
            return new List<Lead>();
        }
        
       
    }
    // SSC-697, Duplicate Account check based on Email or Mobile Number: Bashim
    // In the below method we have added one more parameter mobile number to get duplicate account based on mobile number
    @AuraEnabled
    public static List<UtilitiesWithoutSharing.DuplicateAccountWrapper> checkduplicateEmail(String emailId, String mobileNumber){
        String emailfield = emailId.toLowerCase();
        List<UtilitiesWithoutSharing.DuplicateAccountWrapper> AccountMapEmailAndMobileNumber = UseExistingAccount.findDuplicateAccountsByEmailAndMobileNumber(new Set<String> {emailfield},new Set<String>{mobileNumber});
        return AccountMapEmailAndMobileNumber;
         
    }
    @AuraEnabled
    public static String SearchBrokerLeadFlow(String LeadNumber){
        byPassDuplicateLogic = true;
        try{
            UtilitiesWithoutSharing.getConvertedOppBySearchLead(LeadNumber,'');
            return '';
        } catch(Exceptions.IncorrectFilterException ex){return 'Lead number provided is not the correct one';}
        catch(Exceptions.InsufficientAccessException exAccess)
        {return 'Insufficient Privileges to search for Lead.';}
        catch(Exceptions.BrokerSuspensionException exAccess)
        {return 'Lead is not allowed for Suspended Broker.';}
        catch(Exceptions.VIPBrokerLeadException exVIP){return 'This lead matches an existing VIP Lead in the system. This cannot be converted.Please reach out to your manager';
        }catch(Exceptions.AlreadyConvertedException ex){return 'This Lead Number '+LeadNumber +' Is Already Converted.';}
        catch(Exception e){return e.getMessage();}
      
    }
    

    @AuraEnabled
    public static String sentforApproval(String LeadId,String OtherReason, String ExReason){
        Id profileId=userinfo.getProfileId();
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
        if(ExReason =='VIP Reason Lead'){
            Lead ld = new Lead();
            ld.VipApprovalReason__c = OtherReason;
            ld.Id = LeadId;
            update ld;
            
            if(profileName == 'Sales Manager' || Test.isRunningTest()){
                User us =[SELECT ID,ManagerId FROM User WHERE Id=:UserInfo.getUserId()];
                LeadShare  shareLead = new LeadShare();
                shareLead.LeadId = LeadId;
                shareLead.UserOrGroupId = us.ManagerId;
                shareLead.LeadAccessLevel = 'edit';
                shareLead.RowCause = Schema.LeadShare.RowCause.Manual;
                insert shareLead;
            }

            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments('Submitting request for approval.');
            req1.setObjectId(LeadId);
            
            req1.setSubmitterId(UserInfo.getUserId()); 
            
            req1.setProcessDefinitionNameOrId('VIP_Approval');
            req1.setSkipEntryCriteria(true);
            
            // Submit the approval request for the account
            Approval.ProcessResult result = Approval.process(req1);
            Approval.UnlockResult unlockResultList = Approval.unlock(ld, false);
            if(result.isSuccess()){
                return 'SUCCESS';
            }else{
                return 'APPROVALS_ERROR';
            }
        }else if(ExReason =='Broker Reason Lead'){
            Lead ld = new Lead();
            ld.EmailApprovalsOtherReason__c = OtherReason;
            ld.Id = LeadId;
            update ld;
            if(profileName == 'Sales Manager' || Test.isRunningTest()){
                User us =[SELECT ID,ManagerId FROM User WHERE Id=:UserInfo.getUserId()];
                LeadShare  shareLead = new LeadShare();
                shareLead.LeadId = LeadId;
                shareLead.UserOrGroupId = us.ManagerId;
                shareLead.LeadAccessLevel = 'edit';
                shareLead.RowCause = Schema.LeadShare.RowCause.Manual;
                insert shareLead;
            }
            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments('Submitting request for approval.');
            req1.setObjectId(LeadId);
            
            req1.setSubmitterId(UserInfo.getUserId()); 
            
            req1.setProcessDefinitionNameOrId('Lead_Approval1');
            req1.setSkipEntryCriteria(true);
            
            // Submit the approval request for the account
            Approval.ProcessResult result = Approval.process(req1);
            Approval.UnlockResult unlockResultList = Approval.unlock(ld, false);
            if(result.isSuccess()){
                return 'SUCCESS';
            }else{
                return 'APPROVALS_ERROR';
            }
        }else{
        Lead ld= new Lead();
        ld.Id = LeadId;
        ld.EmailApprovalsReason__c = ExReason;
        ld.EmailApprovalsOtherReason__c = OtherReason;
        update ld;
       
        if(profileName == 'Sales Manager' || Test.isRunningTest()){
            User us =[SELECT ID,ManagerId FROM User WHERE Id=:UserInfo.getUserId()];
            LeadShare  shareLead = new LeadShare();
            shareLead.LeadId = LeadId;
            shareLead.UserOrGroupId = us.ManagerId;
            shareLead.LeadAccessLevel = 'edit';
            shareLead.RowCause = Schema.LeadShare.RowCause.Manual;
            insert shareLead;
        }
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(LeadId);
        
        req1.setSubmitterId(UserInfo.getUserId()); 
        
        req1.setProcessDefinitionNameOrId('Email_Exceptional_Approvals_Lead2');
        req1.setSkipEntryCriteria(true);
        
        // Submit the approval request for the account
        Approval.ProcessResult result = Approval.process(req1);
        Approval.UnlockResult unlockResultList = Approval.unlock(ld, false);
            if(result.isSuccess()){
                return 'SUCCESS';
            }else{
                return 'APPROVALS_ERROR';
            }
        }
    }
    @AuraEnabled
    public static String addacocuntTeamMember(String recordId,String LeadId,String LeadNumber){
        try{
        UtilitiesWithoutSharing.getConvertedOppBySearchLead(LeadNumber,recordId);
        return '';
        }catch(Exceptions.IncorrectFilterException ex){return 'Lead number provided is not the correct one';}
        catch(Exceptions.InsufficientAccessException exAccess){return 'Insufficient Privileges to search for Lead.';}
        catch(Exceptions.VIPBrokerLeadException exVIP){return 'This lead matches an existing VIP Lead in the system. This cannot be converted.Please reach out to your manager';
        }catch(Exceptions.AlreadyConvertedException ex){return 'This Lead Number '+LeadNumber +' Is Already Converted.';}
        catch(Exception e){return e.getMessage();}
      
        
    }
    
}