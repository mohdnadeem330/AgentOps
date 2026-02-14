public with sharing class North_baniyasRequest {
    
    @auraEnabled
    public static String getAllDlpCases(Integer pageSize, Integer pageNumber, String filterCondition,String caseRetriveType,string searchValue, String sortBy){
        System.debug('pageSize--'+pageSize+'pageNumber--'+pageNumber+'filterCondition--'+filterCondition);
        System.debug('Entering getAllCases method');
        System.debug('@@@searchValue'+searchValue);
        String jsonData = '';
        Integer offset = (pageNumber - 1) * pageSize;
        String userId = UserInfo.getUserId();
        // String countQuery = 'SELECT COUNT() FROM Case Where CreatedById=:userId';
        String countQuery='';
        if(caseRetriveType == 'NewCase')
        {
            countQuery = 'SELECT COUNT() FROM Case WHERE Assigned_To__c = null and Recordtype_Name__c IN (\'Requests\', \'Complaints\') and Status IN (\'New\')';
        }else if(caseRetriveType == 'Mycases'){
            //String userId = UserInfo.getUserId();
            countQuery = 'SELECT COUNT() FROM Case WHERE Assigned_To__c=:userId and Recordtype_Name__c IN (\'Requests\', \'Complaints\') and Status IN (\'New\',\'Work In Progress\',\'Escalated\',\'Re Opened\')';           
        }
        else if(caseRetriveType == 'AllAcceptedCase'){
            countQuery = 'SELECT COUNT() FROM Case WHERE Assigned_To__c !=null and Recordtype_Name__c IN (\'Requests\', \'Complaints\') and Status IN (\'New\',\'Work In Progress\',\'Escalated\',\'Re Opened\')';
        }else if(caseRetriveType == 'FilterCase'){
            String likeSearchValue = '%'+searchValue+'%';             
            countQuery = 'SELECT COUNT() FROM Case WHERE (CaseNumber LIKE :likeSearchValue OR Unit_Name__c LIKE :likeSearchValue OR CaseCategory__c LIKE :likeSearchValue OR SubCategory__c LIKE :likeSearchValue OR Status LIKE :likeSearchValue OR Assigned_To__r.Name LIKE :likeSearchValue OR Priority LIKE :likeSearchValue OR Appointment_Status__c LIKE :likeSearchValue )';
        }else if(caseRetriveType == 'dlpEmergencyCase'){            
            countQuery = 'SELECT COUNT() FROM Case WHERE Priority IN (\'Emergency\') and Recordtype_Name__c IN (\'Requests\', \'Complaints\') and Status IN (\'New\',\'Work In Progress\',\'Escalated\',\'Re Opened\')';           
        }else if(caseRetriveType == 'dlpAllCase'){            
            countQuery = 'SELECT COUNT() FROM Case WHERE Recordtype_Name__c IN (\'Requests\', \'Complaints\')';
        }
        
        if (String.isNotBlank(filterCondition)) {
            //countQuery += filterCondition;
        }
        system.debug('countQuery--'+countQuery);
        Integer totalRecords = database.countQuery(countQuery);
        system.debug('totalRecords'+totalRecords);
        Integer recordEnd = pageSize * pageNumber;        
        WrapperClass objcls =  new WrapperClass();  
        objcls.pageSize = pageSize;
        objcls.pageNumber = pageNumber;
        objcls.recordStart = offset + 1;
        objcls.recordEnd = totalRecords >= recordEnd ? recordEnd : totalRecords;
        objcls.totalRecords = totalRecords;
        String mainQuery='';
        if(caseRetriveType == 'NewCase')
        {
            mainQuery = 'SELECT Id,Status,Origin,CaseComments__c,Appointment_Status__c,Recordtype_Name__c,CaseNumber,OwnerId,ContactId,AccountId,Priority,CaseCategory__c,SubCategory__c,Subject,Description,FORMAT(CreatedDate),FORMAT(LastModifiedDate),Unit__r.Name,Assigned_To__r.Name,Unit_Name__c ' + 
                'FROM Case ' + 
                'WHERE Assigned_To__c =null and Recordtype_Name__c IN (\'Requests\', \'Complaints\') and Status IN (\'New\')';
        }
        else if(caseRetriveType == 'Mycases')
        {
            mainQuery = 'SELECT Id,Status,Origin,CaseComments__c,Appointment_Status__c,Recordtype_Name__c,CaseNumber,OwnerId,ContactId,AccountId,Priority,CaseCategory__c,SubCategory__c,Subject,Description,FORMAT(CreatedDate),FORMAT(LastModifiedDate),Unit__r.Name,Assigned_To__r.Name,Unit_Name__c ' + 
                'FROM Case ' + 
                'WHERE Assigned_To__c=:userId and Recordtype_Name__c IN (\'Requests\', \'Complaints\') and Status IN (\'New\',\'Work In Progress\',\'Escalated\',\'Re Opened\')';
        }
        else if(caseRetriveType == 'AllAcceptedCase'){
            
            mainQuery = 'SELECT Id,Status,Origin,Appointment_Status__c,CaseComments__c,Recordtype_Name__c,CaseNumber,OwnerId,ContactId,AccountId,Priority,CaseCategory__c,SubCategory__c,Subject,Description,FORMAT(CreatedDate),FORMAT(LastModifiedDate),Unit__r.Name,Assigned_To__r.Name,Unit_Name__c ' + 
                'FROM Case ' + 
                'WHERE Assigned_To__c != null and Recordtype_Name__c IN (\'Requests\', \'Complaints\') and Status IN (\'New\',\'Work In Progress\',\'Escalated\',\'Re Opened\')';
            
        }else if(caseRetriveType == 'dlpEmergencyCase'){
            
            mainQuery = 'SELECT Id,Status,Origin,Appointment_Status__c,CaseComments__c,Recordtype_Name__c,CaseNumber,OwnerId,ContactId,AccountId,Priority,CaseCategory__c,SubCategory__c,Subject,Description,FORMAT(CreatedDate),FORMAT(LastModifiedDate),Unit__r.Name,Assigned_To__r.Name,Unit_Name__c ' + 
                'FROM Case ' + 
                'WHERE Priority In (\'Emergency\') and Recordtype_Name__c IN (\'Requests\', \'Complaints\') and Status IN (\'New\',\'Work In Progress\',\'Escalated\',\'Re Opened\')';
            
        }else if(caseRetriveType == 'dlpAllCase'){
            
            mainQuery = 'SELECT Id,Status,Origin,Appointment_Status__c,CaseComments__c,Recordtype_Name__c,CaseNumber,OwnerId,ContactId,AccountId,Priority,CaseCategory__c,SubCategory__c,Subject,Description,FORMAT(CreatedDate),FORMAT(LastModifiedDate),Unit__r.Name,Assigned_To__r.Name,Unit_Name__c ' + 
                'FROM Case ' + 
                'WHERE Recordtype_Name__c IN (\'Requests\', \'Complaints\')';
            
        }
        else if(caseRetriveType == 'FilterCase'){
            String likeSearchValue = '%'+searchValue+'%';
            mainQuery = 'SELECT Id,Status,Origin,Appointment_Status__c,CaseComments__c,Recordtype_Name__c,CaseNumber,OwnerId,ContactId,AccountId,Priority,CaseCategory__c,SubCategory__c,Subject,Description,FORMAT(CreatedDate),FORMAT(LastModifiedDate),Unit__r.Name,Assigned_To__r.Name,Unit_Name__c ' + 
                'FROM Case ' + 
                'WHERE (CaseNumber LIKE :likeSearchValue OR Unit_Name__c LIKE :likeSearchValue OR CaseCategory__c LIKE :likeSearchValue OR SubCategory__c LIKE :likeSearchValue OR Status LIKE :likeSearchValue OR Assigned_To__r.Name LIKE :likeSearchValue OR Priority LIKE :likeSearchValue OR Appointment_Status__c LIKE :likeSearchValue)';
        }
        
        // Start by Daksh Sharma for Sort By feature 
        String sortField = 'LastModifiedDate';
        String sortOrder = 'DESC';
        
        if(String.isNotBlank(sortBy)) {
            List<String> parts = sortBy.split('/');
            if(parts.size() == 2){
                sortField = parts[0];
                sortOrder = parts[1];
            }
        }
        
        mainQuery += ' ORDER BY ' + sortField + ' ' + sortOrder + ' LIMIT :pageSize OFFSET :offset';  
        // End by Daksh Sharma for Sort By feature      
        
        System.debug('Main Query: ' + mainQuery);
        objcls.cs = database.query(mainQuery);
        jsonData = JSON.serialize(objcls);
        system.debug('jsonData-->'+jsonData);
        return jsonData;
    }
    
    public class WrapperClass{
        @AuraEnabled public Integer pageSize {get;set;}
        @AuraEnabled public Integer pageNumber {get;set;}
        @AuraEnabled public Integer totalRecords {get;set;}
        @AuraEnabled public Integer recordStart {get;set;}
        @AuraEnabled public Integer recordEnd {get;set;}
        @AuraEnabled public List<Case> cs {get;set;}
        @AuraEnabled public List<Payment_Request__c> paymentReq {get;set;}
    } 
    
    @auraEnabled
    public static Case getDLpCaseInfo(string caseId){
        system.debug('caseId@@'+caseId);
        return [SELECT Id, Status,Origin,CaseComments__c,Recordtype_Name__c,CaseNumber,OwnerId,ContactId,Contact.Name, Account.Name,Assigned_To__r.Name, Appointment_Status__c,
                AccountId,Priority,CaseCategory__c,SubCategory__c,RecordTypeId,Subject,Unit_Name__c,Description,Owner.Name,Appointment_Date__c, SuppliedEmail, SuppliedName, SuppliedPhone from Case WHERE Id=:caseId];
    }
    
    @auraEnabled
    public static void updatedlpCase(String CaseId,String Status,String Comment,Datetime AppointmentDate,String PostComment, String AppointmentStatus, String CaseCategory, String SubCategory ){
        try{
            if(String.isNotBlank(PostComment)){
                CaseComment newComment = new CaseComment();
                newComment.ParentId = CaseId;
                newComment.CommentBody = PostComment;
                newComment.IsPublished = true;
                insert newComment;   
            } 
            Case updateCase =new Case();
                updateCase.Id=CaseId;
                updateCase.Status =Status;
                updateCase.CaseComments__c = Comment;
                updateCase.Appointment_Date__c = AppointmentDate;
                updateCase.Appointment_Status__c = AppointmentStatus;
                updateCase.CaseCategory__c = CaseCategory;
                updateCase.SubCategory__c = SubCategory;
                Update updateCase; 
        } catch (DmlException e) {	
            throw new AuraHandledException(e.getMessage());
        }            
    } 
    
    @auraEnabled
    public static void updateAssignTo(String CaseId, String assignedUserId){
        try{
            Id assignTo = String.isNotBlank(assignedUserId) ? assignedUserId : UserInfo.getUserId();
            Case updateCase =new Case();
            updateCase.Id=CaseId;
            updateCase.Assigned_To__c = assignTo;          
            Update updateCase;
        } catch (DmlException e) {	
            throw new AuraHandledException(e.getMessage());
        }           
    }  
    
    @auraEnabled
    public static User getUserName(String UserId){
        try{
            
            return [SELECT Id,Name from User WHERE Id=:UserId];
            
        } catch (DmlException e) {	
            throw new AuraHandledException(e.getMessage());
        }           
    }  
    
    @AuraEnabled
    public static List<CaseComment> getCaseCommentsAndPosts(Id caseId) {
        return [
            SELECT Id, CommentBody, CreatedBy.Name, CreatedDate
            FROM CaseComment
            WHERE ParentId = :caseId
            AND CommentBody != null
            ORDER BY CreatedDate DESC
        ];
    }
    
    @InvocableMethod(label='Notify North baniyas Queue Members' description='Send case number to queue members')
    public static void notifyNorthBaniyasQueue(List<Id> caseIds) {
        if (caseIds == null || caseIds.isEmpty()) return;
        
        System.debug('@@@CaseIds'+caseIds);
        // Query the Case
        List<Case> newCaselist = [SELECT Id, CaseNumber,CaseComments__c,SubCategory__c,CaseCategory__c,Unit__r.Name,Owner.Name,CreatedDate FROM Case WHERE Id = :caseIds[0] LIMIT 1];
        System.debug('@@@c'+newCaselist);    
        List<GroupMember> listGroupMember =   [Select Id,GroupId,UserOrGroup.Name,UserOrGroup.Email,UserOrGroupId,UserOrGroup.UserType,Group.DeveloperName,UserOrGroup.IsActive From GroupMember where Group.DeveloperName ='North_Baniyas_Queue' and UserOrGroup.Email !=null and UserOrGroup.IsActive = true and UserOrGroup.UserType In ('PowerPartner')];
        System.debug('@@@listGroupMember'+listGroupMember);
        String emailSubject ='';
        string emailBody ='';
        if(!newCaselist.isempty()){
            if(newCaselist[0].Unit__r.Name !=null){
                emailSubject = 'New Case Created - '+newCaselist[0].CaseNumber+' - '+newCaselist[0].Unit__r.Name+' - '+newCaselist[0].SubCategory__c+'';       	                     
                emailBody = 'Hello team,<br> ' +
                    'A new case has been assigned to the North baniyas queue with below details.<br><br>' +
                    '<b>Case Number : </b> ' + newCaselist[0].CaseNumber + '<br>' +
                    '<b>Case owner : </b> North baniyas queue<br>' +
                    '<b>Case category : </b> ' + newCaselist[0].CaseCategory__c + '<br>' +
                    '<b>Unit : </b> ' + newCaselist[0].Unit__r.Name + '<br>' +
                    '<b>Created Date :</b> ' + newCaselist[0].CreatedDate + '<br>' +
                    '<b>Case Comment :</b> ' + newCaselist[0].CaseComments__c+'<br><br><br><br>' +
                    '<b>Regards,</b><br>' +
                    '<b>Aldar Customer Care';  
            }  else{
                emailSubject = 'New Case Created - '+newCaselist[0].CaseNumber+'-'+newCaselist[0].SubCategory__c+''; 
                emailBody = 'Hello team,<br> ' +
                    'A new case has been assigned to the North baniyas queue with below details.<br><br>' +
                    '<b>Case Number : </b> ' + newCaselist[0].CaseNumber + '<br>' +
                    '<b>Case owner : </b> North baniyas queue<br>' +
                    '<b>Case category : </b> ' + newCaselist[0].CaseCategory__c + '<br>' +							
                    '<b>Created Date :</b> ' + newCaselist[0].CreatedDate + '<br>' +
                    '<b>Case Comment :</b> ' + newCaselist[0].CaseComments__c+'<br><br><br><br>' +
                    '<b>Regards,</b><br>' +
                    '<b>Aldar Customer Care';  
                
            }
            
        }
  
        List<string> userEmail = new List<string>();
        for(GroupMember gm :listGroupMember){
            if(gm.UserOrGroup.Email !=null)
            {
                userEmail.add(gm.UserOrGroup.Email);
            }
        }
        System.debug('@@@userEmail'+userEmail);
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        if(!userEmail.isempty() && !newCaselist.isempty())
        {
            System.debug('@@@userEmail'+emailSubject);
            System.debug('@@@userEmail'+emailBody);
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String orgWideEmailAddress = Utilities.getOrgWideEmailAddressIdByName(Constants.ALDAR_PROPERTIES_ORGWIDEEMAIL_CUSTOMER_CARE);                        
            mail.setOrgWideEmailAddressId(orgWideEmailAddress);
            mail.setToAddresses(userEmail);
            mail.setSubject(emailSubject);
            mail.setHtmlBody(emailBody);
            emails.add(mail);
        }
        
        if (!emails.isEmpty()) {
            System.debug('@@@emails'+emails);
            list<Messaging.SendEmailResult> emailResult  = Messaging.sendEmail(emails);
            //Messaging.sendEmail(emails, false);
        }
    }
    
    public class CaseWithComment {
        @AuraEnabled public Case caseRecord;
        @AuraEnabled public String lastComment;

        public CaseWithComment(Case c, String comment) {
            this.caseRecord = c;
            this.lastComment = comment;
        }
    }


    @AuraEnabled
    public static List<CaseWithComment> getFilteredCasesForExport(String status, String priority, String category, String subCategory, Date fromDate, Date toDate) {
			String query = 'Select Id, CaseNumber, Subject, Origin, OwnerId, Owner.Name, Assigned_To__r.Name, Account.Name, Contact.Name, CustomerType__c, SuppliedEmail, SuppliedName, SuppliedPhone, Recordtype_Name__c, Priority, CaseCategory__c, '+
							'CaseComments__c, SubCategory__c, Unit_Name__c, Status, Appointment_Date__c, CreatedBy.Name, CreatedDate, LastModifiedBy.Name, LastModifiedDate, ClosedDate FROM Case WHERE Recordtype_Name__c IN (\'Requests\', \'Complaints\')' ;
						
        if (String.isNotBlank(status)) {
            query += ' AND Status = :status';
        }
        if (String.isNotBlank(priority)) {
            query += ' AND Priority = :priority';
        }
        if (String.isNotBlank(category)) {
            query += ' AND CaseCategory__c = :category';
        }
        if (String.isNotBlank(subCategory)) {
            query += ' AND SubCategory__c = :subCategory';
        }
        if (fromDate != null){
            query += ' AND CreatedDate >=: fromDate';
        }
        if (toDate != null){
            query += ' AND CreatedDate <=: toDate';
        }
        List<Case> cases = Database.query(query);
        Map<Id, String> caseIdToLatestComment = new Map<Id, String>();
        if (!cases.isEmpty()) {
            List<CaseComment> comments = [
                SELECT Id, CommentBody, ParentId 
                FROM CaseComment 
                WHERE ParentId IN :cases 
                ORDER BY CreatedDate DESC
            ];

            for (CaseComment comment : comments) {
                if (!caseIdToLatestComment.containsKey(comment.ParentId)) {
                    caseIdToLatestComment.put(comment.ParentId, comment.CommentBody);
                }
            }
        }

        List<CaseWithComment> results = new List<CaseWithComment>();
        for (Case c : cases) {
            String lastComment = caseIdToLatestComment.get(c.Id);
            results.add(new CaseWithComment(c, lastComment));
        }
        return results;
    }

    @AuraEnabled
    public static List<User> getQueueMembersByOwner(String caseId) {
        system.debug('CaseId-->'+'caseId');
        Id ownerId = [SELECT OwnerId FROM Case WHERE Id = :caseId LIMIT 1].OwnerId;

        List<GroupMember> groupMembers = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :ownerId];

        Set<Id> userIds = new Set<Id>();
        for (GroupMember gm : groupMembers) {
            userIds.add(gm.UserOrGroupId);
        }
        
        return [SELECT Id, Name FROM User WHERE Id IN :userIds AND IsPartner = true];
    }
}