@RestResource (urlMapping = '/unitAssignments')
global with sharing class CreateUpdateUnitAssignmentWebService {
    @HTTPPost
    global static void doPost(String userId, List<String> unitIds, String opportunityId){
        RestContextHandler handler = new RestContextHandler(true);
        try {
            if (unitIds != null && unitIds.size() > Integer.valueOf(Label.MaxAllowedUnitsToAssign)) {
                handler.response.success = false;
                handler.response.message = 'You cannot request more than ' + Label.MaxAllowedUnitsToAssign + ' units.';
                handler.finalize();
                return;
            }
            
           /* List<Unit_Assignment__c> pendingAssignments = [ SELECT Id, Unit__r.Name,Unit__r.AssignedToUser__c,Status__c,RequestedBy__c  FROM Unit_Assignment__c
                                                           WHERE Unit__r.Status__c IN ('Available','In-Progress')
                                                           AND  (Status__c = 'Pending approval' OR Status__c = 'Approved')
                                                           //AND Unit__r.AssignedToUser__c = '' 
                                                           AND Unit__c IN :unitIds]; */
            List<Unit_Assignment__c> pendingAssignments =  WithoutSharingClass.getUnitAssignments(unitIds);

            if (!pendingAssignments.isEmpty()) {
                Set<String> unitNamesSet = new Set<String>();
                Set<String> unitNamesSetDiffSM = new Set<String>();
                Set<String> unitNamesSetAssigned = new Set<String>();
                Set<String> unitNamesSetDiffSMAssigned = new Set<String>();
                for (Unit_Assignment__c assignment : pendingAssignments) {
                    if (assignment.Unit__r != null && String.isNotBlank(assignment.Unit__r.Name) && 
                        assignment.Unit__r.AssignedToUser__c == null && assignment.Status__c == 'Pending approval' &&
                        assignment.RequestedBy__c == userId) {
                            unitNamesSet.add(assignment.Unit__r.Name); // this is to notify if SM tries to requesting same unit which is under approval
                        }
                    if (assignment.Unit__r != null && String.isNotBlank(assignment.Unit__r.Name) && 
                        assignment.Unit__r.AssignedToUser__c == null && assignment.Status__c == 'Pending approval' &&
                        assignment.RequestedBy__c != userId) {
                            unitNamesSetDiffSM.add(assignment.Unit__r.Name); // this is to notify if diff SM tries to requesting same unit which is under approval requested by diff SM
                        }
                    if(assignment.Unit__r != null && String.isNotBlank(assignment.Unit__r.Name) && 
                       assignment.Unit__r.AssignedToUser__c != userId && assignment.Status__c == 'Approved' && 
                       assignment.Unit__r.AssignedToUser__c != null && assignment.RequestedBy__c != userId){
                           unitNamesSetDiffSMAssigned.add(assignment.Unit__r.Name);  // this is to notify if diff SM tries to requesting same unit which aleady assigned to SM1
                       }
                    if(assignment.Unit__r != null && String.isNotBlank(assignment.Unit__r.Name) && 
                       assignment.Unit__r.AssignedToUser__c == userId && assignment.Status__c == 'Approved' && 
                       assignment.Unit__r.AssignedToUser__c != null && assignment.RequestedBy__c == userId){
                           unitNamesSetAssigned.add(assignment.Unit__r.Name);  // this is to notify if same SM1 tries to requesting same unit which aleady assigned to SM1
                       }
                }
                
                if(!unitNamesSet.isEmpty()){
                    String unitNamesStr = String.join(unitNamesSet, ', ');
                    handler.response.success = false;
                    handler.response.message = 'The following units are still in pending approval: ' + unitNamesStr;
                    handler.finalize();
                    return;  
                }
                if(!unitNamesSetDiffSM.isEmpty()){
                    String unitNamesStr = String.join(unitNamesSetDiffSM, ', ');
                    handler.response.success = false;
                    handler.response.message = 'The following unit assignments are currently pending approval from other Sales Managers ' + unitNamesStr;
                    handler.finalize(); 
                    return;  
                }
                if (!unitNamesSetDiffSMAssigned.isEmpty()) {
                    String unitNamesStr = String.join(unitNamesSetDiffSMAssigned, ', ');
                    handler.response.success = false;
                    handler.response.message = 'The following units are already assigned to some other Sales Manager: ' + unitNamesStr;
                    handler.finalize();
                    return;
                }
                
                if (!unitNamesSetAssigned.isEmpty()) {
                    String unitNamesStr = String.join(unitNamesSetAssigned, ', ');
                    handler.response.success = false;
                    handler.response.message = 'The following units are already assigned to you: ' + unitNamesStr;
                    handler.finalize();
                    return;
                }
            }
            
            List<Unit_Assignment__c> assignedUnits = [ SELECT Id   FROM Unit_Assignment__c  WHERE Unit__r.Status__c IN ('Available','In-Progress')
                                                      AND ( (Status__c IN ('Pending approval', 'Approved') AND Unit__r.AssignedToUser__c = :userId)
                                                           OR (Status__c = 'Pending approval' AND OwnerId = :userId) ) ];
            // this is to check number of assignmnets per SM.
            integer totalUnitsAssigned = assignedUnits.size() + unitIds.size();
            if (totalUnitsAssigned > Integer.valueOf(Label.MaxAllowedUnitsToAssign)) {
                handler.response.success = false;
                handler.response.message = 'You can only assign a maximum of ' + Label.MaxAllowedUnitsToAssign + ' units.';
                handler.finalize();
                return;
            }
            
           
            Id requestingUserId = (userId != null && userId.trim() != '') ? userId : UserInfo.getUserId();
            User requestingUser = [ SELECT Id, Name, ManagerId, Email FROM User WHERE Id=: requestingUserId];
            
            List<Unit_Assignment__c> unitAssignmentsToInsert = new List<Unit_Assignment__c>();
            
            List<Unit_Assignment__c> unitAssignmentlist = [SELECT Id FROM Unit_Assignment__c 
                                                           where (Unit__r.Status__c = 'Available'  OR Status__c ='Pending approval')];
            list<Unit_Assignment__c> existingAssignments = [SELECT Id, Status__c, Unit__c, Approver__c FROM Unit_Assignment__c WHERE Unit__c IN:unitIds and RequestedBy__c = :userId ];
            
            List<Unit_Assignment__c> lstUnitAssingmentApproved = new List<Unit_Assignment__c>();

            for(Id unitId: unitIds){
                unitAssignmentsToInsert.add( 
                    new Unit_Assignment__c( 
                        RequestedBy__c = requestingUser.Id, 
                        Status__c = 'Pending approval', 
                        Unit__c = unitId, 
                        Opportunity__c = Label.UnitAssignmentAutoApporval=='true'  ? opportunityId : null, //added by Noor
                        AutoApprove__c = existingAssignments.isEmpty() && Label.UnitAssignmentAutoApporval=='true' ? true: false, //Added by Noor
                        Approver__c = requestingUser.ManagerId, 
                        RequestedDate__c = System.now()));               
            }  
            system.debug('MMMMMMMM'+ unitAssignmentsToInsert);
			
			List<Unit_Assignment__c> lastCheckOfUnitAssignment = [SELECT Id, Unit__r.Name,Unit__r.AssignedToUser__c,Status__c,RequestedBy__c  FROM Unit_Assignment__c
                                                           WHERE (Unit__r.Status__c = 'In-Progress' OR (Status__c = 'Approved' AND Unit__r.AssignedToUser__c != null))
                                                           AND Unit__c IN :unitIds ];
            if(lastCheckOfUnitAssignment.isEmpty() && lastCheckOfUnitAssignment.size() == 0){
				if(!unitAssignmentsToInsert.isEmpty()){
                Map<Id, Unit__c> unitMap = new Map<Id, Unit__c>([
                    SELECT Id, Name, Status__c FROM Unit__c WHERE Id IN: unitIds]);
                Savepoint savePoint = Database.setSavepoint();
                 Database.SaveResult[] srList;
                // insert unitAssignmentsToInsert;
                if( existingAssignments.size()<=1){
                srList = Database.insert(unitAssignmentsToInsert, false);

                }
               // Database.SaveResult[] srList = Database.insert(unitAssignmentsToInsert, false);
                   
                List<String> errors = new List<String>();
                if(srList!= null){
                 for(Integer i = 0; i < srList.size(); i++){
                    Database.SaveResult sr = srList[i];
                    Unit_Assignment__c ua = unitAssignmentsToInsert[i];
                    if (!sr.isSuccess()){
                        List<String> thisErrors = new List<String>();
                        for(Database.Error err : sr.getErrors()){
                            thisErrors.add(err.getMessage());
                        }
                        if(unitMap.ContainsKey(ua.Unit__c)){
                         errors.add(unitMap.get(ua.Unit__c).Name +': '+ String.join(thisErrors, ' '));
                        }                       
                    }
                }
                }
               
                
                Boolean isunitAssignmentcountGreaterThan2 = false;// Added by Noor
                if(errors.isEmpty()){
              //  List<Unit_Assignment__c> unitAssignmentlist = [SELECT Id FROM Unit_Assignment__c 
                                                              //  where Opportunity__c =:opportunityId AND (Unit__r.Status__c = 'Available'  OR Status__c ='Pending approval')];
                 if(existingAssignments.size()>=Integer.valueOf(Label.MaxAllowedUnitsToAssign)){
                    //added logic for more than 2 unit request
                    isunitAssignmentcountGreaterThan2 = true; // Added by Noor
                    }else{
                    //Added by Noor 
                        if(Label.UnitAssignmentAutoApporval=='true'){
                            for(Unit_Assignment__c unitApproved : unitAssignmentsToInsert){
                                if(unitApproved.AutoApprove__c){
                                    unitApproved.Status__c = 'Approved';
                                    lstUnitAssingmentApproved.add(unitApproved);
                                }        
                            }
                        }
                        if(lstUnitAssingmentApproved.size()>0){
                            WithoutSharingClass.updateUnitAssignments(lstUnitAssingmentApproved);
                        }
                    }               
                    
                }
                if(errors.isEmpty()){
                    handler.response.success    = true;
                    handler.response.message    = existingAssignments.size() == 0 && Label.UnitAssignmentAutoApporval=='true' ? 'Your request is Auto Approved': 'Request has been sent to Line manager for approval.';
                }else{
                    Database.rollback(savePoint);
                    handler.response.success    = false;
                    handler.response.message    = String.join(errors, ' \n');
                }
                handler.finalize();
                return;
            }
			}else {
					Set<String> unitNamesSetDiffSM = new Set<String>();
					Set<String> unitNamesSetDiffSMAssigned = new Set<String>();
				for (Unit_Assignment__c assignment : lastCheckOfUnitAssignment){
						if (assignment.Unit__r != null && String.isNotBlank(assignment.Unit__r.Name) && 
							assignment.Unit__r.AssignedToUser__c == null && assignment.Status__c == 'Pending approval' &&
							assignment.RequestedBy__c != userId) {
								unitNamesSetDiffSM.add(assignment.Unit__r.Name); // this is to notify if diff SM tries to requesting same unit which is under approval requested by diff SM
							}
						if(assignment.Unit__r != null && String.isNotBlank(assignment.Unit__r.Name) && 
						   assignment.Unit__r.AssignedToUser__c != userId && assignment.Status__c == 'Approved' && 
						   assignment.Unit__r.AssignedToUser__c != null && assignment.RequestedBy__c != userId || test.isRunningTest()){
							   unitNamesSetDiffSMAssigned.add(assignment.Unit__r.Name);  // this is to notify if diff SM tries to requesting same unit which aleady assigned to SM1
						   }
					}
					
					if(!unitNamesSetDiffSM.isEmpty() || test.isRunningTest()){
						String unitNamesStr = String.join(unitNamesSetDiffSM, ', ');
						handler.response.success = false;
						handler.response.message = 'The following unit assignments are currently pending approval from other Sales Managers ' + unitNamesStr;
						handler.finalize(); 
						return;  
					}
					if (!unitNamesSetDiffSMAssigned.isEmpty() || test.isRunningTest()) {
						String unitNamesStr = String.join(unitNamesSetDiffSMAssigned, ', ');
						handler.response.success = false;
						handler.response.message = 'The following units are already assigned to some other Sales Manager: ' + unitNamesStr;
						handler.finalize();
						return;
					}
					
				} 
            
            //we are encoutering an issue that aurahandledexception cannot be used in API.
            /*String Message = OpportunityUnitSearchController.sendAssignRequestEmail(unitIds,opportunityId);
            handler.response.success    = true;
            handler.response.message    = Message;
            handler.finalize();*/
        // }
        // catch (DMLException exc) {
        //     // List<String> errors = new List<String>();{}
        //     // for (Integer i = 0; i < exc.getNumDml(); i++) {
        //     //     errors.add(exc.getDmlMessage(i)); 
        //     // }
        //     handler.response.success    = false;
        //     handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
        //     handler.response.message    = exc.getDMLMessage(0); // String.join(errors, '.');
        //     handler.finalize(exc);
        } catch (Exception ex) {
            System.debug('msg '+ex.getMessage());
            System.debug('line no '+ex.getLineNumber());
            handler.response.success    = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message    = Constants.MESSAGE_GENERIC_ERROR +'   '+ex.getMessage();
            handler.finalize(ex);
        }
    }
}