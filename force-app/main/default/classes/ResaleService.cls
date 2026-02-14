public without sharing class ResaleService {

    public static List<String> resaleQueues = new List<String>{'RR_Queue'};
    public static Map<String, Group> QueueDNameToGroupMap;
    public static Group ResaleRRQueue = QueueDNameToGroupMap == null 
                                        ? getQueueInformationsByName(resaleQueues).get('RR_Queue') 
                                        : QueueDNameToGroupMap.containsKey('RR_Queue') 
                                            ? QueueDNameToGroupMap.get('RR_Queue') 
                                            : getQueueInformationsByName(resaleQueues).get('RR_Queue');
        
    //*** validate and update record fields before insert or update, isUpdate is flag for Trigger.isupdate***//
    public static void beforeActionsOnResaleCase(List<SObject> newCaseList, Map<Id, SObject> oldCaseMap, Boolean isUpdate) {
        List<Case> resaleCases = new List<Case>();

        Map<Id, Id> thisCaseIdToUnitIdMap = new Map<Id, Id>();
        Map<Id, String> newUnitIdsToValidationErrorMap = new Map<Id, String>();
        
        Map<Id, Account> accIdsMap = new Map<Id, Account>();
        Map<Id, Id> customerIdToRmIdMap = new Map<Id, Id>();
        
        Map<Id, Boolean> casesToHasValidSignedDocsMap = new Map<Id, Boolean>();
        
        User loggedInUser = Utilities.getLoggedInUserDetail();
        String profileName = loggedInUser.Profile.Name;
        
        Date dateToday = System.today();
        // loop over cases to update default field values based on Status and User, collect ids for bulkified actions
        for (Case newCase: (List<Case>)newCaseList) {
            // process pass only resale type cases
            if (newCase.RecordTypeId == ResaleConstants.Resale_Case_RecordTypeId) {
                Case oldCase = (Case)oldCaseMap.get(newCase.Id);
                
                Boolean goForDirectAssignment = false;
                    
                // current user based actions on record insert
                if(!isUpdate){
                    // if 'New' status case's created by user is Resale Relationship Manager or Contact Centre Agent, set status to 'In Progress'
                    Boolean setStatusToInProgress = false;
                    if(profileName == ResaleConstants.RESALE_RELATIONSHIP_MANAGER_PROFILE){
                        // if created by Resale Relationship Manager, So will not got to round robin
                        newCase.Eligible_for_Round_Robin__c = false;
                        newCase.Is_Directly_Assigned__c = true;
                        newCase.CustomerContacted__c = true;
                        setStatusToInProgress = true;
                    }else if(profileName == ResaleConstants.CONTACT_CENTER_AGENT){
                        setStatusToInProgress = true;
                    }else if(profileName == ResaleConstants.SALES_MANAGER){
                        // set Sales_Manager__c if the case was created by 
                        newCase.ReferredBy__c = UserInfo.getUserId();
                        // should go for round robin if no RM is available for direct assignment 
                        goForDirectAssignment = true;
                    }else if(newCase.Origin == ResaleConstants.CASE_ORIGIN_ONLINE){
                        // for later: assign to cca queue
                        goForDirectAssignment = true;
                    }else if(newCase.Origin == ResaleConstants.CASE_ORIGIN_CUSTOMER_PORTAL){
                        if(!newCase.EligibleforResaleApproval__c && newCase.SalesOrder__c != null){
                            newCase.Status = ResaleConstants.CASE_AGREEMENT_SIGNATURE_IN_PROCESS;
                        }
                        goForDirectAssignment = true;
                    }else{
                        goForDirectAssignment = true;
                    }

                    if(setStatusToInProgress && newCase.Status.equalsIgnoreCase(ResaleConstants.CASE_NEW)){
                        newCase.Status = ResaleConstants.CASE_IN_PROGRESS;
                    }
                }
                
                // unit change based actions on record insert or update
                if (newCase.Unit__c != null && (oldCase == null || oldCase.Unit__c != newCase.Unit__c)) {
                    if(newUnitIdsToValidationErrorMap.containsKey(newCase.Unit__c)){
                        newUnitIdsToValidationErrorMap.put(newCase.Unit__c, ResaleConstants.RESALE_CASES_MANY_PER_UNIT_VALIDATION); // 'Cannot raise multiple listing requests for the same unit.'
                    }else{
                        newUnitIdsToValidationErrorMap.put(newCase.Unit__c, null);
                    }
                    if(isUpdate){
                        thisCaseIdToUnitIdMap.put(newCase.Id, newCase.Unit__c);
                    }
                }

                // status based actions on record insert or update
                if(oldCase == null || oldCase.Status != newCase.Status){
                    if(newCase.Status.equalsIgnoreCase(ResaleConstants.CASE_QUALIFIED)){
                        if(profileName == ResaleConstants.CONTACT_CENTER_AGENT){
                            goForDirectAssignment = true;
                        }
                    }else if(newCase.Status.equalsIgnoreCase(ResaleConstants.STATUS_IN_PROGRESS) &&
                        newCase.Customer_Interest__c!= null &&  oldCase!=null  && oldCase.Customer_Interest__c != null && newCase.Customer_Interest__c != oldCase.Customer_Interest__c // Added by Noor
                            && newCase.Customer_Interest__c == 'Interested'){
                                goForDirectAssignment = true; 
                    }else if(newCase.Status.equalsIgnoreCase(ResaleConstants.CASE_DISCUSSION_IN_PROGRESS)){
                        newCase.Eligible_for_Round_Robin__c = false;
                    }else if(newCase.Status.equalsIgnoreCase(ResaleConstants.CASE_AWAITING_LINE_MANAGER_APPROVAL)){
                        List<String> errorInFields = new List<String>();
                        if(newCase.Unit__c == null)
                            errorInFields.add('Unit');
                        if(newCase.Listing_Expiry__c == null)
                            errorInFields.add('Listing Expiry');
                        if(newCase.Listing_Price__c == null)
                            errorInFields.add('Listing Price');
                        if(newCase.ResaleListingExclusiveness__c == null)
                            errorInFields.add('Exclusiveness');
                        if(!errorInFields.isEmpty())
                            newCase.addError('Please populate: '+String.join(errorInFields, ', '));
                    }else if(newCase.Status.equalsIgnoreCase(ResaleConstants.CASE_PROPERTY_LISTED)){
                        casesToHasValidSignedDocsMap.put(newCase.Id, false);
                    }
                    
                    if(profileName == ResaleConstants.RESALE_RELATIONSHIP_MANAGER_PROFILE && newCase.Eligible_for_Round_Robin__c){
                        newCase.Eligible_for_Round_Robin__c = false;
                    }
                }

                // cases to check for existing RM dealing with the same customer
                if(goForDirectAssignment){
                    if(ResaleRRQueue != null){
                        newCase.OwnerId = ResaleRRQueue.Id;
                    }
                    if(newCase.AccountId != null){
                        customerIdToRmIdMap.put(newCase.AccountId, null);
                    }
                }
                // default field values for cases assigned to RR Quere
                if(newCase.OwnerId == ResaleRRQueue.Id){
                    newCase.Eligible_for_Round_Robin__c = true;
                    newCase.Is_Directly_Assigned__c = false;
                    newCase.QA_Assigned__c = false;
                    newCase.CustomerContacted__c = false;
                }
                

                if(oldCase == null || newCase.AccountId != oldCase.AccountId){
                    accIdsMap.put(newCase.AccountId, null);
                }
                resaleCases.add(newCase);
            }
        }
    
        // bulkified actions start here
        // includes: updating field values based on related records, complex validations, 
        if(!newUnitIdsToValidationErrorMap.isEmpty() || !casesToHasValidSignedDocsMap.isEmpty()){
            // update Account and Sales Order to be same as selected Unit's Primary Account and Sales Order 
            Map<String, SalesOrder__c> unitSalesOrderMap = new Map<String, SalesOrder__c>();

            // get required information before looping over cases
            if(!newUnitIdsToValidationErrorMap.isEmpty()){
                // validate if there's another resale case open for the unit selected
                validateNewUnitIds(thisCaseIdToUnitIdMap, newUnitIdsToValidationErrorMap);
                // collect related sales order for selected unit
                for (SalesOrder__c salesOrder: getSalesOrdersByUnitIds( new List<Id>( newUnitIdsToValidationErrorMap.keySet() ) )) {
                    unitSalesOrderMap.put(salesOrder.Unit__c, salesOrder);
                }
            }
            if(!casesToHasValidSignedDocsMap.isEmpty()){
                // check if a signed doc is attached to the case
                validateSignedDocumentForCases(ResaleConstants.CASE_SIGNED_LISTING_AGREEMENT_DOCUMENT_TYPE, casesToHasValidSignedDocsMap);
            }

            for(Case newCase: (List<Case>)resaleCases) {
                if(newUnitIdsToValidationErrorMap.containsKey(newCase.Unit__c)){
                    if(newUnitIdsToValidationErrorMap.get(newCase.Unit__c) != null){
                        newCase.addError(newUnitIdsToValidationErrorMap.get(newCase.Unit__c));//OPEN_RESALE_CASE_PER_UNIT_VALIDATION);
                    }else{
                        if (unitSalesOrderMap.containsKey(newCase.Unit__c)) {
                            SalesOrder__c salesOrder = unitSalesOrderMap.get(newCase.Unit__c);
                            if( newCase.AccountId != null && newCase.AccountId != salesOrder.Account__c ){
                                newCase.addError( ResaleConstants.RESALE_CASE_UNIT_NOT_OWNED_VALIDATION ); // 'Selected Unit doesn\'t belong to the customer who initiated the listing.'
                            }else{
                                if(newCase.AccountId == null){
                                    newCase.AccountId = salesOrder.Account__c;
                                    customerIdToRmIdMap.put(newCase.AccountId, null);
                                    accIdsMap.put(newCase.AccountId, null);
                                }
                                newCase.SalesOrder__c = salesOrder.Id;
                                // as the sales order is being pupulated now, then calculate manually if the case is eligible for approval or not.
                                /*if(newCase.Origin == ResaleConstants.CASE_ORIGIN_CUSTOMER_PORTAL && !System.Label.ListingPriceApprovalDifference.trim().equalsIgnoreCase('OFF')){
                                    Decimal ineligibleDiff = Decimal.valueOf(System.Label.ListingPriceApprovalDifference.trim());
                                    Decimal percentageDiff = 100 - (newCase.Listing_Price__c * 100 / salesOrder.NetAmount__c);
                                    Boolean eligibleforResaleApproval = (percentageDiff < 0 ? -percentageDiff : percentageDiff) > ineligibleDiff;
                                    if(!eligibleforResaleApproval){
                                        newCase.Status = ResaleConstants.CASE_AGREEMENT_SIGNATURE_IN_PROCESS;
                                    }
                                }*/
                            }
                        }else{
                            newCase.addError( ResaleConstants.RESALE_ACTIVE_SALESORDER_UNIT_VALIDATION ); // 'There are no active sales orders for given unit.'
                        }
                    }
                }
                if(casesToHasValidSignedDocsMap.containsKey(newCase.Id)){
                    if(casesToHasValidSignedDocsMap.get(newCase.Id)){
                        newCase.Listing_Date__c = dateToday;
                        if(newCase.Listing_Expiry__c != null){
                            Matcher m = Pattern.compile( '\\d+' ).matcher( newCase.Listing_Expiry__c );
                            if(m.find()){
                                newCase.Expiry_Date__c = dateToday.addMonths(Integer.valueOf(m.group()));
                            }
                        }
                    }else{
                        newCase.addError( ResaleConstants.RESALE_CASE_SIGNED_LISTING_AGREEMENT_REQ );
                    }
                }
            }
        }

        if(!accIdsMap.isEmpty() || !customerIdToRmIdMap.isEmpty()){
            getCustomerDetails(accIdsMap, customerIdToRmIdMap);
        }
        // placed separately as account can change from related sales order on change of unit, refer REF-ID = Acc_Of_New_Unit
        /*if( !customerIdToRmIdMap.isEmpty() ){
            customerIdToRmIdMap = getCustomerCasesRM(customerIdToRmIdMap);
        }*/
        if(!resaleCases.isEmpty()){
            for(Case c: (List<Case>)resaleCases) {
                if(c.OwnerId == ResaleRRQueue.Id &&  customerIdToRmIdMap.containsKey(c.AccountId)){
                    if(customerIdToRmIdMap.get(c.AccountId) != null){
                        c.OwnerId = customerIdToRmIdMap.get(c.AccountId);
                        c.Is_Directly_Assigned__c = true;
                        c.Eligible_for_Round_Robin__c = false;
                    }else{
                        c.Eligible_for_Round_Robin__c = true;
                    }
                }
                if(accIdsMap.containsKey(c.AccountId) && accIdsMap.get(c.AccountId) != null && accIdsMap.get(c.AccountId).RecordType.Name == ResaleConstants.PERSON_ACCOUNT_RT){
                    c.ContactId = accIdsMap.get(c.AccountId).PersonContactId;
                }
            }
        }
    }

    public static void getInfoFromResaleCases_Insert(Case caseRecord, List<Case> caseToProcess, ResaleCaseInfos resaleCaseInfos) { //, TeamMemberHelper.SharingWrapper sharingWrapper) {
             if(caseRecord.ReferredBy__c != null){
                    CaseShare caseShareRec = new CaseShare();
                      caseShareRec.UserOrGroupId = UserInfo.getUserId();
                      caseShareRec.CaseAccessLevel = 'Read';
                      caseShareRec.CaseId = caseRecord.Id;
                      insert caseShareRec;
                }
        if(caseRecord.OwnerId != ResaleRRQueue.Id){
            resaleCaseInfos.caseIdsToCreateTask.add(caserecord.Id);

            // sharingWrapper.userIds.add(caseRecord.OwnerId);
            // if(caseRecord.AccountId != null)
            //     sharingWrapper.accIds.add(caseRecord.AccountId);
            // if(caseRecord.SalesOrder__c != null)
            //     sharingWrapper.salesOrderIds.add(caseRecord.SalesOrder__c);
            // TeamMemberHelper.addCaseToWrapper(sharingWrapper.userIdToGiveAccessWrapperMap, caseRecord);
        }
        if(caseRecord.Status == ResaleConstants.CASE_AGREEMENT_SIGNATURE_IN_PROCESS){
            caseToProcess.add(caseRecord);
        }
    }

    public static void operateOnResaleCases_Insert(ResaleCaseInfos resaleCaseInfos) { // , TeamMemberHelper.SharingWrapper sharingWrapper) {
        // if(!sharingWrapper.userIds.isEmpty()){
        //     sharingWrapper.profileName = ResaleConstants.RESALE_RELATIONSHIP_MANAGER_PROFILE;
        //     sharingWrapper.accRole = ResaleConstants.RESALE_RELATIONSHIP_MANAGER_PROFILE;
        //     sharingWrapper.accAccessLevel = 'Edit';
        //     sharingWrapper.salesOrderRole = ResaleConstants.RESALE_RELATIONSHIP_MANAGER_PROFILE;
        //     sharingWrapper.salesOrderAccessLevel = 'Edit';
        //     TeamMemberHelper.handleAccessForRelatedRecords(sharingWrapper);
        // }

        if(!resaleCaseInfos.caseIdsToCreateTask.isEmpty()){
            assignRecordOwnersATask(resaleCaseInfos.caseIdsToCreateTask);
        }
    }

    public static void getInfoFromResaleCases_Update(Case newCase, Case oldCase, List<Case> caseToProcess, ResaleCaseInfos resaleCaseInfos) { // , TeamMemberHelper.SharingWrapper sharingWrapper) {
        if(newCase.Status == ResaleConstants.CASE_NEW){
            if(oldCase == null || oldCase.OwnerId != newCase.OwnerId){
                if(!newCase.CustomerContacted__c && newCase.OwnerId != ResaleRRQueue.Id){
                    resaleCaseInfos.caseIdsToCreateTask.add(newCase.Id);
                }
            }
        }
        if(newCase.Status == ResaleConstants.CASE_QUALIFIED){
            if(oldCase == null || oldCase.Status != newCase.Status){
                if(!newCase.CustomerContacted__c && newCase.OwnerId != ResaleRRQueue.Id){
                    resaleCaseInfos.caseIdsToCreateTask.add(newCase.Id);
                }
            }else if(oldCase == null || oldCase.OwnerId != newCase.OwnerId){
                if(!newCase.CustomerContacted__c && newCase.OwnerId != ResaleRRQueue.Id){
                    resaleCaseInfos.caseIdsToCreateTask.add(newCase.Id);
                }
            }
        }
        if(newCase.Status == ResaleConstants.CASE_AGREEMENT_SIGNATURE_IN_PROCESS && (oldCase == null || oldCase.Status != newCase.Status)){
            caseToProcess.add(newCase);
        }
        if(newCase.Status == ResaleConstants.CASE_PROPERTY_LISTED && (oldCase == null || oldCase.Status != newCase.Status)){
            if(newCase.Unit__c != null){
                resaleCaseInfos.listedUnitIdToCaseIdMap.put(newCase.Unit__c, newCase.Id);   
                resaleCaseInfos.listedResaleCaseIdMap.put(newCase.Id, newCase);
            }
        }
        if((newCase.Status == ResaleConstants.CASE_CANCELLED || newCase.Status == ResaleConstants.CASE_CLOSED) && (oldCase == null || oldCase.Status != newCase.Status)){
            resaleCaseInfos.cancelledCaseIds.add(newCase.Id);
        }

        // if(oldCase == null || (newCase.OwnerId != oldCase.OwnerId) || (newCase.AccountId != oldCase.AccountId) || (newCase.SalesOrder__c != oldCase.salesorder__c)){//|| (newCase.AccountId != oldCase.AccountId) 
        //     sharingWrapper.userIds.add(newCase.OwnerId);
        //     if(newCase.AccountId != null)
        //         sharingWrapper.accIds.add(newCase.AccountId);
        //     if(newCase.SalesOrder__c != null)
        //         sharingWrapper.salesOrderIds.add(newCase.SalesOrder__c);
        //     TeamMemberHelper.addCaseToWrapper(sharingWrapper.userIdToGiveAccessWrapperMap, newCase);
        //     if(oldCase != null && oldCase.OwnerId != ResaleRRQueue.Id){
        //         sharingWrapper.userIds.add(oldCase.OwnerId);
        //         if(oldCase.AccountId != null)
        //             sharingWrapper.accIds.add(oldCase.AccountId);
        //         if(oldCase.SalesOrder__c != null)
        //             sharingWrapper.salesOrderIds.add(oldCase.SalesOrder__c);
        //         TeamMemberHelper.addCaseToWrapper(sharingWrapper.userIdToRemoveAccessWrapperMap, oldCase);
        //     }
        // }
    }

    public static void operateOnResaleCases_Update(ResaleCaseInfos resaleCaseInfos) { //, TeamMemberHelper.SharingWrapper sharingWrapper) {
        if(!resaleCaseInfos.listedResaleCaseIdMap.isEmpty()){
            listUnitsWithCaseIdMap(resaleCaseInfos.listedResaleCaseIdMap, resaleCaseInfos.listedUnitIdToCaseIdMap);
        }
        if(!resaleCaseInfos.caseIdsToCreateTask.isEmpty()){
            assignRecordOwnersATask(resaleCaseInfos.caseIdsToCreateTask);
        }
        // if(!sharingWrapper.userIds.isEmpty()){
        //     sharingWrapper.profileName = ResaleConstants.RESALE_RELATIONSHIP_MANAGER_PROFILE;
        //     sharingWrapper.accRole = ResaleConstants.RESALE_RELATIONSHIP_MANAGER_PROFILE;
        //     sharingWrapper.accAccessLevel = 'Edit';
        //     sharingWrapper.salesOrderRole = ResaleConstants.RESALE_RELATIONSHIP_MANAGER_PROFILE;
        //     sharingWrapper.salesOrderAccessLevel = 'Edit';
        //     TeamMemberHelper.handleAccessForRelatedRecords(sharingWrapper);
        // }
        // if(!resaleCaseInfos.cancellationInProgressCases.isEmpty()){
        //     createResaleCharges(resaleCaseInfos.cancellationInProgressCases);
        // }
        if(!resaleCaseInfos.cancelledCaseIds.isEmpty()){
            delistUnitsWithCaseIds(resaleCaseInfos.cancelledCaseIds, null);
        }
    }

    // case and unit related methods
    public static String checkIfCaseExistForSelectedUnit(Id unitId) {
        if(unitId != null){
            Map<Id, String> unitIdToValidationErrorMap = new Map<Id, String>{unitId => null};
            validateNewUnitIds(new Map<Id, Id>(), unitIdToValidationErrorMap);
            return unitIdToValidationErrorMap.get(unitId);
        }else{
            return null;
        }
    }

    public static void validateNewUnitIds(Map<Id, Id> thisCaseIdToUnitIdMap, Map<Id, String> newUnitIdsToValidationErrorMap){
        thisCaseIdToUnitIdMap = thisCaseIdToUnitIdMap == null ? new Map<Id, Id>() : thisCaseIdToUnitIdMap;
        newUnitIdsToValidationErrorMap = newUnitIdsToValidationErrorMap == null ? new Map<Id, String>() : newUnitIdsToValidationErrorMap;
        if(!newUnitIdsToValidationErrorMap.isEmpty()){
            // retrieving all units using ids with in-progress service requests and not-cancelled resale cases
            Map<Id, Unit__c> unitsMap = new Map<Id, Unit__c>(
               [SELECT Id, Name, 
                    (SELECT Id FROM Service_Requests__r 
                        WHERE HexaBPM__IsClosedStatus__c = FALSE 
                            AND HexaBPM__Internal_Status_Name__c !=: ResaleConstants.SERVICEREQUEST_IN_PROGRESS_STATUS AND HexaBPM__Internal_Status_Name__c !=: ResaleConstants.SERVICEREQUEST_BUYER_CHEQUES_RECEIVED_STATUS
                            AND ( RecordType.DeveloperName =: ResaleConstants.SERVICEREQUEST_PROP_TRANSFER_RecordTypeDeveloperName 
                                    OR RecordType.DeveloperName =: ResaleConstants.SERVICEREQUEST_PROP_TRANSFER_NOC_RecordTypeDeveloperName )
                        LIMIT 1),
                    (SELECT Id FROM Cases__r 
                        WHERE RecordTypeId =: ResaleConstants.Resale_Case_RecordTypeId 
                            AND (Status !=: ResaleConstants.CASE_CANCELLED OR Status !=:ResaleConstants.CASE_CLOSED)
                            //     AND Status !=: Constants.CLOSED_CASE
                        ORDER BY CreatedDate DESC )
                FROM Unit__c
                WHERE Id IN: newUnitIdsToValidationErrorMap.keySet()]);
            for (Id unitId : newUnitIdsToValidationErrorMap.keySet()) {
                if(unitsMap.containsKey(unitId)){
                    Unit__c u = unitsMap.get(unitId);
                    if(u.Service_Requests__r != null && !u.Service_Requests__r.isEmpty()){  // if any service request is in-progress, add error
                        newUnitIdsToValidationErrorMap.put(unitId, ResaleConstants.RESALE_OPEN_SERVICE_REQ_UNIT_VALIDATION); // 'A transfer request is already under process for this unit.'
                    }else if(u.Cases__r != null && !u.Cases__r.isEmpty()){  // if current case is not the only one in related resale cases, add error
                        Set<Id> inProgressCaseIds = new Set<Id>();
                        for(Case c: u.Cases__r){
                            if(!thisCaseIdToUnitIdMap.containsKey(c.Id) || thisCaseIdToUnitIdMap.get(c.Id) != unitId){
                                inProgressCaseIds.add(c.Id);
                            }
                        }
                        if(!inProgressCaseIds.isEmpty()){
                            newUnitIdsToValidationErrorMap.put(unitId, ResaleConstants.RESALE_CASE_OPEN_PER_UNIT_VALIDATION);
                        }
                    }
                }else{
                    newUnitIdsToValidationErrorMap.put(unitId, ResaleConstants.RESALE_INVALID_UNIT_SELECTED_VALIDATION); // 'Unit doesn\'t exist.'
                }
            }
        }
    }

    public static Map<Id, Account> getCustomerDetails(Map<Id, Account> accIdsMap, Map<Id, Id> customerIdToRmIdMap) {
        if( !accIdsMap.isEmpty() || !customerIdToRmIdMap.isEmpty() ){
            for(Account acc: [  SELECT Id, Name, FirstName, MiddleName, LastName, RecordType.Name, PersonContactId,
                                    ResidentStatus__pc, MaritalStatus__pc, EmploymentStatus__pc, Company__pc, Position__pc, CompanyAddress__pc,
                                    NoofYearswithCompany__pc, Industry, AnnualIncome__pc,  PassportNumber__pc, 
                                    PersonEmail, MobilePhone__pc, MobileCountryCode__pc,
                                    (SELECT Id, Status, OwnerId 
                                    FROM Cases 
                                    WHERE RecordTypeId =: ResaleConstants.Resale_Case_RecordTypeId 
                               AND (Status !=: ResaleConstants.CASE_CANCELLED OR Status !=:ResaleConstants.CASE_CLOSED)
                                        AND Owner.Type = 'User'
                                        AND Owner.Profile.Name =: ResaleConstants.RESALE_RELATIONSHIP_MANAGER_PROFILE
                                        AND CreatedDate = LAST_N_DAYS:90
                                    ORDER BY LastModifiedDate DESC
                                    LIMIT 1) 
                                FROM Account 
                                WHERE Id IN:accIdsMap.keyset() 
                                    OR Id IN: customerIdToRmIdMap.keySet() ]){
                if( accIdsMap.containsKey(acc.Id) ){
                    accIdsMap.put(acc.Id, acc);
                }
                if( customerIdToRmIdMap.containsKey(acc.Id) && !acc.Cases.isEmpty() ){
                    customerIdToRmIdMap.put(acc.Id, acc.Cases[0].OwnerId);
                }
            }
        }
        return accIdsMap;
    }

    public static Map<Id, Id> getCustomerCasesRM(Map<Id, Id> customerIdToRmIdMap) {
        if(!customerIdToRmIdMap.isEmpty()){
            List<Account> existingCusotmerWithCasesList = [ SELECT Id, 
                                                                (SELECT Id, Status, OwnerId 
                                                                FROM Cases 
                                                                WHERE RecordTypeId =: ResaleConstants.Resale_Case_RecordTypeId 
                                                            AND (Status !=: ResaleConstants.CASE_CANCELLED OR Status !=:ResaleConstants.CASE_CLOSED)
                                                                    AND Owner.Type = 'User'
                                                                    AND Owner.Profile.Name =: ResaleConstants.RESALE_RELATIONSHIP_MANAGER_PROFILE
                                                                    AND CreatedDate = LAST_N_DAYS:90
                                                                ORDER BY LastModifiedDate DESC
                                                                LIMIT 1)
                                                            FROM Account 
                                                            WHERE Id IN: customerIdToRmIdMap.keySet()];
            if(!existingCusotmerWithCasesList.isEmpty()){
                for (Account acc : existingCusotmerWithCasesList) {
                    if( !acc.Cases.isEmpty() ){
                        customerIdToRmIdMap.put(acc.Id, acc.Cases[0].OwnerId);
                    }
                }
            }
        }
        return customerIdToRmIdMap;
    }

    public static void assignRecordOwnersATask(Set<Id> caseIdsSet) {
        if(!caseIdsSet.isEmpty()){
            DateTime dtNow = System.now();
            Date dtAfter24Hours = dtNow.addHours(24).date();
            List<Case> caseRecs = [ SELECT Id, ContactId, CreatedById, Status, CustomerContacted__c,
                                        AccountId, Account.IsPersonAccount, Account.PersonContactId, 
                                        OwnerId, Owner.Type, Owner.Profile.Name, 
                                       (SELECT Id, Subject, 
                                            WhoId, OwnerId, 
                                            CustomerResponse__c 
                                        FROM Tasks 
                                        WHERE Subject =: ResaleConstants.CALL_CUSTOMER )  
                                    FROM Case 
                                    WHERE Id IN: caseIdsSet];
            List<Task> tasksToCreate = new List<Task>();
            for(Case cs : caseRecs){
                if(cs.OwnerId != null && cs.Owner.Type != null && cs.Owner.Profile != null && cs.Owner.Type.equalsIgnoreCase('User') && cs.Owner.Profile.Name.equalsIgnoreCase(ResaleConstants.RESALE_RELATIONSHIP_MANAGER_PROFILE)){
                    Boolean createTask = true;
                    if(!cs.Tasks.isEmpty()){
                        for(Task t : cs.Tasks){
                            if(t.OwnerId == cs.OwnerId && t.WhoId == cs.ContactId){
                                createTask = false;
                            }
                        }
                    }
                    if(createTask){
                        Task t = new Task(
                            Type = ResaleConstants.TASK_TYPE_CALL,
                            Subject = ResaleConstants.CALL_CUSTOMER,
                            ActivityDate = dtAfter24Hours,
                            WhatId = cs.Id,
                            WhoId = cs.ContactId,
                            OwnerId = cs.OwnerId
                        );
                        if(cs.Account.IsPersonAccount && cs.ContactId != cs.Account.PersonContactId){
                            t.WhoId = cs.Account.PersonContactId;
                        }
                        if(cs.CustomerContacted__c && cs.Status != ResaleConstants.CASE_QUALIFIED){
                            t.CustomerResponse__c = ResaleConstants.CUSTOMER_REACHED;
                            t.Status = ResaleConstants.TASK_COMPLETED;
                        }
                        tasksToCreate.add(t);
                    }
                }
            }
            if(!tasksToCreate.isEmpty()){
                insert tasksToCreate;
            }
        }
    }

    public static void processCaseFromTask(List<Task> newTaskList, Map<Id, SObject> oldTaskMap) {
        Map<Id, String> relatedCaseIdToTaskUpdateMap = new Map<Id, String>();
        for (Task newTask : newTaskList) {
            // only for tasks related to Case record
            if( newTask.WhatId != null && newTask.WhatId.getSObjectType().getDescribe().getName().equalsIgnoreCase('Case') ){
                Task oldTask = oldTaskMap.containsKey(newTask.Id) ? (Task)oldTaskMap.get(newTask.Id) : null;
                // only for task for initial reach out to customer by call
                if(newTask.Subject != null && newTask.Subject.equalsIgnoreCase(ResaleConstants.CALL_CUSTOMER) ){
                    // if the case customer is reached by the RM assigned on task then collect the related case id for further processing
                    if(newTask.CustomerResponse__c != null 
                        && ( newTask.CustomerResponse__c.equalsIgnoreCase(ResaleConstants.CUSTOMER_REACHED) || newTask.CustomerResponse__c.equalsIgnoreCase(ResaleConstants.CUSTOMER_NOT_REACHABLE) )
                        && (oldTask == null || oldTask.CustomerResponse__c != newTask.CustomerResponse__c )
                        && newTask.OwnerId == UserInfo.getUserId() ){
                        relatedCaseIdToTaskUpdateMap.put(newTask.WhatId, newTask.CustomerResponse__c);
                    }
                }
            }
        }
        if(!relatedCaseIdToTaskUpdateMap.isEmpty()){
            // on first successful contact to customer, to be updated the related case should be qualified
            List<Case> casesToUpdate = [SELECT Id, 
                                            Status, CustomerContacted__c 
                                        FROM Case 
                                        WHERE Id IN: relatedCaseIdToTaskUpdateMap.keySet()];
            for (Case cs : casesToUpdate) {
                if(relatedCaseIdToTaskUpdateMap.containsKey(cs.Id)){
                    if(relatedCaseIdToTaskUpdateMap.get(cs.Id).equalsIgnoreCase(ResaleConstants.CUSTOMER_REACHED)){
                        if(cs.Status == ResaleConstants.CASE_NEW){
                            cs.Status = ResaleConstants.CASE_IN_PROGRESS;
                        }else if(cs.Status == ResaleConstants.CASE_QUALIFIED){
                            cs.Status = ResaleConstants.CASE_DISCUSSION_IN_PROGRESS;
                        }
                        cs.CustomerContacted__c = true;
                    }else if(relatedCaseIdToTaskUpdateMap.get(cs.Id).equalsIgnoreCase(ResaleConstants.CUSTOMER_NOT_REACHABLE)){
                        cs.CustomerContacted__c = true;
                    }
                }
            }
            update casesToUpdate;
        }
    }
    
    public static void listUnitsAfterAgreementSignature(Set<Id> caseIds) {
        // get resale cases
        List<Case> casesToList = new List<Case>();
        for(Case cs: [  SELECT Id, Status,
                            Unit__c, Unit__r.ResaleListed__c
                        FROM Case 
                        WHERE Id IN: caseIds 
                            AND RecordType.DeveloperName =: ResaleConstants.RESALE_CASE_RecordTypeDeveloperName 
                            AND Unit__r.ResaleListed__c = FALSE
                            AND Status =: ResaleConstants.CASE_AGREEMENT_SIGNATURE_IN_PROCESS]){
            cs.Status = ResaleConstants.CASE_PROPERTY_LISTED;
            casesToList.add(cs);
        }
        if(!casesToList.isEmpty()){
            update casesToList;
        }
    }

    public static void validateSignedDocumentForCases(String docType, Map<Id, Boolean> casesToHasValidSignedDocsMap) {
        if(!casesToHasValidSignedDocsMap.isEmpty()){
            for(Document__c doc : [ SELECT Id,
                                        Case__c,
                                        DocumentType__c,
                                        (SELECT Id FROM ContentDocumentLinks)
                                    FROM Document__c
                                    WHERE Case__c IN: casesToHasValidSignedDocsMap.keySet()
                                            AND DocumentType__c =: docType
                                            AND ProcessResaleCase__c = true]){
                if(casesToHasValidSignedDocsMap.containsKey(doc.Case__c) && !doc.ContentDocumentLinks.isEmpty()){
                    casesToHasValidSignedDocsMap.put(doc.Case__c, true);
                }
            }
        }
    }
    
    public static void listUnitsWithCaseIdMap(Map<Id, Case> listedCaseIdMap, Map<Id, Id> listedUnitIdToCaseIdMap) {
        if(!listedCaseIdMap.isEmpty()){
            List<Unit__c> unitsToUpdate = [ SELECT Id, 
                                                ResaleListed__c, ResaleStatus__c, ResaleListingExclusiveness__c, 
                                                Listed_Date__c, Delisted_Date__c, CancellationChargesExpiryDate__c, 
                                                Listing_Price__c, ListedCase__c, ListedBy__c
                                            FROM Unit__c 
                                            WHERE Id IN: listedUnitIdToCaseIdMap.keyset()
                                                AND ResaleListed__c = FALSE];
            updateUnitsWithCaseStatus(true, unitsToUpdate, listedCaseIdMap, listedUnitIdToCaseIdMap, ResaleConstants.UNIT_RESALESTATUS_PROPERTY_LISTED);
        }
    }

    public static void delistUnitsWithCaseIds(List<Id> caseIds, String newUnitResaleStatus) {
        if(!caseIds.isEmpty()){
            List<Unit__c> unitsToUpdate = [ SELECT Id, 
                                                ResaleListed__c, ResaleStatus__c,
                                                Listed_Date__c, Delisted_Date__c, 
                                                Listing_Price__c
                                            FROM Unit__c 
                                            WHERE Id IN (SELECT Unit__c 
                                                        FROM Case 
                                                        WHERE Id IN: caseIds)
                                                AND ResaleListed__c = TRUE];
            updateUnitsWithCaseStatus(false, unitsToUpdate, new Map<Id, Case>(), new Map<Id, Id>(), newUnitResaleStatus);
        }
    }

    public static void updateUnitsWithCaseStatus(Boolean areListed, List<Unit__c> unitsToUpdate, Map<Id, Case> listedCaseIdMap, Map<Id, Id> listedUnitIdToCaseIdMap, String newUnitResaleStatus){
        Id operator = UserInfo.getUserId();
        if(!unitsToUpdate.isEmpty()){
            Date dateToday = System.today();
            for(Unit__c unit: unitsToUpdate){
                unit.ResaleListed__c = areListed;
                unit.ResaleStatus__c = newUnitResaleStatus;
                unit.Listed_Date__c = areListed ? dateToday : unit.Listed_Date__c;
                unit.Delisted_Date__c = !areListed ? dateToday : unit.Delisted_Date__c;
                if(areListed && listedUnitIdToCaseIdMap.containsKey(unit.Id) && listedCaseIdMap.containsKey(listedUnitIdToCaseIdMap.get(unit.Id))){
                    Case caseRec = listedCaseIdMap.get(listedUnitIdToCaseIdMap.get(unit.Id));
                    unit.Listing_Price__c = caseRec.Listing_Price__c;
                    unit.ListedCase__c = listedUnitIdToCaseIdMap.get(unit.Id);
                    unit.ListedBy__c = caseRec.OwnerId;
                    unit.ResaleListingExclusiveness__c = caseRec.ResaleListingExclusiveness__c;
                    unit.CancellationChargesExpiryDate__c = caseRec.Expiry_Date__c;
                }else{
                    unit.Listing_Price__c = null;
                }
            }
            update unitsToUpdate;
        }       
    }

    public static SalesOrder__c getSalesOrder(Id salesOrderId) {
        List<SalesOrder__c> salesOrdersList = getSalesOrdersWithIds(new List<Id>{salesOrderId});
        return salesOrdersList.isEmpty() ? null : salesOrdersList[0];
    }

    public static List<SalesOrder__c> getSalesOrdersWithIds(List<Id> idList){
        return [SELECT Id, 
                        Unit__c,NetAmount__c,
                        Account__c, Account__r.PersonEmail, Account__r.ResidentStatus__pc, Account__r.CountryOfResidence__pc
                FROM SalesOrder__c 
                WHERE Id IN: idList];
    }

    public static List<SalesOrder__c> getSalesOrdersByUnitIds(List<Id> unitIds){
        return [SELECT Id, Unit__c, Account__c, Account__r.PersonContactId, Status__c, Contact__c, 
                    TotalInstallmentReceived__c, TotalOutstanding__c, NetAmount__c, TotalBilled__c, 
                    NumberOfDefaults__c, HoldFlag__c, Unit__r.Project__r.AsiteProjectName__c  
                FROM SalesOrder__c 
                WHERE Unit__c IN: unitIds
                    AND Status__c IN: ResaleConstants.RESALE_SALESORDER_STATUSES
                ORDER BY CreatedDate ASC];
    }

    public static Case getCase(Id caseId) {
        List<Case> casesList = getCasesWithIds(new List<Id>{caseId});
        return casesList.isEmpty() ? null : casesList[0];
    }

    public static List<Case> getCasesWithIds(List<Id> idList){
        return [SELECT Id, RecordType.Name, RecordType.DeveloperName, 
                    // IsOTPVerified__c, OTP__c,
                    AccountId, Account.PersonEmail
                FROM Case 
                WHERE Id IN: idList];
    }
    
    public static Map<String, Group> getQueueInformationsByName(List<String> queueDNamesList) {
        Map<String, Group> queueMap = new Map<String, Group>();
        for(Group q: [SELECT Id, 
                            Name, DeveloperName
                        FROM Group 
                        WHERE Type = 'Queue' 
                            AND DeveloperName IN: queueDNamesList]){
            queueMap.put(q.DeveloperName, q);
        }
        QueueDNameToGroupMap = queueMap;
        return queueMap;
    }

    @AuraEnabled
    public static string createResaleCharges_AuraEnabled(Id recordId){
        try {
            if(recordId != null && recordId.getSObjectType().getDescribe().getName() == 'Case'){
                List<Case> caseList = [SELECT Id, AccountId, SalesOrder__c, Listing_Price__c FROM Case WHERE Id =: recordId LIMIT 1];
                if(!caseList.isEmpty()){
                    return createResaleCharges(caseList);
                }else{
                    throw new AuraHandledException('Couldn\'t access the case record with provided reord id : '+recordId);
                }
            }else{
                throw new AuraHandledException('Invalid Case Record Id : '+recordId);
            }
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static string createResaleCharges(List<Case> caseList){
        List<SalesOrderOtherCharges__c> chargeList = new List<SalesOrderOtherCharges__c>();
        Map<Id, Id> caseIdSalesOrderIdMap = new Map<Id, Id>(); 
        Set<String> resaleChargeTypes = new Set<String>{ResaleConstants.CHARGETYPE_LISTING, ResaleConstants.CHARGETYPE_SC_SELLER};
        Map<String, SalesOrderOtherCharges__c> existingChargesMap = new Map<String, SalesOrderOtherCharges__c>(); 
        //check existing charges, do not create duplicate charges
        for(SalesOrderOtherCharges__c thisChargeRec: [SELECT Id, TypeOfCharge__c, Case__c FROM SalesOrderOtherCharges__c WHERE Case__c IN: caseList]){
            existingChargesMap.put(thisChargeRec.Case__c+'_'+thisChargeRec.TypeOfCharge__c, thisChargeRec);
        }

        for (Case thisCase : caseList) {
            caseIdSalesOrderIdMap.put(thisCase.Id, thisCase.SalesOrder__c);
            for(String thisChargeType: resaleChargeTypes){
                //check if already exists
                if(existingChargesMap != null && existingChargesMap.get(thisCase.Id+'_'+thisChargeType) != null){
                    //charge exists
                    continue;
                }else{
                    //charge doesnt exist
                    SalesOrderOtherCharges__c thisSOOC = new SalesOrderOtherCharges__c();
                    thisSOOC.Case__c = thisCase.Id;
                    thisSOOC.Approval_Status__c = ResaleConstants.STATUS_IN_PROGRESS;
                    thisSOOC.SalesOrder__c = thisCase.SalesOrder__c;

                    if (thisChargeType == ResaleConstants.CHARGETYPE_LISTING) {
                        thisSOOC.TypeOfCharge__c = ResaleConstants.CHARGETYPE_LISTING;
                        thisSOOC.Amount__c = ResaleConstants.LISTING_PRICE;
                        thisSOOC.Account__c = thisCase.AccountId;
                    }else if(thisChargeType == ResaleConstants.CHARGETYPE_SC_SELLER) {
                        thisSOOC.TypeOfCharge__c = ResaleConstants.CHARGETYPE_SC_SELLER;
                        thisSOOC.Amount__c = (thisCase.Listing_Price__c != null && thisCase.Listing_Price__c > 0) 
                                            ? 0.02 * thisCase.Listing_Price__c // 2% of Listing Price to be charged as Service Charge - Seller
                                            : 0;
                        thisSOOC.Account__c = thisCase.AccountId;
                    }
                    chargeList.add(thisSOOC);
                }
            }
        }
        
        if (chargeList.size() > 0) {
            insert chargeList;
            createReceiptInALDOC(chargeList);
            return ResaleConstants.RESALE_CHARGES_CREATED_SUCCESS; // 'Successfully created listing charges'
        }else{
            throw new AuraHandledException( ResaleConstants.RESALE_CHARGES_ALREADY_EXIST ); // 'Charges already exist. No new charges created.'
        }
    }

    private static void createReceiptInALDOC(List<SalesOrderOtherCharges__c> chargeList){

        List<Id> chargeIdList = new List<Id>(); 

        for(SalesOrderOtherCharges__c thisCharge: chargeList){
            if(thisCharge.ERPID__c == ''){
                chargeIdList.add(thisCharge.Id);
            }
        }
        if(chargeIdList.size() > 0){
            ALDOC_OtherChargesHelper.doOtherChargeCallout(chargeIdList, new Map<String, String>());
        }
    }

    /* public static void cancelCasesOnClearOfAllCharges(Set<Id> caseIds) {
        Map<Id, Case> casesToUpdateMap = new Map<Id, Case>();
        Set<String> resaleChargeTypes = new Set<String>{CHARGETYPE_LISTING, CHARGETYPE_SC_SELLER};
        // get resale cases with all charges
        for(Case cs: [SELECT Id, Status,
                        (SELECT Id, TypeOfCharge__c, OutstandingAmount__c
                            FROM Sales_Orders_Other_Charges__r 
                            WHERE TypeOfCharge__c IN: resaleChargeTypes
                            AND OutstandingAmount__c != 0)
                    FROM Case 
                    WHERE Id IN: caseIds 
                        AND RecordType.DeveloperName =: RESALE_CASE_RecordTypeDeveloperName 
                        AND Status =: CASE_CANCELLATION_IN_PROGRESS]){
            if(cs.Sales_Orders_Other_Charges__r != null && cs.Sales_Orders_Other_Charges__r.isEmpty()){
                // cs.Status = CASE_CANCELLED;
                cs.CancellationFeeCleared__c = true;
                casesToUpdateMap.put(cs.Id, cs);
            }
        }
        if(!casesToUpdateMap.isEmpty()){
            update casesToUpdateMap.values();
        }
    }*/

    public static void processResaleTransfers(Set<Id> salesOrderIds) {
        if(salesOrderIds != null && !salesOrderIds.isEmpty()){
            Date dateToday = System.today();
            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            List<Unit__c> unitsToUpdate = new List<Unit__c>();
            // List<Unit__c> salesOrderToUpdate = new List<Unit__c>();
            for(SalesOrder__c so: [ SELECT Id, Unit__c,
                                       (SELECT Id, Seller__c FROM Opportunities__r 
                                        WHERE RecordTypeId =: ResaleConstants.Resale_Opp_RecordTypeId 
                                            AND StageName =: ResaleConstants.OPP_STATUS_CLOSED_WON
                                            AND Unit__r.ResaleStatus__c =: ResaleConstants.UNIT_RESALESTATUS_TRANSFER_PROGRESS
                                        ORDER BY CreatedDate DESC
                                        LIMIT 1)
                                    FROM SalesOrder__c 
                                    WHERE Id IN: salesOrderIds 
                                        AND Id IN ( SELECT SalesOrder__c FROM Opportunity 
                                                    WHERE RecordTypeId =: ResaleConstants.Resale_Opp_RecordTypeId 
                                                        AND StageName =: ResaleConstants.OPP_STATUS_CLOSED_WON)
                                        AND Unit__r.ResaleStatus__c =: ResaleConstants.UNIT_RESALESTATUS_TRANSFER_PROGRESS]){
                oppsToUpdate.add(
                    new Opportunity(
                        Id = so.Opportunities__r[0].Id, 
                        Transferred__c = TRUE,
                        TransferredDate__c = dateToday
                    )
                );
                /*salesOrderToUpdate.add(
                    new SalesOrder__c(
                        Id = so.Id,
                        Account__c = so.Opportunities__r[0].Seller__c;
                    )
                );*/
                unitsToUpdate.add(
                    new Unit__c(
                        Id = so.Unit__c,
                        ResaleStatus__c = ResaleConstants.UNIT_RESALESTATUS_TRANSFER_COMPLETED
                    )
                );
            }
            if(!oppsToUpdate.isEmpty()){
                Database.update( oppsToUpdate, false );
            }
            /*if(!salesOrderToUpdate.isEmpty()){
                Database.update( salesOrderToUpdate, false );
            }*/
            if(!unitsToUpdate.isEmpty()){
                Database.update( unitsToUpdate, false );
            }
        }
    }

    public static Id getRecordTypeId(String objectName, String recordTypeDName){
        Map<String,Schema.SObjectType> schemaDescribe = Schema.getGlobalDescribe();  
        Schema.DescribeSObjectResult describeResult = schemaDescribe.get(objectName).getDescribe();
        return(describeResult.getRecordTypeInfosByDeveloperName().get(recordTypeDName).getRecordTypeId());
    }

    public static String getRecordTypeName(String objectName, String recordTypeId){
        Map<String,Schema.SObjectType> schemaDescribe = Schema.getGlobalDescribe();  
        Schema.DescribeSObjectResult describeResult = schemaDescribe.get(objectName).getDescribe();
        return(describeResult.getRecordTypeInfosById().get(recordTypeId).getName());
    }

    public static String getSystemMessage(String smdName) {
        return SystemMessages__mdt.getInstance(smdName).Message__c;
    }

    public static Map<String, Profile> getProfileByIds(List<String> profileNames) {
        Map<String, Profile> profileNameMap = new Map<String, Profile>();
        for(Profile p: [SELECT Id, Name FROM Profile WHERE Name IN: profileNames]){
            profileNameMap.put(p.Name, p);
        }
        return profileNameMap;
    }

    public class ResaleCaseInfos{
        public Map<Id, Case> listedResaleCaseIdMap {get;set;}
        public Map<Id, Id> listedUnitIdToCaseIdMap {get;set;}
        public Set<Id> caseIdsToCreateTask {get;set;}
        // public List<Case> cancellationInProgressCases {get;set;}
        public List<Id> cancelledCaseIds {get;set;}
        public ResaleCaseInfos(){
            this.listedResaleCaseIdMap = new Map<Id, Case>();
            this.listedUnitIdToCaseIdMap = new Map<Id, Id>();
            this.caseIdsToCreateTask = new Set<Id>(); 
            // this.cancellationInProgressCases = new List<Case>();
            this.cancelledCaseIds = new List<Id>();
        }
    }
    public static Map<Id,Id> getPermissionAssignedMap(String PermissionSetName){
        List<PermissionSet> customPermissionSet = [SELECT Id FROM PermissionSet WHERE Name =:PermissionSetName  LIMIT 1];
        Map<Id,Id> pers = new Map<Id,Id>();
        if(customPermissionSet.size() >0){
            for(PermissionSetAssignment ps : [SELECT Id,AssigneeId,PermissionSetId FROM PermissionSetAssignment WHERE PermissionSetId = :customPermissionSet[0].Id]){
                pers.put(ps.AssigneeId,ps.PermissionSetId);
            }
        }     
        return pers;
    }
}